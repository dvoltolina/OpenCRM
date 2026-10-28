import { render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TeamRoutePlanningPage } from '../TeamRoutePlanningPage';

const { teamRouteBuilderMock } = vi.hoisted(() => ({
  teamRouteBuilderMock: vi.fn(),
}));

function buildTeamRouteState() {
  return {
    selectedDate: new Date('2026-03-22T00:00:00Z'),
    setSelectedDate: vi.fn(),
    workingTeam: [
      {
        staff: { id: 'staff-1', displayName: 'Alex Rep' },
        schedule: { maxStopsPerDay: 8 },
        territories: [{ id: 'territory-1', name: 'North', colorHex: '#2563eb' }],
        selectedContacts: [{ id: 'contact-1', firstName: 'Jamie', lastName: 'West' }],
      },
    ],
    unassignedContacts: [{ id: 'contact-2', firstName: 'Taylor', lastName: 'Ray' }],
    allContacts: [
      { id: 'contact-1', firstName: 'Jamie', lastName: 'West' },
      { id: 'contact-2', firstName: 'Taylor', lastName: 'Ray' },
    ],
    isLoading: false,
    isSaving: false,
    error: null,
    assignContactToStaff: vi.fn(),
    removeContactFromStaff: vi.fn(),
    moveContactBetweenStaff: vi.fn(),
    autoAssignUnassigned: vi.fn(),
    clearStaffRoute: vi.fn(),
    clearAllRoutes: vi.fn(),
    saveAllRoutes: vi.fn(),
    saveSingleRoute: vi.fn(),
    conflicts: [{ staffId: 'staff-1', message: 'North territory is over capacity.' }],
    refresh: vi.fn(),
  };
}

vi.mock('../../hooks', () => ({
  useTeamRouteBuilder: (...args: unknown[]) => teamRouteBuilderMock(...args),
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

describe('TeamRoutePlanningPage', () => {
  beforeEach(() => {
    teamRouteBuilderMock.mockReturnValue(buildTeamRouteState());
  });

  it('renders the team routing workspace with conflicts and staff columns', () => {
    render(<TeamRoutePlanningPage />);

    expect(screen.getByText('Team Route Planning')).toBeInTheDocument();
    expect(screen.getByText('Balance assignments before routes hit the field.')).toBeInTheDocument();
    expect(screen.getByText('Conflicts detected')).toBeInTheDocument();
    expect(screen.getByText('North territory is over capacity.')).toBeInTheDocument();
    expect(screen.getByText('Unassigned Contacts (1)')).toBeInTheDocument();
    expect(screen.getByText('Alex Rep')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Save All Routes' })).toBeInTheDocument();
  });

  it('renders the empty state when no staff are scheduled', () => {
    teamRouteBuilderMock.mockReturnValue({
      ...buildTeamRouteState(),
      workingTeam: [],
      conflicts: [],
    });

    render(<TeamRoutePlanningPage />);

    expect(screen.getByText('No scheduled staff')).toBeInTheDocument();
  });
});
