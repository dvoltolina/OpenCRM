import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { useTeamRouteBuilder } from '../useTeamRouteBuilder';
import type { Client, Route, RouteStop, Territory, StaffSchedule } from '../../types/models';
import type { TeamMember } from '../useTeamMembers';

// ============================================
// Test Data
// ============================================

const contactA: Client = {
  id: 'contact-a',
  firstName: 'Alice',
  lastName: 'Anderson',
  email: 'alice@example.com',
  tags: [],
  createdAt: new Date(),
  geocodedAddress: {
    latitude: 39.7392,
    longitude: -104.9903,
    formattedAddress: 'Denver, CO',
  },
  address: {
    street: '1 Main St',
    city: 'Denver',
    state: 'CO',
    zipCode: '80202',
    country: 'USA',
  },
};

const contactB: Client = {
  id: 'contact-b',
  firstName: 'Bob',
  lastName: 'Baker',
  email: 'bob@example.com',
  tags: [],
  createdAt: new Date(),
  geocodedAddress: {
    latitude: 40.01499,
    longitude: -105.2705,
    formattedAddress: 'Boulder, CO',
  },
  address: {
    street: '2 Pine St',
    city: 'Boulder',
    state: 'CO',
    zipCode: '80301',
    country: 'USA',
  },
};

const mockContacts: Client[] = [contactA, contactB];

const mockRoutes: Route[] = [
  {
    id: 'route-1',
    businessId: 'biz-1',
    name: 'Existing Route',
    date: new Date('2024-01-15'),
    assigneeId: 'staff-1',
    assigneeName: 'Alice Agent',
    stops: [
      {
        contactId: contactA.id,
        contact: contactA,
        order: 0,
        status: 'pending',
      } as RouteStop,
    ],
    status: 'planned',
    createdAt: new Date(),
    createdBy: 'user-1',
  },
];

const mockSchedules: StaffSchedule[] = [
  {
    id: 'sched-1',
    businessId: 'biz-1',
    staffId: 'staff-1',
    staffName: 'Alice Agent',
    weeklyPatterns: [],
    exceptions: [],
    timezone: 'UTC',
    syncExceptionsFromCalendar: false,
    createdAt: new Date(),
    createdBy: 'user-1',
  },
];

const mockTerritories: Territory[] = [
  {
    id: 'territory-1',
    businessId: 'biz-1',
    name: 'North',
    description: 'North region',
    colorHex: '#123456',
    boundary: { type: 'zip_codes', zipCodes: ['80202'] },
    assignments: [
      { staffId: 'staff-1', staffName: 'Alice Agent', isPrimary: true, priority: 1 },
    ],
    enableAutoSuggestion: true,
    loadBalancingEnabled: false,
    isActive: true,
    createdAt: new Date(),
    createdBy: 'user-1',
  },
];

const mockTeamMembers: TeamMember[] = [
  {
    id: 'staff-1',
    firstName: 'Alice',
    lastName: 'Agent',
    displayName: 'Alice Agent',
    email: 'alice.agent@example.com',
    role: 'staff',
    isActive: true,
    createdAt: new Date(),
  },
  {
    id: 'staff-2',
    firstName: 'Ben',
    lastName: 'Builder',
    displayName: 'Ben Builder',
    email: 'ben.builder@example.com',
    role: 'staff',
    isActive: true,
    createdAt: new Date(),
  },
];

// ============================================
// Mocks
// ============================================

const filtersSeen: unknown[] = [];
const mockUseRoutes = vi.fn();

const mockRouteMutations = {
  createRoute: vi.fn(async (data) => ({
    ...(data as Record<string, unknown>),
    id: 'route-new',
    businessId: 'biz-1',
    createdBy: 'user-1',
    createdAt: new Date(),
    stops: (data as Route).stops ?? [],
    status: 'draft',
  })),
  updateRoute: vi.fn(async (id: string, data: Partial<Route>) => ({
    ...mockRoutes[0],
    ...data,
    id,
  })),
  deleteRoute: vi.fn(async () => {}),
  addStop: vi.fn(async () => mockRoutes[0]),
  removeStop: vi.fn(async () => mockRoutes[0]),
  reorderStops: vi.fn(async () => mockRoutes[0]),
  updateStopStatus: vi.fn(async () => mockRoutes[0]),
  updateStatus: vi.fn(async () => mockRoutes[0]),
  optimizeRoute: vi.fn(async () => mockRoutes[0]),
  isLoading: false,
  error: null,
  clearError: vi.fn(),
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(() => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Owner User',
      role: 'owner',
      businessId: 'biz-1',
      email: 'owner@example.com',
    },
    businessId: 'biz-1',
    user: { uid: 'user-1' },
    isLoading: false,
    error: null,
  })),
}));

vi.mock('../useStaffSchedules', () => ({
  useStaffSchedules: vi.fn(() => ({
    schedules: mockSchedules,
    isLoading: false,
    error: null,
    refresh: vi.fn(),
  })),
  isStaffWorkingOnDate: vi.fn(() => true),
}));

vi.mock('../useTerritories', () => ({
  useTerritories: vi.fn(() => ({
    territories: mockTerritories,
    isLoading: false,
    error: null,
    refresh: vi.fn(),
  })),
  suggestStaffForContact: vi.fn(() => ({ staffId: 'staff-1', staffName: 'Alice Agent', reason: 'primary' })),
}));

vi.mock('../useContacts', () => ({
  useContacts: vi.fn(() => ({
    contacts: mockContacts,
    isLoading: false,
    error: null,
    hasMore: false,
    loadMore: vi.fn(),
    refresh: vi.fn(),
    totalCount: mockContacts.length,
    isLoadingMore: false,
  })),
}));

vi.mock('../useTeamMembers', () => ({
  useTeamMembers: vi.fn(() => ({
    members: mockTeamMembers,
    isLoading: false,
    error: null,
    refresh: vi.fn(),
    updateMemberRole: vi.fn(),
  })),
}));

vi.mock('../useRoutes', () => ({
  useRoutes: (...args: unknown[]) => mockUseRoutes(...args),
  useRouteMutations: vi.fn(() => mockRouteMutations),
}));

// ============================================
// Setup
// ============================================

beforeEach(() => {
  filtersSeen.length = 0;
  mockUseRoutes.mockReset();
  Object.values(mockRouteMutations).forEach((fn) => {
    if (typeof fn === 'function' && 'mockClear' in fn) {
      (fn as unknown as { mockClear: () => void }).mockClear();
    }
  });

  mockUseRoutes.mockImplementation((filters?: unknown) => {
    filtersSeen.push(filters);
    return {
      routes: mockRoutes,
      isLoading: false,
      error: null,
      hasMore: false,
      refresh: vi.fn(),
    };
  });
});

// ============================================
// Tests
// ============================================

describe('useTeamRouteBuilder', () => {
  it('preloads staff assignments from existing routes and keeps unassigned pool accurate', async () => {
    const { result } = renderHook(() => useTeamRouteBuilder(new Date('2024-01-15')));

    await waitFor(() => expect(result.current.workingTeam.length).toBe(2));

    const alice = result.current.workingTeam.find((m) => m.staff.id === 'staff-1');
    const ben = result.current.workingTeam.find((m) => m.staff.id === 'staff-2');

    expect(alice?.selectedContacts.map((c) => c.id)).toEqual([contactA.id]);
    expect(ben?.selectedContacts).toHaveLength(0);
    expect(result.current.unassignedContacts.map((c) => c.id)).toEqual([contactB.id]);
  });

  it('assigns and moves contacts between staff, updating unassigned list', async () => {
    const { result } = renderHook(() => useTeamRouteBuilder(new Date('2024-01-15')));

    await waitFor(() => expect(result.current.workingTeam.length).toBeGreaterThan(0));

    act(() => {
      result.current.assignContactToStaff(contactB.id, 'staff-2');
    });

    let ben = result.current.workingTeam.find((m) => m.staff.id === 'staff-2');
    expect(ben?.selectedContacts.map((c) => c.id)).toEqual([contactB.id]);
    expect(result.current.unassignedContacts.some((c) => c.id === contactB.id)).toBe(false);

    act(() => {
      result.current.moveContactBetweenStaff(contactB.id, 'staff-2', 'staff-1');
    });

    const alice = result.current.workingTeam.find((m) => m.staff.id === 'staff-1');
    ben = result.current.workingTeam.find((m) => m.staff.id === 'staff-2');

    expect(alice?.selectedContacts.map((c) => c.id)).toEqual([contactA.id, contactB.id]);
    expect(ben?.selectedContacts).toHaveLength(0);
    expect(result.current.unassignedContacts).toHaveLength(0);
  });

  it('keeps route filters stable across renders for same date and changes when date changes', async () => {
    const initialDate = new Date('2024-01-15');
    const { result } = renderHook(() => useTeamRouteBuilder(initialDate));

    await waitFor(() => expect(result.current.workingTeam.length).toBeGreaterThan(0));

    const firstFilters = filtersSeen[0];
    expect(firstFilters).toBeTruthy();

    act(() => {
      result.current.assignContactToStaff(contactB.id, 'staff-2');
    });

    const latestSameDate = filtersSeen[filtersSeen.length - 1];
    expect(latestSameDate).toBe(firstFilters);

    act(() => {
      result.current.setSelectedDate(new Date('2024-02-01'));
    });

    const afterDateChange = filtersSeen[filtersSeen.length - 1] as { dateFrom?: Date; dateTo?: Date } | undefined;
    expect(afterDateChange).not.toBe(firstFilters);
    expect(afterDateChange?.dateFrom?.toISOString().startsWith('2024-02-01')).toBe(true);
    expect(afterDateChange?.dateTo?.toISOString().startsWith('2024-02-01')).toBe(true);
  });
});
