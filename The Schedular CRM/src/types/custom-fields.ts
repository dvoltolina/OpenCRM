/**
 * Custom Fields Type Definitions
 * Type definitions for the custom fields system
 *
 * Agent CRM-39 Implementation
 * Dependencies: CRM-20 (Settings - placeholder replaced)
 */

import type { BaseEntity } from '../data/repositories/repository-types';

// ============================================
// Field Types
// ============================================

/**
 * Supported custom field types
 */
export type CustomFieldType =
  | 'text'
  | 'number'
  | 'date'
  | 'select'
  | 'multiselect'
  | 'checkbox'
  | 'url'
  | 'email'
  | 'phone';

/**
 * Entity types that can have custom fields
 */
export type CustomFieldEntityType = 'lead' | 'deal' | 'contact' | 'company';

// ============================================
// Custom Field Definition
// ============================================

/**
 * Definition of a custom field
 * Stored at: businesses/{businessId}/crm_custom_fields/{fieldId}
 */
export interface CustomFieldDefinition extends BaseEntity {
  /** Unique identifier */
  id: string;

  /** Business this field belongs to */
  businessId: string;

  /** Entity type this field applies to */
  entityType: CustomFieldEntityType;

  /** Field name (used as key in customFields object) */
  name: string;

  /** Display label for the field */
  label: string;

  /** Type of the field */
  fieldType: CustomFieldType;

  /** Whether this field is required */
  required: boolean;

  /** Options for select/multiselect fields */
  options?: string[];

  /** Default value for the field */
  defaultValue?: any;

  /** Display order */
  order: number;

  /** Whether this field is active */
  isActive: boolean;

  /** When the field was created */
  createdAt: Date;

  /** When the field was last updated */
  updatedAt?: Date;

  /** Soft delete support */
  isDeleted?: boolean;
  deletedAt?: Date;
}

// ============================================
// Custom Field Value
// ============================================

/**
 * A custom field value for an entity
 * Stored within the entity's customFields property as a key-value pair
 */
export interface CustomFieldValue {
  /** ID of the field definition */
  fieldId: string;

  /** The actual value (type depends on field type) */
  value: any;
}

// ============================================
// Validation Types
// ============================================

/**
 * Validation error for a custom field
 */
export interface CustomFieldValidationError {
  /** Field ID that has the error */
  fieldId: string;

  /** Field name */
  fieldName: string;

  /** Error message */
  message: string;
}

/**
 * Result of validating custom field values
 */
export interface CustomFieldValidationResult {
  /** Whether validation passed */
  isValid: boolean;

  /** List of validation errors */
  errors: CustomFieldValidationError[];
}

// ============================================
// Custom Field Input Types
// ============================================

/**
 * Input data for creating a custom field
 */
export type CustomFieldInput = Omit<
  CustomFieldDefinition,
  'id' | 'createdAt' | 'updatedAt' | 'isDeleted' | 'deletedAt'
>;

/**
 * Input data for updating a custom field
 */
export type CustomFieldUpdateInput = Partial<
  Omit<CustomFieldDefinition, 'id' | 'businessId' | 'createdAt'>
>;

// ============================================
// Custom Field Rendering Config
// ============================================

/**
 * Configuration for rendering a custom field
 */
export interface CustomFieldRenderConfig {
  /** The field definition */
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

// ============================================
// Utility Types
// ============================================

/**
 * Map of field values keyed by field name
 * This is the format stored in entity.customFields
 */
export type CustomFieldValues = Record<string, any>;

/**
 * Grouped custom fields by entity type
 */
export interface CustomFieldsByEntity {
  lead: CustomFieldDefinition[];
  deal: CustomFieldDefinition[];
  contact: CustomFieldDefinition[];
  company: CustomFieldDefinition[];
}

// ============================================
// Type Guards
// ============================================

/**
 * Check if a field type supports options
 */
export function fieldTypeSupportsOptions(fieldType: CustomFieldType): boolean {
  return fieldType === 'select' || fieldType === 'multiselect';
}

/**
 * Check if a field value is empty
 */
export function isFieldValueEmpty(value: any): boolean {
  if (value === null || value === undefined) return true;
  if (typeof value === 'string') return value.trim() === '';
  if (Array.isArray(value)) return value.length === 0;
  return false;
}

/**
 * Validate that a custom field definition is complete
 */
export function isValidFieldDefinition(
  field: Partial<CustomFieldDefinition>
): field is CustomFieldDefinition {
  return (
    Boolean(field.id) &&
    Boolean(field.businessId) &&
    Boolean(field.entityType) &&
    Boolean(field.name) &&
    Boolean(field.label) &&
    Boolean(field.fieldType) &&
    typeof field.required === 'boolean' &&
    typeof field.order === 'number' &&
    typeof field.isActive === 'boolean'
  );
}

// ============================================
// Note: All types are already exported inline above
// ============================================
