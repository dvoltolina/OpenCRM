/**
 * useSequenceBuilder Hook
 * State management for the sequence builder UI
 */

import { useState, useCallback, useMemo } from 'react';
import { useSequence, useSequenceMutations } from './useSequences';
import type {
  Sequence,
  SequenceStep,
  SequenceSettings,
  SequenceStepType,
} from '../types/sequences';
import {
  DEFAULT_SEQUENCE_SETTINGS,
  createEmptyStep,
  generateStepId,
  calculateSequenceDuration,
} from '../types/sequences';

// ============================================
// Types
// ============================================

export interface ValidationError {
  stepId?: string;
  field: string;
  message: string;
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

export interface UseSequenceBuilderResult {
  /** Current sequence (null for new) */
  sequence: Sequence | null;
  /** Current steps being edited */
  steps: SequenceStep[];
  /** Current settings */
  settings: SequenceSettings;
  /** Sequence name */
  name: string;
  /** Sequence description */
  description: string;
  /** Is loading existing sequence */
  isLoading: boolean;
  /** Is saving */
  isSaving: boolean;
  /** Has unsaved changes */
  hasChanges: boolean;
  /** Validation result */
  validation: ValidationResult;
  /** Total sequence duration in days */
  durationDays: number;

  // Actions
  setName: (name: string) => void;
  setDescription: (description: string) => void;
  addStep: (type: SequenceStepType, afterIndex?: number) => void;
  updateStep: (stepId: string, updates: Partial<SequenceStep>) => void;
  removeStep: (stepId: string) => void;
  reorderSteps: (fromIndex: number, toIndex: number) => void;
  duplicateStep: (stepId: string) => void;
  updateSettings: (updates: Partial<SequenceSettings>) => void;
  validate: () => ValidationResult;
  save: () => Promise<Sequence>;
  reset: () => void;
}

// ============================================
// Default Values
// ============================================

const DEFAULT_SETTINGS: SequenceSettings = {
  ...DEFAULT_SEQUENCE_SETTINGS,
  sendingSchedule: { ...DEFAULT_SEQUENCE_SETTINGS.sendingSchedule },
};

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing sequence builder state
 *
 * @param sequenceId - Optional ID for editing existing sequence
 */
export function useSequenceBuilder(sequenceId?: string): UseSequenceBuilderResult {
  // Fetch existing sequence if editing
  const { sequence: existingSequence, isLoading } = useSequence(sequenceId);
  const { createSequence, updateSequence, updateSteps: updateSequenceSteps } =
    useSequenceMutations();

  // Local state
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [steps, setSteps] = useState<SequenceStep[]>([]);
  const [settings, setSettings] = useState<SequenceSettings>(DEFAULT_SETTINGS);
  const [isSaving, setIsSaving] = useState(false);
  const [initialized, setInitialized] = useState(false);

  // Initialize from existing sequence
  useMemo(() => {
    if (existingSequence && !initialized) {
      setName(existingSequence.name);
      setDescription(existingSequence.description || '');
      setSteps(existingSequence.steps);
      setSettings({
        ...DEFAULT_SETTINGS,
        ...existingSequence.settings,
        sendingSchedule: {
          ...DEFAULT_SETTINGS.sendingSchedule,
          ...existingSequence.settings.sendingSchedule,
        },
      });
      setInitialized(true);
    }
  }, [existingSequence, initialized]);

  // Track changes
  const hasChanges = useMemo(() => {
    if (!existingSequence) {
      return name.trim().length > 0 || steps.length > 0;
    }

    return (
      name !== existingSequence.name ||
      description !== (existingSequence.description || '') ||
      JSON.stringify(steps) !== JSON.stringify(existingSequence.steps) ||
      JSON.stringify(settings) !== JSON.stringify(existingSequence.settings)
    );
  }, [existingSequence, name, description, steps, settings]);

  // Calculate duration
  const durationDays = useMemo(() => {
    return Math.ceil(calculateSequenceDuration(steps));
  }, [steps]);

  // ============================================
  // Step Management
  // ============================================

  const addStep = useCallback((type: SequenceStepType, afterIndex?: number) => {
    setSteps((currentSteps) => {
      const insertIndex = afterIndex !== undefined ? afterIndex + 1 : currentSteps.length;
      const newStep = createEmptyStep(type, insertIndex);

      const updatedSteps = [...currentSteps];
      updatedSteps.splice(insertIndex, 0, newStep);

      // Re-index orders
      return updatedSteps.map((step, index) => ({
        ...step,
        order: index,
      }));
    });
  }, []);

  const updateStep = useCallback((stepId: string, updates: Partial<SequenceStep>) => {
    setSteps((currentSteps) =>
      currentSteps.map((step) =>
        step.id === stepId ? { ...step, ...updates } : step
      )
    );
  }, []);

  const removeStep = useCallback((stepId: string) => {
    setSteps((currentSteps) => {
      const filtered = currentSteps.filter((step) => step.id !== stepId);
      // Re-index orders
      return filtered.map((step, index) => ({
        ...step,
        order: index,
      }));
    });
  }, []);

  const reorderSteps = useCallback((fromIndex: number, toIndex: number) => {
    setSteps((currentSteps) => {
      const newSteps = [...currentSteps];
      const [removed] = newSteps.splice(fromIndex, 1);
      newSteps.splice(toIndex, 0, removed);

      // Re-index orders
      return newSteps.map((step, index) => ({
        ...step,
        order: index,
      }));
    });
  }, []);

  const duplicateStep = useCallback((stepId: string) => {
    setSteps((currentSteps) => {
      const stepIndex = currentSteps.findIndex((s) => s.id === stepId);
      if (stepIndex === -1) return currentSteps;

      const originalStep = currentSteps[stepIndex];
      const duplicatedStep: SequenceStep = {
        ...originalStep,
        id: generateStepId(),
        order: stepIndex + 1,
      };

      const newSteps = [...currentSteps];
      newSteps.splice(stepIndex + 1, 0, duplicatedStep);

      // Re-index orders
      return newSteps.map((step, index) => ({
        ...step,
        order: index,
      }));
    });
  }, []);

  // ============================================
  // Settings Management
  // ============================================

  const updateSettings = useCallback((updates: Partial<SequenceSettings>) => {
    setSettings((current) => ({
      ...current,
      ...updates,
    }));
  }, []);

  // ============================================
  // Validation
  // ============================================

  const validate = useCallback((): ValidationResult => {
    const errors: ValidationError[] = [];

    // Validate name
    if (!name.trim()) {
      errors.push({
        field: 'name',
        message: 'Sequence name is required',
      });
    }

    // Validate steps
    if (steps.length === 0) {
      errors.push({
        field: 'steps',
        message: 'Sequence must have at least one step',
      });
    }

    // Validate has at least one action step
    const actionSteps = steps.filter(
      (step) => step.type !== 'wait' && step.isActive
    );
    if (steps.length > 0 && actionSteps.length === 0) {
      errors.push({
        field: 'steps',
        message: 'Sequence must have at least one action step (email, task, call, or SMS)',
      });
    }

    // Validate first step is not a wait
    if (steps.length > 0 && steps[0].type === 'wait') {
      errors.push({
        stepId: steps[0].id,
        field: 'type',
        message: 'First step cannot be a wait step',
      });
    }

    // Validate each step
    steps.forEach((step) => {
      // Validate email steps
      if (step.type === 'email' && step.isActive) {
        if (
          !step.emailConfig?.templateId &&
          (!step.emailConfig?.subject?.trim() || !step.emailConfig?.body?.trim())
        ) {
          errors.push({
            stepId: step.id,
            field: 'emailConfig',
            message: 'Email step must have a template or subject and body',
          });
        }
      }

      // Validate task steps
      if (step.type === 'task' && step.isActive) {
        if (!step.taskConfig?.title?.trim()) {
          errors.push({
            stepId: step.id,
            field: 'taskConfig.title',
            message: 'Task step must have a title',
          });
        }
      }

      // Validate call reminder steps
      if (step.type === 'call_reminder' && step.isActive) {
        if (!step.callConfig?.title?.trim()) {
          errors.push({
            stepId: step.id,
            field: 'callConfig.title',
            message: 'Call reminder step must have a title',
          });
        }
      }

      // Validate wait steps
      if (step.type === 'wait' && step.isActive) {
        if (step.delayDays <= 0 && (!step.delayHours || step.delayHours <= 0)) {
          errors.push({
            stepId: step.id,
            field: 'delayDays',
            message: 'Wait step must have a delay greater than 0',
          });
        }
      }

      // Validate SMS steps
      if (step.type === 'sms' && step.isActive) {
        if (!step.smsConfig?.templateId && !step.smsConfig?.body?.trim()) {
          errors.push({
            stepId: step.id,
            field: 'smsConfig',
            message: 'SMS step must have a template or body',
          });
        }
      }
    });

    // Validate settings
    if (
      settings.sendingSchedule.startHour >= settings.sendingSchedule.endHour
    ) {
      errors.push({
        field: 'settings.sendingSchedule',
        message: 'Business hours start must be before end',
      });
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }, [name, steps, settings]);

  const validation = useMemo(() => validate(), [validate]);

  // ============================================
  // Save
  // ============================================

  const save = useCallback(async (): Promise<Sequence> => {
    const validationResult = validate();
    if (!validationResult.isValid) {
      throw new Error('Validation failed: ' + validationResult.errors[0].message);
    }

    setIsSaving(true);

    try {
      if (existingSequence) {
        // Update existing sequence
        const updated = await updateSequence(existingSequence.id, {
          name,
          description: description || undefined,
          settings,
        });

        // Update steps separately if sequence is not active
        if (existingSequence.status !== 'active') {
          await updateSequenceSteps(existingSequence.id, steps);
        }

        return updated;
      } else {
        // Create new sequence
        return await createSequence({
          name,
          description: description || undefined,
          steps,
          settings,
        });
      }
    } finally {
      setIsSaving(false);
    }
  }, [
    existingSequence,
    name,
    description,
    steps,
    settings,
    validate,
    createSequence,
    updateSequence,
    updateSequenceSteps,
  ]);

  // ============================================
  // Reset
  // ============================================

  const reset = useCallback(() => {
    if (existingSequence) {
      setName(existingSequence.name);
      setDescription(existingSequence.description || '');
      setSteps(existingSequence.steps);
      setSettings(existingSequence.settings);
    } else {
      setName('');
      setDescription('');
      setSteps([]);
      setSettings(DEFAULT_SETTINGS);
    }
  }, [existingSequence]);

  return {
    sequence: existingSequence,
    steps,
    settings,
    name,
    description,
    isLoading,
    isSaving,
    hasChanges,
    validation,
    durationDays,

    setName,
    setDescription,
    addStep,
    updateStep,
    removeStep,
    reorderSteps,
    duplicateStep,
    updateSettings,
    validate,
    save,
    reset,
  };
}

export default useSequenceBuilder;
