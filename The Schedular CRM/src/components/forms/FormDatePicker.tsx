/**
 * FormDatePicker Component
 * Date picker input for forms
 *
 * Agent CRM-14 Implementation
 */

import React from 'react';
import './forms.css';

// ============================================
// Types
// ============================================

export interface FormDatePickerProps {
  /** Current date value */
  value?: Date | string | null;
  /** Change handler */
  onChange: (date: Date | null) => void;
  /** Input ID */
  id?: string;
  /** Input name */
  name?: string;
  /** Placeholder text */
  placeholder?: string;
  /** Minimum date */
  min?: Date | string;
  /** Maximum date */
  max?: Date | string;
  /** Whether the input has an error */
  hasError?: boolean;
  /** Whether the input is disabled */
  disabled?: boolean;
  /** Whether the input is required */
  required?: boolean;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Utilities
// ============================================

/**
 * Convert a Date to YYYY-MM-DD string for input[type="date"]
 */
function toDateString(date: Date | string | null | undefined): string {
  if (!date) return '';

  const d = typeof date === 'string' ? new Date(date) : date;

  if (isNaN(d.getTime())) return '';

  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

/**
 * Parse YYYY-MM-DD string to Date
 */
function parseDate(dateString: string): Date | null {
  if (!dateString) return null;

  const [year, month, day] = dateString.split('-').map(Number);

  if (!year || !month || !day) return null;

  const date = new Date(year, month - 1, day);

  if (isNaN(date.getTime())) return null;

  return date;
}

// ============================================
// Component
// ============================================

/**
 * FormDatePicker - Date input component
 *
 * @example
 * ```tsx
 * <FormDatePicker
 *   value={expectedCloseDate}
 *   onChange={setExpectedCloseDate}
 *   min={new Date()}
 *   placeholder="Select date"
 * />
 * ```
 */
export function FormDatePicker({
  value,
  onChange,
  id,
  name,
  placeholder = 'Select date',
  min,
  max,
  hasError,
  disabled,
  required,
  className = '',
}: FormDatePickerProps) {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const dateValue = e.target.value;
    const parsed = parseDate(dateValue);
    onChange(parsed);
  };

  return (
    <input
      type="date"
      id={id}
      name={name}
      className={`form-input form-datepicker ${hasError ? 'form-input--error' : ''} ${className}`}
      value={toDateString(value)}
      onChange={handleChange}
      min={toDateString(min)}
      max={toDateString(max)}
      disabled={disabled}
      required={required}
      placeholder={placeholder}
    />
  );
}

// ============================================
// DateTime Picker (includes time)
// ============================================

export interface FormDateTimePickerProps extends FormDatePickerProps {
  /** Whether to show time input */
  showTime?: boolean;
}

/**
 * FormDateTimePicker - Date and time input component
 *
 * @example
 * ```tsx
 * <FormDateTimePicker
 *   value={dueDate}
 *   onChange={setDueDate}
 *   showTime
 * />
 * ```
 */
export function FormDateTimePicker({
  value,
  onChange,
  id,
  name,
  placeholder = 'Select date and time',
  min,
  max,
  hasError,
  disabled,
  required,
  className = '',
}: FormDateTimePickerProps) {
  const toDateTimeString = (date: Date | string | null | undefined): string => {
    if (!date) return '';

    const d = typeof date === 'string' ? new Date(date) : date;

    if (isNaN(d.getTime())) return '';

    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day}T${hours}:${minutes}`;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const dateValue = e.target.value;

    if (!dateValue) {
      onChange(null);
      return;
    }

    const date = new Date(dateValue);

    if (isNaN(date.getTime())) {
      onChange(null);
      return;
    }

    onChange(date);
  };

  return (
    <input
      type="datetime-local"
      id={id}
      name={name}
      className={`form-input form-datepicker ${hasError ? 'form-input--error' : ''} ${className}`}
      value={toDateTimeString(value)}
      onChange={handleChange}
      min={toDateTimeString(min)}
      max={toDateTimeString(max)}
      disabled={disabled}
      required={required}
      placeholder={placeholder}
    />
  );
}

export default FormDatePicker;
