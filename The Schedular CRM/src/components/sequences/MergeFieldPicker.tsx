/**
 * MergeFieldPicker Component
 * Dropdown for selecting merge fields to insert
 */

import { useState, useCallback, useRef, useEffect } from 'react';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface MergeFieldPickerProps {
  onSelect: (field: string) => void;
}

interface FieldCategory {
  name: string;
  fields: Array<{
    key: string;
    label: string;
    example?: string;
  }>;
}

// ============================================
// Constants
// ============================================

const FIELD_CATEGORIES: FieldCategory[] = [
  {
    name: 'Contact',
    fields: [
      { key: 'firstName', label: 'First Name', example: 'John' },
      { key: 'lastName', label: 'Last Name', example: 'Smith' },
      { key: 'email', label: 'Email', example: 'john@example.com' },
      { key: 'phone', label: 'Phone', example: '(555) 123-4567' },
      { key: 'title', label: 'Job Title', example: 'Marketing Director' },
    ],
  },
  {
    name: 'Company',
    fields: [
      { key: 'companyName', label: 'Company Name', example: 'Acme Corp' },
      { key: 'industry', label: 'Industry', example: 'Technology' },
    ],
  },
  {
    name: 'Sender',
    fields: [
      { key: 'senderName', label: 'Your Name', example: 'Jane Doe' },
      { key: 'senderEmail', label: 'Your Email', example: 'jane@example.com' },
      { key: 'senderPhone', label: 'Your Phone', example: '(555) 987-6543' },
    ],
  },
];

// ============================================
// Component
// ============================================

export function MergeFieldPicker({ onSelect }: MergeFieldPickerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close on click outside
  useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  // Close on escape
  useEffect(() => {
    if (!isOpen) return;

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsOpen(false);
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen]);

  const handleSelect = useCallback(
    (field: string) => {
      onSelect(field);
      setIsOpen(false);
    },
    [onSelect]
  );

  return (
    <div className="merge-field-picker" ref={containerRef}>
      <button
        type="button"
        className="merge-field-picker__trigger"
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-haspopup="listbox"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" />
          <line x1="7" y1="7" x2="7.01" y2="7" />
        </svg>
        Insert Field
      </button>

      {isOpen && (
        <div className="merge-field-picker__dropdown" role="listbox">
          {FIELD_CATEGORIES.map((category) => (
            <div key={category.name}>
              <div className="merge-field-picker__category">{category.name}</div>
              {category.fields.map((field) => (
                <button
                  key={field.key}
                  type="button"
                  className="merge-field-picker__item"
                  onClick={() => handleSelect(field.key)}
                  role="option"
                >
                  <span>{field.label}</span>
                  <span className="merge-field-picker__item-field">
                    {`{{${field.key}}}`}
                  </span>
                </button>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default MergeFieldPicker;
