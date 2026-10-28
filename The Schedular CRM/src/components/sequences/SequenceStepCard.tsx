/**
 * SequenceStepCard Component
 * Individual step display card with drag handle and actions
 */

import type { ReactNode } from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import type { SequenceStep, SequenceStepType } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceStepCardProps {
  step: SequenceStep;
  index: number;
  totalSteps: number;
  hasError?: boolean;
  isConfirmingDelete?: boolean;
  isDragging?: boolean;
  disabled?: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
  onDuplicate?: () => void;
}

// ============================================
// Helpers
// ============================================

function getStepIcon(type: SequenceStepType): ReactNode {
  switch (type) {
    case 'email':
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
          <path d="m22 6-10 7L2 6" />
        </svg>
      );
    case 'task':
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M9 11l3 3L22 4" />
          <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
        </svg>
      );
    case 'wait':
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 6v6l4 2" />
        </svg>
      );
    case 'call_reminder':
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
        </svg>
      );
    case 'sms':
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      );
    default:
      return (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
        </svg>
      );
  }
}

function getStepTypeName(type: SequenceStepType): string {
  switch (type) {
    case 'email':
      return 'Email';
    case 'task':
      return 'Task';
    case 'wait':
      return 'Wait';
    case 'call_reminder':
      return 'Call';
    case 'sms':
      return 'SMS';
    default:
      return 'Step';
  }
}

function getStepSummary(step: SequenceStep): string {
  switch (step.type) {
    case 'email':
      if (step.emailConfig?.subject) {
        return step.emailConfig.subject;
      }
      if (step.emailConfig?.templateId) {
        return 'Using template';
      }
      return 'No subject set';
    case 'task':
      return step.taskConfig?.title || 'No title set';
    case 'wait':
      const days = step.delayDays || 0;
      const hours = step.delayHours || 0;
      const parts = [];
      if (days > 0) parts.push(`${days} day${days !== 1 ? 's' : ''}`);
      if (hours > 0) parts.push(`${hours} hour${hours !== 1 ? 's' : ''}`);
      return parts.length > 0 ? `Wait ${parts.join(' ')}` : 'No delay set';
    case 'call_reminder':
      return step.callConfig?.title || 'No title set';
    case 'sms':
      if (step.smsConfig?.body) {
        return step.smsConfig.body.substring(0, 50) + (step.smsConfig.body.length > 50 ? '...' : '');
      }
      if (step.smsConfig?.templateId) {
        return 'Using template';
      }
      return 'No message set';
    default:
      return 'Configure step';
  }
}

function calculateCumulativeDay(step: SequenceStep, index: number, allSteps?: SequenceStep[]): string {
  if (index === 0) return 'Day 1';

  // For a standalone card (like in drag overlay), just show the step's delay
  if (!allSteps) {
    return step.delayDays > 0 ? `+${step.delayDays} day${step.delayDays !== 1 ? 's' : ''}` : 'Same day';
  }

  // Calculate cumulative days
  let totalDays = 1; // Start at day 1
  for (let i = 1; i <= index; i++) {
    totalDays += allSteps[i].delayDays || 0;
  }
  return `Day ${totalDays}`;
}

// ============================================
// Component
// ============================================

export function SequenceStepCard({
  step,
  index,
  totalSteps: _totalSteps,
  hasError = false,
  isConfirmingDelete = false,
  isDragging = false,
  disabled = false,
  onEdit,
  onDelete,
  onDuplicate,
}: SequenceStepCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging: isSortableDragging,
  } = useSortable({ id: step.id, disabled });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const isActuallyDragging = isDragging || isSortableDragging;
  const iconClass = `sequence-step-card__icon sequence-step-card__icon--${step.type === 'call_reminder' ? 'call' : step.type}`;

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`sequence-step-card ${isActuallyDragging ? 'sequence-step-card--dragging' : ''} ${hasError ? 'sequence-step-card--error' : ''}`}
      data-testid={`step-card-${step.id}`}
    >
      {/* Drag Handle */}
      <div
        className="sequence-step-card__drag-handle"
        {...attributes}
        {...listeners}
        aria-label="Drag to reorder"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM8 12a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM8 18a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM14 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM14 12a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM14 18a2 2 0 1 1-4 0 2 2 0 0 1 4 0z" />
        </svg>
      </div>

      {/* Content */}
      <div className="sequence-step-card__content">
        <div className={iconClass}>
          {getStepIcon(step.type)}
        </div>
        <div className="sequence-step-card__info">
          <span className="sequence-step-card__type">
            {getStepTypeName(step.type)}
          </span>
          <span className="sequence-step-card__summary">
            {getStepSummary(step)}
          </span>
          {index > 0 && step.type !== 'wait' && (
            <span className="sequence-step-card__delay">
              {calculateCumulativeDay(step, index)}
            </span>
          )}
        </div>
      </div>

      {/* Actions */}
      {(onEdit || onDelete || onDuplicate) && (
        <div className="sequence-step-card__actions">
          {onEdit && (
            <button
              type="button"
              className="sequence-step-card__action-btn"
              onClick={onEdit}
              disabled={disabled}
              aria-label="Edit step"
              title="Edit"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
              </svg>
            </button>
          )}
          {onDuplicate && (
            <button
              type="button"
              className="sequence-step-card__action-btn"
              onClick={onDuplicate}
              disabled={disabled}
              aria-label="Duplicate step"
              title="Duplicate"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
              </svg>
            </button>
          )}
          {onDelete && (
            <button
              type="button"
              className={`sequence-step-card__action-btn sequence-step-card__action-btn--delete ${isConfirmingDelete ? 'sequence-step-card__action-btn--confirming' : ''}`}
              onClick={onDelete}
              disabled={disabled}
              aria-label={isConfirmingDelete ? 'Confirm delete' : 'Delete step'}
              title={isConfirmingDelete ? 'Click again to confirm' : 'Delete'}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
              </svg>
            </button>
          )}
        </div>
      )}
    </div>
  );
}

export default SequenceStepCard;
