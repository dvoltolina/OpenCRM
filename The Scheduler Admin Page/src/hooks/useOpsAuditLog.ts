/**
 * useOpsAuditLog Hook
 * Audit log viewer for ops portal (super-admin only).
 */

import { useCallback, useEffect, useState } from 'react';
import { listOpsAuditLogs, listOpsAuditLogsForTenant } from '../data/opsAuditLog';
import { useSuperAdminContext } from './useSuperAdminContext';
import type { OpsAuditLog } from '../types/ops';

export type UseOpsAuditLogResult = {
  logs: OpsAuditLog[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
};

/**
 * Fetch all ops audit logs.
 */
export function useOpsAuditLog(maxResults = 100): UseOpsAuditLogResult {
  const { isAuthorized } = useSuperAdminContext();
  const [logs, setLogs] = useState<OpsAuditLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthorized) {
      setLogs([]);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const data = await listOpsAuditLogs(maxResults);
      setLogs(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }, [isAuthorized, maxResults]);

  useEffect(() => {
    if (isAuthorized) {
      void refresh();
    }
  }, [isAuthorized, refresh]);

  return { logs, loading, error, refresh };
}

/**
 * Fetch ops audit logs for a specific tenant.
 */
export function useOpsAuditLogForTenant(
  businessId: string | null,
  maxResults = 50,
): UseOpsAuditLogResult {
  const { isAuthorized } = useSuperAdminContext();
  const [logs, setLogs] = useState<OpsAuditLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthorized || !businessId) {
      setLogs([]);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const data = await listOpsAuditLogsForTenant(businessId, maxResults);
      setLogs(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }, [isAuthorized, businessId, maxResults]);

  useEffect(() => {
    if (businessId) {
      void refresh();
    }
  }, [businessId, refresh]);

  return { logs, loading, error, refresh };
}
