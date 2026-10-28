/**
 * OfflineNotice Component
 * Fixed banner displayed when network is offline
 *
 * Agent CRM-34 Implementation
 */

import { useEffect, useState } from 'react';
import './common.css';

// ============================================
// Types
// ============================================

export interface OfflineNoticeProps {
  /** Custom message (default: standard offline message) */
  message?: string;
  /** Position of the banner */
  position?: 'top' | 'bottom';
  /** Show reconnected message when back online */
  showReconnected?: boolean;
  /** Duration to show reconnected message in ms */
  reconnectedDuration?: number;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * OfflineNotice - Fixed banner when network is offline
 *
 * @example
 * ```tsx
 * // Basic usage - add to root layout
 * function RootLayout({ children }) {
 *   return (
 *     <>
 *       <OfflineNotice />
 *       {children}
 *     </>
 *   );
 * }
 *
 * // Custom message and position
 * <OfflineNotice
 *   message="No internet connection. Your changes will be saved locally."
 *   position="bottom"
 *   showReconnected
 * />
 * ```
 */
export function OfflineNotice({
  message = "You're offline. Changes will sync when connected.",
  position = 'top',
  showReconnected = true,
  reconnectedDuration = 3000,
  className = '',
}: OfflineNoticeProps) {
  const [isOffline, setIsOffline] = useState(() => {
    if (typeof navigator === 'undefined') {
      return false;
    }
    return !navigator.onLine;
  });
  const [showReconnectedBanner, setShowReconnectedBanner] = useState(false);
  const [wasOffline, setWasOffline] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return undefined;
    }

    const handleOnline = () => {
      setIsOffline(false);
    };

    const handleOffline = () => {
      setIsOffline(true);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Track offline state and show reconnected message
  useEffect(() => {
    if (isOffline) {
      setWasOffline(true);
      setShowReconnectedBanner(false);
    } else if (wasOffline && showReconnected) {
      // Just came back online
      setShowReconnectedBanner(true);

      // Auto-hide reconnected message
      const timer = setTimeout(() => {
        setShowReconnectedBanner(false);
        setWasOffline(false);
      }, reconnectedDuration);

      return () => clearTimeout(timer);
    }
  }, [isOffline, wasOffline, showReconnected, reconnectedDuration]);

  // Don't render if online and no reconnected message to show
  if (!isOffline && !showReconnectedBanner) {
    return null;
  }

  return (
    <div
      className={`offline-notice offline-notice--${position} ${
        showReconnectedBanner ? 'offline-notice--reconnected' : ''
      } ${className}`}
      role="status"
      aria-live="polite"
    >
      <div className="offline-notice__content">
        {showReconnectedBanner ? (
          <>
            <svg
              className="offline-notice__icon"
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
                d="M13 8L9 12L7 10"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <span className="offline-notice__text">
              Back online. Syncing changes...
            </span>
          </>
        ) : (
          <>
            <svg
              className="offline-notice__icon"
              width="20"
              height="20"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              aria-hidden="true"
            >
              <path
                d="M2 7C2 7 5 3 10 3C15 3 18 7 18 7"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M5 11C5 11 7 9 10 9C13 9 15 11 15 11"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <line
                x1="2"
                y1="2"
                x2="18"
                y2="18"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
            <span className="offline-notice__text">{message}</span>
          </>
        )}
      </div>
    </div>
  );
}

export default OfflineNotice;
