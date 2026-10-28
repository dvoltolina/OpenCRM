import { useCallback, useEffect, useState } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';

import {
  getOnboardingState,
  markOnboardingComplete,
  saveOnboardingProgress,
  normalizeOnboardingState,
} from '../data/onboarding';
import { getDb } from '../lib/firebase';
import type { OnboardingState, OnboardingStepId } from '../types/models';

type UseOnboardingResult = {
  state: OnboardingState | null;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  saveStep: (updates: Partial<OnboardingState>, completedStep?: OnboardingStepId) => Promise<void>;
  complete: () => Promise<void>;
  needsOnboarding: boolean;
};

export function useOnboarding(
  businessId?: string,
  userId?: string,
  options: { subscribe?: boolean } = {},
): UseOnboardingResult {
  const [state, setState] = useState<OnboardingState | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const subscribe = options.subscribe ?? false;

  const refresh = useCallback(async () => {
    if (!businessId) {
      setError('Business context required to load onboarding');
      setState(null);
      return;
    }
    setLoading(true);
    try {
      const data = await getOnboardingState(businessId, userId);
      setState(data);
      setError(null);
    } catch (err) {
      console.error('Failed to load onboarding state', err);
      setError(err instanceof Error ? err.message : 'Failed to load onboarding');
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  const saveStep = useCallback(
    async (updates: Partial<OnboardingState>, completedStep?: OnboardingStepId) => {
      if (!businessId) {
        setError('Business context required to save onboarding');
        return;
      }
      setLoading(true);
      try {
        const data = await saveOnboardingProgress(businessId, updates, {
          completedStep,
          userId,
        });
        setState(data);
        setError(null);
      } catch (err) {
        console.error('Failed to save onboarding progress', err);
        setError(err instanceof Error ? err.message : 'Failed to save onboarding progress');
      } finally {
        setLoading(false);
      }
    },
    [businessId, userId],
  );

  const complete = useCallback(async () => {
    if (!businessId) {
      setError('Business context required to complete onboarding');
      return;
    }
    setLoading(true);
    try {
      const data = await markOnboardingComplete(businessId, userId);
      setState(data);
      setError(null);
    } catch (err) {
      console.error('Failed to mark onboarding complete', err);
      setError(err instanceof Error ? err.message : 'Failed to complete onboarding');
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    if (subscribe) {
      if (!businessId) {
        setState(null);
        setError('Business context required to load onboarding');
        setLoading(false);
        return;
      }

      setLoading(true);
      const db = getDb();
      const ref = doc(db, 'businesses', businessId, 'settings', 'onboarding');
      const unsubscribe = onSnapshot(
        ref,
        (snap) => {
          const data = normalizeOnboardingState(
            (snap.data() as OnboardingState | undefined) ?? undefined,
          );
          setState(data);
          setError(null);
          setLoading(false);
        },
        (err) => {
          console.error('Failed to subscribe to onboarding state', err);
          setError(err instanceof Error ? err.message : 'Failed to load onboarding');
          setLoading(false);
        },
      );

      return () => unsubscribe();
    }

    void refresh();
  }, [businessId, refresh, subscribe, userId]);

  const needsOnboarding = state ? state.status !== 'completed' : true;

  return {
    state,
    loading,
    error,
    refresh,
    saveStep,
    complete,
    needsOnboarding,
  };
}
