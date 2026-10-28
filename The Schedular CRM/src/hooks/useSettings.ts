/**
 * useSettings Hook
 * React hook for CRM settings management
 *
 * Agent CRM-20 Implementation
 * Dependencies: Agent CRM-20 (settings repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import {
  getSettingsRepository,
  type SettingsUpdateData,
} from '../data/repositories/settings-repository';
import type { CRMSettings } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseSettingsResult {
  /** Current CRM settings */
  settings: CRMSettings | null;
  /** True while loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Update settings */
  updateSettings: (data: SettingsUpdateData) => Promise<void>;
  /** Set default pipeline */
  setDefaultPipeline: (pipelineId: string) => Promise<void>;
  /** Toggle lead scoring */
  toggleLeadScoring: (enabled: boolean) => Promise<void>;
  /** Update deal rotting settings */
  updateDealRotting: (enabled: boolean, thresholdDays: number) => Promise<void>;
  /** Refresh settings */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing CRM settings
 *
 * @returns Settings data and update functions
 *
 * @example
 * ```tsx
 * const {
 *   settings,
 *   updateSettings,
 *   setDefaultPipeline,
 *   isLoading,
 * } = useSettings();
 *
 * // Update currency
 * await updateSettings({ defaultCurrency: 'EUR' });
 *
 * // Set default pipeline
 * await setDefaultPipeline('pipeline-123');
 * ```
 */
export function useSettings(): UseSettingsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [settings, setSettings] = useState<CRMSettings | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch settings
  const fetchSettings = useCallback(async () => {
    if (!businessId || !crmUser) {
      setSettings(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSettingsRepository();
      const result = await repo.getSettings(context);

      if (result.success) {
        setSettings(result.data);
      } else {
        throw new Error(result.error.message);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load settings'));
      setSettings(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext]);

  // Subscribe to real-time updates
  useEffect(() => {
    if (!businessId || !crmUser) {
      setSettings(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);

    try {
      const context = getContext();
      const repo = getSettingsRepository();

      const unsubscribe = repo.subscribeToSettings(
        context,
        (updatedSettings) => {
          setSettings(updatedSettings);
          setIsLoading(false);
          setError(null);
        },
        (err) => {
          setError(err);
          setIsLoading(false);
        }
      );

      return unsubscribe;
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to subscribe to settings'));
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext]);

  // Update settings
  const updateSettings = useCallback(
    async (data: SettingsUpdateData): Promise<void> => {
      setError(null);

      try {
        const context = getContext();
        const repo = getSettingsRepository();
        const result = await repo.updateSettings(context, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        // Settings will update via subscription
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update settings');
        setError(error);
        throw error;
      }
    },
    [getContext]
  );

  // Set default pipeline
  const setDefaultPipeline = useCallback(
    async (pipelineId: string): Promise<void> => {
      await updateSettings({ defaultPipelineId: pipelineId });
    },
    [updateSettings]
  );

  // Toggle lead scoring
  const toggleLeadScoring = useCallback(
    async (enabled: boolean): Promise<void> => {
      await updateSettings({ leadScoringEnabled: enabled });
    },
    [updateSettings]
  );

  // Update deal rotting
  const updateDealRotting = useCallback(
    async (enabled: boolean, thresholdDays: number): Promise<void> => {
      await updateSettings({ dealRotting: { enabled, thresholdDays } });
    },
    [updateSettings]
  );

  // Manual refresh
  const refresh = useCallback(() => {
    fetchSettings();
  }, [fetchSettings]);

  return {
    settings,
    isLoading,
    error,
    updateSettings: guardMutation(updateSettings, { action: 'settings-update' }),
    setDefaultPipeline: guardMutation(setDefaultPipeline, { action: 'settings-pipeline-default' }),
    toggleLeadScoring: guardMutation(toggleLeadScoring, { action: 'settings-lead-scoring' }),
    updateDealRotting: guardMutation(updateDealRotting, { action: 'settings-deal-rotting' }),
    refresh,
  };
}

export default useSettings;
