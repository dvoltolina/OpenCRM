/**
 * OpsAuditPage
 * View all ops audit logs (super-admin only).
 */

import { useOpsAuditLog } from '../../hooks/useOpsAuditLog';

function formatAction(action: string): string {
  return action
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatTimestamp(ts: string): string {
  try {
    return new Date(ts).toLocaleString();
  } catch {
    return ts;
  }
}

function getActionVariant(action: string): string {
  if (action.includes('added') || action.includes('created')) return 'success';
  if (action.includes('removed') || action.includes('ended')) return 'danger';
  if (action.includes('changed') || action.includes('toggled')) return 'warn';
  return 'info';
}

export function OpsAuditPage() {
  const { logs, loading, error, refresh } = useOpsAuditLog(200);

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Ops Portal</p>
          <h1>Audit Log</h1>
          <p className="muted">All operations performed by super-admins.</p>
        </div>
        <div className="header-actions">
          <button
            className="button button--ghost"
            onClick={() => void refresh()}
            disabled={loading}
          >
            {loading ? 'Refreshing...' : 'Refresh'}
          </button>
        </div>
      </header>

      {error && (
        <div className="panel panel--alert" role="alert" style={{ marginBottom: 16 }}>
          <strong>Error:</strong> {error}
        </div>
      )}

      <div className="panel">
        {loading && !logs.length ? (
          <p className="muted">Loading audit logs...</p>
        ) : logs.length === 0 ? (
          <p className="muted">No audit logs found.</p>
        ) : (
          <>
            <div
              className="table__head"
              style={{
                display: 'grid',
                gridTemplateColumns: '180px 1fr 150px 1fr 1fr',
                gap: 12,
              }}
            >
              <span>Timestamp</span>
              <span>Action</span>
              <span>Business</span>
              <span>Operator</span>
              <span>Details</span>
            </div>
            {logs.map((log) => (
              <div
                key={log.id}
                className="table__row"
                style={{
                  display: 'grid',
                  gridTemplateColumns: '180px 1fr 150px 1fr 1fr',
                  gap: 12,
                }}
              >
                <span className="muted" style={{ fontSize: 12 }}>
                  {formatTimestamp(log.timestamp)}
                </span>
                <span>
                  <span className={`badge badge--${getActionVariant(log.action)}`}>
                    {formatAction(log.action)}
                  </span>
                </span>
                <span>
                  <span title={log.businessId} style={{ fontSize: 12 }}>
                    {log.businessName || log.businessId.slice(0, 12) + '...'}
                  </span>
                </span>
                <span className="muted" style={{ fontSize: 12 }}>
                  {log.operatorEmail}
                </span>
                <span className="muted" style={{ fontSize: 11 }}>
                  {log.metadata ? (
                    <code style={{ fontSize: 10 }}>
                      {JSON.stringify(log.metadata).slice(0, 50)}
                      {JSON.stringify(log.metadata).length > 50 ? '...' : ''}
                    </code>
                  ) : (
                    '—'
                  )}
                </span>
              </div>
            ))}
          </>
        )}

        <div className="muted" style={{ marginTop: 16, fontSize: 12 }}>
          Showing {logs.length} logs
        </div>
      </div>
    </section>
  );
}
