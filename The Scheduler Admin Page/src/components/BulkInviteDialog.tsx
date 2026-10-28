import { useRef } from 'react';
import { useBulkInvite } from '../hooks/useBulkInvite';
import { generateCsvTemplate } from '../lib/csvParser';

type BulkInviteDialogProps = {
  onClose: () => void;
};

/**
 * Multi-step dialog for bulk staff invites via CSV.
 * Steps: Upload -> Preview -> Sending -> Done
 * HIPAA Note: All audit logging happens in the data layer with counts only.
 */
export function BulkInviteDialog({ onClose }: BulkInviteDialogProps) {
  const { step, parsedData, result, loading, error, handleFileUpload, sendInvites, goBack } =
    useBulkInvite();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleFileUpload(file);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();

    const file = e.dataTransfer.files?.[0];
    if (file && file.type === 'text/csv') {
      handleFileUpload(file);
    } else if (file) {
      alert('Please upload a CSV file');
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDownloadTemplate = () => {
    const template = generateCsvTemplate();
    const blob = new Blob([template], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'bulk-invite-template.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const handleClose = () => {
    if (!loading) {
      onClose();
    }
  };

  return (
    <div className="dialog-overlay" onClick={handleClose}>
      <div className="dialog" onClick={(e) => e.stopPropagation()}>
        <header className="dialog__header">
          <h2>
            {step === 'upload' && 'Bulk Invite Team Members'}
            {step === 'preview' && 'Review Invites'}
            {step === 'sending' && 'Sending Invites...'}
            {step === 'done' && 'Invites Sent'}
          </h2>
          {!loading && (
            <button className="dialog__close" onClick={handleClose} aria-label="Close">
              x
            </button>
          )}
        </header>

        <div className="dialog__body">
          {/* Step 1: Upload */}
          {step === 'upload' && (
            <>
              <p className="muted" style={{ marginBottom: 24 }}>
                Upload a CSV file with team member details.
              </p>

              <div
                className="file-drop-zone"
                onClick={() => fileInputRef.current?.click()}
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                style={{
                  border: '2px dashed #ccc',
                  borderRadius: 8,
                  padding: 48,
                  textAlign: 'center',
                  cursor: 'pointer',
                  marginBottom: 24,
                }}
              >
                <p style={{ margin: 0, fontWeight: 500 }}>Drop CSV file here</p>
                <p className="muted" style={{ margin: '4px 0 0 0', fontSize: 14 }}>
                  or click to browse
                </p>
              </div>

              <input
                ref={fileInputRef}
                type="file"
                accept=".csv"
                onChange={handleFileSelect}
                style={{ display: 'none' }}
              />

              <div className="panel" style={{ padding: 16, marginBottom: 24 }}>
                <p className="eyebrow" style={{ marginBottom: 8 }}>
                  Expected format:
                </p>
                <pre
                  style={{
                    fontSize: 13,
                    margin: 0,
                    padding: 12,
                    background: '#f5f5f5',
                    borderRadius: 4,
                    overflow: 'auto',
                  }}
                >
                  {`email,role,name
john@example.com,staff,John Smith
jane@example.com,admin,Jane Doe`}
                </pre>
              </div>

              <button
                className="button button--secondary"
                onClick={handleDownloadTemplate}
                style={{ marginBottom: 16, width: '100%' }}
              >
                Download Template
              </button>

              <p className="muted" style={{ fontSize: 13, margin: 0 }}>
                <strong>Allowed roles:</strong> admin, manager, staff, sales, provider, frontDesk
              </p>

              {error && (
                <div className="panel panel--alert" style={{ marginTop: 16 }}>
                  <p style={{ margin: 0 }}>{error}</p>
                </div>
              )}
            </>
          )}

          {/* Step 2: Preview */}
          {step === 'preview' && parsedData && (
            <>
              <div style={{ marginBottom: 24 }}>
                <p style={{ margin: 0, fontSize: 15 }}>
                  Found <strong>{parsedData.valid.length + parsedData.invalid.length}</strong>{' '}
                  entries.{' '}
                  <strong style={{ color: '#10b981' }}>{parsedData.valid.length} valid</strong>
                  {parsedData.invalid.length > 0 && (
                    <>
                      , <strong style={{ color: '#ef4444' }}>{parsedData.invalid.length}</strong>{' '}
                      with errors.
                    </>
                  )}
                </p>
              </div>

              <div
                style={{
                  maxHeight: 400,
                  overflowY: 'auto',
                  border: '1px solid #e5e5e5',
                  borderRadius: 8,
                  marginBottom: 24,
                }}
              >
                {/* Valid invites */}
                {parsedData.valid.map((invite, idx) => (
                  <div
                    key={idx}
                    style={{
                      padding: '12px 16px',
                      borderBottom: '1px solid #f5f5f5',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 12,
                    }}
                  >
                    <span
                      aria-hidden="true"
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        background: '#10b981',
                        flexShrink: 0,
                        marginTop: 6,
                      }}
                    />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500 }}>
                        {invite.name || invite.email}
                        {invite.name && (
                          <span className="muted" style={{ marginLeft: 8, fontWeight: 400 }}>
                            ({invite.email})
                          </span>
                        )}
                      </div>
                      <div className="muted" style={{ fontSize: 13 }}>
                        Role: {invite.role}
                      </div>
                    </div>
                  </div>
                ))}

                {/* Invalid invites */}
                {parsedData.invalid.map((item, idx) => (
                  <div
                    key={`invalid-${idx}`}
                    style={{
                      padding: '12px 16px',
                      borderBottom: '1px solid #f5f5f5',
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: 12,
                    }}
                  >
                    <span
                      aria-hidden="true"
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        background: '#ef4444',
                        flexShrink: 0,
                        marginTop: 6,
                      }}
                    />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500 }}>
                        {item.data.email || '(no email)'}
                        {item.data.role && (
                          <span className="muted" style={{ marginLeft: 8, fontWeight: 400 }}>
                            {item.data.role}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 13, color: '#ef4444', marginTop: 4 }}>
                        Row {item.row}: {item.error}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {parsedData.invalid.length > 0 && (
                <div className="panel panel--alert" style={{ marginBottom: 24 }}>
                  <p style={{ margin: 0 }}>
                    Warning: {parsedData.invalid.length} entries will be skipped due to errors.
                  </p>
                </div>
              )}

              {error && (
                <div className="panel panel--alert" style={{ marginBottom: 16 }}>
                  <p style={{ margin: 0 }}>{error}</p>
                </div>
              )}
            </>
          )}

          {/* Step 3: Sending */}
          {step === 'sending' && (
            <div style={{ textAlign: 'center', padding: 48 }}>
              <div
                style={{
                  width: 48,
                  height: 48,
                  border: '4px solid #f3f3f3',
                  borderTop: '4px solid #3b82f6',
                  borderRadius: '50%',
                  margin: '0 auto 24px',
                  animation: 'spin 1s linear infinite',
                }}
              />
              <p style={{ margin: 0, fontSize: 16 }}>Sending invites...</p>
            </div>
          )}

          {/* Step 4: Done */}
          {step === 'done' && result && (
            <>
              {result.success && result.sent > 0 ? (
                <>
                  <p style={{ textAlign: 'center', fontSize: 16, marginBottom: 8 }}>
                    Successfully sent <strong>{result.sent}</strong> invites!
                  </p>
                  <p className="muted" style={{ textAlign: 'center', margin: 0 }}>
                    Invites have been sent to the email addresses. Team members will receive
                    instructions to join.
                  </p>
                </>
              ) : (
                <>
                  <p style={{ textAlign: 'center', fontSize: 16, marginBottom: 8 }}>
                    Failed to send invites
                  </p>
                  <p className="muted" style={{ textAlign: 'center', margin: 0 }}>
                    {result.failed} invites failed to send. Please try again.
                  </p>
                </>
              )}
            </>
          )}
        </div>

        <footer className="dialog__footer">
          {step === 'upload' && (
            <button className="button button--secondary" onClick={handleClose} disabled={loading}>
              Cancel
            </button>
          )}

          {step === 'preview' && parsedData && (
            <>
              <button className="button button--secondary" onClick={goBack} disabled={loading}>
                Back
              </button>
              <button
                className="button button--primary"
                onClick={sendInvites}
                disabled={loading || parsedData.valid.length === 0}
              >
                Send {parsedData.valid.length} Invite{parsedData.valid.length !== 1 ? 's' : ''}
              </button>
            </>
          )}

          {step === 'done' && (
            <button className="button button--primary" onClick={handleClose}>
              Done
            </button>
          )}
        </footer>
      </div>

      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
