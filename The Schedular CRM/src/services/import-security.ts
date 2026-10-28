/**
 * Import Security & RBAC Utilities
 * Agent M4 - Security & RBAC Implementation
 *
 * Enforces role-based access control for CSV import operations
 * Per HIPAA compliance: validates permissions and ensures audit logging
 */

// ============================================
// RBAC Configuration
// ============================================

/**
 * Roles allowed to import data
 * Per security requirements: owner, admin, manager, sales, staff
 */
const LEGACY_ROLE_MAP = {
  assistant: 'frontDesk',
  sales_rep: 'sales',
  marketing: 'sales',
  user: 'staff',
} as const;

const ALLOWED_IMPORT_ROLES = ['owner', 'admin', 'manager', 'sales', 'staff'] as const;

/**
 * Roles denied import access
 */
const DENIED_IMPORT_ROLES = ['client', 'viewer', 'frontDesk', 'guest'] as const;

// ============================================
// Role Validation Functions
// ============================================

/**
 * Validate if the user role is allowed to import data
 * @param role - User role to validate
 * @returns true if role is allowed, false otherwise
 */
export function isAllowedToImport(role: string): boolean {
  const normalizedRole =
    LEGACY_ROLE_MAP[role.toLowerCase().trim() as keyof typeof LEGACY_ROLE_MAP] ??
    role.toLowerCase().trim();
  return ALLOWED_IMPORT_ROLES.includes(normalizedRole as any);
}

/**
 * Validate import authorization
 * @param role - User role
 * @throws Error if role is not authorized
 */
export function validateImportAuthorization(role: string): void {
  if (!role || role.trim() === '') {
    throw new Error('Access denied: No role specified for import operation');
  }

  if (!isAllowedToImport(role)) {
    const normalizedRole = role.toLowerCase().trim();
    if (DENIED_IMPORT_ROLES.includes(normalizedRole as any)) {
      throw new Error(
        `Access denied: Role '${role}' is not authorized to import data. ` +
        `Only ${ALLOWED_IMPORT_ROLES.join(', ')} roles can perform imports.`
      );
    }
    throw new Error(
      `Access denied: Unknown role '${role}'. Allowed roles: ${ALLOWED_IMPORT_ROLES.join(', ')}`
    );
  }
}

/**
 * Validate multi-tenant isolation for import
 * Ensures all operations are scoped to the correct businessId
 * @param businessId - Business ID for the import
 * @param userBusinessId - User's business ID
 * @throws Error if businessId mismatch detected
 */
export function validateBusinessIdIsolation(
  businessId: string,
  userBusinessId: string
): void {
  if (!businessId || businessId.trim() === '') {
    throw new Error('Security violation: No businessId specified for import operation');
  }

  if (!userBusinessId || userBusinessId.trim() === '') {
    throw new Error('Security violation: No userBusinessId found in context');
  }

  if (businessId !== userBusinessId) {
    throw new Error(
      `Security violation: Attempted cross-tenant import. ` +
      `User businessId: ${userBusinessId}, Import businessId: ${businessId}`
    );
  }
}

// ============================================
// Audit Preparation
// ============================================

/**
 * Prepare audit metadata for import operations
 * Never include PHI in audit logs per HIPAA requirements
 * @param context - Security context with user and business info
 * @param action - Import action type
 * @param entityType - Type of entity being imported
 * @param entityIds - IDs of entities (max 10 for logging)
 * @returns Audit metadata object (NO PHI)
 */
export function prepareImportAuditMetadata(
  context: {
    businessId: string;
    userId: string;
    userName: string;
    userRole: string;
  },
  action: 'import' | 'import_validation' | 'import_rollback',
  entityType: string,
  options: {
    totalRows?: number;
    importedCount?: number;
    skippedCount?: number;
    errorCount?: number;
    duplicateHandling?: string;
    dryRun?: boolean;
    entityIds?: string[];
  } = {}
): {
  businessId: string;
  userId: string;
  userName: string;
  userRole: string;
  action: string;
  entityType: string;
  metadata: Record<string, unknown>;
} {
  // CRITICAL: Never include PHI (names, emails, phones, etc.) in audit logs
  const metadata: Record<string, unknown> = {
    action,
    entityType,
    totalRows: options.totalRows,
    importedCount: options.importedCount,
    skippedCount: options.skippedCount,
    errorCount: options.errorCount,
    duplicateHandling: options.duplicateHandling,
    dryRun: options.dryRun || false,
  };

  // Include entity IDs (max 10) for tracking, but NEVER include names or other PHI
  if (options.entityIds && options.entityIds.length > 0) {
    metadata.entityIdSample = options.entityIds.slice(0, 10);
    metadata.entityIdCount = options.entityIds.length;
  }

  return {
    businessId: context.businessId,
    userId: context.userId,
    userName: context.userName, // User name is OK, not client PHI
    userRole: context.userRole,
    action,
    entityType,
    metadata,
  };
}

// ============================================
// PHI Safety Validation
// ============================================

/**
 * Validate that no PHI is being logged
 * This is a defensive check to prevent accidental PHI logging
 * @param data - Data to validate
 * @throws Error if PHI fields are detected
 */
export function validateNoPHIInLogs(data: Record<string, unknown>): void {
  const phiFields = ['email', 'phone', 'firstName', 'lastName', 'name', 'address', 'notes'];

  for (const field of phiFields) {
    if (field in data && data[field] !== null && data[field] !== undefined) {
      throw new Error(
        `Security violation: Attempted to log PHI field '${field}'. ` +
        `PHI must never be included in audit logs.`
      );
    }
  }
}

// ============================================
// Export Allowed Roles (for testing/validation)
// ============================================

export const IMPORT_ALLOWED_ROLES = [...ALLOWED_IMPORT_ROLES];
export const IMPORT_DENIED_ROLES = [...DENIED_IMPORT_ROLES];
