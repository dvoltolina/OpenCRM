/**
 * DashboardPage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state with retry
 * 3. Renders KPI cards
 * 4. Renders dashboard sections
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { DashboardPage } from '../DashboardPage';
import type { Deal, SalesActivity } from '../../types/models';

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => vi.fn(),
  };
});

// Mock AuthContext
vi.mock('../../context/AuthContext', () => ({
    useAuth: vi.fn(() => ({
      businessId: 'biz-1',
      crmUser: {
        id: 'user-1',
        role: 'sales',
        businessId: 'biz-1',
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
  })),
}));

// Mock hooks
vi.mock('../../hooks', async () => {
  const actual = await vi.importActual<typeof import('../../hooks')>('../../hooks');
  return {
    ...actual,
    useDashboardData: vi.fn(),
    useModal: vi.fn(() => ({
      isOpen: false,
      open: vi.fn(),
      close: vi.fn(),
      data: null,
    })),
    usePipelines: vi.fn(() => ({ pipelines: [] })),
    useStages: vi.fn(() => ({ stages: [] })),
    useContacts: vi.fn(() => ({ contacts: [] })),
  };
});

vi.mock('../../components/modals', () => ({
  CreateLeadModal: () => null,
  CreateDealModal: () => null,
  LogActivityModal: () => null,
}));

import { useDashboardData } from '../../hooks';

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    title: 'Big Enterprise Deal',
    valueCents: 500000,
    currency: 'USD',
    status: 'open',
    stageId: 'stage-1',
    pipelineId: 'pipeline-1',
    probability: 75,
    tags: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'deal-2',
    title: 'Medium Deal',
    valueCents: 100000,
    currency: 'USD',
    status: 'open',
    stageId: 'stage-2',
    pipelineId: 'pipeline-1',
    probability: 50,
    tags: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

const mockActivities: SalesActivity[] = [
  {
    id: 'activity-1',
    type: 'call',
    title: 'Sales Call',
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date(),
    updatedAt: new Date(),
    isCompleted: false,
  },
];

const mockKpis = {
  totalPipelineValue: 600000,
  dealsWonThisMonth: 3,
  dealsWonValue: 150000,
  conversionRate: 25.5,
  averageDealSize: 75000,
  dealsByStage: [
    { stageId: 'stage-1', stageName: 'Prospecting', count: 5, value: 200000 },
    { stageId: 'stage-2', stageName: 'Negotiation', count: 3, value: 150000 },
  ],
  leadsThisMonth: 10,
  leadsConverted: 5,
};

const mockUpcomingTasks: SalesActivity[] = [
  {
    id: 'task-1',
    type: 'task',
    title: 'Follow up with client',
    dueDate: new Date('2025-02-01'),
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date(),
    updatedAt: new Date(),
    isCompleted: false,
  },
];

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: [],
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: [],
      isLoading: true,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('Loading dashboard...')).toBeInTheDocument();
    expect(screen.getByText('Sales Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Welcome back, Test User.')).toBeInTheDocument();
  });

  // Test 2: Error state with retry
  it('renders error state with retry button', () => {
    const mockRefresh = vi.fn();
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: [],
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: [],
      isLoading: false,
      error: new Error('Failed to load dashboard'),
      refresh: mockRefresh,
    });

    render(<DashboardPage />);

    expect(screen.getByText(/Error loading dashboard/)).toBeInTheDocument();

    const retryButton = screen.getByText('Retry');
    fireEvent.click(retryButton);
    expect(mockRefresh).toHaveBeenCalled();
  });

  // Test 3: Renders KPI cards
  it('renders KPI cards with data', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: mockDeals,
      leads: [],
      stages: [],
      upcomingTasks: mockUpcomingTasks,
      recentActivities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('My Pipeline')).toBeInTheDocument();
    expect(screen.getByText('Won This Month')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument(); // dealsWonThisMonth
    expect(screen.getByText('Conversion Rate')).toBeInTheDocument();
    expect(screen.getByText('25.5%')).toBeInTheDocument();
    expect(screen.getByText('Avg Deal Size')).toBeInTheDocument();
  });

  // Test 4: Renders dashboard sections
  it('renders dashboard sections', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: mockDeals,
      leads: [],
      stages: [],
      upcomingTasks: mockUpcomingTasks,
      recentActivities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('My Pipeline by Stage')).toBeInTheDocument();
    expect(screen.getByText('Recent Activities')).toBeInTheDocument();
    expect(screen.getByText('My Top Opportunities')).toBeInTheDocument();
    expect(screen.getByText('Upcoming Tasks')).toBeInTheDocument();
  });

  // Test 5: Shows stage data
  it('renders pipeline stages', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: mockDeals,
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('Prospecting')).toBeInTheDocument();
    expect(screen.getByText('5 opportunities')).toBeInTheDocument();
    expect(screen.getByText('Negotiation')).toBeInTheDocument();
    expect(screen.getByText('3 opportunities')).toBeInTheDocument();
  });

  // Test 6: Shows top deals
  it('renders top deals', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: mockDeals,
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('Big Enterprise Deal')).toBeInTheDocument();
    expect(screen.getByText('Medium Deal')).toBeInTheDocument();
  });

  // Test 7: Shows empty states
  it('shows empty state messages when no data', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: {
        ...mockKpis,
        dealsByStage: [],
      },
      deals: [],
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('No pipeline stages configured')).toBeInTheDocument();
    expect(screen.getByText('No recent activities')).toBeInTheDocument();
    expect(screen.getByText('No open opportunities')).toBeInTheDocument();
    expect(screen.getByText('No upcoming tasks')).toBeInTheDocument();
  });

  // Test 8: Shows recent activities
  it('renders recent activities', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: mockDeals,
      leads: [],
      stages: [],
      upcomingTasks: [],
      recentActivities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('Sales Call')).toBeInTheDocument();
  });

  // Test 9: Shows upcoming tasks
  it('renders upcoming tasks', () => {
    vi.mocked(useDashboardData).mockReturnValue({
      kpis: mockKpis,
      deals: [],
      leads: [],
      stages: [],
      upcomingTasks: mockUpcomingTasks,
      recentActivities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<DashboardPage />);

    expect(screen.getByText('Follow up with client')).toBeInTheDocument();
  });
});
