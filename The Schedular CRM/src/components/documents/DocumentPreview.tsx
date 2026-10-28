import { useEffect, useMemo, useState } from 'react';
import type { Document } from '../../types/documents';
import { DocumentService } from '../../services/document-service';
import { useAuth } from '../../context/AuthContext';
import { createSecurityContext } from '../../lib/security-context';

interface DocumentPreviewProps {
  document: Document | null;
  onClose: () => void;
}

export function DocumentPreview({ document, onClose }: DocumentPreviewProps) {
  const { crmUser } = useAuth();
  const service = useMemo(() => new DocumentService(), []);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  useEffect(() => {
    let isActive = true;
    const loadUrl = async () => {
      if (!document || !crmUser) return;
      setLoading(true);
      setError(null);
      try {
        const context = createSecurityContext(crmUser);
        const url = await service.getDownloadUrl(context, document.id);
        if (isActive) {
          setPreviewUrl(url);
        }
      } catch (err) {
        if (isActive) {
          setError(err instanceof Error ? err.message : 'Unable to load document');
          setPreviewUrl(null);
        }
      } finally {
        if (isActive) {
          setLoading(false);
        }
      }
    };

    void loadUrl();
    return () => {
      isActive = false;
    };
  }, [crmUser, document, service]);

  if (!document) return null;

  return (
    <div className="document-preview-backdrop" role="dialog" aria-modal="true">
      <div className="document-preview">
        <div className="document-preview-header">
          <div>
            <p className="document-preview-label">{document.documentType}</p>
            <h3>{document.name}</h3>
            {document.description && <p className="document-preview-description">{document.description}</p>}
          </div>
          <button type="button" onClick={onClose} aria-label="Close preview">
            Close
          </button>
        </div>

        <div className="document-preview-body">
          {loading && <p className="document-preview-loading">Loading preview...</p>}
          {error && <p className="document-preview-error">{error}</p>}
          {!loading && !error && (
            <iframe title={document.name} src={previewUrl || document.storageUrl} className="document-preview-frame" />
          )}
        </div>

        <div className="document-preview-footer">
          <div>
            <p>Version v{document.version}</p>
            <p>Owner: {document.ownerName}</p>
          </div>
          <p>Status: {document.status}</p>
        </div>
      </div>
    </div>
  );
}
