import { useCallback, useEffect, useState } from 'react';

import {
  createWaitlistEntry,
  handleReleasedSlot,
  listWaitlistEntries,
  performWaitlistAction,
  updateWaitlistEntryStatus,
  type ReleasedSlotPayload,
  type WaitlistEntryInput,
} from '../data/waitlist';
import { listClients } from '../data/clients';
import { listServices } from '../data/services';
import { listStaff } from '../data/staff';
import type {
  Client,
  Service,
  StaffMember,
  WaitlistEntry,
  WaitlistEntryStatus,
  WaitlistPriority,
} from '../types/models';

export type HydratedWaitlistEntry = WaitlistEntry & {
  clientName?: string;
  clientEmail?: string;
  clientPhone?: string;
  serviceName?: string;
  providerName?: string;
};

type UseWaitlistEntriesResult = {
  entries: HydratedWaitlistEntry[];
  clients: Client[];
  services: Service[];
  staff: StaffMember[];
  loading: boolean;
  error: string | null;
  refresh: () => void;
  createEntry: (input: WaitlistEntryInput) => Promise<void>;
  convertEntry: (id: string) => Promise<void>;
  expireEntry: (id: string) => Promise<void>;
  notifyEntry: (id: string) => Promise<void>;
  releaseSlot: (payload: ReleasedSlotPayload) => Promise<void>;
};

const statusOrder: Record<WaitlistEntryStatus, number> = {
  active: 0,
  notified: 1,
  converted: 2,
  expired: 3,
};

const priorityOrder: Record<WaitlistPriority, number> = {
  vip: 0,
  standard: 1,
};

export function useWaitlistEntries(businessId?: string, userId?: string): UseWaitlistEntriesResult {
  const [entries, setEntries] = useState<HydratedWaitlistEntry[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [refreshToken, setRefreshToken] = useState(0);

  const refresh = useCallback(() => {
    setRefreshToken((token) => token + 1);
  }, []);

  const guardBusinessId = useCallback(() => {
    if (!businessId) {
      setError('Missing business context for waitlist actions.');
      return false;
    }
    return true;
  }, [businessId]);

  useEffect(() => {
    if (!businessId) {
      setEntries([]);
      setClients([]);
      setServices([]);
      setStaff([]);
      setLoading(false);
      setError(null);
      return;
    }

    let cancelled = false;
    setLoading(true);
    setError(null);

    Promise.all([
      listWaitlistEntries(businessId, userId),
      listClients(businessId, userId),
      listServices(businessId, userId),
      listStaff(businessId, userId),
    ])
      .then(([waitlistEntries, clientRows, serviceRows, staffRows]) => {
        if (cancelled) return;

        const clientMap = new Map(clientRows.map((client) => [client.id, client]));
        const serviceMap = new Map(serviceRows.map((service) => [service.id, service]));
        const staffMap = new Map(staffRows.map((member) => [member.id, member]));

        const hydrated = waitlistEntries
          .map<HydratedWaitlistEntry>((entry) => {
            const client = clientMap.get(entry.clientId);
            const service = serviceMap.get(entry.serviceId);
            const provider = entry.providerId ? staffMap.get(entry.providerId) : undefined;

            return {
              ...entry,
              clientName: client?.name,
              clientEmail: client?.email,
              clientPhone: client?.phone,
              serviceName: service?.name,
              providerName: provider?.displayName,
            };
          })
          .sort((a, b) => {
            const statusDiff = statusOrder[a.status] - statusOrder[b.status];
            if (statusDiff !== 0) return statusDiff;

            const priorityDiff =
              priorityOrder[a.priority ?? 'standard'] - priorityOrder[b.priority ?? 'standard'];
            if (priorityDiff !== 0) return priorityDiff;

            const createdA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const createdB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return createdA - createdB;
          });

        setEntries(hydrated);
        setClients(clientRows);
        setServices(serviceRows);
        setStaff(staffRows);
      })
      .catch((err) => {
        if (cancelled) return;
        console.error('Failed to load waitlist data', err);
        setError('Failed to load waitlist data.');
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [businessId, refreshToken, userId]);

  const createEntry = useCallback(
    async (input: WaitlistEntryInput) => {
      if (!guardBusinessId()) return;
      try {
        await createWaitlistEntry(businessId!, input, userId);
        refresh();
      } catch (err) {
        console.error('Failed to create waitlist entry', err);
        setError('Failed to create waitlist entry.');
      }
    },
    [businessId, guardBusinessId, refresh, userId],
  );

  const convertEntry = useCallback(
    async (id: string) => {
      if (!guardBusinessId()) return;
      try {
        await updateWaitlistEntryStatus(businessId!, id, 'converted', userId);
        refresh();
      } catch (err) {
        console.error('Failed to convert waitlist entry', err);
        setError('Failed to convert waitlist entry.');
      }
    },
    [businessId, guardBusinessId, refresh, userId],
  );

  const expireEntry = useCallback(
    async (id: string) => {
      if (!guardBusinessId()) return;
      try {
        await updateWaitlistEntryStatus(businessId!, id, 'expired', userId);
        refresh();
      } catch (err) {
        console.error('Failed to expire waitlist entry', err);
        setError('Failed to expire waitlist entry.');
      }
    },
    [businessId, guardBusinessId, refresh, userId],
  );

  const notifyEntry = useCallback(
    async (id: string) => {
      if (!guardBusinessId()) return;
      try {
        await performWaitlistAction(businessId!, id, 'notify', {}, userId);
        refresh();
      } catch (err) {
        console.error('Failed to notify waitlist entry', err);
        setError('Failed to send waitlist notification.');
      }
    },
    [businessId, guardBusinessId, refresh, userId],
  );

  const releaseSlot = useCallback(
    async (payload: ReleasedSlotPayload) => {
      if (!guardBusinessId()) return;
      try {
        await handleReleasedSlot(businessId!, payload, userId);
        refresh();
      } catch (err) {
        console.error('Failed to handle released slot', err);
        setError('Failed to broadcast released slot.');
      }
    },
    [businessId, guardBusinessId, refresh, userId],
  );

  return {
    entries,
    clients,
    services,
    staff,
    loading,
    error,
    refresh,
    createEntry,
    convertEntry,
    expireEntry,
    notifyEntry,
    releaseSlot,
  };
}
