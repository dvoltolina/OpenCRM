/**
 * useDealMutations Hook
 * CRUD operations and stage management for deals
 *
 * Agent CRM-09 Implementation
 * Dependencies: Agent CRM-04 (deals repository)
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getDealRepository } from '../data/repositories/deal-repository';
import { createSecurityContext } from './usePipeline';
import { sanitizeTeamIds } from '../lib/security-context';
import { dispatchAutomationEvent } from '../services/automation-dispatcher';
import type { Deal } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface CreateDealInput {
  title: string;
  pipelineId: string;
  stageId: string;
  valueCents: number;
  currency?: string;
  probability?: number;
  expectedCloseDate?: Date;
  clientId?: string;
  clientName?: string;
  companyId?: string;
  companyName?: string;
  assigneeId?: string;
  assigneeName?: string;
  tags?: string[];
  notes?: string;
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: Deal['visibility'];
}

export interface UseDealMutationsResult {
  /** Create a new deal */
  createDeal: (data: CreateDealInput) => Promise<Deal>;
  /** Update an existing deal */
  updateDeal: (id: string, data: Partial<Deal>) => Promise<Deal>;
  /** Delete a deal */
  deleteDeal: (id: string) => Promise<void>;
  /** Move deal to a new stage */
  moveToStage: (id: string, stageId: string, probability?: number) => Promise<Deal>;
  /** Mark deal as won */
  markWon: (id: string, reason?: string) => Promise<Deal>;
  /** Mark deal as lost (reason required) */
  markLost: (id: string, reason: string) => Promise<Deal>;
  /** Reopen a closed deal */
  reopenDeal: (id: string) => Promise<Deal>;
  /** Assign deal to a user */
  assignDeal: (id: string, assigneeId: string, assigneeName: string) => Promise<Deal>;
  /** True while an operation is in progress */
  isLoading: boolean;
  /** Error from the last operation */
  error: Error | null;
  /** Clear the error state */
  clearError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for deal CRUD operations and stage management
 *
 * @returns Mutation functions, loading state, and error handling
 *
 * @example
 * ```tsx
 * const {
 *   createDeal,
 *   moveToStage,
 *   markWon,
 *   isLoading,
 *   error,
 * } = useDealMutations();
 *
 * const handleCreate = async () => {
 *   try {
 *     const deal = await createDeal({
 *       title: 'New Deal',
 *       pipelineId: 'pipeline-123',
 *       stageId: 'stage-1',
 *       valueCents: 100000,
 *     });
 *     console.log('Created:', deal.id);
 *   } catch (err) {
 *     console.error('Failed:', err);
 *   }
 * };
 * ```
 */
export function useDealMutations(): UseDealMutationsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isLoading, setIsLoading] = useState(false);
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

  // Clear error
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // Create a new deal
  const createDeal = useCallback(
    async (data: CreateDealInput): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        // crmUser is guaranteed non-null here since getContext() throws if null
        const currentUser = crmUser!;
        const dealData = {
          title: data.title,
          pipelineId: data.pipelineId,
          stageId: data.stageId,
          valueCents: data.valueCents,
          currency: data.currency || 'USD',
          probability: data.probability ?? 50,
          expectedCloseDate: data.expectedCloseDate,
          status: 'open' as const,
          clientId: data.clientId,
          clientName: data.clientName,
          companyId: data.companyId,
          companyName: data.companyName,
          assigneeId: data.assigneeId,
          assigneeName: data.assigneeName,
          tags: data.tags || [],
          notes: data.notes,
          ownerId: data.ownerId ?? currentUser.id,
          ownerName: data.ownerName ?? currentUser.displayName ?? currentUser.email ?? 'Unknown User',
          teamIds: data.teamIds ? sanitizeTeamIds(data.teamIds) : undefined,
          visibility: data.visibility ?? 'team',
        };

        const result = await repo.create(
          context,
          dealData as Omit<Deal, 'id' | 'createdAt' | 'updatedAt'>
        );

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, getContext]
  );

  // Update an existing deal
  const updateDeal = useCallback(
    async (id: string, data: Partial<Deal>): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.update(context, id, {
          ...data,
          teamIds: data.teamIds ? sanitizeTeamIds(data.teamIds) : data.teamIds,
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Delete a deal
  const deleteDeal = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Move deal to a new stage
  const moveToStage = useCallback(
    async (id: string, stageId: string, probability?: number): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();
        let previousStageId: string | undefined;

        const existing = await repo.getById(context, id);
        if (existing.success && existing.data) {
          previousStageId = existing.data.stageId;
        }

        const result = await repo.moveToStage(context, id, stageId, probability);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        void dispatchAutomationEvent({
          triggerType: 'dealStageChanged',
          entityId: id,
          entityType: 'deal',
          businessId: context.businessId,
          fromStageId: previousStageId,
          toStageId: (result.data as Deal | undefined)?.stageId ?? stageId,
        });

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to move deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Mark deal as won
  const markWon = useCallback(
    async (id: string, reason?: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.markWon(context, id, reason);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to mark deal as won');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Mark deal as lost (reason required)
  const markLost = useCallback(
    async (id: string, reason: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.markLost(context, id, reason);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to mark deal as lost');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Reopen a closed deal
  const reopenDeal = useCallback(
    async (id: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.reopen(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to reopen deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Assign deal to a user
  const assignDeal = useCallback(
    async (id: string, assigneeId: string, assigneeName: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getDealRepository();

        const result = await repo.update(context, id, {
          assigneeId,
          assigneeName,
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to assign deal');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createDeal: guardMutation(createDeal, { action: 'deal-create' }),
    updateDeal: guardMutation(updateDeal, { action: 'deal-update' }),
    deleteDeal: guardMutation(deleteDeal, { action: 'deal-delete' }),
    moveToStage: guardMutation(moveToStage, { action: 'deal-stage-move' }),
    markWon: guardMutation(markWon, { action: 'deal-mark-won' }),
    markLost: guardMutation(markLost, { action: 'deal-mark-lost' }),
    reopenDeal: guardMutation(reopenDeal, { action: 'deal-reopen' }),
    assignDeal: guardMutation(assignDeal, { action: 'deal-assign' }),
    isLoading,
    error,
    clearError,
  };
}

export default useDealMutations;
