/**
 * EntitySequenceBadge Component
 * Small badge shown on lead/contact/deal cards when enrolled in a sequence
 *
 * Phase 3 Implementation
 */

import { useEntityEnrollment } from '../../hooks/useSequenceEnrollments';
import type { EnrollmentEntityType } from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EntitySequenceBadgeProps {
  /** Entity type */
  entityType: EnrollmentEntityType;
  /** Entity ID */
  entityId: string;
  /** Optional email for validation */
  entityEmail?: string;
  /** Show as compact icon only */
  iconOnly?: boolean;
  /** Called when badge is clicked */
  onClick?: () => void;
}

// ============================================
// Component
// ============================================

export function EntitySequenceBadge({
  entityType,
  entityId,
  entityEmail,
  iconOnly = false,
  onClick,
}: EntitySequenceBadgeProps) {
  const { isEnrolled, activeEnrollment, isLoading } = useEntityEnrollment(
    entityType,
    entityId,
    entityEmail
  );

  // Don't show anything if not enrolled or loading
  if (isLoading || !isEnrolled || !activeEnrollment) {
    return null;
  }

  const progressPercent =
    activeEnrollment.totalSteps > 0
      ? Math.round((activeEnrollment.stepsCompleted / activeEnrollment.totalSteps) * 100)
      : 0;

  const statusClass =
    activeEnrollment.status === 'paused'
      ? 'entity-sequence-badge--paused'
      : 'entity-sequence-badge--active';

  if (iconOnly) {
    return (
      <button
        type="button"
        className={`entity-sequence-badge entity-sequence-badge--icon ${statusClass}`}
        onClick={onClick}
        title={`In sequence: ${activeEnrollment.sequenceName} (${progressPercent}%)`}
        data-testid="entity-sequence-badge"
      >
        <svg
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M12 2L2 7l10 5 10-5-10-5z" />
          <path d="M2 17l10 5 10-5" />
          <path d="M2 12l10 5 10-5" />
        </svg>
      </button>
    );
  }

  return (
    <button
      type="button"
      className={`entity-sequence-badge ${statusClass}`}
      onClick={onClick}
      title={`Click to view enrollment details`}
      data-testid="entity-sequence-badge"
    >
      <svg
        className="entity-sequence-badge__icon"
        width="12"
        height="12"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      >
        <path d="M12 2L2 7l10 5 10-5-10-5z" />
        <path d="M2 17l10 5 10-5" />
        <path d="M2 12l10 5 10-5" />
      </svg>
      <span className="entity-sequence-badge__name">
        {truncate(activeEnrollment.sequenceName, 15)}
      </span>
      <span className="entity-sequence-badge__progress">
        {activeEnrollment.stepsCompleted}/{activeEnrollment.totalSteps}
      </span>
      {activeEnrollment.status === 'paused' && (
        <span className="entity-sequence-badge__status">Paused</span>
      )}
    </button>
  );
}

// ============================================
// Simple Variant (no hook, just display)
// ============================================

export interface EntitySequenceBadgeSimpleProps {
  /** Sequence name */
  sequenceName: string;
  /** Steps completed */
  stepsCompleted: number;
  /** Total steps */
  totalSteps: number;
  /** Whether paused */
  isPaused?: boolean;
  /** Icon only mode */
  iconOnly?: boolean;
  /** Click handler */
  onClick?: () => void;
}

/**
 * Simple badge variant that doesn't fetch data - use when enrollment data is already available
 */
export function EntitySequenceBadgeSimple({
  sequenceName,
  stepsCompleted,
  totalSteps,
  isPaused = false,
  iconOnly = false,
  onClick,
}: EntitySequenceBadgeSimpleProps) {
  const progressPercent = totalSteps > 0 ? Math.round((stepsCompleted / totalSteps) * 100) : 0;
  const statusClass = isPaused
    ? 'entity-sequence-badge--paused'
    : 'entity-sequence-badge--active';

  if (iconOnly) {
    return (
      <button
        type="button"
        className={`entity-sequence-badge entity-sequence-badge--icon ${statusClass}`}
        onClick={onClick}
        title={`In sequence: ${sequenceName} (${progressPercent}%)`}
        data-testid="entity-sequence-badge-simple"
      >
        <svg
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M12 2L2 7l10 5 10-5-10-5z" />
          <path d="M2 17l10 5 10-5" />
          <path d="M2 12l10 5 10-5" />
        </svg>
      </button>
    );
  }

  return (
    <button
      type="button"
      className={`entity-sequence-badge ${statusClass}`}
      onClick={onClick}
      title={`Click to view enrollment details`}
      data-testid="entity-sequence-badge-simple"
    >
      <svg
        className="entity-sequence-badge__icon"
        width="12"
        height="12"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      >
        <path d="M12 2L2 7l10 5 10-5-10-5z" />
        <path d="M2 17l10 5 10-5" />
        <path d="M2 12l10 5 10-5" />
      </svg>
      <span className="entity-sequence-badge__name">{truncate(sequenceName, 15)}</span>
      <span className="entity-sequence-badge__progress">
        {stepsCompleted}/{totalSteps}
      </span>
      {isPaused && <span className="entity-sequence-badge__status">Paused</span>}
    </button>
  );
}

// ============================================
// Helpers
// ============================================

function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return `${str.slice(0, maxLength - 1)}…`;
}

export default EntitySequenceBadge;
