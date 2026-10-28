/**
 * DealDetail Component
 * Deal detail view with pipeline stage, value, and activities
 *
 * Agent CRM-17 Implementation
 * Phase 3: Added sequence enrollment section
 */

import { useState } from 'react';
import { DetailHeader } from './DetailHeader';
import { DetailSection } from './DetailSection';
import { DetailTabs, type DetailTabConfig } from './DetailTabs';
import { ActivityTimeline } from './ActivityTimeline';
import { useCalendarSync, useDeal, useDocuments, useTimeline, usePipelineWithStages } from '../../hooks';
import { useActivityLog } from '../../hooks/useActivityLog';
import { useEntitySequenceStatus } from '../../hooks/useEntitySequenceStatus';
import { getDefaultTaskTemplate, getTaskTemplates } from '../../config/taskTemplates';
import { getFeatureFlags } from '../../config/features';
import { EntitySequenceHistory } from '../sequences/EntitySequenceHistory';
import { EnrollmentModal } from '../sequences/EnrollmentModal';
import { AIInsightsCard, AppointmentList, CommHistory, UpcomingAppointments } from '../scheduler';
import type { Deal } from '../../types/models';
import type { SequenceEnrollment } from '../../types/sequences';
import { DealDocumentsTab } from './DealDocumentsTab';
import './details.css';

// ============================================
// Types
// ============================================

export interface DealDetailProps {
  /** Deal ID */
  dealId: string;
  /** Called when edit is requested */
  onEdit?: (deal: Deal) => void;
  /** Whether edit is permitted (read-only disables buttons) */
  canEdit?: boolean;
  /** Called when move stage is requested */
  onMoveStage?: (deal: Deal) => void;
  /** Whether moving stages is permitted */
  canMoveStage?: boolean;
  /** Called when mark as won is requested */
  onMarkWon?: (deal: Deal) => void;
  /** Whether marking won is permitted */
  canMarkWon?: boolean;
  /** Called when mark as lost is requested */
  onMarkLost?: (deal: Deal) => void;
  /** Whether marking lost is permitted */
  canMarkLost?: boolean;
  /** Called when log activity is requested */
  onLogActivity?: () => void;
  /** Whether logging activity is permitted */
  canLogActivity?: boolean;
  /** Called when back button is clicked */
  onBack?: () => void;
  /** Called when client link is clicked */
  onClientClick?: (clientId: string) => void;
  /** Called when company link is clicked */
  onCompanyClick?: (companyId: string) => void;
  /** Called when viewing an enrollment */
  onViewEnrollment?: (enrollment: SequenceEnrollment) => void;
  /** Optional read-only reason tooltip */
  readOnlyReason?: string;
}

// ============================================
// Helpers
// ============================================

function getStatusBadgeVariant(
  status: Deal['status']
): 'default' | 'primary' | 'success' | 'warning' | 'danger' {
  const variants = {
    open: 'primary' as const,
    won: 'success' as const,
    lost: 'danger' as const,
  };
  return variants[status] || 'default';
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
 * DealDetail - Deal detail view
 *
 * @example
 * ```tsx
 * <DealDetail
 *   dealId="deal123"
 *   onEdit={handleEdit}
 *   onMoveStage={handleMoveStage}
 *   onMarkWon={handleMarkWon}
 *   onMarkLost={handleMarkLost}
 *   onLogActivity={() => setShowModal(true)}
 *   onBack={() => navigate('/deals')}
 * />
 * ```
 */
export function DealDetail({
  dealId,
  onEdit,
  onMoveStage,
  onMarkWon,
  onMarkLost,
  onLogActivity,
  onBack,
  onClientClick,
  onCompanyClick,
  onViewEnrollment,
  canEdit = true,
  canMoveStage = true,
  canMarkWon = true,
  canMarkLost = true,
  canLogActivity = true,
  readOnlyReason,
}: DealDetailProps) {
  const { deal, client, company, refresh: refreshDeal, isLoading: dealLoading } = useDeal(dealId);
  const {
    activities,
    isLoading: activitiesLoading,
    refresh: refreshTimeline,
  } = useTimeline({
    entityType: 'deal',
    entityId: dealId,
  });

  const { stages } = usePipelineWithStages(deal?.pipelineId);
  const {
    logNote,
    createTask,
    completeTask,
    uncompleteTask,
    updateActivity,
    isLoading: isLoggingActivities,
  } = useActivityLog();

  // Sequence enrollment state
  const features = getFeatureFlags();
  const {
    documents: dealDocuments,
    isLoading: dealDocumentsLoading,
    uploadDocument: uploadDealDocument,
    refreshDocuments: refreshDealDocuments,
  } = useDocuments({
    entityType: 'deal',
    entityId: dealId,
    autoLoad: features.enableDocuments,
  });
  const calendarSync = useCalendarSync({
    loadConnections: features.enableCalendarSync,
    loadMappings: features.enableCalendarSync,
  });
  const [showEnrollmentModal, setShowEnrollmentModal] = useState(false);
  // Get sequence status for the deal's associated client (if any)
  const {
    canEnroll,
    activeEnrollment,
    isSequencesEnabled,
    refresh: refreshSequenceStatus,
  } = useEntitySequenceStatus(
    deal?.clientId ? 'client' : undefined,
    deal?.clientId,
    deal?.clientEmail
  );

  if (dealLoading) {
    return (
      <div className="detail-view">
        <div className="detail-view__loading">Loading deal...</div>
      </div>
    );
  }

  if (!deal) {
    return (
      <div className="detail-view">
        <div className="detail-view__error">Deal not found</div>
      </div>
    );
  }

  const currentStage = stages.find((s) => s.id === deal.stageId);
  const stageIndex = stages.findIndex((s) => s.id === deal.stageId);
  const progressPercent =
    stages.length > 0 ? ((stageIndex + 1) / stages.length) * 100 : 0;
  const badges = [
    { label: deal.status, variant: getStatusBadgeVariant(deal.status) },
    ...(currentStage ? [{ label: currentStage.name, variant: 'default' as const }] : []),
  ];
  const stageProgressLabel =
    stages.length > 0 && stageIndex >= 0
      ? `${stageIndex + 1} of ${stages.length} pipeline stages`
      : 'Pipeline stage not assigned';
  const actions = [
    ...(onEdit
      ? [
          {
            label: 'Edit',
            onClick: () => onEdit(deal),
            variant: 'secondary' as const,
            disabled: !canEdit,
            title: !canEdit ? readOnlyReason : undefined,
          },
        ]
      : []),
    ...(onMoveStage && deal.status === 'open'
      ? [
          {
            label: 'Move Stage',
            onClick: () => onMoveStage(deal),
            variant: 'secondary' as const,
            disabled: !canMoveStage,
            title: !canMoveStage ? readOnlyReason : undefined,
          },
        ]
      : []),
    ...(onMarkWon && deal.status === 'open'
      ? [
          {
            label: 'Mark Won',
            onClick: () => onMarkWon(deal),
            variant: 'primary' as const,
            disabled: !canMarkWon,
            title: !canMarkWon ? readOnlyReason : undefined,
          },
        ]
      : []),
    ...(onMarkLost && deal.status === 'open'
      ? [
          {
            label: 'Mark Lost',
            onClick: () => onMarkLost(deal),
            variant: 'danger' as const,
            disabled: !canMarkLost,
            title: !canMarkLost ? readOnlyReason : undefined,
          },
        ]
      : []),
  ];

  const overviewTab: DetailTabConfig = {
    id: 'overview',
    label: 'Overview',
    content: (
      <div className="detail-overview-stack">
        <div className="detail-metric-grid">
          <div className="detail-metric-card">
            <span className="detail-metric__label">Deal Value</span>
            <strong className="detail-metric__value">
              {formatCurrency(deal.valueCents, deal.currency)}
            </strong>
            <span className="detail-metric__meta">
              {deal.status === 'open' ? 'Open opportunity' : 'Closed opportunity'}
            </span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Current Stage</span>
            <strong className="detail-metric__value">
              {currentStage?.name ?? 'Unassigned'}
            </strong>
            <span className="detail-metric__meta">{stageProgressLabel}</span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Win Probability</span>
            <strong className="detail-metric__value">{deal.probability}%</strong>
            <span className="detail-metric__meta">
              Expected close {formatDate(deal.expectedCloseDate)}
            </span>
          </div>
          <div className="detail-metric-card">
            <span className="detail-metric__label">Relationship Owner</span>
            <strong className="detail-metric__value">{deal.assigneeName ?? 'Unassigned'}</strong>
            <span className="detail-metric__meta">
              {deal.clientName ? `Linked contact: ${deal.clientName}` : 'No linked contact yet'}
            </span>
          </div>
        </div>

        {deal.status === 'open' && stages.length > 0 && (
          <DetailSection title="Pipeline Progress">
            <div className="pipeline-progress">
              <div className="pipeline-progress__bar">
                <div
                  className="pipeline-progress__fill"
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
              <div className="pipeline-progress__stages">
                {stages.map((stage, index) => (
                  <div
                    key={stage.id}
                    className={`pipeline-progress__stage ${
                      index <= stageIndex ? 'pipeline-progress__stage--active' : ''
                    }`}
                  >
                    <div
                      className="pipeline-progress__stage-dot"
                      style={{
                        backgroundColor: index <= stageIndex ? stage.colorHex : undefined,
                      }}
                    />
                    <div className="pipeline-progress__stage-name">{stage.name}</div>
                  </div>
                ))}
              </div>
            </div>
          </DetailSection>
        )}

        <div className="detail-grid detail-grid--two">
          <DetailSection title="Commercial Snapshot">
            <div className="detail-info">
              <div className="detail-info__row">
                <span className="detail-info__label">Status:</span>
                <span className="detail-info__value">{deal.status}</span>
              </div>
              <div className="detail-info__row">
                <span className="detail-info__label">Value:</span>
                <span className="detail-info__value">
                  {formatCurrency(deal.valueCents, deal.currency)}
                </span>
              </div>
              <div className="detail-info__row">
                <span className="detail-info__label">Probability:</span>
                <span className="detail-info__value">{deal.probability} percent</span>
              </div>
              <div className="detail-info__row">
                <span className="detail-info__label">Expected Close:</span>
                <span className="detail-info__value">
                  {formatDate(deal.expectedCloseDate)}
                </span>
              </div>
              <div className="detail-info__row">
                <span className="detail-info__label">Created:</span>
                <span className="detail-info__value">{formatDate(deal.createdAt)}</span>
              </div>
              {deal.closedAt && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Closed:</span>
                  <span className="detail-info__value">{formatDate(deal.closedAt)}</span>
                </div>
              )}
            </div>
          </DetailSection>

          <DetailSection title="Relationship Context">
            <div className="detail-info">
              {deal.clientName && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Client:</span>
                  <span className="detail-info__value">
                    {onClientClick && deal.clientId ? (
                      <button
                        type="button"
                        className="detail-link"
                        onClick={() => onClientClick(deal.clientId!)}
                      >
                        {deal.clientName}
                      </button>
                    ) : (
                      deal.clientName
                    )}
                  </span>
                </div>
              )}
              {deal.companyName && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Company:</span>
                  <span className="detail-info__value">
                    {onCompanyClick && deal.companyId ? (
                      <button
                        type="button"
                        className="detail-link"
                        onClick={() => onCompanyClick(deal.companyId!)}
                      >
                        {deal.companyName}
                      </button>
                    ) : (
                      deal.companyName
                    )}
                  </span>
                </div>
              )}
              {deal.assigneeName && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Assignee:</span>
                  <span className="detail-info__value">{deal.assigneeName}</span>
                </div>
              )}
              {deal.tags.length > 0 && (
                <div className="detail-info__row">
                  <span className="detail-info__label">Tags:</span>
                  <span className="detail-info__value">
                    <div className="detail-tags">
                      {deal.tags.map((tag) => (
                        <span key={tag} className="detail-tag">
                          {tag}
                        </span>
                      ))}
                    </div>
                  </span>
                </div>
              )}
              <div className="detail-info__row">
                <span className="detail-info__label">Pipeline:</span>
                <span className="detail-info__value">
                  {stageProgressLabel}
                </span>
              </div>
            </div>
          </DetailSection>
        </div>

        {deal.notes && (
          <DetailSection title="Notes">
            <div className="detail-notes">{deal.notes}</div>
          </DetailSection>
        )}
        {deal.wonLostReason && (
          <DetailSection title={`${deal.status === 'won' ? 'Won' : 'Lost'} Reason`}>
            <div className="detail-notes">{deal.wonLostReason}</div>
          </DetailSection>
        )}
      </div>
    ),
  };

  const documentsTab: DetailTabConfig | null = features.enableDocuments
    ? {
        id: 'documents',
        label: 'Documents',
        content: (
          <DealDocumentsTab
            deal={deal}
            client={client}
            company={company}
            documents={dealDocuments}
            isLoading={dealDocumentsLoading}
            onUpload={async (file, { name, documentType }) => {
              await uploadDealDocument(file, {
                name,
                documentType,
                associatedEntity: { type: 'deal', id: deal.id },
              });
            }}
            onRefresh={refreshDealDocuments}
            refreshDeal={refreshDeal}
          />
        ),
      }
    : null;
  const schedulerTab: DetailTabConfig | null = deal.clientId
    ? {
        id: 'scheduler',
        label: 'Scheduler',
        content: (
          <div className="detail-overview-stack">
            <div className="detail-grid detail-grid--two">
              <DetailSection title="Upcoming Appointments">
                <UpcomingAppointments clientId={deal.clientId} maxItems={5} />
              </DetailSection>

              <DetailSection title="Appointment History">
                <AppointmentList clientId={deal.clientId} />
              </DetailSection>
            </div>
            <DetailSection title="Communication History">
              <CommHistory clientId={deal.clientId} />
            </DetailSection>
          </div>
        ),
      }
    : null;

  const tabs: DetailTabConfig[] = [overviewTab];
  if (schedulerTab) {
    tabs.push(schedulerTab);
  }
  if (documentsTab) {
    tabs.push(documentsTab);
  }
  return (
    <div className="detail-view">
      <DetailHeader
        title={deal.title}
        subtitle={formatCurrency(deal.valueCents, deal.currency)}
        badges={badges}
        actions={actions}
        onBack={onBack}
      />

      <div className="detail-view__content">
        <div className="detail-view__main">
          <DetailTabs tabs={tabs} />
        </div>

        <div className="detail-view__sidebar">
          <DetailSection title="Scheduler Context">
            {deal.clientId ? (
              <UpcomingAppointments clientId={deal.clientId} compact />
            ) : (
              <p className="detail-notes">
                Link a contact to this deal to view appointments, communication history, and AI insights from The Scheduler.
              </p>
            )}
          </DetailSection>

          {deal.clientId && (
            <DetailSection title="AI Insights">
              <AIInsightsCard clientId={deal.clientId} />
            </DetailSection>
          )}

          {/* Sequence Section - Show when feature is enabled and deal has a client */}
          {isSequencesEnabled && deal.clientId && deal.clientName && (
            <DetailSection title="Sequences">
              <div className="deal-detail__sequence-section">
                {activeEnrollment ? (
                  <div className="deal-detail__sequence-active">
                    <div className="deal-detail__sequence-badge">
                      <svg
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                      >
                        <path d="M12 2L2 7l10 5 10-5-10-5z" />
                        <path d="M2 17l10 5 10-5" />
                        <path d="M2 12l10 5 10-5" />
                      </svg>
                      <span>In Sequence</span>
                    </div>
                    <div className="deal-detail__sequence-name">
                      {activeEnrollment.sequenceName}
                    </div>
                    <div className="deal-detail__sequence-progress">
                      {activeEnrollment.stepsCompleted}/{activeEnrollment.totalSteps} steps
                    </div>
                    {onViewEnrollment && (
                      <button
                        type="button"
                        className="btn btn-sm btn-secondary"
                        onClick={() => onViewEnrollment(activeEnrollment)}
                      >
                        View Details
                      </button>
                    )}
                  </div>
                ) : (
                  <div className="deal-detail__sequence-empty">
                    <p className="deal-detail__sequence-empty-text">
                      {deal.clientName} is not in any sequence
                    </p>
                    {canEnroll && (
                      <button
                        type="button"
                        className="btn btn-sm btn-primary"
                        onClick={() => setShowEnrollmentModal(true)}
                        data-testid="add-to-sequence-btn"
                      >
                        + Add to Sequence
                      </button>
                    )}
                  </div>
                )}

                {/* History link */}
                <EntitySequenceHistory
                  entityType="client"
                  entityId={deal.clientId}
                  compact
                  onEnrollmentClick={onViewEnrollment}
                />
              </div>
            </DetailSection>
          )}

          <DetailSection title="Activity Timeline">
            <ActivityTimeline
              activities={activities}
              isLoading={activitiesLoading}
              onLogActivity={onLogActivity}
              emptyMessage="No activities logged yet"
              onToggleTask={
                canLogActivity
                  ? async (activityId, nextCompleted) => {
                      if (!canLogActivity) return;
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
                      await logNote(deal.id, 'deal', note);
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
                        dealId: deal.id,
                        clientId: deal.clientId,
                        companyId: deal.companyId,
                        dueDate: resolvedDue,
                        assigneeId: deal.assigneeId,
                        assigneeName: deal.assigneeName,
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
              taskTemplates={getTaskTemplates(currentStage?.name, deal.pipelineId)}
              defaultTemplateId={getDefaultTaskTemplate(currentStage?.name, deal.pipelineId)?.id}
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

      {/* Enrollment Modal */}
      {deal.clientId && deal.clientName && deal.clientEmail && (
        <EnrollmentModal
          isOpen={showEnrollmentModal}
          onClose={() => setShowEnrollmentModal(false)}
          entity={{
            type: 'client',
            id: deal.clientId,
            name: deal.clientName,
            email: deal.clientEmail,
          }}
          onSuccess={() => {
            refreshSequenceStatus();
            setShowEnrollmentModal(false);
          }}
        />
      )}
    </div>
  );
}

export default DealDetail;
