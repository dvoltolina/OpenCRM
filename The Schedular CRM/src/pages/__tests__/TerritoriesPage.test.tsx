import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TerritoriesPage } from '../TerritoriesPage';

const { territoriesState, useTerritoriesMock, useTeamMembersMock } = vi.hoisted(() => ({
  territoriesState: {
    territories: [
      {
        id: 'territory-1',
        name: 'North Region',
        description: 'Northern accounts',
        colorHex: '#3b82f6',
        boundary: { type: 'zip_codes', zipCodes: ['80001', '80002'] },
        assignments: [{ id: 'assignment-1' }],
        enableAutoSuggestion: true,
        loadBalancingEnabled: false,
        isActive: true,
      },
    ],
  },
  useTerritoriesMock: vi.fn(),
  useTeamMembersMock: vi.fn(),
}));

const refreshMock = vi.fn();
const createTerritoryMock = vi.fn();

vi.mock('../../hooks', () => ({
  useTerritories: (...args: unknown[]) => useTerritoriesMock(...args),
  useTerritoryMutations: () => ({
    createTerritory: createTerritoryMock,
    updateTerritory: vi.fn(),
    deleteTerritory: vi.fn(),
    isLoading: false,
  }),
  useTeamMembers: (...args: unknown[]) => useTeamMembersMock(...args),
  useModal: () => ({
    isOpen: false,
    data: null,
    open: vi.fn(),
    close: vi.fn(),
  }),
}));

vi.mock('../../components/territories', () => ({
  BoundaryEditor: () => <div>Boundary Editor</div>,
  StaffAssignmentPanel: () => <div>Staff Assignment Panel</div>,
}));

vi.mock('../../components/modals', () => ({
  ConfirmDialog: () => null,
}));

describe('TerritoriesPage', () => {
  beforeEach(() => {
    refreshMock.mockReset();
    createTerritoryMock.mockReset();
    useTerritoriesMock.mockReturnValue({
      territories: territoriesState.territories,
      isLoading: false,
      refresh: refreshMock,
    });
    useTeamMembersMock.mockReturnValue({
      members: [{ id: 'member-1', name: 'Staff User' }],
      isLoading: false,
    });
  });

  it('renders the territory workspace and selects an existing territory', () => {
    render(<TerritoriesPage />);

    expect(screen.getByText('Territories')).toBeInTheDocument();
    expect(screen.getByText('North Region')).toBeInTheDocument();

    fireEvent.click(screen.getByText('North Region'));

    expect(screen.getByText('Edit Territory')).toBeInTheDocument();
    expect(screen.getByText('Boundary Editor')).toBeInTheDocument();
    expect(screen.getByText('Staff Assignment Panel')).toBeInTheDocument();
  });

  it('renders the empty list state when no territories exist', () => {
    useTerritoriesMock.mockReturnValue({
      territories: [],
      isLoading: false,
      refresh: refreshMock,
    });

    render(<TerritoriesPage />);

    expect(screen.getByText('No territories defined yet')).toBeInTheDocument();
  });
});
