/**
 * Sequence Enrollment Repository
 * Manages enrollment of leads/contacts/deals in sequences
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
  QueryOptions,
} from './repository-types';
import {
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type {
  SequenceEnrollment,
  EnrollmentStatus,
  EnrollmentEntityType,
  ExitReason,
} from '../../types/sequences';

// ============================================
// Validation
// ============================================

const enrollmentValidator: Validator<SequenceEnrollment> = (
  data: Partial<SequenceEnrollment>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.sequenceId !== undefined && !data.sequenceId?.trim()) {
    errors.push({ field: 'sequenceId', message: 'Sequence ID is required', code: 'REQUIRED' });
  }

  if (data.entityId !== undefined && !data.entityId?.trim()) {
    errors.push({ field: 'entityId', message: 'Entity ID is required', code: 'REQUIRED' });
  }

  if (data.entityEmail !== undefined && !data.entityEmail?.trim()) {
    errors.push({ field: 'entityEmail', message: 'Entity email is required', code: 'REQUIRED' });
  }

  if (data.entityType !== undefined) {
    if (!['lead', 'client', 'deal'].includes(data.entityType)) {
      errors.push({
        field: 'entityType',
        message: 'Entity type must be lead, client, or deal',
        code: 'INVALID_VALUE',
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Enrollment Repository
// ============================================

export class SequenceEnrollmentRepository extends ShareableRepository<SequenceEnrollment> {
  protected entityName = 'sequence_enrollment';
  protected sensitiveFields: Array<keyof SequenceEnrollment> = ['entityEmail'];

  constructor() {
    super({ collectionName: 'sequence_enrollments' });
    this.setValidator(enrollmentValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all enrollments for a sequence
   */
  async getBySequence(
    context: SecurityContext,
    sequenceId: string,
    statusFilter?: EnrollmentStatus
  ): Promise<RepositoryResult<SequenceEnrollment[]>> {
    try {
      if (!isValidDocumentId(sequenceId)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'sequenceId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const whereConditions: Array<{ field: string; operator: string; value: unknown }> = [
        { field: 'sequenceId', operator: '==', value: sequenceId },
      ];

      if (statusFilter) {
        whereConditions.push({ field: 'status', operator: '==', value: statusFilter });
      }

      const q = buildQuery(collectionRef, {
        where: whereConditions as QueryOptions['where'],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const enrollments = this.snapshotToEnrollments(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getBySequence',
        sequenceId,
        statusFilter,
        count: enrollments.length,
      });

      return successResult(enrollments);
    } catch (error) {
      return failedResult(error, 'Failed to get enrollments by sequence');
    }
  }

  /**
   * Get enrollments for a specific entity (lead/client/deal)
   */
  async getByEntity(
    context: SecurityContext,
    entityType: EnrollmentEntityType,
    entityId: string
  ): Promise<RepositoryResult<SequenceEnrollment[]>> {
    try {
      if (!isValidDocumentId(entityId)) {
        return failedResult(new InvalidArgumentError('Invalid entity ID', 'entityId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'entityType', operator: '==', value: entityType },
          { field: 'entityId', operator: '==', value: entityId },
        ],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const enrollments = this.snapshotToEnrollments(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getByEntity',
        entityType,
        entityId,
        count: enrollments.length,
      });

      return successResult(enrollments);
    } catch (error) {
      return failedResult(error, 'Failed to get enrollments by entity');
    }
  }

  /**
   * Get active enrollment for an entity (should be at most one)
   */
  async getActiveByEntity(
    context: SecurityContext,
    entityType: EnrollmentEntityType,
    entityId: string
  ): Promise<RepositoryResult<SequenceEnrollment | null>> {
    try {
      if (!isValidDocumentId(entityId)) {
        return failedResult(new InvalidArgumentError('Invalid entity ID', 'entityId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'entityType', operator: '==', value: entityType },
          { field: 'entityId', operator: '==', value: entityId },
          { field: 'status', operator: '==', value: 'active' },
        ],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const enrollments = this.snapshotToEnrollments(snapshot);
      return successResult(enrollments[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to get active enrollment');
    }
  }

  /**
   * Get all active enrollments (for processing)
   */
  async getActive(context: SecurityContext): Promise<RepositoryResult<SequenceEnrollment[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: 'active' }],
        orderBy: { field: 'nextStepScheduledAt', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const enrollments = this.snapshotToEnrollments(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getActive',
        count: enrollments.length,
      });

      return successResult(enrollments);
    } catch (error) {
      return failedResult(error, 'Failed to get active enrollments');
    }
  }

  /**
   * Get enrollments due for processing (nextStepScheduledAt <= now)
   */
  async getDueForProcessing(
    context: SecurityContext,
    beforeTime: Date
  ): Promise<RepositoryResult<SequenceEnrollment[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'active' },
          { field: 'nextStepScheduledAt', operator: '<=', value: Timestamp.fromDate(beforeTime) },
        ],
        orderBy: { field: 'nextStepScheduledAt', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const enrollments = this.snapshotToEnrollments(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getDueForProcessing',
        beforeTime: beforeTime.toISOString(),
        count: enrollments.length,
      });

      return successResult(enrollments);
    } catch (error) {
      return failedResult(error, 'Failed to get enrollments due for processing');
    }
  }

  // ============================================
  // Enrollment Management
  // ============================================

  /**
   * Enroll an entity in a sequence
   * Checks for duplicate enrollments
   */
  async enroll(
    context: SecurityContext,
    data: Omit<SequenceEnrollment, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      // Check if entity is already enrolled in this sequence
      const existingResult = await this.getActiveByEntity(
        context,
        data.entityType as EnrollmentEntityType,
        data.entityId as string
      );

      if (existingResult.success && existingResult.data) {
        return failedResult(
          new InvalidArgumentError(
            `Entity is already enrolled in sequence: ${existingResult.data.sequenceName}`,
            'entityId'
          )
        );
      }

      // Check if entity was already in this specific sequence
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'sequenceId', operator: '==', value: data.sequenceId },
          { field: 'entityId', operator: '==', value: data.entityId },
          { field: 'status', operator: 'in', value: ['active', 'paused'] },
        ],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        return failedResult(
          new InvalidArgumentError('Entity is already enrolled in this sequence', 'entityId')
        );
      }

      const result = await this.create(context, data);

      if (result.success) {
        await this.logAudit(context, 'create', result.data.id, {
          action: 'enroll',
          sequenceId: data.sequenceId,
          entityType: data.entityType,
          entityId: data.entityId,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to enroll entity');
    }
  }

  /**
   * Bulk enroll multiple entities
   * Returns results for each enrollment attempt
   */
  async bulkEnroll(
    context: SecurityContext,
    enrollments: Array<Omit<SequenceEnrollment, 'id' | 'createdAt' | 'updatedAt'>>
  ): Promise<RepositoryResult<{ enrolled: string[]; skipped: { entityId: string; reason: string }[] }>> {
    try {
      const enrolled: string[] = [];
      const skipped: { entityId: string; reason: string }[] = [];

      for (const enrollment of enrollments) {
        const result = await this.enroll(context, enrollment);
        if (result.success) {
          enrolled.push(result.data.id);
        } else {
          skipped.push({
            entityId: enrollment.entityId as string,
            reason: result.error.message,
          });
        }
      }

      await this.logAudit(context, 'batch', null, {
        action: 'bulkEnroll',
        enrolledCount: enrolled.length,
        skippedCount: skipped.length,
      });

      return successResult({ enrolled, skipped });
    } catch (error) {
      return failedResult(error, 'Failed to bulk enroll');
    }
  }

  // ============================================
  // Status Management
  // ============================================

  /**
   * Pause an enrollment
   */
  async pause(
    context: SecurityContext,
    id: string,
    reason?: string
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const enrollment = existingResult.data;

      if (enrollment.status !== 'active') {
        return failedResult(
          new InvalidArgumentError('Can only pause active enrollments', 'status')
        );
      }

      const result = await this.update(context, id, { status: 'paused' });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'pause',
          reason,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to pause enrollment');
    }
  }

  /**
   * Resume a paused enrollment
   */
  async resume(context: SecurityContext, id: string): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const enrollment = existingResult.data;

      if (enrollment.status !== 'paused') {
        return failedResult(
          new InvalidArgumentError('Can only resume paused enrollments', 'status')
        );
      }

      const result = await this.update(context, id, { status: 'active' });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'resume',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to resume enrollment');
    }
  }

  /**
   * Exit an enrollment (remove from sequence)
   */
  async exit(
    context: SecurityContext,
    id: string,
    reason: ExitReason
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const enrollment = existingResult.data;

      if (enrollment.status === 'completed' || enrollment.status === 'exited') {
        return failedResult(
          new InvalidArgumentError('Enrollment has already ended', 'status')
        );
      }

      const result = await this.update(context, id, {
        status: 'exited',
        exitReason: reason,
        exitedAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'exit',
          reason,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to exit enrollment');
    }
  }

  /**
   * Mark enrollment as completed
   */
  async complete(context: SecurityContext, id: string): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const enrollment = existingResult.data;

      if (enrollment.status !== 'active') {
        return failedResult(
          new InvalidArgumentError('Can only complete active enrollments', 'status')
        );
      }

      const result = await this.update(context, id, {
        status: 'completed',
        completedAt: new Date(),
        nextStepScheduledAt: undefined,
      });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'complete',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to complete enrollment');
    }
  }

  /**
   * Mark enrollment as bounced
   */
  async markBounced(context: SecurityContext, id: string): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const result = await this.update(context, id, {
        status: 'bounced',
        exitReason: 'bounced',
        exitedAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markBounced',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark enrollment as bounced');
    }
  }

  /**
   * Mark enrollment as unsubscribed
   */
  async markUnsubscribed(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const result = await this.update(context, id, {
        status: 'unsubscribed',
        exitReason: 'unsubscribed',
        exitedAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'markUnsubscribed',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark enrollment as unsubscribed');
    }
  }

  // ============================================
  // Progress Tracking
  // ============================================

  /**
   * Update enrollment progress
   */
  async updateProgress(
    context: SecurityContext,
    id: string,
    currentStepIndex: number,
    nextStepScheduledAt: Date | undefined,
    stepsCompleted: number
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid enrollment ID', 'id'));
      }

      const result = await this.update(context, id, {
        currentStepIndex,
        nextStepScheduledAt,
        stepsCompleted,
      });

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update enrollment progress');
    }
  }

  /**
   * Increment a stat counter
   */
  async incrementStat(
    context: SecurityContext,
    id: string,
    stat: 'emailsSent' | 'emailsOpened' | 'emailsClicked' | 'tasksCreated' | 'repliesReceived',
    amount: number = 1
  ): Promise<RepositoryResult<SequenceEnrollment>> {
    try {
      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const enrollment = existingResult.data;
      const currentValue = enrollment[stat] || 0;

      return this.update(context, id, {
        [stat]: currentValue + amount,
      });
    } catch (error) {
      return failedResult(error, `Failed to increment stat: ${stat}`);
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private snapshotToEnrollments(snapshot: QuerySnapshot<DocumentData>): SequenceEnrollment[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return this.documentToEnrollment(doc.id, data);
    });
  }

  private documentToEnrollment(id: string, data: DocumentData): SequenceEnrollment {
    return {
      id,
      sequenceId: data.sequenceId as string,
      sequenceName: data.sequenceName as string,
      entityType: data.entityType as EnrollmentEntityType,
      entityId: data.entityId as string,
      entityName: data.entityName as string,
      entityEmail: data.entityEmail as string,
      status: data.status as EnrollmentStatus,
      exitReason: data.exitReason as ExitReason | undefined,
      currentStepIndex: data.currentStepIndex as number,
      nextStepScheduledAt: data.nextStepScheduledAt?.toDate?.() || undefined,
      stepsCompleted: data.stepsCompleted as number,
      totalSteps: data.totalSteps as number,
      emailsSent: data.emailsSent as number,
      emailsOpened: data.emailsOpened as number,
      emailsClicked: data.emailsClicked as number,
      tasksCreated: data.tasksCreated as number,
      repliesReceived: data.repliesReceived as number,
      enrolledById: data.enrolledById as string,
      enrolledByName: data.enrolledByName as string,
      ownerId: data.ownerId as string,
      ownerName: data.ownerName as string,
      teamIds: (data.teamIds as string[]) || [],
      visibility: data.visibility || 'team',
      createdAt: data.createdAt?.toDate?.() || new Date(),
      updatedAt: data.updatedAt?.toDate?.() || undefined,
      completedAt: data.completedAt?.toDate?.() || undefined,
      exitedAt: data.exitedAt?.toDate?.() || undefined,
    };
  }
}

// Export singleton instance
let enrollmentRepository: SequenceEnrollmentRepository | null = null;

export function getSequenceEnrollmentRepository(): SequenceEnrollmentRepository {
  if (!enrollmentRepository) {
    enrollmentRepository = new SequenceEnrollmentRepository();
  }
  return enrollmentRepository;
}
