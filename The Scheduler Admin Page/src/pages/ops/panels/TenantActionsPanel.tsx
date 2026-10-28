/**
 * TenantActionsPanel
 * Special actions: owner invite, impersonation placeholder.
 */

import { useState } from 'react';
import { createOwnerInvite, listOpsInvites } from '../../../data/opsInvites';
import { useSuperAdminContext } from '../../../hooks/useSuperAdminContext';
import { ConfirmDialog } from '../../../components/ConfirmDialog';
import type { OpsOwnerInvite } from '../../../types/ops';
import { useEffect, useCallback } from 'react';

type Props = {
  businessId: string;
  tenantName: string;
};

export function TenantActionsPanel({ businessId, tenantName }: Props) {
  const { userId, email } = useSuperAdminContext();
  const [inviteEmail, setInviteEmail] = useState('');
  const [invites, setInvites] = useState<OpsOwnerInvite[]>([]);
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [confirmInvite, setConfirmInvite] = useState(false);

  const loadInvites = useCallback(async () => {
    setLoading(true);
    try {
      const data = await listOpsInvites(businessId);
      setInvites(data);
    } catch (err) {
      console.error('Failed to load invites', err);
    } finally {
      setLoading(false);
    }
  }, [businessId]);

  useEffect(() => {
    void loadInvites();
  }, [loadInvites]);

  const handleCreateInvite = async () => {
    if (!userId || !email || !inviteEmail.trim()) return;

    setCreating(true);
    try {
      await createOwnerInvite(businessId, inviteEmail.trim(), userId, email);
      setInviteEmail('');
      setConfirmInvite(false);
      await loadInvites();
    } catch (err) {
      console.error('Failed to create invite', err);
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="stack">
      {/* Owner Invite */}
      <div className="panel">
        <h3>Create Owner Invite</h3>
        <p className="muted" style={{ marginBottom: 16 }}>
          Send an invitation email to create a new owner for this business.
          The invite expires in 7 days.
        </p>

        <div className="form-group">
          <label htmlFor="invite-email">Email Address</label>
          <input
            type="email"
            id="invite-email"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            placeholder="owner@example.com"
            disabled={creating}
          />
        </div>

        <button
          className="button button--primary"
          onClick={() => setConfirmInvite(true)}
          disabled={creating || !inviteEmail.trim()}
        >
          {creating ? 'Creating...' : 'Send Invite'}
        </button>

        {/* Pending Invites */}
        {invites.length > 0 && (
          <div style={{ marginTop: 24 }}>
            <h4>Pending Invites</h4>
            <div className="stack" style={{ gap: 8 }}>
              {invites.map((inv) => (
                <div
                  key={inv.id}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    padding: '8px 0',
                    borderBottom: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <strong>{inv.email}</strong>
                    <br />
                    <span className="muted" style={{ fontSize: 11 }}>
                      Expires: {new Date(inv.expiresAt).toLocaleDateString()}
                    </span>
                  </div>
                  <span className={`badge badge--${getStatusVariant(inv.status)}`}>
                    {inv.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Impersonation Placeholder */}
      <div className="panel">
        <h3>Impersonation</h3>
        <p className="muted">
          Impersonation allows you to view the app as if you were logged in as
          a user from this business. This feature requires additional backend
          configuration.
        </p>
        <button className="button button--ghost" disabled>
          Start Impersonation (Coming Soon)
        </button>
        <p className="muted" style={{ marginTop: 12, fontSize: 11 }}>
          All impersonation sessions are audit-logged.
        </p>
      </div>

      {/* Danger Zone */}
      <div className="panel panel--danger" style={{ borderColor: 'var(--color-danger)' }}>
        <h3 style={{ color: 'var(--color-danger)' }}>Danger Zone</h3>
        <p className="muted">
          These actions are irreversible and require additional confirmation.
        </p>
        <button className="button button--danger" disabled>
          Suspend Business (Not Implemented)
        </button>
      </div>

      {/* Confirm Invite Dialog */}
      {confirmInvite && (
        <ConfirmDialog
          title="Create Owner Invite"
          message={`Send an owner invitation to "${inviteEmail}" for business "${tenantName}"?`}
          onConfirm={handleCreateInvite}
          onCancel={() => setConfirmInvite(false)}
          confirmLabel="Send Invite"
        />
      )}
    </div>
  );
}

function getStatusVariant(status: string): string {
  switch (status) {
    case 'pending':
      return 'warn';
    case 'accepted':
      return 'success';
    case 'expired':
    case 'revoked':
      return 'danger';
    default:
      return 'neutral';
  }
}
