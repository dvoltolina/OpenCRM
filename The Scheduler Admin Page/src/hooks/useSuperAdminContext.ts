/**
 * useSuperAdminContext
 * Hook for ops portal pages to access super-admin context.
 * Returns authorization status and operator info for audit logging.
 */

import { useMemo } from 'react';
import { useAuth } from '../context/AuthContext';

export type SuperAdminContext = {
  isAuthorized: boolean;
  userId: string | undefined;
  email: string | undefined;
  displayName: string | undefined;
};

export function useSuperAdminContext(): SuperAdminContext {
  const { state, isSuperAdmin } = useAuth();

  return useMemo(() => {
    if (state.status !== 'signed_in') {
      return {
        isAuthorized: false,
        userId: undefined,
        email: undefined,
        displayName: undefined,
      };
    }

    return {
      isAuthorized: isSuperAdmin,
      userId: state.user.uid,
      email: state.user.email ?? undefined,
      displayName: state.user.displayName ?? undefined,
    };
  }, [state, isSuperAdmin]);
}

/**
 * Hook that throws if not super-admin - use in components that require super-admin access
 */
export function useRequireSuperAdmin(): {
  userId: string;
  email: string;
  displayName: string;
} {
  const ctx = useSuperAdminContext();

  if (!ctx.isAuthorized || !ctx.userId || !ctx.email) {
    throw new Error('Super-admin access required');
  }

  return {
    userId: ctx.userId,
    email: ctx.email,
    displayName: ctx.displayName ?? ctx.email,
  };
}
