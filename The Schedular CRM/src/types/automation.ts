/**
 * Automation Types
 * Defines trigger/action contracts for the automation engine.
 *
 * All rules are tenant-scoped and reference IDs only to avoid PHI in configs.
 */

import type { LeadStatus, SalesActivityType, Visibility } from './models';
import type { EmailTemplateType } from './email';

export type AutomationTriggerType =
  | 'leadCreated'
  | 'leadStatusChanged'
  | 'dealStageChanged'
  | 'taskOverdue'
  | 'taskSnoozed'
  | 'taskReminder';

export type AutomationReminderType = 'upcoming' | 'due_today' | 'overdue';

export type AutomationActionType =
  | 'createTask'
  | 'sendEmailTemplate'
  | 'addTag'
  | 'updateField';

export type AutomationTarget = 'lead' | 'deal' | 'contact' | 'company' | 'activity';
export type AutomationRelatedEntityType = Exclude<AutomationTarget, 'activity'>;

export type AutomationRuleStatus = 'enabled' | 'disabled';

export type AutomationRunStatus = 'success' | 'skipped' | 'rate_limited' | 'failed';

export interface AutomationTrigger {
  type: AutomationTriggerType;
  /** Optional lead status transition filter */
  fromStatus?: LeadStatus;
  toStatus?: LeadStatus;
  /** Optional deal stage transition filter */
  fromStageId?: string;
  toStageId?: string;
  /**
   * For overdue task trigger: how many days past due
   * Positive numbers indicate days overdue, 0 catches due today.
   */
  overdueDays?: number;
  /** For taskReminder trigger: which reminder type fired */
  reminderType?: AutomationReminderType;
}

export interface TaskActionTemplate {
  title: string;
  description?: string;
  dueInDays?: number;
  assigneeId?: string;
  assigneeName?: string;
  activityType?: Extract<SalesActivityType, 'task' | 'note'>;
}

export interface EmailActionTemplate {
  templateId: string;
  templateType?: EmailTemplateType;
  /** Target recipient type (ID resolved at runtime; no emails stored here) */
  recipient: 'lead' | 'contact' | 'assignee' | 'owner';
  /** Optional subject override for simulation mode only */
  subjectOverride?: string;
}

export type AllowedFieldUpdate =
  | 'status'
  | 'stageId'
  | 'assigneeId'
  | 'assigneeName'
  | 'leadSource'
  | 'probability';

export interface FieldUpdateAction {
  field: AllowedFieldUpdate;
  value: string | number | boolean | null;
}

export interface AutomationAction {
  type: AutomationActionType;
  target: AutomationTarget;
  taskTemplate?: TaskActionTemplate;
  emailTemplate?: EmailActionTemplate;
  tag?: string;
  fieldUpdate?: FieldUpdateAction;
}

export interface AutomationRuleMetadata {
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: Visibility;
  [key: string]: unknown;
}

export interface AutomationRule extends AutomationRuleMetadata {
  id: string;
  name: string;
  description?: string;
  trigger: AutomationTrigger;
  action: AutomationAction;
  status: AutomationRuleStatus;
  businessId?: string;
  createdById: string;
  createdByName?: string;
  createdAt: Date;
  updatedAt?: Date;
  /** Optional timestamp of last execution for monitoring */
  lastRunAt?: Date;
}

export interface AutomationRun {
  id: string;
  businessId: string;
  ruleId: string;
  triggerType: AutomationTriggerType;
  actionType: AutomationActionType;
  target: AutomationTarget;
  entityId: string;
  entityType: AutomationTarget;
  status: AutomationRunStatus;
  executedAt: Date;
  createdAt: Date;
  updatedAt?: Date;
  correlationId: string;
  dryRun: boolean;
  errorCode?: string;
  errorMessage?: string;
}

export interface AutomationSimulationResult {
  allowed: boolean;
  reason?: string;
  projectedAction?: {
    target: AutomationTarget;
    actionType: AutomationActionType;
    description: string;
  };
}
