/**
 * LeadActions Component
 * Action bar with buttons for lead operations
 *
 * Agent CRM-24 Implementation
 * Phase 3: Added sequence enrollment support
 */

import type { Lead, LeadStatus } from '../../types/models';
import { getFeatureFlags } from '../../config/features';
import './leads.css';

// ============================================
// Types
// ============================================

export interface LeadActionsProps {
  /** The lead to show actions for */
  lead: Lead;
  /** Called when Edit is clicked */
  onEdit?: (lead: Lead) => void;
  /** Whether edit is permitted (defaults to true when onEdit provided) */
  canEdit?: boolean;
  /** Called when Convert is clicked */
  onConvert?: (lead: Lead) => void;
  /** Whether convert is permitted (defaults to true when onConvert provided) */
  canConvertOverride?: boolean;
  /** Called when View is clicked */
  onView?: (lead: Lead) => void;
  /** Called when Delete is clicked */
  onDelete?: (lead: Lead) => void;
  /** Whether delete is permitted (defaults to true when onDelete provided) */
  canDelete?: boolean;
  /** Called when Add to Sequence is clicked */
  onAddToSequence?: (lead: Lead) => void;
  /** Whether the lead is currently enrolled in a sequence */
  isEnrolledInSequence?: boolean;
  /** Name of the current sequence (if enrolled) */
  currentSequenceName?: string;
  /** Called when Assign Rep is clicked - passes lead and opens assignment modal */
  onAssignRep?: (lead: Lead) => void;
  /** Whether user can assign reps (typically managers only) */
  canAssignRep?: boolean;
  /** Called when status is changed */
  onStatusChange?: (lead: Lead, newStatus: LeadStatus) => void;
  /** Whether status change is permitted */
  canChangeStatus?: boolean;
  /** Whether actions are disabled (e.g., during mutation) */
  disabled?: boolean;
  /** Size variant */
  size?: 'sm' | 'md';
  /** Layout variant */
  variant?: 'inline' | 'dropdown';
  /** Optional read-only hint for tooltips when actions are disabled */
  readOnlyReason?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Check if a lead can be converted
 */
function canConvertLead(lead: Lead): { canConvert: boolean; reason?: string } {
  // Already converted
  if (lead.status === 'converted') {
    return { canConvert: false, reason: 'Lead has already been converted' };
  }

  // No email - required for client creation
  if (!lead.email) {
    return { canConvert: false, reason: 'Lead must have an email to convert' };
  }

  // Unqualified leads should not be converted
  if (lead.status === 'unqualified') {
    return { canConvert: false, reason: 'Cannot convert unqualified leads' };
  }

  return { canConvert: true };
}

/**
 * Get status label for display
 */
function getStatusLabel(status: LeadStatus): string {
  const labels: Record<LeadStatus, string> = {
    new: 'New',
    contacted: 'Contacted',
    qualified: 'Qualified',
    unqualified: 'Unqualified',
    converted: 'Converted',
  };
  return labels[status] || status;
}

// ============================================
// Component
// ============================================

/**
 * LeadActions - Action buttons for a lead row
 *
 * @example
 * ```tsx
 * <LeadActions
 *   lead={lead}
 *   onEdit={handleEdit}
 *   onConvert={handleConvert}
 *   disabled={isMutating}
 * />
 * ```
 */
export function LeadActions({
  lead,
  onEdit,
  canEdit = true,
  onConvert,
  canConvertOverride = true,
  onView,
  onDelete,
  canDelete = true,
  onAddToSequence,
  isEnrolledInSequence = false,
  currentSequenceName,
  onAssignRep,
  canAssignRep = false,
  onStatusChange,
  canChangeStatus = true,
  disabled = false,
  size = 'sm',
  variant = 'inline',
  readOnlyReason,
}: LeadActionsProps) {
  const { canConvert, reason } = canConvertLead(lead);
  const buttonClass = `btn btn-ghost btn-${size}`;
  const features = getFeatureFlags();
  const showSequenceAction = features.enableSequences && onAddToSequence;

  // Check if lead can be added to sequence
  const canAddToSequence = !!lead.email && !isEnrolledInSequence;
  const sequenceBlockReason = !lead.email
    ? 'Lead must have an email to add to sequence'
    : isEnrolledInSequence
      ? `Already in sequence: ${currentSequenceName || 'Unknown'}`
      : undefined;

  // Handle convert click
  const handleConvert = () => {
    if (canConvert && onConvert) {
      onConvert(lead);
    }
  };

  // Handle edit click
  const handleEdit = () => {
    if (onEdit) {
      onEdit(lead);
    }
  };

  // Handle view click
  const handleView = () => {
    if (onView) {
      onView(lead);
    }
  };

  // Handle delete click
  const handleDelete = () => {
    if (onDelete) {
      onDelete(lead);
    }
  };

  // Handle add to sequence click
  const handleAddToSequence = () => {
    if (canAddToSequence && onAddToSequence) {
      onAddToSequence(lead);
    }
  };

  // Handle assign rep click
  const handleAssignRep = () => {
    if (canAssignRep && onAssignRep) {
      onAssignRep(lead);
    }
  };

  // Handle status change
  const handleStatusChange = (newStatus: LeadStatus) => {
    if (canChangeStatus && onStatusChange && lead.status !== newStatus) {
      onStatusChange(lead, newStatus);
    }
  };

  if (variant === 'dropdown') {
    return (
      <div className="lead-actions lead-actions--dropdown">
        <button
          type="button"
          className={`${buttonClass} lead-actions__trigger`}
          disabled={disabled}
          aria-label="Lead actions"
        >
          <svg
            width="16"
            height="16"
            viewBox="0 0 16 16"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <circle cx="8" cy="3" r="1.5" fill="currentColor" />
            <circle cx="8" cy="8" r="1.5" fill="currentColor" />
            <circle cx="8" cy="13" r="1.5" fill="currentColor" />
          </svg>
        </button>
        {/* Dropdown menu would go here in a full implementation */}
      </div>
    );
  }

  return (
    <div className="lead-actions lead-actions--inline">
      {onView && (
        <button
          type="button"
          className={buttonClass}
          onClick={handleView}
          disabled={disabled}
        >
          View
        </button>
      )}

      {/* Status Change Dropdown */}
      {onStatusChange && lead.status !== 'converted' && (
        <select
          className="lead-actions__status-select"
          value={lead.status}
          onChange={(e) => handleStatusChange(e.target.value as LeadStatus)}
          disabled={disabled || !canChangeStatus}
          title={!canChangeStatus && readOnlyReason ? readOnlyReason : 'Change status'}
        >
          <option value="new">New</option>
          <option value="contacted">Contacted</option>
          <option value="qualified">Qualified</option>
          <option value="unqualified">Unqualified</option>
        </select>
      )}

      {/* Assign Rep Button (for managers) */}
      {onAssignRep && canAssignRep && (
        <button
          type="button"
          className={`${buttonClass} lead-actions__assign`}
          onClick={handleAssignRep}
          disabled={disabled}
          title="Assign to sales rep"
        >
          Assign
        </button>
      )}

      {onEdit && (
        <button
          type="button"
          className={buttonClass}
          onClick={handleEdit}
          disabled={disabled || !canEdit}
          title={!canEdit && readOnlyReason ? readOnlyReason : undefined}
        >
          Edit
        </button>
      )}

      {onConvert && (
        <button
          type="button"
          className={`${buttonClass} lead-actions__convert ${
            canConvert ? 'lead-actions__convert--enabled' : ''
          }`}
          onClick={handleConvert}
          disabled={disabled || !canConvert || !canConvertOverride}
          title={
            canConvert && canConvertOverride
              ? 'Convert to contact'
              : readOnlyReason || reason
          }
        >
          {lead.status === 'converted' ? 'Converted' : 'Convert'}
        </button>
      )}

      {showSequenceAction && (
        <button
          type="button"
          className={`${buttonClass} lead-actions__sequence ${
            isEnrolledInSequence ? 'lead-actions__sequence--enrolled' : ''
          }`}
          onClick={handleAddToSequence}
          disabled={disabled || !canAddToSequence}
          title={sequenceBlockReason || 'Add to sequence'}
          data-testid="add-to-sequence-btn"
        >
          {isEnrolledInSequence ? (
            <>
              <svg
                className="lead-actions__sequence-icon"
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
              In Sequence
            </>
          ) : (
            '+ Sequence'
          )}
        </button>
      )}

      {onDelete && (
        <button
          type="button"
          className={`${buttonClass} lead-actions__delete`}
          onClick={handleDelete}
          disabled={disabled || !canDelete}
          title={!canDelete && readOnlyReason ? readOnlyReason : undefined}
        >
          Delete
        </button>
      )}
    </div>
  );
}

// ============================================
// Status Badge Component
// ============================================

export interface LeadStatusBadgeProps {
  status: LeadStatus;
}

/**
 * LeadStatusBadge - Visual status indicator
 */
export function LeadStatusBadge({ status }: LeadStatusBadgeProps) {
  return (
    <span className={`lead-status-badge lead-status-badge--${status}`}>
      {getStatusLabel(status)}
    </span>
  );
}

export default LeadActions;
