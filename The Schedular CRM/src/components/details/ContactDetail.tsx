/**
 * ContactDetail Component
 * Contact detail view with contact info, company link, and related deals
 *
 * Agent CRM-17 Implementation
 */

import { DetailHeader } from './DetailHeader';
import { DetailSection } from './DetailSection';
import { DetailTabs, type DetailTabConfig } from './DetailTabs';
import { RelatedList } from './RelatedList';
import { ActivityTimeline } from './ActivityTimeline';
import { useCalendarSync, useContact, useTimeline, useDeals } from '../../hooks';
import { useActivityLog } from '../../hooks/useActivityLog';
import { getTaskTemplates, getDefaultTaskTemplate } from '../../config/taskTemplates';
import { AppointmentList, AIInsightsCard, CommHistory, UpcomingAppointments } from '../scheduler';
import { EmailList } from '../email/EmailList';
import { EmailComposer } from '../email/EmailComposer';
import { getFeatureFlags } from '../../config/features';
import type { Client, Deal } from '../../types/models';
import './details.css';

// ============================================
// Types
// ============================================

export interface ContactDetailProps {
  /** Contact ID */
  contactId: string;
  /** Called when edit is requested */
  onEdit?: (contact: Client) => void;
  /** Called when create deal is requested */
  onCreateDeal?: (contact: Client) => void;
  /** Called when delete is requested */
  onDelete?: (contact: Client) => void;
  /** Called when log activity is requested */
  onLogActivity?: () => void;
  /** Whether inline logging is permitted */
  canLogActivity?: boolean;
  /** Called when back button is clicked */
  onBack?: () => void;
  /** Called when company link is clicked */
  onCompanyClick?: (companyId: string) => void;
  /** Called when deal link is clicked */
  onDealClick?: (dealId: string) => void;
}

// ============================================
// Helpers
// ============================================

function getLifecycleBadgeVariant(
  lifecycle?: Client['lifecycle']
): 'default' | 'primary' | 'success' | 'warning' | 'danger' {
  if (!lifecycle) return 'default';
  const variants = {
    lead: 'primary' as const,
    prospect: 'warning' as const,
    active: 'success' as const,
    inactive: 'default' as const,
    churned: 'danger' as const,
  };
  return variants[lifecycle] || 'default';
}

function formatCurrency(cents: number, currency: string): string {
  const dollars = cents / 100;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(dollars);
}

function formatDate(value?: Date): string {
  return value ? new Date(value).toLocaleDateString() : 'Not set';
}

// ============================================
// Component
// ============================================

/**
 * ContactDetail - Contact detail view
 *
 * @example
 * ```tsx
 * <ContactDetail
 *   contactId="contact123"
 *   onEdit={handleEdit}
 *   onCreateDeal={handleCreateDeal}
 *   onDelete={handleDelete}
 *   onLogActivity={() => setShowModal(true)}
 *   onBack={() => navigate('/contacts')}
 * />
 * ```
 */
export function ContactDetail({
  contactId,
  onEdit,
  onCreateDeal,
  onDelete,
  onLogActivity,
  canLogActivity = true,
  onBack,
  onCompanyClick,
  onDealClick,
}: ContactDetailProps) {
  const features = getFeatureFlags();
  const calendarSync = useCalendarSync({
    loadConnections: features.enableCalendarSync,
    loadMappings: features.enableCalendarSync,
  });
  const { contact, isLoading: contactLoading } = useContact(contactId);
  const {
    activities,
    isLoading: activitiesLoading,
    refresh: refreshTimeline,
  } = useTimeline({
    entityType: 'client',
    entityId: contactId,
  });
  const {
    logNote,
    createTask,
    completeTask,
    uncompleteTask,
    updateActivity,
    isLoading: isLoggingActivities,
  } = useActivityLog();

  // Fetch related deals
  const { deals, isLoading: dealsLoading } = useDeals({
    clientId: contactId,
  });

  if (contactLoading) {
    return (
      <div className="detail-view">
        <div className="detail-view__loading">Loading contact...</div>
      </div>
    );
  }

  if (!contact) {
    return (
      <div className="detail-view">
        <div className="detail-view__error">Contact not found</div>
      </div>
    );
  }

  const fullName = `${contact.firstName} ${contact.lastName}`;

  const badges = contact.lifecycle
    ? [{ label: contact.lifecycle, variant: getLifecycleBadgeVariant(contact.lifecycle) }]
    : [];

  const actions = [
    ...(onEdit
      ? [{ label: 'Edit', onClick: () => onEdit(contact), variant: 'secondary' as const }]
      : []),
    ...(onCreateDeal
      ? [{ label: 'Create Opportunity', onClick: () => onCreateDeal(contact), variant: 'primary' as const }]
      : []),
    ...(onDelete
      ? [{ label: 'Delete', onClick: () => onDelete(contact), variant: 'danger' as const }]
      : []),
  ];

  // Map deals to related items
  const relatedDeals = deals.map((deal: Deal) => ({
    id: deal.id,
    title: deal.title,
    subtitle: formatCurrency(deal.valueCents, deal.currency),
    metadata: deal.status,
    onClick: onDealClick ? () => onDealClick(deal.id) : undefined,
  }));
  const activeDealCount = deals.filter((deal) => deal.status === 'open').length;
  const totalOpportunityValue = deals.reduce((sum, deal) => sum + deal.valueCents, 0);
  const totalOpportunityCurrency = deals.find((deal) => deal.currency)?.currency ?? 'USD';

  const overviewTab: DetailTabConfig = {
    id: 'overview',
    label: 'Overview',
    content: (
      <div className="detail-overview-stack">
        <div className="detail-metric-grid">
          <div className="detail-metric-card">
            <span className="detail-metric__label">Lifecycle</span>
            <strong className="detail-metric__value">
              {contact.lifecycle ? `${contact.lifecycle[0].toUpperCase()}${contact.lifecycle.slice(1)}` : 'Unassigned'}
            </strong>
            <span className="detail-metric__meta">
              {contact.leadStatus ?? 'No lead status set'}
            </span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Company</span>
            <strong className="detail-metric__value">
              {contact.companyName ?? 'Independent'}
            </strong>
            <span className="detail-metric__meta">{contact.title ?? 'No title added'}</span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Opportunity Value</span>
            <strong className="detail-metric__value">
              {formatCurrency(totalOpportunityValue, totalOpportunityCurrency)}
            </strong>
            <span className="detail-metric__meta">
              {deals.length} opportunities, {activeDealCount} open
            </span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Last Contact</span>
            <strong className="detail-metric__value">
              {contact.lastContactedAt ? formatDate(contact.lastContactedAt) : 'Not logged'}
            </strong>
            <span className="detail-metric__meta">Created {formatDate(contact.createdAt)}</span>
          </div>
        </div>

        <div className="detail-grid detail-grid--two">
          <DetailSection title="Contact Information">
            <div className="detail-info">
              <div className="detail-info__row">
                <span className="detail-info__label">Email:</span>
                <span className="detail-info__value">
                  <a href={`mailto:${contact.email}`}>{contact.email}</a>
                </span>
              </div>
              {contact.phone && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Phone:</span>
                  <span className="detail-info__value">
                    <a href={`tel:${contact.phone}`}>{contact.phone}</a>
                  </span>
                </div>
              )}
              {contact.title && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Title:</span>
                  <span className="detail-info__value">{contact.title}</span>
                </div>
              )}
              {contact.companyName && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Company:</span>
                  <span className="detail-info__value">
                    {onCompanyClick && contact.companyId ? (
                      <button
                        type="button"
                        className="detail-link"
                        onClick={() => onCompanyClick(contact.companyId!)}
                      >
                        {contact.companyName}
                      </button>
                    ) : (
                      contact.companyName
                    )}
                  </span>
                </div>
              )}
            </div>
          </DetailSection>

          <DetailSection title="Relationship Details">
            <div className="detail-info">
              {contact.assignedRepName && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Assigned Rep:</span>
                  <span className="detail-info__value">{contact.assignedRepName}</span>
                </div>
              )}
              {contact.leadSource && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Lead Source:</span>
                  <span className="detail-info__value">{contact.leadSource}</span>
                </div>
              )}
              <div className="detail-info__row">
                <span className="detail-info__label">Created:</span>
                <span className="detail-info__value">{formatDate(contact.createdAt)}</span>
              </div>
              {contact.lastContactedAt && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Last Contacted:</span>
                  <span className="detail-info__value">
                    {formatDate(contact.lastContactedAt)}
                  </span>
                </div>
              )}
              {contact.tags.length > 0 && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Tags:</span>
                  <span className="detail-info__value">
                    <div className="detail-tags">
                      {contact.tags.map((tag) => (
                        <span key={tag} className="detail-tag">
                          {tag}
                        </span>
                      ))}
                    </div>
                  </span>
                </div>
              )}
            </div>
          </DetailSection>
        </div>

        {contact.address && (
          <DetailSection title="Address">
            <div className="detail-info">
              <div className="detail-info__row">
                <span className="detail-info__label">Street:</span>
                <span className="detail-info__value">
                  {contact.address.street ?? 'Not provided'}
                </span>
              </div>
              <div className="detail-info__row">
                <span className="detail-info__label">City/State:</span>
                <span className="detail-info__value">
                  {[contact.address.city, contact.address.state].filter(Boolean).join(', ') || 'Not provided'}
                </span>
              </div>
              {contact.address.zipCode && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Zip Code:</span>
                  <span className="detail-info__value">{contact.address.zipCode}</span>
                </div>
              )}
              {contact.address.country && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Country:</span>
                  <span className="detail-info__value">{contact.address.country}</span>
                </div>
              )}
            </div>
          </DetailSection>
        )}

        {contact.crmNotes && (
          <DetailSection title="Notes">
            <div className="detail-notes">{contact.crmNotes}</div>
          </DetailSection>
        )}

        <DetailSection title={`Related Opportunities (${relatedDeals.length})`}>
          <RelatedList
            items={relatedDeals}
            isLoading={dealsLoading}
            emptyMessage="No opportunities associated with this contact"
            onCreateNew={onCreateDeal ? () => onCreateDeal(contact) : undefined}
            createLabel="Create Opportunity"
          />
        </DetailSection>

        <div className="detail-grid detail-grid--two">
          <DetailSection title="Appointments">
            <AppointmentList clientId={contactId} />
          </DetailSection>

          <DetailSection title="Communication History">
            <CommHistory clientId={contactId} />
          </DetailSection>
        </div>
      </div>
    ),
  };

  const tabs: DetailTabConfig[] = [overviewTab];

  if (features.enableEmailIntegration) {
    tabs.push({
      id: 'email',
      label: 'Email',
      content: (
        <DetailSection title="Email (Beta)">
          <EmailList entityType="client" entityId={contact.id} />
          <EmailComposer
            defaultTo={contact.email}
            associatedEntity={{ type: 'client', id: contact.id }}
          />
        </DetailSection>
      ),
    });
  }

  return (
    <div className="detail-view">
      <DetailHeader
        title={fullName}
        subtitle={contact.email}
        badges={badges}
        actions={actions}
        onBack={onBack}
      />

      <div className="detail-view__content">
        <div className="detail-view__main">
          <DetailTabs tabs={tabs} />
        </div>

        <div className="detail-view__sidebar">
          <DetailSection title="Upcoming Appointments">
            <UpcomingAppointments clientId={contactId} compact />
          </DetailSection>

          <DetailSection title="AI Insights">
            <AIInsightsCard clientId={contactId} />
          </DetailSection>

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
                      await logNote(contact.id, 'client', note);
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
                        dueDate: resolvedDue,
                        clientId: contact.id,
                        companyId: contact.companyId,
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
              taskTemplates={getTaskTemplates(contact.lifecycle)}
              defaultTemplateId={getDefaultTaskTemplate(contact.lifecycle)?.id}
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

export default ContactDetail;
