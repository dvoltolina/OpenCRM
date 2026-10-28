/**
 * Route Planning Hooks
 * Provides hooks for route planning functionality
 *
 * HIPAA Compliance: All operations require authentication
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getRouteRepository } from '../data/repositories/route-repository';
import type { RouteFilters } from '../data/repositories/route-repository';
import { createSecurityContext } from './usePipeline';
import type { Route, RouteStatus, RouteStop, Client, GeocodedAddress } from '../types/models';
import { optimizeRouteViaGoogle } from '../services/cloud-functions-integration';

// ============================================
// useRoutes Hook - List routes with filtering
// ============================================

export interface UseRoutesResult {
  routes: Route[];
  isLoading: boolean;
  error: Error | null;
  hasMore: boolean;
  refresh: () => void;
}

export function useRoutes(filters?: RouteFilters): UseRoutesResult {
  const { crmUser, businessId } = useAuth();
  const [routes, setRoutes] = useState<Route[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);

  const abortControllerRef = useRef<AbortController | null>(null);

  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  const fetchRoutes = useCallback(async () => {
    if (!businessId || !crmUser) {
      setRoutes([]);
      setIsLoading(false);
      return;
    }

    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    abortControllerRef.current = new AbortController();
    const currentAbortController = abortControllerRef.current;

    setIsLoading(true);
    setError(null);

    try {
      if (currentAbortController.signal.aborted) return;

      const context = getContext();
      const repo = getRouteRepository();

      const result = filters
        ? await repo.getFiltered(context, filters)
        : await repo.getAll(context, { orderBy: { field: 'date', direction: 'desc' } });

      if (currentAbortController.signal.aborted) return;

      if (result.success) {
        const data = 'data' in result.data && Array.isArray(result.data.data)
          ? result.data.data
          : (result.data as Route[]);
        setRoutes(data);
        setHasMore(false);
      } else {
        setError(new Error(result.error.message));
        setRoutes([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch routes'));
      setRoutes([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, filters]);

  useEffect(() => {
    fetchRoutes();
  }, [fetchRoutes]);

  const refresh = useCallback(() => {
    fetchRoutes();
  }, [fetchRoutes]);

  return { routes, isLoading, error, hasMore, refresh };
}

// ============================================
// useRouteMutations Hook - CRUD operations
// ============================================

export interface UseRouteMutationsResult {
  createRoute: (data: Partial<Route>) => Promise<Route>;
  updateRoute: (id: string, data: Partial<Route>) => Promise<Route>;
  deleteRoute: (id: string) => Promise<void>;
  addStop: (routeId: string, contact: Client) => Promise<Route>;
  removeStop: (routeId: string, contactId: string) => Promise<Route>;
  reorderStops: (routeId: string, newOrder: string[]) => Promise<Route>;
  updateStopStatus: (
    routeId: string,
    contactId: string,
    status: 'pending' | 'completed' | 'skipped'
  ) => Promise<Route>;
  updateStatus: (routeId: string, status: RouteStatus) => Promise<Route>;
  optimizeRoute: (routeId: string, startLat?: number, startLng?: number) => Promise<Route>;
  isLoading: boolean;
  error: Error | null;
  clearError: () => void;
}

export function useRouteMutations(): UseRouteMutationsResult {
  const { crmUser, businessId } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const createRoute = useCallback(
    async (data: Partial<Route>): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only owner/admin/manager can create routes
        if (context.userRole !== 'owner' && context.userRole !== 'admin' && context.userRole !== 'manager') {
          throw new Error('Only managers and administrators can create routes');
        }

        const repo = getRouteRepository();

        const routeData = {
          name: data.name || 'New Route',
          date: data.date || new Date(),
          assigneeId: data.assigneeId,
          assigneeName: data.assigneeName,
          stops: data.stops || [],
          status: data.status || 'draft',
          startLatitude: data.startLatitude,
          startLongitude: data.startLongitude,
          startAddress: data.startAddress,
          businessId: context.businessId,
          createdBy: context.userId,
          createdByName: context.userName,
        } as Omit<Route, 'id' | 'createdAt' | 'updatedAt'>;

        const result = await repo.create(context, routeData);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create route');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateRoute = useCallback(
    async (id: string, data: Partial<Route>): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only owner/admin/manager can update routes
        if (context.userRole !== 'owner' && context.userRole !== 'admin' && context.userRole !== 'manager') {
          throw new Error('Only managers and administrators can update routes');
        }

        const repo = getRouteRepository();

        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update route');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const deleteRoute = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        if (context.userRole !== 'owner' && context.userRole !== 'admin') {
          throw new Error('Only administrators can delete routes');
        }

        const repo = getRouteRepository();
        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete route');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const addStop = useCallback(
    async (routeId: string, contact: Client): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        const stop: Omit<RouteStop, 'order'> = {
          contactId: contact.id,
          contact,
          status: 'pending',
        };

        const result = await repo.addStop(context, routeId, stop);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add stop');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const removeStop = useCallback(
    async (routeId: string, contactId: string): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        const result = await repo.removeStop(context, routeId, contactId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to remove stop');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const reorderStops = useCallback(
    async (routeId: string, newOrder: string[]): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        const result = await repo.reorderStops(context, routeId, newOrder);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to reorder stops');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateStopStatus = useCallback(
    async (
      routeId: string,
      contactId: string,
      status: 'pending' | 'completed' | 'skipped'
    ): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        const result = await repo.updateStopStatus(context, routeId, contactId, status);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update stop status');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateStatus = useCallback(
    async (routeId: string, status: RouteStatus): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        const result = await repo.updateStatus(context, routeId, status);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update status');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const optimizeRoute = useCallback(
    async (routeId: string, startLat?: number, startLng?: number): Promise<Route> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getRouteRepository();

        // Get current route
        const routeResult = await repo.getById(context, routeId);
        if (!routeResult.success) {
          throw new Error(routeResult.error.message);
        }

        const route = routeResult.data;
        const stopsWithGeocode = route.stops.filter(
          (s) => s.contact.geocodedAddress?.latitude && s.contact.geocodedAddress?.longitude
        );

        if (stopsWithGeocode.length < 2) {
          throw new Error('Need at least 2 geocoded stops to optimize');
        }

        // Use provided start location or first stop
        const currentLat = startLat ?? stopsWithGeocode[0].contact.geocodedAddress!.latitude;
        const currentLng = startLng ?? stopsWithGeocode[0].contact.geocodedAddress!.longitude;

        let optimized: RouteStop[];
        let totalDistanceKm: number;
        let totalDurationMinutes: number;

        // Try Google Routes API first, fall back to nearest-neighbor
        const googleResult = await optimizeRouteViaGoogle({
          businessId: context.businessId,
          routeId,
          startLatitude: currentLat,
          startLongitude: currentLng,
          stops: stopsWithGeocode.map((s) => ({
            contactId: s.contactId,
            latitude: s.contact.geocodedAddress!.latitude,
            longitude: s.contact.geocodedAddress!.longitude,
          })),
        });

        if (googleResult?.success) {
          // Map Google result back to RouteStop[] using contactId lookup
          const stopMap = new Map(stopsWithGeocode.map((s) => [s.contactId, s]));
          optimized = googleResult.optimizedOrder.map((o) => ({
            ...stopMap.get(o.contactId)!,
            order: o.order,
          }));
          totalDistanceKm = googleResult.totalDistanceKm;
          totalDurationMinutes = googleResult.totalDurationMinutes;
        } else {
          // Fallback: client-side nearest-neighbor
          optimized = optimizeRouteOrder(stopsWithGeocode, currentLat, currentLng);
          let totalDistance = 0;
          for (let i = 0; i < optimized.length - 1; i++) {
            const stop1 = optimized[i];
            const stop2 = optimized[i + 1];
            totalDistance += haversineDistance(
              stop1.contact.geocodedAddress!.latitude,
              stop1.contact.geocodedAddress!.longitude,
              stop2.contact.geocodedAddress!.latitude,
              stop2.contact.geocodedAddress!.longitude
            );
          }
          const travelTimeMin = (totalDistance / 40) * 60;
          const stopTimeMin = optimized.length * 15;
          totalDistanceKm = Math.round(totalDistance * 10) / 10;
          totalDurationMinutes = Math.round(travelTimeMin + stopTimeMin);
        }

        const result = await repo.markOptimized(context, routeId, {
          stops: optimized,
          totalDistanceKm,
          totalDurationMinutes,
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to optimize route');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createRoute,
    updateRoute,
    deleteRoute,
    addStop,
    removeStop,
    reorderStops,
    updateStopStatus,
    updateStatus,
    optimizeRoute,
    isLoading,
    error,
    clearError,
  };
}

// ============================================
// useGeocoding Hook - Address geocoding
// ============================================

// Simple in-memory cache for geocoding results
const geocodeCache = new Map<string, GeocodedAddress>();
let lastGeocodingRequest = 0;
const GEOCODING_RATE_LIMIT_MS = 1100; // Nominatim requires 1 request/second

export interface UseGeocodingResult {
  geocodeAddress: (address: string) => Promise<GeocodedAddress | null>;
  geocodeContact: (contact: Client) => Promise<GeocodedAddress | null>;
  isGeocoding: boolean;
  error: Error | null;
}

export function useGeocoding(): UseGeocodingResult {
  const [isGeocoding, setIsGeocoding] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const geocodeAddress = useCallback(async (address: string): Promise<GeocodedAddress | null> => {
    if (!address.trim()) return null;

    // Check cache
    const cached = geocodeCache.get(address.toLowerCase());
    if (cached) return cached;

    setIsGeocoding(true);
    setError(null);

    try {
      // Rate limiting for Nominatim
      const now = Date.now();
      const timeSinceLastRequest = now - lastGeocodingRequest;
      if (timeSinceLastRequest < GEOCODING_RATE_LIMIT_MS) {
        await new Promise((resolve) =>
          setTimeout(resolve, GEOCODING_RATE_LIMIT_MS - timeSinceLastRequest)
        );
      }
      lastGeocodingRequest = Date.now();

      const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
        address
      )}&limit=1`;

      // Create abort controller for timeout (10 second timeout)
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      const response = await fetch(url, {
        headers: {
          'User-Agent': 'TheSchedulerCRM/1.0',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`Geocoding failed: ${response.status}`);
      }

      const data = await response.json();

      if (!data || data.length === 0) {
        return null;
      }

      const result: GeocodedAddress = {
        latitude: parseFloat(data[0].lat),
        longitude: parseFloat(data[0].lon),
        formattedAddress: data[0].display_name,
        placeId: data[0].place_id?.toString(),
        accuracy: 'approximate',
      };

      // Cache the result
      geocodeCache.set(address.toLowerCase(), result);

      return result;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Geocoding failed');
      setError(error);
      return null;
    } finally {
      setIsGeocoding(false);
    }
  }, []);

  const geocodeContact = useCallback(
    async (contact: Client): Promise<GeocodedAddress | null> => {
      if (!contact.address) return null;

      const { street, city, state, zipCode, country } = contact.address;
      const addressParts = [street, city, state, zipCode, country].filter(Boolean);

      if (addressParts.length === 0) return null;

      const addressString = addressParts.join(', ');
      return geocodeAddress(addressString);
    },
    [geocodeAddress]
  );

  return { geocodeAddress, geocodeContact, isGeocoding, error };
}

// ============================================
// Route Optimization Utilities
// ============================================

/**
 * Haversine distance between two points in kilometers
 */
export function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Nearest-neighbor route optimization algorithm
 */
export function optimizeRouteOrder(
  stops: RouteStop[],
  startLat: number,
  startLng: number
): RouteStop[] {
  const optimized: RouteStop[] = [];
  const remaining = [...stops];
  let currentLat = startLat;
  let currentLng = startLng;

  while (remaining.length > 0) {
    let nearestIdx = 0;
    let nearestDist = Infinity;

    remaining.forEach((stop, idx) => {
      if (!stop.contact.geocodedAddress) return;
      const dist = haversineDistance(
        currentLat,
        currentLng,
        stop.contact.geocodedAddress.latitude,
        stop.contact.geocodedAddress.longitude
      );
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestIdx = idx;
      }
    });

    const nearest = remaining.splice(nearestIdx, 1)[0];
    optimized.push({ ...nearest, order: optimized.length });

    if (nearest.contact.geocodedAddress) {
      currentLat = nearest.contact.geocodedAddress.latitude;
      currentLng = nearest.contact.geocodedAddress.longitude;
    }
  }

  return optimized;
}

export default useRoutes;
