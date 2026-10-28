/**
 * useDealStageTransition Hook
 * React hook for deal stage transition operations
 *
 * Agent CRM-12 Implementation
 * Dependencies: Agent CRM-12 (deal stage service)
 *
 * This hook provides a React-friendly interface to the DealStageService
 * for moving deals between stages, marking won/lost, and viewing stage history.
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import {
  getDealStageService,
  type StageTransition,
  type WinLossData,
  type StageHistoryEntry,
  type CanMoveResult,
} from '../services/deal-stage-service';
import type { Deal } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseDealStageTransitionResult {
  /**
   * Check if a deal can be moved to a specific stage
   */
  canMoveToStage: (dealId: string, stageId: string) => Promise<CanMoveResult>;

  /**
   * Move a deal to a new stage with activity logging
   * @param dealId - ID of the deal to move
   * @param toStageId - ID of the target stage
   * @param reason - Optional reason for the transition
   */
  moveToStage: (dealId: string, toStageId: string, reason?: string) => Promise<Deal>;

  /**
   * Move a deal with explicit from/to stage IDs
   * Use this when you need to track the transition history
   */
  moveWithTransition: (transition: StageTransition) => Promise<Deal>;

  /**
   * Mark a deal as won
   * @param dealId - ID of the deal
   * @param reason - Optional reason for winning
   * @param actualValue - Actual closed value (if different from estimate)
   */
  markWon: (dealId: string, reason?: string, actualValue?: number) => Promise<Deal>;

  /**
   * Mark a deal as lost (reason required)
   * @param dealId - ID of the deal
   * @param reason - Required reason for losing
   */
  markLost: (dealId: string, reason: string) => Promise<Deal>;

  /**
   * Reopen a closed deal (won or lost)
   * @param dealId - ID of the deal to reopen
   */
  reopenDeal: (dealId: string) => Promise<Deal>;

  /**
   * Get the stage transition history for a deal
   * @param dealId - ID of the deal
   */
  getStageHistory: (dealId: string) => Promise<StageHistoryEntry[]>;

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
 * Hook for deal stage transition operations with activity logging
 *
 * @returns Stage transition functions, loading state, and error handling
 *
 * @example
 * ```tsx
 * const {
 *   moveToStage,
 *   markWon,
 *   markLost,
 *   getStageHistory,
 *   isLoading,
 * } = useDealStageTransition();
 *
 * // Move a deal to a new stage
 * await moveToStage('deal-123', 'stage-456', 'Customer requested proposal');
 *
 * // Mark deal as won
 * await markWon('deal-123', 'Great negotiation!');
 *
 * // Get stage history
 * const history = await getStageHistory('deal-123');
 * ```
 */
export function useDealStageTransition(): UseDealStageTransitionResult {
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

  // Check if a deal can be moved to a stage
  const canMoveToStage = useCallback(
    async (dealId: string, stageId: string): Promise<CanMoveResult> => {
      try {
        const context = getContext();
        const service = getDealStageService();
        return await service.canMoveToStage(context, dealId, stageId);
      } catch (err) {
        return {
          canMove: false,
          reason: err instanceof Error ? err.message : 'Unknown error',
        };
      }
    },
    [getContext]
  );

  // Move deal to a new stage (convenience method)
  const moveToStage = useCallback(
    async (dealId: string, toStageId: string, reason?: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDealStageService();

        const result = await service.validateAndMove(context, dealId, toStageId, reason);

        if (!result.success || !result.deal) {
          throw new Error(result.error || 'Failed to move deal');
        }

        return result.deal;
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

  // Move deal with explicit transition
  const moveWithTransition = useCallback(
    async (transition: StageTransition): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDealStageService();

        const result = await service.moveToStage(context, transition);

        if (!result.success || !result.deal) {
          throw new Error(result.error || 'Failed to move deal');
        }

        return result.deal;
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
    async (dealId: string, reason?: string, actualValue?: number): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDealStageService();

        const data: WinLossData = {
          dealId,
          outcome: 'won',
          reason,
          actualValue,
        };

        const result = await service.markWon(context, data);

        if (!result.success || !result.deal) {
          throw new Error(result.error || 'Failed to mark deal as won');
        }

        return result.deal;
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
    async (dealId: string, reason: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        if (!reason?.trim()) {
          throw new Error('Reason is required when marking a deal as lost');
        }

        const context = getContext();
        const service = getDealStageService();

        const data: WinLossData = {
          dealId,
          outcome: 'lost',
          reason,
        };

        const result = await service.markLost(context, data);

        if (!result.success || !result.deal) {
          throw new Error(result.error || 'Failed to mark deal as lost');
        }

        return result.deal;
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
    async (dealId: string): Promise<Deal> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDealStageService();

        const result = await service.reopenDeal(context, dealId);

        if (!result.success || !result.deal) {
          throw new Error(result.error || 'Failed to reopen deal');
        }

        return result.deal;
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

  // Get stage history
  const getStageHistory = useCallback(
    async (dealId: string): Promise<StageHistoryEntry[]> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDealStageService();

        const history = await service.getStageHistory(context, dealId);
        return history;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to get stage history');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    canMoveToStage,
    moveToStage: guardMutation(moveToStage, { action: 'deal-stage-move' }),
    moveWithTransition: guardMutation(moveWithTransition, { action: 'deal-stage-transition' }),
    markWon: guardMutation(markWon, { action: 'deal-mark-won' }),
    markLost: guardMutation(markLost, { action: 'deal-mark-lost' }),
    reopenDeal: guardMutation(reopenDeal, { action: 'deal-reopen' }),
    getStageHistory,
    isLoading,
    error,
    clearError,
  };
}

export default useDealStageTransition;
