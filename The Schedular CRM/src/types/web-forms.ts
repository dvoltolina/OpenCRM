/**
 * Web Forms Types
 * Types for embeddable lead capture forms
 *
 * Agent Web Forms Implementation
 * Path: businesses/{businessId}/web_forms/{formId}
 *
 * HIPAA Compliance:
 * - Form submissions create leads protected by existing RBAC
 * - Public endpoints must NOT log PHI
 * - Audit logs use formId/leadId only, no field values
 */

import type { ShareableFields } from './models';

// ============================================
// Field Mapping Types
// ============================================

/**
 * Maps form fields to lead fields
 * Supports standard lead fields and custom fields (prefixed with customField_)
 */
export type LeadFieldMapping =
  | 'firstName'
  | 'lastName'
  | 'email'
  | 'phone'
  | 'companyName'
  | 'title'
  | 'source'
  | 'notes'
  | `customField_${string}`;

// ============================================
// Form Field Types
// ============================================

/**
 * Supported form field input types
 */
export type WebFormFieldType =
  | 'text'
  | 'email'
  | 'phone'
  | 'textarea'
  | 'select'
  | 'checkbox'
  | 'hidden';

/**
 * Validation rules for form fields
 */
export interface WebFormFieldValidation {
  /** Minimum text length */
  minLength?: number;
  /** Maximum text length */
  maxLength?: number;
  /** Regex pattern for validation */
  pattern?: string;
}

/**
 * Individual form field configuration
 */
export interface WebFormField {
  /** Unique field identifier */
  id: string;
  /** Input type */
  type: WebFormFieldType;
  /** Display label for the field */
  label: string;
  /** Placeholder text */
  placeholder?: string;
  /** Whether field is required */
  required: boolean;
  /** Which lead field this maps to */
  mapToField: LeadFieldMapping;
  /** Options for select fields */
  options?: string[];
  /** Default value (useful for hidden fields) */
  defaultValue?: string;
  /** Validation rules */
  validation?: WebFormFieldValidation;
}

// ============================================
// Form Settings Types
// ============================================

/**
 * Submission handling settings
 */
export interface WebFormSettings {
  /** Text displayed on submit button */
  submitButtonText: string;
  /** Message shown after successful submission */
  successMessage: string;
  /** URL to redirect to after submission (optional) */
  redirectUrl?: string;
  /** Email addresses to notify on new submission */
  notifyEmails?: string[];
  /** User ID to auto-assign leads to */
  assignToUserId?: string;
  /** User name for auto-assignment display */
  assignToUserName?: string;
  /** Default lead source value */
  defaultLeadSource?: string;
  /** Tags to apply to created leads */
  defaultTags?: string[];
  /** Sequence ID for auto-enrollment */
  sequenceId?: string;
}

/**
 * Spam protection configuration
 */
export interface WebFormSpamProtection {
  /** Enable honeypot field (invisible field to catch bots) */
  honeypot: boolean;
  /** Maximum submissions per IP per hour */
  rateLimit: number;
  /** Enable Google reCAPTCHA */
  recaptchaEnabled: boolean;
}

/**
 * Visual styling for embedded forms
 */
export interface WebFormStyling {
  /** Color theme */
  theme: 'light' | 'dark' | 'auto';
  /** Primary/accent color (hex) */
  primaryColor?: string;
  /** Font family name */
  fontFamily?: string;
}

/**
 * Form submission statistics
 */
export interface WebFormStats {
  /** Total submissions all time */
  totalSubmissions: number;
  /** Submissions in current calendar month */
  submissionsThisMonth: number;
}

// ============================================
// Main Web Form Type
// ============================================

/**
 * Form status
 */
export type WebFormStatus = 'active' | 'inactive';

/**
 * Web Form entity
 * Path: businesses/{businessId}/web_forms/{formId}
 */
export interface WebForm extends ShareableFields {
  id: string;

  /** Form name (internal reference) */
  name: string;
  /** Optional description */
  description?: string;
  /** Whether form accepts submissions */
  status: WebFormStatus;

  /** Configured form fields */
  fields: WebFormField[];

  /** Submission handling settings */
  settings: WebFormSettings;

  /** Spam protection configuration */
  spamProtection: WebFormSpamProtection;

  /** Visual styling for embed */
  styling: WebFormStyling;

  /** Submission statistics */
  stats: WebFormStats;

  /** Ownership - required from ShareableFields */
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  visibility: 'private' | 'team' | 'org';

  /** Timestamps */
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Form Submission Types
// ============================================

/**
 * Metadata captured during form submission
 * Note: IP address is used for rate limiting only, NOT stored with lead
 */
export interface WebFormSubmissionMetadata {
  /** Referrer URL */
  referrerUrl?: string;
  /** UTM source parameter */
  utmSource?: string;
  /** UTM medium parameter */
  utmMedium?: string;
  /** UTM campaign parameter */
  utmCampaign?: string;
  /** UTM term parameter */
  utmTerm?: string;
  /** UTM content parameter */
  utmContent?: string;
  /** Submission timestamp */
  submittedAt: Date;
  /** User agent string */
  userAgent?: string;
}

/**
 * Form submission data from public endpoint
 */
export interface WebFormSubmissionData {
  /** Form ID being submitted to */
  formId: string;
  /** Field values keyed by field ID */
  fieldValues: Record<string, string | boolean>;
  /** Honeypot field value (should be empty if human) */
  honeypotValue?: string;
  /** reCAPTCHA token for verification */
  recaptchaToken?: string;
  /** Submission metadata */
  metadata: WebFormSubmissionMetadata;
}

/**
 * Result of form submission processing
 */
export interface WebFormSubmissionResult {
  /** Whether submission was successful */
  success: boolean;
  /** Created lead ID (if successful) */
  leadId?: string;
  /** Error message (if failed) */
  error?: string;
  /** Error code for programmatic handling */
  errorCode?: WebFormSubmissionErrorCode;
  /** Duplicate detection warnings */
  duplicateWarnings?: WebFormDuplicateWarning[];
}

/**
 * Error codes for submission failures
 */
export type WebFormSubmissionErrorCode =
  | 'FORM_NOT_FOUND'
  | 'FORM_INACTIVE'
  | 'VALIDATION_ERROR'
  | 'RATE_LIMITED'
  | 'SPAM_DETECTED'
  | 'RECAPTCHA_FAILED'
  | 'INTERNAL_ERROR';

/**
 * Duplicate detection warning (non-blocking)
 */
export interface WebFormDuplicateWarning {
  /** Type of duplicate match */
  matchType: 'email' | 'phone';
  /** Existing lead ID */
  existingLeadId: string;
}

// ============================================
// Public Form Config (Sanitized for Embed)
// ============================================

/**
 * Sanitized form config for public embed endpoint
 * Excludes internal IDs, owner info, and sensitive settings
 */
export interface PublicWebFormConfig {
  /** Form ID */
  id: string;
  /** Form name */
  name: string;
  /** Form fields */
  fields: PublicWebFormField[];
  /** Submit button text */
  submitButtonText: string;
  /** Success message */
  successMessage: string;
  /** Redirect URL (if configured) */
  redirectUrl?: string;
  /** Whether honeypot is enabled (for client-side implementation) */
  honeypotEnabled: boolean;
  /** Whether reCAPTCHA is enabled */
  recaptchaEnabled: boolean;
  /** Visual styling */
  styling: WebFormStyling;
}

/**
 * Sanitized field config for public endpoint
 */
export interface PublicWebFormField {
  /** Field ID */
  id: string;
  /** Input type */
  type: WebFormFieldType;
  /** Display label */
  label: string;
  /** Placeholder text */
  placeholder?: string;
  /** Whether field is required */
  required: boolean;
  /** Options for select fields */
  options?: string[];
  /** Validation rules */
  validation?: WebFormFieldValidation;
}

// ============================================
// Validation Types
// ============================================

/**
 * Field validation error
 */
export interface WebFormFieldError {
  /** Field ID that failed validation */
  fieldId: string;
  /** Error message */
  message: string;
  /** Error code */
  code: 'REQUIRED' | 'INVALID_FORMAT' | 'TOO_SHORT' | 'TOO_LONG' | 'PATTERN_MISMATCH';
}

/**
 * Form validation result
 */
export interface WebFormValidationResult {
  /** Whether all validations passed */
  isValid: boolean;
  /** List of validation errors */
  errors: WebFormFieldError[];
}

// ============================================
// Default Values
// ============================================

/**
 * Default spam protection settings
 */
export const DEFAULT_SPAM_PROTECTION: WebFormSpamProtection = {
  honeypot: true,
  rateLimit: 10, // 10 submissions per IP per hour
  recaptchaEnabled: false,
};

/**
 * Default form styling
 */
export const DEFAULT_STYLING: WebFormStyling = {
  theme: 'light',
  primaryColor: '#3B82F6', // Blue
  fontFamily: 'system-ui, sans-serif',
};

/**
 * Default form settings
 */
export const DEFAULT_SETTINGS: WebFormSettings = {
  submitButtonText: 'Submit',
  successMessage: 'Thank you! We will be in touch soon.',
  defaultTags: [],
};

/**
 * Default form stats
 */
export const DEFAULT_STATS: WebFormStats = {
  totalSubmissions: 0,
  submissionsThisMonth: 0,
};

// ============================================
// Helper Functions
// ============================================

/**
 * Create a new form field with default values
 */
export function createDefaultField(
  id: string,
  type: WebFormFieldType,
  label: string,
  mapToField: LeadFieldMapping
): WebFormField {
  return {
    id,
    type,
    label,
    required: false,
    mapToField,
    placeholder: '',
  };
}

/**
 * Check if a field type supports options
 */
export function fieldTypeSupportsOptions(type: WebFormFieldType): boolean {
  return type === 'select';
}

/**
 * Check if a field type is a text input
 */
export function isTextInputField(type: WebFormFieldType): boolean {
  return ['text', 'email', 'phone', 'textarea'].includes(type);
}

/**
 * Sanitize form for public endpoint
 */
export function toPublicFormConfig(form: WebForm): PublicWebFormConfig {
  return {
    id: form.id,
    name: form.name,
    fields: form.fields
      .filter((f) => f.type !== 'hidden') // Hide hidden fields from public config
      .map((f) => ({
        id: f.id,
        type: f.type,
        label: f.label,
        placeholder: f.placeholder,
        required: f.required,
        options: f.options,
        validation: f.validation,
      })),
    submitButtonText: form.settings.submitButtonText,
    successMessage: form.settings.successMessage,
    redirectUrl: form.settings.redirectUrl,
    honeypotEnabled: form.spamProtection.honeypot,
    recaptchaEnabled: form.spamProtection.recaptchaEnabled,
    styling: form.styling,
  };
}
