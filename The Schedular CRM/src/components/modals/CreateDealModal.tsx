/**
 * CreateDealModal Component
 * Modal wrapper for deal creation/editing
 *
 * Agent CRM-15 Implementation
 */

import { useCallback } from 'react';
import { Modal } from './Modal';
import { DealForm } from '../forms/DealForm';
import { useDealMutations, type CreateDealInput } from '../../hooks/useDealMutations';
import type { Deal, Client, Pipeline, Stage } from '../../types/models';
import type { DealFormData } from '../forms/validation/schemas';
import './modals.css';

// ============================================
// Types
// ============================================

export interface CreateDealModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Initial data for edit mode */
  initialData?: Partial<Deal>;
  /** Pre-selected client for new deal */
  client?: Client;
  /** Available pipelines */
  pipelines?: Pipeline[];
  /** Available stages for selected pipeline */
  stages?: Stage[];
  /** Available clients for selection */
  clients?: Client[];
  /** Called after successful creation/update */
  onSuccess?: (deal: Deal) => void;
  /** Team members for assignee dropdown */
  teamMembers?: Array<{ id: string; name: string }>;
}

// ============================================
// Component
// ============================================

/**
 * CreateDealModal - Modal for creating/editing deals
 *
 * @example
 * ```tsx
 * const createModal = useModal();
 *
 * <button onClick={() => createModal.open()}>Create Deal</button>
 *
 * <CreateDealModal
 *   isOpen={createModal.isOpen}
 *   onClose={createModal.close}
 *   client={selectedClient}
 *   pipelines={pipelines}
 *   stages={stages}
 *   onSuccess={(deal) => console.log('Created:', deal)}
 * />
 * ```
 */
export function CreateDealModal({
  isOpen,
  onClose,
  initialData,
  client,
  pipelines = [],
  stages = [],
  clients = [],
  onSuccess,
  // teamMembers = [],
}: CreateDealModalProps) {
  const { createDeal, updateDeal, isLoading } = useDealMutations();
  const isEditing = Boolean(initialData?.id);

  const handleSubmit = useCallback(
    async (data: DealFormData) => {
      let deal: Deal | undefined;

      // Parse expectedCloseDate to Date if it's a string
      const parseDate = (dateValue: Date | string | undefined): Date | undefined => {
        if (!dateValue) return undefined;
        if (dateValue instanceof Date) return dateValue;
        return new Date(dateValue);
      };

      if (isEditing && initialData?.id) {
        deal = await updateDeal(initialData.id, {
          title: data.title,
          valueCents: data.valueCents,
          probability: data.probability,
          expectedCloseDate: parseDate(data.expectedCloseDate),
          pipelineId: data.pipelineId,
          stageId: data.stageId,
          notes: data.notes,
          tags: data.tags,
        });
      } else {
        const createData: CreateDealInput = {
          title: data.title,
          valueCents: data.valueCents,
          pipelineId: data.pipelineId,
          stageId: data.stageId,
          clientId: data.clientId || client?.id,
          clientName: data.clientName || (client ? `${client.firstName} ${client.lastName}` : undefined),
          companyName: data.companyName || client?.companyName,
          probability: data.probability,
          expectedCloseDate: parseDate(data.expectedCloseDate),
          notes: data.notes,
          tags: data.tags,
        };
        deal = await createDeal(createData);
      }

      if (deal) {
        onSuccess?.(deal);
        onClose();
      }
    },
    [isEditing, initialData?.id, client, createDeal, updateDeal, onSuccess, onClose]
  );

  // Prepare initial data with client if provided
  const formInitialData = initialData || (client ? {
    clientId: client.id,
    clientName: `${client.firstName} ${client.lastName}`,
    companyName: client.companyName,
  } : undefined);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Opportunity' : 'Create Opportunity'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <DealForm
        initialData={formInitialData}
        onSubmit={handleSubmit}
        onCancel={onClose}
        isLoading={isLoading}
        pipelines={pipelines}
        stages={stages}
        clients={clients.map(c => ({ id: c.id, name: `${c.firstName} ${c.lastName}` }))}
      />
    </Modal>
  );
}

export default CreateDealModal;
