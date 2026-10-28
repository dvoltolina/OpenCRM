/**
 * useDealsByStage Hook
 * Groups deals by pipeline stage for kanban board views
 *
 * Agent CRM-09 Implementation
 * Dependencies: Agent CRM-04 (deals repository), Agent CRM-07 (pipeline hooks)
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getStageRepository } from '../data/repositories/stage-repository';
import { createSecurityContext } from './usePipeline';
import type { Deal, Stage } from '../types/models';

// ============================================
// Types
// ============================================

export interface StageWithDeals {
  /** The stage entity */
  stage: Stage;
  /** Deals in this stage */
  deals: Deal[];
  /** Total value of deals in this stage (in cents) */
  totalValue: number;
  /** Count of deals in this stage */
  count: number;
}

export interface DealsByStage {
  [stageId: string]: StageWithDeals;
}

export interface UseDealsByStageResult {
  /** Deals grouped by stage ID */
  dealsByStage: DealsByStage;
  /** All stages in order */
  stages: Stage[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Total value of all deals in the pipeline (in cents) */
  pipelineValue: number;
  /** Total count of deals in the pipeline */
  pipelineCount: number;
  /** Manually refresh the data */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching deals grouped by stage (kanban view)
 *
 * @param pipelineId - ID of the pipeline to fetch deals for
 * @returns Deals grouped by stage, stage list, totals, and state
 *
 * @example
 * ```tsx
 * const { dealsByStage, stages, isLoading, pipelineValue } = useDealsByStage('pipeline-123');
 *
 * return (
 *   <div className="kanban-board">
 *     {stages.map((stage) => (
 *       <KanbanColumn
 *         key={stage.id}
 *         stage={stage}
 *         deals={dealsByStage[stage.id]?.deals || []}
 *         totalValue={dealsByStage[stage.id]?.totalValue || 0}
 *       />
 *     ))}
 *   </div>
 * );
 * ```
 */
export interface UseDealsByStageOptions {
  /** Filter by assigned rep UID (for rep-specific views) */
  assignedRepUid?: string;
}

export function useDealsByStage(
  pipelineId: string | undefined,
  options?: UseDealsByStageOptions
): UseDealsByStageResult {
  const { crmUser, businessId } = useAuth();
  const [deals, setDeals] = useState<Deal[]>([]);
  const [stages, setStages] = useState<Stage[]>([]);
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

  // Fetch deals and stages
  const fetchData = useCallback(async () => {
    if (!pipelineId || !businessId || !crmUser) {
      setDeals([]);
      setStages([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const dealRepo = getDealRepository();
      const stageRepo = getStageRepository();

      // Fetch deals and stages in parallel
      const [dealsResult, stagesResult] = await Promise.all([
        dealRepo.getByPipeline(context, pipelineId),
        stageRepo.getActiveByPipeline(context, pipelineId),
      ]);

      if (dealsResult.success) {
        // Only include open deals in kanban view
        let filteredDeals = dealsResult.data.filter((deal) => deal.status === 'open');

        // Filter by assigned rep UID if provided (for rep-specific pipeline view)
        if (options?.assignedRepUid) {
          filteredDeals = filteredDeals.filter(
            (deal) => deal.assignedRepUid === options.assignedRepUid
          );
        }

        setDeals(filteredDeals);
      } else {
        const details = dealsResult.error?.message || 'Failed to fetch deals';
        throw new Error(`Unable to load deals for pipeline ${pipelineId}: ${details}`);
      }

      if (stagesResult.success) {
        // Stages are already sorted by order field
        setStages(stagesResult.data);
      } else {
        const details = stagesResult.error?.message || 'Failed to fetch pipeline stages';
        throw new Error(`Unable to load stages for pipeline ${pipelineId}: ${details}`);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch deals';
      const contextualMessage = pipelineId ? `Pipeline ${pipelineId}: ${message}` : message;
      setError(new Error(contextualMessage));
      setDeals([]);
      setStages([]);
    } finally {
      setIsLoading(false);
    }
  }, [pipelineId, businessId, crmUser, getContext, options?.assignedRepUid]);

  // Initial fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Group deals by stage
  const dealsByStage = useMemo(() => {
    const grouped: DealsByStage = {};

    // Initialize all stages with empty deals array
    for (const stage of stages) {
      grouped[stage.id] = {
        stage,
        deals: [],
        totalValue: 0,
        count: 0,
      };
    }

    // Assign deals to their stages
    for (const deal of deals) {
      if (grouped[deal.stageId]) {
        grouped[deal.stageId].deals.push(deal);
        grouped[deal.stageId].totalValue += deal.valueCents;
        grouped[deal.stageId].count++;
      }
    }

    return grouped;
  }, [deals, stages]);

  // Calculate pipeline totals
  const { pipelineValue, pipelineCount } = useMemo(() => {
    return {
      pipelineValue: deals.reduce((sum, deal) => sum + deal.valueCents, 0),
      pipelineCount: deals.length,
    };
  }, [deals]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchData();
  }, [fetchData]);

  return {
    dealsByStage,
    stages,
    isLoading,
    error,
    pipelineValue,
    pipelineCount,
    refresh,
  };
}

export default useDealsByStage;
