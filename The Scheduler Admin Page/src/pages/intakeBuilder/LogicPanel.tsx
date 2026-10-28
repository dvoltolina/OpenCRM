import type { IntakeFieldConditionalLogic, IntakeFormField } from '../../types/models';
import { createLocalId } from './helpers';

type LogicPanelProps = {
  fields: IntakeFormField[];
  activeField: IntakeFormField | null;
  onUpdateField: (fieldId: string, updates: Partial<IntakeFormField>) => void;
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
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
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
  body: {
    padding: 20,
  },
  emptyState: {
    textAlign: 'center' as const,
    padding: '24px 16px',
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
  fieldLabel: {
    fontSize: 12,
    fontWeight: 500,
    color: '#475569',
    marginBottom: 6,
    display: 'block',
  },
  select: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 13,
    border: '1px solid #e2e8f0',
    borderRadius: 8,
    background: 'white',
    cursor: 'pointer',
    marginBottom: 12,
  },
  input: {
    width: '100%',
    padding: '10px 12px',
    fontSize: 13,
    border: '1px solid #e2e8f0',
    borderRadius: 8,
    background: 'white',
  },
  btnPrimary: {
    width: '100%',
    padding: '10px 16px',
    fontSize: 13,
    fontWeight: 600,
    color: 'white',
    background: 'linear-gradient(135deg, #4f46e5 0%, #6366f1 100%)',
    border: 'none',
    borderRadius: 8,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  btnSecondary: {
    padding: '8px 12px',
    fontSize: 12,
    fontWeight: 500,
    color: '#64748b',
    background: 'white',
    border: '1px solid #e2e8f0',
    borderRadius: 6,
    cursor: 'pointer',
  },
  btnDanger: {
    padding: '8px 12px',
    fontSize: 12,
    fontWeight: 500,
    color: '#dc2626',
    background: 'white',
    border: '1px solid #fecaca',
    borderRadius: 6,
    cursor: 'pointer',
  },
  conditionCard: {
    background: '#f8fafc',
    borderRadius: 8,
    padding: 16,
    marginBottom: 12,
    border: '1px solid #e2e8f0',
  },
  conditionHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  conditionNumber: {
    fontSize: 11,
    fontWeight: 600,
    color: '#4f46e5',
    background: '#e0e7ff',
    padding: '2px 8px',
    borderRadius: 10,
  },
  conditionFields: {
    display: 'grid',
    gap: 10,
  },
  addConditionBtn: {
    width: '100%',
    padding: '10px',
    fontSize: 13,
    fontWeight: 500,
    color: '#4f46e5',
    background: 'white',
    border: '2px dashed #e2e8f0',
    borderRadius: 8,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    transition: 'all 0.2s ease',
  },
  selectedFieldBadge: {
    fontSize: 11,
    fontWeight: 500,
    color: '#4f46e5',
    background: '#e0e7ff',
    padding: '4px 8px',
    borderRadius: 6,
    display: 'inline-block',
    marginBottom: 12,
  },
};

export function LogicPanel({ fields, activeField, onUpdateField }: LogicPanelProps) {
  const otherFields = fields.filter((field) => field.id !== activeField?.id);

  const handleAddLogic = () => {
    if (!activeField || !otherFields.length) return;
    const defaultLogic: IntakeFieldConditionalLogic = {
      id: createLocalId('logic'),
      action: 'show',
      matchType: 'all',
      conditions: [
        {
          id: createLocalId('condition'),
          fieldId: otherFields[0].id,
          operator: 'equals',
          value: '',
        },
      ],
    };
    onUpdateField(activeField.id, { conditionalLogic: defaultLogic });
  };

  const handleConditionUpdate = (
    conditionId: string,
    updates: Partial<IntakeFieldConditionalLogic['conditions'][number]>,
  ) => {
    if (!activeField?.conditionalLogic) return;
    onUpdateField(activeField.id, {
      conditionalLogic: {
        ...activeField.conditionalLogic,
        conditions: activeField.conditionalLogic.conditions.map((condition) =>
          condition.id === conditionId ? { ...condition, ...updates } : condition,
        ),
      },
    });
  };

  const handleRemoveCondition = (conditionId: string) => {
    if (!activeField?.conditionalLogic) return;
    const remaining = activeField.conditionalLogic.conditions.filter(
      (condition) => condition.id !== conditionId,
    );
    onUpdateField(activeField.id, {
      conditionalLogic: remaining.length
        ? { ...activeField.conditionalLogic, conditions: remaining }
        : undefined,
    });
  };

  const handleAddCondition = () => {
    if (!activeField?.conditionalLogic || !otherFields.length) return;
    onUpdateField(activeField.id, {
      conditionalLogic: {
        ...activeField.conditionalLogic,
        conditions: [
          ...activeField.conditionalLogic.conditions,
          {
            id: createLocalId('condition'),
            fieldId: otherFields[0].id,
            operator: 'equals',
            value: '',
          },
        ],
      },
    });
  };

  if (!activeField) {
    return (
      <section style={styles.panel} aria-label="Conditional logic configuration">
        <div style={styles.header}>
          <div>
            <h3 style={styles.title}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
              </svg>
              Conditional Logic
            </h3>
            <p style={styles.subtitle}>Control field visibility</p>
          </div>
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
            Select a field to configure conditional logic
          </p>
        </div>
      </section>
    );
  }

  return (
    <section style={styles.panel} aria-label="Conditional logic configuration">
      <div style={styles.header}>
        <div>
          <h3 style={styles.title}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2">
              <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
            </svg>
            Conditional Logic
          </h3>
          <p style={styles.subtitle}>Control when this field appears</p>
        </div>
        {activeField.conditionalLogic && (
          <button
            type="button"
            style={styles.btnDanger}
            onClick={() => onUpdateField(activeField.id, { conditionalLogic: undefined })}
            aria-label="Clear all conditional logic"
          >
            Clear
          </button>
        )}
      </div>
      <div style={styles.body}>
        <div style={styles.selectedFieldBadge}>
          Editing: {activeField.label || 'Untitled field'}
        </div>

        {!otherFields.length ? (
          <div style={styles.emptyState}>
            <p style={{ color: '#94a3b8', margin: 0, fontSize: 13 }}>
              Add more fields to enable conditional logic
            </p>
          </div>
        ) : !activeField.conditionalLogic ? (
          <div>
            <p style={{ color: '#64748b', margin: '0 0 16px', fontSize: 13 }}>
              Add rules to show, hide, or require this field based on other form responses.
            </p>
            <button
              type="button"
              style={styles.btnPrimary}
              onClick={handleAddLogic}
              aria-label="Add conditional logic to this field"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <line x1="12" y1="5" x2="12" y2="19"/>
                <line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Add Conditional Logic
            </button>
          </div>
        ) : (
          <>
            <div style={{ marginBottom: 16 }}>
              <label style={styles.fieldLabel} htmlFor="logic-action-select">
                Action
              </label>
              <select
                id="logic-action-select"
                style={styles.select}
                value={activeField.conditionalLogic.action}
                onChange={(e) =>
                  onUpdateField(activeField.id, {
                    conditionalLogic: {
                      ...activeField.conditionalLogic!,
                      action: e.target.value as IntakeFieldConditionalLogic['action'],
                    },
                  })
                }
              >
                <option value="show">Show field when conditions match</option>
                <option value="hide">Hide field when conditions match</option>
                <option value="require">Require field when conditions match</option>
              </select>

              <label style={styles.fieldLabel} htmlFor="logic-match-type-select">
                Match Type
              </label>
              <select
                id="logic-match-type-select"
                style={{ ...styles.select, marginBottom: 0 }}
                value={activeField.conditionalLogic.matchType}
                onChange={(e) =>
                  onUpdateField(activeField.id, {
                    conditionalLogic: {
                      ...activeField.conditionalLogic!,
                      matchType: e.target.value as 'all' | 'any',
                    },
                  })
                }
              >
                <option value="all">All conditions must match (AND)</option>
                <option value="any">Any condition can match (OR)</option>
              </select>
            </div>

            <p style={{ fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 12 }}>
              Conditions
            </p>

            <div role="list" aria-label="Conditions">
              {activeField.conditionalLogic.conditions.map((condition, index) => (
                <div key={condition.id} style={styles.conditionCard} role="listitem">
                  <div style={styles.conditionHeader}>
                    <span style={styles.conditionNumber}>Condition {index + 1}</span>
                    <button
                      type="button"
                      style={{ ...styles.btnSecondary, padding: '4px 8px', fontSize: 11 }}
                      onClick={() => handleRemoveCondition(condition.id)}
                      aria-label={`Remove condition ${index + 1}`}
                    >
                      Remove
                    </button>
                  </div>
                  <div style={styles.conditionFields}>
                    <select
                      style={{ ...styles.select, marginBottom: 0 }}
                      value={condition.fieldId}
                      onChange={(e) => handleConditionUpdate(condition.id, { fieldId: e.target.value })}
                      aria-label={`Condition ${index + 1}: Select field`}
                    >
                      {otherFields.map((field) => (
                        <option key={field.id} value={field.id}>
                          {field.label || field.type}
                        </option>
                      ))}
                    </select>
                    <select
                      style={{ ...styles.select, marginBottom: 0 }}
                      value={condition.operator}
                      onChange={(e) =>
                        handleConditionUpdate(condition.id, {
                          operator: e.target.value as typeof condition.operator,
                        })
                      }
                      aria-label={`Condition ${index + 1}: Operator`}
                    >
                      <option value="equals">equals</option>
                      <option value="not_equals">does not equal</option>
                      <option value="contains">contains</option>
                      <option value="includes">includes option</option>
                    </select>
                    <input
                      type="text"
                      style={styles.input}
                      value={condition.value}
                      onChange={(e) => handleConditionUpdate(condition.id, { value: e.target.value })}
                      placeholder="Enter value..."
                      aria-label={`Condition ${index + 1}: Value`}
                    />
                  </div>
                </div>
              ))}
            </div>
            <button
              type="button"
              style={styles.addConditionBtn}
              onClick={handleAddCondition}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#4f46e5';
                e.currentTarget.style.background = '#f0f9ff';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = '#e2e8f0';
                e.currentTarget.style.background = 'white';
              }}
              aria-label="Add another condition"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <line x1="12" y1="5" x2="12" y2="19"/>
                <line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Add Another Condition
            </button>
          </>
        )}
      </div>
    </section>
  );
}


