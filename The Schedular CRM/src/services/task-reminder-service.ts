/**
 * Task Reminder Service
 * Manages in-app notifications for task reminders and overdue tasks
 *
 * CRM-44 Implementation
 * Dependencies: CRM-13 (Activity/Timeline hooks)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { SalesActivity } from '../types/models';
import { getActivityService } from './activity-service';
import { dispatchAutomationEvent } from './automation-dispatcher';
import { getFeatureFlags } from '../config/features';
import { evaluateTaskSla, type TaskSlaStatus } from '../lib/tasks';
import { checkRateLimit, checkAndRecordRateLimit } from './RateLimitService';
import { getTaskTemplates } from '../config/taskTemplates';

// ============================================
// Types
// ============================================

export type ReminderType = 'upcoming' | 'due_today' | 'overdue';

export interface TaskReminder {
  id: string;
  taskId: string;
  taskTitle: string;
  entityType: 'lead' | 'deal' | 'contact' | 'company';
  entityId: string;
  entityName: string;
  dueDate: Date;
  reminderType: ReminderType;
  daysUntilDue: number; // Negative if overdue
  isRead: boolean;
  slaAt?: Date;
  reminderAt?: Date;
  templateId?: string;
  slaStatus?: TaskSlaStatus;
  createdAt: Date;
}

export interface ReminderServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// Local Storage Keys
// ============================================

const READ_REMINDERS_KEY = 'crm_read_reminders';
const DISMISSED_REMINDERS_KEY = 'crm_dismissed_reminders';
const OVERDUE_AUTOMATION_KEY = 'crm_overdue_automation_dispatched';
const REMINDER_AUTOMATION_KEY = 'crm_reminder_automation_dispatched';
const MAX_STORED_AUTOMATIONS = 200;

/**
 * Build a tenant-scoped localStorage key to avoid cross-business leakage.
 */
function buildStorageKey(base: string, userId: string, businessId?: string): string {
  return businessId ? `${base}_${businessId}_${userId}` : `${base}_${userId}`;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Calculate days until due date
 * Returns positive for upcoming, negative for overdue
 */
function calculateDaysUntilDue(dueDate: Date): number {
  const now = new Date();
  const due = new Date(dueDate);

  // Reset time to midnight for accurate day calculation
  now.setHours(0, 0, 0, 0);
  due.setHours(0, 0, 0, 0);

  const diffMs = due.getTime() - now.getTime();
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  return diffDays;
}

/**
 * Determine reminder type based on days until due
 */
function getReminderType(daysUntilDue: number): ReminderType {
  if (daysUntilDue < 0) {
    return 'overdue';
  } else if (daysUntilDue === 0) {
    return 'due_today';
  } else {
    return 'upcoming';
  }
}

/**
 * Extract entity information from activity
 */
function getEntityInfo(activity: SalesActivity): {
  entityType: 'lead' | 'deal' | 'contact' | 'company';
  entityId: string;
  entityName: string;
} | null {
  if (activity.dealId) {
    return {
      entityType: 'deal',
      entityId: activity.dealId,
      entityName: 'Deal', // Would be enhanced with actual deal title
    };
  }

  if (activity.clientId) {
    return {
      entityType: 'contact',
      entityId: activity.clientId,
      entityName: 'Contact', // Would be enhanced with actual client name
    };
  }

  if (activity.leadId) {
    return {
      entityType: 'lead',
      entityId: activity.leadId,
      entityName: 'Lead', // Would be enhanced with actual lead name
    };
  }

  if (activity.companyId) {
    return {
      entityType: 'company',
      entityId: activity.companyId,
      entityName: 'Company', // Would be enhanced with actual company name
    };
  }

  return null;
}

/**
 * Convert activity to reminder
 */
function activityToReminder(
  activity: SalesActivity,
  readReminderIds: Set<string>,
  dismissedReminderIds: Set<string>
): TaskReminder | null {
  const toDate = (value?: Date | { toDate?: () => Date } | null): Date | undefined => {
    if (!value) return undefined;
    if (value instanceof Date) return value;
    if (typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function') {
      return value.toDate();
    }
    const parsed = new Date(value as unknown as string);
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
  };

  if (!activity.dueDate && !activity.slaAt) {
    return null;
  }

  const entityInfo = getEntityInfo(activity);
  if (!entityInfo) {
    return null;
  }

  const effectiveDueDate = toDate(activity.dueDate) || toDate(activity.slaAt) || new Date();
  const daysUntilDue = calculateDaysUntilDue(effectiveDueDate);
  const reminderType = getReminderType(daysUntilDue);

  // Don't create reminders for dismissed tasks
  if (dismissedReminderIds.has(activity.id)) {
    return null;
  }

  const normalizedActivity: SalesActivity = {
    ...activity,
    dueDate: effectiveDueDate,
    slaAt: toDate(activity.slaAt),
    reminderAt: toDate(activity.reminderAt),
    createdAt: toDate(activity.createdAt) || new Date(),
  };

  const slaState = evaluateTaskSla(normalizedActivity);
  const template =
    normalizedActivity.templateId && normalizedActivity.type === 'task'
      ? getTaskTemplates().find((tpl) => tpl.id === normalizedActivity.templateId)
      : undefined;

  const computeReminderAtFromTemplate = () => {
    const target = normalizedActivity.slaAt || normalizedActivity.dueDate;
    if (!target) return undefined;
    const minutes =
      template?.reminderMinutesBefore ??
      template?.slaMinutes ??
      normalizedActivity.slaMinutes ??
      30;
    return new Date(target.getTime() - minutes * 60 * 1000);
  };

  const reminderAtRaw =
    normalizedActivity.reminderAt ||
    computeReminderAtFromTemplate() ||
    (normalizedActivity.slaAt
      ? new Date(normalizedActivity.slaAt.getTime() - 30 * 60 * 1000)
      : undefined) ||
    effectiveDueDate;
  const normalizedReminderAt =
    reminderAtRaw && reminderAtRaw.getTime() < Date.now()
      ? new Date()
      : reminderAtRaw;

  return {
    id: activity.id,
    taskId: activity.id,
    taskTitle: activity.title,
    entityType: entityInfo.entityType,
    entityId: entityInfo.entityId,
    entityName: entityInfo.entityName,
    dueDate: effectiveDueDate,
    reminderType,
    daysUntilDue,
    isRead: readReminderIds.has(activity.id),
    slaAt: normalizedActivity.slaAt,
    reminderAt: normalizedReminderAt,
    templateId: activity.templateId,
    slaStatus: slaState.status,
    createdAt: normalizedActivity.createdAt,
  };
}

/**
 * Get read reminder IDs from localStorage
 */
function getReadReminderIds(userId: string, businessId?: string): Set<string> {
  try {
    const key = buildStorageKey(READ_REMINDERS_KEY, userId, businessId);
    const stored = localStorage.getItem(key);
    if (!stored) return new Set();

    const data = JSON.parse(stored);
    return new Set(data);
  } catch (error) {
    console.error('Error reading read reminders from localStorage:', error);
    return new Set();
  }
}

/**
 * Get dismissed reminder IDs from localStorage
 */
function getDismissedReminderIds(userId: string, businessId?: string): Set<string> {
  try {
    const key = buildStorageKey(DISMISSED_REMINDERS_KEY, userId, businessId);
    const stored = localStorage.getItem(key);
    if (!stored) return new Set();

    const data = JSON.parse(stored);
    return new Set(data);
  } catch (error) {
    console.error('Error reading dismissed reminders from localStorage:', error);
    return new Set();
  }
}

/**
 * Save read reminder IDs to localStorage
 */
function saveReadReminderIds(userId: string, businessId: string | undefined, ids: Set<string>): void {
  try {
    const key = buildStorageKey(READ_REMINDERS_KEY, userId, businessId);
    const data = Array.from(ids);
    localStorage.setItem(key, JSON.stringify(data));
  } catch (error) {
    console.error('Error saving read reminders to localStorage:', error);
  }
}

/**
 * Save dismissed reminder IDs to localStorage
 */
function saveDismissedReminderIds(userId: string, businessId: string | undefined, ids: Set<string>): void {
  try {
    const key = buildStorageKey(DISMISSED_REMINDERS_KEY, userId, businessId);
    const data = Array.from(ids);
    localStorage.setItem(key, JSON.stringify(data));
  } catch (error) {
    console.error('Error saving dismissed reminders to localStorage:', error);
  }
}

/**
 * Track overdue automation dispatches to avoid re-triggering the same event.
 * Stores correlation IDs (taskId + dueDate) only—no PHI.
 */
function getOverdueAutomationIds(userId: string, businessId?: string): Set<string> {
  try {
    const key = buildStorageKey(OVERDUE_AUTOMATION_KEY, userId, businessId);
    const stored = localStorage.getItem(key);
    if (!stored) return new Set();
    const data = JSON.parse(stored);
    return new Set(Array.isArray(data) ? data : []);
  } catch (error) {
    console.error('Error reading overdue automation IDs from localStorage:', error);
    return new Set();
  }
}

function saveOverdueAutomationIds(userId: string, businessId: string | undefined, ids: Set<string>): void {
  try {
    const key = buildStorageKey(OVERDUE_AUTOMATION_KEY, userId, businessId);
    const ordered = Array.from(ids).slice(-MAX_STORED_AUTOMATIONS);
    localStorage.setItem(key, JSON.stringify(ordered));
  } catch (error) {
    console.error('Error saving overdue automation IDs to localStorage:', error);
  }
}

function buildOverdueCorrelationId(reminder: TaskReminder): string {
  const date = reminder.dueDate instanceof Date ? reminder.dueDate : new Date(reminder.dueDate);
  const datePart = Number.isFinite(date.getTime()) ? date.toISOString().slice(0, 10) : 'unknown';
  return `overdue-${reminder.taskId}-${datePart}`;
}

function getReminderAutomationIds(userId: string, businessId?: string): Set<string> {
  try {
    const key = buildStorageKey(REMINDER_AUTOMATION_KEY, userId, businessId);
    const stored = localStorage.getItem(key);
    if (!stored) return new Set();
    const data = JSON.parse(stored);
    return new Set(Array.isArray(data) ? data : []);
  } catch (error) {
    console.error('Error reading reminder automation IDs from localStorage:', error);
    return new Set();
  }
}

function saveReminderAutomationIds(userId: string, businessId: string | undefined, ids: Set<string>): void {
  try {
    const key = buildStorageKey(REMINDER_AUTOMATION_KEY, userId, businessId);
    const ordered = Array.from(ids).slice(-MAX_STORED_AUTOMATIONS);
    localStorage.setItem(key, JSON.stringify(ordered));
  } catch (error) {
    console.error('Error saving reminder automation IDs to localStorage:', error);
  }
}

function buildReminderCorrelationId(reminder: TaskReminder): string {
  const base = reminder.reminderAt instanceof Date ? reminder.reminderAt : reminder.slaAt || reminder.dueDate;
  const datePart = base ? new Date(base).toISOString() : 'unknown';
  return `reminder-${reminder.taskId}-${datePart}`;
}

function buildSnoozeCorrelationId(reminder: TaskReminder, nextReminderAt?: Date): string {
  const datePart = nextReminderAt ? nextReminderAt.toISOString() : new Date().toISOString();
  return `snooze-${reminder.taskId}-${datePart}`;
}

// ============================================
// Task Reminder Service
// ============================================

export class TaskReminderService {
  /**
   * Get all reminders for a user
   */
  async getReminders(
    context: SecurityContext
  ): Promise<ReminderServiceResult<TaskReminder[]>> {
    const activityService = getActivityService();

    // Get all pending tasks
    const result = await activityService.getPendingTasks(context);

    if (!result.success || !result.data) {
      return {
        success: false,
        error: {
          code: result.error?.code || 'FETCH_ERROR',
          message: result.error?.message || 'Failed to fetch tasks',
        },
      };
    }

    const readIds = getReadReminderIds(context.userId, context.businessId);
    const dismissedIds = getDismissedReminderIds(context.userId, context.businessId);

    // Convert activities to reminders
    const reminders: TaskReminder[] = [];
    for (const activity of result.data) {
      const reminder = activityToReminder(activity, readIds, dismissedIds);
      if (reminder) {
        reminders.push(reminder);
      }
    }

    // Sort by due date (most urgent first)
    reminders.sort((a, b) => {
      return a.dueDate.getTime() - b.dueDate.getTime();
    });

    await this.dispatchOverdueAutomations(context, reminders);
    await this.dispatchReminderAutomations(context, reminders);

    return {
      success: true,
      data: reminders,
    };
  }

  /**
   * Get upcoming tasks (due in next N days)
   */
  async getUpcomingTasks(
    context: SecurityContext,
    days: number
  ): Promise<ReminderServiceResult<TaskReminder[]>> {
    const activityService = getActivityService();

    const result = await activityService.getUpcomingTasks(context, days);

    if (!result.success || !result.data) {
      return {
        success: false,
        error: {
          code: result.error?.code || 'FETCH_ERROR',
          message: result.error?.message || 'Failed to fetch upcoming tasks',
        },
      };
    }

    const readIds = getReadReminderIds(context.userId, context.businessId);
    const dismissedIds = getDismissedReminderIds(context.userId, context.businessId);

    const reminders: TaskReminder[] = [];
    for (const activity of result.data) {
      const reminder = activityToReminder(activity, readIds, dismissedIds);
      if (reminder && reminder.reminderType === 'upcoming') {
        reminders.push(reminder);
      }
    }

    return {
      success: true,
      data: reminders,
    };
  }

  /**
   * Get overdue tasks
   */
  async getOverdueTasks(
    context: SecurityContext
  ): Promise<ReminderServiceResult<TaskReminder[]>> {
    const activityService = getActivityService();

    const result = await activityService.getOverdueTasks(context);

    if (!result.success || !result.data) {
      return {
        success: false,
        error: {
          code: result.error?.code || 'FETCH_ERROR',
          message: result.error?.message || 'Failed to fetch overdue tasks',
        },
      };
    }

    const readIds = getReadReminderIds(context.userId, context.businessId);
    const dismissedIds = getDismissedReminderIds(context.userId, context.businessId);

    const reminders: TaskReminder[] = [];
    for (const activity of result.data) {
      const reminder = activityToReminder(activity, readIds, dismissedIds);
      if (reminder && reminder.reminderType === 'overdue') {
        reminders.push(reminder);
      }
    }

    await this.dispatchOverdueAutomations(context, reminders);

    return {
      success: true,
      data: reminders,
    };
  }

  /**
   * Snooze a reminder by shifting due/SLA/reminder windows forward.
   * Rate-limited to avoid runaway updates; dispatches automation event for audit parity.
   */
  async snoozeReminder(
    context: SecurityContext,
    reminder: TaskReminder,
    snoozeMs: number = 24 * 60 * 60 * 1000
  ): Promise<ReminderServiceResult<TaskReminder>> {
    if (!context.businessId || !context.userId) {
      return {
        success: false,
        error: { code: 'AUTH', message: 'Missing tenant context for snooze' },
      };
    }

    const limit = await checkAndRecordRateLimit('automation', context);
    if (!limit.allowed) {
      return {
        success: false,
        error: { code: 'RATE_LIMITED', message: limit.message || 'Rate limit exceeded' },
      };
    }

    const now = Date.now();
    const baseDue = reminder.dueDate instanceof Date ? reminder.dueDate.getTime() : new Date(reminder.dueDate).getTime();
    const baseReminder = reminder.reminderAt ? reminder.reminderAt.getTime() : baseDue;
    const baseSla = reminder.slaAt ? reminder.slaAt.getTime() : undefined;

    const nextDueDate = new Date((Number.isFinite(baseDue) ? baseDue : now) + snoozeMs);
    const nextReminderAtRaw = baseReminder ? new Date(baseReminder + snoozeMs) : new Date(now + snoozeMs);
    const nextReminderAt =
      nextReminderAtRaw.getTime() < now + 15 * 60 * 1000
        ? new Date(now + 15 * 60 * 1000)
        : nextReminderAtRaw;
    const nextSlaAt = baseSla ? new Date(baseSla + snoozeMs) : undefined;

    const activityService = getActivityService();
    const updateResult = await activityService.updateActivity(
      context,
      reminder.taskId,
      {
        dueDate: nextDueDate,
        reminderAt: nextReminderAt,
        slaAt: nextSlaAt,
      }
    );

    if (!updateResult.success) {
      return {
        success: false,
        error: {
          code: updateResult.error?.code || 'UPDATE_FAILED',
          message: updateResult.error?.message || 'Failed to snooze task',
        },
      };
    }

    // Fire-and-forget audit/automation hook; backend should enforce RBAC and audit logs
    try {
      await dispatchAutomationEvent({
        triggerType: 'taskSnoozed',
        entityId: reminder.taskId,
        entityType: 'activity',
        businessId: context.businessId,
        correlationId: buildSnoozeCorrelationId(reminder, nextReminderAt),
        relatedEntityId: reminder.entityId,
        relatedEntityType: reminder.entityType,
      });
    } catch {
      // intentionally swallow errors to avoid blocking UI; backend will have its own audit
    }

    return {
      success: true,
      data: {
        ...reminder,
        dueDate: nextDueDate,
        reminderAt: nextReminderAt,
        slaAt: nextSlaAt,
      },
    };
  }

  /**
   * Dispatch automation events for overdue tasks without blocking the UI.
   * Correlation IDs are deterministic to avoid duplicate runs.
   */
  private async dispatchOverdueAutomations(
    context: SecurityContext,
    reminders: TaskReminder[]
  ): Promise<void> {
    const features = getFeatureFlags();
    if (!features.enableAutomation) return;
    if (!context.businessId || !context.userId) return;

    const overdueReminders = reminders.filter((reminder) => reminder.reminderType === 'overdue');
    if (overdueReminders.length === 0) return;

    const initialLimit = await checkRateLimit('automation', context);
    if (!initialLimit.allowed) return;

    const dispatchedIds = getOverdueAutomationIds(context.userId, context.businessId);

    await Promise.all(
      overdueReminders.map(async (reminder) => {
        const correlationId = buildOverdueCorrelationId(reminder);
        if (dispatchedIds.has(correlationId)) return;

        try {
          const limitCheck = await checkAndRecordRateLimit('automation', context);
          if (!limitCheck.allowed) return;
          const overdueDays = Math.abs(Math.min(reminder.daysUntilDue, 0));
          await dispatchAutomationEvent({
            triggerType: 'taskOverdue',
            entityId: reminder.taskId,
            entityType: 'activity',
            businessId: context.businessId,
            correlationId,
            overdueDays,
            relatedEntityId: reminder.entityId,
            relatedEntityType: reminder.entityType,
          });
          dispatchedIds.add(correlationId);
        } catch (error) {
          // Soft-fail; avoid surfacing automation dispatch failures to end users
          console.warn('Automation dispatch failed for overdue task');
        }
      })
    );

    saveOverdueAutomationIds(context.userId, context.businessId, dispatchedIds);
  }

  /**
   * Dispatch reminder hooks (email/calendar via automation worker) when reminderAt has passed.
   */
  private async dispatchReminderAutomations(
    context: SecurityContext,
    reminders: TaskReminder[]
  ): Promise<void> {
    const features = getFeatureFlags();
    if (!features.enableAutomation) return;
    if (!context.businessId || !context.userId) return;

    const ready = reminders.filter(
      (reminder) =>
        reminder.reminderAt &&
        reminder.reminderAt.getTime() <= Date.now() &&
        reminder.reminderType !== 'overdue'
    );
    if (ready.length === 0) return;

    const dispatchedIds = getReminderAutomationIds(context.userId, context.businessId);

    for (const reminder of ready) {
      const correlationId = buildReminderCorrelationId(reminder);
      if (dispatchedIds.has(correlationId)) continue;

      const limitCheck = await checkAndRecordRateLimit('automation', context);
      if (!limitCheck.allowed) break;

      try {
        await dispatchAutomationEvent({
          triggerType: 'taskReminder',
          entityId: reminder.taskId,
          entityType: 'activity',
          businessId: context.businessId,
          correlationId,
          reminderType: reminder.reminderType,
          relatedEntityId: reminder.entityId,
          relatedEntityType: reminder.entityType,
        });
        dispatchedIds.add(correlationId);
      } catch (error) {
        // Soft-fail; avoid surfacing automation dispatch failures to end users
        console.warn('Automation dispatch failed for reminders');
      }
    }

    saveReminderAutomationIds(context.userId, context.businessId, dispatchedIds);
  }

  /**
   * Mark a reminder as read
   */
  markAsRead(
    userId: string,
    businessId: string | undefined,
    reminderId: string
  ): ReminderServiceResult<void> {
    try {
      const readIds = getReadReminderIds(userId, businessId);
      readIds.add(reminderId);
      saveReadReminderIds(userId, businessId, readIds);

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MARK_READ_ERROR',
          message: error instanceof Error ? error.message : 'Failed to mark as read',
        },
      };
    }
  }

  /**
   * Mark multiple reminders as read
   */
  markMultipleAsRead(
    userId: string,
    businessId: string | undefined,
    reminderIds: string[]
  ): ReminderServiceResult<void> {
    try {
      const readIds = getReadReminderIds(userId, businessId);
      reminderIds.forEach(id => readIds.add(id));
      saveReadReminderIds(userId, businessId, readIds);

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MARK_READ_ERROR',
          message: error instanceof Error ? error.message : 'Failed to mark as read',
        },
      };
    }
  }

  /**
   * Dismiss a reminder
   */
  dismissReminder(
    userId: string,
    businessId: string | undefined,
    reminderId: string
  ): ReminderServiceResult<void> {
    try {
      const dismissedIds = getDismissedReminderIds(userId, businessId);
      dismissedIds.add(reminderId);
      saveDismissedReminderIds(userId, businessId, dismissedIds);

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'DISMISS_ERROR',
          message: error instanceof Error ? error.message : 'Failed to dismiss reminder',
        },
      };
    }
  }

  /**
   * Clear all dismissed reminders
   */
  clearDismissed(userId: string, businessId: string | undefined): ReminderServiceResult<void> {
    try {
      const key = buildStorageKey(DISMISSED_REMINDERS_KEY, userId, businessId);
      localStorage.removeItem(key);

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CLEAR_ERROR',
          message: error instanceof Error ? error.message : 'Failed to clear dismissed reminders',
        },
      };
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let taskReminderServiceInstance: TaskReminderService | null = null;

export function getTaskReminderService(): TaskReminderService {
  if (!taskReminderServiceInstance) {
    taskReminderServiceInstance = new TaskReminderService();
  }
  return taskReminderServiceInstance;
}
