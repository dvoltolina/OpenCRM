/**
 * TenantOverviewPanel
 * Overview of tenant details and recent audit activity.
 */

import type { WorkspaceInfo, BillingProfile } from '../../../types/models';
import type { OpsAuditLog } from '../../../types/ops';

type Props = {
  workspace: WorkspaceInfo;
  billing: BillingProfile | null;
  auditLogs: OpsAuditLog[];
  auditLoading: boolean;
};

export function TenantOverviewPanel({ workspace, billing, auditLogs, auditLoading }: Props) {
  return (
    <div className="stack">
      {/* Workspace Info */}
      <div className="panel">
        <h3>Workspace Info</h3>
        <dl className="data-list">
          <div>
            <dt>Name</dt>
            <dd>{workspace.name}</dd>
          </div>
          <div>
            <dt>Email</dt>
            <dd>{workspace.email || '—'}</dd>
          </div>
          <div>
            <dt>Phone</dt>
            <dd>{workspace.phone || '—'}</dd>
          </div>
          <div>
            <dt>Slug</dt>
            <dd>{workspace.slug || '—'}</dd>
          </div>
          <div>
            <dt>Timezone</dt>
            <dd>{workspace.timezone || 'America/New_York'}</dd>
          </div>
          <div>
            <dt>HIPAA Compliance</dt>
            <dd>{workspace.requiresHipaaCompliance ? 'Yes' : 'No'}</dd>
          </div>
          <div>
            <dt>MFA Enabled</dt>
            <dd>{workspace.mfaEnabled ? 'Yes' : 'No'}</dd>
          </div>
        </dl>
      </div>

      {/* Billing Summary */}
      <div className="panel">
        <h3>Billing Summary</h3>
        {billing ? (
          <dl className="data-list">
            <div>
              <dt>Plan</dt>
              <dd>{billing.planName || billing.planId || '—'}</dd>
            </div>
            <div>
              <dt>Status</dt>
              <dd>
                <span className={`badge badge--${getStatusVariant(billing.status)}`}>
                  {billing.status}
                </span>
              </dd>
            </div>
            <div>
              <dt>Seats</dt>
              <dd>{billing.seats}</dd>
            </div>
            <div>
              <dt>Add-ons</dt>
              <dd>
                {billing.addonIds?.length
                  ? billing.addonIds.join(', ')
                  : '—'}
              </dd>
            </div>
            <div>
              <dt>Renewal Date</dt>
              <dd>{billing.renewalDate || '—'}</dd>
            </div>
            {billing.trialEndsAt && (
              <div>
                <dt>Trial Ends</dt>
                <dd>{billing.trialEndsAt}</dd>
              </div>
            )}
          </dl>
        ) : (
          <p className="muted">No billing profile found.</p>
        )}
      </div>

      {/* Recent Ops Activity */}
      <div className="panel">
        <h3>Recent Ops Activity</h3>
        {auditLoading ? (
          <p className="muted">Loading...</p>
        ) : auditLogs.length === 0 ? (
          <p className="muted">No ops activity recorded for this tenant.</p>
        ) : (
          <div className="stack" style={{ gap: 8 }}>
            {auditLogs.slice(0, 10).map((log) => (
              <div key={log.id} style={{ fontSize: 13, padding: '8px 0', borderBottom: '1px solid var(--color-border)' }}>
                <div>
                  <strong>{formatAction(log.action)}</strong>
                  <span className="muted" style={{ marginLeft: 8 }}>
                    by {log.operatorEmail}
                  </span>
                </div>
                <div className="muted" style={{ fontSize: 11 }}>
                  {formatTimestamp(log.timestamp)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function getStatusVariant(status: string): string {
  switch (status) {
    case 'active':
      return 'success';
    case 'trialing':
      return 'info';
    case 'past_due':
      return 'warn';
    case 'canceled':
      return 'danger';
    default:
      return 'neutral';
  }
}

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
