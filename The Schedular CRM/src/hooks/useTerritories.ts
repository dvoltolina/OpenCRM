/**
 * Territory Hooks
 * Provides hooks for territory management
 *
 * HIPAA Compliance: All operations require authentication
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getTerritoryRepository,
  isLocationInTerritory,
  isZipCodeInTerritory,
} from '../data/repositories/territory-repository';
import { createSecurityContext } from './usePipeline';
import type {
  Territory,
  TerritoryAssignment,
  Client,
} from '../types/models';

// ============================================
// useTerritories Hook - List all territories
// ============================================

export interface UseTerritoriesResult {
  territories: Territory[];
  isLoading: boolean;
  error: Error | null;
  getTerritoryForContact: (contact: Client) => Territory | null;
  getTerritoryByZipCode: (zipCode: string) => Territory | null;
  getTerritoriesForStaff: (staffId: string) => Territory[];
  refresh: () => void;
}

export function useTerritories(activeOnly = true): UseTerritoriesResult {
  const { crmUser, businessId } = useAuth();
  const [territories, setTerritories] = useState<Territory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

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

  const fetchTerritories = useCallback(async () => {
    if (!businessId || !crmUser) {
      setTerritories([]);
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
      const repo = getTerritoryRepository();
      const result = activeOnly
        ? await repo.getActive(context)
        : await repo.getAllTerritories(context);

      if (currentAbortController.signal.aborted) return;

      if (result.success) {
        setTerritories(result.data);
      } else {
        setError(new Error(result.error.message));
        setTerritories([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch territories'));
      setTerritories([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, activeOnly]);

  useEffect(() => {
    fetchTerritories();
  }, [fetchTerritories]);

  const refresh = useCallback(() => {
    fetchTerritories();
  }, [fetchTerritories]);

  const getTerritoryForContact = useCallback(
    (contact: Client): Territory | null => {
      // First try by zip code (most common)
      if (contact.address?.zipCode) {
        const byZip = territories.find((t) =>
          isZipCodeInTerritory(t, contact.address!.zipCode!)
        );
        if (byZip) return byZip;
      }

      // Then try by geocoded location
      if (contact.geocodedAddress?.latitude && contact.geocodedAddress?.longitude) {
        const byLocation = territories.find((t) =>
          isLocationInTerritory(
            t,
            contact.geocodedAddress!.latitude,
            contact.geocodedAddress!.longitude
          )
        );
        if (byLocation) return byLocation;
      }

      return null;
    },
    [territories]
  );

  const getTerritoryByZipCode = useCallback(
    (zipCode: string): Territory | null => {
      return territories.find((t) => isZipCodeInTerritory(t, zipCode)) ?? null;
    },
    [territories]
  );

  const getTerritoriesForStaff = useCallback(
    (staffId: string): Territory[] => {
      return territories.filter((t) =>
        t.assignments.some((a) => a.staffId === staffId)
      );
    },
    [territories]
  );

  return {
    territories,
    isLoading,
    error,
    getTerritoryForContact,
    getTerritoryByZipCode,
    getTerritoriesForStaff,
    refresh,
  };
}

// ============================================
// useTerritory Hook - Single territory
// ============================================

export interface UseTerritoryResult {
  territory: Territory | null;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

export function useTerritory(territoryId: string | null): UseTerritoryResult {
  const { crmUser, businessId } = useAuth();
  const [territory, setTerritory] = useState<Territory | null>(null);
  const [isLoading, setIsLoading] = useState(true);
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

  const fetchTerritory = useCallback(async () => {
    if (!businessId || !crmUser || !territoryId) {
      setTerritory(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getTerritoryRepository();
      const result = await repo.getById(context, territoryId);

      if (result.success) {
        setTerritory(result.data);
      } else {
        setError(new Error(result.error.message));
        setTerritory(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch territory'));
      setTerritory(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, territoryId, getContext]);

  useEffect(() => {
    fetchTerritory();
  }, [fetchTerritory]);

  const refresh = useCallback(() => {
    fetchTerritory();
  }, [fetchTerritory]);

  return { territory, isLoading, error, refresh };
}

// ============================================
// useTerritoryMutations Hook - CRUD ops
// ============================================

export interface UseTerritoryMutationsResult {
  createTerritory: (data: Partial<Territory>) => Promise<Territory>;
  updateTerritory: (id: string, data: Partial<Territory>) => Promise<Territory>;
  deleteTerritory: (id: string) => Promise<void>;
  updateAssignments: (
    territoryId: string,
    assignments: TerritoryAssignment[]
  ) => Promise<Territory>;
  addAssignment: (
    territoryId: string,
    assignment: TerritoryAssignment
  ) => Promise<Territory>;
  removeAssignment: (territoryId: string, staffId: string) => Promise<Territory>;
  isLoading: boolean;
  error: Error | null;
  clearError: () => void;
}

export function useTerritoryMutations(): UseTerritoryMutationsResult {
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

  const createTerritory = useCallback(
    async (data: Partial<Territory>): Promise<Territory> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();

        const territoryData = {
          name: data.name ?? '',
          description: data.description,
          colorHex: data.colorHex ?? '#3b82f6',
          boundary: data.boundary ?? { type: 'zip_codes' as const, zipCodes: [] },
          assignments: data.assignments ?? [],
          enableAutoSuggestion: data.enableAutoSuggestion ?? true,
          loadBalancingEnabled: data.loadBalancingEnabled ?? false,
          isActive: data.isActive ?? true,
          businessId: context.businessId,
          createdBy: context.userId,
          createdByName: context.userName,
        } as Omit<Territory, 'id' | 'createdAt' | 'updatedAt'>;

        const result = await repo.create(context, territoryData);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create territory');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateTerritory = useCallback(
    async (id: string, data: Partial<Territory>): Promise<Territory> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();
        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update territory');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const deleteTerritory = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();
        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete territory');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateAssignments = useCallback(
    async (
      territoryId: string,
      assignments: TerritoryAssignment[]
    ): Promise<Territory> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();
        const result = await repo.updateAssignments(context, territoryId, assignments);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error =
          err instanceof Error ? err : new Error('Failed to update assignments');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const addAssignment = useCallback(
    async (
      territoryId: string,
      assignment: TerritoryAssignment
    ): Promise<Territory> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();
        const result = await repo.addAssignment(context, territoryId, assignment);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add assignment');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const removeAssignment = useCallback(
    async (territoryId: string, staffId: string): Promise<Territory> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTerritoryRepository();
        const result = await repo.removeAssignment(context, territoryId, staffId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error =
          err instanceof Error ? err : new Error('Failed to remove assignment');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createTerritory,
    updateTerritory,
    deleteTerritory,
    updateAssignments,
    addAssignment,
    removeAssignment,
    isLoading,
    error,
    clearError,
  };
}

// ============================================
// Territory Auto-Suggestion
// ============================================

/**
 * Suggest the best staff member for a contact based on territory
 */
export function suggestStaffForContact(
  territories: Territory[],
  contact: Client,
  availableStaffIds?: string[]
): TerritoryAssignment | null {
  // Find territory for contact
  let territory: Territory | null = null;

  // First try by zip code
  if (contact.address?.zipCode) {
    territory =
      territories.find((t) => isZipCodeInTerritory(t, contact.address!.zipCode!)) ??
      null;
  }

  // Then try by location
  if (!territory && contact.geocodedAddress) {
    territory =
      territories.find((t) =>
        isLocationInTerritory(
          t,
          contact.geocodedAddress!.latitude,
          contact.geocodedAddress!.longitude
        )
      ) ?? null;
  }

  if (!territory || !territory.enableAutoSuggestion) {
    return null;
  }

  // Get assignments sorted by isPrimary, then priority
  let assignments = [...territory.assignments].sort((a, b) => {
    if (a.isPrimary && !b.isPrimary) return -1;
    if (!a.isPrimary && b.isPrimary) return 1;
    return a.priority - b.priority;
  });

  // Filter to only available staff if provided
  if (availableStaffIds) {
    assignments = assignments.filter((a) => availableStaffIds.includes(a.staffId));
  }

  return assignments[0] ?? null;
}

// ============================================
// Helper exports
// ============================================

export { isLocationInTerritory, isZipCodeInTerritory };
