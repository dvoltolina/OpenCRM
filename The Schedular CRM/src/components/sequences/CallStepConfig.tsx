/**
 * CallStepConfig Component
 * Configuration form for call reminder steps
 */

import { useCallback, useMemo } from 'react';
import type { CallStepConfig as CallConfig } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface CallStepConfigProps {
  config: CallConfig | undefined;
  onChange: (config: CallConfig) => void;
  disabled?: boolean;
}

// ============================================
// Component
// ============================================

export function CallStepConfig({
  config,
  onChange,
  disabled = false,
}: CallStepConfigProps) {
  const currentConfig = useMemo<CallConfig>(
    () =>
      config || {
        title: '',
        notes: '',
      },
    [config]
  );

  const handleTitleChange = useCallback(
    (title: string) => {
      onChange({ ...currentConfig, title });
    },
    [currentConfig, onChange]
  );

  const handleNotesChange = useCallback(
    (notes: string) => {
      onChange({ ...currentConfig, notes });
    },
    [currentConfig, onChange]
  );

  return (
    <div className="step-editor__section" data-testid="call-step-config">
      <div className="step-editor__field">
        <label className="step-editor__label" htmlFor="call-title">
          Call Reminder Title
        </label>
        <input
          id="call-title"
          type="text"
          className="step-editor__input"
          placeholder="e.g., Discovery call with prospect"
          value={currentConfig.title}
          onChange={(e) => handleTitleChange(e.target.value)}
          disabled={disabled}
        />
        <span className="step-editor__hint">
          This will create a task to remind you to make the call
        </span>
      </div>

      <div className="step-editor__field">
        <label className="step-editor__label" htmlFor="call-notes">
          Call Script / Notes (optional)
        </label>
        <textarea
          id="call-notes"
          className="step-editor__textarea"
          placeholder="Add talking points, questions to ask, or any notes to reference during the call..."
          value={currentConfig.notes || ''}
          onChange={(e) => handleNotesChange(e.target.value)}
          disabled={disabled}
          rows={6}
        />
        <span className="step-editor__hint">
          These notes will be visible when viewing the task
        </span>
      </div>

      {/* Call Tips */}
      <div
        style={{
          marginTop: '1.5rem',
          padding: '1rem',
          background: 'var(--primary-bg, #eff6ff)',
          borderRadius: '0.5rem',
          border: '1px solid var(--primary-border, #bfdbfe)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '0.5rem',
          }}
        >
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="var(--primary, #3b82f6)"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <path d="M12 16v-4M12 8h.01" />
          </svg>
          <span
            style={{
              fontSize: '0.8125rem',
              fontWeight: '600',
              color: 'var(--primary, #3b82f6)',
            }}
          >
            Call Step Tips
          </span>
        </div>
        <ul
          style={{
            margin: 0,
            paddingLeft: '1.25rem',
            fontSize: '0.8125rem',
            color: 'var(--text-secondary, #6b7280)',
          }}
        >
          <li>Call reminders create a task of type "call" in your task list</li>
          <li>The task will be due on the day the step executes</li>
          <li>Consider adding key talking points to the notes field</li>
        </ul>
      </div>
    </div>
  );
}

export default CallStepConfig;
