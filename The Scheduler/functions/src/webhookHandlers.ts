import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import {db, auth, FieldValue, Timestamp} from "./firebaseAdmin";
import {runImport} from "./importer";
import {INTERNAL_BUSINESS_ROLES, normalizeUserRole} from "./roleUtils";

type RateBucket = {count: number; windowStart: number};

const webhookRateBuckets: Map<string, RateBucket> = new Map(); // per businessId (100/hour)
const syncRateBuckets: Map<string, RateBucket> = new Map(); // per businessId (20 / 5 minutes)
const exportRateBuckets: Map<string, RateBucket> = new Map(); // per businessId (20 / day)

const WEBHOOK_LIMIT = {max: 100, windowMs: 60 * 60 * 1000};
const SYNC_LIMIT = {max: 20, windowMs: 5 * 60 * 1000};
const EXPORT_LIMIT = {max: 20, windowMs: 24 * 60 * 60 * 1000};

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const sanitizeStringArray = (value: unknown): string[] =>
  Array.from(
    new Set(
      (Array.isArray(value) ? value : [])
        .filter((entry): entry is string => typeof entry === "string")
        .map((entry) => entry.trim())
        .filter(Boolean)
    )
  );

const isRateLimited = (map: Map<string, RateBucket>, key: string, limit: {max: number; windowMs: number}) => {
  const now = Date.now();
  const bucket = map.get(key);
  if (!bucket || now - bucket.windowStart > limit.windowMs) {
    map.set(key, {count: 1, windowStart: now});
    return false;
  }
  if (bucket.count >= limit.max) return true;
  bucket.count += 1;
  return false;
};

const hmacValid = (secret: string, rawBody: Buffer, headerSignature?: string): boolean => {
  if (!headerSignature) return false;
  const computed = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
  try {
    return crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(headerSignature));
  } catch {
    return false;
  }
};

const auditLog = async (
  businessId: string,
  entry: {action: string; entity: string; entityId?: string; metadata?: Record<string, unknown>}
) => {
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
};

const loadUserProfile = async (
  uid: string
): Promise<{
  businessId?: string;
  role?: string;
  displayName?: string;
  teamIds?: string[];
  managedTeamIds?: string[];
} | null> => {
  try {
    const snap = await db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    const data = snap.data();
    return {
      businessId: typeof data?.businessId === "string" ? data.businessId.trim() : undefined,
      role: typeof data?.role === "string" ? data.role.trim() : undefined,
      displayName: typeof data?.displayName === "string" ? data.displayName.trim() : undefined,
      teamIds: sanitizeStringArray(data?.teamIds),
      managedTeamIds: sanitizeStringArray(data?.managedTeamIds),
    };
  } catch (error) {
    logger.warn("loadUserProfile failed", {error, uid});
    return null;
  }
};

const requireAuth = async (
  req: any
): Promise<{uid: string; businessId: string; role?: string; displayName?: string; teamIds: string[]}> => {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    throw new Error("unauthorized");
  }
  const tokenString = header.split(" ")[1];
  const decoded = await auth.verifyIdToken(tokenString);
  const headerBusinessId =
    typeof req.headers["x-business-id"] === "string" ? (req.headers["x-business-id"] as string).trim() : undefined;

  let businessId = typeof decoded.businessId === "string" ? decoded.businessId.trim() : headerBusinessId;
  let role = typeof decoded.role === "string" ? decoded.role.trim() : undefined;
  let displayName = typeof decoded.name === "string" ? decoded.name.trim() : undefined;
  const tokenTeamIds = sanitizeStringArray(decoded.teamIds);
  const tokenManagedTeamIds = sanitizeStringArray(decoded.managedTeamIds);
  let profile: Awaited<ReturnType<typeof loadUserProfile>> = null;

  if (!businessId || !role || !displayName || tokenTeamIds.length === 0) {
    profile = await loadUserProfile(decoded.uid);
    if (profile) {
      businessId = businessId || profile.businessId;
      role = role || profile.role;
      displayName = displayName || profile.displayName;
    }
  }

  if (!businessId) throw new Error("invalid-business");
  return {
    uid: decoded.uid,
    businessId,
    role,
    displayName,
    teamIds: Array.from(
      new Set([
        ...tokenTeamIds,
        ...tokenManagedTeamIds,
        ...(profile?.teamIds || []),
        ...(profile?.managedTeamIds || []),
      ])
    ),
  };
};

// ---------------------------------------------------------------------------
// Inbound Webhook: lead intake
// ---------------------------------------------------------------------------

export const leadIntakeWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({accepted: false, reason: "method"});
    return;
  }

  try {
    const secret = process.env.SENDGRID_WEBHOOK_SECRET || process.env.LEAD_WEBHOOK_SECRET;
    if (!secret) {
      res.status(500).json({accepted: false, reason: "config"});
      return;
    }

    const sigHeader = (req.headers["x-signature"] as string | undefined) ?? req.headers["x-sendgrid-signature"];
    if (!req.rawBody || !hmacValid(secret, req.rawBody, typeof sigHeader === "string" ? sigHeader : undefined)) {
      res.status(403).json({accepted: false, reason: "signature"});
      return;
    }

  const payload = typeof req.body === "object" && req.body ? req.body : {};
  const businessId =
    typeof payload.businessId === "string"
      ? payload.businessId.trim()
      : typeof req.headers["x-business-id"] === "string"
        ? (req.headers["x-business-id"] as string).trim()
        : undefined;

    if (!businessId) {
      res.status(403).json({accepted: false, reason: "business"});
      return;
    }

    if (isRateLimited(webhookRateBuckets, businessId, WEBHOOK_LIMIT)) {
      res.status(429).json({accepted: false, reason: "rate_limit"});
      return;
    }

    const eventId = typeof payload.eventId === "string" ? payload.eventId : crypto.randomUUID();
    const docId = eventId || crypto.randomUUID();

    const intakeDoc = {
      fullName: typeof payload.fullName === "string" ? payload.fullName.trim() : "",
      email: typeof payload.email === "string" ? payload.email.trim().toLowerCase() : "",
      source: typeof payload.source === "string" ? payload.source.trim() : "unknown",
      timestamp:
        payload.timestamp instanceof Date
          ? payload.timestamp
          : typeof payload.timestamp === "string"
            ? new Date(payload.timestamp)
            : new Date(),
      createdAt: Timestamp.now(),
      eventId: eventId,
    };

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("lead_intake_events")
      .doc(docId)
      .set(intakeDoc);
    await auditLog(businessId, {
      action: "webhook",
      entity: "webhook",
      entityId: eventId,
      metadata: {
        destination: "lead-intake",
        payloadHash: crypto.createHash("sha256").update(req.rawBody).digest("hex"),
      },
    });

    res.status(200).json({accepted: true});
  } catch (error) {
    logger.error("leadIntakeWebhook error", {error: getErrorMessage(error)});
    res.status(400).json({accepted: false, reason: "error"});
  }
});

// ---------------------------------------------------------------------------
// Outbound webhook dispatcher (stub with dead-letter)
// ---------------------------------------------------------------------------

export const dispatchWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "method"});
    return;
  }
  try {
    const {destination, businessId} = req.body ?? {};
    if (typeof destination !== "string" || typeof businessId !== "string") {
      res.status(400).json({error: "invalid"});
      return;
    }

    const payload = typeof req.body.payload === "object" ? req.body.payload : {};
    const payloadHash = crypto.createHash("sha256").update(JSON.stringify(payload)).digest("hex");
    const attempts = typeof req.body.attempts === "number" ? req.body.attempts : 0;

    // Stub: simulate failure path to dead-letter after 3 attempts
    if (attempts >= 3) {
      const deadRef = await db
        .collection("businesses")
        .doc(businessId)
        .collection("deadLetters")
        .add({
          destination,
          attempts,
          lastAttemptAt: FieldValue.serverTimestamp(),
          payloadHash,
          reason: "max_attempts",
          status: "failed",
        });

      await auditLog(businessId, {
        action: "webhook",
        entity: "webhook",
        entityId: deadRef.id,
        metadata: {destination, attempts, deadLetterId: deadRef.id},
      });

      res.status(500).json({error: "failed", deadLetterId: deadRef.id});
      return;
    }

    // Success stub
    await auditLog(businessId, {
      action: "export",
      entity: "webhook",
      metadata: {destination, attempts: attempts + 1},
    });
    res.status(200).json({success: true});
  } catch (error) {
    logger.error("dispatchWebhook error", {error: getErrorMessage(error)});
    res.status(500).json({error: "internal"});
  }
});

// ---------------------------------------------------------------------------
// Integration sync trigger
// ---------------------------------------------------------------------------

export const integrationSync = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "method"});
    return;
  }
  try {
    const {uid, businessId, role} = await requireAuth(req);
    if (isRateLimited(syncRateBuckets, businessId, SYNC_LIMIT)) {
      const bucket = syncRateBuckets.get(businessId)!;
      const resetAt = new Date(bucket.windowStart + SYNC_LIMIT.windowMs).toISOString();
      res.status(429).json({error: "rate_limit", resetAt});
      return;
    }

    const {integrationId, direction} = req.body ?? {};
    if (typeof integrationId !== "string" || !["pull", "push", "bidirectional"].includes(direction)) {
      res.status(400).json({error: "invalid"});
      return;
    }

    await auditLog(businessId, {
      action: "integration",
      entity: "integration",
      entityId: integrationId,
      metadata: {direction, role, uid},
    });

    res.status(200).json({
      success: true,
      created: 0,
      updated: 0,
      skipped: 0,
      conflicts: [],
      resumeCursor: null,
    });
  } catch (error) {
    logger.error("integrationSync error", {error: getErrorMessage(error)});
    res.status(400).json({error: "unauthorized"});
  }
});

// ---------------------------------------------------------------------------
// Import / Export (stubs with RBAC + rate limits)
// ---------------------------------------------------------------------------

const IMPORT_ALLOWED_ROLES = [...INTERNAL_BUSINESS_ROLES];

const assertRole = (role?: string) => {
  const normalizedRole = normalizeUserRole(role);
  if (!normalizedRole || (normalizedRole !== "owner" && normalizedRole !== "admin" && normalizedRole !== "manager")) {
    throw new Error("forbidden");
  }
};

const assertImportRole = (role?: string) => {
  // More permissive for imports - allow any authenticated business user
  // HIPAA audit logging tracks who performed the import
  const normalizedRole = normalizeUserRole(role);
  if (!normalizedRole || !(IMPORT_ALLOWED_ROLES as readonly string[]).includes(normalizedRole)) {
    throw new Error("forbidden");
  }
};

// HIPAA-compliant allowed origins for CRM
const ALLOWED_ORIGINS = [
  "https://your-firebase-project.web.app",
  "https://your-firebase-project.firebaseapp.com",
  "https://your-firebase-project.web.app",
  "https://your-firebase-project.firebaseapp.com",
  "https://app.example.com",
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5175",
  "http://localhost:3000",
  "http://127.0.0.1:5173",
  "http://127.0.0.1:5174",
  "http://127.0.0.1:5175",
  "http://127.0.0.1:3000",
];

const getCorsOrigin = (requestOrigin?: string): string => {
  if (!requestOrigin) return ALLOWED_ORIGINS[0];
  if (ALLOWED_ORIGINS.includes(requestOrigin)) return requestOrigin;
  // For security, don't reflect unknown origins
  return ALLOWED_ORIGINS[0];
};

export const importData = onRequest(async (req, res) => {
  // HIPAA-compliant CORS - restrict to known origins
  const origin = req.headers.origin as string | undefined;
  res.set("Access-Control-Allow-Origin", getCorsOrigin(origin));
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Business-Id");
  res.set("Access-Control-Max-Age", "3600");
  res.set("Access-Control-Allow-Credentials", "true");

  // Handle preflight OPTIONS request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({error: "method"});
    return;
  }
  try {
    const {businessId, role, uid, displayName, teamIds} = await requireAuth(req);
    assertImportRole(role);

    const sessionId =
      typeof req.body?.sessionId === "string" && req.body.sessionId.trim()
        ? req.body.sessionId.trim()
        : crypto.randomUUID();

    const entityType = typeof req.body?.entityType === "string" ? req.body.entityType : "unknown";
    const rowCount = Array.isArray(req.body?.rows) ? req.body.rows.length : 0;

    const duplicateHandling =
      req.body?.duplicateHandling === "update" || req.body?.duplicateHandling === "create"
        ? req.body.duplicateHandling
        : "skip";

    const importResult = await runImport(db, {
      entityType: entityType as any,
      headers: Array.isArray(req.body?.headers) ? req.body.headers : [],
      rows: Array.isArray(req.body?.rows) ? req.body.rows : [],
      fieldMapping: (req.body?.fieldMapping as Record<string, string>) || {},
      businessId,
      duplicateHandling,
      skipFirstRow: req.body?.skipFirstRow === true,
      dryRun: req.body?.dryRun === true,
      existingIdentifiers: req.body?.existingIdentifiers,
      ownerId: uid,
      ownerName: displayName,
      teamIds,
    });

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("importJobs")
      .doc(sessionId)
      .set(
        {
          status:
            importResult.imported > 0 ||
              (importResult.validationErrors.length === 0 && !importResult.errors?.length)
              ? "completed"
              : "paused",
          entityType,
          processedRows: importResult.imported,
          totalRows: rowCount,
          errorCount: importResult.validationErrors.length,
          importedBy: uid,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          validationErrors: importResult.validationErrors,
          errors: importResult.errors || [],
        },
        {merge: true}
      );

    // HIPAA audit log - record PHI access without logging actual PHI
    await auditLog(businessId, {
      action: "import",
      entity: "importJob",
      entityId: sessionId,
      metadata: {
        uid,
        entityType,
        processedRows: importResult.imported,
        userAgent: req.headers["user-agent"] || "unknown",
        // Note: Do NOT log actual row data (PHI) - only counts and metadata
      },
    });

    res.status(200).json({
      success: importResult.validationErrors.length === 0 && !importResult.errors?.length,
      sessionId,
      processedRows: importResult.imported,
      totalRows: rowCount,
      validationErrors: importResult.validationErrors,
      errors: importResult.errors,
    });
  } catch (error) {
    logger.error("importData error", {error: getErrorMessage(error)});
    res.status(403).json({error: "forbidden"});
  }
});

export const resumeImport = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "method"});
    return;
  }
  try {
    const {role} = await requireAuth(req);
    assertRole(role);
    const sessionId = typeof req.body?.sessionId === "string" ? req.body.sessionId : undefined;
    if (!sessionId) {
      res.status(400).json({error: "sessionId"});
      return;
    }
    res.status(200).json({
      success: true,
      processedRows: 0,
      totalRows: 0,
      validationErrors: [],
      errors: [],
    });
  } catch (error) {
    logger.error("resumeImport error", {error: getErrorMessage(error)});
    res.status(403).json({error: "forbidden"});
  }
});

export const exportData = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "method"});
    return;
  }
  try {
    const {businessId, role} = await requireAuth(req);
    assertRole(role);
    if (isRateLimited(exportRateBuckets, businessId, EXPORT_LIMIT)) {
      res.status(429).json({error: "rate_limit"});
      return;
    }
    const exportId = crypto.randomUUID();
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("exportJobs")
      .doc(exportId)
      .set({
        status: "completed",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        format: req.body?.format ?? "csv",
      });

    await auditLog(businessId, {
      action: "export",
      entity: "exportJob",
      entityId: exportId,
      metadata: {format: req.body?.format ?? "csv"},
    });

    res.setHeader("X-Export-Id", exportId);
    res.setHeader("Content-Type", req.body?.format === "pdf" ? "application/pdf" : "text/csv");
    res.status(200).send(req.body?.format === "pdf" ? "%PDF-1.4\n%" : "id\n");
  } catch (error) {
    logger.error("exportData error", {error: getErrorMessage(error)});
    res.status(403).json({error: "forbidden"});
  }
});
