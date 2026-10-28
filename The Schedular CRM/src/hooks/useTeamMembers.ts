/**
 * useTeamMembers Hook
 * React hook for fetching team members (providers)
 *
 * Agent CRM-20 Implementation
 * Updated: ProvidersRepository migration for audit logging
 *
 * Team members are stored in the shared providers collection from The Scheduler.
 * All operations now go through ProvidersRepository for:
 * - SecurityContext validation
 * - Audit logging (especially for role changes)
 * - Tenant isolation
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getProvidersRepository,
  type Provider,
  type ProviderRole,
} from '../data/repositories/providers-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import { sanitizeTeamIds } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface TeamMember {
  id: string;
  firstName: string;
  lastName: string;
  displayName: string;
  email: string;
  role: ProviderRole;
  isActive: boolean;
  avatarUrl?: string;
  phone?: string;
  teamIds?: string[];
  managedTeamIds?: string[];
  managerId?: string;
  createdAt: Date;
}

export interface UseTeamMembersResult {
  /** List of team members */
  members: TeamMember[];
  /** True while loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Update a member's role (now audit logged) */
  updateMemberRole: (memberId: string, role: ProviderRole) => Promise<void>;
  /** Refresh the list */
  refresh: () => void;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Convert Provider to TeamMember
 */
function providerToTeamMember(provider: Provider): TeamMember {
  return {
    id: provider.id,
    firstName: provider.firstName,
    lastName: provider.lastName,
    displayName: `${provider.firstName} ${provider.lastName}`.trim() || provider.email,
    email: provider.email,
    role: provider.role,
    isActive: provider.isActive,
    avatarUrl: provider.avatarUrl,
    phone: provider.phone,
    teamIds: sanitizeTeamIds((provider as Provider & { teamIds?: string[] }).teamIds),
    managedTeamIds: sanitizeTeamIds((provider as Provider & { managedTeamIds?: string[] }).managedTeamIds),
    managerId: (provider as Provider & { managerId?: string }).managerId,
    createdAt: provider.createdAt,
  };
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching team members
 *
 * Now uses ProvidersRepository for:
 * - SecurityContext validation
 * - Audit logging for role changes
 * - Consistent data access patterns
 *
 * @returns Team members and management functions
 *
 * @example
 * ```tsx
 * const { members, isLoading, updateMemberRole } = useTeamMembers();
 *
 * // Update role (now audit logged!)
 * await updateMemberRole('member-123', 'admin');
 * ```
 */
export function useTeamMembers(): UseTeamMembersResult {
  const { businessId, user, crmUser } = useAuth();
  const [members, setMembers] = useState<TeamMember[]>([]);
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
      userRole: crmUser?.role || 'staff', // Validated by Firestore rules + repository guards
    };
  }, [businessId, crmUser?.role, user]);

  // Subscribe to team members via repository
  useEffect(() => {
    const context = getSecurityContext();

    if (!context) {
      setMembers([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    const repository = getProvidersRepository();

    // Subscribe to active providers
    const unsubscribe = repository.subscribeToActiveProviders(
      context,
      (providers) => {
        const teamMembers = providers.map(providerToTeamMember);
        setMembers(teamMembers);
        setIsLoading(false);
        setError(null);
      },
      (err) => {
        setError(err);
        setIsLoading(false);
      }
    );

    return unsubscribe;
  }, [getSecurityContext, refreshKey]);

  // Update member role via repository (with audit logging)
  const updateMemberRole = useCallback(
    async (memberId: string, role: ProviderRole): Promise<void> => {
      const context = getSecurityContext();

      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        const repository = getProvidersRepository();
        const result = await repository.updateRole(context, memberId, role);

        if (!result.success) {
          const errorMsg = result.error?.message || 'Failed to update role';
          const error = new Error(errorMsg);
          setError(error);
          throw error;
        }

        // Success - the subscription will update the UI
        setError(null);
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update role');
        setError(error);
        throw error;
      }
    },
    [getSecurityContext]
  );

  // Refresh by incrementing key (triggers re-subscribe)
  const refresh = useCallback(() => {
    setRefreshKey((k) => k + 1);
  }, []);

  return {
    members,
    isLoading,
    error,
    updateMemberRole,
    refresh,
  };
}

export default useTeamMembers;

// Re-export types for convenience
export type { ProviderRole };
