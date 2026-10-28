/**
 * KanbanColumn Component
 * A single column in the kanban board representing a pipeline stage
 *
 * Agent CRM-16 Implementation
 */

import { useDroppable } from '@dnd-kit/core';
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { StageHeader } from './StageHeader';
import { DealCard } from './DealCard';
import { EmptyStage } from './EmptyStage';
import type { Deal, Stage } from '../../types/models';
import './pipeline.css';

// ============================================
// Types
// ============================================

export interface KanbanColumnProps {
  /** The stage for this column */
  stage: Stage;
  /** Deals in this column */
  deals: Deal[];
  /** Total value of deals in cents */
  totalValue: number;
  /** Currency code for formatting */
  currency?: string;
  /** Called when a deal card is clicked */
  onDealClick?: (deal: Deal) => void;
  /** Called when "Add Deal" is clicked */
  onAddDeal?: (stageId: string) => void;
  /** Inline quick task handler */
  onQuickTask?: (deal: Deal, stageId: string) => void;
  /** Inline quick note handler */
  onQuickNote?: (deal: Deal, stageId: string) => void;
  /** Whether to show compact deal cards */
  compact?: boolean;
  /** Whether this column is being dragged over */
  isDragOver?: boolean;
}

// ============================================
// Component
// ============================================

/**
 * KanbanColumn - Stage column with deal cards
 *
 * @example
 * ```tsx
 * <KanbanColumn
 *   stage={stage}
 *   deals={dealsInStage}
 *   totalValue={stageValue}
 *   onDealClick={(deal) => openModal(deal)}
 *   onAddDeal={(stageId) => createDeal(stageId)}
 * />
 * ```
 */
export function KanbanColumn({
  stage,
  deals,
  totalValue,
  currency = 'USD',
  onDealClick,
  onAddDeal,
  onQuickTask,
  onQuickNote,
  compact = false,
  isDragOver,
}: KanbanColumnProps) {
  // Make column droppable
  const { setNodeRef, isOver } = useDroppable({
    id: stage.id,
    data: {
      type: 'stage',
      stage,
    },
  });

  const isHighlighted = isDragOver || isOver;

  // Get deal IDs for sortable context
  const dealIds = deals.map((deal) => deal.id);

  return (
    <div
      ref={setNodeRef}
      className={`kanban-column ${isHighlighted ? 'kanban-column--drag-over' : ''}`}
      data-testid={`kanban-column-${stage.id}`}
    >
      <StageHeader
        stage={stage}
        count={deals.length}
        totalValue={totalValue}
        currency={currency}
      />

      <div className="kanban-column__content">
        <SortableContext items={dealIds} strategy={verticalListSortingStrategy}>
          {deals.length === 0 ? (
            <EmptyStage stageName={stage.name} />
          ) : (
            deals.map((deal) => (
              <DealCard
                key={deal.id}
                deal={deal}
                stageId={stage.id}
                onClick={onDealClick}
                onQuickTask={onQuickTask}
                onQuickNote={onQuickNote}
                compact={compact}
              />
            ))
          )}
        </SortableContext>
      </div>

      {onAddDeal && (
        <button
          type="button"
          className="kanban-column__add-btn"
          onClick={() => onAddDeal(stage.id)}
          aria-label={`Add opportunity to ${stage.name}`}
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          Add Opportunity
        </button>
      )}
    </div>
  );
}

export default KanbanColumn;
