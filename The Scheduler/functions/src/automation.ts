import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import type {DecodedIdToken} from "firebase-admin/auth";
import {db, FieldValue, auth} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import {CanonicalUserRole, INTERNAL_BUSINESS_ROLES, normalizeUserRole} from "./roleUtils";

interface AuthResult {
  uid: string;
  businessId: string;
  role?: CanonicalUserRole;
}

async function verifyAuth(
  req: import("express").Request,
  res: import("express").Response,
  allowedRoles: readonly CanonicalUserRole[] = INTERNAL_BUSINESS_ROLES
): Promise<AuthResult | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({error: "Unauthorized"});
    return null;
  }
  const tokenString = authHeader.split(" ")[1];
  let decoded: DecodedIdToken;
  try {
    decoded = await auth.verifyIdToken(tokenString);
  } catch (error) {
    logger.warn("automation verifyAuth failed", {error});
    res.status(401).json({error: "Unauthorized"});
    return null;
  }
  const businessIdHeader = typeof req.headers["x-business-id"] === "string" ?
    req.headers["x-business-id"] as string :
    undefined;
  const businessId = businessIdHeader ??
    (typeof decoded.businessId === "string" ? decoded.businessId : undefined);
  if (!businessId) {
    res.status(400).json({error: "businessId is required"});
    return null;
  }

  const userDoc = await db.collection("users").doc(decoded.uid).get();
  const userData = userDoc.data() ?? {};
  const profileBusinessId = typeof userData.businessId === "string" ? userData.businessId : undefined;
  if (profileBusinessId && profileBusinessId !== businessId) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }

  const role = normalizeUserRole(decoded.role) ?? normalizeUserRole(userData.role);
  if (!role || !allowedRoles.includes(role)) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }
  return {uid: decoded.uid, businessId, role};
}

export const automationEvent = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  try {
    const {
      ruleId,
      actionType,
      entityType,
      entityId,
      correlationId,
      status,
      metadata,
    } = req.body ?? {};

    const runRef = db.collection("businesses")
      .doc(authResult.businessId)
      .collection("automation_runs")
      .doc();

    await runRef.set({
      businessId: authResult.businessId,
      ruleId: ruleId ?? "unspecified",
      actionType: actionType ?? "automationEvent",
      entityType: entityType ?? null,
      entityId: entityId ?? null,
      correlationId: correlationId ?? null,
      status: status ?? "success",
      createdAt: FieldValue.serverTimestamp(),
      executedAt: FieldValue.serverTimestamp(),
      userId: authResult.uid,
      metadata: metadata ?? {},
    });

    res.json({success: true, runId: runRef.id});
  } catch (error) {
    logger.error("automationEvent error", {error});
    res.status(500).json({error: "Failed to record automation event"});
  }
});
