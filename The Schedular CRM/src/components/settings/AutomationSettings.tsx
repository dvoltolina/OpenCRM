import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAutomationRules, type CreateAutomationInput } from '../../hooks/useAutomationRules';
import type {
  AutomationActionType,
  AutomationTarget,
  AutomationTriggerType,
  AllowedFieldUpdate,
} from '../../types/automation';
import { useAuth } from '../../context/AuthContext';
import { usePipelines } from '../../hooks/usePipelines';
import { useStages } from '../../hooks/useStages';
import {
  entityTypeForTrigger,
  getAvailableActionOptions,
  getTargetOptions,
  leadStatuses,
  triggerOptions,
} from './automation-builder-config';
import { AutomationTriggerFields } from './AutomationTriggerFields';

export function AutomationSettings() {
  const { hasRole } = useAuth();
  const canManageAutomation = hasRole(['owner', 'admin', 'manager']);
  const { rules, loading, error, createRule, toggleRule, simulate } = useAutomationRules();
  const { pipelines, defaultPipeline, isLoading: pipelinesLoading } = usePipelines();
  const [selectedPipelineId, setSelectedPipelineId] = useState<string | undefined>(defaultPipeline?.id);
  const { stages, isLoading: stagesLoading } = useStages(selectedPipelineId);
  const [form, setForm] = useState<CreateAutomationInput>({
    name: '',
    description: '',
    trigger: { type: 'leadCreated' },
    action: {
      type: 'createTask',
      target: 'lead',
      taskTemplate: { title: 'Follow up', activityType: 'task', dueInDays: 1 },
    },
  });
  const [message, setMessage] = useState<string | null>(null);
  const triggerType = form.trigger.type;
  const stageOptions = useMemo(() => stages.map((stage) => ({ value: stage.id, label: stage.name })), [stages]);

  useEffect(() => {
    if (!selectedPipelineId && defaultPipeline) {
      setSelectedPipelineId(defaultPipeline.id);
    }
  }, [selectedPipelineId, defaultPipeline]);

  const updateTrigger = useCallback((updates: Partial<CreateAutomationInput['trigger']>) => {
    setForm((prev) => ({
      ...prev,
      trigger: { ...prev.trigger, ...updates, type: updates.type ?? prev.trigger.type },
    }));
  }, []);

  const handlePipelineChange = useCallback((pipelineId?: string) => {
    setSelectedPipelineId(pipelineId);
    setForm((prev) => ({
      ...prev,
      trigger:
        prev.trigger.type === 'dealStageChanged'
          ? { ...prev.trigger, fromStageId: undefined, toStageId: undefined }
          : prev.trigger,
      action:
        prev.action.type === 'updateField' && prev.action.fieldUpdate?.field === 'stageId'
          ? {
              ...prev.action,
              fieldUpdate: {
                field: prev.action.fieldUpdate?.field ?? 'status',
                value: '',
              },
            }
          : prev.action,
    }));
  }, []);

  const actionType = form.action.type;
  const availableActionOptions = useMemo(
    () => getAvailableActionOptions(triggerType),
    [triggerType]
  );

  const targetOptions = useMemo<{ value: AutomationTarget; label: string }[]>(() => {
    return getTargetOptions(triggerType, actionType);
  }, [actionType, triggerType]);

  useEffect(() => {
    if (targetOptions.length === 0) return;
    const allowedTargets = targetOptions.map((opt) => opt.value);
    if (allowedTargets.includes(form.action.target)) {
      return;
    }
    setForm((prev) => ({
      ...prev,
      action: {
        ...prev.action,
        target: allowedTargets[0],
      },
    }));
  }, [form.action, targetOptions]);

  useEffect(() => {
    const allowedActionTypes = availableActionOptions.map((option) => option.value);
    if (allowedActionTypes.includes(form.action.type)) {
      return;
    }

    setForm((prev) => ({
      ...prev,
      action: {
        ...prev.action,
        type: allowedActionTypes[0],
      },
    }));
  }, [availableActionOptions, form.action.type]);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name) return;
    if (!canManageAutomation) {
      setMessage(null);
      return;
    }
    setMessage(null);
    await createRule(form as CreateAutomationInput);
    setMessage('Automation created');
  };

  const actionFields = useMemo(() => {
    const stageSelectDisabled = !canManageAutomation || stageOptions.length === 0;
    const isStageField = form.action?.fieldUpdate?.field === 'stageId';

    switch (actionType) {
      case 'createTask':
        return (
          <>
            <label className="form-label">
              Task Title
              <input
                className="form-control"
                value={form.action?.taskTemplate?.title || ''}
                disabled={!canManageAutomation}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    action: {
                      ...prev.action,
                      taskTemplate: {
                        ...(prev.action.taskTemplate || { title: '', activityType: 'task' }),
                        title: e.target.value,
                      },
                    },
                  }))
                }
              />
            </label>
            <label className="form-label">
              Due in (days)
              <input
                type="number"
                className="form-control"
                value={form.action?.taskTemplate?.dueInDays ?? 1}
                disabled={!canManageAutomation}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    action: {
                      ...prev.action,
                      taskTemplate: {
                        ...(prev.action.taskTemplate || { title: '', activityType: 'task' }),
                        dueInDays: Number(e.target.value),
                      },
                    },
                  }))
                }
              />
            </label>
          </>
        );
      case 'sendEmailTemplate':
        return (
          <>
            <label className="form-label">
              Template ID
              <input
                className="form-control"
                value={form.action?.emailTemplate?.templateId || ''}
                disabled={!canManageAutomation}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    action: {
                      ...prev.action,
                      emailTemplate: {
                        ...(prev.action.emailTemplate || { templateId: '', recipient: 'lead' }),
                        templateId: e.target.value,
                      },
                    },
                  }))
                }
              />
            </label>
            <label className="form-label">
              Recipient
              <select
                className="form-control"
                value={form.action?.emailTemplate?.recipient || 'lead'}
                disabled={!canManageAutomation}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    action: {
                      ...prev.action,
                      emailTemplate: {
                        ...(prev.action.emailTemplate || { templateId: '', recipient: 'lead' }),
                        recipient: e.target.value as 'lead' | 'contact' | 'assignee' | 'owner',
                      },
                    },
                  }))
                }
              >
                <option value="lead">Lead</option>
                <option value="contact">Contact</option>
                <option value="assignee">Assignee</option>
                <option value="owner">Owner</option>
              </select>
              <small className="text-muted">Only preapproved templates are allowed; delivery respects business email limits.</small>
            </label>
          </>
        );
      case 'addTag':
        return (
          <label className="form-label">
            Tag
            <input
              className="form-control"
              value={form.action?.tag || ''}
              disabled={!canManageAutomation}
              onChange={(e) => setForm((prev) => ({ ...prev, action: { ...prev.action, tag: e.target.value } }))}
            />
          </label>
        );
      case 'updateField':
        return (
          <>
            <label className="form-label">
              Field
              <select
                className="form-control"
                value={form.action?.fieldUpdate?.field || 'status'}
                disabled={!canManageAutomation}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    action: {
                      ...prev.action,
                      fieldUpdate: {
                        field: e.target.value as AllowedFieldUpdate,
                        value: prev.action.fieldUpdate?.value ?? '',
                      },
                    },
                  }))
                }
              >
                <option value="status">Status</option>
                <option value="stageId">Stage</option>
                <option value="assigneeId">Assignee</option>
                <option value="leadSource">Lead Source</option>
                <option value="probability">Probability</option>
              </select>
            </label>
            <label className="form-label">
              Value
              {isStageField ? (
                <>
                  <select
                    className="form-control"
                    value={String(form.action?.fieldUpdate?.value ?? '')}
                    disabled={stageSelectDisabled}
                    onChange={(e) =>
                      setForm((prev) => ({
                        ...prev,
                        action: {
                          ...prev.action,
                          fieldUpdate: {
                            field: prev.action.fieldUpdate?.field ?? 'status',
                            value: e.target.value,
                          },
                        },
                      }))
                    }
                  >
                    <option value="">Select stage</option>
                    {stageOptions.map((stage) => (
                      <option key={stage.value} value={stage.value}>
                        {stage.label}
                      </option>
                    ))}
                  </select>
                  {stagesLoading && <small className="text-muted">Loading stages…</small>}
                  {!stagesLoading && stageOptions.length === 0 && (
                    <small className="text-muted">Add pipeline stages to target stage updates.</small>
                  )}
                </>
              ) : (
                <input
                  className="form-control"
                  value={String(form.action?.fieldUpdate?.value ?? '')}
                  disabled={!canManageAutomation}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      action: {
                        ...prev.action,
                        fieldUpdate: {
                          field: prev.action.fieldUpdate?.field ?? 'status',
                          value: e.target.value,
                        },
                      },
                    }))
                  }
                />
              )}
            </label>
          </>
        );
      default:
        return null;
    }
  }, [actionType, form.action, canManageAutomation, stageOptions, stagesLoading]);

  return (
    <section className="settings-section">
      <div className="card">
        <div className="card-header">
          <h3>Automation Builder (MVP)</h3>
          <p className="text-muted">Define simple trigger → action rules with rate limits and audit logging.</p>
          {!canManageAutomation && (
            <div className="alert warning">
              Automation management is limited to owners, admins, and managers. Contact an admin to make changes.
            </div>
          )}
        </div>
        <form className="card-body form-grid" onSubmit={onSubmit}>
          <label className="form-label">
            Name
            <input
              className="form-control"
              value={form.name || ''}
              disabled={!canManageAutomation}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
              required
            />
          </label>
          <label className="form-label">
            Trigger
            <select
              className="form-control"
              value={triggerType}
              disabled={!canManageAutomation}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  trigger: { type: e.target.value as AutomationTriggerType },
                }))
              }
            >
              {triggerOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </label>
          <AutomationTriggerFields
            triggerType={triggerType}
            trigger={form.trigger}
            canManageAutomation={canManageAutomation}
            leadStatuses={leadStatuses}
            selectedPipelineId={selectedPipelineId}
            pipelinesLoading={pipelinesLoading}
            pipelines={pipelines}
            handlePipelineChange={handlePipelineChange}
            stageOptions={stageOptions}
            stagesLoading={stagesLoading}
            updateTrigger={updateTrigger}
          />
          <label className="form-label">
            Target
            <select
              className="form-control"
              value={form.action?.target || targetOptions[0]?.value || 'lead'}
              disabled={!canManageAutomation}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  action: { ...(prev.action || { type: 'createTask' as AutomationActionType }), target: e.target.value as any },
                }))
              }
            >
              {targetOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </label>
          <label className="form-label">
            Action
            <select
              className="form-control"
              value={actionType}
              disabled={!canManageAutomation}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  action: { ...(prev.action || {}), type: e.target.value as AutomationActionType },
                }))
              }
            >
              {availableActionOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </label>
          {actionFields}
          <button className="button primary" type="submit" disabled={loading || !canManageAutomation}>
            {loading ? 'Saving…' : 'Create Automation'}
          </button>
          {message && <div className="alert success">{message}</div>}
          {error && <div className="alert error">{error}</div>}
        </form>
      </div>

      <div className="card">
        <div className="card-header">
          <h3>Existing Automations</h3>
        </div>
        <div className="card-body">
          {loading && <p className="text-muted">Loading…</p>}
          {!loading && rules.length === 0 && <p className="text-muted">No automations defined yet.</p>}
          {!loading &&
            rules.map((rule) => (
              <div key={rule.id} className="list-row">
                <div>
                  <div className="strong">{rule.name}</div>
                  <div className="text-muted">
                    {rule.trigger.type} → {rule.action.type}
                  </div>
                </div>
                <div className="actions">
                  <button
                    className="button secondary"
                    type="button"
                    disabled={!canManageAutomation}
                    onClick={() => toggleRule(rule.id, rule.status === 'enabled' ? 'disabled' : 'enabled')}
                  >
                    {rule.status === 'enabled' ? 'Disable' : 'Enable'}
                  </button>
                  <button
                    className="button ghost"
                    type="button"
                    disabled={!canManageAutomation}
                    onClick={async () => {
                      const reason = await simulate(rule, {
                        triggerType: rule.trigger.type,
                        entityId: 'preview',
                        entityType: entityTypeForTrigger(rule.trigger.type),
                        correlationId: `dryrun-${rule.id}`,
                        dryRun: true,
                      });
                      setMessage(reason ? `Dry run note: ${reason}` : 'Dry run ready');
                    }}
                  >
                    Dry Run
                  </button>
                </div>
              </div>
            ))}
        </div>
      </div>
    </section>
  );
}
