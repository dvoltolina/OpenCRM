/**
 * useDashboardData Hook
 * Fetches all data needed for the dashboard
 *
 * Agent CRM-18 Implementation
 * Dependencies: useDeals, useLeads, usePipelineWithStages, useTimeline hooks
 */

import { useMemo } from 'react';
import { useDeals } from './useDeals';
import { useLeads } from './useLeads';
import { usePipelineWithStages } from './usePipelineWithStages';
import { useUpcomingTasks, useRecentActivities } from './useTimeline';
import { useDashboardKPIs } from './useDashboardKPIs';
import type { DashboardKPIs } from './useDashboardKPIs';
import type { Deal, Lead, Stage, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseDashboardDataOptions {
  /** Filter by assignee ID (for staff to see only their data) */
  assigneeId?: string;
}

export interface UseDashboardDataResult {
  /** All deals */
  deals: Deal[];
  /** All leads */
  leads: Lead[];
  /** Pipeline stages */
  stages: Stage[];
  /** Upcoming tasks (next 7 days) */
  upcomingTasks: SalesActivity[];
  /** Recent activities (last 7 days) */
  recentActivities: SalesActivity[];
  /** Calculated KPIs */
  kpis: DashboardKPIs;
  /** True if any data is loading */
  isLoading: boolean;
  /** Error from any data fetch */
  error: Error | { code: string; message: string } | null;
  /** Refresh all dashboard data */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching all dashboard data
 * Combines multiple data sources for the dashboard view
 *
 * @returns Dashboard data and state
 *
 * @example
 * ```tsx
 * function Dashboard() {
 *   const {
 *     kpis,
 *     deals,
 *     upcomingTasks,
 *     recentActivities,
 *     isLoading,
 *   } = useDashboardData();
 *
 *   if (isLoading) return <Spinner />;
 *
 *   return (
 *     <div>
 *       <KPIGrid kpis={kpis} />
 *       <PipelineFunnel deals={deals} />
 *       <UpcomingTasks tasks={upcomingTasks} />
 *       <ActivityFeed activities={recentActivities} />
 *     </div>
 *   );
 * }
 * ```
 */
export function useDashboardData(options?: UseDashboardDataOptions): UseDashboardDataResult {
  // Fetch broad dashboard datasets first, then apply lightweight client-side
  // assignee scoping. This avoids brittle indexed query paths on the
  // dashboard while preserving the intended personal-view behavior.
  const {
    deals: allDeals,
    isLoading: dealsLoading,
    error: dealsError,
    refresh: refreshDeals,
  } = useDeals();

  const {
    leads: allLeads,
    isLoading: leadsLoading,
    error: leadsError,
    refresh: refreshLeads,
  } = useLeads();

  const deals = useMemo(() => {
    if (!options?.assigneeId) return allDeals;
    return allDeals.filter((deal) => deal.assigneeId === options.assigneeId);
  }, [allDeals, options?.assigneeId]);

  const leads = useMemo(() => {
    if (!options?.assigneeId) return allLeads;
    return allLeads.filter((lead) => lead.assigneeId === options.assigneeId);
  }, [allLeads, options?.assigneeId]);

  // Fetch pipeline with stages
  const {
    stages,
    isLoading: stagesLoading,
    error: stagesError,
    refresh: refreshStages,
  } = usePipelineWithStages();

  // Fetch upcoming tasks (next 7 days)
  const {
    tasks: upcomingTasks,
    isLoading: tasksLoading,
    error: tasksError,
    refresh: refreshTasks,
  } = useUpcomingTasks(7, 10);

  // Fetch recent activities (last 7 days, limit to 10)
  const {
    activities: recentActivities,
    isLoading: activitiesLoading,
    error: activitiesError,
    refresh: refreshActivities,
  } = useRecentActivities(7, 10);

  // Calculate KPIs
  const kpis = useDashboardKPIs({
    deals,
    leads,
    stages,
  });

  // Combine loading states
  const isLoading =
    dealsLoading ||
    leadsLoading ||
    stagesLoading ||
    tasksLoading ||
    activitiesLoading;

  // Combine errors (prioritize first error found)
  const error =
    dealsError || leadsError || stagesError || tasksError || activitiesError;

  // Refresh all data
  const refresh = () => {
    refreshDeals();
    refreshLeads();
    refreshStages();
    refreshTasks();
    refreshActivities();
  };

  return {
    deals,
    leads,
    stages,
    upcomingTasks,
    recentActivities,
    kpis,
    isLoading,
    error,
    refresh,
  };
}

export default useDashboardData;
