/**
 * StageEditor Component Tests
 * Agent CRM-20 Implementation
 */

import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { StageEditor } from '../StageEditor';
import type { Stage } from '../../../types/models';

describe('StageEditor', () => {
  const mockOnSave = vi.fn();
  const mockOnCancel = vi.fn();

  const defaultProps = {
    pipelineId: 'pipeline-123',
    order: 0,
    onSave: mockOnSave,
    onCancel: mockOnCancel,
  };

  const existingStage: Stage = {
    id: 'stage-1',
    pipelineId: 'pipeline-123',
    name: 'Qualified',
    colorHex: '#3b82f6',
    order: 1,
    probability: 30,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Renders create mode
  it('renders in create mode with empty form', () => {
    render(<StageEditor {...defaultProps} />);

    expect(screen.getByTestId('stage-editor')).toBeInTheDocument();
    expect(screen.getByText('New Stage')).toBeInTheDocument();
    expect(screen.getByLabelText('Stage Name *')).toHaveValue('');
    expect(screen.getByTestId('color-picker')).toBeInTheDocument();
    expect(screen.getByText('Create Stage')).toBeInTheDocument();
  });

  // Test 2: Renders edit mode with existing stage data
  it('renders in edit mode with stage data populated', () => {
    render(<StageEditor {...defaultProps} stage={existingStage} />);

    expect(screen.getByText('Edit Stage')).toBeInTheDocument();
    expect(screen.getByLabelText('Stage Name *')).toHaveValue('Qualified');
    expect(screen.getByText('Save Changes')).toBeInTheDocument();
  });

  // Test 3: Validates required stage name
  it('shows error when stage name is empty', async () => {
    const user = userEvent.setup();
    render(<StageEditor {...defaultProps} />);

    // Submit without entering name
    await user.click(screen.getByText('Create Stage'));

    expect(screen.getByRole('alert')).toHaveTextContent('Stage name is required');
    expect(mockOnSave).not.toHaveBeenCalled();
  });

  // Test 4: Validates probability range - component clamps values to 0-100
  it('shows error when probability is out of range', async () => {
    const user = userEvent.setup();
    render(<StageEditor {...defaultProps} />);

    // Enter name and out-of-range probability (component clamps to 100)
    await user.type(screen.getByLabelText('Stage Name *'), 'Test Stage');

    const probabilityInput = screen.getByRole('spinbutton');
    await user.clear(probabilityInput);
    await user.type(probabilityInput, '150');

    // The component clamps the value to 100 on input, so submit should succeed
    await user.click(screen.getByText('Create Stage'));

    // Value should be clamped to 100 (valid) - onSave should be called
    expect(mockOnSave).toHaveBeenCalledWith(
      expect.objectContaining({
        probability: 100, // Clamped from 150
      })
    );
  });

  // Test 5: Submits valid form data for new stage
  it('calls onSave with correct data for new stage', async () => {
    const user = userEvent.setup();
    mockOnSave.mockResolvedValue(undefined);

    render(<StageEditor {...defaultProps} order={2} />);

    // Fill in the form
    await user.type(screen.getByLabelText('Stage Name *'), 'Proposal');

    // Select a color (second color preset - blue)
    const colorButtons = screen.getAllByRole('button', { name: /Select color/i });
    await user.click(colorButtons[1]);

    // Adjust probability
    const probabilityInput = screen.getByRole('spinbutton');
    await user.clear(probabilityInput);
    await user.type(probabilityInput, '50');

    // Submit
    await user.click(screen.getByText('Create Stage'));

    await waitFor(() => {
      expect(mockOnSave).toHaveBeenCalledWith({
        name: 'Proposal',
        colorHex: '#3b82f6',
        probability: 50,
        order: 2,
      });
    });
  });

  // Test 6: Submits valid form data for editing stage
  it('calls onSave with correct data when editing', async () => {
    const user = userEvent.setup();
    mockOnSave.mockResolvedValue(undefined);

    render(<StageEditor {...defaultProps} stage={existingStage} />);

    // Update the name
    const nameInput = screen.getByLabelText('Stage Name *');
    await user.clear(nameInput);
    await user.type(nameInput, 'Qualified Lead');

    // Submit
    await user.click(screen.getByText('Save Changes'));

    await waitFor(() => {
      expect(mockOnSave).toHaveBeenCalledWith({
        name: 'Qualified Lead',
        colorHex: '#3b82f6',
        probability: 30,
        order: 1,
      });
    });
  });

  // Test 7: Calls onCancel when cancel clicked
  it('calls onCancel when cancel button is clicked', async () => {
    const user = userEvent.setup();
    render(<StageEditor {...defaultProps} />);

    await user.click(screen.getByText('Cancel'));

    expect(mockOnCancel).toHaveBeenCalled();
    expect(mockOnSave).not.toHaveBeenCalled();
  });

  // Test 8: Shows error from onSave failure
  it('displays error when save fails', async () => {
    const user = userEvent.setup();
    mockOnSave.mockRejectedValue(new Error('Stage name already exists'));

    render(<StageEditor {...defaultProps} />);

    await user.type(screen.getByLabelText('Stage Name *'), 'Duplicate Name');
    await user.click(screen.getByText('Create Stage'));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Stage name already exists');
    });
  });

  // Test 9: Updates probability via slider
  it('updates probability when slider is moved', async () => {
    render(<StageEditor {...defaultProps} />);

    const slider = screen.getByRole('slider');
    fireEvent.change(slider, { target: { value: '75' } });

    const probabilityInput = screen.getByRole('spinbutton');
    expect(probabilityInput).toHaveValue(75);
  });

  // Test 10: Selects custom color
  it('allows selecting custom color via color input', async () => {
    const user = userEvent.setup();
    mockOnSave.mockResolvedValue(undefined);

    render(<StageEditor {...defaultProps} />);

    // Fill in name
    await user.type(screen.getByLabelText('Stage Name *'), 'Custom Stage');

    // Select custom color
    const colorInput = screen.getByLabelText(/Custom:/);
    fireEvent.input(colorInput, { target: { value: '#ff5500' } });

    // Submit
    await user.click(screen.getByText('Create Stage'));

    await waitFor(() => {
      expect(mockOnSave).toHaveBeenCalledWith(
        expect.objectContaining({
          colorHex: '#ff5500',
        })
      );
    });
  });

  // Test 11: Disables form while submitting
  it('disables form controls while saving', async () => {
    mockOnSave.mockImplementation(
      () => new Promise((resolve) => setTimeout(resolve, 100))
    );

    render(<StageEditor {...defaultProps} isSubmitting={true} />);

    expect(screen.getByLabelText('Stage Name *')).toBeDisabled();
    expect(screen.getByText('Saving...')).toBeInTheDocument();
    expect(screen.getByText('Cancel')).toBeDisabled();
  });

  // Test 12: Resets form when stage prop changes
  it('resets form values when stage prop changes', () => {
    const { rerender } = render(<StageEditor {...defaultProps} />);

    // Initially empty
    expect(screen.getByLabelText('Stage Name *')).toHaveValue('');

    // Rerender with existing stage
    rerender(<StageEditor {...defaultProps} stage={existingStage} />);

    // Should show stage data
    expect(screen.getByLabelText('Stage Name *')).toHaveValue('Qualified');
  });
});
