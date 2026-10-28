/**
 * Firestore Collection Paths
 * Aligned with shared_data_contract.md from The Scheduler
 *
 * All tenant data is scoped under businesses/{businessId}/
 * Top-level collections: users/
 */

// ============================================
// Collection Path Builders
// ============================================

/**
 * Get the path to a business's data
 */
export function businessPath(businessId: string): string {
  return `businesses/${businessId}`;
}

// ============================================
// Existing Collections (from Scheduler)
// These collections already exist and are shared with the scheduler app
// ============================================

/**
 * clients/{clientId} - Client/Contact records
 * SHARED with scheduler - do not create duplicate collection
 */
export function clientsCollection(businessId: string): string {
  return `businesses/${businessId}/clients`;
}

export function clientDoc(businessId: string, clientId: string): string {
  return `businesses/${businessId}/clients/${clientId}`;
}

/**
 * providers/{providerId} - Staff/Provider records
 * SHARED with scheduler
 */
export function providersCollection(businessId: string): string {
  return `businesses/${businessId}/providers`;
}

/**
 * services/{serviceId} - Service catalog
 * SHARED with scheduler
 */
export function servicesCollection(businessId: string): string {
  return `businesses/${businessId}/services`;
}

/**
 * appointments/{appointmentId} - Appointments
 * SHARED with scheduler - CRM can reference but not primary owner
 */
export function appointmentsCollection(businessId: string): string {
  return `businesses/${businessId}/appointments`;
}

/**
 * message_history/{messageId} - Scheduler communication metadata
 * SHARED with scheduler - CRM reads only
 */
export function messageHistoryCollection(businessId: string): string {
  return `businesses/${businessId}/message_history`;
}

/**
 * clientRiskScores/{clientId} - Scheduler AI risk scores
 * SHARED with scheduler - CRM reads only
 */
export function clientRiskScoresCollection(businessId: string): string {
  return `businesses/${businessId}/clientRiskScores`;
}

export function clientRiskScoreDoc(businessId: string, clientId: string): string {
  return `businesses/${businessId}/clientRiskScores/${clientId}`;
}

/**
 * sentimentResults/{resultId} - Scheduler sentiment analysis output
 * SHARED with scheduler - CRM reads only
 */
export function sentimentResultsCollection(businessId: string): string {
  return `businesses/${businessId}/sentimentResults`;
}

/**
 * payments/{paymentId} - Payment records
 * SHARED with scheduler
 */
export function paymentsCollection(businessId: string): string {
  return `businesses/${businessId}/payments`;
}

// ============================================
// CRM-Specific Collections
// These are new collections added by the CRM
// ============================================

/**
 * pipelines/{pipelineId} - Sales pipeline configurations
 */
export function pipelinesCollection(businessId: string): string {
  return `businesses/${businessId}/pipelines`;
}

export function pipelineDoc(businessId: string, pipelineId: string): string {
  return `businesses/${businessId}/pipelines/${pipelineId}`;
}

/**
 * stages/{stageId} - Pipeline stage definitions
 */
export function stagesCollection(businessId: string): string {
  return `businesses/${businessId}/stages`;
}

export function stageDoc(businessId: string, stageId: string): string {
  return `businesses/${businessId}/stages/${stageId}`;
}

/**
 * leads/{leadId} - Sales leads (pre-conversion)
 */
export function leadsCollection(businessId: string): string {
  return `businesses/${businessId}/leads`;
}

export function leadDoc(businessId: string, leadId: string): string {
  return `businesses/${businessId}/leads/${leadId}`;
}

/**
 * deals/{dealId} - Sales deals/opportunities
 */
export function dealsCollection(businessId: string): string {
  return `businesses/${businessId}/deals`;
}

export function dealDoc(businessId: string, dealId: string): string {
  return `businesses/${businessId}/deals/${dealId}`;
}

/**
 * companies/{companyId} - Company/Organization records
 */
export function companiesCollection(businessId: string): string {
  return `businesses/${businessId}/companies`;
}

export function companyDoc(businessId: string, companyId: string): string {
  return `businesses/${businessId}/companies/${companyId}`;
}

/**
 * sales_activities/{activityId} - Sales activity logs
 * Named with prefix to avoid future conflicts
 */
export function salesActivitiesCollection(businessId: string): string {
  return `businesses/${businessId}/sales_activities`;
}

export function salesActivityDoc(businessId: string, activityId: string): string {
  return `businesses/${businessId}/sales_activities/${activityId}`;
}

/**
 * report_views/{viewId} - Saved report definitions with RBAC ownership
 */
export function reportViewsCollection(businessId: string): string {
  return `businesses/${businessId}/report_views`;
}

export function reportViewDoc(businessId: string, viewId: string): string {
  return `businesses/${businessId}/report_views/${viewId}`;
}

/**
 * crm_custom_fields/{fieldId} - Custom field definitions for CRM entities
 */
export function customFieldsCollection(businessId: string): string {
  return `businesses/${businessId}/crm_custom_fields`;
}

export function customFieldDoc(businessId: string, fieldId: string): string {
  return `businesses/${businessId}/crm_custom_fields/${fieldId}`;
}

/**
 * reporting_aggregates/{aggregateId} - Precomputed KPI snapshots for reports
 */
export function reportingAggregatesCollection(businessId: string): string {
  return `businesses/${businessId}/reporting_aggregates`;
}

export function reportingAggregateDoc(businessId: string, aggregateId: string): string {
  return `businesses/${businessId}/reporting_aggregates/${aggregateId}`;
}

/**
 * report_exports/{exportId} - Scheduled report export definitions
 */
export function reportExportsCollection(businessId: string): string {
  return `businesses/${businessId}/report_exports`;
}

export function reportExportDoc(businessId: string, exportId: string): string {
  return `businesses/${businessId}/report_exports/${exportId}`;
}

/**
 * automation_rules/{ruleId} - Automation definitions (trigger -> action)
 */
export function automationRulesCollection(businessId: string): string {
  return `businesses/${businessId}/automation_rules`;
}

export function automationRuleDoc(businessId: string, ruleId: string): string {
  return `businesses/${businessId}/automation_rules/${ruleId}`;
}

/**
 * automation_runs/{runId} - Execution log for automation runs
 */
export function automationRunsCollection(businessId: string): string {
  return `businesses/${businessId}/automation_runs`;
}

export function automationRunDoc(businessId: string, runId: string): string {
  return `businesses/${businessId}/automation_runs/${runId}`;
}

// ============================================
// Settings Documents
// ============================================

/**
 * settings/crm - CRM-specific settings
 */
export function crmSettingsDoc(businessId: string): string {
  return `businesses/${businessId}/settings/crm`;
}

/**
 * settings/feature_flags - Feature flags (shared)
 */
export function featureFlagsDoc(businessId: string): string {
  return `businesses/${businessId}/settings/feature_flags`;
}

// ============================================
// Top-Level Collections
// ============================================

/**
 * users/{uid} - User auth records (top-level, not under business)
 */
export const USERS_COLLECTION = 'users';

export function userDoc(uid: string): string {
  return `users/${uid}`;
}

// ============================================
// Collection Names (for use with collectionGroup queries)
// ============================================

export const COLLECTION_NAMES = {
  // Shared with scheduler
  clients: 'clients',
  providers: 'providers',
  services: 'services',
  appointments: 'appointments',
  payments: 'payments',

  // CRM-specific
  pipelines: 'pipelines',
  stages: 'stages',
  leads: 'leads',
  deals: 'deals',
  companies: 'companies',
  salesActivities: 'sales_activities',
  reportViews: 'report_views',
  customFields: 'crm_custom_fields',
  reportingAggregates: 'reporting_aggregates',
  reportExports: 'report_exports',

  // Top-level
  users: 'users',
  businesses: 'businesses',
} as const;
