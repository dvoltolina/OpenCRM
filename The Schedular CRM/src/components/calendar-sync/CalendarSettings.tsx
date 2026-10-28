import { useEffect, useState } from 'react';
import type { CalendarConnection } from '../../types/calendar-sync';

interface CalendarSettingsProps {
  connection: CalendarConnection;
  onSave: (settings: CalendarConnection['settings']) => Promise<void>;
  disabled?: boolean;
}

export function CalendarSettings({ connection, onSave, disabled }: CalendarSettingsProps) {
  const [settings, setSettings] = useState(connection.settings);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setSettings(connection.settings);
  }, [connection.settings]);

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      await onSave(settings);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to save settings');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="calendar-settings">
      <div className="form-grid">
        <label className="form-label">
          Sync Direction
          <select
            value={settings.syncDirection}
            onChange={(e) =>
              setSettings((prev) => ({ ...prev, syncDirection: e.target.value as CalendarConnection['settings']['syncDirection'] }))
            }
            disabled={disabled || saving}
          >
            <option value="bidirectional">Two-way</option>
            <option value="crm_to_calendar">CRM → Calendar</option>
            <option value="calendar_to_crm">Calendar → CRM</option>
          </select>
        </label>

        <label className="form-label">
          Default Calendar ID
          <input
            type="text"
            value={settings.defaultCalendarId}
            onChange={(e) => setSettings((prev) => ({ ...prev, defaultCalendarId: e.target.value }))}
            disabled={disabled || saving}
          />
        </label>

        <label className="form-label checkbox">
          <input
            type="checkbox"
            checked={settings.syncMeetings}
            onChange={(e) => setSettings((prev) => ({ ...prev, syncMeetings: e.target.checked }))}
            disabled={disabled || saving}
          />
          Sync meetings
        </label>

        <label className="form-label checkbox">
          <input
            type="checkbox"
            checked={settings.syncCalls}
            onChange={(e) => setSettings((prev) => ({ ...prev, syncCalls: e.target.checked }))}
            disabled={disabled || saving}
          />
          Sync calls
        </label>

        <label className="form-label checkbox">
          <input
            type="checkbox"
            checked={settings.syncTasks}
            onChange={(e) => setSettings((prev) => ({ ...prev, syncTasks: e.target.checked }))}
            disabled={disabled || saving}
          />
          Sync tasks (as reminders)
        </label>

        <label className="form-label">
          Look back (days)
          <input
            type="number"
            min={0}
            value={settings.lookbackDays}
            onChange={(e) => setSettings((prev) => ({ ...prev, lookbackDays: Number(e.target.value) }))}
            disabled={disabled || saving}
          />
        </label>

        <label className="form-label">
          Look forward (days)
          <input
            type="number"
            min={1}
            value={settings.lookforwardDays}
            onChange={(e) => setSettings((prev) => ({ ...prev, lookforwardDays: Number(e.target.value) }))}
            disabled={disabled || saving}
          />
        </label>
      </div>

      {error && <div className="alert error">{error}</div>}
      <button className="btn btn--secondary" type="button" onClick={handleSave} disabled={disabled || saving}>
        {saving ? 'Saving…' : 'Save settings'}
      </button>
    </div>
  );
}

export default CalendarSettings;
