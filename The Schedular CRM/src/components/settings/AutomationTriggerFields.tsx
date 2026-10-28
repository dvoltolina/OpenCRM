import type { AutomationTrigger, AutomationTriggerType } from '../../types/automation';
import type { LeadStatus } from '../../types/models';

interface AutomationTriggerFieldsProps {
  triggerType: AutomationTriggerType;
  trigger: AutomationTrigger;
  canManageAutomation: boolean;
  leadStatuses: readonly LeadStatus[];
  selectedPipelineId?: string;
  pipelinesLoading: boolean;
  pipelines: Array<{ id: string; name: string }>;
  handlePipelineChange: (pipelineId?: string) => void;
  stageOptions: Array<{ value: string; label: string }>;
  stagesLoading: boolean;
  updateTrigger: (updates: Partial<AutomationTrigger>) => void;
}

export function AutomationTriggerFields({
  triggerType,
  trigger,
  canManageAutomation,
  leadStatuses,
  selectedPipelineId,
  pipelinesLoading,
  pipelines,
  handlePipelineChange,
  stageOptions,
  stagesLoading,
  updateTrigger,
}: AutomationTriggerFieldsProps) {
  switch (triggerType) {
    case 'leadStatusChanged':
      return (
        <>
          <label className="form-label">
            From Status (optional)
            <select
              className="form-control"
              value={trigger?.fromStatus || ''}
              disabled={!canManageAutomation}
              onChange={(e) =>
                updateTrigger({
                  fromStatus: (e.target.value || undefined) as LeadStatus | undefined,
                })
              }
            >
              <option value="">Any</option>
              {leadStatuses.map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </label>
          <label className="form-label">
            To Status (optional)
            <select
              className="form-control"
              value={trigger?.toStatus || ''}
              disabled={!canManageAutomation}
              onChange={(e) =>
                updateTrigger({
                  toStatus: (e.target.value || undefined) as LeadStatus | undefined,
                })
              }
            >
              <option value="">Any</option>
              {leadStatuses.map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </label>
        </>
      );
    case 'dealStageChanged':
      return (
        <>
          <label className="form-label">
            Pipeline for stage filters
            <select
              className="form-control"
              value={selectedPipelineId || ''}
              disabled={!canManageAutomation || pipelinesLoading || pipelines.length === 0}
              onChange={(e) => handlePipelineChange(e.target.value || undefined)}
            >
              <option value="">{pipelinesLoading ? 'Loading…' : 'Select pipeline'}</option>
              {pipelines.map((pipeline) => (
                <option key={pipeline.id} value={pipeline.id}>
                  {pipeline.name}
                </option>
              ))}
            </select>
            {!pipelinesLoading && pipelines.length === 0 && (
              <small className="text-muted">Create a pipeline to filter by stage transitions.</small>
            )}
          </label>
          <label className="form-label">
            From Stage (optional)
            <select
              className="form-control"
              value={trigger?.fromStageId || ''}
              disabled={!canManageAutomation || stageOptions.length === 0}
              onChange={(e) => updateTrigger({ fromStageId: e.target.value || undefined })}
            >
              <option value="">Any stage</option>
              {stageOptions.map((stage) => (
                <option key={stage.value} value={stage.value}>
                  {stage.label}
                </option>
              ))}
            </select>
          </label>
          <label className="form-label">
            To Stage (optional)
            <select
              className="form-control"
              value={trigger?.toStageId || ''}
              disabled={!canManageAutomation || stageOptions.length === 0}
              onChange={(e) => updateTrigger({ toStageId: e.target.value || undefined })}
            >
              <option value="">Any stage</option>
              {stageOptions.map((stage) => (
                <option key={stage.value} value={stage.value}>
                  {stage.label}
                </option>
              ))}
            </select>
            {stagesLoading && <small className="text-muted">Loading stages…</small>}
            {!stagesLoading && stageOptions.length === 0 && (
              <small className="text-muted">Add stages to your pipeline to target stage transitions.</small>
            )}
          </label>
        </>
      );
    case 'taskOverdue':
      return (
        <label className="form-label">
          Overdue Days (0 = due today)
          <input
            type="number"
            min={0}
            className="form-control"
            value={trigger?.overdueDays ?? 1}
            disabled={!canManageAutomation}
            onChange={(e) => updateTrigger({ overdueDays: Number(e.target.value) })}
          />
        </label>
      );
    case 'taskReminder':
      return (
        <label className="form-label">
          Reminder Type (optional)
          <select
            className="form-control"
            value={trigger?.reminderType || ''}
            disabled={!canManageAutomation}
            onChange={(e) =>
              updateTrigger({
                reminderType: (e.target.value || undefined) as 'upcoming' | 'due_today' | 'overdue' | undefined,
              })
            }
          >
            <option value="">Any reminder</option>
            <option value="upcoming">Upcoming</option>
            <option value="due_today">Due Today</option>
            <option value="overdue">Overdue</option>
          </select>
        </label>
      );
    default:
      return null;
  }
}
