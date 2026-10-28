/**
 * Form Validation Schemas
 * Validation rules for CRM entity forms
 *
 * Agent CRM-14 Implementation
 */

// ============================================
// Types
// ============================================

export interface ValidationError {
  field: string;
  message: string;
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

// ============================================
// Validation Utilities
// ============================================

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const URL_REGEX = /^https?:\/\/.+/;
const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;

/**
 * Validate an email address format
 */
export function isValidEmail(email: string): boolean {
  return EMAIL_REGEX.test(email.trim());
}

/**
 * Validate a URL format
 */
export function isValidUrl(url: string): boolean {
  return URL_REGEX.test(url.trim());
}

/**
 * Validate a phone number format
 */
export function isValidPhone(phone: string): boolean {
  return PHONE_REGEX.test(phone.trim());
}

/**
 * Check if a value is non-empty
 */
export function isRequired(value: unknown): boolean {
  if (value === null || value === undefined) return false;
  if (typeof value === 'string') return value.trim().length > 0;
  if (Array.isArray(value)) return value.length > 0;
  return true;
}

/**
 * Check if a number is within range
 */
export function isInRange(value: number, min: number, max: number): boolean {
  return value >= min && value <= max;
}

/**
 * Check if a number is non-negative
 */
export function isNonNegative(value: number): boolean {
  return value >= 0;
}

// ============================================
// Lead Validation
// ============================================

export interface LeadFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyName?: string;
  title?: string;
  source?: string;
  status?: string;
  notes?: string;
  tags?: string[];
}

export function validateLeadForm(data: LeadFormData): ValidationResult {
  const errors: ValidationError[] = [];

  // Required fields
  if (!isRequired(data.firstName)) {
    errors.push({ field: 'firstName', message: 'First name is required' });
  }

  if (!isRequired(data.lastName)) {
    errors.push({ field: 'lastName', message: 'Last name is required' });
  }

  if (!isRequired(data.email)) {
    errors.push({ field: 'email', message: 'Email is required' });
  } else if (!isValidEmail(data.email)) {
    errors.push({ field: 'email', message: 'Please enter a valid email address' });
  }

  // Optional field validation
  if (data.phone && !isValidPhone(data.phone)) {
    errors.push({ field: 'phone', message: 'Please enter a valid phone number' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Deal Validation
// ============================================

export interface DealFormData {
  title: string;
  valueCents: number;
  pipelineId: string;
  stageId: string;
  currency?: string;
  probability?: number;
  expectedCloseDate?: Date | string;
  clientId?: string;
  clientName?: string;
  companyId?: string;
  companyName?: string;
  notes?: string;
  tags?: string[];
}

export function validateDealForm(data: DealFormData): ValidationResult {
  const errors: ValidationError[] = [];

  // Required fields
  if (!isRequired(data.title)) {
    errors.push({ field: 'title', message: 'Opportunity title is required' });
  }

  if (!isRequired(data.pipelineId)) {
    errors.push({ field: 'pipelineId', message: 'Pipeline is required' });
  }

  if (!isRequired(data.stageId)) {
    errors.push({ field: 'stageId', message: 'Stage is required' });
  }

  // Value validation
  if (data.valueCents === undefined || data.valueCents === null) {
    errors.push({ field: 'valueCents', message: 'Deal value is required' });
  } else if (!isNonNegative(data.valueCents)) {
    errors.push({ field: 'valueCents', message: 'Deal value must be positive' });
  }

  // Probability validation
  if (data.probability !== undefined && !isInRange(data.probability, 0, 100)) {
    errors.push({ field: 'probability', message: 'Probability must be between 0 and 100' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Contact Validation
// ============================================

export interface ContactFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyId?: string;
  companyName?: string;
  title?: string;
  lifecycle?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
  notes?: string;
  tags?: string[];
}

export function validateContactForm(data: ContactFormData): ValidationResult {
  const errors: ValidationError[] = [];

  // Required fields
  if (!isRequired(data.firstName)) {
    errors.push({ field: 'firstName', message: 'First name is required' });
  }

  if (!isRequired(data.lastName)) {
    errors.push({ field: 'lastName', message: 'Last name is required' });
  }

  if (!isRequired(data.email)) {
    errors.push({ field: 'email', message: 'Email is required' });
  } else if (!isValidEmail(data.email)) {
    errors.push({ field: 'email', message: 'Please enter a valid email address' });
  }

  // Optional field validation
  if (data.phone && !isValidPhone(data.phone)) {
    errors.push({ field: 'phone', message: 'Please enter a valid phone number' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Company Validation
// ============================================

export interface CompanyFormData {
  name: string;
  industry?: string;
  size?: string;
  website?: string;
  phone?: string;
  email?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
  notes?: string;
  tags?: string[];
}

export function validateCompanyForm(data: CompanyFormData): ValidationResult {
  const errors: ValidationError[] = [];

  // Required fields
  if (!isRequired(data.name)) {
    errors.push({ field: 'name', message: 'Company name is required' });
  }

  // Optional field validation
  if (data.email && !isValidEmail(data.email)) {
    errors.push({ field: 'email', message: 'Please enter a valid email address' });
  }

  if (data.website && !isValidUrl(data.website)) {
    errors.push({ field: 'website', message: 'Please enter a valid URL (https://...)' });
  }

  if (data.phone && !isValidPhone(data.phone)) {
    errors.push({ field: 'phone', message: 'Please enter a valid phone number' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Activity Validation
// ============================================

export interface ActivityFormData {
  type: string;
  title: string;
  description?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  dueDate?: Date | string;
  assigneeId?: string;
  assigneeName?: string;
  templateId?: string;
  slaMinutes?: number;
  slaAt?: Date | string;
  reminderAt?: Date | string;
}

export function validateActivityForm(data: ActivityFormData): ValidationResult {
  const errors: ValidationError[] = [];

  // Required fields
  if (!isRequired(data.type)) {
    errors.push({ field: 'type', message: 'Activity type is required' });
  }

  if (!isRequired(data.title)) {
    errors.push({ field: 'title', message: 'Title is required' });
  }

  // At least one entity must be linked
  const hasEntity = data.dealId || data.clientId || data.leadId || data.companyId;
  if (!hasEntity) {
    errors.push({
      field: 'entity',
      message: 'Activity must be linked to at least one entity (deal, contact, lead, or company)',
    });
  }

  // Tasks require due date
  if (data.type === 'task' && !data.dueDate) {
    errors.push({ field: 'dueDate', message: 'Due date is required for tasks' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Helper to get error for a specific field
// ============================================

export function getFieldError(
  errors: ValidationError[],
  field: string
): string | undefined {
  const error = errors.find((e) => e.field === field);
  return error?.message;
}
