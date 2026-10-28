import type { Document } from '../../types/documents';

interface DocumentListProps {
  documents: Document[];
  isLoading?: boolean;
  onSelect?: (document: Document) => void;
  onPreview?: (document: Document) => void;
  onRefresh?: () => void;
  emptyMessage?: string;
}

function formatDocumentLabel(value: string): string {
  return value
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function formatFileSize(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  const size = bytes / 1024 ** exponent;
  return `${size >= 10 || exponent === 0 ? Math.round(size) : size.toFixed(1)} ${units[exponent]}`;
}

function getDocumentStatusClassName(status: Document['status']): string {
  switch (status) {
    case 'signed':
    case 'final':
      return 'document-status-pill--success';
    case 'pending_signature':
      return 'document-status-pill--warning';
    case 'voided':
    case 'expired':
      return 'document-status-pill--danger';
    default:
      return 'document-status-pill--neutral';
  }
}

export function DocumentList({
  documents,
  isLoading,
  onSelect,
  onPreview,
  onRefresh,
  emptyMessage = 'No documents yet. Upload a file to get started.',
}: DocumentListProps) {
  if (isLoading) {
    return <div className="document-list loading">Loading documents...</div>;
  }

  if (!documents || documents.length === 0) {
    return (
      <div className="document-list empty">
        <div className="document-list__empty-copy">
          <h3>No linked documents yet</h3>
          <p>{emptyMessage}</p>
        </div>
        {onRefresh && (
          <button type="button" className="btn btn--secondary btn--sm" onClick={onRefresh}>
            Refresh
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="document-list">
      <div className="document-list-header">
        <div className="document-list-header__copy">
          <h3>Documents</h3>
          <p>
            {documents.length} linked {documents.length === 1 ? 'file' : 'files'}
          </p>
        </div>
        {onRefresh && (
          <button type="button" className="btn btn--secondary btn--sm" onClick={onRefresh}>
            Refresh
          </button>
        )}
      </div>
      <div className="document-table-shell">
        <table className="document-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Status</th>
              <th>Version</th>
              <th>Owner</th>
              <th>Updated</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {documents.map((doc) => (
              <tr
                key={doc.id}
                className={onSelect ? 'document-table__row document-table__row--interactive' : 'document-table__row'}
                onClick={() => onSelect?.(doc)}
              >
                <td>
                  <div className="document-table__name">
                    <span className="document-table__title">{doc.name}</span>
                    <span className="document-table__meta">
                      {doc.fileName} · {formatFileSize(doc.fileSize)}
                    </span>
                  </div>
                </td>
                <td className="document-type">{formatDocumentLabel(doc.documentType)}</td>
                <td>
                  <span className={`document-status-pill ${getDocumentStatusClassName(doc.status)}`}>
                    {formatDocumentLabel(doc.status)}
                  </span>
                </td>
                <td>v{doc.version}</td>
                <td>{doc.ownerName}</td>
                <td>{doc.updatedAt ? new Date(doc.updatedAt).toLocaleString() : '—'}</td>
                <td>
                  <button
                    type="button"
                    className="btn btn--secondary btn--sm"
                    disabled={!onPreview}
                    onClick={(e) => {
                      e.stopPropagation();
                      onPreview?.(doc);
                    }}
                  >
                    Preview
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
