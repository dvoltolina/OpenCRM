/**
 * ErrorMessage Component
 * HIPAA-compliant error display with sanitized messages
 *
 * Agent CRM-40 Implementation
 * Ensures no PHI is exposed in user-facing error messages
 */

import { sanitizeErrorMessage } from '../../lib/error-sanitization';

interface ErrorMessageProps {
  /** Error object or string */
  error: unknown;
  /** Context for more specific error messages (e.g., "load contacts") */
  context?: string;
  /** Optional retry callback */
  onRetry?: () => void;
  /** Custom className for styling */
  className?: string;
}

/**
 * Display a sanitized error message
 * Prevents PHI leakage in error displays
 */
export function ErrorMessage({
  error,
  context,
  onRetry,
  className = '',
}: ErrorMessageProps) {
  const sanitizedMessage = sanitizeErrorMessage(error, context);

  return (
    <div className={`error-state ${className}`}>
      <div className="error-icon">⚠️</div>
      <p className="error-message">{sanitizedMessage}</p>
      {onRetry && (
        <button className="btn btn-primary" onClick={onRetry}>
          Retry
        </button>
      )}
    </div>
  );
}

/**
 * Inline error message variant (smaller, no icon)
 */
export function InlineErrorMessage({
  error,
  context,
  className = '',
}: Omit<ErrorMessageProps, 'onRetry'>) {
  const sanitizedMessage = sanitizeErrorMessage(error, context);

  return (
    <div className={`inline-error ${className}`}>
      <span className="error-text">{sanitizedMessage}</span>
    </div>
  );
}

/**
 * Error banner for page-level errors
 */
export function ErrorBanner({
  error,
  context,
  onRetry,
  onDismiss,
}: ErrorMessageProps & { onDismiss?: () => void }) {
  const sanitizedMessage = sanitizeErrorMessage(error, context);

  return (
    <div className="error-banner">
      <div className="error-banner-content">
        <span className="error-icon">⚠️</span>
        <span className="error-message">{sanitizedMessage}</span>
      </div>
      <div className="error-banner-actions">
        {onRetry && (
          <button className="btn btn-sm btn-primary" onClick={onRetry}>
            Retry
          </button>
        )}
        {onDismiss && (
          <button className="btn btn-sm btn-ghost" onClick={onDismiss}>
            Dismiss
          </button>
        )}
      </div>
    </div>
  );
}
