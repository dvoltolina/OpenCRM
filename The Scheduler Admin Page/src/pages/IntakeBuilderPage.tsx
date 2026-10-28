import { useEffect, useMemo, useState } from 'react';

import { isDemoMode } from '../config/demo';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { useIntakeFormBuilder } from '../hooks/useIntakeFormBuilder';
import type { IntakeForm, IntakeFormField, IntakeFormFieldType } from '../types/models';
import { BuilderCanvas } from './intakeBuilder/BuilderCanvas';
import { FieldPalette } from './intakeBuilder/FieldPalette';
import { LogicPanel } from './intakeBuilder/LogicPanel';
import { PreviewPane } from './intakeBuilder/PreviewPane';
import { FIELD_PALETTE, SERVICE_OPTIONS } from './intakeBuilder/constants';
import { cloneField, cloneForm, createFieldTemplate } from './intakeBuilder/helpers';
import { THEME, SPACING } from './dashboard/DashboardComponents';

// Styles for the intake builder
const styles = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(180deg, #F7F8FA 0%, #FFFFFF 100%)',
  },
  header: {
    background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
    borderBottom: `1px solid ${THEME.colorBorder}`,
    padding: `${SPACING.lg}px ${SPACING.xl}px`,
    marginBottom: SPACING.lg,
    boxShadow: THEME.shadow,
  },
  headerTop: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.md,
  },
  aiBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    padding: '6px 12px',
    background: `linear-gradient(135deg, ${THEME.colorAccent} 0%, ${THEME.colorAccentStrong} 100%)`,
    borderRadius: 16,
    fontSize: 11,
    fontWeight: 600,
    color: 'white',
    letterSpacing: '0.5px',
  },
  headerContent: {
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 700,
    color: '#1e293b',
    margin: '0 0 4px 0',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#64748b',
    margin: 0,
  },
  headerActions: {
    display: 'flex',
    gap: 12,
  },
  btnPrimary: {
    padding: '10px 20px',
    fontSize: 14,
    fontWeight: 600,
    color: 'white',
    background: `linear-gradient(135deg, ${THEME.colorAccent} 0%, ${THEME.colorAccentStrong} 100%)`,
    border: 'none',
    borderRadius: THEME.radius,
    cursor: 'pointer',
    transition: `all ${THEME.transitionBase} ease-out`,
  },
  btnSecondary: {
    padding: '10px 20px',
    fontSize: 14,
    fontWeight: 500,
    color: THEME.colorTextMuted,
    background: 'white',
    border: `1px solid ${THEME.colorBorder}`,
    borderRadius: THEME.radius,
    cursor: 'pointer',
    transition: `all ${THEME.transitionBase} ease-out`,
  },
  btnDanger: {
    padding: '10px 20px',
    fontSize: 14,
    fontWeight: 500,
    color: THEME.colorDanger,
    background: 'white',
    border: `1px solid #fecaca`,
    borderRadius: THEME.radius,
    cursor: 'pointer',
    transition: `all ${THEME.transitionBase} ease-out`,
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: '280px 1fr 360px',
    gap: SPACING.lg,
    padding: `0 ${SPACING.xl}px ${SPACING.xl}px`,
    maxWidth: 1600,
    margin: '0 auto',
  } as React.CSSProperties,
  panel: {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    border: `1px solid ${THEME.colorBorder}`,
    overflow: 'hidden',
    boxShadow: THEME.shadow,
  },
  panelHeader: {
    padding: `${SPACING.lg}px ${SPACING.lg}px`,
    borderBottom: `1px solid ${THEME.colorBorderLight}`,
  },
  panelTitle: {
    fontSize: 16,
    fontWeight: 600,
    color: THEME.colorText,
    margin: '0 0 4px 0',
  },
  panelSubtitle: {
    fontSize: 13,
    color: THEME.colorTextMuted,
    margin: 0,
  },
  formList: {
    listStyle: 'none',
    padding: 0,
    margin: 0,
  },
  formItem: {
    padding: `${SPACING.md}px ${SPACING.lg}px`,
    borderBottom: `1px solid ${THEME.colorBorderLight}`,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
  },
  formItemActive: {
    background: THEME.colorAccentSubtle,
    borderLeft: `3px solid ${THEME.colorAccent}`,
  },
  formName: {
    fontSize: 14,
    fontWeight: 600,
    color: THEME.colorText,
    margin: '0 0 4px 0',
  },
  formDesc: {
    fontSize: 12,
    color: THEME.colorTextMuted,
    margin: 0,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
  } as React.CSSProperties,
  statusBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    padding: '2px 8px',
    borderRadius: 12,
    fontSize: 11,
    fontWeight: 500,
  },
  statusActive: {
    background: '#dcfce7',
    color: '#16a34a',
  },
  statusDraft: {
    background: '#fef3c7',
    color: '#d97706',
  },
  editorSection: {
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.lg,
  } as React.CSSProperties,
  formMeta: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: SPACING.md,
    padding: SPACING.lg,
    background: '#F7F8FA',
    borderRadius: THEME.radius,
    margin: SPACING.lg,
  },
  formMetaFull: {
    gridColumn: '1 / -1',
  },
  fieldLabel: {
    display: 'block',
    fontSize: 13,
    fontWeight: 500,
    color: THEME.colorTextMuted,
    marginBottom: 6,
  },
  input: {
    width: '100%',
    padding: '10px 14px',
    fontSize: 14,
    border: `1px solid ${THEME.colorBorder}`,
    borderRadius: THEME.radius,
    background: 'white',
    transition: `border-color ${THEME.transitionBase} ease-out`,
    outline: 'none',
  },
  textarea: {
    width: '100%',
    padding: '10px 14px',
    fontSize: 14,
    border: `1px solid ${THEME.colorBorder}`,
    borderRadius: THEME.radius,
    background: 'white',
    resize: 'vertical' as const,
    minHeight: 80,
    transition: `border-color ${THEME.transitionBase} ease-out`,
    outline: 'none',
  },
  serviceChips: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 8,
  } as React.CSSProperties,
  serviceChip: {
    padding: '6px 12px',
    fontSize: 13,
    borderRadius: 16,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
    border: 'none',
  },
  serviceChipActive: {
    background: THEME.colorAccent,
    color: 'white',
  },
  serviceChipInactive: {
    background: THEME.colorBorderLight,
    color: THEME.colorTextMuted,
  },
  toast: {
    position: 'fixed' as const,
    bottom: SPACING.lg,
    right: SPACING.lg,
    padding: `${SPACING.md}px ${SPACING.lg}px`,
    background: THEME.colorText,
    color: 'white',
    borderRadius: THEME.radius,
    fontSize: 14,
    fontWeight: 500,
    boxShadow: THEME.shadowHover,
    zIndex: 1000,
    display: 'flex',
    alignItems: 'center',
    gap: 10,
  },
  emptyState: {
    textAlign: 'center' as const,
    padding: `${SPACING.xxl}px ${SPACING.lg}px`,
  },
  emptyIcon: {
    width: 64,
    height: 64,
    margin: `0 auto ${SPACING.md}px`,
    borderRadius: '50%',
    background: THEME.colorBorderLight,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: 24,
  },
  rightPanel: {
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.lg,
  } as React.CSSProperties,
};

export function IntakeBuilderPage() {
  const { businessId } = useBusinessContext({ minRole: 'admin', requireBusinessId: true });
  const { flags, loading: flagsLoading } = useFeatureFlags(businessId);
  const { forms, loading, saving, error, createForm, saveForm, duplicateForm, archiveForm } =
    useIntakeFormBuilder(businessId);
  const isReadOnly = isDemoMode;

  const [selectedFormId, setSelectedFormId] = useState<string | null>(null);
  const [workingForm, setWorkingForm] = useState<IntakeForm | null>(null);
  const [baselineSnapshot, setBaselineSnapshot] = useState('');
  const [activeFieldId, setActiveFieldId] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!forms.length || selectedFormId) return;
    setSelectedFormId(forms[0].id);
  }, [forms, selectedFormId]);

  const selectedForm = useMemo(
    () => forms.find((form) => form.id === selectedFormId) ?? null,
    [forms, selectedFormId],
  );

  useEffect(() => {
    if (!selectedForm) {
      setWorkingForm(null);
      setBaselineSnapshot('');
      setActiveFieldId(null);
      return;
    }
    const cloned = cloneForm(selectedForm);
    setWorkingForm(cloned);
    setBaselineSnapshot(JSON.stringify(cloned));
    setActiveFieldId(cloned.fields[0]?.id ?? null);
  }, [selectedForm]);

  const activeField = useMemo(
    () => workingForm?.fields.find((field) => field.id === activeFieldId) ?? null,
    [workingForm, activeFieldId],
  );

  const isDirty = useMemo(() => {
    if (!workingForm) return false;
    return JSON.stringify(workingForm) !== baselineSnapshot;
  }, [workingForm, baselineSnapshot]);

  const handleCreateForm = async () => {
    const form = await createForm('New intake form');
    if (form) {
      setSelectedFormId(form.id);
      setStatusMessage('New form created — start customizing fields below.');
    }
  };

  const handleDuplicate = async () => {
    if (!selectedFormId) return;
    const form = await duplicateForm(selectedFormId);
    if (form) {
      setSelectedFormId(form.id);
      setStatusMessage(`Duplicated "${selectedForm?.name}" — review before publishing.`);
    }
  };

  const handleArchive = async () => {
    if (!selectedFormId) return;
    await archiveForm(selectedFormId);
    setStatusMessage('Form archived. Reactivate anytime from the library.');
  };

  const handleSave = async () => {
    if (!workingForm) return;
    const saved = await saveForm(workingForm);
    if (saved) {
      setBaselineSnapshot(JSON.stringify(saved));
      setStatusMessage('Form saved. Conditional logic + preview updated.');
    }
  };

  const handleFieldUpdate = (fieldId: string, updates: Partial<IntakeFormField>) => {
    setWorkingForm((prev) => {
      if (!prev) return prev;
      return {
        ...prev,
        fields: prev.fields.map((field) =>
          field.id === fieldId
            ? {
                ...field,
                ...updates,
              }
            : field,
        ),
      };
    });
  };

  const handleFormMetaChange = (updates: Partial<IntakeForm>) => {
    setWorkingForm((prev) => (prev ? { ...prev, ...updates } : prev));
  };

  const handleAddField = (type: IntakeFormFieldType) => {
    setWorkingForm((prev) => {
      if (!prev) return prev;
      const newField = createFieldTemplate(type);
      setActiveFieldId(newField.id);
      return {
        ...prev,
        fields: [...prev.fields, newField],
      };
    });
  };

  const handleRemoveField = (fieldId: string) => {
    setWorkingForm((prev) => {
      if (!prev) return prev;
      const filtered = prev.fields.filter((field) => field.id !== fieldId);
      setActiveFieldId((current) => {
        if (current !== fieldId) return current;
        return filtered[0]?.id ?? null;
      });
      return {
        ...prev,
        fields: filtered,
      };
    });
  };

  const handleReorderFields = (sourceId: string, targetId: string) => {
    if (sourceId === targetId) return;
    setWorkingForm((prev) => {
      if (!prev) return prev;
      const next = [...prev.fields];
      const sourceIndex = next.findIndex((field) => field.id === sourceId);
      const targetIndex = next.findIndex((field) => field.id === targetId);
      if (sourceIndex === -1 || targetIndex === -1) {
        return prev;
      }
      const [moved] = next.splice(sourceIndex, 1);
      const insertIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex;
      next.splice(Math.max(insertIndex, 0), 0, moved);
      return { ...prev, fields: next };
    });
  };

  const handleDuplicateField = (fieldId: string) => {
    setWorkingForm((prev) => {
      if (!prev) return prev;
      const index = prev.fields.findIndex((field) => field.id === fieldId);
      if (index === -1) return prev;
      const clone = cloneField(prev.fields[index]);
      const next = [...prev.fields];
      next.splice(index + 1, 0, clone);
      setActiveFieldId(clone.id);
      return { ...prev, fields: next };
    });
  };

  useEffect(() => {
    const timer = statusMessage
      ? setTimeout(() => {
          setStatusMessage(null);
        }, 4000)
      : undefined;
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [statusMessage]);

  if (flagsLoading) {
    return (
      <div style={styles.container}>
        <div style={{ ...styles.panel, margin: SPACING.xl, padding: SPACING.xxl, textAlign: 'center' }}>
          <div style={styles.emptyIcon}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={THEME.colorTextMuted} strokeWidth="2">
              <circle cx="12" cy="12" r="10"/>
              <path d="M12 6v6l4 2"/>
            </svg>
          </div>
          <p style={{ color: THEME.colorTextMuted, margin: 0 }}>Loading builder...</p>
        </div>
      </div>
    );
  }

  if (!flags.enableIntakeBuilder) {
    return (
      <div style={styles.container}>
        <div style={styles.header}>
          <div style={styles.aiBadge}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/>
              <path d="M2 17l10 5 10-5"/>
              <path d="M2 12l10 5 10-5"/>
            </svg>
            OpenCRM
          </div>
          <div style={{ marginTop: SPACING.md }}>
            <h1 style={styles.headerTitle}>Intake Form Builder</h1>
            <p style={styles.headerSubtitle}>Design custom intake forms for your clients</p>
          </div>
        </div>
        <div style={{ padding: `0 ${SPACING.xl}px` }}>
          <div style={{ ...styles.panel, padding: SPACING.xxl, textAlign: 'center', maxWidth: 500, margin: '0 auto' }}>
            <div style={{ ...styles.emptyIcon, background: '#fef3c7' }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={THEME.colorWarning} strokeWidth="2">
                <path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
            </div>
            <h3 style={{ ...styles.panelTitle, marginBottom: SPACING.sm }}>Module Not Enabled</h3>
            <p style={{ color: THEME.colorTextMuted, margin: `0 0 ${SPACING.lg}px`, lineHeight: 1.6 }}>
              Enable the Intake Builder from Settings → Feature Flags to start designing custom intake forms.
            </p>
            <button type="button" style={styles.btnSecondary} onClick={() => window.location.href = '/settings'}>
              Go to Settings
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      {/* Header */}
      <header style={styles.header}>
        <div style={styles.headerTop}>
          <div style={styles.aiBadge}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/>
              <path d="M2 17l10 5 10-5"/>
              <path d="M2 12l10 5 10-5"/>
            </svg>
            OpenCRM
          </div>
          {isDirty && (
            <span style={{ fontSize: 13, color: '#f59e0b', display: 'flex', alignItems: 'center', gap: 6 }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="6"/>
              </svg>
              Unsaved changes
            </span>
          )}
        </div>
        <div style={styles.headerContent}>
          <div>
            <h1 style={styles.headerTitle}>Intake Form Builder</h1>
            <p style={styles.headerSubtitle}>
              Design custom intake forms, set conditional logic, and preview the client experience
            </p>
          </div>
          <div style={styles.headerActions}>
            <button
              type="button"
              style={{ ...styles.btnSecondary, opacity: saving || isReadOnly ? 0.6 : 1 }}
              onClick={handleCreateForm}
              onMouseOver={(e) => {
                if (!saving) e.currentTarget.style.boxShadow = THEME.shadow;
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.boxShadow = 'none';
              }}
              title={isReadOnly ? 'This action is disabled in demo mode.' : undefined}
              disabled={saving || isReadOnly}
            >
              <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 5v14M5 12h14"/>
                </svg>
                New Form
              </span>
            </button>
            <button
              type="button"
              style={{ ...styles.btnSecondary, opacity: !selectedFormId || saving || isReadOnly ? 0.6 : 1 }}
              onClick={handleDuplicate}
              onMouseOver={(e) => {
                if (selectedFormId && !saving) e.currentTarget.style.boxShadow = THEME.shadow;
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.boxShadow = 'none';
              }}
              title={isReadOnly ? 'This action is disabled in demo mode.' : undefined}
              disabled={!selectedFormId || saving || isReadOnly}
            >
              <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                </svg>
                Duplicate
              </span>
            </button>
            <button
              type="button"
              style={{ ...styles.btnDanger, opacity: !selectedFormId || saving || isReadOnly ? 0.6 : 1 }}
              onClick={handleArchive}
              onMouseOver={(e) => {
                if (selectedFormId && !saving) e.currentTarget.style.boxShadow = THEME.shadow;
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.boxShadow = 'none';
              }}
              title={isReadOnly ? 'This action is disabled in demo mode.' : undefined}
              disabled={!selectedFormId || saving || isReadOnly}
            >
              Archive
            </button>
            <button
              type="button"
              style={{ ...styles.btnPrimary, opacity: !isDirty || saving || isReadOnly ? 0.6 : 1 }}
              onClick={handleSave}
              onMouseOver={(e) => {
                if (isDirty && !saving) e.currentTarget.style.boxShadow = THEME.shadowHover;
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.boxShadow = 'none';
              }}
              title={isReadOnly ? 'This action is disabled in demo mode.' : undefined}
              disabled={!isDirty || saving || isReadOnly}
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      </header>

      {/* Toast notification */}
      {statusMessage && (
        <div style={styles.toast} role="status" aria-live="polite">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#4ade80" strokeWidth="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
          {statusMessage}
        </div>
      )}

      {/* Error alert */}
      {error && (
        <div style={{ margin: `0 ${SPACING.xl}px ${SPACING.lg}px`, padding: `${SPACING.md}px ${SPACING.lg}px`, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: THEME.radius }} role="alert">
          <div style={{ display: 'flex', alignItems: 'center', gap: SPACING.md }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={THEME.colorDanger} strokeWidth="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="8" x2="12" y2="12"/>
              <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <div>
              <p style={{ color: THEME.colorDanger, fontWeight: 600, margin: 0, fontSize: 14 }}>Error</p>
              <p style={{ color: '#b91c1c', margin: `${SPACING.xs}px 0 0`, fontSize: 13 }}>{error}</p>
            </div>
          </div>
        </div>
      )}

      {/* Main grid */}
      <div style={styles.grid}>
        {/* Left sidebar - Form Library */}
        <aside style={styles.panel}>
          <div style={styles.panelHeader}>
            <h2 style={styles.panelTitle}>Form Library</h2>
            <p style={styles.panelSubtitle}>Select a form to edit</p>
          </div>
          {loading ? (
            <div style={styles.emptyState}>
              <p style={{ color: THEME.colorTextMuted, margin: 0 }}>Loading forms...</p>
            </div>
          ) : !forms.length ? (
            <div style={styles.emptyState}>
              <div style={styles.emptyIcon}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={THEME.colorTextMuted} strokeWidth="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                </svg>
              </div>
              <h4 style={{ color: THEME.colorText, margin: `0 0 ${SPACING.sm}px`, fontWeight: 600 }}>No forms yet</h4>
              <p style={{ color: THEME.colorTextMuted, margin: `0 0 ${SPACING.md}px`, fontSize: 13 }}>
                Create your first intake form to get started
              </p>
              <button type="button" style={{ ...styles.btnPrimary, padding: '8px 16px', fontSize: 13 }} onClick={handleCreateForm}>
                Create Form
              </button>
            </div>
          ) : (
            <ul style={styles.formList}>
              {forms.map((form) => {
                const isSelected = form.id === selectedFormId;
                return (
                  <li
                    key={form.id}
                    style={{
                      ...styles.formItem,
                      ...(isSelected ? styles.formItemActive : {}),
                    }}
                    onClick={() => setSelectedFormId(form.id)}
                    role="button"
                    tabIndex={0}
                    onKeyDown={(e) => e.key === 'Enter' && setSelectedFormId(form.id)}
                    onMouseOver={(e) => {
                      if (!isSelected) {
                        e.currentTarget.style.background = '#F9FAFB';
                      }
                    }}
                    onMouseOut={(e) => {
                      if (!isSelected) {
                        e.currentTarget.style.background = 'transparent';
                      }
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: SPACING.sm }}>
                      <p style={styles.formName}>{form.name}</p>
                      <span style={{ ...styles.statusBadge, ...(form.isActive ? styles.statusActive : styles.statusDraft) }}>
                        {form.isActive ? 'Active' : 'Draft'}
                      </span>
                    </div>
                    <p style={styles.formDesc}>{form.description || 'No description'}</p>
                    <div style={{ marginTop: SPACING.sm, fontSize: 11, color: THEME.colorTextMuted }}>
                      {form.fields.length} field{form.fields.length !== 1 ? 's' : ''}
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </aside>

        {/* Center - Form Editor */}
        <main style={{ ...styles.panel, ...styles.editorSection }}>
          {!workingForm ? (
            <div style={styles.emptyState}>
              <div style={styles.emptyIcon}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={THEME.colorTextMuted} strokeWidth="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </div>
              <h3 style={{ color: THEME.colorText, margin: `0 0 ${SPACING.sm}px`, fontWeight: 600 }}>Select a Form</h3>
              <p style={{ color: THEME.colorTextMuted, margin: 0, fontSize: 14 }}>
                Choose a form from the library to start editing
              </p>
            </div>
          ) : (
            <>
              {/* Form metadata */}
              <div style={styles.formMeta}>
                <div>
                  <label style={styles.fieldLabel} htmlFor="form-name-input">Form Name</label>
                  <input
                    id="form-name-input"
                    type="text"
                    style={styles.input}
                    value={workingForm.name}
                    onChange={(e) => handleFormMetaChange({ name: e.target.value })}
                    placeholder="e.g., New Patient Intake"
                  />
                </div>
                <div>
                  <label style={styles.fieldLabel}>Status</label>
                  <div style={{ display: 'flex', gap: SPACING.sm, marginTop: 6 }}>
                    <button
                      type="button"
                      style={{ ...styles.serviceChip, ...(workingForm.isActive ? styles.serviceChipActive : styles.serviceChipInactive) }}
                      onClick={() => handleFormMetaChange({ isActive: true })}
                    >
                      Active
                    </button>
                    <button
                      type="button"
                      style={{ ...styles.serviceChip, ...(!workingForm.isActive ? { ...styles.serviceChipActive, background: THEME.colorWarning } : styles.serviceChipInactive) }}
                      onClick={() => handleFormMetaChange({ isActive: false })}
                    >
                      Draft
                    </button>
                  </div>
                </div>
                <div style={styles.formMetaFull}>
                  <label style={styles.fieldLabel} htmlFor="form-desc-input">Description</label>
                  <textarea
                    id="form-desc-input"
                    style={styles.textarea}
                    value={workingForm.description ?? ''}
                    onChange={(e) => handleFormMetaChange({ description: e.target.value })}
                    placeholder="Describe what this form collects and when clients will see it..."
                    rows={2}
                  />
                </div>
                <div style={styles.formMetaFull}>
                  <label style={styles.fieldLabel}>Link to Services</label>
                  <p style={{ fontSize: 12, color: THEME.colorTextMuted, margin: `0 0 ${SPACING.sm}px` }}>
                    This form will appear when clients book these services
                  </p>
                  <div style={styles.serviceChips}>
                    {SERVICE_OPTIONS.map((service) => {
                      const selected = workingForm.serviceIds?.includes(service) ?? false;
                      return (
                        <button
                          key={service}
                          type="button"
                          style={{ ...styles.serviceChip, ...(selected ? styles.serviceChipActive : styles.serviceChipInactive) }}
                          onClick={() => {
                            const next = selected
                              ? workingForm.serviceIds?.filter((id) => id !== service) ?? []
                              : [...(workingForm.serviceIds ?? []), service];
                            handleFormMetaChange({ serviceIds: next });
                          }}
                        >
                          {selected && (
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ marginRight: 4 }}>
                              <polyline points="20 6 9 17 4 12"/>
                            </svg>
                          )}
                          {service}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              {/* Field Palette */}
              <FieldPalette palette={FIELD_PALETTE} onAddField={handleAddField} />

              {/* Builder Canvas */}
              <BuilderCanvas
                form={workingForm}
                activeFieldId={activeFieldId}
                onSelectField={setActiveFieldId}
                onUpdateField={handleFieldUpdate}
                onRemoveField={handleRemoveField}
                onReorder={handleReorderFields}
                onDuplicateField={handleDuplicateField}
              />
            </>
          )}
        </main>

        {/* Right sidebar - Logic & Preview */}
        <div style={styles.rightPanel}>
          <LogicPanel
            fields={workingForm?.fields ?? []}
            activeField={activeField}
            onUpdateField={handleFieldUpdate}
          />
          <PreviewPane form={workingForm} />
        </div>
      </div>
    </div>
  );
}
