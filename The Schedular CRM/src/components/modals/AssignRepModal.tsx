/**
 * AssignRepModal Component
 * Modal for assigning leads/contacts to sales reps
 *
 * CRM Unified Funnel Implementation
 * Used by LeadsPage for manager assignment workflow
 */

import { useState, useCallback, useMemo } from 'react';
import { Modal } from './Modal';
import { useTeamMembers } from '../../hooks/useTeamMembers';
import type { Lead } from '../../types/models';
import './modals.css';

// ============================================
// Types
// ============================================

export interface AssignRepModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Lead(s) to assign - single lead or array for bulk assign */
  leads: Lead | Lead[];
  /** Called after successful assignment */
  onAssign: (assigneeId: string, assigneeName: string) => Promise<void>;
  /** Whether assignment is in progress */
  isAssigning?: boolean;
}

// ============================================
// Component
// ============================================

/**
 * AssignRepModal - Modal for assigning leads to sales reps
 *
 * Features:
 * - Shows list of active team members filtered to sales reps
 * - Supports single and bulk lead assignment
 * - Shows current assignment if single lead
 *
 * @example
 * ```tsx
 * <AssignRepModal
 *   isOpen={assignModal.isOpen}
 *   onClose={assignModal.close}
 *   leads={selectedLead}
 *   onAssign={async (repId, repName) => {
 *     await assignLead(selectedLead.id, repId, repName);
 *     refresh();
 *   }}
 *   isAssigning={isMutating}
 * />
 * ```
 */
export function AssignRepModal({
  isOpen,
  onClose,
  leads,
  onAssign,
  isAssigning = false,
}: AssignRepModalProps) {
  const { members, isLoading: isLoadingMembers } = useTeamMembers();
  const [selectedRepId, setSelectedRepId] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  // Normalize leads to array
  const leadArray = useMemo(() => {
    return Array.isArray(leads) ? leads : [leads];
  }, [leads]);

  const isBulkAssign = leadArray.length > 1;

  // Filter to active staff members who can be assigned leads
  // Typically staff, manager roles - exclude owner/admin unless they want assignments
  const assignableReps = useMemo(() => {
    return members.filter((m) => m.isActive);
  }, [members]);

  // Get current assignee for single lead
  const currentAssignee = useMemo(() => {
    if (isBulkAssign) return null;
    const lead = leadArray[0];
    return lead?.assigneeId ? {
      id: lead.assigneeId,
      name: lead.assigneeName || 'Unknown',
    } : null;
  }, [leadArray, isBulkAssign]);

  // Handle assignment
  const handleAssign = useCallback(async () => {
    if (!selectedRepId) {
      setError('Please select a sales rep');
      return;
    }

    const selectedRep = assignableReps.find((r) => r.id === selectedRepId);
    if (!selectedRep) {
      setError('Selected rep not found');
      return;
    }

    setError(null);

    try {
      const repName = `${selectedRep.firstName} ${selectedRep.lastName}`.trim();
      await onAssign(selectedRepId, repName);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to assign lead');
    }
  }, [selectedRepId, assignableReps, onAssign, onClose]);

  // Reset state when modal opens
  const handleClose = useCallback(() => {
    setSelectedRepId('');
    setError(null);
    onClose();
  }, [onClose]);

  // Modal title based on single vs bulk
  const modalTitle = isBulkAssign
    ? `Assign ${leadArray.length} Leads to Rep`
    : 'Assign Lead to Rep';

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={modalTitle}
      size="sm"
      closeOnOverlayClick={!isAssigning}
      closeOnEscape={!isAssigning}
    >
      <div className="assign-rep-modal">
        {/* Lead Info Summary */}
        <div className="assign-rep-modal__summary">
          {isBulkAssign ? (
            <p className="assign-rep-modal__bulk-info">
              Assigning <strong>{leadArray.length} leads</strong> to a sales rep.
            </p>
          ) : (
            <div className="assign-rep-modal__lead-info">
              <p className="assign-rep-modal__lead-name">
                <strong>{leadArray[0]?.firstName} {leadArray[0]?.lastName}</strong>
              </p>
              {leadArray[0]?.email && (
                <p className="assign-rep-modal__lead-email">{leadArray[0].email}</p>
              )}
              {currentAssignee && (
                <p className="assign-rep-modal__current">
                  Currently assigned to: <strong>{currentAssignee.name}</strong>
                </p>
              )}
            </div>
          )}
        </div>

        {/* Rep Selection */}
        <div className="assign-rep-modal__selection">
          <label htmlFor="rep-select" className="form-label">
            Select Sales Rep
          </label>
          {isLoadingMembers ? (
            <p className="text-muted">Loading team members...</p>
          ) : assignableReps.length === 0 ? (
            <p className="text-muted">No team members available for assignment.</p>
          ) : (
            <select
              id="rep-select"
              className="form-select"
              value={selectedRepId}
              onChange={(e) => setSelectedRepId(e.target.value)}
              disabled={isAssigning}
            >
              <option value="">-- Select a rep --</option>
              {assignableReps.map((rep) => (
                <option key={rep.id} value={rep.id}>
                  {rep.firstName} {rep.lastName}
                  {rep.role !== 'staff' && ` (${rep.role})`}
                  {currentAssignee?.id === rep.id && ' (current)'}
                </option>
              ))}
            </select>
          )}
        </div>

        {/* Error Display */}
        {error && (
          <div className="assign-rep-modal__error">
            <p className="error-text">{error}</p>
          </div>
        )}

        {/* Actions */}
        <div className="modal-actions">
          <button
            type="button"
            className="btn btn-secondary"
            onClick={handleClose}
            disabled={isAssigning}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={handleAssign}
            disabled={isAssigning || !selectedRepId || isLoadingMembers}
          >
            {isAssigning ? 'Assigning...' : 'Assign'}
          </button>
        </div>
      </div>
    </Modal>
  );
}

export default AssignRepModal;
