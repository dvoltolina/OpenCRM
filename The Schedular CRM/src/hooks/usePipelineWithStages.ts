/**
 * usePipelineWithStages Hook
 * Combined hook that fetches a pipeline with its stages
 * If no pipelineId is provided, uses the default pipeline
 *
 * Agent CRM-07 Implementation
 * Dependencies: Agent CRM-02 (pipeline/stage repositories)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getPipelineRepository, DEFAULT_STAGES } from '../data/repositories/pipeline-repository';
import { getStageRepository } from '../data/repositories/stage-repository';
import { createSecurityContext } from './usePipeline';
import type { Pipeline, Stage } from '../types/models';
import { getUserTeamIds } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface UsePipelineWithStagesResult {
  /** The pipeline data */
  pipeline: Pipeline | null;
  /** All active stages for the pipeline, ordered */
  stages: Stage[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether the default pipeline was used (no pipelineId provided) */
  isDefault: boolean;
  /** Total count of stages */
  stageCount: number;
  /** Manually refresh both pipeline and stages */
  refresh: () => void;
  /** Whether the user can create a pipeline when none are accessible */
  canCreatePipeline: boolean;
  /** Helper to create a default pipeline with default stages */
  createDefaultPipeline: () => Promise<Pipeline>;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Combined hook for fetching a pipeline with its stages
 * If no pipelineId is provided, automatically fetches the default pipeline
 *
 * @param pipelineId - Optional ID of the pipeline. If omitted, uses default pipeline.
 * @returns Pipeline, stages, and state
 *
 * @example
 * ```tsx
 * // Use default pipeline
 * const { pipeline, stages, isLoading } = usePipelineWithStages();
 *
 * // Use specific pipeline
 * const { pipeline, stages } = usePipelineWithStages('pipeline-123');
 *
 * // Render kanban columns
 * return (
 *   <div>
 *     {stages.map(stage => (
 *       <KanbanColumn key={stage.id} stage={stage} />
 *     ))}
 *   </div>
 * );
 * ```
 */
export function usePipelineWithStages(
  pipelineId?: string
): UsePipelineWithStagesResult {
  const { crmUser, businessId } = useAuth();
  const [pipeline, setPipeline] = useState<Pipeline | null>(null);
  const [stages, setStages] = useState<Stage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [isDefault, setIsDefault] = useState(false);
  const [canCreatePipeline, setCanCreatePipeline] = useState(false);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    const teamIds = getUserTeamIds(crmUser);
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      teamIds
    );
  }, [businessId, crmUser]);

  // Fetch pipeline and stages
  const fetchData = useCallback(async () => {
    if (!businessId || !crmUser) {
      setPipeline(null);
      setStages([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const pipelineRepo = getPipelineRepository();
      const stageRepo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      let targetPipelineId = pipelineId;

      // If no pipelineId provided, get the default pipeline
      if (!targetPipelineId) {
        const defaultResult = await pipelineRepo.getDefault(context);
        if (defaultResult.success && defaultResult.data) {
          targetPipelineId = defaultResult.data.id;
          setPipeline(defaultResult.data);
          setIsDefault(true);
        } else {
          // No default pipeline exists or accessible, attempt to fall back to first accessible pipeline
          const activeResult = await pipelineRepo.getActive(context, resolvedTeamIds);
          if (activeResult.success && activeResult.data.data.length > 0) {
            const firstPipeline = activeResult.data.data[0];
            targetPipelineId = firstPipeline.id;
            setPipeline(firstPipeline);
            setIsDefault(false);
            setCanCreatePipeline(false);
          } else {
            setPipeline(null);
            setStages([]);
            setIsDefault(true);
            setCanCreatePipeline(
              context.userRole !== 'frontDesk' && context.userRole !== 'client'
            );
            setIsLoading(false);
            return;
          }
        }
      } else {
        // Fetch specific pipeline
        const pipelineResult = await pipelineRepo.getById(
          context,
          targetPipelineId,
          resolvedTeamIds
        );
        if (pipelineResult.success) {
          setPipeline(pipelineResult.data);
          setIsDefault(false);
          setCanCreatePipeline(false);
        } else {
          if (pipelineResult.error?.code === 'PERMISSION_DENIED') {
            setPipeline(null);
            setStages([]);
            setIsDefault(false);
            setCanCreatePipeline(
              context.userRole !== 'frontDesk' && context.userRole !== 'client'
            );
            setIsLoading(false);
            return;
          }
          setError(new Error(pipelineResult.error.message));
          setPipeline(null);
          setStages([]);
          setIsLoading(false);
          return;
        }
      }

      // Fetch stages for the pipeline
      const stagesResult = await stageRepo.getActiveByPipeline(
        context,
        targetPipelineId,
        resolvedTeamIds
      );

      if (stagesResult.success) {
        setStages(stagesResult.data);
      } else {
        setError(new Error(stagesResult.error.message));
        setStages([]);
      }
    } catch (err) {
      setError(
        err instanceof Error ? err : new Error('Failed to fetch pipeline data')
      );
      setPipeline(null);
      setStages([]);
    } finally {
      setIsLoading(false);
    }
  }, [pipelineId, businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchData();
  }, [fetchData]);

  const createDefaultPipeline = useCallback(async () => {
    const context = getContext();
    const pipelineRepo = getPipelineRepository();
    const stageRepo = getStageRepository();
    const resolvedTeamIds = getUserTeamIds(crmUser);

    const result = await pipelineRepo.create(
      context,
      {
        name: 'Default Pipeline',
        isDefault: true,
        isActive: true,
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: resolvedTeamIds,
      }
    );

    if (!result.success) {
      throw new Error(result.error.message);
    }

    const defaultStages = DEFAULT_STAGES.map((stage) => ({
      ...stage,
      isActive: true,
    }));

    await stageRepo.createMany(
      context,
      result.data.id,
      defaultStages as Array<Omit<Stage, 'id' | 'pipelineId' | 'createdAt' | 'updatedAt'>>,
      resolvedTeamIds
    );

    await pipelineRepo.setDefault(context, result.data.id);
    await fetchData();
    return result.data;
  }, [crmUser, fetchData, getContext]);

  return {
    pipeline,
    stages,
    isLoading,
    error,
    isDefault,
    stageCount: stages.length,
    refresh,
    canCreatePipeline,
    createDefaultPipeline,
  };
}

export default usePipelineWithStages;
