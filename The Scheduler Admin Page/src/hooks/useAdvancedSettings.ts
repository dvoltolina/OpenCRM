import { useState, useCallback } from 'react';

import { useBusinessContext } from './useBusinessContext';
import { toggleHipaaMode, requestDataExport, initiatBusinessDeletion } from '../data/advancedSettings';
import type { WorkspaceInfo } from '../types/models';

export type AdvancedSettingsState = {
  hipaaEnabled: boolean;
  mfaEnabled: boolean;
  loading: boolean;
  error: string | null;
};

export type AdvancedSettingsActions = {
  toggleHipaa: (enabled: boolean) => Promise<void>;
  requestExport: () => Promise<void>;
  deleteWorkspace: () => Promise<void>;
};

export function useAdvancedSettings(workspaceInfo: WorkspaceInfo | null) {
  // Enforce owner-only access
  const { businessId, userId } = useBusinessContext({ minRole: 'owner' });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggleHipaa = useCallback(
    async (enabled: boolean) => {
      if (!businessId || !userId) {
        throw new Error('Missing required context for HIPAA toggle');
      }

      setLoading(true);
      setError(null);

      try {
        await toggleHipaaMode({ businessId, enabled, userId });
        // Success - component should refetch workspace info
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to toggle HIPAA mode';
        setError(message);
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [businessId, userId],
  );

  const requestExport = useCallback(async () => {
    if (!businessId || !userId) {
      throw new Error('Missing required context for data export');
    }

    setLoading(true);
    setError(null);

    try {
      await requestDataExport(businessId, userId);
      // Success - component should show confirmation
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to request data export';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  const deleteWorkspace = useCallback(async () => {
    if (!businessId || !userId) {
      throw new Error('Missing required context for workspace deletion');
    }

    setLoading(true);
    setError(null);

    try {
      await initiatBusinessDeletion(businessId, userId);
      // Success - component should show confirmation and logout
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete workspace';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  return {
    state: {
      hipaaEnabled: workspaceInfo?.requiresHipaaCompliance ?? false,
      mfaEnabled: workspaceInfo?.mfaEnabled ?? false,
      loading,
      error,
    },
    actions: {
      toggleHipaa,
      requestExport,
      deleteWorkspace,
    },
  };
}
