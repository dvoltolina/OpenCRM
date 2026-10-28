import { useCallback, useId, useState, type ChangeEvent, type DragEvent } from 'react';
import type { DocumentType } from '../../types/documents';

interface DocumentUploaderProps {
  onUpload?: (file: File, options: { name: string; documentType: DocumentType }) => Promise<void> | void;
  associatedEntity?: { type: 'deal' | 'lead' | 'client'; id: string };
  folderId?: string;
  accept?: string;
}

const DEFAULT_TYPE: DocumentType = 'attachment';

export function DocumentUploader({
  onUpload,
  associatedEntity,
  folderId,
  accept,
}: DocumentUploaderProps) {
  const inputId = useId();
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFile = useCallback(
    async (file: File) => {
      if (!file || isUploading) return;
      setError(null);
      setIsUploading(true);
      try {
        await onUpload?.(file, {
          name: file.name,
          documentType: DEFAULT_TYPE,
        });
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Upload failed');
      } finally {
        setIsUploading(false);
      }
    },
    [isUploading, onUpload]
  );

  const handleInputChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      void handleFile(file);
      event.target.value = '';
    }
  };

  const handleDrop = (event: DragEvent<HTMLLabelElement>) => {
    event.preventDefault();
    setIsDragging(false);
    const file = event.dataTransfer.files?.[0];
    if (file) {
      void handleFile(file);
    }
  };

  return (
    <div className="document-uploader">
      <label
        htmlFor={inputId}
        className={`uploader-dropzone ${isDragging ? 'dragging' : ''}`}
        onDragOver={(e) => {
          e.preventDefault();
          setIsDragging(true);
        }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={handleDrop}
      >
        <span className="uploader-dropzone__icon" aria-hidden="true">
          +
        </span>
        <div className="uploader-dropzone__copy">
          <p className="uploader-dropzone__title">
            {isUploading ? 'Uploading document...' : 'Drop a file here or browse from your device'}
          </p>
          <p className="uploader-dropzone__hint">
            Attach signed forms, PDFs, quotes, images, or supporting files.
          </p>
          {associatedEntity && (
            <p className="uploader-meta">
              Linked to {associatedEntity.type} #{associatedEntity.id}
              {folderId ? ` in folder ${folderId}` : ''}
            </p>
          )}
        </div>
        <span className="uploader-dropzone__action" aria-hidden="true">
          {isUploading ? 'Uploading...' : 'Choose file'}
        </span>
        <input
          id={inputId}
          type="file"
          className="uploader-dropzone__input"
          accept={accept}
          onChange={handleInputChange}
          disabled={isUploading}
          aria-label="Upload document"
        />
      </label>
      {error && <div className="uploader-error">Upload failed: {error}</div>}
    </div>
  );
}
