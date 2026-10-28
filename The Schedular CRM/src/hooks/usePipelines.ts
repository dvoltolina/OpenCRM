/**
 * usePipelines Hook
 * Manages all pipelines for the business with CRUD operations
 *
 * Agent CRM-07 Implementation
 * Dependencies: Agent CRM-02 (pipeline repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getPipelineRepository } from '../data/repositories/pipeline-repository';
import { createSecurityContext } from './usePipeline';
import type { Pipeline } from '../types/models';
import { getUserTeamIds } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UsePipelinesResult {
  /** All active pipelines */
  pipelines: Pipeline[];
  /** The default pipeline, if one exists */
  defaultPipeline: Pipeline | null;
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Create a new pipeline */
  createPipeline: (data: Partial<Pipeline>) => Promise<Pipeline>;
  /** Set a pipeline as the default */
  setDefaultPipeline: (id: string) => Promise<void>;
  /** Archive a pipeline */
  archivePipeline: (id: string) => Promise<void>;
  /** Restore an archived pipeline */
  restorePipeline: (id: string) => Promise<void>;
  /** Update an existing pipeline */
  updatePipeline: (id: string, data: Partial<Pipeline>) => Promise<void>;
  /** Delete a pipeline (if allowed) */
  deletePipeline: (id: string) => Promise<void>;
  /** Manually refresh the pipeline list */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing all pipelines
 *
 * @returns Pipeline list, mutations, and state
 *
 * @example
 * ```tsx
 * const {
 *   pipelines,
 *   defaultPipeline,
 *   isLoading,
 *   createPipeline,
 *   setDefaultPipeline,
 * } = usePipelines();
 *
 * const handleCreate = async () => {
 *   await createPipeline({ name: 'New Pipeline', isDefault: false });
 * };
 * ```
 */
export function usePipelines(): UsePipelinesResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [pipelines, setPipelines] = useState<Pipeline[]>([]);
  const [defaultPipeline, setDefaultPipelineState] = useState<Pipeline | null>(null);
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

  // Fetch all active pipelines
  const fetchPipelines = useCallback(async () => {
    if (!businessId || !crmUser) {
      setPipelines([]);
      setDefaultPipelineState(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getPipelineRepository();

      // Fetch active pipelines
      const result = await repo.getActive(context, getUserTeamIds(crmUser));
      if (result.success) {
        setPipelines(result.data.data);

        // Find the default pipeline
        const defaultP = result.data.data.find((p) => p.isDefault) || null;
        setDefaultPipelineState(defaultP);
      } else {
        setError(new Error(result.error.message));
        setPipelines([]);
        setDefaultPipelineState(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch pipelines'));
      setPipelines([]);
      setDefaultPipelineState(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchPipelines();
  }, [fetchPipelines]);

  // Create a new pipeline
  const createPipeline = useCallback(
    async (data: Partial<Pipeline>): Promise<Pipeline> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const pipelineData = {
        name: data.name || 'New Pipeline',
        isDefault: data.isDefault ?? false,
        isActive: true,
        teamIds: data.teamIds ?? getUserTeamIds(crmUser),
      };

      const result = await repo.create(
        context,
        pipelineData as Omit<Pipeline, 'id' | 'createdAt' | 'updatedAt'>
      );

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();

      return result.data;
    },
    [crmUser, fetchPipelines, getContext]
  );

  // Set a pipeline as default
  const setDefaultPipeline = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const result = await repo.setDefault(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();
    },
    [getContext, fetchPipelines]
  );

  // Archive a pipeline
  const archivePipeline = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const result = await repo.archive(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();
    },
    [getContext, fetchPipelines]
  );

  // Restore an archived pipeline
  const restorePipeline = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const result = await repo.restore(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();
    },
    [getContext, fetchPipelines]
  );

  // Update an existing pipeline
  const updatePipeline = useCallback(
    async (id: string, data: Partial<Pipeline>): Promise<void> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const result = await repo.update(context, id, data);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();
    },
    [getContext, fetchPipelines]
  );

  // Delete a pipeline
  const deletePipeline = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getPipelineRepository();

      const result = await repo.delete(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchPipelines();
    },
    [getContext, fetchPipelines]
  );

  // Manual refresh
  const refresh = useCallback(() => {
    fetchPipelines();
  }, [fetchPipelines]);

  return {
    pipelines,
    defaultPipeline,
    isLoading,
    error,
    createPipeline: guardMutation(createPipeline, { action: 'pipeline-create' }),
    setDefaultPipeline: guardMutation(setDefaultPipeline, { action: 'pipeline-default' }),
    archivePipeline: guardMutation(archivePipeline, { action: 'pipeline-archive' }),
    restorePipeline: guardMutation(restorePipeline, { action: 'pipeline-restore' }),
    updatePipeline: guardMutation(updatePipeline, { action: 'pipeline-update' }),
    deletePipeline: guardMutation(deletePipeline, { action: 'pipeline-delete' }),
    refresh,
  };
}

export default usePipelines;
