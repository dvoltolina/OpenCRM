/**
 * FormSelect Component
 * Styled select dropdown for forms
 *
 * Agent CRM-14 Implementation
 */

import React from 'react';
import './forms.css';

// ============================================
// Types
// ============================================

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface FormSelectProps
  extends Omit<React.SelectHTMLAttributes<HTMLSelectElement>, 'onChange'> {
  /** Available options */
  options: SelectOption[];
  /** Placeholder text */
  placeholder?: string;
  /** Whether the select has an error */
  hasError?: boolean;
  /** Change handler with value */
  onChange?: (value: string) => void;
}

// ============================================
// Component
// ============================================

/**
 * FormSelect - Styled select dropdown
 *
 * @example
 * ```tsx
 * <FormSelect
 *   options={[
 *     { value: 'new', label: 'New' },
 *     { value: 'contacted', label: 'Contacted' },
 *   ]}
 *   value={status}
 *   onChange={setStatus}
 *   placeholder="Select status"
 * />
 * ```
 */
export function FormSelect({
  options,
  placeholder,
  hasError,
  onChange,
  className = '',
  value,
  ...props
}: FormSelectProps) {
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange?.(e.target.value);
  };

  return (
    <select
      className={`form-select ${hasError ? 'form-select--error' : ''} ${className}`}
      value={value ?? ''}
      onChange={handleChange}
      {...props}
    >
      {placeholder && (
        <option value="" disabled>
          {placeholder}
        </option>
      )}
      {options.map((option) => (
        <option key={option.value} value={option.value} disabled={option.disabled}>
          {option.label}
        </option>
      ))}
    </select>
  );
}

// ============================================
// Searchable Select (for larger lists)
// ============================================

export interface SearchableSelectProps {
  /** Available options */
  options: SelectOption[];
  /** Current value */
  value: string;
  /** Change handler */
  onChange: (value: string) => void;
  /** Placeholder text */
  placeholder?: string;
  /** Whether the select has an error */
  hasError?: boolean;
  /** Whether the component is disabled */
  disabled?: boolean;
  /** Input ID */
  id?: string;
  /** Input name */
  name?: string;
}

/**
 * SearchableSelect - Select with search/filter capability
 *
 * @example
 * ```tsx
 * <SearchableSelect
 *   options={clients}
 *   value={clientId}
 *   onChange={setClientId}
 *   placeholder="Search clients..."
 * />
 * ```
 */
export function SearchableSelect({
  options,
  value,
  onChange,
  placeholder = 'Search...',
  hasError,
  disabled,
  id,
  name,
}: SearchableSelectProps) {
  const [isOpen, setIsOpen] = React.useState(false);
  const [searchTerm, setSearchTerm] = React.useState('');
  const containerRef = React.useRef<HTMLDivElement>(null);

  // Find selected option label
  const selectedOption = options.find((o) => o.value === value);
  const displayValue = selectedOption?.label || '';

  // Filter options by search term
  const filteredOptions = React.useMemo(() => {
    if (!searchTerm) return options;
    const term = searchTerm.toLowerCase();
    return options.filter((o) => o.label.toLowerCase().includes(term));
  }, [options, searchTerm]);

  // Close on outside click
  React.useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
        setSearchTerm('');
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    setIsOpen(false);
    setSearchTerm('');
  };

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange('');
    setSearchTerm('');
  };

  return (
    <div
      ref={containerRef}
      className={`searchable-select ${hasError ? 'searchable-select--error' : ''} ${
        disabled ? 'searchable-select--disabled' : ''
      }`}
    >
      <div
        className="searchable-select__trigger"
        onClick={() => !disabled && setIsOpen(!isOpen)}
      >
        {isOpen ? (
          <input
            type="text"
            id={id}
            name={name}
            className="searchable-select__input"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder={placeholder}
            autoFocus
          />
        ) : (
          <span className={`searchable-select__value ${!displayValue ? 'searchable-select__placeholder' : ''}`}>
            {displayValue || placeholder}
          </span>
        )}
        {value && !isOpen && (
          <button
            type="button"
            className="searchable-select__clear"
            onClick={handleClear}
            aria-label="Clear selection"
          >
            &times;
          </button>
        )}
        <span className="searchable-select__arrow">{isOpen ? '\u25B2' : '\u25BC'}</span>
      </div>

      {isOpen && (
        <div className="searchable-select__dropdown">
          {filteredOptions.length > 0 ? (
            filteredOptions.map((option) => (
              <div
                key={option.value}
                className={`searchable-select__option ${
                  option.value === value ? 'searchable-select__option--selected' : ''
                } ${option.disabled ? 'searchable-select__option--disabled' : ''}`}
                onClick={() => !option.disabled && handleSelect(option.value)}
              >
                {option.label}
              </div>
            ))
          ) : (
            <div className="searchable-select__no-results">No results found</div>
          )}
        </div>
      )}
    </div>
  );
}

export default FormSelect;
