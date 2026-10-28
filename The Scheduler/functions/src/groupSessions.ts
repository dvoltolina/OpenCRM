/**
 * Cloud Functions for Group Sessions
 *
 * Priority 5: Group Session Functions
 *
 * Handles:
 * - Join group session (add attendee with payment)
 * - Leave group session (remove attendee, process refund)
 * - Get available group sessions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue, Timestamp} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import Stripe from "stripe";

// Initialize Stripe (only if configured)
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripe = stripeSecretKey ?
  new Stripe(stripeSecretKey, {apiVersion: "2025-02-24.acacia"}) :
  null;

interface GroupSessionResponse {
  success: boolean;
  sessionId?: string;
  attendeeId?: string;
  error?: string;
}

interface AvailableSessionsResponse {
  success: boolean;
  sessions?: Record<string, unknown>[];
  error?: string;
}

type Attendee = {
  id?: string;
  clientId?: string;
  paymentIntentId?: string;
  status?: string;
};

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const logGroupSessionError = (
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
 * Add attendee to group session with payment
 *
 * POST /joinGroupSession
 * Body: {
 *   businessId: string,
 *   sessionId: string,
 *   clientId: string,
 *   paymentIntentId?: string (if payment required)
 * }
 *
 * Returns: {
 *   success: true,
 *   sessionId: string,
 *   attendeeId: string
 * }
 */
export const joinGroupSession = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, sessionId, clientId, paymentIntentId} = req.body;

    if (!businessId || !sessionId || !clientId) {
      res.status(400).json({
        success: false,
        error: "businessId, sessionId, and clientId are required",
      });
      return;
    }

    // Get session
    const sessionDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .get();

    if (!sessionDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Session not found",
      });
      return;
    }

    const session = sessionDoc.data();

    // Check capacity
    const currentAttendees = session?.attendees?.length || 0;
    const maxCapacity = session?.maxCapacity || 0;

    if (currentAttendees >= maxCapacity) {
      res.status(400).json({
        success: false,
        error: "Session is full",
      });
      return;
    }

    // Check if client already joined
    const attendees: Attendee[] = Array.isArray(session?.attendees) ?
      session.attendees as Attendee[] :
      [];
    const alreadyJoined = attendees.some(
      (attendee) => attendee.clientId === clientId
    );

    if (alreadyJoined) {
      res.status(400).json({
        success: false,
        error: "Client already joined this session",
      });
      return;
    }

    // Get client data
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

    const client = clientDoc.data();

    // Create attendee record
    const attendeeId = db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .collection("attendees")
      .doc().id;

    const attendee = {
      id: attendeeId,
      clientId,
      clientName: `${client?.firstName} ${client?.lastName}`,
      clientEmail: client?.email,
      joinedAt: FieldValue.serverTimestamp(),
      paymentIntentId: paymentIntentId || null,
      status: "confirmed",
    };

    // Add attendee to session
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .update({
        attendees: FieldValue.arrayUnion(attendee),
        currentCapacity: currentAttendees + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });

    // Store detailed attendee record
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .collection("attendees")
      .doc(attendeeId)
      .set(attendee);

    const response: GroupSessionResponse = {
      success: true,
      sessionId,
      attendeeId,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logGroupSessionError("Error joining group session", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Remove attendee from group session and process refund
 *
 * POST /leaveGroupSession
 * Body: {
 *   businessId: string,
 *   sessionId: string,
 *   attendeeId: string,
 *   refundReason?: string
 * }
 *
 * Returns: {
 *   success: true,
 *   refunded: boolean
 * }
 */
export const leaveGroupSession = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, sessionId, attendeeId, refundReason} = req.body;

    if (!businessId || !sessionId || !attendeeId) {
      res.status(400).json({
        success: false,
        error: "businessId, sessionId, and attendeeId are required",
      });
      return;
    }

    // Get attendee
    const attendeeDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .collection("attendees")
      .doc(attendeeId)
      .get();

    if (!attendeeDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Attendee not found",
      });
      return;
    }

    const attendee = attendeeDoc.data();

    // Get session
    const sessionDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .get();

    if (!sessionDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Session not found",
      });
      return;
    }

    const session = sessionDoc.data();

    // Remove attendee from session
    const sessionAttendees: Attendee[] = Array.isArray(session?.attendees) ?
      session.attendees as Attendee[] :
      [];
    const updatedAttendees = sessionAttendees.filter((a) => a.id !== attendeeId);

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .doc(sessionId)
      .update({
        attendees: updatedAttendees,
        currentCapacity: updatedAttendees.length,
        updatedAt: FieldValue.serverTimestamp(),
      });

    // Mark attendee as cancelled
    await attendeeDoc.ref.update({
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp(),
      cancellationReason: refundReason || "Client requested",
    });

    // Process refund if payment was made
    let refunded = false;
    let refundError: string | null = null;

    if (attendee?.paymentIntentId && stripe) {
      try {
        logger.info("Processing refund for group session cancellation", {
          businessId,
          sessionId,
          attendeeId,
        });

        // Create Stripe refund
        const refund = await stripe.refunds.create({
          payment_intent: attendee.paymentIntentId,
          reason: "requested_by_customer",
          metadata: {
            businessId,
            sessionId,
            attendeeId,
            source: "group_session_cancellation",
            refundReason: refundReason || "Client cancelled",
          },
        });

        refunded = refund.status === "succeeded" || refund.status === "pending";

        // Update attendee record with refund info
        await attendeeDoc.ref.update({
          refundId: refund.id,
          refundStatus: refund.status,
          refundAmountCents: refund.amount,
          refundedAt: FieldValue.serverTimestamp(),
        });

        // Create payment record for the refund
        await db
          .collection("businesses")
          .doc(businessId)
          .collection("payments")
          .add({
            type: "refund",
            sourcePaymentIntentId: attendee.paymentIntentId,
            stripeRefundId: refund.id,
            amountCents: refund.amount,
            currency: refund.currency,
            status: refund.status,
            reason: refundReason || "Group session cancellation",
            metadata: {sessionId, attendeeId},
            createdAt: FieldValue.serverTimestamp(),
          });

        logger.info("Refund processed successfully", {
          refundId: refund.id,
          status: refund.status,
          amount: refund.amount,
        });
      } catch (stripeError: unknown) {
        const message = getErrorMessage(stripeError);
        logger.error("Stripe refund failed", {
          error: message,
          businessId,
          sessionId,
          attendeeId,
        });
        refundError = message;
        // Don't fail the whole request - attendee is already removed
      }
    } else if (attendee?.paymentIntentId && !stripe) {
      logger.warn("Stripe not configured - refund skipped", {
        businessId,
        sessionId,
        attendeeId,
      });
      refundError = "Payment processor not configured";
    }

    res.json({
      success: true,
      refunded,
      refundError,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logGroupSessionError("Error leaving group session", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Get available group sessions (public sessions with capacity)
 *
 * POST /getAvailableGroupSessions
 * Body: {
 *   businessId: string,
 *   startDate?: string (ISO 8601),
 *   endDate?: string (ISO 8601),
 *   serviceId?: string
 * }
 *
 * Returns: {
 *   success: true,
 *   sessions: [...]
 * }
 */
export const getAvailableGroupSessions = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, startDate, endDate, serviceId} = req.body;

    if (!businessId) {
      res.status(400).json({
        success: false,
        error: "businessId is required",
      });
      return;
    }

    // Build query
    let query = db
      .collection("businesses")
      .doc(businessId)
      .collection("group_sessions")
      .where("isPublic", "==", true)
      .where("status", "==", "scheduled");

    // Add date filters if provided
    if (startDate) {
      query = query.where(
        "startTime",
        ">=",
        Timestamp.fromDate(new Date(startDate))
      );
    }

    if (endDate) {
      query = query.where("startTime", "<=", Timestamp.fromDate(new Date(endDate)));
    }

    // Execute query
    const sessionsSnapshot = await query.orderBy("startTime", "asc").get();

    // Filter by serviceId and capacity
    const sessions = sessionsSnapshot.docs
      .map((doc) => {
        const session = doc.data();
        return {
          id: doc.id,
          title: session.title,
          description: session.description,
          serviceId: session.serviceId,
          providerId: session.providerId,
          locationId: session.locationId,
          startTime: session.startTime,
          endTime: session.endTime,
          maxCapacity: session.maxCapacity,
          currentCapacity: session.currentCapacity || 0,
          availableSpots: session.maxCapacity - (session.currentCapacity || 0),
          priceCents: session.priceCents,
        };
      })
      .filter((session) => {
        // Filter by service if specified
        if (serviceId && session.serviceId !== serviceId) {
          return false;
        }
        // Only show sessions with available spots
        return session.availableSpots > 0;
      });

    const response: AvailableSessionsResponse = {
      success: true,
      sessions,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logGroupSessionError("Error getting available group sessions", error);
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});
