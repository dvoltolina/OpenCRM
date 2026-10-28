type BackupCodesViewProps = {
  backupCodes: string[];
  savedBackupCodes: boolean;
  error?: string | null;
  onToggleSaved: (checked: boolean) => void;
  onCopyCodes: () => void;
  onDownloadCodes: () => void;
  onContinue: () => void;
};

export function BackupCodesView({
  backupCodes,
  savedBackupCodes,
  error,
  onToggleSaved,
  onCopyCodes,
  onDownloadCodes,
  onContinue,
}: BackupCodesViewProps) {
  return (
    <div className="auth-shell">
      <div className="auth-card" role="main" aria-labelledby="backup-codes-title">
        <p className="eyebrow">Account security</p>
        <h1 id="backup-codes-title">Save your backup codes</h1>
        <p className="muted" style={{ marginBottom: 24 }}>
          These codes can be used if you lose access to your authenticator app. Each code works
          only once. Store them in a secure place.
        </p>

        <div
          role="region"
          aria-label="Backup recovery codes"
          style={{
            backgroundColor: '#f5f5f5',
            padding: '16px',
            borderRadius: '8px',
            marginBottom: '16px',
            fontFamily: 'monospace',
            fontSize: '14px',
          }}
        >
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: '8px',
            }}
          >
            {backupCodes.map((code, idx) => (
              <div key={idx} aria-label={`Backup code ${idx + 1}: ${code}`}>
                {idx + 1}. {code}
              </div>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
          <button
            className="button button--secondary"
            type="button"
            onClick={onCopyCodes}
            aria-label="Copy backup codes to clipboard"
          >
            Copy codes
          </button>
          <button
            className="button button--secondary"
            type="button"
            onClick={onDownloadCodes}
            aria-label="Download backup codes as text file"
          >
            Download
          </button>
        </div>

        <label
          className="auth-label"
          htmlFor="saved-backup-codes-checkbox"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            marginBottom: 16,
            cursor: 'pointer',
          }}
        >
          <input
            id="saved-backup-codes-checkbox"
            type="checkbox"
            checked={savedBackupCodes}
            onChange={(e) => onToggleSaved(e.target.checked)}
            aria-required="true"
          />
          I have saved these codes in a secure place
        </label>

        {error ? <p className="error" role="alert" style={{ marginBottom: 12 }}>{error}</p> : null}

        <button
          className="button button--primary"
          type="button"
          onClick={onContinue}
          disabled={!savedBackupCodes}
          aria-label="Continue to dashboard"
        >
          Continue to Dashboard
        </button>
      </div>
    </div>
  );
}
