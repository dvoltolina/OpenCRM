import type { IntakeForm, IntakeFormField } from '../../types/models';

type PreviewPaneProps = {
  form: IntakeForm | null;
};

const styles = {
  panel: {
    background: 'white',
    borderRadius: 12,
    border: '1px solid #e2e8f0',
    overflow: 'hidden',
  },
  header: {
    padding: '16px 20px',
    borderBottom: '1px solid #f1f5f9',
  },
  title: {
    fontSize: 14,
    fontWeight: 600,
    color: '#1e293b',
    margin: '0 0 4px 0',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  subtitle: {
    fontSize: 12,
    color: '#94a3b8',
    margin: 0,
  },
  previewContainer: {
    padding: 20,
    background: '#f8fafc',
  },
  previewCard: {
    background: 'white',
    borderRadius: 12,
    border: '1px solid #e2e8f0',
    overflow: 'hidden',
    boxShadow: '0 4px 12px rgba(0,0,0,0.05)',
  },
  previewHeader: {
    padding: '20px 24px',
    borderBottom: '1px solid #f1f5f9',
    background: 'linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)',
  },
  previewTitle: {
    fontSize: 18,
    fontWeight: 700,
    color: '#1e293b',
    margin: '0 0 6px 0',
  },
  previewDesc: {
    fontSize: 13,
    color: '#64748b',
    margin: 0,
    lineHeight: 1.5,
  },
  previewBody: {
    padding: 24,
    maxHeight: 400,
    overflowY: 'auto' as const,
  },
  fieldWrapper: {
    marginBottom: 20,
  },
  fieldWrapperHalf: {
    display: 'inline-block',
    width: 'calc(50% - 8px)',
    marginRight: 16,
    verticalAlign: 'top',
  } as React.CSSProperties,
  label: {
    display: 'block',
    fontSize: 13,
    fontWeight: 500,
    color: '#374151',
    marginBottom: 6,
  },
  required: {
    color: '#dc2626',
    marginLeft: 2,
  },
  input: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #d1d5db',
    borderRadius: 8,
    background: '#f9fafb',
    color: '#9ca3af',
  },
  textarea: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #d1d5db',
    borderRadius: 8,
    background: '#f9fafb',
    color: '#9ca3af',
    resize: 'none' as const,
    minHeight: 80,
  },
  select: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #d1d5db',
    borderRadius: 8,
    background: '#f9fafb',
    color: '#9ca3af',
    cursor: 'not-allowed',
  },
  optionsList: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 8,
  },
  optionRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '8px 12px',
    background: '#f9fafb',
    borderRadius: 8,
    border: '1px solid #e5e7eb',
  },
  radioCircle: {
    width: 18,
    height: 18,
    borderRadius: '50%',
    border: '2px solid #d1d5db',
    flexShrink: 0,
  },
  checkboxSquare: {
    width: 18,
    height: 18,
    borderRadius: 4,
    border: '2px solid #d1d5db',
    flexShrink: 0,
  },
  optionText: {
    fontSize: 13,
    color: '#6b7280',
  },
  helperText: {
    fontSize: 11,
    color: '#9ca3af',
    marginTop: 4,
  },
  signaturePad: {
    width: '100%',
    height: 100,
    border: '2px dashed #d1d5db',
    borderRadius: 8,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: '#f9fafb',
  },
  signatureText: {
    fontSize: 13,
    color: '#9ca3af',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  fileUpload: {
    width: '100%',
    padding: '20px',
    border: '2px dashed #d1d5db',
    borderRadius: 8,
    background: '#f9fafb',
    textAlign: 'center' as const,
  },
  conditionalBadge: {
    fontSize: 10,
    color: '#d97706',
    background: '#fef3c7',
    padding: '2px 6px',
    borderRadius: 8,
    marginLeft: 8,
    fontWeight: 500,
  },
  emptyState: {
    textAlign: 'center' as const,
    padding: '32px 16px',
  },
  emptyIcon: {
    width: 48,
    height: 48,
    margin: '0 auto 12px',
    borderRadius: '50%',
    background: '#f1f5f9',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
};

export function PreviewPane({ form }: PreviewPaneProps) {
  if (!form) {
    return (
      <section style={styles.panel} aria-label="Form preview">
        <div style={styles.header}>
          <h3 style={styles.title}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2">
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
              <circle cx="12" cy="12" r="3"/>
            </svg>
            Live Preview
          </h3>
          <p style={styles.subtitle}>See how clients will view your form</p>
        </div>
        <div style={styles.emptyState}>
          <div style={styles.emptyIcon}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <line x1="9" y1="9" x2="15" y2="15"/>
              <line x1="15" y1="9" x2="9" y2="15"/>
            </svg>
          </div>
          <p style={{ color: '#64748b', margin: 0, fontSize: 13 }}>
            Select a form to see the preview
          </p>
        </div>
      </section>
    );
  }

  return (
    <section style={styles.panel} aria-label="Form preview">
      <div style={styles.header}>
        <h3 style={styles.title}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
            <circle cx="12" cy="12" r="3"/>
          </svg>
          Live Preview
        </h3>
        <p style={styles.subtitle}>Client view of your form</p>
      </div>
      <div style={styles.previewContainer}>
        <div style={styles.previewCard}>
          <div style={styles.previewHeader}>
            <h4 style={styles.previewTitle}>{form.name || 'Untitled Form'}</h4>
            {form.description && <p style={styles.previewDesc}>{form.description}</p>}
          </div>
          <div style={styles.previewBody}>
            {!form.fields.length ? (
              <div style={styles.emptyState}>
                <p style={{ color: '#94a3b8', margin: 0, fontSize: 13 }}>
                  Add fields to see the preview
                </p>
              </div>
            ) : (
              form.fields.map((field) => (
                <div
                  key={field.id}
                  style={field.width === 'half' ? styles.fieldWrapperHalf : styles.fieldWrapper}
                >
                  <label style={styles.label}>
                    {field.label}
                    {field.required && <span style={styles.required}>*</span>}
                    {field.conditionalLogic && <span style={styles.conditionalBadge}>Conditional</span>}
                  </label>
                  {renderPreviewInput(field)}
                  {field.helperText && <p style={styles.helperText}>{field.helperText}</p>}
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </section>
  );
}

function renderPreviewInput(field: IntakeFormField) {
  if (field.type === 'textarea') {
    return (
      <textarea
        style={styles.textarea}
        placeholder={field.placeholder || 'Enter your response...'}
        disabled
        rows={3}
      />
    );
  }
  if (field.type === 'dropdown') {
    return (
      <select style={styles.select} disabled>
        <option>{field.placeholder || 'Select an option...'}</option>
        {(field.options ?? []).map((option) => (
          <option key={option}>{option}</option>
        ))}
      </select>
    );
  }
  if (field.type === 'radio') {
    return (
      <div style={styles.optionsList}>
        {(field.options ?? []).map((option) => (
          <div key={option} style={styles.optionRow}>
            <div style={styles.radioCircle} />
            <span style={styles.optionText}>{option}</span>
          </div>
        ))}
      </div>
    );
  }
  if (field.type === 'checkbox') {
    return (
      <div style={styles.optionsList}>
        {(field.options ?? []).map((option) => (
          <div key={option} style={styles.optionRow}>
            <div style={styles.checkboxSquare} />
            <span style={styles.optionText}>{option}</span>
          </div>
        ))}
      </div>
    );
  }
  if (field.type === 'date') {
    return (
      <input
        type="text"
        style={styles.input}
        placeholder="MM/DD/YYYY"
        disabled
      />
    );
  }
  if (field.type === 'file') {
    return (
      <div style={styles.fileUpload}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" style={{ marginBottom: 8 }}>
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="17 8 12 3 7 8"/>
          <line x1="12" y1="3" x2="12" y2="15"/>
        </svg>
        <p style={{ color: '#9ca3af', margin: 0, fontSize: 13 }}>Click to upload or drag and drop</p>
      </div>
    );
  }
  if (field.type === 'signature') {
    return (
      <div style={styles.signaturePad}>
        <div style={styles.signatureText}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25z"/>
            <path d="M20.71 5.63l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83a1 1 0 0 0 0-1.41z"/>
          </svg>
          Sign here
        </div>
      </div>
    );
  }
  return (
    <input
      type="text"
      style={styles.input}
      placeholder={field.placeholder || 'Enter your answer...'}
      disabled
    />
  );
}


