import { useCallback, useEffect, useState } from 'react';

import {
  getFeatureFlags,
  getDefaultFeatureFlags,
  updateFeatureFlags,
} from '../data/featureFlags';
import type { FeatureFlags } from '../types/models';

type FeatureFlagState = {
  flags: FeatureFlags;
  loading: boolean;
  error: string | null;
  updating: boolean;
  refresh: () => Promise<void>;
  mutate: (updates: Partial<FeatureFlags>) => Promise<void>;
};

export function useFeatureFlags(businessId?: string): FeatureFlagState {
  const [flags, setFlags] = useState<FeatureFlags>(getDefaultFeatureFlags());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [updating, setUpdating] = useState(false);

  const refresh = useCallback(async () => {
    if (!businessId) {
      // No businessId - use defaults and set error
      setFlags(getDefaultFeatureFlags());
      setError('Business context required to load feature flags');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await getFeatureFlags(businessId);
      setFlags(data);
    } catch (err) {
      console.error('Failed to load feature flags', err);
      setError(err instanceof Error ? err.message : 'Failed to load feature flags');
      // On error, fall back to defaults but keep error visible
      setFlags(getDefaultFeatureFlags());
    } finally {
      setLoading(false);
    }
  }, [businessId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return {
    flags,
    loading,
    error,
    updating,
    refresh,
    mutate: async (updates) => {
      if (!businessId) {
        console.warn('Cannot mutate feature flags without businessId');
        setError('Business context required to update feature flags');
        return;
      }
      if (!Object.keys(updates).length) return;
      setError(null);
      setUpdating(true);
      const previous = flags;
      setFlags((prev) => ({ ...prev, ...updates }));
      try {
        await updateFeatureFlags(businessId, updates);
      } catch (err) {
        console.error('Failed to update feature flags', err);
        setError(err instanceof Error ? err.message : 'Failed to update feature flags');
        setFlags(previous);
      } finally {
        setUpdating(false);
      }
    },
  };
}

