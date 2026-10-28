import { useCallback, useEffect, useMemo, useState, type CSSProperties } from 'react';

import { isDemoMode } from '../config/demo';
import { listLocations, listResources } from '../data/locations';
import {
  createService,
  deleteService,
  listServices,
  updateService,
  type ServiceInput,
} from '../data/services';
import { useBusinessContext } from '../hooks/useBusinessContext';
import type { Location, Resource, Service } from '../types/models';
import { SPACING, THEME } from './dashboard/DashboardComponents';

type ServiceFormState = {
  name: string;
  durationMinutes: number;
  price: string;
  bufferMinutes: string;
  category: string;
  colorHex: string;
  isActive: boolean;
  providerIdsCsv: string;
  resourceIds: string[];
};

type ServiceEditorState = {
  mode: 'create' | 'edit';
  service?: Service;
};

export function ServicesPage() {
  const { businessId, userId, role } = useBusinessContext();
  const [services, setServices] = useState<Service[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [resources, setResources] = useState<Resource[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editor, setEditor] = useState<ServiceEditorState | null>(null);

  const canManageServices = role === 'owner' || role === 'admin' || role === 'manager';
  const mutationsBlocked = isDemoMode || !canManageServices;

  const refresh = useCallback(async () => {
    if (!businessId) {
      setServices([]);
      setLocations([]);
      setResources([]);
      setError('Business context required to load services.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [serviceRows, locationRows, resourceRows] = await Promise.all([
        listServices(businessId, userId),
        listLocations(businessId, userId),
        listResources(businessId),
      ]);
      setServices(serviceRows);
      setLocations(locationRows);
      setResources(resourceRows);
    } catch (err) {
      console.error('Failed to load services workspace', err);
      setError(err instanceof Error ? err.message : 'Failed to load services.');
      setServices([]);
      setLocations([]);
      setResources([]);
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const resourcesById = useMemo(
    () => Object.fromEntries(resources.map((resource) => [resource.id, resource])),
    [resources],
  );
  const locationsById = useMemo(
    () => Object.fromEntries(locations.map((location) => [location.id, location])),
    [locations],
  );

  const servicesWithLocations = useMemo(
    () =>
      services.map((service) => {
        const locationIds = Array.from(
          new Set(
            (service.resourceIds ?? [])
              .map((resourceId) => resourcesById[resourceId]?.locationId)
              .filter(Boolean),
          ),
        ) as string[];
        return { ...service, locationIds };
      }),
    [resourcesById, services],
  );

  const handleSave = async (input: ServiceInput, serviceId?: string) => {
    if (!businessId) return;
    setSaving(true);
    setError(null);
    try {
      if (serviceId) {
        await updateService(businessId, serviceId, input, userId);
      } else {
        await createService(businessId, input, userId);
      }
      setEditor(null);
      await refresh();
    } catch (err) {
      console.error('Failed to save service', err);
      setError(err instanceof Error ? err.message : 'Failed to save service.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (service: Service) => {
    if (!businessId || mutationsBlocked) return;
    if (!confirm(`Delete ${service.name}?`)) return;
    setSaving(true);
    setError(null);
    try {
      await deleteService(businessId, service.id, userId);
      await refresh();
    } catch (err) {
      console.error('Failed to delete service', err);
      setError(err instanceof Error ? err.message : 'Failed to delete service.');
    } finally {
      setSaving(false);
    }
  };

  const sectionStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    padding: SPACING.lg,
  };
  const headerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.xl,
    gap: SPACING.lg,
  };
  const tableContainerStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radiusLg,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    overflow: 'hidden',
  };
  const tableHeadStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '2fr 1fr 1fr 1fr 1.2fr 1.4fr 0.8fr auto',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  };
  const rowStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '2fr 1fr 1fr 1fr 1.2fr 1.4fr 0.8fr auto',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorderLight}`,
    alignItems: 'center',
    fontSize: 14,
    color: THEME.colorText,
    cursor: canManageServices ? 'pointer' : 'default',
  };
  const alertPanelStyle: CSSProperties = {
    marginBottom: SPACING.lg,
    padding: SPACING.md,
    borderRadius: 10,
    border: '1px solid #f59e0b',
    background: '#fffbeb',
    color: '#92400e',
    fontSize: 13,
  };
  const buttonBaseStyle: CSSProperties = {
    padding: `${SPACING.sm + 2}px ${SPACING.lg}px`,
    borderRadius: SPACING.sm,
    fontSize: 14,
    fontWeight: 500,
    border: 'none',
    cursor: 'pointer',
  };

  return (
    <section style={sectionStyle}>
      <header style={headerStyle}>
        <div>
          <p
            style={{
              fontSize: 11,
              fontWeight: 600,
              color: THEME.colorAccent,
              textTransform: 'uppercase',
              letterSpacing: '0.1em',
              margin: 0,
            }}
          >
            Catalog
          </p>
          <h1 style={{ fontSize: 26, fontWeight: 700, color: THEME.colorText, margin: `${SPACING.sm}px 0 0` }}>
            Services
          </h1>
          <p style={{ fontSize: 14, color: THEME.colorTextMuted, margin: `${SPACING.xs}px 0 0` }}>
            Manage appointment types, durations, buffers, and required resources from the shared
            `services` collection.
          </p>
        </div>
        <div style={{ display: 'flex', gap: SPACING.sm }}>
          <button
            className="button button--secondary"
            style={buttonBaseStyle}
            type="button"
            onClick={() => void refresh()}
            disabled={loading || saving}
          >
            Refresh
          </button>
          <button
            className="button button--primary"
            style={buttonBaseStyle}
            type="button"
            onClick={() => setEditor({ mode: 'create' })}
            disabled={mutationsBlocked || saving}
            title={
              isDemoMode
                ? 'Disabled in demo mode.'
                : canManageServices
                  ? undefined
                  : 'Insufficient permissions.'
            }
          >
            Add service
          </button>
        </div>
      </header>

      {error && <div style={alertPanelStyle}>{error}</div>}
      {!canManageServices && (
        <div style={alertPanelStyle}>
          Service writes require owner, admin, or manager access.
        </div>
      )}

      <div style={tableContainerStyle} role="table" aria-label="Services catalog">
        <div style={tableHeadStyle} role="row">
          <span role="columnheader">Name</span>
          <span role="columnheader">Duration</span>
          <span role="columnheader">Price</span>
          <span role="columnheader">Buffer</span>
          <span role="columnheader">Locations</span>
          <span role="columnheader">Required resources</span>
          <span role="columnheader">Status</span>
          <span role="columnheader">Actions</span>
        </div>
        {loading ? (
          <div style={{ padding: SPACING.lg, color: THEME.colorTextMuted }}>Loading services...</div>
        ) : servicesWithLocations.length === 0 ? (
          <div style={{ padding: SPACING.lg, color: THEME.colorTextMuted }}>
            No services yet. Add your first service to begin scheduling.
          </div>
        ) : (
          servicesWithLocations.map((service) => (
            <div
              key={service.id}
              style={rowStyle}
              role="row"
              onClick={() => {
                if (!mutationsBlocked) {
                  setEditor({ mode: 'edit', service });
                }
              }}
              tabIndex={canManageServices ? 0 : -1}
              onKeyDown={(event) => {
                if (!canManageServices) return;
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault();
                  setEditor({ mode: 'edit', service });
                }
              }}
            >
              <span role="cell">
                <span
                  style={{
                    display: 'inline-block',
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    marginRight: SPACING.sm,
                    background: service.colorHex ?? '#2563eb',
                  }}
                />
                {service.name}
                <span style={{ color: THEME.colorTextMuted, marginLeft: SPACING.sm }}>
                  {service.category ?? 'General'}
                </span>
              </span>
              <span role="cell">{service.durationMinutes}m</span>
              <span role="cell">{typeof service.price === 'number' ? `$${service.price}` : '—'}</span>
              <span role="cell">{service.bufferMinutes ? `${service.bufferMinutes}m` : '0m'}</span>
              <span role="cell">
                {service.locationIds.length === 0
                  ? 'Any location'
                  : service.locationIds
                      .map((locationId) => locationsById[locationId]?.name ?? locationId)
                      .join(', ')}
              </span>
              <span role="cell">
                {(service.resourceIds ?? []).length === 0
                  ? 'None'
                  : (service.resourceIds ?? [])
                      .map((resourceId) => resourcesById[resourceId]?.name ?? resourceId)
                      .join(', ')}
              </span>
              <span role="cell">{service.isActive === false ? 'inactive' : 'active'}</span>
              <span role="cell">
                <button
                  className="button button--ghost"
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation();
                    void handleDelete(service);
                  }}
                  disabled={mutationsBlocked || saving}
                >
                  Delete
                </button>
              </span>
            </div>
          ))
        )}
      </div>

      {editor && (
        <ServiceEditorDialog
          mode={editor.mode}
          service={editor.service}
          resources={resources}
          disabled={mutationsBlocked || saving}
          onClose={() => setEditor(null)}
          onSave={(input) => void handleSave(input, editor.service?.id)}
        />
      )}
    </section>
  );
}

function ServiceEditorDialog({
  mode,
  service,
  resources,
  disabled,
  onClose,
  onSave,
}: {
  mode: 'create' | 'edit';
  service?: Service;
  resources: Resource[];
  disabled: boolean;
  onClose: () => void;
  onSave: (input: ServiceInput) => void;
}) {
  const [form, setForm] = useState<ServiceFormState>(() => ({
    name: service?.name ?? '',
    durationMinutes: service?.durationMinutes ?? 60,
    price: service?.price?.toString() ?? '',
    bufferMinutes: service?.bufferMinutes?.toString() ?? '0',
    category: service?.category ?? 'General',
    colorHex: service?.colorHex ?? '#2563eb',
    isActive: service?.isActive ?? true,
    providerIdsCsv: (service?.providerIds ?? []).join(', '),
    resourceIds: service?.resourceIds ?? [],
  }));

  const toggleResource = (resourceId: string) => {
    setForm((prev) => ({
      ...prev,
      resourceIds: prev.resourceIds.includes(resourceId)
        ? prev.resourceIds.filter((id) => id !== resourceId)
        : [...prev.resourceIds, resourceId],
    }));
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const providerIds = form.providerIdsCsv
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
    onSave({
      name: form.name.trim(),
      durationMinutes: Math.max(5, Number(form.durationMinutes) || 60),
      price: form.price.trim().length ? Number(form.price) : undefined,
      bufferMinutes: form.bufferMinutes.trim().length ? Number(form.bufferMinutes) : 0,
      category: form.category.trim() || undefined,
      colorHex: form.colorHex || undefined,
      isActive: form.isActive,
      providerIds,
      resourceIds: form.resourceIds,
    });
  };

  return (
    <div
      className="dialog-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="service-dialog-title"
      onClick={onClose}
    >
      <div className="dialog" onClick={(event) => event.stopPropagation()}>
        <h2 id="service-dialog-title">{mode === 'create' ? 'Add service' : 'Edit service'}</h2>
        <form className="stack" onSubmit={handleSubmit}>
          <label>
            Name
            <input
              type="text"
              value={form.name}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              required
            />
          </label>
          <div className="grid grid--2">
            <label>
              Duration (minutes)
              <input
                type="number"
                min={5}
                value={form.durationMinutes}
                onChange={(event) =>
                  setForm((prev) => ({ ...prev, durationMinutes: Number(event.target.value) || 60 }))
                }
              />
            </label>
            <label>
              Buffer (minutes)
              <input
                type="number"
                min={0}
                value={form.bufferMinutes}
                onChange={(event) => setForm((prev) => ({ ...prev, bufferMinutes: event.target.value }))}
              />
            </label>
          </div>
          <div className="grid grid--2">
            <label>
              Price
              <input
                type="number"
                min={0}
                step="0.01"
                value={form.price}
                onChange={(event) => setForm((prev) => ({ ...prev, price: event.target.value }))}
              />
            </label>
            <label>
              Category
              <input
                type="text"
                value={form.category}
                onChange={(event) => setForm((prev) => ({ ...prev, category: event.target.value }))}
              />
            </label>
          </div>
          <div className="grid grid--2">
            <label>
              Color
              <input
                type="color"
                value={form.colorHex}
                onChange={(event) => setForm((prev) => ({ ...prev, colorHex: event.target.value }))}
              />
            </label>
            <label className="meta-row" style={{ alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(event) => setForm((prev) => ({ ...prev, isActive: event.target.checked }))}
              />
              Active
            </label>
          </div>
          <label>
            Provider IDs (comma-separated)
            <input
              type="text"
              value={form.providerIdsCsv}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, providerIdsCsv: event.target.value }))
              }
              placeholder="provider-1, provider-2"
            />
          </label>
          <fieldset>
            <legend>Required resources</legend>
            <div className="chip-row chip-row--wrap">
              {resources.map((resource) => (
                <label key={resource.id} className="chip chip--outline" style={{ cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={form.resourceIds.includes(resource.id)}
                    onChange={() => toggleResource(resource.id)}
                  />
                  {resource.name}
                </label>
              ))}
            </div>
          </fieldset>
          <div className="dialog-actions">
            <button type="button" onClick={onClose}>
              Cancel
            </button>
            <button className="button button--primary" type="submit" disabled={disabled || !form.name.trim()}>
              {mode === 'create' ? 'Create service' : 'Save changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
