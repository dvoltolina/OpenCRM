/**
 * useTeams Hook
 * React hook for managing teams (CRUD operations)
 *
 * Used by Admin page for team management
 *
 * HIPAA Compliance:
 * - All operations go through TeamsRepository for audit logging
 * - SecurityContext validation on every operation
 * - Tenant isolation via businessId scoping
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getTeamsRepository,
  type TeamCreateData,
  type TeamUpdateData,
} from '../data/repositories/teams-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Team } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseTeamsResult {
  /** List of teams */
  teams: Team[];
  /** True while loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Create a new team */
  createTeam: (data: TeamCreateData) => Promise<Team | null>;
  /** Update an existing team */
  updateTeam: (id: string, data: TeamUpdateData) => Promise<Team | null>;
  /** Delete a team (hard delete) */
  deleteTeam: (id: string) => Promise<boolean>;
  /** Deactivate a team (soft delete) */
  deactivateTeam: (id: string) => Promise<boolean>;
  /** Reactivate a team */
  reactivateTeam: (id: string) => Promise<boolean>;
  /** Assign a manager to a team */
  assignManager: (teamId: string, managerId: string, managerName: string) => Promise<boolean>;
  /** Refresh the list */
  refresh: () => void;
}

export interface UseTeamsOptions {
  /** Include inactive teams (default: false) */
  includeInactive?: boolean;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing teams
 *
 * @param options - Configuration options
 * @returns Teams and management functions
 *
 * @example
 * ```tsx
 * const { teams, isLoading, createTeam, updateTeam, deleteTeam } = useTeams();
 *
 * // Create a new team
 * await createTeam({ name: 'Sales Team', description: 'Primary sales team' });
 *
 * // Update a team
 * await updateTeam('team-123', { name: 'Updated Name' });
 *
 * // Delete a team
 * await deleteTeam('team-123');
 * ```
 */
export function useTeams(options: UseTeamsOptions = {}): UseTeamsResult {
  const { includeInactive = false } = options;
  const { businessId, user, crmUser } = useAuth();
  const [teams, setTeams] = useState<Team[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Create SecurityContext from auth
  const getSecurityContext = useCallback((): SecurityContext | null => {
    if (!businessId || !user) {
      return null;
    }

    return {
      businessId,
      userId: user.uid,
      userName: user.displayName || user.email || 'Unknown',
      userRole: crmUser?.role || 'staff',
      teamIds: crmUser?.teamIds || [],
      managedTeamIds: crmUser?.managedTeamIds || [],
    };
  }, [businessId, crmUser?.role, crmUser?.teamIds, crmUser?.managedTeamIds, user]);

  // Subscribe to teams via repository
  useEffect(() => {
    const context = getSecurityContext();

    if (!context) {
      setTeams([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    const repository = getTeamsRepository();

    // Subscribe to teams
    const unsubscribe = repository.subscribeToTeams(
      context,
      (teamsList) => {
        setTeams(teamsList);
        setIsLoading(false);
        setError(null);
      },
      (err) => {
        setError(err);
        setIsLoading(false);
      },
      !includeInactive // activeOnly = !includeInactive
    );

    return unsubscribe;
  }, [getSecurityContext, refreshKey, includeInactive]);

  // Create a new team
  const createTeam = useCallback(
    async (data: TeamCreateData): Promise<Team | null> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return null;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.create(context, data);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to create team';
          setError(new Error(errorMsg));
          return null;
        }

        setError(null);
        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create team');
        setError(error);
        return null;
      }
    },
    [getSecurityContext]
  );

  // Update an existing team
  const updateTeam = useCallback(
    async (id: string, data: TeamUpdateData): Promise<Team | null> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return null;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.update(context, id, data);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to update team';
          setError(new Error(errorMsg));
          return null;
        }

        setError(null);
        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update team');
        setError(error);
        return null;
      }
    },
    [getSecurityContext]
  );

  // Delete a team (hard delete)
  const deleteTeam = useCallback(
    async (id: string): Promise<boolean> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return false;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.delete(context, id);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to delete team';
          setError(new Error(errorMsg));
          return false;
        }

        setError(null);
        return true;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete team');
        setError(error);
        return false;
      }
    },
    [getSecurityContext]
  );

  // Deactivate a team (soft delete)
  const deactivateTeam = useCallback(
    async (id: string): Promise<boolean> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return false;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.deactivate(context, id);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to deactivate team';
          setError(new Error(errorMsg));
          return false;
        }

        setError(null);
        return true;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to deactivate team');
        setError(error);
        return false;
      }
    },
    [getSecurityContext]
  );

  // Reactivate a team
  const reactivateTeam = useCallback(
    async (id: string): Promise<boolean> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return false;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.reactivate(context, id);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to reactivate team';
          setError(new Error(errorMsg));
          return false;
        }

        setError(null);
        return true;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to reactivate team');
        setError(error);
        return false;
      }
    },
    [getSecurityContext]
  );

  // Assign a manager to a team
  const assignManager = useCallback(
    async (teamId: string, managerId: string, managerName: string): Promise<boolean> => {
      const context = getSecurityContext();

      if (!context) {
        setError(new Error('Not authenticated'));
        return false;
      }

      try {
        const repository = getTeamsRepository();
        const result = await repository.assignManager(context, teamId, managerId, managerName);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to assign manager';
          setError(new Error(errorMsg));
          return false;
        }

        setError(null);
        return true;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to assign manager');
        setError(error);
        return false;
      }
    },
    [getSecurityContext]
  );

  // Refresh by incrementing key (triggers re-subscribe)
  const refresh = useCallback(() => {
    setRefreshKey((k) => k + 1);
  }, []);

  return {
    teams,
    isLoading,
    error,
    createTeam,
    updateTeam,
    deleteTeam,
    deactivateTeam,
    reactivateTeam,
    assignManager,
    refresh,
  };
}

export default useTeams;
