/**
 * Audit Log Types
 *
 * Agent CRM-28 Implementation
 * HIPAA Compliance: Comprehensive audit logging for all CRM mutations
 */

// ============================================
// Audit Entry Types
// ============================================

export type AuditAction =
  | 'create'
  | 'update'
  | 'delete'
  | 'read'
  | 'convert'
  | 'merge'
  | 'export'
  | 'import'
  | 'integration'
  | 'webhook'
  | 'automation'
  | 'webhook_endpoint_created'
  | 'webhook_endpoint_updated'
  | 'webhook_endpoint_deleted'
  | 'webhook_secret_regenerated'
  | 'webhook_endpoint_tested'
  | 'webhook_delivery_retried'
  | 'login_failure'
  | 'role_changed'
  | 'staff_deactivated'
  | 'bulk_delete';

export type AuditEntityType =
  | 'lead'
  | 'deal'
  | 'contact'
  | 'company'
  | 'activity'
  | 'pipeline'
  | 'stage'
  | 'report'
  | 'reportView'
  | 'importJob'
  | 'exportJob'
  | 'integration'
  | 'webhook'
  | 'automationRule'
  | 'automationRun'
  | 'calendar_connection'
  | 'calendar_mapping'
  | 'calendar_event'
  | 'reportExport'
  | 'reportingAggregate'
  | 'webhook_endpoint'
  | 'webhook_delivery'
  | 'route';

/**
 * Represents a change to a field
 */
export interface FieldChange {
  old: any;
  new: any;
}

/**
 * Main audit log entry structure
 * Stored at: businesses/{businessId}/auditLogs/{logId}
 */
export interface AuditEntry {
  id: string;
  businessId: string;
  userId: string;
  userName: string;
  action: AuditAction;
  entityType: AuditEntityType;
  entityId: string;
  entityName?: string; // Denormalized entity name for display
  changes?: Record<string, FieldChange>;
  timestamp: Date;
  createdAt: Date; // Added to satisfy BaseEntity constraint
  metadata?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
}

// ============================================
// Query & Filter Types
// ============================================

export interface AuditLogFilters {
  /** Filter by user ID */
  userId?: string;
  /** Filter by entity type */
  entityType?: AuditEntityType;
  /** Filter by action */
  action?: AuditAction;
  /** Filter by entity ID */
  entityId?: string;
  /** Start date for range filter */
  startDate?: Date;
  /** End date for range filter */
  endDate?: Date;
  /** Maximum number of results */
  limit?: number;
  /** Pagination cursor */
  startAfter?: any;
}

/**
 * Result for audit log queries
 */
export interface AuditLogResult {
  entries: AuditEntry[];
  hasMore: boolean;
  lastDoc?: any;
}

// ============================================
// Settings Types
// ============================================

/**
 * Audit log configuration per business
 */
export interface AuditLogSettings {
  /** Whether audit logging is enabled */
  enabled: boolean;
  /** Retention period in days (default: 90) */
  retentionDays: number;
  /** Whether to log IP addresses */
  logIpAddress: boolean;
  /** Whether to log user agents */
  logUserAgent: boolean;
}

/**
 * Default audit log settings
 */
export const DEFAULT_AUDIT_SETTINGS: AuditLogSettings = {
  enabled: true,
  retentionDays: 90,
  logIpAddress: false, // HIPAA: Disable by default to minimize PII
  logUserAgent: false,
};

// ============================================
// Export CSV Types
// ============================================

export interface AuditLogCSVRow {
  timestamp: string;
  user: string;
  action: string;
  entityType: string;
  entityId: string;
  entityName: string;
  changes: string;
}
