/**
 * DealDetail Component Tests
 *
 * Agent CRM-17 Implementation
 *
 * Test Scenarios:
 * 1. Displays deal information
 * 2. Shows stage progress
 * 3. Client/company links work
 * 4. Won/Lost actions work
 */

import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { DealDetail } from '../DealDetail';
import type { Deal, Stage, Pipeline } from '../../../types/models';

// ============================================
// Setup
// ============================================

// Mock createPortal to render in the same container
vi.mock('react-dom', async () => {
  const actual = await vi.importActual('react-dom');
  return {
    ...actual,
    createPortal: (node: React.ReactNode) => node,
  };
});

// Mock hooks
vi.mock('../../../hooks', () => ({
  useDeal: vi.fn(),
  useTimeline: vi.fn(),
  usePipelineWithStages: vi.fn(),
  useCalendarSync: vi.fn(() => ({
    enabled: false,
    configured: false,
    contextReady: false,
    connections: [],
    conflicts: [],
    activityStatuses: {},
    loading: false,
    error: null,
    refresh: vi.fn(),
    startOAuth: vi.fn(),
    connectWithCode: vi.fn(),
    disconnect: vi.fn(),
    refreshTokens: vi.fn(),
    syncConnection: vi.fn(),
    syncActivity: vi.fn(),
    resolveConflict: vi.fn(),
    updateSettings: vi.fn(),
  })),
  useDocuments: vi.fn(() => ({
    documents: [],
    folders: [],
    isLoading: false,
    isUploading: false,
    error: null,
    refreshDocuments: vi.fn(),
    refreshFolders: vi.fn(),
    uploadDocument: vi.fn(),
    createFolder: vi.fn(),
    moveToFolder: vi.fn(),
    generatePublicLink: vi.fn(),
    revokePublicLink: vi.fn(),
  })),
}));

vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    businessId: 'biz-1',
    crmUser: {
      id: 'user-1',
      role: 'admin',
      displayName: 'Test User',
      email: 'test@example.com',
      teamIds: [],
      managedTeamIds: [],
      managerId: undefined,
    },
    user: null,
    loading: false,
    isAuthenticated: true,
    signOut: vi.fn(),
  }),
  AuthProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

vi.mock('../../scheduler', () => ({
  AIInsightsCard: ({ clientId }: { clientId: string }) => <div>AI Insights for {clientId}</div>,
  AppointmentList: ({ clientId }: { clientId: string }) => <div>Appointments for {clientId}</div>,
  CommHistory: ({ clientId }: { clientId: string }) => <div>Communication History for {clientId}</div>,
  UpcomingAppointments: ({ clientId }: { clientId: string }) => <div>Upcoming Appointments for {clientId}</div>,
}));

vi.mock('../../../hooks/useEntitySequenceStatus', () => ({
  useEntitySequenceStatus: () => ({
    canEnroll: false,
    activeEnrollment: null,
    isSequencesEnabled: false,
    refresh: vi.fn(),
  }),
}));

vi.mock('../../sequences/EntitySequenceHistory', () => ({
  EntitySequenceHistory: () => <div>Sequence History</div>,
}));

vi.mock('../../sequences/EnrollmentModal', () => ({
  EnrollmentModal: () => null,
}));

// Import hooks after mocking
import { useDeal, useTimeline, usePipelineWithStages } from '../../../hooks';

const mockDeal: Deal = {
  id: 'deal-1',
  pipelineId: 'pipeline-1',
  stageId: 'stage-2',
  title: 'Enterprise Deal',
  valueCents: 5000000, // $50,000
  currency: 'USD',
  probability: 75,
  expectedCloseDate: new Date('2024-03-01'),
  status: 'open',
  clientId: 'client-1',
  clientName: 'John Doe',
  companyId: 'company-1',
  companyName: 'Acme Corp',
  assigneeName: 'Jane Smith',
  tags: ['enterprise', 'priority'],
  notes: 'High-value opportunity',
  createdAt: new Date('2024-01-15'),
  updatedAt: new Date('2024-01-16'),
};

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-1',
    name: 'Qualification',
    order: 0,
    colorHex: '#3b82f6',
    probability: 25,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
  {
    id: 'stage-2',
    pipelineId: 'pipeline-1',
    name: 'Proposal',
    order: 1,
    colorHex: '#8b5cf6',
    probability: 50,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
  {
    id: 'stage-3',
    pipelineId: 'pipeline-1',
    name: 'Negotiation',
    order: 2,
    colorHex: '#10b981',
    probability: 75,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
];

const mockPipeline: Pipeline = {
  id: 'pipeline-1',
  name: 'Sales Pipeline',
  isDefault: true,
  isActive: true,
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: [],
  createdAt: new Date('2024-01-01'),
};

const pipelineHookState = (
  overrides: Partial<ReturnType<typeof usePipelineWithStages>> = {}
) => ({
  pipeline: mockPipeline,
  stages: mockStages,
  isLoading: false,
  error: null,
  isDefault: true,
  stageCount: mockStages.length,
  refresh: vi.fn(),
  canCreatePipeline: false,
  createDefaultPipeline: vi.fn(),
  ...overrides,
});

describe('DealDetail', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Displays deal information
  // ============================================
  it('displays deal information', () => {
    vi.mocked(useDeal).mockReturnValue({
      deal: mockDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(<DealDetail dealId="deal-1" />);

    // Check title
    expect(screen.getByText('Enterprise Deal')).toBeInTheDocument();

    // Check formatted value (appears in both header and details)
    expect(screen.getAllByText('$50,000.00').length).toBeGreaterThan(0);

    // Check probability
    expect(screen.getByText('75%')).toBeInTheDocument();

    // Check client name
    expect(screen.getByText('John Doe')).toBeInTheDocument();

    // Check company name
    expect(screen.getByText('Acme Corp')).toBeInTheDocument();

    // Check notes
    expect(screen.getByText('High-value opportunity')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Shows stage progress
  // ============================================
  it('shows pipeline progress for open deals', () => {
    vi.mocked(useDeal).mockReturnValue({
      deal: mockDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(<DealDetail dealId="deal-1" />);

    // Check pipeline progress section exists
    expect(screen.getByText('Pipeline Progress')).toBeInTheDocument();

    // Check all stage names are displayed (may appear in badge and progress)
    expect(screen.getByText('Qualification')).toBeInTheDocument();
    expect(screen.getAllByText('Proposal').length).toBeGreaterThan(0);
    expect(screen.getByText('Negotiation')).toBeInTheDocument();
  });

  it('hides pipeline progress for closed deals', () => {
    const closedDeal = { ...mockDeal, status: 'won' as const };

    vi.mocked(useDeal).mockReturnValue({
      deal: closedDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(<DealDetail dealId="deal-1" />);

    // Pipeline progress should not exist for closed deals
    expect(screen.queryByText('Pipeline Progress')).not.toBeInTheDocument();
  });

  // ============================================
  // Test 3: Client/company links work
  // ============================================
  it('renders client and company as clickable links', () => {
    const mockOnClientClick = vi.fn();
    const mockOnCompanyClick = vi.fn();

    vi.mocked(useDeal).mockReturnValue({
      deal: mockDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(
      <DealDetail
        dealId="deal-1"
        onClientClick={mockOnClientClick}
        onCompanyClick={mockOnCompanyClick}
      />
    );

    // Click client link
    const clientLink = screen.getByRole('button', { name: 'John Doe' });
    fireEvent.click(clientLink);
    expect(mockOnClientClick).toHaveBeenCalledWith('client-1');

    // Click company link
    const companyLink = screen.getByRole('button', { name: 'Acme Corp' });
    fireEvent.click(companyLink);
    expect(mockOnCompanyClick).toHaveBeenCalledWith('company-1');
  });

  it('shows scheduler context for linked clients', () => {
    vi.mocked(useDeal).mockReturnValue({
      deal: mockDeal,
      stage: mockStages[1],
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(<DealDetail dealId="deal-1" />);

    expect(screen.getByText('Scheduler')).toBeInTheDocument();
    expect(screen.getByText('Upcoming Appointments for client-1')).toBeInTheDocument();
    expect(screen.getByText('AI Insights for client-1')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('tab', { name: 'Scheduler' }));

    expect(screen.getAllByText('Upcoming Appointments for client-1').length).toBeGreaterThan(0);
    expect(screen.getByText('Appointments for client-1')).toBeInTheDocument();
    expect(screen.getByText('Communication History for client-1')).toBeInTheDocument();
  });

  it('shows an explicit scheduler fallback when no client is linked', () => {
    const dealWithoutClient: Deal = {
      ...mockDeal,
      clientId: undefined,
      clientName: undefined,
      clientEmail: undefined,
    };

    vi.mocked(useDeal).mockReturnValue({
      deal: dealWithoutClient,
      stage: mockStages[1],
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(<DealDetail dealId="deal-1" />);

    expect(screen.queryByText('Scheduler')).not.toBeInTheDocument();
    expect(
      screen.getByText(/Link a contact to this deal to view appointments, communication history, and AI insights/)
    ).toBeInTheDocument();
  });

  // ============================================
  // Test 4: Won/Lost actions work
  // ============================================
  it('shows won and lost actions for open deals', () => {
    const mockOnMarkWon = vi.fn();
    const mockOnMarkLost = vi.fn();

    vi.mocked(useDeal).mockReturnValue({
      deal: mockDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(
      <DealDetail dealId="deal-1" onMarkWon={mockOnMarkWon} onMarkLost={mockOnMarkLost} />
    );

    // Check both buttons exist
    expect(screen.getByText('Mark Won')).toBeInTheDocument();
    expect(screen.getByText('Mark Lost')).toBeInTheDocument();
  });

  it('hides won/lost actions for closed deals', () => {
    const closedDeal = { ...mockDeal, status: 'won' as const };
    const mockOnMarkWon = vi.fn();
    const mockOnMarkLost = vi.fn();

    vi.mocked(useDeal).mockReturnValue({
      deal: closedDeal,
      stage: mockStages[1], // Proposal stage
      client: null,
      company: null,
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(useTimeline).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    vi.mocked(usePipelineWithStages).mockReturnValue({
      ...pipelineHookState(),
    });

    render(
      <DealDetail dealId="deal-1" onMarkWon={mockOnMarkWon} onMarkLost={mockOnMarkLost} />
    );

    // Won/Lost buttons should not exist for closed deals
    expect(screen.queryByText('Mark Won')).not.toBeInTheDocument();
    expect(screen.queryByText('Mark Lost')).not.toBeInTheDocument();
  });
});
