import { useState, useCallback } from 'react';
import { runIntegrationSync, type IntegrationSyncRequest } from '../services/cloud-functions-integration';
import { useAuth } from '../context/AuthContext';

export interface UseIntegrationSyncResult {
  isLoading: boolean;
  error: string | null;
  lastResult: string | null;
  runSync: (request?: Partial<IntegrationSyncRequest>) => Promise<void>;
}

const DEFAULT_REQUEST: IntegrationSyncRequest = {
  integrationId: 'default',
  direction: 'pull',
};

export function useIntegrationSync(): UseIntegrationSyncResult {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastResult, setLastResult] = useState<string | null>(null);
  const { businessId } = useAuth();

  const runSync = useCallback(async (request?: Partial<IntegrationSyncRequest>) => {
    setIsLoading(true);
    setError(null);
    setLastResult(null);

    try {
      const payload: IntegrationSyncRequest = {
        ...DEFAULT_REQUEST,
        ...request,
        businessId: businessId || request?.businessId,
      };
      const result = await runIntegrationSync(payload);

      if (!result.success) {
        setError(result.errors?.[0] || 'Integration sync failed');
        return;
      }

      setLastResult(
        `Synced: created ${result.created}, updated ${result.updated}, skipped ${result.skipped}, conflicts ${result.conflicts.length}`
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Integration sync failed');
    } finally {
      setIsLoading(false);
    }
  }, [businessId]);

  return {
    isLoading,
    error,
    lastResult,
    runSync,
  };
}

export default useIntegrationSync;
