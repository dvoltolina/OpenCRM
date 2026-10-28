/**
 * useTenantList Hook
 * Fetches all tenants for the ops portal (super-admin only).
 */

import { useCallback, useEffect, useState } from 'react';
import { listAllTenants } from '../data/opsTenants';
import { useSuperAdminContext } from './useSuperAdminContext';
import type { TenantSummary } from '../types/ops';

export type UseTenantListResult = {
  tenants: TenantSummary[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
};

export function useTenantList(): UseTenantListResult {
  const { isAuthorized, userId, email } = useSuperAdminContext();
  const [tenants, setTenants] = useState<TenantSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthorized || !userId || !email) {
      setError('Not authorized');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const data = await listAllTenants(userId, email);
      setTenants(data);
    } catch (err) {
      console.error('Failed to load tenants', err);
      setError(err instanceof Error ? err.message : 'Failed to load tenants');
    } finally {
      setLoading(false);
    }
  }, [isAuthorized, userId, email]);

  useEffect(() => {
    if (isAuthorized) {
      void refresh();
    }
  }, [isAuthorized, refresh]);

  return { tenants, loading, error, refresh };
}
