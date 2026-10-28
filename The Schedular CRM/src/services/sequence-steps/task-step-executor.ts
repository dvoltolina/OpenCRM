/**
 * Task Step Executor
 * Creates tasks (sales_activities) for sequence steps
 *
 * HIPAA Compliance:
 * - No PHI in logs
 * - Tasks created via activity service with proper RBAC
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { StepExecutionResult, ExecutorContext } from './types';
import { getActivityService } from '../activity-service';

// ============================================
// Task Step Executor
// ============================================

export class TaskStepExecutor {
  private activityService = getActivityService();

  /**
   * Execute a task step.
   */
  async execute(context: ExecutorContext): Promise<StepExecutionResult> {
    const { securityContext, enrollment, step, sequence } = context;

    // 1. Validate task configuration
    if (!step.taskConfig) {
      return {
        success: false,
        errorCode: 'MISSING_CONFIG',
        errorMessage: 'Task step is missing task configuration',
      };
    }

    // 2. Validate required fields
    if (!step.taskConfig.title) {
      return {
        success: false,
        errorCode: 'MISSING_TITLE',
        errorMessage: 'Task step must have a title',
      };
    }

    // 3. Determine assignee
    // If assignToOwner is true, use sequence owner; otherwise use entity owner
    const assigneeId = step.taskConfig.assignToOwner
      ? sequence.ownerId
      : enrollment.ownerId;
    const assigneeName = step.taskConfig.assignToOwner
      ? sequence.ownerName
      : enrollment.ownerName;

    // 4. Calculate due date
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + (step.taskConfig.dueDays || 0));

    // 5. Determine entity link based on enrollment type
    const entityField = this.getEntityField(enrollment.entityType);

    // 6. Create the task via activity service
    const result = await this.activityService.createTask(securityContext, {
      type: 'task',
      title: step.taskConfig.title,
      description: step.taskConfig.description || this.buildDefaultDescription(enrollment, sequence),
      dueDate,
      assigneeId,
      assigneeName,
      [entityField]: enrollment.entityId,
    });

    if (!result.success) {
      return {
        success: false,
        errorCode: result.error?.code || 'CREATE_FAILED',
        errorMessage: result.error?.message || 'Failed to create task',
      };
    }

    return {
      success: true,
      taskId: result.data?.id,
    };
  }

  /**
   * Get the entity field name for linking the task.
   */
  private getEntityField(entityType: string): string {
    switch (entityType) {
      case 'lead':
        return 'leadId';
      case 'client':
        return 'clientId';
      case 'deal':
        return 'dealId';
      default:
        return 'clientId';
    }
  }

  /**
   * Build default description for the task.
   */
  private buildDefaultDescription(
    enrollment: { entityName: string; sequenceName: string },
    sequence: { name: string }
  ): string {
    return `Task created from sequence "${sequence.name}" for ${enrollment.entityName}`;
  }
}

// ============================================
// Singleton Instance
// ============================================

let executorInstance: TaskStepExecutor | null = null;

export function getTaskStepExecutor(): TaskStepExecutor {
  if (!executorInstance) {
    executorInstance = new TaskStepExecutor();
  }
  return executorInstance;
}
