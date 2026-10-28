import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../lib/security-context';
import { getNotificationService } from '../services/notification-service';
import {
  getDefaultNotificationPreferences,
  type NotificationPreferencesUpdate,
  type NotificationPreferences,
} from '../types/notifications';

export interface UseNotificationPreferencesResult {
  preferences: NotificationPreferences | null;
  isLoading: boolean;
  isSaving: boolean;
  error: Error | null;
  refresh: () => void;
  updatePreferences: (updates: NotificationPreferencesUpdate) => Promise<NotificationPreferences>;
  resetPreferences: () => Promise<NotificationPreferences>;
}

export function useNotificationPreferences(): UseNotificationPreferencesResult {
  const { crmUser, businessId } = useAuth();
  const notificationService = useMemo(() => getNotificationService(), []);
  const [preferences, setPreferences] = useState<NotificationPreferences | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const securityContext = useMemo(() => {
    if (!crmUser || !businessId) {
      return null;
    }

    try {
      return createSecurityContext(crmUser);
    } catch {
      return null;
    }
  }, [businessId, crmUser]);

  const loadPreferences = useCallback(async () => {
    if (!securityContext || !crmUser || !businessId) {
      setPreferences(null);
      setError(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const result = await notificationService.getPreferences(securityContext);
      if (!result.success || !result.data) {
        throw new Error(result.error?.message || 'Failed to load notification preferences');
      }

      setPreferences(result.data);
    } catch (err) {
      setPreferences(null);
      setError(err instanceof Error ? err : new Error('Failed to load notification preferences'));
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, notificationService, securityContext]);

  useEffect(() => {
    loadPreferences();
  }, [loadPreferences, refreshKey]);

  const updatePreferences = useCallback(
    async (updates: NotificationPreferencesUpdate): Promise<NotificationPreferences> => {
      if (!securityContext) {
        throw new Error('User not authenticated');
      }

      setIsSaving(true);
      setError(null);

      try {
        const result = await notificationService.updatePreferences(securityContext, updates);
        if (!result.success || !result.data) {
          throw new Error(result.error?.message || 'Failed to update notification preferences');
        }

        setPreferences(result.data);
        return result.data;
      } catch (err) {
        const nextError = err instanceof Error ? err : new Error('Failed to update notification preferences');
        setError(nextError);
        throw nextError;
      } finally {
        setIsSaving(false);
      }
    },
    [notificationService, securityContext]
  );

  const resetPreferences = useCallback(async (): Promise<NotificationPreferences> => {
    if (!crmUser || !businessId) {
      throw new Error('User not authenticated');
    }

    const fallbackTimezone =
      preferences?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'America/New_York';
    const defaults = getDefaultNotificationPreferences(crmUser.id, businessId, fallbackTimezone);

    return updatePreferences({
      emailEnabled: defaults.emailEnabled,
      pushEnabled: defaults.pushEnabled,
      quietHoursStart: defaults.quietHoursStart,
      quietHoursEnd: defaults.quietHoursEnd,
      timezone: defaults.timezone,
      typeSettings: defaults.typeSettings,
      emailDigestFrequency: defaults.emailDigestFrequency,
      emailDigestTime: defaults.emailDigestTime,
    });
  }, [businessId, crmUser, preferences?.timezone, updatePreferences]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    preferences,
    isLoading,
    isSaving,
    error,
    refresh,
    updatePreferences,
    resetPreferences,
  };
}
