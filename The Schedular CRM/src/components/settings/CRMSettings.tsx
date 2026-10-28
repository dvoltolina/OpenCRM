/**
 * CRMSettings Component
 * Main settings page with tabbed navigation
 *
 * Agent CRM-20 Implementation
 * Dependencies: useSettings hook
 */

import { useState, useCallback } from 'react';
import { useSettings } from '../../hooks/useSettings';
import { useAuth } from '../../context/AuthContext';
import { PipelineSettings } from './PipelineSettings';
import { TeamSettings } from './TeamSettings';
import { CustomFieldsSettings } from './CustomFieldsSettings';
import './settings.css';

// ============================================
// Types
// ============================================

type SettingsTab = 'general' | 'pipeline' | 'team' | 'custom-fields';

export interface CRMSettingsProps {
  /** Initial tab to display */
  initialTab?: SettingsTab;
  /** Called when tab changes */
  onTabChange?: (tab: SettingsTab) => void;
}

// ============================================
// Currency Options
// ============================================

const CURRENCY_OPTIONS = [
  { value: 'USD', label: 'US Dollar (USD)' },
  { value: 'EUR', label: 'Euro (EUR)' },
  { value: 'GBP', label: 'British Pound (GBP)' },
  { value: 'CAD', label: 'Canadian Dollar (CAD)' },
  { value: 'AUD', label: 'Australian Dollar (AUD)' },
  { value: 'NZD', label: 'New Zealand Dollar (NZD)' },
  { value: 'JPY', label: 'Japanese Yen (JPY)' },
  { value: 'CHF', label: 'Swiss Franc (CHF)' },
  { value: 'INR', label: 'Indian Rupee (INR)' },
  { value: 'MXN', label: 'Mexican Peso (MXN)' },
];

// ============================================
// Component
// ============================================

/**
 * CRMSettings - Main settings page
 *
 * @example
 * ```tsx
 * <CRMSettings initialTab="pipeline" />
 * ```
 */
export function CRMSettings({ initialTab = 'general', onTabChange }: CRMSettingsProps) {
  const { crmUser } = useAuth();
  const {
    settings,
    isLoading,
    error,
    updateSettings,
    toggleLeadScoring,
    updateDealRotting,
    refresh,
  } = useSettings();

  const [activeTab, setActiveTab] = useState<SettingsTab>(initialTab);
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Check if user can edit settings
  const canEdit = crmUser?.role === 'owner' || crmUser?.role === 'admin';

  // Handle tab change
  const handleTabChange = useCallback(
    (tab: SettingsTab) => {
      setActiveTab(tab);
      setSaveError(null);
      setSaveSuccess(false);
      onTabChange?.(tab);
    },
    [onTabChange]
  );

  // Handle currency change
  const handleCurrencyChange = async (currency: string) => {
    if (!canEdit) return;

    setIsSaving(true);
    setSaveError(null);
    setSaveSuccess(false);

    try {
      await updateSettings({ defaultCurrency: currency });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update currency');
    } finally {
      setIsSaving(false);
    }
  };

  // Handle lead scoring toggle
  const handleLeadScoringToggle = async (enabled: boolean) => {
    if (!canEdit) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      await toggleLeadScoring(enabled);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update lead scoring');
    } finally {
      setIsSaving(false);
    }
  };

  // Handle deal rotting update
  const handleDealRottingUpdate = async (enabled: boolean, days: number) => {
    if (!canEdit) return;

    setIsSaving(true);
    setSaveError(null);

    try {
      await updateDealRotting(enabled, days);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update deal rotting');
    } finally {
      setIsSaving(false);
    }
  };

  // Render loading state
  if (isLoading && !settings) {
    return (
      <div className="crm-settings crm-settings--loading" data-testid="crm-settings-loading">
        <div className="crm-settings__loader">Loading settings...</div>
      </div>
    );
  }

  // Render error state
  if (error && !settings) {
    return (
      <div className="crm-settings crm-settings--error" data-testid="crm-settings-error">
        <div className="crm-settings__error-message">
          <p>Failed to load settings</p>
          <p className="crm-settings__error-detail">{error.message}</p>
          <button
            type="button"
            className="crm-settings__btn crm-settings__btn--primary"
            onClick={refresh}
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="crm-settings" data-testid="crm-settings">
      {/* Header */}
      <div className="crm-settings__header">
        <h2 className="crm-settings__title">CRM Settings</h2>
        {!canEdit && (
          <span className="crm-settings__read-only">View Only</span>
        )}
      </div>

      {/* Tabs */}
      <div className="crm-settings__tabs" role="tablist">
        <button
          type="button"
          role="tab"
          className={`crm-settings__tab ${activeTab === 'general' ? 'crm-settings__tab--active' : ''}`}
          onClick={() => handleTabChange('general')}
          aria-selected={activeTab === 'general'}
        >
          General
        </button>
        <button
          type="button"
          role="tab"
          className={`crm-settings__tab ${activeTab === 'pipeline' ? 'crm-settings__tab--active' : ''}`}
          onClick={() => handleTabChange('pipeline')}
          aria-selected={activeTab === 'pipeline'}
        >
          Pipelines
        </button>
        <button
          type="button"
          role="tab"
          className={`crm-settings__tab ${activeTab === 'team' ? 'crm-settings__tab--active' : ''}`}
          onClick={() => handleTabChange('team')}
          aria-selected={activeTab === 'team'}
        >
          Team
        </button>
        <button
          type="button"
          role="tab"
          className={`crm-settings__tab ${activeTab === 'custom-fields' ? 'crm-settings__tab--active' : ''}`}
          onClick={() => handleTabChange('custom-fields')}
          aria-selected={activeTab === 'custom-fields'}
        >
          Custom Fields
        </button>
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

      {/* Tab Panels */}
      <div className="crm-settings__content" role="tabpanel">
        {/* General Settings */}
        {activeTab === 'general' && settings && (
          <div className="crm-settings__panel" data-testid="general-settings">
            <h3 className="crm-settings__section-title">General Settings</h3>

            {/* Currency Setting */}
            <div className="crm-settings__field">
              <label htmlFor="currency" className="crm-settings__label">
                Default Currency
              </label>
              <select
                id="currency"
                className="crm-settings__select"
                value={settings.defaultCurrency}
                onChange={(e) => handleCurrencyChange(e.target.value)}
                disabled={!canEdit || isSaving}
              >
                {CURRENCY_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
              <p className="crm-settings__help">
                Currency used for displaying deal values
              </p>
            </div>

            {/* Lead Scoring Toggle */}
            <div className="crm-settings__field">
              <div className="crm-settings__toggle-row">
                <label htmlFor="leadScoring" className="crm-settings__label">
                  Lead Scoring
                </label>
                <label className="crm-settings__switch">
                  <input
                    id="leadScoring"
                    type="checkbox"
                    checked={settings.leadScoringEnabled}
                    onChange={(e) => handleLeadScoringToggle(e.target.checked)}
                    disabled={!canEdit || isSaving}
                  />
                  <span className="crm-settings__switch-slider" />
                </label>
              </div>
              <p className="crm-settings__help">
                Automatically score leads based on engagement and fit criteria
              </p>
            </div>

            {/* Deal Rotting Settings */}
            <div className="crm-settings__field">
              <div className="crm-settings__toggle-row">
                <label htmlFor="dealRotting" className="crm-settings__label">
                  Deal Rotting Alerts
                </label>
                <label className="crm-settings__switch">
                  <input
                    id="dealRotting"
                    type="checkbox"
                    checked={settings.dealRotting?.enabled ?? false}
                    onChange={(e) =>
                      handleDealRottingUpdate(e.target.checked, settings.dealRotting?.thresholdDays ?? 14)
                    }
                    disabled={!canEdit || isSaving}
                  />
                  <span className="crm-settings__switch-slider" />
                </label>
              </div>
              {settings.dealRotting?.enabled && (
                <div className="crm-settings__sub-field">
                  <label htmlFor="rottingDays" className="crm-settings__label-small">
                    Days before deal is marked as rotting
                  </label>
                  <input
                    id="rottingDays"
                    type="number"
                    className="crm-settings__input crm-settings__input--small"
                    min="1"
                    max="365"
                    value={settings.dealRotting?.thresholdDays ?? 14}
                    onChange={(e) =>
                      handleDealRottingUpdate(true, Math.max(1, parseInt(e.target.value) || 14))
                    }
                    disabled={!canEdit || isSaving}
                  />
                </div>
              )}
              <p className="crm-settings__help">
                Highlight deals that haven't been updated within the threshold period
              </p>
            </div>

          </div>
        )}

        {/* Pipeline Settings */}
        {activeTab === 'pipeline' && (
          <div className="crm-settings__panel" data-testid="pipeline-settings-panel">
            <PipelineSettings />
          </div>
        )}

        {/* Team Settings */}
        {activeTab === 'team' && (
          <div className="crm-settings__panel" data-testid="team-settings-panel">
            <TeamSettings />
          </div>
        )}

        {/* Custom Fields Settings */}
        {activeTab === 'custom-fields' && (
          <div className="crm-settings__panel" data-testid="custom-fields-panel">
            <CustomFieldsSettings />
          </div>
        )}
      </div>
    </div>
  );
}

export default CRMSettings;
