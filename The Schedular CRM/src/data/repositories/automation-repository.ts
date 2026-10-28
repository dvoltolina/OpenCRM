/**
 * Automation Repository
 * Stores automation rules (trigger -> action) and execution runs.
 *
 * HIPAA/PHI: Rules and runs store IDs/metadata only. No freeform PHI is persisted.
 */

import { getDocs, limit, orderBy, query, where, type QueryConstraint } from 'firebase/firestore';
import { ShareableRepository, type VisibilityLevel } from './access-control';
import { BaseRepository } from './base-repository';
import type {
  PaginatedResult,
  QueryOptions,
  RepositoryResult,
  SecurityContext,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  failedResult,
  successResult,
  InvalidArgumentError,
} from '../errors/repository-errors';
import type {
  AutomationAction,
  AutomationActionType,
  AutomationRun,
  AutomationRunStatus,
  AutomationRule,
  AutomationRuleStatus,
  AutomationTarget,
  AutomationTrigger,
  AutomationTriggerType,
} from '../../types/automation';
import { documentsToEntities } from './firestore-utils';
import type { UserRole } from '../../types/models';

const ALLOWED_TRIGGER_TYPES: AutomationTriggerType[] = [
  'leadCreated',
  'leadStatusChanged',
  'dealStageChanged',
  'taskOverdue',
  'taskSnoozed',
  'taskReminder',
];

const ALLOWED_ACTION_TYPES: AutomationActionType[] = [
  'createTask',
  'sendEmailTemplate',
  'addTag',
  'updateField',
];

const ALLOWED_TARGETS: AutomationTarget[] = ['lead', 'deal', 'contact', 'company', 'activity'];
const ALLOWED_REMINDER_TYPES = ['upcoming', 'due_today', 'overdue'];

const ALLOWED_RULE_STATUS: AutomationRuleStatus[] = ['enabled', 'disabled'];
const ALLOWED_RUN_STATUS: AutomationRunStatus[] = ['success', 'skipped', 'rate_limited', 'failed'];
const AUTOMATION_MANAGER_ROLES: UserRole[] = ['owner', 'admin', 'manager'];

const MAX_DESC_LENGTH = 200;

// ============================================
// Validators
// ============================================

function isValidActionTarget(target?: AutomationTarget): boolean {
  return Boolean(target && ALLOWED_TARGETS.includes(target));
}

function validateAction(action?: AutomationAction): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!action) {
    errors.push({ field: 'action', message: 'Action is required', code: 'REQUIRED' });
    return { isValid: false, errors };
  }

  if (!ALLOWED_ACTION_TYPES.includes(action.type)) {
    errors.push({ field: 'action.type', message: 'Unsupported action type', code: 'INVALID_VALUE' });
  }

  if (!isValidActionTarget(action.target)) {
    errors.push({ field: 'action.target', message: 'Target is required', code: 'REQUIRED' });
  }

  if (action.type === 'createTask') {
    if (!action.taskTemplate?.title?.trim()) {
      errors.push({ field: 'action.taskTemplate.title', message: 'Task title is required', code: 'REQUIRED' });
    }
    if (action.taskTemplate?.description && action.taskTemplate.description.length > MAX_DESC_LENGTH) {
      errors.push({
        field: 'action.taskTemplate.description',
        message: `Description must be under ${MAX_DESC_LENGTH} characters`,
        code: 'TOO_LONG',
      });
    }
  }

  if (action.type === 'sendEmailTemplate') {
    if (!action.emailTemplate?.templateId?.trim()) {
      errors.push({ field: 'action.emailTemplate.templateId', message: 'Template ID is required', code: 'REQUIRED' });
    }
    if (
      action.emailTemplate?.recipient &&
      !['lead', 'contact', 'assignee', 'owner'].includes(action.emailTemplate.recipient)
    ) {
      errors.push({
        field: 'action.emailTemplate.recipient',
        message: 'Invalid recipient type',
        code: 'INVALID_VALUE',
      });
    }
  }

  if (action.type === 'addTag') {
    if (!action.tag || !action.tag.trim()) {
      errors.push({ field: 'action.tag', message: 'Tag value is required', code: 'REQUIRED' });
    }
  }

  if (action.type === 'updateField') {
    if (!action.fieldUpdate) {
      errors.push({ field: 'action.fieldUpdate', message: 'Field update is required', code: 'REQUIRED' });
    } else if (!action.fieldUpdate.field) {
      errors.push({ field: 'action.fieldUpdate.field', message: 'Field name is required', code: 'REQUIRED' });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

function validateTrigger(trigger?: AutomationTrigger): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!trigger) {
    errors.push({ field: 'trigger', message: 'Trigger is required', code: 'REQUIRED' });
    return { isValid: false, errors };
  }

  if (!ALLOWED_TRIGGER_TYPES.includes(trigger.type)) {
    errors.push({ field: 'trigger.type', message: 'Unsupported trigger type', code: 'INVALID_VALUE' });
  }

  if (trigger.type === 'taskOverdue' && trigger.overdueDays !== undefined && trigger.overdueDays < 0) {
    errors.push({
      field: 'trigger.overdueDays',
      message: 'Overdue days must be zero or greater',
      code: 'OUT_OF_RANGE',
    });
  }

  if (
    trigger.type === 'taskReminder' &&
    trigger.reminderType &&
    !ALLOWED_REMINDER_TYPES.includes(trigger.reminderType)
  ) {
    errors.push({
      field: 'trigger.reminderType',
      message: 'Invalid reminder type',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

function validateAutomationRule(data: Partial<AutomationRule>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.name?.trim()) {
    errors.push({ field: 'name', message: 'Name is required', code: 'REQUIRED' });
  }

  if (data.description && data.description.length > MAX_DESC_LENGTH) {
    errors.push({
      field: 'description',
      message: `Description must be under ${MAX_DESC_LENGTH} characters`,
      code: 'TOO_LONG',
    });
  }

  if (data.status && !ALLOWED_RULE_STATUS.includes(data.status)) {
    errors.push({ field: 'status', message: 'Invalid status', code: 'INVALID_VALUE' });
  }

  const triggerValidation = validateTrigger(data.trigger);
  const actionValidation = validateAction(data.action);

  return {
    isValid: errors.length === 0 && triggerValidation.isValid && actionValidation.isValid,
    errors: [...errors, ...triggerValidation.errors, ...actionValidation.errors],
  };
}

function validateAutomationRun(data: Partial<AutomationRun>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.ruleId) {
    errors.push({ field: 'ruleId', message: 'ruleId is required', code: 'REQUIRED' });
  }

  if (!data.entityId) {
    errors.push({ field: 'entityId', message: 'entityId is required', code: 'REQUIRED' });
  }

  if (data.status && !ALLOWED_RUN_STATUS.includes(data.status)) {
    errors.push({ field: 'status', message: 'Invalid status', code: 'INVALID_VALUE' });
  }

  if (data.actionType && !ALLOWED_ACTION_TYPES.includes(data.actionType)) {
    errors.push({ field: 'actionType', message: 'Invalid actionType', code: 'INVALID_VALUE' });
  }

  if (data.triggerType && !ALLOWED_TRIGGER_TYPES.includes(data.triggerType)) {
    errors.push({ field: 'triggerType', message: 'Invalid triggerType', code: 'INVALID_VALUE' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Automation Rule Repository
// ============================================

export class AutomationRuleRepository extends ShareableRepository<AutomationRule> {
  protected entityName = 'automation rule';
  protected defaultVisibility: VisibilityLevel = 'team';

  constructor() {
    super({ collectionName: 'automation_rules', softDelete: false });
    this.setValidator(validateAutomationRule as Validator<AutomationRule>);
  }

  /**
   * RBAC: Only owner/admin/manager can create, update, or delete automation rules.
   */
  private guardManageAccess(context: SecurityContext): ReturnType<typeof failedResult> | null {
    try {
      this.requireRole(context, AUTOMATION_MANAGER_ROLES);
      return null;
    } catch (error) {
      return failedResult(error, 'Not authorized to manage automation rules');
    }
  }

  private guardDeleteAccess(context: SecurityContext): ReturnType<typeof failedResult> | null {
    try {
      this.requireRole(context, ['owner', 'admin']);
      return null;
    } catch (error) {
      return failedResult(error, 'Only owners or admins can delete automation rules');
    }
  }

  async getByTriggerType(
    context: SecurityContext,
    triggerType: AutomationTriggerType
  ): Promise<RepositoryResult<PaginatedResult<AutomationRule>>> {
    const options: QueryOptions = {
      where: [
        { field: 'trigger.type', operator: '==', value: triggerType },
        { field: 'status', operator: '==', value: 'enabled' },
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: 50,
    };

    return this.getAll(context, options);
  }

  async create(
    context: SecurityContext,
    data: Omit<AutomationRule, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<AutomationRule>> {
    const authError = this.guardManageAccess(context);
    if (authError) return authError;
    return super.create(context, data, customId);
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<AutomationRule, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<AutomationRule>> {
    const authError = this.guardManageAccess(context);
    if (authError) return authError;
    return super.update(context, id, data);
  }

  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    const authError = this.guardDeleteAccess(context);
    if (authError) return authError;
    return super.delete(context, id);
  }

  async setStatus(
    context: SecurityContext,
    id: string,
    status: AutomationRuleStatus
  ): Promise<RepositoryResult<AutomationRule>> {
    if (!ALLOWED_RULE_STATUS.includes(status)) {
      return failedResult(
        new InvalidArgumentError('status', 'Invalid status value'),
        'Invalid status value'
      );
    }
    const authError = this.guardManageAccess(context);
    if (authError) return authError;
    return this.update(context, id, { status });
  }
}

// ============================================
// Automation Run Repository
// ============================================

export class AutomationRunRepository extends BaseRepository<AutomationRun> {
  constructor() {
    super({ collectionName: 'automation_runs', softDelete: false });
    this.setValidator(validateAutomationRun as Validator<AutomationRun>);
  }

  async logRun(
    context: SecurityContext,
    data: Omit<AutomationRun, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<AutomationRun>> {
    const runPayload = {
      ...data,
      createdAt: data.executedAt || new Date(),
    };
    return this.create(context, runPayload);
  }

  async getRecentForRule(
    context: SecurityContext,
    ruleId: string,
    limitCount = 10
  ): Promise<RepositoryResult<AutomationRun[]>> {
    try {
      this.ensureSecurityContext(context);
      const collectionRef = this.getCollectionRef(context);
      const constraints: QueryConstraint[] = [
        where('ruleId', '==', ruleId),
        orderBy('createdAt', 'desc'),
        limit(limitCount),
      ];

      const q = query(collectionRef, ...constraints);
      const snapshot = await getDocs(q);
      const runs = documentsToEntities<AutomationRun>(snapshot.docs);
      return successResult(runs);
    } catch (error) {
      return failedResult(error, 'Failed to fetch automation runs');
    }
  }

  async getByCorrelationId(
    context: SecurityContext,
    correlationId: string,
    ruleId?: string
  ): Promise<RepositoryResult<AutomationRun | null>> {
    try {
      this.ensureSecurityContext(context);
      const collectionRef = this.getCollectionRef(context);
      const constraints: QueryConstraint[] = [
        where('correlationId', '==', correlationId),
        ...(ruleId ? [where('ruleId', '==', ruleId)] : []),
        orderBy('createdAt', 'desc'),
        limit(1),
      ];

      const q = query(collectionRef, ...constraints);
      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const runs = documentsToEntities<AutomationRun>(snapshot.docs);
      return successResult(runs[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to fetch automation run by correlationId');
    }
  }
}

// ============================================
// Singletons
// ============================================

let automationRuleRepositoryInstance: AutomationRuleRepository | null = null;
let automationRunRepositoryInstance: AutomationRunRepository | null = null;

export function getAutomationRuleRepository(): AutomationRuleRepository {
  if (!automationRuleRepositoryInstance) {
    automationRuleRepositoryInstance = new AutomationRuleRepository();
  }
  return automationRuleRepositoryInstance;
}

export function getAutomationRunRepository(): AutomationRunRepository {
  if (!automationRunRepositoryInstance) {
    automationRunRepositoryInstance = new AutomationRunRepository();
  }
  return automationRunRepositoryInstance;
}
