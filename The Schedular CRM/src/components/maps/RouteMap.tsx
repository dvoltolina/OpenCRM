/**
 * RouteMap Component
 * Displays an interactive map for route planning with Leaflet
 *
 * Features:
 * - Display contact markers on map
 * - Click-to-select markers for route building
 * - Draw route lines between selected stops
 * - Show popup with contact details on marker click
 */

import { useEffect, useRef, useMemo } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import type { Client, RouteStop } from '../../types/models';

// Fix default marker icon issue in Leaflet/React
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

// Configure default icon
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
});

// Custom marker icons
const createCustomIcon = (color: string, isSelected: boolean = false) => {
  const size = isSelected ? 35 : 25;
  return L.divIcon({
    className: 'custom-marker',
    html: `
      <div style="
        background-color: ${color};
        width: ${size}px;
        height: ${size}px;
        border-radius: 50% 50% 50% 0;
        transform: rotate(-45deg);
        border: 2px solid white;
        box-shadow: 0 2px 5px rgba(0,0,0,0.3);
        ${isSelected ? 'z-index: 1000;' : ''}
      ">
        ${isSelected ? `<div style="
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%) rotate(45deg);
          color: white;
          font-weight: bold;
          font-size: 12px;
        ">${'check'}</div>` : ''}
      </div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size],
    popupAnchor: [0, -size],
  });
};

const defaultIcon = createCustomIcon('#3b82f6', false);
const selectedIcon = createCustomIcon('#10b981', true);
const stopNumberIcon = (num: number) =>
  L.divIcon({
    className: 'stop-number-marker',
    html: `
      <div style="
        background-color: #10b981;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 2px 5px rgba(0,0,0,0.3);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: 14px;
      ">${num}</div>
    `,
    iconSize: [30, 30],
    iconAnchor: [15, 15],
    popupAnchor: [0, -15],
  });

// ============================================
// Types
// ============================================

export interface RouteMapProps {
  /** List of all contacts with geocoded addresses */
  contacts: Client[];
  /** Currently selected contacts for the route */
  selectedContacts: Client[];
  /** Stops in current route (ordered) */
  routeStops?: RouteStop[];
  /** Called when a contact marker is clicked */
  onContactClick?: (contact: Client) => void;
  /** Center coordinates for initial view */
  center?: [number, number];
  /** Initial zoom level */
  zoom?: number;
  /** Map height */
  height?: string | number;
  /** Show route lines between stops */
  showRouteLines?: boolean;
  /** Whether the map is in selection mode */
  selectionMode?: boolean;
}

// ============================================
// Map Bounds Handler
// ============================================

interface MapBoundsHandlerProps {
  contacts: Client[];
  selectedContacts: Client[];
}

function MapBoundsHandler({ contacts, selectedContacts }: MapBoundsHandlerProps) {
  const map = useMap();
  const initialFitDone = useRef(false);

  useEffect(() => {
    if (initialFitDone.current) return;

    const allContacts = selectedContacts.length > 0 ? selectedContacts : contacts;
    const geocodedContacts = allContacts.filter(
      (c) => c.geocodedAddress?.latitude && c.geocodedAddress?.longitude
    );

    if (geocodedContacts.length === 0) return;

    if (geocodedContacts.length === 1) {
      const c = geocodedContacts[0];
      map.setView([c.geocodedAddress!.latitude, c.geocodedAddress!.longitude], 13);
    } else {
      const bounds = L.latLngBounds(
        geocodedContacts.map((c) => [
          c.geocodedAddress!.latitude,
          c.geocodedAddress!.longitude,
        ])
      );
      map.fitBounds(bounds, { padding: [50, 50] });
    }

    initialFitDone.current = true;
  }, [map, contacts, selectedContacts]);

  return null;
}

// ============================================
// RouteMap Component
// ============================================

export function RouteMap({
  contacts,
  selectedContacts,
  routeStops = [],
  onContactClick,
  center = [39.8283, -98.5795], // Center of US
  zoom = 4,
  height = 500,
  showRouteLines = true,
  selectionMode = true,
}: RouteMapProps) {
  // Filter contacts with valid geocoded addresses
  const geocodedContacts = useMemo(
    () =>
      contacts.filter(
        (c) => c.geocodedAddress?.latitude && c.geocodedAddress?.longitude
      ),
    [contacts]
  );

  // Get selected contact IDs for quick lookup
  const selectedIds = useMemo(
    () => new Set(selectedContacts.map((c) => c.id)),
    [selectedContacts]
  );

  // Get stop order for numbered markers
  const stopOrder = useMemo(() => {
    const order = new Map<string, number>();
    routeStops.forEach((stop, index) => {
      order.set(stop.contactId, index + 1);
    });
    return order;
  }, [routeStops]);

  // Build route line coordinates
  const routeCoordinates = useMemo(() => {
    if (!showRouteLines || routeStops.length < 2) return [];

    return routeStops
      .filter(
        (stop) =>
          stop.contact.geocodedAddress?.latitude &&
          stop.contact.geocodedAddress?.longitude
      )
      .map((stop) => [
        stop.contact.geocodedAddress!.latitude,
        stop.contact.geocodedAddress!.longitude,
      ] as [number, number]);
  }, [routeStops, showRouteLines]);

  const handleMarkerClick = (contact: Client) => {
    if (onContactClick && selectionMode) {
      onContactClick(contact);
    }
  };

  // Determine marker icon based on selection state
  const getMarkerIcon = (contact: Client) => {
    const stopNum = stopOrder.get(contact.id);
    if (stopNum) {
      return stopNumberIcon(stopNum);
    }
    if (selectedIds.has(contact.id)) {
      return selectedIcon;
    }
    return defaultIcon;
  };

  return (
    <div className="route-map-container" style={{ height }}>
      <MapContainer
        center={center}
        zoom={zoom}
        style={{ height: '100%', width: '100%', borderRadius: '8px' }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapBoundsHandler
          contacts={geocodedContacts}
          selectedContacts={selectedContacts}
        />

        {/* Route line connecting stops */}
        {routeCoordinates.length >= 2 && (
          <Polyline
            positions={routeCoordinates}
            color="#10b981"
            weight={4}
            opacity={0.8}
            dashArray="10, 5"
          />
        )}

        {/* Contact markers */}
        {geocodedContacts.map((contact) => (
          <Marker
            key={contact.id}
            position={[
              contact.geocodedAddress!.latitude,
              contact.geocodedAddress!.longitude,
            ]}
            icon={getMarkerIcon(contact)}
            eventHandlers={{
              click: () => handleMarkerClick(contact),
            }}
          >
            <Popup>
              <div className="contact-popup">
                <strong>
                  {contact.firstName} {contact.lastName}
                </strong>
                {contact.companyName && (
                  <div className="popup-company">{contact.companyName}</div>
                )}
                {contact.address && (
                  <div className="popup-address">
                    {[
                      contact.address.street,
                      contact.address.city,
                      contact.address.state,
                      contact.address.zipCode,
                    ]
                      .filter(Boolean)
                      .join(', ')}
                  </div>
                )}
                {contact.phone && (
                  <div className="popup-phone">{contact.phone}</div>
                )}
                {selectionMode && (
                  <button
                    className="btn btn-sm btn-primary popup-action"
                    onClick={() => handleMarkerClick(contact)}
                  >
                    {selectedIds.has(contact.id) ? 'Remove from Route' : 'Add to Route'}
                  </button>
                )}
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}

export default RouteMap;
