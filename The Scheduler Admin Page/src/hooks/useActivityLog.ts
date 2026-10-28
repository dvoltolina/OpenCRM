import { useState, useEffect, useCallback } from 'react';
import { useBusinessContext } from './useBusinessContext';
import {
  listActivityLogs,
  listUserActivity,
  ActivityLogEntry,
  ActivityLogFilters,
} from '../data/activityLog';

export interface UseActivityLogOptions {
  userId?: string;
  action?: string;
  autoRefresh?: boolean;
  limit?: number;
}

export interface UseActivityLogResult {
  entries: ActivityLogEntry[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
}

/**
 * Hook for fetching and managing activity logs
 *
 * @param options - Optional filters and configuration
 * @returns Activity log entries, loading state, error state, and refresh function
 */
export function useActivityLog(options: UseActivityLogOptions = {}): UseActivityLogResult {
  const { businessId } = useBusinessContext({ minRole: 'admin' });
  const [entries, setEntries] = useState<ActivityLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      setError('No business context available');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const filters: ActivityLogFilters = {
        userId: options.userId,
        action: options.action,
        limit: options.limit || 50,
      };

      const logs = options.userId
        ? await listUserActivity(businessId, options.userId, filters.limit)
        : await listActivityLogs(businessId, filters);

      setEntries(logs);
    } catch (err) {
      console.error('Failed to load activity log:', err);
      setError(err instanceof Error ? err.message : 'Failed to load activity log');
    } finally {
      setLoading(false);
    }
  }, [businessId, options.userId, options.action, options.limit]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  // Auto-refresh every 30 seconds if enabled
  useEffect(() => {
    if (!options.autoRefresh) return;

    const interval = setInterval(() => {
      void refresh();
    }, 30000);

    return () => clearInterval(interval);
  }, [options.autoRefresh, refresh]);

  return {
    entries,
    loading,
    error,
    refresh,
  };
}
