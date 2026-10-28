/**
 * ActivityTimeline Component
 * Activity feed component for detail views with inline note/task logging.
 *
 * Agent CRM-17 Implementation — extended for Activity Productivity Agent
 */

import React from 'react';
import type { SalesActivity } from '../../types/models';
import { applyTaskTemplate, type TaskTemplate } from '../../config/taskTemplates';
import { SyncStatusBadge } from '../calendar-sync/SyncStatusBadge';
import type { ActivityStatus } from '../../hooks/useCalendarSync';
import {
  formatDateTimeLocal,
  formatRelativeTime,
  formatSlaLabel,
  getActivityIcon,
} from './activityTimelineUtils';
import './details.css';

// ============================================
// Types
// ============================================

export interface ActivityTimelineProps {
  activities: SalesActivity[];
  isLoading: boolean;
  onActivityClick?: (activity: SalesActivity) => void;
  onLogActivity?: () => void;
  emptyMessage?: string;
  onToggleTask?: (activityId: string, nextCompleted: boolean) => Promise<void> | void;
  onQuickNote?: (note: string) => Promise<void> | void;
  onQuickTask?: (input: {
    title: string;
    dueDate?: Date;
    templateId?: string;
    slaMinutes?: number;
    slaAt?: Date;
    reminderAt?: Date;
    pipelineId?: string;
  }) => Promise<void> | void;
  onUpdateTask?: (
    activityId: string,
    updates: Partial<
      Pick<
        SalesActivity,
        'dueDate' | 'templateId' | 'slaMinutes' | 'slaAt' | 'reminderAt'
      >
    >
  ) => Promise<void> | void;
  taskTemplates?: TaskTemplate[];
  defaultTemplateId?: string;
  isMutating?: boolean;
  calendarEnabled?: boolean;
  calendarStatuses?: Record<string, ActivityStatus>;
  onAddToCalendar?: (activityId: string) => Promise<void> | void;
  onResolveCalendarConflict?: (mappingId: string) => Promise<void> | void;
}

// ============================================
// Component
// ============================================

export function ActivityTimeline({
  activities,
  isLoading,
  onActivityClick,
  onLogActivity,
  emptyMessage = 'No activity yet',
  onToggleTask,
  onQuickNote,
  onQuickTask,
  onUpdateTask,
  taskTemplates = [],
  defaultTemplateId,
  isMutating = false,
  calendarEnabled = false,
  calendarStatuses,
  onAddToCalendar,
  onResolveCalendarConflict,
}: ActivityTimelineProps) {
  const [completingTaskId, setCompletingTaskId] = React.useState<string | null>(null);
  const [noteText, setNoteText] = React.useState('');
  const [quickTaskError, setQuickTaskError] = React.useState<string | null>(null);
  const [quickTask, setQuickTask] = React.useState<{
    title: string;
    dueDate?: string;
    templateId?: string;
    slaMinutes?: number;
    slaAt?: Date;
    reminderAt?: Date;
    pipelineId?: string;
  }>({
    title: '',
    templateId: defaultTemplateId || taskTemplates[0]?.id,
  });
  const [savingTaskId, setSavingTaskId] = React.useState<string | null>(null);
  const [inlineError, setInlineError] = React.useState<{ taskId: string | null; message: string | null }>({
    taskId: null,
    message: null,
  });
  const [taskDrafts, setTaskDrafts] = React.useState<
    Record<string, { dueDate?: string; templateId?: string }>
  >({});

  const applyTemplateToQuickTask = React.useCallback(
    (templateId?: string, overrideTitle = false) => {
      if (!templateId) return;
      const template = taskTemplates.find((t) => t.id === templateId);
      if (!template) return;

      const applied = applyTaskTemplate(template);
      setQuickTask((prev) => ({
        ...prev,
        templateId,
        title: overrideTitle || !prev.title ? applied.title : prev.title,
        dueDate: formatDateTimeLocal(applied.dueDate),
        slaMinutes: applied.slaMinutes,
        slaAt: applied.slaAt,
        reminderAt: applied.reminderAt,
      }));
      setQuickTaskError(null);
    },
    [taskTemplates]
  );

  // Initialize quick task defaults when templates are present
  React.useEffect(() => {
    if (!onQuickTask) return;
    if (quickTask.dueDate) return;
    const templateId = quickTask.templateId || defaultTemplateId || taskTemplates[0]?.id;
    applyTemplateToQuickTask(templateId, true);
  }, [applyTemplateToQuickTask, defaultTemplateId, onQuickTask, quickTask.dueDate, quickTask.templateId, taskTemplates]);

  const getTaskDraft = React.useCallback(
    (activity: SalesActivity) => {
      const draft = taskDrafts[activity.id];
      return {
        dueDate:
          draft?.dueDate ||
          (activity.dueDate ? formatDateTimeLocal(activity.dueDate) : ''),
        templateId:
          draft?.templateId ||
          activity.templateId ||
          defaultTemplateId ||
          taskTemplates[0]?.id,
      };
    },
    [defaultTemplateId, taskDrafts, taskTemplates]
  );

  const setTaskDraft = (activityId: string, updates: { dueDate?: string; templateId?: string }) => {
    setTaskDrafts((prev) => ({ ...prev, [activityId]: { ...prev[activityId], ...updates } }));
  };

  const handleTaskToggle = async (activity: SalesActivity) => {
    if (activity.type !== 'task' || !onToggleTask) return;

    setCompletingTaskId(activity.id);

    try {
      await onToggleTask(activity.id, !activity.isCompleted);
    } finally {
      setCompletingTaskId(null);
    }
  };

  const handleQuickNoteSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!onQuickNote) return;
    const trimmed = noteText.trim();
    if (!trimmed) return;
    await onQuickNote(trimmed);
    setNoteText('');
  };

  const handleQuickTaskSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!onQuickTask) return;
    if (!quickTask.title.trim()) {
      setQuickTaskError('Title is required');
      return;
    }
    const dueDate = quickTask.dueDate ? new Date(quickTask.dueDate) : undefined;
    await onQuickTask({
      title: quickTask.title.trim(),
      dueDate,
      templateId: quickTask.templateId,
      slaMinutes: quickTask.slaMinutes,
      slaAt: quickTask.slaAt,
      reminderAt: quickTask.reminderAt,
      pipelineId: quickTask.pipelineId,
    });
    setQuickTask({
      title: '',
      templateId: quickTask.templateId,
      slaAt: quickTask.slaAt,
      slaMinutes: quickTask.slaMinutes,
      reminderAt: quickTask.reminderAt,
      dueDate: quickTask.dueDate,
      pipelineId: quickTask.pipelineId,
    });
    setQuickTaskError(null);
  };

  const handleSaveDueDate = async (activity: SalesActivity) => {
    if (!onUpdateTask || activity.type !== 'task') return;
    const draft = getTaskDraft(activity);
    if (!draft.dueDate) {
      setInlineError({ taskId: activity.id, message: 'Set a due date before saving' });
      return;
    }

    const parsed = new Date(draft.dueDate);
    if (Number.isNaN(parsed.getTime())) {
      setInlineError({ taskId: activity.id, message: 'Enter a valid date/time' });
      return;
    }

    setSavingTaskId(activity.id);
    setInlineError({ taskId: null, message: null });

    try {
      await onUpdateTask(activity.id, { dueDate: parsed });
    } finally {
      setSavingTaskId(null);
    }
  };

  const handleSnooze = async (activity: SalesActivity, days: number) => {
    if (!onUpdateTask || activity.type !== 'task') return;
    const base = activity.dueDate || activity.slaAt || new Date();
    const next = new Date(base);
    next.setDate(next.getDate() + days);
    setTaskDraft(activity.id, { dueDate: formatDateTimeLocal(next) });
    setInlineError({ taskId: null, message: null });

    setSavingTaskId(activity.id);
    try {
      await onUpdateTask(activity.id, { dueDate: next });
    } finally {
      setSavingTaskId(null);
    }
  };

  const handleApplyTemplateToTask = async (activity: SalesActivity) => {
    if (!onUpdateTask || activity.type !== 'task') return;
    const draft = getTaskDraft(activity);
    const template = taskTemplates.find((t) => t.id === draft.templateId) || taskTemplates[0];
    if (!template) {
      setInlineError({ taskId: activity.id, message: 'Select a template first' });
      return;
    }

    const applied = applyTaskTemplate(template);
    setSavingTaskId(activity.id);
    setInlineError({ taskId: null, message: null });

    try {
      await onUpdateTask(activity.id, {
        templateId: template.id,
        dueDate: applied.dueDate,
        slaMinutes: applied.slaMinutes,
        slaAt: applied.slaAt,
        reminderAt: applied.reminderAt,
      });
      setTaskDraft(activity.id, { dueDate: formatDateTimeLocal(applied.dueDate), templateId: template.id });
    } finally {
      setSavingTaskId(null);
    }
  };

  if (isLoading) {
    return (
      <div className="activity-timeline">
        <div className="activity-timeline__loading">Loading activities...</div>
      </div>
    );
  }

  return (
    <div className="activity-timeline">
      {(onLogActivity || onQuickNote || onQuickTask) && (
        <div className="activity-timeline__header">
          {onLogActivity && (
            <button type="button" className="btn btn--primary btn--sm" onClick={onLogActivity}>
              Log Activity
            </button>
          )}
          {(onQuickNote || onQuickTask) && (
            <div className="activity-timeline__shortcuts" aria-label="Quick logging">
              {onQuickNote && (
                <form className="activity-timeline__composer activity-timeline__composer--note" onSubmit={handleQuickNoteSubmit}>
                  <label className="activity-timeline__field activity-timeline__field--grow" htmlFor="quick-note">
                    <span className="activity-timeline__field-label">Quick note</span>
                    <input
                      id="quick-note"
                      type="text"
                      value={noteText}
                      placeholder="Add note (Ctrl+Enter to save)"
                      onChange={(e) => setNoteText(e.target.value)}
                      onKeyDown={(e) => {
                        if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                          handleQuickNoteSubmit(e);
                        }
                      }}
                      disabled={isMutating}
                    />
                  </label>
                  <div className="activity-timeline__composer-actions">
                    <button type="submit" className="btn btn--secondary btn--sm" disabled={isMutating || !noteText.trim()}>
                      Add note
                    </button>
                  </div>
                </form>
              )}
              {onQuickTask && (
                <form className="activity-timeline__composer activity-timeline__composer--task" onSubmit={handleQuickTaskSubmit}>
                  <label className="activity-timeline__field activity-timeline__field--grow" htmlFor="quick-task-title">
                    <span className="activity-timeline__field-label">Quick task title</span>
                    <input
                      id="quick-task-title"
                      type="text"
                      value={quickTask.title}
                      placeholder="Task title"
                      onChange={(e) => setQuickTask((prev) => ({ ...prev, title: e.target.value }))}
                      disabled={isMutating}
                    />
                  </label>
                  {taskTemplates.length > 0 && (
                    <label className="activity-timeline__field">
                      <span className="activity-timeline__field-label">Template</span>
                      <select
                        aria-label="Task template"
                        value={quickTask.templateId || taskTemplates[0].id}
                        onChange={(e) => applyTemplateToQuickTask(e.target.value, true)}
                        disabled={isMutating}
                      >
                        {taskTemplates.map((template) => (
                          <option key={template.id} value={template.id}>
                            {template.label}
                          </option>
                        ))}
                      </select>
                    </label>
                  )}
                  <label className="activity-timeline__field">
                    <span className="activity-timeline__field-label">Due date</span>
                    <input
                      type="datetime-local"
                      value={quickTask.dueDate || ''}
                      onChange={(e) => setQuickTask((prev) => ({ ...prev, dueDate: e.target.value }))}
                      aria-label="Task due date"
                      disabled={isMutating}
                    />
                  </label>
                  <div className="activity-timeline__composer-actions">
                    <button
                      type="submit"
                      className="btn btn--primary btn--sm"
                      disabled={isMutating || !quickTask.title.trim()}
                    >
                      Add task
                    </button>
                  </div>
                  {quickTaskError && (
                    <span className="activity-timeline__error" role="status">
                      {quickTaskError}
                    </span>
                  )}
                </form>
              )}
            </div>
          )}
        </div>
      )}

      {activities.length === 0 ? (
        <div className="activity-timeline__empty">
          <p>{emptyMessage}</p>
          {onLogActivity && (
            <button type="button" className="btn btn--secondary btn--sm" onClick={onLogActivity}>
              Log First Activity
            </button>
          )}
        </div>
      ) : (
        <div className="activity-timeline__items">
          {activities.map((activity) => {
            const slaLabel = formatSlaLabel(activity);
            const calendarStatus = calendarStatuses?.[activity.id];
            const lastSyncedAt = calendarStatus?.lastSyncedAt
              ? new Date(calendarStatus.lastSyncedAt)
              : undefined;
            return (
              <div
                key={activity.id}
                className={`activity-item ${onActivityClick ? 'activity-item--clickable' : ''} ${
                  activity.type === 'task' && !activity.isCompleted ? 'activity-item--task-pending' : ''
                }`}
                onClick={() => onActivityClick?.(activity)}
                onKeyDown={(e) => {
                  if (e.key.toLowerCase() === 'c' && activity.type === 'task') {
                    e.preventDefault();
                    handleTaskToggle(activity);
                  }
                }}
                role={onActivityClick ? 'button' : undefined}
                tabIndex={onActivityClick ? 0 : undefined}
              >
                <div className="activity-item__icon">
                  {activity.type === 'task' ? (
                    <input
                      type="checkbox"
                      className="activity-item__checkbox"
                      checked={activity.isCompleted}
                      onChange={(e) => {
                        e.stopPropagation();
                        handleTaskToggle(activity);
                      }}
                      disabled={completingTaskId === activity.id || isMutating}
                      aria-label={`Mark task "${activity.title}" as ${activity.isCompleted ? 'incomplete' : 'complete'}`}
                    />
                  ) : (
                    <span className={`activity-icon activity-icon--${activity.type}`}>
                      {getActivityIcon(activity.type)}
                    </span>
                  )}
                </div>
                <div className="activity-item__content">
                  <div className="activity-item__header">
                    <div className="activity-item__title">{activity.title}</div>
                    <div className="activity-item__time">
                      {formatRelativeTime(activity.createdAt)}
                    </div>
                  </div>
                  {activity.description && (
                    <div className="activity-item__description">{activity.description}</div>
                  )}
                  <div className="activity-item__meta">
                    <span className="activity-item__author">{activity.createdByName}</span>
                    {activity.type === 'task' && activity.dueDate && (
                      <>
                        <span className="activity-item__separator">•</span>
                        <span className="activity-item__due">
                          Due: {new Date(activity.dueDate).toLocaleDateString()}
                        </span>
                      </>
                    )}
                    {slaLabel && (
                      <span className={`activity-sla activity-sla--${slaLabel.tone}`}>
                        {slaLabel.label}
                      </span>
                    )}
                  </div>
                  {calendarEnabled && (
                    <div className="activity-item__calendar">
                      {calendarStatus ? (
                        <div className="activity-item__calendar-status">
                          <SyncStatusBadge status={calendarStatus.syncStatus} lastSyncAt={lastSyncedAt} compact />
                          <div className="activity-item__calendar-meta">
                            {calendarStatus.syncDirection === 'calendar_to_crm' && (
                              <span className="text-muted">Imported from calendar</span>
                            )}
                            {lastSyncedAt && (
                              <span className="text-muted">Synced {formatRelativeTime(lastSyncedAt)}</span>
                            )}
                          </div>
                          {calendarStatus.syncStatus === 'conflict' &&
                            calendarStatus.mappingId &&
                            onResolveCalendarConflict && (
                              <button
                                type="button"
                                className="btn btn--ghost btn--sm"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  onResolveCalendarConflict(calendarStatus.mappingId!);
                                }}
                              >
                                Resolve
                              </button>
                            )}
                        </div>
                      ) : (
                        onAddToCalendar && (
                          <button
                            type="button"
                            className="btn btn--ghost btn--sm"
                            onClick={(e) => {
                              e.stopPropagation();
                              onAddToCalendar(activity.id);
                            }}
                          >
                            Add to Calendar
                          </button>
                        )
                      )}
                    </div>
                  )}

                  {activity.type === 'task' && onUpdateTask && (
                    <div className="activity-item__inline-edit">
                      <div className="activity-item__reschedule">
                        <label htmlFor={`due-${activity.id}`} className="sr-only">
                          Due date for {activity.title}
                        </label>
                        <input
                          id={`due-${activity.id}`}
                          type="datetime-local"
                          value={getTaskDraft(activity).dueDate}
                          onChange={(e) => {
                            setTaskDraft(activity.id, { dueDate: e.target.value });
                            setInlineError({ taskId: null, message: null });
                          }}
                          disabled={isMutating || savingTaskId === activity.id}
                        />
                        <div className="activity-item__reschedule-actions">
                          <button
                            type="button"
                            className="btn btn--secondary btn--sm"
                            onClick={() => handleSaveDueDate(activity)}
                            disabled={isMutating || savingTaskId === activity.id}
                          >
                            Save
                          </button>
                          <button
                            type="button"
                            className="btn btn--ghost btn--sm"
                            onClick={() => handleSnooze(activity, 1)}
                            disabled={isMutating || savingTaskId === activity.id}
                          >
                            +1d
                          </button>
                          <button
                            type="button"
                            className="btn btn--ghost btn--sm"
                            onClick={() => handleSnooze(activity, 3)}
                            disabled={isMutating || savingTaskId === activity.id}
                          >
                            +3d
                          </button>
                        </div>
                      </div>

                      {taskTemplates.length > 0 && (
                        <div className="activity-item__template">
                          <label htmlFor={`template-${activity.id}`} className="sr-only">
                            Template for {activity.title}
                          </label>
                          <select
                            id={`template-${activity.id}`}
                            value={getTaskDraft(activity).templateId}
                            onChange={(e) => {
                              setTaskDraft(activity.id, { templateId: e.target.value });
                              setInlineError({ taskId: null, message: null });
                            }}
                            disabled={isMutating || savingTaskId === activity.id}
                          >
                            {taskTemplates.map((template) => (
                              <option key={template.id} value={template.id}>
                                {template.label}
                              </option>
                            ))}
                          </select>
                          <button
                            type="button"
                            className="btn btn--secondary btn--sm"
                            onClick={() => handleApplyTemplateToTask(activity)}
                            disabled={isMutating || savingTaskId === activity.id}
                          >
                            Apply template
                          </button>
                        </div>
                      )}

                      {inlineError.taskId === activity.id && inlineError.message && (
                        <div className="activity-item__error" role="status">
                          {inlineError.message}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default ActivityTimeline;
