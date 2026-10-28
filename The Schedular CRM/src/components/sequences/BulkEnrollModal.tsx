/**
 * BulkEnrollModal Component
 * Modal for enrolling multiple entities in a sequence
 *
 * Phase 3 Implementation
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useSequences } from '../../hooks/useSequences';
import { useEnrollmentMutations } from '../../hooks/useSequenceEnrollments';
import { getRateLimitService } from '../../services/RateLimitService';
import { useAuth } from '../../context/AuthContext';
import type { Sequence, EnrollmentEntityType } from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface BulkEntity {
  type: EnrollmentEntityType;
  id: string;
  name: string;
  email: string;
  hasOptedOut?: boolean;
  isAlreadyEnrolled?: boolean;
  enrolledSequenceName?: string;
}

export interface BulkEnrollModalProps {
  /** Whether modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Entities to potentially enroll */
  entities: BulkEntity[];
  /** Called after enrollment completes */
  onComplete?: (results: BulkEnrollResult) => void;
}

export interface BulkEnrollResult {
  enrolled: string[];
  skipped: Array<{ entityId: string; reason: string }>;
  errors: Array<{ entityId: string; error: string }>;
}

interface ValidationResult {
  valid: BulkEntity[];
  invalid: Array<{ entity: BulkEntity; reason: string }>;
}

// ============================================
// Component
// ============================================

export function BulkEnrollModal({
  isOpen,
  onClose,
  entities,
  onComplete,
}: BulkEnrollModalProps) {
  const { crmUser, businessId } = useAuth();
  const [selectedSequenceId, setSelectedSequenceId] = useState<string>('');
  const [skipInvalid, setSkipInvalid] = useState(true);
  const [isEnrolling, setIsEnrolling] = useState(false);
  const [progress, setProgress] = useState(0);
  const [results, setResults] = useState<BulkEnrollResult | null>(null);
  const [rateLimitWarning, setRateLimitWarning] = useState<string | null>(null);

  // Fetch active sequences
  const { sequences, isLoading: sequencesLoading } = useSequences({ status: 'active' });

  // Enrollment mutations
  const { bulkEnroll, mutationError } = useEnrollmentMutations();

  // Get selected sequence
  const selectedSequence = useMemo(
    () => sequences.find((s) => s.id === selectedSequenceId),
    [sequences, selectedSequenceId]
  );

  // Validate entities
  const validation = useMemo((): ValidationResult => {
    const valid: BulkEntity[] = [];
    const invalid: Array<{ entity: BulkEntity; reason: string }> = [];

    entities.forEach((entity) => {
      if (!entity.email) {
        invalid.push({ entity, reason: 'No email address' });
      } else if (entity.hasOptedOut) {
        invalid.push({ entity, reason: 'Opted out of emails' });
      } else if (entity.isAlreadyEnrolled) {
        invalid.push({
          entity,
          reason: `Already in: ${entity.enrolledSequenceName || 'another sequence'}`,
        });
      } else {
        valid.push(entity);
      }
    });

    return { valid, invalid };
  }, [entities]);

  // Calculate enrollable count
  const enrollableCount = skipInvalid
    ? validation.valid.length
    : entities.filter((e) => e.email && !e.hasOptedOut && !e.isAlreadyEnrolled).length;

  // Check rate limits
  const checkRateLimits = useCallback(async () => {
    if (!businessId || !crmUser) return;

    const rateLimitService = getRateLimitService();
    const usage = await rateLimitService.getUsage('bulk_operation', crmUser.id, businessId);

    if (usage.remaining < 1) {
      setRateLimitWarning(
        `Bulk operation limit reached. Try again after ${usage.resetAt.toLocaleTimeString()}.`
      );
    } else if (usage.remaining <= 3) {
      setRateLimitWarning(
        `${usage.remaining} bulk operations remaining. Limit resets at ${usage.resetAt.toLocaleTimeString()}.`
      );
    } else {
      setRateLimitWarning(null);
    }
  }, [businessId, crmUser]);

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen) {
      setSelectedSequenceId('');
      setSkipInvalid(true);
      setIsEnrolling(false);
      setProgress(0);
      setResults(null);
      checkRateLimits();
    }
  }, [isOpen, checkRateLimits]);

  // Handle bulk enrollment
  const handleEnroll = async () => {
    if (!selectedSequence || enrollableCount === 0) return;

    setIsEnrolling(true);
    setProgress(0);

    try {
      const entitiesToEnroll = skipInvalid ? validation.valid : entities.filter(
        (e) => e.email && !e.hasOptedOut && !e.isAlreadyEnrolled
      );

      // Simulate progress for better UX
      const progressInterval = setInterval(() => {
        setProgress((prev) => Math.min(prev + 10, 90));
      }, 200);

      const result = await bulkEnroll({
        sequenceId: selectedSequence.id,
        sequenceName: selectedSequence.name,
        totalSteps: selectedSequence.steps.length,
        entities: entitiesToEnroll.map((e) => ({
          type: e.type,
          id: e.id,
          name: e.name,
          email: e.email,
        })),
      });

      clearInterval(progressInterval);
      setProgress(100);

      const enrollResult: BulkEnrollResult = {
        enrolled: result.enrolled,
        skipped: result.skipped,
        errors: [],
      };

      setResults(enrollResult);
      onComplete?.(enrollResult);
    } catch (err) {
      setResults({
        enrolled: [],
        skipped: [],
        errors: [{ entityId: 'all', error: err instanceof Error ? err.message : 'Unknown error' }],
      });
    } finally {
      setIsEnrolling(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className="modal-overlay"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="bulk-enroll-modal-title"
    >
      <div
        className="modal-content bulk-enroll-modal"
        onClick={(e) => e.stopPropagation()}
        data-testid="bulk-enroll-modal"
      >
        {/* Header */}
        <div className="modal-header">
          <h2 id="bulk-enroll-modal-title" className="modal-title">
            {results ? 'Enrollment Results' : 'Bulk Enroll in Sequence'}
          </h2>
          <button
            type="button"
            className="modal-close"
            onClick={onClose}
            aria-label="Close modal"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div className="modal-body">
          {results ? (
            <ResultsContent results={results} onClose={onClose} />
          ) : isEnrolling ? (
            <ProgressContent progress={progress} count={enrollableCount} />
          ) : (
            <EnrollmentFormContent
              entities={entities}
              validation={validation}
              sequences={sequences}
              selectedSequenceId={selectedSequenceId}
              selectedSequence={selectedSequence}
              skipInvalid={skipInvalid}
              enrollableCount={enrollableCount}
              rateLimitWarning={rateLimitWarning}
              isLoading={sequencesLoading}
              mutationError={mutationError}
              onSequenceChange={setSelectedSequenceId}
              onSkipInvalidChange={setSkipInvalid}
              onEnroll={handleEnroll}
              onCancel={onClose}
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

interface EnrollmentFormContentProps {
  entities: BulkEntity[];
  validation: ValidationResult;
  sequences: Sequence[];
  selectedSequenceId: string;
  selectedSequence: Sequence | undefined;
  skipInvalid: boolean;
  enrollableCount: number;
  rateLimitWarning: string | null;
  isLoading: boolean;
  mutationError: Error | null;
  onSequenceChange: (id: string) => void;
  onSkipInvalidChange: (skip: boolean) => void;
  onEnroll: () => void;
  onCancel: () => void;
}

function EnrollmentFormContent({
  entities,
  validation,
  sequences,
  selectedSequenceId,
  selectedSequence,
  skipInvalid,
  enrollableCount,
  rateLimitWarning,
  isLoading,
  mutationError,
  onSequenceChange,
  onSkipInvalidChange,
  onEnroll,
  onCancel,
}: EnrollmentFormContentProps) {
  return (
    <>
      {/* Summary */}
      <div className="bulk-enroll-modal__summary">
        <div className="bulk-enroll-modal__summary-item">
          <span className="bulk-enroll-modal__summary-value">{entities.length}</span>
          <span className="bulk-enroll-modal__summary-label">Selected</span>
        </div>
        <div className="bulk-enroll-modal__summary-item bulk-enroll-modal__summary-item--valid">
          <span className="bulk-enroll-modal__summary-value">{validation.valid.length}</span>
          <span className="bulk-enroll-modal__summary-label">Valid</span>
        </div>
        <div className="bulk-enroll-modal__summary-item bulk-enroll-modal__summary-item--invalid">
          <span className="bulk-enroll-modal__summary-value">{validation.invalid.length}</span>
          <span className="bulk-enroll-modal__summary-label">Issues</span>
        </div>
      </div>

      {/* Invalid Entities List */}
      {validation.invalid.length > 0 && (
        <div className="bulk-enroll-modal__issues">
          <h4 className="bulk-enroll-modal__issues-title">
            Entities with Issues ({validation.invalid.length})
          </h4>
          <div className="bulk-enroll-modal__issues-list">
            {validation.invalid.slice(0, 5).map(({ entity, reason }) => (
              <div key={entity.id} className="bulk-enroll-modal__issue">
                <span className="bulk-enroll-modal__issue-name">{entity.name}</span>
                <span className="bulk-enroll-modal__issue-reason">{reason}</span>
              </div>
            ))}
            {validation.invalid.length > 5 && (
              <div className="bulk-enroll-modal__issue-more">
                +{validation.invalid.length - 5} more
              </div>
            )}
          </div>
        </div>
      )}

      {/* Skip Invalid Checkbox */}
      {validation.invalid.length > 0 && (
        <label className="bulk-enroll-modal__checkbox">
          <input
            type="checkbox"
            checked={skipInvalid}
            onChange={(e) => onSkipInvalidChange(e.target.checked)}
          />
          <span>Skip entities with issues (enroll {validation.valid.length} only)</span>
        </label>
      )}

      {/* Rate Limit Warning */}
      {rateLimitWarning && (
        <div className="bulk-enroll-modal__rate-warning" role="alert">
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span>{rateLimitWarning}</span>
        </div>
      )}

      {/* Sequence Selector */}
      <div className="bulk-enroll-modal__field">
        <label htmlFor="bulk-sequence-select" className="bulk-enroll-modal__label">
          Select Sequence
        </label>
        <select
          id="bulk-sequence-select"
          className="bulk-enroll-modal__select"
          value={selectedSequenceId}
          onChange={(e) => onSequenceChange(e.target.value)}
          disabled={isLoading}
          data-testid="bulk-sequence-select"
        >
          <option value="">Choose a sequence...</option>
          {sequences.map((sequence) => (
            <option key={sequence.id} value={sequence.id}>
              {sequence.name} ({sequence.steps.length} steps)
            </option>
          ))}
        </select>
      </div>

      {/* Sequence Preview */}
      {selectedSequence && (
        <div className="bulk-enroll-modal__preview">
          <strong>{selectedSequence.name}</strong>
          <p>{selectedSequence.description || 'No description'}</p>
          <div className="bulk-enroll-modal__preview-stats">
            <span>{selectedSequence.steps.length} steps</span>
            <span>{selectedSequence.stats.activeEnrollments} active enrollments</span>
          </div>
        </div>
      )}

      {/* Estimated Enrollment */}
      <div className="bulk-enroll-modal__estimate">
        <strong>{enrollableCount}</strong> entities will be enrolled
      </div>

      {/* Error Message */}
      {mutationError && (
        <div className="bulk-enroll-modal__error" role="alert">
          {mutationError.message}
        </div>
      )}

      {/* Actions */}
      <div className="modal-footer">
        <button type="button" className="btn btn-secondary" onClick={onCancel}>
          Cancel
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={onEnroll}
          disabled={!selectedSequenceId || enrollableCount === 0 || !!rateLimitWarning?.includes('reached')}
          data-testid="bulk-enroll-button"
        >
          Enroll {enrollableCount} Entities
        </button>
      </div>
    </>
  );
}

interface ProgressContentProps {
  progress: number;
  count: number;
}

function ProgressContent({ progress, count }: ProgressContentProps) {
  return (
    <div className="bulk-enroll-modal__progress" data-testid="bulk-enroll-progress">
      <div className="bulk-enroll-modal__progress-icon">
        <svg
          className="bulk-enroll-modal__spinner"
          width="48"
          height="48"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </div>
      <h3 className="bulk-enroll-modal__progress-title">Enrolling {count} entities...</h3>
      <div className="bulk-enroll-modal__progress-bar">
        <div
          className="bulk-enroll-modal__progress-fill"
          style={{ width: `${progress}%` }}
        />
      </div>
      <p className="bulk-enroll-modal__progress-text">{progress}% complete</p>
    </div>
  );
}

interface ResultsContentProps {
  results: BulkEnrollResult;
  onClose: () => void;
}

function ResultsContent({ results, onClose }: ResultsContentProps) {
  return (
    <div className="bulk-enroll-modal__results" data-testid="bulk-enroll-results">
      <div className="bulk-enroll-modal__results-summary">
        <div className="bulk-enroll-modal__results-item bulk-enroll-modal__results-item--success">
          <span className="bulk-enroll-modal__results-value">{results.enrolled.length}</span>
          <span className="bulk-enroll-modal__results-label">Enrolled</span>
        </div>
        <div className="bulk-enroll-modal__results-item bulk-enroll-modal__results-item--skipped">
          <span className="bulk-enroll-modal__results-value">{results.skipped.length}</span>
          <span className="bulk-enroll-modal__results-label">Skipped</span>
        </div>
        <div className="bulk-enroll-modal__results-item bulk-enroll-modal__results-item--error">
          <span className="bulk-enroll-modal__results-value">{results.errors.length}</span>
          <span className="bulk-enroll-modal__results-label">Errors</span>
        </div>
      </div>

      {/* Skipped Details */}
      {results.skipped.length > 0 && (
        <div className="bulk-enroll-modal__results-details">
          <h4>Skipped ({results.skipped.length})</h4>
          <ul>
            {results.skipped.slice(0, 10).map((item, index) => (
              <li key={index}>
                <code>{item.entityId.slice(0, 8)}...</code>: {item.reason}
              </li>
            ))}
            {results.skipped.length > 10 && (
              <li className="text-muted">+{results.skipped.length - 10} more</li>
            )}
          </ul>
        </div>
      )}

      {/* Error Details */}
      {results.errors.length > 0 && (
        <div className="bulk-enroll-modal__results-details bulk-enroll-modal__results-details--error">
          <h4>Errors ({results.errors.length})</h4>
          <ul>
            {results.errors.map((item, index) => (
              <li key={index}>{item.error}</li>
            ))}
          </ul>
        </div>
      )}

      <div className="modal-footer">
        <button type="button" className="btn btn-primary" onClick={onClose}>
          Done
        </button>
      </div>
    </div>
  );
}

export default BulkEnrollModal;
