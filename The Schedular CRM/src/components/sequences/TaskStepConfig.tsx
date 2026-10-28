/**
 * TaskStepConfig Component
 * Configuration form for task steps
 */

import { useCallback, useMemo } from 'react';
import type { TaskStepConfig as TaskConfig } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface TaskStepConfigProps {
  config: TaskConfig | undefined;
  onChange: (config: TaskConfig) => void;
  disabled?: boolean;
}

// ============================================
// Component
// ============================================

export function TaskStepConfig({
  config,
  onChange,
  disabled = false,
}: TaskStepConfigProps) {
  const currentConfig = useMemo<TaskConfig>(
    () =>
      config || {
        title: '',
        description: '',
        assignToOwner: true,
        dueDays: 0,
      },
    [config]
  );

  const handleTitleChange = useCallback(
    (title: string) => {
      onChange({ ...currentConfig, title });
    },
    [currentConfig, onChange]
  );

  const handleDescriptionChange = useCallback(
    (description: string) => {
      onChange({ ...currentConfig, description });
    },
    [currentConfig, onChange]
  );

  const handleAssignmentChange = useCallback(
    (assignToOwner: boolean) => {
      onChange({ ...currentConfig, assignToOwner });
    },
    [currentConfig, onChange]
  );

  const handleDueDaysChange = useCallback(
    (dueDays: number) => {
      onChange({ ...currentConfig, dueDays });
    },
    [currentConfig, onChange]
  );

  return (
    <div className="step-editor__section" data-testid="task-step-config">
      <div className="step-editor__field">
        <label className="step-editor__label" htmlFor="task-title">
          Task Title
        </label>
        <input
          id="task-title"
          type="text"
          className="step-editor__input"
          placeholder="e.g., Follow up with prospect"
          value={currentConfig.title}
          onChange={(e) => handleTitleChange(e.target.value)}
          disabled={disabled}
        />
      </div>

      <div className="step-editor__field">
        <label className="step-editor__label" htmlFor="task-description">
          Description (optional)
        </label>
        <textarea
          id="task-description"
          className="step-editor__textarea"
          placeholder="Add any notes or context for this task..."
          value={currentConfig.description || ''}
          onChange={(e) => handleDescriptionChange(e.target.value)}
          disabled={disabled}
          rows={3}
        />
      </div>

      <div className="step-editor__field">
        <label className="step-editor__label">Assign To</label>
        <div className="step-editor__row">
          <label className="step-editor__checkbox-label">
            <input
              type="radio"
              name="task-assignment"
              checked={currentConfig.assignToOwner}
              onChange={() => handleAssignmentChange(true)}
              disabled={disabled}
            />
            Sequence owner
          </label>
          <label className="step-editor__checkbox-label">
            <input
              type="radio"
              name="task-assignment"
              checked={!currentConfig.assignToOwner}
              onChange={() => handleAssignmentChange(false)}
              disabled={disabled}
            />
            Contact/lead owner
          </label>
        </div>
        <span className="step-editor__hint">
          {currentConfig.assignToOwner
            ? 'Task will be assigned to whoever owns the sequence'
            : 'Task will be assigned to whoever owns the enrolled contact or lead'}
        </span>
      </div>

      <div className="step-editor__field">
        <label className="step-editor__label" htmlFor="task-due-days">
          Due Date
        </label>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <input
            id="task-due-days"
            type="number"
            className="step-editor__input"
            style={{ width: '80px' }}
            min="0"
            value={currentConfig.dueDays}
            onChange={(e) => handleDueDaysChange(parseInt(e.target.value) || 0)}
            disabled={disabled}
          />
          <span style={{ color: 'var(--text-secondary)' }}>
            day{currentConfig.dueDays !== 1 ? 's' : ''} after step executes
          </span>
        </div>
        <span className="step-editor__hint">
          Set to 0 for same-day due date
        </span>
      </div>
    </div>
  );
}

export default TaskStepConfig;
