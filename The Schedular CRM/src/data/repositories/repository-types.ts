/**
 * Repository Types
 * Shared interfaces for the repository pattern
 *
 * HIPAA Compliance: SecurityContext ensures multi-tenant isolation
 * and provides audit trail information for all data access operations.
 */

import type { DocumentSnapshot, WhereFilterOp, OrderByDirection } from 'firebase/firestore';

// ============================================
// Security Context (HIPAA Compliance)
// ============================================

/**
 * SecurityContext provides multi-tenant isolation and audit trail information.
 * MUST be passed to all repository operations per HIPAA compliance requirements.
 */
export interface SecurityContext {
  /** The business ID for multi-tenant scoping - all queries MUST filter by this */
  businessId: string;
  /** Current user ID for audit trail */
  userId: string;
  /** Current user display name for denormalized audit fields */
  userName: string;
  /** User's role for permission checks */
  userRole: string;
  /** Team membership for access-controlled resources */
  teamIds?: string[];
  /** Managed teams for manager hierarchy (if applicable) */
  managedTeamIds?: string[];
  /** Direct manager identifier (if applicable) */
  managerId?: string;
  /** Whether this business requires HIPAA compliance (forces audit logging on) */
  requiresHipaaCompliance?: boolean;
  /** Whether audit logging is enabled for this business (defaults to true) */
  auditLoggingEnabled?: boolean;
}

// ============================================
// Repository Options
// ============================================

/**
 * Options for repository instantiation
 */
export interface RepositoryOptions {
  /** Enable soft delete instead of hard delete */
  softDelete?: boolean;
  /** Collection name for this repository */
  collectionName: string;
}

// ============================================
// Query Types
// ============================================

/**
 * Where clause for filtering queries
 */
export interface WhereClause {
  field: string;
  operator: WhereFilterOp | string;
  value: unknown;
}

/**
 * Order by clause for sorting
 */
export interface OrderByClause {
  field: string;
  direction: OrderByDirection;
}

/**
 * Options for querying collections
 */
export interface QueryOptions {
  /** Maximum number of documents to return */
  limit?: number;
  /** Cursor for pagination - start after this document */
  startAfter?: DocumentSnapshot;
  /** Order by configuration */
  orderBy?: OrderByClause;
  /** Additional order by clauses for compound sorting */
  orderByMultiple?: OrderByClause[];
  /** Where clauses for filtering */
  where?: WhereClause[];
}

/**
 * Paginated result with cursor support
 */
export interface PaginatedResult<T> {
  data: T[];
  /** Last document for pagination cursor */
  lastDoc: DocumentSnapshot | null;
  /** Whether more results exist */
  hasMore: boolean;
  /** Total count (if available, requires separate query) */
  totalCount?: number;
}

// ============================================
// Repository Result Types
// ============================================

/**
 * Error codes for repository operations
 */
export type RepositoryErrorCode =
  | 'NOT_FOUND'
  | 'PERMISSION_DENIED'
  | 'VALIDATION_ERROR'
  | 'NETWORK_ERROR'
  | 'ALREADY_EXISTS'
  | 'INVALID_ARGUMENT'
  | 'UNKNOWN';

/**
 * Structured error from repository operations
 */
export interface RepositoryErrorDetails {
  code: RepositoryErrorCode;
  message: string;
  field?: string;
  originalError?: unknown;
}

/**
 * Result type for repository operations - either success with data or failure with error
 * Using discriminated union for type-safe error handling
 */
export type RepositoryResult<T> =
  | { success: true; data: T; error: null }
  | { success: false; data: null; error: RepositoryErrorDetails };

// ============================================
// Audit Log Types (HIPAA Compliance)
// ============================================

/**
 * Audit log entry for tracking data access and modifications
 */
export interface AuditLogEntry {
  /** Action performed (create, read, update, delete, list) */
  action: 'create' | 'read' | 'update' | 'delete' | 'list' | 'batch';
  /** Entity type (collection name) */
  entityType: string;
  /** Entity ID (document ID) - null for list operations */
  entityId: string | null;
  /** Business ID for multi-tenant context */
  businessId: string;
  /** User who performed the action */
  userId: string;
  userName: string;
  /** Timestamp of the action */
  timestamp: Date;
  /** Additional details about the operation */
  details?: Record<string, unknown>;
  /** Source of the operation (service/component name) */
  source?: string;
  /** Business-level compliance flags propagated for conditional audit logging */
  requiresHipaaCompliance?: boolean;
  auditLoggingEnabled?: boolean;
}

/**
 * Audit logger interface - implementations can log to Firestore, console, etc.
 */
export interface AuditLogger {
  log(entry: AuditLogEntry): Promise<void>;
}

// ============================================
// Base Entity Interface
// ============================================

/**
 * Base interface for all entities with common fields
 */
export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt?: Date;
  /** Soft delete flag - only present if soft delete is enabled */
  isDeleted?: boolean;
  /** Soft delete timestamp */
  deletedAt?: Date;
}

// ============================================
// Subscription Types
// ============================================

/**
 * Callback for real-time subscription updates
 */
export type SubscriptionCallback<T> = (data: T[], error?: Error) => void;

/**
 * Unsubscribe function returned by subscribe methods
 */
export type Unsubscribe = () => void;

// ============================================
// Batch Operation Types
// ============================================

/**
 * Operation type for batch operations
 */
export type BatchOperationType = 'create' | 'update' | 'delete';

/**
 * Single operation in a batch
 */
export interface BatchOperation<T> {
  type: BatchOperationType;
  id?: string; // Required for update/delete
  data?: Partial<T>; // Required for create/update
}

/**
 * Result of a batch operation
 */
export interface BatchResult {
  success: boolean;
  /** Number of operations that succeeded */
  successCount: number;
  /** Number of operations that failed */
  failureCount: number;
  /** IDs of created documents (for create operations) */
  createdIds?: string[];
  /** Errors encountered during batch */
  errors?: RepositoryErrorDetails[];
}

// ============================================
// Validation Types
// ============================================

/**
 * Validation result for entity data
 */
export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

/**
 * Single validation error
 */
export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

/**
 * Validator function type
 */
export type Validator<T> = (data: Partial<T>) => ValidationResult;
