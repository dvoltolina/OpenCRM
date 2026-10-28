/**
 * useAuditLog Hook
 * Manages audit log queries and filtering
 *
 * Agent CRM-28 Implementation
 * HIPAA Compliance: Provides UI access to comprehensive audit logs
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getAuditLogService } from '../services/AuditLogService';
import { createSecurityContext } from './usePipeline';
import type {
  AuditLogFilters,
  AuditEntry,
  AuditEntityType,
} from '../types/audit';

// ============================================
// Types
// ============================================

export interface UseAuditLogResult {
  /** List of audit entries */
  entries: AuditEntry[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether there are more entries to load */
  hasMore: boolean;
  /** Load more entries for pagination */
  loadMore: () => void;
  /** Total count of entries */
  totalCount: number;
  /** Manually refresh the audit log */
  refresh: () => void;
}

export interface UseEntityAuditHistoryResult {
  /** List of audit entries for the entity */
  entries: AuditEntry[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh the history */
  refresh: () => void;
}

// ============================================
// Hook: General Audit Log Query
// ============================================

/**
 * Hook for fetching and filtering audit logs
 *
 * @param filters - Optional filters to apply
 * @returns Audit log entries and state
 *
 * @example
 * ```tsx
 * const { entries, isLoading } = useAuditLog({
 *   userId: 'user-123',
 *   entityType: 'deal',
 *   startDate: new Date('2024-01-01'),
 * });
 * ```
 */
export function useAuditLog(filters?: AuditLogFilters): UseAuditLogResult {
  const { crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [lastDoc, setLastDoc] = useState<any>(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const userIdFilter = filters?.userId;
  const entityTypeFilter = filters?.entityType;
  const actionFilter = filters?.action;
  const entityIdFilter = filters?.entityId;
  const startDateFilter = filters?.startDate;
  const endDateFilter = filters?.endDate;
  const limitFilter = filters?.limit;

  // Stabilize filter values for dependency array
  const filterKey = useMemo(
    () =>
      JSON.stringify({
        userId: userIdFilter,
        entityType: entityTypeFilter,
        action: actionFilter,
        entityId: entityIdFilter,
        startDate: startDateFilter?.getTime(),
        endDate: endDateFilter?.getTime(),
        limit: limitFilter,
      }),
    [actionFilter, endDateFilter, entityIdFilter, entityTypeFilter, limitFilter, startDateFilter, userIdFilter]
  );
  const stableFilters = useMemo<AuditLogFilters | undefined>(
    () =>
      filters
        ? {
            userId: userIdFilter,
            entityType: entityTypeFilter,
            action: actionFilter,
            entityId: entityIdFilter,
            startDate: startDateFilter,
            endDate: endDateFilter,
            limit: limitFilter,
          }
        : undefined,
    [actionFilter, endDateFilter, entityIdFilter, entityTypeFilter, filters, limitFilter, startDateFilter, userIdFilter]
  );

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch audit logs
  const fetchAuditLogs = useCallback(
    async (append: boolean = false) => {
      if (!businessId || !crmUser) {
        setEntries([]);
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getAuditLogService();

        const queryFilters: AuditLogFilters = {
          ...stableFilters,
          startAfter: append ? lastDoc : undefined,
          limit: stableFilters?.limit || 50,
        };

        const result = await service.getAuditLog(context, queryFilters);

        if (!result.success) {
          throw new Error(result.error?.message || 'Failed to fetch audit logs');
        }

        const newEntries = result.data?.entries || [];

        if (append) {
          setEntries((prev) => [...prev, ...newEntries]);
        } else {
          setEntries(newEntries);
        }

        setHasMore(result.data?.hasMore || false);
        setLastDoc(result.data?.lastDoc);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch audit logs'));
        if (!append) {
          setEntries([]);
        }
      } finally {
        setIsLoading(false);
      }
    },
    [businessId, crmUser, getContext, lastDoc, stableFilters]
  );

  // Initial fetch and re-fetch on filter changes
  useEffect(() => {
    fetchAuditLogs(false);
  }, [fetchAuditLogs, filterKey, refreshKey]);

  // Load more for pagination
  const loadMore = useCallback(() => {
    if (!isLoading && hasMore) {
      fetchAuditLogs(true);
    }
  }, [isLoading, hasMore, fetchAuditLogs]);

  // Manual refresh
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
    setLastDoc(null);
  }, []);

  // Calculate total count
  const totalCount = useMemo(() => entries.length, [entries]);

  return {
    entries,
    isLoading,
    error,
    hasMore,
    loadMore,
    totalCount,
    refresh,
  };
}

// ============================================
// Hook: Entity Audit History
// ============================================

/**
 * Hook for fetching audit history for a specific entity
 *
 * @param entityType - Type of entity
 * @param entityId - ID of entity
 * @param limit - Maximum number of entries to fetch
 * @returns Audit entries for the entity
 *
 * @example
 * ```tsx
 * const { entries, isLoading } = useEntityAuditHistory('deal', 'deal-123');
 * ```
 */
export function useEntityAuditHistory(
  entityType: AuditEntityType,
  entityId: string,
  limit: number = 50
): UseEntityAuditHistoryResult {
  const { crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch entity history
  const fetchHistory = useCallback(async () => {
    if (!businessId || !crmUser || !entityId) {
      setEntries([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getAuditLogService();

      const result = await service.getEntityHistory(context, entityType, entityId, limit);

      if (!result.success) {
        throw new Error(result.error?.message || 'Failed to fetch entity history');
      }

      setEntries(result.data || []);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch entity history'));
      setEntries([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, entityId, entityType, getContext, limit]);

  // Initial fetch
  useEffect(() => {
    fetchHistory();
  }, [fetchHistory, refreshKey]);

  // Manual refresh
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    entries,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// Hook: User Activity Log
// ============================================

/**
 * Hook for fetching audit logs for a specific user
 *
 * @param userId - ID of user
 * @param limit - Maximum number of entries to fetch
 * @returns Audit entries for the user
 *
 * @example
 * ```tsx
 * const { entries, isLoading } = useUserActivity('user-123');
 * ```
 */
export function useUserActivity(
  userId: string,
  limit: number = 100
): UseEntityAuditHistoryResult {
  const { crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch user activity
  const fetchActivity = useCallback(async () => {
    if (!businessId || !crmUser || !userId) {
      setEntries([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getAuditLogService();

      const result = await service.getUserActivity(context, userId, limit);

      if (!result.success) {
        throw new Error(result.error?.message || 'Failed to fetch user activity');
      }

      setEntries(result.data || []);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch user activity'));
      setEntries([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, limit, userId]);

  // Initial fetch
  useEffect(() => {
    fetchActivity();
  }, [fetchActivity, refreshKey]);

  // Manual refresh
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    entries,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// Hook: Recent Activity
// ============================================

/**
 * Hook for fetching recent audit logs
 *
 * @param days - Number of days to look back
 * @param limit - Maximum number of entries to fetch
 * @returns Recent audit entries
 *
 * @example
 * ```tsx
 * const { entries, isLoading } = useRecentActivity(7);
 * ```
 */
export function useRecentActivity(
  days: number = 7,
  limit: number = 100
): UseEntityAuditHistoryResult {
  const { crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch recent activity
  const fetchActivity = useCallback(async () => {
    if (!businessId || !crmUser) {
      setEntries([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getAuditLogService();

      const result = await service.getRecentActivity(context, days, limit);

      if (!result.success) {
        throw new Error(result.error?.message || 'Failed to fetch recent activity');
      }

      setEntries(result.data || []);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch recent activity'));
      setEntries([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, days, getContext, limit]);

  // Initial fetch
  useEffect(() => {
    fetchActivity();
  }, [fetchActivity, refreshKey]);

  // Manual refresh
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    entries,
    isLoading,
    error,
    refresh,
  };
}

export default useAuditLog;
