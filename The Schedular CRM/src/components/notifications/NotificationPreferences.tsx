/**
 * NotificationPreferences Component
 * Persisted settings for notification delivery and priority categories
 *
 * CRM-44 Implementation
 */

import { useCallback, useEffect, useState } from 'react';
import { useNotificationPreferences } from '../../hooks/useNotificationPreferences';
import type { DigestFrequency, NotificationType } from '../../types/notifications';
import './notifications.css';

interface NotificationPreferencesProps {
  userId: string;
}

function isDigestTimeEnabled(frequency: string) {
  return frequency === 'daily' || frequency === 'weekly';
}

type DraftPreferenceField =
  | 'emailDigestTime'
  | 'quietHoursStart'
  | 'quietHoursEnd'
  | 'timezone';

interface DraftPreferenceValues {
  emailDigestTime: string;
  quietHoursStart: string;
  quietHoursEnd: string;
  timezone: string;
}

function getDraftValues(timezone = 'America/New_York'): DraftPreferenceValues {
  return {
    emailDigestTime: '09:00',
    quietHoursStart: '22:00',
    quietHoursEnd: '08:00',
    timezone,
  };
}

export function NotificationPreferences({ userId: _userId }: NotificationPreferencesProps) {
  const {
    preferences,
    isLoading,
    isSaving,
    error,
    updatePreferences,
    resetPreferences,
  } = useNotificationPreferences();
  const [saveMessage, setSaveMessage] = useState<string | null>(null);
  const [draftValues, setDraftValues] = useState<DraftPreferenceValues>(() => getDraftValues());

  useEffect(() => {
    if (!saveMessage) return undefined;
    const timeout = window.setTimeout(() => setSaveMessage(null), 3000);
    return () => window.clearTimeout(timeout);
  }, [saveMessage]);

  useEffect(() => {
    if (!preferences) return;
    setDraftValues({
      emailDigestTime: preferences.emailDigestTime || '09:00',
      quietHoursStart: preferences.quietHoursStart || '22:00',
      quietHoursEnd: preferences.quietHoursEnd || '08:00',
      timezone: preferences.timezone || 'America/New_York',
    });
  }, [preferences]);

  const showSaveMessage = useCallback((message: string) => {
    setSaveMessage(message);
  }, []);

  const persistUpdate = useCallback(
    async (updater: () => Promise<unknown>, message = 'Preference updated') => {
      try {
        await updater();
        showSaveMessage(message);
      } catch {
        // Hook exposes the error state; no duplicate UI action needed here.
      }
    },
    [showSaveMessage]
  );

  const handleGlobalToggle = useCallback(
    (field: 'emailEnabled' | 'pushEnabled') => {
      if (!preferences) return;

      void persistUpdate(() =>
        updatePreferences({
          [field]: !preferences[field],
        })
      );
    },
    [persistUpdate, preferences, updatePreferences]
  );

  const handleTypeToggle = useCallback(
    (type: NotificationType) => {
      if (!preferences) return;

      const current = preferences.typeSettings[type];
      void persistUpdate(() =>
        updatePreferences({
          typeSettings: {
            [type]: {
              ...current,
              enabled: !current?.enabled,
            },
          },
        })
      );
    },
    [persistUpdate, preferences, updatePreferences]
  );

  const handleFieldChange = useCallback(
    (field: 'emailDigestFrequency', value: DigestFrequency) => {
      void persistUpdate(
        () =>
          updatePreferences({
            [field]: value,
          }),
        'Preferences saved'
      );
    },
    [persistUpdate, updatePreferences]
  );

  const handleDraftChange = useCallback((field: DraftPreferenceField, value: string) => {
    setDraftValues((current) => ({
      ...current,
      [field]: value,
    }));
  }, []);

  const handleDraftCommit = useCallback(
    (field: DraftPreferenceField) => {
      if (!preferences) return;

      const rawValue = draftValues[field];
      const nextValue = field === 'timezone' ? rawValue.trim() || preferences.timezone : rawValue;
      const currentValue = preferences[field] || '';

      if (currentValue === nextValue) {
        return;
      }

      void persistUpdate(
        () =>
          updatePreferences({
            [field]: nextValue,
          }),
        'Preferences saved'
      );
    },
    [draftValues, persistUpdate, preferences, updatePreferences]
  );

  const handleReset = useCallback(() => {
    void persistUpdate(() => resetPreferences(), 'Preferences reset to defaults');
  }, [persistUpdate, resetPreferences]);

  if (isLoading) {
    return (
      <div className="notification-preferences-container">
        <div className="notification-preferences-content">Loading notification preferences...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="notification-preferences-container">
        <div className="notification-error-banner" role="alert">
          {error.message}
        </div>
      </div>
    );
  }

  if (!preferences) {
    return (
      <div className="notification-preferences-container">
        <div className="notification-preferences-content">Notification preferences are unavailable.</div>
      </div>
    );
  }

  return (
    <div className="notification-preferences-container">
      <div className="notification-preferences-header">
        <h2 className="notification-preferences-title">Notification Preferences</h2>
        <p className="notification-preferences-description">
          Configure delivery channels, digest behavior, and high-signal CRM alerts.
        </p>
      </div>

      <div className="notification-preferences-content">
        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="email-notifications" className="preference-label">
              Email Notifications
            </label>
            <p className="preference-description">
              Send CRM alerts to your verified account email.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="email-notifications"
              checked={preferences.emailEnabled}
              onChange={() => handleGlobalToggle('emailEnabled')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="push-notifications" className="preference-label">
              Push Notifications
            </label>
            <p className="preference-description">
              Enable web push for urgent in-app alerts.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="push-notifications"
              checked={preferences.pushEnabled}
              onChange={() => handleGlobalToggle('pushEnabled')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="digest-frequency" className="preference-label">
              Digest Frequency
            </label>
            <p className="preference-description">
              Choose how often batched email digests should be delivered.
            </p>
          </div>
          <select
            id="digest-frequency"
            value={preferences.emailDigestFrequency}
            onChange={(e) => handleFieldChange('emailDigestFrequency', e.target.value as DigestFrequency)}
            disabled={isSaving}
            className="preference-select"
          >
            <option value="off">Off</option>
            <option value="realtime">Realtime</option>
            <option value="hourly">Hourly</option>
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
          </select>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="digest-time" className="preference-label">
              Digest Delivery Time
            </label>
            <p className="preference-description">
              Delivery time for daily or weekly digests.
            </p>
          </div>
          <input
            id="digest-time"
            type="time"
            value={draftValues.emailDigestTime}
            onChange={(e) => handleDraftChange('emailDigestTime', e.target.value)}
            onBlur={() => handleDraftCommit('emailDigestTime')}
            disabled={isSaving || !isDigestTimeEnabled(preferences.emailDigestFrequency)}
            className="preference-select"
          />
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="quiet-hours-start" className="preference-label">
              Quiet Hours Start
            </label>
            <p className="preference-description">
              Suppress non-urgent delivery after this local time.
            </p>
          </div>
          <input
            id="quiet-hours-start"
            type="time"
            value={draftValues.quietHoursStart}
            onChange={(e) => handleDraftChange('quietHoursStart', e.target.value)}
            onBlur={() => handleDraftCommit('quietHoursStart')}
            disabled={isSaving}
            className="preference-select"
          />
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="quiet-hours-end" className="preference-label">
              Quiet Hours End
            </label>
            <p className="preference-description">
              Resume delivery after this local time.
            </p>
          </div>
          <input
            id="quiet-hours-end"
            type="time"
            value={draftValues.quietHoursEnd}
            onChange={(e) => handleDraftChange('quietHoursEnd', e.target.value)}
            onBlur={() => handleDraftCommit('quietHoursEnd')}
            disabled={isSaving}
            className="preference-select"
          />
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="timezone" className="preference-label">
              Timezone
            </label>
            <p className="preference-description">
              Used for digests and quiet-hours evaluation.
            </p>
          </div>
          <input
            id="timezone"
            type="text"
            value={draftValues.timezone}
            onChange={(e) => handleDraftChange('timezone', e.target.value)}
            onBlur={() => handleDraftCommit('timezone')}
            disabled={isSaving}
            className="preference-select"
          />
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="task-due-alerts" className="preference-label">
              Task Due Alerts
            </label>
            <p className="preference-description">
              Notify me when tasks are nearing or past due.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="task-due-alerts"
              checked={preferences.typeSettings.task_due?.enabled ?? true}
              onChange={() => handleTypeToggle('task_due')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="task-assigned-alerts" className="preference-label">
              Task Assignment Alerts
            </label>
            <p className="preference-description">
              Notify me when work is assigned directly to me.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="task-assigned-alerts"
              checked={preferences.typeSettings.task_assigned?.enabled ?? true}
              onChange={() => handleTypeToggle('task_assigned')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="goal-risk-alerts" className="preference-label">
              Goal Risk Alerts
            </label>
            <p className="preference-description">
              Notify me when active goals fall behind pace.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="goal-risk-alerts"
              checked={preferences.typeSettings.goal_at_risk?.enabled ?? true}
              onChange={() => handleTypeToggle('goal_at_risk')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>

        <div className="preference-item">
          <div className="preference-label-group">
            <label htmlFor="system-announcements" className="preference-label">
              System Announcements
            </label>
            <p className="preference-description">
              Keep workspace-wide service and release notices enabled.
            </p>
          </div>
          <label className="preference-toggle">
            <input
              type="checkbox"
              id="system-announcements"
              checked={preferences.typeSettings.system_announcement?.enabled ?? true}
              onChange={() => handleTypeToggle('system_announcement')}
              disabled={isSaving}
              className="preference-toggle-input"
            />
            <span className="preference-toggle-slider" />
          </label>
        </div>
      </div>

      <div className="notification-preferences-footer">
        <button
          type="button"
          onClick={handleReset}
          className="preference-reset-btn"
          disabled={isSaving}
        >
          {isSaving ? 'Saving…' : 'Reset to Defaults'}
        </button>

        {saveMessage && (
          <span className="preference-save-message">
            {saveMessage}
          </span>
        )}
      </div>
    </div>
  );
}
