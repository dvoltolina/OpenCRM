/**
 * useTenantDetails Hook
 * Fetches and mutates a single tenant's details (super-admin only).
 */

import { useCallback, useEffect, useState } from 'react';
import {
  getTenantDetails,
  updateTenantPlan,
  toggleTenantAddon,
  updateTenantFeatureFlags,
} from '../data/opsTenants';
import { useSuperAdminContext } from './useSuperAdminContext';
import type { WorkspaceInfo, BillingProfile, FeatureFlags } from '../types/models';

export type TenantDetails = {
  workspace: WorkspaceInfo;
  billing: BillingProfile | null;
  flags: FeatureFlags;
};

export type UseTenantDetailsResult = {
  details: TenantDetails | null;
  loading: boolean;
  error: string | null;
  updating: boolean;
  refresh: () => Promise<void>;
  setPlan: (planId: string, planName: string, seats: number) => Promise<void>;
  toggleAddon: (addonId: string, enabled: boolean) => Promise<void>;
  updateFlags: (updates: Partial<FeatureFlags>) => Promise<void>;
};

export function useTenantDetails(businessId: string | null): UseTenantDetailsResult {
  const { isAuthorized, userId, email } = useSuperAdminContext();
  const [details, setDetails] = useState<TenantDetails | null>(null);
  const [loading, setLoading] = useState(false);
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthorized || !userId || !email || !businessId) {
      setDetails(null);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const data = await getTenantDetails(businessId, userId, email);
      setDetails(data);
    } catch (err) {
      console.error('Failed to load tenant details', err);
      setError(err instanceof Error ? err.message : 'Failed to load tenant');
    } finally {
      setLoading(false);
    }
  }, [isAuthorized, userId, email, businessId]);

  useEffect(() => {
    if (businessId) {
      void refresh();
    } else {
      setDetails(null);
    }
  }, [businessId, refresh]);

  const setPlan = useCallback(
    async (planId: string, planName: string, seats: number) => {
      if (!isAuthorized || !userId || !email || !businessId) return;

      setUpdating(true);
      setError(null);
      try {
        await updateTenantPlan(businessId, planId, planName, seats, userId, email);
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to update plan');
        throw err;
      } finally {
        setUpdating(false);
      }
    },
    [isAuthorized, userId, email, businessId, refresh],
  );

  const toggleAddon = useCallback(
    async (addonId: string, enabled: boolean) => {
      if (!isAuthorized || !userId || !email || !businessId) return;

      setUpdating(true);
      setError(null);
      try {
        await toggleTenantAddon(businessId, addonId, enabled, userId, email);
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to toggle addon');
        throw err;
      } finally {
        setUpdating(false);
      }
    },
    [isAuthorized, userId, email, businessId, refresh],
  );

  const updateFlags = useCallback(
    async (updates: Partial<FeatureFlags>) => {
      if (!isAuthorized || !userId || !email || !businessId) return;

      setUpdating(true);
      setError(null);
      try {
        await updateTenantFeatureFlags(businessId, updates, userId, email);
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to update flags');
        throw err;
      } finally {
        setUpdating(false);
      }
    },
    [isAuthorized, userId, email, businessId, refresh],
  );

  return {
    details,
    loading,
    error,
    updating,
    refresh,
    setPlan,
    toggleAddon,
    updateFlags,
  };
}
