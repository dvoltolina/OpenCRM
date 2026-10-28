import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AdminDashboardPage } from '../AdminDashboardPage';

const {
  authState,
  navigateMock,
  useDealsMock,
  useLeadsMock,
  useAuditLogMock,
  useTeamMembersMock,
  usePendingApprovalsMock,
} = vi.hoisted(() => ({
  authState: { role: 'owner' },
  navigateMock: vi.fn(),
  useDealsMock: vi.fn(),
  useLeadsMock: vi.fn(),
  useAuditLogMock: vi.fn(),
  useTeamMembersMock: vi.fn(),
  usePendingApprovalsMock: vi.fn(),
}));

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => navigateMock,
  };
});

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      role: authState.role,
    },
  }),
}));

vi.mock('../../hooks', () => ({
  useDeals: (...args: unknown[]) => useDealsMock(...args),
  useLeads: (...args: unknown[]) => useLeadsMock(...args),
  usePipelines: () => ({
    pipelines: [{ id: 'pipeline-1', name: 'Revenue' }],
  }),
  useStages: () => ({
    stages: [{ id: 'stage-1', name: 'Qualified', probability: 60 }],
  }),
  useContacts: () => ({
    contacts: [],
  }),
  useModal: () => ({
    isOpen: false,
    data: null,
    open: vi.fn(),
    close: vi.fn(),
  }),
}));

vi.mock('../../hooks/useAuditLog', () => ({
  useAuditLog: (...args: unknown[]) => useAuditLogMock(...args),
}));

vi.mock('../../hooks/useTeamMembers', () => ({
  useTeamMembers: (...args: unknown[]) => useTeamMembersMock(...args),
}));

vi.mock('../../hooks/useTimeEntries', () => ({
  usePendingApprovals: (...args: unknown[]) => usePendingApprovalsMock(...args),
}));

vi.mock('../../components/dashboard', () => ({
  TeamLeaderboard: () => <div>Team Leaderboard</div>,
  ForecastVsGoal: () => <div>Forecast Vs Goal</div>,
}));

vi.mock('../../components/modals', () => ({
  CreateLeadModal: () => null,
  CreateDealModal: () => null,
}));

describe('AdminDashboardPage', () => {
  beforeEach(() => {
    authState.role = 'owner';
    useDealsMock.mockReturnValue({
      deals: [
        {
          id: 'deal-1',
          status: 'open',
          valueCents: 500000,
          stageId: 'stage-1',
          assigneeId: 'user-1',
          assigneeName: 'Owner User',
        },
      ],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    useLeadsMock.mockReturnValue({
      leads: [{ id: 'lead-1', status: 'converted' }],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    useAuditLogMock.mockReturnValue({
      entries: [
        {
          id: 'audit-1',
          entityType: 'deal',
          action: 'updated',
          userName: 'Owner User',
          timestamp: new Date('2026-03-20T10:00:00Z'),
        },
      ],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    useTeamMembersMock.mockReturnValue({
      members: [{ id: 'staff-1', displayName: 'Alex Rep' }],
      isLoading: false,
    });
    usePendingApprovalsMock.mockReturnValue({
      entries: [{ id: 'entry-1' }],
      isLoading: false,
      refresh: vi.fn(),
    });
  });

  it('shows an access denied state for non-admin roles', () => {
    authState.role = 'staff';

    render(
      <MemoryRouter>
        <AdminDashboardPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Access denied')).toBeInTheDocument();
  });

  it('renders the admin workspace with leadership stats and dashboard sections', () => {
    render(
      <MemoryRouter>
        <AdminDashboardPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Admin Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Manage Team')).toBeInTheDocument();
    expect(screen.getByText('Forecast Vs Goal')).toBeInTheDocument();
    expect(screen.getByText('Team Leaderboard')).toBeInTheDocument();
    expect(screen.getByText('Pending Approvals')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Last 30 days' })).toBeInTheDocument();
  });
});
