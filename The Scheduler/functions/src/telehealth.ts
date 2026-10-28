/**
 * Cloud Functions for Telehealth Integration
 *
 * Priority 4: Zoom OAuth + Meeting Creation
 *
 * Handles:
 * - Zoom OAuth connection
 * - Zoom meeting creation for telehealth appointments
 *
 * Environment Variables Required:
 * - ZOOM_ACCOUNT_ID
 * - ZOOM_CLIENT_ID
 * - ZOOM_CLIENT_SECRET
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";

// Zoom OAuth Configuration
const zoomAccountId = process.env.ZOOM_ACCOUNT_ID || "";
const zoomClientId = process.env.ZOOM_CLIENT_ID || "";
const zoomClientSecret = process.env.ZOOM_CLIENT_SECRET || "";

interface ZoomAuthResponse {
  success: boolean;
  integrationId?: string;
  error?: string;
}

interface ZoomMeetingResponse {
  success: boolean;
  meetingUrl?: string;
  meetingId?: string;
  passcode?: string;
  error?: string;
}

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const logTelehealthError = (
  message: string,
  error: unknown,
  metadata: Record<string, unknown> = {}
) => {
  logger.error(message, {
    ...metadata,
    error: getErrorMessage(error),
  });
};

/**
 * Connect Zoom using server-to-server OAuth
 *
 * POST /connectZoom
 * Body: {
 *   businessId: string,
 *   userId: string
 * }
 *
 * Returns: { success: true, integrationId: string }
 */
export const connectZoom = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!zoomAccountId || !zoomClientId || !zoomClientSecret) {
    res.status(500).json({
      success: false,
      error: "Zoom OAuth not configured",
    });
    return;
  }

  try {
    const {businessId, userId} = req.body;

    if (!businessId || !userId) {
      res.status(400).json({
        success: false,
        error: "businessId and userId are required",
      });
      return;
    }

    // Get server-to-server OAuth token
    const tokenResponse = await fetch(
      "https://zoom.us/oauth/token?grant_type=account_credentials&account_id=" +
        zoomAccountId,
      {
        method: "POST",
        headers: {
          Authorization:
            "Basic " +
            Buffer.from(`${zoomClientId}:${zoomClientSecret}`).toString(
              "base64"
            ),
        },
      }
    );

    if (!tokenResponse.ok) {
      logger.error("Zoom token exchange failed", {
        status: tokenResponse.status,
        statusText: tokenResponse.statusText,
      });
      res.status(500).json({
        success: false,
        error: "Failed to connect to Zoom",
      });
      return;
    }

    const tokens = await tokenResponse.json();

    // Store integration
    const integrationId = db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc().id;

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(integrationId)
      .set({
        id: integrationId,
        provider: "zoom",
        userId,
        status: "connected",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

    // Store tokens
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(integrationId)
      .collection("tokens")
      .doc("oauth")
      .set({
        accessToken: tokens.access_token,
        expiresAt: new Date(Date.now() + tokens.expires_in * 1000),
        tokenType: tokens.token_type,
        updatedAt: FieldValue.serverTimestamp(),
      });

    const response: ZoomAuthResponse = {
      success: true,
      integrationId,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logTelehealthError("Error connecting Zoom", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Handle Zoom OAuth callback for user-level OAuth.
 *
 * If your deployment uses server-to-server OAuth only, this endpoint will
 * return a clear error instructing clients to use `connectZoom` instead.
 *
 * POST /handleZoomOAuthCallback
 * Body: { code: string, state: string }
 */
export const handleZoomOAuthCallback = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!req.body?.code || !req.body?.state) {
    res.status(400).json({
      success: false,
      error: "Missing code or state",
    });
    return;
  }

  // If user-level OAuth is needed in the future, implement token exchange here.
  // For now, we explicitly fail fast to avoid silent placeholders.
  res.status(501).json({
    success: false,
    error:
      "User-level Zoom OAuth is not enabled. Use server-to-server /connectZoom.",
  });
});

/**
 * Disconnect Zoom integration
 *
 * POST /disconnectZoom
 * Body: {
 *   businessId: string,
 *   integrationId: string
 * }
 *
 * Returns: { success: true }
 */
export const disconnectZoom = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, integrationId} = req.body;

    if (!businessId || !integrationId) {
      res.status(400).json({
        success: false,
        error: "businessId and integrationId are required",
      });
      return;
    }

    // Delete integration and tokens
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(integrationId)
      .delete();

    res.json({success: true});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logTelehealthError("Error disconnecting Zoom", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Create Zoom meeting for telehealth appointment
 *
 * POST /createZoomMeeting
 * Body: {
 *   businessId: string,
 *   integrationId: string,
 *   appointmentId: string,
 *   topic: string,
 *   startTime: string (ISO 8601),
 *   duration: number (minutes)
 * }
 *
 * Returns: {
 *   success: true,
 *   meetingUrl: string,
 *   meetingId: string,
 *   passcode: string
 * }
 */
export const createZoomMeeting = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, integrationId, appointmentId, topic, startTime, duration} =
      req.body;

    if (
      !businessId ||
      !integrationId ||
      !appointmentId ||
      !topic ||
      !startTime ||
      !duration
    ) {
      res.status(400).json({
        success: false,
        error: "All fields are required",
      });
      return;
    }

    // Get integration tokens
    const tokenDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(integrationId)
      .collection("tokens")
      .doc("oauth")
      .get();

    if (!tokenDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Integration not found",
      });
      return;
    }

    const tokens = tokenDoc.data();

    // Create Zoom meeting
    const meetingResponse = await fetch("https://api.zoom.us/v2/users/me/meetings", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${tokens?.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        topic,
        type: 2, // Scheduled meeting
        start_time: startTime,
        duration,
        timezone: "UTC",
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: false,
          waiting_room: true,
          auto_recording: "none",
        },
      }),
    });

    if (!meetingResponse.ok) {
      logger.error("Zoom meeting creation failed", {
        status: meetingResponse.status,
        statusText: meetingResponse.statusText,
      });
      res.status(500).json({
        success: false,
        error: "Failed to create Zoom meeting",
      });
      return;
    }

    const meeting = await meetingResponse.json();

    // Store meeting details with appointment
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(appointmentId)
      .update({
        telehealthMeetingUrl: meeting.join_url,
        telehealthMeetingId: meeting.id.toString(),
        telehealthProvider: "zoom",
        telehealthPasscode: meeting.password,
        updatedAt: FieldValue.serverTimestamp(),
      });

    const response: ZoomMeetingResponse = {
      success: true,
      meetingUrl: meeting.join_url,
      meetingId: meeting.id.toString(),
      passcode: meeting.password,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logTelehealthError("Error creating Zoom meeting", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});
