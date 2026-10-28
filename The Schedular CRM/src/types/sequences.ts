/**
 * Sequence Types
 * Multi-step outreach automation (cadences) for CRM
 *
 * Path: businesses/{businessId}/sequences/{sequenceId}
 * Path: businesses/{businessId}/sequence_enrollments/{enrollmentId}
 * Path: businesses/{businessId}/sequence_executions/{executionId}
 */

import type { ShareableFields, Visibility } from './models';

// ============================================
// Step Types
// ============================================

export type SequenceStepType = 'email' | 'task' | 'wait' | 'sms' | 'call_reminder';

// ============================================
// Status Types
// ============================================

export type SequenceStatus = 'draft' | 'active' | 'paused' | 'archived';

export type EnrollmentStatus =
  | 'active'
  | 'paused'
  | 'completed'
  | 'exited'
  | 'bounced'
  | 'unsubscribed';

export type ExecutionStatus =
  | 'pending'
  | 'scheduled'
  | 'executing'
  | 'completed'
  | 'failed'
  | 'skipped';

export type EnrollmentEntityType = 'lead' | 'client' | 'deal';

// ============================================
// Exit Reasons
// ============================================

export type ExitReason =
  | 'manual'
  | 'replied'
  | 'unsubscribed'
  | 'bounced'
  | 'meeting_booked'
  | 'deal_won'
  | 'deal_lost'
  | 'converted'
  | 'sequence_paused'
  | 'sequence_archived';

// ============================================
// Step Configuration Types
// ============================================

export interface EmailStepConfig {
  /** Reference to message_templates collection */
  templateId?: string;
  /** Inline subject (used if no template) */
  subject?: string;
  /** Inline body with merge fields (used if no template) */
  body?: string;
}

export interface TaskStepConfig {
  /** Task title */
  title: string;
  /** Task description */
  description?: string;
  /** Assign to sequence owner or entity owner */
  assignToOwner: boolean;
  /** Days after step triggers for due date */
  dueDays: number;
}

export interface SmsStepConfig {
  /** Reference to message_templates collection */
  templateId?: string;
  /** Inline SMS body with merge fields */
  body?: string;
}

export interface CallStepConfig {
  /** Call reminder title */
  title: string;
  /** Call script or notes */
  notes?: string;
}

// ============================================
// Sequence Step
// ============================================

export interface SequenceStep {
  /** Unique step identifier (UUID) */
  id: string;
  /** Order in sequence (0-based) */
  order: number;
  /** Step type */
  type: SequenceStepType;

  // Timing
  /** Days after previous step (0 = same day) */
  delayDays: number;
  /** Hours after previous step */
  delayHours?: number;
  /** Preferred send time (e.g., '09:00') */
  timeOfDay?: string;
  /** Skip weekends when scheduling */
  skipWeekends?: boolean;

  // Type-specific configuration
  emailConfig?: EmailStepConfig;
  taskConfig?: TaskStepConfig;
  smsConfig?: SmsStepConfig;
  callConfig?: CallStepConfig;

  /** Whether this step is active */
  isActive: boolean;
}

// ============================================
// Sending Schedule
// ============================================

export interface SendingSchedule {
  /** Timezone for scheduling (e.g., 'America/New_York') */
  timezone: string;
  /** Only send during business hours */
  businessHoursOnly: boolean;
  /** Start of business hours (0-23) */
  startHour: number;
  /** End of business hours (0-23) */
  endHour: number;
  /** Days to exclude (0=Sunday, 6=Saturday) */
  excludeDays: number[];
}

// ============================================
// Sequence Settings
// ============================================

export interface SequenceSettings {
  /** Sending schedule configuration */
  sendingSchedule: SendingSchedule;

  // Limits
  /** Max emails per day from this sequence */
  dailyEmailLimit?: number;
  /** Max new enrollments per day */
  maxEnrollmentsPerDay?: number;

  // Behavior
  /** Pause sequence when contact replies */
  pauseOnReply: boolean;
  /** Pause on email open (if tracking enabled) */
  pauseOnOpen: boolean;
  /** Track email opens */
  trackOpens?: boolean;
  /** Track link clicks */
  trackClicks?: boolean;
  /** Exit if they book via Scheduler */
  pauseOnMeetingBooked: boolean;
  /** Remove on unsubscribe (always true) */
  removeOnUnsubscribe: boolean;

  // Email threading
  /** Send as replies to first email */
  threadEmails: boolean;
}

// ============================================
// Filter Conditions (for enrollment/exit criteria)
// ============================================

export type FilterOperator =
  | 'equals'
  | 'notEquals'
  | 'contains'
  | 'greaterThan'
  | 'lessThan'
  | 'in'
  | 'notIn';

export interface FilterCondition {
  field: string;
  operator: FilterOperator;
  value: string | number | string[];
}

// ============================================
// Enrollment & Exit Criteria
// ============================================

export interface EnrollmentCriteria {
  /** Entity type to enroll */
  entityType: EnrollmentEntityType;
  /** Conditions for auto-enrollment */
  conditions: FilterCondition[];
  /** Whether to auto-enroll matching entities */
  autoEnroll: boolean;
}

export interface ExitCriteria {
  onReply: boolean;
  onMeetingBooked: boolean;
  onDealWon: boolean;
  onDealLost: boolean;
  onLeadConverted: boolean;
  onManualRemoval: boolean;
  customConditions?: FilterCondition[];
}

// ============================================
// Sequence Stats (denormalized)
// ============================================

export interface SequenceStats {
  totalEnrolled: number;
  activeEnrollments: number;
  completedCount: number;
  exitedCount: number;
  replyRate?: number;
  openRate?: number;
}

// ============================================
// Sequence
// ============================================

export interface Sequence extends ShareableFields {
  id: string;
  name: string;
  description?: string;

  /** Current status */
  status: SequenceStatus;

  /** Ordered list of steps */
  steps: SequenceStep[];

  /** Sequence settings */
  settings: SequenceSettings;

  /** Auto-enrollment rules (optional) */
  enrollmentCriteria?: EnrollmentCriteria;

  /** Auto-exit rules */
  exitCriteria?: ExitCriteria;

  /** Denormalized stats for dashboards */
  stats: SequenceStats;

  // Ownership (from ShareableFields)
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  visibility: Visibility;

  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Email Metrics (for tracking)
// ============================================

export interface EmailMetrics {
  delivered: boolean;
  deliveredAt?: Date;
  opened: boolean;
  openedAt?: Date;
  clicked: boolean;
  clickedAt?: Date;
  replied: boolean;
  repliedAt?: Date;
  bounced: boolean;
  bouncedAt?: Date;
  bounceType?: 'hard' | 'soft';
}

// ============================================
// Execution Result
// ============================================

export interface ExecutionResult {
  success: boolean;
  /** Message ID for email/SMS */
  messageId?: string;
  /** Task ID for task creation */
  taskId?: string;
  /** Error code if failed */
  errorCode?: string;
  /** Error message if failed */
  errorMessage?: string;
  /** Retry count */
  retryCount?: number;
}

// ============================================
// Sequence Enrollment
// ============================================

export interface SequenceEnrollment extends ShareableFields {
  id: string;
  sequenceId: string;
  /** Denormalized for display */
  sequenceName: string;

  // Enrolled entity
  entityType: EnrollmentEntityType;
  entityId: string;
  /** e.g., "John Smith" */
  entityName: string;
  entityEmail: string;
  /** Phone number for SMS sequences (optional) */
  entityPhone?: string;

  // Status
  status: EnrollmentStatus;
  exitReason?: ExitReason;

  // Progress
  /** Current step index (0-based) */
  currentStepIndex: number;
  /** When next step is scheduled */
  nextStepScheduledAt?: Date;

  // Stats
  stepsCompleted: number;
  totalSteps: number;
  emailsSent: number;
  emailsOpened: number;
  emailsClicked: number;
  tasksCreated: number;
  repliesReceived: number;

  // Ownership
  enrolledById: string;
  enrolledByName: string;
  /** Owner of the enrolled entity */
  ownerId: string;
  ownerName: string;

  createdAt: Date;
  updatedAt?: Date;
  completedAt?: Date;
  exitedAt?: Date;
}

// ============================================
// Sequence Execution
// ============================================

export interface SequenceExecution {
  id: string;
  enrollmentId: string;
  sequenceId: string;
  stepId: string;
  stepIndex: number;
  stepType: SequenceStepType;

  // Execution details
  status: ExecutionStatus;
  scheduledAt: Date;
  executedAt?: Date;

  // Results
  result?: ExecutionResult;

  // Email tracking
  emailMetrics?: EmailMetrics;

  // Idempotency
  idempotencyKey: string;

  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Helper Types
// ============================================

export interface SequenceFilters {
  status?: SequenceStatus;
  ownerId?: string;
  search?: string;
}

export interface EnrollmentFilters {
  status?: EnrollmentStatus;
  entityType?: EnrollmentEntityType;
  search?: string;
  dateRange?: { start: Date; end: Date };
}

export interface ExecutionFilters {
  status?: ExecutionStatus;
  stepType?: SequenceStepType;
}

// ============================================
// Default Values
// ============================================

export const DEFAULT_SENDING_SCHEDULE: SendingSchedule = {
  timezone: 'America/New_York',
  businessHoursOnly: true,
  startHour: 9,
  endHour: 17,
  excludeDays: [0, 6], // Sunday, Saturday
};

export const DEFAULT_SEQUENCE_SETTINGS: SequenceSettings = {
  sendingSchedule: DEFAULT_SENDING_SCHEDULE,
  dailyEmailLimit: 50,
  maxEnrollmentsPerDay: 100,
  pauseOnReply: true,
  pauseOnOpen: false,
  trackOpens: true,
  trackClicks: true,
  pauseOnMeetingBooked: true,
  removeOnUnsubscribe: true,
  threadEmails: false,
};

export const DEFAULT_EXIT_CRITERIA: ExitCriteria = {
  onReply: true,
  onMeetingBooked: true,
  onDealWon: true,
  onDealLost: true,
  onLeadConverted: true,
  onManualRemoval: true,
};

export const DEFAULT_SEQUENCE_STATS: SequenceStats = {
  totalEnrolled: 0,
  activeEnrollments: 0,
  completedCount: 0,
  exitedCount: 0,
};

// ============================================
// Validation Helpers
// ============================================

export function isValidStepType(type: string): type is SequenceStepType {
  return ['email', 'task', 'wait', 'sms', 'call_reminder'].includes(type);
}

export function isValidSequenceStatus(status: string): status is SequenceStatus {
  return ['draft', 'active', 'paused', 'archived'].includes(status);
}

export function isValidEnrollmentStatus(status: string): status is EnrollmentStatus {
  return ['active', 'paused', 'completed', 'exited', 'bounced', 'unsubscribed'].includes(status);
}

export function isValidExecutionStatus(status: string): status is ExecutionStatus {
  return ['pending', 'scheduled', 'executing', 'completed', 'failed', 'skipped'].includes(status);
}

export function isValidEntityType(type: string): type is EnrollmentEntityType {
  return ['lead', 'client', 'deal'].includes(type);
}

/**
 * Generate a unique step ID
 */
export function generateStepId(): string {
  return `step_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Create a new empty step of the given type
 */
export function createEmptyStep(type: SequenceStepType, order: number): SequenceStep {
  const base: SequenceStep = {
    id: generateStepId(),
    order,
    type,
    delayDays: order === 0 ? 0 : 1,
    isActive: true,
  };

  switch (type) {
    case 'email':
      return { ...base, emailConfig: { subject: '', body: '' } };
    case 'task':
      return { ...base, taskConfig: { title: '', assignToOwner: true, dueDays: 0 } };
    case 'wait':
      return { ...base, delayDays: 1 };
    case 'call_reminder':
      return { ...base, callConfig: { title: '' } };
    case 'sms':
      return { ...base, smsConfig: { body: '' } };
    default:
      return base;
  }
}

/**
 * Calculate total days for a sequence
 */
export function calculateSequenceDuration(steps: SequenceStep[]): number {
  return steps.reduce((total, step) => {
    const days = step.delayDays || 0;
    const hours = step.delayHours || 0;
    return total + days + hours / 24;
  }, 0);
}
