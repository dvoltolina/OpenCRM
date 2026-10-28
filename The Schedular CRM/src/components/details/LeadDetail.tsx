/**
 * LeadDetail Component
 * Lead detail view with contact info, status, and activities
 *
 * Agent CRM-17 Implementation
 */

import { DetailHeader } from './DetailHeader';
import { DetailSection } from './DetailSection';
import { DetailTabs, type DetailTabConfig } from './DetailTabs';
import { ActivityTimeline } from './ActivityTimeline';
import { useCalendarSync, useDocuments, useLead, useTimeline } from '../../hooks';
import { useActivityLog } from '../../hooks/useActivityLog';
import { getTaskTemplates, getDefaultTaskTemplate } from '../../config/taskTemplates';
import { getFeatureFlags } from '../../config/features';
import { EmailList } from '../email/EmailList';
import { EmailComposer } from '../email/EmailComposer';
import { DocumentList } from '../documents/DocumentList';
import { DocumentUploader } from '../documents/DocumentUploader';
import type { Lead } from '../../types/models';
import './details.css';

// ============================================
// Types
// ============================================

export interface LeadDetailProps {
  /** Lead ID */
  leadId: string;
  /** Called when edit is requested */
  onEdit?: (lead: Lead) => void;
  /** Called when convert is requested */
  onConvert?: (lead: Lead) => void;
  /** Called when delete is requested */
  onDelete?: (lead: Lead) => void;
  /** Called when log activity is requested */
  onLogActivity?: () => void;
  /** Whether inline logging is permitted */
  canLogActivity?: boolean;
  /** Called when back button is clicked */
  onBack?: () => void;
}

// ============================================
// Helpers
// ============================================

function getStatusBadgeVariant(
  status: Lead['status']
): 'default' | 'primary' | 'success' | 'warning' | 'danger' {
  const variants = {
    new: 'primary' as const,
    contacted: 'warning' as const,
    qualified: 'success' as const,
    unqualified: 'danger' as const,
    converted: 'success' as const,
  };
  return variants[status] || 'default';
}

function getSourceLabel(source: Lead['source']): string {
  const labels: Record<Lead['source'], string> = {
    website: 'Website',
    referral: 'Referral',
    coldCall: 'Cold Call',
    social: 'Social Media',
    event: 'Event',
    scheduler: 'Scheduler',
    other: 'Other',
  };
  return labels[source] || source;
}

// ============================================
// Component
// ============================================

/**
 * LeadDetail - Lead detail view
 *
 * @example
 * ```tsx
 * <LeadDetail
 *   leadId="lead123"
 *   onEdit={handleEdit}
 *   onConvert={handleConvert}
 *   onDelete={handleDelete}
 *   onLogActivity={() => setShowModal(true)}
 *   onBack={() => navigate('/leads')}
 * />
 * ```
 */
export function LeadDetail({
  leadId,
  onEdit,
  onConvert,
  onDelete,
  onLogActivity,
  canLogActivity = true,
  onBack,
}: LeadDetailProps) {
  const features = getFeatureFlags();
  const { lead, isLoading: leadLoading } = useLead(leadId);
  const {
    activities,
    isLoading: activitiesLoading,
    refresh: refreshTimeline,
  } = useTimeline({
    entityType: 'lead',
    entityId: leadId,
  });
  const {
    logNote,
    createTask,
    completeTask,
    uncompleteTask,
    updateActivity,
    isLoading: isLoggingActivities,
  } = useActivityLog();
  const {
    documents: leadDocuments,
    isLoading: leadDocumentsLoading,
    uploadDocument: uploadLeadDocument,
    refreshDocuments: refreshLeadDocuments,
  } = useDocuments({
    entityType: 'lead',
    entityId: leadId,
    autoLoad: features.enableDocuments,
  });
  const calendarSync = useCalendarSync({
    loadConnections: features.enableCalendarSync,
    loadMappings: features.enableCalendarSync,
  });

  if (leadLoading) {
    return (
      <div className="detail-view">
        <div className="detail-view__loading">Loading lead...</div>
      </div>
    );
  }

  if (!lead) {
    return (
      <div className="detail-view">
        <div className="detail-view__error">Lead not found</div>
      </div>
    );
  }

  const fullName = `${lead.firstName} ${lead.lastName}`;

  const badges = [
    { label: lead.status, variant: getStatusBadgeVariant(lead.status) },
    { label: getSourceLabel(lead.source), variant: 'default' as const },
  ];

  const actions = [
    ...(onEdit ? [{ label: 'Edit', onClick: () => onEdit(lead), variant: 'secondary' as const }] : []),
    ...(onConvert && lead.status !== 'converted'
      ? [{ label: 'Convert', onClick: () => onConvert(lead), variant: 'primary' as const }]
      : []),
    ...(onDelete
      ? [{ label: 'Delete', onClick: () => onDelete(lead), variant: 'danger' as const }]
      : []),
  ];

  const overviewTab: DetailTabConfig = {
    id: 'overview',
    label: 'Overview',
    content: (
      <>
        <DetailSection title="Contact Information">
          <div className="detail-info">
            <div className="detail-info__row">
              <span className="detail-info__label">Email:</span>
              <span className="detail-info__value">
                <a href={`mailto:${lead.email}`}>{lead.email}</a>
              </span>
            </div>
            {lead.phone && (
              <div className="detail-info__row">
                <span className="detail-info__label">Phone:</span>
                <span className="detail-info__value">
                  <a href={`tel:${lead.phone}`}>{lead.phone}</a>
                </span>
              </div>
            )}
            {lead.companyName && (
              <div className="detail-info__row">
                <span className="detail-info__label">Company:</span>
                <span className="detail-info__value">{lead.companyName}</span>
              </div>
            )}
            {lead.title && (
              <div className="detail-info__row">
                <span className="detail-info__label">Title:</span>
                <span className="detail-info__value">{lead.title}</span>
              </div>
            )}
          </div>
        </DetailSection>

        <DetailSection title="Lead Details">
          <div className="detail-info">
            {lead.assigneeName && (
              <div className="detail-info__row">
                <span className="detail-info__label">Assignee:</span>
                <span className="detail-info__value">{lead.assigneeName}</span>
              </div>
            )}
            {lead.score !== undefined && (
              <div className="detail-info__row">
                <span className="detail-info__label">Score:</span>
                <span className="detail-info__value">{lead.score}/100</span>
              </div>
            )}
            {lead.tags.length > 0 && (
              <div className="detail-info__row">
                <span className="detail-info__label">Tags:</span>
                <span className="detail-info__value">
                  <div className="detail-tags">
                    {lead.tags.map((tag) => (
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
              <span className="detail-info__value">
                {lead.createdAt.toLocaleDateString()}
              </span>
            </div>
          </div>
        </DetailSection>

        {lead.notes && (
          <DetailSection title="Notes">
            <div className="detail-notes">{lead.notes}</div>
          </DetailSection>
        )}
      </>
    ),
  };

  const documentsTab: DetailTabConfig | null = features.enableDocuments
    ? {
        id: 'documents',
        label: 'Documents',
        content: (
          <DetailSection title="Documents">
            <DocumentUploader
              associatedEntity={{ type: 'lead', id: lead.id }}
              onUpload={async (file, { name, documentType }) => {
                await uploadLeadDocument(file, {
                  name,
                  documentType,
                  associatedEntity: { type: 'lead', id: lead.id },
                });
              }}
            />
            <DocumentList
              documents={leadDocuments}
              isLoading={leadDocumentsLoading}
              onRefresh={refreshLeadDocuments}
              emptyMessage="Link lead files from the Documents hub to see them here."
            />
          </DetailSection>
        ),
      }
    : null;

  const tabs: DetailTabConfig[] = [overviewTab];

  if (documentsTab) {
    tabs.push(documentsTab);
  }

  if (features.enableEmailIntegration) {
    tabs.push({
      id: 'email',
      label: 'Email',
      content: (
        <DetailSection title="Email (Beta)">
          <EmailList entityType="lead" entityId={lead.id} />
          <EmailComposer
            defaultTo={lead.email}
            associatedEntity={{ type: 'lead', id: lead.id }}
          />
        </DetailSection>
      ),
    });
  }

  return (
    <div className="detail-view">
      <DetailHeader
        title={fullName}
        subtitle={lead.email}
        badges={badges}
        actions={actions}
        onBack={onBack}
      />

      <div className="detail-view__content">
        <div className="detail-view__main">
          <DetailTabs tabs={tabs} />
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
                      await logNote(lead.id, 'lead', note);
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
                        leadId: lead.id,
                        dealId: lead.convertedToDealId,
                        clientId: lead.convertedToClientId,
                        dueDate: resolvedDue,
                        assigneeId: lead.assigneeId,
                        assigneeName: lead.assigneeName,
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
              taskTemplates={getTaskTemplates(lead.status)}
              defaultTemplateId={getDefaultTaskTemplate(lead.status)?.id}
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

export default LeadDetail;
