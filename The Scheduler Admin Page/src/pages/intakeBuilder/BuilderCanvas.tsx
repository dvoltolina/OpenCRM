import type { DragEvent } from 'react';

import type { IntakeForm, IntakeFormField } from '../../types/models';

type BuilderCanvasProps = {
  form: IntakeForm | null;
  activeFieldId: string | null;
  onSelectField: (id: string | null) => void;
  onUpdateField: (fieldId: string, updates: Partial<IntakeFormField>) => void;
  onRemoveField: (fieldId: string) => void;
  onReorder: (sourceId: string, targetId: string) => void;
  onDuplicateField: (fieldId: string) => void;
};

const styles = {
  container: {
    padding: '0 24px 24px',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  title: {
    fontSize: 14,
    fontWeight: 600,
    color: '#1e293b',
    margin: 0,
  },
  subtitle: {
    fontSize: 12,
    color: '#94a3b8',
    margin: 0,
  },
  fieldCount: {
    fontSize: 12,
    color: '#64748b',
    background: '#f1f5f9',
    padding: '4px 10px',
    borderRadius: 12,
  },
  emptyState: {
    textAlign: 'center' as const,
    padding: '48px 24px',
    background: '#f8fafc',
    borderRadius: 12,
    border: '2px dashed #e2e8f0',
  },
  emptyIcon: {
    width: 56,
    height: 56,
    margin: '0 auto 16px',
    borderRadius: '50%',
    background: 'white',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
  },
  fieldList: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 12,
  },
  fieldCard: {
    background: 'white',
    border: '1px solid #e2e8f0',
    borderRadius: 12,
    overflow: 'hidden',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
  },
  fieldCardActive: {
    border: '2px solid #4f46e5',
    boxShadow: '0 0 0 3px rgba(79, 70, 229, 0.1)',
  },
  fieldHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '12px 16px',
    background: '#f8fafc',
    borderBottom: '1px solid #f1f5f9',
  },
  fieldHeaderLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
  },
  dragHandle: {
    color: '#94a3b8',
    cursor: 'grab',
    padding: 4,
    display: 'flex',
  },
  fieldLabel: {
    fontSize: 14,
    fontWeight: 600,
    color: '#1e293b',
    margin: 0,
  },
  typeBadge: {
    fontSize: 11,
    fontWeight: 500,
    color: '#4f46e5',
    background: '#e0e7ff',
    padding: '2px 8px',
    borderRadius: 10,
  },
  conditionalBadge: {
    fontSize: 11,
    fontWeight: 500,
    color: '#d97706',
    background: '#fef3c7',
    padding: '2px 8px',
    borderRadius: 10,
    marginLeft: 6,
  },
  requiredBadge: {
    fontSize: 11,
    fontWeight: 500,
    color: '#dc2626',
    background: '#fef2f2',
    padding: '2px 8px',
    borderRadius: 10,
    marginLeft: 6,
  },
  fieldActions: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
  },
  actionBtn: {
    padding: '6px 10px',
    fontSize: 12,
    fontWeight: 500,
    color: '#64748b',
    background: 'white',
    border: '1px solid #e2e8f0',
    borderRadius: 6,
    cursor: 'pointer',
    transition: 'all 0.15s ease',
  },
  actionBtnDanger: {
    color: '#dc2626',
    borderColor: '#fecaca',
  },
  fieldBody: {
    padding: 16,
  },
  fieldRow: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 12,
    marginBottom: 12,
  } as React.CSSProperties,
  fieldRowFull: {
    gridColumn: '1 / -1',
  },
  inputGroup: {
    marginBottom: 0,
  },
  inputLabel: {
    display: 'block',
    fontSize: 12,
    fontWeight: 500,
    color: '#475569',
    marginBottom: 6,
  },
  input: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #e2e8f0',
    borderRadius: 8,
    background: 'white',
    transition: 'border-color 0.2s ease',
    outline: 'none',
  },
  select: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #e2e8f0',
    borderRadius: 8,
    background: 'white',
    cursor: 'pointer',
  },
  textarea: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 14,
    border: '1px solid #e2e8f0',
    borderRadius: 8,
    background: 'white',
    resize: 'vertical' as const,
    minHeight: 80,
    fontFamily: 'inherit',
  },
  checkboxRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '8px 0',
  },
  checkbox: {
    width: 18,
    height: 18,
    cursor: 'pointer',
  },
  checkboxLabel: {
    fontSize: 13,
    color: '#475569',
    cursor: 'pointer',
  },
  optionsSection: {
    marginTop: 12,
    padding: 16,
    background: '#f8fafc',
    borderRadius: 8,
  },
  optionsHint: {
    fontSize: 11,
    color: '#94a3b8',
    marginTop: 6,
  },
};

// Drag handle icon
const DragIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
    <circle cx="9" cy="6" r="2"/>
    <circle cx="15" cy="6" r="2"/>
    <circle cx="9" cy="12" r="2"/>
    <circle cx="15" cy="12" r="2"/>
    <circle cx="9" cy="18" r="2"/>
    <circle cx="15" cy="18" r="2"/>
  </svg>
);

export function BuilderCanvas({
  form,
  activeFieldId,
  onSelectField,
  onUpdateField,
  onRemoveField,
  onReorder,
  onDuplicateField,
}: BuilderCanvasProps) {
  if (!form) {
    return null;
  }

  const handleDrag = (event: DragEvent<HTMLDivElement>, fieldId: string) => {
    event.dataTransfer.setData('text/plain', fieldId);
  };

  const handleDrop = (event: DragEvent<HTMLDivElement>, targetId: string) => {
    event.preventDefault();
    const sourceId = event.dataTransfer.getData('text/plain');
    if (sourceId) {
      onReorder(sourceId, targetId);
    }
  };

  if (!form.fields.length) {
    return (
      <div style={styles.container}>
        <div style={styles.header}>
          <div>
            <h3 style={styles.title}>Form Fields</h3>
            <p style={styles.subtitle}>Drag and drop to reorder</p>
          </div>
        </div>
        <div style={styles.emptyState}>
          <div style={styles.emptyIcon}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <line x1="12" y1="8" x2="12" y2="16"/>
              <line x1="8" y1="12" x2="16" y2="12"/>
            </svg>
          </div>
          <h4 style={{ color: '#475569', margin: '0 0 8px', fontWeight: 600 }}>No fields yet</h4>
          <p style={{ color: '#94a3b8', margin: 0, fontSize: 13 }}>
            Use the palette above to add text inputs, dropdowns, checkboxes, and more
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <div>
          <h3 style={styles.title}>Form Fields</h3>
          <p style={styles.subtitle}>Click to edit, drag to reorder</p>
        </div>
        <span style={styles.fieldCount}>{form.fields.length} field{form.fields.length !== 1 ? 's' : ''}</span>
      </div>
      <div style={styles.fieldList} role="list" aria-label="Form fields">
        {form.fields.map((field, index) => {
          const isActive = field.id === activeFieldId;
          const isChoiceField = ['dropdown', 'radio', 'checkbox'].includes(field.type);
          return (
            <div
              key={field.id}
              style={{
                ...styles.fieldCard,
                ...(isActive ? styles.fieldCardActive : {}),
              }}
              draggable
              onDragStart={(event) => handleDrag(event, field.id)}
              onDragOver={(event) => event.preventDefault()}
              onDrop={(event) => handleDrop(event, field.id)}
              onClick={() => onSelectField(field.id)}
              role="listitem"
              aria-label={`Field ${index + 1}: ${field.label || 'Untitled field'}`}
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  onSelectField(field.id);
                }
              }}
            >
              <div style={styles.fieldHeader}>
                <div style={styles.fieldHeaderLeft}>
                  <div style={styles.dragHandle} aria-hidden="true">
                    <DragIcon />
                  </div>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <p style={styles.fieldLabel}>{field.label || 'Untitled field'}</p>
                      <span style={styles.typeBadge}>{field.type}</span>
                      {field.required && <span style={styles.requiredBadge}>Required</span>}
                      {field.conditionalLogic && <span style={styles.conditionalBadge}>Conditional</span>}
                    </div>
                  </div>
                </div>
                <div style={styles.fieldActions}>
                  <button
                    type="button"
                    style={styles.actionBtn}
                    onClick={(e) => {
                      e.stopPropagation();
                      onDuplicateField(field.id);
                    }}
                    aria-label={`Duplicate field`}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ marginRight: 4 }}>
                      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                    </svg>
                    Copy
                  </button>
                  <button
                    type="button"
                    style={{ ...styles.actionBtn, ...styles.actionBtnDanger }}
                    onClick={(e) => {
                      e.stopPropagation();
                      onRemoveField(field.id);
                    }}
                    aria-label={`Remove field`}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ marginRight: 4 }}>
                      <polyline points="3 6 5 6 21 6"/>
                      <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                    </svg>
                    Delete
                  </button>
                </div>
              </div>
              {isActive && (
                <div style={styles.fieldBody}>
                  <div style={styles.fieldRow}>
                    <div style={styles.inputGroup}>
                      <label style={styles.inputLabel} htmlFor={`field-label-${field.id}`}>
                        Field Label
                      </label>
                      <input
                        id={`field-label-${field.id}`}
                        type="text"
                        style={styles.input}
                        value={field.label}
                        onChange={(e) => onUpdateField(field.id, { label: e.target.value })}
                        placeholder="e.g., What is your name?"
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                    <div style={styles.inputGroup}>
                      <label style={styles.inputLabel} htmlFor={`field-placeholder-${field.id}`}>
                        Placeholder Text
                      </label>
                      <input
                        id={`field-placeholder-${field.id}`}
                        type="text"
                        style={styles.input}
                        value={field.placeholder ?? ''}
                        onChange={(e) => onUpdateField(field.id, { placeholder: e.target.value })}
                        placeholder="e.g., Enter your answer"
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                  </div>
                  <div style={styles.fieldRow}>
                    <div style={styles.inputGroup}>
                      <label style={styles.inputLabel} htmlFor={`field-helper-${field.id}`}>
                        Helper Text (optional)
                      </label>
                      <input
                        id={`field-helper-${field.id}`}
                        type="text"
                        style={styles.input}
                        value={field.helperText ?? ''}
                        onChange={(e) => onUpdateField(field.id, { helperText: e.target.value })}
                        placeholder="Additional instructions for the client"
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                    <div style={styles.inputGroup}>
                      <label style={styles.inputLabel} htmlFor={`field-width-${field.id}`}>
                        Field Width
                      </label>
                      <select
                        id={`field-width-${field.id}`}
                        style={styles.select}
                        value={field.width ?? 'full'}
                        onChange={(e) => onUpdateField(field.id, { width: e.target.value as 'full' | 'half' })}
                        onClick={(e) => e.stopPropagation()}
                      >
                        <option value="full">Full width (100%)</option>
                        <option value="half">Half width (50%)</option>
                      </select>
                    </div>
                  </div>
                  <div style={styles.checkboxRow}>
                    <input
                      id={`field-required-${field.id}`}
                      type="checkbox"
                      style={styles.checkbox}
                      checked={field.required}
                      onChange={(e) => onUpdateField(field.id, { required: e.target.checked })}
                      onClick={(e) => e.stopPropagation()}
                    />
                    <label
                      style={styles.checkboxLabel}
                      htmlFor={`field-required-${field.id}`}
                      onClick={(e) => e.stopPropagation()}
                    >
                      This field is required
                    </label>
                  </div>
                  {isChoiceField && (
                    <div style={styles.optionsSection}>
                      <label style={styles.inputLabel} htmlFor={`field-options-${field.id}`}>
                        Options
                      </label>
                      <textarea
                        id={`field-options-${field.id}`}
                        style={styles.textarea}
                        rows={4}
                        value={(field.options ?? []).join('\n')}
                        onChange={(e) =>
                          onUpdateField(field.id, {
                            options: e.target.value
                              .split('\n')
                              .map((line) => line.trim())
                              .filter(Boolean),
                          })
                        }
                        placeholder="Option 1&#10;Option 2&#10;Option 3"
                        onClick={(e) => e.stopPropagation()}
                      />
                      <p style={styles.optionsHint}>Enter each option on a new line</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}


