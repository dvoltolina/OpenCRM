/**
 * useKanbanDragDrop Hook
 * Manages drag-and-drop state for the pipeline kanban board
 *
 * Agent CRM-16 Implementation
 * Dependencies: Agent CRM-09 (useDealsByStage), Agent CRM-12 (stage transitions)
 */

import { useState, useCallback } from 'react';
import type { DragStartEvent, DragEndEvent, DragOverEvent } from '@dnd-kit/core';
import { useDealStageTransition } from './useDealStageTransition';
import type { Deal, Stage } from '../types/models';

// ============================================
// Types
// ============================================

export interface DragState {
  /** The deal being dragged */
  activeDeal: Deal | null;
  /** The stage the deal is currently over */
  overStageId: string | null;
  /** Original stage ID before drag started */
  originalStageId: string | null;
}

interface MoveAttemptContext {
  dealTitle: string;
  fromStageId: string;
  toStageId: string;
}

export interface UseKanbanDragDropOptions {
  /** Called after a successful stage move */
  onMoveSuccess?: (deal: Deal, fromStageId: string, toStageId: string) => void;
  /** Called when a move fails */
  onMoveError?: (error: Error, deal: Deal) => void;
  /** Optional guard to determine if the caller can move a deal */
  canMoveDeal?: (deal: Deal) => boolean;
  /** Optional read-only message surfaced when a move is blocked */
  readOnlyMessage?: string;
}

export interface UseKanbanDragDropResult {
  /** Current drag state */
  dragState: DragState;
  /** Handler for drag start event */
  handleDragStart: (event: DragStartEvent, deals: Deal[]) => void;
  /** Handler for drag over event */
  handleDragOver: (event: DragOverEvent) => void;
  /** Handler for drag end event */
  handleDragEnd: (event: DragEndEvent, stages: Stage[]) => Promise<void>;
  /** Handler for drag cancel event */
  handleDragCancel: () => void;
  /** Whether a move operation is in progress */
  isMoving: boolean;
  /** Error from the last move operation */
  moveError: Error | null;
  /** Details about the last attempted move (for contextual errors) */
  lastMoveAttempt: MoveAttemptContext | null;
  /** Clear the move error */
  clearMoveError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing kanban board drag-and-drop operations
 *
 * @param options - Configuration options
 * @returns Drag state, handlers, and operation status
 *
 * @example
 * ```tsx
 * const {
 *   dragState,
 *   handleDragStart,
 *   handleDragOver,
 *   handleDragEnd,
 *   handleDragCancel,
 *   isMoving,
 * } = useKanbanDragDrop({
 *   onMoveSuccess: (deal, from, to) => {
 *     console.log(`Moved ${deal.title} from ${from} to ${to}`);
 *     refresh(); // Refresh the data
 *   },
 * });
 * ```
 */
export function useKanbanDragDrop(
  options: UseKanbanDragDropOptions = {}
): UseKanbanDragDropResult {
  const { onMoveSuccess, onMoveError, canMoveDeal, readOnlyMessage } = options;

  // Use the stage transition hook for actual moves
  const { moveToStage, isLoading: isMoving, error: transitionError, clearError } = useDealStageTransition();

  // Local drag state
  const [dragState, setDragState] = useState<DragState>({
    activeDeal: null,
    overStageId: null,
    originalStageId: null,
  });

  const [moveError, setMoveError] = useState<Error | null>(null);
  const [lastMoveAttempt, setLastMoveAttempt] = useState<MoveAttemptContext | null>(null);

  // Handle drag start
  const handleDragStart = useCallback(
    (event: DragStartEvent, deals: Deal[]) => {
      const dealId = event.active.id as string;
      const deal = deals.find((d) => d.id === dealId);

      if (!deal) return;
      if (canMoveDeal && !canMoveDeal(deal)) {
        setMoveError(new Error(readOnlyMessage || 'You do not have permission to move this deal'));
        setLastMoveAttempt({
          dealTitle: deal.title,
          fromStageId: deal.stageId,
          toStageId: deal.stageId,
        });
        return;
      }

      setDragState({
        activeDeal: deal,
        overStageId: deal.stageId,
        originalStageId: deal.stageId,
      });
      setMoveError(null);
      setLastMoveAttempt(null);
    },
    [canMoveDeal, readOnlyMessage]
  );

  // Handle drag over
  const handleDragOver = useCallback((event: DragOverEvent) => {
    const overId = event.over?.id as string | undefined;

    if (overId) {
      setDragState((prev) => ({
        ...prev,
        overStageId: overId,
      }));
    }
  }, []);

  // Handle drag end
  const handleDragEnd = useCallback(
    async (event: DragEndEvent, stages: Stage[]) => {
      const { over } = event;
      const deal = dragState.activeDeal;
      const originalStageId = dragState.originalStageId;

      // Reset drag state immediately for UI responsiveness
      setDragState({
        activeDeal: null,
        overStageId: null,
        originalStageId: null,
      });

      // If no drop target or no deal, do nothing
      if (!over || !deal || !originalStageId) {
        return;
      }

      // Extract stage ID from drop target
      // The over.id could be a stage column ID or a deal card ID
      let targetStageId = over.id as string;

      // Check if the target is a deal (dropped on another deal card)
      // In that case, use the stage of that deal
      if (!stages.find((s) => s.id === targetStageId)) {
        // Try to find the stage from the over data
        const overData = over.data?.current as { stageId?: string } | undefined;
        if (overData?.stageId) {
          targetStageId = overData.stageId;
        } else {
          // Dropped on something that's not a stage, cancel
          return;
        }
      }

      // If dropped on the same stage, no action needed
      if (targetStageId === originalStageId) {
        return;
      }

      // Enforce move guard
      if (canMoveDeal && !canMoveDeal(deal)) {
        setMoveError(new Error(readOnlyMessage || 'You do not have permission to move this deal'));
        setLastMoveAttempt({
          dealTitle: deal.title,
          fromStageId: originalStageId,
          toStageId: targetStageId,
        });
        return;
      }

      // Perform the stage transition
      try {
        setLastMoveAttempt({
          dealTitle: deal.title,
          fromStageId: originalStageId,
          toStageId: targetStageId,
        });
        const updatedDeal = await moveToStage(deal.id, targetStageId);
        setLastMoveAttempt(null);
        onMoveSuccess?.(updatedDeal, originalStageId, targetStageId);
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to move deal');
        setMoveError(error);
        onMoveError?.(error, deal);
      }
    },
    [canMoveDeal, dragState, moveToStage, onMoveError, onMoveSuccess, readOnlyMessage]
  );

  // Handle drag cancel
  const handleDragCancel = useCallback(() => {
    setDragState({
      activeDeal: null,
      overStageId: null,
      originalStageId: null,
    });
    setLastMoveAttempt(null);
  }, []);

  // Clear move error
  const clearMoveError = useCallback(() => {
    setMoveError(null);
    clearError();
    setLastMoveAttempt(null);
  }, [clearError]);

  return {
    dragState,
    handleDragStart,
    handleDragOver,
    handleDragEnd,
    handleDragCancel,
    isMoving,
    moveError: moveError || transitionError,
    lastMoveAttempt,
    clearMoveError,
  };
}

export default useKanbanDragDrop;
