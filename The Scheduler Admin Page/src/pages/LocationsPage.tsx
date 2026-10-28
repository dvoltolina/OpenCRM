import { useMemo, useState, type CSSProperties } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { useLocationsWorkspace } from '../hooks/useLocationsWorkspace';
import type { Location, LocationInput, Resource, ResourceInput } from '../types/models';
import { formatOperatingHours } from '../lib/operatingHours';
import {
  ConflictPanel,
  LocationDialog,
  ResourceDialog,
  ResourceList,
  ServicesPanel,
  buildServiceOptions,
  buildStaffOptions,
  useStaffLookup,
} from './locations/LocationsComponents';
import { ResourceMaintenanceDrawer } from './locations/ResourceMaintenanceDrawer';
import { THEME, SPACING } from './dashboard/DashboardComponents';

export function LocationsPage() {
  const { businessId, role, userId } = useBusinessContext();
  const { flags, loading: flagsLoading, error: flagError } = useFeatureFlags(businessId);
  const {
    locations,
    resources,
    staff,
    services,
    conflicts,
    loading,
    error,
    saving,
    saveLocation,
    deleteLocation,
    saveResource,
    deleteResource,
    toggleMaintenance,
    resolveConflict,
  } = useLocationsWorkspace(businessId, userId);

  const staffLookup = useStaffLookup(staff);
  const staffOptions = useMemo(() => buildStaffOptions(staff), [staff]);
  const serviceOptions = useMemo(() => buildServiceOptions(services), [services]);

  const [locationModal, setLocationModal] = useState<{ mode: 'create' | 'edit'; location: Location | null } | null>(null);
  const [resourceModal, setResourceModal] = useState<{ locationId: string; resource: Resource | null } | null>(null);
  const [maintenanceModal, setMaintenanceModal] = useState<Resource | null>(null);

  const canManage = role === 'owner' || role === 'admin';
  const locationResources = (locationId: string) =>
    resources.filter((resource) => resource.locationId === locationId);

  const handleLocationSave = async (input: LocationInput) => {
    await saveLocation(input, locationModal?.location?.id);
    setLocationModal(null);
  };

  const handleDeleteLocation = async (location: Location) => {
    if (!canManage) return;
    // HIPAA: No PHI in confirm dialog - location names are business data, not PHI
    if (!confirm(`Delete ${location.name}? Resources will need reassignment.`)) return;
    await deleteLocation(location.id);
  };

  const handleResourceSave = async (input: ResourceInput) => {
    if (!resourceModal) return;
    await saveResource(
      {
        ...input,
        locationId: resourceModal.locationId,
      },
      resourceModal.resource?.id,
    );
    setResourceModal(null);
  };

  const handleDeleteResource = async (resource: Resource) => {
    if (!canManage) return;
    if (!confirm(`Delete ${resource.name}?`)) return;
    await deleteResource(resource.id);
  };

  const handleToggleMaintenance = async (resource: Resource) => {
    if (!canManage) return;
    const note =
      resource.status === 'maintenance'
        ? undefined
        : prompt('Maintenance note (optional):') ?? undefined;
    if (resource.status !== 'maintenance' && note === undefined) {
      // user cancelled prompt
      return;
    }
    await toggleMaintenance(resource.id, note);
  };

  const handleResolveConflict = async (conflictId: string) => {
    const resolution = prompt('Resolution details');
    if (!resolution) return;
    await resolveConflict(conflictId, resolution);
  };

  const gridStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(520px, 1fr))',
    gap: SPACING.lg,
    marginBottom: SPACING.lg,
  };

  const emptyStateStyle: CSSProperties = {
    padding: SPACING.xxl,
    background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
    borderRadius: THEME.radiusLg,
    boxShadow: '0 4px 16px rgba(15, 23, 42, 0.04)',
    border: `1px solid ${THEME.colorBorder}`,
    textAlign: 'center' as const,
  };

  const alertPanelStyle: CSSProperties = {
    padding: SPACING.lg,
    background: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)',
    borderRadius: THEME.radiusLg,
    boxShadow: '0 4px 16px rgba(15, 23, 42, 0.04)',
    border: '1px solid #fbbf24',
    marginBottom: SPACING.lg,
  };

  if (!flags.enableLocations && !flagsLoading) {
    return (
      <section>
        <header className="page-header">
          <div>
            <p className="eyebrow">Multi-office</p>
            <h1>Locations</h1>
            <p className="muted">This module is disabled for the current tenant.</p>
          </div>
        </header>
        <div style={alertPanelStyle}>
          <p className="muted">
            Enable `enableLocations` in feature flags to surface the locations & resources workspace.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Multi-office</p>
          <h1>Locations &amp; Resources</h1>
          <p className="muted">
            Track each clinic, assign staff, manage rooms/equipment, and watch for resource conflicts.
          </p>
        </div>
        <div className="header-actions">
          <button
            className="button button--primary"
            type="button"
            disabled={!canManage}
            onClick={() => setLocationModal({ mode: 'create', location: null })}
            aria-label="Add new location"
            title={canManage ? "Add new location" : "Insufficient permissions to add locations"}
          >
            Add location
          </button>
        </div>
      </header>

      {(error || flagError) && (
        <div style={alertPanelStyle}>
          <p className="muted">{error ?? flagError}</p>
        </div>
      )}

      {flags.enableResources && (
        <ConflictPanel
          conflicts={conflicts}
          onResolve={(conflict) => handleResolveConflict(conflict.id)}
        />
      )}

      {loading ? (
        <div style={emptyStateStyle}>
          <p className="muted">Loading locations...</p>
        </div>
      ) : locations.length === 0 ? (
        <div style={emptyStateStyle}>
          <p className="muted">No locations yet. Create one to get started.</p>
        </div>
      ) : (
        <div style={gridStyle} role="list" aria-label="Locations list">
          {locations.map((location) => (
            <LocationCard
              key={location.id}
              location={location}
              staffLookup={staffLookup}
              resources={locationResources(location.id)}
              canManage={canManage}
              onEdit={() => setLocationModal({ mode: 'edit', location })}
              onDelete={() => handleDeleteLocation(location)}
              onAddResource={() =>
                setResourceModal({
                  locationId: location.id,
                  resource: null,
                })
              }
              onEditResource={(resource) =>
                setResourceModal({
                  locationId: resource.locationId,
                  resource,
                })
              }
              onDeleteResource={handleDeleteResource}
              onToggleMaintenance={handleToggleMaintenance}
              onShowMaintenanceLog={(resource) => setMaintenanceModal(resource)}
            />
          ))}
        </div>
      )}

      {flags.enableResources && (
        <ServicesPanel services={services} resourceLookup={Object.fromEntries(resources.map((r) => [r.id, r]))} />
      )}

      {locationModal !== null && (
        <LocationDialog
          location={locationModal.location}
          staffOptions={staffOptions}
          onClose={() => setLocationModal(null)}
          onSave={(input) => handleLocationSave({ ...input, staffIds: input.staffIds ?? [] })}
        />
      )}

      {resourceModal && (
        <ResourceDialog
          resource={resourceModal.resource}
          locationId={resourceModal.locationId}
          staffOptions={staffOptions}
          serviceOptions={serviceOptions}
          onClose={() => setResourceModal(null)}
          onSave={(input) => handleResourceSave(input)}
        />
      )}

      {maintenanceModal && (
        <ResourceMaintenanceDrawer
          businessId={businessId}
          resource={maintenanceModal}
          canManage={canManage}
          onClose={() => setMaintenanceModal(null)}
        />
      )}

      {saving && (
        <div style={{ ...alertPanelStyle, marginTop: SPACING.md }}>
          <p className="muted">Saving changes…</p>
        </div>
      )}
    </section>
  );
}

function LocationCard({
  location,
  staffLookup,
  resources,
  canManage,
  onEdit,
  onDelete,
  onAddResource,
  onEditResource,
  onDeleteResource,
  onToggleMaintenance,
  onShowMaintenanceLog,
}: {
  location: Location;
  staffLookup: ReturnType<typeof useStaffLookup>;
  resources: Resource[];
  canManage: boolean;
  onEdit: () => void;
  onDelete: () => void;
  onAddResource: () => void;
  onEditResource: (resource: Resource) => void;
  onDeleteResource: (resource: Resource) => void;
  onToggleMaintenance: (resource: Resource) => void;
  onShowMaintenanceLog: (resource: Resource) => void;
}) {
  const [isHovered, setIsHovered] = useState(false);

  const cardStyle: CSSProperties = {
    background: 'linear-gradient(180deg, #FFFFFF 0%, #FAFBFC 100%)',
    borderRadius: 16,
    boxShadow: isHovered
      ? '0 12px 32px rgba(15, 23, 42, 0.1)'
      : '0 4px 16px rgba(15, 23, 42, 0.04)',
    border: '1px solid #E5E7EB',
    padding: SPACING.lg,
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.lg,
    transition: 'all 200ms ease-out',
    transform: isHovered ? 'translateY(-4px)' : 'translateY(0)',
  };

  const headerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: SPACING.md,
  };

  const titleStyle: CSSProperties = {
    fontSize: 20,
    fontWeight: 700,
    margin: 0,
    color: '#0f172a',
    lineHeight: 1.2,
    letterSpacing: '-0.01em',
  };

  const addressStyle: CSSProperties = {
    fontSize: 14,
    color: '#64748b',
    margin: '6px 0 0',
    lineHeight: 1.5,
  };

  const actionsStyle: CSSProperties = {
    display: 'flex',
    gap: SPACING.sm,
    flexShrink: 0,
  };

  const contentStackStyle: CSSProperties = {
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.md,
  };

  const sectionHeaderStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: SPACING.lg,
    marginTop: SPACING.sm,
    borderTop: '1px solid #E5E7EB',
  };

  const sectionTitleStyle: CSSProperties = {
    fontSize: 12,
    fontWeight: 600,
    margin: 0,
    color: '#64748b',
    textTransform: 'uppercase',
    letterSpacing: '0.08em',
  };

  return (
    <article
      style={cardStyle}
      role="listitem"
      aria-label={`Location: ${location.name}`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div style={headerStyle}>
        <div>
          <h2 style={titleStyle}>{location.name}</h2>
          <p style={addressStyle}>{location.address}</p>
          {location.status === 'inactive' && (
            <span className="badge badge--warn" aria-label="Status: inactive" style={{ marginTop: SPACING.xs }}>
              inactive
            </span>
          )}
        </div>
        {canManage && (
          <div style={actionsStyle} role="group" aria-label={`Actions for ${location.name}`}>
            <button
              className="button button--ghost"
              type="button"
              onClick={onEdit}
              aria-label={`Edit ${location.name}`}
            >
              Edit
            </button>
            <button
              className="button button--ghost"
              type="button"
              onClick={onDelete}
              aria-label={`Delete ${location.name}`}
            >
              Delete
            </button>
          </div>
        )}
      </div>
      <div style={contentStackStyle}>
        <div className="meta-row">
          <span className="badge badge--neutral">TZ</span>
          <span>{location.timezone}</span>
          <span className="badge badge--neutral">Hours</span>
          <span>{formatOperatingHours(location.operatingHours ?? location.hours)}</span>
        </div>
        {location.phone || location.email ? (
          <div className="meta-row">
            {location.phone && (
              <span className="badge badge--ghost">{location.phone}</span>
            )}
            {location.email && (
              <span className="badge badge--ghost">{location.email}</span>
            )}
          </div>
        ) : null}
        {typeof location.capacity === 'number' && (
          <div className="meta-row">
            <span className="badge badge--neutral">Capacity</span>
            <span>{location.capacity} rooms/chairs</span>
          </div>
        )}
        {location.parkingInfo && (
          <div className="note-box">
            <strong>Parking</strong>: {location.parkingInfo}
          </div>
        )}
        {location.notes && <div className="note-box">{location.notes}</div>}
        {(location.staffIds?.length ?? 0) > 0 && (
          <div className="chip-row chip-row--wrap">
            {location.staffIds?.map((staffId) => (
              <span className="chip chip--ghost" key={staffId}>
                {staffLookup[staffId]?.displayName ?? staffId}
              </span>
            ))}
          </div>
        )}
        {location.tags && location.tags.length > 0 && (
          <div className="chip-row chip-row--compact">
            {location.tags.map((tag) => (
              <span className="chip chip--outline" key={tag}>
                {tag}
              </span>
            ))}
          </div>
        )}
      </div>
      <div style={sectionHeaderStyle}>
        <h3 style={sectionTitleStyle}>Resources</h3>
        {canManage && (
          <button
            className="button button--ghost"
            type="button"
            onClick={onAddResource}
            aria-label={`Add resource to ${location.name}`}
          >
            Add resource
          </button>
        )}
      </div>
      <ResourceList
        resources={resources}
        staffLookup={staffLookup}
        onEdit={(resource) => onEditResource(resource)}
        onDelete={(resource) => onDeleteResource(resource)}
        onToggleMaintenance={(resource) => onToggleMaintenance(resource)}
        onShowMaintenanceLog={(resource) => onShowMaintenanceLog(resource)}
      />
    </article>
  );
}
