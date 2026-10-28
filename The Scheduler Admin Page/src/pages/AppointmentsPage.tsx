import { type CSSProperties, type FormEvent, useMemo, useState } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { findSchedulingConflicts, useAppointments } from '../hooks/useAppointments';
import type { Appointment, AppointmentStatus } from '../types/models';
import {
  CreateAppointmentDialog,
  EditAppointmentDialog,
  EMPTY_APPOINTMENT_FORM,
  type AppointmentFormState,
} from './appointments/AppointmentDialogs';

type Filters = {
  status: 'all' | AppointmentStatus;
  providerId: 'all' | string;
  serviceId: 'all' | string;
  locationId: 'all' | string;
  search: string;
};

type AppointmentRow = Appointment & {
  clientName: string;
  providerName: string;
  serviceName: string;
  locationName: string;
};

const INITIAL_FILTERS: Filters = {
  status: 'all',
  providerId: 'all',
  serviceId: 'all',
  locationId: 'all',
  search: '',
};

export function AppointmentsPage() {
  const { businessId, userId } = useBusinessContext({ requireBusinessId: true });
  const {
    appointments,
    clients,
    staff,
    services,
    locations,
    loading,
    saving,
    error,
    refresh,
    create,
    update,
    cancel,
  } = useAppointments(businessId, userId);

  const [filters, setFilters] = useState<Filters>(INITIAL_FILTERS);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editing, setEditing] = useState<AppointmentRow | null>(null);
  const [createForm, setCreateForm] = useState<AppointmentFormState>(EMPTY_APPOINTMENT_FORM);
  const [editForm, setEditForm] = useState<AppointmentFormState>(EMPTY_APPOINTMENT_FORM);
  const [editStatus, setEditStatus] = useState<AppointmentStatus>('pending');
  const [cancelReason, setCancelReason] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  const clientMap = useMemo(() => Object.fromEntries(clients.map((client) => [client.id, client])), [clients]);
  const staffMap = useMemo(() => Object.fromEntries(staff.map((member) => [member.id, member])), [staff]);
  const serviceMap = useMemo(() => Object.fromEntries(services.map((service) => [service.id, service])), [services]);
  const locationMap = useMemo(
    () => Object.fromEntries(locations.map((location) => [location.id, location])),
    [locations],
  );

  const rows = useMemo<AppointmentRow[]>(
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

  const filteredRows = useMemo(() => {
    return rows.filter((row) => {
      if (filters.status !== 'all' && row.status !== filters.status) return false;
      if (filters.providerId !== 'all' && row.providerId !== filters.providerId) return false;
      if (filters.serviceId !== 'all' && row.serviceId !== filters.serviceId) return false;
      if (filters.locationId !== 'all' && row.locationId !== filters.locationId) return false;
      if (filters.search) {
        const term = filters.search.toLowerCase();
        const searchBlob = `${row.clientName} ${row.providerName} ${row.serviceName} ${row.locationName}`;
        if (!searchBlob.toLowerCase().includes(term)) return false;
      }
      return true;
    });
  }, [filters, rows]);

  const conflicts = useMemo(() => findSchedulingConflicts(filteredRows).slice(0, 8), [filteredRows]);

  const handleOpenCreate = () => {
    const now = new Date();
    const plusHour = new Date(now.getTime() + 60 * 60 * 1000);
    setCreateForm({
      ...EMPTY_APPOINTMENT_FORM,
      clientId: clients[0]?.id ?? '',
      providerId: staff[0]?.id ?? '',
      serviceId: services[0]?.id ?? '',
      locationId: locations[0]?.id ?? '',
      startTime: toLocalInputValue(now.toISOString()),
      endTime: toLocalInputValue(plusHour.toISOString()),
    });
    setFormError(null);
    setShowCreateDialog(true);
  };

  const handleCreateFieldChange = (field: keyof AppointmentFormState, value: string) => {
    setCreateForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setFormError(null);

    if (!createForm.clientId || !createForm.providerId || !createForm.serviceId || !createForm.startTime || !createForm.endTime) {
      setFormError('Client, provider, service, start time, and end time are required.');
      return;
    }

    const startIso = toIsoString(createForm.startTime);
    const endIso = toIsoString(createForm.endTime);
    if (!startIso || !endIso || new Date(endIso).getTime() <= new Date(startIso).getTime()) {
      setFormError('End time must be after the start time.');
      return;
    }

    await create({
      clientId: createForm.clientId,
      providerId: createForm.providerId,
      serviceId: createForm.serviceId,
      locationId: createForm.locationId || undefined,
      startTime: startIso,
      endTime: endIso,
      notes: createForm.notes.trim() || undefined,
    });
    setShowCreateDialog(false);
  };

  const handleOpenEdit = (row: AppointmentRow) => {
    setEditing(row);
    setEditStatus(row.status);
    setCancelReason('');
    setFormError(null);
    setEditForm({
      clientId: row.clientId,
      providerId: row.providerId,
      serviceId: row.serviceId,
      locationId: row.locationId ?? '',
      startTime: toLocalInputValue(row.startTime ?? row.start),
      endTime: toLocalInputValue(row.endTime ?? row.end),
      notes: '',
    });
  };

  const handleEditFieldChange = (field: keyof AppointmentFormState, value: string) => {
    setEditForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleSaveEdit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!editing) return;
    setFormError(null);

    const startIso = toIsoString(editForm.startTime);
    const endIso = toIsoString(editForm.endTime);
    if (!startIso || !endIso || new Date(endIso).getTime() <= new Date(startIso).getTime()) {
      setFormError('End time must be after the start time.');
      return;
    }

    await update(editing.id, {
      status: editStatus,
      providerId: editForm.providerId,
      serviceId: editForm.serviceId,
      locationId: editForm.locationId || undefined,
      startTime: startIso,
      endTime: endIso,
      notes: editForm.notes.trim() || undefined,
    });
    setEditing(null);
  };

  const handleCancelAppointment = async () => {
    if (!editing) return;
    await cancel(editing.id, {
      reason: cancelReason.trim() || undefined,
      notifyClient: false,
    });
    setEditing(null);
  };

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Operations</p>
          <h1>Appointments</h1>
          <p className="muted">
            Manage tenant appointments with shared `appointments-create`, `appointments-update`, and
            `appointments-cancel` callables.
          </p>
        </div>
        <div className="header-actions">
          <button className="button button--ghost" type="button" onClick={() => void refresh()} disabled={loading}>
            Refresh
          </button>
          <button className="button button--primary" type="button" onClick={handleOpenCreate}>
            New appointment
          </button>
        </div>
      </header>

      {error ? (
        <div className="panel panel--alert" style={{ marginBottom: 16 }}>
          <p className="muted">{error}</p>
        </div>
      ) : null}

      <div className="panel" style={{ marginBottom: 16 }}>
        <h2>Filters</h2>
        <div className="grid grid--2">
          <label>
            <span className="eyebrow">Search</span>
            <input
              type="search"
              placeholder="Client, provider, service, location"
              value={filters.search}
              onChange={(event) => setFilters((prev) => ({ ...prev, search: event.target.value }))}
            />
          </label>

          <label>
            <span className="eyebrow">Status</span>
            <select
              value={filters.status}
              onChange={(event) => setFilters((prev) => ({ ...prev, status: event.target.value as Filters['status'] }))}
            >
              <option value="all">All statuses</option>
              <option value="pending">Pending</option>
              <option value="confirmed">Confirmed</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
              <option value="noShow">No show</option>
            </select>
          </label>

          <label>
            <span className="eyebrow">Provider</span>
            <select
              value={filters.providerId}
              onChange={(event) =>
                setFilters((prev) => ({ ...prev, providerId: event.target.value as Filters['providerId'] }))
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
                setFilters((prev) => ({ ...prev, serviceId: event.target.value as Filters['serviceId'] }))
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
                setFilters((prev) => ({ ...prev, locationId: event.target.value as Filters['locationId'] }))
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

      <div className="panel" style={{ marginBottom: 16 }}>
        <h2>Appointment Queue ({filteredRows.length})</h2>
        <p className="muted">{loading ? 'Loading appointments…' : 'Click a row to edit, reschedule, or cancel.'}</p>
        <div className="table">
          <div className="table__head">
            <span>Start</span>
            <span>Client</span>
            <span>Provider</span>
            <span>Service</span>
            <span>Location</span>
            <span>Status</span>
          </div>
          {filteredRows.length === 0 && !loading ? (
            <div className="empty-state">No appointments match the current filters.</div>
          ) : null}
          {filteredRows.map((row) => (
            <div
              key={row.id}
              className="table__row"
              role="button"
              onClick={() => handleOpenEdit(row)}
            >
              <span>{formatDateTime(row.startTime ?? row.start)}</span>
              <span>{row.clientName}</span>
              <span>{row.providerName}</span>
              <span>{row.serviceName}</span>
              <span>{row.locationName}</span>
              <span>
                <span style={statusBadgeStyle(row.status)}>{row.status}</span>
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="panel panel--alert">
        <h2>Live Conflict Checks ({conflicts.length})</h2>
        <p className="muted">
          Derived from overlapping appointment windows by provider or location in the current filtered set.
        </p>
        {conflicts.length === 0 ? (
          <p className="muted">No conflicts detected in this view.</p>
        ) : (
          <ul className="list">
            {conflicts.map((conflict) => (
              <li key={conflict.id}>
                {conflict.type === 'provider'
                  ? `Provider conflict (${staffMap[conflict.key]?.displayName ?? conflict.key})`
                  : `Location conflict (${locationMap[conflict.key]?.name ?? conflict.key})`}{' '}
                · {formatDateTime(conflict.startTime)} to {formatTime(conflict.endTime)}
              </li>
            ))}
          </ul>
        )}
      </div>

      <CreateAppointmentDialog
        open={showCreateDialog}
        form={createForm}
        clients={clients}
        staff={staff}
        services={services}
        locations={locations}
        saving={saving}
        formError={formError}
        onClose={() => setShowCreateDialog(false)}
        onSubmit={handleCreate}
        onChange={handleCreateFieldChange}
      />

      <EditAppointmentDialog
        open={Boolean(editing)}
        title={editing?.clientName ?? ''}
        serviceName={editing?.serviceName ?? ''}
        form={editForm}
        status={editStatus}
        cancelReason={cancelReason}
        staff={staff}
        services={services}
        locations={locations}
        saving={saving}
        formError={formError}
        onClose={() => setEditing(null)}
        onSubmit={handleSaveEdit}
        onCancelAppointment={() => void handleCancelAppointment()}
        onChange={handleEditFieldChange}
        onStatusChange={setEditStatus}
        onCancelReasonChange={setCancelReason}
      />
    </section>
  );
}

function toLocalInputValue(value: string | undefined): string {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const year = date.getFullYear().toString().padStart(4, '0');
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:${minutes}`;
}

function toIsoString(value: string | undefined): string | undefined {
  if (!value) return undefined;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString();
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

function statusBadgeStyle(status: AppointmentStatus): CSSProperties {
  const tone: Record<AppointmentStatus, { background: string; color: string }> = {
    pending: { background: '#fef3c7', color: '#78350f' },
    confirmed: { background: '#dcfce7', color: '#166534' },
    completed: { background: '#dbeafe', color: '#1d4ed8' },
    cancelled: { background: '#fee2e2', color: '#991b1b' },
    noShow: { background: '#e2e8f0', color: '#334155' },
  };

  return {
    display: 'inline-block',
    padding: '4px 10px',
    borderRadius: 8,
    backgroundColor: tone[status].background,
    color: tone[status].color,
    fontSize: 12,
    fontWeight: 600,
    textTransform: 'uppercase',
    letterSpacing: '0.02em',
  };
}
