import { demoFeatureFlagOverrides, isDemoMode } from './demo';

const baseFeatureFlags = {
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
};

export const featureFlags = isDemoMode
  ? {
      ...baseFeatureFlags,
      ...demoFeatureFlagOverrides,
    }
  : baseFeatureFlags;
