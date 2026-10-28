import { useEffect, useCallback } from 'react';
import type { WorkspaceInfo } from '../../types/models';

type BaseDialogProps = {
  onClose: () => void;
  onConfirm: () => void;
  confirmationText: string;
  onConfirmationChange: (text: string) => void;
  password?: string;
  onPasswordChange?: (password: string) => void;
  loading: boolean;
  error: string | null;
};

type EnableHipaaDialogProps = BaseDialogProps;
type DisableHipaaDialogProps = BaseDialogProps & {
  password: string;
  onPasswordChange: (password: string) => void;
};
type DataExportDialogProps = {
  workspaceEmail?: string;
  onClose: () => void;
  onConfirm: () => void;
  loading: boolean;
  error: string | null;
};
type DeleteWorkspaceDialogProps = BaseDialogProps & {
  workspaceName?: string;
  password: string;
  onPasswordChange: (password: string) => void;
};

export function EnableHipaaDialog({
  onClose,
  onConfirm,
  confirmationText,
  onConfirmationChange,
  loading,
  error,
}: EnableHipaaDialogProps) {
  // Handle escape key to close dialog
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !loading) {
        onClose();
      }
    },
    [onClose, loading]
  );

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true" aria-labelledby="enable-hipaa-title">
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 id="enable-hipaa-title" style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
          Enable HIPAA Compliance Mode
        </h2>

        <div className="stack" style={{ gap: 16 }}>
          <div>
            <p style={{ fontWeight: 600, marginBottom: 8 }}>Enabling HIPAA mode will:</p>
            <ul style={{ margin: 0, paddingLeft: 20, lineHeight: 1.8 }}>
              <li>Enable audit logging for all PHI access</li>
              <li>Require MFA for all owner/admin accounts</li>
              <li>Enable automatic session timeout (15 min)</li>
              <li>Disable analytics that may contain PHI</li>
              <li>Enable BAA requirements for integrations</li>
            </ul>
          </div>

          <div className="note-box">
            <p style={{ margin: 0 }}>
              This is required for healthcare businesses handling Protected Health Information (PHI).
            </p>
          </div>

          <div>
            <label htmlFor="enable-hipaa-confirm">
              <strong>Type "ENABLE HIPAA" to confirm:</strong>
            </label>
            <input
              id="enable-hipaa-confirm"
              type="text"
              value={confirmationText}
              onChange={(e) => onConfirmationChange(e.target.value)}
              placeholder="ENABLE HIPAA"
              style={{
                marginTop: 8,
                padding: '8px 12px',
                width: '100%',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
              }}
              disabled={loading}
            />
          </div>

          {error && (
            <div
              className="note-box"
              style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
              role="alert"
            >
              {error}
            </div>
          )}

          <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
            <button
              type="button"
              className="button button--ghost"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="button"
              className="button button--primary"
              onClick={onConfirm}
              disabled={loading || confirmationText !== 'ENABLE HIPAA'}
            >
              {loading ? 'Enabling...' : 'Enable HIPAA'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function DisableHipaaDialog({
  onClose,
  onConfirm,
  confirmationText,
  onConfirmationChange,
  password,
  onPasswordChange,
  loading,
  error,
}: DisableHipaaDialogProps) {
  // Handle escape key to close dialog
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !loading) {
        onClose();
      }
    },
    [onClose, loading]
  );

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true" aria-labelledby="disable-hipaa-title">
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 id="disable-hipaa-title" style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
          Warning: Disable HIPAA Compliance Mode
        </h2>

        <div className="stack" style={{ gap: 16 }}>
          <div
            className="note-box"
            style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
          >
            <p style={{ margin: 0, fontWeight: 600 }}>
              WARNING: Disabling HIPAA mode may put your business at risk of non-compliance if you
              handle Protected Health Information.
            </p>
          </div>

          <div>
            <p style={{ fontWeight: 600, marginBottom: 8 }}>This will:</p>
            <ul style={{ margin: 0, paddingLeft: 20, lineHeight: 1.8 }}>
              <li>Remove MFA requirements for staff</li>
              <li>Disable enhanced audit logging</li>
              <li>Remove session timeout restrictions</li>
            </ul>
          </div>

          <div>
            <label htmlFor="disable-hipaa-confirm">
              <strong>Type "DISABLE HIPAA" to confirm:</strong>
            </label>
            <input
              id="disable-hipaa-confirm"
              type="text"
              value={confirmationText}
              onChange={(e) => onConfirmationChange(e.target.value)}
              placeholder="DISABLE HIPAA"
              style={{
                marginTop: 8,
                padding: '8px 12px',
                width: '100%',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
              }}
              disabled={loading}
            />
          </div>

          <div>
            <label htmlFor="disable-hipaa-password">
              <strong>Enter your password:</strong>
            </label>
            <input
              id="disable-hipaa-password"
              type="password"
              value={password}
              onChange={(e) => onPasswordChange(e.target.value)}
              placeholder="Password"
              style={{
                marginTop: 8,
                padding: '8px 12px',
                width: '100%',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
              }}
              disabled={loading}
            />
          </div>

          {error && (
            <div
              className="note-box"
              style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
              role="alert"
            >
              {error}
            </div>
          )}

          <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
            <button
              type="button"
              className="button button--ghost"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="button"
              className="button"
              style={{
                background: '#fee2e2',
                borderColor: '#fca5a5',
                color: '#991b1b',
              }}
              onClick={onConfirm}
              disabled={loading || confirmationText !== 'DISABLE HIPAA' || !password}
            >
              {loading ? 'Disabling...' : 'Disable HIPAA'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function DataExportDialog({
  workspaceEmail,
  onClose,
  onConfirm,
  loading,
  error,
}: DataExportDialogProps) {
  // Handle escape key to close dialog
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !loading) {
        onClose();
      }
    },
    [onClose, loading]
  );

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true" aria-labelledby="data-export-title">
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 id="data-export-title" style={{ marginTop: 0 }}>Request Data Export</h2>

        <div className="stack" style={{ gap: 16 }}>
          <p>
            Your data export will include all business information, client records, appointments,
            payments, and settings. This process typically takes 24-48 hours.
          </p>

          <div className="note-box">
            <p style={{ margin: 0 }}>
              You will receive an email at <strong>{workspaceEmail || 'your registered email'}</strong> with a secure download link when your export is ready.
            </p>
          </div>

          <p className="muted" style={{ fontSize: 13 }}>
            The download link will expire after 7 days for security purposes.
          </p>

          {error && (
            <div
              className="note-box"
              style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
              role="alert"
            >
              {error}
            </div>
          )}

          <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
            <button
              type="button"
              className="button button--ghost"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="button"
              className="button button--primary"
              onClick={onConfirm}
              disabled={loading}
            >
              {loading ? 'Requesting...' : 'Request Export'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function DeleteWorkspaceDialog({
  workspaceName,
  onClose,
  onConfirm,
  confirmationText,
  onConfirmationChange,
  password,
  onPasswordChange,
  loading,
  error,
}: DeleteWorkspaceDialogProps) {
  // Handle escape key to close dialog
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !loading) {
        onClose();
      }
    },
    [onClose, loading]
  );

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true" aria-labelledby="delete-workspace-title">
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2
          id="delete-workspace-title"
          style={{
            marginTop: 0,
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            color: '#991b1b',
          }}
        >
          Warning: Delete Workspace
        </h2>

        <div className="stack" style={{ gap: 16 }}>
          <div
            className="note-box"
            style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
          >
            <p style={{ margin: 0, fontWeight: 600 }}>
              WARNING: This action cannot be undone. All data will be permanently deleted.
            </p>
          </div>

          <div>
            <p style={{ fontWeight: 600, marginBottom: 8 }}>This will permanently delete:</p>
            <ul style={{ margin: 0, paddingLeft: 20, lineHeight: 1.8 }}>
              <li>All client records and appointment history</li>
              <li>All staff accounts and permissions</li>
              <li>All billing and payment data</li>
              <li>All settings and integrations</li>
              <li>The workspace "{workspaceName}"</li>
            </ul>
          </div>

          <div>
            <label htmlFor="delete-workspace-confirm">
              <strong>Type "DELETE MY WORKSPACE" to confirm:</strong>
            </label>
            <input
              id="delete-workspace-confirm"
              type="text"
              value={confirmationText}
              onChange={(e) => onConfirmationChange(e.target.value)}
              placeholder="DELETE MY WORKSPACE"
              style={{
                marginTop: 8,
                padding: '8px 12px',
                width: '100%',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
              }}
              disabled={loading}
            />
          </div>

          <div>
            <label htmlFor="delete-workspace-password">
              <strong>Enter your password:</strong>
            </label>
            <input
              id="delete-workspace-password"
              type="password"
              value={password}
              onChange={(e) => onPasswordChange(e.target.value)}
              placeholder="Password"
              style={{
                marginTop: 8,
                padding: '8px 12px',
                width: '100%',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
              }}
              disabled={loading}
            />
          </div>

          {error && (
            <div
              className="note-box"
              style={{ background: '#fee2e2', borderColor: '#fca5a5', color: '#991b1b' }}
              role="alert"
            >
              {error}
            </div>
          )}

          <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
            <button
              type="button"
              className="button button--ghost"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="button"
              className="button"
              style={{
                background: '#991b1b',
                borderColor: '#991b1b',
                color: '#fff',
              }}
              onClick={onConfirm}
              disabled={loading || confirmationText !== 'DELETE MY WORKSPACE' || !password}
            >
              {loading ? 'Deleting...' : 'Delete Workspace'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Modal styles component
export function ModalStyles() {
  return (
    <style>{`
      .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 20px;
      }

      .modal {
        background: white;
        border-radius: 12px;
        padding: 24px;
        max-width: 500px;
        width: 100%;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
      }

      .stack {
        display: flex;
        flex-direction: column;
      }
    `}</style>
  );
}
