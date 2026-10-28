/**
 * Custom Fields Service
 * Business logic for custom field validation and value processing
 *
 * Agent CRM-39 Implementation
 * Dependencies: custom-fields types
 */

import type {
  CustomFieldDefinition,
  CustomFieldValues,
  CustomFieldValidationError,
  CustomFieldValidationResult,
} from '../types/custom-fields';
import { isFieldValueEmpty, fieldTypeSupportsOptions } from '../types/custom-fields';

// ============================================
// Validation Functions
// ============================================

/**
 * Validate a single custom field value
 */
export function validateFieldValue(
  field: CustomFieldDefinition,
  value: any
): string | null {
  // Check required fields
  if (field.required && isFieldValueEmpty(value)) {
    return `${field.label} is required`;
  }

  // If empty and not required, skip further validation
  if (isFieldValueEmpty(value)) {
    return null;
  }

  // Type-specific validation
  switch (field.fieldType) {
    case 'text':
      return validateTextField(field, value);

    case 'number':
      return validateNumberField(field, value);

    case 'date':
      return validateDateField(field, value);

    case 'select':
      return validateSelectField(field, value);

    case 'multiselect':
      return validateMultiSelectField(field, value);

    case 'checkbox':
      return validateCheckboxField(field, value);

    case 'url':
      return validateUrlField(field, value);

    case 'email':
      return validateEmailField(field, value);

    case 'phone':
      return validatePhoneField(field, value);

    default:
      return null;
  }
}

/**
 * Validate text field
 */
function validateTextField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'string') {
    return `${field.label} must be text`;
  }

  if (value.length > 1000) {
    return `${field.label} must be less than 1000 characters`;
  }

  return null;
}

/**
 * Validate number field
 */
function validateNumberField(field: CustomFieldDefinition, value: any): string | null {
  const num = Number(value);
  if (isNaN(num)) {
    return `${field.label} must be a valid number`;
  }

  return null;
}

/**
 * Validate date field
 */
function validateDateField(field: CustomFieldDefinition, value: any): string | null {
  // Accept Date objects or ISO strings
  const date = value instanceof Date ? value : new Date(value);

  if (isNaN(date.getTime())) {
    return `${field.label} must be a valid date`;
  }

  return null;
}

/**
 * Validate select field
 */
function validateSelectField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'string') {
    return `${field.label} must be a text value`;
  }

  if (field.options && !field.options.includes(value)) {
    return `${field.label} must be one of the available options`;
  }

  return null;
}

/**
 * Validate multiselect field
 */
function validateMultiSelectField(
  field: CustomFieldDefinition,
  value: any
): string | null {
  if (!Array.isArray(value)) {
    return `${field.label} must be a list of values`;
  }

  if (field.options) {
    const invalidValues = value.filter((v) => !field.options?.includes(v));
    if (invalidValues.length > 0) {
      return `${field.label} contains invalid options: ${invalidValues.join(', ')}`;
    }
  }

  return null;
}

/**
 * Validate checkbox field
 */
function validateCheckboxField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'boolean') {
    return `${field.label} must be true or false`;
  }

  return null;
}

/**
 * Validate URL field
 */
function validateUrlField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'string') {
    return `${field.label} must be text`;
  }

  try {
    new URL(value);
    return null;
  } catch {
    return `${field.label} must be a valid URL`;
  }
}

/**
 * Validate email field
 */
function validateEmailField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'string') {
    return `${field.label} must be text`;
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(value)) {
    return `${field.label} must be a valid email address`;
  }

  return null;
}

/**
 * Validate phone field
 */
function validatePhoneField(field: CustomFieldDefinition, value: any): string | null {
  if (typeof value !== 'string') {
    return `${field.label} must be text`;
  }

  // Basic phone validation (allows various formats)
  const phoneRegex = /^[\d\s\-\+\(\)\.]+$/;
  if (!phoneRegex.test(value)) {
    return `${field.label} must be a valid phone number`;
  }

  // Ensure it has enough digits
  const digitsOnly = value.replace(/\D/g, '');
  if (digitsOnly.length < 7) {
    return `${field.label} must contain at least 7 digits`;
  }

  return null;
}

/**
 * Validate all custom field values for an entity
 */
export function validateCustomFields(
  fields: CustomFieldDefinition[],
  values: CustomFieldValues
): CustomFieldValidationResult {
  const errors: CustomFieldValidationError[] = [];

  for (const field of fields) {
    const value = values[field.name];
    const error = validateFieldValue(field, value);

    if (error) {
      errors.push({
        fieldId: field.id,
        fieldName: field.name,
        message: error,
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Value Processing
// ============================================

/**
 * Get the default value for a field
 */
export function getDefaultFieldValue(field: CustomFieldDefinition): any {
  if (field.defaultValue !== undefined && field.defaultValue !== null) {
    return field.defaultValue;
  }

  // Type-specific defaults
  switch (field.fieldType) {
    case 'text':
    case 'url':
    case 'email':
    case 'phone':
      return '';

    case 'number':
      return null;

    case 'date':
      return null;

    case 'select':
      return field.options?.[0] || '';

    case 'multiselect':
      return [];

    case 'checkbox':
      return false;

    default:
      return null;
  }
}

/**
 * Initialize custom field values with defaults
 */
export function initializeCustomFieldValues(
  fields: CustomFieldDefinition[]
): CustomFieldValues {
  const values: CustomFieldValues = {};

  for (const field of fields) {
    values[field.name] = getDefaultFieldValue(field);
  }

  return values;
}

/**
 * Sanitize a value for storage
 */
export function sanitizeFieldValue(
  field: CustomFieldDefinition,
  value: any
): any {
  if (isFieldValueEmpty(value)) {
    return null;
  }

  switch (field.fieldType) {
    case 'text':
    case 'url':
    case 'email':
    case 'phone':
      return String(value).trim();

    case 'number':
      return Number(value);

    case 'date':
      // Store as ISO string
      return value instanceof Date ? value.toISOString() : new Date(value).toISOString();

    case 'select':
      return String(value);

    case 'multiselect':
      return Array.isArray(value) ? value : [value];

    case 'checkbox':
      return Boolean(value);

    default:
      return value;
  }
}

/**
 * Sanitize all custom field values for storage
 */
export function sanitizeCustomFieldValues(
  fields: CustomFieldDefinition[],
  values: CustomFieldValues
): CustomFieldValues {
  const sanitized: CustomFieldValues = {};

  for (const field of fields) {
    const value = values[field.name];
    if (value !== undefined) {
      sanitized[field.name] = sanitizeFieldValue(field, value);
    }
  }

  return sanitized;
}

// ============================================
// Field Definition Validation
// ============================================

/**
 * Validate a custom field definition
 */
export function validateFieldDefinition(
  field: Partial<CustomFieldDefinition>
): string | null {
  // Validate name
  if (!field.name || typeof field.name !== 'string') {
    return 'Field name is required';
  }

  // Name must be camelCase alphanumeric
  if (!/^[a-z][a-zA-Z0-9]*$/.test(field.name)) {
    return 'Field name must be camelCase (start with lowercase letter, no spaces or special characters)';
  }

  // Validate label
  if (!field.label || typeof field.label !== 'string') {
    return 'Field label is required';
  }

  // Validate field type
  if (!field.fieldType) {
    return 'Field type is required';
  }

  // Validate options for select/multiselect
  if (fieldTypeSupportsOptions(field.fieldType)) {
    if (!field.options || !Array.isArray(field.options)) {
      return `${field.fieldType} fields must have options`;
    }

    if (field.options.length === 0) {
      return `${field.fieldType} fields must have at least one option`;
    }

    // Check for duplicates
    const uniqueOptions = new Set(field.options);
    if (uniqueOptions.size !== field.options.length) {
      return 'Options must be unique';
    }
  }

  return null;
}

// ============================================
// Export Service Class
// ============================================

/**
 * Custom Fields Service
 * Provides validation and processing for custom fields
 */
export class CustomFieldsService {
  /**
   * Validate a field value
   */
  validateValue(field: CustomFieldDefinition, value: any): string | null {
    return validateFieldValue(field, value);
  }

  /**
   * Validate all field values
   */
  validateValues(
    fields: CustomFieldDefinition[],
    values: CustomFieldValues
  ): CustomFieldValidationResult {
    return validateCustomFields(fields, values);
  }

  /**
   * Validate a field definition
   */
  validateDefinition(field: Partial<CustomFieldDefinition>): string | null {
    return validateFieldDefinition(field);
  }

  /**
   * Get default value for a field
   */
  getDefaultValue(field: CustomFieldDefinition): any {
    return getDefaultFieldValue(field);
  }

  /**
   * Initialize values with defaults
   */
  initializeValues(fields: CustomFieldDefinition[]): CustomFieldValues {
    return initializeCustomFieldValues(fields);
  }

  /**
   * Sanitize values for storage
   */
  sanitizeValues(
    fields: CustomFieldDefinition[],
    values: CustomFieldValues
  ): CustomFieldValues {
    return sanitizeCustomFieldValues(fields, values);
  }
}

// ============================================
// Singleton Export
// ============================================

let customFieldsServiceInstance: CustomFieldsService | null = null;

/**
 * Get the singleton instance of the custom fields service
 */
export function getCustomFieldsService(): CustomFieldsService {
  if (!customFieldsServiceInstance) {
    customFieldsServiceInstance = new CustomFieldsService();
  }
  return customFieldsServiceInstance;
}
