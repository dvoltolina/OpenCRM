import { useState, useMemo } from 'react';
import { ActivityLogEntry, getActionConfig } from '../data/activityLog';
import { useActivityLog } from '../hooks/useActivityLog';

interface ActivityLogPanelProps {
  userId?: string;
  limit?: number;
  showFilters?: boolean;
  title?: string;
}

/**
 * Activity Log Panel Component
 *
 * Displays activity logs grouped by date with HIPAA-compliant display
 * - Shows entity IDs, never names or PHI
 * - Groups entries by date (Today, Yesterday, This Week, etc.)
 * - Supports filtering by action type
 */
export function ActivityLogPanel({
  userId,
  limit = 50,
  showFilters = true,
  title = 'Activity Log',
}: ActivityLogPanelProps) {
  const [actionFilter, setActionFilter] = useState<string>('');
  const { entries, loading, error, refresh } = useActivityLog({
    userId,
    limit,
    action: actionFilter || undefined,
  });

  // Group entries by date
  const groupedEntries = useMemo(() => {
    const groups: Record<string, ActivityLogEntry[]> = {};

    entries.forEach((entry) => {
      const dateKey = getDateGroupKey(entry.timestamp);
      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(entry);
    });

    return groups;
  }, [entries]);

  // Get sorted group keys
  const groupKeys = useMemo(() => {
    return Object.keys(groupedEntries).sort((a, b) => {
      const order = ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'];
      const aIndex = order.indexOf(a) !== -1 ? order.indexOf(a) : order.length;
      const bIndex = order.indexOf(b) !== -1 ? order.indexOf(b) : order.length;
      return aIndex - bIndex;
    });
  }, [groupedEntries]);

  if (loading && entries.length === 0) {
    return (
      <div className="panel">
        <h2>{title}</h2>
        <p className="muted">Loading activity logs...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="panel panel--alert">
        <h2>{title}</h2>
        <p className="muted">Error: {error}</p>
        <button className="button button--ghost" onClick={() => void refresh()}>
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="panel">
      <div className="panel__subheader">
        <h2 style={{ margin: 0 }}>{title}</h2>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button className="button button--ghost" onClick={() => void refresh()} title="Refresh">
            Refresh
          </button>
        </div>
      </div>

      {showFilters && (
        <div style={{ marginTop: '12px', marginBottom: '12px' }}>
          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            style={{
              padding: '8px 12px',
              borderRadius: '6px',
              border: '1px solid var(--color-border)',
              background: 'var(--color-bg-panel)',
              fontSize: '14px',
            }}
          >
            <option value="">All actions</option>
            <option value="login_success">Login Success</option>
            <option value="login_failure">Login Failure</option>
            <option value="appointment_created">Appointment Created</option>
            <option value="appointment_updated">Appointment Updated</option>
            <option value="appointment_cancelled">Appointment Cancelled</option>
            <option value="client_created">Client Created</option>
            <option value="client_updated">Client Updated</option>
            <option value="staff_invited">Staff Invited</option>
            <option value="role_changed">Role Changed</option>
          </select>
        </div>
      )}

      {entries.length === 0 ? (
        <p className="muted" style={{ marginTop: '16px' }}>
          No activity logs found.
        </p>
      ) : (
        <div className="stack" style={{ marginTop: '16px' }}>
          {groupKeys.map((groupKey) => (
            <div key={groupKey}>
              <h3
                style={{
                  fontSize: '14px',
                  fontWeight: 'bold',
                  color: 'var(--color-text-muted)',
                  marginBottom: '8px',
                  paddingBottom: '4px',
                  borderBottom: '1px solid var(--color-border)',
                }}
              >
                {groupKey}
              </h3>
              <div className="stack">
                {groupedEntries[groupKey].map((entry) => (
                  <ActivityLogItem key={entry.id} entry={entry} />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

interface ActivityLogItemProps {
  entry: ActivityLogEntry;
}

function ActivityLogItem({ entry }: ActivityLogItemProps) {
  const config = getActionConfig(entry.action);

  return (
    <div
      style={{
        display: 'flex',
        gap: '12px',
        padding: '10px 0',
        borderBottom: '1px solid var(--color-border-light)',
      }}
    >
      <div style={{ flex: 1 }}>
        <div style={{ fontWeight: 'semibold', marginBottom: '2px' }}>{config.label}</div>
        <div className="muted" style={{ fontSize: '13px' }}>
          {formatActivityDescription(entry)}
        </div>
      </div>
      <div
        className="muted"
        style={{ fontSize: '13px', flexShrink: 0, textAlign: 'right' }}
        title={entry.timestamp.toLocaleString()}
      >
        {formatTime(entry.timestamp)}
      </div>
    </div>
  );
}

/**
 * Get date group key for an entry
 * Returns: Today, Yesterday, This Week, This Month, or Earlier
 */
function getDateGroupKey(date: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  const entryDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

  if (entryDate.getTime() === today.getTime()) {
    return 'Today';
  }

  if (entryDate.getTime() === yesterday.getTime()) {
    return 'Yesterday';
  }

  const weekAgo = new Date(today);
  weekAgo.setDate(weekAgo.getDate() - 7);
  if (entryDate >= weekAgo) {
    return 'This Week';
  }

  const monthAgo = new Date(today);
  monthAgo.setDate(monthAgo.getDate() - 30);
  if (entryDate >= monthAgo) {
    return 'This Month';
  }

  return 'Earlier';
}

/**
 * Format time for display
 * Shows relative time if recent, otherwise absolute time
 */
function formatTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) {
    return 'Just now';
  }

  if (diffMins < 60) {
    return `${diffMins}m ago`;
  }

  if (diffHours < 24) {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  }

  if (diffDays < 7) {
    return date.toLocaleDateString('en-US', { weekday: 'short', hour: 'numeric', minute: '2-digit' });
  }

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

/**
 * Format activity description
 * CRITICAL: NEVER include PHI - only IDs and metadata
 */
function formatActivityDescription(entry: ActivityLogEntry): string {
  const parts: string[] = [];

  if (entry.entityType && entry.entityId) {
    parts.push(`${entry.entityType} #${entry.entityId.substring(0, 8)}`);
  }

  if (entry.metadata) {
    const metadataStr = Object.entries(entry.metadata)
      .filter(([key]) => !key.toLowerCase().includes('name') && !key.toLowerCase().includes('email'))
      .map(([key, value]) => `${key}: ${value}`)
      .join(', ');

    if (metadataStr) {
      parts.push(metadataStr);
    }
  }

  if (entry.ipAddress) {
    parts.push(`from ${entry.ipAddress}`);
  }

  return parts.length > 0 ? parts.join(' • ') : 'No additional details';
}
