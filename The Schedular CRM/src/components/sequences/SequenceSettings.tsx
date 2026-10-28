/**
 * SequenceSettings Component
 * Sequence-level settings configuration
 */

import { useCallback } from 'react';
import type { SequenceSettings as Settings, SendingSchedule } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceSettingsProps {
  settings: Settings;
  onUpdate: (updates: Partial<Settings>) => void;
  disabled?: boolean;
}

// ============================================
// Constants
// ============================================

const TIMEZONES = [
  { value: 'America/New_York', label: 'Eastern Time (ET)' },
  { value: 'America/Chicago', label: 'Central Time (CT)' },
  { value: 'America/Denver', label: 'Mountain Time (MT)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (PT)' },
  { value: 'America/Phoenix', label: 'Arizona (MST)' },
  { value: 'America/Anchorage', label: 'Alaska (AKT)' },
  { value: 'Pacific/Honolulu', label: 'Hawaii (HST)' },
  { value: 'UTC', label: 'UTC' },
];

const HOURS = Array.from({ length: 24 }, (_, i) => ({
  value: i,
  label: i === 0 ? '12:00 AM' : i < 12 ? `${i}:00 AM` : i === 12 ? '12:00 PM' : `${i - 12}:00 PM`,
}));

const DAYS = [
  { value: 0, label: 'Sunday' },
  { value: 1, label: 'Monday' },
  { value: 2, label: 'Tuesday' },
  { value: 3, label: 'Wednesday' },
  { value: 4, label: 'Thursday' },
  { value: 5, label: 'Friday' },
  { value: 6, label: 'Saturday' },
];

// ============================================
// Toggle Component
// ============================================

interface ToggleProps {
  label: string;
  hint?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  locked?: boolean;
}

function Toggle({ label, hint, checked, onChange, disabled, locked }: ToggleProps) {
  return (
    <div className="sequence-settings__toggle">
      <div>
        <div className="sequence-settings__toggle-label">{label}</div>
        {hint && <div className="sequence-settings__toggle-hint">{hint}</div>}
      </div>
      <button
        type="button"
        className={`sequence-settings__switch ${checked ? 'sequence-settings__switch--active' : ''}`}
        onClick={() => !locked && onChange(!checked)}
        disabled={disabled || locked}
        aria-pressed={checked}
      >
        <div className="sequence-settings__switch-knob" />
      </button>
    </div>
  );
}

// ============================================
// Component
// ============================================

export function SequenceSettings({
  settings,
  onUpdate,
  disabled = false,
}: SequenceSettingsProps) {
  const handleScheduleChange = useCallback(
    (updates: Partial<SendingSchedule>) => {
      onUpdate({
        sendingSchedule: {
          ...settings.sendingSchedule,
          ...updates,
        },
      });
    },
    [settings.sendingSchedule, onUpdate]
  );

  const handleExcludeDayToggle = useCallback(
    (day: number) => {
      const current = settings.sendingSchedule.excludeDays || [];
      const newExcludeDays = current.includes(day)
        ? current.filter((d) => d !== day)
        : [...current, day];
      handleScheduleChange({ excludeDays: newExcludeDays });
    },
    [settings.sendingSchedule.excludeDays, handleScheduleChange]
  );

  return (
    <div className="sequence-settings" data-testid="sequence-settings">
      {/* Sending Schedule */}
      <div className="sequence-settings__section">
        <h4 className="sequence-settings__section-title">Sending Schedule</h4>

        <div className="sequence-settings__field">
          <label className="sequence-settings__label" htmlFor="timezone">
            Timezone
          </label>
          <select
            id="timezone"
            className="sequence-settings__select"
            value={settings.sendingSchedule.timezone}
            onChange={(e) => handleScheduleChange({ timezone: e.target.value })}
            disabled={disabled}
          >
            {TIMEZONES.map((tz) => (
              <option key={tz.value} value={tz.value}>
                {tz.label}
              </option>
            ))}
          </select>
        </div>

        <Toggle
          label="Business hours only"
          hint="Only send during business hours"
          checked={settings.sendingSchedule.businessHoursOnly}
          onChange={(checked) => handleScheduleChange({ businessHoursOnly: checked })}
          disabled={disabled}
        />

        {settings.sendingSchedule.businessHoursOnly && (
          <div className="sequence-settings__row">
            <div className="sequence-settings__field">
              <label className="sequence-settings__label" htmlFor="start-hour">
                Start
              </label>
              <select
                id="start-hour"
                className="sequence-settings__select"
                value={settings.sendingSchedule.startHour}
                onChange={(e) =>
                  handleScheduleChange({ startHour: parseInt(e.target.value) })
                }
                disabled={disabled}
              >
                {HOURS.map((h) => (
                  <option key={h.value} value={h.value}>
                    {h.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="sequence-settings__field">
              <label className="sequence-settings__label" htmlFor="end-hour">
                End
              </label>
              <select
                id="end-hour"
                className="sequence-settings__select"
                value={settings.sendingSchedule.endHour}
                onChange={(e) =>
                  handleScheduleChange({ endHour: parseInt(e.target.value) })
                }
                disabled={disabled}
              >
                {HOURS.map((h) => (
                  <option key={h.value} value={h.value}>
                    {h.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}

        <div className="sequence-settings__field">
          <label className="sequence-settings__label">Exclude Days</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
            {DAYS.map((day) => (
              <label
                key={day.value}
                className="step-editor__checkbox-label"
                style={{
                  padding: '0.25rem 0.5rem',
                  background: (settings.sendingSchedule.excludeDays || []).includes(day.value)
                    ? 'var(--error-bg)'
                    : 'transparent',
                  borderRadius: '0.25rem',
                  fontSize: '0.75rem',
                }}
              >
                <input
                  type="checkbox"
                  className="step-editor__checkbox"
                  checked={(settings.sendingSchedule.excludeDays || []).includes(day.value)}
                  onChange={() => handleExcludeDayToggle(day.value)}
                  disabled={disabled}
                />
                {day.label.slice(0, 3)}
              </label>
            ))}
          </div>
        </div>
      </div>

      {/* Limits */}
      <div className="sequence-settings__section">
        <h4 className="sequence-settings__section-title">Limits</h4>

        <div className="sequence-settings__row">
          <div className="sequence-settings__field">
            <label className="sequence-settings__label" htmlFor="daily-email-limit">
              Daily Email Limit
            </label>
            <input
              id="daily-email-limit"
              type="number"
              className="sequence-settings__input"
              min="1"
              max="500"
              value={settings.dailyEmailLimit || 50}
              onChange={(e) =>
                onUpdate({ dailyEmailLimit: parseInt(e.target.value) || 50 })
              }
              disabled={disabled}
            />
          </div>
          <div className="sequence-settings__field">
            <label className="sequence-settings__label" htmlFor="max-enrollments">
              Max Enrollments/Day
            </label>
            <input
              id="max-enrollments"
              type="number"
              className="sequence-settings__input"
              min="1"
              max="1000"
              value={settings.maxEnrollmentsPerDay || 100}
              onChange={(e) =>
                onUpdate({ maxEnrollmentsPerDay: parseInt(e.target.value) || 100 })
              }
              disabled={disabled}
            />
          </div>
        </div>
      </div>

      {/* Behavior */}
      <div className="sequence-settings__section">
        <h4 className="sequence-settings__section-title">Behavior</h4>

        <Toggle
          label="Pause on reply"
          hint="Pause sequence when contact replies to an email"
          checked={settings.pauseOnReply}
          onChange={(checked) => onUpdate({ pauseOnReply: checked })}
          disabled={disabled}
        />

        <Toggle
          label="Pause on email open"
          hint="Pause when contact opens an email (if tracking enabled)"
          checked={settings.pauseOnOpen}
          onChange={(checked) => onUpdate({ pauseOnOpen: checked })}
          disabled={disabled}
        />

        <Toggle
          label="Exit on meeting booked"
          hint="Remove contact if they book via Scheduler"
          checked={settings.pauseOnMeetingBooked}
          onChange={(checked) => onUpdate({ pauseOnMeetingBooked: checked })}
          disabled={disabled}
        />

        <Toggle
          label="Remove on unsubscribe"
          hint="Always remove contacts who unsubscribe"
          checked={settings.removeOnUnsubscribe}
          onChange={() => {}}
          disabled={disabled}
          locked
        />
      </div>

      {/* Email Threading */}
      <div className="sequence-settings__section">
        <h4 className="sequence-settings__section-title">Email Threading</h4>

        <Toggle
          label="Thread emails"
          hint="Send follow-up emails as replies to the first email"
          checked={settings.threadEmails}
          onChange={(checked) => onUpdate({ threadEmails: checked })}
          disabled={disabled}
        />
      </div>
    </div>
  );
}

export default SequenceSettings;
