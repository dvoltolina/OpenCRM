/**
 * CreateCompanyModal Component
 * Modal wrapper for company creation/editing
 *
 * Agent CRM-15 Implementation
 */

import { useCallback } from 'react';
import { Modal } from './Modal';
import { CompanyForm } from '../forms/CompanyForm';
import { useCompanyMutations } from '../../hooks/useCompanyMutations';
import type { Company, CompanySize } from '../../types/models';
import type { CompanyFormData } from '../forms/validation/schemas';
import './modals.css';

// ============================================
// Types
// ============================================

export interface CreateCompanyModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Initial data for edit mode */
  initialData?: Partial<Company>;
  /** Called after successful creation/update */
  onSuccess?: (company: Company) => void;
}

// ============================================
// Component
// ============================================

/**
 * CreateCompanyModal - Modal for creating/editing companies
 *
 * @example
 * ```tsx
 * const createModal = useModal();
 * const editModal = useModal<Company>();
 *
 * <button onClick={() => createModal.open()}>Add Company</button>
 * <button onClick={() => editModal.open(company)}>Edit Company</button>
 *
 * <CreateCompanyModal
 *   isOpen={createModal.isOpen}
 *   onClose={createModal.close}
 *   onSuccess={(company) => console.log('Created:', company)}
 * />
 *
 * <CreateCompanyModal
 *   isOpen={editModal.isOpen}
 *   onClose={editModal.close}
 *   initialData={editModal.data}
 *   onSuccess={(company) => console.log('Updated:', company)}
 * />
 * ```
 */
export function CreateCompanyModal({
  isOpen,
  onClose,
  initialData,
  onSuccess,
}: CreateCompanyModalProps) {
  const { createCompany, updateCompany, isLoading } = useCompanyMutations();
  const isEditing = Boolean(initialData?.id);

  const handleSubmit = useCallback(
    async (data: CompanyFormData) => {
      // Cast size to CompanySize type when calling mutations
      const mutationData: Partial<Company> = {
        ...data,
        size: data.size as CompanySize | undefined,
      };

      if (isEditing && initialData?.id) {
        await updateCompany(initialData.id, mutationData);
        // For updates, we need to get the updated company from the cache/context
        // or rely on the parent component to refetch. The onSuccess expects
        // a Company object, so we'll need to pass the initial data with updates.
        onSuccess?.({ ...initialData, ...mutationData } as Company);
        onClose();
      } else {
        const company = await createCompany(mutationData);
        onSuccess?.(company);
        onClose();
      }
    },
    [isEditing, initialData, createCompany, updateCompany, onSuccess, onClose]
  );

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Company' : 'Create Company'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <CompanyForm
        initialData={initialData}
        onSubmit={handleSubmit}
        onCancel={onClose}
        isLoading={isLoading}
      />
    </Modal>
  );
}

export default CreateCompanyModal;
