/**
 * Audit Log Repository
 * Firestore data access for audit logs
 *
 * Agent CRM-28 Implementation
 * HIPAA Compliance: Stores comprehensive audit trail for all CRM mutations
 *
 * Storage Path: businesses/{businessId}/auditLogs/{logId}
 * Indexes: timestamp (desc), userId, entityType, entityId
 */

import { Timestamp } from 'firebase/firestore';
import type { WhereFilterOp } from 'firebase/firestore';
import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  QueryOptions,
  RepositoryResult,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  ValidationError,
  failedResult,
  successResult,
  InvalidArgumentError,
} from '../errors/repository-errors';
import type {
  AuditEntry,
  AuditLogFilters,
  AuditLogResult,
  AuditAction,
  AuditEntityType,
} from '../../types/audit';
import { getAccessibleTeamScope, sanitizeTeamIds } from '../../lib/security-context';

/**
 * Restrict audit visibility for non-org-privileged users.
 * Managers only see entries tied to their managedTeamIds/teamIds (fail-closed without metadata).
 * Staff/others only see their own entries.
 */
export function filterAuditEntriesForContext(
  context: SecurityContext,
  entries: AuditEntry[]
): AuditEntry[] {
  const role = (context.userRole || '').toLowerCase();
  if (role === 'owner' || role === 'admin') {
    return entries;
  }

  if (role === 'manager') {
    const scope = getAccessibleTeamScope(context);
    if (scope.allTeamIds.length === 0) {
      return [];
    }

    return entries.filter((entry) => {
      const meta = entry.metadata || {};
      const entryTeams = sanitizeTeamIds(
        Array.isArray(meta.teamIds)
          ? meta.teamIds
          : Array.isArray(meta.managedTeamIds)
            ? meta.managedTeamIds
            : []
      );

      if (entryTeams.length === 0) {
        return false;
      }

      return entryTeams.some((teamId) => scope.allTeamIds.includes(teamId));
    });
  }

  // Staff, clients, and front desk users see only their own audit trail.
  return entries.filter((entry) => entry.userId === context.userId);
}

// ============================================
// Validator
// ============================================

/**
 * Validate audit entry data
 */
export function validateAuditEntry(data: Partial<AuditEntry>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Required fields validation
  if (data.userId !== undefined && !data.userId?.trim()) {
    errors.push({
      field: 'userId',
      message: 'User ID is required',
      code: 'REQUIRED',
    });
  }

  if (data.userName !== undefined && !data.userName?.trim()) {
    errors.push({
      field: 'userName',
      message: 'User name is required',
      code: 'REQUIRED',
    });
  }

  if (data.action !== undefined) {
    const validActions: AuditAction[] = [
      'create',
      'update',
      'delete',
      'read',
      'convert',
      'merge',
      'export',
      'import',
      'integration',
      'webhook',
      'automation',
    ];
    if (!validActions.includes(data.action)) {
      errors.push({
        field: 'action',
        message: 'Invalid action type',
        code: 'INVALID_VALUE',
      });
    }
  }

  if (data.entityType !== undefined) {
    const validEntityTypes: AuditEntityType[] = [
      'lead',
      'deal',
      'contact',
      'company',
      'activity',
      'pipeline',
      'stage',
      'report',
      'reportView',
      'importJob',
      'exportJob',
      'integration',
      'webhook',
      'automationRule',
      'automationRun',
    ];
    if (!validEntityTypes.includes(data.entityType)) {
      errors.push({
        field: 'entityType',
        message: 'Invalid entity type',
        code: 'INVALID_VALUE',
      });
    }
  }

  if (data.entityId !== undefined && !data.entityId?.trim()) {
    errors.push({
      field: 'entityId',
      message: 'Entity ID is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Audit Repository Class
// ============================================

/**
 * AuditRepository
 * Provides CRUD operations and query methods for audit logs
 */
export class AuditRepository extends BaseRepository<AuditEntry & { createdAt: Date }> {
  constructor() {
    super({
      collectionName: 'auditLogs',
      softDelete: false, // Never soft delete audit logs
    });
    this.setValidator(validateAuditEntry as Validator<AuditEntry>);
  }

  // ============================================
  // Create Override (with auto-timestamping)
  // ============================================

  /**
   * Create a new audit log entry
   * Timestamp is auto-generated if not provided
   */
  async create(
    context: SecurityContext,
    data: Omit<AuditEntry, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<AuditEntry>> {
    // Ensure timestamp is set
    const entryData = {
      ...data,
      businessId: context.businessId,
      timestamp: data.timestamp || new Date(),
      createdAt: data.timestamp || new Date(), // Add createdAt
    };

    return super.create(context, entryData, customId);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get audit logs with filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: AuditLogFilters
  ): Promise<RepositoryResult<AuditLogResult>> {
    const whereClause = [];
    const options: QueryOptions = {
      limit: filters.limit || 100,
      orderBy: { field: 'timestamp', direction: 'desc' },
    };

    // Apply filters
    if (filters.userId) {
      whereClause.push({ field: 'userId', operator: '==' as WhereFilterOp, value: filters.userId });
    }

    if (filters.entityType) {
      whereClause.push({ field: 'entityType', operator: '==' as WhereFilterOp, value: filters.entityType });
    }

    if (filters.action) {
      whereClause.push({ field: 'action', operator: '==' as WhereFilterOp, value: filters.action });
    }

    if (filters.entityId) {
      whereClause.push({ field: 'entityId', operator: '==' as WhereFilterOp, value: filters.entityId });
    }

    // Date range filtering
    if (filters.startDate) {
      whereClause.push({
        field: 'timestamp',
        operator: '>=' as WhereFilterOp,
        value: Timestamp.fromDate(filters.startDate),
      });
    }

    if (filters.endDate) {
      whereClause.push({
        field: 'timestamp',
        operator: '<=' as WhereFilterOp,
        value: Timestamp.fromDate(filters.endDate),
      });
    }

    // Pagination
    if (filters.startAfter) {
      options.startAfter = filters.startAfter;
    }

    options.where = whereClause;

    const result = await this.getAll(context, options);

    if (!result.success) {
      return failedResult(result.error);
    }

    const scopedEntries = filterAuditEntriesForContext(context, result.data.data);

    return successResult({
      entries: scopedEntries,
      hasMore: scopedEntries.length > 0 && result.data.hasMore,
      lastDoc: scopedEntries.length > 0 ? result.data.lastDoc : undefined,
    });
  }

  /**
   * Get audit logs for a specific entity
   */
  async getByEntity(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    limit: number = 50
  ): Promise<RepositoryResult<AuditEntry[]>> {
    const result = await this.getAll(context, {
      where: [
        { field: 'entityType', operator: '==', value: entityType },
        { field: 'entityId', operator: '==', value: entityId },
      ],
      orderBy: { field: 'timestamp', direction: 'desc' },
      limit,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(filterAuditEntriesForContext(context, result.data.data));
  }

  /**
   * Get audit logs by user
   */
  async getByUser(
    context: SecurityContext,
    userId: string,
    limit: number = 100
  ): Promise<RepositoryResult<AuditEntry[]>> {
    const result = await this.getAll(context, {
      where: [{ field: 'userId', operator: '==', value: userId }],
      orderBy: { field: 'timestamp', direction: 'desc' },
      limit,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(filterAuditEntriesForContext(context, result.data.data));
  }

  /**
   * Get audit logs by action type
   */
  async getByAction(
    context: SecurityContext,
    action: AuditAction,
    limit: number = 100
  ): Promise<RepositoryResult<AuditEntry[]>> {
    const result = await this.getAll(context, {
      where: [{ field: 'action', operator: '==', value: action }],
      orderBy: { field: 'timestamp', direction: 'desc' },
      limit,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(filterAuditEntriesForContext(context, result.data.data));
  }

  /**
   * Get recent audit logs (last N days)
   */
  async getRecent(
    context: SecurityContext,
    days: number = 7,
    limit: number = 100
  ): Promise<RepositoryResult<AuditEntry[]>> {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const result = await this.getAll(context, {
      where: [
        {
          field: 'timestamp',
          operator: '>=',
          value: Timestamp.fromDate(startDate),
        },
      ],
      orderBy: { field: 'timestamp', direction: 'desc' },
      limit,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(filterAuditEntriesForContext(context, result.data.data));
  }

  /**
   * Delete old audit logs (for retention policy)
   * Should be called periodically by a scheduled job
   */
  async deleteOldEntries(
    context: SecurityContext,
    retentionDays: number
  ): Promise<RepositoryResult<number>> {
    if (retentionDays <= 0) {
      return failedResult(
        new InvalidArgumentError('Retention days must be a positive number')
      );
    }

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    // Get old entries
    const result = await this.getAll(context, {
      where: [
        {
          field: 'timestamp',
          operator: '<',
          value: Timestamp.fromDate(cutoffDate),
        },
      ],
      limit: 500, // Process in batches to avoid overwhelming Firestore
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    let deletedCount = 0;

    // Delete in batches
    for (const entry of result.data.data) {
      const deleteResult = await this.delete(context, entry.id);
      if (deleteResult.success) {
        deletedCount++;
      }
    }

    return successResult(deletedCount);
  }

  // ============================================
  // Override: Prevent updates and deletes
  // ============================================

  /**
   * Override update to prevent modification of audit logs
   * Audit logs should be immutable per HIPAA compliance
   */
  async update(
    _context: SecurityContext,
    _id: string,
    _data: Partial<Omit<AuditEntry, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<AuditEntry>> {
    return failedResult(
      new ValidationError('Audit logs are immutable and cannot be updated', [
        {
          field: 'audit',
          message: 'Audit logs cannot be modified',
        },
      ])
    );
  }

  /**
   * Override delete to prevent manual deletion
   * Only automated retention policy should delete audit logs
   * This can be bypassed using deleteOldEntries method
   */
  async delete(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    // Allow deletion through base class (used by deleteOldEntries)
    return super.delete(context, id);
  }
}

// Export singleton instance factory
let auditRepositoryInstance: AuditRepository | null = null;

export function getAuditRepository(): AuditRepository {
  if (!auditRepositoryInstance) {
    auditRepositoryInstance = new AuditRepository();
  }
  return auditRepositoryInstance;
}
