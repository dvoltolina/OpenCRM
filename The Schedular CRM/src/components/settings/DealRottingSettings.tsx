/**
 * DealRottingSettings Component
 * Configure deal rotting detection thresholds
 *
 * Agent CRM-41 Implementation
 * Dependencies: CRM-20 (Settings), CRM-41 (Deal Rotting Service)
 */

import React, { useState, useEffect } from 'react';
import { useSettings } from '../../hooks/useSettings';
import { useDealRotting } from '../../hooks/useDealRotting';
import './settings.css';

// ============================================
// Types
// ============================================

export interface DealRottingSettingsProps {
  /** Whether the user can edit settings */
  canEdit?: boolean;
  /** Called when settings are saved */
  onSave?: () => void;
}

// ============================================
// Component
// ============================================

/**
 * DealRottingSettings - Configure deal rotting detection
 *
 * Allows admins to:
 * - Enable/disable rotting detection
 * - Set threshold days for rotting
 * - Preview how many deals are currently rotting
 *
 * @example
 * ```tsx
 * <DealRottingSettings
 *   canEdit={user.role === 'admin'}
 *   onSave={() => showSuccessMessage()}
 * />
 * ```
 */
export function DealRottingSettings({ canEdit = true, onSave }: DealRottingSettingsProps) {
  const { settings, updateDealRotting, isLoading: settingsLoading } = useSettings();
  const { rottingDeals, atRiskDeals, isLoading: rottingLoading } = useDealRotting();

  // Local state for form
  const [enabled, setEnabled] = useState(false);
  const [thresholdDays, setThresholdDays] = useState(14);
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Initialize form from settings
  useEffect(() => {
    if (settings?.dealRotting) {
      setEnabled(settings.dealRotting.enabled);
      setThresholdDays(settings.dealRotting.thresholdDays);
    }
  }, [settings]);

  // Handle enable/disable toggle
  const handleEnabledChange = async (newEnabled: boolean) => {
    if (!canEdit) return;

    setEnabled(newEnabled);

    // Auto-save when toggling
    setIsSaving(true);
    setSaveError(null);
    setSaveSuccess(false);

    try {
      await updateDealRotting(newEnabled, thresholdDays);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update settings');
      // Revert on error
      setEnabled(!newEnabled);
    } finally {
      setIsSaving(false);
    }
  };

  // Handle threshold days change
  const handleThresholdChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value, 10);
    if (!isNaN(value) && value > 0 && value <= 365) {
      setThresholdDays(value);
    }
  };

  // Handle save
  const handleSave = async () => {
    if (!canEdit) return;

    setIsSaving(true);
    setSaveError(null);
    setSaveSuccess(false);

    try {
      await updateDealRotting(enabled, thresholdDays);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      onSave?.();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to update settings');
    } finally {
      setIsSaving(false);
    }
  };

  // Calculate warning threshold (half of rotting threshold)
  const warningDays = Math.floor(thresholdDays / 2);

  // Check if settings have changed
  const hasChanges =
    settings?.dealRotting &&
    (settings.dealRotting.enabled !== enabled ||
      settings.dealRotting.thresholdDays !== thresholdDays);

  if (settingsLoading && !settings) {
    return (
      <div className="settings-section">
        <div className="settings-section__loading">Loading settings...</div>
      </div>
    );
  }

  return (
    <div className="settings-section" data-testid="deal-rotting-settings">
      <div className="settings-section__header">
        <h3 className="settings-section__title">Opportunity Rotting Alerts</h3>
        <p className="settings-section__description">
          Get notified when opportunities haven't had activity for a while. This helps you identify
          opportunities that need attention.
        </p>
      </div>

      <div className="settings-section__content">
        {/* Enable/Disable Toggle */}
        <div className="settings-field">
          <div className="settings-field__header">
            <label className="settings-field__label">
              <input
                type="checkbox"
                checked={enabled}
                onChange={(e) => handleEnabledChange(e.target.checked)}
                disabled={!canEdit || isSaving}
                className="settings-field__checkbox"
              />
              <span className="settings-field__label-text">Enable deal rotting alerts</span>
            </label>
          </div>
          <p className="settings-field__hint">
            When enabled, opportunities without recent activity will be flagged as "stale" or "rotting"
          </p>
        </div>

        {/* Threshold Days */}
        {enabled && (
          <div className="settings-field">
            <label className="settings-field__label">
              Rotting Threshold (Days)
              <input
                type="number"
                value={thresholdDays}
                onChange={handleThresholdChange}
                min="1"
                max="365"
                disabled={!canEdit || isSaving}
                className="settings-field__input settings-field__input--number"
              />
            </label>
            <p className="settings-field__hint">
              Opportunities without activity for this many days will be marked as "rotting"
            </p>
          </div>
        )}

        {/* Warning Info */}
        {enabled && (
          <div className="settings-info">
            <div className="settings-info__icon">ℹ️</div>
            <div className="settings-info__content">
              <p className="settings-info__text">
                <strong>Warning threshold:</strong> {warningDays} days
              </p>
              <p className="settings-info__text">
                Opportunities will show a warning badge when they haven't had activity for {warningDays}{' '}
                days, and a rotting badge after {thresholdDays} days.
              </p>
            </div>
          </div>
        )}

        {/* Current Status Preview */}
        {enabled && !rottingLoading && (
          <div className="settings-preview">
            <h4 className="settings-preview__title">Current Status</h4>
            <div className="settings-preview__stats">
              <div className="settings-preview__stat settings-preview__stat--warning">
                <span className="settings-preview__stat-value">{atRiskDeals.length}</span>
                <span className="settings-preview__stat-label">At Risk</span>
              </div>
              <div className="settings-preview__stat settings-preview__stat--rotting">
                <span className="settings-preview__stat-value">{rottingDeals.length}</span>
                <span className="settings-preview__stat-label">Rotting</span>
              </div>
              <div className="settings-preview__stat">
                <span className="settings-preview__stat-value">
                  {atRiskDeals.length + rottingDeals.length}
                </span>
                <span className="settings-preview__stat-label">Total Stale</span>
              </div>
            </div>
          </div>
        )}

        {/* Error Message */}
        {saveError && (
          <div className="settings-message settings-message--error" role="alert">
            {saveError}
          </div>
        )}

        {/* Success Message */}
        {saveSuccess && (
          <div className="settings-message settings-message--success" role="status">
            Settings saved successfully!
          </div>
        )}

        {/* Save Button */}
        {enabled && hasChanges && canEdit && (
          <div className="settings-actions">
            <button
              className="settings-button settings-button--primary"
              onClick={handleSave}
              disabled={isSaving}
            >
              {isSaving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        )}

        {/* Read-only Notice */}
        {!canEdit && (
          <div className="settings-message settings-message--info">
            You don't have permission to change these settings. Contact an administrator.
          </div>
        )}
      </div>
    </div>
  );
}

export default DealRottingSettings;
