/**
 * EmbedCodeModal Component
 * Shows embed code options for web forms
 *
 * Agent Web Forms Implementation
 */

import { useState, useCallback } from 'react';
import type { WebForm } from '../../types/web-forms';
import { getWebFormEmbedService } from '../../services/web-form-embed-service';

interface EmbedCodeModalProps {
  form: WebForm;
  businessId: string;
  onClose: () => void;
}

type EmbedType = 'html' | 'javascript' | 'iframe' | 'link';

/**
 * EmbedCodeModal - Display embed code options
 */
export function EmbedCodeModal({ form, businessId, onClose }: EmbedCodeModalProps) {
  const [activeType, setActiveType] = useState<EmbedType>('html');
  const [copied, setCopied] = useState(false);

  const embedService = getWebFormEmbedService();
  const embedCode = embedService.generateEmbedCode(form, businessId);

  const getCode = useCallback(() => {
    switch (activeType) {
      case 'html':
        return embedCode.html;
      case 'javascript':
        return embedCode.javascript || '';
      case 'iframe':
        return embedCode.iframeHtml;
      case 'link':
        return embedCode.directLink;
    }
  }, [activeType, embedCode]);

  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(getCode());
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback for older browsers
      const textarea = document.createElement('textarea');
      textarea.value = getCode();
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  }, [getCode]);

  return (
    <div className="embed-modal-overlay" onClick={onClose}>
      <div className="embed-modal" onClick={(e) => e.stopPropagation()}>
        <div className="embed-modal-header">
          <h2>Embed "{form.name}"</h2>
          <button className="btn-close" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="embed-modal-content">
          {/* Embed Type Tabs */}
          <div className="embed-type-tabs">
            <button
              className={`embed-tab ${activeType === 'html' ? 'active' : ''}`}
              onClick={() => setActiveType('html')}
            >
              HTML Snippet
            </button>
            <button
              className={`embed-tab ${activeType === 'javascript' ? 'active' : ''}`}
              onClick={() => setActiveType('javascript')}
            >
              JavaScript
            </button>
            <button
              className={`embed-tab ${activeType === 'iframe' ? 'active' : ''}`}
              onClick={() => setActiveType('iframe')}
            >
              iFrame
            </button>
            <button
              className={`embed-tab ${activeType === 'link' ? 'active' : ''}`}
              onClick={() => setActiveType('link')}
            >
              Direct Link
            </button>
          </div>

          {/* Description */}
          <div className="embed-description">
            {activeType === 'html' && (
              <p>
                Copy and paste this snippet into your website's HTML. The form
                will render in place of the div element.
              </p>
            )}
            {activeType === 'javascript' && (
              <p>
                Use this JavaScript code for single-page applications (React,
                Vue, Angular) or when you need dynamic loading.
              </p>
            )}
            {activeType === 'iframe' && (
              <p>
                Use an iframe for maximum isolation. The form will be sandboxed
                but styling options are limited.
              </p>
            )}
            {activeType === 'link' && (
              <p>
                Share this direct link to the form. Useful for email campaigns
                or social media posts.
              </p>
            )}
          </div>

          {/* Code Display */}
          <div className="embed-code-container">
            <pre className="embed-code">{getCode()}</pre>
            <button
              className={`btn-copy ${copied ? 'copied' : ''}`}
              onClick={handleCopy}
            >
              {copied ? '✓ Copied!' : 'Copy to Clipboard'}
            </button>
          </div>

          {/* Additional Info */}
          <div className="embed-info">
            <h4>Important Notes:</h4>
            <ul>
              <li>The form must be in "Active" status to accept submissions.</li>
              <li>
                Submissions will create new leads in your CRM automatically.
              </li>
              <li>
                Spam protection is {form.spamProtection.honeypot ? 'enabled' : 'disabled'}.
              </li>
              {form.spamProtection.recaptchaEnabled && (
                <li>reCAPTCHA is enabled - ensure it's configured in your Cloud Functions.</li>
              )}
              {form.settings.sequenceId && (
                <li>Leads will be auto-enrolled in a sequence.</li>
              )}
            </ul>
          </div>
        </div>

        <div className="embed-modal-footer">
          <button className="btn-secondary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

export default EmbedCodeModal;
