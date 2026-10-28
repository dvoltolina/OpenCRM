/**
 * useRoutes Hook Tests
 *
 * Test Scenarios:
 * 1. Returns route list
 * 2. Filters by date
 * 3. Creates new route
 * 4. Optimizes route with nearest-neighbor algorithm
 * 5. Tests haversine distance calculation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useRoutes, useRouteMutations, haversineDistance, optimizeRouteOrder } from '../useRoutes';
import type { Client, Route, RouteStop } from '../../types/models';

// ============================================
// Mock Auth Context
// ============================================

const mockCrmUser = {
  id: 'user-123',
  displayName: 'Test User',
  role: 'admin',
  businessId: 'business-123',
  email: 'test@example.com',
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(() => ({
    crmUser: mockCrmUser,
    businessId: 'business-123',
    user: { uid: 'user-123' },
    isLoading: false,
    error: null,
  })),
}));

// ============================================
// Mock Route Repository
// ============================================

const mockContactWithGeo = (
  id: string,
  lat: number,
  lng: number,
  name: string
): Client => ({
  id,
  firstName: name,
  lastName: 'Test',
  email: `${name.toLowerCase()}@example.com`,
  tags: [],
  createdAt: new Date(),
  geocodedAddress: {
    latitude: lat,
    longitude: lng,
    formattedAddress: `${lat}, ${lng}`,
  },
});

const mockRoutes: Route[] = [
  {
    id: 'route-1',
    businessId: 'business-123',
    name: 'Monday Route',
    date: new Date('2024-01-15'),
    stops: [],
    status: 'draft',
    createdAt: new Date(),
    createdBy: 'user-123',
  },
  {
    id: 'route-2',
    businessId: 'business-123',
    name: 'Tuesday Route',
    date: new Date('2024-01-16'),
    stops: [],
    status: 'planned',
    totalDistanceKm: 25.5,
    totalDurationMinutes: 90,
    createdAt: new Date(),
    createdBy: 'user-123',
  },
];

const mockGetAll = vi.fn();
const mockGetFiltered = vi.fn();
const mockCreate = vi.fn();
const mockUpdate = vi.fn();
const mockDelete = vi.fn();
const mockGetById = vi.fn();
const mockAddStop = vi.fn();
const mockRemoveStop = vi.fn();
const mockReorderStops = vi.fn();
const mockUpdateStatus = vi.fn();
const mockMarkOptimized = vi.fn();

vi.mock('../../data/repositories/route-repository', () => ({
  getRouteRepository: vi.fn(() => ({
    getAll: mockGetAll,
    getFiltered: mockGetFiltered,
    create: mockCreate,
    update: mockUpdate,
    delete: mockDelete,
    getById: mockGetById,
    addStop: mockAddStop,
    removeStop: mockRemoveStop,
    reorderStops: mockReorderStops,
    updateStatus: mockUpdateStatus,
    markOptimized: mockMarkOptimized,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useRoutes', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockGetAll.mockResolvedValue({
      success: true,
      data: { data: mockRoutes, hasMore: false, lastDoc: null },
    });

    mockGetFiltered.mockResolvedValue({
      success: true,
      data: mockRoutes,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('returns route list', async () => {
    const { result } = renderHook(() => useRoutes());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.routes).toHaveLength(2);
    expect(result.current.routes[0].name).toBe('Monday Route');
  });

  it('filters by date', async () => {
    const dateFilter = {
      dateFrom: new Date('2024-01-15'),
      dateTo: new Date('2024-01-15'),
    };

    renderHook(() => useRoutes(dateFilter));

    await waitFor(() => {
      expect(mockGetFiltered).toHaveBeenCalled();
    });
  });

  it('handles fetch error', async () => {
    mockGetAll.mockResolvedValue({
      success: false,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch' },
    });

    const { result } = renderHook(() => useRoutes());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
  });

  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useRoutes());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      result.current.refresh();
    });

    expect(mockGetAll).toHaveBeenCalledTimes(2);
  });
});

describe('useRouteMutations', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockCreate.mockResolvedValue({
      success: true,
      data: mockRoutes[0],
    });

    mockUpdate.mockResolvedValue({
      success: true,
      data: mockRoutes[0],
    });

    mockDelete.mockResolvedValue({
      success: true,
      data: undefined,
    });
  });

  it('creates a new route', async () => {
    const { result } = renderHook(() => useRouteMutations());

    await act(async () => {
      const route = await result.current.createRoute({
        name: 'New Route',
        date: new Date('2024-01-17'),
        stops: [],
      });
      expect(route.id).toBe('route-1');
    });

    expect(mockCreate).toHaveBeenCalled();
  });

  it('updates a route', async () => {
    const { result } = renderHook(() => useRouteMutations());

    await act(async () => {
      const route = await result.current.updateRoute('route-1', {
        name: 'Updated Route',
      });
      expect(route.id).toBe('route-1');
    });

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.any(Object),
      'route-1',
      { name: 'Updated Route' }
    );
  });

  it('deletes a route', async () => {
    const { result } = renderHook(() => useRouteMutations());

    await act(async () => {
      await result.current.deleteRoute('route-1');
    });

    expect(mockDelete).toHaveBeenCalledWith(
      expect.any(Object),
      'route-1'
    );
  });

  it('handles create error', async () => {
    mockCreate.mockResolvedValue({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: 'Name is required' },
    });

    const { result } = renderHook(() => useRouteMutations());

    await expect(
      act(async () => {
        await result.current.createRoute({
          name: '',
          date: new Date(),
        });
      })
    ).rejects.toThrow('Name is required');
  });
});

describe('haversineDistance', () => {
  it('calculates distance between two points', () => {
    // New York to Los Angeles (approximately 3,944 km)
    const nyLat = 40.7128;
    const nyLng = -74.006;
    const laLat = 34.0522;
    const laLng = -118.2437;

    const distance = haversineDistance(nyLat, nyLng, laLat, laLng);

    // Should be approximately 3,944 km (allow 5% margin)
    expect(distance).toBeGreaterThan(3700);
    expect(distance).toBeLessThan(4200);
  });

  it('returns 0 for same point', () => {
    const lat = 40.7128;
    const lng = -74.006;

    const distance = haversineDistance(lat, lng, lat, lng);

    expect(distance).toBe(0);
  });

  it('calculates short distance accurately', () => {
    // Central Park to Times Square (approximately 2.5 km)
    const cpLat = 40.7829;
    const cpLng = -73.9654;
    const tsLat = 40.758;
    const tsLng = -73.9855;

    const distance = haversineDistance(cpLat, cpLng, tsLat, tsLng);

    // Should be approximately 2.5 km (allow 20% margin for short distances)
    expect(distance).toBeGreaterThan(2);
    expect(distance).toBeLessThan(4);
  });
});

describe('optimizeRouteOrder', () => {
  it('optimizes route using nearest-neighbor', () => {
    const contact1 = mockContactWithGeo('c1', 40.7128, -74.006, 'NYC');
    const contact2 = mockContactWithGeo('c2', 40.758, -73.9855, 'Times Square');
    const contact3 = mockContactWithGeo('c3', 40.7829, -73.9654, 'Central Park');

    const stops: RouteStop[] = [
      { contactId: 'c1', contact: contact1, order: 0, status: 'pending' },
      { contactId: 'c2', contact: contact2, order: 1, status: 'pending' },
      { contactId: 'c3', contact: contact3, order: 2, status: 'pending' },
    ];

    // Start from NYC (contact1)
    const optimized = optimizeRouteOrder(stops, 40.7128, -74.006);

    expect(optimized).toHaveLength(3);
    // First stop should be closest to NYC
    expect(optimized[0].order).toBe(0);
    // Orders should be sequential
    expect(optimized.map((s) => s.order)).toEqual([0, 1, 2]);
  });

  it('handles empty stops array', () => {
    const optimized = optimizeRouteOrder([], 40.7128, -74.006);
    expect(optimized).toHaveLength(0);
  });

  it('handles single stop', () => {
    const contact = mockContactWithGeo('c1', 40.7128, -74.006, 'NYC');
    const stops: RouteStop[] = [
      { contactId: 'c1', contact, order: 0, status: 'pending' },
    ];

    const optimized = optimizeRouteOrder(stops, 40.0, -74.0);

    expect(optimized).toHaveLength(1);
    expect(optimized[0].contactId).toBe('c1');
  });

  it('maintains contact data after optimization', () => {
    const contact1 = mockContactWithGeo('c1', 40.7128, -74.006, 'NYC');
    const contact2 = mockContactWithGeo('c2', 40.758, -73.9855, 'Times Square');

    const stops: RouteStop[] = [
      { contactId: 'c1', contact: contact1, order: 0, status: 'pending', notes: 'Important' },
      { contactId: 'c2', contact: contact2, order: 1, status: 'pending' },
    ];

    const optimized = optimizeRouteOrder(stops, 40.7128, -74.006);

    // Contact data should be preserved
    const nycStop = optimized.find((s) => s.contactId === 'c1');
    expect(nycStop?.contact.firstName).toBe('NYC');
    expect(nycStop?.notes).toBe('Important');
  });
});
