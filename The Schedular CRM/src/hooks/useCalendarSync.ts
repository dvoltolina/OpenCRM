/**
 * useCalendarSync Hook
 * UI-friendly wrapper for calendar OAuth and sync operations.
 *
 * Guarded by feature flag `enableCalendarSync` and Functions base URL.
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../lib/security-context';
import { getFeatureFlags } from '../config/features';
import type {
  CalendarConnection,
  CalendarProvider,
  CalendarSyncMapping,
  SyncDirection,
  SyncStatus,
} from '../types/calendar-sync';
import type { SyncResult } from '../types/integrations';
import { getCalendarOAuthService } from '../services/calendar-oauth-service';
import { getCalendarSyncService } from '../services/calendar-sync-service';
import { getCalendarConnectionRepository, getCalendarSyncMappingRepository } from '../data/repositories';

interface UseCalendarSyncOptions {
  loadConnections?: boolean;
  loadMappings?: boolean;
}

export interface ActivityStatus {
  syncStatus: SyncStatus;
  mappingId?: string;
  syncDirection?: SyncDirection;
  provider?: CalendarProvider;
  lastSyncedAt?: Date;
}

export interface UseCalendarSyncResult {
  enabled: boolean;
  configured: boolean;
  contextReady: boolean;
  connections: CalendarConnection[];
  conflicts: CalendarSyncMapping[];
  activityStatuses: Record<string, ActivityStatus>;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  startOAuth: (provider: CalendarProvider) => Promise<void>;
  connectWithCode: (
    provider: CalendarProvider,
    authCode: string,
    state?: string
  ) => Promise<CalendarConnection | null>;
  disconnect: (connectionId: string) => Promise<void>;
  refreshTokens: (connectionId: string) => Promise<void>;
  syncConnection: (connectionId: string) => Promise<SyncResult | null>;
  syncActivity: (activityId: string) => Promise<void>;
  resolveConflict: (mappingId: string, resolution: 'use_crm' | 'use_calendar') => Promise<void>;
  updateSettings: (connectionId: string, settings: CalendarConnection['settings']) => Promise<void>;
}

const sanitizeError = (err: unknown, fallback: string): string => {
  if (err instanceof Error && err.message) return err.message;
  if (typeof err === 'string') return err;
  return fallback;
};

export function useCalendarSync(options: UseCalendarSyncOptions = {}): UseCalendarSyncResult {
  const { loadConnections = true, loadMappings = true } = options;
  const { crmUser } = useAuth();
  const oauth = useMemo(() => getCalendarOAuthService(), []);
  const syncService = useMemo(() => getCalendarSyncService(), []);
  const connectionRepo = useMemo(() => getCalendarConnectionRepository(), []);
  const mappingRepo = useMemo(() => getCalendarSyncMappingRepository(), []);
  const enabled = useMemo(() => getFeatureFlags().enableCalendarSync, []);
  const configured = useMemo(
    () =>
      Boolean(
        (typeof import.meta !== 'undefined' && (import.meta as any)?.env?.VITE_FUNCTIONS_BASE_URL) ||
          oauth.isConfigured()
      ),
    [oauth]
  );

  const context = useMemo(() => {
    if (!crmUser) return null;
    try {
      return createSecurityContext(crmUser);
    } catch {
      return null;
    }
  }, [crmUser]);

  const contextReady = Boolean(enabled && context);

  const [connections, setConnections] = useState<CalendarConnection[]>([]);
  const [conflicts, setConflicts] = useState<CalendarSyncMapping[]>([]);
  const [activityStatuses, setActivityStatuses] = useState<Record<string, ActivityStatus>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refreshMappings = useCallback(async () => {
    if (!contextReady || !loadMappings) return;
    const result = await mappingRepo.getAll(context!, { limit: 50 });
    if (result.success) {
      setConflicts(result.data.data.filter((m) => m.status === 'conflict'));
      const map: Record<string, ActivityStatus> = {};
      for (const mapping of result.data.data) {
        map[mapping.activityId] = {
          syncStatus: mapping.status || 'synced',
          mappingId: mapping.id,
          syncDirection: mapping.syncDirection,
          provider: mapping.provider,
          lastSyncedAt: mapping.lastSyncedAt,
        };
      }
      setActivityStatuses(map);
    }
  }, [context, contextReady, loadMappings, mappingRepo]);

  const refresh = useCallback(async () => {
    if (!contextReady || !loadConnections) return;
    setLoading(true);
    setError(null);
    try {
      const result = await connectionRepo.getByUser(context!, context!.userId);
      if (result.success) {
        setConnections(result.data.data);
      } else if (result.error) {
        setError(result.error.message);
      }
      await refreshMappings();
    } catch (err) {
      setError(sanitizeError(err, 'Unable to load calendar connections'));
    } finally {
      setLoading(false);
    }
  }, [context, contextReady, loadConnections, connectionRepo, refreshMappings]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const startOAuth = useCallback(
    async (provider: CalendarProvider) => {
      if (!contextReady) {
        throw new Error('User context unavailable');
      }
      const url = await oauth.getAuthUrl(provider, context!.userId, context!.businessId);
      if (typeof window !== 'undefined') {
        window.open(url, '_blank', 'noopener,noreferrer');
      }
    },
    [context, contextReady, oauth]
  );

  const connectWithCode = useCallback(
    async (provider: CalendarProvider, authCode: string, state?: string) => {
      if (!contextReady) throw new Error('User context unavailable');
      try {
        const connection = await oauth.handleCallback(context!, provider, authCode, state || '');
        await refresh();
        return connection;
      } catch (err) {
        setError(sanitizeError(err, 'Failed to connect calendar'));
        return null;
      }
    },
    [context, contextReady, oauth, refresh]
  );

  const disconnect = useCallback(
    async (connectionId: string) => {
      if (!contextReady) return;
      await oauth.disconnect(context!, connectionId);
      await refresh();
    },
    [context, contextReady, oauth, refresh]
  );

  const refreshTokens = useCallback(
    async (connectionId: string) => {
      if (!contextReady) return;
      await oauth.refreshTokens(context!, connectionId);
      await refresh();
    },
    [context, contextReady, oauth, refresh]
  );

  const syncConnection = useCallback(
    async (connectionId: string): Promise<SyncResult | null> => {
      if (!contextReady) return null;
      const result = await syncService.syncCalendar(context!, connectionId);
      await refreshMappings();
      return result;
    },
    [context, contextReady, refreshMappings, syncService]
  );

  const syncActivity = useCallback(
    async (activityId: string) => {
      if (!contextReady) return;
      await syncService.syncActivityToCalendar(context!, activityId);
      await refreshMappings();
    },
    [context, contextReady, refreshMappings, syncService]
  );

  const resolveConflict = useCallback(
    async (mappingId: string, resolution: 'use_crm' | 'use_calendar') => {
      if (!contextReady) return;
      await syncService.resolveConflict(context!, mappingId, resolution);
      await refreshMappings();
    },
    [context, contextReady, refreshMappings, syncService]
  );

  const updateSettings = useCallback(
    async (connectionId: string, settings: CalendarConnection['settings']) => {
      if (!contextReady) return;
      await connectionRepo.update(context!, connectionId, { settings });
      await refresh();
    },
    [context, contextReady, connectionRepo, refresh]
  );

  return {
    enabled,
    configured,
    contextReady,
    connections,
    conflicts,
    activityStatuses,
    loading,
    error,
    refresh,
    startOAuth,
    connectWithCode,
    disconnect,
    refreshTokens,
    syncConnection,
    syncActivity,
    resolveConflict,
    updateSettings,
  };
}
