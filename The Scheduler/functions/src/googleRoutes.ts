/**
 * Google Routes API Cloud Function
 * Optimizes route stop order and returns real driving distances/durations.
 *
 * Uses Google Routes API computeRoutes with optimizeWaypointOrder.
 * Only lat/lng coordinates are sent to Google — no PHI (names, IDs, etc.).
 *
 * HIPAA: No client names, contact IDs, or addresses are forwarded to Google.
 * The contactId field is only used internally between CRM and this function.
 */

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import {db, FieldValue, auth} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";

const googleRoutesApiKey = defineSecret("GOOGLE_ROUTES_API_KEY");

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface OptimizeStop {
  contactId: string;
  latitude: number;
  longitude: number;
}

interface OptimizeRequest {
  businessId?: string;
  routeId?: string;
  startLatitude: number;
  startLongitude: number;
  stops: OptimizeStop[];
}

interface OptimizedStopResult {
  contactId: string;
  order: number;
  distanceToNextMeters: number | null;
  durationToNextSeconds: number | null;
}

interface OptimizeResponse {
  success: boolean;
  optimizedOrder: OptimizedStopResult[];
  totalDistanceKm: number;
  totalDurationMinutes: number;
  source: "google_routes_api" | "fallback_nearest_neighbor";
  error?: string;
}

// ---------------------------------------------------------------------------
// Rate Limiting
// ---------------------------------------------------------------------------

type RateBucket = {count: number; windowStart: number};
const routeRateBuckets: Map<string, RateBucket> = new Map();
const ROUTE_LIMIT = {max: 60, windowMs: 60 * 60 * 1000}; // 60/hour

function isRateLimited(buckets: Map<string, RateBucket>, key: string, limit: {max: number; windowMs: number}): boolean {
  const now = Date.now();
  const bucket = buckets.get(key);
  if (!bucket || now - bucket.windowStart > limit.windowMs) {
    buckets.set(key, {count: 1, windowStart: now});
    return false;
  }
  bucket.count++;
  return bucket.count > limit.max;
}

// ---------------------------------------------------------------------------
// Auth (same pattern as webhookHandlers)
// ---------------------------------------------------------------------------

async function requireAuth(req: any): Promise<{uid: string; businessId: string}> {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    throw new Error("unauthorized");
  }
  const tokenString = header.split(" ")[1];
  const decoded = await auth.verifyIdToken(tokenString);
  const headerBusinessId =
    typeof req.headers["x-business-id"] === "string"
      ? (req.headers["x-business-id"] as string).trim()
      : undefined;

  const businessId =
    typeof decoded.businessId === "string" ? decoded.businessId.trim() : headerBusinessId;

  if (!businessId) {
    throw new Error("missing businessId");
  }

  return {uid: decoded.uid, businessId};
}

// ---------------------------------------------------------------------------
// Audit Log (no PHI — only counts and metadata)
// ---------------------------------------------------------------------------

async function auditLog(
  businessId: string,
  entry: {action: string; entity: string; entityId?: string; metadata?: Record<string, unknown>}
) {
  try {
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("audit_logs")
      .add({
        action: entry.action,
        entity: entry.entity,
        entityId: entry.entityId ?? null,
        metadata: entry.metadata ?? {},
        createdAt: FieldValue.serverTimestamp(),
      });
  } catch (error) {
    logger.warn("auditLog failed", {error, businessId});
  }
}

// ---------------------------------------------------------------------------
// Nearest-neighbor fallback (server-side, no external API)
// ---------------------------------------------------------------------------

function haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function nearestNeighborFallback(
  stops: OptimizeStop[],
  startLat: number,
  startLng: number
): OptimizeResponse {
  const optimized: OptimizedStopResult[] = [];
  const remaining = [...stops];
  let currentLat = startLat;
  let currentLng = startLng;
  let totalDistance = 0;

  while (remaining.length > 0) {
    let nearestIdx = 0;
    let nearestDist = Infinity;

    remaining.forEach((stop, idx) => {
      const dist = haversineDistance(currentLat, currentLng, stop.latitude, stop.longitude);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestIdx = idx;
      }
    });

    const nearest = remaining.splice(nearestIdx, 1)[0];
    const distMeters = Math.round(nearestDist * 1000);
    totalDistance += nearestDist;

    optimized.push({
      contactId: nearest.contactId,
      order: optimized.length,
      distanceToNextMeters: distMeters,
      durationToNextSeconds: null,
    });

    currentLat = nearest.latitude;
    currentLng = nearest.longitude;
  }

  const travelMinutes = (totalDistance / 40) * 60; // 40 km/h average
  const stopMinutes = optimized.length * 15;

  return {
    success: true,
    optimizedOrder: optimized,
    totalDistanceKm: Math.round(totalDistance * 10) / 10,
    totalDurationMinutes: Math.round(travelMinutes + stopMinutes),
    source: "fallback_nearest_neighbor",
  };
}

// ---------------------------------------------------------------------------
// Google Routes API call
// ---------------------------------------------------------------------------

async function callGoogleRoutesApi(
  apiKey: string,
  startLat: number,
  startLng: number,
  stops: OptimizeStop[]
): Promise<OptimizeResponse> {
  // Build the request for Google Routes API computeRoutes
  // Origin = start location, Destination = last stop (will be reordered)
  // Intermediates = all stops as waypoints to be optimized
  const waypoints = stops.map((stop) => ({
    location: {
      latLng: {
        latitude: stop.latitude,
        longitude: stop.longitude,
      },
    },
  }));

  const requestBody = {
    origin: {
      location: {
        latLng: {
          latitude: startLat,
          longitude: startLng,
        },
      },
    },
    destination: waypoints[waypoints.length - 1],
    intermediates: waypoints.slice(0, -1),
    travelMode: "DRIVE",
    optimizeWaypointOrder: true,
    routingPreference: "TRAFFIC_AWARE",
  };

  const response = await fetch(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
          "routes.optimizedIntermediateWaypointIndex,routes.legs.distanceMeters,routes.legs.duration,routes.distanceMeters,routes.duration",
      },
      body: JSON.stringify(requestBody),
    }
  );

  if (!response.ok) {
    const errorText = await response.text();
    logger.error("Google Routes API error", {status: response.status, error: errorText});
    throw new Error(`Google Routes API returned ${response.status}`);
  }

  const data = await response.json() as any;
  const route = data.routes?.[0];

  if (!route) {
    throw new Error("No route returned from Google Routes API");
  }

  // Map the optimized order back to contactIds
  const optimizedIndices: number[] = route.optimizedIntermediateWaypointIndex || [];
  // The destination (last stop) is always last; intermediates are reordered
  const intermediateStops = stops.slice(0, -1);
  const destinationStop = stops[stops.length - 1];

  const orderedStops: OptimizeStop[] = [
    ...optimizedIndices.map((idx: number) => intermediateStops[idx]),
    destinationStop,
  ];

  // Extract per-leg distances and durations
  const legs = route.legs || [];
  let totalDistanceMeters = 0;
  let totalDurationSeconds = 0;

  const optimizedOrder: OptimizedStopResult[] = orderedStops.map((stop, i) => {
    const leg = legs[i]; // leg[i] is from previous point to this stop
    const distMeters = leg?.distanceMeters ?? null;
    const durSeconds = leg?.duration ? parseInt(leg.duration.replace("s", ""), 10) : null;

    if (distMeters) totalDistanceMeters += distMeters;
    if (durSeconds) totalDurationSeconds += durSeconds;

    return {
      contactId: stop.contactId,
      order: i,
      distanceToNextMeters: distMeters,
      durationToNextSeconds: durSeconds,
    };
  });

  return {
    success: true,
    optimizedOrder,
    totalDistanceKm: Math.round((totalDistanceMeters / 1000) * 10) / 10,
    totalDurationMinutes: Math.round(totalDurationSeconds / 60),
    source: "google_routes_api",
  };
}

// ---------------------------------------------------------------------------
// Cloud Function export
// ---------------------------------------------------------------------------

export const optimizeRouteGoogle = onRequest(
  {
    memory: "256MiB",
    timeoutSeconds: 60,
    secrets: [googleRoutesApiKey],
  },
  async (req, res) => {
    // CORS
    if (applyCors(req, res, {methods: "POST, OPTIONS"})) {
      return;
    }
    // Additional header for business ID
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Business-Id");

    if (req.method !== "POST") {
      res.status(405).json({error: "method"});
      return;
    }

    try {
      const {uid, businessId} = await requireAuth(req);

      // Rate limit
      if (isRateLimited(routeRateBuckets, businessId, ROUTE_LIMIT)) {
        res.status(429).json({error: "rate_limit"});
        return;
      }

      // Validate input
      const body: OptimizeRequest = req.body;
      const startLat = Number(body.startLatitude);
      const startLng = Number(body.startLongitude);
      const stops = Array.isArray(body.stops) ? body.stops : [];

      if (!isFinite(startLat) || !isFinite(startLng)) {
        res.status(400).json({error: "Invalid start coordinates"});
        return;
      }

      if (stops.length < 2) {
        res.status(400).json({error: "Need at least 2 stops to optimize"});
        return;
      }

      // Validate all stops have valid coordinates
      const validStops = stops.filter(
        (s) => s.contactId && isFinite(Number(s.latitude)) && isFinite(Number(s.longitude))
      ).map((s) => ({
        contactId: s.contactId,
        latitude: Number(s.latitude),
        longitude: Number(s.longitude),
      }));

      if (validStops.length < 2) {
        res.status(400).json({error: "Need at least 2 stops with valid coordinates"});
        return;
      }

      // Google Routes API has a 25 waypoint limit for intermediates
      if (validStops.length > 25) {
        res.status(400).json({error: "Maximum 25 stops supported for route optimization"});
        return;
      }

      // Try Google Routes API, fall back to nearest-neighbor
      let result: OptimizeResponse;
      try {
        const apiKey = googleRoutesApiKey.value();
        if (!apiKey) {
          throw new Error("GOOGLE_ROUTES_API_KEY not configured");
        }
        result = await callGoogleRoutesApi(apiKey, startLat, startLng, validStops);
      } catch (apiError) {
        logger.warn("Google Routes API failed, using fallback", {error: String(apiError)});
        result = nearestNeighborFallback(validStops, startLat, startLng);
      }

      // Audit log — no PHI, only metadata
      await auditLog(businessId, {
        action: "route_optimize",
        entity: "route",
        entityId: body.routeId,
        metadata: {
          uid,
          stopCount: validStops.length,
          source: result.source,
          totalDistanceKm: result.totalDistanceKm,
          totalDurationMinutes: result.totalDurationMinutes,
        },
      });

      res.status(200).json(result);
    } catch (error) {
      logger.error("optimizeRouteGoogle error", {error: String(error)});
      res.status(403).json({error: "forbidden"});
    }
  }
);
