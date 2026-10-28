import type { ChangeEvent, DragEvent, RefObject } from 'react';

type EntityType = 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment';

interface ImportUploadStepProps {
  entityType: EntityType;
  isDragging: boolean;
  fileInputRef: RefObject<HTMLInputElement | null>;
  onFileInputChange: (event: ChangeEvent<HTMLInputElement>) => void;
  onDragOver: (event: DragEvent) => void;
  onDragLeave: (event: DragEvent) => void;
  onDrop: (event: DragEvent) => void;
  onClickUpload: () => void;
}

const requiredFieldsByEntity: Record<EntityType, string[]> = {
  lead: ['First name', 'Last name', 'Email address'],
  contact: ['First name', 'Last name', 'Email address'],
  deal: ['Title', 'Value'],
  company: ['Company name'],
  client: ['First name', 'Last name', 'Email address'],
  appointment: ['Client email', 'Start time'],
};

export function ImportUploadStep({
  entityType,
  isDragging,
  fileInputRef,
  onFileInputChange,
  onDragOver,
  onDragLeave,
  onDrop,
  onClickUpload,
}: ImportUploadStepProps) {
  const requiredFields = requiredFieldsByEntity[entityType];

  return (
    <div className="import-step-content import-upload-step">
      <div
        className={`file-dropzone ${isDragging ? 'dragging' : ''}`}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
        onClick={onClickUpload}
        role="button"
        tabIndex={0}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            onClickUpload();
          }
        }}
      >
        <div className="dropzone-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z" />
            <path d="M14 3v5h5" />
            <path d="M12 17V10" />
            <path d="m9.5 12.5 2.5-2.5 2.5 2.5" />
          </svg>
        </div>
        <div className="dropzone-text">
          <p className="dropzone-title">Drop a CSV file to begin</p>
          <p>or click to browse from your computer</p>
        </div>
        <p className="dropzone-hint">Accepted format: `.csv`</p>
        <input
          ref={fileInputRef}
          type="file"
          accept=".csv"
          onChange={onFileInputChange}
          style={{ display: 'none' }}
        />
      </div>

      <div className="import-callout import-callout--warning" role="note">
        <div className="import-callout__icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M12 9v4" />
            <path d="M12 17h.01" />
            <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" />
          </svg>
        </div>
        <div>
          <p className="import-callout__title">HIPAA compliance notice</p>
          <p className="import-callout__copy">
            Do not import files containing Protected Health Information, patient names, diagnoses,
            medical records, or other health-related data. Remove any PHI columns before uploading.
          </p>
        </div>
      </div>

      <div className="import-instructions">
        <div className="import-instructions__header">
          <h3>Prepare the file</h3>
          <p>Use a clean CSV with consistent column names before moving into field review.</p>
        </div>

        <div className="import-instructions__grid">
          <section className="import-instructions__panel">
            <h4>CSV requirements</h4>
            <ul>
              <li>Use the first row for column headers.</li>
              <li>Keep dates in `MM/DD/YYYY`, `YYYY-MM-DD`, or `DD-MM-YYYY` format.</li>
              <li>Currency values may include `$` signs and commas.</li>
              <li>Review duplicates before importing if email or phone values overlap.</li>
            </ul>
          </section>

          <section className="import-instructions__panel">
            <h4>Required fields</h4>
            <ul>
              {requiredFields.map((field) => (
                <li key={field}>{field}</li>
              ))}
            </ul>
          </section>
        </div>

        {entityType === 'contact' ? (
          <div className="import-callout import-callout--info">
            <div>
              <p className="import-callout__title">Contact imports can create linked records</p>
              <p className="import-callout__copy">
                Contacts are created for each valid row. Deals are only created when deal fields
                are present, and companies are created or linked when company data is included.
              </p>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
