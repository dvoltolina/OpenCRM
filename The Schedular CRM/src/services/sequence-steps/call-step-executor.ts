/**
 * Call Step Executor
 * Creates call reminder tasks for sequence steps
 *
 * Call steps create a task with call-specific metadata
 * (script, notes) that the assignee should complete.
 *
 * HIPAA Compliance:
 * - No PHI in logs
 * - Call notes stored in task description
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { StepExecutionResult, ExecutorContext } from './types';
import { getActivityService } from '../activity-service';

// ============================================
// Call Step Executor
// ============================================

export class CallStepExecutor {
  private activityService = getActivityService();

  /**
   * Execute a call step.
   * Creates a call task for the assignee.
   */
  async execute(context: ExecutorContext): Promise<StepExecutionResult> {
    const { securityContext, enrollment, step, sequence } = context;

    // 1. Validate call configuration
    if (!step.callConfig) {
      return {
        success: false,
        errorCode: 'MISSING_CONFIG',
        errorMessage: 'Call step is missing call configuration',
      };
    }

    // 2. Validate required fields
    if (!step.callConfig.title) {
      return {
        success: false,
        errorCode: 'MISSING_TITLE',
        errorMessage: 'Call step must have a title',
      };
    }

    // 3. Determine assignee (typically the sequence owner)
    const assigneeId = sequence.ownerId;
    const assigneeName = sequence.ownerName;

    // 4. Calculate due date (same day by default for calls)
    const dueDate = new Date();

    // 5. Build task description with call notes/script
    const description = this.buildCallDescription(enrollment, step.callConfig);

    // 6. Determine entity link based on enrollment type
    const entityField = this.getEntityField(enrollment.entityType);

    // 7. Create the call task via activity service
    const result = await this.activityService.createTask(securityContext, {
      type: 'task',
      title: step.callConfig.title,
      description,
      dueDate,
      assigneeId,
      assigneeName,
      [entityField]: enrollment.entityId,
    });

    if (!result.success) {
      return {
        success: false,
        errorCode: result.error?.code || 'CREATE_FAILED',
        errorMessage: result.error?.message || 'Failed to create call task',
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
   * Build call task description with notes/script.
   */
  private buildCallDescription(
    enrollment: { entityName: string; entityEmail: string; sequenceName: string },
    callConfig: { title: string; notes?: string }
  ): string {
    const lines: string[] = [
      `Call ${enrollment.entityName}`,
      `Email: ${enrollment.entityEmail}`,
      `Sequence: ${enrollment.sequenceName}`,
    ];

    if (callConfig.notes) {
      lines.push('');
      lines.push('Call Notes/Script:');
      lines.push(callConfig.notes);
    }

    return lines.join('\n');
  }
}

// ============================================
// Singleton Instance
// ============================================

let executorInstance: CallStepExecutor | null = null;

export function getCallStepExecutor(): CallStepExecutor {
  if (!executorInstance) {
    executorInstance = new CallStepExecutor();
  }
  return executorInstance;
}
