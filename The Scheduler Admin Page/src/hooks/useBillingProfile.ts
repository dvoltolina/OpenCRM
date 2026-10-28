import { useCallback, useEffect, useState } from 'react';

import {
  getBillingPortalUrl,
  getBillingProfile,
  startCheckoutSession,
} from '../data/billingProfile';
import type { BillingProfile } from '../types/models';

type UseBillingProfileResult = {
  profile: BillingProfile | null;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  launchCheckout: (input: { planId: string; seats: number; addons?: string[] }) => Promise<string>;
  openPortal: () => Promise<string | null>;
};

export function useBillingProfile(businessId?: string, userId?: string): UseBillingProfileResult {
  const [profile, setProfile] = useState<BillingProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      setProfile(null);
      setError('Business context required to load billing');
      return;
    }
    setLoading(true);
    try {
      const data = await getBillingProfile(businessId, userId);
      setProfile(data);
      setError(null);
    } catch (err) {
      console.error('Failed to load billing profile', err);
      setError(err instanceof Error ? err.message : 'Failed to load billing profile');
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  const launchCheckout = useCallback(
    async (input: { planId: string; seats: number; addons?: string[] }) => {
      if (!businessId) {
        setError('Business context required to launch checkout');
        return '';
      }
      try {
        return await startCheckoutSession(businessId, input, userId);
      } catch (err) {
        console.error('Failed to start checkout', err);
        setError(err instanceof Error ? err.message : 'Unable to start checkout');
        return '';
      }
    },
    [businessId, userId],
  );

  const openPortal = useCallback(async () => {
    if (!businessId) {
      setError('Business context required to open billing portal');
      return null;
    }
    try {
      return await getBillingPortalUrl(businessId, userId);
    } catch (err) {
      console.error('Failed to open billing portal', err);
      setError(err instanceof Error ? err.message : 'Unable to open billing portal');
      return null;
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return { profile, loading, error, refresh, launchCheckout, openPortal };
}
