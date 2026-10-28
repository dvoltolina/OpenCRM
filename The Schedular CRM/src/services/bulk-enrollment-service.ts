/**
 * Bulk Enrollment Service
 * Handles bulk enrollment operations with validation and rate limiting
 *
 * Phase 3 Implementation
 * HIPAA Compliant: No PHI in logs, audit trail for all operations
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { getRateLimitService, type RateLimitResult } from './RateLimitService';
import type {
  EnrollmentEntityType,
  SequenceEnrollment,
  EnrollmentStatus,
} from '../types/sequences';

// ============================================
// Types
// ============================================

export interface BulkEnrollmentEntity {
  type: EnrollmentEntityType;
  id: string;
  name: string;
  email: string;
  hasOptedOut?: boolean;
}

export interface BulkEnrollmentOptions {
  /** Skip entities that have validation issues */
  skipInvalid: boolean;
  /** Batch size for enrollment (default 10) */
  batchSize?: number;
  /** Progress callback */
  onProgress?: (progress: BulkEnrollmentProgress) => void;
}

export interface BulkEnrollmentProgress {
  processed: number;
  total: number;
  enrolled: number;
  skipped: number;
  errors: number;
}

export interface BulkEnrollmentResult {
  enrolled: string[];
  skipped: Array<{ entityId: string; reason: string }>;
  errors: Array<{ entityId: string; error: string }>;
}

export interface ValidationResult {
  valid: BulkEnrollmentEntity[];
  invalid: Array<{ entity: BulkEnrollmentEntity; reason: string }>;
}

// ============================================
// Service
// ============================================

export class BulkEnrollmentService {
  private rateLimitService = getRateLimitService();
  private enrollmentRepo = getSequenceEnrollmentRepository();
  private sequenceRepo = getSequenceRepository();

  /**
   * Validate entities before bulk enrollment
   */
  async validateEntities(
    context: SecurityContext,
    entities: BulkEnrollmentEntity[],
    sequenceId: string
  ): Promise<ValidationResult> {
    const valid: BulkEnrollmentEntity[] = [];
    const invalid: Array<{ entity: BulkEnrollmentEntity; reason: string }> = [];

    for (const entity of entities) {
      const validationResult = await this.validateSingleEntity(context, entity, sequenceId);

      if (validationResult.isValid) {
        valid.push(entity);
      } else {
        invalid.push({ entity, reason: validationResult.reason });
      }
    }

    return { valid, invalid };
  }

  /**
   * Validate a single entity for enrollment
   */
  private async validateSingleEntity(
    context: SecurityContext,
    entity: BulkEnrollmentEntity,
    sequenceId: string
  ): Promise<{ isValid: boolean; reason: string }> {
    // Check email
    if (!entity.email || !entity.email.trim()) {
      return { isValid: false, reason: 'No email address' };
    }

    // Check opt-out
    if (entity.hasOptedOut) {
      return { isValid: false, reason: 'Opted out of emails' };
    }

    // Check if already enrolled in any active sequence
    const activeResult = await this.enrollmentRepo.getActiveByEntity(
      context,
      entity.type,
      entity.id
    );

    if (activeResult.success && activeResult.data) {
      return {
        isValid: false,
        reason: `Already enrolled in: ${activeResult.data.sequenceName}`,
      };
    }

    // Check if already enrolled in this specific sequence (including paused)
    const entityEnrollments = await this.enrollmentRepo.getByEntity(
      context,
      entity.type,
      entity.id
    );

    if (entityEnrollments.success) {
      const existingInSequence = entityEnrollments.data.find(
        (e) =>
          e.sequenceId === sequenceId &&
          (e.status === 'active' || e.status === 'paused')
      );

      if (existingInSequence) {
        return {
          isValid: false,
          reason: 'Already enrolled in this sequence',
        };
      }
    }

    return { isValid: true, reason: '' };
  }

  /**
   * Check rate limits for bulk enrollment
   */
  async checkRateLimits(
    context: SecurityContext,
    entityCount: number
  ): Promise<{
    allowed: boolean;
    bulkLimit: RateLimitResult;
    emailLimit: RateLimitResult;
    message?: string;
  }> {
    // Check bulk operation limit
    const bulkLimit = await this.rateLimitService.checkLimit(
      'bulk_operation',
      context.userId,
      context.businessId
    );

    // Check email limit (assuming each enrollment may send an email)
    const emailLimit = await this.rateLimitService.checkLimit(
      'email',
      context.userId,
      context.businessId
    );

    // Check if we have capacity
    if (!bulkLimit.allowed) {
      return {
        allowed: false,
        bulkLimit,
        emailLimit,
        message: `Bulk operation limit reached. ${bulkLimit.message}`,
      };
    }

    // Warn if email limit might be exceeded
    if (emailLimit.remaining < entityCount) {
      return {
        allowed: true,
        bulkLimit,
        emailLimit,
        message: `Warning: Only ${emailLimit.remaining} emails remaining. Some enrollments may not send initial emails.`,
      };
    }

    return { allowed: true, bulkLimit, emailLimit };
  }

  /**
   * Perform bulk enrollment
   */
  async bulkEnroll(
    context: SecurityContext,
    sequenceId: string,
    sequenceName: string,
    totalSteps: number,
    entities: BulkEnrollmentEntity[],
    options: BulkEnrollmentOptions = { skipInvalid: true }
  ): Promise<BulkEnrollmentResult> {
    const result: BulkEnrollmentResult = {
      enrolled: [],
      skipped: [],
      errors: [],
    };

    const batchSize = options.batchSize || 10;

    // Record bulk operation
    await this.rateLimitService.recordAction(
      'bulk_operation',
      context.userId,
      context.businessId
    );

    // Validate entities if skipInvalid is true
    let entitiesToEnroll = entities;
    if (options.skipInvalid) {
      const validation = await this.validateEntities(context, entities, sequenceId);
      entitiesToEnroll = validation.valid;
      result.skipped.push(
        ...validation.invalid.map((v) => ({
          entityId: v.entity.id,
          reason: v.reason,
        }))
      );
    }

    // Process in batches
    const batches = this.createBatches(entitiesToEnroll, batchSize);
    let processed = 0;

    for (const batch of batches) {
      const batchResults = await this.processBatch(
        context,
        sequenceId,
        sequenceName,
        totalSteps,
        batch
      );

      result.enrolled.push(...batchResults.enrolled);
      result.skipped.push(...batchResults.skipped);
      result.errors.push(...batchResults.errors);

      processed += batch.length;

      // Report progress
      options.onProgress?.({
        processed,
        total: entitiesToEnroll.length,
        enrolled: result.enrolled.length,
        skipped: result.skipped.length,
        errors: result.errors.length,
      });
    }

    // Update sequence stats
    if (result.enrolled.length > 0) {
      await this.sequenceRepo.incrementStat(
        context,
        sequenceId,
        'totalEnrolled',
        result.enrolled.length
      );
      await this.sequenceRepo.incrementStat(
        context,
        sequenceId,
        'activeEnrollments',
        result.enrolled.length
      );
    }

    return result;
  }

  /**
   * Process a batch of enrollments
   */
  private async processBatch(
    context: SecurityContext,
    sequenceId: string,
    sequenceName: string,
    totalSteps: number,
    entities: BulkEnrollmentEntity[]
  ): Promise<BulkEnrollmentResult> {
    const result: BulkEnrollmentResult = {
      enrolled: [],
      skipped: [],
      errors: [],
    };

    for (const entity of entities) {
      try {
        const enrollmentData: Omit<SequenceEnrollment, 'id' | 'createdAt' | 'updatedAt'> = {
          sequenceId,
          sequenceName,
          entityType: entity.type,
          entityId: entity.id,
          entityName: entity.name,
          entityEmail: entity.email,
          status: 'active' as EnrollmentStatus,
          currentStepIndex: 0,
          stepsCompleted: 0,
          totalSteps,
          emailsSent: 0,
          emailsOpened: 0,
          emailsClicked: 0,
          tasksCreated: 0,
          repliesReceived: 0,
          enrolledById: context.userId,
          enrolledByName: context.userName,
          ownerId: context.userId,
          ownerName: context.userName,
          teamIds: context.teamIds || [],
          visibility: 'team',
        };

        const enrollResult = await this.enrollmentRepo.enroll(context, enrollmentData);

        if (enrollResult.success) {
          result.enrolled.push(enrollResult.data.id);
        } else {
          result.skipped.push({
            entityId: entity.id,
            reason: enrollResult.error.message,
          });
        }
      } catch (err) {
        result.errors.push({
          entityId: entity.id,
          error: err instanceof Error ? err.message : 'Unknown error',
        });
      }
    }

    return result;
  }

  /**
   * Split entities into batches
   */
  private createBatches<T>(items: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < items.length; i += batchSize) {
      batches.push(items.slice(i, i + batchSize));
    }
    return batches;
  }

  /**
   * Get enrollment statistics for a set of entities
   */
  async getEnrollmentStats(
    context: SecurityContext,
    entities: BulkEnrollmentEntity[]
  ): Promise<{
    total: number;
    alreadyEnrolled: number;
    missingEmail: number;
    optedOut: number;
    enrollable: number;
  }> {
    let alreadyEnrolled = 0;
    let missingEmail = 0;
    let optedOut = 0;

    for (const entity of entities) {
      if (!entity.email) {
        missingEmail++;
        continue;
      }

      if (entity.hasOptedOut) {
        optedOut++;
        continue;
      }

      const activeResult = await this.enrollmentRepo.getActiveByEntity(
        context,
        entity.type,
        entity.id
      );

      if (activeResult.success && activeResult.data) {
        alreadyEnrolled++;
      }
    }

    const enrollable = entities.length - alreadyEnrolled - missingEmail - optedOut;

    return {
      total: entities.length,
      alreadyEnrolled,
      missingEmail,
      optedOut,
      enrollable,
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let bulkEnrollmentServiceInstance: BulkEnrollmentService | null = null;

export function getBulkEnrollmentService(): BulkEnrollmentService {
  if (!bulkEnrollmentServiceInstance) {
    bulkEnrollmentServiceInstance = new BulkEnrollmentService();
  }
  return bulkEnrollmentServiceInstance;
}

export default BulkEnrollmentService;
