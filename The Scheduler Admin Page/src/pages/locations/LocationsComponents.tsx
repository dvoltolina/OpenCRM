import { useEffect, useMemo, useState } from 'react';

import type {
  Resource,
  ResourceConflict,
  ResourceInput,
  Service,
  StaffMember,
} from '../../types/models';
import { LocationDialog } from './LocationDialog';
import type { ServiceOption, StaffOption } from './locationTypes';

export { LocationDialog };

export function ResourceDialog({
  resource,
  locationId,
  staffOptions,
  serviceOptions,
  onClose,
  onSave,
}: {
  resource: Resource | null;
  locationId: string;
  staffOptions: StaffOption[];
  serviceOptions: ServiceOption[];
  onClose: () => void;
  onSave: (input: ResourceInput) => void;
}) {
  const [form, setForm] = useState<ResourceInput>(() =>
    resource ?? {
      locationId,
      name: '',
      type: 'room',
      status: 'available',
      tags: [],
      assignedStaffIds: [],
      serviceIds: [],
      maintenanceNote: '',
      capacity: 1,
      colorHex: '#475569',
      isShared: false,
    },
  );

  useEffect(() => {
    setForm(
      resource ?? {
        locationId,
        name: '',
        type: 'room',
        status: 'available',
        tags: [],
        assignedStaffIds: [],
        serviceIds: [],
        maintenanceNote: '',
        capacity: 1,
        colorHex: '#475569',
        isShared: false,
      },
    );
  }, [resource, locationId]);

  // Close dialog on Escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  const toggleValue = (key: 'assignedStaffIds' | 'serviceIds', value: string) => {
    setForm((prev) => {
      const list = prev[key] ?? [];
      return {
        ...prev,
        [key]: list.includes(value) ? list.filter((id) => id !== value) : [...list, value],
      };
    });
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSave({
      ...form,
      tags: form.tags?.filter(Boolean),
    });
  };

  return (
    <div
      className="dialog-overlay"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="resource-dialog-title"
    >
      <div className="dialog" onClick={(e) => e.stopPropagation()}>
        <h2 id="resource-dialog-title">{resource ? 'Edit resource' : 'New resource'}</h2>
        <form className="stack" onSubmit={handleSubmit}>
          <label>
            Name
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
              required
            />
          </label>
          <div className="grid grid--2">
            <label>
              Type
              <select
                value={form.type}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, type: e.target.value as ResourceInput['type'] }))
                }
              >
                <option value="room">Room</option>
                <option value="equipment">Equipment</option>
              </select>
            </label>
            <label>
              Status
              <select
                value={form.status}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    status: e.target.value as ResourceInput['status'],
                  }))
                }
              >
                <option value="available">Available</option>
                <option value="in_use">In use</option>
                <option value="maintenance">Maintenance</option>
              </select>
            </label>
          </div>
          <label>
            Capacity
            <input
              type="number"
              min={1}
              value={form.capacity ?? 1}
              onChange={(e) =>
                setForm((prev) => ({ ...prev, capacity: Number(e.target.value) || 1 }))
              }
            />
          </label>
          <div className="grid grid--2">
            <label>
              Color
              <input
                type="color"
                value={form.colorHex ?? '#475569'}
                onChange={(e) => setForm((prev) => ({ ...prev, colorHex: e.target.value }))}
              />
            </label>
            <label className="meta-row" style={{ alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={form.isShared ?? false}
                onChange={(e) => setForm((prev) => ({ ...prev, isShared: e.target.checked }))}
              />
              Shared resource
            </label>
          </div>
          <label>
            Tags (comma separated)
            <input
              type="text"
              value={form.tags?.join(', ') ?? ''}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  tags: e.target.value
                    .split(',')
                    .map((tag) => tag.trim())
                    .filter(Boolean),
                }))
              }
            />
          </label>
          {form.status === 'maintenance' && (
            <label>
              Maintenance note
              <textarea
                rows={3}
                value={form.maintenanceNote ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, maintenanceNote: e.target.value }))}
                placeholder="Blocked until repairs complete"
              />
            </label>
          )}
          <fieldset>
            <legend>Assigned staff</legend>
            <div className="chip-row chip-row--wrap">
              {staffOptions.map((option) => (
                <label key={option.id} className="chip chip--outline" style={{ cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={form.assignedStaffIds?.includes(option.id)}
                    onChange={() => toggleValue('assignedStaffIds', option.id)}
                  />
                  {option.label}
                </label>
              ))}
            </div>
          </fieldset>
          <fieldset>
            <legend>Linked services</legend>
            <div className="chip-row chip-row--wrap">
              {serviceOptions.map((option) => (
                <label key={option.id} className="chip chip--outline" style={{ cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={form.serviceIds?.includes(option.id)}
                    onChange={() => toggleValue('serviceIds', option.id)}
                  />
                  {option.label}
                </label>
              ))}
            </div>
          </fieldset>
          <div className="dialog-actions">
            <button type="button" onClick={onClose} aria-label="Cancel">
              Cancel
            </button>
            <button type="submit" aria-label={resource ? 'Save resource changes' : 'Create new resource'}>
              Save resource
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function ResourceList({
  resources,
  staffLookup,
  onEdit,
  onDelete,
  onToggleMaintenance,
  onShowMaintenanceLog,
}: {
  resources: Resource[];
  staffLookup: Record<string, StaffMember>;
  onEdit: (resource: Resource) => void;
  onDelete: (resource: Resource) => void;
  onToggleMaintenance: (resource: Resource) => void;
  onShowMaintenanceLog: (resource: Resource) => void;
}) {
  if (!resources.length) {
    return <p className="muted">No resources yet. Add rooms/equipment to avoid conflicts.</p>;
  }

  return (
    <div className="table table--no-head">
      {resources.map((resource) => (
        <ResourceRow
          key={resource.id}
          resource={resource}
          staffLookup={staffLookup}
          onEdit={() => onEdit(resource)}
          onDelete={() => onDelete(resource)}
          onToggleMaintenance={() => onToggleMaintenance(resource)}
          onShowMaintenanceLog={() => onShowMaintenanceLog(resource)}
        />
      ))}
    </div>
  );
}

function ResourceRow({
  resource,
  staffLookup,
  onEdit,
  onDelete,
  onToggleMaintenance,
  onShowMaintenanceLog,
}: {
  resource: Resource;
  staffLookup: Record<string, StaffMember>;
  onEdit: () => void;
  onDelete: () => void;
  onToggleMaintenance: () => void;
  onShowMaintenanceLog: () => void;
}) {
  const badgeTone =
    resource.status === 'available'
      ? 'badge--success'
      : resource.status === 'maintenance'
        ? 'badge--warn'
        : 'badge--info';

  return (
    <div className="resource-row" role="article" aria-label={`Resource: ${resource.name}`}>
      <div>
        <div className="resource-row__title">
          <span className="service-title">
            <span
              className="chip__dot"
              style={{ background: resource.colorHex ?? '#475569' }}
              aria-hidden="true"
            />
            {resource.name}
          </span>{' '}
          <span className={`badge ${badgeTone}`} aria-label={`Status: ${resource.status === 'in_use' ? 'in use' : resource.status}`}>
            {resource.status === 'in_use' ? 'in use' : resource.status}
          </span>
        </div>
        <div className="muted">
          {resource.type} · {resource.tags?.join(', ') || 'no tags'} · capacity{' '}
          {resource.capacity ?? 1}
        </div>
        {resource.isShared && <div className="badge badge--info">shared resource</div>}
        {resource.maintenanceSince && (
          <div className="muted">
            Maintenance since {new Date(resource.maintenanceSince).toLocaleDateString()}
          </div>
        )}
        {resource.maintenanceNote && <div className="note-box">{resource.maintenanceNote}</div>}
        {resource.assignedStaffIds && resource.assignedStaffIds.length > 0 && (
          <div className="chip-row chip-row--compact">
            {resource.assignedStaffIds.map((id) => {
              const staff = staffLookup[id];
              return (
                <span className="chip chip--ghost" key={id}>
                  {staff?.displayName ?? id}
                </span>
              );
            })}
          </div>
        )}
      </div>
      <div className="resource-actions" role="group" aria-label={`Actions for ${resource.name}`}>
        <button
          className="button button--ghost"
          type="button"
          onClick={onEdit}
          aria-label={`Edit ${resource.name}`}
        >
          Edit
        </button>
        <button
          className="button button--ghost"
          type="button"
          onClick={onToggleMaintenance}
          aria-label={resource.status === 'maintenance' ? `Mark ${resource.name} as available` : `Mark ${resource.name} for maintenance`}
        >
          {resource.status === 'maintenance' ? 'Mark available' : 'Mark maintenance'}
        </button>
        <button
          className="button button--ghost"
          type="button"
          onClick={onDelete}
          aria-label={`Delete ${resource.name}`}
        >
          Delete
        </button>
        <button
          className="button button--ghost"
          type="button"
          onClick={onShowMaintenanceLog}
          aria-label={`View maintenance history for ${resource.name}`}
        >
          History
        </button>
      </div>
    </div>
  );
}

export function ConflictPanel({
  conflicts,
  onResolve,
}: {
  conflicts: ResourceConflict[];
  onResolve: (conflict: ResourceConflict) => void;
}) {
  if (!conflicts.length) return null;
  return (
    <section className="panel panel--alert" role="alert" aria-labelledby="conflicts-title">
      <h2 id="conflicts-title" className="panel__title">Resource conflicts</h2>
      <p className="muted">Detected conflicts from appointments + resource bookings.</p>
      <div className="conflict-list" role="list">
        {conflicts.map((conflict) => (
          <div className="conflict-card" key={conflict.id} role="listitem">
            <div className="badge badge--warn" aria-label={`Severity: ${conflict.severity ?? 'info'}`}>
              {conflict.severity ?? 'info'}
            </div>
            <div>
              <div className="conflict-card__title">{conflict.description}</div>
              <div className="muted">{conflict.time}</div>
            </div>
            <button
              className="button button--ghost"
              type="button"
              onClick={() => onResolve(conflict)}
              aria-label={`Resolve conflict: ${conflict.description}`}
            >
              Resolve
            </button>
          </div>
        ))}
      </div>
    </section>
  );
}

export function ServicesPanel({
  services,
  resourceLookup,
}: {
  services: Service[];
  resourceLookup: Record<string, Resource>;
}) {
  if (!services.length) return null;

  return (
    <section className="panel" aria-labelledby="services-title">
      <h2 id="services-title" className="panel__title">Services & resources</h2>
      <p className="muted">Shows which rooms/equipment each service requires.</p>
      <div className="table" role="table" aria-label="Services and required resources">
        <div className="table__head">
          <span>Service</span>
          <span>Duration</span>
          <span>Resources</span>
        </div>
        {services.map((service) => (
          <div className="table__row" key={service.id}>
            <span className="service-title">
              <span
                className="chip__dot"
                style={{
                  background: service.colorHex ?? '#2563eb',
                }}
              />
              {service.name}
            </span>
            <span>{service.durationMinutes}m</span>
            <span>
              {service.resourceIds && service.resourceIds.length ? (
                <div className="chip-row chip-row--compact">
                  {service.resourceIds.map((resourceId) => (
                    <span className="chip chip--ghost" key={resourceId}>
                      {resourceLookup[resourceId]?.name ?? resourceId}
                    </span>
                  ))}
                </div>
              ) : (
                <span className="muted">No resource requirement</span>
              )}
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}

export function buildStaffOptions(staff: StaffMember[]): StaffOption[] {
  return staff.map((member) => ({
    id: member.id,
    label: member.displayName ?? member.id,
    role: member.role,
  }));
}

export function buildServiceOptions(services: Service[]): ServiceOption[] {
  return services.map((service) => ({
    id: service.id,
    label: service.name,
    colorHex: service.colorHex,
  }));
}

export function useStaffLookup(staff: StaffMember[]): Record<string, StaffMember> {
  return useMemo(() => Object.fromEntries(staff.map((member) => [member.id, member])), [staff]);
}
