/**
 * LeadScoringSettings Component
 * Configure lead scoring rules and settings
 *
 * Agent CRM-40 Implementation
 * Dependencies: CRM-08 (Lead hooks), CRM-20 (Settings)
 */

import { useState, useMemo } from 'react';
import { useLeadScoring } from '../../hooks/useLeadScoring';
import { useAuth } from '../../context/AuthContext';
import { LeadScoreDisplay } from '../leads/LeadScoreDisplay';
import { calculateScore, getDefaultRules } from '../../services/lead-scoring-service';
import type { LeadScoringRule, LeadScoringCondition } from '../../types/lead-scoring';
import type { Lead } from '../../types/models';
import './settings.css';

// ============================================
// Types
// ============================================

export interface LeadScoringSettingsProps {
  /** Optional: Called when settings are saved */
  onSave?: () => void;
}

// ============================================
// Condition Labels
// ============================================

const CONDITION_LABELS: Record<LeadScoringCondition, string> = {
  has_email: 'Has Email',
  has_phone: 'Has Phone',
  has_company: 'Has Company Name',
  source_equals: 'Source Equals',
  status_equals: 'Status Equals',
  has_activity: 'Has Recent Activity',
  days_since_created: 'Days Since Created',
};

// Available source options for lead scoring rules (for future use when implementing custom rule editor)
// const SOURCE_OPTIONS = [
//   { value: 'website', label: 'Website' },
//   { value: 'referral', label: 'Referral' },
//   { value: 'coldCall', label: 'Cold Call' },
//   { value: 'social', label: 'Social Media' },
//   { value: 'event', label: 'Event' },
//   { value: 'scheduler', label: 'Scheduler' },
//   { value: 'other', label: 'Other' },
// ];

// Available status options for lead scoring rules (for future use when implementing custom rule editor)
// const STATUS_OPTIONS = [
//   { value: 'new', label: 'New' },
//   { value: 'contacted', label: 'Contacted' },
//   { value: 'qualified', label: 'Qualified' },
//   { value: 'unqualified', label: 'Unqualified' },
//   { value: 'converted', label: 'Converted' },
// ];

// ============================================
// Sample Lead for Preview
// ============================================

const SAMPLE_LEAD: Lead = {
  id: 'sample-lead',
  firstName: 'Jane',
  lastName: 'Smith',
  email: 'jane.smith@example.com',
  phone: '+1 (555) 123-4567',
  companyName: 'Acme Corp',
  title: 'Marketing Director',
  status: 'new',
  source: 'website',
  score: 0,
  tags: [],
  createdAt: new Date(),
};

// ============================================
// Component
// ============================================

/**
 * LeadScoringSettings - Configure lead scoring rules
 *
 * @example
 * ```tsx
 * <LeadScoringSettings onSave={() => console.log('Saved!')} />
 * ```
 */
export function LeadScoringSettings({ onSave }: LeadScoringSettingsProps) {
  const { crmUser } = useAuth();
  const {
    config,
    isLoading,
    error,
    updateConfig,
    toggleScoring,
    recalculateAll,
  } = useLeadScoring();

  const [isSaving, setIsSaving] = useState(false);
  const [isRecalculating, setIsRecalculating] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);
  // State for future rule editing functionality
  // const [editingRule, setEditingRule] = useState<LeadScoringRule | null>(null);
  // const [showAddRule, setShowAddRule] = useState(false);

  // Check if user can edit settings
  const canEdit = crmUser?.role === 'owner' || crmUser?.role === 'admin';

  // Calculate preview score
  const previewScore = useMemo(() => {
    if (!config) return null;
    return calculateScore(SAMPLE_LEAD, config, false);
  }, [config]);

  // Handle enable/disable toggle
  const handleToggle = async (enabled: boolean) => {
    if (!canEdit) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      await toggleScoring(enabled);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update lead scoring');
    } finally {
      setIsSaving(false);
    }
  };

  // Handle rule update
  const handleUpdateRule = async (ruleId: string, updates: Partial<LeadScoringRule>) => {
    if (!canEdit || !config) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      const updatedRules = config.rules.map((rule) =>
        rule.id === ruleId ? { ...rule, ...updates } : rule
      );

      await updateConfig({ rules: updatedRules });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      // setEditingRule(null);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update rule');
    } finally {
      setIsSaving(false);
    }
  };

  // Handle rule deletion
  const handleDeleteRule = async (ruleId: string) => {
    if (!canEdit || !config) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      const updatedRules = config.rules.filter((rule) => rule.id !== ruleId);
      await updateConfig({ rules: updatedRules });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to delete rule');
    } finally {
      setIsSaving(false);
    }
  };

  /*
  // Handle add rule
  const handleAddRule = async (newRule: Omit<LeadScoringRule, 'id'>) => {
    if (!canEdit || !config) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      const ruleWithId: LeadScoringRule = {
        ...newRule,
        id: `rule-${Date.now()}`,
      };

      const updatedRules = [...config.rules, ruleWithId];
      await updateConfig({ rules: updatedRules });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      setShowAddRule(false);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to add rule');
    } finally {
      setIsSaving(false);
    }
  };
  */

  // Handle decay settings update
  const handleDecayUpdate = async (
    enabled: boolean,
    pointsPerDay?: number,
    startDays?: number
  ) => {
    if (!canEdit || !config) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      await updateConfig({
        decayEnabled: enabled,
        decayPointsPerDay: pointsPerDay ?? config.decayPointsPerDay,
        decayStartDays: startDays ?? config.decayStartDays,
      });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update decay settings');
    } finally {
      setIsSaving(false);
    }
  };

  // Handle recalculate all
  const handleRecalculateAll = async () => {
    if (!canEdit) return;

    setIsRecalculating(true);
    setSaveError(null);

    try {
      await recalculateAll();
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to recalculate scores');
    } finally {
      setIsRecalculating(false);
    }
  };

  // Reset to defaults
  const handleResetDefaults = async () => {
    if (!canEdit || !config) return;
    if (!confirm('Reset to default scoring rules? This will overwrite your current rules.')) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      await updateConfig({ rules: getDefaultRules() });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to reset rules');
    } finally {
      setIsSaving(false);
    }
  };

  // Render loading state
  if (isLoading && !config) {
    return (
      <div className="lead-scoring-settings lead-scoring-settings--loading">
        <div className="crm-settings__loader">Loading scoring settings...</div>
      </div>
    );
  }

  // Render error state
  if (error && !config) {
    return (
      <div className="lead-scoring-settings lead-scoring-settings--error">
        <div className="crm-settings__error-message">
          <p>Failed to load scoring settings</p>
          <p className="crm-settings__error-detail">{error.message}</p>
        </div>
      </div>
    );
  }

  if (!config) return null;

  return (
    <div className="lead-scoring-settings" data-testid="lead-scoring-settings">
      {/* Header */}
      <div className="crm-settings__header">
        <h3 className="crm-settings__section-title">Lead Scoring</h3>
        {!canEdit && <span className="crm-settings__read-only">View Only</span>}
      </div>

      {/* Status Messages */}
      {saveError && (
        <div className="crm-settings__alert crm-settings__alert--error" role="alert">
          {saveError}
        </div>
      )}
      {saveSuccess && (
        <div className="crm-settings__alert crm-settings__alert--success" role="status">
          Settings saved successfully
        </div>
      )}

      {/* Enable/Disable Toggle */}
      <div className="crm-settings__field">
        <div className="crm-settings__toggle-row">
          <label htmlFor="scoringEnabled" className="crm-settings__label">
            Enable Lead Scoring
          </label>
          <label className="crm-settings__switch">
            <input
              id="scoringEnabled"
              type="checkbox"
              checked={config.enabled}
              onChange={(e) => handleToggle(e.target.checked)}
              disabled={!canEdit || isSaving}
            />
            <span className="crm-settings__switch-slider" />
          </label>
        </div>
        <p className="crm-settings__help">
          Automatically calculate lead quality scores (0-100) based on configurable rules
        </p>
      </div>

      {config.enabled && (
        <>
          {/* Scoring Rules */}
          <div className="crm-settings__field">
            <div className="crm-settings__field-header">
              <h4 className="crm-settings__label">Scoring Rules</h4>
              <div className="crm-settings__button-group">
                <button
                  type="button"
                  className="crm-settings__btn crm-settings__btn--secondary crm-settings__btn--sm"
                  onClick={handleResetDefaults}
                  disabled={!canEdit || isSaving}
                >
                  Reset to Defaults
                </button>
                <button
                  type="button"
                  className="crm-settings__btn crm-settings__btn--primary crm-settings__btn--sm"
                  // onClick={() => setShowAddRule(true)}
                  disabled={true /* !canEdit || isSaving */}
                  title="Not implemented yet"
                >
                  Add Rule
                </button>
              </div>
            </div>

            <div className="lead-scoring-settings__rules-list">
              {config.rules.map((rule) => (
                <div key={rule.id} className="lead-scoring-settings__rule-card">
                  <div className="lead-scoring-settings__rule-header">
                    <div className="lead-scoring-settings__rule-info">
                      <h5 className="lead-scoring-settings__rule-name">{rule.name}</h5>
                      <p className="lead-scoring-settings__rule-condition">
                        {CONDITION_LABELS[rule.condition]}
                        {rule.conditionValue && `: ${rule.conditionValue}`}
                      </p>
                    </div>
                    <div className="lead-scoring-settings__rule-points">
                      <span
                        className="lead-scoring-settings__points-badge"
                        style={{
                          color: rule.points >= 0 ? '#22c55e' : '#ef4444',
                        }}
                      >
                        {rule.points >= 0 ? '+' : ''}
                        {rule.points}
                      </span>
                    </div>
                  </div>
                  {canEdit && (
                    <div className="lead-scoring-settings__rule-actions">
                      <button
                        type="button"
                        className="crm-settings__btn crm-settings__btn--text crm-settings__btn--sm"
                        onClick={() =>
                          handleUpdateRule(rule.id, { isActive: !rule.isActive })
                        }
                        disabled={isSaving}
                      >
                        {rule.isActive ? 'Disable' : 'Enable'}
                      </button>
                      <button
                        type="button"
                        className="crm-settings__btn crm-settings__btn--text crm-settings__btn--sm crm-settings__btn--danger"
                        onClick={() => handleDeleteRule(rule.id)}
                        disabled={isSaving}
                      >
                        Delete
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Decay Settings */}
          <div className="crm-settings__field">
            <div className="crm-settings__toggle-row">
              <label htmlFor="decayEnabled" className="crm-settings__label">
                Time Decay
              </label>
              <label className="crm-settings__switch">
                <input
                  id="decayEnabled"
                  type="checkbox"
                  checked={config.decayEnabled}
                  onChange={(e) => handleDecayUpdate(e.target.checked)}
                  disabled={!canEdit || isSaving}
                />
                <span className="crm-settings__switch-slider" />
              </label>
            </div>
            <p className="crm-settings__help">
              Reduce scores for older leads to prioritize recent leads
            </p>

            {config.decayEnabled && (
              <div className="crm-settings__sub-fields">
                <div className="crm-settings__sub-field">
                  <label htmlFor="decayStartDays" className="crm-settings__label-small">
                    Start decay after (days)
                  </label>
                  <input
                    id="decayStartDays"
                    type="number"
                    className="crm-settings__input crm-settings__input--small"
                    min="1"
                    max="365"
                    value={config.decayStartDays}
                    onChange={(e) =>
                      handleDecayUpdate(true, undefined, Math.max(1, parseInt(e.target.value) || 30))
                    }
                    disabled={!canEdit || isSaving}
                  />
                </div>
                <div className="crm-settings__sub-field">
                  <label htmlFor="decayPointsPerDay" className="crm-settings__label-small">
                    Points to subtract per day
                  </label>
                  <input
                    id="decayPointsPerDay"
                    type="number"
                    className="crm-settings__input crm-settings__input--small"
                    min="0.1"
                    max="10"
                    step="0.1"
                    value={config.decayPointsPerDay}
                    onChange={(e) =>
                      handleDecayUpdate(true, Math.max(0.1, parseFloat(e.target.value) || 1))
                    }
                    disabled={!canEdit || isSaving}
                  />
                </div>
              </div>
            )}
          </div>

          {/* Preview */}
          <div className="crm-settings__field">
            <h4 className="crm-settings__label">Preview</h4>
            <div className="lead-scoring-settings__preview">
              <p className="crm-settings__help">
                Sample lead: {SAMPLE_LEAD.firstName} {SAMPLE_LEAD.lastName} from {SAMPLE_LEAD.companyName}
              </p>
              {previewScore && (
                <div className="lead-scoring-settings__preview-score">
                  <LeadScoreDisplay score={previewScore} showBreakdown />
                </div>
              )}
            </div>
          </div>

          {/* Recalculate All */}
          <div className="crm-settings__field">
            <button
              type="button"
              className="crm-settings__btn crm-settings__btn--secondary"
              onClick={handleRecalculateAll}
              disabled={!canEdit || isRecalculating || isSaving}
            >
              {isRecalculating ? 'Recalculating...' : 'Recalculate All Lead Scores'}
            </button>
            <p className="crm-settings__help">
              Update scores for all existing leads based on current rules
            </p>
          </div>
        </>
      )}
    </div>
  );
}

export default LeadScoringSettings;
