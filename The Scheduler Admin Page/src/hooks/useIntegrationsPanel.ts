import { useCallback, useEffect, useMemo, useState } from 'react';

import {
  connectIntegration,
  disconnectIntegration,
  getTelehealthSettings,
  listIntegrations,
  listStaffIntegrationPreferences,
  refreshIntegrationStatus,
  saveStaffIntegrationPreference,
  type IntegrationProvider,
  updateTelehealthSettings,
} from '../data/integrations';
import { listServices } from '../data/services';
import { listStaff } from '../data/staff';
import type {
  CalendarIntegrationProvider,
  IntegrationAccount,
  Service,
  StaffIntegrationPreference,
  StaffMember,
  TelehealthFallbackOption,
  TelehealthProvider,
  TelehealthSettings,
} from '../types/models';

export type StaffIntegrationRow = {
  id: string;
  name: string;
  role: StaffMember['role'];
  calendarProvider: CalendarIntegrationProvider | 'none';
  telehealthProvider: TelehealthProvider | 'default' | TelehealthFallbackOption;
};

export type ServiceTelehealthPreference = {
  id: string;
  name: string;
  provider: TelehealthProvider | 'default';
};

export type UseIntegrationsPanelReturn = {
  loading: boolean;
  error: string | null;
  integrationLookup: Record<string, IntegrationAccount | undefined>;
  staffRows: StaffIntegrationRow[];
  telehealthSettings: TelehealthSettings | null;
  servicePreferences: ServiceTelehealthPreference[];
  mutationKey: string | null;
  refresh: () => Promise<void>;
  actions: {
    connect: (provider: IntegrationProvider) => Promise<void>;
    disconnect: (provider: IntegrationProvider) => Promise<void>;
    refreshProvider: (provider: IntegrationProvider) => Promise<void>;
    updateStaffCalendar: (
      staffId: string,
      provider: CalendarIntegrationProvider | 'none',
    ) => Promise<void>;
    updateStaffTelehealth: (
      staffId: string,
      provider: TelehealthProvider | 'default' | TelehealthFallbackOption,
    ) => Promise<void>;
    setDefaultTelehealthProvider: (provider: TelehealthProvider) => Promise<void>;
    setFallbackTelehealthProvider: (provider: TelehealthFallbackOption) => Promise<void>;
    setRequireTelehealthLink: (enabled: boolean) => Promise<void>;
    setServiceTelehealthProvider: (
      serviceId: string,
      provider: TelehealthProvider | 'default',
    ) => Promise<void>;
  };
};

export function useIntegrationsPanel(businessId?: string, userId?: string): UseIntegrationsPanelReturn {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [integrations, setIntegrations] = useState<IntegrationAccount[]>([]);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [staffPrefs, setStaffPrefs] = useState<Record<string, StaffIntegrationPreference>>({});
  const [telehealthSettings, setTelehealthSettings] = useState<TelehealthSettings | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [mutationKey, setMutationKey] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      // No businessId - clear all data and set error
      setIntegrations([]);
      setStaff([]);
      setStaffPrefs({});
      setTelehealthSettings(null);
      setServices([]);
      setError('Business context required to load integrations');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const [
        integrationList,
        staffList,
        preferenceList,
        telehealth,
        serviceList,
      ] = await Promise.all([
        listIntegrations(businessId),
        listStaff(businessId, userId),
        listStaffIntegrationPreferences(businessId),
        getTelehealthSettings(businessId),
        listServices(businessId, userId),
      ]);
      setIntegrations(integrationList);
      setStaff(staffList);
      setStaffPrefs(
        preferenceList.reduce<Record<string, StaffIntegrationPreference>>((acc, pref) => {
          acc[pref.staffId] = pref;
          return acc;
        }, {}),
      );
      setTelehealthSettings(telehealth);
      setServices(serviceList);
    } catch (err) {
      console.error('Failed to load integrations panel', err);
      setError(err instanceof Error ? err.message : 'Failed to load integrations data');
      // Clear data on error
      setIntegrations([]);
      setStaff([]);
      setStaffPrefs({});
      setTelehealthSettings(null);
      setServices([]);
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const integrationLookup = useMemo(() => {
    return integrations.reduce<Record<string, IntegrationAccount>>((acc, integration) => {
      acc[integration.provider] = integration;
      return acc;
    }, {});
  }, [integrations]);

  const staffRows = useMemo<StaffIntegrationRow[]>(() => {
    return staff.map((member) => {
      const pref = staffPrefs[member.id];
      return {
        id: member.id,
        name: member.displayName,
        role: member.role,
        calendarProvider: pref?.calendarProvider ?? 'none',
        telehealthProvider: pref?.telehealthProvider ?? 'default',
      };
    });
  }, [staff, staffPrefs]);

  const servicePreferences = useMemo<ServiceTelehealthPreference[]>(() => {
    return services.map((service) => ({
      id: service.id,
      name: service.name,
      provider:
        telehealthSettings?.perServiceProviders?.[service.id] ?? ('default' as const),
    }));
  }, [services, telehealthSettings]);

  const updateStaffPreference = useCallback(
    async (
      staffId: string,
      field: 'calendarProvider' | 'telehealthProvider',
      value: CalendarIntegrationProvider | TelehealthProvider | 'none' | 'default' | TelehealthFallbackOption,
    ) => {
      if (!businessId) {
        console.warn('Cannot update staff preference without businessId');
        setError('Business context required to update staff preferences');
        return;
      }
      const currentPref =
        staffPrefs[staffId] ?? ({
          staffId,
          calendarProvider: 'none',
          telehealthProvider: 'default',
        } as StaffIntegrationPreference);
      const nextPref: StaffIntegrationPreference = {
        ...currentPref,
        [field]: value,
      } as StaffIntegrationPreference;

      setStaffPrefs((prev) => ({
        ...prev,
        [staffId]: nextPref,
      }));
      setMutationKey(`staff:${staffId}`);
      try {
        await saveStaffIntegrationPreference(businessId, nextPref);
      } catch (err) {
        console.error('Failed to update staff integration preference', err);
        setError(
          err instanceof Error ? err.message : 'Failed to update staff integration preference',
        );
        setStaffPrefs((prev) => ({
          ...prev,
          [staffId]: currentPref,
        }));
      } finally {
        setMutationKey(null);
      }
    },
    [businessId, staffPrefs],
  );

  const setTelehealthState = useCallback(
    async (updates: Partial<TelehealthSettings>, mutationId: string) => {
      if (!businessId) {
        console.warn('Cannot update telehealth settings without businessId');
        setError('Business context required to update telehealth settings');
        return;
      }
      if (!telehealthSettings) return;
      const previous = telehealthSettings;
      const next = {
        ...previous,
        ...updates,
        perServiceProviders: updates.perServiceProviders
          ? updates.perServiceProviders
          : previous.perServiceProviders,
      };
      setTelehealthSettings(next);
      setMutationKey(mutationId);
      try {
        await updateTelehealthSettings(businessId, updates);
      } catch (err) {
        console.error('Failed to update telehealth settings', err);
        setError(err instanceof Error ? err.message : 'Failed to update telehealth settings');
        setTelehealthSettings(previous);
      } finally {
        setMutationKey(null);
      }
    },
    [businessId, telehealthSettings],
  );

  const setServiceTelehealthProvider = useCallback(
    async (serviceId: string, provider: TelehealthProvider | 'default') => {
      if (!telehealthSettings) return;
      const perService = { ...telehealthSettings.perServiceProviders };
      if (provider === 'default') {
        delete perService[serviceId];
      } else {
        perService[serviceId] = provider;
      }
      await setTelehealthState({ perServiceProviders: perService }, `service:${serviceId}`);
    },
    [setTelehealthState, telehealthSettings],
  );

  const setDefaultTelehealthProvider = useCallback(
    async (provider: TelehealthProvider) => {
      await setTelehealthState({ defaultProvider: provider }, 'telehealth');
    },
    [setTelehealthState],
  );

  const setFallbackTelehealthProvider = useCallback(
    async (provider: TelehealthFallbackOption) => {
      await setTelehealthState({ fallbackProvider: provider }, 'telehealth');
    },
    [setTelehealthState],
  );

  const setRequireTelehealthLink = useCallback(
    async (enabled: boolean) => {
      await setTelehealthState({ requireLink: enabled }, 'telehealth');
    },
    [setTelehealthState],
  );

  const runProviderAction = useCallback(
    async (
      provider: IntegrationProvider,
      action: (bizId: string, prov: IntegrationProvider) => Promise<void>,
    ) => {
      if (!businessId) {
        console.warn('Cannot run provider action without businessId');
        setError('Business context required to manage integrations');
        return;
      }
      setMutationKey(`provider:${provider}`);
      try {
        await action(businessId, provider);
        await refresh();
      } catch (err) {
        console.error('Integration action failed', err);
        setError(err instanceof Error ? err.message : 'Integration action failed');
      } finally {
        setMutationKey(null);
      }
    },
    [businessId, refresh],
  );

  return {
    loading,
    error,
    integrationLookup,
    staffRows,
    telehealthSettings,
    servicePreferences,
    mutationKey,
    refresh,
    actions: {
      connect: (provider) => runProviderAction(provider, connectIntegration),
      disconnect: (provider) => runProviderAction(provider, disconnectIntegration),
      refreshProvider: (provider) => runProviderAction(provider, refreshIntegrationStatus),
      updateStaffCalendar: (staffId, provider) =>
        updateStaffPreference(staffId, 'calendarProvider', provider),
      updateStaffTelehealth: (staffId, provider) =>
        updateStaffPreference(staffId, 'telehealthProvider', provider),
      setDefaultTelehealthProvider,
      setFallbackTelehealthProvider,
      setRequireTelehealthLink,
      setServiceTelehealthProvider,
    },
  };
}
