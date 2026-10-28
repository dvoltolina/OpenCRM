/**
 * useNetworkStatus Hook
 * Track online/offline network status with browser events
 *
 * Agent CRM-34 Implementation
 */

import { useState, useEffect, useCallback } from 'react';
import { isOnline as checkIsOnline } from '../lib/network';

// ============================================
// Types
// ============================================

export interface UseNetworkStatusOptions {
  /** Callback when status changes to online */
  onOnline?: () => void;
  /** Callback when status changes to offline */
  onOffline?: () => void;
  /** Callback on any status change */
  onChange?: (isOnline: boolean) => void;
}

export interface UseNetworkStatusResult {
  /** True if currently online */
  isOnline: boolean;
  /** True if currently offline */
  isOffline: boolean;
  /** Manually refresh status */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for tracking network online/offline status
 *
 * @param options - Event callbacks
 * @returns Network status and refresh function
 *
 * @example
 * ```tsx
 * function MyComponent() {
 *   const { isOnline, isOffline } = useNetworkStatus({
 *     onOnline: () => {
 *       console.log('Back online! Syncing data...');
 *       syncPendingChanges();
 *     },
 *     onOffline: () => {
 *       console.log('Gone offline. Working in offline mode.');
 *     },
 *   });
 *
 *   return (
 *     <div>
 *       {isOffline && (
 *         <div className="offline-banner">
 *           You are currently offline
 *         </div>
 *       )}
 *     </div>
 *   );
 * }
 * ```
 */
export function useNetworkStatus(
  options: UseNetworkStatusOptions = {}
): UseNetworkStatusResult {
  const { onOnline, onOffline, onChange } = options;

  // Initialize state with current online status
  const [isOnline, setIsOnline] = useState(() => {
    // Check if we're in a browser environment
    if (typeof navigator === 'undefined') {
      return true; // Default to online in non-browser environments
    }
    return checkIsOnline();
  });

  // Manually refresh status
  const refresh = useCallback(() => {
    const currentStatus = checkIsOnline();
    setIsOnline(currentStatus);
  }, []);

  // Set up event listeners
  useEffect(() => {
    // Skip if not in browser
    if (typeof window === 'undefined') {
      return;
    }

    const handleOnline = () => {
      setIsOnline(true);
      onOnline?.();
      onChange?.(true);
    };

    const handleOffline = () => {
      setIsOnline(false);
      onOffline?.();
      onChange?.(false);
    };

    // Add event listeners
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Cleanup
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [onOnline, onOffline, onChange]);

  return {
    isOnline,
    isOffline: !isOnline,
    refresh,
  };
}

export default useNetworkStatus;
