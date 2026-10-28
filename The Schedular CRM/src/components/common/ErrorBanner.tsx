/**
 * ErrorBanner Component
 * Consistent error display with retry and dismiss actions
 *
 * Agent CRM-34 Implementation
 */

import { useEffect, useRef } from 'react';
import './common.css';

// ============================================
// Types
// ============================================

export interface ErrorBannerProps {
  /** Error message to display */
  message: string;
  /** Banner variant (default: 'error') */
  variant?: 'error' | 'warning' | 'info';
  /** Optional retry callback */
  onRetry?: () => void;
  /** Optional dismiss callback */
  onDismiss?: () => void;
  /** Auto-dismiss after duration in ms (0 = no auto-dismiss) */
  autoDismiss?: number;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * ErrorBanner - Consistent error display component
 *
 * @example
 * ```tsx
 * // Simple error
 * <ErrorBanner
 *   message="Failed to load data"
 *   onDismiss={() => setError(null)}
 * />
 *
 * // With retry
 * <ErrorBanner
 *   message="Network error. Please try again."
 *   variant="error"
 *   onRetry={handleRetry}
 *   onDismiss={() => setError(null)}
 * />
 *
 * // Warning with auto-dismiss
 * <ErrorBanner
 *   message="Changes saved with warnings"
 *   variant="warning"
 *   autoDismiss={5000}
 *   onDismiss={() => setWarning(null)}
 * />
 * ```
 */
export function ErrorBanner({
  message,
  variant = 'error',
  onRetry,
  onDismiss,
  autoDismiss = 0,
  className = '',
}: ErrorBannerProps) {
  const timerRef = useRef<number | undefined>(undefined);

  // Handle auto-dismiss
  useEffect(() => {
    if (autoDismiss > 0 && onDismiss) {
      timerRef.current = window.setTimeout(() => {
        onDismiss();
      }, autoDismiss);
    }

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, [autoDismiss, onDismiss]);

  // Get icon based on variant
  const getIcon = () => {
    switch (variant) {
      case 'error':
        return (
          <svg
            width="20"
            height="20"
            viewBox="0 0 20 20"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M10 18C14.4183 18 18 14.4183 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 14.4183 5.58172 18 10 18Z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 6V10"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 14H10.01"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        );
      case 'warning':
        return (
          <svg
            width="20"
            height="20"
            viewBox="0 0 20 20"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M8.25701 3.09961C9.02301 1.63361 11.103 1.63361 11.869 3.09961L18.289 14.5996C19.027 15.9996 18.001 17.6996 16.419 17.6996H3.58101C1.99901 17.6996 0.973005 15.9996 1.71101 14.5996L8.25701 3.09961Z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 7V11"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 15H10.01"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        );
      case 'info':
        return (
          <svg
            width="20"
            height="20"
            viewBox="0 0 20 20"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M10 18C14.4183 18 18 14.4183 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 14.4183 5.58172 18 10 18Z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 14V10"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M10 6H10.01"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        );
    }
  };

  return (
    <div
      className={`error-banner error-banner--${variant} ${className}`}
      role="alert"
      aria-live="polite"
    >
      <div className="error-banner__icon">{getIcon()}</div>

      <div className="error-banner__content">
        <p className="error-banner__message">{message}</p>
      </div>

      <div className="error-banner__actions">
        {onRetry && (
          <button
            type="button"
            className="error-banner__button error-banner__button--retry"
            onClick={onRetry}
          >
            Retry
          </button>
        )}

        {onDismiss && (
          <button
            type="button"
            className="error-banner__button error-banner__button--dismiss"
            onClick={onDismiss}
            aria-label="Dismiss"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M12 4L4 12M4 4L12 12"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        )}
      </div>
    </div>
  );
}

export default ErrorBanner;
