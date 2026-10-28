/**
 * usePipeline Hook
 * Fetches and manages a single pipeline by ID
 *
 * Agent CRM-07 Implementation
 * Dependencies: Agent CRM-02 (pipeline repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getPipelineRepository } from '../data/repositories/pipeline-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Pipeline } from '../types/models';
import {
  createSecurityContextFromParams,
  getDefaultManagedTeamIds,
  getDefaultTeamIds,
  getUserManagedTeamIds,
  getUserTeamIds,
  getShareableAccessSummary,
  type ShareableAccessSummary,
} from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface UsePipelineResult {
  /** The pipeline data, null if loading or not found */
  pipeline: Pipeline | null;
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if fetch failed */
  error: Error | null;
  /** Manually refresh the pipeline data */
  refresh: () => void;
  /** Access metadata helper for UI guards */
  getAccessSummary: (pipeline: Pipeline | null) => ShareableAccessSummary | null;
}

// ============================================
// Helper: Create SecurityContext from Auth
// ============================================

export function createSecurityContext(
  businessId: string,
  userId: string,
  userName: string,
  userRole: string,
  teamIds: string[] = [],
  managedTeamIds: string[] = [],
  managerId?: string
): SecurityContext {
  const resolvedTeamIds = teamIds.length ? teamIds : getDefaultTeamIds();
  const resolvedManagedTeamIds = managedTeamIds.length ? managedTeamIds : getDefaultManagedTeamIds();
  return createSecurityContextFromParams(
    businessId,
    userId,
    userName,
    userRole,
    resolvedTeamIds,
    resolvedManagedTeamIds,
    managerId
  );
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and managing a single pipeline
 *
 * @param pipelineId - ID of the pipeline to fetch
 * @returns Pipeline data, loading state, error, and refresh function
 *
 * @example
 * ```tsx
 * const { pipeline, isLoading, error, refresh } = usePipeline('pipeline-123');
 *
 * if (isLoading) return <Spinner />;
 * if (error) return <Error message={error.message} />;
 * if (!pipeline) return <NotFound />;
 *
 * return <PipelineView pipeline={pipeline} />;
 * ```
 */
export function usePipeline(pipelineId: string | undefined): UsePipelineResult {
  const { crmUser, businessId } = useAuth();
  const [pipeline, setPipeline] = useState<Pipeline | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchPipeline = useCallback(async () => {
    if (!pipelineId || !businessId || !crmUser) {
      setPipeline(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = createSecurityContext(
        businessId,
        crmUser.id,
        crmUser.displayName,
        crmUser.role,
        getUserTeamIds(crmUser),
        getUserManagedTeamIds(crmUser)
      );

      const repo = getPipelineRepository();
      const result = await repo.getById(context, pipelineId);

      if (result.success) {
        setPipeline(result.data);
      } else {
        setError(new Error(result.error.message));
        setPipeline(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch pipeline'));
      setPipeline(null);
    } finally {
      setIsLoading(false);
    }
  }, [pipelineId, businessId, crmUser]);

  // Initial fetch
  useEffect(() => {
    fetchPipeline();
  }, [fetchPipeline]);

  const refresh = useCallback(() => {
    fetchPipeline();
  }, [fetchPipeline]);

  const getAccessSummary = useCallback(
    (target: Pipeline | null): ShareableAccessSummary | null => {
      if (!target || !businessId || !crmUser) return null;
      const context = createSecurityContext(
        businessId,
        crmUser.id,
        crmUser.displayName,
        crmUser.role,
        getUserTeamIds(crmUser),
        getUserManagedTeamIds(crmUser)
      );
      return getShareableAccessSummary(context, target);
    },
    [businessId, crmUser]
  );

  return {
    pipeline,
    isLoading,
    error,
    refresh,
    getAccessSummary,
  };
}

export default usePipeline;
