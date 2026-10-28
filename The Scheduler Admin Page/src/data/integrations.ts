import {
  type CalendarIntegrationProvider,
  type IntegrationAccount,
  type StaffIntegrationPreference,
  type TelehealthProvider,
  type TelehealthSettings,
} from '../types/models';
import {
  callTenantFunction,
  fetchCollection,
  fetchDoc,
  scopedCollection,
} from './firestoreBase';
import { assertDemoMutationAllowed } from '../config/demo';

export type IntegrationProvider =
  | CalendarIntegrationProvider
  | TelehealthProvider;

export async function listIntegrations(businessId: string): Promise<IntegrationAccount[]> {
  const scoped = scopedCollection<IntegrationAccount>(businessId, ['integrations']);
  return fetchCollection(scoped);
}

export async function listStaffIntegrationPreferences(
  businessId: string,
): Promise<StaffIntegrationPreference[]> {
  const scoped = scopedCollection<StaffIntegrationPreference>(businessId, ['staff_integrations']);
  return fetchCollection(scoped);
}

export async function saveStaffIntegrationPreference(
  businessId: string,
  preference: StaffIntegrationPreference,
) {
  assertDemoMutationAllowed('save staff integration preference');
  if (!businessId) throw new Error('businessId is required to save staff integration preference');

  await callTenantFunction('integrations-saveStaffPreference', businessId, { preference });
}

const defaultTelehealthSettings: TelehealthSettings = {
  defaultProvider: 'zoom',
  fallbackProvider: 'phone',
  requireLink: true,
  perServiceProviders: {},
};

export async function getTelehealthSettings(businessId: string): Promise<TelehealthSettings> {
  const doc = await fetchDoc<TelehealthSettings>(businessId, ['settings'], 'telehealth');
  if (doc) {
    return {
      ...defaultTelehealthSettings,
      ...doc,
      perServiceProviders: doc.perServiceProviders ?? {},
    };
  }
  return { ...defaultTelehealthSettings };
}

export async function updateTelehealthSettings(
  businessId: string,
  updates: Partial<TelehealthSettings>,
) {
  assertDemoMutationAllowed('update telehealth settings');
  if (!businessId) throw new Error('businessId is required to update telehealth settings');

  await callTenantFunction('integrations-updateTelehealthSettings', businessId, { updates });
}

export async function connectIntegration(
  businessId: string,
  provider: IntegrationProvider,
) {
  assertDemoMutationAllowed('connect integration');
  if (!businessId) throw new Error('businessId is required to connect an integration');

  await callTenantFunction('integrations-connect', businessId, { provider });
}

export async function disconnectIntegration(
  businessId: string,
  provider: IntegrationProvider,
) {
  assertDemoMutationAllowed('disconnect integration');
  if (!businessId) throw new Error('businessId is required to disconnect an integration');

  await callTenantFunction('integrations-disconnect', businessId, { provider });
}

export async function refreshIntegrationStatus(
  businessId: string,
  provider: IntegrationProvider,
) {
  assertDemoMutationAllowed('refresh integration');
  if (!businessId) throw new Error('businessId is required to refresh integration status');

  await callTenantFunction('integrations-refresh', businessId, { provider });
}
