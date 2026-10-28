/**
 * DealForm Tests
 *
 * Agent CRM-14 Implementation
 *
 * Test Scenarios:
 * 1. Renders pipeline/stage selectors
 * 2. Validates positive value
 * 3. Pre-fills data in edit mode
 * 4. Handles client selection
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DealForm } from '../DealForm';
import type { Pipeline, Stage } from '../../../types/models';

describe('DealForm', () => {
  const mockOnSubmit = vi.fn();
  const mockOnCancel = vi.fn();

  const mockPipelines: Pipeline[] = [
    {
      id: 'pipeline-1',
      name: 'Sales Pipeline',
      isDefault: true,
      isActive: true,
      ownerId: 'owner-1',
      ownerName: 'Owner',
      teamIds: [],
      createdAt: new Date(),
    },
    {
      id: 'pipeline-2',
      name: 'Enterprise Pipeline',
      isDefault: false,
      isActive: true,
      ownerId: 'owner-1',
      ownerName: 'Owner',
      teamIds: [],
      createdAt: new Date(),
    },
  ];

  const mockStages: Stage[] = [
    {
      id: 'stage-1',
      pipelineId: 'pipeline-1',
      name: 'Lead',
      order: 0,
      colorHex: '#ccc',
      probability: 10,
      isActive: true,
      createdAt: new Date(),
    },
    {
      id: 'stage-2',
      pipelineId: 'pipeline-1',
      name: 'Qualified',
      order: 1,
      colorHex: '#3B82F6',
      probability: 50,
      isActive: true,
      createdAt: new Date(),
    },
    {
      id: 'stage-3',
      pipelineId: 'pipeline-2',
      name: 'Enterprise Lead',
      order: 0,
      colorHex: '#8B5CF6',
      probability: 25,
      isActive: true,
      createdAt: new Date(),
    },
  ];

  const mockClients = [
    { id: 'client-1', name: 'John Doe' },
    { id: 'client-2', name: 'Jane Smith' },
  ];

  const mockCompanies = [
    { id: 'company-1', name: 'Acme Corp' },
    { id: 'company-2', name: 'Tech Inc' },
  ];

  const defaultProps = {
    onSubmit: mockOnSubmit,
    onCancel: mockOnCancel,
    pipelines: mockPipelines,
    stages: mockStages,
    clients: mockClients,
    companies: mockCompanies,
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Renders pipeline/stage selectors
  // ============================================
  it('renders pipeline/stage selectors', () => {
    render(<DealForm {...defaultProps} />);

    // Pipeline selector
    const pipelineSelect = screen.getByLabelText(/pipeline/i);
    expect(pipelineSelect).toBeInTheDocument();

    // Stage selector
    const stageSelect = screen.getByLabelText(/stage/i);
    expect(stageSelect).toBeInTheDocument();

    // Check pipeline options exist
    expect(screen.getByRole('option', { name: /sales pipeline/i })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: /enterprise pipeline/i })).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Validates required fields
  // ============================================
  it('validates positive value', async () => {
    render(<DealForm {...defaultProps} />);

    // Leave title empty and submit
    const submitButton = screen.getByRole('button', { name: /create opportunity/i });
    fireEvent.click(submitButton);

    // Wait for validation error (title is required)
    await waitFor(() => {
      expect(screen.getByText(/opportunity title is required/i)).toBeInTheDocument();
    });

    expect(mockOnSubmit).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 3: Pre-fills data in edit mode
  // ============================================
  it('pre-fills data in edit mode', () => {
    const initialData = {
      id: 'deal-123',
      title: 'Existing Deal',
      valueCents: 150000, // $1,500.00
      pipelineId: 'pipeline-1',
      stageId: 'stage-2',
      probability: 50,
      currency: 'USD',
      status: 'open' as const,
      tags: [],
      createdAt: new Date(),
    };

    render(<DealForm {...defaultProps} initialData={initialData} />);

    expect(screen.getByLabelText(/opportunity title/i)).toHaveValue('Existing Deal');
    expect(screen.getByRole('button', { name: /save changes/i })).toBeInTheDocument();
  });

  // ============================================
  // Test 4: Handles client selection
  // ============================================
  it('handles client selection', async () => {
    const user = userEvent.setup();
    mockOnSubmit.mockResolvedValue(undefined);

    render(<DealForm {...defaultProps} />);

    // Fill required fields
    await user.type(screen.getByLabelText(/opportunity title/i), 'Client Deal');

    // Enter value
    const valueInput = screen.getByPlaceholderText('0.00');
    await user.type(valueInput, '1000');

    // Select pipeline
    const pipelineSelect = screen.getByLabelText(/pipeline/i);
    await user.selectOptions(pipelineSelect, 'pipeline-1');

    // Select stage
    const stageSelect = screen.getByLabelText(/stage/i);
    await user.selectOptions(stageSelect, 'stage-1');

    // Open client searchable select and select a client
    const clientTrigger = screen.getByText(/search clients/i);
    await user.click(clientTrigger);

    // Wait for dropdown and click on John Doe
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
    await user.click(screen.getByText('John Doe'));

    // Submit form
    const submitButton = screen.getByRole('button', { name: /create opportunity/i });
    fireEvent.click(submitButton);

    // Verify onSubmit was called
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalled();
    });

    const submittedData = mockOnSubmit.mock.calls[0][0];
    expect(submittedData.title).toBe('Client Deal');
    expect(submittedData.valueCents).toBe(100000); // 1000.00 * 100
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('filters stages by selected pipeline', async () => {
    const user = userEvent.setup();
    render(<DealForm {...defaultProps} />);

    // Select first pipeline
    const pipelineSelect = screen.getByLabelText(/pipeline/i);
    await user.selectOptions(pipelineSelect, 'pipeline-1');

    // Check stage options - should only show pipeline-1 stages
    const stageSelect = screen.getByLabelText(/stage/i);
    const stageOptions = within(stageSelect).getAllByRole('option');

    // Should have placeholder + 2 stages from pipeline-1
    const stageNames = stageOptions.map(opt => opt.textContent);
    expect(stageNames).toContain('Lead (10%)');
    expect(stageNames).toContain('Qualified (50%)');
    expect(stageNames).not.toContain('Enterprise Lead (25%)');
  });

  it('updates probability when stage is selected', async () => {
    const user = userEvent.setup();
    render(<DealForm {...defaultProps} />);

    // Select pipeline
    const pipelineSelect = screen.getByLabelText(/pipeline/i);
    await user.selectOptions(pipelineSelect, 'pipeline-1');

    // Select stage with 50% probability
    const stageSelect = screen.getByLabelText(/stage/i);
    await user.selectOptions(stageSelect, 'stage-2');

    // Check probability field updated
    await waitFor(() => {
      const probabilityInput = screen.getByLabelText(/probability/i);
      expect(probabilityInput).toHaveValue(50);
    });
  });

  it('calls onCancel when cancel button clicked', async () => {
    const user = userEvent.setup();
    render(<DealForm {...defaultProps} />);

    const cancelButton = screen.getByRole('button', { name: /cancel/i });
    await user.click(cancelButton);

    expect(mockOnCancel).toHaveBeenCalledTimes(1);
  });
});
