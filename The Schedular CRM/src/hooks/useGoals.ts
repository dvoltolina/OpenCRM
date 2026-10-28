/**
 * useGoals Hook
 * Manages goals with filtering, mutations, and progress tracking
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getGoalRepository } from '../data/repositories/goal-repository';
import { getGoalService } from '../services/goal-service';
import { createSecurityContext } from './usePipeline';
import { getFeatureFlags } from '../config/features';
import type {
  Goal,
  GoalStatus,
  GoalPeriod,
  GoalAssigneeType,
  GoalProgressSummary,
  GoalDashboardStats,
  CreateGoalData,
} from '../types/goals';
import { getShareableAccessSummary, type ShareableAccessSummary } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface GoalFilters {
  status?: GoalStatus;
  period?: GoalPeriod;
  assigneeType?: GoalAssigneeType;
  assigneeId?: string;
  search?: string;
}

export interface UseGoalsResult {
  /** List of goals matching filters */
  goals: Goal[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh the goal list */
  refresh: () => void;
  /** Total count of filtered goals */
  totalCount: number;
  /** Feature flag check */
  isEnabled: boolean;
  /** Access metadata helper for UI guards */
  getAccessSummary: (goal: Goal | null | undefined) => ShareableAccessSummary | null;
}

export interface UseGoalResult {
  /** Single goal */
  goal: Goal | null;
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh */
  refresh: () => void;
  /** Access metadata */
  accessSummary: ShareableAccessSummary | null;
}

export interface UseGoalMutationsResult {
  /** Create a new goal */
  createGoal: (data: CreateGoalData) => Promise<Goal>;
  /** Update an existing goal */
  updateGoal: (id: string, data: Partial<Goal>) => Promise<Goal>;
  /** Cancel a goal */
  cancelGoal: (id: string) => Promise<Goal>;
  /** Delete a goal */
  deleteGoal: (id: string) => Promise<void>;
  /** Recalculate goal progress */
  recalculateProgress: (id: string) => Promise<Goal>;
  /** Loading state for mutations */
  isMutating: boolean;
  /** Error from last mutation */
  mutationError: Error | null;
}

export interface UseGoalDashboardResult {
  /** Goal progress summaries */
  goals: GoalProgressSummary[];
  /** Aggregated stats */
  stats: GoalDashboardStats | null;
  /** True while loading */
  isLoading: boolean;
  /** Error if operation failed */
  error: Error | null;
  /** Refresh dashboard data */
  refresh: () => void;
}

// ============================================
// useGoals Hook
// ============================================

/**
 * Hook for fetching and filtering goals
 */
export function useGoals(filters?: GoalFilters): UseGoalsResult {
  const { crmUser, businessId } = useAuth();
  const [goals, setGoals] = useState<Goal[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const isEnabled = getFeatureFlags().enableGoals;

  const statusFilter = filters?.status;
  const periodFilter = filters?.period;
  const assigneeTypeFilter = filters?.assigneeType;
  const assigneeIdFilter = filters?.assigneeId;
  const searchFilter = filters?.search;

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

  const getAccessSummary = useCallback(
    (goal: Goal | null | undefined): ShareableAccessSummary | null => {
      if (!goal || !businessId || !crmUser) return null;
      try {
        const context = getContext();
        return getShareableAccessSummary(context, goal);
      } catch {
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Fetch goals
  const fetchGoals = useCallback(async () => {
    if (!businessId || !crmUser || !isEnabled) {
      setGoals([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getGoalRepository();

      let fetchedGoals: Goal[] = [];

      // Use appropriate query based on filters
      if (statusFilter) {
        const result = await repo.getByStatus(context, statusFilter);
        if (result.success) {
          fetchedGoals = result.data;
        } else {
          throw new Error(result.error?.message || 'Failed to fetch goals');
        }
      } else if (assigneeTypeFilter && assigneeIdFilter) {
        const result = await repo.getByAssignee(context, assigneeTypeFilter, assigneeIdFilter);
        if (result.success) {
          fetchedGoals = result.data;
        } else {
          throw new Error(result.error?.message || 'Failed to fetch goals');
        }
      } else if (periodFilter) {
        const result = await repo.getActiveByPeriod(context, periodFilter, new Date());
        if (result.success) {
          fetchedGoals = result.data;
        } else {
          throw new Error(result.error?.message || 'Failed to fetch goals');
        }
      } else {
        const result = await repo.getAll(context, {
          orderBy: { field: 'createdAt', direction: 'desc' },
        });
        if (result.success) {
          fetchedGoals = result.data.data;
        } else {
          throw new Error(result.error?.message || 'Failed to fetch goals');
        }
      }

      // Apply client-side search filter
      if (searchFilter) {
        const searchLower = searchFilter.toLowerCase();
        fetchedGoals = fetchedGoals.filter(
          (goal) =>
            goal.assigneeName.toLowerCase().includes(searchLower) ||
            goal.metric.toLowerCase().includes(searchLower)
        );
      }

      setGoals(fetchedGoals);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch goals'));
      setGoals([]);
    } finally {
      setIsLoading(false);
    }
  }, [assigneeIdFilter, assigneeTypeFilter, businessId, crmUser, getContext, isEnabled, periodFilter, searchFilter, statusFilter]);

  useEffect(() => {
    fetchGoals();
  }, [fetchGoals, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    goals,
    isLoading,
    error,
    refresh,
    totalCount: goals.length,
    isEnabled,
    getAccessSummary,
  };
}

// ============================================
// useGoal Hook (single goal)
// ============================================

/**
 * Hook for fetching a single goal by ID
 */
export function useGoal(goalId: string | undefined): UseGoalResult {
  const { crmUser, businessId } = useAuth();
  const [goal, setGoal] = useState<Goal | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

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

  const accessSummary = useMemo(() => {
    if (!goal || !businessId || !crmUser) return null;
    try {
      const context = getContext();
      return getShareableAccessSummary(context, goal);
    } catch {
      return null;
    }
  }, [goal, businessId, crmUser, getContext]);

  const fetchGoal = useCallback(async () => {
    if (!businessId || !crmUser || !goalId) {
      setGoal(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getGoalRepository();
      const result = await repo.getById(context, goalId);

      if (result.success) {
        setGoal(result.data);
      } else {
        throw new Error(result.error?.message || 'Failed to fetch goal');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch goal'));
      setGoal(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, goalId, getContext]);

  useEffect(() => {
    fetchGoal();
  }, [fetchGoal, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    goal,
    isLoading,
    error,
    refresh,
    accessSummary,
  };
}

// ============================================
// useGoalMutations Hook
// ============================================

/**
 * Hook for goal mutations (create, update, cancel, delete)
 */
export function useGoalMutations(): UseGoalMutationsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isMutating, setIsMutating] = useState(false);
  const [mutationError, setMutationError] = useState<Error | null>(null);

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

  const createGoal = useCallback(
    async (data: CreateGoalData): Promise<Goal> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const service = getGoalService();
        const result = await service.createGoal(context, data);

        if (!result.success || !result.data) {
          throw result.error || new Error('Failed to create goal');
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create goal');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const updateGoal = useCallback(
    async (id: string, data: Partial<Goal>): Promise<Goal> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getGoalRepository();
        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error?.message || 'Failed to update goal');
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update goal');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const cancelGoal = useCallback(
    async (id: string): Promise<Goal> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getGoalRepository();
        const result = await repo.cancelGoal(context, id);

        if (!result.success) {
          throw new Error(result.error?.message || 'Failed to cancel goal');
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to cancel goal');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const deleteGoal = useCallback(
    async (id: string): Promise<void> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getGoalRepository();
        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error?.message || 'Failed to delete goal');
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete goal');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const recalculateProgress = useCallback(
    async (id: string): Promise<Goal> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const service = getGoalService();
        const result = await service.calculateProgress(context, id);

        if (!result.success || !result.data) {
          throw result.error || new Error('Failed to recalculate progress');
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to recalculate progress');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  return {
    createGoal: guardMutation(createGoal, { action: 'goal-create' }),
    updateGoal: guardMutation(updateGoal, { action: 'goal-update' }),
    cancelGoal: guardMutation(cancelGoal, { action: 'goal-cancel' }),
    deleteGoal: guardMutation(deleteGoal, { action: 'goal-delete' }),
    recalculateProgress: guardMutation(recalculateProgress, { action: 'goal-recalculate' }),
    isMutating,
    mutationError,
  };
}

// ============================================
// useGoalDashboard Hook
// ============================================

/**
 * Hook for the goal dashboard with progress summaries and stats
 */
export function useGoalDashboard(userId?: string): UseGoalDashboardResult {
  const { crmUser, businessId } = useAuth();
  const [goals, setGoals] = useState<GoalProgressSummary[]>([]);
  const [stats, setStats] = useState<GoalDashboardStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const isEnabled = getFeatureFlags().enableGoals;
  const targetUserId = userId || crmUser?.id;

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

  const fetchDashboard = useCallback(async () => {
    if (!businessId || !crmUser || !targetUserId || !isEnabled) {
      setGoals([]);
      setStats(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getGoalService();
      const result = await service.getGoalDashboard(context, targetUserId);

      if (result.success && result.data) {
        setGoals(result.data.goals);
        setStats(result.data.stats);
      } else {
        throw result.error || new Error('Failed to fetch goal dashboard');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch goal dashboard'));
      setGoals([]);
      setStats(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, isEnabled, targetUserId]);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    goals,
    stats,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useMyGoals Hook (convenience wrapper)
// ============================================

/**
 * Hook for fetching current user's goals
 */
export function useMyGoals(): UseGoalsResult {
  const { crmUser } = useAuth();

  return useGoals({
    assigneeType: 'user',
    assigneeId: crmUser?.id,
  });
}

export default useGoals;
