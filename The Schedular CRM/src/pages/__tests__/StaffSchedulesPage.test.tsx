import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { StaffSchedulesPage } from '../StaffSchedulesPage';

const {
  useTeamMembersMock,
  useStaffSchedulesMock,
  createScheduleMock,
} = vi.hoisted(() => ({
  useTeamMembersMock: vi.fn(),
  useStaffSchedulesMock: vi.fn(),
  createScheduleMock: vi.fn(),
}));

vi.mock('../../hooks', () => ({
  useTeamMembers: (...args: unknown[]) => useTeamMembersMock(...args),
  useStaffSchedules: (...args: unknown[]) => useStaffSchedulesMock(...args),
  useStaffScheduleMutations: () => ({
    createSchedule: createScheduleMock,
    updateSchedule: vi.fn(),
    deleteSchedule: vi.fn(),
    updateWeeklyPatterns: vi.fn(),
    addException: vi.fn(),
    removeException: vi.fn(),
    isLoading: false,
  }),
  useModal: () => ({
    isOpen: false,
    data: null,
    open: vi.fn(),
    close: vi.fn(),
  }),
  createDefaultWeeklyPatterns: () => [],
}));

vi.mock('../../components/schedules', () => ({
  WeeklyPatternEditor: () => <div>Weekly Pattern Editor</div>,
  ExceptionList: () => <div>Exception List</div>,
}));

vi.mock('../../components/modals', () => ({
  ConfirmDialog: () => null,
}));

describe('StaffSchedulesPage', () => {
  beforeEach(() => {
    createScheduleMock.mockReset();
    useTeamMembersMock.mockReturnValue({
      members: [
        {
          id: 'staff-1',
          displayName: 'Alex Rep',
          email: 'alex@example.com',
        },
      ],
      isLoading: false,
    });
    useStaffSchedulesMock.mockReturnValue({
      schedules: [
        {
          id: 'schedule-1',
          staffId: 'staff-1',
          timezone: 'America/Denver',
          weeklyPatterns: [],
          exceptions: [],
        },
      ],
      isLoading: false,
      refresh: vi.fn(),
    });
  });

  it('renders the schedule editor for a selected staff member with an existing schedule', () => {
    render(<StaffSchedulesPage />);

    fireEvent.click(screen.getByText('Alex Rep'));

    expect(screen.getByText('Staff Schedules')).toBeInTheDocument();
    expect(screen.getByText("Alex Rep's Schedule")).toBeInTheDocument();
    expect(screen.getByText('Weekly Pattern Editor')).toBeInTheDocument();
    expect(screen.getByText('Exception List')).toBeInTheDocument();
  });

  it('renders the create-schedule state when a selected staff member has no schedule', () => {
    useStaffSchedulesMock.mockReturnValue({
      schedules: [],
      isLoading: false,
      refresh: vi.fn(),
    });

    render(<StaffSchedulesPage />);

    fireEvent.click(screen.getByText('Alex Rep'));

    expect(screen.getByText('Alex Rep has no schedule yet')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Create Schedule' })).toBeInTheDocument();
  });
});
