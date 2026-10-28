import { doc, setDoc } from 'firebase/firestore';

import {
  assertDemoMutationAllowed,
  demoFeatureFlagOverrides,
  isDemoMode,
} from '../config/demo';
import { fetchDoc } from './firestoreBase';
import { getDb } from '../lib/firebase';
import type { FeatureFlags } from '../types/models';

const DEFAULT_FLAGS: FeatureFlags = {
  enableCalendarSync: true,
  enableTelehealth: true,
  enableAutomatedReminders: true,
  enablePayments: true,
  enableReporting: true,
  enableImportExport: false,
  enableAutomation: false,
  enableWaitlist: true,
  enableLocations: true,
  enableResources: true,
  enableResourceConflicts: true,
  enableClientPortal: true,
  enableSessionNotes: true,
  enableMarketing: false,
  enableIntakeBuilder: true,
  waitlistNotifyChannels: ['sms', 'email'],
};

export async function getFeatureFlags(businessId: string): Promise<FeatureFlags> {
  const doc = await fetchDoc<FeatureFlags>(businessId, ['settings'], 'feature_flags');
  const resolved = {
    ...DEFAULT_FLAGS,
    ...doc,
  };
  return isDemoMode
    ? {
        ...resolved,
        ...demoFeatureFlagOverrides,
      }
    : resolved;
}

export async function updateFeatureFlags(
  businessId: string,
  updates: Partial<FeatureFlags>,
) {
  assertDemoMutationAllowed('update feature flags');
  if (!businessId) {
    throw new Error('businessId is required to update feature flags');
  }
  if (!Object.keys(updates).length) {
    return;
  }
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'settings', 'feature_flags');
  await setDoc(ref, updates, { merge: true });
}

export function getDefaultFeatureFlags(): FeatureFlags {
  return { ...DEFAULT_FLAGS };
}
