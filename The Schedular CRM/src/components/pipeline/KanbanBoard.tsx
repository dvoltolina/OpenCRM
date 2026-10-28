/**
 * KanbanBoard Component
 * Interactive kanban board for pipeline deal management
 *
 * Agent CRM-16 Implementation
 * Agent CRM-35: Enhanced with improved keyboard navigation and accessibility
 * Dependencies: Agent CRM-09 (useDealsByStage), Agent CRM-12 (stage transitions)
 */

import { useMemo, useCallback } from 'react';
import {
  DndContext,
  DragOverlay,
  closestCorners,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
  type DragOverEvent,
} from '@dnd-kit/core';
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable';
import { KanbanColumn } from './KanbanColumn';
import { DealCard } from './DealCard';
import { useDealsByStage, type DealsByStage } from '../../hooks/useDealsByStage';
import { useKanbanDragDrop } from '../../hooks/useKanbanDragDrop';
import type { Deal, Pipeline } from '../../types/models';
import { Button } from '../ui';
import './pipeline.css';
import './pipeline-professional.css';

// ============================================
// Types
// ============================================

export interface KanbanBoardProps {
  /** The pipeline to display */
  pipeline: Pipeline;
  /** Called when a deal card is clicked */
  onDealClick?: (deal: Deal) => void;
  /** Called when "Add Deal" is clicked on a stage */
  onAddDeal?: (stageId: string) => void;
  /** Inline quick task handler */
  onQuickTask?: (deal: Deal, stageId: string) => void;
  /** Inline quick note handler */
  onQuickNote?: (deal: Deal, stageId: string) => void;
  /** Whether the user can move deals between stages */
  canMoveDeal?: (deal: Deal) => boolean;
  /** Read-only reason to surface when move is blocked */
  readOnlyReason?: string;
  /** Whether to show compact deal cards */
  compact?: boolean;
  /** Currency code for value formatting */
  currency?: string;
  /** Filter deals by assigned rep UID (for rep-specific views) */
  assignedRepUid?: string;
}

// ============================================
// Helpers
// ============================================

/**
 * Format cents to currency display
 */
function formatCurrency(cents: number, currency: string = 'USD'): string {
  const amount = cents / 100;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

/**
 * Get all deals from dealsByStage map
 */
function getAllDeals(dealsByStage: DealsByStage): Deal[] {
  return Object.values(dealsByStage).flatMap((stageData) => stageData.deals);
}

// ============================================
// Component
// ============================================

/**
 * KanbanBoard - Main kanban board component with drag-and-drop
 *
 * @example
 * ```tsx
 * <KanbanBoard
 *   pipeline={selectedPipeline}
 *   onDealClick={(deal) => openDealModal(deal)}
 *   onAddDeal={(stageId) => openCreateDealModal(stageId)}
 *   currency="USD"
 * />
 * ```
 */
export function KanbanBoard({
  pipeline,
  onDealClick,
  onAddDeal,
  onQuickTask,
  onQuickNote,
  canMoveDeal,
  readOnlyReason,
  compact = false,
  currency = 'USD',
  assignedRepUid,
}: KanbanBoardProps) {
  // Fetch deals grouped by stage, with optional rep filter
  const {
    dealsByStage,
    stages,
    isLoading,
    error,
    pipelineValue,
    pipelineCount,
    refresh,
  } = useDealsByStage(pipeline.id, { assignedRepUid });

  // Set up drag and drop
  const {
    dragState,
    handleDragStart,
    handleDragOver,
    handleDragEnd,
    handleDragCancel,
    isMoving,
    moveError,
    lastMoveAttempt,
    clearMoveError,
  } = useKanbanDragDrop({
    onMoveSuccess: () => {
      // Refresh data after successful move
      refresh();
    },
    canMoveDeal,
    readOnlyMessage: readOnlyReason,
  });

  // Get all deals for finding active deal
  const allDeals = useMemo(() => getAllDeals(dealsByStage), [dealsByStage]);

  // Configure sensors for drag and drop
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8, // Minimum drag distance before activating
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Drag event handlers
  const onDragStart = useCallback(
    (event: DragStartEvent) => {
      handleDragStart(event, allDeals);
    },
    [handleDragStart, allDeals]
  );

  const onDragOver = useCallback(
    (event: DragOverEvent) => {
      handleDragOver(event);
    },
    [handleDragOver]
  );

  const onDragEnd = useCallback(
    async (event: DragEndEvent) => {
      await handleDragEnd(event, stages);
    },
    [handleDragEnd, stages]
  );

  const onDragCancel = useCallback(() => {
    handleDragCancel();
  }, [handleDragCancel]);

  const getStageName = useCallback(
    (stageId: string | null) => stages.find((stage) => stage.id === stageId)?.name || 'selected stage',
    [stages]
  );

  const moveErrorMessage = useMemo(() => {
    if (!moveError) return '';
    if (!lastMoveAttempt) {
      return `Failed to move deal: ${moveError.message}`;
    }

    const fromStage = getStageName(lastMoveAttempt.fromStageId);
    const toStage = getStageName(lastMoveAttempt.toStageId);
    return `Could not move "${lastMoveAttempt.dealTitle}" from ${fromStage} to ${toStage}: ${moveError.message}`;
  }, [getStageName, lastMoveAttempt, moveError]);

  // Loading state
  if (isLoading) {
    return (
      <div className="kanban-board__loading" data-testid="kanban-loading">
        <div className="kanban-board__spinner" />
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="kanban-board__error" data-testid="kanban-error" role="alert" aria-live="assertive">
        <div className="kanban-board__error-title">Failed to load pipeline</div>
        <div className="kanban-board__error-message">
          {`We couldn't load the ${pipeline.name} pipeline.`}
          {error.message ? ` ${error.message}` : ''}
        </div>
        <Button variant="secondary" onClick={refresh}>
          Try Again
        </Button>
      </div>
    );
  }

  return (
    <>
      {/* Header with pipeline metrics */}
      <div className="kanban-board__header">
        <h2 className="kanban-board__title" id="pipeline-title">
          {pipeline.name}
        </h2>
        <div className="kanban-board__metrics" role="region" aria-label="Pipeline metrics">
          <div className="kanban-board__metric">
            <div className="kanban-board__metric-label" id="total-deals-label">
              Total Deals
            </div>
            <div
              className="kanban-board__metric-value"
              data-testid="pipeline-count"
              aria-labelledby="total-deals-label"
            >
              {pipelineCount}
            </div>
          </div>
          <div className="kanban-board__metric">
            <div className="kanban-board__metric-label" id="pipeline-value-label">
              Pipeline Value
            </div>
            <div
              className="kanban-board__metric-value"
              data-testid="pipeline-value"
              aria-labelledby="pipeline-value-label"
            >
              {formatCurrency(pipelineValue, currency)}
            </div>
          </div>
        </div>
      </div>

      {/* Kanban board with drag and drop */}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={onDragStart}
        onDragOver={onDragOver}
        onDragEnd={onDragEnd}
        onDragCancel={onDragCancel}
      >
        <div
          className={`kanban-board ${isMoving ? 'kanban-board--loading' : ''}`}
          data-testid="kanban-board"
          role="region"
          aria-label={`${pipeline.name} pipeline board`}
          aria-describedby="pipeline-title"
        >
          {stages.map((stage) => {
            const stageData = dealsByStage[stage.id];
            return (
              <KanbanColumn
                key={stage.id}
                stage={stage}
                deals={stageData?.deals || []}
                totalValue={stageData?.totalValue || 0}
                currency={currency}
                onDealClick={onDealClick}
                onAddDeal={onAddDeal}
                compact={compact}
                isDragOver={dragState.overStageId === stage.id}
                onQuickTask={onQuickTask}
                onQuickNote={onQuickNote}
              />
            );
          })}
        </div>

        {/* Drag overlay - shows the dragged card */}
        <DragOverlay>
          {dragState.activeDeal && (
            <div className="drag-overlay">
              <DealCard
                deal={dragState.activeDeal}
                stageId={dragState.originalStageId || ''}
                isDragging
                compact={compact}
              />
            </div>
          )}
        </DragOverlay>
      </DndContext>

      {/* Move error toast */}
      {moveError && (
        <div className="move-error-toast" role="alert" aria-live="assertive" aria-atomic="true">
          <span className="move-error-toast__message">{moveErrorMessage}</span>
          <button
            type="button"
            className="move-error-toast__close"
            onClick={clearMoveError}
            aria-label="Dismiss error message"
          >
            &times;
          </button>
        </div>
      )}
    </>
  );
}

export default KanbanBoard;
