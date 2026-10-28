/**
 * QuickActivityBar
 * Inline composer for logging notes or tasks without opening the full modal.
 *
 * Keeps template defaults, SLA/reminder timings, and entity linking in a compact form.
 */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { applyTaskTemplate, getDefaultTaskTemplate, getTaskTemplates, type TaskTemplate } from '../../config/taskTemplates';
import { useAuth } from '../../context/AuthContext';
import { createSecurityContext } from '../../hooks/usePipeline';
import { getStageRepository } from '../../data/repositories/stage-repository';
import { getUserManagedTeamIds, getUserTeamIds } from '../../lib/security-context';
import './quick-activity-bar.css';

const STAGE_CACHE_TTL_MS = 5 * 60 * 1000;
const stageCache = new Map<string, { name?: string; pipelineId?: string; fetchedAt: number }>();

type EntityType = 'deal' | 'lead' | 'client';

interface EntityOption {
  id: string;
  label: string;
  type: EntityType;
  pipelineId?: string;
  stageId?: string;
  stageName?: string;
  status?: string;
  lifecycle?: string;
}

export interface QuickActivityInput {
  type: 'note' | 'task';
  title: string;
  note?: string;
  entityType: EntityType;
  entityId: string;
  dueDate?: Date;
  templateId?: string;
  slaMinutes?: number;
  slaAt?: Date;
  reminderAt?: Date;
  assigneeId?: string;
  assigneeName?: string;
}

export interface QuickActivityBarProps {
  deals: Array<{ id: string; title: string; pipelineId?: string; stageId?: string; stageName?: string }>;
  leads: Array<{ id: string; name: string; status?: string }>;
  contacts: Array<{ id: string; name: string; lifecycle?: string }>;
  taskTemplates: TaskTemplate[];
  defaultTemplateId?: string;
  defaultAssignee?: { id: string; name: string };
  onCreate: (input: QuickActivityInput) => Promise<void>;
  isSubmitting?: boolean;
  isDisabled?: boolean;
}

function formatDateTimeLocal(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours()
  )}:${pad(date.getMinutes())}`;
}

function getDefaultEntity(options: EntityOption[]): EntityOption | undefined {
  return options[0];
}

/**
 * Keep inline UI minimal: a single bar that can toggle between note/task.
 */
export function QuickActivityBar({
  deals,
  leads,
  contacts,
  taskTemplates,
  defaultTemplateId,
  defaultAssignee,
  onCreate,
  isSubmitting = false,
  isDisabled = false,
}: QuickActivityBarProps) {
  const { crmUser, businessId } = useAuth();
  const allEntities: EntityOption[] = useMemo(
    () => [
      ...deals.map((deal) => ({
        id: deal.id,
        label: deal.title,
        type: 'deal' as const,
        pipelineId: deal.pipelineId,
        stageId: deal.stageId,
        stageName: deal.stageName,
      })),
      ...leads.map((lead) => ({
        id: lead.id,
        label: lead.name,
        type: 'lead' as const,
        status: lead.status,
      })),
      ...contacts.map((contact) => ({
        id: contact.id,
        label: contact.name,
        type: 'client' as const,
        lifecycle: contact.lifecycle,
      })),
    ],
    [contacts, deals, leads]
  );

  const defaultEntity = useMemo(() => getDefaultEntity(allEntities), [allEntities]);

  const [mode, setMode] = useState<'note' | 'task'>('note');
  const [entityType, setEntityType] = useState<EntityType>(defaultEntity?.type || 'deal');
  const [entityId, setEntityId] = useState<string>(defaultEntity?.id || '');
  const [title, setTitle] = useState('');
  const [note, setNote] = useState('');
  const [templateId, setTemplateId] = useState<string | undefined>(
    defaultTemplateId || taskTemplates[0]?.id
  );
  const [dueDate, setDueDate] = useState<string>('');
  const [slaMinutes, setSlaMinutes] = useState<number | undefined>(undefined);
  const [slaAt, setSlaAt] = useState<Date | undefined>(undefined);
  const [reminderAt, setReminderAt] = useState<Date | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);
  const [stageMeta, setStageMeta] = useState<Record<string, { name?: string; pipelineId?: string }>>({});
  const [hasManualDueDate, setHasManualDueDate] = useState(false);
  const [templateUserSelected, setTemplateUserSelected] = useState(false);

  // Apply initial template defaults for tasks
  const selectedEntity = useMemo(
    () => allEntities.find((entity) => entity.type === entityType && entity.id === entityId),
    [allEntities, entityId, entityType]
  );

  const selectedStage =
    selectedEntity?.type === 'deal' && selectedEntity.stageId
      ? stageMeta[selectedEntity.stageId]
      : undefined;

  useEffect(() => {
    if (!selectedEntity || selectedEntity.type !== 'deal') return;
    const stageId = selectedEntity.stageId;
    if (!stageId) return;
    const cacheKey = businessId ? `${businessId}:${stageId}` : stageId;
    const cached = cacheKey ? stageCache.get(cacheKey) : undefined;
    if (cached && Date.now() - cached.fetchedAt < STAGE_CACHE_TTL_MS) {
      queueMicrotask(() => {
        setStageMeta((prev) => ({
          ...prev,
          [stageId]: { name: cached.name, pipelineId: cached.pipelineId },
        }));
      });
      return;
    }
    if (stageMeta[stageId]) return;
    if (!crmUser || !businessId) return;

    let mounted = true;

    const fetchStage = async () => {
      try {
        const repo = getStageRepository();
        const context = createSecurityContext(
          businessId,
          crmUser.id,
          crmUser.displayName || crmUser.email || 'User',
          crmUser.role,
          getUserTeamIds(crmUser),
          getUserManagedTeamIds(crmUser)
        );
        const result = await repo.getById(context, stageId, getUserTeamIds(crmUser));
        if (result.success && mounted && result.data) {
          if (cacheKey) {
            stageCache.set(cacheKey, {
              name: result.data.name,
              pipelineId: result.data.pipelineId,
              fetchedAt: Date.now(),
            });
          }
          setStageMeta((prev) => ({
            ...prev,
            [stageId]: {
              name: result.data.name,
              pipelineId: result.data.pipelineId,
            },
          }));
        }
      } catch {
        // Safe to ignore; fall back to base templates when stage metadata is unavailable.
      }
    };

    fetchStage();
    return () => {
      mounted = false;
    };
  }, [businessId, crmUser, selectedEntity, stageMeta]);

  const contextualTemplates = useMemo(() => {
    if (mode !== 'task') return [];
    if (!selectedEntity) return taskTemplates;

    if (selectedEntity.type === 'deal') {
      const stageName = selectedEntity.stageName || selectedStage?.name;
      const pipelineId = selectedEntity.pipelineId || selectedStage?.pipelineId;
      return getTaskTemplates(stageName, pipelineId);
    }

    if (selectedEntity.type === 'lead') {
      return getTaskTemplates(selectedEntity.status);
    }

    if (selectedEntity.type === 'client') {
      return getTaskTemplates(selectedEntity.lifecycle);
    }

    return taskTemplates;
  }, [mode, selectedEntity, selectedStage?.name, selectedStage?.pipelineId, taskTemplates]);

  const applyTemplateDefaults = useCallback(
    (nextTemplateId: string, overrideTitle: boolean, force = false) => {
      const template =
        contextualTemplates.find((t) => t.id === nextTemplateId) ||
        taskTemplates.find((t) => t.id === nextTemplateId);
      if (!template) return;

      const applied = applyTaskTemplate(template);
      setTemplateId(template.id);
      if (force || !hasManualDueDate) {
        setDueDate(formatDateTimeLocal(applied.dueDate));
        setHasManualDueDate(false);
      }
      setSlaMinutes(applied.slaMinutes);
      setSlaAt(applied.slaAt);
      setReminderAt(applied.reminderAt);
      if (overrideTitle || (!title && mode === 'task')) {
        setTitle(applied.title);
      }
    },
    [contextualTemplates, hasManualDueDate, mode, taskTemplates, title]
  );

  useEffect(() => {
    // Avoid synchronous state updates in the effect body; defer to microtask.
    queueMicrotask(() => {
      setTemplateUserSelected(false);
      setHasManualDueDate(false);
    });
  }, [entityId, entityType]);

  useEffect(() => {
    if (mode !== 'task') return;
    const templates = contextualTemplates.length > 0 ? contextualTemplates : taskTemplates;
    const preferred = selectedEntity
      ? getDefaultTaskTemplate(
          selectedEntity.type === 'deal'
            ? selectedEntity.stageName || selectedStage?.name
            : selectedEntity.type === 'lead'
              ? selectedEntity.status
              : selectedEntity.lifecycle,
          selectedEntity.type === 'deal'
            ? selectedEntity.pipelineId || selectedStage?.pipelineId
            : undefined
        )
      : undefined;
    const preferredId = preferred?.id || defaultTemplateId || templates[0]?.id;
    const hasCurrent = templateId && templates.some((template) => template.id === templateId);
    const nextTemplateId =
      !templateUserSelected && preferredId
        ? preferredId
        : hasCurrent
          ? templateId!
          : preferredId;

    if (!nextTemplateId) return;

    // Defer state updates to next tick to avoid setState during render phase of effect
    queueMicrotask(() => {
      applyTemplateDefaults(nextTemplateId, !title, !hasCurrent || !templateUserSelected);
      if (!templateUserSelected) {
        setTemplateUserSelected(false);
      }
    });
  }, [
    applyTemplateDefaults,
    contextualTemplates,
    defaultTemplateId,
    mode,
    selectedEntity,
    selectedStage?.name,
    selectedStage?.pipelineId,
    taskTemplates,
    templateId,
    templateUserSelected,
    title,
  ]);

  const filteredEntities = useMemo(
    () => allEntities.filter((entity) => entity.type === entityType),
    [allEntities, entityType]
  );

  const handleEntityTypeChange = (value: EntityType) => {
    setEntityType(value);
    const first = allEntities.find((e) => e.type === value);
    setEntityId(first?.id || '');
  };

  const handleTemplateChange = (value: string) => {
    setTemplateUserSelected(true);
    applyTemplateDefaults(value, !title, true);
    setError(null);
  };

  const resetForm = () => {
    setTitle('');
    setNote('');
    if (mode === 'task' && templateId) {
      handleTemplateChange(templateId);
    } else {
      setDueDate('');
      setSlaMinutes(undefined);
      setSlaAt(undefined);
      setReminderAt(undefined);
    }
    setHasManualDueDate(false);
    setTemplateUserSelected(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isDisabled) return;
    if (!entityId) {
      setError('Link to a deal, lead, or contact to log activity');
      return;
    }
    if (!title.trim() && !note.trim()) {
      setError('Add a title or note before logging');
      return;
    }

    const payload: QuickActivityInput = {
      type: mode,
      title: title.trim() || (mode === 'note' ? 'Note' : 'Task'),
      note: note.trim(),
      entityType,
      entityId,
      assigneeId: defaultAssignee?.id,
      assigneeName: defaultAssignee?.name,
    };

    if (mode === 'task') {
      const resolvedDue = dueDate ? new Date(dueDate) : new Date(Date.now() + 24 * 60 * 60 * 1000);
      payload.dueDate = resolvedDue;
      payload.templateId = templateId;
      payload.slaMinutes = slaMinutes;
      payload.slaAt = slaAt;
      payload.reminderAt = reminderAt;
    }

    await onCreate(payload);
    resetForm();
    setError(null);
  };

  const templateOptions = contextualTemplates.length > 0 ? contextualTemplates : taskTemplates;

  const onKeyDown = (event: React.KeyboardEvent) => {
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      handleSubmit(event as unknown as React.FormEvent);
    }
  };

  const hasEntities = allEntities.length > 0;

  return (
    <div className="quick-activity-bar" aria-label="Quick activity composer">
      <div className="quick-activity-bar__header">
        <div className="quick-activity-bar__tabs">
          <button
            type="button"
            className={`quick-activity-tab ${mode === 'note' ? 'active' : ''}`}
            onClick={() => setMode('note')}
            disabled={isSubmitting || isDisabled}
          >
            Add Note
          </button>
          <button
            type="button"
            className={`quick-activity-tab ${mode === 'task' ? 'active' : ''}`}
            onClick={() => setMode('task')}
            disabled={isSubmitting || isDisabled}
          >
            Add Task
          </button>
        </div>
        <span className="quick-activity-bar__hint">Ctrl/Cmd+Enter to save</span>
      </div>

      <form className="quick-activity-bar__form" onSubmit={handleSubmit} onKeyDown={onKeyDown}>
        <div className="quick-activity-bar__row">
          <div className="quick-activity-bar__field">
            <label htmlFor="quick-entity-type">Link to</label>
            <select
              id="quick-entity-type"
              value={entityType}
              onChange={(e) => handleEntityTypeChange(e.target.value as EntityType)}
              disabled={!hasEntities || isSubmitting || isDisabled}
              data-testid="quick-entity-type"
            >
              <option value="deal">Opportunity</option>
              <option value="lead">Lead</option>
              <option value="client">Contact</option>
            </select>
          </div>

          <div className="quick-activity-bar__field">
            <label htmlFor="quick-entity-id" className="sr-only">
              Entity
            </label>
            <select
              id="quick-entity-id"
              value={entityId}
              onChange={(e) => setEntityId(e.target.value)}
              disabled={!hasEntities || isSubmitting || isDisabled}
              data-testid="quick-entity-id"
            >
              {filteredEntities.map((entity) => (
                <option key={entity.id} value={entity.id}>
                  {entity.label}
                </option>
              ))}
            </select>
            {!hasEntities && (
              <div className="quick-activity-bar__helper">
                Create an opportunity, lead, or contact to log activity.
              </div>
            )}
          </div>
        </div>

        <div className="quick-activity-bar__row">
          <div className="quick-activity-bar__field quick-activity-bar__field--grow">
            <label htmlFor="quick-title">Title</label>
            <input
              id="quick-title"
              data-testid="quick-title"
              type="text"
              placeholder={mode === 'note' ? 'Add note title...' : 'Add task title...'}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={isSubmitting || isDisabled}
            />
          </div>

          {mode === 'task' && templateOptions.length > 0 && (
            <div className="quick-activity-bar__field">
              <label htmlFor="quick-template">Template</label>
              <select
                id="quick-template"
                value={templateId || templateOptions[0]?.id || ''}
                onChange={(e) => handleTemplateChange(e.target.value)}
                disabled={isSubmitting || isDisabled}
                data-testid="quick-template"
              >
                {templateOptions.map((template) => (
                  <option key={template.id} value={template.id}>
                    {template.label}
                  </option>
                ))}
              </select>
            </div>
          )}

          {mode === 'task' && (
            <div className="quick-activity-bar__field">
              <label htmlFor="quick-due">Due</label>
              <input
                id="quick-due"
                data-testid="quick-due"
                type="datetime-local"
                value={dueDate}
                onChange={(e) => {
                  setDueDate(e.target.value);
                  setHasManualDueDate(true);
                }}
                disabled={isSubmitting || isDisabled}
              />
              {(slaAt || reminderAt) && (
                <div className="quick-activity-bar__helper">
                  {slaAt && <span>SLA: {slaAt.toLocaleString()}</span>}
                  {reminderAt && <span>Reminder: {reminderAt.toLocaleString()}</span>}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="quick-activity-bar__row">
          <div className="quick-activity-bar__field quick-activity-bar__field--grow">
            <label htmlFor="quick-note" className="sr-only">
              Note
            </label>
            <input
              id="quick-note"
              data-testid="quick-note"
              type="text"
              placeholder={mode === 'note' ? 'Add note (optional)...' : 'Add task context (optional)...'}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              disabled={isSubmitting || isDisabled}
            />
          </div>

          <div className="quick-activity-bar__actions">
            {error && (
              <span className="quick-activity-bar__error" role="status">
                {error}
              </span>
            )}
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isSubmitting || isDisabled || !hasEntities}
              data-testid="quick-submit"
            >
              {isSubmitting ? 'Saving...' : mode === 'note' ? 'Log Note' : 'Log Task'}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}

export default QuickActivityBar;
