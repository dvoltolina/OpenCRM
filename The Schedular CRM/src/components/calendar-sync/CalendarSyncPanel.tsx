import { useMemo, useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import { useCalendarSync } from '../../hooks/useCalendarSync';
import { ConnectCalendarButton } from './ConnectCalendarButton';
import { CalendarSettings } from './CalendarSettings';
import { SyncStatusBadge } from './SyncStatusBadge';
import { ConflictResolver } from './ConflictResolver';

interface CalendarSyncPanelProps {
  title?: string;
  description?: string;
  showConflicts?: boolean;
}

export function CalendarSyncPanel({
  title = 'Calendar Sync (Google / Outlook)',
  description = 'Sync CRM meetings, calls, and tasks with Google or Outlook. OAuth runs through Cloud Functions; tokens stay encrypted server-side.',
  showConflicts = true,
}: CalendarSyncPanelProps) {
  const features = useMemo(() => getFeatureFlags(), []);
  const calendarSync = useCalendarSync({
    loadConnections: features.enableCalendarSync,
    loadMappings: features.enableCalendarSync && showConflicts,
  });
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [syncingId, setSyncingId] = useState<string | null>(null);

  const handleSync = async (connectionId: string) => {
    setSyncingId(connectionId);
    setStatusMessage(null);
    try {
      const result = await calendarSync.syncConnection(connectionId);
      if (result) {
        const created = result.created || 0;
        const updated = result.updated || 0;
        const successMessage =
          created + updated > 0
            ? `Sync completed (${created} created, ${updated} updated)`
            : 'Sync completed';
        setStatusMessage(result.success ? successMessage : result.errors?.[0] || 'Sync failed');
      }
    } catch (err) {
      setStatusMessage(err instanceof Error ? err.message : 'Sync failed');
    } finally {
      setSyncingId(null);
    }
  };

  const disabled = !calendarSync.configured || calendarSync.loading;

  return (
    <div className="card">
      <div className="card-header">
        <div>
          <h3>{title}</h3>
          <p className="text-muted">{description}</p>
        </div>
        {calendarSync.loading && <span className="text-muted">Loading...</span>}
      </div>
      <div className="card-body">
        {!features.enableCalendarSync && (
          <div className="alert info">Calendar sync is disabled via feature flag.</div>
        )}

        {features.enableCalendarSync && (
          <>
            {!calendarSync.configured && (
              <div className="alert warning">
                Calendar sync requires the shared Scheduler Functions host to resolve from
                `VITE_FUNCTIONS_BASE_URL` or Firebase project config, plus provider OAuth secrets
                configured in the Functions project.
              </div>
            )}
            {calendarSync.error && <div className="alert error">{calendarSync.error}</div>}
            {statusMessage && <div className="alert success">{statusMessage}</div>}

            <ConnectCalendarButton
              onStartOAuth={calendarSync.startOAuth}
              disabled={disabled}
              helperText="Tokens stay encrypted; we never store attendee emails or event details."
            />

            {calendarSync.loading && <div className="text-muted">Loading calendar connections...</div>}
            {!calendarSync.loading && calendarSync.connections.length === 0 && (
              <div className="text-muted">No calendars connected yet.</div>
            )}

            {calendarSync.connections.map((connection) => (
              <div key={connection.id} className="card soft">
                <div className="card-header">
                  <div>
                    <strong>{connection.provider.toUpperCase()}</strong> — {connection.userName}
                    <div className="text-muted">
                      Direction: {connection.settings.syncDirection} • Default calendar:{' '}
                      {connection.settings.defaultCalendarId || 'Not set'}
                    </div>
                  </div>
                  <SyncStatusBadge
                    status={connection.lastSyncStatus}
                    lastSyncAt={connection.lastSyncAt}
                    compact
                  />
                </div>
                <div className="card-body">
                  {connection.lastSyncError && (
                    <div className="alert warning">Last error: {connection.lastSyncError}</div>
                  )}
                  <div className="button-row">
                    <button
                      className="button"
                      onClick={() => handleSync(connection.id)}
                      disabled={calendarSync.loading || syncingId === connection.id}
                    >
                      {syncingId === connection.id ? 'Syncing...' : 'Sync now'}
                    </button>
                    <button
                      className="button"
                      onClick={() => calendarSync.refreshTokens(connection.id)}
                      disabled={calendarSync.loading}
                    >
                      Refresh tokens
                    </button>
                    <button
                      className="button danger"
                      onClick={() => calendarSync.disconnect(connection.id)}
                      disabled={calendarSync.loading}
                    >
                      Disconnect
                    </button>
                  </div>
                  <CalendarSettings
                    connection={connection}
                    onSave={(settings) => calendarSync.updateSettings(connection.id, settings)}
                    disabled={calendarSync.loading}
                  />
                </div>
              </div>
            ))}

            {showConflicts && (
              <ConflictResolver conflicts={calendarSync.conflicts} onResolve={calendarSync.resolveConflict} />
            )}
          </>
        )}
      </div>
    </div>
  );
}

export default CalendarSyncPanel;
