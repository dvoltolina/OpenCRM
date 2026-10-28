/**
 * TransferOwnershipDialog
 * Dialog for transferring business ownership to an existing admin user.
 * Requires password re-authentication and explicit text confirmation.
 */

import { useState, useEffect } from 'react';

import type { StaffMember } from '../types/models';

type Props = {
  businessName: string;
  adminStaff: StaffMember[];
  currentOwnerId: string;
  onConfirm: (newOwnerId: string, password: string) => Promise<void>;
  onCancel: () => void;
};

export function TransferOwnershipDialog({
  businessName,
  adminStaff,
  currentOwnerId,
  onConfirm,
  onCancel,
}: Props) {
  const [selectedAdminId, setSelectedAdminId] = useState<string>('');
  const [confirmText, setConfirmText] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Filter out current owner from admin list
  const eligibleAdmins = adminStaff.filter((staff) => staff.id !== currentOwnerId);

  useEffect(() => {
    // Reset error when inputs change
    setError(null);
  }, [selectedAdminId, confirmText, password]);

  const isValid =
    selectedAdminId !== '' &&
    confirmText === 'TRANSFER' &&
    password.trim().length > 0;

  const handleConfirm = async () => {
    if (!isValid) return;

    setLoading(true);
    setError(null);

    try {
      await onConfirm(selectedAdminId, password);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to transfer ownership';
      setError(message);
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && isValid && !loading) {
      handleConfirm();
    }
  };

  return (
    <div
      className="dialog-overlay"
      onClick={onCancel}
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
      }}
    >
      <div
        className="dialog"
        onClick={(e) => e.stopPropagation()}
        style={{
          backgroundColor: 'var(--color-surface)',
          borderRadius: 12,
          padding: 24,
          maxWidth: 500,
          width: '90%',
          boxShadow: 'var(--shadow-lg)',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ margin: 0 }}>Warning: Transfer Ownership</h2>
          <button
            type="button"
            onClick={onCancel}
            disabled={loading}
            style={{
              marginLeft: 'auto',
              background: 'none',
              border: 'none',
              fontSize: 24,
              cursor: 'pointer',
              opacity: loading ? 0.5 : 1,
            }}
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <div style={{ marginBottom: 24 }}>
          <p style={{ marginBottom: 16 }}>
            You are about to transfer ownership of <strong>"{businessName}"</strong> to another
            user.
          </p>

          <div
            style={{
              backgroundColor: 'var(--color-warning-bg, #fff4e6)',
              border: '1px solid var(--color-warning, #ff9800)',
              borderRadius: 8,
              padding: 16,
              marginBottom: 16,
            }}
          >
            <p style={{ margin: 0, marginBottom: 8, fontWeight: 600 }}>
              This action is IRREVERSIBLE.
            </p>
            <p style={{ margin: 0, marginBottom: 8 }}>After transfer:</p>
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>You will become an Admin</li>
              <li>The new owner will have full control</li>
              <li>Only the new owner can transfer ownership</li>
              <li>Billing responsibility transfers immediately</li>
            </ul>
          </div>

          {eligibleAdmins.length === 0 ? (
            <div
              style={{
                backgroundColor: 'var(--color-error-bg, #ffebee)',
                border: '1px solid var(--color-error, #f44336)',
                borderRadius: 8,
                padding: 16,
                marginBottom: 16,
              }}
            >
              <p style={{ margin: 0 }}>
                No eligible admins found. You must have at least one user with Admin role to
                transfer ownership.
              </p>
            </div>
          ) : (
            <>
              <div style={{ marginBottom: 16 }}>
                <label
                  htmlFor="new-owner-select"
                  style={{
                    display: 'block',
                    marginBottom: 8,
                    fontWeight: 500,
                  }}
                >
                  Select New Owner
                </label>
                <select
                  id="new-owner-select"
                  className="input"
                  value={selectedAdminId}
                  onChange={(e) => setSelectedAdminId(e.target.value)}
                  disabled={loading}
                  style={{ width: '100%' }}
                >
                  <option value="">-- Select admin user --</option>
                  {eligibleAdmins.map((admin) => (
                    <option key={admin.id} value={admin.id}>
                      {admin.displayName || admin.email}
                      {admin.email && admin.displayName ? ` (${admin.email})` : ''}
                    </option>
                  ))}
                </select>
                <p className="muted" style={{ marginTop: 4, fontSize: 13 }}>
                  Only users with Admin role can become owners
                </p>
              </div>

              <div style={{ marginBottom: 16 }}>
                <label
                  htmlFor="confirm-text"
                  style={{
                    display: 'block',
                    marginBottom: 8,
                    fontWeight: 500,
                  }}
                >
                  Type "TRANSFER" to confirm
                </label>
                <input
                  id="confirm-text"
                  type="text"
                  className="input"
                  value={confirmText}
                  onChange={(e) => setConfirmText(e.target.value)}
                  disabled={loading}
                  placeholder="TRANSFER"
                  onKeyDown={handleKeyDown}
                  style={{ width: '100%' }}
                />
              </div>

              <div style={{ marginBottom: 16 }}>
                <label
                  htmlFor="password-confirm"
                  style={{
                    display: 'block',
                    marginBottom: 8,
                    fontWeight: 500,
                  }}
                >
                  Enter your password
                </label>
                <input
                  id="password-confirm"
                  type="password"
                  className="input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  placeholder="Password"
                  onKeyDown={handleKeyDown}
                  autoComplete="current-password"
                  style={{ width: '100%' }}
                />
              </div>
            </>
          )}

          {error && (
            <div
              style={{
                backgroundColor: 'var(--color-error-bg, #ffebee)',
                border: '1px solid var(--color-error, #f44336)',
                borderRadius: 8,
                padding: 12,
                marginBottom: 16,
              }}
            >
              <p style={{ margin: 0, color: 'var(--color-error, #f44336)' }}>{error}</p>
            </div>
          )}
        </div>

        <div
          className="dialog-actions"
          style={{
            display: 'flex',
            justifyContent: 'flex-end',
            gap: 12,
          }}
        >
          <button
            type="button"
            className="button button--ghost"
            onClick={onCancel}
            disabled={loading}
          >
            Cancel
          </button>
          <button
            type="button"
            className="button button--danger"
            onClick={handleConfirm}
            disabled={!isValid || loading || eligibleAdmins.length === 0}
          >
            {loading ? 'Transferring...' : 'Transfer Ownership'}
          </button>
        </div>
      </div>
    </div>
  );
}
