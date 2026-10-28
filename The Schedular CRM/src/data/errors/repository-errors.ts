/**
 * Repository Error Classes
 * Custom error types for repository operations
 *
 * HIPAA Compliance: Error messages are sanitized to prevent
 * leaking sensitive information. Original errors are preserved
 * for logging but not exposed to clients.
 */

import type { RepositoryErrorCode, RepositoryErrorDetails } from '../repositories/repository-types';

/**
 * Base repository error class
 * All repository-specific errors extend this class
 */
export class RepositoryError extends Error {
  public readonly code: RepositoryErrorCode;
  public readonly field?: string;
  public readonly originalError?: unknown;

  constructor(
    code: RepositoryErrorCode,
    message: string,
    field?: string,
    originalError?: unknown
  ) {
    super(message);
    this.name = 'RepositoryError';
    this.code = code;
    this.field = field;
    this.originalError = originalError;

    // Maintains proper stack trace for where error was thrown
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, RepositoryError);
    }
  }

  /**
   * Convert to RepositoryErrorDetails for Result type
   */
  toDetails(): RepositoryErrorDetails {
    return {
      code: this.code,
      message: this.message,
      field: this.field,
      originalError: this.originalError,
    };
  }

  /**
   * Create a sanitized version safe for client exposure
   * HIPAA: Does not include original error or stack trace
   */
  toSafeDetails(): Omit<RepositoryErrorDetails, 'originalError'> {
    return {
      code: this.code,
      message: this.message,
      field: this.field,
    };
  }
}

/**
 * Document not found error
 */
export class NotFoundError extends RepositoryError {
  public readonly entityType: string;
  public readonly entityId: string;

  constructor(entityType: string, entityId: string) {
    super(
      'NOT_FOUND',
      `${entityType} with ID '${entityId}' not found`
    );
    this.name = 'NotFoundError';
    this.entityType = entityType;
    this.entityId = entityId;
  }
}

/**
 * Permission denied error - used for unauthorized access attempts
 * HIPAA: Log these for security audit trail
 */
export class PermissionError extends RepositoryError {
  public readonly attemptedAction: string;
  public readonly resourceType: string;

  constructor(
    attemptedAction: string,
    resourceType: string,
    details?: string
  ) {
    super(
      'PERMISSION_DENIED',
      details || `Permission denied: cannot ${attemptedAction} ${resourceType}`
    );
    this.name = 'PermissionError';
    this.attemptedAction = attemptedAction;
    this.resourceType = resourceType;
  }
}

/**
 * Validation error for invalid data
 */
export class ValidationError extends RepositoryError {
  public readonly validationErrors: Array<{ field: string; message: string }>;

  constructor(
    message: string,
    validationErrors: Array<{ field: string; message: string }> = [],
    field?: string
  ) {
    super('VALIDATION_ERROR', message, field);
    this.name = 'ValidationError';
    this.validationErrors = validationErrors;
  }

  /**
   * Create from multiple validation errors
   */
  static fromErrors(errors: Array<{ field: string; message: string }>): ValidationError {
    const message = errors.map(e => `${e.field}: ${e.message}`).join('; ');
    return new ValidationError(message, errors);
  }
}

/**
 * Network error for connectivity issues
 */
export class NetworkError extends RepositoryError {
  public readonly isRetryable: boolean;

  constructor(message: string, originalError?: unknown, isRetryable = true) {
    super('NETWORK_ERROR', message, undefined, originalError);
    this.name = 'NetworkError';
    this.isRetryable = isRetryable;
  }
}

/**
 * Already exists error for duplicate documents
 */
export class AlreadyExistsError extends RepositoryError {
  public readonly entityType: string;
  public readonly conflictField?: string;

  constructor(entityType: string, conflictField?: string, conflictValue?: string) {
    const message = conflictField
      ? `${entityType} with ${conflictField} '${conflictValue}' already exists`
      : `${entityType} already exists`;
    super('ALREADY_EXISTS', message, conflictField);
    this.name = 'AlreadyExistsError';
    this.entityType = entityType;
    this.conflictField = conflictField;
  }
}

/**
 * Invalid argument error
 */
export class InvalidArgumentError extends RepositoryError {
  constructor(message: string, field?: string) {
    super('INVALID_ARGUMENT', message, field);
    this.name = 'InvalidArgumentError';
  }
}

/**
 * Authorization error for RBAC violations
 * HIPAA: Log these for security audit trail
 */
export class AuthorizationError extends RepositoryError {
  public readonly requiredRole?: string;
  public readonly userRole?: string;

  constructor(message: string, requiredRole?: string, userRole?: string) {
    super('PERMISSION_DENIED', message);
    this.name = 'AuthorizationError';
    this.requiredRole = requiredRole;
    this.userRole = userRole;
  }
}

// ============================================
// Error Conversion Utilities
// ============================================

/**
 * Convert Firestore error codes to repository error codes
 */
export function mapFirestoreErrorCode(firestoreCode: string): RepositoryErrorCode {
  switch (firestoreCode) {
    case 'not-found':
      return 'NOT_FOUND';
    case 'permission-denied':
    case 'unauthenticated':
      return 'PERMISSION_DENIED';
    case 'invalid-argument':
    case 'failed-precondition':
      return 'VALIDATION_ERROR';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'NETWORK_ERROR';
    case 'already-exists':
      return 'ALREADY_EXISTS';
    default:
      return 'UNKNOWN';
  }
}

/**
 * Convert any error to a RepositoryError
 * HIPAA: Sanitizes error messages to prevent information leakage
 */
export function toRepositoryError(error: unknown, context?: string): RepositoryError {
  // Already a RepositoryError
  if (error instanceof RepositoryError) {
    return error;
  }

  // Firebase/Firestore error
  if (error instanceof Error && 'code' in error) {
    const firestoreError = error as Error & { code: string };
    const code = mapFirestoreErrorCode(firestoreError.code);

    // Sanitize message for HIPAA compliance - don't expose internal details
    let message = context ? `${context}: ` : '';
    switch (code) {
      case 'NOT_FOUND':
        message += 'The requested resource was not found';
        break;
      case 'PERMISSION_DENIED':
        message += 'Access denied';
        break;
      case 'NETWORK_ERROR':
        message += 'Network error occurred. Please try again';
        break;
      default:
        message += 'An error occurred';
    }

    return new RepositoryError(code, message, undefined, error);
  }

  // Generic error
  if (error instanceof Error) {
    return new RepositoryError(
      'UNKNOWN',
      context || 'An unexpected error occurred',
      undefined,
      error
    );
  }

  // Unknown error type
  return new RepositoryError(
    'UNKNOWN',
    context || 'An unexpected error occurred',
    undefined,
    error
  );
}

/**
 * Create a failed RepositoryResult from an error
 */
export function failedResult(error: unknown, context?: string): {
  success: false;
  data: null;
  error: RepositoryErrorDetails;
} {
  const repoError = toRepositoryError(error, context);
  return {
    success: false,
    data: null,
    error: repoError.toDetails(),
  };
}

/**
 * Create a successful RepositoryResult
 */
export function successResult<T>(data: T): {
  success: true;
  data: T;
  error: null;
} {
  return {
    success: true,
    data,
    error: null,
  };
}

/**
 * Type guard to check if a result is successful
 */
export function isSuccess<T>(
  result: { success: boolean; data: T | null; error: RepositoryErrorDetails | null }
): result is { success: true; data: T; error: null } {
  return result.success === true;
}

/**
 * Type guard to check if a result is a failure
 */
export function isFailure<T>(
  result: { success: boolean; data: T | null; error: RepositoryErrorDetails | null }
): result is { success: false; data: null; error: RepositoryErrorDetails } {
  return result.success === false;
}
