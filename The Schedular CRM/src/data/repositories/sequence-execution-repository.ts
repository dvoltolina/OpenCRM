/**
 * Sequence Execution Repository
 * Tracks individual step executions for enrollments
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type {
  SequenceExecution,
  ExecutionStatus,
  SequenceStepType,
  ExecutionResult,
  EmailMetrics,
} from '../../types/sequences';

// ============================================
// Validation
// ============================================

const executionValidator: Validator<SequenceExecution> = (
  data: Partial<SequenceExecution>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.enrollmentId !== undefined && !data.enrollmentId?.trim()) {
    errors.push({ field: 'enrollmentId', message: 'Enrollment ID is required', code: 'REQUIRED' });
  }

  if (data.sequenceId !== undefined && !data.sequenceId?.trim()) {
    errors.push({ field: 'sequenceId', message: 'Sequence ID is required', code: 'REQUIRED' });
  }

  if (data.stepId !== undefined && !data.stepId?.trim()) {
    errors.push({ field: 'stepId', message: 'Step ID is required', code: 'REQUIRED' });
  }

  if (data.idempotencyKey !== undefined && !data.idempotencyKey?.trim()) {
    errors.push({
      field: 'idempotencyKey',
      message: 'Idempotency key is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Execution Repository
// ============================================

export class SequenceExecutionRepository extends BaseRepository<SequenceExecution> {
  constructor() {
    super({ collectionName: 'sequence_executions' });
    this.setValidator(executionValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all executions for an enrollment
   */
  async getByEnrollment(
    context: SecurityContext,
    enrollmentId: string
  ): Promise<RepositoryResult<SequenceExecution[]>> {
    try {
      if (!isValidDocumentId(enrollmentId)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'enrollmentId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'enrollmentId', operator: '==', value: enrollmentId }],
        orderBy: { field: 'stepIndex', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const executions = this.snapshotToExecutions(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getByEnrollment',
        enrollmentId,
        count: executions.length,
      });

      return successResult(executions);
    } catch (error) {
      return failedResult(error, 'Failed to get executions by enrollment');
    }
  }

  /**
   * Check if a step was already executed (by idempotency key)
   */
  async getByIdempotencyKey(
    context: SecurityContext,
    idempotencyKey: string
  ): Promise<RepositoryResult<SequenceExecution | null>> {
    try {
      if (!idempotencyKey?.trim()) {
        return failedResult(
          new InvalidArgumentError('Idempotency key is required', 'idempotencyKey')
        );
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'idempotencyKey', operator: '==', value: idempotencyKey }],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const executions = this.snapshotToExecutions(snapshot);
      return successResult(executions[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to get execution by idempotency key');
    }
  }

  /**
   * Get execution for a specific step in an enrollment
   */
  async getByStep(
    context: SecurityContext,
    enrollmentId: string,
    stepId: string
  ): Promise<RepositoryResult<SequenceExecution | null>> {
    try {
      if (!isValidDocumentId(enrollmentId)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'enrollmentId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'enrollmentId', operator: '==', value: enrollmentId },
          { field: 'stepId', operator: '==', value: stepId },
        ],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const executions = this.snapshotToExecutions(snapshot);
      return successResult(executions[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to get execution by step');
    }
  }

  /**
   * Get pending executions ready to run
   */
  async getPending(
    context: SecurityContext,
    beforeTime: Date
  ): Promise<RepositoryResult<SequenceExecution[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'scheduled' },
          { field: 'scheduledAt', operator: '<=', value: Timestamp.fromDate(beforeTime) },
        ],
        orderBy: { field: 'scheduledAt', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const executions = this.snapshotToExecutions(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getPending',
        beforeTime: beforeTime.toISOString(),
        count: executions.length,
      });

      return successResult(executions);
    } catch (error) {
      return failedResult(error, 'Failed to get pending executions');
    }
  }

  /**
   * Get executions by status
   */
  async getByStatus(
    context: SecurityContext,
    status: ExecutionStatus
  ): Promise<RepositoryResult<SequenceExecution[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: status }],
        orderBy: { field: 'scheduledAt', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const executions = this.snapshotToExecutions(snapshot);

      return successResult(executions);
    } catch (error) {
      return failedResult(error, 'Failed to get executions by status');
    }
  }

  /**
   * Get executions by message ID (for webhook handling)
   */
  async getByMessageId(
    context: SecurityContext,
    messageId: string
  ): Promise<RepositoryResult<SequenceExecution | null>> {
    try {
      if (!messageId?.trim()) {
        return failedResult(new InvalidArgumentError('Message ID is required', 'messageId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'result.messageId', operator: '==', value: messageId }],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const executions = this.snapshotToExecutions(snapshot);
      return successResult(executions[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to get execution by message ID');
    }
  }

  // ============================================
  // Execution Management
  // ============================================

  /**
   * Create execution with idempotency check
   */
  async createWithIdempotency(
    context: SecurityContext,
    data: Omit<SequenceExecution, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      // Check for existing execution with same idempotency key
      const existingResult = await this.getByIdempotencyKey(context, data.idempotencyKey);
      if (existingResult.success && existingResult.data) {
        // Return existing execution instead of creating duplicate
        return successResult(existingResult.data);
      }

      const result = await this.create(context, data);

      if (result.success) {
        await this.logAudit(context, 'create', result.data.id, {
          action: 'createExecution',
          enrollmentId: data.enrollmentId,
          stepId: data.stepId,
          stepType: data.stepType,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to create execution');
    }
  }

  /**
   * Mark execution as executing (in progress)
   */
  async markExecuting(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const result = await this.update(context, id, {
        status: 'executing',
      });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markExecuting',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark execution as executing');
    }
  }

  /**
   * Mark execution as completed with result
   */
  async markCompleted(
    context: SecurityContext,
    id: string,
    result: ExecutionResult
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const updateResult = await this.update(context, id, {
        status: 'completed',
        executedAt: new Date(),
        result,
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markCompleted',
          success: result.success,
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to mark execution as completed');
    }
  }

  /**
   * Mark execution as failed with error
   */
  async markFailed(
    context: SecurityContext,
    id: string,
    error: { errorCode: string; errorMessage: string; retryCount?: number }
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const updateResult = await this.update(context, id, {
        status: 'failed',
        executedAt: new Date(),
        result: {
          success: false,
          errorCode: error.errorCode,
          errorMessage: error.errorMessage,
          retryCount: error.retryCount,
        },
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markFailed',
          errorCode: error.errorCode,
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to mark execution as failed');
    }
  }

  /**
   * Mark execution as skipped
   */
  async markSkipped(
    context: SecurityContext,
    id: string,
    reason: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const updateResult = await this.update(context, id, {
        status: 'skipped',
        executedAt: new Date(),
        result: {
          success: true,
          errorMessage: reason,
        },
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markSkipped',
          reason,
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to mark execution as skipped');
    }
  }

  /**
   * Reschedule a failed execution for retry
   */
  async reschedule(
    context: SecurityContext,
    id: string,
    scheduledAt: Date,
    retryCount: number
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const existingResultData = existingResult.data.result;
      const updateResult = await this.update(context, id, {
        status: 'scheduled',
        scheduledAt,
        result: {
          ...existingResultData,
          success: existingResultData?.success ?? false,
          retryCount,
        },
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', id, {
          action: 'reschedule',
          scheduledAt: scheduledAt.toISOString(),
          retryCount,
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to reschedule execution');
    }
  }

  // ============================================
  // Email Metrics
  // ============================================

  /**
   * Update email metrics for an execution
   */
  async updateEmailMetrics(
    context: SecurityContext,
    id: string,
    metrics: Partial<EmailMetrics>
  ): Promise<RepositoryResult<SequenceExecution>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid execution ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const execution = existingResult.data;
      const updatedMetrics: EmailMetrics = {
        ...execution.emailMetrics,
        delivered: false,
        opened: false,
        clicked: false,
        replied: false,
        bounced: false,
        ...metrics,
      };

      const updateResult = await this.update(context, id, {
        emailMetrics: updatedMetrics,
      });

      if (updateResult.success) {
        await this.logAudit(context, 'update', id, {
          action: 'updateEmailMetrics',
          metricsUpdated: Object.keys(metrics),
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to update email metrics');
    }
  }

  /**
   * Record email open
   */
  async recordEmailOpen(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    return this.updateEmailMetrics(context, id, {
      opened: true,
      openedAt: new Date(),
    });
  }

  /**
   * Record email click
   */
  async recordEmailClick(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    return this.updateEmailMetrics(context, id, {
      clicked: true,
      clickedAt: new Date(),
    });
  }

  /**
   * Record email delivery
   */
  async recordEmailDelivery(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    return this.updateEmailMetrics(context, id, {
      delivered: true,
      deliveredAt: new Date(),
    });
  }

  /**
   * Record email bounce
   */
  async recordEmailBounce(
    context: SecurityContext,
    id: string,
    bounceType: 'hard' | 'soft'
  ): Promise<RepositoryResult<SequenceExecution>> {
    return this.updateEmailMetrics(context, id, {
      bounced: true,
      bouncedAt: new Date(),
      bounceType,
    });
  }

  /**
   * Record email reply
   */
  async recordEmailReply(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceExecution>> {
    return this.updateEmailMetrics(context, id, {
      replied: true,
      repliedAt: new Date(),
    });
  }

  // ============================================
  // Helper Methods
  // ============================================

  private snapshotToExecutions(snapshot: QuerySnapshot<DocumentData>): SequenceExecution[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return this.documentToExecution(doc.id, data);
    });
  }

  private documentToExecution(id: string, data: DocumentData): SequenceExecution {
    return {
      id,
      enrollmentId: data.enrollmentId as string,
      sequenceId: data.sequenceId as string,
      stepId: data.stepId as string,
      stepIndex: data.stepIndex as number,
      stepType: data.stepType as SequenceStepType,
      status: data.status as ExecutionStatus,
      scheduledAt: data.scheduledAt?.toDate?.() || new Date(),
      executedAt: data.executedAt?.toDate?.() || undefined,
      result: data.result as ExecutionResult | undefined,
      emailMetrics: data.emailMetrics as EmailMetrics | undefined,
      idempotencyKey: data.idempotencyKey as string,
      createdAt: data.createdAt?.toDate?.() || new Date(),
      updatedAt: data.updatedAt?.toDate?.() || undefined,
    };
  }
}

// Export singleton instance
let executionRepository: SequenceExecutionRepository | null = null;

export function getSequenceExecutionRepository(): SequenceExecutionRepository {
  if (!executionRepository) {
    executionRepository = new SequenceExecutionRepository();
  }
  return executionRepository;
}
