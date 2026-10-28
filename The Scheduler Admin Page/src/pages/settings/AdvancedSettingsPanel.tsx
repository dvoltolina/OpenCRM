import { useState } from 'react';
import { isDemoMode } from '../../config/demo';
import type { WorkspaceInfo } from '../../types/models';
import type { AdvancedSettingsState, AdvancedSettingsActions } from '../../hooks/useAdvancedSettings';
import {
  EnableHipaaDialog,
  DisableHipaaDialog,
  DataExportDialog,
  DeleteWorkspaceDialog,
  ModalStyles,
} from './ConfirmationDialogs';

type AdvancedSettingsPanelProps = {
  workspaceInfo: WorkspaceInfo | null;
  state: AdvancedSettingsState;
  actions: AdvancedSettingsActions;
  onRefresh: () => void;
};

type ConfirmationDialog = 'enable-hipaa' | 'disable-hipaa' | 'data-export' | 'delete-workspace' | null;

export function AdvancedSettingsPanel({
  workspaceInfo,
  state,
  actions,
  onRefresh,
}: AdvancedSettingsPanelProps) {
  const [activeDialog, setActiveDialog] = useState<ConfirmationDialog>(null);
  const [confirmationText, setConfirmationText] = useState('');
  const [password, setPassword] = useState('');
  const [dialogError, setDialogError] = useState<string | null>(null);
  const [dialogLoading, setDialogLoading] = useState(false);

  const hipaaEnabled = state.hipaaEnabled;

  // Reset dialog state when closing
  const closeDialog = () => {
    setActiveDialog(null);
    setConfirmationText('');
    setPassword('');
    setDialogError(null);
    setDialogLoading(false);
  };

  // Handle HIPAA enable
  const handleEnableHipaa = async () => {
    if (confirmationText !== 'ENABLE HIPAA') {
      setDialogError('Please type "ENABLE HIPAA" exactly to confirm');
      return;
    }

    setDialogLoading(true);
    setDialogError(null);

    try {
      await actions.toggleHipaa(true);
      closeDialog();
      onRefresh(); // Refresh workspace info to show updated state
    } catch (err) {
      setDialogError(err instanceof Error ? err.message : 'Failed to enable HIPAA mode');
    } finally {
      setDialogLoading(false);
    }
  };

  // Handle HIPAA disable
  const handleDisableHipaa = async () => {
    if (confirmationText !== 'DISABLE HIPAA') {
      setDialogError('Please type "DISABLE HIPAA" exactly to confirm');
      return;
    }

    if (!password) {
      setDialogError('Password is required to disable HIPAA mode');
      return;
    }

    setDialogLoading(true);
    setDialogError(null);

    try {
      // TODO: Re-authenticate user with password before disabling
      // This would call Firebase reauthenticateWithCredential
      // For now, we'll proceed with the toggle
      await actions.toggleHipaa(false);
      closeDialog();
      onRefresh();
    } catch (err) {
      setDialogError(err instanceof Error ? err.message : 'Failed to disable HIPAA mode');
    } finally {
      setDialogLoading(false);
    }
  };

  // Handle data export request
  const handleDataExport = async () => {
    setDialogLoading(true);
    setDialogError(null);

    try {
      await actions.requestExport();
      closeDialog();
      alert('Data export request submitted. You will receive an email when your export is ready.');
    } catch (err) {
      setDialogError(err instanceof Error ? err.message : 'Failed to request data export');
    } finally {
      setDialogLoading(false);
    }
  };

  // Handle workspace deletion
  const handleDeleteWorkspace = async () => {
    if (confirmationText !== 'DELETE MY WORKSPACE') {
      setDialogError('Please type "DELETE MY WORKSPACE" exactly to confirm');
      return;
    }

    if (!password) {
      setDialogError('Password is required to delete workspace');
      return;
    }

    setDialogLoading(true);
    setDialogError(null);

    try {
      // TODO: Re-authenticate user with password before deleting
      await actions.deleteWorkspace();
      closeDialog();
      alert('Workspace deletion initiated. You will be logged out.');
      // TODO: Logout user and redirect
    } catch (err) {
      setDialogError(err instanceof Error ? err.message : 'Failed to delete workspace');
    } finally {
      setDialogLoading(false);
    }
  };

  return (
    <>
      <section className="panel">
        <div className="panel__subheader">
          <div>
            <h2>Advanced Settings</h2>
            <p className="muted">
              Security, compliance, and workspace management settings. Owner access required.
            </p>
          </div>
        </div>

        <div className="stack" style={{ gap: 24 }}>
          {/* HIPAA Compliance Mode */}
          <div>
            <p className="panel__title">HIPAA Compliance Mode</p>
            <p className="muted" style={{ marginBottom: 12 }}>
              Enable enhanced security and audit logging for healthcare businesses handling Protected Health
              Information (PHI).
            </p>

            <div className="note-box" style={{ marginBottom: 12 }}>
              <strong>Current Status:</strong>{' '}
              {hipaaEnabled ? (
                <span style={{ color: '#166534' }}>HIPAA Mode Enabled</span>
              ) : (
                <span style={{ color: '#991b1b' }}>HIPAA Mode Disabled</span>
              )}
            </div>

            {hipaaEnabled ? (
              <button
                type="button"
                className="button button--ghost"
                onClick={() => setActiveDialog('disable-hipaa')}
                disabled={state.loading || isDemoMode}
                title={isDemoMode ? 'HIPAA controls are read-only in demo mode.' : undefined}
              >
                Disable HIPAA Mode
              </button>
            ) : (
              <button
                type="button"
                className="button button--primary"
                onClick={() => setActiveDialog('enable-hipaa')}
                disabled={state.loading || isDemoMode}
                title={isDemoMode ? 'HIPAA controls are read-only in demo mode.' : undefined}
              >
                Enable HIPAA Mode
              </button>
            )}

            <p className="muted" style={{ marginTop: 8, fontSize: 13 }}>
              Changes require confirmation and may affect staff access requirements.
            </p>
          </div>

          {/* Data Export (GDPR/CCPA) */}
          <div>
            <p className="panel__title">Data Export (GDPR/CCPA)</p>
            <p className="muted" style={{ marginBottom: 12 }}>
              Request a complete export of your business data for compliance or migration purposes.
            </p>

            <button
              type="button"
              className="button button--ghost"
              onClick={() => setActiveDialog('data-export')}
              disabled={state.loading || isDemoMode}
              title={isDemoMode ? 'Data export is disabled in demo mode.' : undefined}
            >
              Request Data Export
            </button>

            <p className="muted" style={{ marginTop: 8, fontSize: 13 }}>
              You will receive an email with a download link when your export is ready (typically within 24
              hours).
            </p>
          </div>

          {!isDemoMode && (
            <div style={{ borderTop: '2px solid #fee2e2', paddingTop: 20 }}>
              <p className="panel__title" style={{ color: '#991b1b' }}>
                Danger Zone
              </p>
              <p className="muted" style={{ marginBottom: 12 }}>
                Irreversible actions that will permanently affect your workspace.
              </p>

              <button
                type="button"
                className="button"
                style={{
                  background: '#fee2e2',
                  borderColor: '#fca5a5',
                  color: '#991b1b',
                }}
                onClick={() => setActiveDialog('delete-workspace')}
                disabled={state.loading}
              >
                Delete Workspace
              </button>

              <p className="muted" style={{ marginTop: 8, fontSize: 13, color: '#991b1b' }}>
                This action cannot be undone. All data will be permanently deleted.
              </p>
            </div>
          )}
        </div>

        {state.error && (
          <div
            className="note-box"
            style={{
              marginTop: 16,
              background: '#fee2e2',
              borderColor: '#fca5a5',
              color: '#991b1b',
            }}
            role="alert"
          >
            <strong>Error:</strong> {state.error}
          </div>
        )}
      </section>

      {/* Dialogs */}
      {activeDialog === 'enable-hipaa' && (
        <EnableHipaaDialog
          onClose={closeDialog}
          onConfirm={handleEnableHipaa}
          confirmationText={confirmationText}
          onConfirmationChange={setConfirmationText}
          loading={dialogLoading}
          error={dialogError}
        />
      )}

      {activeDialog === 'disable-hipaa' && (
        <DisableHipaaDialog
          onClose={closeDialog}
          onConfirm={handleDisableHipaa}
          confirmationText={confirmationText}
          onConfirmationChange={setConfirmationText}
          password={password}
          onPasswordChange={setPassword}
          loading={dialogLoading}
          error={dialogError}
        />
      )}

      {activeDialog === 'data-export' && (
        <DataExportDialog
          workspaceEmail={workspaceInfo?.email}
          onClose={closeDialog}
          onConfirm={handleDataExport}
          loading={dialogLoading}
          error={dialogError}
        />
      )}

      {activeDialog === 'delete-workspace' && (
        <DeleteWorkspaceDialog
          workspaceName={workspaceInfo?.name}
          onClose={closeDialog}
          onConfirm={handleDeleteWorkspace}
          confirmationText={confirmationText}
          onConfirmationChange={setConfirmationText}
          password={password}
          onPasswordChange={setPassword}
          loading={dialogLoading}
          error={dialogError}
        />
      )}

      <ModalStyles />
    </>
  );
}
