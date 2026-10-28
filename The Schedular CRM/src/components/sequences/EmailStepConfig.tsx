/**
 * EmailStepConfig Component
 * Configuration form for email steps
 */

import { useState, useCallback } from 'react';
import { MergeFieldPicker } from './MergeFieldPicker';
import type { EmailStepConfig as EmailConfig } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface EmailStepConfigProps {
  config: EmailConfig | undefined;
  onChange: (config: EmailConfig) => void;
  disabled?: boolean;
}

// ============================================
// Component
// ============================================

export function EmailStepConfig({
  config,
  onChange,
  disabled = false,
}: EmailStepConfigProps) {
  const [useTemplate, setUseTemplate] = useState(!!config?.templateId);

  const handleSubjectChange = useCallback(
    (subject: string) => {
      onChange({
        ...config,
        subject,
        templateId: undefined,
      });
    },
    [config, onChange]
  );

  const handleBodyChange = useCallback(
    (body: string) => {
      onChange({
        ...config,
        body,
        templateId: undefined,
      });
    },
    [config, onChange]
  );

  const handleTemplateChange = useCallback(
    (templateId: string) => {
      onChange({
        templateId,
        subject: undefined,
        body: undefined,
      });
    },
    [onChange]
  );

  const handleModeChange = useCallback(
    (isTemplate: boolean) => {
      setUseTemplate(isTemplate);
      if (isTemplate) {
        onChange({
          templateId: config?.templateId || '',
          subject: undefined,
          body: undefined,
        });
      } else {
        onChange({
          subject: config?.subject || '',
          body: config?.body || '',
          templateId: undefined,
        });
      }
    },
    [config, onChange]
  );

  const handleInsertMergeField = useCallback(
    (field: string, target: 'subject' | 'body') => {
      const currentValue = target === 'subject' ? config?.subject || '' : config?.body || '';
      const newValue = currentValue + `{{${field}}}`;
      if (target === 'subject') {
        handleSubjectChange(newValue);
      } else {
        handleBodyChange(newValue);
      }
    },
    [config, handleSubjectChange, handleBodyChange]
  );

  return (
    <div className="step-editor__section" data-testid="email-step-config">
      {/* Mode Toggle */}
      <div className="step-editor__field">
        <label className="step-editor__label">Email Content</label>
        <div className="step-editor__row">
          <label className="step-editor__checkbox-label">
            <input
              type="radio"
              name="email-mode"
              checked={!useTemplate}
              onChange={() => handleModeChange(false)}
              disabled={disabled}
            />
            Custom content
          </label>
          <label className="step-editor__checkbox-label">
            <input
              type="radio"
              name="email-mode"
              checked={useTemplate}
              onChange={() => handleModeChange(true)}
              disabled={disabled}
            />
            Use template
          </label>
        </div>
      </div>

      {useTemplate ? (
        /* Template Selection */
        <div className="step-editor__field">
          <label className="step-editor__label" htmlFor="email-template">
            Email Template
          </label>
          <select
            id="email-template"
            className="step-editor__select"
            value={config?.templateId || ''}
            onChange={(e) => handleTemplateChange(e.target.value)}
            disabled={disabled}
          >
            <option value="">Select a template...</option>
            {/* Templates would be loaded from a hook/context */}
            <option value="welcome">Welcome Email</option>
            <option value="follow-up">Follow-up</option>
            <option value="meeting-request">Meeting Request</option>
          </select>
          <span className="step-editor__hint">
            Templates are managed in Settings &gt; Email Templates
          </span>
        </div>
      ) : (
        /* Custom Content */
        <>
          <div className="step-editor__field">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <label className="step-editor__label" htmlFor="email-subject">
                Subject Line
              </label>
              <MergeFieldPicker
                onSelect={(field) => handleInsertMergeField(field, 'subject')}
              />
            </div>
            <input
              id="email-subject"
              type="text"
              className="step-editor__input"
              placeholder="e.g., Quick follow-up, {{firstName}}"
              value={config?.subject || ''}
              onChange={(e) => handleSubjectChange(e.target.value)}
              disabled={disabled}
            />
          </div>

          <div className="step-editor__field">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <label className="step-editor__label" htmlFor="email-body">
                Email Body
              </label>
              <MergeFieldPicker
                onSelect={(field) => handleInsertMergeField(field, 'body')}
              />
            </div>
            <textarea
              id="email-body"
              className="step-editor__textarea"
              placeholder="Hi {{firstName}},&#10;&#10;I wanted to follow up on our conversation..."
              value={config?.body || ''}
              onChange={(e) => handleBodyChange(e.target.value)}
              disabled={disabled}
              rows={6}
            />
            <span className="step-editor__hint">
              Use {'{{fieldName}}'} to insert merge fields. They will be replaced with actual values.
            </span>
          </div>
        </>
      )}
    </div>
  );
}

export default EmailStepConfig;
