import {
  assertDemoMutationAllowed,
  demoFeatureFlagOverrides,
  isDemoMode,
} from '../config/demo';
import { callTenantFunction, fetchDoc } from './firestoreBase';
import { getCustomerPortalUrl } from './payments';
import { logAuditEvent } from './auditLog';
import type { BillingEntitlement, BillingProfile } from '../types/models';

type CheckoutSessionInput = {
  planId: string;
  seats: number;
  addons?: string[];
};

export async function getBillingProfile(
  businessId: string,
  userId?: string,
): Promise<BillingProfile> {
  if (!businessId) throw new Error('businessId is required to load billing profile');
  const docData = await fetchDoc<BillingProfile>(businessId, ['subscriptions'], 'current');
  const entitlements = Array.isArray(docData?.entitlements)
    ? docData?.entitlements
    : docData?.entitlements && typeof docData.entitlements === 'object'
      ? Object.entries(docData.entitlements).map(([id, enabled]) => ({
          id,
          label: id,
          enabled: Boolean(enabled),
          source: 'plan' as const,
        }))
      : [];
  const profile: BillingProfile = docData
    ? {
        ...docData,
        businessId,
        addonIds: docData.addonIds ?? docData.addOnIds ?? [],
        addOnIds: docData.addOnIds ?? docData.addonIds ?? [],
        entitlements,
        unknownAddOns: docData.unknownAddOns ?? [],
      }
    : {
        businessId,
        status: 'incomplete',
        seats: 0,
        addonIds: [],
        addOnIds: [],
        unknownAddOns: [],
        entitlements: [],
      };
  const demoEntitlements: BillingEntitlement[] = [
    {
      id: 'enableReporting',
      label: 'Reporting',
      enabled: demoFeatureFlagOverrides.enableReporting,
      source: 'trial',
    },
    {
      id: 'enableMarketing',
      label: 'Marketing',
      enabled: demoFeatureFlagOverrides.enableMarketing,
      source: 'trial',
    },
    {
      id: 'enableWaitlist',
      label: 'Waitlist',
      enabled: demoFeatureFlagOverrides.enableWaitlist,
      source: 'trial',
    },
    {
      id: 'enableIntakeBuilder',
      label: 'Intake Builder',
      enabled: demoFeatureFlagOverrides.enableIntakeBuilder,
      source: 'trial',
    },
  ];

  const resolvedProfile =
    isDemoMode && !docData
      ? {
          ...profile,
          status: 'trialing' as const,
          planId: 'pro',
          planName: 'Demo Pro',
          seats: 10,
          addonIds: [],
          addOnIds: [],
          entitlements: demoEntitlements,
        }
      : profile;
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'configRead',
    entityType: 'BillingProfile',
    entityId: businessId,
    metadata: { source: 'getBillingProfile', status: resolvedProfile.status },
  });
  return resolvedProfile;
}

export async function startCheckoutSession(
  businessId: string,
  input: CheckoutSessionInput,
  userId?: string,
): Promise<string> {
  assertDemoMutationAllowed('start checkout');
  if (!businessId) throw new Error('businessId is required to start checkout');
  const response = await callTenantFunction<typeof input, { url?: string }>(
    'billingCreateCheckoutSession',
    businessId,
    input,
  );
  const url = typeof response?.url === 'string' ? response.url.trim() : '';
  if (!url) {
    throw new Error('Checkout URL is unavailable for this workspace.');
  }
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'dataExport',
    entityType: 'BillingProfile',
    entityId: businessId,
    metadata: { source: 'startCheckoutSession', planId: input.planId, seats: input.seats },
  });
  return url;
}

export async function getBillingPortalUrl(businessId: string, userId?: string): Promise<string> {
  assertDemoMutationAllowed('open billing portal');
  const url = await getCustomerPortalUrl(businessId, userId);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'dataExport',
    entityType: 'BillingProfile',
    entityId: businessId,
    metadata: { source: 'getBillingPortalUrl' },
  });
  return url;
}
