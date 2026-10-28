/**
 * FormField Component
 * Reusable form field wrapper with label, input, and error display
 *
 * Agent CRM-14 Implementation
 * Agent CRM-35: Enhanced with improved ARIA labels and accessibility
 */

import React from 'react';
import './forms.css';

// ============================================
// Types
// ============================================

export interface FormFieldProps {
  /** Field label */
  label: string;
  /** Field name (for accessibility and error matching) */
  name: string;
  /** Whether the field is required */
  required?: boolean;
  /** Error message to display */
  error?: string;
  /** Help text to display below the field */
  helpText?: string;
  /** Children (input element) */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * FormField - Wrapper component for form inputs
 *
 * @example
 * ```tsx
 * <FormField label="Email" name="email" required error={errors.email}>
 *   <input type="email" value={email} onChange={handleChange} />
 * </FormField>
 * ```
 */
export function FormField({
  label,
  name,
  required = false,
  error,
  helpText,
  children,
  className = '',
}: FormFieldProps) {
  const hasError = Boolean(error);
  const errorId = `${name}-error`;
  const helpId = `${name}-help`;

  // Clone children to add aria attributes
  const enhancedChildren = React.Children.map(children, (child) => {
    if (React.isValidElement(child)) {
      const ariaProps: Record<string, string> = {
        id: name,
        'aria-required': required ? 'true' : 'false',
      };

      if (hasError) {
        ariaProps['aria-invalid'] = 'true';
        ariaProps['aria-describedby'] = errorId;
      } else if (helpText) {
        ariaProps['aria-describedby'] = helpId;
      }

      return React.cloneElement(child, ariaProps);
    }
    return child;
  });

  return (
    <div className={`form-field ${hasError ? 'form-field--error' : ''} ${className}`}>
      <label htmlFor={name} className="form-field__label">
        {label}
        {required && (
          <span className="form-field__required" aria-label="required">
            *
          </span>
        )}
      </label>
      <div className="form-field__input-wrapper">{enhancedChildren}</div>
      {error && (
        <p className="form-field__error" id={errorId} role="alert" aria-live="polite">
          {error}
        </p>
      )}
      {helpText && !error && (
        <p className="form-field__help" id={helpId}>
          {helpText}
        </p>
      )}
    </div>
  );
}

// ============================================
// Form Input Components
// ============================================

export interface FormInputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  /** Whether the input has an error */
  hasError?: boolean;
}

/**
 * FormInput - Styled input component
 */
export function FormInput({ hasError, className = '', ...props }: FormInputProps) {
  return (
    <input
      className={`form-input ${hasError ? 'form-input--error' : ''} ${className}`}
      {...props}
    />
  );
}

export interface FormTextareaProps
  extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  /** Whether the textarea has an error */
  hasError?: boolean;
}

/**
 * FormTextarea - Styled textarea component
 */
export function FormTextarea({ hasError, className = '', ...props }: FormTextareaProps) {
  return (
    <textarea
      className={`form-textarea ${hasError ? 'form-textarea--error' : ''} ${className}`}
      {...props}
    />
  );
}

// ============================================
// Form Actions
// ============================================

export interface FormActionsProps {
  /** Children (buttons) */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

/**
 * FormActions - Container for form submit/cancel buttons
 */
export function FormActions({ children, className = '' }: FormActionsProps) {
  return <div className={`form-actions ${className}`}>{children}</div>;
}

// ============================================
// Form Button
// ============================================

export interface FormButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Button variant */
  variant?: 'primary' | 'secondary' | 'danger';
  /** Whether the button is in loading state */
  isLoading?: boolean;
}

/**
 * FormButton - Styled button component
 */
export function FormButton({
  variant = 'primary',
  isLoading = false,
  disabled,
  children,
  className = '',
  ...props
}: FormButtonProps) {
  return (
    <button
      className={`form-button form-button--${variant} ${className}`}
      disabled={disabled || isLoading}
      aria-busy={isLoading ? 'true' : 'false'}
      aria-live={isLoading ? 'polite' : undefined}
      {...props}
    >
      {isLoading ? 'Saving...' : children}
    </button>
  );
}

// ============================================
// Form Row (for side-by-side fields)
// ============================================

export interface FormRowProps {
  /** Children (form fields) */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

/**
 * FormRow - Container for side-by-side form fields
 */
export function FormRow({ children, className = '' }: FormRowProps) {
  return <div className={`form-row ${className}`}>{children}</div>;
}

// ============================================
// Form Section
// ============================================

export interface FormSectionProps {
  /** Section title */
  title?: string;
  /** Section description */
  description?: string;
  /** Children (form fields) */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

/**
 * FormSection - Group related form fields
 */
export function FormSection({
  title,
  description,
  children,
  className = '',
}: FormSectionProps) {
  return (
    <div className={`form-section ${className}`}>
      {title && <h3 className="form-section__title">{title}</h3>}
      {description && <p className="form-section__description">{description}</p>}
      <div className="form-section__content">{children}</div>
    </div>
  );
}

export default FormField;
