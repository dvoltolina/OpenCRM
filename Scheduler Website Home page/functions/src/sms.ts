import {Request, Response} from "express";
import {HttpsError} from "firebase-functions/v2/https";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import twilio from "twilio";
import {db, auth, FieldValue} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";

type DecodedToken = {
  uid: string;
  businessId?: string;
  role?: string;
};

const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID ?? "";
const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN ?? "";
const twilioMessagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID ?? "";
const twilioFromNumber = process.env.TWILIO_FROM_NUMBER ?? "";
const appBaseUrl = process.env.APP_BASE_URL ?? process.env.FUNCTIONS_BASE_URL ?? "";

const twilioClient = twilioAccountSid && twilioAuthToken ?
  twilio(twilioAccountSid, twilioAuthToken) :
  null;

function requireTwilio(): void {
  if (!twilioClient || (!twilioMessagingServiceSid && !twilioFromNumber)) {
    throw new HttpsError("failed-precondition", "SMS provider not configured");
  }
}

function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, "");
}

async function verifyRequest(req: Request): Promise<DecodedToken> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new HttpsError("unauthenticated", "Missing Authorization header");
  }
  const token = authHeader.replace("Bearer ", "").trim();
  const decoded = await auth.verifyIdToken(token);
  return {
    uid: decoded.uid,
    businessId: (decoded as any).businessId,
    role: (decoded as any).role,
  };
}

function assertTenantAccess(businessId: string | undefined, expected: string): void {
  if (!businessId || businessId !== expected) {
    throw new HttpsError("permission-denied", "Tenant mismatch");
  }
}

function assertRoleAllowed(role: string | undefined): void {
  const allowed = new Set(["owner", "admin", "manager", "staff"]);
  if (!role || !allowed.has(role)) {
    throw new HttpsError("permission-denied", "Insufficient role");
  }
}

async function checkOptOut(businessId: string, normalizedPhone: string): Promise<boolean> {
  const snap = await db
    .collection(`businesses/${businessId}/sms_opt_outs`)
    .where("phone", "==", normalizedPhone)
    .where("status", "==", "opted_out")
    .limit(1)
    .get();
  return !snap.empty;
}

async function auditSmsSend(
  businessId: string,
  userId: string,
  messageId: string,
  providerMessageId: string,
  recipientPhone: string
): Promise<void> {
  await db.collection("businesses").doc(businessId).collection("audit_logs").add({
    businessId,
    userId,
    actionType: "smsSend",
    entityType: "sms_message",
    entityId: messageId,
    timestamp: FieldValue.serverTimestamp(),
    metadata: {
      providerMessageId,
      recipientPhoneLast4: recipientPhone.slice(-4),
    },
  });
}

export const sendSms = onRequest(async (req: Request, res: Response) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).json({error: "Method not allowed"});
    return;
  }

  try {
    requireTwilio();
    const decoded = await verifyRequest(req);

    const {businessId, messageId, to, body} = req.body ?? {};
    if (!businessId || !messageId || !to || !body) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    assertTenantAccess(decoded.businessId, businessId);
    assertRoleAllowed(decoded.role);

    const normalizedPhone = normalizePhone(String(to));
    if (!normalizedPhone) {
      throw new HttpsError("invalid-argument", "Invalid phone number");
    }

    const optedOut = await checkOptOut(businessId, normalizedPhone);
    if (optedOut) {
      res.status(200).json({success: false, errorCode: "OPTED_OUT"});
      return;
    }

    const messageRef = db
      .collection(`businesses/${businessId}/sms_messages`)
      .doc(String(messageId));

    await messageRef.set(
      {
        businessId,
        recipientPhone: normalizedPhone,
        direction: "outbound",
        status: "queued",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    const statusCallback =
      appBaseUrl && appBaseUrl.length ?
        `${appBaseUrl}/smsWebhookStatus` :
        undefined;

    const params: twilio.MessageCreateOptions = {
      to,
      body,
      statusCallback,
    };

    if (twilioMessagingServiceSid) {
      params.messagingServiceSid = twilioMessagingServiceSid;
    } else if (twilioFromNumber) {
      params.from = twilioFromNumber;
    }

    const response = await twilioClient!.messages.create(params);

    await messageRef.update({
      providerMessageId: response.sid,
      status: "sent",
      sentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await auditSmsSend(
      businessId,
      decoded.uid,
      String(messageId),
      response.sid,
      normalizedPhone
    );

    res.status(200).json({success: true, sid: response.sid});
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Send failed";
    logger.error("sendSms error", {error: message});
    if (error instanceof HttpsError) {
      res.status(400).json({success: false, error: error.message, code: error.code});
    } else {
      res.status(500).json({success: false, error: "Failed to send SMS"});
    }
  }
});

function validateTwilioSignature(req: Request, urlOverride?: string): boolean {
  if (!twilioAuthToken) return false;
  const signature = req.headers["x-twilio-signature"] as string | undefined;
  if (!signature) return false;
  const requestUrl =
    urlOverride ??
    `${req.protocol}://${req.get("host")}${req.originalUrl}`;
  return twilio.validateRequest(twilioAuthToken, signature, requestUrl, req.body);
}

export const smsWebhookStatus = onRequest(async (req: Request, res: Response) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const isValid = validateTwilioSignature(req);
  if (!isValid) {
    res.status(403).send("Invalid signature");
    return;
  }

  const {MessageSid, MessageStatus, ErrorCode, ErrorMessage} = req.body ?? {};
  if (!MessageSid) {
    res.status(200).send("OK");
    return;
  }

  try {
    const snap = await db
      .collectionGroup("sms_messages")
      .where("providerMessageId", "==", MessageSid)
      .limit(1)
      .get();

    if (snap.empty) {
      res.status(200).send("OK");
      return;
    }

    const doc = snap.docs[0];
    const updateData: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
    };

    switch (MessageStatus) {
      case "delivered":
        updateData.status = "delivered";
        updateData.deliveredAt = FieldValue.serverTimestamp();
        break;
      case "failed":
      case "undelivered":
        updateData.status = "failed";
        updateData.failedAt = FieldValue.serverTimestamp();
        updateData.errorCode = ErrorCode;
        updateData.errorMessage = ErrorMessage;
        break;
      case "sent":
      case "queued":
      default:
        updateData.status = MessageStatus ?? doc.get("status");
        break;
    }

    await doc.ref.update(updateData);
    res.status(200).send("OK");
  } catch (error: unknown) {
    logger.error("smsWebhookStatus error", {error});
    res.status(500).send("Internal error");
  }
});

export const smsWebhookInbound = onRequest(async (req: Request, res: Response) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const isValid = validateTwilioSignature(req);
  if (!isValid) {
    res.status(403).send("Invalid signature");
    return;
  }

  const {From, To, Body, MessageSid} = req.body ?? {};
  const normalizedFrom = normalizePhone(String(From ?? ""));
  const normalizedBody = String(Body ?? "").toLowerCase().trim();

  try {
    const integrationSnap = await db
      .collectionGroup("integrations")
      .where("provider", "==", "twilio")
      .where("twilioNumber", "==", To)
      .limit(1)
      .get();

    if (integrationSnap.empty) {
      res.status(200).send("OK");
      return;
    }

    const businessId = integrationSnap.docs[0].ref.parent.parent?.id;
    if (!businessId) {
      res.status(200).send("OK");
      return;
    }

    const stopKeywords = ["stop", "stopall", "unsubscribe", "cancel", "end", "quit"];
    const startKeywords = ["start", "yes", "unstop"];

    if (stopKeywords.includes(normalizedBody)) {
      const optOutSnap = await db
        .collection(`businesses/${businessId}/sms_opt_outs`)
        .where("phone", "==", normalizedFrom)
        .limit(1)
        .get();

      if (optOutSnap.empty) {
        await db
          .collection(`businesses/${businessId}/sms_opt_outs`)
          .add({
            phone: normalizedFrom,
            status: "opted_out",
            optedOutAt: FieldValue.serverTimestamp(),
            source: "reply_stop",
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
      } else {
        await optOutSnap.docs[0].ref.update({
          status: "opted_out",
          optedOutAt: FieldValue.serverTimestamp(),
          source: "reply_stop",
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      res
        .type("text/xml")
        .send("<Response><Message>You have been unsubscribed. Reply START to resubscribe.</Message></Response>");
      return;
    }

    if (startKeywords.includes(normalizedBody)) {
      const optOutSnap = await db
        .collection(`businesses/${businessId}/sms_opt_outs`)
        .where("phone", "==", normalizedFrom)
        .limit(1)
        .get();

      if (!optOutSnap.empty) {
        await optOutSnap.docs[0].ref.update({
          status: "opted_in",
          optedInAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      res
        .type("text/xml")
        .send("<Response><Message>You have been resubscribed to messages.</Message></Response>");
      return;
    }

    await db.collection(`businesses/${businessId}/sms_messages`).add({
      businessId,
      recipientPhone: normalizedFrom,
      fromNumber: To,
      direction: "inbound",
      status: "delivered",
      providerMessageId: MessageSid,
      body: Body,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    res.type("text/xml").send("<Response></Response>");
  } catch (error: unknown) {
    logger.error("smsWebhookInbound error", {error});
    res.status(500).send("Internal error");
  }
});
