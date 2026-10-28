/**
 * PipelineSettings Component Tests
 * Agent CRM-20 Implementation
 */

import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PipelineSettings } from '../PipelineSettings';
import type { Pipeline, Stage } from '../../../types/models';

// Mock hooks
const mockCreatePipeline = vi.fn();
const mockUpdatePipeline = vi.fn();
const mockCreateStage = vi.fn();
const mockUpdateStage = vi.fn();
const mockReorderStages = vi.fn();
const mockSetDefaultPipeline = vi.fn();

// Mock AuthContext - default to admin user for existing tests
vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-admin',
      businessId: 'biz-123',
      email: 'admin@example.com',
      displayName: 'Admin User',
      role: 'admin',
      teamIds: ['team-a', 'team-b'],
      createdAt: new Date(),
    },
    businessId: 'biz-123',
  }),
}));

const mockPipelines: Pipeline[] = [
  {
    id: 'pipeline-1',
    name: 'Sales Pipeline',
    isDefault: true,
    isActive: true,
    ownerId: 'user-admin',
    ownerName: 'Admin User',
    teamIds: ['team-a'],
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: 'pipeline-2',
    name: 'Enterprise Pipeline',
    isDefault: false,
    isActive: true,
    ownerId: 'user-admin',
    ownerName: 'Admin User',
    teamIds: [],
    createdAt: new Date('2024-01-02'),
    updatedAt: new Date('2024-01-02'),
  },
];

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-1',
    name: 'Lead',
    colorHex: '#6366f1',
    order: 0,
    probability: 10,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'stage-2',
    pipelineId: 'pipeline-1',
    name: 'Qualified',
    colorHex: '#3b82f6',
    order: 1,
    probability: 30,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'stage-3',
    pipelineId: 'pipeline-1',
    name: 'Archived Stage',
    colorHex: '#64748b',
    order: 2,
    probability: 0,
    isActive: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

vi.mock('../../../hooks/usePipelines', () => ({
  usePipelines: () => ({
    pipelines: mockPipelines,
    createPipeline: mockCreatePipeline,
    updatePipeline: mockUpdatePipeline,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('../../../hooks/useStages', () => ({
  useStages: (pipelineId?: string) => ({
    stages: pipelineId === 'pipeline-1' ? mockStages : [],
    createStage: mockCreateStage,
    updateStage: mockUpdateStage,
    reorderStages: mockReorderStages,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('../../../hooks/useSettings', () => ({
  useSettings: () => ({
    settings: {
      businessId: 'biz-123',
      defaultPipelineId: 'pipeline-1',
      defaultCurrency: 'USD',
      leadScoringEnabled: false,
      dealRotting: { enabled: false, thresholdDays: 14 },
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    setDefaultPipeline: mockSetDefaultPipeline,
    isLoading: false,
    error: null,
  }),
}));

describe('PipelineSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Renders pipeline list
  it('renders pipeline list with all pipelines', () => {
    render(<PipelineSettings />);

    expect(screen.getByTestId('pipeline-settings')).toBeInTheDocument();
    expect(screen.getByTestId('pipeline-list')).toBeInTheDocument();

    // Check pipelines are rendered
    expect(screen.getByText('Sales Pipeline')).toBeInTheDocument();
    expect(screen.getByText('Enterprise Pipeline')).toBeInTheDocument();

    // Check default badge
    expect(screen.getByText('Default')).toBeInTheDocument();
  });

  // Test 2: Shows stages for selected pipeline
  it('shows stages when a pipeline is selected', () => {
    render(<PipelineSettings />);

    // Default pipeline should be selected automatically
    expect(screen.getByText('Stages for "Sales Pipeline"')).toBeInTheDocument();

    // Check active stages (there may be multiple stage lists - active and archived)
    expect(screen.getAllByTestId('stage-list').length).toBeGreaterThan(0);
    expect(screen.getByText('Lead')).toBeInTheDocument();
    expect(screen.getByText('Qualified')).toBeInTheDocument();

    // Check archived stages section
    expect(screen.getByText('Archived Stages')).toBeInTheDocument();
    expect(screen.getByText('Archived Stage')).toBeInTheDocument();
  });

  // Test 3: Creates new pipeline
  it('creates new pipeline with valid name', async () => {
    const user = userEvent.setup();
    mockCreatePipeline.mockResolvedValue({ id: 'new-pipeline', name: 'New Pipeline' });

    render(<PipelineSettings />);

    // Click new pipeline button
    await user.click(screen.getByText('+ New Pipeline'));

    // Fill in name
    const input = screen.getByPlaceholderText('Pipeline name');
    await user.type(input, 'New Pipeline');

    // Click create
    await user.click(screen.getByText('Create'));

    await waitFor(() => {
      expect(mockCreatePipeline).toHaveBeenCalledWith({
        name: 'New Pipeline',
        isDefault: false,
        isActive: true,
        teamIds: ['team-a', 'team-b'],
      });
    });
  });

  // Test 4: Shows error for empty pipeline name
  it('shows error when creating pipeline without name', async () => {
    const user = userEvent.setup();

    render(<PipelineSettings />);

    // Click new pipeline button
    await user.click(screen.getByText('+ New Pipeline'));

    // Click create without entering name
    await user.click(screen.getByText('Create'));

    expect(screen.getByRole('alert')).toHaveTextContent('Pipeline name is required');
    expect(mockCreatePipeline).not.toHaveBeenCalled();
  });

  it('updates team sharing with chip input', async () => {
    const user = userEvent.setup();
    mockUpdatePipeline.mockResolvedValue(undefined);

    render(<PipelineSettings />);

    const teamInput = screen.getByPlaceholderText('Add team ID and press Enter');
    await user.type(teamInput, 'team-c{enter}');
    await user.click(screen.getByText('Save Sharing'));

    await waitFor(() => {
      expect(mockUpdatePipeline).toHaveBeenCalledWith('pipeline-1', { teamIds: ['team-a', 'team-c'] });
    });
  });

  // Test 5: Sets pipeline as default
  it('sets a pipeline as default', async () => {
    const user = userEvent.setup();
    mockSetDefaultPipeline.mockResolvedValue(undefined);
    mockUpdatePipeline.mockResolvedValue(undefined);

    render(<PipelineSettings />);

    // Find the Enterprise Pipeline item and click Set Default
    const enterpriseItem = screen.getByTestId('pipeline-item-pipeline-2');
    const setDefaultBtn = within(enterpriseItem).getByTitle('Set as default');

    await user.click(setDefaultBtn);

    await waitFor(() => {
      expect(mockSetDefaultPipeline).toHaveBeenCalledWith('pipeline-2');
      expect(mockUpdatePipeline).toHaveBeenCalledWith('pipeline-2', { isDefault: true });
    });
  });

  // Test 6: Opens stage editor for new stage
  it('opens stage editor when add stage is clicked', async () => {
    const user = userEvent.setup();

    render(<PipelineSettings />);

    // Click add stage
    await user.click(screen.getByText('+ Add Stage'));

    // Stage editor should appear
    expect(screen.getByTestId('stage-editor')).toBeInTheDocument();
    expect(screen.getByText('New Stage')).toBeInTheDocument();
    expect(screen.getByLabelText('Stage Name *')).toBeInTheDocument();
  });

  // Test 7: Archives a pipeline
  it('archives a pipeline when archive button is clicked', async () => {
    const user = userEvent.setup();
    mockUpdatePipeline.mockResolvedValue(undefined);

    render(<PipelineSettings />);

    // Find the Enterprise Pipeline item and click Archive
    const enterpriseItem = screen.getByTestId('pipeline-item-pipeline-2');
    const archiveBtn = within(enterpriseItem).getByTitle('Archive');

    await user.click(archiveBtn);

    await waitFor(() => {
      expect(mockUpdatePipeline).toHaveBeenCalledWith('pipeline-2', { isActive: false });
    });
  });

  // Test 8: Selects different pipeline
  it('changes selected pipeline when clicked', async () => {
    const user = userEvent.setup();
    const onPipelineSelect = vi.fn();

    render(<PipelineSettings onPipelineSelect={onPipelineSelect} />);

    // Click Enterprise Pipeline
    await user.click(screen.getByText('Enterprise Pipeline'));

    expect(onPipelineSelect).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'pipeline-2',
        name: 'Enterprise Pipeline',
      })
    );

    // Header should update
    expect(screen.getByText('Stages for "Enterprise Pipeline"')).toBeInTheDocument();
  });

  // Test 9: Cancels pipeline creation
  it('cancels pipeline creation form', async () => {
    const user = userEvent.setup();

    render(<PipelineSettings />);

    // Open create form
    await user.click(screen.getByText('+ New Pipeline'));
    expect(screen.getByPlaceholderText('Pipeline name')).toBeInTheDocument();

    // Cancel
    await user.click(screen.getByText('Cancel'));

    // Form should be hidden
    expect(screen.queryByPlaceholderText('Pipeline name')).not.toBeInTheDocument();
  });

  // Test 10: Shows stage probability
  it('displays stage probability in stage list', () => {
    render(<PipelineSettings />);

    expect(screen.getByText('10% probability')).toBeInTheDocument();
    expect(screen.getByText('30% probability')).toBeInTheDocument();
  });
});
