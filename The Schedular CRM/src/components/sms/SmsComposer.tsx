/**
 * SMS Composer Component
 * Compose and send SMS messages with template support
 *
 * Features:
 * - Rich text area with character counter
 * - Template selection
 * - Merge field insertion
 * - Preview mode
 * - Opt-out status display
 *
 * HIPAA: No PHI should be entered directly - use merge fields
 */

import { useState, useCallback, useEffect } from 'react';
import { CharacterCounter } from './CharacterCounter';
import {
  calculateSegmentCount,
  SMS_CHAR_LIMITS,
  formatPhoneDisplay,
} from '../../types/sms';
import type { SmsTemplate } from '../../types/sms';
import { getMergeFieldProcessor } from '../../services/sequence-merge-fields';

interface SmsComposerProps {
  /** Initial message body */
  initialBody?: string;
  /** Recipient phone number */
  recipientPhone?: string;
  /** Recipient name for display */
  recipientName?: string;
  /** Available templates */
  templates?: SmsTemplate[];
  /** Whether recipient has opted out */
  isOptedOut?: boolean;
  /** Callback when message is sent */
  onSend: (body: string) => Promise<void>;
  /** Callback when cancelled */
  onCancel?: () => void;
  /** Show template selector */
  showTemplates?: boolean;
  /** Is sending in progress */
  isSending?: boolean;
  /** Custom class name */
  className?: string;
}

export function SmsComposer({
  initialBody = '',
  recipientPhone,
  recipientName,
  templates = [],
  isOptedOut = false,
  onSend,
  onCancel,
  showTemplates = true,
  isSending = false,
  className = '',
}: SmsComposerProps) {
  const [body, setBody] = useState(initialBody);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [showPreview, setShowPreview] = useState(false);
  const [showMergeFields, setShowMergeFields] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const mergeFieldProcessor = getMergeFieldProcessor();

  // Update body when initial value changes
  useEffect(() => {
    setBody(initialBody);
  }, [initialBody]);

  // Handle template selection
  const handleTemplateChange = useCallback(
    (templateId: string) => {
      setSelectedTemplate(templateId);
      if (templateId) {
        const template = templates.find((t) => t.id === templateId);
        if (template) {
          setBody(template.body);
        }
      }
    },
    [templates]
  );

  // Insert merge field at cursor
  const insertMergeField = useCallback(
    (fieldKey: string) => {
      const textArea = document.getElementById('sms-body') as HTMLTextAreaElement;
      if (textArea) {
        const start = textArea.selectionStart;
        const end = textArea.selectionEnd;
        const newBody = body.slice(0, start) + `{{${fieldKey}}}` + body.slice(end);
        setBody(newBody);

        // Move cursor after inserted field
        setTimeout(() => {
          textArea.focus();
          const newPos = start + fieldKey.length + 4;
          textArea.setSelectionRange(newPos, newPos);
        }, 0);
      }
      setShowMergeFields(false);
    },
    [body]
  );

  // Get preview with sample data
  const getPreview = useCallback(() => {
    return mergeFieldProcessor.preview(body);
  }, [body, mergeFieldProcessor]);

  // Validate and send
  const handleSend = useCallback(async () => {
    setError(null);

    // Validate message
    if (!body.trim()) {
      setError('Message cannot be empty');
      return;
    }

    const segmentCount = calculateSegmentCount(body);
    if (segmentCount > SMS_CHAR_LIMITS.MAX_SEGMENTS) {
      setError(`Message exceeds maximum of ${SMS_CHAR_LIMITS.MAX_SEGMENTS} segments`);
      return;
    }

    // Validate merge fields
    const validation = mergeFieldProcessor.validate(body);
    if (!validation.valid) {
      setError(`Unknown merge fields: ${validation.unknownFields.join(', ')}`);
      return;
    }

    try {
      await onSend(body);
    } catch (err) {
      setError('Failed to send message. Please try again.');
    }
  }, [body, onSend, mergeFieldProcessor]);

  // Group merge fields by category
  const fieldsByCategory = mergeFieldProcessor.getFieldsByCategory();

  return (
    <div className={`bg-white rounded-lg shadow ${className}`}>
      {/* Header */}
      <div className="px-4 py-3 border-b">
        <h3 className="text-lg font-medium">Compose SMS</h3>
        {recipientPhone && (
          <p className="text-sm text-gray-500 mt-1">
            To: {recipientName ? `${recipientName} (${formatPhoneDisplay(recipientPhone)})` : formatPhoneDisplay(recipientPhone)}
          </p>
        )}
      </div>

      {/* Opt-out warning */}
      {isOptedOut && (
        <div className="px-4 py-3 bg-red-50 border-b border-red-100">
          <p className="text-sm text-red-700 flex items-center gap-2">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
            This recipient has opted out of SMS messages
          </p>
        </div>
      )}

      <div className="p-4 space-y-4">
        {/* Template selector */}
        {showTemplates && templates.length > 0 && (
          <div>
            <label htmlFor="template-select" className="block text-sm font-medium text-gray-700 mb-1">
              Template
            </label>
            <select
              id="template-select"
              value={selectedTemplate}
              onChange={(e) => handleTemplateChange(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">None - Write custom message</option>
              {templates.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name} ({t.segmentCount} segment{t.segmentCount !== 1 ? 's' : ''})
                </option>
              ))}
            </select>
          </div>
        )}

        {/* Message body */}
        <div>
          <div className="flex items-center justify-between mb-1">
            <label htmlFor="sms-body" className="block text-sm font-medium text-gray-700">
              Message
            </label>
            <button
              type="button"
              onClick={() => setShowMergeFields(!showMergeFields)}
              className="text-sm text-blue-600 hover:text-blue-800"
            >
              + Insert merge field
            </button>
          </div>

          {/* Merge field dropdown */}
          {showMergeFields && (
            <div className="mb-2 p-3 bg-gray-50 rounded-md border max-h-48 overflow-y-auto">
              {Object.entries(fieldsByCategory).map(([category, fields]) => (
                <div key={category} className="mb-2">
                  <p className="text-xs font-medium text-gray-500 uppercase mb-1">
                    {category}
                  </p>
                  <div className="flex flex-wrap gap-1">
                    {fields.map((field) => (
                      <button
                        key={field.key}
                        type="button"
                        onClick={() => insertMergeField(field.key)}
                        className="px-2 py-1 text-xs bg-white border rounded hover:bg-blue-50 hover:border-blue-300"
                        title={`Example: ${field.example}`}
                      >
                        {`{{${field.key}}}`}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}

          <textarea
            id="sms-body"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Type your message here... Use {{firstName}} for personalization"
            rows={4}
            disabled={isOptedOut || isSending}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none disabled:bg-gray-100"
          />

          {/* Character counter */}
          <div className="mt-2">
            <CharacterCounter text={body} showCost showEncoding />
          </div>
        </div>

        {/* Preview toggle */}
        <div>
          <button
            type="button"
            onClick={() => setShowPreview(!showPreview)}
            className="text-sm text-gray-600 hover:text-gray-800"
          >
            {showPreview ? 'Hide preview' : 'Show preview'}
          </button>

          {showPreview && (
            <div className="mt-2 p-3 bg-gray-100 rounded-md">
              <p className="text-xs text-gray-500 mb-1">Preview with sample data:</p>
              <p className="text-sm whitespace-pre-wrap">{getPreview()}</p>
            </div>
          )}
        </div>

        {/* Error message */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* HIPAA reminder */}
        <div className="p-3 bg-amber-50 border border-amber-200 rounded-md">
          <p className="text-xs text-amber-700">
            <strong>HIPAA Reminder:</strong> Do not include protected health information (PHI) directly in SMS messages.
            Use merge fields for personalization and include secure portal links for sensitive content.
          </p>
        </div>
      </div>

      {/* Footer */}
      <div className="px-4 py-3 border-t bg-gray-50 flex justify-end gap-3">
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            disabled={isSending}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
          >
            Cancel
          </button>
        )}
        <button
          type="button"
          onClick={handleSend}
          disabled={isOptedOut || isSending || !body.trim()}
          className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSending ? 'Sending...' : 'Send SMS'}
        </button>
      </div>
    </div>
  );
}

export default SmsComposer;
