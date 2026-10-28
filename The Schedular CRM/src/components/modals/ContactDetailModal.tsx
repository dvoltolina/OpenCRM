/**
 * ContactDetailModal Component
 * Comprehensive view/edit modal for contact management with company linkage and tags
 *
 * Agent FW-02 Implementation
 * HIPAA Compliant: No PHI in logs, businessId scoped, RBAC enforced
 */

import { useState, useCallback, useMemo } from 'react';
import { Modal } from './Modal';
import { ContactForm } from '../forms/ContactForm';
import { useContactMutations } from '../../hooks/useContactMutations';
import { useCompanies } from '../../hooks/useCompanies';
import { useDeals } from '../../hooks/useDeals';
import { usePipelines, useStages, useModal } from '../../hooks';
import { DuplicateList } from '../duplicates/DuplicateList';
import { MergeModal } from '../duplicates/MergeModal';
import { CreateDealModal } from './CreateDealModal';
import { useDuplicateDetection } from '../../hooks/useDuplicateDetection';
import { formatCurrency } from '../../utils/formatting';
import type { Client, ClientLifecycle, ContactLeadStatus, Deal } from '../../types/models';
import type { ContactFormData } from '../forms/validation/schemas';
import './modals.css';

// Lead status options for the unified funnel
const LEAD_STATUS_OPTIONS: ContactLeadStatus[] = ['New', 'Working', 'Qualified', 'Unqualified', 'Nurturing'];

// ============================================
// Types
// ============================================

export interface ContactDetailModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Contact to display */
  contact: Client;
  /** Called after successful update */
  onSuccess?: () => void;
}

// ============================================
// Component
// ============================================

/**
 * ContactDetailModal - Comprehensive view/edit modal for contacts
 * Supports:
 * - View mode with lifecycle info
 * - Edit mode
 * - Tag management (add/remove)
 * - Company linkage (link/unlink)
 * - Delete confirmation
 *
 * SECURITY: All mutations enforce businessId scoping via hooks
 *
 * @example
 * ```tsx
 * const detailModal = useModal<Client>();
 *
 * <button onClick={() => detailModal.open(contact)}>View Details</button>
 *
 * <ContactDetailModal
 *   isOpen={detailModal.isOpen}
 *   onClose={detailModal.close}
 *   contact={detailModal.data}
 *   onSuccess={refresh}
 * />
 * ```
 */
export function ContactDetailModal({
  isOpen,
  onClose,
  contact,
  onSuccess,
}: ContactDetailModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [tagInput, setTagInput] = useState('');
  const [duplicateNotice, setDuplicateNotice] = useState<string | null>(null);
  const [mergeCandidate, setMergeCandidate] = useState<Client | null>(null);

  const {
    updateContact,
    linkToCompany,
    unlinkFromCompany,
    addTag,
    removeTag,
    isLoading,
  } = useContactMutations();

  const { companies } = useCompanies();

  // Fetch opportunities linked to this contact
  const { deals: contactOpportunities, isLoading: isLoadingOpportunities, refresh: refreshOpportunities } = useDeals({
    clientId: contact.id,
  });

  // Pipeline/stage data for create opportunity modal
  const { pipelines } = usePipelines();
  const [selectedPipelineId, setSelectedPipelineId] = useState<string>('');
  const { stages } = useStages(selectedPipelineId || pipelines[0]?.id);

  // Modal for creating opportunity from contact
  const createOpportunityModal = useModal<{ contact: Client }>();

  // Handle creating opportunity from this contact
  const handleCreateOpportunity = useCallback(() => {
    if (pipelines.length > 0) {
      setSelectedPipelineId(pipelines[0].id);
    }
    createOpportunityModal.open({ contact });
  }, [contact, createOpportunityModal, pipelines]);

  // Handle opportunity creation success
  const handleOpportunityCreated = useCallback((_deal: Deal) => {
    refreshOpportunities();
    createOpportunityModal.close();
    onSuccess?.();
  }, [createOpportunityModal, refreshOpportunities, onSuccess]);

  // Handle lead status change
  const handleLeadStatusChange = useCallback(
    async (newStatus: ContactLeadStatus) => {
      await updateContact(contact.id, { leadStatus: newStatus });
      onSuccess?.();
    },
    [contact.id, updateContact, onSuccess]
  );
  const {
    checkEntity,
    mergeEntities,
    duplicates,
    isChecking,
    isMerging,
    error: duplicateError,
    clearError: clearDuplicateError,
    clearDuplicates,
  } = useDuplicateDetection();

  // Switch to edit mode
  const handleEditClick = useCallback(() => {
    setIsEditing(true);
  }, []);

  // Cancel editing (return to view mode)
  const handleCancelEdit = useCallback(() => {
    setIsEditing(false);
  }, []);

  // Handle form submission
  const handleSubmit = useCallback(
    async (data: ContactFormData, options?: { allowDuplicate?: boolean }) => {
      const mutationData: Partial<Client> = {
        ...data,
        lifecycle: data.lifecycle as ClientLifecycle | undefined,
      };

      await updateContact(contact.id, mutationData, options);
      setIsEditing(false);
      onSuccess?.();
    },
    [contact.id, updateContact, onSuccess]
  );

  // Handle company link change
  const handleCompanyChange = useCallback(
    async (companyId: string | undefined, companyName: string | undefined) => {
      if (companyId && companyName) {
        await linkToCompany(contact.id, companyId, companyName);
      } else {
        await unlinkFromCompany(contact.id);
      }
      onSuccess?.();
    },
    [contact.id, linkToCompany, unlinkFromCompany, onSuccess]
  );

  const handleDuplicateScan = useCallback(async () => {
    clearDuplicateError();
    setDuplicateNotice(null);

    try {
      const matches = await checkEntity(contact, {
        entityType: 'client',
        minConfidence: 60,
        excludeId: contact.id,
      });
      setDuplicateNotice(
        matches.length > 0
          ? 'Potential duplicates found. Review and merge if needed.'
          : 'No duplicates detected.'
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to check duplicates. Please try again.';
      setDuplicateNotice(message);
    }
  }, [checkEntity, clearDuplicateError, contact]);

  const handleOpenMerge = useCallback((duplicate: Client) => {
    setMergeCandidate(duplicate);
  }, []);

  const handleMerge = useCallback(
    async (
      primaryId: string,
      secondaryId: string,
      fieldPreferences: Record<string, 'primary' | 'secondary'>,
      transferRelatedRecords: boolean
    ) => {
      const result = await mergeEntities({
        entityType: 'client',
        primaryId,
        secondaryId,
        fieldPreferences,
        transferRelatedRecords,
      });
      setDuplicateNotice('Merged duplicate record and transferred related history.');
      setMergeCandidate(null);
      clearDuplicates();
      await handleDuplicateScan();
      onSuccess?.();
      return result;
    },
    [clearDuplicates, handleDuplicateScan, mergeEntities, onSuccess]
  );

  // Handle tag addition
  const handleAddTag = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const trimmedTag = tagInput.trim();
      if (!trimmedTag) return;

      // Prevent duplicate tags (case-insensitive)
      if (contact.tags.some(t => t.toLowerCase() === trimmedTag.toLowerCase())) {
        setTagInput('');
        return;
      }

      await addTag(contact.id, trimmedTag);
      setTagInput('');
      onSuccess?.();
    },
    [contact.id, contact.tags, tagInput, addTag, onSuccess]
  );

  // Handle tag removal
  const handleRemoveTag = useCallback(
    async (tag: string) => {
      await removeTag(contact.id, tag);
      onSuccess?.();
    },
    [contact.id, removeTag, onSuccess]
  );

  // Render content based on mode
  const content = useMemo(() => {
    if (isEditing) {
      // Edit Mode: Show form
      return (
        <ContactForm
          initialData={contact}
          onSubmit={handleSubmit}
          onCancel={handleCancelEdit}
          isLoading={isLoading}
          companies={companies}
        />
      );
    }

    // View Mode: Show details
    return (
      <div className="contact-detail-view">
        {/* Header with edit button */}
        <div className="detail-header">
          <h3>{contact.firstName} {contact.lastName}</h3>
          <button
            className="btn btn-primary btn-sm"
            onClick={handleEditClick}
            disabled={isLoading}
          >
            Edit Contact
          </button>
        </div>

        {/* Basic Info */}
        <section className="detail-section">
          <h4>Contact Information</h4>
          <dl className="detail-grid">
            <dt>Email</dt>
            <dd>{contact.email}</dd>

            {contact.phone && (
              <>
                <dt>Phone</dt>
                <dd>{contact.phone}</dd>
              </>
            )}

            {contact.title && (
              <>
                <dt>Title</dt>
                <dd>{contact.title}</dd>
              </>
            )}

            {contact.lifecycle && (
              <>
                <dt>Lifecycle Stage</dt>
                <dd className={`lifecycle-badge lifecycle-${contact.lifecycle}`}>
                  {contact.lifecycle}
                </dd>
              </>
            )}

            {contact.leadSource && (
              <>
                <dt>Lead Source</dt>
                <dd>{contact.leadSource}</dd>
              </>
            )}

            {contact.lastContactedAt && (
              <>
                <dt>Last Contacted</dt>
                <dd>{contact.lastContactedAt.toLocaleDateString()}</dd>
              </>
            )}
          </dl>
        </section>

        {/* Lead Status - Unified Funnel */}
        <section className="detail-section">
          <h4>Lead Status</h4>
          <div className="lead-status-control">
            <select
              className="form-select"
              value={contact.leadStatus || ''}
              onChange={(e) => {
                const newStatus = e.target.value as ContactLeadStatus;
                void handleLeadStatusChange(newStatus || null);
              }}
              disabled={isLoading}
            >
              <option value="">No lead status</option>
              {LEAD_STATUS_OPTIONS.map((status) => (
                <option key={status} value={status || ''}>
                  {status}
                </option>
              ))}
            </select>
            {contact.leadStatus && (
              <span className={`lead-status-badge lead-status-${contact.leadStatus?.toLowerCase()}`}>
                {contact.leadStatus}
              </span>
            )}
          </div>
          {contact.assignedRepName && (
            <p className="assigned-rep-info">
              <strong>Assigned Rep:</strong> {contact.assignedRepName}
            </p>
          )}
        </section>

        {/* Opportunities Section - Shows deals linked to this contact */}
        <section className="detail-section">
          <div className="detail-header">
            <h4>Opportunities</h4>
            <button
              className="btn btn-primary btn-sm"
              onClick={handleCreateOpportunity}
              disabled={isLoading}
            >
              + Create Opportunity
            </button>
          </div>
          {isLoadingOpportunities ? (
            <p className="text-muted">Loading opportunities...</p>
          ) : contactOpportunities.length === 0 ? (
            <div className="opportunities-empty">
              <p className="text-muted">No opportunities linked to this contact.</p>
              <p className="text-hint">
                Create an opportunity to start tracking a potential deal with this contact.
              </p>
            </div>
          ) : (
            <div className="opportunities-list">
              <table className="mini-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Value</th>
                    <th>Stage</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {contactOpportunities.map((opp) => (
                    <tr key={opp.id}>
                      <td>{opp.title}</td>
                      <td>{opp.valueCents ? formatCurrency(opp.valueCents, opp.currency) : '-'}</td>
                      <td>{opp.stageId}</td>
                      <td>
                        <span className={`status-badge status-${opp.status}`}>
                          {opp.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="opportunities-summary">
                <span>
                  <strong>{contactOpportunities.length}</strong> opportunit{contactOpportunities.length === 1 ? 'y' : 'ies'}
                </span>
                <span>
                  Total: <strong>{formatCurrency(contactOpportunities.reduce((sum, o) => sum + (o.valueCents || 0), 0), 'USD')}</strong>
                </span>
              </div>
            </div>
          )}
        </section>

        {/* Company Linkage */}
        <section className="detail-section">
          <h4>Company</h4>
          {contact.companyId && contact.companyName ? (
            <div className="company-link">
              <p>
                <strong>{contact.companyName}</strong>
              </p>
              <button
                className="btn btn-ghost btn-sm"
                onClick={() => handleCompanyChange(undefined, undefined)}
                disabled={isLoading}
              >
                Unlink Company
              </button>
            </div>
          ) : (
            <div className="company-link-empty">
              <p className="text-muted">No company linked</p>
              <select
                className="form-select"
                onChange={(e) => {
                  const selected = companies.find(c => c.id === e.target.value);
                  if (selected) {
                    void handleCompanyChange(selected.id, selected.name);
                  }
                }}
                disabled={isLoading}
                defaultValue=""
              >
                <option value="" disabled>Select a company...</option>
                {companies.map(company => (
                  <option key={company.id} value={company.id}>
                    {company.name}
                  </option>
                ))}
              </select>
            </div>
          )}
        </section>

        {/* Tags */}
        <section className="detail-section">
          <h4>Tags</h4>
          <div className="tags-container">
            {contact.tags.map(tag => (
              <span key={tag} className="tag">
                {tag}
                <button
                  className="tag-remove"
                  onClick={() => void handleRemoveTag(tag)}
                  disabled={isLoading}
                  aria-label={`Remove tag ${tag}`}
                >
                  ×
                </button>
              </span>
            ))}
          </div>
          <form onSubmit={handleAddTag} className="tag-input-form">
            <input
              type="text"
              placeholder="Add tag..."
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              className="form-input"
              disabled={isLoading}
            />
            <button
              type="submit"
              className="btn btn-secondary btn-sm"
              disabled={isLoading || !tagInput.trim()}
            >
              Add Tag
            </button>
          </form>
        </section>

        {/* Notes */}
        {contact.crmNotes && (
          <section className="detail-section">
            <h4>Notes</h4>
            <p className="notes-text">{contact.crmNotes}</p>
          </section>
        )}

        {/* Address */}
        {contact.address && (
          <section className="detail-section">
            <h4>Address</h4>
            <address className="detail-address">
              {contact.address.street && <div>{contact.address.street}</div>}
              {(contact.address.city || contact.address.state || contact.address.zipCode) && (
                <div>
                  {contact.address.city && `${contact.address.city}, `}
                  {contact.address.state && `${contact.address.state} `}
                  {contact.address.zipCode && contact.address.zipCode}
                </div>
              )}
              {contact.address.country && <div>{contact.address.country}</div>}
            </address>
          </section>
        )}

        {/* Duplicates */}
        <section className="detail-section">
          <div className="detail-header">
            <h4>Duplicates</h4>
            <button
              className="btn btn-secondary btn-sm"
              onClick={() => void handleDuplicateScan()}
              disabled={isChecking}
            >
              {isChecking ? 'Checking…' : 'Check duplicates'}
            </button>
          </div>
          {duplicateNotice && <p className="text-muted">{duplicateNotice}</p>}
          {duplicateError && (
            <div className="alert error">
              {duplicateError.message}
            </div>
          )}
          {duplicates.length > 0 ? (
            <DuplicateList
              entityType="client"
              entity={contact}
              matches={duplicates.map((match) => ({
                ...match,
                entity: match.entity as Client,
              }))}
              onMerge={(_, duplicate) => handleOpenMerge(duplicate as Client)}
              isDisabled={isMerging}
            />
          ) : (
            <p className="text-muted">No duplicates loaded yet. Run a check to confirm.</p>
          )}
        </section>

        {/* Metadata */}
        <section className="detail-section detail-metadata">
          <dl className="detail-grid">
            <dt>Created</dt>
            <dd>{contact.createdAt.toLocaleDateString()}</dd>

            {contact.updatedAt && (
              <>
                <dt>Last Updated</dt>
                <dd>{contact.updatedAt.toLocaleDateString()}</dd>
              </>
            )}
          </dl>
        </section>
      </div>
    );
  }, [
    isEditing,
    contact,
    companies,
    tagInput,
    isLoading,
    handleEditClick,
    handleSubmit,
    handleCancelEdit,
    handleCompanyChange,
    handleAddTag,
    handleRemoveTag,
    handleDuplicateScan,
    duplicateNotice,
    duplicateError,
    duplicates,
    isChecking,
    isMerging,
    handleOpenMerge,
    // New dependencies for opportunities and lead status
    contactOpportunities,
    isLoadingOpportunities,
    handleCreateOpportunity,
    handleLeadStatusChange,
  ]);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Contact' : 'Contact Details'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      {content}
      <MergeModal
        isOpen={Boolean(mergeCandidate)}
        onClose={() => setMergeCandidate(null)}
        entityType="client"
        primary={contact}
        secondary={mergeCandidate}
        onMerge={(primaryId, secondaryId, fieldPreferences, transferRelatedRecords) =>
          handleMerge(primaryId, secondaryId, fieldPreferences, transferRelatedRecords)
        }
        isMerging={isMerging}
      />

      {/* Create Opportunity Modal - pre-filled with this contact */}
      <CreateDealModal
        isOpen={createOpportunityModal.isOpen}
        onClose={createOpportunityModal.close}
        client={contact}
        pipelines={pipelines}
        stages={stages}
        onSuccess={handleOpportunityCreated}
      />
    </Modal>
  );
}

export default ContactDetailModal;
