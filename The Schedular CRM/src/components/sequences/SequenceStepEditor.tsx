/**
 * SequenceStepEditor Component
 * Modal for editing step configuration
 */

import { useState, useCallback, useMemo } from 'react';
import { EmailStepConfig } from './EmailStepConfig';
import { TaskStepConfig } from './TaskStepConfig';
import { WaitStepConfig } from './WaitStepConfig';
import { CallStepConfig } from './CallStepConfig';
import type { SequenceStep, SequenceStepType } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceStepEditorProps {
  step: SequenceStep;
  onSave: (step: SequenceStep) => void;
  onCancel: () => void;
  disabled?: boolean;
}

type EmailStepConfigValue = SequenceStep['emailConfig'];
type TaskStepConfigValue = SequenceStep['taskConfig'];
type CallStepConfigValue = SequenceStep['callConfig'];

// ============================================
// Helpers
// ============================================

function getStepTypeName(type: SequenceStepType): string {
  switch (type) {
    case 'email':
      return 'Email Step';
    case 'task':
      return 'Task Step';
    case 'wait':
      return 'Wait Step';
    case 'call_reminder':
      return 'Call Reminder';
    case 'sms':
      return 'SMS Step';
    default:
      return 'Step';
  }
}

// ============================================
// Component
// ============================================

export function SequenceStepEditor({
  step,
  onSave,
  onCancel,
  disabled = false,
}: SequenceStepEditorProps) {
  // Local state for editing
  const [editedStep, setEditedStep] = useState<SequenceStep>({ ...step });

  // Update handlers
  const handleEmailConfigChange = useCallback(
    (config: EmailStepConfigValue) => {
      setEditedStep((prev) => ({ ...prev, emailConfig: config }));
    },
    []
  );

  const handleTaskConfigChange = useCallback(
    (config: TaskStepConfigValue) => {
      setEditedStep((prev) => ({ ...prev, taskConfig: config }));
    },
    []
  );

  const handleCallConfigChange = useCallback(
    (config: CallStepConfigValue) => {
      setEditedStep((prev) => ({ ...prev, callConfig: config }));
    },
    []
  );

  const handleDelayChange = useCallback(
    (delayDays: number, delayHours?: number) => {
      setEditedStep((prev) => ({
        ...prev,
        delayDays,
        delayHours,
      }));
    },
    []
  );

  const handleTimeOfDayChange = useCallback((timeOfDay: string) => {
    setEditedStep((prev) => ({ ...prev, timeOfDay }));
  }, []);

  const handleSkipWeekendsChange = useCallback((skipWeekends: boolean) => {
    setEditedStep((prev) => ({ ...prev, skipWeekends }));
  }, []);

  // Validation
  const validationErrors = useMemo(() => {
    const errors: string[] = [];

    switch (editedStep.type) {
      case 'email':
        if (
          !editedStep.emailConfig?.templateId &&
          (!editedStep.emailConfig?.subject?.trim() || !editedStep.emailConfig?.body?.trim())
        ) {
          errors.push('Email must have a subject and body, or use a template');
        }
        break;
      case 'task':
        if (!editedStep.taskConfig?.title?.trim()) {
          errors.push('Task must have a title');
        }
        break;
      case 'wait':
        if (editedStep.delayDays <= 0 && (!editedStep.delayHours || editedStep.delayHours <= 0)) {
          errors.push('Wait must have a delay greater than 0');
        }
        break;
      case 'call_reminder':
        if (!editedStep.callConfig?.title?.trim()) {
          errors.push('Call reminder must have a title');
        }
        break;
      case 'sms':
        if (!editedStep.smsConfig?.templateId && !editedStep.smsConfig?.body?.trim()) {
          errors.push('SMS must have a message or use a template');
        }
        break;
    }

    return errors;
  }, [editedStep]);

  const isValid = validationErrors.length === 0;

  const handleSave = useCallback(() => {
    if (isValid) {
      onSave(editedStep);
    }
  }, [editedStep, isValid, onSave]);

  return (
    <div className="step-editor-overlay" onClick={onCancel}>
      <div
        className="step-editor"
        onClick={(e) => e.stopPropagation()}
        data-testid="step-editor"
      >
        {/* Header */}
        <div className="step-editor__header">
          <h3 className="step-editor__title">{getStepTypeName(step.type)}</h3>
          <button
            type="button"
            className="step-editor__close-btn"
            onClick={onCancel}
            aria-label="Close"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 6L6 18M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="step-editor__content">
          {/* Timing (for non-wait steps) */}
          {editedStep.type !== 'wait' && (
            <div className="step-editor__field">
              <label className="step-editor__label">Timing</label>
              <div className="step-editor__row">
                <div className="step-editor__field">
                  <label className="step-editor__label" htmlFor="delay-days">
                    Days after previous step
                  </label>
                  <input
                    id="delay-days"
                    type="number"
                    className="step-editor__input"
                    min="0"
                    value={editedStep.delayDays}
                    onChange={(e) =>
                      handleDelayChange(
                        parseInt(e.target.value) || 0,
                        editedStep.delayHours
                      )
                    }
                    disabled={disabled}
                  />
                </div>
                <div className="step-editor__field">
                  <label className="step-editor__label" htmlFor="delay-hours">
                    Hours
                  </label>
                  <input
                    id="delay-hours"
                    type="number"
                    className="step-editor__input"
                    min="0"
                    max="23"
                    value={editedStep.delayHours || 0}
                    onChange={(e) =>
                      handleDelayChange(
                        editedStep.delayDays,
                        parseInt(e.target.value) || 0
                      )
                    }
                    disabled={disabled}
                  />
                </div>
              </div>
              <div className="step-editor__row" style={{ marginTop: '0.75rem' }}>
                <div className="step-editor__field">
                  <label className="step-editor__label" htmlFor="time-of-day">
                    Preferred time of day
                  </label>
                  <input
                    id="time-of-day"
                    type="time"
                    className="step-editor__input"
                    value={editedStep.timeOfDay || ''}
                    onChange={(e) => handleTimeOfDayChange(e.target.value)}
                    disabled={disabled}
                  />
                  <span className="step-editor__hint">Leave empty to use sequence settings</span>
                </div>
                <div className="step-editor__field">
                  <label className="step-editor__checkbox-label">
                    <input
                      type="checkbox"
                      className="step-editor__checkbox"
                      checked={editedStep.skipWeekends || false}
                      onChange={(e) => handleSkipWeekendsChange(e.target.checked)}
                      disabled={disabled}
                    />
                    Skip weekends
                  </label>
                </div>
              </div>
            </div>
          )}

          {/* Type-specific configuration */}
          {editedStep.type === 'email' && (
            <EmailStepConfig
              config={editedStep.emailConfig}
              onChange={handleEmailConfigChange}
              disabled={disabled}
            />
          )}

          {editedStep.type === 'task' && (
            <TaskStepConfig
              config={editedStep.taskConfig}
              onChange={handleTaskConfigChange}
              disabled={disabled}
            />
          )}

          {editedStep.type === 'wait' && (
            <WaitStepConfig
              delayDays={editedStep.delayDays}
              delayHours={editedStep.delayHours}
              onChange={handleDelayChange}
              disabled={disabled}
            />
          )}

          {editedStep.type === 'call_reminder' && (
            <CallStepConfig
              config={editedStep.callConfig}
              onChange={handleCallConfigChange}
              disabled={disabled}
            />
          )}

          {/* Validation Errors */}
          {validationErrors.length > 0 && (
            <div className="step-editor__field">
              {validationErrors.map((error, index) => (
                <p key={index} className="step-editor__error">
                  {error}
                </p>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="step-editor__footer">
          <button
            type="button"
            className="step-editor__cancel-btn"
            onClick={onCancel}
          >
            Cancel
          </button>
          <button
            type="button"
            className="step-editor__save-btn"
            onClick={handleSave}
            disabled={disabled || !isValid}
            data-testid="save-step-btn"
          >
            Save Step
          </button>
        </div>
      </div>
    </div>
  );
}

export default SequenceStepEditor;
