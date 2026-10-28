/**
 * SequenceStepEditor Tests
 *
 * Test Scenarios:
 * 1. Renders correct config for each step type
 * 2. Validation prevents empty saves
 * 3. Save callback receives updated step
 * 4. Cancel callback closes editor
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { SequenceStepEditor } from '../SequenceStepEditor';
import type { SequenceStep } from '../../../types/sequences';

// ============================================
// Test Data
// ============================================

const emailStep: SequenceStep = {
  id: 'step-email',
  order: 0,
  type: 'email',
  delayDays: 0,
  isActive: true,
  emailConfig: {
    subject: 'Test Subject',
    body: 'Test Body',
  },
};

const taskStep: SequenceStep = {
  id: 'step-task',
  order: 1,
  type: 'task',
  delayDays: 1,
  isActive: true,
  taskConfig: {
    title: 'Test Task',
    description: 'Task description',
    assignToOwner: true,
    dueDays: 0,
  },
};

const waitStep: SequenceStep = {
  id: 'step-wait',
  order: 2,
  type: 'wait',
  delayDays: 3,
  delayHours: 0,
  isActive: true,
};

const callStep: SequenceStep = {
  id: 'step-call',
  order: 3,
  type: 'call_reminder',
  delayDays: 1,
  isActive: true,
  callConfig: {
    title: 'Test Call',
    notes: 'Call notes',
  },
};

// ============================================
// Tests
// ============================================

describe('SequenceStepEditor', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Renders correct config for each step type
  // ============================================
  describe('renders correct config for each step type', () => {
    it('renders email step config', () => {
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={emailStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByTestId('step-editor')).toBeInTheDocument();
      expect(screen.getByTestId('email-step-config')).toBeInTheDocument();
      expect(screen.getByText('Email Step')).toBeInTheDocument();
    });

    it('renders task step config', () => {
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={taskStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByTestId('task-step-config')).toBeInTheDocument();
      expect(screen.getByText('Task Step')).toBeInTheDocument();
      expect(screen.getByLabelText('Task Title')).toHaveValue('Test Task');
    });

    it('renders wait step config', () => {
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={waitStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByTestId('wait-step-config')).toBeInTheDocument();
      expect(screen.getByText('Wait Step')).toBeInTheDocument();
      expect(screen.getByText('Wait for 3 days')).toBeInTheDocument();
    });

    it('renders call step config', () => {
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={callStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByTestId('call-step-config')).toBeInTheDocument();
      expect(screen.getByText('Call Reminder')).toBeInTheDocument();
      expect(screen.getByLabelText('Call Reminder Title')).toHaveValue('Test Call');
    });
  });

  // ============================================
  // Test 2: Validation prevents empty saves
  // ============================================
  describe('validation prevents empty saves', () => {
    it('shows error for empty email subject', () => {
      const emptyEmailStep: SequenceStep = {
        ...emailStep,
        emailConfig: { subject: '', body: '' },
      };
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={emptyEmailStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(
        screen.getByText('Email must have a subject and body, or use a template')
      ).toBeInTheDocument();
      expect(screen.getByTestId('save-step-btn')).toBeDisabled();
    });

    it('shows error for empty task title', () => {
      const emptyTaskStep: SequenceStep = {
        ...taskStep,
        taskConfig: { title: '', assignToOwner: true, dueDays: 0 },
      };
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={emptyTaskStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByText('Task must have a title')).toBeInTheDocument();
      expect(screen.getByTestId('save-step-btn')).toBeDisabled();
    });

    it('shows error for zero wait delay', () => {
      const zeroWaitStep: SequenceStep = {
        ...waitStep,
        delayDays: 0,
        delayHours: 0,
      };
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={zeroWaitStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(
        screen.getByText('Wait must have a delay greater than 0')
      ).toBeInTheDocument();
      expect(screen.getByTestId('save-step-btn')).toBeDisabled();
    });

    it('shows error for empty call title', () => {
      const emptyCallStep: SequenceStep = {
        ...callStep,
        callConfig: { title: '' },
      };
      const onSave = vi.fn();
      const onCancel = vi.fn();

      render(
        <SequenceStepEditor
          step={emptyCallStep}
          onSave={onSave}
          onCancel={onCancel}
        />
      );

      expect(screen.getByText('Call reminder must have a title')).toBeInTheDocument();
      expect(screen.getByTestId('save-step-btn')).toBeDisabled();
    });
  });

  // ============================================
  // Test 3: Save callback receives updated step
  // ============================================
  it('save callback receives updated step', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={taskStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    // Modify the task title
    const titleInput = screen.getByLabelText('Task Title');
    fireEvent.change(titleInput, { target: { value: 'Updated Task' } });

    // Click save
    fireEvent.click(screen.getByTestId('save-step-btn'));

    expect(onSave).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'step-task',
        type: 'task',
        taskConfig: expect.objectContaining({
          title: 'Updated Task',
        }),
      })
    );
  });

  // ============================================
  // Test 4: Cancel callback closes editor
  // ============================================
  it('cancel callback closes editor', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={emailStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    // Click cancel button
    fireEvent.click(screen.getByText('Cancel'));

    expect(onCancel).toHaveBeenCalled();
    expect(onSave).not.toHaveBeenCalled();
  });

  it('clicking overlay closes editor', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={emailStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    // Click on the overlay (outside the modal content)
    const overlay = document.querySelector('.step-editor-overlay');
    if (overlay) {
      fireEvent.click(overlay);
    }

    expect(onCancel).toHaveBeenCalled();
  });

  it('close button closes editor', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={emailStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    // Click close button
    fireEvent.click(screen.getByLabelText('Close'));

    expect(onCancel).toHaveBeenCalled();
  });

  // ============================================
  // Test 5: Disabled state
  // ============================================
  it('disables inputs when disabled prop is true', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={taskStep}
        onSave={onSave}
        onCancel={onCancel}
        disabled
      />
    );

    expect(screen.getByLabelText('Task Title')).toBeDisabled();
    expect(screen.getByTestId('save-step-btn')).toBeDisabled();
  });

  // ============================================
  // Test 6: Timing fields
  // ============================================
  it('shows timing fields for non-wait steps', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={emailStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    expect(screen.getByLabelText('Days after previous step')).toBeInTheDocument();
    expect(screen.getByLabelText('Hours')).toBeInTheDocument();
    expect(screen.getByLabelText('Preferred time of day')).toBeInTheDocument();
  });

  it('does not show timing fields for wait steps', () => {
    const onSave = vi.fn();
    const onCancel = vi.fn();

    render(
      <SequenceStepEditor
        step={waitStep}
        onSave={onSave}
        onCancel={onCancel}
      />
    );

    // Wait steps have their own delay config, not the general timing section
    expect(screen.queryByLabelText('Days after previous step')).not.toBeInTheDocument();
  });
});
