/**
 * CreateLeadModal Component
 * Modal wrapper for lead creation/editing
 *
 * Agent CRM-15 Implementation
 */

import { useCallback } from 'react';
import { Modal } from './Modal';
import { LeadForm } from '../forms/LeadForm';
import { useLeadMutations } from '../../hooks/useLeadMutations';
import type { Lead, LeadStatus, LeadSource } from '../../types/models';
import type { LeadFormData } from '../forms/validation/schemas';
import './modals.css';

// ============================================
// Types
// ============================================

export interface CreateLeadModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Initial data for edit mode */
  initialData?: Partial<Lead>;
  /** Called after successful creation/update */
  onSuccess?: (lead: Lead) => void;
  /** Team members for assignee dropdown */
  teamMembers?: Array<{ id: string; name: string }>;
}

// ============================================
// Component
// ============================================

/**
 * CreateLeadModal - Modal for creating/editing leads
 *
 * @example
 * ```tsx
 * const createModal = useModal();
 * const editModal = useModal<Lead>();
 *
 * <button onClick={() => createModal.open()}>Create Lead</button>
 * <button onClick={() => editModal.open(lead)}>Edit Lead</button>
 *
 * <CreateLeadModal
 *   isOpen={createModal.isOpen}
 *   onClose={createModal.close}
 *   onSuccess={(lead) => console.log('Created:', lead)}
 * />
 *
 * <CreateLeadModal
 *   isOpen={editModal.isOpen}
 *   onClose={editModal.close}
 *   initialData={editModal.data}
 *   onSuccess={(lead) => console.log('Updated:', lead)}
 * />
 * ```
 */
export function CreateLeadModal({
  isOpen,
  onClose,
  initialData,
  onSuccess,
  teamMembers = [],
}: CreateLeadModalProps) {
  const { createLead, updateLead, isLoading } = useLeadMutations();
  const isEditing = Boolean(initialData?.id);

  const handleSubmit = useCallback(
    async (data: LeadFormData, options?: { allowDuplicate?: boolean }) => {
      // Cast status and source to proper types when calling mutations
      const mutationData: Partial<Lead> = {
        ...data,
        status: data.status as LeadStatus | undefined,
        source: data.source as LeadSource | undefined,
      };

      if (isEditing && initialData?.id) {
        await updateLead(initialData.id, mutationData, options);
        // For updates, we need to get the updated lead from the cache/context
        // or rely on the parent component to refetch. The onSuccess expects
        // a Lead object, so we'll need to pass the initial data with updates.
        onSuccess?.({ ...initialData, ...mutationData } as Lead);
        onClose();
      } else {
        const lead = await createLead(mutationData, options);
        onSuccess?.(lead);
        onClose();
      }
    },
    [isEditing, initialData, createLead, updateLead, onSuccess, onClose]
  );

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Lead' : 'Create Lead'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <LeadForm
        initialData={initialData}
        onSubmit={handleSubmit}
        onCancel={onClose}
        isLoading={isLoading}
        teamMembers={teamMembers}
      />
    </Modal>
  );
}

export default CreateLeadModal;
