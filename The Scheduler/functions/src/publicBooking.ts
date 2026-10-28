import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue, Timestamp} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";

type PublicBookingRequest = {
  businessId?: string;
  serviceId?: string;
  providerId?: string;
  startTime?: string;
  durationMinutes?: number;
  client?: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phone?: string;
  };
  notes?: string;
};

const RATE_WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_IP = 20;
const rateBuckets: Map<string, {count: number; windowStart: number}> = new Map();

const rateLimited = (ip: string): boolean => {
  const now = Date.now();
  const bucket = rateBuckets.get(ip);
  if (!bucket || now - bucket.windowStart > RATE_WINDOW_MS) {
    rateBuckets.set(ip, {count: 1, windowStart: now});
    return false;
  }
  if (bucket.count >= MAX_REQUESTS_PER_IP) return true;
  bucket.count += 1;
  return false;
};

const sanitizeString = (value: unknown, max = 120): string | undefined => {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  if (!trimmed) return undefined;
  return trimmed.slice(0, max);
};

const getIp = (req: import("express").Request): string =>
  ((req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0] || req.ip || "unknown").trim();

const requireBusiness = async (businessId: string): Promise<FirebaseFirestore.DocumentSnapshot> => {
  const snap = await db.collection("businesses").doc(businessId).get();
  if (!snap.exists) {
    throw new Error("business_not_found");
  }
  return snap;
};

const ensureSlotAvailable = async (
  businessId: string,
  providerId: string,
  start: Timestamp,
  end: Timestamp
): Promise<void> => {
  // Basic overlap check: any appointment for provider that starts within the requested window.
  const snap = await db
    .collection("businesses")
    .doc(businessId)
    .collection("appointments")
    .where("providerId", "==", providerId)
    .where("startTime", ">=", Timestamp.fromMillis(start.toMillis() - 60 * 60 * 1000))
    .where("startTime", "<=", end)
    .limit(1)
    .get();

  if (!snap.empty) {
    throw new Error("slot_unavailable");
  }
};

export const publicCreateAppointment = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const ip = getIp(req);
  if (rateLimited(ip)) {
    res.status(429).json({error: "Too many requests"});
    return;
  }

  const body = (req.body ?? {}) as PublicBookingRequest;
  const businessId = sanitizeString(body.businessId);
  const serviceId = sanitizeString(body.serviceId);
  const providerId = sanitizeString(body.providerId);
  const startIso = sanitizeString(body.startTime);
  const durationMinutes =
    typeof body.durationMinutes === "number" && body.durationMinutes > 0 ?
      Math.min(body.durationMinutes, 240) :
      30;
  const clientFirstName = sanitizeString(body.client?.firstName);
  const clientLastName = sanitizeString(body.client?.lastName);
  const clientEmail = sanitizeString(body.client?.email);
  const clientPhone = sanitizeString(body.client?.phone, 40);
  const notes = sanitizeString(body.notes, 500);

  if (!businessId || !serviceId || !providerId || !startIso) {
    res.status(400).json({error: "businessId, serviceId, providerId, startTime are required"});
    return;
  }
  if (!clientFirstName || !clientLastName || !clientEmail) {
    res.status(400).json({error: "client firstName, lastName, and email are required"});
    return;
  }

  let startTs: Timestamp;
  try {
    const millis = Date.parse(startIso);
    if (Number.isNaN(millis)) throw new Error("bad_date");
    startTs = Timestamp.fromMillis(millis);
  } catch {
    res.status(400).json({error: "Invalid startTime"});
    return;
  }

  const now = Timestamp.now();
  if (startTs.toMillis() < now.toMillis()) {
    res.status(400).json({error: "startTime must be in the future"});
    return;
  }

  const endTs = Timestamp.fromMillis(startTs.toMillis() + durationMinutes * 60 * 1000);

  try {
    await requireBusiness(businessId);
    await ensureSlotAvailable(businessId, providerId, startTs, endTs);

    const clientRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("clients")
      .doc();

    const appointmentRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc();

    await db.runTransaction(async (tx) => {
      tx.set(clientRef, {
        id: clientRef.id,
        businessId,
        firstName: clientFirstName,
        lastName: clientLastName,
        email: clientEmail,
        phone: clientPhone || null,
        lifecycle: "prospect",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(appointmentRef, {
        id: appointmentRef.id,
        businessId,
        serviceId,
        providerId,
        clientId: clientRef.id,
        startTime: startTs,
        endTime: endTs,
        status: "requested",
        source: "public_booking",
        notes: notes || null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    res.json({
      success: true,
      appointmentId: appointmentRef.id,
      clientId: clientRef.id,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "internal_error";
    if (message === "business_not_found") {
      res.status(404).json({error: "Business not found"});
      return;
    }
    if (message === "slot_unavailable") {
      res.status(409).json({error: "Requested slot is unavailable"});
      return;
    }
    logger.error("publicCreateAppointment failed", {error});
    res.status(500).json({error: "Internal error"});
  }
});

export const publicListCatalog = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "GET") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  const businessId = sanitizeString(req.query.businessId, 120);
  if (!businessId) {
    res.status(400).json({error: "businessId is required"});
    return;
  }
  try {
    await requireBusiness(businessId);
    const [servicesSnap, providersSnap, locationsSnap] = await Promise.all([
      db.collection("businesses").doc(businessId).collection("services").where("isActive", "==", true).get(),
      db.collection("businesses").doc(businessId).collection("providers").where("isActive", "==", true).get(),
      db.collection("businesses").doc(businessId).collection("locations").get(),
    ]);

    const services = servicesSnap.docs.map((d) => ({
      id: d.id,
      name: d.get("name"),
      durationMinutes: d.get("durationMinutes") ?? null,
      priceCents: d.get("priceCents") ?? null,
    }));
    const providers = providersSnap.docs.map((d) => ({
      id: d.id,
      name: `${d.get("firstName") ?? ""} ${d.get("lastName") ?? ""}`.trim(),
      locationId: d.get("locationId") ?? null,
    }));
    const locations = locationsSnap.docs.map((d) => ({
      id: d.id,
      name: d.get("name") ?? "",
    }));

    res.json({services, providers, locations});
  } catch (error) {
    logger.error("publicListCatalog failed", {error});
    res.status(500).json({error: "Internal error"});
  }
});

export const resolveBusinessSlug = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "GET") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  const slug = sanitizeString(req.query.slug, 120);
  if (!slug) {
    res.status(400).json({error: "slug is required"});
    return;
  }
  try {
    const snap = await db
      .collection("businesses")
      .where("slug", "==", slug)
      .limit(1)
      .get();
    if (snap.empty) {
      res.status(404).json({error: "Business not found"});
      return;
    }
    const doc = snap.docs[0];
    const data = doc.data() as Record<string, unknown>;
    res.json({
      businessId: doc.id,
      name: data.name ?? null,
      slug,
      publicBookingUrl: data.publicBookingUrl ?? null,
    });
  } catch (error) {
    logger.error("resolveBusinessSlug failed", {error});
    res.status(500).json({error: "Internal error"});
  }
});

export const publicGetAvailableAppointments = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const {businessId, providerId, startDate, days = 7} = req.body ?? {};
  const cleanBusinessId = sanitizeString(businessId, 120);
  const cleanProviderId = sanitizeString(providerId, 120);
  const clampedDays = Number.isFinite(days) ? Math.min(Math.max(Number(days), 1), 14) : 7;

  if (!cleanBusinessId) {
    res.status(400).json({error: "businessId is required"});
    return;
  }

  let rangeStart: Timestamp;
  let rangeEnd: Timestamp;
  try {
    const base = startDate ? new Date(startDate as string) : new Date();
    base.setHours(0, 0, 0, 0);
    rangeStart = Timestamp.fromDate(base);
    const end = new Date(base);
    end.setDate(end.getDate() + clampedDays);
    rangeEnd = Timestamp.fromDate(end);
  } catch {
    res.status(400).json({error: "Invalid startDate"});
    return;
  }

  try {
    await requireBusiness(cleanBusinessId);
    let query = db
      .collection("businesses")
      .doc(cleanBusinessId)
      .collection("appointments")
      .where("isGroupSession", "==", false)
      .where("startTime", ">=", rangeStart)
      .where("startTime", "<=", rangeEnd)
      .orderBy("startTime", "asc")
      .limit(50);

    if (cleanProviderId) {
      query = query.where("providerId", "==", cleanProviderId);
    }

    const snap = await query.get();
    const nowMs = Date.now();
    const slots = snap.docs
      .map((d) => {
        const data = d.data();
        const start = data.startTime as FirebaseFirestore.Timestamp | undefined;
        const end = data.endTime as FirebaseFirestore.Timestamp | undefined;
        if (!start) return null;
        return {
          id: d.id,
          serviceId: data.serviceId ?? null,
          providerId: data.providerId ?? null,
          locationId: data.locationId ?? null,
          startTime: start.toDate(),
          endTime: end ? end.toDate() : null,
          priceCents: data.priceCents ?? null,
          status: data.status ?? null,
        };
      })
      .filter(Boolean)
      .filter((slot) => {
        // basic filter: future only, and either available/requested/scheduled
        const startMs = (slot as {startTime: Date}).startTime.getTime();
        const status = (slot as {status?: string}).status;
        const allowed = ["available", "scheduled", "open"];
        return startMs > nowMs && (!status || allowed.includes(status));
      });

    res.json({slots});
  } catch (error) {
    logger.error("publicGetAvailableAppointments failed", {error});
    res.status(500).json({error: "Internal error"});
  }
});
