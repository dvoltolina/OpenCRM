import { useState, useMemo } from 'react';
import type { SalesActivityType, SalesActivity } from '../types/models';
import {
  useRecentActivities,
  useDeals,
  useLeads,
  useContacts,
  useModal,
} from '../hooks';
import { Modal, ConfirmDialog } from '../components/modals';
import { ActivityForm } from '../components/forms/ActivityForm';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import type { ActivityFormData } from '../components/forms/validation/schemas';
import { useActivityLog } from '../hooks/useActivityLog';
import { useAuth } from '../context/AuthContext';
import { getTaskTemplates } from '../config/taskTemplates';
import { QuickActivityBar, type QuickActivityInput } from '../components/activities/QuickActivityBar';
import { evaluateTaskSla } from '../lib/tasks';
import {
  canDeleteShareableEntity,
  canWriteShareableEntity,
  createSecurityContext,
  getShareableAccessSummary,
} from '../lib/security-context';
import './styles/activities.css';

const activityTypes: { value: SalesActivityType | 'all'; label: string }[] = [
  { value: 'all', label: 'All Activities' },
  { value: 'call', label: 'Calls' },
  { value: 'email', label: 'Emails' },
  { value: 'meeting', label: 'Meetings' },
  { value: 'note', label: 'Notes' },
  { value: 'task', label: 'Tasks' },
];

export function ActivitiesPage() {
  const [typeFilter, setTypeFilter] = useState<SalesActivityType | 'all'>(() => {
    const param = new URLSearchParams(window.location.search).get('type');
    return param === 'task' ? 'task' : 'all';
  });
  const [editingActivity, setEditingActivity] = useState<SalesActivity | null>(null);
  const [deletingActivity, setDeletingActivity] = useState<SalesActivity | null>(null);
  const [limit, setLimit] = useState(20);
  const [showCompleted, setShowCompleted] = useState(true);
  const [isQuickSubmitting, setIsQuickSubmitting] = useState(false);
  const logModal = useModal();
  const editModal = useModal();
  const deleteModal = useModal();

  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );
  const getAccessSummary = useMemo(
    () =>
      securityContext
        ? (activity: SalesActivity | null) =>
            activity ? getShareableAccessSummary(securityContext, activity) : null
        : () => null,
    [securityContext]
  );
  const canCreate = Boolean(securityContext);
  const canWriteActivity = (activity: SalesActivity) =>
    Boolean(
      getAccessSummary(activity)?.canWrite ||
        (securityContext &&
          (canWriteShareableEntity(securityContext, activity) ||
            activity.createdById === securityContext.userId))
    );
  const canDeleteActivity = (activity: SalesActivity) =>
    Boolean(
      getAccessSummary(activity)?.canDelete ||
        (securityContext && canDeleteShareableEntity(securityContext, activity))
    );
  const readOnlyReason = (activity: SalesActivity) => {
    const summary = getAccessSummary(activity);
    if (!summary || summary.canWrite) return undefined;
    if (summary.visibility === 'org' && !summary.hasTeamAccess) return 'Read-only: org-visible only';
    return 'Read-only: not shared to you or your teams';
  };
  // Fetch recent activities (last 30 days)
  const {
    activities,
    isLoading,
    error,
    refresh,
  } = useRecentActivities(30);
  const { deals } = useDeals({ status: 'open' });
  const { leads } = useLeads();
  const { contacts } = useContacts();
  const {
    logActivity,
    createTask,
    updateActivity,
    deleteActivity,
    completeTask,
    uncompleteTask,
    isLoading: isLogging
  } = useActivityLog();
  const taskTemplates = getTaskTemplates();
  // Filter activities by type and completion status
  const filteredActivities = useMemo(() => {
    let filtered = activities;
    // Filter by type
    if (typeFilter !== 'all') {
      filtered = filtered.filter((activity) => activity.type === typeFilter);
    }
    // Filter by completion status for tasks
    if (!showCompleted) {
      filtered = filtered.filter((activity) => {
        if (activity.type === 'task') {
          return !activity.isCompleted;
        }
        return true;
      });
    }

    return filtered;
  }, [activities, typeFilter, showCompleted]);

  // Display only limited number of activities
  const displayedActivities = useMemo(() => {
    return filteredActivities.slice(0, limit);
  }, [filteredActivities, limit]);

  const hasMore = filteredActivities.length > limit;
  const pendingTaskCount = filteredActivities.filter(
    (activity) => activity.type === 'task' && !activity.isCompleted
  ).length;
  const completedTaskCount = filteredActivities.filter(
    (activity) => activity.type === 'task' && activity.isCompleted
  ).length;

  const getActivityIcon = (type: SalesActivityType) => {
    switch (type) {
      case 'call':
        return 'CL';
      case 'email':
        return 'EM';
      case 'meeting':
        return 'MT';
      case 'note':
        return 'NT';
      case 'task':
        return 'TS';
      default:
        return 'AC';
    }
  };

  const getSlaBadge = (activity: SalesActivity) => {
    if (activity.type !== 'task') return null;
    const { status, minutesRemaining } = evaluateTaskSla(activity);
    switch (status) {
      case 'breached':
        return { label: 'SLA breached', tone: 'danger' as const };
      case 'atRisk':
        return {
          label: minutesRemaining !== undefined ? `SLA at risk (${minutesRemaining}m)` : 'SLA at risk',
          tone: 'warning' as const,
        };
      case 'ok':
        return { label: 'On track', tone: 'ok' as const };
      case 'met':
        return { label: 'SLA met', tone: 'success' as const };
      default:
        return null;
    }
  };

  // Handler: Edit activity
  const handleEditActivity = (activity: SalesActivity) => {
    if (!canEdit(activity)) return;
    setEditingActivity(activity);
    editModal.open();
  };

  // Handler: Delete activity
  const handleDeleteActivity = (activity: SalesActivity) => {
    if (!canDelete(activity)) return;
    setDeletingActivity(activity);
    deleteModal.open();
  };

  // Handler: Confirm delete
  const handleConfirmDelete = async () => {
    if (!deletingActivity) return;
    if (!canDelete(deletingActivity)) return;

    const success = await deleteActivity(deletingActivity.id);
    if (success) {
      refresh();
      deleteModal.close();
      setDeletingActivity(null);
    }
  };

  // Handler: Toggle task completion
  const handleToggleTaskComplete = async (activity: SalesActivity) => {
    if (activity.type !== 'task') return;
    if (!canEdit(activity)) return;

    if (activity.isCompleted) {
      await uncompleteTask(activity.id);
    } else {
      await completeTask(activity.id);
    }
    refresh();
  };

  const defaultAssignee = crmUser
    ? { id: crmUser.id, name: crmUser.displayName || crmUser.email || 'Current User' }
    : undefined;

  const handleQuickCreate = async (input: QuickActivityInput) => {
    if (!canCreate) return;
    setIsQuickSubmitting(true);

    const assigneeFields =
      input.assigneeId && input.assigneeName
        ? { assigneeId: input.assigneeId, assigneeName: input.assigneeName }
        : {};

    const entityPayload =
      input.entityType === 'deal'
        ? { dealId: input.entityId }
        : input.entityType === 'lead'
          ? { leadId: input.entityId }
          : { clientId: input.entityId };

    try {
      const created =
        input.type === 'note'
          ? await logActivity({
              type: 'note',
              title: input.title,
              description: input.note,
              ...entityPayload,
            })
          : await createTask({
              title: input.title,
              description: input.note,
              dueDate: input.dueDate || new Date(Date.now() + 24 * 60 * 60 * 1000),
              templateId: input.templateId,
              slaMinutes: input.slaMinutes,
              slaAt: input.slaAt,
              reminderAt: input.reminderAt,
              ...assigneeFields,
              ...entityPayload,
            });

      if (created) {
        refresh();
      }
    } finally {
      setIsQuickSubmitting(false);
    }
  };

  // Handler: Load more activities
  const handleLoadMore = () => {
    setLimit((prev) => prev + 20);
  };

  // Check if user can edit/delete activity
  const canEdit = (activity: SalesActivity) => canWriteActivity(activity);
  const canDelete = (activity: SalesActivity) => canDeleteActivity(activity);

  // Show loading state
  if (isLoading) {
    return (
      <PageLayout width="wide" className="activities-page">
        <PageHeader
          eyebrow="Activity Log"
          title="Activities"
          subtitle="Calls, meetings, notes, and tasks across the current workspace."
          actions={(
            <Button
              disabled={isLoading || !canCreate}
              onClick={() => logModal.open()}
              title={!canCreate ? 'You do not have permission to log activities' : undefined}
            >
              Log activity
            </Button>
          )}
        />
        <Card className="activities-page__status-card" padding="lg">
          <div className="loading-state">
            <p>Loading activities...</p>
          </div>
        </Card>
      </PageLayout>
    );
  }

  // Show error state
  if (error) {
    return (
      <PageLayout width="wide" className="activities-page">
        <PageHeader
          eyebrow="Activity Log"
          title="Activities"
          subtitle="Calls, meetings, notes, and tasks across the current workspace."
          actions={(
            <Button
              onClick={() => logModal.open()}
              disabled={!canCreate}
              title={!canCreate ? 'You do not have permission to log activities' : undefined}
            >
              Log activity
            </Button>
          )}
        />
        <Card padding="lg">
          <EmptyState
            eyebrow="Load Error"
            title="Activities could not be loaded"
            description={`Error loading activities: ${error.message}`}
            actions={<Button onClick={refresh}>Retry</Button>}
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="activities-page">
      <PageHeader
        eyebrow="Activity Log"
        title="Activities"
        subtitle="Capture follow-ups, review recent work, and manage task execution from a single timeline."
        actions={(
          <div className="activities-page__header-actions">
            <Button
              onClick={() => logModal.open()}
              disabled={!canCreate}
              title={!canCreate ? 'You do not have permission to log activities' : undefined}
            >
              Log activity
            </Button>
          </div>
        )}
      />

      <Card className="activities-page__hero" padding="lg" tone="accent">
        <div className="activities-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current Focus</p>
          <h2>{typeFilter === 'all' ? 'All activity' : activityTypes.find((type) => type.value === typeFilter)?.label}</h2>
          <p>
            Review recent activity, filter by type, and keep open follow-up work moving without
            leaving the page.
          </p>
        </div>
        <div className="activities-page__hero-stats">
          <div>
            <span>Visible items</span>
            <strong>{filteredActivities.length}</strong>
          </div>
          <div>
            <span>Open tasks</span>
            <strong>{pendingTaskCount}</strong>
          </div>
          <div>
            <span>Completed tasks</span>
            <strong>{completedTaskCount}</strong>
          </div>
        </div>
      </Card>

      <Card className="activities-page__quick-card" padding="lg" tone="subtle">
        <QuickActivityBar
          deals={deals.map((d) => ({
            id: d.id,
            title: d.title,
            pipelineId: d.pipelineId,
            stageId: d.stageId,
          }))}
          leads={leads.map((l) => ({
            id: l.id,
            name: `${l.firstName} ${l.lastName}`.trim() || l.companyName || 'Lead',
            status: l.status,
          }))}
          contacts={contacts.map((c) => ({
            id: c.id,
            name: `${c.firstName} ${c.lastName}`.trim() || c.email || 'Contact',
            lifecycle: c.lifecycle,
          }))}
          taskTemplates={taskTemplates}
          defaultTemplateId={taskTemplates[0]?.id}
          defaultAssignee={defaultAssignee}
          onCreate={handleQuickCreate}
          isSubmitting={isQuickSubmitting || isLogging}
          isDisabled={!canCreate}
        />
      </Card>

      <Card className="activities-page__filters-card" padding="md">
        <Toolbar
          start={(
            <div className="filter-tabs">
              {activityTypes.map((type) => (
                <button
                  key={type.value}
                  type="button"
                  className={`filter-tab ${typeFilter === type.value ? 'active' : ''}`}
                  onClick={() => setTypeFilter(type.value as SalesActivityType | 'all')}
                >
                  <span className="tab-label">{type.label}</span>
                </button>
              ))}
            </div>
          )}
          end={(
            <div className="activities-page__filter-controls">
              <label className="filter-checkbox">
                <input
                  type="checkbox"
                  checked={showCompleted}
                  onChange={(e) => setShowCompleted(e.target.checked)}
                />
                Show completed tasks
              </label>
              <span className="ui-results-count">{displayedActivities.length} shown</span>
            </div>
          )}
        />
      </Card>

      <Card className="activities-page__timeline-card" padding="lg">
        <div className="activities-timeline">
          {displayedActivities.length === 0 ? (
            <EmptyState
              eyebrow="Timeline"
              title="No activities found"
              description="Adjust the current filters or log a new activity to start building this timeline."
              actions={
                filteredActivities.length === 0 && activities.length === 0 ? (
                  <Button
                    onClick={() => logModal.open()}
                    disabled={!canCreate}
                    title={!canCreate ? 'You do not have permission to log activities' : undefined}
                  >
                    Log your first activity
                  </Button>
                ) : undefined
              }
            />
          ) : (
            <>
              {displayedActivities.map((activity) => {
                const sla = getSlaBadge(activity);
                return (
                  <div
                    key={activity.id}
                    className={`activity-item ${activity.type === 'task' && activity.isCompleted ? 'completed' : ''}`}
                    role="group"
                    tabIndex={0}
                    onKeyDown={(e) => {
                      if (e.key.toLowerCase() === 'c' && activity.type === 'task') {
                        e.preventDefault();
                        handleToggleTaskComplete(activity);
                      }
                    }}
                  >
                    <div className="activity-icon" aria-hidden="true">{getActivityIcon(activity.type)}</div>
                    <div className="activity-content">
                      {sla && (
                        <span className={`activity-sla-badge activity-sla-badge--${sla.tone}`}>
                          {sla.label}
                        </span>
                      )}
                      <div className="activity-header">
                        <span className="activity-title">{activity.title}</span>
                        <div className="activity-actions">
                          {activity.type === 'task' && (
                            <button
                              type="button"
                              className="btn-icon activities-page__action-pill"
                              onClick={() => handleToggleTaskComplete(activity)}
                              disabled={isLogging || !canEdit(activity)}
                              title={
                                !canEdit(activity)
                                  ? readOnlyReason(activity)
                                  : activity.isCompleted
                                    ? 'Mark as incomplete'
                                    : 'Mark as complete'
                              }
                            >
                              {activity.isCompleted ? 'Undo' : 'Done'}
                            </button>
                          )}
                          <button
                            type="button"
                            className="btn-icon activities-page__action-pill"
                            onClick={() => handleEditActivity(activity)}
                            disabled={isLogging || !canEdit(activity)}
                            title={!canEdit(activity) ? readOnlyReason(activity) : 'Edit activity'}
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            className="btn-icon btn-danger activities-page__action-pill"
                            onClick={() => handleDeleteActivity(activity)}
                            disabled={isLogging || !canDelete(activity)}
                            title={!canDelete(activity) ? readOnlyReason(activity) || 'Read-only' : 'Delete activity'}
                          >
                            Delete
                          </button>
                          <span className="activity-time">
                            {activity.createdAt?.toLocaleString() || '-'}
                          </span>
                        </div>
                      </div>
                      {activity.description && (
                        <p className="activity-description">{activity.description}</p>
                      )}
                      <div className="activity-meta">
                        <span className="activity-type">{activity.type}</span>
                        <span className="activity-author">by {activity.createdByName}</span>
                        {activity.type === 'task' && activity.dueDate && (
                          <span className="activity-due-date">
                            Due: {new Date(activity.dueDate).toLocaleDateString()}
                          </span>
                        )}
                        {activity.type === 'task' && activity.isCompleted && activity.completedAt && (
                          <span className="activity-completed">
                            Completed: {new Date(activity.completedAt).toLocaleDateString()}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
              {hasMore && (
                <div className="load-more">
                  <Button
                    variant="secondary"
                    onClick={handleLoadMore}
                    disabled={isLogging}
                  >
                    Load More ({filteredActivities.length - limit} remaining)
                  </Button>
                </div>
              )}
            </>
          )}
        </div>
      </Card>

      <Modal
        isOpen={logModal.isOpen}
        onClose={logModal.close}
        title="Log Activity"
        size="lg"
        closeOnOverlayClick={!isLogging}
        closeOnEscape={!isLogging}
      >
        <ActivityForm
          onSubmit={async (data: ActivityFormData) => {
            const toDate = (value?: Date | string) => {
              if (!value) return undefined;
              return value instanceof Date ? value : new Date(value);
            };
            await logActivity({
              type: data.type as SalesActivityType,
              title: data.title,
              description: data.description,
              dealId: data.dealId || undefined,
              clientId: data.clientId || undefined,
              leadId: data.leadId || undefined,
              companyId: data.companyId || undefined,
              templateId: data.templateId,
              slaMinutes: data.slaMinutes,
              slaAt: toDate(data.slaAt),
              reminderAt: toDate(data.reminderAt),
              dueDate: toDate(data.dueDate),
              assigneeId: data.assigneeId || undefined,
              assigneeName: data.assigneeName || undefined,
            });
            refresh();
            logModal.close();
          }}
          onCancel={logModal.close}
          isLoading={isLogging}
          deals={deals.map((d) => ({ id: d.id, title: d.title }))}
          clients={contacts.map((c) => ({
            id: c.id,
            name: `${c.firstName} ${c.lastName}`.trim(),
          }))}
          leads={leads.map((l) => ({
            id: l.id,
            name: `${l.firstName} ${l.lastName}`.trim(),
          }))}
          taskTemplates={getTaskTemplates()}
        />
      </Modal>

      <Modal
        isOpen={editModal.isOpen}
        onClose={() => {
          editModal.close();
          setEditingActivity(null);
        }}
        title="Edit Activity"
        size="lg"
        closeOnOverlayClick={!isLogging}
        closeOnEscape={!isLogging}
      >
        {editingActivity && (
          <ActivityForm
            initialData={editingActivity}
            onSubmit={async (data: ActivityFormData) => {
              const toDate = (value?: Date | string) => {
                if (!value) return undefined;
                return value instanceof Date ? value : new Date(value);
              };
              await updateActivity(editingActivity.id, {
                title: data.title,
                description: data.description,
                templateId: data.templateId,
                slaMinutes: data.slaMinutes,
                slaAt: toDate(data.slaAt),
                reminderAt: toDate(data.reminderAt),
                dueDate: toDate(data.dueDate),
                assigneeId: data.assigneeId || undefined,
                assigneeName: data.assigneeName || undefined,
              });
              refresh();
              editModal.close();
              setEditingActivity(null);
            }}
            onCancel={() => {
              editModal.close();
              setEditingActivity(null);
            }}
            isLoading={isLogging}
            deals={deals.map((d) => ({ id: d.id, title: d.title }))}
            clients={contacts.map((c) => ({
              id: c.id,
              name: `${c.firstName} ${c.lastName}`.trim(),
            }))}
            leads={leads.map((l) => ({
              id: l.id,
              name: `${l.firstName} ${l.lastName}`.trim(),
            }))}
          />
        )}
      </Modal>

      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onConfirm={handleConfirmDelete}
        onCancel={() => {
          deleteModal.close();
          setDeletingActivity(null);
        }}
        title="Delete Activity"
        message={`Are you sure you want to delete this ${deletingActivity?.type || 'activity'}? This action cannot be undone.`}
        confirmText="Delete"
        cancelText="Cancel"
        variant="danger"
        isLoading={isLogging}
      />
    </PageLayout>
  );
}
