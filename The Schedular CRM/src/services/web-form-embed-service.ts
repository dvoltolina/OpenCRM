/**
 * Web Form Embed Service
 * Generates embed code snippets for web forms
 *
 * Agent Web Forms Implementation
 *
 * Security Notes:
 * - Embed script should be served from CDN with integrity hash
 * - Form config endpoint returns only public-safe data
 * - reCAPTCHA secret key must be in Cloud Function, not client
 */

import type { WebForm } from '../types/web-forms';

// ============================================
// Configuration
// ============================================

/**
 * CDN/hosting configuration for embed scripts
 * These would typically come from environment config
 */
const EMBED_CONFIG = {
  /** Base URL for the embed script */
  scriptBaseUrl: 'https://forms.example.com',
  /** API endpoint for form config and submissions */
  apiBaseUrl: 'https://api.example.com',
  /** Current embed script version */
  scriptVersion: '1.0.0',
};

// ============================================
// Embed Code Types
// ============================================

export interface EmbedCodeOptions {
  /** Include inline styles */
  includeStyles?: boolean;
  /** Use async script loading */
  async?: boolean;
  /** Custom container ID */
  containerId?: string;
}

export interface EmbedCodeResult {
  /** HTML snippet to embed */
  html: string;
  /** JavaScript snippet (alternative to script tag) */
  javascript?: string;
  /** Direct link to form (popup/iframe option) */
  directLink: string;
  /** Iframe embed code */
  iframeHtml: string;
}

// ============================================
// Embed Script Generator Service
// ============================================

export class WebFormEmbedService {
  /**
   * Generate embed code for a web form
   *
   * @param form - The web form to generate embed code for
   * @param businessId - Business ID for API calls
   * @param options - Embed code options
   */
  generateEmbedCode(
    form: WebForm,
    businessId: string,
    options: EmbedCodeOptions = {}
  ): EmbedCodeResult {
    const {
      async = true,
      containerId = `scheduler-form-${form.id}`,
    } = options;

    const formId = form.id;
    const scriptUrl = `${EMBED_CONFIG.scriptBaseUrl}/embed.js`;

    // Standard embed snippet
    const html = this.generateHtmlEmbed(
      formId,
      businessId,
      containerId,
      scriptUrl,
      async
    );

    // JavaScript-only snippet (for SPA integrations)
    const javascript = this.generateJavaScriptEmbed(
      formId,
      businessId,
      containerId,
      scriptUrl
    );

    // Direct link for popup/modal usage
    const directLink = `${EMBED_CONFIG.scriptBaseUrl}/form/${businessId}/${formId}`;

    // Iframe embed for maximum isolation
    const iframeHtml = this.generateIframeEmbed(directLink, form.name);

    return {
      html,
      javascript,
      directLink,
      iframeHtml,
    };
  }

  /**
   * Generate HTML embed snippet
   */
  private generateHtmlEmbed(
    formId: string,
    businessId: string,
    containerId: string,
    scriptUrl: string,
    async: boolean
  ): string {
    const asyncAttr = async ? ' async' : '';

    return `<!-- The Scheduler CRM Form -->
<div id="${containerId}"></div>
<script
  src="${scriptUrl}"
  data-form-id="${formId}"
  data-business-id="${businessId}"
  data-container="${containerId}"${asyncAttr}
></script>
<!-- End The Scheduler CRM Form -->`;
  }

  /**
   * Generate JavaScript-only embed snippet
   * Useful for SPAs where script tags may not work
   */
  private generateJavaScriptEmbed(
    formId: string,
    businessId: string,
    containerId: string,
    scriptUrl: string
  ): string {
    return `// The Scheduler CRM Form
(function() {
  // Create container if it doesn't exist
  if (!document.getElementById('${containerId}')) {
    var container = document.createElement('div');
    container.id = '${containerId}';
    document.body.appendChild(container);
  }

  // Load embed script
  var script = document.createElement('script');
  script.src = '${scriptUrl}';
  script.dataset.formId = '${formId}';
  script.dataset.businessId = '${businessId}';
  script.dataset.container = '${containerId}';
  script.async = true;
  document.head.appendChild(script);
})();`;
  }

  /**
   * Generate iframe embed snippet
   * Maximum isolation, but less flexible styling
   */
  private generateIframeEmbed(directLink: string, formName: string): string {
    return `<!-- The Scheduler CRM Form (iframe) -->
<iframe
  src="${directLink}"
  title="${this.escapeHtml(formName)}"
  width="100%"
  height="500"
  frameborder="0"
  style="border: none; max-width: 600px;"
  allow="clipboard-write"
></iframe>
<!-- End The Scheduler CRM Form -->`;
  }

  /**
   * Generate the embed script content itself
   * This would be served as a static file from CDN
   */
  generateEmbedScriptContent(): string {
    return `/**
 * The Scheduler CRM - Form Embed Script
 * Version: ${EMBED_CONFIG.scriptVersion}
 *
 * This script renders embeddable lead capture forms.
 * It should be served from a CDN with proper caching and integrity hash.
 */
(function() {
  'use strict';

  var API_BASE = '${EMBED_CONFIG.apiBaseUrl}';

  // Find the script tag that loaded us
  var scripts = document.getElementsByTagName('script');
  var currentScript = scripts[scripts.length - 1];

  var formId = currentScript.dataset.formId;
  var businessId = currentScript.dataset.businessId;
  var containerId = currentScript.dataset.container || 'scheduler-form-' + formId;

  if (!formId || !businessId) {
    console.error('[SchedulerForm] Missing required data attributes: data-form-id, data-business-id');
    return;
  }

  var container = document.getElementById(containerId);
  if (!container) {
    console.error('[SchedulerForm] Container not found: ' + containerId);
    return;
  }

  // Show loading state
  container.innerHTML = '<div style="text-align: center; padding: 20px;">Loading form...</div>';

  // Fetch form configuration
  fetch(API_BASE + '/v1/forms/' + businessId + '/' + formId + '/config')
    .then(function(response) {
      if (!response.ok) {
        throw new Error('Form not found');
      }
      return response.json();
    })
    .then(function(config) {
      renderForm(container, config, businessId);
    })
    .catch(function(error) {
      container.innerHTML = '<div style="color: red; padding: 20px;">Form unavailable</div>';
      console.error('[SchedulerForm]', error);
    });

  function renderForm(container, config, businessId) {
    // Apply theme styles
    var theme = config.styling.theme || 'light';
    var primaryColor = config.styling.primaryColor || '#3B82F6';
    var fontFamily = config.styling.fontFamily || 'system-ui, sans-serif';

    var isDark = theme === 'dark' || (theme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
    var bgColor = isDark ? '#1f2937' : '#ffffff';
    var textColor = isDark ? '#f9fafb' : '#111827';
    var borderColor = isDark ? '#374151' : '#d1d5db';
    var inputBg = isDark ? '#374151' : '#f9fafb';

    var styles = \`
      .scheduler-form {
        font-family: \${fontFamily};
        background: \${bgColor};
        color: \${textColor};
        padding: 24px;
        border-radius: 8px;
        max-width: 500px;
      }
      .scheduler-form-field {
        margin-bottom: 16px;
      }
      .scheduler-form-label {
        display: block;
        margin-bottom: 4px;
        font-weight: 500;
        font-size: 14px;
      }
      .scheduler-form-required {
        color: #ef4444;
        margin-left: 2px;
      }
      .scheduler-form-input {
        width: 100%;
        padding: 10px 12px;
        border: 1px solid \${borderColor};
        border-radius: 6px;
        font-size: 16px;
        background: \${inputBg};
        color: \${textColor};
        box-sizing: border-box;
      }
      .scheduler-form-input:focus {
        outline: none;
        border-color: \${primaryColor};
        box-shadow: 0 0 0 3px \${primaryColor}22;
      }
      .scheduler-form-textarea {
        min-height: 100px;
        resize: vertical;
      }
      .scheduler-form-checkbox-wrapper {
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .scheduler-form-checkbox {
        width: 18px;
        height: 18px;
        accent-color: \${primaryColor};
      }
      .scheduler-form-submit {
        width: 100%;
        padding: 12px 24px;
        background: \${primaryColor};
        color: white;
        border: none;
        border-radius: 6px;
        font-size: 16px;
        font-weight: 600;
        cursor: pointer;
        transition: opacity 0.2s;
      }
      .scheduler-form-submit:hover {
        opacity: 0.9;
      }
      .scheduler-form-submit:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }
      .scheduler-form-error {
        color: #ef4444;
        font-size: 12px;
        margin-top: 4px;
      }
      .scheduler-form-success {
        text-align: center;
        padding: 40px 20px;
      }
      .scheduler-form-success-icon {
        font-size: 48px;
        margin-bottom: 16px;
      }
      .scheduler-form-honeypot {
        position: absolute;
        left: -9999px;
        opacity: 0;
        pointer-events: none;
      }
    \`;

    // Inject styles
    var styleEl = document.createElement('style');
    styleEl.textContent = styles;
    document.head.appendChild(styleEl);

    // Build form HTML
    var formHtml = '<form class="scheduler-form" id="scheduler-form-' + config.id + '">';

    // Honeypot field (spam protection)
    if (config.honeypotEnabled) {
      formHtml += '<div class="scheduler-form-honeypot">';
      formHtml += '<input type="text" name="scheduler_hp" tabindex="-1" autocomplete="off">';
      formHtml += '</div>';
    }

    // Form fields
    config.fields.forEach(function(field) {
      formHtml += '<div class="scheduler-form-field">';
      formHtml += '<label class="scheduler-form-label" for="field-' + field.id + '">';
      formHtml += escapeHtml(field.label);
      if (field.required) {
        formHtml += '<span class="scheduler-form-required">*</span>';
      }
      formHtml += '</label>';

      if (field.type === 'textarea') {
        formHtml += '<textarea';
        formHtml += ' class="scheduler-form-input scheduler-form-textarea"';
        formHtml += ' id="field-' + field.id + '"';
        formHtml += ' name="' + field.id + '"';
        formHtml += ' placeholder="' + escapeHtml(field.placeholder || '') + '"';
        if (field.required) formHtml += ' required';
        formHtml += '></textarea>';
      } else if (field.type === 'select') {
        formHtml += '<select';
        formHtml += ' class="scheduler-form-input"';
        formHtml += ' id="field-' + field.id + '"';
        formHtml += ' name="' + field.id + '"';
        if (field.required) formHtml += ' required';
        formHtml += '>';
        formHtml += '<option value="">Select...</option>';
        (field.options || []).forEach(function(opt) {
          formHtml += '<option value="' + escapeHtml(opt) + '">' + escapeHtml(opt) + '</option>';
        });
        formHtml += '</select>';
      } else if (field.type === 'checkbox') {
        formHtml += '<div class="scheduler-form-checkbox-wrapper">';
        formHtml += '<input type="checkbox"';
        formHtml += ' class="scheduler-form-checkbox"';
        formHtml += ' id="field-' + field.id + '"';
        formHtml += ' name="' + field.id + '"';
        if (field.required) formHtml += ' required';
        formHtml += '>';
        formHtml += '</div>';
      } else {
        formHtml += '<input';
        formHtml += ' type="' + field.type + '"';
        formHtml += ' class="scheduler-form-input"';
        formHtml += ' id="field-' + field.id + '"';
        formHtml += ' name="' + field.id + '"';
        formHtml += ' placeholder="' + escapeHtml(field.placeholder || '') + '"';
        if (field.required) formHtml += ' required';
        formHtml += '>';
      }

      formHtml += '<div class="scheduler-form-error" id="error-' + field.id + '"></div>';
      formHtml += '</div>';
    });

    // Submit button
    formHtml += '<button type="submit" class="scheduler-form-submit">';
    formHtml += escapeHtml(config.submitButtonText);
    formHtml += '</button>';

    formHtml += '</form>';

    container.innerHTML = formHtml;

    // Handle form submission
    var form = document.getElementById('scheduler-form-' + config.id);
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      handleSubmit(form, config, businessId);
    });
  }

  function handleSubmit(form, config, businessId) {
    var submitBtn = form.querySelector('.scheduler-form-submit');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Submitting...';

    // Gather field values
    var fieldValues = {};
    config.fields.forEach(function(field) {
      var input = form.querySelector('[name="' + field.id + '"]');
      if (input) {
        if (field.type === 'checkbox') {
          fieldValues[field.id] = input.checked;
        } else {
          fieldValues[field.id] = input.value;
        }
      }
    });

    // Get honeypot value
    var honeypotInput = form.querySelector('[name="scheduler_hp"]');
    var honeypotValue = honeypotInput ? honeypotInput.value : '';

    // Get UTM params from URL
    var urlParams = new URLSearchParams(window.location.search);

    var submission = {
      formId: config.id,
      fieldValues: fieldValues,
      honeypotValue: honeypotValue,
      metadata: {
        referrerUrl: document.referrer || null,
        utmSource: urlParams.get('utm_source') || null,
        utmMedium: urlParams.get('utm_medium') || null,
        utmCampaign: urlParams.get('utm_campaign') || null,
        utmTerm: urlParams.get('utm_term') || null,
        utmContent: urlParams.get('utm_content') || null,
        submittedAt: new Date().toISOString(),
        userAgent: navigator.userAgent
      }
    };

    fetch(API_BASE + '/v1/forms/' + businessId + '/submit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(submission)
    })
    .then(function(response) { return response.json(); })
    .then(function(result) {
      if (result.success) {
        showSuccess(form.parentNode, config);
      } else {
        showError(form, result.error || 'Submission failed');
        submitBtn.disabled = false;
        submitBtn.textContent = config.submitButtonText;
      }
    })
    .catch(function(error) {
      showError(form, 'Network error. Please try again.');
      submitBtn.disabled = false;
      submitBtn.textContent = config.submitButtonText;
    });
  }

  function showSuccess(container, config) {
    container.innerHTML = \`
      <div class="scheduler-form scheduler-form-success">
        <div class="scheduler-form-success-icon">✓</div>
        <p>\${escapeHtml(config.successMessage)}</p>
      </div>
    \`;

    if (config.redirectUrl) {
      setTimeout(function() {
        window.location.href = config.redirectUrl;
      }, 2000);
    }
  }

  function showError(form, message) {
    var existingError = form.querySelector('.scheduler-form-submit-error');
    if (existingError) existingError.remove();

    var errorDiv = document.createElement('div');
    errorDiv.className = 'scheduler-form-error scheduler-form-submit-error';
    errorDiv.textContent = message;
    errorDiv.style.marginTop = '12px';
    errorDiv.style.textAlign = 'center';

    form.appendChild(errorDiv);
  }

  function escapeHtml(str) {
    if (!str) return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
})();`;
  }

  /**
   * Escape HTML entities
   */
  private escapeHtml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}

// ============================================
// Singleton Export
// ============================================

let webFormEmbedServiceInstance: WebFormEmbedService | null = null;

export function getWebFormEmbedService(): WebFormEmbedService {
  if (!webFormEmbedServiceInstance) {
    webFormEmbedServiceInstance = new WebFormEmbedService();
  }
  return webFormEmbedServiceInstance;
}
