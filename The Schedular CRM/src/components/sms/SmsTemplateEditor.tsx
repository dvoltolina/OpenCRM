/**
 * SMS Template Editor Component
 * Create and edit SMS templates
 *
 * Features:
 * - Template name and body editing
 * - Merge field insertion
 * - Real-time character/segment counting
 * - Preview with sample data
 * - Category selection
 * - PHI validation warnings
 */

import { useState, useCallback, useEffect } from 'react';
import { CharacterCounter } from './CharacterCounter';
import type { SmsTemplate, SmsCategory } from '../../types/sms';
import {
  calculateSegmentCount,
  SMS_CHAR_LIMITS,
} from '../../types/sms';
import { getMergeFieldProcessor } from '../../services/sequence-merge-fields';

interface SmsTemplateEditorProps {
  /** Existing template to edit (null for new) */
  template?: SmsTemplate | null;
  /** Callback when saved */
  onSave: (data: Omit<SmsTemplate, 'id' | 'createdAt' | 'updatedAt' | 'characterCount' | 'segmentCount'>) => Promise<void>;
  /** Callback when cancelled */
  onCancel?: () => void;
  /** Is saving in progress */
  isSaving?: boolean;
  /** Custom class name */
  className?: string;
}

export function SmsTemplateEditor({
  template,
  onSave,
  onCancel,
  isSaving = false,
  className = '',
}: SmsTemplateEditorProps) {
  const [name, setName] = useState(template?.name || '');
  const [body, setBody] = useState(template?.body || '');
  const [category, setCategory] = useState<SmsCategory>(template?.category || 'transactional');
  const [isActive, setIsActive] = useState(template?.isActive ?? true);
  const [showMergeFields, setShowMergeFields] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const mergeFieldProcessor = getMergeFieldProcessor();

  // Reset form when template changes
  useEffect(() => {
    if (template) {
      setName(template.name);
      setBody(template.body);
      setCategory(template.category);
      setIsActive(template.isActive);
    } else {
      setName('');
      setBody('');
      setCategory('transactional');
      setIsActive(true);
    }
  }, [template]);

  // Insert merge field at cursor
  const insertMergeField = useCallback(
    (fieldKey: string) => {
      const textArea = document.getElementById('template-body') as HTMLTextAreaElement;
      if (textArea) {
        const start = textArea.selectionStart;
        const end = textArea.selectionEnd;
        const newBody = body.slice(0, start) + `{{${fieldKey}}}` + body.slice(end);
        setBody(newBody);

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

  // Validate form
  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (!name.trim()) {
      newErrors.name = 'Template name is required';
    }

    if (!body.trim()) {
      newErrors.body = 'Message body is required';
    }

    const segmentCount = calculateSegmentCount(body);
    if (segmentCount > SMS_CHAR_LIMITS.MAX_SEGMENTS) {
      newErrors.body = `Message exceeds maximum of ${SMS_CHAR_LIMITS.MAX_SEGMENTS} segments`;
    }

    // Validate merge fields
    const validation = mergeFieldProcessor.validate(body);
    if (!validation.valid) {
      newErrors.mergeFields = `Unknown merge fields: ${validation.unknownFields.join(', ')}`;
    }

    // Check for PHI patterns
    const phiPatterns = [
      /\{\{.*ssn.*\}\}/i,
      /\{\{.*dob.*\}\}/i,
      /\{\{.*diagnosis.*\}\}/i,
      /\{\{.*treatment.*\}\}/i,
      /\{\{.*medical.*\}\}/i,
    ];
    for (const pattern of phiPatterns) {
      if (pattern.test(body)) {
        newErrors.phi = 'Template may contain PHI merge fields - please review';
        break;
      }
    }

    setErrors(newErrors);
    return (
      Object.keys(newErrors).length === 0 || (Object.keys(newErrors).length === 1 && Boolean(newErrors.phi))
    );
  }, [name, body, mergeFieldProcessor]);

  // Handle save
  const handleSave = useCallback(async () => {
    if (!validate()) {
      return;
    }

    const templateData: Omit<SmsTemplate, 'id' | 'createdAt' | 'updatedAt' | 'characterCount' | 'segmentCount'> = {
      businessId: template?.businessId || '',
      name: name.trim(),
      body: body,
      isActive,
      category,
      createdById: template?.createdById || '',
      createdByName: template?.createdByName,
    };

    try {
      await onSave(templateData);
    } catch (err) {
      setErrors({ submit: 'Failed to save template. Please try again.' });
    }
  }, [name, body, isActive, category, template, validate, onSave]);

  // Group merge fields by category
  const fieldsByCategory = mergeFieldProcessor.getFieldsByCategory();

  return (
    <div className={`bg-white rounded-lg shadow ${className}`}>
      {/* Header */}
      <div className="px-4 py-3 border-b">
        <h3 className="text-lg font-medium">
          {template ? 'Edit Template' : 'New SMS Template'}
        </h3>
      </div>

      <div className="p-4 space-y-4">
        {/* Template name */}
        <div>
          <label htmlFor="template-name" className="block text-sm font-medium text-gray-700 mb-1">
            Template Name
          </label>
          <input
            id="template-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g., Appointment Reminder"
            disabled={isSaving}
            className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
              errors.name ? 'border-red-300' : 'border-gray-300'
            }`}
          />
          {errors.name && (
            <p className="mt-1 text-sm text-red-600">{errors.name}</p>
          )}
        </div>

        {/* Category */}
        <div>
          <label htmlFor="template-category" className="block text-sm font-medium text-gray-700 mb-1">
            Category
          </label>
          <select
            id="template-category"
            value={category}
            onChange={(e) => setCategory(e.target.value as SmsCategory)}
            disabled={isSaving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="transactional">Transactional</option>
            <option value="marketing">Marketing</option>
          </select>
          <p className="mt-1 text-xs text-gray-500">
            {category === 'transactional'
              ? 'For appointment reminders, confirmations, and operational messages'
              : 'For promotional content - requires explicit opt-in'}
          </p>
        </div>

        {/* Message body */}
        <div>
          <div className="flex items-center justify-between mb-1">
            <label htmlFor="template-body" className="block text-sm font-medium text-gray-700">
              Message Body
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
              {Object.entries(fieldsByCategory).map(([cat, fields]) => (
                <div key={cat} className="mb-2">
                  <p className="text-xs font-medium text-gray-500 uppercase mb-1">
                    {cat}
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
            id="template-body"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Type your message here... Use {{firstName}} for personalization"
            rows={5}
            disabled={isSaving}
            className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none ${
              errors.body ? 'border-red-300' : 'border-gray-300'
            }`}
          />

          {/* Character counter */}
          <div className="mt-2">
            <CharacterCounter text={body} showCost showEncoding />
          </div>

          {errors.body && (
            <p className="mt-1 text-sm text-red-600">{errors.body}</p>
          )}
          {errors.mergeFields && (
            <p className="mt-1 text-sm text-amber-600">{errors.mergeFields}</p>
          )}
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

        {/* Active toggle */}
        <div className="flex items-center gap-2">
          <input
            id="template-active"
            type="checkbox"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
            disabled={isSaving}
            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
          />
          <label htmlFor="template-active" className="text-sm text-gray-700">
            Template is active
          </label>
        </div>

        {/* PHI warning */}
        {errors.phi && (
          <div className="p-3 bg-amber-50 border border-amber-200 rounded-md">
            <p className="text-sm text-amber-700 flex items-center gap-2">
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              {errors.phi}
            </p>
          </div>
        )}

        {/* Submit error */}
        {errors.submit && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{errors.submit}</p>
          </div>
        )}

        {/* HIPAA reminder */}
        <div className="p-3 bg-blue-50 border border-blue-200 rounded-md">
          <p className="text-xs text-blue-700">
            <strong>HIPAA Reminder:</strong> SMS templates must not contain protected health information (PHI).
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
            disabled={isSaving}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
          >
            Cancel
          </button>
        )}
        <button
          type="button"
          onClick={handleSave}
          disabled={isSaving || !name.trim() || !body.trim()}
          className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSaving ? 'Saving...' : template ? 'Update Template' : 'Create Template'}
        </button>
      </div>
    </div>
  );
}

export default SmsTemplateEditor;
