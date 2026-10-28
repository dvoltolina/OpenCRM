/**
 * FormBuilder Component
 * Visual editor for creating and editing web forms
 *
 * Agent Web Forms Implementation
 */

import { useState, useCallback } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  WebForm,
  WebFormField,
  WebFormFieldType,
  LeadFieldMapping,
} from '../../types/web-forms';
import {
  DEFAULT_SPAM_PROTECTION,
  DEFAULT_STYLING,
  DEFAULT_SETTINGS,
  createDefaultField,
} from '../../types/web-forms';
import { getWebFormRepository } from '../../data/repositories/web-form-repository';
import { FormPreview } from './FormPreview';
import { FormSettings } from './FormSettings';

interface FormBuilderProps {
  form: WebForm | null;
  context: SecurityContext | null;
  onSave: () => void;
  onClose: () => void;
}

type BuilderTab = 'fields' | 'settings' | 'preview';

/**
 * FormBuilder - Create and edit web forms
 */
export function FormBuilder({ form, context, onSave, onClose }: FormBuilderProps) {
  const isEditing = Boolean(form);
  const [activeTab, setActiveTab] = useState<BuilderTab>('fields');
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState(form?.name || '');
  const [description, setDescription] = useState(form?.description || '');
  const [fields, setFields] = useState<WebFormField[]>(
    form?.fields || getDefaultFields()
  );
  const [settings, setSettings] = useState(form?.settings || { ...DEFAULT_SETTINGS });
  const [spamProtection, setSpamProtection] = useState(
    form?.spamProtection || { ...DEFAULT_SPAM_PROTECTION }
  );
  const [styling, setStyling] = useState(form?.styling || { ...DEFAULT_STYLING });

  const repository = getWebFormRepository();

  // Generate unique field ID
  const generateFieldId = useCallback(() => {
    return `field_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }, []);

  // Add new field
  const handleAddField = useCallback(
    (type: WebFormFieldType) => {
      const labelMap: Record<WebFormFieldType, string> = {
        text: 'Text Field',
        email: 'Email',
        phone: 'Phone',
        textarea: 'Message',
        select: 'Select Option',
        checkbox: 'Checkbox',
        hidden: 'Hidden Field',
      };

      const mappingMap: Record<WebFormFieldType, LeadFieldMapping> = {
        text: 'firstName',
        email: 'email',
        phone: 'phone',
        textarea: 'notes',
        select: 'source',
        checkbox: 'notes',
        hidden: 'source',
      };

      const newField = createDefaultField(
        generateFieldId(),
        type,
        labelMap[type],
        mappingMap[type]
      );

      if (type === 'select') {
        newField.options = ['Option 1', 'Option 2', 'Option 3'];
      }

      setFields((prev) => [...prev, newField]);
    },
    [generateFieldId]
  );

  // Remove field
  const handleRemoveField = useCallback((fieldId: string) => {
    setFields((prev) => prev.filter((f) => f.id !== fieldId));
  }, []);

  // Update field
  const handleUpdateField = useCallback(
    (fieldId: string, updates: Partial<WebFormField>) => {
      setFields((prev) =>
        prev.map((f) => (f.id === fieldId ? { ...f, ...updates } : f))
      );
    },
    []
  );

  // Move field
  const handleMoveField = useCallback((fromIndex: number, toIndex: number) => {
    setFields((prev) => {
      const newFields = [...prev];
      const [removed] = newFields.splice(fromIndex, 1);
      newFields.splice(toIndex, 0, removed);
      return newFields;
    });
  }, []);

  // Save form
  const handleSave = useCallback(async () => {
    if (!context) {
      setError('Not authenticated');
      return;
    }

    if (!name.trim()) {
      setError('Form name is required');
      return;
    }

    if (fields.length === 0) {
      setError('At least one field is required');
      return;
    }

    const hasEmail = fields.some((f) => f.mapToField === 'email');
    if (!hasEmail) {
      setError('Form must have at least one email field');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const formData = {
        name: name.trim(),
        description: description.trim() || undefined,
        status: form?.status || ('inactive' as const),
        fields,
        settings,
        spamProtection,
        styling,
        ownerId: form?.ownerId || context.userId,
        ownerName: form?.ownerName || context.userName,
        teamIds: form?.teamIds || context.teamIds || [],
        visibility: form?.visibility || ('team' as const),
      };

      if (isEditing && form) {
        const result = await repository.update(context, form.id, formData);
        if (!result.success) {
          setError(result.error?.message || 'Failed to update form');
          return;
        }
      } else {
        const result = await repository.create(context, formData as any);
        if (!result.success) {
          setError(result.error?.message || 'Failed to create form');
          return;
        }
      }

      onSave();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setIsSaving(false);
    }
  }, [
    context,
    name,
    description,
    fields,
    settings,
    spamProtection,
    styling,
    form,
    isEditing,
    repository,
    onSave,
  ]);

  // Build preview form object
  const previewForm: WebForm = {
    id: form?.id || 'preview',
    name: name || 'Preview Form',
    description,
    status: 'active',
    fields,
    settings,
    spamProtection,
    styling,
    stats: form?.stats || { totalSubmissions: 0, submissionsThisMonth: 0 },
    ownerId: context?.userId || '',
    ownerName: context?.userName || '',
    teamIds: [],
    visibility: 'team',
    createdAt: form?.createdAt || new Date(),
  };

  return (
    <div className="form-builder-overlay">
      <div className="form-builder-modal">
        {/* Header */}
        <div className="form-builder-header">
          <h2>{isEditing ? 'Edit Form' : 'Create New Form'}</h2>
          <button className="btn-close" onClick={onClose}>
            ×
          </button>
        </div>

        {/* Tabs */}
        <div className="form-builder-tabs">
          <button
            className={`tab ${activeTab === 'fields' ? 'active' : ''}`}
            onClick={() => setActiveTab('fields')}
          >
            Fields
          </button>
          <button
            className={`tab ${activeTab === 'settings' ? 'active' : ''}`}
            onClick={() => setActiveTab('settings')}
          >
            Settings
          </button>
          <button
            className={`tab ${activeTab === 'preview' ? 'active' : ''}`}
            onClick={() => setActiveTab('preview')}
          >
            Preview
          </button>
        </div>

        {/* Error */}
        {error && <div className="form-builder-error">{error}</div>}

        {/* Content */}
        <div className="form-builder-content">
          {activeTab === 'fields' && (
            <FieldsEditor
              name={name}
              description={description}
              fields={fields}
              onNameChange={setName}
              onDescriptionChange={setDescription}
              onAddField={handleAddField}
              onRemoveField={handleRemoveField}
              onUpdateField={handleUpdateField}
              onMoveField={handleMoveField}
            />
          )}

          {activeTab === 'settings' && (
            <FormSettings
              settings={settings}
              spamProtection={spamProtection}
              styling={styling}
              onSettingsChange={setSettings}
              onSpamProtectionChange={setSpamProtection}
              onStylingChange={setStyling}
            />
          )}

          {activeTab === 'preview' && <FormPreview form={previewForm} />}
        </div>

        {/* Footer */}
        <div className="form-builder-footer">
          <button className="btn-secondary" onClick={onClose} disabled={isSaving}>
            Cancel
          </button>
          <button className="btn-primary" onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Form'}
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * FieldsEditor - Edit form fields
 */
interface FieldsEditorProps {
  name: string;
  description: string;
  fields: WebFormField[];
  onNameChange: (name: string) => void;
  onDescriptionChange: (desc: string) => void;
  onAddField: (type: WebFormFieldType) => void;
  onRemoveField: (fieldId: string) => void;
  onUpdateField: (fieldId: string, updates: Partial<WebFormField>) => void;
  onMoveField: (fromIndex: number, toIndex: number) => void;
}

function FieldsEditor({
  name,
  description,
  fields,
  onNameChange,
  onDescriptionChange,
  onAddField,
  onRemoveField,
  onUpdateField,
  onMoveField,
}: FieldsEditorProps) {
  const fieldTypes: { type: WebFormFieldType; label: string }[] = [
    { type: 'text', label: 'Text' },
    { type: 'email', label: 'Email' },
    { type: 'phone', label: 'Phone' },
    { type: 'textarea', label: 'Text Area' },
    { type: 'select', label: 'Dropdown' },
    { type: 'checkbox', label: 'Checkbox' },
    { type: 'hidden', label: 'Hidden' },
  ];

  const leadMappings: { value: LeadFieldMapping; label: string }[] = [
    { value: 'firstName', label: 'First Name' },
    { value: 'lastName', label: 'Last Name' },
    { value: 'email', label: 'Email' },
    { value: 'phone', label: 'Phone' },
    { value: 'companyName', label: 'Company' },
    { value: 'title', label: 'Job Title' },
    { value: 'source', label: 'Lead Source' },
    { value: 'notes', label: 'Notes' },
  ];

  return (
    <div className="fields-editor">
      {/* Form Name & Description */}
      <div className="form-meta">
        <div className="form-field">
          <label>Form Name *</label>
          <input
            type="text"
            value={name}
            onChange={(e) => onNameChange(e.target.value)}
            placeholder="e.g., Contact Us Form"
          />
        </div>
        <div className="form-field">
          <label>Description</label>
          <input
            type="text"
            value={description}
            onChange={(e) => onDescriptionChange(e.target.value)}
            placeholder="Optional description for internal reference"
          />
        </div>
      </div>

      {/* Add Field Buttons */}
      <div className="add-field-section">
        <label>Add Field</label>
        <div className="add-field-buttons">
          {fieldTypes.map(({ type, label }) => (
            <button
              key={type}
              className="btn-add-field"
              onClick={() => onAddField(type)}
            >
              + {label}
            </button>
          ))}
        </div>
      </div>

      {/* Fields List */}
      <div className="fields-list">
        {fields.length === 0 ? (
          <div className="fields-empty">
            No fields yet. Add fields using the buttons above.
          </div>
        ) : (
          fields.map((field, index) => (
            <div key={field.id} className="field-item">
              <div className="field-item-header">
                <div className="field-item-drag">
                  <button
                    disabled={index === 0}
                    onClick={() => onMoveField(index, index - 1)}
                  >
                    ↑
                  </button>
                  <button
                    disabled={index === fields.length - 1}
                    onClick={() => onMoveField(index, index + 1)}
                  >
                    ↓
                  </button>
                </div>
                <span className="field-item-type">{field.type}</span>
                <button
                  className="btn-remove-field"
                  onClick={() => onRemoveField(field.id)}
                >
                  ×
                </button>
              </div>

              <div className="field-item-body">
                <div className="field-row">
                  <div className="form-field">
                    <label>Label</label>
                    <input
                      type="text"
                      value={field.label}
                      onChange={(e) =>
                        onUpdateField(field.id, { label: e.target.value })
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label>Maps To</label>
                    <select
                      value={field.mapToField}
                      onChange={(e) =>
                        onUpdateField(field.id, {
                          mapToField: e.target.value as LeadFieldMapping,
                        })
                      }
                    >
                      {leadMappings.map(({ value, label }) => (
                        <option key={value} value={value}>
                          {label}
                        </option>
                      ))}
                      <option value="customField_custom">Custom Field</option>
                    </select>
                  </div>
                </div>

                <div className="field-row">
                  <div className="form-field">
                    <label>Placeholder</label>
                    <input
                      type="text"
                      value={field.placeholder || ''}
                      onChange={(e) =>
                        onUpdateField(field.id, { placeholder: e.target.value })
                      }
                    />
                  </div>
                  <div className="form-field checkbox">
                    <label>
                      <input
                        type="checkbox"
                        checked={field.required}
                        onChange={(e) =>
                          onUpdateField(field.id, { required: e.target.checked })
                        }
                      />
                      Required
                    </label>
                  </div>
                </div>

                {field.type === 'select' && (
                  <div className="form-field">
                    <label>Options (one per line)</label>
                    <textarea
                      value={(field.options || []).join('\n')}
                      onChange={(e) =>
                        onUpdateField(field.id, {
                          options: e.target.value.split('\n').filter((o) => o.trim()),
                        })
                      }
                      rows={3}
                    />
                  </div>
                )}

                {field.type === 'hidden' && (
                  <div className="form-field">
                    <label>Default Value</label>
                    <input
                      type="text"
                      value={field.defaultValue || ''}
                      onChange={(e) =>
                        onUpdateField(field.id, { defaultValue: e.target.value })
                      }
                    />
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

/**
 * Get default fields for new forms
 */
function getDefaultFields(): WebFormField[] {
  return [
    {
      id: 'default_first_name',
      type: 'text',
      label: 'First Name',
      placeholder: 'Enter your first name',
      required: true,
      mapToField: 'firstName',
    },
    {
      id: 'default_last_name',
      type: 'text',
      label: 'Last Name',
      placeholder: 'Enter your last name',
      required: true,
      mapToField: 'lastName',
    },
    {
      id: 'default_email',
      type: 'email',
      label: 'Email',
      placeholder: 'Enter your email',
      required: true,
      mapToField: 'email',
    },
    {
      id: 'default_phone',
      type: 'phone',
      label: 'Phone',
      placeholder: 'Enter your phone number',
      required: false,
      mapToField: 'phone',
    },
    {
      id: 'default_message',
      type: 'textarea',
      label: 'Message',
      placeholder: 'How can we help you?',
      required: false,
      mapToField: 'notes',
    },
  ];
}

export default FormBuilder;
