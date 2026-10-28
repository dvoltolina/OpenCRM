import { useCallback, useMemo } from 'react';

import { useAuth } from '../context/AuthContext';
import type { RoleRequirement } from '../types/auth';

type UseBusinessContextOptions = {
  requireBusinessId?: boolean;
  minRole?: RoleRequirement;
};

export function useBusinessContext(options: UseBusinessContextOptions = {}) {
  const { state, hasRole, requireRole } = useAuth();
  const businessId = state.status === 'signed_in' ? state.user.businessId : undefined;
  const role = state.status === 'signed_in' ? state.user.role : undefined;
  const userId = state.status === 'signed_in' ? state.user.uid : undefined;
  const providerId = state.status === 'signed_in' ? state.user.providerId : undefined;
  const clientId = state.status === 'signed_in' ? state.user.clientId : undefined;
  const userDisplayName = state.status === 'signed_in' ? state.user.displayName : undefined;
  const userEmail = state.status === 'signed_in' ? state.user.email : undefined;

  if (options.minRole && state.status === 'signed_in') {
    requireRole(options.minRole);
  }

  if (options.requireBusinessId && state.status === 'signed_in' && !businessId) {
    throw new Error('Business context is required but missing for this user.');
  }

  const assertBusinessId = useCallback(() => {
    if (!businessId) {
      throw new Error('Business context is required for this operation.');
    }
    return businessId;
  }, [businessId]);

  return useMemo(
    () => ({
      businessId,
      role,
      userId,
      providerId,
      clientId,
      userDisplayName,
      userEmail,
      hasRole,
      requireRole,
      assertBusinessId,
      status: state.status,
    }),
    [
      assertBusinessId,
      businessId,
      clientId,
      hasRole,
      providerId,
      requireRole,
      role,
      state.status,
      userDisplayName,
      userEmail,
      userId,
    ],
  );
}
