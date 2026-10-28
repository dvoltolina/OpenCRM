import type { IntakeFormFieldType } from '../../types/models';

export type FieldPaletteItem = {
  type: IntakeFormFieldType;
  label: string;
  description: string;
  icon: string;
};

export const FIELD_PALETTE: FieldPaletteItem[] = [
  { type: 'text', label: 'Text Input', description: 'Short answer', icon: 'text' },
  { type: 'textarea', label: 'Long Text', description: 'Paragraph response', icon: 'textarea' },
  { type: 'dropdown', label: 'Dropdown', description: 'Select one option', icon: 'dropdown' },
  { type: 'radio', label: 'Single Choice', description: 'Pick one answer', icon: 'radio' },
  { type: 'checkbox', label: 'Multiple Choice', description: 'Select many', icon: 'checkbox' },
  { type: 'date', label: 'Date', description: 'Calendar picker', icon: 'date' },
  { type: 'file', label: 'File Upload', description: 'Documents & images', icon: 'file' },
  { type: 'signature', label: 'Signature', description: 'E-signature pad', icon: 'signature' },
];

export const SERVICE_OPTIONS = [
  'Physical Therapy Evaluation',
  'Follow-up Visit',
  'Telehealth Check-in',
  'Massage Therapy',
  'Initial Consultation',
  'Wellness Check',
];

