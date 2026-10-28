/**
 * Sequence Repository
 * Manages outreach sequences with RBAC and multi-tenant isolation
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository } from './access-control';
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
  Sequence,
  SequenceStep,
  SequenceStats,
  SequenceStatus,
} from '../../types/sequences';

// ============================================
// Validation
// ============================================

const sequenceValidator: Validator<Sequence> = (data: Partial<Sequence>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({ field: 'name', message: 'Name is required', code: 'REQUIRED' });
  }

  if (data.steps !== undefined) {
    if (!Array.isArray(data.steps)) {
      errors.push({ field: 'steps', message: 'Steps must be an array', code: 'INVALID_TYPE' });
    } else {
      // Validate each step has required fields
      data.steps.forEach((step, index) => {
        if (!step.id) {
          errors.push({
            field: `steps[${index}].id`,
            message: 'Step ID is required',
            code: 'REQUIRED',
          });
        }
        if (!step.type) {
          errors.push({
            field: `steps[${index}].type`,
            message: 'Step type is required',
            code: 'REQUIRED',
          });
        }
        if (step.delayDays !== undefined && step.delayDays < 0) {
          errors.push({
            field: `steps[${index}].delayDays`,
            message: 'Delay days must be non-negative',
            code: 'INVALID_VALUE',
          });
        }
      });
    }
  }

  if (data.settings?.sendingSchedule) {
    const schedule = data.settings.sendingSchedule;
    if (schedule.startHour < 0 || schedule.startHour > 23) {
      errors.push({
        field: 'settings.sendingSchedule.startHour',
        message: 'Start hour must be between 0 and 23',
        code: 'INVALID_VALUE',
      });
    }
    if (schedule.endHour < 0 || schedule.endHour > 23) {
      errors.push({
        field: 'settings.sendingSchedule.endHour',
        message: 'End hour must be between 0 and 23',
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
// Sequence Repository
// ============================================

export class SequenceRepository extends ShareableRepository<Sequence> {
  protected entityName = 'sequence';
  protected sensitiveFields: Array<keyof Sequence> = [];

  constructor() {
    super({ collectionName: 'sequences' });
    this.setValidator(sequenceValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all sequences with optional status filter
   */
  async getByStatus(
    context: SecurityContext,
    status: SequenceStatus
  ): Promise<RepositoryResult<Sequence[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: status }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const sequences = this.snapshotToSequences(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getByStatus',
        status,
        count: sequences.length,
      });

      return successResult(sequences);
    } catch (error) {
      return failedResult(error, 'Failed to get sequences by status');
    }
  }

  /**
   * Get active sequences only
   */
  async getActive(context: SecurityContext): Promise<RepositoryResult<Sequence[]>> {
    return this.getByStatus(context, 'active');
  }

  /**
   * List sequences with optional filters
   */
  async list(
    context: SecurityContext,
    filters?: { status?: SequenceStatus }
  ): Promise<RepositoryResult<Sequence[]>> {
    try {
      if (filters?.status) {
        return this.getByStatus(context, filters.status);
      }

      // Get all sequences using getAll from base class
      const result = await this.getAll(context);
      if (!result.success) {
        return failedResult(result.error, 'Failed to list sequences');
      }

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to list sequences');
    }
  }

  /**
   * Get sequences by owner
   */
  async getByOwner(
    context: SecurityContext,
    ownerId: string
  ): Promise<RepositoryResult<Sequence[]>> {
    try {
      if (!ownerId) {
        return failedResult(new InvalidArgumentError('Owner ID is required', 'ownerId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'ownerId', operator: '==', value: ownerId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const sequences = this.snapshotToSequences(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getByOwner',
        ownerId,
        count: sequences.length,
      });

      return successResult(sequences);
    } catch (error) {
      return failedResult(error, 'Failed to get sequences by owner');
    }
  }

  // ============================================
  // Status Management
  // ============================================

  /**
   * Activate a sequence (set status to active)
   * Validates that sequence has at least one action step
   */
  async activate(context: SecurityContext, id: string): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;

      // Validate sequence has at least one action step
      const actionSteps = sequence.steps.filter(
        (step) => step.type !== 'wait' && step.isActive
      );
      if (actionSteps.length === 0) {
        return failedResult(
          new InvalidArgumentError(
            'Sequence must have at least one active action step (email, task, call, or SMS)',
            'steps'
          )
        );
      }

      // Validate email steps have content
      const emailSteps = sequence.steps.filter((s) => s.type === 'email' && s.isActive);
      for (const step of emailSteps) {
        if (!step.emailConfig?.templateId && (!step.emailConfig?.subject || !step.emailConfig?.body)) {
          return failedResult(
            new InvalidArgumentError(
              'All email steps must have a template or subject and body',
              'steps'
            )
          );
        }
      }

      const result = await this.update(context, id, { status: 'active' });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'activate',
          previousStatus: sequence.status,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to activate sequence');
    }
  }

  /**
   * Pause a sequence (set status to paused)
   */
  async pause(context: SecurityContext, id: string): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;

      if (sequence.status === 'archived') {
        return failedResult(
          new InvalidArgumentError('Cannot pause an archived sequence', 'status')
        );
      }

      const result = await this.update(context, id, { status: 'paused' });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'pause',
          previousStatus: sequence.status,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to pause sequence');
    }
  }

  /**
   * Archive a sequence (soft delete)
   * Cannot archive sequence with active enrollments
   */
  async archive(
    context: SecurityContext,
    id: string,
    hasActiveEnrollments: boolean = false
  ): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      if (hasActiveEnrollments) {
        return failedResult(
          new InvalidArgumentError(
            'Cannot archive sequence with active enrollments. Pause or remove enrollments first.',
            'status'
          )
        );
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;

      const result = await this.update(context, id, { status: 'archived' });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'archive',
          previousStatus: sequence.status,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to archive sequence');
    }
  }

  // ============================================
  // Step Management
  // ============================================

  /**
   * Update steps for a sequence
   * Cannot modify steps of an active sequence
   */
  async updateSteps(
    context: SecurityContext,
    id: string,
    steps: SequenceStep[]
  ): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;

      if (sequence.status === 'active') {
        return failedResult(
          new InvalidArgumentError(
            'Cannot modify steps of an active sequence. Pause it first.',
            'status'
          )
        );
      }

      // Re-index step orders
      const orderedSteps = steps.map((step, index) => ({
        ...step,
        order: index,
      }));

      const result = await this.update(context, id, { steps: orderedSteps });

      if (result.success) {
        await this.logAudit(context, 'update', id, {
          action: 'updateSteps',
          stepCount: steps.length,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update sequence steps');
    }
  }

  // ============================================
  // Duplication
  // ============================================

  /**
   * Duplicate a sequence with a new name
   */
  async duplicate(
    context: SecurityContext,
    id: string,
    newName?: string
  ): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;

      // Create new sequence with reset stats
      const duplicated: Omit<Sequence, 'id' | 'createdAt' | 'updatedAt'> = {
        name: newName || `${sequence.name} (Copy)`,
        description: sequence.description,
        status: 'draft', // Always start as draft
        steps: sequence.steps.map((step) => ({
          ...step,
          id: `step_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        })),
        settings: { ...sequence.settings },
        enrollmentCriteria: sequence.enrollmentCriteria
          ? { ...sequence.enrollmentCriteria }
          : undefined,
        exitCriteria: sequence.exitCriteria ? { ...sequence.exitCriteria } : undefined,
        stats: {
          totalEnrolled: 0,
          activeEnrollments: 0,
          completedCount: 0,
          exitedCount: 0,
        },
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: sequence.teamIds,
        visibility: sequence.visibility,
      };

      const result = await this.create(context, duplicated);

      if (result.success) {
        await this.logAudit(context, 'create', result.data.id, {
          action: 'duplicate',
          sourceSequenceId: id,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to duplicate sequence');
    }
  }

  // ============================================
  // Stats Management
  // ============================================

  /**
   * Update sequence stats (called when enrollments change)
   */
  async updateStats(
    context: SecurityContext,
    id: string,
    stats: Partial<SequenceStats>
  ): Promise<RepositoryResult<Sequence>> {
    try {
      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid sequence ID', 'id'));
      }

      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;
      const updatedStats: SequenceStats = {
        ...sequence.stats,
        ...stats,
      };

      return this.update(context, id, { stats: updatedStats });
    } catch (error) {
      return failedResult(error, 'Failed to update sequence stats');
    }
  }

  /**
   * Increment a specific stat
   */
  async incrementStat(
    context: SecurityContext,
    id: string,
    stat: keyof SequenceStats,
    amount: number = 1
  ): Promise<RepositoryResult<Sequence>> {
    try {
      const existingResult = await this.getById(context, id);
      if (!existingResult.success) {
        return existingResult;
      }

      const sequence = existingResult.data;
      const currentValue = (sequence.stats[stat] as number) || 0;

      return this.updateStats(context, id, {
        [stat]: currentValue + amount,
      });
    } catch (error) {
      return failedResult(error, `Failed to increment sequence stat: ${stat}`);
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  /**
   * Convert Firestore snapshot to Sequence array
   */
  private snapshotToSequences(snapshot: QuerySnapshot<DocumentData>): Sequence[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return this.documentToSequence(doc.id, data);
    });
  }

  private documentToSequence(id: string, data: DocumentData): Sequence {
    return {
      id,
      name: data.name as string,
      description: data.description as string | undefined,
      status: data.status as SequenceStatus,
      steps: (data.steps as SequenceStep[]) || [],
      settings: data.settings || {},
      enrollmentCriteria: data.enrollmentCriteria,
      exitCriteria: data.exitCriteria,
      stats: data.stats || {
        totalEnrolled: 0,
        activeEnrollments: 0,
        completedCount: 0,
        exitedCount: 0,
      },
      ownerId: data.ownerId as string,
      ownerName: data.ownerName as string,
      teamIds: (data.teamIds as string[]) || [],
      visibility: data.visibility || 'team',
      createdAt: data.createdAt?.toDate?.() || new Date(),
      updatedAt: data.updatedAt?.toDate?.() || undefined,
    };
  }
}

// Export singleton instance
let sequenceRepository: SequenceRepository | null = null;

export function getSequenceRepository(): SequenceRepository {
  if (!sequenceRepository) {
    sequenceRepository = new SequenceRepository();
  }
  return sequenceRepository;
}
