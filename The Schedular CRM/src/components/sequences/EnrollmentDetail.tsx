/**
 * EnrollmentDetail Component
 * Detailed view of a single enrollment with timeline and actions
 *
 * Phase 3 Implementation
 */

import { useState, useCallback } from 'react';
import { useEnrollmentMutations } from '../../hooks/useSequenceEnrollments';
import { EnrollmentTimeline } from './EnrollmentTimeline';
import type {
  SequenceEnrollment,
  EnrollmentStatus,
  EnrollmentEntityType,
  ExitReason,
} from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EnrollmentDetailProps {
  /** Enrollment to display */
  enrollment: SequenceEnrollment;
  /** Called when enrollment is updated */
  onUpdate?: (enrollment: SequenceEnrollment) => void;
  /** Called when back button is clicked */
  onBack?: () => void;
  /** Called when entity link is clicked */
  onEntityClick?: (entityType: EnrollmentEntityType, entityId: string) => void;
  /** Whether this is displayed in a slideover */
  isSlideOver?: boolean;
}

// ============================================
// Component
// ============================================

export function EnrollmentDetail({
  enrollment,
  onUpdate,
  onBack,
  onEntityClick,
  isSlideOver = false,
}: EnrollmentDetailProps) {
  const [confirmAction, setConfirmAction] = useState<'pause' | 'exit' | 'skip' | null>(null);

  const { pause, resume, exit, isMutating, mutationError } = useEnrollmentMutations();

  // Calculate progress
  const progressPercent =
    enrollment.totalSteps > 0
      ? Math.round((enrollment.stepsCompleted / enrollment.totalSteps) * 100)
      : 0;

  // Action handlers
  const handlePause = useCallback(async () => {
    try {
      const updated = await pause(enrollment.id, 'manual');
      onUpdate?.(updated);
      setConfirmAction(null);
    } catch {
      // Error handled by hook
    }
  }, [enrollment.id, pause, onUpdate]);

  const handleResume = useCallback(async () => {
    try {
      const updated = await resume(enrollment.id);
      onUpdate?.(updated);
    } catch {
      // Error handled by hook
    }
  }, [enrollment.id, resume, onUpdate]);

  const handleExit = useCallback(async () => {
    try {
      const updated = await exit(enrollment.id, 'manual');
      onUpdate?.(updated);
      setConfirmAction(null);
    } catch {
      // Error handled by hook
    }
  }, [enrollment.id, exit, onUpdate]);

  const containerClass = isSlideOver
    ? 'enrollment-detail enrollment-detail--slideover'
    : 'enrollment-detail';

  return (
    <div className={containerClass} data-testid="enrollment-detail">
      {/* Header */}
      <div className="enrollment-detail__header">
        {onBack && (
          <button
            type="button"
            className="enrollment-detail__back"
            onClick={onBack}
            aria-label="Go back"
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M19 12H5M12 19l-7-7 7-7" />
            </svg>
          </button>
        )}
        <div className="enrollment-detail__header-content">
          <h2 className="enrollment-detail__title">{enrollment.entityName}</h2>
          <p className="enrollment-detail__subtitle">{enrollment.entityEmail}</p>
        </div>
        <StatusBadge status={enrollment.status} />
      </div>

      {/* Sequence Info */}
      <div className="enrollment-detail__sequence-info">
        <span className="enrollment-detail__sequence-label">Sequence:</span>
        <span className="enrollment-detail__sequence-name">{enrollment.sequenceName}</span>
      </div>

      {/* Progress Bar */}
      <div className="enrollment-detail__progress-section">
        <div className="enrollment-detail__progress-header">
          <span className="enrollment-detail__progress-label">Progress</span>
          <span className="enrollment-detail__progress-value">
            {enrollment.stepsCompleted} of {enrollment.totalSteps} steps
          </span>
        </div>
        <div className="enrollment-detail__progress-bar">
          <div
            className="enrollment-detail__progress-fill"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
        <div className="enrollment-detail__progress-percent">{progressPercent}% complete</div>
      </div>

      {/* Next Step */}
      {enrollment.status === 'active' && enrollment.nextStepScheduledAt && (
        <div className="enrollment-detail__next-step">
          <div className="enrollment-detail__next-step-icon">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <circle cx="12" cy="12" r="10" />
              <polyline points="12 6 12 12 16 14" />
            </svg>
          </div>
          <div className="enrollment-detail__next-step-content">
            <span className="enrollment-detail__next-step-label">Next step scheduled</span>
            <span className="enrollment-detail__next-step-time">
              {formatDateTime(enrollment.nextStepScheduledAt)}
            </span>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="enrollment-detail__stats">
        <div className="enrollment-detail__stat">
          <span className="enrollment-detail__stat-value">{enrollment.emailsSent}</span>
          <span className="enrollment-detail__stat-label">Emails Sent</span>
        </div>
        <div className="enrollment-detail__stat">
          <span className="enrollment-detail__stat-value">{enrollment.emailsOpened}</span>
          <span className="enrollment-detail__stat-label">Opens</span>
        </div>
        <div className="enrollment-detail__stat">
          <span className="enrollment-detail__stat-value">{enrollment.emailsClicked}</span>
          <span className="enrollment-detail__stat-label">Clicks</span>
        </div>
        <div className="enrollment-detail__stat">
          <span className="enrollment-detail__stat-value">{enrollment.repliesReceived}</span>
          <span className="enrollment-detail__stat-label">Replies</span>
        </div>
        <div className="enrollment-detail__stat">
          <span className="enrollment-detail__stat-value">{enrollment.tasksCreated}</span>
          <span className="enrollment-detail__stat-label">Tasks</span>
        </div>
      </div>

      {/* Error Message */}
      {mutationError && (
        <div className="enrollment-detail__error" role="alert">
          {mutationError.message}
        </div>
      )}

      {/* Actions */}
      <div className="enrollment-detail__actions">
        {enrollment.status === 'active' && (
          <>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => setConfirmAction('pause')}
              disabled={isMutating}
            >
              Pause
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => setConfirmAction('skip')}
              disabled={isMutating}
              title="Coming soon"
            >
              Skip Step
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => setConfirmAction('exit')}
              disabled={isMutating}
            >
              Remove from Sequence
            </button>
          </>
        )}
        {enrollment.status === 'paused' && (
          <>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleResume}
              disabled={isMutating}
            >
              {isMutating ? 'Resuming...' : 'Resume'}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => setConfirmAction('exit')}
              disabled={isMutating}
            >
              Remove from Sequence
            </button>
          </>
        )}
        {onEntityClick && (
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => onEntityClick(enrollment.entityType, enrollment.entityId)}
          >
            View {enrollment.entityType}
          </button>
        )}
      </div>

      {/* Confirm Dialog */}
      {confirmAction && (
        <ConfirmDialog
          action={confirmAction}
          entityName={enrollment.entityName}
          isMutating={isMutating}
          onConfirm={confirmAction === 'pause' ? handlePause : handleExit}
          onCancel={() => setConfirmAction(null)}
        />
      )}

      {/* Timeline */}
      <div className="enrollment-detail__timeline-section">
        <h3 className="enrollment-detail__section-title">Activity Timeline</h3>
        <EnrollmentTimeline enrollment={enrollment} />
      </div>

      {/* Metadata */}
      <div className="enrollment-detail__metadata">
        <div className="enrollment-detail__metadata-row">
          <span className="enrollment-detail__metadata-label">Enrolled by:</span>
          <span className="enrollment-detail__metadata-value">{enrollment.enrolledByName}</span>
        </div>
        <div className="enrollment-detail__metadata-row">
          <span className="enrollment-detail__metadata-label">Enrolled on:</span>
          <span className="enrollment-detail__metadata-value">
            {formatDateTime(enrollment.createdAt)}
          </span>
        </div>
        {enrollment.exitedAt && (
          <div className="enrollment-detail__metadata-row">
            <span className="enrollment-detail__metadata-label">Exited on:</span>
            <span className="enrollment-detail__metadata-value">
              {formatDateTime(enrollment.exitedAt)}
            </span>
          </div>
        )}
        {enrollment.exitReason && (
          <div className="enrollment-detail__metadata-row">
            <span className="enrollment-detail__metadata-label">Exit reason:</span>
            <span className="enrollment-detail__metadata-value">
              {formatExitReason(enrollment.exitReason)}
            </span>
          </div>
        )}
        {enrollment.completedAt && (
          <div className="enrollment-detail__metadata-row">
            <span className="enrollment-detail__metadata-label">Completed on:</span>
            <span className="enrollment-detail__metadata-value">
              {formatDateTime(enrollment.completedAt)}
            </span>
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface StatusBadgeProps {
  status: EnrollmentStatus;
}

function StatusBadge({ status }: StatusBadgeProps) {
  const variants: Record<EnrollmentStatus, string> = {
    active: 'success',
    paused: 'warning',
    completed: 'info',
    exited: 'default',
    bounced: 'danger',
    unsubscribed: 'danger',
  };

  const labels: Record<EnrollmentStatus, string> = {
    active: 'Active',
    paused: 'Paused',
    completed: 'Completed',
    exited: 'Exited',
    bounced: 'Bounced',
    unsubscribed: 'Unsubscribed',
  };

  return (
    <span className={`enrollment-status-badge enrollment-status-badge--${variants[status]}`}>
      {labels[status]}
    </span>
  );
}

interface ConfirmDialogProps {
  action: 'pause' | 'exit' | 'skip';
  entityName: string;
  isMutating: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

function ConfirmDialog({
  action,
  entityName,
  isMutating,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const titles: Record<string, string> = {
    pause: 'Pause Enrollment',
    exit: 'Remove from Sequence',
    skip: 'Skip Current Step',
  };

  const messages: Record<string, string> = {
    pause: `Pause the sequence for ${entityName}? You can resume it later.`,
    exit: `Remove ${entityName} from this sequence? This action cannot be undone.`,
    skip: `Skip the current step for ${entityName}? This will move them to the next step.`,
  };

  const confirmLabels: Record<string, string> = {
    pause: 'Pause',
    exit: 'Remove',
    skip: 'Skip',
  };

  return (
    <div className="enrollment-detail__confirm-overlay" onClick={onCancel}>
      <div
        className="enrollment-detail__confirm-dialog"
        onClick={(e) => e.stopPropagation()}
        role="alertdialog"
        aria-labelledby="confirm-title"
        aria-describedby="confirm-message"
      >
        <h4 id="confirm-title" className="enrollment-detail__confirm-title">
          {titles[action]}
        </h4>
        <p id="confirm-message" className="enrollment-detail__confirm-message">
          {messages[action]}
        </p>
        <div className="enrollment-detail__confirm-actions">
          <button
            type="button"
            className="btn btn-secondary"
            onClick={onCancel}
            disabled={isMutating}
          >
            Cancel
          </button>
          <button
            type="button"
            className={`btn ${action === 'exit' ? 'btn-danger' : 'btn-primary'}`}
            onClick={onConfirm}
            disabled={isMutating}
          >
            {isMutating ? 'Processing...' : confirmLabels[action]}
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================
// Helpers
// ============================================

function formatDateTime(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}

function formatExitReason(reason: ExitReason): string {
  const labels: Record<ExitReason, string> = {
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

export default EnrollmentDetail;
