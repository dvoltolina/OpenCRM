/**
 * Cloud Functions for Client Portal
 *
 * Priority 5: Client Portal Functions
 *
 * Handles:
 * - Magic link generation for passwordless access
 * - Magic link validation
 * - Client portal data retrieval
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import * as crypto from "crypto";

interface MagicLinkResponse {
  success: boolean;
  magicLink?: string;
  token?: string;
  error?: string;
}

interface PortalDataResponse {
  success: boolean;
  client?: Record<string, unknown>;
  appointments?: Record<string, unknown>[];
  forms?: Record<string, unknown>[];
  error?: string;
}

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

/**
 * Generate secure magic link for client portal access
 *
 * POST /generateMagicLink
 * Body: {
 *   businessId: string,
 *   clientId: string,
 *   expiresIn?: number (seconds, default 86400 = 24 hours)
 * }
 *
 * Returns: {
 *   success: true,
 *   magicLink: string,
 *   token: string
 * }
 */
export const generateMagicLink = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, clientId, expiresIn = 86400} = req.body;

    if (!businessId || !clientId) {
      res.status(400).json({
        success: false,
        error: "businessId and clientId are required",
      });
      return;
    }

    // Verify client exists
    const clientDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("clients")
      .doc(clientId)
      .get();

    if (!clientDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Client not found",
      });
      return;
    }

    // Generate secure token
    const token = crypto.randomBytes(32).toString("base64url");

    // Calculate expiration
    const expiresAt = new Date(Date.now() + expiresIn * 1000);

    // Store token
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("magic_links")
      .doc(token)
      .set({
        clientId,
        businessId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
        used: false,
      });

    // Build magic link URL
    const baseUrl = process.env.CLIENT_PORTAL_BASE_URL || "https://scheduler.example.com";
    const magicLink = `${baseUrl}/access?token=${token}&businessId=${businessId}`;

    const response: MagicLinkResponse = {
      success: true,
      magicLink,
      token,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error generating magic link:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Validate magic link token
 *
 * POST /validateMagicLink
 * Body: {
 *   token: string,
 *   businessId: string
 * }
 *
 * Returns: {
 *   success: true,
 *   clientId: string
 * }
 */
export const validateMagicLink = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {token, businessId} = req.body;

    if (!token || !businessId) {
      res.status(400).json({
        success: false,
        error: "token and businessId are required",
      });
      return;
    }

    // Get token document
    const tokenDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("magic_links")
      .doc(token)
      .get();

    if (!tokenDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Invalid token",
      });
      return;
    }

    const tokenData = tokenDoc.data();

    // Check if already used
    if (tokenData?.used) {
      res.status(403).json({
        success: false,
        error: "Token already used",
      });
      return;
    }

    // Check if expired
    const expiresAt = tokenData?.expiresAt?.toDate();
    if (expiresAt && expiresAt < new Date()) {
      res.status(403).json({
        success: false,
        error: "Token expired",
      });
      return;
    }

    // Mark token as used (single-use tokens for security)
    await tokenDoc.ref.update({
      used: true,
      usedAt: FieldValue.serverTimestamp(),
    });

    // HIPAA audit log: track portal access via magic link
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("audit_logs")
      .add({
        businessId,
        userId: tokenData?.clientId,
        actionType: "loginSuccess",
        entityType: "client_portal",
        entityId: tokenData?.clientId,
        timestamp: FieldValue.serverTimestamp(),
        metadata: {accessMethod: "magic_link"},
      });

    res.json({
      success: true,
      clientId: tokenData?.clientId,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error validating magic link:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Get client portal data
 *
 * POST /getClientPortalData
 * Body: {
 *   businessId: string,
 *   clientId: string
 * }
 *
 * Returns: {
 *   success: true,
 *   client: {...},
 *   appointments: [...],
 *   forms: [...]
 * }
 */
export const getClientPortalData = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, clientId} = req.body;

    if (!businessId || !clientId) {
      res.status(400).json({
        success: false,
        error: "businessId and clientId are required",
      });
      return;
    }

    // Get client data (sanitized for client view)
    const clientDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("clients")
      .doc(clientId)
      .get();

    if (!clientDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Client not found",
      });
      return;
    }

    const clientData = clientDoc.data();

    // Sanitize client data (remove internal fields)
    const client = {
      id: clientDoc.id,
      firstName: clientData?.firstName,
      lastName: clientData?.lastName,
      email: clientData?.email,
      phone: clientData?.phone,
      birthday: clientData?.birthday,
    };

    // Get appointments (future and recent past)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const appointmentsSnapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .where("clientId", "==", clientId)
      .where("startTime", ">=", thirtyDaysAgo)
      .orderBy("startTime", "desc")
      .limit(50)
      .get();

    const appointments = appointmentsSnapshot.docs.map((doc) => {
      const appt = doc.data();
      return {
        id: doc.id,
        startTime: appt.startTime,
        endTime: appt.endTime,
        status: appt.status,
        serviceId: appt.serviceId,
        providerId: appt.providerId,
        locationId: appt.locationId,
        notes: appt.notes,
        telehealthMeetingUrl: appt.telehealthMeetingUrl,
      };
    });

    // Get intake forms
    const formsSnapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("intake_forms")
      .where("clientId", "==", clientId)
      .orderBy("createdAt", "desc")
      .limit(20)
      .get();

    const forms = formsSnapshot.docs.map((doc) => {
      const form = doc.data();
      return {
        id: doc.id,
        templateName: form.templateName,
        status: form.status,
        createdAt: form.createdAt,
        submittedAt: form.submittedAt,
      };
    });

    const response: PortalDataResponse = {
      success: true,
      client,
      appointments,
      forms,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error getting client portal data:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});
