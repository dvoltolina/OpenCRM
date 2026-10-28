/**
 * FormSettings Component
 * Settings panel for web form configuration
 *
 * Agent Web Forms Implementation
 */

import type {
  WebFormSettings,
  WebFormSpamProtection,
  WebFormStyling,
} from '../../types/web-forms';

interface FormSettingsProps {
  settings: WebFormSettings;
  spamProtection: WebFormSpamProtection;
  styling: WebFormStyling;
  onSettingsChange: (settings: WebFormSettings) => void;
  onSpamProtectionChange: (protection: WebFormSpamProtection) => void;
  onStylingChange: (styling: WebFormStyling) => void;
}

/**
 * FormSettings - Configure form behavior and appearance
 */
export function FormSettings({
  settings,
  spamProtection,
  styling,
  onSettingsChange,
  onSpamProtectionChange,
  onStylingChange,
}: FormSettingsProps) {
  return (
    <div className="form-settings">
      {/* Submission Settings */}
      <section className="settings-section">
        <h3>Submission Settings</h3>

        <div className="form-field">
          <label>Submit Button Text</label>
          <input
            type="text"
            value={settings.submitButtonText}
            onChange={(e) =>
              onSettingsChange({ ...settings, submitButtonText: e.target.value })
            }
            placeholder="Submit"
          />
        </div>

        <div className="form-field">
          <label>Success Message</label>
          <textarea
            value={settings.successMessage}
            onChange={(e) =>
              onSettingsChange({ ...settings, successMessage: e.target.value })
            }
            placeholder="Thank you for your submission!"
            rows={2}
          />
        </div>

        <div className="form-field">
          <label>Redirect URL (optional)</label>
          <input
            type="url"
            value={settings.redirectUrl || ''}
            onChange={(e) =>
              onSettingsChange({
                ...settings,
                redirectUrl: e.target.value || undefined,
              })
            }
            placeholder="https://example.com/thank-you"
          />
          <span className="field-hint">
            Leave empty to show success message instead
          </span>
        </div>
      </section>

      {/* Lead Settings */}
      <section className="settings-section">
        <h3>Lead Settings</h3>

        <div className="form-field">
          <label>Default Lead Source</label>
          <select
            value={settings.defaultLeadSource || 'website'}
            onChange={(e) =>
              onSettingsChange({ ...settings, defaultLeadSource: e.target.value })
            }
          >
            <option value="website">Website</option>
            <option value="referral">Referral</option>
            <option value="social">Social Media</option>
            <option value="event">Event</option>
            <option value="other">Other</option>
          </select>
        </div>

        <div className="form-field">
          <label>Default Tags (comma-separated)</label>
          <input
            type="text"
            value={(settings.defaultTags || []).join(', ')}
            onChange={(e) =>
              onSettingsChange({
                ...settings,
                defaultTags: e.target.value
                  .split(',')
                  .map((t) => t.trim())
                  .filter(Boolean),
              })
            }
            placeholder="web-form, inbound"
          />
        </div>

        <div className="form-field">
          <label>Sequence ID (auto-enroll)</label>
          <input
            type="text"
            value={settings.sequenceId || ''}
            onChange={(e) =>
              onSettingsChange({
                ...settings,
                sequenceId: e.target.value || undefined,
              })
            }
            placeholder="Leave empty to skip sequence enrollment"
          />
          <span className="field-hint">
            Leads will be automatically enrolled in this sequence
          </span>
        </div>
      </section>

      {/* Notifications */}
      <section className="settings-section">
        <h3>Notifications</h3>

        <div className="form-field">
          <label>Notify Emails (one per line)</label>
          <textarea
            value={(settings.notifyEmails || []).join('\n')}
            onChange={(e) =>
              onSettingsChange({
                ...settings,
                notifyEmails: e.target.value
                  .split('\n')
                  .map((t) => t.trim())
                  .filter(Boolean),
              })
            }
            placeholder="sales@example.com&#10;manager@example.com"
            rows={3}
          />
          <span className="field-hint">
            Team members who will be notified of new submissions
          </span>
        </div>
      </section>

      {/* Spam Protection */}
      <section className="settings-section">
        <h3>Spam Protection</h3>

        <div className="form-field checkbox">
          <label>
            <input
              type="checkbox"
              checked={spamProtection.honeypot}
              onChange={(e) =>
                onSpamProtectionChange({
                  ...spamProtection,
                  honeypot: e.target.checked,
                })
              }
            />
            Enable Honeypot Field
          </label>
          <span className="field-hint">
            Invisible field to detect and block bots
          </span>
        </div>

        <div className="form-field">
          <label>Rate Limit (submissions per IP per hour)</label>
          <input
            type="number"
            min="1"
            max="100"
            value={spamProtection.rateLimit}
            onChange={(e) =>
              onSpamProtectionChange({
                ...spamProtection,
                rateLimit: parseInt(e.target.value, 10) || 10,
              })
            }
          />
        </div>

        <div className="form-field checkbox">
          <label>
            <input
              type="checkbox"
              checked={spamProtection.recaptchaEnabled}
              onChange={(e) =>
                onSpamProtectionChange({
                  ...spamProtection,
                  recaptchaEnabled: e.target.checked,
                })
              }
            />
            Enable reCAPTCHA
          </label>
          <span className="field-hint">
            Requires Google reCAPTCHA setup in Cloud Functions
          </span>
        </div>
      </section>

      {/* Styling */}
      <section className="settings-section">
        <h3>Appearance</h3>

        <div className="form-field">
          <label>Color Theme</label>
          <select
            value={styling.theme}
            onChange={(e) =>
              onStylingChange({
                ...styling,
                theme: e.target.value as 'light' | 'dark' | 'auto',
              })
            }
          >
            <option value="light">Light</option>
            <option value="dark">Dark</option>
            <option value="auto">Auto (system preference)</option>
          </select>
        </div>

        <div className="form-field">
          <label>Primary Color</label>
          <div className="color-input-wrapper">
            <input
              type="color"
              value={styling.primaryColor || '#3B82F6'}
              onChange={(e) =>
                onStylingChange({ ...styling, primaryColor: e.target.value })
              }
            />
            <input
              type="text"
              value={styling.primaryColor || '#3B82F6'}
              onChange={(e) =>
                onStylingChange({ ...styling, primaryColor: e.target.value })
              }
              placeholder="#3B82F6"
              pattern="^#[0-9A-Fa-f]{6}$"
            />
          </div>
        </div>

        <div className="form-field">
          <label>Font Family</label>
          <select
            value={styling.fontFamily || 'system-ui, sans-serif'}
            onChange={(e) =>
              onStylingChange({ ...styling, fontFamily: e.target.value })
            }
          >
            <option value="system-ui, sans-serif">System Default</option>
            <option value="Arial, sans-serif">Arial</option>
            <option value="'Helvetica Neue', sans-serif">Helvetica</option>
            <option value="Georgia, serif">Georgia</option>
            <option value="'Times New Roman', serif">Times New Roman</option>
            <option value="'Courier New', monospace">Courier New</option>
          </select>
        </div>
      </section>
    </div>
  );
}

export default FormSettings;
