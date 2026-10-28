/**
 * StepTypeSelector Component
 * Visual selector for choosing step types
 */

import type { ReactNode } from 'react';
import type { SequenceStepType } from '../../types/sequences';
import { getFeatureFlags } from '../../config/features';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface StepTypeSelectorProps {
  onSelect: (type: SequenceStepType) => void;
  onCancel: () => void;
}

interface StepTypeOption {
  type: SequenceStepType;
  label: string;
  description: string;
  icon: ReactNode;
  colorClass: string;
  requiresFlag?: keyof ReturnType<typeof getFeatureFlags>;
}

// ============================================
// Constants
// ============================================

const STEP_TYPES: StepTypeOption[] = [
  {
    type: 'email',
    label: 'Email',
    description: 'Send an automated email',
    colorClass: 'sequence-step-card__icon--email',
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
        <path d="m22 6-10 7L2 6" />
      </svg>
    ),
  },
  {
    type: 'task',
    label: 'Task',
    description: 'Create a task reminder',
    colorClass: 'sequence-step-card__icon--task',
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M9 11l3 3L22 4" />
        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
      </svg>
    ),
  },
  {
    type: 'wait',
    label: 'Wait',
    description: 'Add a delay between steps',
    colorClass: 'sequence-step-card__icon--wait',
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <circle cx="12" cy="12" r="10" />
        <path d="M12 6v6l4 2" />
      </svg>
    ),
  },
  {
    type: 'call_reminder',
    label: 'Call',
    description: 'Create a call reminder task',
    colorClass: 'sequence-step-card__icon--call',
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
      </svg>
    ),
  },
  {
    type: 'sms',
    label: 'SMS',
    description: 'Send a text message',
    colorClass: 'sequence-step-card__icon--sms',
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
      </svg>
    ),
    requiresFlag: 'enableEmailIntegration', // SMS would be similar feature flag
  },
];

// ============================================
// Component
// ============================================

export function StepTypeSelector({ onSelect, onCancel: _onCancel }: StepTypeSelectorProps) {
  const features = getFeatureFlags();

  return (
    <div className="step-type-selector" data-testid="step-type-selector">
      {STEP_TYPES.map((option) => {
        // Check if feature is enabled
        const isDisabled = option.requiresFlag && !features[option.requiresFlag];

        return (
          <button
            key={option.type}
            type="button"
            className="step-type-selector__option"
            onClick={() => onSelect(option.type)}
            disabled={isDisabled}
            title={isDisabled ? 'This feature is not enabled' : option.description}
          >
            <div className={`step-type-selector__icon ${option.colorClass}`}>
              {option.icon}
            </div>
            <span className="step-type-selector__label">{option.label}</span>
            <span className="step-type-selector__description">
              {isDisabled ? 'Coming soon' : option.description}
            </span>
          </button>
        );
      })}
    </div>
  );
}

export default StepTypeSelector;
