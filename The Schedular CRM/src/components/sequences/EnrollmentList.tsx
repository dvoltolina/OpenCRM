/**
 * EnrollmentList Component
 * Table of enrollments for a sequence with filtering and bulk actions
 *
 * Phase 3 Implementation
 */

import { useState, useMemo, useCallback } from 'react';
import { useSequenceEnrollments, useEnrollmentMutations } from '../../hooks/useSequenceEnrollments';
import type {
  SequenceEnrollment,
  EnrollmentStatus,
  EnrollmentEntityType,
  EnrollmentFilters,
} from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EnrollmentListProps {
  /** Sequence ID to show enrollments for */
  sequenceId: string;
  /** Called when an enrollment is clicked */
  onEnrollmentClick?: (enrollment: SequenceEnrollment) => void;
  /** Called when entity link is clicked */
  onEntityClick?: (entityType: EnrollmentEntityType, entityId: string) => void;
}

// ============================================
// Component
// ============================================

export function EnrollmentList({
  sequenceId,
  onEnrollmentClick,
  onEntityClick,
}: EnrollmentListProps) {
  // Filter state
  const [statusFilter, setStatusFilter] = useState<EnrollmentStatus | ''>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  // Pagination
  const [page, setPage] = useState(1);
  const pageSize = 20;

  // Build filters
  const filters: EnrollmentFilters = useMemo(
    () => ({
      status: statusFilter || undefined,
      search: searchQuery || undefined,
    }),
    [statusFilter, searchQuery]
  );

  // Fetch enrollments
  const { enrollments, isLoading, error, refresh, countByStatus, totalCount } =
    useSequenceEnrollments(sequenceId, filters);

  // Mutations
  const { pause, resume, exit, isMutating } = useEnrollmentMutations();

  // Paginated data
  const paginatedEnrollments = useMemo(() => {
    const start = (page - 1) * pageSize;
    return enrollments.slice(start, start + pageSize);
  }, [enrollments, page, pageSize]);

  const totalPages = Math.ceil(enrollments.length / pageSize);

  // Selection handlers
  const handleSelectAll = useCallback(() => {
    if (selectedIds.size === paginatedEnrollments.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(paginatedEnrollments.map((e) => e.id)));
    }
  }, [paginatedEnrollments, selectedIds]);

  const handleSelectOne = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);

  // Bulk actions
  const handleBulkPause = useCallback(async () => {
    for (const id of selectedIds) {
      const enrollment = enrollments.find((e) => e.id === id);
      if (enrollment?.status === 'active') {
        await pause(id, 'bulk_pause');
      }
    }
    setSelectedIds(new Set());
    refresh();
  }, [selectedIds, enrollments, pause, refresh]);

  const handleBulkResume = useCallback(async () => {
    for (const id of selectedIds) {
      const enrollment = enrollments.find((e) => e.id === id);
      if (enrollment?.status === 'paused') {
        await resume(id);
      }
    }
    setSelectedIds(new Set());
    refresh();
  }, [selectedIds, enrollments, resume, refresh]);

  const handleBulkRemove = useCallback(async () => {
    if (!window.confirm(`Remove ${selectedIds.size} enrollments from sequence?`)) {
      return;
    }
    for (const id of selectedIds) {
      await exit(id, 'manual');
    }
    setSelectedIds(new Set());
    refresh();
  }, [selectedIds, exit, refresh]);

  // Single actions
  const handlePause = useCallback(
    async (enrollment: SequenceEnrollment) => {
      await pause(enrollment.id);
      refresh();
    },
    [pause, refresh]
  );

  const handleResume = useCallback(
    async (enrollment: SequenceEnrollment) => {
      await resume(enrollment.id);
      refresh();
    },
    [resume, refresh]
  );

  const handleRemove = useCallback(
    async (enrollment: SequenceEnrollment) => {
      if (!window.confirm(`Remove ${enrollment.entityName} from sequence?`)) {
        return;
      }
      await exit(enrollment.id, 'manual');
      refresh();
    },
    [exit, refresh]
  );

  // Clear filters
  const handleClearFilters = useCallback(() => {
    setStatusFilter('');
    setSearchQuery('');
    setPage(1);
  }, []);

  const hasFilters = statusFilter || searchQuery;
  const hasSelection = selectedIds.size > 0;

  return (
    <div className="enrollment-list" data-testid="enrollment-list">
      {/* Filters */}
      <div className="enrollment-list__filters">
        <div className="enrollment-list__filter-group">
          <label htmlFor="status-filter" className="enrollment-list__filter-label">
            Status
          </label>
          <select
            id="status-filter"
            className="enrollment-list__filter-select"
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value as EnrollmentStatus | '');
              setPage(1);
            }}
            data-testid="enrollment-status-filter"
          >
            <option value="">All ({totalCount})</option>
            <option value="active">Active ({countByStatus.active})</option>
            <option value="paused">Paused ({countByStatus.paused})</option>
            <option value="completed">Completed ({countByStatus.completed})</option>
            <option value="exited">Exited ({countByStatus.exited})</option>
            <option value="bounced">Bounced ({countByStatus.bounced})</option>
            <option value="unsubscribed">Unsubscribed ({countByStatus.unsubscribed})</option>
          </select>
        </div>

        <div className="enrollment-list__filter-group enrollment-list__filter-group--search">
          <label htmlFor="search-filter" className="enrollment-list__filter-label">
            Search
          </label>
          <input
            id="search-filter"
            type="text"
            className="enrollment-list__filter-input"
            placeholder="Search by name or email..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setPage(1);
            }}
            data-testid="enrollment-search-filter"
          />
        </div>

        {hasFilters && (
          <button
            type="button"
            className="enrollment-list__clear-filters"
            onClick={handleClearFilters}
          >
            Clear Filters
          </button>
        )}
      </div>

      {/* Bulk Actions */}
      {hasSelection && (
        <div className="enrollment-list__bulk-actions" data-testid="bulk-actions">
          <span className="enrollment-list__selection-count">
            {selectedIds.size} selected
          </span>
          <button
            type="button"
            className="btn btn-sm btn-secondary"
            onClick={handleBulkPause}
            disabled={isMutating}
          >
            Pause Selected
          </button>
          <button
            type="button"
            className="btn btn-sm btn-secondary"
            onClick={handleBulkResume}
            disabled={isMutating}
          >
            Resume Selected
          </button>
          <button
            type="button"
            className="btn btn-sm btn-danger"
            onClick={handleBulkRemove}
            disabled={isMutating}
          >
            Remove Selected
          </button>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="enrollment-list__error" role="alert">
          {error.message}
          <button type="button" onClick={refresh}>
            Retry
          </button>
        </div>
      )}

      {/* Loading */}
      {isLoading && (
        <div className="enrollment-list__loading">
          <div className="enrollment-list__spinner" />
          Loading enrollments...
        </div>
      )}

      {/* Table */}
      {!isLoading && !error && (
        <>
          <div className="enrollment-list__table-wrapper">
            <table className="enrollment-list__table" data-testid="enrollment-table">
              <thead>
                <tr>
                  <th className="enrollment-list__th enrollment-list__th--checkbox">
                    <input
                      type="checkbox"
                      checked={
                        paginatedEnrollments.length > 0 &&
                        selectedIds.size === paginatedEnrollments.length
                      }
                      onChange={handleSelectAll}
                      aria-label="Select all"
                    />
                  </th>
                  <th className="enrollment-list__th">Contact</th>
                  <th className="enrollment-list__th">Email</th>
                  <th className="enrollment-list__th">Status</th>
                  <th className="enrollment-list__th">Progress</th>
                  <th className="enrollment-list__th">Next Step</th>
                  <th className="enrollment-list__th">Enrolled</th>
                  <th className="enrollment-list__th">Actions</th>
                </tr>
              </thead>
              <tbody>
                {paginatedEnrollments.map((enrollment) => (
                  <EnrollmentRow
                    key={enrollment.id}
                    enrollment={enrollment}
                    isSelected={selectedIds.has(enrollment.id)}
                    isMutating={isMutating}
                    onSelect={() => handleSelectOne(enrollment.id)}
                    onClick={() => onEnrollmentClick?.(enrollment)}
                    onEntityClick={onEntityClick}
                    onPause={handlePause}
                    onResume={handleResume}
                    onRemove={handleRemove}
                  />
                ))}
              </tbody>
            </table>
          </div>

          {/* Empty State */}
          {paginatedEnrollments.length === 0 && (
            <div className="enrollment-list__empty" data-testid="enrollment-empty">
              {hasFilters
                ? 'No enrollments match your filters'
                : 'No enrollments yet'}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="enrollment-list__pagination">
              <button
                type="button"
                className="enrollment-list__page-btn"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
              >
                Previous
              </button>
              <span className="enrollment-list__page-info">
                Page {page} of {totalPages}
              </span>
              <button
                type="button"
                className="enrollment-list__page-btn"
                disabled={page === totalPages}
                onClick={() => setPage(page + 1)}
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface EnrollmentRowProps {
  enrollment: SequenceEnrollment;
  isSelected: boolean;
  isMutating: boolean;
  onSelect: () => void;
  onClick: () => void;
  onEntityClick?: (entityType: EnrollmentEntityType, entityId: string) => void;
  onPause: (enrollment: SequenceEnrollment) => void;
  onResume: (enrollment: SequenceEnrollment) => void;
  onRemove: (enrollment: SequenceEnrollment) => void;
}

function EnrollmentRow({
  enrollment,
  isSelected,
  isMutating,
  onSelect,
  onClick,
  onEntityClick,
  onPause,
  onResume,
  onRemove,
}: EnrollmentRowProps) {
  const progressPercent =
    enrollment.totalSteps > 0
      ? Math.round((enrollment.stepsCompleted / enrollment.totalSteps) * 100)
      : 0;

  const nextStepDisplay = enrollment.nextStepScheduledAt
    ? formatRelativeDate(enrollment.nextStepScheduledAt)
    : '—';

  const enrolledDisplay = formatRelativeDate(enrollment.createdAt);

  return (
    <tr className="enrollment-list__row" data-testid={`enrollment-row-${enrollment.id}`}>
      <td className="enrollment-list__td enrollment-list__td--checkbox">
        <input
          type="checkbox"
          checked={isSelected}
          onChange={onSelect}
          aria-label={`Select ${enrollment.entityName}`}
        />
      </td>
      <td className="enrollment-list__td">
        <button
          type="button"
          className="enrollment-list__entity-link"
          onClick={() => onEntityClick?.(enrollment.entityType, enrollment.entityId)}
        >
          {enrollment.entityName}
        </button>
        <span className={`enrollment-list__entity-type badge badge--${enrollment.entityType}`}>
          {enrollment.entityType}
        </span>
      </td>
      <td className="enrollment-list__td enrollment-list__td--email">
        {enrollment.entityEmail}
      </td>
      <td className="enrollment-list__td">
        <StatusBadge status={enrollment.status} exitReason={enrollment.exitReason} />
      </td>
      <td className="enrollment-list__td">
        <div className="enrollment-list__progress">
          <div className="enrollment-list__progress-bar">
            <div
              className="enrollment-list__progress-fill"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
          <span className="enrollment-list__progress-text">
            {enrollment.stepsCompleted}/{enrollment.totalSteps}
          </span>
        </div>
      </td>
      <td className="enrollment-list__td">{nextStepDisplay}</td>
      <td className="enrollment-list__td">{enrolledDisplay}</td>
      <td className="enrollment-list__td enrollment-list__td--actions">
        <div className="enrollment-list__actions">
          <button
            type="button"
            className="btn btn-ghost btn-sm"
            onClick={onClick}
            title="View details"
          >
            View
          </button>
          {enrollment.status === 'active' && (
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={() => onPause(enrollment)}
              disabled={isMutating}
              title="Pause enrollment"
            >
              Pause
            </button>
          )}
          {enrollment.status === 'paused' && (
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={() => onResume(enrollment)}
              disabled={isMutating}
              title="Resume enrollment"
            >
              Resume
            </button>
          )}
          {(enrollment.status === 'active' || enrollment.status === 'paused') && (
            <button
              type="button"
              className="btn btn-ghost btn-sm btn-danger"
              onClick={() => onRemove(enrollment)}
              disabled={isMutating}
              title="Remove from sequence"
            >
              Remove
            </button>
          )}
        </div>
      </td>
    </tr>
  );
}

interface StatusBadgeProps {
  status: EnrollmentStatus;
  exitReason?: string;
}

function StatusBadge({ status, exitReason }: StatusBadgeProps) {
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
    <span
      className={`enrollment-status-badge enrollment-status-badge--${variants[status]}`}
      title={exitReason ? `Reason: ${exitReason}` : undefined}
    >
      {labels[status]}
    </span>
  );
}

// ============================================
// Helpers
// ============================================

function formatRelativeDate(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    return 'Today';
  } else if (diffDays === 1) {
    return 'Yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
  } else {
    return date.toLocaleDateString();
  }
}

export default EnrollmentList;
