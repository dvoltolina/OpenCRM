/**
 * useLead Hook
 * Fetches and manages a single lead with related activities
 *
 * Agent CRM-08 Implementation
 * Dependencies: Agent CRM-03 (leads repository), Agent CRM-06 (activities)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { createSecurityContext } from './usePipeline';
import type { Lead, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseLeadResult {
  /** The lead data, null if loading or not found */
  lead: Lead | null;
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if fetch failed */
  error: Error | null;
  /** Activities related to this lead */
  activities: SalesActivity[];
  /** True while activities are loading */
  isLoadingActivities: boolean;
  /** Manually refresh the lead data */
  refresh: () => void;
  /** Manually refresh activities */
  refreshActivities: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and managing a single lead
 *
 * @param leadId - ID of the lead to fetch
 * @returns Lead data, activities, loading state, and refresh functions
 *
 * @example
 * ```tsx
 * const { lead, activities, isLoading, error, refresh } = useLead('lead-123');
 *
 * if (isLoading) return <Spinner />;
 * if (error) return <Error message={error.message} />;
 * if (!lead) return <NotFound />;
 *
 * return (
 *   <LeadDetail lead={lead} activities={activities} />
 * );
 * ```
 */
export function useLead(leadId: string | undefined): UseLeadResult {
  const { crmUser, businessId } = useAuth();
  const [lead, setLead] = useState<Lead | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoadingActivities, setIsLoadingActivities] = useState(false);

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

  // Fetch lead
  const fetchLead = useCallback(async () => {
    if (!leadId || !businessId || !crmUser) {
      setLead(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getLeadRepository();

      const result = await repo.getById(context, leadId);

      if (result.success) {
        setLead(result.data);
      } else {
        setError(new Error(result.error.message));
        setLead(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch lead'));
      setLead(null);
    } finally {
      setIsLoading(false);
    }
  }, [leadId, businessId, crmUser, getContext]);

  // Fetch activities for the lead
  const fetchActivities = useCallback(async () => {
    if (!leadId || !businessId || !crmUser) {
      setActivities([]);
      return;
    }

    setIsLoadingActivities(true);

    try {
      // Note: ActivityRepository.getByLead will be implemented in Agent CRM-06
      // For now, we'll return an empty array as a placeholder
      // When ActivityRepository is available, uncomment the following:
      /*
      const context = getContext();
      const activityRepo = getActivityRepository();
      const result = await activityRepo.getByLead(context, leadId);

      if (result.success) {
        setActivities(result.data.data);
      } else {
        setActivities([]);
      }
      */
      setActivities([]);
    } catch {
      setActivities([]);
    } finally {
      setIsLoadingActivities(false);
    }
  }, [leadId, businessId, crmUser]);

  // Initial fetch
  useEffect(() => {
    fetchLead();
  }, [fetchLead]);

  // Fetch activities when lead is loaded
  useEffect(() => {
    if (lead) {
      fetchActivities();
    }
  }, [lead, fetchActivities]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchLead();
  }, [fetchLead]);

  const refreshActivities = useCallback(() => {
    fetchActivities();
  }, [fetchActivities]);

  return {
    lead,
    isLoading,
    error,
    activities,
    isLoadingActivities,
    refresh,
    refreshActivities,
  };
}

export default useLead;
