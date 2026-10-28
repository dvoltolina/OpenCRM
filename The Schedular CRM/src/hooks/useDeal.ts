/**
 * useDeal Hook
 * Fetches a single deal with its related data (stage, client, company, activities)
 *
 * Agent CRM-09 Implementation
 * Dependencies: Agent CRM-04 (deals repository), Agent CRM-07 (pipeline hooks)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getStageRepository } from '../data/repositories/stage-repository';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import { createSecurityContext } from './usePipeline';
import type { Deal, Stage, Client, Company, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseDealResult {
  /** The deal data */
  deal: Deal | null;
  /** The stage the deal is in */
  stage: Stage | null;
  /** The linked client (if any) */
  client: Client | null;
  /** The linked company (if any) */
  company: Company | null;
  /** Activities for this deal */
  activities: SalesActivity[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh the deal data */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching a single deal with related data
 *
 * @param dealId - ID of the deal to fetch
 * @returns Deal, related entities, and state
 *
 * @example
 * ```tsx
 * const { deal, stage, client, activities, isLoading } = useDeal('deal-123');
 *
 * if (isLoading) return <Loading />;
 * if (!deal) return <NotFound />;
 *
 * return (
 *   <DealDetail
 *     deal={deal}
 *     stage={stage}
 *     client={client}
 *     activities={activities}
 *   />
 * );
 * ```
 */
export function useDeal(dealId: string | undefined): UseDealResult {
  const { crmUser, businessId } = useAuth();
  const [deal, setDeal] = useState<Deal | null>(null);
  const [stage, setStage] = useState<Stage | null>(null);
  const [client, setClient] = useState<Client | null>(null);
  const [company, setCompany] = useState<Company | null>(null);
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

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

  // Fetch deal and related data
  const fetchDeal = useCallback(async () => {
    if (!dealId || !businessId || !crmUser) {
      setDeal(null);
      setStage(null);
      setClient(null);
      setCompany(null);
      setActivities([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const dealRepo = getDealRepository();

      // Fetch the deal
      const dealResult = await dealRepo.getById(context, dealId);
      if (!dealResult.success) {
        setError(new Error(dealResult.error.message));
        setDeal(null);
        setIsLoading(false);
        return;
      }

      const fetchedDeal = dealResult.data;
      setDeal(fetchedDeal);

      // Fetch related data in parallel
      const [stageResult, clientResult, companyResult, activitiesResult] = await Promise.all([
        // Fetch stage
        fetchedDeal.stageId
          ? getStageRepository().getById(context, fetchedDeal.stageId)
          : Promise.resolve({ success: true, data: null, error: null }),
        // Fetch client if linked
        fetchedDeal.clientId
          ? getContactRepository().getById(context, fetchedDeal.clientId)
          : Promise.resolve({ success: true, data: null, error: null }),
        // Fetch company if linked
        fetchedDeal.companyId
          ? getCompanyRepository().getById(context, fetchedDeal.companyId)
          : Promise.resolve({ success: true, data: null, error: null }),
        // Fetch activities for this deal
        getActivityRepository().getByDeal(context, dealId),
      ]);

      // Set stage
      if (stageResult.success && stageResult.data) {
        setStage(stageResult.data);
      } else {
        setStage(null);
      }

      // Set client
      if (clientResult.success && clientResult.data) {
        setClient(clientResult.data);
      } else {
        setClient(null);
      }

      // Set company
      if (companyResult.success && companyResult.data) {
        setCompany(companyResult.data);
      } else {
        setCompany(null);
      }

      // Set activities
              if (activitiesResult.success) {
                setActivities(activitiesResult.data.data);
              } else {
        setActivities([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch deal'));
      setDeal(null);
      setStage(null);
      setClient(null);
      setCompany(null);
      setActivities([]);
    } finally {
      setIsLoading(false);
    }
  }, [dealId, businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchDeal();
  }, [fetchDeal]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchDeal();
  }, [fetchDeal]);

  return {
    deal,
    stage,
    client,
    company,
    activities,
    isLoading,
    error,
    refresh,
  };
}

export default useDeal;
