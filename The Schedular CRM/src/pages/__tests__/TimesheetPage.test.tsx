import { render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TimesheetPage } from '../TimesheetPage';

const { authState, pendingApprovalsMock, timeEntriesMock } = vi.hoisted(() => ({
  authState: {
    role: 'owner',
  },
  pendingApprovalsMock: vi.fn(),
  timeEntriesMock: vi.fn(),
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      role: authState.role,
    },
  }),
}));

vi.mock('../../hooks', () => ({
  useTimeEntries: (...args: unknown[]) => timeEntriesMock(...args),
  usePendingApprovals: (...args: unknown[]) => pendingApprovalsMock(...args),
  useTimeEntryMutations: () => ({
    approve: vi.fn(),
    reject: vi.fn(),
    bulkApprove: vi.fn(),
    isLoading: false,
  }),
  formatMinutesAsTime: (minutes: number) => `${minutes}m`,
  formatMinutesAsDecimal: (minutes: number) => (minutes / 60).toFixed(1),
  calculateOvertimeMinutes: () => ({ regularMinutes: 480, overtimeMinutes: 60 }),
  generatePayrollCSV: vi.fn(() => 'csv'),
  downloadCSV: vi.fn(),
  useModal: () => ({
    isOpen: false,
    data: null,
    open: vi.fn(),
    close: vi.fn(),
  }),
}));

vi.mock('../../components/modals', () => ({
  ConfirmDialog: () => null,
}));

describe('TimesheetPage', () => {
  beforeEach(() => {
    authState.role = 'owner';
    pendingApprovalsMock.mockReturnValue({
      entries: [
        {
          id: 'entry-1',
          staffId: 'staff-1',
          clockInTime: new Date('2026-03-16T08:00:00Z'),
          clockOutTime: new Date('2026-03-16T17:00:00Z'),
          breakMinutes: 30,
          workedMinutes: 510,
          clockInOutsideGeofence: false,
          clockInAddress: '123 Main Street',
        },
      ],
      count: 1,
      isLoading: false,
      refresh: vi.fn(),
    });
    timeEntriesMock.mockReturnValue({
      entries: [
        {
          id: 'entry-1',
          staffId: 'staff-1',
          clockInTime: new Date('2026-03-16T08:00:00Z'),
          clockOutTime: new Date('2026-03-16T17:00:00Z'),
          breakMinutes: 30,
          workedMinutes: 510,
          status: 'approved',
        },
      ],
      isLoading: false,
      refresh: vi.fn(),
    });
  });

  it('renders the pending approval view for approvers', () => {
    render(<TimesheetPage />);

    expect(screen.getByText('Pending Approval (1)')).toBeInTheDocument();
    expect(screen.getByText('Approve All (1)')).toBeInTheDocument();
    expect(screen.getByText('staff-1')).toBeInTheDocument();
  });

  it('defaults managers to the weekly view instead of the hidden pending tab', () => {
    authState.role = 'manager';

    render(<TimesheetPage />);

    expect(screen.getByText('Weekly View')).toBeInTheDocument();
    expect(screen.getByText('Total Worked')).toBeInTheDocument();
    expect(screen.queryByText(/Pending Approval/)).not.toBeInTheDocument();
  });

  it('shows the restricted state for non-manager staff users', () => {
    authState.role = 'staff';

    render(<TimesheetPage />);

    expect(screen.getByText('You do not have permission to view timesheets')).toBeInTheDocument();
  });
});
