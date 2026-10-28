/**
 * RoutePlanningPage
 * Allows managers to plan routes for field sales visits
 *
 * Features:
 * - View contacts with addresses on a map
 * - Select multiple contacts to create a route
 * - Optimize route order using nearest-neighbor algorithm
 * - Save and manage routes
 */

import { useState, useMemo, useCallback, useEffect } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import {
  useContacts,
  useRoutes,
  useRouteMutations,
  useGeocoding,
  useModal,
  useContactMutations,
} from '../hooks';
import { RouteMap } from '../components/maps/RouteMap';
import { ConfirmDialog } from '../components/modals';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import { useAuth } from '../context/AuthContext';
import type { Client, Route, RouteStop } from '../types/models';
import './styles/route-planning-page.css';

// ============================================
// Sortable Route Stop Item
// ============================================

interface SortableRouteStopProps {
  contact: Client;
  index: number;
  onRemove: (id: string) => void;
  disabled?: boolean;
  canManage: boolean;
}

function SortableRouteStop({ contact, index, onRemove, disabled, canManage }: SortableRouteStopProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: contact.id,
    disabled: disabled || !canManage,
  });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <li
      ref={setNodeRef}
      style={style}
      className={`route-stop-item ${isDragging ? 'route-stop-item--dragging' : ''}`}
    >
      {canManage && (
        <div className="route-stop-drag-handle" {...attributes} {...listeners}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <line x1="8" y1="6" x2="16" y2="6" />
            <line x1="8" y1="12" x2="16" y2="12" />
            <line x1="8" y1="18" x2="16" y2="18" />
          </svg>
        </div>
      )}
      <span className="stop-number">{index + 1}</span>
      <div className="stop-info">
        <strong>{contact.firstName} {contact.lastName}</strong>
        {contact.companyName && <span className="company">{contact.companyName}</span>}
      </div>
      {canManage && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onRemove(contact.id)}
          disabled={disabled}
        >
          Remove
        </Button>
      )}
    </li>
  );
}

export function RoutePlanningPage() {
  const { crmUser } = useAuth();
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split('T')[0];
  });
  const [routeName, setRouteName] = useState('');
  const [selectedContacts, setSelectedContacts] = useState<Client[]>([]);
  const [activeRouteId, setActiveRouteId] = useState<string | null>(null);
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const deleteModal = useModal<Route>();
  const saveModal = useModal();

  // Fetch contacts with addresses
  const { contacts, isLoading: contactsLoading, refresh: refreshContacts } = useContacts({ search: searchQuery });

  // Fetch routes for selected date
  const selectedDateObj = useMemo(() => new Date(selectedDate), [selectedDate]);
  const routeFilters = useMemo(
    () => ({
      dateFrom: selectedDateObj,
      dateTo: selectedDateObj,
    }),
    [selectedDateObj]
  );
  const { routes, isLoading: routesLoading, refresh: refreshRoutes } = useRoutes(routeFilters);

  const {
    createRoute,
    updateRoute,
    deleteRoute,
    addStop: _addStop,
    removeStop: _removeStop,
    optimizeRoute,
    isLoading: isMutating,
  } = useRouteMutations();

  const { geocodeContact, isGeocoding } = useGeocoding();
  const { updateGeocodedAddress } = useContactMutations();

  // Filter contacts with geocoded addresses for the map
  const geocodedContacts = useMemo(
    () => contacts.filter((c) => c.geocodedAddress?.latitude && c.geocodedAddress?.longitude),
    [contacts]
  );

  // Contacts without geocoded addresses
  const ungeocodedContacts = useMemo(
    () => contacts.filter((c) => c.address && !c.geocodedAddress),
    [contacts]
  );

  // Build route stops from selected contacts
  const routeStops: RouteStop[] = useMemo(
    () =>
      selectedContacts.map((contact, index) => ({
        contactId: contact.id,
        contact,
        order: index,
        status: 'pending' as const,
      })),
    [selectedContacts]
  );

  // Permission checks
  const canManageRoutes = crmUser?.role === 'owner' || crmUser?.role === 'admin' || crmUser?.role === 'manager';

  // Drag-and-drop sensors
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Handle drag end for reordering stops
  const handleDragEnd = useCallback((event: DragEndEvent) => {
    const { active, over } = event;

    if (!over || active.id === over.id) {
      return;
    }

    setSelectedContacts((prev) => {
      const oldIndex = prev.findIndex((c) => c.id === active.id);
      const newIndex = prev.findIndex((c) => c.id === over.id);

      if (oldIndex === -1 || newIndex === -1) {
        return prev;
      }

      const newContacts = [...prev];
      const [removed] = newContacts.splice(oldIndex, 1);
      newContacts.splice(newIndex, 0, removed);

      return newContacts;
    });
  }, []);

  const handleContactClick = useCallback((contact: Client) => {
    setSelectedContacts((prev) => {
      const isSelected = prev.some((c) => c.id === contact.id);
      if (isSelected) {
        return prev.filter((c) => c.id !== contact.id);
      }
      return [...prev, contact];
    });
  }, []);

  const handleRemoveFromRoute = useCallback((contactId: string) => {
    setSelectedContacts((prev) => prev.filter((c) => c.id !== contactId));
  }, []);

  const handleClearRoute = useCallback(() => {
    setSelectedContacts([]);
    setActiveRouteId(null);
    setRouteName('');
  }, []);

  const handleOptimizeRoute = useCallback(async () => {
    if (selectedContacts.length < 2) return;

    setIsOptimizing(true);
    try {
      // If we have an active route, optimize it via the repository
      if (activeRouteId) {
        const optimized = await optimizeRoute(activeRouteId);
        setSelectedContacts(optimized.stops.map((s) => s.contact));
      } else {
        // Create temporary route, optimize, get updated stops
        const tempRoute = await createRoute({
          name: routeName || 'Temp Route',
          date: selectedDateObj,
          stops: routeStops,
        });
        const optimized = await optimizeRoute(tempRoute.id);
        setSelectedContacts(optimized.stops.map((s) => s.contact));
        setActiveRouteId(optimized.id);
        setRouteName(optimized.name);
      }
    } catch (err) {
      console.error('Failed to optimize route:', err);
    } finally {
      setIsOptimizing(false);
    }
  }, [selectedContacts, activeRouteId, routeName, selectedDateObj, routeStops, optimizeRoute, createRoute]);

  const handleSaveRoute = useCallback(async () => {
    if (!routeName.trim() || selectedContacts.length === 0) return;

    try {
      if (activeRouteId) {
        await updateRoute(activeRouteId, {
          name: routeName,
          date: selectedDateObj,
          stops: routeStops,
        });
      } else {
        const route = await createRoute({
          name: routeName,
          date: selectedDateObj,
          stops: routeStops,
        });
        setActiveRouteId(route.id);
      }
      refreshRoutes();
      saveModal.close();
    } catch (err) {
      console.error('Failed to save route:', err);
    }
  }, [routeName, selectedContacts, activeRouteId, selectedDateObj, routeStops, updateRoute, createRoute, refreshRoutes, saveModal]);

  const handleLoadRoute = useCallback((route: Route) => {
    setSelectedContacts(route.stops.map((s) => s.contact));
    setActiveRouteId(route.id);
    setRouteName(route.name);
  }, []);

  const handleDeleteRoute = useCallback(async () => {
    if (!deleteModal.data) return;
    try {
      await deleteRoute(deleteModal.data.id);
      if (activeRouteId === deleteModal.data.id) {
        handleClearRoute();
      }
      refreshRoutes();
      deleteModal.close();
    } catch (err) {
      console.error('Failed to delete route:', err);
    }
  }, [deleteModal, deleteRoute, activeRouteId, handleClearRoute, refreshRoutes]);

  const handleGeocodeContact = useCallback(async (contact: Client) => {
    try {
      const result = await geocodeContact(contact);
      if (result) {
        // Persist geocoding result to contact
        await updateGeocodedAddress(contact.id, result);
        // Refresh contacts to show updated geocoding on the map
        refreshContacts();
      }
    } catch (err) {
      console.error('Failed to geocode contact:', contact.id, err);
    }
  }, [geocodeContact, updateGeocodedAddress, refreshContacts]);

  const isLoading = contactsLoading || routesLoading;
  const [initialLoadDone, setInitialLoadDone] = useState(false);
  useEffect(() => {
    if (!isLoading && !initialLoadDone) {
      setInitialLoadDone(true);
    }
  }, [isLoading, initialLoadDone]);

  const refreshAll = useCallback(() => {
    refreshContacts();
    refreshRoutes();
  }, [refreshContacts, refreshRoutes]);

  if (!initialLoadDone && isLoading) {
    return (
      <PageLayout width="wide" className="route-planning-page">
        <PageHeader
          eyebrow="Field Routes"
          title="Route Planning"
          subtitle="Build and optimize rep routes around geocoded contacts."
        />
        <Card padding="lg" className="route-planning-page__status-card">
          <p>Loading route planner...</p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="route-planning-page">
      <PageHeader
        eyebrow="Field Routes"
        title="Route Planning"
        subtitle="Build a day’s route, optimize stop order, and keep geocoding gaps visible before reps leave."
        actions={(
          <div className="route-planning-page__header-actions">
            <label className="route-planning-page__date-field">
              <span>Date</span>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="date-input"
              />
            </label>
            <Button variant="ghost" onClick={refreshAll}>
              Refresh
            </Button>
          </div>
        )}
      />

      <Card tone="accent" className="route-planning-page__hero">
        <div className="route-planning-page__hero-copy">
          <h2>Coordinate coverage before the day starts.</h2>
          <p>
            Select mapped contacts, optimize the stop sequence, and keep an eye on
            addresses that still need geocoding before routes are saved.
          </p>
        </div>
        <div className="route-planning-page__hero-stats" aria-label="Route planning summary">
          <div>
            <span>Mapped contacts</span>
            <strong>{geocodedContacts.length}</strong>
          </div>
          <div>
            <span>Current stops</span>
            <strong>{selectedContacts.length}</strong>
          </div>
          <div>
            <span>Saved routes</span>
            <strong>{routes.length}</strong>
          </div>
        </div>
      </Card>

      <div className="route-planning-layout">
        <Card padding="sm" className="route-planning-page__map-card">
          <Toolbar
            className="route-planning-page__toolbar"
            start={(
              <div className="route-planning-page__section-heading">
                <h2>Map Coverage</h2>
                <p>Click markers to add or remove stops for the active route.</p>
              </div>
            )}
            end={(
              <span className="route-planning-page__toolbar-meta">
                {canManageRoutes ? 'Interactive selection enabled' : 'View-only'}
              </span>
            )}
          />
          <div className="route-map-section">
            <RouteMap
              contacts={geocodedContacts}
              selectedContacts={selectedContacts}
              routeStops={routeStops}
              onContactClick={handleContactClick}
              showRouteLines={true}
              selectionMode={canManageRoutes}
              height="min(68vh, 640px)"
            />
            {geocodedContacts.length === 0 && (
              <div className="map-empty-state">
                <p>No contacts with geocoded addresses found.</p>
                <p>Add addresses to contacts to see them on the map.</p>
              </div>
            )}
          </div>
        </Card>

        <div className="route-sidebar">
          <Card className="route-planning-page__sidebar-card">
            <div className="route-planning-page__section-heading">
              <h2>Search Contacts</h2>
              <p>Filter the contact pool before assigning stops on the map.</p>
            </div>
            <input
              type="text"
              placeholder="Search contacts..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
          </Card>

          <Card className="route-planning-page__sidebar-card">
            <div className="route-planning-page__section-heading">
              <h2>Current Route</h2>
              <p>
                {selectedContacts.length === 0
                  ? 'Click map markers to start a route.'
                  : `${selectedContacts.length} stop${selectedContacts.length === 1 ? '' : 's'} selected.`}
              </p>
            </div>
            {selectedContacts.length === 0 ? (
              <EmptyState
                title="No stops selected"
                description="Choose mapped contacts to build a route for the selected day."
              />
            ) : (
              <>
                <div className="route-name-input">
                  <input
                    type="text"
                    placeholder="Route name..."
                    value={routeName}
                    onChange={(e) => setRouteName(e.target.value)}
                    className="search-input"
                    style={{ width: '100%' }}
                    disabled={!canManageRoutes}
                  />
                </div>
                <DndContext
                  sensors={sensors}
                  collisionDetection={closestCenter}
                  onDragEnd={handleDragEnd}
                >
                  <SortableContext
                    items={selectedContacts.map((c) => c.id)}
                    strategy={verticalListSortingStrategy}
                  >
                    <ul className="route-stops-list">
                      {selectedContacts.map((contact, index) => (
                        <SortableRouteStop
                          key={contact.id}
                          contact={contact}
                          index={index}
                          onRemove={handleRemoveFromRoute}
                          disabled={isMutating}
                          canManage={canManageRoutes}
                        />
                      ))}
                    </ul>
                  </SortableContext>
                </DndContext>
                {canManageRoutes && (
                  <div className="route-actions">
                    <Button
                      variant="secondary"
                      onClick={handleOptimizeRoute}
                      disabled={selectedContacts.length < 2 || isOptimizing || isMutating}
                    >
                      {isOptimizing ? 'Optimizing...' : 'Optimize Route'}
                    </Button>
                    <Button
                      onClick={() => saveModal.open()}
                      disabled={!routeName.trim() || isMutating}
                    >
                      Save Route
                    </Button>
                    <Button
                      variant="ghost"
                      onClick={handleClearRoute}
                      disabled={isMutating}
                    >
                      Clear
                    </Button>
                  </div>
                )}
              </>
            )}
          </Card>

          <Card className="route-planning-page__sidebar-card">
            <div className="route-planning-page__section-heading">
              <h2>Saved Routes</h2>
              <p>{new Date(selectedDate).toLocaleDateString()}</p>
            </div>
            {routes.length === 0 ? (
              <EmptyState
                title="No saved routes"
                description="Saved routes for this date will appear here once a plan is stored."
              />
            ) : (
              <ul className="saved-routes-list">
                {routes.map((route) => (
                  <li
                    key={route.id}
                    className={`saved-route-item ${activeRouteId === route.id ? 'active' : ''}`}
                  >
                    <div className="route-info" onClick={() => handleLoadRoute(route)}>
                      <strong>{route.name}</strong>
                      <span className="stop-count">{route.stops.length} stops</span>
                      {route.totalDistanceKm && (
                        <span className="distance">{route.totalDistanceKm} km</span>
                      )}
                      {route.totalDurationMinutes && (
                        <span className="distance">~{Math.round(route.totalDurationMinutes / 60)}h {route.totalDurationMinutes % 60}m</span>
                      )}
                    </div>
                    {canManageRoutes && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => deleteModal.open(route)}
                        disabled={isMutating}
                      >
                        Delete
                      </Button>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </Card>

          {ungeocodedContacts.length > 0 && (
            <Card className="route-planning-page__sidebar-card route-planning-page__sidebar-card--warning">
              <div className="route-planning-page__section-heading">
                <h2>Needs Geocoding</h2>
                <p>{ungeocodedContacts.length} contact{ungeocodedContacts.length === 1 ? '' : 's'} still missing map coordinates.</p>
              </div>
              <ul className="ungeocoded-list">
                {ungeocodedContacts.slice(0, 5).map((contact) => (
                  <li key={contact.id} className="ungeocoded-item">
                    <span>{contact.firstName} {contact.lastName}</span>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleGeocodeContact(contact)}
                      disabled={isGeocoding}
                    >
                      {isGeocoding ? 'Geocoding...' : 'Geocode'}
                    </Button>
                  </li>
                ))}
                {ungeocodedContacts.length > 5 && (
                  <li className="more-count">+{ungeocodedContacts.length - 5} more</li>
                )}
              </ul>
            </Card>
          )}
        </div>
      </div>

      {/* Confirm Save Modal */}
      <ConfirmDialog
        isOpen={saveModal.isOpen}
        onCancel={saveModal.close}
        onConfirm={handleSaveRoute}
        title="Save Route"
        message={`Save "${routeName}" with ${selectedContacts.length} stops?`}
        confirmText="Save"
        variant="info"
      />

      {/* Confirm Delete Modal */}
      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onCancel={deleteModal.close}
        onConfirm={handleDeleteRoute}
        title="Delete Route"
        message={`Are you sure you want to delete "${deleteModal.data?.name}"? This cannot be undone.`}
        confirmText="Delete"
        variant="danger"
      />
    </PageLayout>
  );
}

export default RoutePlanningPage;
