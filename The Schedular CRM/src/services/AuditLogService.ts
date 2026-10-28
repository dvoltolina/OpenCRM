/**
 * Audit Log Service
 * High-level API for audit logging
 *
 * Agent CRM-28 Implementation
 * HIPAA Compliance: Comprehensive audit logging for all CRM mutations
 *
 * Usage:
 * - Call logAction() to create audit entries
 * - Call getAuditLog() to query audit history
 * - Integrates with BaseRepository's AuditLogger interface
 */

import { getAuditRepository } from '../data/repositories/audit-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import { resolveTeamIds, sanitizeTeamIds } from '../lib/security-context';
import type {
  AuditEntry,
  AuditAction,
  AuditEntityType,
  AuditLogFilters,
  AuditLogResult,
  FieldChange,
} from '../types/audit';

// ============================================
// HIPAA Compliance Constants
// ============================================

/**
 * HIPAA requires audit log retention for 6 years
 * per 45 CFR 164.530(j) - Documentation retention period
 */
export const HIPAA_RETENTION_DAYS = 2190; // 6 years

// ============================================
// Audit Volume Reduction (matching Flutter app)
// ============================================

/**
 * Critical actions that always get logged (HIPAA/security)
 * Other actions are dropped to reduce Firestore writes
 */
const CRITICAL_ACTIONS: Set<AuditAction> = new Set([
  'delete',           // Destructive - always log
  'export',           // Data export - HIPAA requirement
  'import',           // Bulk data changes
  'merge',            // Data consolidation
  'webhook_endpoint_created',
  'webhook_endpoint_updated',
  'webhook_endpoint_deleted',
  'webhook_secret_regenerated', // Security-critical
]);

/**
 * PHI entity types - log create/update for these
 */
const PHI_ENTITY_TYPES: Set<AuditEntityType> = new Set([
  'lead',
  'deal',
  'contact',
  'company',
]);

/**
 * Throttle cache: key -> last log timestamp
 * Prevents duplicate writes for same user/action/entity within window
 */
const throttleCache: Map<string, number> = new Map();
const THROTTLE_WINDOW_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Check if an audit entry should be logged based on:
 * 1. Critical action type
 * 2. PHI entity mutation
 * 3. Throttle window
 */
function shouldLogAudit(
  action: AuditAction,
  entityType: AuditEntityType,
  businessId: string,
  userId: string,
  entityId: string
): boolean {
  // Always log critical actions
  if (CRITICAL_ACTIONS.has(action)) {
    return true;
  }

  // Log PHI entity mutations (create/update) but throttle them
  if (PHI_ENTITY_TYPES.has(entityType) && (action === 'create' || action === 'update')) {
    const throttleKey = `${businessId}:${userId}:${action}:${entityType}:${entityId}`;
    const now = Date.now();
    const lastLog = throttleCache.get(throttleKey);

    if (lastLog && now - lastLog < THROTTLE_WINDOW_MS) {
      return false; // Throttled - skip this write
    }

    throttleCache.set(throttleKey, now);

    // Cleanup old entries periodically (every 100 entries)
    if (throttleCache.size > 1000) {
      const cutoff = now - THROTTLE_WINDOW_MS;
      for (const [key, timestamp] of throttleCache) {
        if (timestamp < cutoff) {
          throttleCache.delete(key);
        }
      }
    }

    return true;
  }

  // Skip all other actions (read, list, non-critical updates)
  return false;
}

// ============================================
// Types
// ============================================

export interface LogActionOptions {
  action: AuditAction;
  entityType: AuditEntityType;
  entityId: string;
  entityName?: string;
  changes?: Record<string, FieldChange>;
  metadata?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
}

export interface AuditServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

function mergeTeamScopeMetadata(
  context: SecurityContext,
  metadata?: Record<string, any>
): Record<string, any> {
  const base = metadata ? { ...metadata } : {};
  const contextTeams = sanitizeTeamIds(context.teamIds);
  const contextManagedTeams = sanitizeTeamIds(context.managedTeamIds);
  const metaTeams = Array.isArray(base.teamIds) ? sanitizeTeamIds(base.teamIds) : [];
  const metaManagedTeams = Array.isArray(base.managedTeamIds)
    ? sanitizeTeamIds(base.managedTeamIds)
    : [];

  const teamIds = resolveTeamIds([
    ...contextTeams,
    ...contextManagedTeams,
    ...metaTeams,
    ...metaManagedTeams,
  ]);
  const managedTeamIds = resolveTeamIds([...contextManagedTeams, ...metaManagedTeams]);

  return {
    ...base,
    teamIds,
    managedTeamIds,
  };
}

// ============================================
// Audit Log Service
// ============================================

export class AuditLogService {
  /**
   * Determine whether audit logging is enabled for this context.
   * HIPAA businesses are always logged even if a toggle is disabled.
   */
  private isAuditEnabled(context: SecurityContext): boolean {
    const requiresHipaaCompliance = context.requiresHipaaCompliance === true;
    const auditLoggingEnabled = context.auditLoggingEnabled === true;
    return requiresHipaaCompliance || auditLoggingEnabled;
  }

  /**
   * Log a CRM action
   * Applies volume reduction: only logs critical actions and throttled PHI mutations
   */
  async logAction(
    context: SecurityContext,
    options: LogActionOptions
  ): Promise<AuditServiceResult<AuditEntry>> {
    if (!this.isAuditEnabled(context)) {
      return { success: true, data: undefined };
    }

    // Check if this audit entry should be logged (volume reduction)
    if (!shouldLogAudit(
      options.action,
      options.entityType,
      context.businessId,
      context.userId,
      options.entityId
    )) {
      // Silently skip non-critical/throttled entries
      return {
        success: true,
        data: undefined,
      };
    }

    const auditRepo = getAuditRepository();

    const entryData: Omit<AuditEntry, 'id' | 'createdAt' | 'updatedAt'> = {
      businessId: context.businessId,
      userId: context.userId,
      userName: context.userName,
      action: options.action,
      entityType: options.entityType,
      entityId: options.entityId,
      entityName: options.entityName,
      changes: options.changes,
      timestamp: new Date(),
      metadata: mergeTeamScopeMetadata(context, options.metadata),
      ipAddress: options.ipAddress,
      userAgent: options.userAgent,
    };

    const result = await auditRepo.create(context, entryData);

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
   * Get audit log with filters
   */
  async getAuditLog(
    context: SecurityContext,
    filters: AuditLogFilters = {}
  ): Promise<AuditServiceResult<AuditLogResult>> {
    const auditRepo = getAuditRepository();

    const result = await auditRepo.getFiltered(context, filters);

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
   * Get audit logs for a specific entity
   */
  async getEntityHistory(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    limit: number = 50
  ): Promise<AuditServiceResult<AuditEntry[]>> {
    const auditRepo = getAuditRepository();

    const result = await auditRepo.getByEntity(context, entityType, entityId, limit);

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
   * Get audit logs by user
   */
  async getUserActivity(
    context: SecurityContext,
    userId: string,
    limit: number = 100
  ): Promise<AuditServiceResult<AuditEntry[]>> {
    const auditRepo = getAuditRepository();

    const result = await auditRepo.getByUser(context, userId, limit);

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
   * Get recent audit logs
   */
  async getRecentActivity(
    context: SecurityContext,
    days: number = 7,
    limit: number = 100
  ): Promise<AuditServiceResult<AuditEntry[]>> {
    const auditRepo = getAuditRepository();

    const result = await auditRepo.getRecent(context, days, limit);

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
   * Clean up old audit logs based on retention policy
   * Should be called by scheduled job
   *
   * HIPAA Compliance: Default retention is 6 years (2190 days)
   * per 45 CFR 164.530(j) which requires maintaining records for 6 years
   */
  async cleanupOldLogs(
    context: SecurityContext,
    retentionDays: number = HIPAA_RETENTION_DAYS
  ): Promise<AuditServiceResult<number>> {
    const auditRepo = getAuditRepository();

    const result = await auditRepo.deleteOldEntries(context, retentionDays);

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

  // ============================================
  // Convenience Methods for Common Actions
  // ============================================

  /**
   * Log entity creation
   */
  async logCreate(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    entityName?: string,
    metadata?: Record<string, any>
  ): Promise<AuditServiceResult<AuditEntry>> {
    return this.logAction(context, {
      action: 'create',
      entityType,
      entityId,
      entityName,
      metadata,
    });
  }

  /**
   * Log entity update with changes
   */
  async logUpdate(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    changes: Record<string, FieldChange>,
    entityName?: string,
    metadata?: Record<string, any>
  ): Promise<AuditServiceResult<AuditEntry>> {
    return this.logAction(context, {
      action: 'update',
      entityType,
      entityId,
      entityName,
      changes,
      metadata,
    });
  }

  /**
   * Log entity deletion
   */
  async logDelete(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    entityName?: string,
    metadata?: Record<string, any>
  ): Promise<AuditServiceResult<AuditEntry>> {
    return this.logAction(context, {
      action: 'delete',
      entityType,
      entityId,
      entityName,
      metadata,
    });
  }

  /**
   * Log entity conversion (e.g., lead to deal)
   */
  async logConversion(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    entityName?: string,
    metadata?: Record<string, any>
  ): Promise<AuditServiceResult<AuditEntry>> {
    return this.logAction(context, {
      action: 'convert',
      entityType,
      entityId,
      entityName,
      metadata,
    });
  }

  /**
   * Log entity merge
   */
  async logMerge(
    context: SecurityContext,
    entityType: AuditEntityType,
    entityId: string,
    entityName?: string,
    metadata?: Record<string, any>
  ): Promise<AuditServiceResult<AuditEntry>> {
    return this.logAction(context, {
      action: 'merge',
      entityType,
      entityId,
      entityName,
      metadata,
    });
  }

  // ============================================
  // Utility: Create FieldChange from old/new values
  // ============================================

  /**
   * Helper to create changes object from old and new entity
   */
  static createChanges<T extends Record<string, any>>(
    oldEntity: T,
    newEntity: Partial<T>
  ): Record<string, FieldChange> {
    const changes: Record<string, FieldChange> = {};

    for (const key in newEntity) {
      if (Object.prototype.hasOwnProperty.call(newEntity, key)) {
        const oldValue = oldEntity[key];
        const newValue = newEntity[key];

        // Skip if values are the same
        if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) {
          changes[key] = {
            old: oldValue,
            new: newValue,
          };
        }
      }
    }

    return changes;
  }
}

// Test-only utility to clear throttle cache
export function __resetAuditThrottleForTests() {
  throttleCache.clear();
}

// ============================================
// Singleton Instance
// ============================================

let auditLogServiceInstance: AuditLogService | null = null;

export function getAuditLogService(): AuditLogService {
  if (!auditLogServiceInstance) {
    auditLogServiceInstance = new AuditLogService();
  }
  return auditLogServiceInstance;
}

// ============================================
// AuditLogger Implementation for BaseRepository
// ============================================

import type { AuditLogger, AuditLogEntry } from '../data/repositories/repository-types';

/**
 * Adapter to use AuditLogService as BaseRepository's AuditLogger
 */
export class RepositoryAuditLogger implements AuditLogger {
  private service: AuditLogService;

  constructor(service?: AuditLogService) {
    this.service = service || getAuditLogService();
  }

  async log(entry: AuditLogEntry): Promise<void> {
    const requiresHipaaCompliance = entry.requiresHipaaCompliance === true;
    const auditLoggingEnabled = requiresHipaaCompliance || entry.auditLoggingEnabled === true;

    if (!auditLoggingEnabled) {
      return;
    }

    const context: SecurityContext = {
      businessId: entry.businessId,
      userId: entry.userId,
      userName: entry.userName,
      userRole: 'admin', // Default role for audit logging
      requiresHipaaCompliance,
      auditLoggingEnabled,
    };

    // Map repository actions to audit actions
    const actionMap: Record<string, AuditAction> = {
      create: 'create',
      update: 'update',
      delete: 'delete',
      read: 'update', // Map read to update (we mainly care about mutations)
      list: 'update',
      batch: 'update',
    };

    const auditAction = actionMap[entry.action] || 'update';

    // Only log mutations (not reads/lists)
    if (entry.action === 'read' || entry.action === 'list') {
      return; // Skip read operations to reduce log volume
    }

    // Map entity types
    const entityTypeMap: Record<string, AuditEntityType | null> = {
      sales_activities: 'activity',
      leads: 'lead',
      deals: 'deal',
      clients: 'contact',
      companies: 'company',
      pipelines: 'pipeline',
      stages: 'stage',
    };

    const entityType = entityTypeMap[entry.entityType];
    if (!entityType) {
      return; // Skip unknown entity types
    }

    if (!entry.entityId) {
      return; // Skip entries without entityId
    }

    await this.service.logAction(context, {
      action: auditAction,
      entityType,
      entityId: entry.entityId,
      metadata: entry.details,
      ipAddress: undefined,
      userAgent: undefined,
    });
  }
}
