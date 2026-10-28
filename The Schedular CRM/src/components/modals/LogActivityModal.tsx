/**
 * LogActivityModal Component
 * Modal for quickly logging activities (calls, emails, meetings, notes)
 *
 * Agent CRM-15 Implementation
 */

import { useCallback } from 'react';
import { Modal } from './Modal';
import { ActivityForm } from '../forms/ActivityForm';
import { useActivityLog } from '../../hooks/useActivityLog';
import type { SalesActivity, SalesActivityType } from '../../types/models';
import type { ActivityFormData } from '../forms/validation/schemas';
import { getTaskTemplates } from '../../config/taskTemplates';
import './modals.css';

// ============================================
// Types
// ============================================

export type EntityType = 'lead' | 'deal' | 'client' | 'company';

export interface LogActivityModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Entity type for the activity */
  entityType: EntityType;
  /** Entity ID for the activity */
  entityId: string;
  /** Entity name for display */
  entityName?: string;
  /** Pre-selected activity type */
  defaultActivityType?: SalesActivityType;
  /** Called after successful activity log */
  onSuccess?: (activity: SalesActivity) => void;
  /** Team members for assignee dropdown */
  teamMembers?: Array<{ id: string; name: string }>;
  /** Deals list for linking */
  deals?: Array<{ id: string; title: string }>;
  /** Clients list for linking */
  clients?: Array<{ id: string; name: string }>;
  /** Leads list for linking */
  leads?: Array<{ id: string; name: string }>;
  /** Companies list for linking */
  companies?: Array<{ id: string; name: string }>;
}

// ============================================
// Component
// ============================================

/**
 * LogActivityModal - Modal for logging activities
 *
 * @example
 * ```tsx
 * const activityModal = useModal<{ entityType: EntityType; entityId: string }>();
 *
 * <button onClick={() => activityModal.open({ entityType: 'deal', entityId: deal.id })}>
 *   Log Activity
 * </button>
 *
 * <LogActivityModal
 *   isOpen={activityModal.isOpen}
 *   onClose={activityModal.close}
 *   entityType={activityModal.data?.entityType || 'deal'}
 *   entityId={activityModal.data?.entityId || ''}
 *   entityName={deal.title}
 *   onSuccess={(activity) => console.log('Logged:', activity)}
 * />
 * ```
 */
export function LogActivityModal({
  isOpen,
  onClose,
  entityType,
  entityId,
  entityName,
  defaultActivityType = 'note',
  onSuccess,
  teamMembers = [],
  deals = [],
  clients = [],
  leads = [],
  companies = [],
}: LogActivityModalProps) {
  const { logActivity, isLoading } = useActivityLog();

  const handleSubmit = useCallback(
    async (data: ActivityFormData) => {
      // Map entity type to the correct ID field
      const entityIds: Record<string, string> = {};
      switch (entityType) {
        case 'lead':
          entityIds.leadId = entityId;
          break;
        case 'deal':
          entityIds.dealId = entityId;
          break;
        case 'client':
          entityIds.clientId = entityId;
          break;
        case 'company':
          entityIds.companyId = entityId;
          break;
      }

      const parseDate = (dateValue: Date | string | undefined): Date | undefined => {
        if (!dateValue) return undefined;
        if (dateValue instanceof Date) return dateValue;
        return new Date(dateValue);
      };

      const activity = await logActivity({
        type: data.type as SalesActivityType,
        title: data.title,
        description: data.description,
        dueDate: parseDate(data.dueDate),
        templateId: data.templateId,
        slaMinutes: data.slaMinutes,
        slaAt: parseDate(data.slaAt),
        reminderAt: parseDate(data.reminderAt),
        assigneeId: data.assigneeId,
        assigneeName: data.assigneeName,
        ...entityIds,
      });

      if (activity) {
        onSuccess?.(activity);
        onClose();
      }
    },
    [entityType, entityId, logActivity, onSuccess, onClose]
  );

  // Build title based on entity
  const title = entityName
    ? `Log Activity for ${entityName}`
    : `Log Activity`;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={title}
      size="md"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      <ActivityForm
        initialData={{ type: defaultActivityType }}
        onSubmit={handleSubmit}
        onCancel={onClose}
        isLoading={isLoading}
        teamMembers={teamMembers}
        deals={deals}
        clients={clients}
        leads={leads}
        companies={companies}
        taskTemplates={getTaskTemplates()}
      />
    </Modal>
  );
}

export default LogActivityModal;
