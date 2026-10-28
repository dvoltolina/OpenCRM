/**
 * DealCard Component
 * Draggable deal card for the kanban board
 *
 * Agent CRM-16 Implementation
 */

import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import type { Deal } from '../../types/models';
import './pipeline.css';

// ============================================
// Types
// ============================================

export interface DealCardProps {
  /** The deal to display */
  deal: Deal;
  /** Called when the card is clicked */
  onClick?: (deal: Deal) => void;
  /** Quick note action (inline) */
  onQuickNote?: (deal: Deal, stageId: string) => void;
  /** Quick task action (inline) */
  onQuickTask?: (deal: Deal, stageId: string) => void;
  /** Whether the card is in a dragging state */
  isDragging?: boolean;
  /** Whether to show compact variant */
  compact?: boolean;
  /** Stage ID for drag data */
  stageId: string;
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
 * Format date for display
 */
function formatDate(date: Date | undefined): string {
  if (!date) return '';
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
  }).format(date);
}

/**
 * Get initials from a name
 */
function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

// ============================================
// Component
// ============================================

/**
 * DealCard - Draggable card displaying deal information
 *
 * @example
 * ```tsx
 * <DealCard
 *   deal={deal}
 *   stageId={stage.id}
 *   onClick={(deal) => openDealModal(deal)}
 * />
 * ```
 */
export function DealCard({
  deal,
  onClick,
  onQuickNote,
  onQuickTask,
  isDragging,
  compact,
  stageId,
}: DealCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging: isSortableDragging,
  } = useSortable({
    id: deal.id,
    data: {
      type: 'deal',
      deal,
      stageId,
    },
  });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const isCurrentlyDragging = isDragging || isSortableDragging;

  const handleClick = () => {
    // Don't trigger click during drag
    if (!isCurrentlyDragging && onClick) {
      onClick(deal);
    }
  };

  const handleKeyDown: React.KeyboardEventHandler<HTMLDivElement> = (event) => {
    if (event.key.toLowerCase() === 't' && onQuickTask) {
      event.preventDefault();
      onQuickTask(deal, stageId);
    }
    if (event.key.toLowerCase() === 'n' && onQuickNote) {
      event.preventDefault();
      onQuickNote(deal, stageId);
    }
  };

  if (compact) {
    return (
      <div
        ref={setNodeRef}
        style={style}
        {...attributes}
        {...listeners}
        className={`deal-card deal-card--compact ${isCurrentlyDragging ? 'deal-card--dragging' : ''}`}
        onClick={handleClick}
        onKeyDown={handleKeyDown}
        tabIndex={onClick || onQuickTask || onQuickNote ? 0 : undefined}
        data-testid={`deal-card-${deal.id}`}
      >
        <div className="deal-card__title" title={deal.title}>{deal.title}</div>
        <div className="deal-card__value">{formatCurrency(deal.valueCents, deal.currency)}</div>
      </div>
    );
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className={`deal-card ${isCurrentlyDragging ? 'deal-card--dragging' : ''}`}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      data-testid={`deal-card-${deal.id}`}
      tabIndex={onClick || onQuickTask || onQuickNote ? 0 : undefined}
    >
      <div className="deal-card__header">
        <span className="deal-card__title" title={deal.title}>{deal.title}</span>
        <span className="deal-card__value">{formatCurrency(deal.valueCents, deal.currency)}</span>
      </div>

      {(deal.clientName || deal.companyName) && (
        <div className="deal-card__client">
          {deal.clientName && (
            <div className="deal-card__client-avatar">{getInitials(deal.clientName)}</div>
          )}
          <span className="deal-card__client-name">
            {deal.clientName || deal.companyName}
          </span>
        </div>
      )}

      <div className="deal-card__footer">
        {deal.expectedCloseDate && (
          <span className="deal-card__date">{formatDate(deal.expectedCloseDate)}</span>
        )}
        <span className="deal-card__probability">{deal.probability}%</span>
        {(onQuickTask || onQuickNote) && (
          <div className="deal-card__actions" aria-label="Quick actions">
            {onQuickTask && (
              <button
                type="button"
                className="deal-card__action"
                onClick={(e) => {
                  e.stopPropagation();
                  onQuickTask(deal, stageId);
                }}
                onMouseDown={(e) => e.stopPropagation()}
                title="Create follow-up task (T)"
                aria-label="Create follow-up task"
              >
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <circle cx="12" cy="12" r="8" />
                  <path d="m9.5 12 1.8 1.8 3.7-3.9" />
                </svg>
              </button>
            )}
            {onQuickNote && (
              <button
                type="button"
                className="deal-card__action"
                onClick={(e) => {
                  e.stopPropagation();
                  onQuickNote(deal, stageId);
                }}
                onMouseDown={(e) => e.stopPropagation()}
                title="Add note (N)"
                aria-label="Add note"
              >
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z" />
                  <path d="M14 3v5h5" />
                  <path d="M9 13h6" />
                  <path d="M9 17h4" />
                </svg>
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default DealCard;
