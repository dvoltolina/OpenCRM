/**
 * TemplateEditor Component
 * Create and edit form templates with drag-and-drop field ordering
 *
 * Agent CRM-30 Implementation
 */

import React, { useState, useEffect } from 'react';
import { useTemplateMutations } from '../../hooks/useTemplates';
import type {
  FormTemplate,
  TemplateField,
  TemplateFieldType,
  TemplateCategory,
} from '../../types/templates';
import { generateId } from '../../data/repositories/firestore-utils';
import './templates.css';

interface TemplateEditorProps {
  template?: FormTemplate | null;
  onSave: (template: FormTemplate) => void;
  onCancel: () => void;
}

const FIELD_TYPES: { value: TemplateFieldType; label: string }[] = [
  { value: 'text', label: 'Text' },
  { value: 'textarea', label: 'Text Area' },
  { value: 'number', label: 'Number' },
  { value: 'email', label: 'Email' },
  { value: 'phone', label: 'Phone' },
  { value: 'date', label: 'Date' },
  { value: 'checkbox', label: 'Checkbox' },
  { value: 'select', label: 'Select Dropdown' },
  { value: 'signature', label: 'Signature' },
];

const CATEGORIES: { value: TemplateCategory; label: string }[] = [
  { value: 'therapy', label: 'Therapy' },
  { value: 'real_estate', label: 'Real Estate' },
  { value: 'accounting', label: 'Accounting' },
  { value: 'custom', label: 'Custom' },
];

export function TemplateEditor({ template, onSave, onCancel }: TemplateEditorProps) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<TemplateCategory>('custom');
  const [tags, setTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState('');
  const [fields, setFields] = useState<TemplateField[]>([]);
  const [editingField, setEditingField] = useState<TemplateField | null>(null);

  const { createTemplate, updateTemplate, isLoading, error } = useTemplateMutations();

  // Load template data if editing
  useEffect(() => {
    if (template) {
      setName(template.name);
      setDescription(template.description || '');
      setCategory(template.category);
      setTags(template.tags);
      setFields([...template.fields].sort((a, b) => a.order - b.order));
    }
  }, [template]);

  const handleAddField = () => {
    const newField: TemplateField = {
      id: generateId(),
      type: 'text',
      label: 'New Field',
      required: false,
      order: fields.length,
    };
    setFields([...fields, newField]);
    setEditingField(newField);
  };

  const handleEditField = (field: TemplateField) => {
    setEditingField(field);
  };

  const handleSaveField = (updatedField: TemplateField) => {
    setFields(fields.map((f) => (f.id === updatedField.id ? updatedField : f)));
    setEditingField(null);
  };

  const handleDeleteField = (fieldId: string) => {
    setFields(fields.filter((f) => f.id !== fieldId).map((f, idx) => ({ ...f, order: idx })));
  };

  const handleMoveField = (fieldId: string, direction: 'up' | 'down') => {
    const index = fields.findIndex((f) => f.id === fieldId);
    if (index === -1) return;

    const newIndex = direction === 'up' ? index - 1 : index + 1;
    if (newIndex < 0 || newIndex >= fields.length) return;

    const newFields = [...fields];
    [newFields[index], newFields[newIndex]] = [newFields[newIndex], newFields[index]];
    setFields(newFields.map((f, idx) => ({ ...f, order: idx })));
  };

  const handleAddTag = () => {
    const trimmedTag = tagInput.trim();
    if (trimmedTag && !tags.includes(trimmedTag)) {
      setTags([...tags, trimmedTag]);
      setTagInput('');
    }
  };

  const handleRemoveTag = (tag: string) => {
    setTags(tags.filter((t) => t !== tag));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      alert('Please enter a template name');
      return;
    }

    if (fields.length === 0) {
      alert('Please add at least one field');
      return;
    }

    try {
      const templateData = {
        name: name.trim(),
        description: description.trim(),
        category,
        tags,
        fields,
        isSystem: false,
        isActive: true,
        usageCount: template?.usageCount || 0,
        lastUsedAt: template?.lastUsedAt,
        createdBy: template?.createdBy || '',
        createdByName: template?.createdByName || '',
      };

      if (template) {
        const updated = await updateTemplate(template.id, templateData);
        onSave(updated);
      } else {
        const created = await createTemplate(templateData);
        onSave(created);
      }
    } catch (err) {
      console.error('Failed to save template:', err);
    }
  };

  return (
    <div className="template-editor">
      <div className="template-editor-header">
        <h2>{template ? 'Edit Template' : 'Create New Template'}</h2>
      </div>

      <form onSubmit={handleSubmit} className="template-editor-form">
        <div className="template-editor-section">
          <h3>Basic Information</h3>

          <div className="form-group">
            <label htmlFor="template-name">Template Name *</label>
            <input
              id="template-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Client Intake Form"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="template-description">Description</label>
            <textarea
              id="template-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Brief description of this template"
              rows={3}
            />
          </div>

          <div className="form-group">
            <label htmlFor="template-category">Category *</label>
            <select
              id="template-category"
              value={category}
              onChange={(e) => setCategory(e.target.value as TemplateCategory)}
              required
            >
              {CATEGORIES.map((cat) => (
                <option key={cat.value} value={cat.value}>
                  {cat.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label htmlFor="template-tags">Tags</label>
            <div className="tag-input-container">
              <input
                id="template-tags"
                type="text"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                placeholder="Add a tag and press Enter"
              />
              <button type="button" onClick={handleAddTag} className="btn btn-sm">
                Add
              </button>
            </div>
            {tags.length > 0 && (
              <div className="tags-list">
                {tags.map((tag) => (
                  <span key={tag} className="tag">
                    {tag}
                    <button type="button" onClick={() => handleRemoveTag(tag)}>
                      &times;
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="template-editor-section">
          <div className="template-editor-section-header">
            <h3>Form Fields</h3>
            <button type="button" onClick={handleAddField} className="btn btn-primary">
              Add Field
            </button>
          </div>

          {fields.length === 0 ? (
            <div className="template-editor-empty">
              <p>No fields added yet. Click "Add Field" to get started.</p>
            </div>
          ) : (
            <div className="template-fields-list">
              {fields.map((field, index) => (
                <FieldRow
                  key={field.id}
                  field={field}
                  index={index}
                  totalFields={fields.length}
                  onEdit={handleEditField}
                  onDelete={handleDeleteField}
                  onMove={handleMoveField}
                />
              ))}
            </div>
          )}
        </div>

        {error && <div className="template-editor-error">{error.message}</div>}

        <div className="template-editor-actions">
          <button type="button" onClick={onCancel} className="btn btn-secondary" disabled={isLoading}>
            Cancel
          </button>
          <button type="submit" className="btn btn-primary" disabled={isLoading}>
            {isLoading ? 'Saving...' : template ? 'Update Template' : 'Create Template'}
          </button>
        </div>
      </form>

      {editingField && (
        <FieldEditorModal
          field={editingField}
          onSave={handleSaveField}
          onCancel={() => setEditingField(null)}
        />
      )}
    </div>
  );
}

// ============================================
// FieldRow Component
// ============================================

interface FieldRowProps {
  field: TemplateField;
  index: number;
  totalFields: number;
  onEdit: (field: TemplateField) => void;
  onDelete: (fieldId: string) => void;
  onMove: (fieldId: string, direction: 'up' | 'down') => void;
}

function FieldRow({ field, index, totalFields, onEdit, onDelete, onMove }: FieldRowProps) {
  return (
    <div className="template-field-row">
      <div className="field-row-content">
        <div className="field-row-order">{index + 1}</div>
        <div className="field-row-info">
          <div className="field-row-label">
            {field.label}
            {field.required && <span className="required-indicator">*</span>}
          </div>
          <div className="field-row-type">{field.type}</div>
        </div>
      </div>
      <div className="field-row-actions">
        <button
          type="button"
          onClick={() => onMove(field.id, 'up')}
          disabled={index === 0}
          className="btn btn-sm"
          title="Move up"
        >
          ↑
        </button>
        <button
          type="button"
          onClick={() => onMove(field.id, 'down')}
          disabled={index === totalFields - 1}
          className="btn btn-sm"
          title="Move down"
        >
          ↓
        </button>
        <button type="button" onClick={() => onEdit(field)} className="btn btn-sm">
          Edit
        </button>
        <button type="button" onClick={() => onDelete(field.id)} className="btn btn-sm btn-danger">
          Delete
        </button>
      </div>
    </div>
  );
}

// ============================================
// FieldEditorModal Component
// ============================================

interface FieldEditorModalProps {
  field: TemplateField;
  onSave: (field: TemplateField) => void;
  onCancel: () => void;
}

function FieldEditorModal({ field, onSave, onCancel }: FieldEditorModalProps) {
  const [editedField, setEditedField] = useState<TemplateField>({ ...field });
  const [optionInput, setOptionInput] = useState('');

  const handleAddOption = () => {
    const trimmedOption = optionInput.trim();
    if (trimmedOption && !editedField.options?.includes(trimmedOption)) {
      setEditedField({
        ...editedField,
        options: [...(editedField.options || []), trimmedOption],
      });
      setOptionInput('');
    }
  };

  const handleRemoveOption = (option: string) => {
    setEditedField({
      ...editedField,
      options: editedField.options?.filter((o) => o !== option),
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(editedField);
  };

  const requiresOptions = editedField.type === 'select';

  return (
    <div className="field-editor-overlay">
      <div className="field-editor-modal">
        <div className="field-editor-header">
          <h3>Edit Field</h3>
          <button onClick={onCancel}>&times;</button>
        </div>

        <form onSubmit={handleSubmit} className="field-editor-form">
          <div className="form-group">
            <label>Field Type *</label>
            <select
              value={editedField.type}
              onChange={(e) =>
                setEditedField({ ...editedField, type: e.target.value as TemplateFieldType })
              }
              required
            >
              {FIELD_TYPES.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Label *</label>
            <input
              type="text"
              value={editedField.label}
              onChange={(e) => setEditedField({ ...editedField, label: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label>Placeholder</label>
            <input
              type="text"
              value={editedField.placeholder || ''}
              onChange={(e) => setEditedField({ ...editedField, placeholder: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Help Text</label>
            <input
              type="text"
              value={editedField.helpText || ''}
              onChange={(e) => setEditedField({ ...editedField, helpText: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>
              <input
                type="checkbox"
                checked={editedField.required}
                onChange={(e) => setEditedField({ ...editedField, required: e.target.checked })}
              />
              Required Field
            </label>
          </div>

          {requiresOptions && (
            <div className="form-group">
              <label>Options *</label>
              <div className="option-input-container">
                <input
                  type="text"
                  value={optionInput}
                  onChange={(e) => setOptionInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddOption())}
                  placeholder="Add option and press Enter"
                />
                <button type="button" onClick={handleAddOption} className="btn btn-sm">
                  Add
                </button>
              </div>
              {editedField.options && editedField.options.length > 0 && (
                <div className="options-list">
                  {editedField.options.map((option) => (
                    <span key={option} className="option">
                      {option}
                      <button type="button" onClick={() => handleRemoveOption(option)}>
                        &times;
                      </button>
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}

          <div className="field-editor-actions">
            <button type="button" onClick={onCancel} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Save Field
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
