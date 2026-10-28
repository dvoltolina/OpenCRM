import { useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../lib/security-context';
import type { SecurityContext } from '../data/repositories/repository-types';

/**
 * Build a SecurityContext from the current auth session.
 * Ensures multi-tenant scoping (businessId) and role propagation for repository calls.
 */
export function useSecurityContext(): { context: SecurityContext | null; isAuthenticated: boolean } {
  const { crmUser, businessId } = useAuth();

  const context = useMemo(() => {
    if (!crmUser || !businessId) return null;
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName || crmUser.email || crmUser.id,
      crmUser.role,
      sanitizeTeamIds(crmUser.teamIds || []),
      sanitizeTeamIds(crmUser.managedTeamIds || []),
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  return {
    context,
    isAuthenticated: Boolean(context),
  };
}
