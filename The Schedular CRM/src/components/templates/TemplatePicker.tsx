/**
 * TemplatePicker Component
 * Modal for selecting a template with preview
 *
 * Agent CRM-30 Implementation
 */

import { useState } from 'react';
import { useTemplates } from '../../hooks/useTemplates';
import type { FormTemplate, TemplateCategory } from '../../types/templates';
import './templates.css';

interface TemplatePickerProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (template: FormTemplate) => void;
  category?: TemplateCategory;
  title?: string;
}

export function TemplatePicker({
  isOpen,
  onClose,
  onSelect,
  category,
  title = 'Select a Template',
}: TemplatePickerProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<TemplateCategory | 'all'>(
    category || 'all'
  );
  const [previewTemplate, setPreviewTemplate] = useState<FormTemplate | null>(null);

  const { templates, isLoading, error } = useTemplates({
    isActive: true,
    searchTerm: searchTerm || undefined,
    category: selectedCategory !== 'all' ? selectedCategory : undefined,
  });

  const handleSelect = (template: FormTemplate) => {
    onSelect(template);
    onClose();
  };

  const handlePreview = (template: FormTemplate) => {
    setPreviewTemplate(template);
  };

  const handleClosePreview = () => {
    setPreviewTemplate(null);
  };

  if (!isOpen) return null;

  return (
    <div className="template-picker-overlay">
      <div className="template-picker-modal">
        <div className="template-picker-header">
          <h2>{title}</h2>
          <button className="template-picker-close" onClick={onClose}>
            &times;
          </button>
        </div>

        <div className="template-picker-search">
          <input
            type="text"
            placeholder="Search templates..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="template-search-input"
          />
        </div>

        <div className="template-picker-filters">
          <button
            className={`filter-btn ${selectedCategory === 'all' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('all')}
          >
            All
          </button>
          <button
            className={`filter-btn ${selectedCategory === 'therapy' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('therapy')}
          >
            Therapy
          </button>
          <button
            className={`filter-btn ${selectedCategory === 'real_estate' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('real_estate')}
          >
            Real Estate
          </button>
          <button
            className={`filter-btn ${selectedCategory === 'accounting' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('accounting')}
          >
            Accounting
          </button>
          <button
            className={`filter-btn ${selectedCategory === 'custom' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('custom')}
          >
            Custom
          </button>
        </div>

        <div className="template-picker-content">
          {isLoading ? (
            <div className="template-picker-loading">Loading templates...</div>
          ) : error ? (
            <div className="template-picker-error">
              <p>Error loading templates: {error.message}</p>
            </div>
          ) : templates.length === 0 ? (
            <div className="template-picker-empty">
              <p>No templates found</p>
              {searchTerm && <p>Try adjusting your search</p>}
            </div>
          ) : (
            <div className="template-picker-list">
              {templates.map((template) => (
                <div key={template.id} className="template-picker-item">
                  <div className="template-picker-item-content">
                    <h3>{template.name}</h3>
                    {template.description && <p>{template.description}</p>}
                    <div className="template-picker-item-meta">
                      <span>{template.fields.length} fields</span>
                      <span>Used {template.usageCount} times</span>
                    </div>
                  </div>
                  <div className="template-picker-item-actions">
                    <button
                      className="btn btn-secondary btn-sm"
                      onClick={() => handlePreview(template)}
                    >
                      Preview
                    </button>
                    <button className="btn btn-primary btn-sm" onClick={() => handleSelect(template)}>
                      Select
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {previewTemplate && (
          <TemplatePreviewModal template={previewTemplate} onClose={handleClosePreview} />
        )}
      </div>
    </div>
  );
}

// ============================================
// TemplatePreviewModal Component
// ============================================

interface TemplatePreviewModalProps {
  template: FormTemplate;
  onClose: () => void;
}

function TemplatePreviewModal({ template, onClose }: TemplatePreviewModalProps) {
  const getFieldTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      text: 'Text',
      number: 'Number',
      date: 'Date',
      signature: 'Signature',
      checkbox: 'Checkbox',
      select: 'Select',
      textarea: 'Text Area',
      email: 'Email',
      phone: 'Phone',
    };
    return labels[type] || type;
  };

  return (
    <div className="template-preview-overlay">
      <div className="template-preview-modal">
        <div className="template-preview-header">
          <h2>Preview: {template.name}</h2>
          <button className="template-preview-close" onClick={onClose}>
            &times;
          </button>
        </div>

        <div className="template-preview-content">
          {template.description && (
            <div className="template-preview-description">
              <p>{template.description}</p>
            </div>
          )}

          <div className="template-preview-fields">
            <h3>Fields ({template.fields.length})</h3>
            <div className="template-preview-fields-list">
              {template.fields
                .sort((a, b) => a.order - b.order)
                .map((field) => (
                  <div key={field.id} className="template-preview-field">
                    <div className="template-preview-field-header">
                      <span className="template-preview-field-label">
                        {field.label}
                        {field.required && <span className="required-indicator">*</span>}
                      </span>
                      <span className="template-preview-field-type">
                        {getFieldTypeLabel(field.type)}
                      </span>
                    </div>
                    {field.helpText && (
                      <p className="template-preview-field-help">{field.helpText}</p>
                    )}
                    {field.options && field.options.length > 0 && (
                      <div className="template-preview-field-options">
                        <strong>Options:</strong> {field.options.join(', ')}
                      </div>
                    )}
                  </div>
                ))}
            </div>
          </div>
        </div>

        <div className="template-preview-footer">
          <button className="btn btn-secondary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
