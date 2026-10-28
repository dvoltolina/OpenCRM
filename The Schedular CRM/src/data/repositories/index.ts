/**
 * Repository Index
 * Centralized exports for all repositories
 */

// Base repository and types
export * from './repository-types';
export * from './base-repository';

// Repository error handling (excluding ValidationError to avoid duplicate)
export {
  RepositoryError,
  NotFoundError,
  InvalidArgumentError,
  toRepositoryError,
  failedResult,
  successResult,
} from '../errors/repository-errors';

// Utility functions
export * from './firestore-utils';

// Specific repositories
export * from './lead-repository';
export * from './pipeline-repository';
export * from './stage-repository';
export * from './deal-repository';
export * from './contact-repository';
export * from './company-repository';
export * from './activity-repository';
export * from './custom-fields-repository';
export * from './settings-repository';
export * from './templates-repository';
export * from './document-repository';
export * from './document-folder-repository';
export * from './document-template-repository';
export * from './document-activity-repository';
export * from './audit-repository';
export * from './signature-repository';
export * from './rate-limit-repository';
export * from './payment-repository';
export * from './payment-method-repository';
export * from './file-link-repository';
export * from './file-link-access-log-repository';
export * from './email-template-repository';
export * from './email-log-repository';
export * from './email-account-repository';
export * from './email-message-repository';
export * from './email-thread-repository';
export * from './email-tracking-event-repository';
export * from './providers-repository';
export * from './reporting-aggregate-repository';
export * from './report-view-repository';
export * from './report-export-repository';
export * from './automation-repository';
export * from './goal-repository';
export * from './forecast-repository';
export * from './sequence-repository';
export * from './sequence-enrollment-repository';
export * from './sequence-execution-repository';
export * from './dashboard-repository';
export * from './report-repository';
export * from './scheduled-report-repository';
export * from './webhook-endpoint-repository';
export * from './webhook-delivery-repository';
export * from './api-key-repository';
export * from './integration-repository';
export * from './calendar-connection-repository';
export * from './calendar-sync-mapping-repository';
export * from './route-repository';
export * from './time-entry-repository';
export * from './staff-schedule-repository';
export * from './territory-repository';
export * from './client-note-repository';
