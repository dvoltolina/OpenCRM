/**
 * EntitySequenceHistory Component
 * Shows sequence events in an entity's activity feed
 *
 * Phase 3 Implementation
 */

import { useEntityEnrollment } from '../../hooks/useSequenceEnrollments';
import type { EnrollmentEntityType, SequenceEnrollment, EnrollmentStatus } from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EntitySequenceHistoryProps {
  /** Entity type */
  entityType: EnrollmentEntityType;
  /** Entity ID */
  entityId: string;
  /** Show compact view */
  compact?: boolean;
  /** Called when an enrollment is clicked */
  onEnrollmentClick?: (enrollment: SequenceEnrollment) => void;
}

// ============================================
// Component
// ============================================

export function EntitySequenceHistory({
  entityType,
  entityId,
  compact = false,
  onEnrollmentClick,
}: EntitySequenceHistoryProps) {
  const { enrollmentHistory, isLoading, error, activeEnrollment } = useEntityEnrollment(
    entityType,
    entityId
  );

  if (isLoading) {
    return (
      <div className="entity-sequence-history entity-sequence-history--loading">
        <div className="entity-sequence-history__spinner" />
        <span>Loading sequence history...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="entity-sequence-history entity-sequence-history--error">
        Failed to load sequence history
      </div>
    );
  }

  if (enrollmentHistory.length === 0) {
    return (
      <div className="entity-sequence-history entity-sequence-history--empty">
        No sequence enrollments
      </div>
    );
  }

  if (compact) {
    return (
      <CompactHistory
        enrollments={enrollmentHistory}
        activeEnrollment={activeEnrollment}
        onEnrollmentClick={onEnrollmentClick}
      />
    );
  }

  return (
    <div className="entity-sequence-history" data-testid="entity-sequence-history">
      <h4 className="entity-sequence-history__title">Sequence History</h4>

      {/* Active enrollment highlight */}
      {activeEnrollment && (
        <div className="entity-sequence-history__active">
          <div className="entity-sequence-history__active-header">
            <span className="entity-sequence-history__active-badge">Active</span>
            <span className="entity-sequence-history__active-name">
              {activeEnrollment.sequenceName}
            </span>
          </div>
          <div className="entity-sequence-history__active-progress">
            <div className="entity-sequence-history__progress-bar">
              <div
                className="entity-sequence-history__progress-fill"
                style={{
                  width: `${getProgressPercent(activeEnrollment)}%`,
                }}
              />
            </div>
            <span className="entity-sequence-history__progress-text">
              {activeEnrollment.stepsCompleted}/{activeEnrollment.totalSteps} steps
            </span>
          </div>
          {activeEnrollment.nextStepScheduledAt && (
            <div className="entity-sequence-history__next-step">
              Next step: {formatDate(activeEnrollment.nextStepScheduledAt)}
            </div>
          )}
          <button
            type="button"
            className="btn btn-sm btn-secondary"
            onClick={() => onEnrollmentClick?.(activeEnrollment)}
          >
            View Details
          </button>
        </div>
      )}

      {/* History list */}
      <div className="entity-sequence-history__list">
        {enrollmentHistory
          .filter((e) => e.id !== activeEnrollment?.id)
          .map((enrollment) => (
            <HistoryItem
              key={enrollment.id}
              enrollment={enrollment}
              onClick={() => onEnrollmentClick?.(enrollment)}
            />
          ))}
      </div>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface CompactHistoryProps {
  enrollments: SequenceEnrollment[];
  activeEnrollment: SequenceEnrollment | null;
  onEnrollmentClick?: (enrollment: SequenceEnrollment) => void;
}

function CompactHistory({
  enrollments,
  activeEnrollment,
  onEnrollmentClick,
}: CompactHistoryProps) {
  return (
    <div
      className="entity-sequence-history entity-sequence-history--compact"
      data-testid="entity-sequence-history-compact"
    >
      {activeEnrollment ? (
        <button
          type="button"
          className="entity-sequence-history__compact-active"
          onClick={() => onEnrollmentClick?.(activeEnrollment)}
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
          <span>{activeEnrollment.sequenceName}</span>
          <span className="entity-sequence-history__compact-progress">
            ({activeEnrollment.stepsCompleted}/{activeEnrollment.totalSteps})
          </span>
        </button>
      ) : enrollments.length > 0 ? (
        <span className="entity-sequence-history__compact-count">
          {enrollments.length} past sequence{enrollments.length > 1 ? 's' : ''}
        </span>
      ) : null}
    </div>
  );
}

interface HistoryItemProps {
  enrollment: SequenceEnrollment;
  onClick: () => void;
}

function HistoryItem({ enrollment, onClick }: HistoryItemProps) {
  const statusLabel = getStatusLabel(enrollment.status);
  const statusClass = getStatusClass(enrollment.status);

  return (
    <button
      type="button"
      className="entity-sequence-history__item"
      onClick={onClick}
      data-testid={`history-item-${enrollment.id}`}
    >
      <div className="entity-sequence-history__item-header">
        <span className="entity-sequence-history__item-name">{enrollment.sequenceName}</span>
        <span className={`entity-sequence-history__item-status ${statusClass}`}>
          {statusLabel}
        </span>
      </div>
      <div className="entity-sequence-history__item-meta">
        <span>
          {enrollment.stepsCompleted}/{enrollment.totalSteps} steps completed
        </span>
        <span>•</span>
        <span>{formatDate(enrollment.createdAt)}</span>
      </div>
      {enrollment.exitReason && (
        <div className="entity-sequence-history__item-reason">
          Exited: {formatExitReason(enrollment.exitReason)}
        </div>
      )}
    </button>
  );
}

// ============================================
// Activity Feed Integration Events
// ============================================

export interface SequenceActivityEvent {
  id: string;
  type: 'sequence_enrolled' | 'sequence_email' | 'sequence_completed' | 'sequence_exited';
  timestamp: Date;
  title: string;
  description: string;
  metadata: {
    sequenceId: string;
    sequenceName: string;
    enrollmentId?: string;
    stepIndex?: number;
    exitReason?: string;
  };
}

/**
 * Convert enrollment to activity events for entity timeline
 */
export function enrollmentToActivityEvents(
  enrollment: SequenceEnrollment
): SequenceActivityEvent[] {
  const events: SequenceActivityEvent[] = [];

  // Enrollment event
  events.push({
    id: `${enrollment.id}-enrolled`,
    type: 'sequence_enrolled',
    timestamp: enrollment.createdAt,
    title: `Enrolled in ${enrollment.sequenceName}`,
    description: `Added to sequence by ${enrollment.enrolledByName}`,
    metadata: {
      sequenceId: enrollment.sequenceId,
      sequenceName: enrollment.sequenceName,
      enrollmentId: enrollment.id,
    },
  });

  // Email events (simplified - would need execution data for full detail)
  if (enrollment.emailsSent > 0) {
    events.push({
      id: `${enrollment.id}-emails`,
      type: 'sequence_email',
      timestamp: enrollment.updatedAt || enrollment.createdAt,
      title: `${enrollment.emailsSent} sequence email${enrollment.emailsSent > 1 ? 's' : ''} sent`,
      description: `${enrollment.emailsOpened} opened, ${enrollment.repliesReceived} replied`,
      metadata: {
        sequenceId: enrollment.sequenceId,
        sequenceName: enrollment.sequenceName,
        enrollmentId: enrollment.id,
      },
    });
  }

  // Completion/exit event
  if (enrollment.completedAt) {
    events.push({
      id: `${enrollment.id}-completed`,
      type: 'sequence_completed',
      timestamp: enrollment.completedAt,
      title: `Completed ${enrollment.sequenceName}`,
      description: `Finished all ${enrollment.totalSteps} steps`,
      metadata: {
        sequenceId: enrollment.sequenceId,
        sequenceName: enrollment.sequenceName,
        enrollmentId: enrollment.id,
      },
    });
  } else if (enrollment.exitedAt) {
    events.push({
      id: `${enrollment.id}-exited`,
      type: 'sequence_exited',
      timestamp: enrollment.exitedAt,
      title: `Exited ${enrollment.sequenceName}`,
      description: formatExitReason(enrollment.exitReason || 'unknown'),
      metadata: {
        sequenceId: enrollment.sequenceId,
        sequenceName: enrollment.sequenceName,
        enrollmentId: enrollment.id,
        exitReason: enrollment.exitReason,
      },
    });
  }

  return events;
}

// ============================================
// Helpers
// ============================================

function getProgressPercent(enrollment: SequenceEnrollment): number {
  return enrollment.totalSteps > 0
    ? Math.round((enrollment.stepsCompleted / enrollment.totalSteps) * 100)
    : 0;
}

function getStatusLabel(status: EnrollmentStatus): string {
  const labels: Record<EnrollmentStatus, string> = {
    active: 'Active',
    paused: 'Paused',
    completed: 'Completed',
    exited: 'Exited',
    bounced: 'Bounced',
    unsubscribed: 'Unsubscribed',
  };
  return labels[status] || status;
}

function getStatusClass(status: EnrollmentStatus): string {
  const classes: Record<EnrollmentStatus, string> = {
    active: 'entity-sequence-history__item-status--active',
    paused: 'entity-sequence-history__item-status--paused',
    completed: 'entity-sequence-history__item-status--completed',
    exited: 'entity-sequence-history__item-status--exited',
    bounced: 'entity-sequence-history__item-status--bounced',
    unsubscribed: 'entity-sequence-history__item-status--unsubscribed',
  };
  return classes[status] || '';
}

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date);
}

function formatExitReason(reason: string): string {
  const labels: Record<string, string> = {
    manual: 'Manually removed',
    replied: 'Contact replied',
    unsubscribed: 'Unsubscribed',
    bounced: 'Email bounced',
    meeting_booked: 'Meeting booked',
    deal_won: 'Deal won',
    deal_lost: 'Deal lost',
    converted: 'Lead converted',
    sequence_paused: 'Sequence paused',
    sequence_archived: 'Sequence archived',
  };
  return labels[reason] || reason;
}

export default EntitySequenceHistory;
