// Feature flags for enabling/disabling CRM features
// These can be driven by subscription tier or business settings

import { isDemoMode } from './demo';

export interface FeatureFlags {
  enableDocuments: boolean;
  enableESignature: boolean;
  enableAutoWinOnSignedProposal: boolean;
  enableCompanies: boolean;
  enableLeadScoring: boolean;
  enableReports: boolean;
  enableTaskReminders: boolean;
  enableEmailIntegration: boolean;
  enableCalendarSync: boolean;
  enableCustomFields: boolean;
  enableImportExport: boolean;
  enableAdvancedReporting: boolean;
  enableReportSavedViews: boolean;
  enableDuplicatePrevention: boolean;
  enableAutomation: boolean;
  enableSequences: boolean;
  enableGoals: boolean;
  enableForecasting: boolean;
  enableWebForms: boolean;
  enableSms: boolean;
  enablePushNotifications: boolean;
  enableDashboards: boolean;
  enableScheduledReports: boolean;
  /** Enable external REST API access (default: false in production) */
  enableApi: boolean;
  /** Enable outbound webhooks (default: false in production) */
  enableWebhooks: boolean;
  /** Enable route planning for field sales (default: true in dev) */
  enableRoutePlanning: boolean;
}

// Import/export stays gated in production until hardened; enable explicitly via env
const envDocuments = import.meta.env.VITE_ENABLE_DOCUMENTS;
const enableDocuments = envDocuments === 'false' ? false : true;

const envESignature = import.meta.env.VITE_ENABLE_ESIGNATURE;
const enableESignature = envESignature === 'true';

const envAutoWin = import.meta.env.VITE_ENABLE_AUTO_WIN_ON_SIGNED_PROPOSAL;
const enableAutoWinOnSignedProposal =
  envAutoWin === 'false' ? false : true;

const envImportExport = import.meta.env.VITE_ENABLE_IMPORT_EXPORT;
const enableImportExport =
  envImportExport === 'true'
    ? true
    : envImportExport === 'false'
      ? false
      : !import.meta.env.PROD;

const envAdvancedReporting = import.meta.env.VITE_ENABLE_ADVANCED_REPORTING;
const enableAdvancedReporting =
  envAdvancedReporting === 'true'
    ? true
    : envAdvancedReporting === 'false'
      ? false
      : !import.meta.env.PROD;

const envReportSavedViews = import.meta.env.VITE_ENABLE_REPORT_SAVED_VIEWS;
const enableReportSavedViews =
  envReportSavedViews === 'true'
    ? true
    : envReportSavedViews === 'false'
      ? false
      : enableAdvancedReporting && !import.meta.env.PROD;

const envDuplicatePrevention = import.meta.env.VITE_ENABLE_DUPLICATE_PREVENTION;
const enableDuplicatePrevention =
  envDuplicatePrevention === 'false'
    ? false
    : true;

const envAutomation = import.meta.env.VITE_ENABLE_AUTOMATION;
const enableAutomation =
  envAutomation === 'true'
    ? true
    : envAutomation === 'false'
      ? false
      : !import.meta.env.PROD;

// Sequences (multi-step outreach cadences) - disabled in production by default
const envSequences = import.meta.env.VITE_ENABLE_SEQUENCES;
const enableSequences =
  envSequences === 'true'
    ? true
    : envSequences === 'false'
      ? false
      : !import.meta.env.PROD;

// Goals (sales quotas/targets) - disabled in production by default
const envGoals = import.meta.env.VITE_ENABLE_GOALS;
const enableGoals =
  envGoals === 'true'
    ? true
    : envGoals === 'false'
      ? false
      : !import.meta.env.PROD;

// Forecasting (weighted revenue projections) - disabled in production by default
const envForecasting = import.meta.env.VITE_ENABLE_FORECASTING;
const enableForecasting =
  envForecasting === 'true'
    ? true
    : envForecasting === 'false'
      ? false
      : !import.meta.env.PROD;

// Web Forms (embeddable lead capture) - disabled in production by default
const envWebForms = import.meta.env.VITE_ENABLE_WEB_FORMS;
const enableWebForms =
  envWebForms === 'true'
    ? true
    : envWebForms === 'false'
      ? false
      : !import.meta.env.PROD;

// SMS (Twilio-based messaging) - disabled in production by default
// Requires Twilio account and Business Associate Agreement for HIPAA
const envSms = import.meta.env.VITE_ENABLE_SMS;
const enableSms =
  envSms === 'true'
    ? true
    : envSms === 'false'
      ? false
      : !import.meta.env.PROD;

// Push notifications (Web Push) - disabled by default until keys configured
const envPush = import.meta.env.VITE_ENABLE_PUSH_NOTIFICATIONS;
const enablePushNotifications =
  envPush === 'true'
    ? true
    : envPush === 'false'
      ? false
      : false;

// Dashboards (customizable analytics dashboards) - disabled in production by default
const envDashboards = import.meta.env.VITE_ENABLE_DASHBOARDS;
const enableDashboards =
  envDashboards === 'true'
    ? true
    : envDashboards === 'false'
      ? false
      : !import.meta.env.PROD;

// Scheduled Reports (recurring report delivery) - disabled in production by default
// Requires SendGrid and Cloud Functions configuration
const envScheduledReports = import.meta.env.VITE_ENABLE_SCHEDULED_REPORTS;
const enableScheduledReports =
  envScheduledReports === 'true'
    ? true
    : envScheduledReports === 'false'
      ? false
      : !import.meta.env.PROD;

// API (external REST API access) - disabled in production by default
// Requires Cloud Functions API layer and API key management
const envApi = import.meta.env.VITE_ENABLE_API;
const enableApi =
  envApi === 'true'
    ? true
    : envApi === 'false'
      ? false
      : !import.meta.env.PROD;

// Webhooks (outbound webhook delivery) - disabled in production by default
// Requires webhook endpoint management and delivery infrastructure
const envWebhooks = import.meta.env.VITE_ENABLE_WEBHOOKS;
const enableWebhooks =
  envWebhooks === 'true'
    ? true
    : envWebhooks === 'false'
      ? false
      : !import.meta.env.PROD;

// Route Planning (field sales route optimization) - enabled by default
// Uses OpenStreetMap Nominatim for geocoding (no API key required)
const envRoutePlanning = import.meta.env.VITE_ENABLE_ROUTE_PLANNING;
const enableRoutePlanning =
  envRoutePlanning === 'true'
    ? true
    : envRoutePlanning === 'false'
      ? false
      : true;

const baseFeatures: FeatureFlags = {
  enableDocuments,
  enableESignature,
  enableAutoWinOnSignedProposal,
  enableCompanies: true,
  enableLeadScoring: true,
  enableReports: true,
  enableTaskReminders: true,
  enableEmailIntegration: false, // Phase 2
  enableCalendarSync: false, // Phase 2
  enableCustomFields: true,
  enableImportExport,
  enableAdvancedReporting,
  enableReportSavedViews,
  enableDuplicatePrevention,
  enableAutomation,
  enableSequences,
  enableGoals,
  enableForecasting,
  enableWebForms,
  enableSms,
  enablePushNotifications,
  enableDashboards,
  enableScheduledReports,
  enableApi,
  enableWebhooks,
  enableRoutePlanning,
};

const demoFeatures: FeatureFlags = {
  ...baseFeatures,
  enableDocuments: true,
  enableESignature: false,
  enableAutoWinOnSignedProposal: false,
  enableCompanies: true,
  enableLeadScoring: true,
  enableReports: true,
  enableTaskReminders: true,
  enableEmailIntegration: false,
  enableCalendarSync: false,
  enableCustomFields: true,
  enableImportExport: false,
  enableAdvancedReporting: true,
  enableReportSavedViews: true,
  enableDuplicatePrevention: true,
  enableAutomation: true,
  enableSequences: true,
  enableGoals: true,
  enableForecasting: true,
  enableWebForms: true,
  enableSms: false,
  enablePushNotifications: false,
  enableDashboards: true,
  enableScheduledReports: true,
  enableApi: true,
  enableWebhooks: true,
  enableRoutePlanning: false,
};

// Default feature flags - all enabled for development
export const defaultFeatures: FeatureFlags = isDemoMode ? demoFeatures : baseFeatures;

// Get feature flags - can be extended to fetch from Firestore per business
export function getFeatureFlags(): FeatureFlags {
  return defaultFeatures;
}

export function isDuplicatePreventionEnabled(): boolean {
  const flags = getFeatureFlags();
  return flags.enableDuplicatePrevention !== false;
}
