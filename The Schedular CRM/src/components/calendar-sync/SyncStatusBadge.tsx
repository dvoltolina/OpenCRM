import type { CalendarConnection, SyncStatus } from '../../types/calendar-sync';

interface SyncStatusBadgeProps {
  status: CalendarConnection['status'] | CalendarConnection['lastSyncStatus'] | SyncStatus;
  lastSyncAt?: Date;
  compact?: boolean;
}

const statusTone: Record<string, string> = {
  active: 'success',
  synced: 'success',
  success: 'success',
  partial: 'warning',
  failed: 'error',
  error: 'error',
  disconnected: 'muted',
  pending: 'warning',
  conflict: 'warning',
};

const statusLabel: Record<string, string> = {
  active: 'Active',
  synced: 'Synced',
  success: 'Synced',
  partial: 'Partial',
  failed: 'Failed',
  error: 'Error',
  disconnected: 'Disconnected',
  pending: 'Pending',
  conflict: 'Conflict',
};

export function SyncStatusBadge({ status, lastSyncAt, compact }: SyncStatusBadgeProps) {
  const tone = statusTone[status] || 'muted';
  const label = statusLabel[status] || status;

  return (
    <div className={`sync-status sync-status--${tone}`}>
      <span className="sync-status__dot" aria-hidden="true" />
      <span className="sync-status__label">{label}</span>
      {!compact && lastSyncAt && (
        <span className="sync-status__meta">Last sync {lastSyncAt.toLocaleString()}</span>
      )}
    </div>
  );
}

export default SyncStatusBadge;
