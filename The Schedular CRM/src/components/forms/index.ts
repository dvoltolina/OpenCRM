/**
 * Form Components Library
 * Reusable form components for CRM entities
 *
 * Agent CRM-14 Implementation
 */

// ============================================
// Base Form Components
// ============================================

export {
  FormField,
  FormInput,
  FormTextarea,
  FormActions,
  FormButton,
  FormRow,
  FormSection,
} from './FormField';
export type {
  FormFieldProps,
  FormInputProps,
  FormTextareaProps,
  FormActionsProps,
  FormButtonProps,
  FormRowProps,
  FormSectionProps,
} from './FormField';

// ============================================
// Select Components
// ============================================

export { FormSelect, SearchableSelect } from './FormSelect';
export type { FormSelectProps, SearchableSelectProps, SelectOption } from './FormSelect';

// ============================================
// Date Picker Components
// ============================================

export { FormDatePicker, FormDateTimePicker } from './FormDatePicker';
export type { FormDatePickerProps, FormDateTimePickerProps } from './FormDatePicker';

// ============================================
// Entity Forms
// ============================================

export { LeadForm } from './LeadForm';
export type { LeadFormProps } from './LeadForm';

export { DealForm } from './DealForm';
export type { DealFormProps } from './DealForm';

export { ContactForm } from './ContactForm';
export type { ContactFormProps } from './ContactForm';

export { CompanyForm } from './CompanyForm';
export type { CompanyFormProps } from './CompanyForm';

export { ActivityForm } from './ActivityForm';
export type { ActivityFormProps } from './ActivityForm';

// ============================================
// Validation
// ============================================

export {
  validateLeadForm,
  validateDealForm,
  validateContactForm,
  validateCompanyForm,
  validateActivityForm,
  getFieldError,
  isValidEmail,
  isValidUrl,
  isValidPhone,
  isRequired,
  isInRange,
  isNonNegative,
} from './validation/schemas';
export type {
  LeadFormData,
  DealFormData,
  ContactFormData,
  CompanyFormData,
  ActivityFormData,
  ValidationError,
  ValidationResult,
} from './validation/schemas';
