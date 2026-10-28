/**
 * Activity Logging Service
 * Unified API for logging all types of sales activities
 *
 * Agent CRM-13 Implementation
 * Dependencies: Agent CRM-06 (activities repository)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { getActivityRepository, type EntityType } from '../data/repositories/activity-repository';
import { hasManagerTeamAccess } from '../data/repositories/access-control';
import { sanitizeTeamIds } from '../lib/security-context';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { SalesActivity, SalesActivityType } from '../types/models';

// ============================================
// Types
// ============================================

export interface LogActivityOptions {
  type: SalesActivityType;
  title: string;
  description?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  dueDate?: Date;
  assigneeId?: string;
  assigneeName?: string;
  templateId?: string;
  slaMinutes?: number;
  slaAt?: Date;
  reminderAt?: Date;
}

export interface TaskOptions extends LogActivityOptions {
  type: 'task';
  dueDate: Date; // Required for tasks
}

export interface QuickLogOptions {
  notes: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
}

export interface TimelineEntry extends SalesActivity {
  entityType: EntityType;
}

export interface ActivityServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// Re-export EntityType for convenience
export type { EntityType };

// ============================================
// Activity Service
// ============================================

export class ActivityService {
  /**
   * Log a generic activity with all options
   */
  async logActivity(
    context: SecurityContext,
    options: LogActivityOptions
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const activityRepo = getActivityRepository();

    // Validate at least one entity is linked
    const hasEntity = options.dealId || options.clientId || options.leadId || options.companyId;
    if (!hasEntity) {
      return {
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Activity must be linked to at least one entity (deal, client, lead, or company)',
        },
      };
    }

    const activityData = {
      type: options.type,
      title: options.title,
      description: options.description,
      dealId: options.dealId,
      clientId: options.clientId,
      leadId: options.leadId,
      companyId: options.companyId,
      dueDate: options.dueDate,
      assigneeId: options.assigneeId,
      assigneeName: options.assigneeName,
      templateId: options.templateId,
      slaMinutes: options.slaMinutes,
      slaAt: options.slaAt,
      reminderAt: options.reminderAt,
      createdById: context.userId,
      createdByName: context.userName || 'Unknown User',
      isCompleted: false,
    };

    const result = await activityRepo.create(context, activityData);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Quick log a call
   */
  async logCall(
    context: SecurityContext,
    entityId: string,
    entityType: EntityType,
    notes: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const entityField = this.getEntityField(entityType);

    return this.logActivity(context, {
      type: 'call',
      title: 'Phone Call',
      description: notes,
      [entityField]: entityId,
    });
  }

  /**
   * Quick log an email
   */
  async logEmail(
    context: SecurityContext,
    entityId: string,
    entityType: EntityType,
    subject: string,
    notes?: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const entityField = this.getEntityField(entityType);

    return this.logActivity(context, {
      type: 'email',
      title: subject,
      description: notes,
      [entityField]: entityId,
    });
  }

  /**
   * Quick log a meeting
   */
  async logMeeting(
    context: SecurityContext,
    entityId: string,
    entityType: EntityType,
    notes: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const entityField = this.getEntityField(entityType);

    return this.logActivity(context, {
      type: 'meeting',
      title: 'Meeting',
      description: notes,
      [entityField]: entityId,
    });
  }

  /**
   * Quick log a note
   */
  async logNote(
    context: SecurityContext,
    entityId: string,
    entityType: EntityType,
    note: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const entityField = this.getEntityField(entityType);

    return this.logActivity(context, {
      type: 'note',
      title: 'Note',
      description: note,
      [entityField]: entityId,
    });
  }

  /**
   * Create a task with required due date
   */
  async createTask(
    context: SecurityContext,
    options: TaskOptions
  ): Promise<ActivityServiceResult<SalesActivity>> {
    // Validate dueDate is provided
    if (!options.dueDate) {
      return {
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Due date is required for tasks',
        },
      };
    }

    // Validate at least one entity is linked
    const hasEntity = options.dealId || options.clientId || options.leadId || options.companyId;
    if (!hasEntity) {
      return {
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Task must be linked to at least one entity',
        },
      };
    }

    const activityRepo = getActivityRepository();

    const taskData = {
      type: 'task' as const,
      title: options.title,
      description: options.description,
      dealId: options.dealId,
      clientId: options.clientId,
      leadId: options.leadId,
      companyId: options.companyId,
      dueDate: options.dueDate,
      assigneeId: options.assigneeId,
      assigneeName: options.assigneeName,
      templateId: options.templateId,
      slaMinutes: options.slaMinutes,
      slaAt: options.slaAt,
      reminderAt: options.reminderAt,
      createdById: context.userId,
      createdByName: context.userName || 'Unknown User',
      isCompleted: false,
    };

    const result = await activityRepo.create(context, taskData);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Mark a task as completed
   * RBAC: Only creator, assignee, or admin/owner can complete
   */
  async completeTask(
    context: SecurityContext,
    activityId: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const activityRepo = getActivityRepository();

    // Fetch existing activity to check permissions
    const existing = await activityRepo.getById(context, activityId);
    if (!existing.success) {
      return {
        success: false,
        error: existing.error,
      };
    }

    // RBAC: creator, assignee, or admin can complete
    const isCreator = existing.data.createdById === context.userId;
    const isAssignee = existing.data.assigneeId === context.userId;
    const isAdmin = context.userRole === 'admin' || context.userRole === 'owner';

    if (!isCreator && !isAssignee && !isAdmin) {
      return {
        success: false,
        error: {
          code: 'PERMISSION_DENIED',
          message: 'You do not have permission to complete this task',
        },
      };
    }

    const result = await activityRepo.markComplete(context, activityId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Mark a task as incomplete
   * RBAC: Only creator, assignee, or admin/owner can uncomplete
   */
  async uncompleteTask(
    context: SecurityContext,
    activityId: string
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const activityRepo = getActivityRepository();

    // Fetch existing activity to check permissions
    const existing = await activityRepo.getById(context, activityId);
    if (!existing.success) {
      return {
        success: false,
        error: existing.error,
      };
    }

    // RBAC: creator, assignee, or admin can uncomplete
    const isCreator = existing.data.createdById === context.userId;
    const isAssignee = existing.data.assigneeId === context.userId;
    const isAdmin = context.userRole === 'admin' || context.userRole === 'owner';

    if (!isCreator && !isAssignee && !isAdmin) {
      return {
        success: false,
        error: {
          code: 'PERMISSION_DENIED',
          message: 'You do not have permission to uncomplete this task',
        },
      };
    }

    const result = await activityRepo.markIncomplete(context, activityId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Get chronological timeline for a specific entity
   */
  async getEntityTimeline(
    context: SecurityContext,
    entityType: EntityType,
    entityId: string,
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getTimeline(context, entityType, entityId, {
      limit,
      orderBy: { field: 'createdAt', direction: 'desc' },
    });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get unified timeline across multiple related entities
   * Useful for showing all activities for a deal AND its client
   */
  async getUnifiedTimeline(
    context: SecurityContext,
    params: {
      dealId?: string;
      clientId?: string;
      companyId?: string;
      leadId?: string;
    },
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getUnifiedTimeline(context, params, { limit });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get pending tasks for a user
   */
  async getPendingTasks(
    context: SecurityContext,
    assigneeId?: string,
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getPendingTasks(context, assigneeId, { limit });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get overdue tasks
   */
  async getOverdueTasks(
    context: SecurityContext,
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getOverdueTasks(context, { limit });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get upcoming tasks (due within N days)
   */
  async getUpcomingTasks(
    context: SecurityContext,
    days: number,
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getUpcomingTasks(context, days, { limit });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get recent activities (last N days)
   */
  async getRecentActivities(
    context: SecurityContext,
    days: number = 7,
    limit?: number
  ): Promise<ActivityServiceResult<SalesActivity[]>> {
    const activityRepo = getActivityRepository();

    const result = await activityRepo.getRecent(context, days, { limit });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Update an activity
   * RBAC: Only creator or admin/owner can edit
   */
  async updateActivity(
    context: SecurityContext,
    activityId: string,
    updates: Partial<Pick<SalesActivity, 'title' | 'description' | 'dueDate' | 'assigneeId' | 'assigneeName' | 'teamIds' | 'templateId' | 'slaMinutes' | 'slaAt' | 'reminderAt'>>
  ): Promise<ActivityServiceResult<SalesActivity>> {
    const activityRepo = getActivityRepository();

    // Fetch existing activity to check permissions
    const existing = await activityRepo.getById(context, activityId);
    if (!existing.success) {
      return {
        success: false,
        error: existing.error,
      };
    }

    // RBAC: creator, admin/owner, or manager with team access can edit
    const isCreator = existing.data.createdById === context.userId;
    const isAdmin = context.userRole === 'admin' || context.userRole === 'owner';
    const isManagerWithAccess = hasManagerTeamAccess(context, existing.data.teamIds);

    if (!isCreator && !isAdmin && !isManagerWithAccess) {
      return {
        success: false,
        error: {
          code: 'PERMISSION_DENIED',
          message: 'You do not have permission to update this activity',
        },
      };
    }

    const result = await activityRepo.update(context, activityId, {
      ...updates,
      teamIds: updates.teamIds ? sanitizeTeamIds(updates.teamIds) : updates.teamIds,
    });

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Delete an activity
   * RBAC: Only admin/owner can delete activities
   */
  async deleteActivity(
    context: SecurityContext,
    activityId: string
  ): Promise<ActivityServiceResult<void>> {
    // RBAC: Only admin/owner can delete activities
    const isAdmin = context.userRole === 'admin' || context.userRole === 'owner';

    if (!isAdmin) {
      return {
        success: false,
        error: {
          code: 'PERMISSION_DENIED',
          message: 'Only administrators can delete activities',
        },
      };
    }

    const activityRepo = getActivityRepository();

    const result = await activityRepo.delete(context, activityId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
    };
  }

  // ============================================
  // Private Helpers
  // ============================================

  /**
   * Get the field name for an entity type
   */
  private getEntityField(entityType: EntityType): string {
    const fieldMap: Record<EntityType, string> = {
      deal: 'dealId',
      client: 'clientId',
      lead: 'leadId',
      company: 'companyId',
    };
    return fieldMap[entityType];
  }
}

// ============================================
// Singleton Instance
// ============================================

let activityServiceInstance: ActivityService | null = null;

export function getActivityService(): ActivityService {
  if (!activityServiceInstance) {
    activityServiceInstance = new ActivityService();
  }
  return activityServiceInstance;
}
