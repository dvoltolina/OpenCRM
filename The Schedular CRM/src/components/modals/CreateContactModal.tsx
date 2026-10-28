/**
 * CreateContactModal Component
 * Modal wrapper for contact creation/editing
 *
 * Agent CRM-15 Implementation
 */

import { useCallback } from 'react';
import { Modal } from './Modal';
import { ContactForm } from '../forms/ContactForm';
import { useContactMutations } from '../../hooks/useContactMutations';
import type { Client, Company, ClientLifecycle } from '../../types/models';
import type { ContactFormData } from '../forms/validation/schemas';
import './modals.css';

// ============================================
// Types
// ============================================

export interface CreateContactModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Initial data for edit mode */
  initialData?: Partial<Client>;
  /** Pre-selected company for new contact */
  company?: Company;
  /** Available companies for selection */
  companies?: Company[];
  /** Called after successful creation/update */
  onSuccess?: (contact: Client) => void;
}

// ============================================
// Component
// ============================================

/**
 * CreateContactModal - Modal for creating/editing contacts
 *
 * @example
 * ```tsx
 * const createModal = useModal();
 *
 * <button onClick={() => createModal.open()}>Add Contact</button>
 *
 * <CreateContactModal
 *   isOpen={createModal.isOpen}
 *   onClose={createModal.close}
 *   company={selectedCompany}
 *   companies={companies}
 *   onSuccess={(contact) => console.log('Created:', contact)}
 * />
 * ```
 */
export function CreateContactModal({
  isOpen,
  onClose,
  initialData,
  company,
  companies = [],
  onSuccess,
}: CreateContactModalProps) {
  const { createContact, updateContact, isLoading } = useContactMutations();
  const isEditing = Boolean(initialData?.id);

  const handleSubmit = useCallback(
    async (data: ContactFormData, options?: { allowDuplicate?: boolean }) => {
      // Cast lifecycle to ClientLifecycle type when calling mutations
      const mutationData: Partial<Client> = {
        ...data,
        lifecycle: data.lifecycle as ClientLifecycle | undefined,
      };

      if (isEditing && initialData?.id) {
        await updateContact(initialData.id, mutationData, options);
        // For updates, we need to get the updated contact from the cache/context
        // or rely on the parent component to refetch. The onSuccess expects
        // a Client object, so we'll need to pass the initial data with updates.
        onSuccess?.({ ...initialData, ...mutationData } as Client);
        onClose();
      } else {
        const createData: Partial<Client> = {
          ...mutationData,
          companyId: data.companyId || company?.id,
          companyName: data.companyName || company?.name,
        };
        const contact = await createContact(createData, options);
        onSuccess?.(contact);
        onClose();
      }
    },
    [isEditing, initialData, company, createContact, updateContact, onSuccess, onClose]
  );

  // Prepare initial data with company if provided
  const formInitialData = initialData || (company ? {
    companyId: company.id,
    companyName: company.name,
  } : undefined);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Contact' : 'Create Contact'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <ContactForm
        initialData={formInitialData}
        onSubmit={handleSubmit}
        onCancel={onClose}
        isLoading={isLoading}
        companies={companies}
      />
    </Modal>
  );
}

export default CreateContactModal;
