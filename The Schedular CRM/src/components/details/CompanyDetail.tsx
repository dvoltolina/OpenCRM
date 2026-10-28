/**
 * CompanyDetail Component
 * Company detail view with contact info, contacts list, and related deals
 *
 * Agent CRM-17 Implementation
 */

import { DetailHeader } from './DetailHeader';
import { DetailSection } from './DetailSection';
import { RelatedList } from './RelatedList';
import { ActivityTimeline } from './ActivityTimeline';
import { useCalendarSync, useCompany, useTimeline, useContacts, useDeals } from '../../hooks';
import { useActivityLog } from '../../hooks/useActivityLog';
import { getTaskTemplates, getDefaultTaskTemplate } from '../../config/taskTemplates';
import type { Company, Client, Deal } from '../../types/models';
import './details.css';

// ============================================
// Types
// ============================================

export interface CompanyDetailProps {
  /** Company ID */
  companyId: string;
  /** Called when edit is requested */
  onEdit?: (company: Company) => void;
  /** Called when create contact is requested */
  onCreateContact?: (company: Company) => void;
  /** Called when delete is requested */
  onDelete?: (company: Company) => void;
  /** Called when log activity is requested */
  onLogActivity?: () => void;
  /** Whether inline logging is permitted */
  canLogActivity?: boolean;
  /** Called when back button is clicked */
  onBack?: () => void;
  /** Called when contact link is clicked */
  onContactClick?: (contactId: string) => void;
  /** Called when deal link is clicked */
  onDealClick?: (dealId: string) => void;
}

// ============================================
// Helpers
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

function formatDate(value?: Date): string {
  return value ? new Date(value).toLocaleDateString() : 'Not set';
}

// ============================================
// Component
// ============================================

/**
 * CompanyDetail - Company detail view
 *
 * @example
 * ```tsx
 * <CompanyDetail
 *   companyId="company123"
 *   onEdit={handleEdit}
 *   onCreateContact={handleCreateContact}
 *   onDelete={handleDelete}
 *   onLogActivity={() => setShowModal(true)}
 *   onBack={() => navigate('/companies')}
 * />
 * ```
 */
export function CompanyDetail({
  companyId,
  onEdit,
  onCreateContact,
  onDelete,
  onLogActivity,
  canLogActivity = true,
  onBack,
  onContactClick,
  onDealClick,
}: CompanyDetailProps) {
  const { company, isLoading: companyLoading } = useCompany(companyId);
  const {
    activities,
    isLoading: activitiesLoading,
    refresh: refreshTimeline,
  } = useTimeline({
    entityType: 'company',
    entityId: companyId,
  });
  const {
    logNote,
    createTask,
    completeTask,
    uncompleteTask,
    updateActivity,
    isLoading: isLoggingActivities,
  } = useActivityLog();

  // Fetch related contacts
  const { contacts, isLoading: contactsLoading } = useContacts({
    companyId: companyId,
  });

  // Fetch related deals
  const { deals, isLoading: dealsLoading } = useDeals({
    companyId: companyId,
  });
  const calendarSync = useCalendarSync();

  if (companyLoading) {
    return (
      <div className="detail-view">
        <div className="detail-view__loading">Loading company...</div>
      </div>
    );
  }

  if (!company) {
    return (
      <div className="detail-view">
        <div className="detail-view__error">Company not found</div>
      </div>
    );
  }

  const badges = [
    ...(company.industry ? [{ label: company.industry, variant: 'default' as const }] : []),
    ...(company.size ? [{ label: getSizeLabel(company.size), variant: 'default' as const }] : []),
  ];

  const actions = [
    ...(onEdit
      ? [{ label: 'Edit', onClick: () => onEdit(company), variant: 'secondary' as const }]
      : []),
    ...(onCreateContact
      ? [
          {
            label: 'Create Contact',
            onClick: () => onCreateContact(company),
            variant: 'primary' as const,
          },
        ]
      : []),
    ...(onDelete
      ? [{ label: 'Delete', onClick: () => onDelete(company), variant: 'danger' as const }]
      : []),
  ];

  // Map contacts to related items
  const relatedContacts = contacts.map((contact: Client) => ({
    id: contact.id,
    title: `${contact.firstName} ${contact.lastName}`,
    subtitle: contact.email,
    metadata: contact.title || undefined,
    onClick: onContactClick ? () => onContactClick(contact.id) : undefined,
  }));

  // Map deals to related items
  const relatedDeals = deals.map((deal: Deal) => ({
    id: deal.id,
    title: deal.title,
    subtitle: formatCurrency(deal.valueCents, deal.currency),
    metadata: deal.status,
    onClick: onDealClick ? () => onDealClick(deal.id) : undefined,
  }));

  // Calculate total deal value
  const totalDealValue = deals
    .filter((deal: Deal) => deal.status === 'open' || deal.status === 'won')
    .reduce((sum: number, deal: Deal) => sum + deal.valueCents, 0);
  const activeDealCount = deals.filter((deal) => deal.status === 'open').length;
  const dealCurrency = deals.find((deal) => deal.currency)?.currency ?? 'USD';

  return (
    <div className="detail-view">
      <DetailHeader
        title={company.name}
        subtitle={company.website}
        badges={badges}
        actions={actions}
        onBack={onBack}
      />

      <div className="detail-view__content">
        <div className="detail-view__main">
          <div className="detail-overview-stack">
            <div className="detail-metric-grid">
              <div className="detail-metric-card">
                <span className="detail-metric__label">Industry</span>
                <strong className="detail-metric__value">{company.industry ?? 'General'}</strong>
                <span className="detail-metric__meta">{getSizeLabel(company.size) || 'Size not set'}</span>
              </div>
              <div className="detail-metric-card">
                <span className="detail-metric__label">Contacts</span>
                <strong className="detail-metric__value">{contacts.length}</strong>
                <span className="detail-metric__meta">
                  {contacts.length === 1 ? 'Primary relationship' : 'Active stakeholders'}
                </span>
              </div>
              <div className="detail-metric-card">
                <span className="detail-metric__label">Opportunities</span>
                <strong className="detail-metric__value">{deals.length}</strong>
                <span className="detail-metric__meta">{activeDealCount} open opportunities</span>
              </div>
              <div className="detail-metric-card">
                <span className="detail-metric__label">Pipeline Value</span>
                <strong className="detail-metric__value">
                  {formatCurrency(totalDealValue, dealCurrency)}
                </strong>
                <span className="detail-metric__meta">Created {formatDate(company.createdAt)}</span>
              </div>
            </div>

            <div className="detail-grid detail-grid--two">
              <DetailSection title="Company Information">
                <div className="detail-info">
                  {company.website && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Website:</span>
                      <span className="detail-info__value">
                        <a href={company.website} target="_blank" rel="noopener noreferrer">
                          {company.website}
                        </a>
                      </span>
                    </div>
                  )}
                  {company.phone && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Phone:</span>
                      <span className="detail-info__value">
                        <a href={`tel:${company.phone}`}>{company.phone}</a>
                      </span>
                    </div>
                  )}
                  {company.email && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Email:</span>
                      <span className="detail-info__value">
                        <a href={`mailto:${company.email}`}>{company.email}</a>
                      </span>
                    </div>
                  )}
                  {company.industry && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Industry:</span>
                      <span className="detail-info__value">{company.industry}</span>
                    </div>
                  )}
                  {company.size && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Size:</span>
                      <span className="detail-info__value">{getSizeLabel(company.size)}</span>
                    </div>
                  )}
                </div>
              </DetailSection>

              <DetailSection title={company.address ? 'Address' : 'Additional Details'}>
                <div className="detail-info">
                  {company.address?.street && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Street:</span>
                      <span className="detail-info__value">{company.address.street}</span>
                    </div>
                  )}
                  <div className="detail-info__row">
                    <span className="detail-info__label">City/State:</span>
                    <span className="detail-info__value">
                      {[company.address?.city, company.address?.state].filter(Boolean).join(', ') || 'Not provided'}
                    </span>
                  </div>
                  {company.address?.zipCode && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Zip Code:</span>
                      <span className="detail-info__value">{company.address.zipCode}</span>
                    </div>
                  )}
                  {company.address?.country && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Country:</span>
                      <span className="detail-info__value">{company.address.country}</span>
                    </div>
                  )}
                  {company.tags.length > 0 && (
                    <div className="detail-info__row">
                      <span className="detail-info__label">Tags:</span>
                      <span className="detail-info__value">
                        <div className="detail-tags">
                          {company.tags.map((tag) => (
                            <span key={tag} className="detail-tag">
                              {tag}
                            </span>
                          ))}
                        </div>
                      </span>
                    </div>
                  )}
                  <div className="detail-info__row">
                    <span className="detail-info__label">Created:</span>
                    <span className="detail-info__value">{formatDate(company.createdAt)}</span>
                  </div>
                </div>
              </DetailSection>
            </div>

            {company.notes && (
              <DetailSection title="Notes">
                <div className="detail-notes">{company.notes}</div>
              </DetailSection>
            )}

            <div className="detail-grid detail-grid--two">
              <DetailSection title={`Contacts (${contacts.length})`}>
                <RelatedList
                  items={relatedContacts}
                  isLoading={contactsLoading}
                  emptyMessage="No contacts at this company"
                  onCreateNew={onCreateContact ? () => onCreateContact(company) : undefined}
                  createLabel="Add Contact"
                />
              </DetailSection>

              <DetailSection title={`Opportunities (${deals.length})`}>
                {totalDealValue > 0 && (
                  <div className="detail-summary">
                    <span className="detail-summary__label">Open + won pipeline</span>
                    <span className="detail-summary__value">
                      {formatCurrency(totalDealValue, dealCurrency)}
                    </span>
                  </div>
                )}
                <RelatedList
                  items={relatedDeals}
                  isLoading={dealsLoading}
                  emptyMessage="No deals associated with this company"
                  createLabel="View All Deals"
                />
              </DetailSection>
            </div>
          </div>
        </div>

        <div className="detail-view__sidebar">
          <DetailSection title="Activity Timeline">
            <ActivityTimeline
              activities={activities}
              isLoading={activitiesLoading}
              onLogActivity={onLogActivity}
              emptyMessage="No activities logged yet"
              onToggleTask={
                canLogActivity
                  ? async (activityId, nextCompleted) => {
                      if (nextCompleted) {
                        await completeTask(activityId);
                      } else {
                        await uncompleteTask(activityId);
                      }
                      refreshTimeline();
                    }
                  : undefined
              }
              onQuickNote={
                canLogActivity
                  ? async (note: string) => {
                      await logNote(company.id, 'company', note);
                      refreshTimeline();
                    }
                  : undefined
              }
              onQuickTask={
                canLogActivity
                  ? async ({
                      title,
                      dueDate,
                      templateId,
                      slaMinutes,
                      slaAt,
                      reminderAt,
                    }) => {
                      const resolvedDue = dueDate || new Date(Date.now() + 24 * 60 * 60 * 1000);
                      await createTask({
                        title,
                        companyId: company.id,
                        dueDate: resolvedDue,
                        templateId,
                        slaMinutes,
                        slaAt,
                        reminderAt,
                      });
                      refreshTimeline();
                    }
                  : undefined
              }
              onUpdateTask={
                canLogActivity
                  ? async (activityId, updates) => {
                      await updateActivity(activityId, updates);
                      refreshTimeline();
                    }
                  : undefined
              }
              taskTemplates={getTaskTemplates(company.industry)}
              defaultTemplateId={getDefaultTaskTemplate(company.industry)?.id}
              isMutating={isLoggingActivities}
              calendarEnabled={calendarSync.enabled}
              calendarStatuses={calendarSync.activityStatuses}
              onAddToCalendar={
                calendarSync.enabled ? async (activityId) => calendarSync.syncActivity(activityId) : undefined
              }
              onResolveCalendarConflict={
                calendarSync.enabled
                  ? async (mappingId) => calendarSync.resolveConflict(mappingId, 'use_crm')
                  : undefined
              }
            />
          </DetailSection>
        </div>
      </div>
    </div>
  );
}

export default CompanyDetail;
