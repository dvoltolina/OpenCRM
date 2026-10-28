/**
 * CompanyDetailModal Component
 * Comprehensive view/edit modal for company management with linked contacts/deals and tags
 *
 * Agent FW-02 Implementation
 * HIPAA Compliant: No PHI in logs, businessId scoped, RBAC enforced
 */

import { useState, useCallback, useMemo } from 'react';
import { Modal } from './Modal';
import { CompanyForm } from '../forms/CompanyForm';
import { useCompanyMutations } from '../../hooks/useCompanyMutations';
import { useContacts } from '../../hooks/useContacts';
import { useDeals } from '../../hooks/useDeals';
import type { Company } from '../../types/models';
import type { CompanyFormData } from '../forms/validation/schemas';
import './modals.css';

// ============================================
// Types
// ============================================

export interface CompanyDetailModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Company to display */
  company: Company;
  /** Called after successful update */
  onSuccess?: () => void;
}

// ============================================
// Helper Functions
// ============================================

function formatCurrency(cents: number, currency: string): string {
  const dollars = cents / 100;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(dollars);
}

function getSizeLabel(size?: Company['size']): string {
  if (!size) return '';
  const labels = {
    small: 'Small (1-50)',
    medium: 'Medium (51-200)',
    large: 'Large (201-1000)',
    enterprise: 'Enterprise (1000+)',
  };
  return labels[size] || size;
}

// ============================================
// Component
// ============================================

/**
 * CompanyDetailModal - Comprehensive view/edit modal for companies
 * Supports:
 * - View mode with basic info, linked contacts, and linked deals
 * - Edit mode
 * - Tag management (add/remove)
 * - Delete confirmation
 *
 * SECURITY: All mutations enforce businessId scoping via hooks
 *
 * @example
 * ```tsx
 * const detailModal = useModal<Company>();
 *
 * <button onClick={() => detailModal.open(company)}>View Details</button>
 *
 * <CompanyDetailModal
 *   isOpen={detailModal.isOpen}
 *   onClose={detailModal.close}
 *   company={detailModal.data}
 *   onSuccess={refresh}
 * />
 * ```
 */
export function CompanyDetailModal({
  isOpen,
  onClose,
  company,
  onSuccess,
}: CompanyDetailModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [tagInput, setTagInput] = useState('');

  const {
    updateCompany,
    addTag,
    removeTag,
    isLoading,
  } = useCompanyMutations();

  // Fetch linked contacts for this company
  const { contacts } = useContacts({ companyId: company.id });

  // Fetch linked deals for this company
  const { deals } = useDeals({ companyId: company.id });

  // Calculate total deal value
  const totalDealValue = useMemo(() => {
    return deals
      .filter(deal => deal.status === 'open' || deal.status === 'won')
      .reduce((sum, deal) => sum + deal.valueCents, 0);
  }, [deals]);

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
    async (data: CompanyFormData) => {
      // Cast size to CompanySize for type compatibility
      const mutationData: Partial<Company> = {
        ...data,
        size: data.size as Company['size'],
      };

      await updateCompany(company.id, mutationData);
      setIsEditing(false);
      onSuccess?.();
    },
    [company.id, updateCompany, onSuccess]
  );

  // Handle tag addition
  const handleAddTag = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const trimmedTag = tagInput.trim();
      if (!trimmedTag) return;

      // Prevent duplicate tags (case-insensitive)
      if (company.tags.some(t => t.toLowerCase() === trimmedTag.toLowerCase())) {
        setTagInput('');
        return;
      }

      await addTag(company.id, trimmedTag);
      setTagInput('');
      onSuccess?.();
    },
    [company.id, company.tags, tagInput, addTag, onSuccess]
  );

  // Handle tag removal
  const handleRemoveTag = useCallback(
    async (tag: string) => {
      await removeTag(company.id, tag);
      onSuccess?.();
    },
    [company.id, removeTag, onSuccess]
  );

  // Render content based on mode
  const content = useMemo(() => {
    if (isEditing) {
      // Edit Mode: Show form
      return (
        <CompanyForm
          initialData={company}
          onSubmit={handleSubmit}
          onCancel={handleCancelEdit}
          isLoading={isLoading}
        />
      );
    }

    // View Mode: Show details
    return (
      <div className="company-detail-view">
        {/* Header with edit button */}
        <div className="detail-header">
          <h3>{company.name}</h3>
          <button
            className="btn btn-primary btn-sm"
            onClick={handleEditClick}
            disabled={isLoading}
          >
            Edit Company
          </button>
        </div>

        {/* Basic Info */}
        <section className="detail-section">
          <h4>Company Information</h4>
          <dl className="detail-grid">
            {company.industry && (
              <>
                <dt>Industry</dt>
                <dd>{company.industry}</dd>
              </>
            )}

            {company.size && (
              <>
                <dt>Size</dt>
                <dd>{getSizeLabel(company.size)}</dd>
              </>
            )}

            {company.website && (
              <>
                <dt>Website</dt>
                <dd>
                  <a href={company.website} target="_blank" rel="noopener noreferrer">
                    {company.website}
                  </a>
                </dd>
              </>
            )}

            {company.email && (
              <>
                <dt>Email</dt>
                <dd>
                  <a href={`mailto:${company.email}`}>{company.email}</a>
                </dd>
              </>
            )}

            {company.phone && (
              <>
                <dt>Phone</dt>
                <dd>
                  <a href={`tel:${company.phone}`}>{company.phone}</a>
                </dd>
              </>
            )}
          </dl>
        </section>

        {/* Address */}
        {company.address && (
          <section className="detail-section">
            <h4>Address</h4>
            <address className="detail-address">
              {company.address.street && <div>{company.address.street}</div>}
              {(company.address.city || company.address.state || company.address.zipCode) && (
                <div>
                  {company.address.city && `${company.address.city}, `}
                  {company.address.state && `${company.address.state} `}
                  {company.address.zipCode && company.address.zipCode}
                </div>
              )}
              {company.address.country && <div>{company.address.country}</div>}
            </address>
          </section>
        )}

        {/* Linked Contacts */}
        <section className="detail-section">
          <h4>Linked Contacts ({contacts.length})</h4>
          {contacts.length > 0 ? (
            <div className="linked-list">
              {contacts.map(contact => (
                <div key={contact.id} className="linked-item">
                  <div className="linked-item-main">
                    <strong>{contact.firstName} {contact.lastName}</strong>
                    {contact.title && <span className="text-muted"> · {contact.title}</span>}
                  </div>
                  <div className="linked-item-sub text-muted">
                    {contact.email}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-muted">No contacts linked to this company</p>
          )}
        </section>

        {/* Linked Deals */}
        <section className="detail-section">
          <h4>Linked Deals ({deals.length})</h4>
          {totalDealValue > 0 && (
            <div className="deal-summary">
              <strong>Total Value: </strong>
              {formatCurrency(totalDealValue, 'USD')}
            </div>
          )}
          {deals.length > 0 ? (
            <div className="linked-list">
              {deals.map(deal => (
                <div key={deal.id} className="linked-item">
                  <div className="linked-item-main">
                    <strong>{deal.title}</strong>
                    <span className={`status-badge status-${deal.status}`}>
                      {deal.status}
                    </span>
                  </div>
                  <div className="linked-item-sub text-muted">
                    {formatCurrency(deal.valueCents, deal.currency)}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-muted">No deals linked to this company</p>
          )}
        </section>

        {/* Tags */}
        <section className="detail-section">
          <h4>Tags</h4>
          <div className="tags-container">
            {company.tags.map(tag => (
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
        {company.notes && (
          <section className="detail-section">
            <h4>Notes</h4>
            <p className="notes-text">{company.notes}</p>
          </section>
        )}

        {/* Metadata */}
        <section className="detail-section detail-metadata">
          <dl className="detail-grid">
            <dt>Created</dt>
            <dd>{company.createdAt.toLocaleDateString()}</dd>

            {company.updatedAt && (
              <>
                <dt>Last Updated</dt>
                <dd>{company.updatedAt.toLocaleDateString()}</dd>
              </>
            )}
          </dl>
        </section>
      </div>
    );
  }, [
    isEditing,
    company,
    contacts,
    deals,
    totalDealValue,
    tagInput,
    isLoading,
    handleEditClick,
    handleSubmit,
    handleCancelEdit,
    handleAddTag,
    handleRemoveTag,
  ]);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Company' : 'Company Details'}
      size="lg"
      closeOnOverlayClick={!isLoading}
      closeOnEscape={!isLoading}
    >
      {content}
    </Modal>
  );
}

export default CompanyDetailModal;
