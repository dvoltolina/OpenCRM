/**
 * SequenceList Component
 * Table/card display of sequences with actions
 */

import { useState, useCallback } from 'react';
import type { Sequence } from '../../types/sequences';
import type { ShareableAccessSummary } from '../../lib/security-context';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceListProps {
  sequences: Sequence[];
  onEdit: (sequence: Sequence) => void;
  onDuplicate: (sequence: Sequence) => void;
  onArchive: (sequence: Sequence) => void;
  onToggleStatus: (sequence: Sequence) => void;
  getAccessSummary: (sequence: Sequence | null | undefined) => ShareableAccessSummary | null;
  isLoading?: boolean;
}

interface SequenceRowProps {
  sequence: Sequence;
  onEdit: (sequence: Sequence) => void;
  onDuplicate: (sequence: Sequence) => void;
  onArchive: (sequence: Sequence) => void;
  onToggleStatus: (sequence: Sequence) => void;
  accessSummary: ShareableAccessSummary | null;
  isLoading?: boolean;
}

// ============================================
// Helpers
// ============================================

function getStatusBadgeClass(status: Sequence['status']): string {
  switch (status) {
    case 'active':
      return 'sequence-list__badge--active';
    case 'paused':
      return 'sequence-list__badge--paused';
    case 'archived':
      return 'sequence-list__badge--archived';
    case 'draft':
    default:
      return 'sequence-list__badge--draft';
  }
}

function formatDate(date: Date | undefined): string {
  if (!date) return '-';
  const d = date instanceof Date ? date : new Date(date);
  return d.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ============================================
// SequenceRow Sub-component
// ============================================

function SequenceRow({
  sequence,
  onEdit,
  onDuplicate,
  onArchive,
  onToggleStatus,
  accessSummary,
  isLoading,
}: SequenceRowProps) {
  const [showActions, setShowActions] = useState(false);
  const [confirmArchive, setConfirmArchive] = useState(false);

  const canEdit = accessSummary?.canEdit ?? false;
  const canDelete = accessSummary?.canDelete ?? false;

  const handleArchiveClick = useCallback(() => {
    if (confirmArchive) {
      onArchive(sequence);
      setConfirmArchive(false);
      setShowActions(false);
    } else {
      setConfirmArchive(true);
    }
  }, [confirmArchive, onArchive, sequence]);

  const handleToggleActions = useCallback(() => {
    setShowActions((prev) => !prev);
    setConfirmArchive(false);
  }, []);

  const handleEdit = useCallback(() => {
    onEdit(sequence);
    setShowActions(false);
  }, [onEdit, sequence]);

  const handleDuplicate = useCallback(() => {
    onDuplicate(sequence);
    setShowActions(false);
  }, [onDuplicate, sequence]);

  const handleToggleStatus = useCallback(() => {
    onToggleStatus(sequence);
    setShowActions(false);
  }, [onToggleStatus, sequence]);

  const statusAction = sequence.status === 'active' ? 'Pause' : 'Activate';

  return (
    <tr className="sequence-list__row" data-testid={`sequence-row-${sequence.id}`}>
      <td className="sequence-list__cell sequence-list__cell--name">
        <button
          type="button"
          className="sequence-list__name-btn"
          onClick={handleEdit}
        >
          {sequence.name}
        </button>
        {sequence.description && (
          <span className="sequence-list__description">{sequence.description}</span>
        )}
      </td>
      <td className="sequence-list__cell sequence-list__cell--status">
        <span className={`sequence-list__badge ${getStatusBadgeClass(sequence.status)}`}>
          {sequence.status}
        </span>
      </td>
      <td className="sequence-list__cell sequence-list__cell--steps">
        {sequence.steps.length} steps
      </td>
      <td className="sequence-list__cell sequence-list__cell--enrollments">
        <div className="sequence-list__enrollment-stats">
          <span title="Active enrollments">{sequence.stats.activeEnrollments} active</span>
          <span className="sequence-list__stat-divider">/</span>
          <span title="Completed">{sequence.stats.completedCount} done</span>
        </div>
      </td>
      <td className="sequence-list__cell sequence-list__cell--owner">
        {sequence.ownerName}
      </td>
      <td className="sequence-list__cell sequence-list__cell--date">
        {formatDate(sequence.updatedAt || sequence.createdAt)}
      </td>
      <td className="sequence-list__cell sequence-list__cell--actions">
        <div className="sequence-list__actions-wrapper">
          <button
            type="button"
            className="sequence-list__actions-btn"
            onClick={handleToggleActions}
            aria-label="Sequence actions"
            aria-expanded={showActions}
            disabled={isLoading}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="12" cy="5" r="2" />
              <circle cx="12" cy="12" r="2" />
              <circle cx="12" cy="19" r="2" />
            </svg>
          </button>
          {showActions && (
            <div className="sequence-list__dropdown">
              <button
                type="button"
                className="sequence-list__dropdown-item"
                onClick={handleEdit}
              >
                Edit
              </button>
              <button
                type="button"
                className="sequence-list__dropdown-item"
                onClick={handleDuplicate}
              >
                Duplicate
              </button>
              {sequence.status !== 'archived' && canEdit && (
                <button
                  type="button"
                  className="sequence-list__dropdown-item"
                  onClick={handleToggleStatus}
                  disabled={sequence.status === 'draft' && sequence.steps.length === 0}
                >
                  {statusAction}
                </button>
              )}
              {canDelete && sequence.status !== 'archived' && (
                <>
                  <div className="sequence-list__dropdown-divider" />
                  <button
                    type="button"
                    className={`sequence-list__dropdown-item sequence-list__dropdown-item--danger ${confirmArchive ? 'sequence-list__dropdown-item--confirm' : ''}`}
                    onClick={handleArchiveClick}
                  >
                    {confirmArchive ? 'Click again to confirm' : 'Archive'}
                  </button>
                </>
              )}
            </div>
          )}
        </div>
      </td>
    </tr>
  );
}

// ============================================
// Main Component
// ============================================

export function SequenceList({
  sequences,
  onEdit,
  onDuplicate,
  onArchive,
  onToggleStatus,
  getAccessSummary,
  isLoading,
}: SequenceListProps) {
  if (sequences.length === 0) {
    return null;
  }

  return (
    <div className="sequence-list" data-testid="sequence-list">
      <table className="sequence-list__table">
        <thead>
          <tr>
            <th className="sequence-list__header">Name</th>
            <th className="sequence-list__header">Status</th>
            <th className="sequence-list__header">Steps</th>
            <th className="sequence-list__header">Enrollments</th>
            <th className="sequence-list__header">Owner</th>
            <th className="sequence-list__header">Updated</th>
            <th className="sequence-list__header sequence-list__header--actions">
              <span className="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {sequences.map((sequence) => (
            <SequenceRow
              key={sequence.id}
              sequence={sequence}
              onEdit={onEdit}
              onDuplicate={onDuplicate}
              onArchive={onArchive}
              onToggleStatus={onToggleStatus}
              accessSummary={getAccessSummary(sequence)}
              isLoading={isLoading}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default SequenceList;
