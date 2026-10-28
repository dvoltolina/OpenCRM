/**
 * Gift Card Functions for The Scheduler
 *
 * These functions handle gift card operations:
 * - Creating payment intents for gift card purchases
 * - Handling payment webhook events
 * - Sending gift card delivery emails
 * - Expiring gift cards on schedule
 *
 * Environment Variables Required:
 * - STRIPE_SECRET_KEY: Stripe secret key
 * - SENDGRID_API_KEY: SendGrid API key for email delivery
 */

import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import Stripe from "stripe";
import {db, FieldValue} from "./firebaseAdmin";
import sgMail from "@sendgrid/mail";
import Handlebars from "handlebars";
import * as fs from "fs";
import * as path from "path";
import {applyCors, sanitizeMetadataMap} from "./httpUtils";

const BUSINESS_ID_REGEX = /^[a-zA-Z0-9_-]{6,128}$/;
const GIFT_CARD_ID_REGEX = /^[a-zA-Z0-9_-]{6,128}$/;
const MIN_AMOUNT_CENTS = 100; // $1.00 minimum to reduce abuse
const MAX_AMOUNT_CENTS = 1000000; // $10,000 maximum to prevent abuse
const MAX_METADATA_ENTRIES = 20;
const RATE_LIMIT_WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_WINDOW = 30;
const rateLimitBuckets: Map<string, {count: number; windowStart: number}> = new Map();

// Initialize Stripe (reuse from index.ts in actual deployment)
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "";
const stripe = stripeSecretKey ?
  new Stripe(stripeSecretKey, {apiVersion: "2025-02-24.acacia"}) :
  null;

const sendgridApiKey = process.env.SENDGRID_API_KEY ?? "";
if (sendgridApiKey) {
  sgMail.setApiKey(sendgridApiKey);
}

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const logGiftCardError = (
  message: string,
  error: unknown,
  metadata: Record<string, unknown> = {}
) => {
  logger.error(message, {
    ...metadata,
    error: getErrorMessage(error),
  });
};

const logGiftCardWarn = (
  message: string,
  error: unknown,
  metadata: Record<string, unknown> = {}
) => {
  logger.warn(message, {
    ...metadata,
    error: getErrorMessage(error),
  });
};

// ============================================================================
// Email Template Loading
// ============================================================================

/**
 * Load and compile Handlebars templates.
 * Templates are loaded lazily and cached for performance.
 */
const templateCache: Map<string, Handlebars.TemplateDelegate> = new Map();

function getCompiledTemplate(templateName: string): Handlebars.TemplateDelegate {
  const cachedTemplate = templateCache.get(templateName);
  if (cachedTemplate) return cachedTemplate;

  const templatePath = path.join(__dirname, "templates", `${templateName}.html`);

  try {
    const templateSource = fs.readFileSync(templatePath, "utf-8");
    const compiledTemplate = Handlebars.compile(templateSource);
    templateCache.set(templateName, compiledTemplate);
    return compiledTemplate;
  } catch (error) {
    logGiftCardError(`Failed to load template: ${templateName}`, error, {templatePath});
    throw new Error(`Template not found: ${templateName}`);
  }
}

/**
 * Template data interface for purchase confirmation emails.
 */
interface PurchaseConfirmationData {
  purchaserName: string;
  code: string;
  amountDollars: string;
  purchaseDate: string;
  expiresAt?: string;
  isSendingToOther: boolean;
  recipientName?: string;
  recipientEmail?: string;
  businessName: string;
  businessLogoUrl?: string;
  businessAddress?: string;
  businessPhone?: string;
  businessEmail?: string;
  bookingUrl?: string;
}

/**
 * Template data interface for gift card delivery emails.
 */
interface DeliveryTemplateData {
  recipientName: string;
  senderName: string;
  code: string;
  amountDollars: string;
  personalMessage?: string;
  expiresAt?: string;
  businessName: string;
  businessLogoUrl?: string;
  businessAddress?: string;
  businessPhone?: string;
  businessEmail?: string;
  bookingUrl?: string;
}

// ============================================================================
// Gift Card Payment Functions
// ============================================================================

/**
 * Create a Payment Intent for gift card purchase.
 *
 * POST /createGiftCardPayment
 * Body: {
 *   amountCents: number,
 *   businessId: string,
 *   giftCardId: string,
 *   customerEmail?: string
 * }
 *
 * Returns: { clientSecret: string, paymentIntentId: string }
 */
export const createGiftCardPayment = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  const amountCentsRaw = req.body?.amountCents;
  const businessId =
    typeof req.body?.businessId === "string" ? req.body.businessId.trim() : "";
  const giftCardId =
    typeof req.body?.giftCardId === "string" ? req.body.giftCardId.trim() : "";
  const customerEmail =
    typeof req.body?.customerEmail === "string" ? req.body.customerEmail.trim() : "";
  const metadata = req.body?.metadata;

  try {
    const amountNumber = Number(amountCentsRaw);
    const amountCents = Math.floor(amountNumber);
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "createGiftCardPayment")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }
    if (!Number.isFinite(amountNumber) || amountCents <= 0) {
      res.status(400).json({
        error: "amountCents must be a positive number",
      });
      return;
    }

    if (amountCents < MIN_AMOUNT_CENTS || amountCents > MAX_AMOUNT_CENTS) {
      res.status(400).json({
        error: `amountCents must be between ${MIN_AMOUNT_CENTS} and ${MAX_AMOUNT_CENTS}`,
      });
      return;
    }

    if (!businessId || !giftCardId) {
      res.status(400).json({
        error: "Missing required fields: amountCents, businessId, giftCardId",
      });
      return;
    }

    if (!BUSINESS_ID_REGEX.test(businessId) || !GIFT_CARD_ID_REGEX.test(giftCardId)) {
      res.status(400).json({error: "Invalid businessId or giftCardId format"});
      return;
    }

    const businessRef = db.collection("businesses").doc(businessId);
    const businessSnapshot = await businessRef.get();
    if (!businessSnapshot.exists) {
      res.status(404).json({error: "Business not found"});
      return;
    }

    const giftCardRef = businessRef.collection("giftCards").doc(giftCardId);
    const giftCardDoc = await giftCardRef.get();
    if (!giftCardDoc.exists) {
      res.status(404).json({error: "Gift card not found"});
      return;
    }

    const giftCardData = giftCardDoc.data();
    if (giftCardData?.status && giftCardData.status !== "pending") {
      res.status(409).json({error: "Gift card must be pending for purchase"});
      return;
    }

    if (customerEmail && customerEmail.length > 254) {
      res.status(400).json({error: "customerEmail too long"});
      return;
    }

    const safeMetadata = sanitizeMetadataMap(metadata, 200);
    if (Object.keys(safeMetadata).length > MAX_METADATA_ENTRIES) {
      res.status(400).json({error: "Too many metadata fields"});
      return;
    }

    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: amountCents,
      currency: "usd",
      automatic_payment_methods: {enabled: true},
      metadata: {
        businessId,
        giftCardId,
        type: "gift_card_purchase",
        ...safeMetadata,
      },
    };

    if (customerEmail) {
      paymentIntentParams.receipt_email = customerEmail;
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

    logger.info("Gift card payment intent created", {
      paymentIntentId: paymentIntent.id,
      businessId,
      giftCardId,
      amountCents,
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error: unknown) {
    const errorMessage = getErrorMessage(error);
    logGiftCardError("Error creating gift card payment intent", error, {
      businessId,
      giftCardId,
    });
    res.status(500).json({error: errorMessage});
  }
});

/**
 * Handle successful gift card payment.
 * Call this from the main stripeWebhook handler when type is gift_card_purchase.
 */
export async function handleGiftCardPaymentSucceeded(
  paymentIntent: Stripe.PaymentIntent
): Promise<void> {
  const {businessId, giftCardId} = paymentIntent.metadata;

  if (!businessId || !giftCardId) {
    logger.warn("Gift card payment missing metadata", {
      paymentIntentId: paymentIntent.id,
    });
    return;
  }

  const giftCardRef = db
    .collection("businesses")
    .doc(businessId)
    .collection("giftCards")
    .doc(giftCardId);

  const giftCardDoc = await giftCardRef.get();
  if (!giftCardDoc.exists) {
    logger.error("Gift card not found for payment", {businessId, giftCardId});
    return;
  }

  const giftCardData = giftCardDoc.data();

  // Get template for expiration calculation
  let expiresAt: Date | null = null;
  if (giftCardData?.templateId) {
    const templateDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("giftCardTemplates")
      .doc(giftCardData.templateId)
      .get();

    if (templateDoc.exists) {
      const templateData = templateDoc.data();
      if (templateData?.validityDays) {
        expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + templateData.validityDays);
      }
    }
  }

  // Activate the gift card
  const updateData: Record<string, unknown> = {
    status: "active",
    activatedAt: FieldValue.serverTimestamp(),
    paymentId: paymentIntent.id,
  };

  if (expiresAt) {
    updateData.expiresAt = expiresAt.toISOString();
  }

  await giftCardRef.update(updateData);

  logger.info("Gift card activated", {
    businessId,
    giftCardId,
    paymentIntentId: paymentIntent.id,
  });

  // Trigger email delivery
  await sendGiftCardEmails(businessId, giftCardId);
}

// ============================================================================
// Gift Card Email Functions
// ============================================================================

/**
 * Send gift card emails to purchaser and recipient.
 */
export async function sendGiftCardEmails(
  businessId: string,
  giftCardId: string
): Promise<void> {
  const giftCardDoc = await db
    .collection("businesses")
    .doc(businessId)
    .collection("giftCards")
    .doc(giftCardId)
    .get();

  if (!giftCardDoc.exists) {
    logger.error("Gift card not found for email delivery", {businessId, giftCardId});
    return;
  }

  const giftCard = giftCardDoc.data();
  if (!giftCard) {
    logger.error("Gift card data missing for email delivery", {businessId, giftCardId});
    return;
  }
  const amountDollars = (giftCard.originalAmountCents / 100).toFixed(2);

  // Get business info for branding
  const businessDoc = await db.collection("businesses").doc(businessId).get();
  const businessData = businessDoc.data();
  const businessName = businessData?.name || "Our Business";
  const fromEmail = businessData?.contactEmail || "noreply@scheduler.example.com";

  // Send confirmation to purchaser
  await sendPurchaserConfirmation(giftCard, amountDollars, businessName, fromEmail, businessData);

  // Send to recipient if different from purchaser
  if (giftCard.recipientEmail && giftCard.recipientEmail !== giftCard.purchaserEmail) {
    await sendRecipientDelivery(giftCard, amountDollars, businessName, fromEmail, businessData);

    // Mark as delivered
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("giftCards")
      .doc(giftCardId)
      .update({
        delivered: true,
        deliveredAt: FieldValue.serverTimestamp(),
      });

    logger.info("Gift card delivered to recipient", {
      businessId,
      giftCardId,
    });
  }
}

async function sendPurchaserConfirmation(
  giftCard: FirebaseFirestore.DocumentData,
  amountDollars: string,
  businessName: string,
  fromEmail: string,
  businessData?: FirebaseFirestore.DocumentData
): Promise<void> {
  const subject = `Your $${amountDollars} Gift Card Purchase Confirmation`;

  const isSendingToOther = !!(
    giftCard.recipientEmail &&
    giftCard.recipientEmail !== giftCard.purchaserEmail
  );

  // Prepare template data
  const templateData: PurchaseConfirmationData = {
    purchaserName: giftCard.purchaserName || "Valued Customer",
    code: giftCard.code,
    amountDollars,
    purchaseDate: new Date().toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }),
    expiresAt: giftCard.expiresAt ?
      new Date(giftCard.expiresAt).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }) :
      undefined,
    isSendingToOther,
    recipientName: giftCard.recipientName,
    recipientEmail: giftCard.recipientEmail,
    businessName,
    businessLogoUrl: businessData?.logoUrl,
    businessAddress: businessData?.address,
    businessPhone: businessData?.phone,
    businessEmail: businessData?.contactEmail,
    bookingUrl: businessData?.bookingUrl,
  };

  // Render template
  let body: string;
  try {
    const template = getCompiledTemplate("gift_card_purchase_confirmation");
    body = template(templateData);
  } catch (error) {
    // Fallback to simple HTML if template fails
    logGiftCardWarn("Template rendering failed, using fallback", error);
    body = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Thank you for your gift card purchase!</h2>
        <p>Your <strong>$${amountDollars}</strong> gift card has been successfully purchased.</p>
        <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0; font-size: 14px; color: #666;">Gift Card Code</p>
          <p style="margin: 5px 0 0; font-size: 24px; font-weight: bold; letter-spacing: 2px;">${giftCard.code}</p>
        </div>
        ${isSendingToOther ?
    "<p>We will send this gift card to " +
    `<strong>${giftCard.recipientName || giftCard.recipientEmail}</strong> shortly.</p>` :
    "<p>You can use this code when booking your next appointment.</p>"
}
        <p style="margin-top: 30px; color: #666;">Thank you for choosing ${businessName}!</p>
      </div>
    `;
  }

  await sendEmail({
    toEmail: giftCard.purchaserEmail,
    toName: giftCard.purchaserName,
    subject,
    body,
    fromEmail,
    fromName: businessName,
  });
}

async function sendRecipientDelivery(
  giftCard: FirebaseFirestore.DocumentData,
  amountDollars: string,
  businessName: string,
  fromEmail: string,
  businessData?: FirebaseFirestore.DocumentData
): Promise<void> {
  const senderName = giftCard.purchaserName || "Someone special";
  const subject = `You've received a $${amountDollars} Gift Card from ${senderName}!`;

  // Prepare template data
  const templateData: DeliveryTemplateData = {
    recipientName: giftCard.recipientName || "Friend",
    senderName,
    code: giftCard.code,
    amountDollars,
    personalMessage: giftCard.personalMessage,
    expiresAt: giftCard.expiresAt ?
      new Date(giftCard.expiresAt).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }) :
      undefined,
    businessName,
    businessLogoUrl: businessData?.logoUrl,
    businessAddress: businessData?.address,
    businessPhone: businessData?.phone,
    businessEmail: businessData?.contactEmail,
    bookingUrl: businessData?.bookingUrl,
  };

  // Render template
  let body: string;
  try {
    const template = getCompiledTemplate("gift_card_delivery");
    body = template(templateData);
  } catch (error) {
    // Fallback to simple HTML if template fails
    logGiftCardWarn("Template rendering failed, using fallback", error);

    // HIPAA Compliance: Personal messages should not contain PHI
    // Add disclaimer below personal message
    const messageText = giftCard.personalMessage ?
      `<div style="margin: 20px 0;">
          <p style="font-size: 12px; color: #888; margin-bottom: 5px;">
            Personal message from sender:
          </p>
          <blockquote style="border-left: 3px solid #ddd; padding-left: 15px; ` +
          `font-style: italic; color: #555;">"${giftCard.personalMessage}"</blockquote>
          <p style="font-size: 11px; color: #999; font-style: italic; ` +
          "text-align: center;\">(Please note: Gift messages should not " +
          `contain personal health information)</p>
        </div>` :
      "";

    const expiresText = giftCard.expiresAt ?
      `<p style="font-size: 12px; color: #999;">Valid until: ${new Date(giftCard.expiresAt).toLocaleDateString()}</p>` :
      "";

    body = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">You've received a gift card!</h2>
        <p><strong>${senderName}</strong> has sent you a
          <strong>$${amountDollars}</strong> gift card to ${businessName}.</p>
        ${messageText}
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          padding: 30px; border-radius: 12px; margin: 20px 0;
          text-align: center; color: white;">
          <p style="margin: 0; font-size: 14px; opacity: 0.9;">Your Gift Card Code</p>
          <p style="margin: 10px 0 0; font-size: 28px; font-weight: bold; letter-spacing: 3px;">${giftCard.code}</p>
          <p style="margin: 15px 0 0; font-size: 18px;">$${amountDollars}</p>
        </div>
        <p>Use this code when booking your appointment to apply the balance.</p>
        ${expiresText}
        <p style="margin-top: 30px; color: #666;">We look forward to seeing you at ${businessName}!</p>
      </div>
    `;
  }

  await sendEmail({
    toEmail: giftCard.recipientEmail,
    toName: giftCard.recipientName,
    subject,
    body,
    fromEmail,
    fromName: businessName,
  });
}

interface SendEmailParams {
  toEmail: string;
  toName?: string;
  subject: string;
  body: string;
  fromEmail: string;
  fromName: string;
}

async function sendEmail(params: SendEmailParams): Promise<void> {
  if (!sendgridApiKey) {
    logger.warn("SendGrid not configured, skipping email", {
      hasRecipient: Boolean(params.toEmail),
      subject: params.subject,
    });
    return;
  }

  try {
    await sgMail.send({
      to: {email: params.toEmail, name: params.toName || params.toEmail},
      from: {email: params.fromEmail, name: params.fromName},
      subject: params.subject,
      html: params.body,
    });

    logger.info("Gift card email sent", {subject: params.subject});
  } catch (error) {
    logGiftCardError("Failed to send gift card email", error, {
      subject: params.subject,
      hasRecipient: Boolean(params.toEmail),
    });
    // Don't throw - email failure shouldn't block gift card activation
  }
}

// ============================================================================
// Gift Card Scheduled Functions
// ============================================================================

/**
 * Scheduled function to expire gift cards past their expiration date.
 *
 * Runs daily at 00:05 UTC. Finds active gift cards with expiresAt in the past
 * and updates their status to expired.
 *
 * Schedule: "5 0 * * *" = 00:05 UTC daily
 */
export const expireGiftCards = onSchedule(
  {
    schedule: "5 0 * * *",
    timeZone: "UTC",
    retryCount: 2,
    maxRetrySeconds: 300,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    logger.info("Starting gift card expiration job");

    const now = new Date();
    let totalExpired = 0;

    // Get all businesses
    const businesses = await db.collection("businesses").get();

    for (const businessDoc of businesses.docs) {
      const businessId = businessDoc.id;

      // Find active gift cards with expired dates
      const expiredCardsSnapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("giftCards")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now.toISOString())
        .get();

      if (expiredCardsSnapshot.empty) continue;

      // Update each expired card in batches
      const BATCH_SIZE = 400;
      let processedCount = 0;

      for (let i = 0; i < expiredCardsSnapshot.docs.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchDocs = expiredCardsSnapshot.docs.slice(i, i + BATCH_SIZE);

        for (const doc of batchDocs) {
          batch.update(doc.ref, {
            status: "expired",
            expiredAt: FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        processedCount += batchDocs.length;
      }

      totalExpired += processedCount;
      logger.info(`Expired ${processedCount} gift cards for business ${businessId}`);
    }

    logger.info(`Gift card expiration job complete. Total expired: ${totalExpired}`);
  }
);

// ============================================================================
// Gift Card Callable Functions
// ============================================================================

/**
 * Callable function to resend gift card email.
 *
 * onCall: resendGiftCardEmail
 * Data: { businessId: string, giftCardId: string }
 *
 * Returns: { success: boolean }
 */
export const resendGiftCardEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const {businessId, giftCardId} = request.data;

  if (!businessId || !giftCardId) {
    throw new HttpsError("invalid-argument", "businessId and giftCardId required");
  }

  // Verify user has access to this business
  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  const userData = userDoc.data();

  if (!userData || userData.businessId !== businessId) {
    throw new HttpsError("permission-denied", "Access denied to this business");
  }

  // Verify gift card exists and is active
  const giftCardDoc = await db
    .collection("businesses")
    .doc(businessId)
    .collection("giftCards")
    .doc(giftCardId)
    .get();

  if (!giftCardDoc.exists) {
    throw new HttpsError("not-found", "Gift card not found");
  }

  const giftCard = giftCardDoc.data();
  if (!giftCard) {
    throw new HttpsError("internal", "Gift card data missing");
  }

  if (giftCard.status !== "active") {
    throw new HttpsError("failed-precondition", "Gift card must be active to resend email");
  }

  await sendGiftCardEmails(businessId, giftCardId);

  logger.info("Gift card email resent", {businessId, giftCardId, userId: request.auth.uid});

  return {success: true};
});

/**
 * Get gift card balance by code (public endpoint for balance checks).
 *
 * POST /checkGiftCardBalance
 * Body: { businessId: string, code: string }
 *
 * Returns: { valid: boolean, balanceCents: number, expiresAt?: string }
 */
export const checkGiftCardBalance = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const businessId =
    typeof req.body?.businessId === "string" ? req.body.businessId.trim() : "";
  const code =
    typeof req.body?.code === "string" ? req.body.code.trim() : "";

  if (!businessId || !code) {
    res.status(400).json({error: "businessId and code required"});
    return;
  }

  if (code.length > 128) {
    res.status(400).json({error: "code too long"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "checkGiftCardBalance")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }
    const snapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("giftCards")
      .where("code", "==", code.toUpperCase())
      .limit(1)
      .get();

    if (snapshot.empty) {
      res.json({valid: false, balanceCents: 0});
      return;
    }

    const giftCard = snapshot.docs[0].data();
    const now = new Date();

    const isExpired = giftCard.expiresAt && new Date(giftCard.expiresAt) < now;
    const isValid = giftCard.status === "active" && !isExpired;

    res.json({
      valid: isValid,
      balanceCents: isValid ? giftCard.remainingBalanceCents : 0,
      expiresAt: giftCard.expiresAt || null,
    });
  } catch (error: unknown) {
    const errorMessage = getErrorMessage(error);
    logGiftCardError("Error checking gift card balance", error, {businessId});
    res.status(500).json({error: errorMessage});
  }
});

function getClientIp(req: import("express").Request): string {
  const forwarded = (req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0]?.trim();
  return forwarded || req.ip || "unknown";
}

function isRateLimited(key: string, scope: string): boolean {
  const bucketKey = `${scope}:${key}`;
  const now = Date.now();
  const bucket = rateLimitBuckets.get(bucketKey);

  if (!bucket || now - bucket.windowStart > RATE_LIMIT_WINDOW_MS) {
    rateLimitBuckets.set(bucketKey, {count: 1, windowStart: now});
    return false;
  }

  if (bucket.count >= MAX_REQUESTS_PER_WINDOW) {
    return true;
  }

  bucket.count += 1;
  return false;
}
