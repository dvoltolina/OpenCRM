/**
 * useTimeline Hook
 * React hook for fetching activity timelines
 *
 * Agent CRM-13 Implementation
 * Dependencies: ActivityService, AuthContext
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getActivityService, type EntityType } from '../services/activity-service';
import type { SalesActivity } from '../types/models';
import { createSecurityContext } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface UseTimelineResult {
  /** Activity timeline */
  activities: SalesActivity[];
  /** Loading state */
  isLoading: boolean;
  /** Error state */
  error: { code: string; message: string } | null;
  /** Refresh the timeline */
  refresh: () => void;
}

export interface UseTimelineOptions {
  /** Entity type to fetch timeline for */
  entityType: EntityType;
  /** Entity ID */
  entityId: string | undefined;
  /** Maximum number of activities to fetch */
  limit?: number;
}

export interface UseUnifiedTimelineOptions {
  /** Deal ID to include */
  dealId?: string;
  /** Client ID to include */
  clientId?: string;
  /** Company ID to include */
  companyId?: string;
  /** Lead ID to include */
  leadId?: string;
  /** Maximum number of activities to fetch */
  limit?: number;
}

export interface UseTasksResult {
  /** Tasks list */
  tasks: SalesActivity[];
  /** Loading state */
  isLoading: boolean;
  /** Error state */
  error: { code: string; message: string } | null;
  /** Refresh the tasks */
  refresh: () => void;
}

// ============================================
// useTimeline Hook
// ============================================

/**
 * Hook for fetching activity timeline for a specific entity
 */
export function useTimeline(options: UseTimelineOptions): UseTimelineResult {
  const { crmUser, businessId } = useAuth();
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  useEffect(() => {
    if (!crmUser || !businessId || !options.entityId) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    const fetchTimeline = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getEntityTimeline(
          context,
          options.entityType,
          options.entityId!,
          options.limit
        );

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch timeline' });
          setActivities([]);
        } else {
          setActivities(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch timeline' });
        setActivities([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTimeline();
  }, [crmUser, businessId, options.entityType, options.entityId, options.limit, refreshKey]);

  return {
    activities,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useUnifiedTimeline Hook
// ============================================

/**
 * Hook for fetching unified timeline across multiple entities
 */
export function useUnifiedTimeline(options: UseUnifiedTimelineOptions): UseTimelineResult {
  const { crmUser, businessId } = useAuth();
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  // Check if any entity IDs are provided
  const hasEntities = options.dealId || options.clientId || options.companyId || options.leadId;

  useEffect(() => {
    if (!crmUser || !businessId || !hasEntities) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    const fetchTimeline = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getUnifiedTimeline(
          context,
          {
            dealId: options.dealId,
            clientId: options.clientId,
            companyId: options.companyId,
            leadId: options.leadId,
          },
          options.limit
        );

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch timeline' });
          setActivities([]);
        } else {
          setActivities(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch timeline' });
        setActivities([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTimeline();
  }, [
    crmUser,
    businessId,
    options.dealId,
    options.clientId,
    options.companyId,
    options.leadId,
    options.limit,
    hasEntities,
    refreshKey,
  ]);

  return {
    activities,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// usePendingTasks Hook
// ============================================

/**
 * Hook for fetching pending tasks
 */
export function usePendingTasks(assigneeId?: string, limit?: number): UseTasksResult {
  const { crmUser, businessId } = useAuth();
  const [tasks, setTasks] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setTasks([]);
      setIsLoading(false);
      return;
    }

    const fetchTasks = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getPendingTasks(context, assigneeId, limit);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch tasks' });
          setTasks([]);
        } else {
          setTasks(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch tasks' });
        setTasks([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTasks();
  }, [crmUser, businessId, assigneeId, limit, refreshKey]);

  return {
    tasks,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useOverdueTasks Hook
// ============================================

/**
 * Hook for fetching overdue tasks
 */
export function useOverdueTasks(limit?: number): UseTasksResult {
  const { crmUser, businessId } = useAuth();
  const [tasks, setTasks] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setTasks([]);
      setIsLoading(false);
      return;
    }

    const fetchTasks = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getOverdueTasks(context, limit);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch overdue tasks' });
          setTasks([]);
        } else {
          setTasks(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch overdue tasks' });
        setTasks([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTasks();
  }, [crmUser, businessId, limit, refreshKey]);

  return {
    tasks,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useUpcomingTasks Hook
// ============================================

/**
 * Hook for fetching upcoming tasks (due within N days)
 */
export function useUpcomingTasks(days: number = 7, limit?: number): UseTasksResult {
  const { crmUser, businessId } = useAuth();
  const [tasks, setTasks] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setTasks([]);
      setIsLoading(false);
      return;
    }

    const fetchTasks = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getUpcomingTasks(context, days, limit);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch upcoming tasks' });
          setTasks([]);
        } else {
          setTasks(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch upcoming tasks' });
        setTasks([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTasks();
  }, [crmUser, businessId, days, limit, refreshKey]);

  return {
    tasks,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useRecentActivities Hook
// ============================================

/**
 * Hook for fetching recent activities (last N days)
 */
export function useRecentActivities(days: number = 7, limit?: number): UseTimelineResult {
  const { crmUser, businessId } = useAuth();
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    const fetchActivities = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.getRecentActivities(context, days, limit);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to fetch activities' });
          setActivities([]);
        } else {
          setActivities(result.data || []);
        }
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to fetch activities' });
        setActivities([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchActivities();
  }, [crmUser, businessId, days, limit, refreshKey]);

  return {
    activities,
    isLoading,
    error,
    refresh,
  };
}
