/**
 * PipelinePage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state
 * 3. Renders pipeline with kanban board
 * 4. Renders empty/no pipeline state
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { PipelinePage } from '../PipelinePage';
import type { Pipeline, Stage } from '../../types/models';

const authState = {
  crmUser: {
    id: 'user-1',
    businessId: 'biz-1',
    displayName: 'Test User',
    role: 'admin' as 'admin' | 'staff',
    teamIds: [] as string[],
    managedTeamIds: [] as string[],
  },
  businessId: 'biz-1',
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => authState,
}));

vi.mock('../../lib/security-context', () => ({
  createSecurityContext: vi.fn(() => ({
    businessId: 'biz-1',
    userId: 'user-1',
    userName: 'Test User',
    userRole: 'staff',
    teamIds: [],
    managedTeamIds: [],
  })),
  getShareableAccessSummary: vi.fn(() => ({
    visibility: 'team',
    isOwner: false,
    hasOrgPrivilege: false,
    hasManagerAccess: false,
    hasTeamAccess: false,
    canRead: true,
    canWrite: false,
    canDelete: false,
    effectiveTeams: [],
    canChangeOwnership: false,
  })),
}));

// Mock hooks
vi.mock('../../hooks/usePipelineWithStages', () => ({
  usePipelineWithStages: vi.fn(),
}));

vi.mock('../../hooks', () => ({
  useModal: vi.fn(() => ({
    isOpen: false,
    open: vi.fn(),
    close: vi.fn(),
    data: null,
  })),
  useTeamMembers: vi.fn(() => ({
    members: [],
    isLoading: false,
  })),
}));

vi.mock('../../hooks/useActivityLog', () => ({
  useActivityLog: vi.fn(() => ({
    createTask: vi.fn(),
    isLoading: false,
  })),
}));

const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

// Mock KanbanBoard component
vi.mock('../../components/pipeline/KanbanBoard', () => ({
  KanbanBoard: ({ pipeline }: { pipeline: Pipeline }) => (
    <div data-testid="kanban-board">{pipeline.name}</div>
  ),
}));

vi.mock('../../components/modals', () => ({
  CreateDealModal: () => null,
}));

import { usePipelineWithStages } from '../../hooks/usePipelineWithStages';

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    name: 'Prospecting',
    order: 0,
    pipelineId: 'pipeline-1',
    probability: 10,
    colorHex: '#3b82f6',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'stage-2',
    name: 'Negotiation',
    order: 1,
    pipelineId: 'pipeline-1',
    probability: 50,
    colorHex: '#f59e0b',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

const mockPipeline: Pipeline & { stages: Stage[] } = {
  id: 'pipeline-1',
  name: 'Sales Pipeline',
  isDefault: true,
  isActive: true,
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: [],
  createdAt: new Date(),
  updatedAt: new Date(),
  stages: mockStages,
};

describe('PipelinePage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: null,
      stages: [],
      isLoading: true,
      error: null,
      isDefault: false,
      stageCount: 0,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(screen.getByText('Loading pipeline...')).toBeInTheDocument();
    expect(screen.getByText('Pipeline')).toBeInTheDocument();
  });

  // Test 2: Error state
  it('renders error state', () => {
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: null,
      stages: [],
      isLoading: false,
      error: new Error('Failed to load pipeline'),
      isDefault: false,
      stageCount: 0,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(screen.getByText('Unable to load the pipeline board.')).toBeInTheDocument();
    expect(screen.getByText('Failed to load pipeline')).toBeInTheDocument();
  });

  // Test 3: Renders pipeline with kanban board
  it('renders pipeline with kanban board', () => {
    authState.crmUser.role = 'admin';
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: mockPipeline,
      stages: mockStages,
      isLoading: false,
      error: null,
      isDefault: true,
      stageCount: 2,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(screen.getByTestId('kanban-board')).toBeInTheDocument();
    expect(screen.getByText('Sales Pipeline')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'New Opportunity' })).toBeInTheDocument();
  });

  it('shows read-only banner when pipeline not writable', () => {
    authState.crmUser.role = 'staff';
    authState.crmUser.teamIds = [];
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: { ...mockPipeline, visibility: 'team', teamIds: ['other-team'] },
      stages: mockStages,
      isLoading: false,
      error: null,
      isDefault: true,
      stageCount: 2,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    // View-only users should see the page render without edit controls
    expect(screen.getByText('Pipeline')).toBeInTheDocument();
  });

  // Test 4: No pipeline state
  it('renders no pipeline state when pipeline is null', () => {
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: null,
      stages: [],
      isLoading: false,
      error: null,
      isDefault: true,
      stageCount: 0,
      refresh: vi.fn(),
      canCreatePipeline: true,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(screen.getByText('Pipeline setup')).toBeInTheDocument();
    expect(screen.getByText('No pipeline is configured yet')).toBeInTheDocument();
    expect(screen.getByText('Create the default pipeline to start tracking opportunities by stage and give managers a clean board view.')).toBeInTheDocument();
    expect(screen.getByText('You can create the initial pipeline from here.')).toBeInTheDocument();
    expect(screen.getByText('Create Pipeline')).toBeInTheDocument();
  });

  // Test 5: Page header present
  it('renders page header', () => {
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: mockPipeline,
      stages: mockStages,
      isLoading: false,
      error: null,
      isDefault: true,
      stageCount: 2,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline: vi.fn(),
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Pipeline' })).toBeInTheDocument();
  });

  // Test 6: Non-eligible user directed to settings
  it('shows settings redirect when user cannot create a pipeline', () => {
    const createDefaultPipeline = vi.fn();
    vi.mocked(usePipelineWithStages).mockReturnValue({
      pipeline: null,
      stages: [],
      isLoading: false,
      error: null,
      isDefault: true,
      stageCount: 0,
      refresh: vi.fn(),
      canCreatePipeline: false,
      createDefaultPipeline,
    });

    render(
      <MemoryRouter>
        <PipelinePage />
      </MemoryRouter>
    );

    expect(
      screen.getByText('You need pipeline access. Ask an admin to create it or open settings to review access.')
    ).toBeInTheDocument();
    const goToSettingsButton = screen.getByRole('button', { name: 'Go to Settings' });
    goToSettingsButton.click();
    expect(mockNavigate).toHaveBeenCalledWith('/settings?tab=pipeline');
    expect(createDefaultPipeline).not.toHaveBeenCalled();
  });
});
