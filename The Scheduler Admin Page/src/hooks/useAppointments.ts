import { useCallback, useEffect, useState } from 'react';

import {
  cancelAppointment,
  createAppointment,
  listAppointments,
  updateAppointment,
  type AppointmentInput,
  type AppointmentUpdateInput,
} from '../data/appointments';
import { listClients } from '../data/clients';
import { listLocations } from '../data/locations';
import { listServices } from '../data/services';
import { listStaff } from '../data/staff';
import type { Appointment, Client, Location, Service, StaffMember } from '../types/models';

type UseAppointmentsState = {
  appointments: Appointment[];
  clients: Client[];
  staff: StaffMember[];
  services: Service[];
  locations: Location[];
  loading: boolean;
  saving: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  create: (input: AppointmentInput) => Promise<void>;
  update: (appointmentId: string, updates: AppointmentUpdateInput) => Promise<void>;
  cancel: (
    appointmentId: string,
    metadata?: { reason?: string; notifyClient?: boolean },
  ) => Promise<void>;
};

export type SchedulingConflict = {
  id: string;
  type: 'provider' | 'location';
  key: string;
  appointmentIds: [string, string];
  startTime: string;
  endTime: string;
};

export function useAppointments(businessId?: string, userId?: string): UseAppointmentsState {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      setAppointments([]);
      setClients([]);
      setStaff([]);
      setServices([]);
      setLocations([]);
      setError('Business context required to load appointments.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [appointmentRows, clientRows, staffRows, serviceRows, locationRows] = await Promise.all([
        listAppointments(businessId, {}, userId),
        listClients(businessId, userId),
        listStaff(businessId, userId),
        listServices(businessId, userId),
        listLocations(businessId, userId),
      ]);

      const sorted = [...appointmentRows].sort(
        (a, b) => getAppointmentStart(a).getTime() - getAppointmentStart(b).getTime(),
      );

      setAppointments(sorted);
      setClients(clientRows);
      setStaff(staffRows);
      setServices(serviceRows);
      setLocations(locationRows);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load appointment data.');
      setAppointments([]);
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

  const withMutation = useCallback(
    async (executor: () => Promise<void>) => {
      setSaving(true);
      setError(null);
      try {
        await executor();
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save appointment changes.');
      } finally {
        setSaving(false);
      }
    },
    [refresh],
  );

  return {
    appointments,
    clients,
    staff,
    services,
    locations,
    loading,
    saving,
    error,
    refresh,
    create: async (input) => {
      if (!businessId) return;
      await withMutation(async () => {
        await createAppointment(businessId, input, userId);
      });
    },
    update: async (appointmentId, updates) => {
      if (!businessId) return;
      await withMutation(async () => {
        await updateAppointment(businessId, appointmentId, updates, userId);
      });
    },
    cancel: async (appointmentId, metadata = {}) => {
      if (!businessId) return;
      await withMutation(async () => {
        await cancelAppointment(businessId, appointmentId, metadata, userId);
      });
    },
  };
}

export function findSchedulingConflicts(appointments: Appointment[]): SchedulingConflict[] {
  const rows = appointments
    .filter((appointment) => appointment.status !== 'cancelled')
    .sort((a, b) => getAppointmentStart(a).getTime() - getAppointmentStart(b).getTime());
  const conflicts: SchedulingConflict[] = [];

  for (let i = 0; i < rows.length; i += 1) {
    const current = rows[i];
    const currentStart = getAppointmentStart(current).getTime();
    const currentEnd = getAppointmentEnd(current).getTime();

    for (let j = i + 1; j < rows.length; j += 1) {
      const candidate = rows[j];
      const candidateStart = getAppointmentStart(candidate).getTime();

      if (candidateStart >= currentEnd) break;

      const candidateEnd = getAppointmentEnd(candidate).getTime();
      if (!rangesOverlap(currentStart, currentEnd, candidateStart, candidateEnd)) continue;

      if (current.providerId && candidate.providerId && current.providerId === candidate.providerId) {
        conflicts.push({
          id: `provider:${current.id}:${candidate.id}`,
          type: 'provider',
          key: current.providerId,
          appointmentIds: [current.id, candidate.id],
          startTime: new Date(Math.max(currentStart, candidateStart)).toISOString(),
          endTime: new Date(Math.min(currentEnd, candidateEnd)).toISOString(),
        });
      }

      if (current.locationId && candidate.locationId && current.locationId === candidate.locationId) {
        conflicts.push({
          id: `location:${current.id}:${candidate.id}`,
          type: 'location',
          key: current.locationId,
          appointmentIds: [current.id, candidate.id],
          startTime: new Date(Math.max(currentStart, candidateStart)).toISOString(),
          endTime: new Date(Math.min(currentEnd, candidateEnd)).toISOString(),
        });
      }
    }
  }

  return conflicts;
}

function getAppointmentStart(appointment: Appointment): Date {
  return new Date(appointment.startTime ?? appointment.start ?? appointment.createdAt ?? 0);
}

function getAppointmentEnd(appointment: Appointment): Date {
  return new Date(appointment.endTime ?? appointment.end ?? appointment.startTime ?? appointment.start ?? 0);
}

function rangesOverlap(startA: number, endA: number, startB: number, endB: number): boolean {
  return startA < endB && startB < endA;
}
