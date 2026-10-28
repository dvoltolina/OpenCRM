import { doc, setDoc } from 'firebase/firestore';

import { assertDemoMutationAllowed, isDemoMode } from '../config/demo';
import { fetchDoc } from './firestoreBase';
import { getDb } from '../lib/firebase';
import { logAuditEvent } from './auditLog';
import type { OnboardingState, OnboardingStepId } from '../types/models';
import { addDoc, collection } from 'firebase/firestore';
import { formatOperatingHours } from '../lib/operatingHours';

// Utility to recursively remove undefined values (Firestore rejects undefined)
function stripUndefined<T>(obj: T): T {
  if (obj === null || obj === undefined) return obj;
  if (Array.isArray(obj)) {
    return obj.map(stripUndefined) as T;
  }
  if (typeof obj === 'object') {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
      if (value !== undefined) {
        result[key] = stripUndefined(value);
      }
    }
    return result as T;
  }
  return obj;
}

// Industries that require HIPAA compliance
export const HIPAA_REQUIRED_INDUSTRIES = [
  'healthcare',
  'medical',
  'dental',
  'therapy',
  'mental health',
  'psychiatry',
  'psychology',
  'counseling',
  'physical therapy',
  'chiropractic',
  'optometry',
  'pharmacy',
  'nursing',
  'home health',
  'hospice',
  'rehabilitation',
  'substance abuse',
  'behavioral health',
];

export function requiresHipaaCompliance(industry: string): boolean {
  if (!industry) return false;
  const normalized = industry.toLowerCase().trim();
  return HIPAA_REQUIRED_INDUSTRIES.some(
    (hipaaIndustry) =>
      normalized.includes(hipaaIndustry) || hipaaIndustry.includes(normalized),
  );
}

const BASE_ONBOARDING_STEPS: OnboardingStepId[] = [
  'business',
  'scheduling',
  'locations',
  'team',
  'billing',
  'integrations',
  'review',
];

const HIPAA_ONBOARDING_STEPS: OnboardingStepId[] = [
  'business',
  'scheduling',
  'locations',
  'team',
  'compliance',
  'billing',
  'integrations',
  'review',
];

// Default export for backwards compatibility
export const ONBOARDING_STEPS: OnboardingStepId[] = HIPAA_ONBOARDING_STEPS;

export function getOnboardingSteps(industry: string): OnboardingStepId[] {
  return requiresHipaaCompliance(industry) ? HIPAA_ONBOARDING_STEPS : BASE_ONBOARDING_STEPS;
}

function defaultOnboardingState(): OnboardingState {
  return {
    status: 'not_started',
    currentStep: 'business',
    completedSteps: [],
    businessBasics: {
      businessName: '',
      industry: '',
      legalEntityType: 'llc',
      timezone: 'UTC',
      primaryLocation: '',
      primaryLocationAddress: {
        street: '',
        city: '',
        state: '',
        zip: '',
        country: 'US',
      },
      contactEmail: '',
      contactPhone: '',
      website: '',
      logoUrl: '',
      tagline: 'Powered by Scheduler',
    },
    scheduling: {
      operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      selfBookingAccess: 'existing_only',
      requireDeposit: false,
      depositType: 'amount',
      depositAmount: 0,
      services: [],
      emailReminders: true,
      smsReminders: false,
      reminderLeadTimeHours: 24,
      communicationNotes: '',
      hours: [
        { day: 'monday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
        { day: 'tuesday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
        { day: 'wednesday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
        { day: 'thursday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
        { day: 'friday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
        { day: 'saturday', isOpen: false, blocks: [] },
        { day: 'sunday', isOpen: false, blocks: [] },
      ],
    },
    locations: [],
    team: {
      invites: [],
      skipped: false,
    },
    compliance: {
      hipaaAcknowledged: false,
      mfaReminderAcknowledged: false,
      allowedDomains: [],
      dataRetentionMonths: 12,
      phiLoggingSafeguards: true,
    },
    billing: {
      planId: null,
      seats: 1,
      addons: [],
      status: 'trialing',
    },
    integrations: {
      importPreference: 'none',
      calendarSyncPlanned: false,
      paymentsReady: false,
    },
    reviewConfirmed: false,
    updatedAt: new Date().toISOString(),
  };
}

function mergeState(base: OnboardingState, incoming?: Partial<OnboardingState>): OnboardingState {
  if (!incoming) return base;
  return {
    ...base,
    ...incoming,
    businessBasics: { ...base.businessBasics, ...incoming.businessBasics },
    scheduling: {
      ...base.scheduling,
      ...incoming.scheduling,
      services: incoming.scheduling?.services ?? base.scheduling.services,
    },
    locations: incoming.locations ?? base.locations,
    team: {
      invites: incoming.team?.invites ?? base.team.invites,
      skipped: incoming.team?.skipped ?? base.team.skipped,
    },
    compliance: { ...base.compliance, ...incoming.compliance },
    billing: { ...base.billing, ...incoming.billing },
    integrations: { ...base.integrations, ...incoming.integrations },
    completedSteps: incoming.completedSteps ?? base.completedSteps,
    reviewConfirmed: incoming.reviewConfirmed ?? base.reviewConfirmed,
    currentStep: incoming.currentStep ?? base.currentStep,
    status: incoming.status ?? base.status,
    updatedAt: incoming.updatedAt ?? base.updatedAt,
    completedAt: incoming.completedAt ?? base.completedAt,
  };
}

export function normalizeOnboardingState(incoming?: Partial<OnboardingState>): OnboardingState {
  return mergeState(defaultOnboardingState(), incoming ?? {});
}

export async function getOnboardingState(
  businessId: string,
  userId?: string,
): Promise<OnboardingState> {
  if (!businessId) throw new Error('businessId is required to load onboarding state');
  const docData = await fetchDoc<OnboardingState>(businessId, ['settings'], 'onboarding');
  const state =
    isDemoMode && !docData
      ? normalizeOnboardingState({
          status: 'completed',
          currentStep: 'review',
          completedSteps: ONBOARDING_STEPS,
          reviewConfirmed: true,
          completedAt: new Date().toISOString(),
        })
      : normalizeOnboardingState(docData ?? {});
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'configRead',
    entityType: 'Onboarding',
    entityId: businessId,
    metadata: { source: 'getOnboardingState', status: state.status },
  });
  return state;
}

type SaveOptions = {
  completedStep?: OnboardingStepId;
  userId?: string;
};

export async function saveOnboardingProgress(
  businessId: string,
  updates: Partial<OnboardingState>,
  options: SaveOptions = {},
): Promise<OnboardingState> {
  assertDemoMutationAllowed('save onboarding progress');
  if (!businessId) throw new Error('businessId is required to save onboarding progress');
  const existing = await getOnboardingState(businessId, options.userId);
  const merged = mergeState(existing, {
    ...updates,
    status: updates.status ?? 'in_progress',
  });
  const completed = new Set<OnboardingStepId>(merged.completedSteps ?? []);
  if (options.completedStep) {
    completed.add(options.completedStep);
  }
  if (updates.completedSteps) {
    updates.completedSteps.forEach((step) => completed.add(step));
  }
  merged.completedSteps = Array.from(completed);
  merged.updatedAt = new Date().toISOString();

  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'settings', 'onboarding');
  const cleanedData = stripUndefined(merged);
  await setDoc(ref, cleanedData, { merge: true });
  await logAuditEvent({
    businessId,
    userId: options.userId,
    actionType: 'configWrite',
    entityType: 'Onboarding',
    entityId: businessId,
    metadata: {
      step: options.completedStep ?? merged.currentStep,
      completedSteps: merged.completedSteps.length,
    },
  });
  return cleanedData;
}

export async function markOnboardingComplete(
  businessId: string,
  userId?: string,
): Promise<OnboardingState> {
  assertDemoMutationAllowed('complete onboarding');
  const existing = await getOnboardingState(businessId, userId);
  const completedSteps = Array.from(new Set<OnboardingStepId>([...existing.completedSteps, ...ONBOARDING_STEPS]));
  const updates: OnboardingState = {
    ...existing,
    status: 'completed',
    currentStep: 'review',
    completedSteps,
    reviewConfirmed: true,
    completedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'settings', 'onboarding');
  const cleanedData = stripUndefined(updates);
  await setDoc(ref, cleanedData, { merge: true });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'configWrite',
    entityType: 'Onboarding',
    entityId: businessId,
    metadata: { source: 'markOnboardingComplete' },
  });
  return cleanedData;
}

export async function createLocationsAndServices(
  businessId: string,
  draft: OnboardingState,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('create onboarding locations and services');
  if (!businessId) throw new Error('businessId is required to finalize onboarding');
  const db = getDb();
  const now = new Date().toISOString();

  const locationPromises = draft.locations.map((loc) =>
    addDoc(collection(db, 'businesses', businessId, 'locations'), {
      name: loc.name || 'New Location',
      address: loc.address ?? '',
      timezone: loc.timezone || draft.businessBasics.timezone || 'UTC',
      notes: loc.notes ?? '',
      isActive: true,
      hours: formatOperatingHours(draft.scheduling.hours),
      operatingHours: draft.scheduling.hours ?? [],
      createdAt: now,
      updatedAt: now,
    }),
  );

  const servicePromises = draft.scheduling.services.map((svc) =>
    addDoc(collection(db, 'businesses', businessId, 'services'), {
      name: svc.name,
      description: svc.description ?? '',
      duration: svc.durationMinutes ?? 30,
      price: typeof svc.price === 'number' ? svc.price : 0,
      category: svc.category ?? '',
      bufferBefore: svc.bufferBefore ?? 0,
      bufferAfter: svc.bufferAfter ?? 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    }),
  );

  await Promise.all([...locationPromises, ...servicePromises]);

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'configWrite',
    entityType: 'Onboarding',
    entityId: businessId,
    metadata: {
      locationsCreated: draft.locations.length,
      servicesCreated: draft.scheduling.services.length,
      source: 'createLocationsAndServices',
    },
  });
}
