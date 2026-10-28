/**
 * CustomFieldRenderer Component
 * Renders custom fields in entity forms based on field type
 *
 * Agent CRM-39 Implementation
 * Dependencies: custom-fields types, FormField components
 */

import {
  FormField,
  FormInput,
} from './FormField';
import { FormSelect } from './FormSelect';
import { FormDatePicker } from './FormDatePicker';
import type {
  CustomFieldDefinition,
  CustomFieldValues,
} from '../../types/custom-fields';
import './forms.css';

// ============================================
// Types
// ============================================

export interface CustomFieldRendererProps {
  /** The custom field definition */
  field: CustomFieldDefinition;

  /** Current value */
  value: any;

  /** Callback when value changes */
  onChange: (value: any) => void;

  /** Whether the field is disabled */
  disabled?: boolean;

  /** Validation error for this field */
  error?: string;
}

export interface CustomFieldsRendererProps {
  /** Array of custom field definitions */
  fields: CustomFieldDefinition[];

  /** Current values for all fields */
  values: CustomFieldValues;

  /** Callback when any value changes */
  onChange: (name: string, value: any) => void;

  /** Whether all fields are disabled */
  disabled?: boolean;

  /** Validation errors keyed by field name */
  errors?: Record<string, string>;
}

// ============================================
// Single Field Renderer
// ============================================

/**
 * CustomFieldRenderer - Renders a single custom field
 *
 * @example
 * ```tsx
 * <CustomFieldRenderer
 *   field={fieldDefinition}
 *   value={value}
 *   onChange={handleChange}
 *   error={error}
 * />
 * ```
 */
export function CustomFieldRenderer({
  field,
  value,
  onChange,
  disabled = false,
  error,
}: CustomFieldRendererProps) {
  const renderFieldInput = () => {
    switch (field.fieldType) {
      case 'text':
        return (
          <FormInput
            type="text"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder={`Enter ${field.label.toLowerCase()}`}
          />
        );

      case 'number':
        return (
          <FormInput
            type="number"
            value={value ?? ''}
            onChange={(e) => onChange(e.target.value ? Number(e.target.value) : null)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder={`Enter ${field.label.toLowerCase()}`}
          />
        );

      case 'date':
        return (
          <FormDatePicker
            value={value ? new Date(value) : null}
            onChange={(date) => onChange(date?.toISOString() || null)}
            disabled={disabled}
            hasError={Boolean(error)}
          />
        );

      case 'select':
        return (
          <FormSelect
            value={value || ''}
            onChange={(value) => onChange(value)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder={`Select ${field.label}`}
            options={
              field.options?.map((option) => ({
                value: option,
                label: option,
              })) || []
            }
          />
        );

      case 'multiselect':
        return (
          <div className="custom-field__multiselect">
            {field.options?.map((option) => (
              <label key={option} className="custom-field__checkbox-label">
                <input
                  type="checkbox"
                  checked={Array.isArray(value) && value.includes(option)}
                  onChange={(e) => {
                    const currentValues = Array.isArray(value) ? value : [];
                    if (e.target.checked) {
                      onChange([...currentValues, option]);
                    } else {
                      onChange(currentValues.filter((v) => v !== option));
                    }
                  }}
                  disabled={disabled}
                />
                <span>{option}</span>
              </label>
            ))}
          </div>
        );

      case 'checkbox':
        return (
          <label className="custom-field__checkbox-single">
            <input
              type="checkbox"
              checked={Boolean(value)}
              onChange={(e) => onChange(e.target.checked)}
              disabled={disabled}
            />
            <span>{field.label}</span>
          </label>
        );

      case 'url':
        return (
          <FormInput
            type="url"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder="https://example.com"
          />
        );

      case 'email':
        return (
          <FormInput
            type="email"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder="email@example.com"
          />
        );

      case 'phone':
        return (
          <FormInput
            type="tel"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
            hasError={Boolean(error)}
            placeholder="+1 (555) 123-4567"
          />
        );

      default:
        return (
          <FormInput
            type="text"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
            hasError={Boolean(error)}
          />
        );
    }
  };

  // Special rendering for checkbox (no wrapper)
  if (field.fieldType === 'checkbox') {
    return (
      <div className="form-field">
        {renderFieldInput()}
        {error && (
          <p className="form-field__error" role="alert" aria-live="polite">
            {error}
          </p>
        )}
      </div>
    );
  }

  return (
    <FormField
      label={field.label}
      name={field.name}
      required={field.required}
      error={error}
    >
      {renderFieldInput()}
    </FormField>
  );
}

// ============================================
// Multiple Fields Renderer
// ============================================

/**
 * CustomFieldsRenderer - Renders multiple custom fields
 *
 * @example
 * ```tsx
 * <CustomFieldsRenderer
 *   fields={customFields}
 *   values={values}
 *   onChange={handleFieldChange}
 *   errors={validationErrors}
 * />
 * ```
 */
export function CustomFieldsRenderer({
  fields,
  values,
  onChange,
  disabled = false,
  errors = {},
}: CustomFieldsRendererProps) {
  if (fields.length === 0) {
    return null;
  }

  return (
    <div className="custom-fields-renderer">
      <h4 className="custom-fields-renderer__title">Custom Fields</h4>
      <div className="custom-fields-renderer__fields">
        {fields.map((field) => (
          <CustomFieldRenderer
            key={field.id}
            field={field}
            value={values[field.name]}
            onChange={(value) => onChange(field.name, value)}
            disabled={disabled}
            error={errors[field.name]}
          />
        ))}
      </div>
    </div>
  );
}

// ============================================
// Utility Components
// ============================================

/**
 * Preview of how a custom field will appear
 */
export interface CustomFieldPreviewProps {
  /** The field definition to preview */
  field: CustomFieldDefinition;
}

export function CustomFieldPreview({ field }: CustomFieldPreviewProps) {
  return (
    <div className="custom-field-preview">
      <div className="custom-field-preview__label">Preview:</div>
      <CustomFieldRenderer
        field={field}
        value={field.defaultValue}
        onChange={() => {}}
        disabled={true}
      />
    </div>
  );
}

export default CustomFieldRenderer;
