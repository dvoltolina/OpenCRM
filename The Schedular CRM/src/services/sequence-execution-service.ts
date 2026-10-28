/**
 * Sequence Execution Service
 * Core execution engine for processing sequence steps
 *
 * HIPAA Compliance:
 * - No PHI in logs (entity IDs only)
 * - All actions audited
 * - Rate limits enforced
 * - Idempotency prevents duplicate actions
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type {
  SequenceEnrollment,
  ExecutionResult,
  SequenceStepType,
} from '../types/sequences';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { getSequenceExecutionRepository } from '../data/repositories/sequence-execution-repository';
import { getAuditLogService } from './AuditLogService';
import { getSequenceScheduler, getNextRetryTime } from './sequence-scheduler';
import {
  getEmailStepExecutor,
  getTaskStepExecutor,
  getWaitStepExecutor,
  getCallStepExecutor,
  getSmsStepExecutor,
  type ExecutorContext,
  type StepExecutionResult,
} from './sequence-steps';

// ============================================
// Types
// ============================================

export interface ProcessingResult {
  processed: number;
  succeeded: number;
  failed: number;
  skipped: number;
  errors: { executionId: string; error: string }[];
}

export interface RetryPolicy {
  maxAttempts: number;
  initialDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
}

// ============================================
// Constants
// ============================================

const DEFAULT_RETRY_POLICY: RetryPolicy = {
  maxAttempts: 3,
  initialDelayMs: 60000, // 1 minute
  maxDelayMs: 3600000, // 1 hour
  backoffMultiplier: 2,
};

// ============================================
// Sequence Execution Service
// ============================================

export class SequenceExecutionService {
  private sequenceRepo = getSequenceRepository();
  private enrollmentRepo = getSequenceEnrollmentRepository();
  private executionRepo = getSequenceExecutionRepository();
  private auditService = getAuditLogService();
  private scheduler = getSequenceScheduler();

  private retryPolicy: RetryPolicy;

  constructor(retryPolicy?: Partial<RetryPolicy>) {
    this.retryPolicy = { ...DEFAULT_RETRY_POLICY, ...retryPolicy };
  }

  // ============================================
  // Main Processing Methods
  // ============================================

  /**
   * Process all enrollments with steps due for execution.
   * Called by scheduled Cloud Function every 5-15 minutes.
   */
  async processScheduledSteps(context: SecurityContext): Promise<ProcessingResult> {
    const result: ProcessingResult = {
      processed: 0,
      succeeded: 0,
      failed: 0,
      skipped: 0,
      errors: [],
    };

    try {
      // 1. Get pending executions that are due
      const now = new Date();
      const pendingResult = await this.executionRepo.getPending(context, now);

      if (!pendingResult.success || !pendingResult.data) {
        return result;
      }

      const pendingExecutions = pendingResult.data;
      result.processed = pendingExecutions.length;

      // 2. Process each execution
      for (const execution of pendingExecutions) {
        try {
          const execResult = await this.executeStep(context, execution.id);

          if (execResult.success) {
            // Check if this was a skip (skipped steps still have success: true)
            if (execResult.errorMessage?.startsWith('Skipped')) {
              result.skipped++;
            } else {
              result.succeeded++;
            }
          } else {
            result.failed++;
            result.errors.push({
              executionId: execution.id,
              error: execResult.errorMessage || 'Unknown error',
            });
          }
        } catch (error) {
          result.failed++;
          result.errors.push({
            executionId: execution.id,
            error: error instanceof Error ? error.message : 'Unknown error',
          });
        }
      }

      // 3. Audit log the processing run
      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'activity',
        entityId: 'sequence_processing',
        metadata: {
          action: 'processScheduledSteps',
          processed: result.processed,
          succeeded: result.succeeded,
          failed: result.failed,
          skipped: result.skipped,
        },
      });
    } catch (error) {
      // Log error but don't throw - processing should be resilient
    }

    return result;
  }

  /**
   * Schedule the next step for an enrollment.
   * Called after step completion or on initial enrollment.
   */
  async scheduleNextStep(context: SecurityContext, enrollmentId: string): Promise<void> {
    // 1. Get enrollment
    const enrollmentResult = await this.enrollmentRepo.getById(context, enrollmentId);
    if (!enrollmentResult.success || !enrollmentResult.data) {
      return;
    }
    const enrollment = enrollmentResult.data;

    // 2. Check enrollment is still active
    if (enrollment.status !== 'active') {
      return;
    }

    // 3. Get sequence
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return;
    }
    const sequence = sequenceResult.data;

    // 4. Check sequence is still active
    if (sequence.status !== 'active') {
      // Pause enrollment if sequence is paused/archived
      await this.enrollmentRepo.pause(context, enrollmentId, 'Sequence is not active');
      return;
    }

    // 5. Find next active step
    const nextStepIndex = enrollment.currentStepIndex + 1;
    const nextStep = sequence.steps.find(
      (s, idx) => idx >= nextStepIndex && s.isActive
    );

    // 6. If no more steps, complete enrollment
    if (!nextStep) {
      await this.enrollmentRepo.complete(context, enrollmentId);
      await this.sequenceRepo.incrementStat(context, sequence.id, 'completedCount');
      return;
    }

    // 7. Calculate scheduled time
    const now = new Date();
    const scheduleResult = this.scheduler.calculateNextStepTime(now, nextStep, sequence.settings);

    // 8. Create execution record with idempotency
    const idempotencyKey = `${enrollmentId}:${nextStep.id}`;
    await this.executionRepo.createWithIdempotency(context, {
      enrollmentId,
      sequenceId: sequence.id,
      stepId: nextStep.id,
      stepIndex: sequence.steps.indexOf(nextStep),
      stepType: nextStep.type,
      status: 'scheduled',
      scheduledAt: scheduleResult.scheduledAt,
      idempotencyKey,
    });

    // 9. Update enrollment progress
    await this.enrollmentRepo.updateProgress(
      context,
      enrollmentId,
      sequence.steps.indexOf(nextStep),
      scheduleResult.scheduledAt,
      enrollment.stepsCompleted
    );
  }

  /**
   * Execute a specific step for an enrollment.
   * Handles idempotency, rate limiting, and error handling.
   */
  async executeStep(
    context: SecurityContext,
    executionId: string
  ): Promise<ExecutionResult> {
    // 1. Get execution record
    const executionResult = await this.executionRepo.getById(context, executionId);
    if (!executionResult.success || !executionResult.data) {
      return {
        success: false,
        errorCode: 'EXECUTION_NOT_FOUND',
        errorMessage: 'Execution record not found',
      };
    }
    const execution = executionResult.data;

    // 2. Check if already executed (idempotency)
    if (execution.status === 'completed' || execution.status === 'skipped') {
      return {
        success: true,
        ...execution.result,
      };
    }

    // 3. Get enrollment
    const enrollmentResult = await this.enrollmentRepo.getById(context, execution.enrollmentId);
    if (!enrollmentResult.success || !enrollmentResult.data) {
      await this.executionRepo.markSkipped(context, executionId, 'Enrollment not found');
      return {
        success: false,
        errorCode: 'ENROLLMENT_NOT_FOUND',
        errorMessage: 'Enrollment not found',
      };
    }
    const enrollment = enrollmentResult.data;

    // 4. Check enrollment status
    if (enrollment.status !== 'active') {
      await this.executionRepo.markSkipped(context, executionId, `Enrollment status: ${enrollment.status}`);
      return {
        success: true,
        errorMessage: `Skipped - enrollment is ${enrollment.status}`,
      };
    }

    // 5. Get sequence
    const sequenceResult = await this.sequenceRepo.getById(context, execution.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      await this.executionRepo.markSkipped(context, executionId, 'Sequence not found');
      return {
        success: false,
        errorCode: 'SEQUENCE_NOT_FOUND',
        errorMessage: 'Sequence not found',
      };
    }
    const sequence = sequenceResult.data;

    // 6. Check sequence status
    if (sequence.status !== 'active') {
      await this.executionRepo.markSkipped(context, executionId, `Sequence status: ${sequence.status}`);
      await this.enrollmentRepo.pause(context, enrollment.id, 'Sequence is not active');
      return {
        success: true,
        errorMessage: `Skipped - sequence is ${sequence.status}`,
      };
    }

    // 7. Find the step
    const step = sequence.steps.find((s) => s.id === execution.stepId);
    if (!step) {
      await this.executionRepo.markSkipped(context, executionId, 'Step not found');
      return {
        success: false,
        errorCode: 'STEP_NOT_FOUND',
        errorMessage: 'Step not found in sequence',
      };
    }

    // 8. Mark as executing
    await this.executionRepo.markExecuting(context, executionId);

    // 9. Execute the step
    const executorContext: ExecutorContext = {
      securityContext: context,
      enrollment,
      sequence,
      step,
      execution,
    };

    const stepResult = await this.executeStepByType(step.type, executorContext);

    // 10. Handle result
    if (stepResult.success) {
      // Mark completed
      await this.executionRepo.markCompleted(context, executionId, {
        success: true,
        messageId: stepResult.messageId,
        taskId: stepResult.taskId,
      });

      // Update enrollment stats
      await this.updateEnrollmentStats(context, enrollment, step.type, stepResult);

      // Schedule next step
      await this.scheduleNextStep(context, enrollment.id);

      // Audit log
      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'activity',
        entityId: executionId,
        metadata: {
          action: 'sequenceStepExecuted',
          sequenceId: sequence.id,
          enrollmentId: enrollment.id,
          stepType: step.type,
          stepIndex: execution.stepIndex,
          result: 'success',
        },
      });
    } else {
      // Handle failure with retry logic
      const retryCount = (execution.result?.retryCount || 0) + 1;

      if (retryCount < this.retryPolicy.maxAttempts) {
        // Reschedule for retry
        const nextRetryAt = getNextRetryTime(
          retryCount,
          this.retryPolicy.initialDelayMs,
          this.retryPolicy.maxDelayMs
        );
        await this.executionRepo.reschedule(context, executionId, nextRetryAt, retryCount);
      } else {
        // Max retries exceeded - mark as failed
        await this.executionRepo.markFailed(context, executionId, {
          errorCode: stepResult.errorCode || 'MAX_RETRIES_EXCEEDED',
          errorMessage: stepResult.errorMessage || 'Maximum retry attempts exceeded',
          retryCount,
        });

        // Audit log
        await this.auditService.logAction(context, {
          action: 'update',
          entityType: 'activity',
          entityId: executionId,
          metadata: {
            action: 'sequenceStepFailed',
            sequenceId: sequence.id,
            enrollmentId: enrollment.id,
            stepType: step.type,
            stepIndex: execution.stepIndex,
            errorCode: stepResult.errorCode,
          },
        });
      }
    }

    return {
      success: stepResult.success,
      messageId: stepResult.messageId,
      taskId: stepResult.taskId,
      errorCode: stepResult.errorCode,
      errorMessage: stepResult.errorMessage,
    };
  }

  // ============================================
  // Exit Criteria Checking
  // ============================================

  /**
   * Check exit criteria for an enrollment.
   * Returns true if enrollment should exit.
   */
  async checkExitCriteria(
    context: SecurityContext,
    enrollmentId: string
  ): Promise<{ shouldExit: boolean; reason?: string }> {
    // Get enrollment
    const enrollmentResult = await this.enrollmentRepo.getById(context, enrollmentId);
    if (!enrollmentResult.success || !enrollmentResult.data) {
      return { shouldExit: false };
    }
    const enrollment = enrollmentResult.data;

    // Get sequence
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return { shouldExit: false };
    }
    const sequence = sequenceResult.data;

    const exitCriteria = sequence.exitCriteria;
    if (!exitCriteria) {
      return { shouldExit: false };
    }

    // Check reply
    if (exitCriteria.onReply && enrollment.repliesReceived > 0) {
      return { shouldExit: true, reason: 'replied' };
    }

    // Other exit criteria would be checked via event handlers
    // (meeting booked, deal won/lost, etc.)

    return { shouldExit: false };
  }

  // ============================================
  // Private Helpers
  // ============================================

  /**
   * Execute step based on type.
   */
  private async executeStepByType(
    stepType: SequenceStepType,
    context: ExecutorContext
  ): Promise<StepExecutionResult> {
    switch (stepType) {
      case 'email':
        return getEmailStepExecutor().execute(context);
      case 'task':
        return getTaskStepExecutor().execute(context);
      case 'wait':
        return getWaitStepExecutor().execute(context);
      case 'call_reminder':
        return getCallStepExecutor().execute(context);
      case 'sms':
        return getSmsStepExecutor().execute(context);
      default:
        return {
          success: false,
          errorCode: 'UNKNOWN_STEP_TYPE',
          errorMessage: `Unknown step type: ${stepType}`,
        };
    }
  }

  /**
   * Update enrollment stats after step execution.
   */
  private async updateEnrollmentStats(
    context: SecurityContext,
    enrollment: SequenceEnrollment,
    stepType: SequenceStepType,
    _result: StepExecutionResult
  ): Promise<void> {
    switch (stepType) {
      case 'email':
        await this.enrollmentRepo.incrementStat(context, enrollment.id, 'emailsSent');
        break;
      case 'task':
      case 'call_reminder':
        await this.enrollmentRepo.incrementStat(context, enrollment.id, 'tasksCreated');
        break;
      // Wait steps don't update stats
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let serviceInstance: SequenceExecutionService | null = null;

export function getSequenceExecutionService(): SequenceExecutionService {
  if (!serviceInstance) {
    serviceInstance = new SequenceExecutionService();
  }
  return serviceInstance;
}
