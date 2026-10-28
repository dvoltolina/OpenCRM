/**
 * EnrollmentModal Component
 * Modal for enrolling a single entity (lead/contact/deal) in a sequence
 *
 * Phase 3 Implementation
 */

import { useState, useEffect, useMemo } from 'react';
import { useSequences } from '../../hooks/useSequences';
import { useEnrollmentMutations, useEntityEnrollment } from '../../hooks/useSequenceEnrollments';
import type { Sequence, EnrollmentEntityType, SequenceEnrollment } from '../../types/sequences';
import { calculateSequenceDuration } from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EntityInfo {
  type: EnrollmentEntityType;
  id: string;
  name: string;
  email: string;
  hasOptedOut?: boolean;
}

export interface EnrollmentModalProps {
  /** Whether modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Entity to enroll */
  entity: EntityInfo;
  /** Called after successful enrollment */
  onSuccess?: (enrollment: SequenceEnrollment) => void;
}

// ============================================
// Component
// ============================================

export function EnrollmentModal({
  isOpen,
  onClose,
  entity,
  onSuccess,
}: EnrollmentModalProps) {
  const [selectedSequenceId, setSelectedSequenceId] = useState<string>('');
  const [enrollmentComplete, setEnrollmentComplete] = useState(false);
  const [createdEnrollment, setCreatedEnrollment] = useState<SequenceEnrollment | null>(null);

  // Fetch active sequences
  const { sequences, isLoading: sequencesLoading } = useSequences({ status: 'active' });

  // Check entity enrollment status
  const {
    isEnrolled,
    activeEnrollment,
    canEnroll,
    enrollmentBlockReason,
    isLoading: statusLoading,
  } = useEntityEnrollment(entity.type, entity.id, entity.email);

  // Enrollment mutations
  const { enroll, isMutating, mutationError } = useEnrollmentMutations();

  // Get selected sequence details
  const selectedSequence = useMemo(
    () => sequences.find((s) => s.id === selectedSequenceId),
    [sequences, selectedSequenceId]
  );

  // Calculate sequence duration
  const sequenceDuration = useMemo(() => {
    if (!selectedSequence) return 0;
    return calculateSequenceDuration(selectedSequence.steps);
  }, [selectedSequence]);

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen) {
      setSelectedSequenceId('');
      setEnrollmentComplete(false);
      setCreatedEnrollment(null);
    }
  }, [isOpen]);

  // Validation warnings
  const warnings = useMemo(() => {
    const warns: string[] = [];

    if (!entity.email) {
      warns.push('This entity does not have an email address');
    }

    if (entity.hasOptedOut) {
      warns.push('This entity has opted out of emails');
    }

    if (isEnrolled && activeEnrollment) {
      warns.push(`Already enrolled in: ${activeEnrollment.sequenceName}`);
    }

    return warns;
  }, [entity, isEnrolled, activeEnrollment]);

  // Can submit
  const canSubmit = useMemo(() => {
    return (
      selectedSequenceId &&
      entity.email &&
      !entity.hasOptedOut &&
      canEnroll &&
      !isMutating
    );
  }, [selectedSequenceId, entity, canEnroll, isMutating]);

  // Handle enrollment
  const handleEnroll = async () => {
    if (!selectedSequence || !canSubmit) return;

    try {
      const enrollment = await enroll({
        sequenceId: selectedSequence.id,
        sequenceName: selectedSequence.name,
        entityType: entity.type,
        entityId: entity.id,
        entityName: entity.name,
        entityEmail: entity.email,
        totalSteps: selectedSequence.steps.length,
      });

      setCreatedEnrollment(enrollment);
      setEnrollmentComplete(true);
      onSuccess?.(enrollment);
    } catch {
      // Error handled by hook
    }
  };

  // Handle close
  const handleClose = () => {
    onClose();
  };

  if (!isOpen) return null;

  const isLoading = sequencesLoading || statusLoading;

  return (
    <div
      className="modal-overlay"
      onClick={handleClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="enrollment-modal-title"
    >
      <div
        className="modal-content enrollment-modal"
        onClick={(e) => e.stopPropagation()}
        data-testid="enrollment-modal"
      >
        {/* Header */}
        <div className="modal-header">
          <h2 id="enrollment-modal-title" className="modal-title">
            {enrollmentComplete ? 'Enrollment Successful' : 'Add to Sequence'}
          </h2>
          <button
            type="button"
            className="modal-close"
            onClick={handleClose}
            aria-label="Close modal"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div className="modal-body">
          {enrollmentComplete && createdEnrollment ? (
            <SuccessContent
              enrollment={createdEnrollment}
              sequenceName={selectedSequence?.name || ''}
              onViewEnrollment={() => {
                // Could navigate to enrollment detail
                handleClose();
              }}
              onClose={handleClose}
            />
          ) : (
            <EnrollmentForm
              entity={entity}
              sequences={sequences}
              selectedSequenceId={selectedSequenceId}
              selectedSequence={selectedSequence}
              sequenceDuration={sequenceDuration}
              warnings={warnings}
              enrollmentBlockReason={enrollmentBlockReason}
              isLoading={isLoading}
              isMutating={isMutating}
              mutationError={mutationError}
              canSubmit={!!canSubmit}
              onSequenceChange={setSelectedSequenceId}
              onEnroll={handleEnroll}
              onCancel={handleClose}
            />
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface EnrollmentFormProps {
  entity: EntityInfo;
  sequences: Sequence[];
  selectedSequenceId: string;
  selectedSequence: Sequence | undefined;
  sequenceDuration: number;
  warnings: string[];
  enrollmentBlockReason?: string;
  isLoading: boolean;
  isMutating: boolean;
  mutationError: Error | null;
  canSubmit: boolean;
  onSequenceChange: (id: string) => void;
  onEnroll: () => void;
  onCancel: () => void;
}

function EnrollmentForm({
  entity,
  sequences,
  selectedSequenceId,
  selectedSequence,
  sequenceDuration,
  warnings,
  enrollmentBlockReason,
  isLoading,
  isMutating,
  mutationError,
  canSubmit,
  onSequenceChange,
  onEnroll,
  onCancel,
}: EnrollmentFormProps) {
  return (
    <>
      {/* Entity Info */}
      <div className="enrollment-modal__entity-info">
        <div className="enrollment-modal__entity-name">{entity.name}</div>
        <div className="enrollment-modal__entity-email">
          {entity.email || <span className="text-muted">No email</span>}
        </div>
        <span className={`enrollment-modal__entity-type badge badge--${entity.type}`}>
          {entity.type}
        </span>
      </div>

      {/* Warnings */}
      {warnings.length > 0 && (
        <div className="enrollment-modal__warnings">
          {warnings.map((warning, index) => (
            <div key={index} className="enrollment-modal__warning">
              <svg
                className="enrollment-modal__warning-icon"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                <line x1="12" y1="9" x2="12" y2="13" />
                <line x1="12" y1="17" x2="12.01" y2="17" />
              </svg>
              <span>{warning}</span>
            </div>
          ))}
        </div>
      )}

      {/* Block Reason */}
      {enrollmentBlockReason && (
        <div className="enrollment-modal__block-reason">
          {enrollmentBlockReason}
        </div>
      )}

      {/* Sequence Selector */}
      <div className="enrollment-modal__field">
        <label htmlFor="sequence-select" className="enrollment-modal__label">
          Select Sequence
        </label>
        <select
          id="sequence-select"
          className="enrollment-modal__select"
          value={selectedSequenceId}
          onChange={(e) => onSequenceChange(e.target.value)}
          disabled={isLoading || isMutating}
          data-testid="sequence-select"
        >
          <option value="">Choose a sequence...</option>
          {sequences.map((sequence) => (
            <option key={sequence.id} value={sequence.id}>
              {sequence.name}
            </option>
          ))}
        </select>
        {isLoading && <span className="enrollment-modal__loading">Loading sequences...</span>}
      </div>

      {/* Sequence Preview */}
      {selectedSequence && (
        <div className="enrollment-modal__preview">
          <h4 className="enrollment-modal__preview-title">Sequence Details</h4>
          <div className="enrollment-modal__preview-stats">
            <div className="enrollment-modal__preview-stat">
              <span className="enrollment-modal__preview-stat-value">
                {selectedSequence.steps.length}
              </span>
              <span className="enrollment-modal__preview-stat-label">Steps</span>
            </div>
            <div className="enrollment-modal__preview-stat">
              <span className="enrollment-modal__preview-stat-value">
                {formatDuration(sequenceDuration)}
              </span>
              <span className="enrollment-modal__preview-stat-label">Duration</span>
            </div>
            <div className="enrollment-modal__preview-stat">
              <span className="enrollment-modal__preview-stat-value">
                {selectedSequence.stats.activeEnrollments}
              </span>
              <span className="enrollment-modal__preview-stat-label">Active</span>
            </div>
          </div>
          {selectedSequence.description && (
            <p className="enrollment-modal__preview-description">
              {selectedSequence.description}
            </p>
          )}
        </div>
      )}

      {/* Error Message */}
      {mutationError && (
        <div className="enrollment-modal__error" role="alert">
          {mutationError.message}
        </div>
      )}

      {/* Actions */}
      <div className="modal-footer">
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
          className="btn btn-primary"
          onClick={onEnroll}
          disabled={!canSubmit}
          data-testid="enroll-button"
        >
          {isMutating ? 'Enrolling...' : 'Enroll'}
        </button>
      </div>
    </>
  );
}

interface SuccessContentProps {
  enrollment: SequenceEnrollment;
  sequenceName: string;
  onViewEnrollment: () => void;
  onClose: () => void;
}

function SuccessContent({
  enrollment,
  sequenceName,
  onViewEnrollment,
  onClose,
}: SuccessContentProps) {
  return (
    <div className="enrollment-modal__success" data-testid="enrollment-success">
      <div className="enrollment-modal__success-icon">
        <svg
          width="48"
          height="48"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
          <polyline points="22 4 12 14.01 9 11.01" />
        </svg>
      </div>
      <h3 className="enrollment-modal__success-title">Successfully Enrolled</h3>
      <p className="enrollment-modal__success-message">
        <strong>{enrollment.entityName}</strong> has been enrolled in{' '}
        <strong>{sequenceName}</strong>.
      </p>
      <p className="enrollment-modal__success-detail">
        The first step will be executed according to the sequence schedule.
      </p>
      <div className="modal-footer">
        <button
          type="button"
          className="btn btn-secondary"
          onClick={onViewEnrollment}
        >
          View Enrollment
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={onClose}
        >
          Done
        </button>
      </div>
    </div>
  );
}

// ============================================
// Helpers
// ============================================

function formatDuration(days: number): string {
  if (days < 1) {
    const hours = Math.round(days * 24);
    return `${hours}h`;
  }
  if (days === 1) {
    return '1 day';
  }
  return `${Math.round(days)} days`;
}

export default EnrollmentModal;
