/**
 * StageList Component
 * Sortable list of pipeline stages with edit/archive actions
 *
 * Agent CRM-20 Implementation
 */

import React, { useState } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import type { Stage } from '../../types/models';
import './settings.css';

// ============================================
// Types
// ============================================

export interface StageListProps {
  /** List of stages to display */
  stages: Stage[];
  /** Called when stage order changes */
  onReorder: (stageIds: string[]) => Promise<void>;
  /** Called when edit is clicked */
  onEdit: (stage: Stage) => void;
  /** Called when archive/restore is clicked */
  onArchive: (stage: Stage) => Promise<void>;
  /** Whether reordering is disabled */
  disabled?: boolean;
  /** Whether user can modify stages (RBAC) */
  canModify?: boolean;
}

interface SortableStageItemProps {
  stage: Stage;
  onEdit: (stage: Stage) => void;
  onArchive: (stage: Stage) => Promise<void>;
  disabled?: boolean;
  canModify?: boolean;
}

// ============================================
// Sortable Stage Item
// ============================================

function SortableStageItem({ stage, onEdit, onArchive, disabled, canModify = true }: SortableStageItemProps) {
  const [isArchiving, setIsArchiving] = useState(false);

  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: stage.id,
    disabled,
  });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const handleArchive = async () => {
    setIsArchiving(true);
    try {
      await onArchive(stage);
    } finally {
      setIsArchiving(false);
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`stage-list__item ${isDragging ? 'stage-list__item--dragging' : ''} ${!stage.isActive ? 'stage-list__item--archived' : ''}`}
      data-testid={`stage-item-${stage.id}`}
    >
      <div className="stage-list__drag-handle" {...attributes} {...listeners}>
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <line x1="8" y1="6" x2="16" y2="6" />
          <line x1="8" y1="12" x2="16" y2="12" />
          <line x1="8" y1="18" x2="16" y2="18" />
        </svg>
      </div>

      <div
        className="stage-list__color"
        style={{ backgroundColor: stage.colorHex }}
        aria-hidden="true"
      />

      <div className="stage-list__info">
        <span className="stage-list__name">{stage.name}</span>
        <span className="stage-list__probability">{stage.probability}% probability</span>
      </div>

      <div className="stage-list__actions">
        <button
          type="button"
          className="stage-list__btn"
          onClick={() => onEdit(stage)}
          disabled={disabled || !canModify}
          title={!canModify ? 'Only owners and admins can edit stages' : `Edit ${stage.name}`}
          aria-label={`Edit ${stage.name}`}
        >
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
          </svg>
        </button>
        <button
          type="button"
          className="stage-list__btn stage-list__btn--archive"
          onClick={handleArchive}
          disabled={disabled || isArchiving || !canModify}
          title={!canModify ? 'Only owners and admins can archive stages' : (stage.isActive ? `Archive ${stage.name}` : `Restore ${stage.name}`)}
          aria-label={stage.isActive ? `Archive ${stage.name}` : `Restore ${stage.name}`}
        >
          {stage.isActive ? (
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <polyline points="3 6 5 6 21 6" />
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
            </svg>
          ) : (
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.85 1 6.5 2.5" />
              <polyline points="21 3 21 9 15 9" />
            </svg>
          )}
        </button>
      </div>
    </div>
  );
}

// ============================================
// Component
// ============================================

/**
 * StageList - Sortable list of stages with drag-and-drop
 *
 * @example
 * ```tsx
 * <StageList
 *   stages={stages}
 *   onReorder={handleReorder}
 *   onEdit={openStageEditor}
 *   onArchive={handleArchive}
 * />
 * ```
 */
export function StageList({
  stages,
  onReorder,
  onEdit,
  onArchive,
  disabled = false,
  canModify = true,
}: StageListProps) {
  const [isReordering, setIsReordering] = useState(false);

  // Configure sensors
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Handle drag end
  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;

    if (!over || active.id === over.id) {
      return;
    }

    // Find indices
    const oldIndex = stages.findIndex((s) => s.id === active.id);
    const newIndex = stages.findIndex((s) => s.id === over.id);

    if (oldIndex === -1 || newIndex === -1) {
      return;
    }

    // Create new order
    const newStages = [...stages];
    const [removed] = newStages.splice(oldIndex, 1);
    newStages.splice(newIndex, 0, removed);

    // Call reorder with new order
    setIsReordering(true);
    try {
      await onReorder(newStages.map((s) => s.id));
    } finally {
      setIsReordering(false);
    }
  };

  const stageIds = stages.map((s) => s.id);

  if (stages.length === 0) {
    return (
      <div className="stage-list__empty" data-testid="stage-list-empty">
        <p>No stages yet. Add your first stage to get started.</p>
      </div>
    );
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragEnd={handleDragEnd}
    >
      <div
        className={`stage-list ${isReordering ? 'stage-list--reordering' : ''}`}
        data-testid="stage-list"
      >
        <SortableContext items={stageIds} strategy={verticalListSortingStrategy}>
          {stages.map((stage) => (
            <SortableStageItem
              key={stage.id}
              stage={stage}
              onEdit={onEdit}
              onArchive={onArchive}
              disabled={disabled || isReordering}
              canModify={canModify}
            />
          ))}
        </SortableContext>
      </div>
    </DndContext>
  );
}

export default StageList;
