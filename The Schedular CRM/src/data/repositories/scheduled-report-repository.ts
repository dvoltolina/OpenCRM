/**
 * Scheduled Report Repository
 * Manages scheduled report configurations with RBAC and Firestore persistence.
 *
 * HIPAA Compliance:
 * - Scheduled reports contain no PHI (configuration only)
 * - All operations require SecurityContext for businessId scoping
 * - Recipient emails/users validated against business membership
 * - Audit log all schedule operations
 */

import { getDocs } from 'firebase/firestore';
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
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type {
  ScheduledReport,
  ScheduledReportFrequency,
  ScheduledReportFormat,
} from '../../types/reporting';

// ============================================
// Validation
// ============================================

const VALID_FREQUENCIES: ScheduledReportFrequency[] = ['daily', 'weekly', 'monthly'];
const VALID_FORMATS: ScheduledReportFormat[] = ['csv', 'xlsx', 'pdf'];

const scheduledReportValidator: Validator<ScheduledReport> = (
  data: Partial<ScheduledReport>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.reportId?.trim()) {
    errors.push({
      field: 'reportId',
      message: 'Report ID is required',
      code: 'REQUIRED',
    });
  }

  if (data.frequency !== undefined && !VALID_FREQUENCIES.includes(data.frequency)) {
    errors.push({
      field: 'frequency',
      message: `Invalid frequency. Must be one of: ${VALID_FREQUENCIES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.format !== undefined && !VALID_FORMATS.includes(data.format)) {
    errors.push({
      field: 'format',
      message: `Invalid format. Must be one of: ${VALID_FORMATS.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (!data.timeOfDay?.trim()) {
    errors.push({
      field: 'timeOfDay',
      message: 'Time of day is required',
      code: 'REQUIRED',
    });
  } else if (!/^\d{2}:\d{2}$/.test(data.timeOfDay)) {
    errors.push({
      field: 'timeOfDay',
      message: 'Time of day must be in HH:MM format',
      code: 'INVALID_FORMAT',
    });
  }

  if (data.frequency === 'weekly' && (data.dayOfWeek === undefined || data.dayOfWeek < 0 || data.dayOfWeek > 6)) {
    errors.push({
      field: 'dayOfWeek',
      message: 'Day of week (0-6, Sunday-Saturday) is required for weekly schedules',
      code: 'REQUIRED',
    });
  }

  if (data.frequency === 'monthly' && (data.dayOfMonth === undefined || data.dayOfMonth < 1 || data.dayOfMonth > 28)) {
    errors.push({
      field: 'dayOfMonth',
      message: 'Day of month (1-28) is required for monthly schedules',
      code: 'REQUIRED',
    });
  }

  if (
    (!data.recipientUserIds || data.recipientUserIds.length === 0) &&
    (!data.recipientEmails || data.recipientEmails.length === 0)
  ) {
    errors.push({
      field: 'recipientUserIds',
      message: 'At least one recipient (user or email) is required',
      code: 'REQUIRED',
    });
  }

  // Validate email format if provided
  if (data.recipientEmails?.length) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    for (const email of data.recipientEmails) {
      if (!emailRegex.test(email)) {
        errors.push({
          field: 'recipientEmails',
          message: `Invalid email format: ${email}`,
          code: 'INVALID_FORMAT',
        });
      }
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Scheduled Report Repository
// ============================================

/**
 * Scheduled Report Repository
 * Handles CRUD operations for scheduled reports with RBAC
 */
export class ScheduledReportRepository extends BaseRepository<ScheduledReport> {
  protected entityName = 'scheduledReport';
  protected sensitiveFields: Array<keyof ScheduledReport> = ['recipientEmails'];

  constructor() {
    super({ collectionName: 'scheduled_reports' });
    this.setValidator(scheduledReportValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all scheduled reports created by the user
   */
  async getMySchedules(context: SecurityContext): Promise<RepositoryResult<ScheduledReport[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'createdById', operator: '==', value: context.userId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const schedules = this.snapshotToSchedules(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getMySchedules',
        count: schedules.length,
      });

      return successResult(schedules);
    } catch (error) {
      return failedResult(error, 'Failed to get user schedules');
    }
  }

  /**
   * Get scheduled reports where user is a recipient
   */
  async getWhereRecipient(context: SecurityContext): Promise<RepositoryResult<ScheduledReport[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'recipientUserIds', operator: 'array-contains', value: context.userId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const schedules = this.snapshotToSchedules(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getWhereRecipient',
        count: schedules.length,
      });

      return successResult(schedules);
    } catch (error) {
      return failedResult(error, 'Failed to get recipient schedules');
    }
  }

  /**
   * Get all schedules for a specific report
   */
  async getByReportId(
    context: SecurityContext,
    reportId: string
  ): Promise<RepositoryResult<ScheduledReport[]>> {
    try {
      if (!isValidDocumentId(reportId)) {
        return failedResult(new InvalidArgumentError('Invalid report ID', 'reportId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'reportId', operator: '==', value: reportId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const schedules = this.snapshotToSchedules(snapshot);

      // Filter to schedules user can access (creator or recipient)
      const accessibleSchedules = schedules.filter(
        (s) =>
          s.createdById === context.userId ||
          s.recipientUserIds.includes(context.userId) ||
          ['admin', 'owner'].includes(context.userRole)
      );

      await this.logAudit(context, 'list', null, {
        action: 'getByReportId',
        reportId,
        count: accessibleSchedules.length,
      });

      return successResult(accessibleSchedules);
    } catch (error) {
      return failedResult(error, 'Failed to get schedules by report');
    }
  }

  /**
   * Get active schedules due for execution (Cloud Function use)
   * This is designed to be called by Cloud Functions with admin context
   */
  async getDueForExecution(
    context: SecurityContext,
    beforeTime: Date
  ): Promise<RepositoryResult<ScheduledReport[]>> {
    try {
      // This should only be called with admin context
      if (!['admin', 'owner'].includes(context.userRole) && context.userId !== 'system') {
        return failedResult(
          new AuthorizationError(
            'Only system/admin can query due schedules',
            'getDueForExecution',
            context.userRole
          )
        );
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'isActive', operator: '==', value: true },
          { field: 'nextSendAt', operator: '<=', value: beforeTime },
        ],
        orderBy: { field: 'nextSendAt', direction: 'asc' },
        limit: 100, // Process in batches
      });

      const snapshot = await getDocs(q);
      const schedules = this.snapshotToSchedules(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getDueForExecution',
        count: schedules.length,
        beforeTime: beforeTime.toISOString(),
      });

      return successResult(schedules);
    } catch (error) {
      return failedResult(error, 'Failed to get due schedules');
    }
  }

  /**
   * Update last sent timestamp and calculate next send time
   */
  async updateAfterExecution(
    context: SecurityContext,
    scheduleId: string,
    nextSendAt: Date
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(new InvalidArgumentError('Invalid schedule ID', 'scheduleId'));
      }

      const result = await this.update(context, scheduleId, {
        lastSentAt: new Date(),
        nextSendAt,
        lastError: undefined,
        lastErrorAt: undefined,
      });

      if (result.success) {
        await this.logAudit(context, 'update', scheduleId, {
          action: 'updateAfterExecution',
          nextSendAt: nextSendAt.toISOString(),
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update schedule after execution');
    }
  }

  /**
   * Record execution error
   */
  async recordError(
    context: SecurityContext,
    scheduleId: string,
    errorMessage: string
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(new InvalidArgumentError('Invalid schedule ID', 'scheduleId'));
      }

      const result = await this.update(context, scheduleId, {
        lastError: errorMessage,
        lastErrorAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', scheduleId, {
          action: 'recordError',
          error: errorMessage.substring(0, 200), // Truncate for audit
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to record error');
    }
  }

  /**
   * Toggle schedule active status
   */
  async setActive(
    context: SecurityContext,
    scheduleId: string,
    isActive: boolean
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(new InvalidArgumentError('Invalid schedule ID', 'scheduleId'));
      }

      // Check permissions (only creator or admin can modify)
      const existing = await this.getById(context, scheduleId);
      if (!existing.success) {
        return existing;
      }

      if (
        existing.data.createdById !== context.userId &&
        !['admin', 'owner'].includes(context.userRole)
      ) {
        return failedResult(
          new AuthorizationError(
            'Only schedule creator or admin can modify active status',
            'setActive',
            context.userRole
          )
        );
      }

      const result = await this.update(context, scheduleId, { isActive });

      if (result.success) {
        await this.logAudit(context, 'update', scheduleId, {
          action: 'setActive',
          isActive,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update schedule status');
    }
  }

  // ============================================
  // Override Methods for Permission Checks
  // ============================================

  /**
   * Override delete to check permissions
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    try {
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      // Check permissions
      if (
        existing.data.createdById !== context.userId &&
        !['admin', 'owner'].includes(context.userRole)
      ) {
        return failedResult(
          new AuthorizationError(
            'Only schedule creator or admin can delete',
            'delete',
            context.userRole
          )
        );
      }

      return super.delete(context, id);
    } catch (error) {
      return failedResult(error, 'Failed to delete schedule');
    }
  }

  /**
   * Override update to check permissions
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<ScheduledReport>
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return existing;
      }

      // Check permissions (system user can update for execution)
      if (
        context.userId !== 'system' &&
        existing.data.createdById !== context.userId &&
        !['admin', 'owner'].includes(context.userRole)
      ) {
        return failedResult(
          new AuthorizationError(
            'Only schedule creator or admin can modify',
            'update',
            context.userRole
          )
        );
      }

      // Prevent changing creator
      if (data.createdById !== undefined && data.createdById !== existing.data.createdById) {
        return failedResult(
          new InvalidArgumentError('Cannot change schedule creator', 'createdById')
        );
      }

      return super.update(context, id, data);
    } catch (error) {
      return failedResult(error, 'Failed to update schedule');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  /**
   * Convert Firestore snapshot to ScheduledReport array
   */
  private snapshotToSchedules(snapshot: QuerySnapshot<DocumentData>): ScheduledReport[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        businessId: data.businessId as string,
        reportId: data.reportId as string,
        reportName: data.reportName as string,
        frequency: data.frequency as ScheduledReportFrequency,
        timeOfDay: data.timeOfDay as string,
        dayOfWeek: data.dayOfWeek as number | undefined,
        dayOfMonth: data.dayOfMonth as number | undefined,
        timezone: data.timezone as string || 'UTC',
        format: data.format as ScheduledReportFormat,
        includeChart: data.includeChart as boolean ?? true,
        recipientUserIds: (data.recipientUserIds as string[]) || [],
        recipientEmails: (data.recipientEmails as string[]) || [],
        createdById: data.createdById as string,
        createdByName: data.createdByName as string | undefined,
        isActive: data.isActive as boolean ?? true,
        lastSentAt: data.lastSentAt?.toDate?.() || undefined,
        nextSendAt: data.nextSendAt?.toDate?.() || undefined,
        lastError: data.lastError as string | undefined,
        lastErrorAt: data.lastErrorAt?.toDate?.() || undefined,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// ============================================
// Export singleton instance
// ============================================

let scheduledReportRepository: ScheduledReportRepository | null = null;

export function getScheduledReportRepository(): ScheduledReportRepository {
  if (!scheduledReportRepository) {
    scheduledReportRepository = new ScheduledReportRepository();
  }
  return scheduledReportRepository;
}
