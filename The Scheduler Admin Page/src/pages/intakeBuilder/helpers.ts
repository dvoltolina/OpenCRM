import type { IntakeForm, IntakeFormField, IntakeFormFieldType } from '../../types/models';

export const createLocalId = (prefix: string) => `${prefix}_${Math.random().toString(36).slice(2, 8)}`;

export const cloneForm = (form: IntakeForm): IntakeForm => JSON.parse(JSON.stringify(form));

const defaultOptions: Record<string, string[]> = {
  dropdown: ['Option A', 'Option B'],
  radio: ['Option 1', 'Option 2'],
  checkbox: ['Choice 1', 'Choice 2'],
};

export function createFieldTemplate(type: IntakeFormFieldType): IntakeFormField {
  return {
    id: createLocalId('field'),
    type,
    label: defaultLabel(type),
    required: type === 'signature',
    placeholder: placeholderByType(type),
    helperText: undefined,
    width: 'full',
    defaultValue: type === 'date' ? new Date().toISOString().slice(0, 10) : undefined,
    options: defaultOptions[type] ? [...defaultOptions[type]] : [],
  };
}

export function cloneField(field: IntakeFormField): IntakeFormField {
  const cloned: IntakeFormField = JSON.parse(JSON.stringify(field));
  cloned.id = createLocalId('field');
  if (cloned.conditionalLogic) {
    cloned.conditionalLogic = {
      ...cloned.conditionalLogic,
      id: createLocalId('logic'),
      conditions: cloned.conditionalLogic.conditions.map((condition) => ({
        ...condition,
        id: createLocalId('condition'),
      })),
    };
  }
  return cloned;
}

function defaultLabel(type: IntakeFormFieldType) {
  switch (type) {
    case 'textarea':
      return 'Long answer';
    case 'dropdown':
      return 'Select an option';
    case 'radio':
      return 'Choose one';
    case 'checkbox':
      return 'Select any that apply';
    case 'date':
      return 'Date';
    case 'file':
      return 'Upload file';
    case 'signature':
      return 'Signature';
    default:
      return 'Short answer';
  }
}

function placeholderByType(type: IntakeFormFieldType) {
  if (type === 'text') return 'Enter text';
  if (type === 'textarea') return 'Provide more context';
  if (type === 'dropdown') return 'Select';
  return undefined;
}


