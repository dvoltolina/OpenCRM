/**
 * CustomFieldEditor Component
 * Form for creating and editing custom field definitions
 *
 * Agent CRM-39 Implementation
 * Dependencies: custom-fields types, FormField components
 */

import { useState, useEffect } from 'react';
import {
  FormField,
  FormInput,
  FormActions,
  FormButton,
  FormSection,
} from './FormField';
import { FormSelect } from './FormSelect';
import { CustomFieldPreview } from './CustomFieldRenderer';
import { getCustomFieldsService } from '../../services/custom-fields-service';
import type {
  CustomFieldDefinition,
  CustomFieldType,
  CustomFieldEntityType,
  CustomFieldInput,
} from '../../types/custom-fields';
import { fieldTypeSupportsOptions } from '../../types/custom-fields';
import './forms.css';

// ============================================
// Types
// ============================================

export interface CustomFieldEditorProps {
  /** Existing field to edit (undefined for new field) */
  field?: CustomFieldDefinition;

  /** Business ID */
  businessId: string;

  /** Entity type this field is for */
  entityType: CustomFieldEntityType;

  /** Callback when save is clicked */
  onSave: (data: CustomFieldInput) => Promise<void>;

  /** Callback when cancel is clicked */
  onCancel: () => void;

  /** Whether the form is in a saving state */
  isSaving?: boolean;
}

interface FormData {
  name: string;
  label: string;
  fieldType: CustomFieldType;
  required: boolean;
  options: string[];
  defaultValue: any;
  isActive: boolean;
}

// ============================================
// Component
// ============================================

/**
 * CustomFieldEditor - Form for creating/editing custom field definitions
 *
 * @example
 * ```tsx
 * <CustomFieldEditor
 *   businessId="biz-123"
 *   entityType="lead"
 *   onSave={handleSave}
 *   onCancel={handleCancel}
 * />
 * ```
 */
export function CustomFieldEditor({
  field,
  businessId,
  entityType,
  onSave,
  onCancel,
  isSaving = false,
}: CustomFieldEditorProps) {
  const [formData, setFormData] = useState<FormData>({
    name: field?.name || '',
    label: field?.label || '',
    fieldType: field?.fieldType || 'text',
    required: field?.required || false,
    options: field?.options || [],
    defaultValue: field?.defaultValue,
    isActive: field?.isActive ?? true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [newOption, setNewOption] = useState('');

  const isEditMode = Boolean(field);

  // Update form when field changes
  useEffect(() => {
    if (field) {
      setFormData({
        name: field.name,
        label: field.label,
        fieldType: field.fieldType,
        required: field.required,
        options: field.options || [],
        defaultValue: field.defaultValue,
        isActive: field.isActive,
      });
    }
  }, [field]);

  // Handle field change
  const handleChange = (key: keyof FormData, value: any) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
    // Clear error for this field
    setErrors((prev) => {
      const newErrors = { ...prev };
      delete newErrors[key];
      return newErrors;
    });
  };

  // Handle field type change
  const handleFieldTypeChange = (newType: CustomFieldType) => {
    handleChange('fieldType', newType);

    // Reset options if switching away from select/multiselect
    if (!fieldTypeSupportsOptions(newType)) {
      handleChange('options', []);
    }

    // Reset default value when type changes
    handleChange('defaultValue', undefined);
  };

  // Add option for select/multiselect
  const handleAddOption = () => {
    const trimmed = newOption.trim();
    if (!trimmed) return;

    if (formData.options.includes(trimmed)) {
      setErrors((prev) => ({ ...prev, options: 'Option already exists' }));
      return;
    }

    handleChange('options', [...formData.options, trimmed]);
    setNewOption('');
  };

  // Remove option
  const handleRemoveOption = (option: string) => {
    handleChange(
      'options',
      formData.options.filter((o) => o !== option)
    );
  };

  // Generate field name from label
  const handleLabelBlur = () => {
    // Only auto-generate name if in create mode and name is empty
    if (!isEditMode && !formData.name && formData.label) {
      const generatedName = formData.label
        .trim()
        .replace(/[^a-zA-Z0-9\s]/g, '') // Remove special chars
        .split(/\s+/) // Split on whitespace
        .map((word, i) =>
          i === 0
            ? word.toLowerCase()
            : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
        )
        .join('');

      if (generatedName) {
        handleChange('name', generatedName);
      }
    }
  };

  // Validate form
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    const service = getCustomFieldsService();

    // Build field definition for validation
    const fieldDef: Partial<CustomFieldDefinition> = {
      name: formData.name,
      label: formData.label,
      fieldType: formData.fieldType,
      required: formData.required,
      options: formData.options,
    };

    const error = service.validateDefinition(fieldDef);
    if (error) {
      // Try to determine which field has the error
      if (error.includes('name')) {
        newErrors.name = error;
      } else if (error.includes('label')) {
        newErrors.label = error;
      } else if (error.includes('type')) {
        newErrors.fieldType = error;
      } else if (error.includes('option')) {
        newErrors.options = error;
      } else {
        newErrors.general = error;
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Handle submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    const data: CustomFieldInput = {
      businessId,
      entityType,
      name: formData.name,
      label: formData.label,
      fieldType: formData.fieldType,
      required: formData.required,
      options: fieldTypeSupportsOptions(formData.fieldType) ? formData.options : undefined,
      defaultValue: formData.defaultValue,
      order: field?.order ?? 0, // Will be set by the hook if new
      isActive: formData.isActive,
    };

    try {
      await onSave(data);
    } catch (error) {
      setErrors({
        general: error instanceof Error ? error.message : 'Failed to save field',
      });
    }
  };

  // Build preview field
  const previewField: CustomFieldDefinition = {
    id: 'preview',
    businessId,
    entityType,
    name: formData.name || 'fieldName',
    label: formData.label || 'Field Label',
    fieldType: formData.fieldType,
    required: formData.required,
    options: formData.options,
    defaultValue: formData.defaultValue,
    order: 0,
    isActive: formData.isActive,
    createdAt: new Date(),
  };

  return (
    <form className="custom-field-editor" onSubmit={handleSubmit}>
      {errors.general && (
        <div className="custom-field-editor__error" role="alert">
          {errors.general}
        </div>
      )}

      <FormSection title="Basic Information">
        <FormField label="Field Label" name="label" required error={errors.label}>
          <FormInput
            type="text"
            value={formData.label}
            onChange={(e) => handleChange('label', e.target.value)}
            onBlur={handleLabelBlur}
            disabled={isSaving}
            hasError={Boolean(errors.label)}
            placeholder="e.g., Industry Type"
          />
        </FormField>

        <FormField
          label="Field Name"
          name="name"
          required
          error={errors.name}
          helpText="Internal name used in code (camelCase, no spaces)"
        >
          <FormInput
            type="text"
            value={formData.name}
            onChange={(e) => handleChange('name', e.target.value)}
            disabled={isSaving || isEditMode}
            hasError={Boolean(errors.name)}
            placeholder="e.g., industryType"
          />
        </FormField>

        <FormField label="Field Type" name="fieldType" required error={errors.fieldType}>
          <FormSelect
            value={formData.fieldType}
            onChange={(value) => handleFieldTypeChange(value as CustomFieldType)}
            disabled={isSaving}
            hasError={Boolean(errors.fieldType)}
            options={[
              { value: 'text', label: 'Text' },
              { value: 'number', label: 'Number' },
              { value: 'date', label: 'Date' },
              { value: 'select', label: 'Select (Dropdown)' },
              { value: 'multiselect', label: 'Multi-Select' },
              { value: 'checkbox', label: 'Checkbox' },
              { value: 'url', label: 'URL' },
              { value: 'email', label: 'Email' },
              { value: 'phone', label: 'Phone' },
            ]}
          />
        </FormField>

        <FormField label="Required" name="required">
          <label className="custom-field-editor__checkbox">
            <input
              type="checkbox"
              checked={formData.required}
              onChange={(e) => handleChange('required', e.target.checked)}
              disabled={isSaving}
            />
            <span>Make this field required</span>
          </label>
        </FormField>
      </FormSection>

      {fieldTypeSupportsOptions(formData.fieldType) && (
        <FormSection
          title="Options"
          description="Define the available options for this field"
        >
          <div className="custom-field-editor__options">
            <div className="custom-field-editor__options-list">
              {formData.options.map((option, index) => (
                <div key={index} className="custom-field-editor__option-item">
                  <span>{option}</span>
                  <button
                    type="button"
                    onClick={() => handleRemoveOption(option)}
                    disabled={isSaving}
                    className="custom-field-editor__option-remove"
                    aria-label={`Remove ${option}`}
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>

            <div className="custom-field-editor__add-option">
              <FormInput
                type="text"
                value={newOption}
                onChange={(e) => setNewOption(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleAddOption();
                  }
                }}
                disabled={isSaving}
                placeholder="Add option"
              />
              <button
                type="button"
                onClick={handleAddOption}
                disabled={isSaving || !newOption.trim()}
                className="custom-field-editor__add-option-btn"
              >
                Add
              </button>
            </div>

            {errors.options && (
              <p className="form-field__error" role="alert">
                {errors.options}
              </p>
            )}
          </div>
        </FormSection>
      )}

      <FormSection title="Preview">
        <CustomFieldPreview field={previewField} />
      </FormSection>

      <FormActions>
        <FormButton type="button" variant="secondary" onClick={onCancel} disabled={isSaving}>
          Cancel
        </FormButton>
        <FormButton type="submit" variant="primary" isLoading={isSaving}>
          {isEditMode ? 'Update Field' : 'Create Field'}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default CustomFieldEditor;
