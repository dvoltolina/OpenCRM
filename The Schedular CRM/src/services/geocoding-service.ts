/**
 * Geocoding Service
 * Provides address-to-coordinates conversion using OpenStreetMap Nominatim API
 *
 * PRIVACY NOTE: This service sends business addresses to an external API (Nominatim).
 * Addresses should be business/contact addresses only, not patient/PHI data.
 * No personal health information should be included in address strings.
 *
 * Rate Limiting: Nominatim requires 1 request/second - enforced via lastRequestTime
 */

import type { GeocodedAddress, Client } from '../types/models';

// In-memory cache for geocoding results (keyed by lowercase address string)
const geocodeCache = new Map<string, GeocodedAddress>();
let lastGeocodingRequest = 0;
const GEOCODING_RATE_LIMIT_MS = 1100; // Nominatim requires 1 request/second
const GEOCODING_TIMEOUT_MS = 10000; // 10 second timeout

/**
 * Build address string from contact address parts
 */
export function buildAddressString(contact: Client): string | null {
  if (!contact.address) return null;

  const { street, city, state, zipCode, country } = contact.address;
  const addressParts = [street, city, state, zipCode, country].filter(Boolean);

  if (addressParts.length === 0) return null;

  return addressParts.join(', ');
}

/**
 * Check if address has changed between old and new contact data
 */
export function hasAddressChanged(
  oldContact: Client | null,
  newData: Partial<Client>
): boolean {
  if (!newData.address) return false;

  // If no old contact or no old address, it's a new address
  if (!oldContact?.address) return !!newData.address;

  const oldAddress = oldContact.address;
  const newAddress = newData.address;

  // Compare relevant fields
  return (
    oldAddress.street !== newAddress.street ||
    oldAddress.city !== newAddress.city ||
    oldAddress.state !== newAddress.state ||
    oldAddress.zipCode !== newAddress.zipCode ||
    oldAddress.country !== newAddress.country
  );
}

/**
 * Geocode an address string using OpenStreetMap Nominatim
 *
 * @param address - Full address string to geocode
 * @returns Geocoded address with coordinates, or null if geocoding failed
 */
export async function geocodeAddress(address: string): Promise<GeocodedAddress | null> {
  if (!address.trim()) return null;

  // Check cache first
  const cacheKey = address.toLowerCase();
  const cached = geocodeCache.get(cacheKey);
  if (cached) return cached;

  // Enforce rate limiting
  const now = Date.now();
  const timeSinceLastRequest = now - lastGeocodingRequest;
  if (timeSinceLastRequest < GEOCODING_RATE_LIMIT_MS) {
    await new Promise((resolve) =>
      setTimeout(resolve, GEOCODING_RATE_LIMIT_MS - timeSinceLastRequest)
    );
  }
  lastGeocodingRequest = Date.now();

  try {
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
      address
    )}&limit=1`;

    // Create abort controller for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), GEOCODING_TIMEOUT_MS);

    const response = await fetch(url, {
      headers: {
        'User-Agent': 'TheSchedulerCRM/1.0',
      },
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      // Log error without exposing address details
      console.error('Geocoding request failed:', response.status);
      return null;
    }

    const data = await response.json();

    if (!data || data.length === 0) {
      return null;
    }

    const result: GeocodedAddress = {
      latitude: parseFloat(data[0].lat),
      longitude: parseFloat(data[0].lon),
      formattedAddress: data[0].display_name,
      placeId: data[0].place_id?.toString(),
      accuracy: 'approximate',
      geocodedAt: new Date(),
    };

    // Cache the result
    geocodeCache.set(cacheKey, result);

    return result;
  } catch (err) {
    // Log error without exposing address details
    if (err instanceof Error && err.name === 'AbortError') {
      console.error('Geocoding request timed out');
    } else {
      console.error('Geocoding failed');
    }
    return null;
  }
}

/**
 * Geocode a contact's address
 *
 * @param contact - Contact with address to geocode
 * @returns Geocoded address with coordinates, or null if geocoding failed
 */
export async function geocodeContactAddress(contact: Client): Promise<GeocodedAddress | null> {
  const addressString = buildAddressString(contact);
  if (!addressString) return null;

  return geocodeAddress(addressString);
}

/**
 * Clear the geocoding cache (useful for testing)
 */
export function clearGeocodeCache(): void {
  geocodeCache.clear();
}
