/**
 * Automation Engine
 * Executes trigger -> action automations with rate limits, idempotency, and audit logging.
 *
 * Scope: Minimal MVP for trigger/action execution with dry-run support.
 */

import { getAutomationRuleRepository, getAutomationRunRepository } from '../data/repositories/automation-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type {
  AutomationAction,
  AutomationActionType,
  AutomationRun,
  AutomationRunStatus,
  AutomationRule,
  AutomationTriggerType,
  AutomationSimulationResult,
} from '../types/automation';
import { getRateLimitService } from './RateLimitService';
import { ActivityService } from './activity-service';
import { EmailService } from './email-service';
import { LeadRepository } from '../data/repositories/lead-repository';
import { DealRepository } from '../data/repositories/deal-repository';
import { ContactRepository } from '../data/repositories/contact-repository';
import { CompanyRepository } from '../data/repositories/company-repository';
import { AuditLogService } from './AuditLogService';
import type { LeadStatus } from '../types/models';
import type { AutomationRelatedEntityType, AutomationReminderType } from '../types/automation';

// ============================================
// Types
// ============================================

export interface AutomationEvent {
  triggerType: AutomationTriggerType;
  entityId: string;
  entityType: 'lead' | 'deal' | 'contact' | 'company' | 'activity';
  correlationId: string;
  dryRun?: boolean;
  fromStatus?: LeadStatus;
  toStatus?: LeadStatus;
  fromStageId?: string;
  toStageId?: string;
  overdueDays?: number;
  reminderType?: AutomationReminderType;
  relatedEntityId?: string;
  relatedEntityType?: AutomationRelatedEntityType;
}

interface ActionResult {
  success: boolean;
  errorCode?: string;
  errorMessage?: string;
}

interface ResolvedAutomationEntity {
  entityId: string;
  entityType: AutomationEvent['entityType'];
}

// ============================================
// Helpers
// ============================================

function matchesTrigger(rule: AutomationRule, event: AutomationEvent): boolean {
  if (rule.status !== 'enabled') return false;
  if (rule.trigger.type !== event.triggerType) return false;

  if (rule.trigger.fromStatus && rule.trigger.fromStatus !== event.fromStatus) return false;
  if (rule.trigger.toStatus && rule.trigger.toStatus !== event.toStatus) return false;

  if (rule.trigger.fromStageId && rule.trigger.fromStageId !== event.fromStageId) return false;
  if (rule.trigger.toStageId && rule.trigger.toStageId !== event.toStageId) return false;

  if (rule.trigger.type === 'taskOverdue' && rule.trigger.overdueDays !== undefined) {
    return event.overdueDays !== undefined && event.overdueDays >= rule.trigger.overdueDays;
  }

  if (rule.trigger.type === 'taskReminder' && rule.trigger.reminderType && rule.trigger.reminderType !== event.reminderType) {
    return false;
  }

  return true;
}

function buildAuditMetadata(rule: AutomationRule, event: AutomationEvent, status: AutomationRunStatus) {
  return {
    ruleId: rule.id,
    ruleName: rule.name,
    triggerType: rule.trigger.type,
    actionType: rule.action.type,
    entityId: event.entityId,
    entityType: event.entityType,
    status,
    correlationId: event.correlationId,
    dryRun: event.dryRun ?? false,
    reminderType: event.reminderType,
    relatedEntityId: event.relatedEntityId,
    relatedEntityType: event.relatedEntityType,
  };
}

// ============================================
// Automation Engine
// ============================================

export class AutomationEngine {
  private rateLimitService = getRateLimitService();
  private activityService = new ActivityService();
  private emailService = new EmailService();
  private leadRepository = new LeadRepository();
  private dealRepository = new DealRepository();
  private contactRepository = new ContactRepository();
  private companyRepository = new CompanyRepository();
  private auditLogService = new AuditLogService();
  private ruleRepo = getAutomationRuleRepository();
  private runRepo = getAutomationRunRepository();

  /**
   * Evaluate a trigger event against all enabled rules and execute matching rule.
   * Intended for worker/Cloud Function use; UI may call for dry-run simulation.
   */
  async handleEvent(
    context: SecurityContext,
    event: AutomationEvent
  ): Promise<AutomationSimulationResult[]> {
    const results: AutomationSimulationResult[] = [];

    const rulesResult = await this.ruleRepo.getByTriggerType(context, event.triggerType);
    if (!rulesResult.success) {
      return [
        {
          allowed: false,
          reason: rulesResult.error?.message || 'Unable to load automation rules',
        },
      ];
    }

    for (const rule of rulesResult.data.data) {
      if (!matchesTrigger(rule, event)) continue;
      const execution = await this.executeRule(context, rule, event);
      results.push(execution);
    }

    return results;
  }

  /**
   * Execute a single rule for an event.
   */
  async executeRule(
    context: SecurityContext,
    rule: AutomationRule,
    event: AutomationEvent
  ): Promise<AutomationSimulationResult> {
    // Idempotency guard
    if (event.correlationId) {
      const existing = await this.runRepo.getByCorrelationId(context, event.correlationId, rule.id);
      if (existing.success && existing.data) {
        return {
          allowed: false,
          reason: 'Run already recorded for this event',
        };
      }
    }

    // Rate limit
    const rateCheck = await this.rateLimitService.checkLimit('automation', context.userId, context.businessId);
    if (!rateCheck.allowed) {
      await this.logRun(context, rule, event, 'rate_limited');
      return {
        allowed: false,
        reason: rateCheck.message || 'Automation rate limit exceeded',
      };
    }

    if (event.dryRun) {
      // Do not record run for dry-run, but ensure audit trail for visibility
      await this.auditLogService.logAction(context, {
        action: 'automation',
        entityType: 'automationRule',
        entityId: rule.id,
        entityName: rule.name,
        metadata: buildAuditMetadata(rule, event, 'skipped'),
      });

      return {
        allowed: true,
        projectedAction: {
          target: rule.action.target,
          actionType: rule.action.type,
          description: this.describeAction(rule.action),
        },
      };
    }

    const actionResult = await this.performAction(context, rule.action, event);

    const status: AutomationRunStatus = actionResult.success ? 'success' : (actionResult.errorCode as AutomationRunStatus) || 'failed';

    await this.rateLimitService.recordAction('automation', context.userId, context.businessId);
    await this.logRun(context, rule, event, status, actionResult.errorCode, actionResult.errorMessage);

    return {
      allowed: actionResult.success,
      reason: actionResult.errorMessage,
      projectedAction: {
        target: rule.action.target,
        actionType: rule.action.type,
        description: this.describeAction(rule.action),
      },
    };
  }

  /**
   * Generate a human-readable action summary.
   */
  private describeAction(action: AutomationAction): string {
    switch (action.type) {
      case 'createTask':
        return `Create task "${action.taskTemplate?.title || ''}" on ${action.target}`;
      case 'sendEmailTemplate':
        return `Send email template ${action.emailTemplate?.templateId} to ${action.emailTemplate?.recipient || 'contact'}`;
      case 'addTag':
        return `Add tag "${action.tag || ''}" to ${action.target}`;
      case 'updateField':
        return `Update field ${action.fieldUpdate?.field} on ${action.target}`;
      default:
        return 'Automation action';
    }
  }

  /**
   * Perform the configured action.
   */
  private async performAction(
    context: SecurityContext,
    action: AutomationAction,
    event: AutomationEvent
  ): Promise<ActionResult> {
    switch (action.type) {
      case 'createTask':
        return this.createTask(context, action, event);
      case 'sendEmailTemplate':
        return this.sendEmail(context, action, event);
      case 'addTag':
        return this.addTag(context, action, event);
      case 'updateField':
        return this.updateField(context, action, event);
      default:
        return { success: false, errorCode: 'unsupported_action', errorMessage: 'Unsupported action type' };
    }
  }

  private async createTask(
    context: SecurityContext,
    action: AutomationAction,
    event: AutomationEvent
  ): Promise<ActionResult> {
    const template = action.taskTemplate;
    if (!template?.title) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'Task title required' };
    }

    const dueDate = template.dueInDays
      ? new Date(Date.now() + template.dueInDays * 24 * 60 * 60 * 1000)
      : undefined;

    const targetEntity = this.resolveActionEntity(action, event);
    if (!targetEntity) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'No linked entity available for task action' };
    }

    const entityField = this.getEntityField(targetEntity.entityType);
    if (!entityField) {
      return {
        success: false,
        errorCode: 'validation_error',
        errorMessage: `Tasks cannot target ${targetEntity.entityType} records directly`,
      };
    }

    const result = await this.activityService.logActivity(context, {
      type: template.activityType || 'task',
      title: template.title,
      description: template.description,
      [entityField]: targetEntity.entityId,
      dueDate,
      assigneeId: template.assigneeId,
      assigneeName: template.assigneeName,
    });

    if (!result.success) {
      return { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
    }

    return { success: true };
  }

  private async sendEmail(
    context: SecurityContext,
    action: AutomationAction,
    event: AutomationEvent
  ): Promise<ActionResult> {
    const email = action.emailTemplate;
    if (!email?.templateId) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'Template ID required' };
    }

    const targetEntity = this.resolveActionEntity(action, event) ?? (
      event.entityType === 'activity'
        ? null
        : {
            entityId: event.entityId,
            entityType: event.entityType,
          }
    );
    if (!targetEntity) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'No linked entity available for email action' };
    }

    const recipientId = targetEntity.entityId;
    const sendResult = await this.emailService.sendEmail(context, {
      recipientId,
      templateId: email.templateId,
      templateType: email.templateType || 'custom',
      category: 'transactional',
      relatedEntity: {
        type: targetEntity.entityType === 'deal' ? 'deal' : 'lead',
        id: targetEntity.entityId,
      },
    });

    if (!sendResult.success) {
      return { success: false, errorCode: 'action_failed', errorMessage: sendResult.error };
    }

    return { success: true };
  }

  private async addTag(
    context: SecurityContext,
    action: AutomationAction,
    event: AutomationEvent
  ): Promise<ActionResult> {
    if (!action.tag?.trim()) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'Tag is required' };
    }

    const targetEntity = this.resolveActionEntity(action, event);
    if (!targetEntity) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'No linked entity available for tag action' };
    }

    const updater = this.getTagUpdater(targetEntity.entityType);
    if (!updater) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'Unsupported target for tag' };
    }

    return updater(context, targetEntity.entityId, action.tag.trim());
  }

  private async updateField(
    context: SecurityContext,
    action: AutomationAction,
    event: AutomationEvent
  ): Promise<ActionResult> {
    if (!action.fieldUpdate) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'Field update required' };
    }

    const targetEntity = this.resolveActionEntity(action, event);
    if (!targetEntity) {
      return { success: false, errorCode: 'validation_error', errorMessage: 'No linked entity available for field update' };
    }

    if (targetEntity.entityType === 'lead') {
      const result = await this.leadRepository.update(context, targetEntity.entityId, {
        [action.fieldUpdate.field]: action.fieldUpdate.value,
      });
      return result.success
        ? { success: true }
        : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
    }

    if (targetEntity.entityType === 'deal') {
      const result = await this.dealRepository.update(context, targetEntity.entityId, {
        [action.fieldUpdate.field]: action.fieldUpdate.value,
      });
      return result.success
        ? { success: true }
        : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
    }

    return { success: false, errorCode: 'validation_error', errorMessage: 'Unsupported target for field update' };
  }

  private resolveActionEntity(
    action: AutomationAction,
    event: AutomationEvent
  ): ResolvedAutomationEntity | null {
    if (
      action.target !== 'activity' &&
      event.relatedEntityType === action.target &&
      event.relatedEntityId
    ) {
      return {
        entityId: event.relatedEntityId,
        entityType: event.relatedEntityType,
      };
    }

    if (action.target === event.entityType) {
      return {
        entityId: event.entityId,
        entityType: event.entityType,
      };
    }

    if (event.entityType !== 'activity') {
      return {
        entityId: event.entityId,
        entityType: event.entityType,
      };
    }

    if (event.relatedEntityId && event.relatedEntityType) {
      return {
        entityId: event.relatedEntityId,
        entityType: event.relatedEntityType,
      };
    }

    return null;
  }

  private getEntityField(entityType: AutomationEvent['entityType']): 'leadId' | 'dealId' | 'clientId' | 'companyId' | null {
    switch (entityType) {
      case 'lead':
        return 'leadId';
      case 'deal':
        return 'dealId';
      case 'contact':
        return 'clientId';
      case 'company':
        return 'companyId';
      default:
        return null;
    }
  }

  private getTagUpdater(
    entityType: AutomationEvent['entityType']
  ): ((context: SecurityContext, id: string, tag: string) => Promise<ActionResult>) | null {
    if (entityType === 'lead') {
      return async (ctx, id, tag) => {
        const existing = await this.leadRepository.getById(ctx, id);
        if (!existing.success || !existing.data) {
          return { success: false, errorCode: 'not_found', errorMessage: 'Lead not found' };
        }
        const tags = Array.from(new Set([...(existing.data.tags || []), tag]));
        const result = await this.leadRepository.update(ctx, id, { tags });
        return result.success
          ? { success: true }
          : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
      };
    }

    if (entityType === 'deal') {
      return async (ctx, id, tag) => {
        const existing = await this.dealRepository.getById(ctx, id);
        if (!existing.success || !existing.data) {
          return { success: false, errorCode: 'not_found', errorMessage: 'Deal not found' };
        }
        const tags = Array.from(new Set([...(existing.data.tags || []), tag]));
        const result = await this.dealRepository.update(ctx, id, { tags });
        return result.success
          ? { success: true }
          : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
      };
    }

    if (entityType === 'contact') {
      return async (ctx, id, tag) => {
        const existing = await this.contactRepository.getById(ctx, id);
        if (!existing.success || !existing.data) {
          return { success: false, errorCode: 'not_found', errorMessage: 'Contact not found' };
        }
        const tags = Array.from(new Set([...(existing.data.tags || []), tag]));
        const result = await this.contactRepository.update(ctx, id, { tags });
        return result.success
          ? { success: true }
          : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
      };
    }

    if (entityType === 'company') {
      return async (ctx, id, tag) => {
        const existing = await this.companyRepository.getById(ctx, id);
        if (!existing.success || !existing.data) {
          return { success: false, errorCode: 'not_found', errorMessage: 'Company not found' };
        }
        const tags = Array.from(new Set([...(existing.data.tags || []), tag]));
        const result = await this.companyRepository.update(ctx, id, { tags });
        return result.success
          ? { success: true }
          : { success: false, errorCode: 'action_failed', errorMessage: result.error?.message };
      };
    }

    return null;
  }

  private async logRun(
    context: SecurityContext,
    rule: AutomationRule,
    event: AutomationEvent,
    status: AutomationRunStatus,
    errorCode?: string,
    errorMessage?: string
  ): Promise<void> {
    const runPayload: Omit<AutomationRun, 'id' | 'createdAt' | 'updatedAt'> = {
      businessId: context.businessId,
      ruleId: rule.id,
      triggerType: rule.trigger.type,
      actionType: rule.action.type as AutomationActionType,
      target: rule.action.target,
      entityId: event.entityId,
      entityType: event.entityType,
      status,
      executedAt: new Date(),
      correlationId: event.correlationId || this.generateCorrelationId(),
      dryRun: event.dryRun ?? false,
      errorCode,
      errorMessage,
    };

    await this.runRepo.logRun(context, runPayload);
    await this.auditLogService.logAction(context, {
      action: 'automation',
      entityType: 'automationRun',
      entityId: runPayload.correlationId,
      entityName: rule.name,
      metadata: buildAuditMetadata(rule, event, status),
    });
  }

  private generateCorrelationId(): string {
    if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
      return crypto.randomUUID();
    }
    return `auto-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
  }
}

// Singleton accessor
let automationEngineInstance: AutomationEngine | null = null;

export function getAutomationEngine(): AutomationEngine {
  if (!automationEngineInstance) {
    automationEngineInstance = new AutomationEngine();
  }
  return automationEngineInstance;
}
