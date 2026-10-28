import type { Document } from '../../types/documents';

interface SignatureStatusProps {
  document: Document;
  onRefresh?: () => void;
}

export function SignatureStatus({ document, onRefresh }: SignatureStatusProps) {
  if (!document.requiresSignature) {
    return <p className="signature-status">No signature required</p>;
  }

  const signers = document.signers || [];

  return (
    <div className="signature-status">
      <div className="signature-status-header">
        <h4>Signature status</h4>
        {onRefresh && (
          <button type="button" onClick={onRefresh}>
            Refresh
          </button>
        )}
      </div>
      {signers.length === 0 && <p className="muted">No signers added yet.</p>}
      {signers.length > 0 && (
        <ul>
          {signers.map((signer) => (
            <li key={signer.email}>
              <div>
                <p>{signer.name}</p>
                <p className="signature-role">{signer.role}</p>
              </div>
              <div className={`signature-badge status-${signer.status}`}>
                {signer.status}
                {signer.signedAt && (
                  <span className="signature-date">
                    {new Date(signer.signedAt).toLocaleDateString()}
                  </span>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
      {document.signedDocumentUrl && (
        <div className="signature-download">
          <a href={document.signedDocumentUrl} target="_blank" rel="noreferrer">
            Download signed copy
          </a>
        </div>
      )}
    </div>
  );
}
