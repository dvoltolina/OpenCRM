/**
 * WaitStepConfig Component
 * Configuration form for wait/delay steps
 */

import { useCallback } from 'react';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface WaitStepConfigProps {
  delayDays: number;
  delayHours?: number;
  onChange: (delayDays: number, delayHours?: number) => void;
  disabled?: boolean;
}

// ============================================
// Component
// ============================================

export function WaitStepConfig({
  delayDays,
  delayHours,
  onChange,
  disabled = false,
}: WaitStepConfigProps) {
  const handleDaysChange = useCallback(
    (days: number) => {
      onChange(days, delayHours);
    },
    [delayHours, onChange]
  );

  const handleHoursChange = useCallback(
    (hours: number) => {
      onChange(delayDays, hours);
    },
    [delayDays, onChange]
  );

  // Preset buttons for common delays
  const presets = [
    { days: 1, hours: 0, label: '1 day' },
    { days: 2, hours: 0, label: '2 days' },
    { days: 3, hours: 0, label: '3 days' },
    { days: 7, hours: 0, label: '1 week' },
  ];

  const handlePresetClick = useCallback(
    (days: number, hours: number) => {
      onChange(days, hours);
    },
    [onChange]
  );

  const totalHours = delayDays * 24 + (delayHours || 0);
  const displayText = (() => {
    const parts = [];
    if (delayDays > 0) {
      parts.push(`${delayDays} day${delayDays !== 1 ? 's' : ''}`);
    }
    if (delayHours && delayHours > 0) {
      parts.push(`${delayHours} hour${delayHours !== 1 ? 's' : ''}`);
    }
    if (parts.length === 0) {
      return 'No wait time set';
    }
    return `Wait for ${parts.join(' and ')}`;
  })();

  return (
    <div className="step-editor__section" data-testid="wait-step-config">
      <div className="step-editor__field">
        <label className="step-editor__label">Wait Duration</label>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1.5rem',
          background: 'var(--surface-secondary)',
          borderRadius: '0.5rem',
          marginBottom: '1rem',
        }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{
              fontSize: '1.5rem',
              fontWeight: '600',
              color: 'var(--text-primary)',
            }}>
              {displayText}
            </div>
            {totalHours > 0 && (
              <div style={{
                fontSize: '0.75rem',
                color: 'var(--text-tertiary)',
                marginTop: '0.25rem',
              }}>
                ({totalHours} total hours)
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Quick Presets */}
      <div className="step-editor__field">
        <label className="step-editor__label">Quick Select</label>
        <div style={{
          display: 'flex',
          gap: '0.5rem',
          flexWrap: 'wrap',
        }}>
          {presets.map((preset) => (
            <button
              key={preset.label}
              type="button"
              onClick={() => handlePresetClick(preset.days, preset.hours)}
              disabled={disabled}
              style={{
                padding: '0.375rem 0.75rem',
                background:
                  delayDays === preset.days && (delayHours || 0) === preset.hours
                    ? 'var(--primary)'
                    : 'var(--surface)',
                color:
                  delayDays === preset.days && (delayHours || 0) === preset.hours
                    ? 'white'
                    : 'var(--text-primary)',
                border: '1px solid var(--border)',
                borderRadius: '0.375rem',
                fontSize: '0.8125rem',
                cursor: disabled ? 'not-allowed' : 'pointer',
                transition: 'all 0.15s',
              }}
            >
              {preset.label}
            </button>
          ))}
        </div>
      </div>

      {/* Custom Input */}
      <div className="step-editor__field">
        <label className="step-editor__label">Custom Duration</label>
        <div className="step-editor__row">
          <div className="step-editor__field">
            <label className="step-editor__label" htmlFor="wait-days">
              Days
            </label>
            <input
              id="wait-days"
              type="number"
              className="step-editor__input"
              min="0"
              value={delayDays}
              onChange={(e) => handleDaysChange(parseInt(e.target.value) || 0)}
              disabled={disabled}
            />
          </div>
          <div className="step-editor__field">
            <label className="step-editor__label" htmlFor="wait-hours">
              Hours
            </label>
            <input
              id="wait-hours"
              type="number"
              className="step-editor__input"
              min="0"
              max="23"
              value={delayHours || 0}
              onChange={(e) => handleHoursChange(parseInt(e.target.value) || 0)}
              disabled={disabled}
            />
          </div>
        </div>
      </div>

      {totalHours === 0 && (
        <div className="step-editor__error">
          Wait step must have a delay greater than 0
        </div>
      )}
    </div>
  );
}

export default WaitStepConfig;
