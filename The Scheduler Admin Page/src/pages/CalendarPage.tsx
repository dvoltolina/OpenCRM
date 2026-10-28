import { useMemo, useState } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { findSchedulingConflicts, useAppointments } from '../hooks/useAppointments';
import type { Appointment } from '../types/models';

type CalendarFilters = {
  providerId: 'all' | string;
  serviceId: 'all' | string;
  locationId: 'all' | string;
};

type CalendarRow = Appointment & {
  clientName: string;
  providerName: string;
  serviceName: string;
  locationName: string;
};

const INITIAL_FILTERS: CalendarFilters = {
  providerId: 'all',
  serviceId: 'all',
  locationId: 'all',
};

export function CalendarPage() {
  const { businessId, userId } = useBusinessContext({ requireBusinessId: true });
  const { appointments, clients, staff, services, locations, loading, error, refresh } = useAppointments(
    businessId,
    userId,
  );

  const [selectedDay, setSelectedDay] = useState(() => toDayKey(new Date()));
  const [filters, setFilters] = useState<CalendarFilters>(INITIAL_FILTERS);

  const clientMap = useMemo(() => Object.fromEntries(clients.map((client) => [client.id, client])), [clients]);
  const staffMap = useMemo(() => Object.fromEntries(staff.map((member) => [member.id, member])), [staff]);
  const serviceMap = useMemo(() => Object.fromEntries(services.map((service) => [service.id, service])), [services]);
  const locationMap = useMemo(
    () => Object.fromEntries(locations.map((location) => [location.id, location])),
    [locations],
  );

  const rows = useMemo<CalendarRow[]>(
    () =>
      appointments.map((appointment) => ({
        ...appointment,
        clientName: clientMap[appointment.clientId]?.name ?? appointment.clientId,
        providerName: staffMap[appointment.providerId]?.displayName ?? appointment.providerId,
        serviceName: serviceMap[appointment.serviceId]?.name ?? appointment.serviceId,
        locationName: appointment.locationId
          ? locationMap[appointment.locationId]?.name ?? appointment.locationId
          : 'Unassigned',
      })),
    [appointments, clientMap, locationMap, serviceMap, staffMap],
  );

  const dayRows = useMemo(
    () =>
      rows
        .filter((row) => {
          if (!isSameDay(row.startTime ?? row.start, selectedDay)) return false;
          if (filters.providerId !== 'all' && row.providerId !== filters.providerId) return false;
          if (filters.serviceId !== 'all' && row.serviceId !== filters.serviceId) return false;
          if (filters.locationId !== 'all' && row.locationId !== filters.locationId) return false;
          return row.status !== 'cancelled';
        })
        .sort(
          (a, b) =>
            new Date(a.startTime ?? a.start ?? 0).getTime() -
            new Date(b.startTime ?? b.start ?? 0).getTime(),
        ),
    [filters.locationId, filters.providerId, filters.serviceId, rows, selectedDay],
  );

  const conflicts = useMemo(() => findSchedulingConflicts(dayRows), [dayRows]);

  const timelineRows = useMemo(() => {
    const byHour = new Map<number, CalendarRow[]>();
    for (let hour = 6; hour <= 21; hour += 1) {
      byHour.set(hour, []);
    }
    dayRows.forEach((row) => {
      const hour = new Date(row.startTime ?? row.start ?? 0).getHours();
      const bucket = byHour.get(hour);
      if (bucket) {
        bucket.push(row);
      } else {
        byHour.set(hour, [row]);
      }
    });
    return Array.from(byHour.entries());
  }, [dayRows]);

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Scheduling</p>
          <h1>Calendar</h1>
          <p className="muted">
            Operational day board sourced from tenant `appointments` with provider, service, and location filters.
          </p>
        </div>
        <div className="header-actions">
          <button className="button button--ghost" type="button" onClick={() => void refresh()} disabled={loading}>
            Refresh
          </button>
          <a className="button button--primary" href="/appointments">
            Open appointments
          </a>
        </div>
      </header>

      {error ? (
        <div className="panel panel--alert" style={{ marginBottom: 16 }}>
          <p className="muted">{error}</p>
        </div>
      ) : null}

      <div className="panel" style={{ marginBottom: 16 }}>
        <h2>Calendar Controls</h2>
        <div className="grid grid--2">
          <label>
            <span className="eyebrow">Day</span>
            <input
              type="date"
              value={selectedDay}
              onChange={(event) => setSelectedDay(event.target.value)}
            />
          </label>

          <label>
            <span className="eyebrow">Provider</span>
            <select
              value={filters.providerId}
              onChange={(event) =>
                setFilters((prev) => ({ ...prev, providerId: event.target.value as CalendarFilters['providerId'] }))
              }
            >
              <option value="all">All providers</option>
              {staff.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.displayName}
                </option>
              ))}
            </select>
          </label>

          <label>
            <span className="eyebrow">Service</span>
            <select
              value={filters.serviceId}
              onChange={(event) =>
                setFilters((prev) => ({ ...prev, serviceId: event.target.value as CalendarFilters['serviceId'] }))
              }
            >
              <option value="all">All services</option>
              {services.map((service) => (
                <option key={service.id} value={service.id}>
                  {service.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            <span className="eyebrow">Location</span>
            <select
              value={filters.locationId}
              onChange={(event) =>
                setFilters((prev) => ({ ...prev, locationId: event.target.value as CalendarFilters['locationId'] }))
              }
            >
              <option value="all">All locations</option>
              {locations.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      <div className="grid grid--3" style={{ marginBottom: 16 }}>
        <div className="panel">
          <div className="eyebrow">Appointments</div>
          <h2>{dayRows.length}</h2>
          <p className="muted">Scheduled on {formatDateLabel(selectedDay)}</p>
        </div>
        <div className="panel">
          <div className="eyebrow">Providers Active</div>
          <h2>{new Set(dayRows.map((row) => row.providerId)).size}</h2>
          <p className="muted">With at least one active appointment</p>
        </div>
        <div className="panel">
          <div className="eyebrow">Conflicts</div>
          <h2>{conflicts.length}</h2>
          <p className="muted">Overlapping provider/location assignments</p>
        </div>
      </div>

      <div className="panel" style={{ marginBottom: 16 }}>
        <h2>Conflict Feed</h2>
        {conflicts.length === 0 ? (
          <p className="muted">No provider or location conflicts detected for this day.</p>
        ) : (
          <ul className="list">
            {conflicts.map((conflict) => (
              <li key={conflict.id}>
                {conflict.type === 'provider'
                  ? `Provider overlap (${staffMap[conflict.key]?.displayName ?? conflict.key})`
                  : `Location overlap (${locationMap[conflict.key]?.name ?? conflict.key})`}{' '}
                · {formatDateTime(conflict.startTime)} to {formatTime(conflict.endTime)}
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="panel">
        <h2>Day Timeline</h2>
        {loading ? <p className="muted">Loading calendar timeline…</p> : null}
        {!loading && dayRows.length === 0 ? (
          <p className="muted">No active appointments for this day and filter combination.</p>
        ) : null}
        <div className="stack">
          {timelineRows.map(([hour, entries]) => (
            <div key={hour} className="meta-row" style={{ alignItems: 'flex-start', borderBottom: '1px solid #e2e8f0', paddingBottom: 10 }}>
              <div style={{ minWidth: 72 }}>
                <strong>{formatHour(hour)}</strong>
              </div>
              <div style={{ flex: 1 }}>
                {entries.length === 0 ? (
                  <span className="muted">No bookings</span>
                ) : (
                  <div className="chip-row chip-row--wrap">
                    {entries.map((entry) => (
                        <span key={entry.id} className="chip chip--ghost">
                        {formatTime(entry.startTime ?? entry.start)} {entry.clientName} · {entry.providerName} · {entry.serviceName} ·{' '}
                        {entry.locationName}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function isSameDay(isoDateTime: string | undefined, day: string): boolean {
  if (!isoDateTime) return false;
  return toDayKey(new Date(isoDateTime)) === day;
}

function formatDateLabel(value: string): string {
  return new Date(value).toLocaleDateString(undefined, { dateStyle: 'medium' });
}

function formatDateTime(value?: string): string {
  if (!value) return 'Unknown';
  return new Date(value).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function formatTime(value?: string): string {
  if (!value) return 'Unknown';
  return new Date(value).toLocaleTimeString(undefined, { timeStyle: 'short' });
}

function formatHour(hour: number): string {
  const date = new Date();
  date.setHours(hour, 0, 0, 0);
  return date.toLocaleTimeString(undefined, { hour: 'numeric' });
}

function toDayKey(date: Date): string {
  const year = date.getFullYear().toString().padStart(4, '0');
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}
