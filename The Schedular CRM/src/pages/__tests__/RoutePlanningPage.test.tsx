import { render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { RoutePlanningPage } from '../RoutePlanningPage';

const {
  useContactsMock,
  useRoutesMock,
  authState,
  refreshContactsMock,
  refreshRoutesMock,
} = vi.hoisted(() => ({
  useContactsMock: vi.fn(),
  useRoutesMock: vi.fn(),
  authState: { role: 'manager' },
  refreshContactsMock: vi.fn(),
  refreshRoutesMock: vi.fn(),
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
  useContacts: (...args: unknown[]) => useContactsMock(...args),
  useRoutes: (...args: unknown[]) => useRoutesMock(...args),
  useRouteMutations: () => ({
    createRoute: vi.fn(),
    updateRoute: vi.fn(),
    deleteRoute: vi.fn(),
    addStop: vi.fn(),
    removeStop: vi.fn(),
    optimizeRoute: vi.fn(),
    isLoading: false,
  }),
  useGeocoding: () => ({
    geocodeContact: vi.fn(),
    isGeocoding: false,
  }),
  useContactMutations: () => ({
    updateGeocodedAddress: vi.fn(),
  }),
  useModal: () => ({
    isOpen: false,
    data: null,
    open: vi.fn(),
    close: vi.fn(),
  }),
}));

vi.mock('../../components/maps/RouteMap', () => ({
  RouteMap: ({
    contacts,
    selectedContacts,
  }: {
    contacts: Array<{ id: string }>;
    selectedContacts: Array<{ id: string }>;
  }) => <div>Route Map {contacts.length}/{selectedContacts.length}</div>,
}));

vi.mock('../../components/modals', () => ({
  ConfirmDialog: () => null,
}));

describe('RoutePlanningPage', () => {
  beforeEach(() => {
    authState.role = 'manager';
    refreshContactsMock.mockReset();
    refreshRoutesMock.mockReset();
    useContactsMock.mockReturnValue({
      contacts: [
        {
          id: 'contact-1',
          firstName: 'Alex',
          lastName: 'Stone',
          companyName: 'Northwind',
          address: { city: 'Denver', state: 'CO', zipCode: '80202' },
          geocodedAddress: { latitude: 39.7392, longitude: -104.9903 },
        },
        {
          id: 'contact-2',
          firstName: 'Jamie',
          lastName: 'West',
          companyName: 'Acme',
          address: { city: 'Aurora', state: 'CO', zipCode: '80012' },
        },
      ],
      isLoading: false,
      refresh: refreshContactsMock,
    });
    useRoutesMock.mockReturnValue({
      routes: [
        {
          id: 'route-1',
          name: 'North Loop',
          stops: [{ contact: { id: 'contact-1', firstName: 'Alex', lastName: 'Stone' } }],
          totalDistanceKm: 18,
          totalDurationMinutes: 95,
        },
      ],
      isLoading: false,
      refresh: refreshRoutesMock,
    });
  });

  it('renders the route planning workspace with map, route list, and geocoding queue', () => {
    render(<RoutePlanningPage />);

    expect(screen.getByText('Route Planning')).toBeInTheDocument();
    expect(screen.getByText('Map Coverage')).toBeInTheDocument();
    expect(screen.getByText('Route Map 1/0')).toBeInTheDocument();
    expect(screen.getByText('No stops selected')).toBeInTheDocument();
    expect(screen.getByText('North Loop')).toBeInTheDocument();
    expect(screen.getByText('Needs Geocoding')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument();
  });
});
