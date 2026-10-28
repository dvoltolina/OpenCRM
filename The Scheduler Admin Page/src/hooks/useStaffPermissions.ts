import { useCallback, useEffect, useMemo, useState } from 'react';

import {
  buildDefaultModuleAccess,
  findInvitePermissions,
  getStaffPermissions,
  isModuleEnabled,
} from '../data/staffPermissions';
import type { ModuleAccess, StaffPermissions } from '../types/models';
import type { UserRole } from '../types/auth';

type UseStaffPermissionsResult = {
  permissions: StaffPermissions | null;
  access: ModuleAccess;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  hasModule: (module?: keyof ModuleAccess) => boolean;
};

export function useStaffPermissions(
  businessId?: string,
  userId?: string,
  role?: UserRole,
  email?: string | null,
): UseStaffPermissionsResult {
  const [permissions, setPermissions] = useState<StaffPermissions | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId || !userId) {
      setPermissions(null);
      setError('Business context required');
      return;
    }
    setLoading(true);
    try {
      const data = await getStaffPermissions(businessId, userId);
      if (data) {
        setPermissions(data);
        setError(null);
        return;
      }
      const invitePermissions = email
        ? await findInvitePermissions(businessId, email)
        : null;
      if (invitePermissions) {
        setPermissions(invitePermissions);
        setError(null);
        return;
      }
      setPermissions(null);
      setError(null);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load staff permissions';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [businessId, email, userId]);

  useEffect(() => {
    if (businessId && userId) {
      void refresh();
    }
  }, [businessId, email, refresh, userId]);

  const access = useMemo<ModuleAccess>(() => {
    if (permissions?.moduleAccess) {
      return permissions.moduleAccess;
    }
    const roleSource = permissions?.role ?? role;
    return buildDefaultModuleAccess(roleSource);
  }, [permissions?.moduleAccess, permissions?.role, role]);

  const hasModule = useCallback(
    (module?: keyof ModuleAccess) => isModuleEnabled(access, module),
    [access],
  );

  return {
    permissions,
    access,
    loading,
    error,
    refresh,
    hasModule,
  };
}
