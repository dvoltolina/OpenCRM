import { useMemo, useState } from 'react';

import type {
  Client,
  GroupSession,
  GroupSessionAttendee,
  Location,
  Service,
  StaffMember,
} from '../../types/models';
import type {
  GroupSessionAttendeeInput,
  GroupSessionInput,
} from '../../data/groupSessions';

type StaffOption = { id: string; label: string };
type ServiceOption = { id: string; label: string; colorHex?: string };
type LocationOption = { id: string; label: string };
type ClientOption = { id: string; label: string };

export function SessionDialog({
  session,
  services,
  staff,
  locations,
  onClose,
  onSubmit,
}: {
  session: GroupSession | null;
  services: Service[];
  staff: StaffMember[];
  locations: Location[];
  onClose: () => void;
  onSubmit: (input: GroupSessionInput) => void;
}) {
  const [form, setForm] = useState<GroupSessionInput>(() =>
    session
      ? {
          title: session.title,
          serviceId: session.serviceId,
          providerIds: session.providerIds,
          locationId: session.locationId,
          start: session.start,
          end: session.end,
          capacity: session.capacity,
          attendeeIds: session.attendeeIds,
          waitlistIds: session.waitlistIds,
          visibility: session.visibility,
          registrationDeadline: session.registrationDeadline,
          allowWaitlist: session.allowWaitlist ?? true,
          notes: session.notes,
          requiredResourceIds: session.requiredResourceIds,
        }
      : {
          title: '',
          serviceId: services[0]?.id ?? '',
          providerIds: [],
          locationId: locations[0]?.id,
          start: new Date().toISOString(),
          end: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
          capacity: 10,
          attendeeIds: [],
          waitlistIds: [],
          visibility: 'public',
          registrationDeadline: undefined,
          allowWaitlist: true,
          notes: '',
          requiredResourceIds: [],
        },
  );

  const staffOptions = useMemo<StaffOption[]>(
    () => staff.map((member) => ({ id: member.id, label: member.displayName ?? member.id })),
    [staff],
  );

  const serviceOptions = useMemo<ServiceOption[]>(
    () => services.map((service) => ({ id: service.id, label: service.name, colorHex: service.colorHex })),
    [services],
  );

  const locationOptions = useMemo<LocationOption[]>(
    () => locations.map((location) => ({ id: location.id, label: location.name })),
    [locations],
  );

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSubmit({
      ...form,
      start: toIsoString(form.start),
      end: toIsoString(form.end),
      registrationDeadline: form.registrationDeadline ? toIsoString(form.registrationDeadline) : undefined,
    });
  };

  return (
    <div className="dialog-overlay" onClick={onClose}>
      <div className="dialog dialog--large" onClick={(event) => event.stopPropagation()}>
        <h2>{session ? 'Edit group session' : 'New group session'}</h2>
        <form className="stack" onSubmit={handleSubmit}>
          <label>
            Title
            <input
              type="text"
              value={form.title}
              onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
              required
            />
          </label>
          <div className="grid grid--2">
            <label>
              Service
              <select
                value={form.serviceId}
                onChange={(e) => setForm((prev) => ({ ...prev, serviceId: e.target.value }))}
              >
                {serviceOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Location
              <select
                value={form.locationId ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, locationId: e.target.value || undefined }))}
              >
                <option value="">Virtual / unspecified</option>
                {locationOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
          <div className="grid grid--2">
            <label>
              Start
              <input
                type="datetime-local"
                value={toLocalInputValue(form.start)}
                onChange={(e) => setForm((prev) => ({ ...prev, start: e.target.value }))}
                required
              />
            </label>
            <label>
              End
              <input
                type="datetime-local"
                value={toLocalInputValue(form.end)}
                onChange={(e) => setForm((prev) => ({ ...prev, end: e.target.value }))}
                required
              />
            </label>
          </div>
          <div className="grid grid--2">
            <label>
              Capacity
              <input
                type="number"
                min={1}
                value={form.capacity}
                onChange={(e) => setForm((prev) => ({ ...prev, capacity: Number(e.target.value) || 1 }))}
              />
            </label>
            <label>
              Visibility
              <select
                value={form.visibility}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, visibility: e.target.value as GroupSession['visibility'] }))
                }
              >
                <option value="public">Public</option>
                <option value="internal">Internal</option>
              </select>
            </label>
          </div>
          <label>
            Registration deadline
            <input
              type="datetime-local"
              value={form.registrationDeadline ? toLocalInputValue(form.registrationDeadline) : ''}
              onChange={(e) =>
                setForm((prev) => ({ ...prev, registrationDeadline: e.target.value || undefined }))
              }
            />
          </label>
          <label className="checkbox">
            <input
              type="checkbox"
              checked={form.allowWaitlist ?? true}
              onChange={(e) => setForm((prev) => ({ ...prev, allowWaitlist: e.target.checked }))}
            />
            Allow waitlist signup
          </label>
          <fieldset>
            <legend>Facilitators</legend>
            <div className="chip-row chip-row--wrap">
              {staffOptions.map((option) => (
                <label key={option.id} className="chip chip--outline">
                  <input
                    type="checkbox"
                    checked={form.providerIds.includes(option.id)}
                    onChange={() =>
                      setForm((prev) => ({
                        ...prev,
                        providerIds: toggleValue(prev.providerIds, option.id),
                      }))
                    }
                  />
                  {option.label}
                </label>
              ))}
            </div>
          </fieldset>
          <label>
            Notes
            <textarea
              rows={3}
              value={form.notes ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, notes: e.target.value }))}
              placeholder="Prep instructions, virtual meeting link, etc."
            />
          </label>
          <div className="dialog-actions">
            <button type="button" onClick={onClose}>
              Cancel
            </button>
            <button type="submit">{session ? 'Save changes' : 'Create session'}</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function SessionCard({
  session,
  serviceLabel,
  locationLabel,
  providerLabels,
  waitlistCount,
  onSelect,
  onEdit,
  onDelete,
  selected,
}: {
  session: GroupSession;
  serviceLabel: string;
  locationLabel?: string;
  providerLabels: string[];
  waitlistCount: number;
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
  selected: boolean;
}) {
  const confirmed = session.attendeeIds.length;
  const remaining = Math.max(session.capacity - confirmed, 0);

  return (
    <div className={`panel session-card${selected ? ' session-card--selected' : ''}`}>
      <button className="session-card__overlay" type="button" onClick={onSelect} aria-label="View details" />
      <div className="panel__subheader" style={{ justifyContent: 'space-between' }}>
        <div>
          <div className="panel__title">{session.title}</div>
          <p className="muted">{serviceLabel}</p>
        </div>
        <div className="chip chip--ghost">{session.visibility === 'public' ? 'Public' : 'Internal'}</div>
      </div>
      <dl className="meta-grid">
        <div>
          <dt className="eyebrow">When</dt>
          <dd>
            {formatDateRange(session.start, session.end)}
            {session.registrationDeadline && (
              <span className="muted"> · Register by {formatShortDate(session.registrationDeadline)}</span>
            )}
          </dd>
        </div>
        <div>
          <dt className="eyebrow">Location</dt>
          <dd>{locationLabel ?? 'Virtual / TBD'}</dd>
        </div>
      </dl>
      <div className="stack">
        <div className="chip-row chip-row--wrap">
          {providerLabels.length === 0 ? (
            <span className="muted">No facilitators assigned</span>
          ) : (
            providerLabels.map((label) => (
              <span className="chip chip--ghost" key={label}>
                {label}
              </span>
            ))
          )}
        </div>
        <div className="session-metrics">
          <div>
            <span className="eyebrow">Capacity</span>
            <strong>
              {confirmed}/{session.capacity}
            </strong>
          </div>
          <div>
            <span className="eyebrow">Seats left</span>
            <strong>{remaining}</strong>
          </div>
          <div>
            <span className="eyebrow">Waitlist</span>
            <strong>{waitlistCount}</strong>
          </div>
        </div>
        <div className="session-card__actions">
          <button className="button button--ghost" type="button" onClick={onEdit}>
            Edit
          </button>
          <button className="button button--ghost" type="button" onClick={onDelete}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}

export function AttendeePanel({
  session,
  attendees,
  clients,
  onAddAttendee,
  onUpdateAttendee,
  onRemoveAttendee,
}: {
  session: GroupSession;
  attendees: GroupSessionAttendee[];
  clients: Client[];
  onAddAttendee: (input: GroupSessionAttendeeInput) => void;
  onUpdateAttendee: (attendeeId: string, updates: Partial<GroupSessionAttendeeInput>) => void;
  onRemoveAttendee: (attendeeId: string) => void;
}) {
  const clientLookup = useMemo(
    () => Object.fromEntries(clients.map((client) => [client.id, client])),
    [clients],
  );
  const [selectedClientId, setSelectedClientId] = useState('');

  const confirmed = attendees.filter((attendee) => attendee.status === 'confirmed');
  const waitlisted = attendees.filter((attendee) => attendee.status === 'waitlisted');

  const handleAdd = () => {
    if (!selectedClientId) return;
    onAddAttendee({ clientId: selectedClientId, status: confirmed.length < session.capacity ? 'confirmed' : 'waitlisted' });
    setSelectedClientId('');
  };

  return (
    <div className="panel">
      <div className="panel__subheader">
        <div>
          <div className="panel__title">Attendees</div>
          <p className="muted">
            {confirmed.length}/{session.capacity} confirmed · {waitlisted.length} waitlisted
          </p>
        </div>
        <div className="attendee-add">
          <select value={selectedClientId} onChange={(e) => setSelectedClientId(e.target.value)}>
            <option value="">Select client</option>
            {clients.map((client) => (
              <option key={client.id} value={client.id}>
                {client.name}
              </option>
            ))}
          </select>
          <button className="button button--primary" type="button" onClick={handleAdd} disabled={!selectedClientId}>
            Add
          </button>
        </div>
      </div>

      <div className="stack">
        <AttendeeList
          title="Confirmed"
          attendees={confirmed}
          clientLookup={clientLookup}
          onStatusChange={(attendee, status) => onUpdateAttendee(attendee.id, { status })}
          onRemove={(attendee) => onRemoveAttendee(attendee.id)}
        />
        <AttendeeList
          title="Waitlist"
          attendees={waitlisted}
          clientLookup={clientLookup}
          onStatusChange={(attendee, status) => onUpdateAttendee(attendee.id, { status })}
          onRemove={(attendee) => onRemoveAttendee(attendee.id)}
        />
      </div>
    </div>
  );
}

function AttendeeList({
  title,
  attendees,
  clientLookup,
  onStatusChange,
  onRemove,
}: {
  title: string;
  attendees: GroupSessionAttendee[];
  clientLookup: Record<string, Client | undefined>;
  onStatusChange: (attendee: GroupSessionAttendee, status: GroupSessionAttendee['status']) => void;
  onRemove: (attendee: GroupSessionAttendee) => void;
}) {
  return (
    <div className="attendee-list">
      <div className="attendee-list__header">
        <div className="panel__title">{title}</div>
        <span className="muted">{attendees.length}</span>
      </div>
      {attendees.length === 0 ? (
        <p className="muted">None yet.</p>
      ) : (
        <ul>
          {attendees.map((attendee) => {
            const client = clientLookup[attendee.clientId];
            return (
              <li key={attendee.id} className="attendee-row">
                <div>
                  <strong>{client?.name ?? attendee.clientId}</strong>
                  {client?.email && <p className="muted">{client.email}</p>}
                </div>
                <div className="attendee-row__actions">
                  {attendee.status !== 'confirmed' && (
                    <button type="button" onClick={() => onStatusChange(attendee, 'confirmed')}>
                      Confirm
                    </button>
                  )}
                  {attendee.status !== 'waitlisted' && (
                    <button type="button" onClick={() => onStatusChange(attendee, 'waitlisted')}>
                      Waitlist
                    </button>
                  )}
                  <button type="button" onClick={() => onRemove(attendee)}>
                    Remove
                  </button>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}

export function buildServiceOptionsForSessions(services: Service[]): ServiceOption[] {
  return services.map((service) => ({
    id: service.id,
    label: service.name,
    colorHex: service.colorHex,
  }));
}

export function buildStaffOptionsForSessions(staff: StaffMember[]): StaffOption[] {
  return staff.map((member) => ({ id: member.id, label: member.displayName ?? member.id }));
}

export function buildLocationOptions(locations: Location[]): LocationOption[] {
  return locations.map((location) => ({ id: location.id, label: location.name }));
}

export function buildClientOptions(clients: Client[]): ClientOption[] {
  return clients.map((client) => ({ id: client.id, label: client.name }));
}

function toggleValue(list: string[], value: string) {
  return list.includes(value) ? list.filter((item) => item !== value) : [...list, value];
}

function toLocalInputValue(value: string | undefined) {
  if (!value) return '';
  const date = new Date(value);
  return `${date.getFullYear().toString().padStart(4, '0')}-${(date.getMonth() + 1)
    .toString()
    .padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}T${date
    .getHours()
    .toString()
    .padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
}

function toIsoString(value: string | undefined) {
  if (!value) return undefined;
  const date = new Date(value);
  return date.toISOString();
}

function formatDateRange(start: string, end: string) {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const startFormatter = startDate.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
  const endFormatter = endDate.toLocaleTimeString(undefined, {
    timeStyle: 'short',
  });
  return `${startFormatter} - ${endFormatter}`;
}

function formatShortDate(value?: string) {
  if (!value) return '';
  return new Date(value).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
  });
}


