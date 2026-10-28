import { useCallback, useEffect, useState } from 'react';

import {
  addGroupSessionAttendee,
  createGroupSession,
  deleteGroupSession,
  listGroupSessionAttendees,
  listGroupSessions,
  removeGroupSessionAttendee,
  updateGroupSession,
  updateGroupSessionAttendee,
  type GroupSessionAttendeeInput,
  type GroupSessionInput,
} from '../data/groupSessions';
import { listClients } from '../data/clients';
import { listServices } from '../data/services';
import { listStaff } from '../data/staff';
import { listLocations } from '../data/locations';
import type {
  Client,
  GroupSession,
  GroupSessionAttendee,
  Location,
  Service,
  StaffMember,
} from '../types/models';

type UseGroupSessionsState = {
  sessions: GroupSession[];
  attendeesBySession: Record<string, GroupSessionAttendee[]>;
  clients: Client[];
  staff: StaffMember[];
  services: Service[];
  locations: Location[];
  loading: boolean;
  saving: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  loadAttendees: (sessionId: string) => Promise<void>;
  saveSession: (input: GroupSessionInput, sessionId?: string) => Promise<void>;
  deleteSession: (sessionId: string) => Promise<void>;
  addAttendee: (sessionId: string, attendee: GroupSessionAttendeeInput) => Promise<void>;
  updateAttendee: (
    sessionId: string,
    attendeeId: string,
    updates: Partial<GroupSessionAttendeeInput>,
  ) => Promise<void>;
  removeAttendee: (sessionId: string, attendeeId: string) => Promise<void>;
};

export function useGroupSessions(businessId?: string, userId?: string): UseGroupSessionsState {
  const [sessions, setSessions] = useState<GroupSession[]>([]);
  const [attendeesBySession, setAttendeesBySession] = useState<Record<string, GroupSessionAttendee[]>>(
    {},
  );
  const [clients, setClients] = useState<Client[]>([]);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      // No businessId - clear all data and set error
      setSessions([]);
      setClients([]);
      setStaff([]);
      setServices([]);
      setLocations([]);
      setError('Business context required to load group sessions');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [sessionRows, clientRows, staffRows, serviceRows, locationRows] = await Promise.all([
        listGroupSessions(businessId, userId),
        listClients(businessId, userId),
        listStaff(businessId, userId),
        listServices(businessId, userId),
        listLocations(businessId, userId),
      ]);

      setSessions(sessionRows);
      setClients(clientRows);
      setStaff(staffRows);
      setServices(serviceRows);
      setLocations(locationRows);
    } catch (err) {
      console.error('Failed to load group sessions', err);
      setError(err instanceof Error ? err.message : 'Failed to load group session data.');
      // Clear data on error
      setSessions([]);
      setClients([]);
      setStaff([]);
      setServices([]);
      setLocations([]);
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const loadAttendees = useCallback(
    async (sessionId: string) => {
      if (!sessionId) return;
      if (!businessId) {
        console.warn('Cannot load attendees without businessId');
        return;
      }
      try {
        const rows = await listGroupSessionAttendees(businessId, sessionId, userId);
        setAttendeesBySession((prev) => ({ ...prev, [sessionId]: rows }));
      } catch (err) {
        console.error('Failed to load attendees for session', sessionId, err);
        setAttendeesBySession((prev) => ({ ...prev, [sessionId]: [] }));
      }
    },
    [businessId, userId],
  );

  const withMutation = useCallback(
    async (fn: () => Promise<void>) => {
      setSaving(true);
      setError(null);
      try {
        await fn();
        await refresh();
      } catch (err) {
        console.error('Group session mutation failed', err);
        setError(err instanceof Error ? err.message : 'Failed to save group session changes.');
      } finally {
        setSaving(false);
      }
    },
    [refresh],
  );

  return {
    sessions,
    attendeesBySession,
    clients,
    staff,
    services,
    locations,
    loading,
    saving,
    error,
    refresh,
    loadAttendees,
    saveSession: async (input, sessionId) => {
      if (!businessId) return;
      await withMutation(async () => {
        if (sessionId) {
          await updateGroupSession(businessId, sessionId, input, userId);
        } else {
          await createGroupSession(businessId, input, userId);
        }
      });
    },
    deleteSession: async (sessionId) => {
      if (!businessId) return;
      await withMutation(async () => {
        await deleteGroupSession(businessId, sessionId, userId);
      });
    },
    addAttendee: async (sessionId, attendee) => {
      if (!businessId) return;
      await withMutation(async () => {
        await addGroupSessionAttendee(businessId, sessionId, attendee, userId);
      });
      await loadAttendees(sessionId);
    },
    updateAttendee: async (sessionId, attendeeId, updates) => {
      if (!businessId) return;
      await withMutation(async () => {
        await updateGroupSessionAttendee(businessId, sessionId, attendeeId, updates, userId);
      });
      await loadAttendees(sessionId);
    },
    removeAttendee: async (sessionId, attendeeId) => {
      if (!businessId) return;
      await withMutation(async () => {
        await removeGroupSessionAttendee(businessId, sessionId, attendeeId, userId);
      });
      await loadAttendees(sessionId);
    },
  };
}
