/**
 * useStages Hook
 * Manages stages for a specific pipeline
 *
 * Agent CRM-07 Implementation
 * Dependencies: Agent CRM-02 (stage repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getStageRepository } from '../data/repositories/stage-repository';
import { createSecurityContext } from './usePipeline';
import type { Stage } from '../types/models';
import { getUserTeamIds } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseStagesResult {
  /** All stages for the pipeline, ordered by 'order' field */
  stages: Stage[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Create a new stage */
  createStage: (data: Partial<Stage>) => Promise<Stage>;
  /** Update an existing stage */
  updateStage: (id: string, data: Partial<Stage>) => Promise<void>;
  /** Reorder stages atomically */
  reorderStages: (stageIds: string[]) => Promise<void>;
  /** Archive a stage */
  archiveStage: (id: string) => Promise<void>;
  /** Restore an archived stage */
  restoreStage: (id: string) => Promise<void>;
  /** Delete a stage */
  deleteStage: (id: string) => Promise<void>;
  /** Manually refresh the stage list */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing stages within a pipeline
 *
 * @param pipelineId - ID of the pipeline to fetch stages for
 * @returns Stage list, mutations, and state
 *
 * @example
 * ```tsx
 * const {
 *   stages,
 *   isLoading,
 *   createStage,
 *   reorderStages,
 * } = useStages('pipeline-123');
 *
 * const handleReorder = async (newOrder: string[]) => {
 *   await reorderStages(newOrder);
 * };
 * ```
 */
export function useStages(pipelineId: string | undefined): UseStagesResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [stages, setStages] = useState<Stage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

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

  // Fetch all stages for the pipeline
  const fetchStages = useCallback(async () => {
    if (!pipelineId || !businessId || !crmUser) {
      setStages([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      // Fetch active stages ordered by 'order' field
      const result = await repo.getActiveByPipeline(
        context,
        pipelineId,
        resolvedTeamIds
      );

      if (result.success) {
        setStages(result.data);
      } else {
        setError(new Error(result.error.message));
        setStages([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch stages'));
      setStages([]);
    } finally {
      setIsLoading(false);
    }
  }, [pipelineId, businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchStages();
  }, [fetchStages]);

  // Create a new stage
  const createStage = useCallback(
    async (data: Partial<Stage>): Promise<Stage> => {
      if (!pipelineId) {
        throw new Error('Pipeline ID is required');
      }

      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      // Get next order number
      const nextOrder = await repo.getNextOrder(
        context,
        pipelineId,
        resolvedTeamIds
      );

      const stageData = {
        pipelineId,
        name: data.name || 'New Stage',
        order: data.order ?? nextOrder,
        colorHex: data.colorHex || '#6B7280',
        probability: data.probability ?? 50,
        isActive: true,
      };

      const result = await repo.create(
        context,
        stageData as Omit<Stage, 'id' | 'createdAt' | 'updatedAt'>,
        undefined,
        resolvedTeamIds
      );

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchStages();

      return result.data;
    },
    [crmUser, pipelineId, getContext, fetchStages]
  );

  // Update an existing stage
  const updateStage = useCallback(
    async (id: string, data: Partial<Stage>): Promise<void> => {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      const result = await repo.update(context, id, data, resolvedTeamIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchStages();
    },
    [crmUser, getContext, fetchStages]
  );

  // Reorder stages atomically
  const reorderStages = useCallback(
    async (stageIds: string[]): Promise<void> => {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      const result = await repo.reorder(context, stageIds, resolvedTeamIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Optimistically update local state
      const reorderedStages = stageIds
        .map((id, index) => {
          const stage = stages.find((s) => s.id === id);
          return stage ? { ...stage, order: index } : null;
        })
        .filter((s): s is Stage => s !== null);

      setStages(reorderedStages);

      // Also refresh to ensure consistency
      await fetchStages();
    },
    [crmUser, getContext, stages, fetchStages]
  );

  // Archive a stage
  const archiveStage = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      const result = await repo.archive(context, id, resolvedTeamIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchStages();
    },
    [crmUser, getContext, fetchStages]
  );

  // Restore an archived stage
  const restoreStage = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      const result = await repo.restore(context, id, resolvedTeamIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchStages();
    },
    [crmUser, getContext, fetchStages]
  );

  // Delete a stage
  const deleteStage = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getStageRepository();
      const resolvedTeamIds = getUserTeamIds(crmUser);

      const result = await repo.delete(context, id, resolvedTeamIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchStages();
    },
    [crmUser, getContext, fetchStages]
  );

  // Manual refresh
  const refresh = useCallback(() => {
    fetchStages();
  }, [fetchStages]);

  return {
    stages,
    isLoading,
    error,
    createStage: guardMutation(createStage, { action: 'stage-create' }),
    updateStage: guardMutation(updateStage, { action: 'stage-update' }),
    reorderStages: guardMutation(reorderStages, { action: 'stage-reorder' }),
    archiveStage: guardMutation(archiveStage, { action: 'stage-archive' }),
    restoreStage: guardMutation(restoreStage, { action: 'stage-restore' }),
    deleteStage: guardMutation(deleteStage, { action: 'stage-delete' }),
    refresh,
  };
}

export default useStages;
