/**
 * Error Sanitization Utilities
 * HIPAA-compliant error message handling
 *
 * Agent CRM-40 Implementation
 * Ensures no PHI is exposed in user-facing error messages
 */

/**
 * Sanitize error messages to prevent PHI leakage
 * Removes specific identifiers and replaces with generic messages
 *
 * @param error - Error object or string
 * @param context - Optional context for more specific error messages
 * @returns Sanitized error message safe for display
 */
export function sanitizeErrorMessage(
  error: unknown,
  context?: string
): string {
  // Default generic message
  const genericMessage = context
    ? `Failed to ${context}. Please try again.`
    : 'An error occurred. Please try again.';

  // If error is null/undefined, return generic
  if (!error) {
    return genericMessage;
  }

  // Extract message from Error object
  const errorMessage = error instanceof Error ? error.message : String(error);

  // Check for common error types that are safe to display
  const safeErrorPatterns = [
    /not found/i,
    /unauthorized/i,
    /permission denied/i,
    /network/i,
    /timeout/i,
    /invalid/i,
    /required/i,
  ];

  // If it matches a safe pattern, return the message
  if (safeErrorPatterns.some(pattern => pattern.test(errorMessage))) {
    return errorMessage;
  }

  // Otherwise, return generic message
  return genericMessage;
}

/**
 * Redact PHI from strings (names, emails, phones, etc.)
 * Used for logging non-PHI metadata
 *
 * @param str - String that may contain PHI
 * @returns Redacted string with PHI replaced
 */
export function redactPHI(str: string): string {
  return str
    // Redact emails
    .replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[EMAIL_REDACTED]')
    // Redact phone numbers (various formats)
    .replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE_REDACTED]')
    .replace(/\(\d{3}\)\s*\d{3}[-.]?\d{4}/g, '[PHONE_REDACTED]')
    // Redact common ID patterns
    .replace(/\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b/gi, '[ID_REDACTED]');
}

/**
 * Check if a console log statement might contain PHI
 * Used during development to identify risky logging
 *
 * @param message - Log message to check
 * @returns true if the message might contain PHI
 */
export function mightContainPHI(message: string): boolean {
  const phiIndicators = [
    /\b(name|email|phone|address|ssn|dob|birth)\b/i,
    /\b(client|contact|patient|customer)\b/i,
    /@/,  // Email addresses
    /\d{3}[-.]?\d{3}[-.]?\d{4}/, // Phone numbers
  ];

  return phiIndicators.some(pattern => pattern.test(message));
}

/**
 * Safe console logger that redacts PHI
 * Use this instead of console.log in production code
 *
 * @param level - Log level (log, warn, error, debug)
 * @param message - Message to log
 * @param data - Optional data to log (will be redacted)
 */
export function safeLog(
  level: 'log' | 'warn' | 'error' | 'debug',
  message: string,
  data?: unknown
): void {
  // In production, only log errors
  if (process.env.NODE_ENV === 'production' && level !== 'error') {
    return;
  }

  const redactedMessage = redactPHI(message);

  if (data) {
    // Stringify and redact data
    const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
    const redactedData = redactPHI(dataStr);
    console[level](redactedMessage, redactedData);
  } else {
    console[level](redactedMessage);
  }
}
