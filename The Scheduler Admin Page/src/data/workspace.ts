import { doc, getDoc, updateDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

import {
  assertDemoMutationAllowed,
  DEMO_BUSINESS_ID,
  isDemoMode,
} from '../config/demo';
import { getDb, getFunctionsClient } from '../lib/firebase';
import type { WorkspaceInfo } from '../types/models';

export const BOOKING_SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAX_SLUG_LENGTH = 50;

export function generateSlugFromName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .substring(0, MAX_SLUG_LENGTH);
}

/**
 * Fetches workspace/business information for the admin dashboard.
 * This includes workspace ID, slug, public booking URL, and other business details.
 *
 * SECURITY: businessId must come from authenticated user context.
 * This function enforces strict tenant scoping.
 */
export async function getWorkspaceInfo(businessId: string): Promise<WorkspaceInfo> {
  if (!businessId) {
    throw new Error('businessId is required to fetch workspace info');
  }

  const db = getDb();
  const businessRef = doc(db, 'businesses', businessId);
  const snap = await getDoc(businessRef);

  if (!snap.exists()) {
    if (isDemoMode) {
      return {
        id: DEMO_BUSINESS_ID,
        name: 'Demo Workspace',
        slug: 'demo-clinic',
        publicBookingUrl: 'https://app.example.com/book/demo-clinic',
        timezone: 'America/Denver',
        requiresHipaaCompliance: false,
        mfaEnabled: false,
      };
    }
    throw new Error('Workspace not found. Contact support if this persists.');
  }

  const data = snap.data();

  // Build public booking URL if slug is available
  const publicBookingUrl = data?.slug
    ? `https://app.example.com/book/${data.slug}`
    : undefined;

  return {
    id: businessId,
    name: data?.name ?? 'Unnamed Workspace',
    slug: data?.slug,
    publicBookingUrl,
    inviteCode: data?.inviteCode,
    email: data?.email,
    phone: data?.phone,
    address: data?.address,
    timezone: data?.timezone ?? 'America/New_York',
    logo: data?.logo,
    requiresHipaaCompliance: data?.requiresHipaaCompliance ?? false,
    mfaEnabled: data?.mfaEnabled ?? false,
  };
}

/**
 * Updates workspace slug and other editable fields.
 * Regenerates publicBookingUrl when slug changes.
 */
export async function updateWorkspaceInfo(
  businessId: string,
  updates: Partial<Omit<WorkspaceInfo, 'id' | 'publicBookingUrl' | 'inviteCode'>>,
): Promise<void> {
  assertDemoMutationAllowed('update workspace settings');
  if (!businessId) {
    throw new Error('businessId is required to update workspace info');
  }

  const db = getDb();
  const businessRef = doc(db, 'businesses', businessId);

  // Remove publicBookingUrl from updates as it's computed
  const { ...validUpdates } = updates;

  await updateDoc(businessRef, {
    ...validUpdates,
    updatedAt: new Date().toISOString(),
  });
}

type LookupSlugResponse = {
  found: boolean;
  businessId?: string;
  businessName?: string;
};

export async function lookupBusinessBySlug(slug: string): Promise<LookupSlugResponse> {
  if (isDemoMode) {
    return { found: false };
  }
  const functions = getFunctionsClient();
  const callable = httpsCallable<{ slug: string }, LookupSlugResponse>(functions, 'lookupBusinessBySlug');
  const result = await callable({ slug });
  return result.data;
}

type CreateWorkspaceInput = {
  businessName: string;
  ownerEmail: string;
  ownerDisplayName: string;
  industry?: string;
  slug?: string;
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
};

type CreateWorkspaceResponse = {
  workspaceId: string;
  businessId: string;
  inviteCode: string;
  publicSlug: string;
  publicBookingUrl: string;
  requiresHipaaCompliance: boolean;
  mfaEnabled: boolean;
};

export async function createWorkspace(input: CreateWorkspaceInput): Promise<CreateWorkspaceResponse> {
  assertDemoMutationAllowed('create workspace');
  const slug = input.slug && BOOKING_SLUG_REGEX.test(input.slug)
    ? input.slug
    : generateSlugFromName(input.businessName);

  const functions = getFunctionsClient();
  const callable = httpsCallable<CreateWorkspaceInput, CreateWorkspaceResponse>(functions, 'createWorkspace');
  const result = await callable({ ...input, slug });
  return result.data;
}
