/**
 * Ops Tenants Data Layer
 * Cross-tenant data access for super-admins.
 * All operations are audit-logged.
 */

import {
  getDocs,
  getDoc,
  doc,
  query,
  orderBy,
  limit,
  updateDoc,
  setDoc,
} from 'firebase/firestore';

import { getDb } from '../lib/firebase';
import { businessesCollection } from './opsFirestoreBase';
import { logOpsAuditEvent } from './opsAuditLog';
import { getDefaultFeatureFlags } from './featureFlags';
import type { TenantSummary } from '../types/ops';
import type { BillingProfile, FeatureFlags, WorkspaceInfo } from '../types/models';

/**
 * Fetch all tenants (cross-tenant listing).
 * Super-admin only.
 */
export async function listAllTenants(
  operatorId: string,
  operatorEmail: string,
  maxResults = 500,
): Promise<TenantSummary[]> {
  const db = getDb();
  const businessesRef = businessesCollection();
  // Note: createdAt may not exist on all docs, so we order by name as fallback
  const snap = await getDocs(
    query(businessesRef, limit(maxResults)),
  );

  const tenants: TenantSummary[] = [];

  for (const docSnap of snap.docs) {
    const data = docSnap.data() as WorkspaceInfo & { createdAt?: string; lastActiveAt?: string };
    const businessId = docSnap.id;

    // Fetch billing profile
    const billingRef = doc(db, 'businesses', businessId, 'subscriptions', 'current');
    const billingSnap = await getDoc(billingRef);
    const billing = billingSnap.exists() ? (billingSnap.data() as BillingProfile) : null;

    // Fetch feature flags
    const flagsRef = doc(db, 'businesses', businessId, 'settings', 'feature_flags');
    const flagsSnap = await getDoc(flagsRef);
    const flags = flagsSnap.exists() ? (flagsSnap.data() as Partial<FeatureFlags>) : {};
    const flagsEnabled = Object.values(flags).filter((v) => v === true).length;

    const addonIds = billing?.addonIds ?? billing?.addOnIds ?? [];

    tenants.push({
      id: businessId,
      name: data.name ?? 'Unnamed',
      slug: data.slug,
      email: data.email,
      createdAt: data.createdAt,
      lastActiveAt: data.lastActiveAt,
      planId: billing?.planId,
      planName: billing?.planName,
      status: billing?.status ?? 'incomplete',
      seats: billing?.seats ?? 0,
      addonIds,
      renewalDate: billing?.renewalDate,
      hasCrm: addonIds.includes('crm'),
      hasAi: addonIds.includes('ai'),
      flagsEnabled,
      flagsTotal: Object.keys(getDefaultFeatureFlags()).length,
    });
  }

  return tenants;
}

/**
 * Fetch single tenant details.
 * Logs a tenant_viewed audit event.
 */
export async function getTenantDetails(
  businessId: string,
  operatorId: string,
  operatorEmail: string,
): Promise<{
  workspace: WorkspaceInfo;
  billing: BillingProfile | null;
  flags: FeatureFlags;
} | null> {
  const db = getDb();

  const businessRef = doc(db, 'businesses', businessId);
  const businessSnap = await getDoc(businessRef);

  if (!businessSnap.exists()) {
    return null;
  }

  const workspace = { id: businessId, ...businessSnap.data() } as WorkspaceInfo;

  const billingRef = doc(db, 'businesses', businessId, 'subscriptions', 'current');
  const billingSnap = await getDoc(billingRef);
  const billing = billingSnap.exists() ? (billingSnap.data() as BillingProfile) : null;

  const flagsRef = doc(db, 'businesses', businessId, 'settings', 'feature_flags');
  const flagsSnap = await getDoc(flagsRef);
  const flags = flagsSnap.exists()
    ? { ...getDefaultFeatureFlags(), ...flagsSnap.data() }
    : getDefaultFeatureFlags();

  // Audit the view
  await logOpsAuditEvent({
    operatorId,
    operatorEmail,
    action: 'tenant_viewed',
    businessId,
    businessName: workspace.name,
  });

  return { workspace, billing, flags: flags as FeatureFlags };
}

/**
 * Update tenant plan and seats.
 */
export async function updateTenantPlan(
  businessId: string,
  planId: string,
  planName: string,
  seats: number,
  operatorId: string,
  operatorEmail: string,
): Promise<void> {
  const db = getDb();
  const billingRef = doc(db, 'businesses', businessId, 'subscriptions', 'current');

  await setDoc(
    billingRef,
    {
      planId,
      planName,
      seats,
      updatedAt: new Date().toISOString(),
      updatedBy: operatorId,
    },
    { merge: true },
  );

  await logOpsAuditEvent({
    operatorId,
    operatorEmail,
    action: 'plan_changed',
    businessId,
    metadata: { planId, planName, seats },
  });
}

/**
 * Toggle addon for tenant.
 */
export async function toggleTenantAddon(
  businessId: string,
  addonId: string,
  enabled: boolean,
  operatorId: string,
  operatorEmail: string,
): Promise<void> {
  const db = getDb();
  const billingRef = doc(db, 'businesses', businessId, 'subscriptions', 'current');
  const billingSnap = await getDoc(billingRef);

  const current = billingSnap.exists() ? (billingSnap.data() as BillingProfile) : null;
  const currentAddons = current?.addonIds ?? current?.addOnIds ?? [];

  const newAddons = enabled
    ? [...new Set([...currentAddons, addonId])]
    : currentAddons.filter((id) => id !== addonId);

  await setDoc(
    billingRef,
    {
      addonIds: newAddons,
      updatedAt: new Date().toISOString(),
      updatedBy: operatorId,
    },
    { merge: true },
  );

  await logOpsAuditEvent({
    operatorId,
    operatorEmail,
    action: enabled ? 'addon_added' : 'addon_removed',
    businessId,
    metadata: { addonId, enabled },
  });
}

/**
 * Update tenant feature flags.
 */
export async function updateTenantFeatureFlags(
  businessId: string,
  updates: Partial<FeatureFlags>,
  operatorId: string,
  operatorEmail: string,
): Promise<void> {
  const db = getDb();
  const flagsRef = doc(db, 'businesses', businessId, 'settings', 'feature_flags');

  await setDoc(flagsRef, updates, { merge: true });

  await logOpsAuditEvent({
    operatorId,
    operatorEmail,
    action: 'flag_toggled',
    businessId,
    metadata: { flags: Object.keys(updates), values: updates },
  });
}
