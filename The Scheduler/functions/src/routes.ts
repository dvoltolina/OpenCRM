/**
 * Cloud Functions for AI Route Optimization
 *
 * Proxies route optimization requests to the local AI server (RTX 3090).
 * Used by CRM portal and Admin portal to optimize routes for providers.
 *
 * HIPAA Compliance:
 * - All requests are authenticated and business-scoped
 * - Client location data is PHI - audit logged
 * - AI server runs on local infrastructure (PHI never leaves)
 *
 * Environment Variables:
 * - AI_BASE_URL: Base URL for the AI server (e.g., http://192.168.1.100:8000)
 * - AI_API_KEY: API key for AI server authentication (optional)
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "./firebaseAdmin";

// ============================================================================
// Types
// ============================================================================

interface Waypoint {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  windowStart: string; // ISO 8601
  windowEnd: string; // ISO 8601
  serviceDurationMinutes: number;
  priority?: number;
  isRequired?: boolean;
  clientId?: string;
  appointmentId?: string;
  address?: string;
  arrivalNotes?: string;
}

interface OptimizeRouteRequest {
  businessId: string;
  providerId: string;
  providerName?: string;
  routeDate: string; // ISO 8601 date
  depotLatitude: number;
  depotLongitude: number;
  depotAddress?: string;
  returnToDepot?: boolean;
  endLatitude?: number;
  endLongitude?: number;
  endAddress?: string;
  waypoints: Waypoint[];
  earliestDeparture: string; // ISO 8601
  latestReturn: string; // ISO 8601
  maxDrivingMinutes?: number;
  objective?: "minimize_time" | "minimize_distance" | "balance";
  includeBreaks?: boolean;
  breakDurationMinutes?: number;
  breakWindowStart?: string;
  breakWindowEnd?: string;
  bufferBetweenStopsMinutes?: number;
}

interface RouteStop {
  id: string;
  sequenceOrder: number;
  stopType: "depot" | "appointment" | "breakStop" | "endDepot";
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  windowStart: string;
  windowEnd: string;
  scheduledArrival: string;
  serviceDurationMinutes: number;
  bufferMinutes?: number;
  appointmentId?: string;
  clientId?: string;
  serviceId?: string;
  serviceName?: string;
  travelToNextMinutes?: number;
  distanceToNextMeters?: number;
  arrivalNotes?: string;
}

interface TravelSegment {
  id: string;
  fromStopId: string;
  toStopId: string;
  sequenceOrder: number;
  distanceMeters: number;
  estimatedDurationSeconds: number;
  encodedPolyline?: string;
  fromLatitude: number;
  fromLongitude: number;
  toLatitude: number;
  toLongitude: number;
}

interface OptimizedRoute {
  id: string;
  businessId: string;
  providerId: string;
  providerName: string;
  routeDate: string;
  status: "planned" | "in_progress" | "completed" | "cancelled";
  stops: RouteStop[];
  segments: TravelSegment[];
  startTime: string;
  expectedEndTime: string;
  totalDistanceMeters: number;
  totalTravelTimeSeconds: number;
  totalServiceTimeSeconds: number;
  originalDistanceMeters?: number;
  originalTravelTimeSeconds?: number;
  distanceSavedMeters?: number;
  timeSavedSeconds?: number;
  optimizationImprovementPercent?: number;
  objective: string;
  optimizerVersion: string;
  optimizedAt: string;
}

// ============================================================================
// Configuration
// ============================================================================

const AI_BASE_URL = process.env.AI_BASE_URL || "http://localhost:8000";
const AI_API_KEY = process.env.AI_API_KEY;
const ROUTE_ENDPOINT = "/api/v1/routes/optimize";
const REQUEST_TIMEOUT_MS = 30000;

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Verify caller has access to the business
 */
async function verifyBusinessAccess(
  request: CallableRequest,
  businessId: string
): Promise<{uid: string; role: string}> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid;

  // Check if user has role in business
  const memberDoc = await db
    .collection("businesses")
    .doc(businessId)
    .collection("members")
    .doc(uid)
    .get();

  if (!memberDoc.exists) {
    // Also check if user is owner
    const businessDoc = await db.collection("businesses").doc(businessId).get();
    if (!businessDoc.exists || businessDoc.data()?.ownerId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You do not have access to this business"
      );
    }
    return {uid, role: "owner"};
  }

  const role = memberDoc.data()?.role || "staff";
  return {uid, role};
}

/**
 * Log audit event for HIPAA compliance
 */
async function logAudit(
  businessId: string,
  uid: string,
  action: string,
  entityType: string,
  entityId: string,
  details?: Record<string, unknown>
): Promise<void> {
  try {
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("auditLogs")
      .add({
        action,
        entityType,
        entityId,
        userId: uid,
        timestamp: FieldValue.serverTimestamp(),
        source: "CloudFunction:routes",
        details: details || {},
      });
  } catch (e) {
    logger.warn("Failed to write audit log", {error: e});
  }
}

/**
 * Call the AI server for route optimization
 */
async function callAIServer(
  businessId: string,
  requestBody: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const url = `${AI_BASE_URL}${ROUTE_ENDPOINT}`;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "X-Business-ID": businessId,
  };

  if (AI_API_KEY) {
    headers["Authorization"] = `Bearer ${AI_API_KEY}`;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify(requestBody),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errorText = await response.text();
      logger.error("AI server error", {
        status: response.status,
        error: errorText,
      });
      throw new HttpsError(
        "internal",
        `Route optimization failed: ${response.status}`
      );
    }

    return (await response.json()) as Record<string, unknown>;
  } catch (error) {
    clearTimeout(timeoutId);

    if (error instanceof Error && error.name === "AbortError") {
      throw new HttpsError(
        "deadline-exceeded",
        "Route optimization request timed out"
      );
    }

    // If AI server is unavailable, throw specific error
    if (
      error instanceof Error &&
      (error.message.includes("ECONNREFUSED") ||
        error.message.includes("fetch failed"))
    ) {
      throw new HttpsError(
        "unavailable",
        "Route optimization service is temporarily unavailable"
      );
    }

    throw error;
  }
}

/**
 * Validate the optimization request
 */
function validateRequest(data: OptimizeRouteRequest): string[] {
  const errors: string[] = [];

  if (!data.businessId) {
    errors.push("businessId is required");
  }
  if (!data.providerId) {
    errors.push("providerId is required");
  }
  if (!data.routeDate) {
    errors.push("routeDate is required");
  }
  if (data.depotLatitude === undefined || data.depotLongitude === undefined) {
    errors.push("depot coordinates are required");
  }
  if (!data.waypoints || data.waypoints.length === 0) {
    errors.push("At least one waypoint is required");
  }
  if (!data.earliestDeparture || !data.latestReturn) {
    errors.push("earliestDeparture and latestReturn are required");
  }

  // Validate waypoints
  if (data.waypoints) {
    for (let i = 0; i < data.waypoints.length; i++) {
      const wp = data.waypoints[i];
      if (!wp.id) errors.push(`Waypoint ${i}: id is required`);
      if (wp.latitude === undefined || wp.longitude === undefined) {
        errors.push(`Waypoint ${i}: coordinates are required`);
      }
      if (!wp.windowStart || !wp.windowEnd) {
        errors.push(`Waypoint ${i}: time window is required`);
      }
    }
  }

  return errors;
}

// ============================================================================
// Cloud Functions
// ============================================================================

/**
 * Optimize a route for a provider's day.
 *
 * Callable from CRM, Admin Portal, or Mobile App.
 * Proxies to local AI server for actual optimization.
 */
export const optimizeRoute = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 60,
    cors: true,
  },
  async (request: CallableRequest): Promise<OptimizedRoute> => {
    const data = request.data as OptimizeRouteRequest;

    // Validate request
    const validationErrors = validateRequest(data);
    if (validationErrors.length > 0) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid request: ${validationErrors.join(", ")}`
      );
    }

    // Verify business access
    const {uid, role} = await verifyBusinessAccess(request, data.businessId);

    logger.info("Route optimization requested", {
      businessId: data.businessId,
      providerId: data.providerId,
      waypointCount: data.waypoints.length,
      routeDate: data.routeDate,
      uid,
      role,
    });

    // Build request body for AI server
    const aiRequestBody = {
      business_id: data.businessId,
      provider_id: data.providerId,
      route_date: data.routeDate,
      depot_latitude: data.depotLatitude,
      depot_longitude: data.depotLongitude,
      depot_address: data.depotAddress,
      return_to_depot: data.returnToDepot ?? true,
      end_latitude: data.endLatitude,
      end_longitude: data.endLongitude,
      end_address: data.endAddress,
      waypoints: data.waypoints.map((w) => ({
        id: w.id,
        name: w.name,
        latitude: w.latitude,
        longitude: w.longitude,
        window_start: w.windowStart,
        window_end: w.windowEnd,
        service_duration_minutes: w.serviceDurationMinutes,
        priority: w.priority ?? 1,
        is_required: w.isRequired ?? true,
        client_id: w.clientId,
        appointment_id: w.appointmentId,
        address: w.address,
        arrival_notes: w.arrivalNotes,
      })),
      earliest_departure: data.earliestDeparture,
      latest_return: data.latestReturn,
      max_driving_minutes: data.maxDrivingMinutes,
      objective: data.objective ?? "minimize_time",
      include_breaks: data.includeBreaks ?? false,
      break_duration_minutes: data.breakDurationMinutes ?? 30,
      break_window_start: data.breakWindowStart,
      break_window_end: data.breakWindowEnd,
      buffer_between_stops_minutes: data.bufferBetweenStopsMinutes ?? 5,
    };

    // Call AI server
    const aiResponse = await callAIServer(data.businessId, aiRequestBody);

    // Parse response into OptimizedRoute
    const now = new Date().toISOString();
    const routeId =
      (aiResponse.id as string) || `route_${Date.now()}_${data.providerId}`;

    const stops: RouteStop[] = ((aiResponse.stops as unknown[]) || []).map(
      (s: unknown) => {
        const stop = s as Record<string, unknown>;
        return {
          id: stop.id as string,
          sequenceOrder: stop.sequence_order as number,
          stopType: (stop.stop_type as RouteStop["stopType"]) || "appointment",
          name: (stop.name as string) || "",
          address: (stop.address as string) || "",
          latitude: stop.latitude as number,
          longitude: stop.longitude as number,
          windowStart: stop.window_start as string,
          windowEnd: stop.window_end as string,
          scheduledArrival: stop.scheduled_arrival as string,
          serviceDurationMinutes: (stop.service_duration_minutes as number) || 0,
          bufferMinutes: stop.buffer_minutes as number,
          appointmentId: stop.appointment_id as string,
          clientId: stop.client_id as string,
          serviceId: stop.service_id as string,
          serviceName: stop.service_name as string,
          travelToNextMinutes: stop.travel_to_next_minutes as number,
          distanceToNextMeters: stop.distance_to_next_meters as number,
          arrivalNotes: stop.arrival_notes as string,
        };
      }
    );

    const segments: TravelSegment[] = (
      (aiResponse.segments as unknown[]) || []
    ).map((s: unknown) => {
      const seg = s as Record<string, unknown>;
      return {
        id: (seg.id as string) || `seg_${Date.now()}`,
        fromStopId: seg.from_stop_id as string,
        toStopId: seg.to_stop_id as string,
        sequenceOrder: seg.sequence_order as number,
        distanceMeters: seg.distance_meters as number,
        estimatedDurationSeconds: seg.estimated_duration_seconds as number,
        encodedPolyline: seg.encoded_polyline as string,
        fromLatitude: seg.from_latitude as number,
        fromLongitude: seg.from_longitude as number,
        toLatitude: seg.to_latitude as number,
        toLongitude: seg.to_longitude as number,
      };
    });

    const optimizedRoute: OptimizedRoute = {
      id: routeId,
      businessId: data.businessId,
      providerId: data.providerId,
      providerName: data.providerName || "",
      routeDate: data.routeDate,
      status: "planned",
      stops,
      segments,
      startTime:
        (aiResponse.start_time as string) || data.earliestDeparture,
      expectedEndTime:
        (aiResponse.expected_end_time as string) || data.latestReturn,
      totalDistanceMeters: (aiResponse.total_distance_meters as number) || 0,
      totalTravelTimeSeconds:
        (aiResponse.total_travel_time_seconds as number) || 0,
      totalServiceTimeSeconds:
        (aiResponse.total_service_time_seconds as number) ||
        data.waypoints.reduce((sum, w) => sum + w.serviceDurationMinutes * 60, 0),
      originalDistanceMeters: aiResponse.original_distance_meters as number,
      originalTravelTimeSeconds:
        aiResponse.original_travel_time_seconds as number,
      distanceSavedMeters: aiResponse.distance_saved_meters as number,
      timeSavedSeconds: aiResponse.time_saved_seconds as number,
      optimizationImprovementPercent:
        aiResponse.optimization_improvement_percent as number,
      objective: data.objective || "minimize_time",
      optimizerVersion: (aiResponse.optimizer_version as string) || "1.0.0",
      optimizedAt: now,
    };

    // Save to Firestore
    await db
      .collection("businesses")
      .doc(data.businessId)
      .collection("optimizedRoutes")
      .doc(routeId)
      .set({
        ...optimizedRoute,
        createdAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });

    // Log audit event
    await logAudit(
      data.businessId,
      uid,
      "ai_route_optimization_success",
      "optimizedRoute",
      routeId,
      {
        providerId: data.providerId,
        waypointCount: data.waypoints.length,
        totalDistanceMeters: optimizedRoute.totalDistanceMeters,
        timeSavedSeconds: optimizedRoute.timeSavedSeconds,
      }
    );

    logger.info("Route optimization completed", {
      routeId,
      businessId: data.businessId,
      providerId: data.providerId,
      stopsCount: stops.length,
      totalDistanceMeters: optimizedRoute.totalDistanceMeters,
    });

    return optimizedRoute;
  }
);

/**
 * Get routes for a provider on a specific date.
 */
export const getProviderRoutes = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 30,
    cors: true,
  },
  async (
    request: CallableRequest
  ): Promise<{routes: OptimizedRoute[]}> => {
    const data = request.data as {
      businessId: string;
      providerId: string;
      date: string;
    };

    if (!data.businessId || !data.providerId || !data.date) {
      throw new HttpsError(
        "invalid-argument",
        "businessId, providerId, and date are required"
      );
    }

    // Verify business access
    await verifyBusinessAccess(request, data.businessId);

    // Query routes
    const snapshot = await db
      .collection("businesses")
      .doc(data.businessId)
      .collection("optimizedRoutes")
      .where("providerId", "==", data.providerId)
      .where("routeDate", "==", data.date)
      .orderBy("createdAt", "desc")
      .limit(10)
      .get();

    const routes: OptimizedRoute[] = snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        businessId: d.businessId,
        providerId: d.providerId,
        providerName: d.providerName || "",
        routeDate: d.routeDate,
        status: d.status,
        stops: d.stops || [],
        segments: d.segments || [],
        startTime: d.startTime,
        expectedEndTime: d.expectedEndTime,
        totalDistanceMeters: d.totalDistanceMeters,
        totalTravelTimeSeconds: d.totalTravelTimeSeconds,
        totalServiceTimeSeconds: d.totalServiceTimeSeconds,
        originalDistanceMeters: d.originalDistanceMeters,
        originalTravelTimeSeconds: d.originalTravelTimeSeconds,
        distanceSavedMeters: d.distanceSavedMeters,
        timeSavedSeconds: d.timeSavedSeconds,
        optimizationImprovementPercent: d.optimizationImprovementPercent,
        objective: d.objective,
        optimizerVersion: d.optimizerVersion,
        optimizedAt: d.optimizedAt,
      };
    });

    return {routes};
  }
);

/**
 * Update route status (start, complete, cancel).
 */
export const updateRouteStatus = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 30,
    cors: true,
  },
  async (request: CallableRequest): Promise<{success: boolean}> => {
    const data = request.data as {
      businessId: string;
      routeId: string;
      status: "planned" | "in_progress" | "completed" | "cancelled";
      reason?: string;
    };

    if (!data.businessId || !data.routeId || !data.status) {
      throw new HttpsError(
        "invalid-argument",
        "businessId, routeId, and status are required"
      );
    }

    const validStatuses = ["planned", "in_progress", "completed", "cancelled"];
    if (!validStatuses.includes(data.status)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid status. Must be one of: ${validStatuses.join(", ")}`
      );
    }

    // Verify business access
    const {uid} = await verifyBusinessAccess(request, data.businessId);

    // Update route
    const routeRef = db
      .collection("businesses")
      .doc(data.businessId)
      .collection("optimizedRoutes")
      .doc(data.routeId);

    const routeDoc = await routeRef.get();
    if (!routeDoc.exists) {
      throw new HttpsError("not-found", "Route not found");
    }

    const updateData: Record<string, unknown> = {
      status: data.status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    };

    if (data.status === "in_progress") {
      updateData.startedAt = FieldValue.serverTimestamp();
    } else if (data.status === "completed") {
      updateData.completedAt = FieldValue.serverTimestamp();
    } else if (data.status === "cancelled" && data.reason) {
      updateData.cancellationReason = data.reason;
    }

    await routeRef.update(updateData);

    // Log audit
    await logAudit(
      data.businessId,
      uid,
      `route_status_${data.status}`,
      "optimizedRoute",
      data.routeId,
      {status: data.status, reason: data.reason}
    );

    return {success: true};
  }
);

/**
 * Geocode an address to coordinates.
 * Uses Nominatim (OpenStreetMap) for free geocoding.
 */
export const geocodeAddress = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 15,
    cors: true,
  },
  async (
    request: CallableRequest
  ): Promise<{
    latitude: number;
    longitude: number;
    formattedAddress: string;
    accuracy: string;
  }> => {
    const data = request.data as {
      businessId: string;
      address: string;
      city?: string;
      state?: string;
      zipCode?: string;
      country?: string;
    };

    if (!data.businessId || !data.address) {
      throw new HttpsError(
        "invalid-argument",
        "businessId and address are required"
      );
    }

    // Verify business access
    await verifyBusinessAccess(request, data.businessId);

    // Build full address string
    const addressParts = [
      data.address,
      data.city,
      data.state,
      data.zipCode,
      data.country || "USA",
    ].filter(Boolean);
    const fullAddress = addressParts.join(", ");

    // Call Nominatim (OpenStreetMap free geocoding)
    const encodedAddress = encodeURIComponent(fullAddress);
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodedAddress}&limit=1`;

    const response = await fetch(url, {
      headers: {
        "User-Agent": "TheScheduler/1.0 (contact@scheduler.example.com)",
      },
    });

    if (!response.ok) {
      throw new HttpsError("internal", "Geocoding service error");
    }

    const results = (await response.json()) as Array<{
      lat: string;
      lon: string;
      display_name: string;
      class: string;
    }>;

    if (!results || results.length === 0) {
      throw new HttpsError(
        "not-found",
        "Could not geocode address. Please check the address and try again."
      );
    }

    const result = results[0];

    // Determine accuracy based on result class
    let accuracy = "approximate";
    if (result.class === "building" || result.class === "place") {
      accuracy = "rooftop";
    } else if (result.class === "highway") {
      accuracy = "interpolated";
    }

    return {
      latitude: parseFloat(result.lat),
      longitude: parseFloat(result.lon),
      formattedAddress: result.display_name,
      accuracy,
    };
  }
);
