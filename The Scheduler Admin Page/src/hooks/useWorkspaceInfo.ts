import { useCallback, useEffect, useState } from 'react';

import { getWorkspaceInfo } from '../data/workspace';
import type { WorkspaceInfo } from '../types/models';

type UseWorkspaceInfoResult = {
  workspace: WorkspaceInfo | null;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
};

export function useWorkspaceInfo(businessId?: string): UseWorkspaceInfoResult {
  const [workspace, setWorkspace] = useState<WorkspaceInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      setWorkspace(null);
      setError('Business context required');
      return;
    }
    setLoading(true);
    try {
      const data = await getWorkspaceInfo(businessId);
      setWorkspace(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load workspace');
    } finally {
      setLoading(false);
    }
  }, [businessId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return { workspace, loading, error, refresh };
}
