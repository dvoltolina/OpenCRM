/**
 * Cloud Functions for The Scheduler - Stripe Integration
 *
 * These functions handle server-side Stripe operations that require
 * the secret API key, including:
 * - Creating payment intents for appointment payments
 * - Managing subscriptions (create, update, cancel)
 * - Handling Stripe webhooks
 * - Creating customer portal sessions
 *
 * Environment Variables Required:
 * - STRIPE_SECRET_KEY: Your Stripe secret key (test or live)
 * - STRIPE_WEBHOOK_SECRET: Webhook signing secret for verification
 */

import {setGlobalOptions} from "firebase-functions";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import Stripe from "stripe";
import type {DecodedIdToken} from "firebase-admin/auth";
// Import from centralized Firebase Admin module (initializes Firebase first)
import {db, storage, auth, app, FieldValue, Timestamp} from "./firebaseAdmin";
import sgMail from "@sendgrid/mail";
import twilio from "twilio";
import {SESv2Client, SendEmailCommand} from "@aws-sdk/client-sesv2";
import {SNSClient, PublishCommand} from "@aws-sdk/client-sns";
import type {PublishCommandInput} from "@aws-sdk/client-sns";
import * as zlib from "zlib";
import {applyCors, sanitizeMetadataMap} from "./httpUtils";
import {leadsConvert} from "./crm/leadsConvert";
import {crmMetrics} from "./crm/metrics";
import {dealsStageChange} from "./crm/stageChange";
import {crmExport} from "./crm/export";
import {crmImport} from "./crm/import";
import {
  publicCreateAppointment,
  resolveBusinessSlug,
  publicListCatalog,
  publicGetAvailableAppointments,
} from "./publicBooking";
import {INTERNAL_BUSINESS_ROLES, normalizeUserRole} from "./roleUtils";

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const requireCallableBusiness = (request: CallableRequest): {
  businessId: string;
  uid: string;
  role?: string;
} => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  const businessId =
    (typeof request.data?.businessId === "string" && request.data.businessId.trim()) ||
    (typeof request.auth.token.businessId === "string" ? request.auth.token.businessId : undefined);

  if (!businessId) {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  const role = normalizeUserRole(request.auth.token.role);

  return {businessId, uid: request.auth.uid, role};
};

// Import gift card functions for re-export and webhook handling
import {
  handleGiftCardPaymentSucceeded,
} from "./giftCards";

// Re-export gift card functions
export {
  createGiftCardPayment,
  expireGiftCards,
  resendGiftCardEmail,
  checkGiftCardBalance,
} from "./giftCards";

// Re-export accounting integration functions
export {
  // OAuth
  exchangeAccountingOAuthCode,
  refreshAccountingOAuthToken,
  revokeAccountingOAuthToken,
  // QuickBooks
  createQuickBooksCustomer,
  createQuickBooksInvoice,
  createQuickBooksPayment,
  createQuickBooksSalesReceipt,
  getQuickBooksAccounts,
  getQuickBooksTaxCodes,
  syncToQuickBooks,
  // Xero
  createXeroContact,
  createXeroInvoice,
  createXeroPayment,
  getXeroAccounts,
  getXeroTaxRates,
  syncToXero,
  // Generic sync dispatchers
  syncClientToAccounting,
  syncPaymentToAccounting,
} from "./accounting";

// Re-export encryption/KMS functions (HIPAA-compliant key management)
export {
  initializeEncryptionKey,
  getEncryptionKey,
  rotateEncryptionKey,
  getEncryptionKeyByVersion,
  encryptData,
  decryptData,
} from "./encryption/kms";

// Re-export calendar integration functions (Priority 4)
export {
  connectCalendar,
  connectGoogleCalendar,
  handleGoogleOAuthCallback,
  refreshCalendarTokens,
  syncCalendar,
  disconnectGoogleCalendar,
  connectOutlookCalendar,
  handleOutlookOAuthCallback,
  disconnectCalendar,
  googleCalendarWebhook,
  outlookCalendarWebhook,
  syncCalendars,
  refreshCalendarTokensJob,
  disconnectOutlookCalendar,
  syncCalendarEvents,
  handleCalendarWebhook,
} from "./calendar";

// Re-export telehealth integration functions (Priority 4)
export {
  connectZoom,
  handleZoomOAuthCallback,
  disconnectZoom,
  createZoomMeeting,
} from "./telehealth";

// Re-export marketing campaign functions (Priority 5)
export {
  previewCampaign,
  launchCampaign,
  testCampaign,
} from "./marketing";
import {previewCampaign, launchCampaign, testCampaign} from "./marketing";
// Email integration endpoints
export {
  connectEmailAccount,
  refreshEmailTokens,
  syncEmailInbox,
  syncEmailSent,
  sendIntegratedEmail,
  disconnectEmailAccount,
  gmailOAuthCallback,
  outlookOAuthCallback,
  emailWebhook,
  trackEmailOpen,
  trackEmailClick,
} from "./email";
// Webhook + integration/import/export endpoints
export {
  leadIntakeWebhook,
  dispatchWebhook,
  integrationSync,
  importData,
  resumeImport,
  exportData,
} from "./webhookHandlers";

// Re-export reporting functions (Priority 5)
export {
  exportReportCsv,
  exportReportPdf,
  getReportMetrics,
} from "./reports";
export {reportingAggregations} from "./reportingAggregations";
// Google Routes API optimization (CRM route planning)
export {optimizeRouteGoogle} from "./googleRoutes";
// Namespace re-exports for dot-notation targets
export const leads = {convert: leadsConvert};
export const deals = {stageChange: dealsStageChange};
// Re-export CRM Cloud Functions
export {leadsConvert} from "./crm/leadsConvert";
export {crmMetrics} from "./crm/metrics";
export {dealsStageChange} from "./crm/stageChange";
import {exportReportCsv, exportReportPdf, getReportMetrics} from "./reports";

// Re-export client portal functions (Priority 5)
export {
  generateMagicLink,
  validateMagicLink,
  getClientPortalData,
} from "./clientPortal";
export {
  publicCreateAppointment,
  resolveBusinessSlug,
  publicListCatalog,
  publicGetAvailableAppointments,
} from "./publicBooking";

// Re-export group session functions (Priority 5)
export {
  joinGroupSession,
  leaveGroupSession,
  getAvailableGroupSessions,
} from "./groupSessions";
// Automation + Sequences processors
export {automationEvent} from "./automation";
export {
  processSequenceSteps,
  handleEmailWebhook as sequenceEmailWebhook,
  onAppointmentCreated as sequenceOnAppointmentCreated,
  onDealUpdated as sequenceOnDealUpdated,
  onLeadConverted as sequenceOnLeadConverted,
} from "./sequences";

// SMS messaging (Twilio) - feature-flagged via environment configuration
export {sendSms, smsWebhookStatus, smsWebhookInbound} from "./sms";
// Re-export staff onboarding functions (Join Codes & Invites)
export {
  createJoinCode,
  revokeJoinCode,
  requestJoinWithCode,
  createInvite,
  revokeInvite,
  acceptInvite,
  reviewJoinRequest,
} from "./staffOnboarding";

// Admin functions (MFA backup codes, ownership transfer, bulk invites)
export {
  mfaVerifyBackupCode,
  ownershipTransfer,
  staffSave,
  staffBulkInvite,
} from "./adminFunctions";
import {ownershipTransfer, staffBulkInvite, staffSave} from "./adminFunctions";

// Workspace/business management functions
import {
  createWorkspace as createWorkspaceCallable,
  initiateBusinessDeletion as initiateBusinessDeletionCallable,
  lookupBusinessBySlug as lookupBusinessBySlugCallable,
  requestDataExport as requestDataExportCallable,
} from "./workspaces";
export {createWorkspace} from "./workspaces";
export {initiateBusinessDeletion} from "./workspaces";
export {lookupBusinessBySlug} from "./workspaces";
export {requestDataExport} from "./workspaces";
export {validateInviteCode} from "./workspaces";

// Integration settings functions
export {
  updateTelehealthSettings,
  saveStaffIntegrationPreference,
} from "./integrationSettings";

// Route optimization functions
export {
  optimizeRoute,
  getProviderRoutes,
  updateRouteStatus,
  geocodeAddress,
} from "./routes";

// Set global options for cost control
setGlobalOptions({maxInstances: 10});

// Initialize Stripe
// In production, set this via Firebase CLI: firebase functions:config:set stripe.secret_key="sk_..."
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "";
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

if (!stripeSecretKey) {
  logger.warn("STRIPE_SECRET_KEY not set - Stripe functions will not work");
}

const stripe = stripeSecretKey ?
  new Stripe(stripeSecretKey, {
    apiVersion: "2025-02-24.acacia",
  }) :
  null;

const sendgridApiKey = process.env.SENDGRID_API_KEY ?? "";
if (sendgridApiKey) {
  sgMail.setApiKey(sendgridApiKey);
}

const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID ?? "";
const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN ?? "";
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER ?? "";
const twilioClient = twilioAccountSid && twilioAuthToken ?
  twilio(twilioAccountSid, twilioAuthToken) :
  null;

const sesRegion = process.env.AWS_SES_REGION ?? "";
const sesAccessKeyId = process.env.AWS_SES_ACCESS_KEY_ID ?? "";
const sesSecretAccessKey = process.env.AWS_SES_SECRET_ACCESS_KEY ?? "";
const sesClient = sesRegion && sesAccessKeyId && sesSecretAccessKey ?
  new SESv2Client({
    region: sesRegion,
    credentials: {
      accessKeyId: sesAccessKeyId,
      secretAccessKey: sesSecretAccessKey,
    },
  }) :
  null;

const snsRegion = process.env.AWS_SNS_REGION ?? "";
const snsAccessKeyId = process.env.AWS_SNS_ACCESS_KEY_ID ?? "";
const snsSecretAccessKey = process.env.AWS_SNS_SECRET_ACCESS_KEY ?? "";
const snsClient = snsRegion && snsAccessKeyId && snsSecretAccessKey ?
  new SNSClient({
    region: snsRegion,
    credentials: {
      accessKeyId: snsAccessKeyId,
      secretAccessKey: snsSecretAccessKey,
    },
  }) :
  null;

const RATE_LIMIT_WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_WINDOW = 30;
const MAX_METADATA_KEYS = 25;
const rateLimitBuckets: Map<string, {count: number; windowStart: number}> = new Map();

type AuditActionType =
  | "loginSuccess"
  | "loginFailure"
  | "phiRead"
  | "phiReadList"
  | "phiWrite"
  | "dataExport"
  | "securityEvent";

export interface AuditLogPayload {
  businessId: string;
  userId: string;
  actionType: AuditActionType;
  entityType: string;
  entityId: string;
  deviceInfo?: Record<string, unknown>;
  correlationId?: string;
  metadata?: Record<string, unknown>;
}

const auditLogCollection = (businessId: string) =>
  db.collection("businesses").doc(businessId).collection("audit_logs");

const sanitizeMetadata = (
  metadata?: Record<string, unknown>
): Record<string, unknown> => {
  const sanitized = sanitizeMetadataMap(metadata, 200);
  if (Object.keys(sanitized).length > MAX_METADATA_KEYS) {
    const limited = Object.entries(sanitized).slice(0, MAX_METADATA_KEYS);
    return Object.fromEntries(limited);
  }
  for (const [key, value] of Object.entries(sanitized)) {
    if (typeof value === "string" && value.includes("\n")) {
      delete sanitized[key];
    }
  }
  return sanitized;
};

const isValidEmail = (value: string): boolean =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());

const getClientIp = (req: import("express").Request): string => {
  const forwarded = (req.headers["x-forwarded-for"] as string | undefined)
    ?.split(",")[0]?.trim();
  return forwarded || req.ip || "unknown";
};

const isRateLimited = (key: string, scope: string): boolean => {
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
};

interface AuthContext {
  uid: string;
  businessId: string;
}

type SentMessage = {
  channel: string;
  recipient: string;
  success: boolean;
  messageId?: string | null;
};

type WaitlistSlotPrefs = {
  earliestDate?: unknown;
  latestDate?: unknown;
  preferredDaysOfWeek?: number[];
  timeOfDayPreferences?: string[];
  priorityScore?: number;
  createdAt?: unknown;
  clientName?: string;
  providerName?: string;
  serviceName?: string;
  bookingLink?: string;
  notificationPreference?: string;
  clientEmail?: string;
  clientId?: string;
  clientPhone?: string;
};

const requireAuthWithBusiness = async (
  req: import("express").Request,
  res: import("express").Response,
  providedBusinessId?: string
): Promise<AuthContext | null> => {
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
    logger.warn("Auth verification failed", {error});
    res.status(401).json({error: "Unauthorized"});
    return null;
  }

  const tokenBusinessId = typeof decoded.businessId === "string" ?
    decoded.businessId :
    undefined;

  const userId = decoded.uid as string;
  let businessId = typeof providedBusinessId === "string" ?
    providedBusinessId.trim() :
    undefined;

  if (!businessId && tokenBusinessId) {
    businessId = tokenBusinessId;
  }

  const userDoc = await db.collection("users").doc(userId).get();
  const userBiz = userDoc.exists ? userDoc.get("businessId") : undefined;

  if (!businessId && typeof userBiz === "string") {
    businessId = userBiz;
  }

  if (!businessId) {
    res.status(400).json({error: "businessId is required"});
    return null;
  }

  if (tokenBusinessId && businessId !== tokenBusinessId) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }

  if (typeof userBiz === "string" && userBiz && userBiz !== businessId) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }

  const businessDoc = await db.collection("businesses").doc(businessId).get();
  if (!businessDoc.exists) {
    res.status(404).json({error: "Business not found"});
    return null;
  }

  return {uid: userId, businessId};
};

/**
 * Best-effort audit log writer for compliance tracking.
 *
 * Metadata must never include PHI or free-text content. IP address is
 * intentionally derived from the request context instead of caller-provided
 * values to prevent spoofing.
 */
export const writeAuditLogEntry = async (
  payload: AuditLogPayload,
  requestIp?: string
): Promise<void> => {
  try {
    const docRef = auditLogCollection(payload.businessId).doc();
    const metadata = sanitizeMetadata(payload.metadata);
    const deviceInfo =
      payload.deviceInfo && typeof payload.deviceInfo === "object" ?
        payload.deviceInfo :
        undefined;

    const data: Record<string, unknown> = {
      id: docRef.id,
      businessId: payload.businessId,
      userId: payload.userId,
      actionType: payload.actionType,
      entityType: payload.entityType,
      entityId: payload.entityId,
      metadata,
      timestamp: FieldValue.serverTimestamp(),
    };

    if (deviceInfo) {
      data.deviceInfo = deviceInfo;
    }

    if (payload.correlationId) {
      data.correlationId = payload.correlationId;
    }

    if (requestIp) {
      data.ipAddress = requestIp;
    }

    Object.keys(data).forEach((key) => {
      if (data[key] === undefined) {
        delete data[key];
      }
    });

    await docRef.set(data, {merge: true});
  } catch (error) {
    logger.error("Failed to write audit log entry", error);
  }
};

/**
 * Callable function to log authentication attempts with IP + device context.
 *
 * Expects:
 * - status: 'success' | 'failure'
 * - userId: optional user identifier (falls back to auth.uid when available)
 * - failureReason: optional short code for failures (no PHI)
 * - businessId: optional tenant hint; server validates against user profile when possible
 * - deviceInfo: optional structured map (strings/numbers/bools only)
 */
export const logAuthenticationEvent = onCall(
  {enforceAppCheck: true},
  async (request): Promise<void> => {
    const rawStatus = typeof request.data?.status === "string" ?
      request.data.status.toLowerCase() :
      "";
    if (rawStatus !== "success" && rawStatus !== "failure") {
      throw new HttpsError(
        "invalid-argument",
        "status must be 'success' or 'failure'"
      );
    }

    const requestUserId = typeof request.data?.userId === "string" ?
      request.data.userId :
      undefined;
    const failureReason = typeof request.data?.failureReason === "string" ?
      request.data.failureReason :
      undefined;
    const providedBusinessId = typeof request.data?.businessId === "string" ?
      request.data.businessId :
      undefined;
    const authBusinessId = typeof request.auth?.token?.businessId === "string" ?
      request.auth?.token?.businessId :
      undefined;
    const userId = request.auth?.uid ?? requestUserId;

    let businessId = providedBusinessId ?? authBusinessId;
    if (!businessId && userId) {
      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists) {
        const docBiz = userDoc.get("businessId");
        if (typeof docBiz === "string" && docBiz) {
          businessId = docBiz;
        }
      }
    }

    if (!businessId) {
      logger.warn(
        "logAuthenticationEvent skipped - missing businessId",
        {userId, status: rawStatus}
      );
      return;
    }

    const baseDeviceInfo = request.data?.deviceInfo;
    let deviceInfo = sanitizeMetadata(
      baseDeviceInfo && typeof baseDeviceInfo === "object" ?
        baseDeviceInfo as Record<string, unknown> :
        {}
    );

    const userAgent = request.rawRequest.get("user-agent");
    if (typeof userAgent === "string" && userAgent) {
      deviceInfo = {...deviceInfo, userAgent};
    }

    const metadata: Record<string, unknown> = {status: rawStatus};
    if (rawStatus === "failure" && failureReason) {
      metadata.failureReason = failureReason;
    }

    await writeAuditLogEntry(
      {
        businessId,
        userId: userId ?? "unknown",
        actionType: rawStatus === "success" ? "loginSuccess" : "loginFailure",
        entityType: "Authentication",
        entityId: userId ?? "unknown",
        deviceInfo: Object.keys(deviceInfo).length ? deviceInfo : undefined,
        metadata,
      },
      request.rawRequest.ip
    );
  }
);

/**
 * Create a Payment Intent for appointment payment
 *
 * POST /createPaymentIntent
 * Body: {
 *   amount: number (in cents),
 *   currency: string (default: 'usd'),
 *   customerId?: string (optional existing Stripe customer),
 *   metadata?: object (appointment details)
 * }
 *
 * Returns: { clientSecret: string, paymentIntentId: string }
 */
export const createPaymentIntent = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "createPaymentIntent")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {
      amount,
      currency = "usd",
      customerId,
      metadata,
      businessId,
      applicationFeeAmount,
      stripeAccountId,
      destinationAccountId,
      appointmentId,
      clientId,
      staffId,
      serviceType,
    } = req.body ?? {};

    if (!amount || typeof amount !== "number" || amount < 50) {
      res.status(400).json({
        error: "Invalid amount. Must be at least 50 cents.",
      });
      return;
    }

    const resolvedBusinessId =
      typeof businessId === "string" ?
        businessId :
        (metadata != null && typeof metadata.businessId === "string" ?
          metadata.businessId :
          undefined);
    if (!resolvedBusinessId) {
      res.status(400).json({error: "businessId is required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      resolvedBusinessId
    );
    if (!authContext) return;

    const safeMetadataRaw = sanitizeMetadata(metadata);
    const safeMetadata: Record<string, string | number | null> = {};
    for (const [key, value] of Object.entries(safeMetadataRaw)) {
      if (typeof value === "string" || typeof value === "number") {
        safeMetadata[key] = value;
      } else if (typeof value === "boolean") {
        safeMetadata[key] = value ? "true" : "false";
      }
    }
    const normalizedCurrency =
      typeof currency === "string" ? currency.toLowerCase() : "usd";
    const normalizedApplicationFee =
      applicationFeeAmount && Number.isFinite(applicationFeeAmount) ?
        Math.max(0, Math.floor(Number(applicationFeeAmount))) :
        undefined;
    const destination =
      typeof destinationAccountId === "string" && destinationAccountId ?
        destinationAccountId :
        (typeof stripeAccountId === "string" ? stripeAccountId : undefined);

    const baseMetadata: Record<string, string> = {
      businessId: authContext.businessId ?? "",
    };
    if (typeof appointmentId === "string" && appointmentId) {
      baseMetadata.appointmentId = appointmentId;
    }
    if (typeof clientId === "string" && clientId) {
      baseMetadata.clientId = clientId;
    }
    if (typeof staffId === "string" && staffId) {
      baseMetadata.staffId = staffId;
    }
    if (typeof serviceType === "string" && serviceType) {
      baseMetadata.serviceType = serviceType;
    }

    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: Math.floor(amount),
      currency: normalizedCurrency,
      automatic_payment_methods: {enabled: true},
      metadata: {
        ...baseMetadata,
        ...safeMetadata,
      },
    };

    if (destination) {
      paymentIntentParams.transfer_data = {destination};
      if (normalizedApplicationFee !== undefined) {
        paymentIntentParams.application_fee_amount = normalizedApplicationFee;
      }
    } else if (normalizedApplicationFee !== undefined) {
      paymentIntentParams.application_fee_amount = normalizedApplicationFee;
    }

    if (customerId) {
      paymentIntentParams.customer = customerId;
    }

    const stripeOptions = destination ?
      {stripeAccount: destination} :
      undefined;

    const paymentIntent = await stripe.paymentIntents.create(
      paymentIntentParams,
      stripeOptions
    );

    logger.info(`Payment Intent created: ${paymentIntent.id}`, {
      businessId: authContext.businessId,
      paymentIntentId: paymentIntent.id,
      destinationAccountId: destination ?? "platform",
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error creating payment intent:", {error});
    res.status(500).json({error: message});
  }
});

/**
 * Create a Stripe Customer
 *
 * POST /createCustomer
 * Body: {
 *   email: string,
 *   name?: string,
 *   businessId: string,
 *   metadata?: object
 * }
 *
 * Returns: { customerId: string }
 */
export const createCustomer = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "createCustomer")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {email, name, businessId, metadata} = req.body ?? {};

    if (!email) {
      res.status(400).json({error: "Email required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    const sanitizedMetadata = sanitizeMetadata(metadata);

    const customer = await stripe.customers.create({
      email,
      name,
      metadata: {
        businessId: authContext.businessId,
        ...sanitizedMetadata,
      },
    });

    logger.info(`Customer created: ${customer.id}`);

    res.json({customerId: customer.id});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error creating customer:", {error});
    res.status(500).json({error: message});
  }
});

/**
 * Create a Subscription
 *
 * POST /createSubscription
 * Body: {
 *   customerId: string,
 *   priceId: string (Stripe price ID for the subscription),
 *   trialPeriodDays?: number (default: 14),
 *   metadata?: object
 * }
 *
 * Returns: { subscriptionId: string, status: string, clientSecret?: string }
 */
export const createSubscription = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "createSubscription")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {
      customerId,
      priceId,
      trialPeriodDays = 14,
      metadata,
      businessId,
    } = req.body ?? {};

    if (!customerId || !priceId) {
      res.status(400).json({error: "customerId and priceId required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    const normalizedTrialPeriod = Number.isFinite(trialPeriodDays) ?
      Math.max(0, Math.floor(Number(trialPeriodDays))) :
      14;
    const sanitizedMetadata = sanitizeMetadata(metadata);

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{price: priceId}],
      trial_period_days: normalizedTrialPeriod,
      payment_behavior: "default_incomplete",
      payment_settings: {save_default_payment_method: "on_subscription"},
      expand: ["latest_invoice.payment_intent"],
      metadata: {
        businessId: authContext.businessId,
        ...sanitizedMetadata,
      },
    });

    logger.info(`Subscription created: ${subscription.id}`);

    const invoice = subscription.latest_invoice as Stripe.Invoice;
    const paymentIntent = invoice?.payment_intent as Stripe.PaymentIntent;

    res.json({
      subscriptionId: subscription.id,
      status: subscription.status,
      clientSecret: paymentIntent?.client_secret,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error creating subscription:", {error});
    res.status(500).json({error: message});
  }
});

/**
 * Cancel a Subscription
 *
 * POST /cancelSubscription
 * Body: {
 *   subscriptionId: string,
 *   cancelAtPeriodEnd: boolean (default: true)
 * }
 *
 * Returns: { success: boolean, cancelAt?: timestamp }
 */
export const cancelSubscription = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "cancelSubscription")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {subscriptionId, cancelAtPeriodEnd = true, businessId} = req.body;

    if (!subscriptionId) {
      res.status(400).json({error: "subscriptionId required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    if (cancelAtPeriodEnd) {
      const subscription = await stripe.subscriptions.update(subscriptionId, {
        cancel_at_period_end: true,
      });

      logger.info(
        `Subscription ${subscriptionId} set to cancel at period end`
      );

      res.json({
        success: true,
        cancelAt: subscription.cancel_at,
      });
    } else {
      await stripe.subscriptions.cancel(subscriptionId);

      logger.info(`Subscription ${subscriptionId} canceled immediately`);

      res.json({success: true});
    }
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error canceling subscription:", {error});
    res.status(500).json({error: message});
  }
});

/**
 * Create Customer Portal Session
 *
 * POST /createPortalSession
 * Body: {
 *   customerId: string,
 *   returnUrl?: string (URL to return to after portal)
 * }
 *
 * Returns: { url: string }
 */
export const createPortalSession = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "createPortalSession")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {customerId, returnUrl, businessId} = req.body;

    if (!customerId) {
      res.status(400).json({error: "customerId required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl || "https://yourapp.com/billing",
    });

    logger.info(`Portal session created for customer ${customerId}`);

    res.json({url: session.url});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error creating portal session:", {error});
    res.status(500).json({error: message});
  }
});

const buildStubBillingUrl = (
  baseUrl: string,
  params: Record<string, string | number | undefined>
): string => {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    query.append(key, String(value));
  });
  const separator = baseUrl.includes("?") ? "&" : "?";
  const queryString = query.toString();
  return `${baseUrl}${queryString ? separator + queryString : ""}`;
};

export const billingCreateCheckoutSession = onCall(async (request) => {
  const {businessId, uid, role} = requireCallableBusiness(request);
  if (role && role !== "owner") {
    throw new HttpsError("permission-denied", "Owner role required");
  }

  const planIdRaw = typeof request.data?.plan === "string" ? request.data.plan : request.data?.planId;
  const planId = planIdRaw && typeof planIdRaw === "string" ? planIdRaw.trim() : "starter";

  const addOnValue = request.data?.addOns ?? request.data?.addons;
  const addOnIds = Array.isArray(addOnValue) ?
    addOnValue.filter((v) => typeof v === "string" && v.trim()).map((v) => v.trim()) :
    typeof addOnValue === "string" ?
      addOnValue.split(",").map((v) => v.trim()).filter(Boolean) :
      [];

  const parsedSeats = Number(request.data?.seats);
  const seats = Number.isFinite(parsedSeats) && parsedSeats > 0 ? Math.round(parsedSeats) : undefined;

  const base = process.env.BILLING_CHECKOUT_BASE_URL || "https://billing.example.com/checkout";
  const url = buildStubBillingUrl(base, {businessId, planId, seats, addOns: addOnIds.join(",")});

  logger.info("Created stub checkout session", {
    businessId,
    uid,
    planId,
    seats,
    addOnCount: addOnIds.length,
  });

  return {url};
});

export const billingCreatePortalSession = onCall(async (request) => {
  const {businessId, uid, role} = requireCallableBusiness(request);
  if (role && role !== "owner") {
    throw new HttpsError("permission-denied", "Owner role required");
  }
  const base = process.env.BILLING_PORTAL_BASE_URL || "https://billing.example.com/portal";
  const url = buildStubBillingUrl(base, {businessId});
  logger.info("Created stub portal session", {businessId, uid});
  return {url};
});

const normalizeBillingPath = (path: string): string => {
  if (!path) return "/";
  const trimmed = path.endsWith("/") && path !== "/" ? path.slice(0, -1) : path;
  return trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
};

export const billing = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const path = normalizeBillingPath(req.path);

  try {
    if (req.method !== "POST") {
      res.status(405).json({error: "method_not_allowed"});
      return;
    }

    if (path === "/create-checkout-session") {
      const authContext = await requireAuthWithBusiness(
        req,
        res,
        typeof req.body?.businessId === "string" ? req.body.businessId : undefined
      );
      if (!authContext) return;

      const planIdRaw =
        typeof req.body?.plan === "string" ? req.body.plan : req.body?.planId;
      const planId = planIdRaw && typeof planIdRaw === "string" ? planIdRaw.trim() : "starter";
      const addOnValue = req.body?.addOns ?? req.body?.addons;
      const addOnIds = Array.isArray(addOnValue) ?
        addOnValue.filter((v: unknown) => typeof v === "string" && v.trim()).map((v: string) => v.trim()) :
        typeof addOnValue === "string" ?
          addOnValue.split(",").map((v: string) => v.trim()).filter(Boolean) :
          [];
      const parsedSeats = Number(req.body?.seats);
      const seats = Number.isFinite(parsedSeats) && parsedSeats > 0 ? Math.round(parsedSeats) : undefined;
      const base = process.env.BILLING_CHECKOUT_BASE_URL || "https://billing.example.com/checkout";
      const url = buildStubBillingUrl(base, {
        businessId: authContext.businessId,
        planId,
        seats,
        addOns: addOnIds.join(","),
      });
      res.json({url});
      return;
    }

    if (path === "/create-portal-session") {
      await createPortalSession(req, res);
      return;
    }

    if (path === "/webhook") {
      await stripeWebhook(req, res);
      return;
    }

    res.status(404).json({error: "not_found"});
  } catch (error: unknown) {
    const status = Number.isInteger((error as {status?: number}).status) ?
      (error as {status: number}).status :
      Number((error as {code?: string}).code) || 500;
    logger.error("Billing endpoint failed", {path, error});
    res.status(status).json({error: "server_error"});
  }
});
(billing as unknown as Record<string, unknown>).createCheckoutSession = billingCreateCheckoutSession;
(billing as unknown as Record<string, unknown>).createPortalSession = billingCreatePortalSession;

/**
 * Process a refund for an existing Stripe payment intent.
 *
 * POST /refundPayment
 * Body: {
 *   paymentIntentId: string,
 *   businessId: string,
 *   amount?: number,        // cents, optional for full refund
 *   reason?: string,        // Stripe refund reason enum
 *   appointmentId?: string  // overrides metadata
 * }
 */
export const refundPayment = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!stripe) {
    res.status(500).json({error: "Stripe not configured"});
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "refundPayment")) {
      res.status(429).json({error: "Too many requests"});
      return;
    }

    const {
      paymentIntentId,
      businessId,
      amount,
      reason,
      appointmentId,
      stripeAccountId,
    } = req.body ?? {};

    if (!paymentIntentId || typeof paymentIntentId !== "string") {
      res.status(400).json({error: "paymentIntentId is required"});
      return;
    }

    if (!businessId || typeof businessId !== "string") {
      res.status(400).json({error: "businessId is required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      businessId
    );
    if (!authContext) return;

    let requestedAmount: number | undefined;
    if (amount !== undefined) {
      requestedAmount = Number(amount);
      if (!Number.isFinite(requestedAmount) || requestedAmount <= 0) {
        res.status(400).json({error: "amount must be a positive number"});
        return;
      }
      requestedAmount = Math.floor(requestedAmount);
    }

    const paymentsRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("payments");

    let sourceDocId = paymentIntentId;
    let sourcePaymentData =
      (await paymentsRef.doc(paymentIntentId).get()).data() ?? null;

    if (!sourcePaymentData) {
      const altSnapshot = await paymentsRef
        .where("stripePaymentIntentId", "==", paymentIntentId)
        .limit(1)
        .get();
      if (!altSnapshot.empty) {
        const altDoc = altSnapshot.docs[0];
        sourceDocId = altDoc.id;
        sourcePaymentData = altDoc.data();
      }
    }

    if (!sourcePaymentData) {
      res.status(404).json({error: "Source payment not found"});
      return;
    }

    if (
      sourcePaymentData.businessId &&
      sourcePaymentData.businessId !== businessId
    ) {
      res.status(403).json({error: "Payment belongs to another business"});
      return;
    }

    const originalAmountCents = Number(
      sourcePaymentData.amountCents ?? sourcePaymentData.amount ?? 0
    );
    if (!Number.isFinite(originalAmountCents) || originalAmountCents <= 0) {
      res.status(400).json({error: "Source payment missing amountCents"});
      return;
    }

    const alreadyRefunded = Number(sourcePaymentData.refundAmountCents ?? 0);
    const maxRefundable = Math.max(0, originalAmountCents - alreadyRefunded);
    if (maxRefundable <= 0) {
      res.status(400).json({error: "Payment already fully refunded"});
      return;
    }

    const refundAmountCents = requestedAmount ?? maxRefundable;
    if (refundAmountCents > maxRefundable) {
      res.status(400).json({
        error: `Requested refund exceeds remaining balance (${maxRefundable} cents)`,
      });
      return;
    }

    const normalizedReason =
      (reason as Stripe.RefundCreateParams.Reason | undefined) ??
      "requested_by_customer";
    const effectiveAppointmentId =
      appointmentId ?? sourcePaymentData.appointmentId;

    const refund = await stripe.refunds.create(
      {
        payment_intent: paymentIntentId,
        amount: refundAmountCents,
        reason: normalizedReason,
        metadata: {
          businessId,
          appointmentId: effectiveAppointmentId ?? "",
          sourcePaymentId: sourceDocId,
        },
      },
      stripeAccountId ? {stripeAccount: stripeAccountId} : undefined
    );

    const now = new Date();
    const refundDoc = {
      businessId,
      appointmentId: effectiveAppointmentId ?? null,
      clientId: sourcePaymentData.clientId ?? null,
      amountCents: refundAmountCents,
      currency:
        sourcePaymentData.currency?.toString().toLowerCase() ??
        refund.currency ??
        "usd",
      status: "completed",
      type: "refund",
      stripePaymentIntentId: paymentIntentId,
      stripeRefundId: refund.id,
      parentPaymentId: sourceDocId,
      reason: normalizedReason,
      createdAt: now,
      refundedAt: now,
      updatedAt: now,
    };

    await paymentsRef.doc(refund.id).set(refundDoc, {merge: true});

    const cumulativeRefund = alreadyRefunded + refundAmountCents;
    const paymentStatus =
      cumulativeRefund >= originalAmountCents ?
        "refunded" :
        "partially_refunded";

    await paymentsRef.doc(sourceDocId).set(
      {
        refundAmountCents: cumulativeRefund,
        status: paymentStatus,
        refundedAt: now,
        stripeRefundId: refund.id,
        updatedAt: now,
      },
      {merge: true}
    );

    if (effectiveAppointmentId) {
      await db
        .collection("businesses")
        .doc(businessId)
        .collection("appointments")
        .doc(effectiveAppointmentId)
        .set(
          {
            paymentStatus: paymentStatus,
            refundStatus: paymentStatus === "refunded" ? "full" : "partial",
            refundAmountCents: cumulativeRefund,
            refundProcessedAt: now,
            refundPaymentId: refund.id,
            updatedAt: now,
          },
          {merge: true}
        );
    }

    logger.info("Refund processed", {
      businessId,
      paymentIntentId,
      refundId: refund.id,
      refundAmountCents,
    });

    res.json({
      success: true,
      refundId: refund.id,
      refundAmountCents,
      status: paymentStatus,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Refund processing failed", {
      error: message,
      stack: error && typeof error === "object" ? (error as {stack?: string}).stack : undefined,
    });
    res.status(500).json({error: message || "Refund failed"});
  }
});

/**
 * Resolve a receipt URL for a shared payment record.
 *
 * POST /getPaymentReceiptUrl
 * Body: {
 *   businessId: string,
 *   paymentId: string
 * }
 *
 * Returns: {
 *   success: true,
 *   url: string | null,
 *   source: "paymentDoc" | "invoice" | "paymentIntent" | "none"
 * }
 */
export const getPaymentReceiptUrl = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const {businessId, paymentId} = req.body ?? {};

    if (!businessId || typeof businessId !== "string") {
      res.status(400).json({error: "businessId is required"});
      return;
    }

    if (!paymentId || typeof paymentId !== "string") {
      res.status(400).json({error: "paymentId is required"});
      return;
    }

    const authContext = await requireAuthWithBusiness(req, res, businessId);
    if (!authContext) return;

    const userDoc = await db.collection("users").doc(authContext.uid).get();
    const role = normalizeUserRole(userDoc.get("role"));
    if (role !== "owner" && role !== "admin") {
      res.status(403).json({error: "Billing receipt access requires owner or admin role"});
      return;
    }

    const paymentRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("payments")
      .doc(paymentId);
    const paymentSnap = await paymentRef.get();

    if (!paymentSnap.exists) {
      res.status(404).json({error: "Payment not found"});
      return;
    }

    const paymentData = paymentSnap.data() ?? {};
    const candidateFields = [
      paymentData.receiptUrl,
      paymentData.stripeReceiptUrl,
      paymentData.hostedInvoiceUrl,
      paymentData.invoicePdfUrl,
      paymentData.receipt_url,
    ];
    const existingUrl = candidateFields.find(
      (value): value is string => typeof value === "string" && value.trim().length > 0
    ) ?? null;

    if (existingUrl) {
      await writeAuditLogEntry(
        {
          businessId,
          userId: authContext.uid,
          actionType: "dataExport",
          entityType: "Payment",
          entityId: paymentId,
          metadata: {
            source: "getPaymentReceiptUrl",
            resultSource: "paymentDoc",
            foundReceiptUrl: true,
          },
        },
        getClientIp(req)
      );

      res.json({success: true, url: existingUrl, source: "paymentDoc"});
      return;
    }

    if (!stripe) {
      await writeAuditLogEntry(
        {
          businessId,
          userId: authContext.uid,
          actionType: "dataExport",
          entityType: "Payment",
          entityId: paymentId,
          metadata: {
            source: "getPaymentReceiptUrl",
            resultSource: "none",
            foundReceiptUrl: false,
            stripeConfigured: false,
          },
        },
        getClientIp(req)
      );

      res.json({success: true, url: null, source: "none"});
      return;
    }

    const stripeAccountId =
      typeof paymentData.stripeAccountId === "string" && paymentData.stripeAccountId.trim().length > 0 ?
        paymentData.stripeAccountId.trim() :
        undefined;
    const stripeRequestOptions = stripeAccountId ? {stripeAccount: stripeAccountId} : undefined;
    const updates: Record<string, unknown> = {};
    let resolvedUrl: string | null = null;
    let resultSource: "invoice" | "paymentIntent" | "none" = "none";

    const invoiceId = typeof paymentData.stripeInvoiceId === "string" ?
      paymentData.stripeInvoiceId :
      undefined;
    let paymentIntentId =
      typeof paymentData.stripePaymentIntentId === "string" ? paymentData.stripePaymentIntentId :
      typeof paymentData.paymentIntentId === "string" ? paymentData.paymentIntentId :
      undefined;

    if (invoiceId) {
      const invoice = await stripe.invoices.retrieve(invoiceId, stripeRequestOptions);
      const hostedInvoiceUrl = typeof invoice.hosted_invoice_url === "string" ?
        invoice.hosted_invoice_url :
        undefined;
      const invoicePdfUrl = typeof invoice.invoice_pdf === "string" ?
        invoice.invoice_pdf :
        undefined;

      if (hostedInvoiceUrl) {
        updates.hostedInvoiceUrl = hostedInvoiceUrl;
      }
      if (invoicePdfUrl) {
        updates.invoicePdfUrl = invoicePdfUrl;
      }
      if (!paymentIntentId && typeof invoice.payment_intent === "string") {
        paymentIntentId = invoice.payment_intent;
        updates.stripePaymentIntentId = paymentIntentId;
      }

      resolvedUrl = hostedInvoiceUrl ?? invoicePdfUrl ?? null;
      if (resolvedUrl) {
        updates.receiptUrl = resolvedUrl;
        resultSource = "invoice";
      }
    }

    if (!resolvedUrl && paymentIntentId) {
      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId,
        {expand: ["latest_charge"]},
        stripeRequestOptions
      );

      let latestCharge: Stripe.Charge | null = null;
      if (paymentIntent.latest_charge && typeof paymentIntent.latest_charge !== "string") {
        latestCharge = paymentIntent.latest_charge;
      } else if (typeof paymentIntent.latest_charge === "string") {
        latestCharge = await stripe.charges.retrieve(
          paymentIntent.latest_charge,
          stripeRequestOptions
        );
      }

      const chargeReceiptUrl =
        latestCharge && typeof latestCharge.receipt_url === "string" ?
          latestCharge.receipt_url :
          null;

      if (chargeReceiptUrl) {
        updates.receiptUrl = chargeReceiptUrl;
        updates.stripePaymentIntentId = paymentIntentId;
        resolvedUrl = chargeReceiptUrl;
        resultSource = "paymentIntent";
      }
    }

    if (Object.keys(updates).length > 0) {
      updates.updatedAt = new Date();
      await paymentRef.set(updates, {merge: true});
    }

    await writeAuditLogEntry(
      {
        businessId,
        userId: authContext.uid,
        actionType: "dataExport",
        entityType: "Payment",
        entityId: paymentId,
        metadata: {
          source: "getPaymentReceiptUrl",
          resultSource,
          foundReceiptUrl: Boolean(resolvedUrl),
          usedInvoiceLookup: Boolean(invoiceId),
          usedPaymentIntentLookup: Boolean(paymentIntentId),
        },
      },
      getClientIp(req)
    );

    res.json({success: true, url: resolvedUrl, source: resultSource});
  } catch (error: unknown) {
    logger.error("Failed to resolve payment receipt URL", {error: getErrorMessage(error)});
    res.status(500).json({error: getErrorMessage(error)});
  }
});

/**
 * Stripe Webhook Handler
 *
 * POST /stripeWebhook
 *
 * Handles Stripe webhook events:
 * - payment_intent.succeeded
 * - payment_intent.payment_failed
 * - customer.subscription.created
 * - customer.subscription.updated
 * - customer.subscription.deleted
 * - invoice.paid
 * - invoice.payment_failed
 */
export const stripeWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!stripe || !webhookSecret) {
    res.status(500).json({error: "Stripe webhook not configured"});
    return;
  }

  const sig = req.headers["stripe-signature"];

  if (!sig) {
    res.status(400).send("Missing stripe-signature header");
    return;
  }

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig as string,
      webhookSecret
    );
  } catch (err: unknown) {
    const message = getErrorMessage(err);
    logger.error(`Webhook signature verification failed: ${message}`);
    res.status(400).send(`Webhook Error: ${message}`);
    return;
  }

  logger.info(`Received webhook event: ${event.type}`);

  try {
    const eventRef = db.collection("stripe_webhook_events").doc(event.id);
    const existingEvent = await eventRef.get();
    if (existingEvent.exists) {
      logger.info("Duplicate Stripe webhook event ignored", {
        eventId: event.id,
        type: event.type,
      });
      res.json({received: true, duplicate: true});
      return;
    }

    await eventRef.set({
      type: event.type,
      status: "processing",
      receivedAt: new Date(),
      createdAt: event.created ? new Date(event.created * 1000) : FieldValue.serverTimestamp(),
    });

    switch (event.type) {
    case "payment_intent.succeeded": {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentIntentSucceeded(paymentIntent);
      break;
    }

    case "payment_intent.payment_failed": {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentIntentFailed(paymentIntent);
      break;
    }

    case "customer.subscription.created":
    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription;
      await handleSubscriptionUpdate(subscription);
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      await handleSubscriptionDeleted(subscription);
      break;
    }

    case "invoice.paid": {
      const invoice = event.data.object as Stripe.Invoice;
      await handleInvoicePaid(invoice);
      break;
    }

    case "invoice.payment_failed": {
      const invoice = event.data.object as Stripe.Invoice;
      await handleInvoicePaymentFailed(invoice);
      break;
    }

    default:
      logger.info(`Unhandled event type: ${event.type}`);
    }

    await eventRef.set(
      {
        status: "processed",
        processedAt: new Date(),
      },
      {merge: true}
    );

    res.json({received: true});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    try {
      await db
        .collection("stripe_webhook_events")
        .doc(event.id)
        .set(
          {
            status: "error",
            errorMessage: message || "unknown",
            processedAt: new Date(),
          },
          {merge: true}
        );
    } catch (logError: unknown) {
      logger.error("Failed to record webhook error status", {error: logError});
    }
    logger.error(`Error handling webhook: ${message}`);
    res.status(500).json({error: message});
  }
});

// Webhook helper functions

async function handlePaymentIntentSucceeded(
  paymentIntent: Stripe.PaymentIntent
) {
  logger.info(`Payment succeeded: ${paymentIntent.id}`);

  // Check if this is a gift card purchase
  if (paymentIntent.metadata.type === "gift_card_purchase") {
    await handleGiftCardPaymentSucceeded(paymentIntent);
    return;
  }

  // Handle appointment payment
  const appointmentId = paymentIntent.metadata.appointmentId;
  if (appointmentId) {
    const businessId = paymentIntent.metadata.businessId;
    if (!businessId) {
      logger.error("Missing businessId in payment metadata");
      return;
    }

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(appointmentId)
      .update({
        paymentStatus: "completed",
        stripePaymentIntentId: paymentIntent.id,
        updatedAt: new Date(),
      });

    logger.info(
      `Updated appointment ${appointmentId} payment status to completed`
    );
  }
}

async function handlePaymentIntentFailed(paymentIntent: Stripe.PaymentIntent) {
  logger.error(`Payment failed: ${paymentIntent.id}`);

  const appointmentId = paymentIntent.metadata.appointmentId;
  if (appointmentId) {
    const businessId = paymentIntent.metadata.businessId;
    if (!businessId) return;

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(appointmentId)
      .update({
        paymentStatus: "failed",
        stripePaymentIntentId: paymentIntent.id,
        updatedAt: new Date(),
      });
  }
}

async function handleSubscriptionUpdate(subscription: Stripe.Subscription) {
  logger.info(`Subscription updated: ${subscription.id}`);

  const customerId = subscription.customer as string;
  const businessId = subscription.metadata.businessId;

  if (!businessId) {
    logger.error("Missing businessId in subscription metadata");
    return;
  }

  await db
    .collection("businesses")
    .doc(businessId)
    .collection("subscriptions")
    .doc("current")
    .set(
      {
        stripeSubscriptionId: subscription.id,
        stripeCustomerId: customerId,
        status: subscription.status,
        currentPeriodStart: new Date(subscription.current_period_start * 1000),
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
        updatedAt: new Date(),
      },
      {merge: true}
    );

  logger.info(`Updated subscription for business ${businessId}`);
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  logger.info(`Subscription deleted: ${subscription.id}`);

  const businessId = subscription.metadata.businessId;
  if (!businessId) return;

  await db
    .collection("businesses")
    .doc(businessId)
    .collection("subscriptions")
    .doc("current")
    .update({
      status: "canceled",
      canceledAt: new Date(),
      updatedAt: new Date(),
    });
}

async function handleInvoicePaid(invoice: Stripe.Invoice) {
  logger.info(`Invoice paid: ${invoice.id}`);

  const businessId = invoice.metadata?.businessId;
  if (!businessId) {
    logger.error("Missing businessId in invoice metadata");
    return;
  }

  const subscriptionId = invoice.subscription as string | undefined;
  const customerId = invoice.customer as string | undefined;

  const businessRef = db.collection("businesses").doc(businessId);
  const now = new Date();

  await businessRef.collection("subscriptions").doc("current").set(
    {
      status: "active",
      lastInvoiceId: invoice.id,
      lastInvoiceStatus: "paid",
      lastInvoiceAmount: invoice.amount_paid ?? invoice.amount_due ?? 0,
      lastInvoicePaidAt: now,
      updatedAt: now,
    },
    {merge: true}
  );

  await businessRef.collection("payments").doc(invoice.id).set(
    {
      businessId,
      type: "subscription",
      status: "completed",
      amountCents: invoice.amount_paid ?? invoice.amount_due ?? 0,
      currency: invoice.currency ?? "usd",
      stripeInvoiceId: invoice.id,
      stripeSubscriptionId: subscriptionId ?? null,
      stripeCustomerId: customerId ?? null,
      createdAt: new Date(invoice.created * 1000),
      paidAt: now,
      updatedAt: now,
    },
    {merge: true}
  );

  if (customerId && stripe) {
    try {
      const customer = await stripe.customers.retrieve(customerId);
      if (customer && "email" in customer && customer.email) {
        logger.info("Receipt ready", {
          invoiceId: invoice.id,
          customerId,
        });
      }
    } catch (customerError: unknown) {
      const message = getErrorMessage(customerError);
      logger.warn("Unable to retrieve Stripe customer for receipt", {
        invoiceId: invoice.id,
        error: message,
      });
    }
  }
}

async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  logger.error(`Invoice payment failed: ${invoice.id}`);

  const businessId = invoice.metadata?.businessId;
  if (!businessId) {
    logger.error("Missing businessId in invoice metadata");
    return;
  }

  const subscriptionId = invoice.subscription as string | undefined;
  const customerId = invoice.customer as string | undefined;
  const businessRef = db.collection("businesses").doc(businessId);
  const now = new Date();

  await businessRef.collection("subscriptions").doc("current").set(
    {
      status: "past_due",
      lastInvoiceId: invoice.id,
      lastInvoiceStatus: "failed",
      lastFailedAt: now,
      updatedAt: now,
    },
    {merge: true}
  );

  await businessRef.collection("payments").doc(invoice.id).set(
    {
      businessId,
      type: "subscription",
      status: "failed",
      amountCents: invoice.amount_due ?? 0,
      currency: invoice.currency ?? "usd",
      stripeInvoiceId: invoice.id,
      stripeSubscriptionId: subscriptionId ?? null,
      stripeCustomerId: customerId ?? null,
      createdAt: new Date(invoice.created * 1000),
      failedAt: now,
      failureReason:
        invoice.last_finalization_error?.message ?? "payment_failed",
      updatedAt: now,
    },
    {merge: true}
  );

  logger.info("Payment failure notification queued", {
    businessId,
    invoiceId: invoice.id,
  });
}

// ============================================================================
// Email & SMS Gateway Functions (Agent B - External Integrations)
// ============================================================================

/**
 * SendGrid Email Gateway
 *
 * POST /sendgridEmail
 * Body: {
 *   fromEmail: string,
 *   fromName: string,
 *   toEmail: string,
 *   toName: string,
 *   subject: string,
 *   body: string,
 *   replyTo?: string
 * }
 *
 * Returns: { success: true, messageId: string } | { success: false, error: string }
 */
export const sendgridEmail = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!sendgridApiKey || !sgMail) {
    res.status(500).json({
      success: false,
      error: "SendGrid not configured. Set SENDGRID_API_KEY environment variable.",
    });
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "sendgridEmail")) {
      res.status(429).json({
        success: false,
        error: "Too many requests",
      });
      return;
    }

    const {
      fromEmail,
      fromName,
      toEmail,
      toName,
      subject,
      body,
      replyTo,
      businessId,
    } = req.body ?? {};

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    const bodyString = typeof body === "string" ? body : "";
    const subjectString = typeof subject === "string" ? subject.trim() : "";
    const fromEmailString =
      typeof fromEmail === "string" ? fromEmail.trim() : "";
    const toEmailString = typeof toEmail === "string" ? toEmail.trim() : "";
    const replyToString =
      typeof replyTo === "string" ? replyTo.trim() : undefined;

    if (!fromEmailString || !toEmailString || !subjectString || !bodyString) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: fromEmail, toEmail, subject, body",
      });
      return;
    }

    if (!isValidEmail(fromEmailString) || !isValidEmail(toEmailString)) {
      res.status(400).json({
        success: false,
        error: "Invalid fromEmail or toEmail format",
      });
      return;
    }

    if (replyToString && !isValidEmail(replyToString)) {
      res.status(400).json({
        success: false,
        error: "Invalid replyTo format",
      });
      return;
    }

    if (subjectString.length > 255) {
      res.status(400).json({
        success: false,
        error: "Subject too long (max 255 characters)",
      });
      return;
    }

    if (bodyString.length > 12000) {
      res.status(400).json({
        success: false,
        error: "Body too long",
      });
      return;
    }

    // Construct SendGrid message
    const msg = {
      to: {
        email: toEmailString,
        name: toName || toEmailString,
      },
      from: {
        email: fromEmailString,
        name: fromName || fromEmailString,
      },
      subject: subjectString,
      html: bodyString,
      ...(replyToString && {replyTo: replyToString}),
    };

    // Send via SendGrid
    const [response] = await sgMail.send(msg);

    logger.info("SendGrid email sent", {statusCode: response.statusCode});

    res.json({
      success: true,
      messageId: response.headers["x-message-id"],
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("SendGrid error", {error: message});
    res.status(500).json({
      success: false,
      error: message || "Failed to send email via SendGrid",
    });
  }
});

/**
 * AWS SES Email Gateway
 *
 * POST /sesEmail
 * Body: {
 *   fromEmail: string,
 *   fromName: string,
 *   toEmail: string,
 *   toName: string,
 *   subject: string,
 *   body: string,
 *   replyTo?: string
 * }
 *
 * Returns: { success: true, messageId: string } | { success: false, error: string }
 */
export const sesEmail = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!sesClient) {
    res.status(500).json({
      success: false,
      error: "AWS SES not configured. Set AWS_SES_REGION, AWS_SES_ACCESS_KEY_ID, and AWS_SES_SECRET_ACCESS_KEY.",
    });
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "sesEmail")) {
      res.status(429).json({
        success: false,
        error: "Too many requests",
      });
      return;
    }

    const {
      fromEmail,
      fromName,
      toEmail,
      toName,
      subject,
      body,
      replyTo,
      businessId,
    } = req.body ?? {};

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    const bodyString = typeof body === "string" ? body : "";
    const subjectString = typeof subject === "string" ? subject.trim() : "";
    const fromEmailString =
      typeof fromEmail === "string" ? fromEmail.trim() : "";
    const toEmailString = typeof toEmail === "string" ? toEmail.trim() : "";
    const replyToString =
      typeof replyTo === "string" ? replyTo.trim() : undefined;

    // Validate required fields
    if (!fromEmailString || !toEmailString || !subjectString || !bodyString) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: fromEmail, toEmail, subject, body",
      });
      return;
    }

    if (!isValidEmail(fromEmailString) || !isValidEmail(toEmailString)) {
      res.status(400).json({
        success: false,
        error: "Invalid fromEmail or toEmail format",
      });
      return;
    }

    if (replyToString && !isValidEmail(replyToString)) {
      res.status(400).json({
        success: false,
        error: "Invalid replyTo format",
      });
      return;
    }

    if (subjectString.length > 255) {
      res.status(400).json({
        success: false,
        error: "Subject too long (max 255 characters)",
      });
      return;
    }

    if (bodyString.length > 12000) {
      res.status(400).json({
        success: false,
        error: "Body too long",
      });
      return;
    }

    // Construct AWS SES email
    const fromAddress = fromName ?
      `${fromName} <${fromEmailString}>` :
      fromEmailString;
    const toAddress = toName ? `${toName} <${toEmailString}>` : toEmailString;

    const command = new SendEmailCommand({
      FromEmailAddress: fromAddress,
      Destination: {
        ToAddresses: [toAddress],
      },
      Content: {
        Simple: {
          Subject: {
            Data: subjectString,
            Charset: "UTF-8",
          },
          Body: {
            Html: {
              Data: bodyString,
              Charset: "UTF-8",
            },
          },
        },
      },
      ...(replyTo && {
        ReplyToAddresses: [replyTo],
      }),
    });

    // Send via AWS SES
    const response = await sesClient.send(command);

    logger.info("AWS SES email sent", {messageId: response.MessageId ?? null});

    res.json({
      success: true,
      messageId: response.MessageId,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("AWS SES error", {error: message});
    res.status(500).json({
      success: false,
      error: message || "Failed to send email via AWS SES",
    });
  }
});

/**
 * Twilio SMS Gateway
 *
 * POST /twilioSms
 * Body: {
 *   to: string (E.164 format, e.g., +15551234567),
 *   message: string
 * }
 *
 * Returns: { success: true, messageId: string, segments: number } | { success: false, error: string }
 */
export const twilioSms = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!twilioClient || !twilioPhoneNumber) {
    res.status(500).json({
      success: false,
      error: "Twilio not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER.",
    });
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "twilioSms")) {
      res.status(429).json({
        success: false,
        error: "Too many requests",
      });
      return;
    }

    const {to, message, businessId} = req.body ?? {};

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    // Validate required fields
    if (!to || !message) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: to, message",
      });
      return;
    }

    // Validate phone format (basic check for E.164)
    if (!to.match(/^\+?[1-9]\d{10,14}$/)) {
      res.status(400).json({
        success: false,
        error: "Invalid phone number format. Use E.164 format (e.g., +15551234567)",
      });
      return;
    }

    if (typeof message !== "string" || !message.trim()) {
      res.status(400).json({
        success: false,
        error: "message must be a non-empty string",
      });
      return;
    }

    if (message.length > 1600) {
      res.status(400).json({
        success: false,
        error: "Message too long (max 1600 characters)",
      });
      return;
    }

    // Send via Twilio
    const response = await twilioClient.messages.create({
      body: message,
      from: twilioPhoneNumber,
      to: to,
    });

    logger.info("Twilio SMS sent", {sid: response.sid});

    // Calculate segments (Twilio charges per segment)
    const segments = response.numSegments ? parseInt(response.numSegments) : 1;

    res.json({
      success: true,
      messageId: response.sid,
      segments: segments,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Twilio error", {error: message});
    res.status(500).json({
      success: false,
      error: message || "Failed to send SMS via Twilio",
    });
  }
});

/**
 * AWS SNS SMS Gateway
 *
 * POST /snsSms
 * Body: {
 *   to: string (E.164 format, e.g., +15551234567),
 *   message: string,
 *   senderId?: string (optional sender ID/name)
 * }
 *
 * Returns: { success: true, messageId: string } | { success: false, error: string }
 */
export const snsSms = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!snsClient) {
    res.status(500).json({
      success: false,
      error: "AWS SNS not configured. Set AWS_SNS_REGION, AWS_SNS_ACCESS_KEY_ID, and AWS_SNS_SECRET_ACCESS_KEY.",
    });
    return;
  }

  try {
    const clientIp = getClientIp(req);
    if (isRateLimited(clientIp, "snsSms")) {
      res.status(429).json({
        success: false,
        error: "Too many requests",
      });
      return;
    }

    const {to, message, senderId, businessId} = req.body ?? {};

    const authContext = await requireAuthWithBusiness(
      req,
      res,
      typeof businessId === "string" ? businessId : undefined
    );
    if (!authContext) return;

    // Validate required fields
    if (!to || !message) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: to, message",
      });
      return;
    }

    // Validate phone format
    if (!to.match(/^\+?[1-9]\d{10,14}$/)) {
      res.status(400).json({
        success: false,
        error: "Invalid phone number format. Use E.164 format (e.g., +15551234567)",
      });
      return;
    }

    if (typeof message !== "string" || !message.trim()) {
      res.status(400).json({
        success: false,
        error: "message must be a non-empty string",
      });
      return;
    }

    if (message.length > 1600) {
      res.status(400).json({
        success: false,
        error: "Message too long (max 1600 characters)",
      });
      return;
    }

    // Construct AWS SNS message
    const messageAttributes: NonNullable<PublishCommandInput["MessageAttributes"]> =
      {
        "AWS.SNS.SMS.SMSType": {
          DataType: "String",
          StringValue: "Transactional", // Use Transactional for critical messages
        },
      };

    const params: PublishCommandInput = {
      PhoneNumber: to,
      Message: message,
      MessageAttributes: messageAttributes,
    };

    // Add sender ID if provided (not supported in all countries)
    if (senderId) {
      messageAttributes["AWS.SNS.SMS.SenderID"] = {
        DataType: "String",
        StringValue: senderId,
      };
    }

    const command = new PublishCommand(params);

    // Send via AWS SNS
    const response = await snsClient.send(command);

    logger.info("AWS SNS SMS sent", {messageId: response.MessageId ?? null});

    res.json({
      success: true,
      messageId: response.MessageId,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("AWS SNS error", {error: message});
    res.status(500).json({
      success: false,
      error: message || "Failed to send SMS via AWS SNS",
    });
  }
});

// ============================================================================
// Communications automation functions
// ============================================================================

/**
 * Send a one-off test message for a specific template.
 *
 * POST /sendTestMessage
 * Body: {
 *   businessId: string,
 *   userId: string,
 *   templateId?: string,
 *   subject?: string,      // for email when templateId is not provided
 *   body?: string,         // freeform body when templateId is not provided
 *   channel: 'email' | 'sms',
 *   recipient: string, // email or phone
 *   testData?: object,
 *   fromEmail?: string,
 *   fromName?: string,
 *   replyTo?: string
 * }
 */
export const sendTestMessage = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp, "sendTestMessage")) {
    res.status(429).json({
      success: false,
      error: "Too many requests",
    });
    return;
  }

  const authContext = await requireAuthWithBusiness(
    req,
    res,
    typeof req.body?.businessId === "string" ? req.body.businessId : undefined
  );
  if (!authContext) return;

  const {
    businessId,
    userId: _userId,
    templateId,
    subject,
    body,
    channel,
    recipient,
    testData,
    fromEmail,
    fromName,
    replyTo,
  } = req.body ?? {};

  if (!businessId || !channel || !recipient) {
    res.status(400).json({
      success: false,
      error: "businessId, channel, and recipient are required",
    });
    return;
  }
  if (!templateId && !body) {
    res.status(400).json({
      success: false,
      error: "Provide a templateId or a freeform body",
    });
    return;
  }

  try {
    await verifyUserRole(authContext.uid, authContext.businessId, ["owner", "admin"]);

    let renderedBody = body ?? "";
    let renderedSubject = subject ?? "";
    let previewVariables: Record<string, string> = {};
    let templateFromEmail: string | undefined;
    let templateFromName: string | undefined;
    let variables: Record<string, unknown> = {...(testData ?? {})};

    if (templateId) {
      const template = await loadTemplate(businessId, templateId, channel);
      if (!template) {
        res.status(404).json({success: false, error: "Template not found"});
        return;
      }

      templateFromEmail = template.fromEmail;
      templateFromName = template.fromName;

      const defaultData = {
        client_name: "John Doe",
        date: "Monday, January 15, 2025",
        time: "2:00 PM",
        provider_name: "Dr. Smith",
        location: "123 Main St",
        service_type: "Initial Consultation",
        business_name: "Scheduler HQ",
        booking_link: "https://scheduler.example.com/book",
        support_phone: "(555) 123-4567",
      };

      variables = {...defaultData, ...(testData ?? {})};
      const variableMap = normalizeVariables(
        variables as Record<string, unknown>
      );
      renderedBody = renderTemplate(template.body, variableMap);
      renderedSubject =
        channel === "email" ?
          renderTemplate(template.subject ?? "", variableMap) :
          "";
      const varsList = extractVariables(template.body);
      previewVariables = Object.fromEntries(
        varsList.map((v: string) => [v, ""])
      );
    }

    const effectiveSubject =
      channel === "email" ?
        (renderedSubject && renderedSubject.length > 0 ?
          renderedSubject :
          "Template Preview") :
        "";
    const toName =
      ((variables["client_name"] as string | undefined) ??
        (variables["clientName"] as string | undefined)) ??
      "Valued Client";

    let sendResult;
    if (channel === "email") {
      sendResult = await sendEmailMessage({
        toEmail: recipient,
        toName,
        subject: effectiveSubject || "Template Preview",
        body: renderedBody,
        fromEmail:
          fromEmail ??
          templateFromEmail ??
          "noreply@scheduler.example.com",
        fromName: fromName ?? templateFromName ?? "Scheduler",
        replyTo,
      });
    } else if (channel === "sms") {
      sendResult = await sendSmsMessage({
        to: recipient,
        message: renderedBody,
      });
    } else {
      res.status(400).json({success: false, error: "Unsupported channel"});
      return;
    }

    res.json({
      success: sendResult.success,
      messageId: sendResult.messageId,
      renderedPreview: renderedBody.substring(0, 500),
      variables: previewVariables,
    });
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("sendTestMessage error:", {error});
    res.status(500).json({
      success: false,
      error: message ?? "Failed to send test message",
    });
  }
});

/**
 * Trigger automated communications for an appointment lifecycle event.
 *
 * POST /sendAutomationMessage
 * Body: {
 *   businessId: string,
 *   userId: string,
 *   trigger: string, // matches AutomationTrigger name
 *   appointmentId?: string,
 *   clientId?: string,
 *   customData?: object
 * }
 */
export const sendAutomationMessage = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const {
    businessId,
    userId: _userId,
    trigger,
    appointmentId,
    clientId,
    customData,
  } = req.body ?? {};

  if (!businessId || !trigger) {
    res.status(400).json({
      success: false,
      error: "businessId and trigger are required",
    });
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp, "sendAutomationMessage")) {
    res.status(429).json({
      success: false,
      error: "Too many requests",
    });
    return;
  }

  const authContext = await requireAuthWithBusiness(
    req,
    res,
    typeof businessId === "string" ? businessId : undefined
  );
  if (!authContext) return;

  try {
    await verifyUserRole(authContext.uid, authContext.businessId, INTERNAL_BUSINESS_ROLES);

    const businessRef = db.collection("businesses").doc(authContext.businessId);
    const businessDoc = await businessRef.get();
    const business = businessDoc.data() ?? {};

    const rulesSnapshot = await businessRef
      .collection("automation_rules")
      .where("trigger", "==", String(trigger))
      .where("enabled", "==", true)
      .get();

    if (rulesSnapshot.empty) {
      res.json({sent: 0, messages: []});
      return;
    }

    const templates = await loadTemplatesMap(businessId);

    const appointmentDoc = appointmentId ?
      await businessRef.collection("appointments").doc(appointmentId).get() :
      null;
    const appointment = appointmentDoc?.data() ?? null;

    const resolvedClientId =
      clientId ?? (appointment ? appointment.clientId : null);
    const clientDoc = resolvedClientId ?
      await businessRef.collection("clients").doc(resolvedClientId).get() :
      null;
    const client = clientDoc?.data() ?? null;

    const providerDoc =
      appointment && appointment.providerId ?
        await businessRef
          .collection("providers")
          .doc(String(appointment.providerId))
          .get() :
        null;
    const provider = providerDoc?.data() ?? null;

    const serviceDoc =
      appointment && appointment.serviceId ?
        await businessRef
          .collection("services")
          .doc(String(appointment.serviceId))
          .get() :
        null;
    const service = serviceDoc?.data() ?? null;

    const locationDoc =
      appointment && appointment.locationId ?
        await businessRef
          .collection("locations")
          .doc(String(appointment.locationId))
          .get() :
        null;
    const location = locationDoc?.data() ?? null;

    const appointmentStart = appointment?.startTime ?
      toDate(appointment.startTime) :
      customData?.appointmentDate ?
        new Date(customData.appointmentDate) :
        null;

    const baseVariables: Record<string, string> = {
      client_name:
        client?.fullName ??
        client?.name ??
        [client?.firstName, client?.lastName].filter(Boolean).join(" ") ??
        "Client",
      date: appointmentStart ? formatDate(appointmentStart) : "",
      time: appointmentStart ? formatTime(appointmentStart) : "",
      location:
        location?.name ??
        location?.address ??
        customData?.location ??
        "Location",
      provider_name:
        provider?.fullName ??
        [provider?.firstName, provider?.lastName].filter(Boolean).join(" ") ??
        customData?.providerName ??
        "Provider",
      service_type: service?.name ?? customData?.serviceType ?? "Service",
      business_name: business?.name ?? "Your Business",
      support_phone:
        business?.supportPhone ?? customData?.support_phone ?? "Support",
      booking_link: customData?.booking_link ?? "",
      cancellation_reason: customData?.cancellation_reason ?? "",
      ...normalizeVariables(customData ?? {}),
    };

    const messages: SentMessage[] = [];
    const now = new Date();

    for (const ruleDoc of rulesSnapshot.docs) {
      const rule = ruleDoc.data();
      const messageType =
        rule.messageType ?? rule.type ?? String(trigger ?? "message");
      const channels: string[] = resolveChannels(rule);

      for (const channel of channels) {
        if (channel === "email") {
          const toEmail =
            client?.email ??
            customData?.clientEmail ??
            appointment?.clientEmail ??
            "";
          if (!toEmail) continue;

          const templateKey = `${channel}:${String(messageType)}`.toLowerCase();
          const template = templates[templateKey];

          const subject = template ?
            renderTemplate(template.subject ?? "", baseVariables) :
            `Update from ${baseVariables.business_name}`;
          const body = template ?
            renderTemplate(template.body, baseVariables) :
            renderFallbackBody(baseVariables, trigger);

          const sendResult = await sendEmailMessage({
            toEmail,
            toName: baseVariables.client_name,
            subject,
            body,
            fromEmail:
              template?.fromEmail ??
              business?.senderEmail ??
              "noreply@scheduler.example.com",
            fromName: template?.fromName ?? business?.name ?? "Scheduler",
          });

          await businessRef.collection("message_history").add({
            clientId: resolvedClientId ?? "",
            appointmentId: appointmentId ?? null,
            channel: "email",
            type: messageType,
            recipient: toEmail,
            status: sendResult.success ? "sent" : "failed",
            subject,
            body,
            sentAt: now,
            createdAt: now,
          });

          messages.push({
            channel,
            recipient: toEmail,
            success: sendResult.success,
            messageId: sendResult.messageId,
          });
        } else if (channel === "sms") {
          const toPhone =
            customData?.clientPhone ?? client?.phone ?? client?.mobile ?? "";
          if (!toPhone) continue;

          const templateKey = `${channel}:${String(messageType)}`.toLowerCase();
          const template = templates[templateKey];
          const message = template ?
            renderTemplate(template.body, baseVariables) :
            renderFallbackSms(baseVariables, trigger);

          const sendResult = await sendSmsMessage({
            to: toPhone,
            message,
          });

          await businessRef.collection("message_history").add({
            clientId: resolvedClientId ?? "",
            appointmentId: appointmentId ?? null,
            channel: "sms",
            type: messageType,
            recipient: toPhone,
            status: sendResult.success ? "sent" : "failed",
            body: message,
            sentAt: now,
            createdAt: now,
          });

          messages.push({
            channel,
            recipient: toPhone,
            success: sendResult.success,
            messageId: sendResult.messageId,
          });
        }
      }
    }

    const sentCount = messages.filter((m) => m.success).length;
    res.json({sent: sentCount, messages});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("sendAutomationMessage error:", {error});
    res.status(500).json({
      success: false,
      error: message ?? "Failed to send automation messages",
    });
  }
});

// ============================================================================
// Waitlist automation functions
// ============================================================================

/**
 * Notify matching waitlist entries when a slot becomes available.
 *
 * POST /handleReleasedSlot
 * Body: {
 *   businessId: string,
 *   userId: string,
 *   providerId: string,
 *   serviceId: string,
 *   locationId?: string,
 *   startTime: string, // ISO
 *   endTime?: string,
 *   maxNotifications?: number,
 *   responseWindowMinutes?: number,
 *   bookingLink?: string
 * }
 */
export const handleReleasedSlot = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp, "handleReleasedSlot")) {
    res.status(429).json({
      success: false,
      error: "Too many requests",
    });
    return;
  }

  const authContext = await requireAuthWithBusiness(
    req,
    res,
    typeof req.body?.businessId === "string" ? req.body.businessId : undefined
  );
  if (!authContext) return;

  const {
    businessId,
    userId: _userId,
    providerId,
    serviceId,
    locationId,
    startTime,
    endTime,
    maxNotifications,
    responseWindowMinutes,
    bookingLink,
  } = req.body ?? {};

  if (!businessId || !providerId || !serviceId || !startTime) {
    res.status(400).json({
      success: false,
      error: "businessId, providerId, serviceId, and startTime are required",
    });
    return;
  }

  try {
    await verifyUserRole(authContext.uid, authContext.businessId, INTERNAL_BUSINESS_ROLES);

    const slotStart = new Date(startTime);
    const slotEnd = endTime ? new Date(endTime) : null;

    if (Number.isNaN(slotStart.getTime())) {
      res.status(400).json({success: false, error: "Invalid startTime"});
      return;
    }

    const businessRef = db.collection("businesses").doc(businessId);
    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> =
      businessRef
        .collection("waitlist_entries")
        .where("status", "==", "active")
        .where("serviceId", "==", serviceId);

    if (providerId) {
      query = query.where("providerId", "==", providerId);
    }
    if (locationId) {
      query = query.where("locationId", "==", locationId);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      res.json({notified: 0, entryIds: []});
      return;
    }

    const responseWindow =
      typeof responseWindowMinutes === "number" && responseWindowMinutes > 0 ?
        responseWindowMinutes :
        120;

    const providerDoc = await businessRef
      .collection("providers")
      .doc(providerId)
      .get();
    const serviceDoc = await businessRef
      .collection("services")
      .doc(serviceId)
      .get();
    const locationDoc = locationId ?
      await businessRef.collection("locations").doc(locationId).get() :
      null;
    const businessDoc = await businessRef.get();

    const providerName =
      providerDoc.data()?.fullName ??
      [providerDoc.data()?.firstName, providerDoc.data()?.lastName]
        .filter(Boolean)
        .join(" ") ??
      providerDoc.data()?.name ??
      "Provider";
    const serviceName = serviceDoc.data()?.name ?? "Service";
    const locationName =
      locationDoc?.data()?.name ??
      locationDoc?.data()?.address ??
      "Location";
    const businessData = businessDoc.data() ?? {};
    const businessName = businessData.name ?? "Your Business";
    const supportPhone = businessData.supportPhone ?? "Support";

    const matches: Array<WaitlistSlotPrefs & {id: string}> = snapshot.docs
      .map((doc) => ({id: doc.id, ...(doc.data() as WaitlistSlotPrefs)}))
      .filter((entry) => matchesSlot(entry, slotStart))
      .sort((a, b) => {
        const scoreDiff =
          (a.priorityScore ?? 0) - (b.priorityScore ?? 0);
        if (scoreDiff !== 0) return scoreDiff;
        const createdA = toDate(a.createdAt)?.getTime() ?? 0;
        const createdB = toDate(b.createdAt)?.getTime() ?? 0;
        return createdA - createdB;
      });

    const limit =
      typeof maxNotifications === "number" && maxNotifications > 0 ?
        maxNotifications :
        3;
    const toNotify = matches.slice(0, limit);

    if (!toNotify.length) {
      res.json({notified: 0, entryIds: []});
      return;
    }

    const templates = await loadTemplatesMap(businessId);
    const waitlistEmailTemplate = templates["email:waitlistnotification"];
    const waitlistSmsTemplate = templates["sms:waitlistnotification"];

    const notifiedIds: string[] = [];
    const now = new Date();

    for (const entry of toNotify) {
      const variables: Record<string, string> = {
        client_name: entry.clientName ?? "there",
        date: formatDate(slotStart),
        time: formatTime(slotStart),
        location: locationName,
        provider_name: entry.providerName ?? providerName,
        service_type: entry.serviceName ?? serviceName,
        business_name: businessName,
        support_phone: supportPhone,
        booking_link: bookingLink ?? entry.bookingLink ?? "",
      };

      const pref = entry.notificationPreference ?? "email";
      const channels =
        pref === "both" ? ["email", "sms"] : [String(pref)];

      for (const channel of channels) {
        if (channel === "email" && entry.clientEmail) {
          const subject = waitlistEmailTemplate ?
            renderTemplate(waitlistEmailTemplate.subject ?? "", variables) :
            `Spot available with ${providerName}`;
          const body = waitlistEmailTemplate ?
            renderTemplate(waitlistEmailTemplate.body, variables) :
            renderFallbackBody(variables, "waitlist");

          const result = await sendEmailMessage({
            toEmail: entry.clientEmail,
            toName: entry.clientName ?? "Client",
            subject,
            body,
            fromEmail:
              businessData.senderEmail ?? "noreply@scheduler.example.com",
            fromName: businessName,
          });

          await businessRef.collection("message_history").add({
            clientId: entry.clientId ?? entry.id,
            channel: "email",
            type: "waitlistNotification",
            recipient: entry.clientEmail,
            status: result.success ? "sent" : "failed",
            subject,
            body,
            sentAt: now,
            createdAt: now,
          });
        } else if (channel === "sms" && entry.clientPhone) {
          const body = waitlistSmsTemplate ?
            renderTemplate(waitlistSmsTemplate.body, variables) :
            renderFallbackSms(variables, "waitlist");

          const result = await sendSmsMessage({
            to: entry.clientPhone,
            message: body,
          });

          await businessRef.collection("message_history").add({
            clientId: entry.clientId ?? entry.id,
            channel: "sms",
            type: "waitlistNotification",
            recipient: entry.clientPhone,
            status: result.success ? "sent" : "failed",
            body,
            sentAt: now,
            createdAt: now,
          });
        }
      }

      await businessRef
        .collection("waitlist_entries")
        .doc(entry.id)
        .update({
          status: "notified",
          lastNotifiedAt: now,
          responseExpiresAt: new Date(
            now.getTime() + responseWindow * 60 * 1000
          ),
          notifiedSlot: {
            startTime: slotStart,
            endTime: slotEnd,
            providerId,
            serviceId,
            locationId: locationId ?? null,
          },
          updatedAt: now,
        });

      notifiedIds.push(entry.id);
    }

    res.json({notified: notifiedIds.length, entryIds: notifiedIds});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("handleReleasedSlot error:", {error});
    res.status(500).json({
      success: false,
      error: message ?? "Failed to notify waitlist",
    });
  }
});

/**
 * Manually notify a specific waitlist entry.
 *
 * POST /notifyWaitlistEntry
 * Body: {
 *   businessId: string,
 *   userId: string,
 *   entryId: string,
 *   message: string,
 *   channel: 'email' | 'sms' | 'both',
 *   subject?: string
 * }
 */
export const notifyWaitlistEntry = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp, "notifyWaitlistEntry")) {
    res.status(429).json({
      success: false,
      error: "Too many requests",
    });
    return;
  }

  const {businessId, userId: _userId, entryId, message, channel, subject} =
    req.body ?? {};

  const authContext = await requireAuthWithBusiness(
    req,
    res,
    typeof businessId === "string" ? businessId : undefined
  );
  if (!authContext) return;

  if (!businessId || !entryId || !message || !channel) {
    res.status(400).json({
      success: false,
      error: "businessId, entryId, message, and channel are required",
    });
    return;
  }

  try {
    await verifyUserRole(authContext.uid, authContext.businessId, INTERNAL_BUSINESS_ROLES);

    const businessRef = db.collection("businesses").doc(businessId);
    const entryDoc = await businessRef
      .collection("waitlist_entries")
      .doc(entryId)
      .get();

    if (!entryDoc.exists) {
      res.status(404).json({success: false, error: "Entry not found"});
      return;
    }

    const entry = entryDoc.data() ?? {};
    const businessDoc = await businessRef.get();
    const business = businessDoc.data() ?? {};
    const now = new Date();
    const channels =
      channel === "both" ? ["email", "sms"] : [String(channel)];

    for (const ch of channels) {
      if (ch === "email" && entry.clientEmail) {
        const result = await sendEmailMessage({
          toEmail: entry.clientEmail,
          toName: entry.clientName ?? "Client",
          subject: subject ?? "Waitlist update",
          body: message,
          fromEmail: business.senderEmail ?? "noreply@scheduler.example.com",
          fromName: business.name ?? "Scheduler",
        });

        await businessRef.collection("message_history").add({
          clientId: entry.clientId ?? entry.id,
          channel: "email",
          type: "waitlistNotification",
          recipient: entry.clientEmail,
          status: result.success ? "sent" : "failed",
          subject: subject ?? "Waitlist update",
          body: message,
          sentAt: now,
          createdAt: now,
        });
      } else if (ch === "sms" && entry.clientPhone) {
        const result = await sendSmsMessage({
          to: entry.clientPhone,
          message,
        });

        await businessRef.collection("message_history").add({
          clientId: entry.clientId ?? entry.id,
          channel: "sms",
          type: "waitlistNotification",
          recipient: entry.clientPhone,
          status: result.success ? "sent" : "failed",
          body: message,
          sentAt: now,
          createdAt: now,
        });
      }
    }

    await entryDoc.ref.update({
      status: "notified",
      lastNotifiedAt: now,
      updatedAt: now,
    });

    res.json({success: true});
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("notifyWaitlistEntry error:", {error});
    res.status(500).json({
      success: false,
      error: message ?? "Failed to notify waitlist entry",
    });
  }
});

// Namespace export for legacy entrypoints (waitlist.notifyX)
// ============================================================================
// Helper utilities
// ============================================================================

type TemplateRecord = {
  id: string;
  channel: string;
  type: string;
  subject?: string;
  body: string;
  variables?: string[];
  fromEmail?: string;
  fromName?: string;
};

type SendResult = {
  success: boolean;
  messageId?: string;
  provider?: string;
  error?: string;
};

async function verifyUserRole(
  userId: string | undefined,
  businessId: string,
  allowedRoles: readonly string[]
) {
  if (!userId) {
    throw new Error("userId is required for authorization");
  }

  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new Error("User not found");
  }
  const data = userDoc.data() ?? {};

  if (data.businessId && data.businessId !== businessId) {
    throw new Error("User does not belong to this business");
  }

  const role = normalizeUserRole(data.role);
  if (!role || !allowedRoles.includes(role)) {
    throw new Error("Insufficient permissions");
  }

  return role;
}

async function loadTemplate(
  businessId: string,
  templateId: string,
  channel: string
): Promise<TemplateRecord | null> {
  const collection = db
    .collection("businesses")
    .doc(businessId)
    .collection("message_templates");

  const byId = await collection.doc(templateId).get();
  if (byId.exists) {
    const data = byId.data() ?? {};
    if (data.channel === channel) {
      return {
        id: byId.id,
        channel,
        type: data.type ?? templateId,
        subject: data.subject,
        body: data.body ?? "",
        variables: data.variables,
        fromEmail: data.fromEmail,
        fromName: data.fromName,
      };
    }
  }

  const byType = await collection
    .where("type", "==", templateId)
    .where("channel", "==", channel)
    .limit(1)
    .get();

  if (!byType.empty) {
    const doc = byType.docs[0];
    const data = doc.data();
    return {
      id: doc.id,
      channel,
      type: data.type ?? templateId,
      subject: data.subject,
      body: data.body ?? "",
      variables: data.variables,
      fromEmail: data.fromEmail,
      fromName: data.fromName,
    };
  }

  return null;
}

async function loadTemplatesMap(
  businessId: string
): Promise<Record<string, TemplateRecord>> {
  const snapshot = await db
    .collection("businesses")
    .doc(businessId)
    .collection("message_templates")
    .get();

  const templates: Record<string, TemplateRecord> = {};
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const key = `${data.channel}:${data.type}`;
    templates[key.toLowerCase()] = {
      id: doc.id,
      channel: data.channel,
      type: data.type,
      subject: data.subject,
      body: data.body ?? "",
      variables: data.variables,
      fromEmail: data.fromEmail,
      fromName: data.fromName,
    };
  });
  return templates;
}

function renderTemplate(
  template: string,
  variables: Record<string, string>
): string {
  let result = template;
  for (const [key, value] of Object.entries(variables)) {
    result = result.replace(
      new RegExp(`{{${key}}}`, "g"),
      value ?? ""
    );
  }
  return result;
}

function extractVariables(template: string): string[] {
  const matches = template.match(/{{(.*?)}}/g) ?? [];
  return matches.map((match) => match.replace(/[{}]/g, ""));
}

function normalizeVariables(input: Record<string, unknown>): Record<string, string> {
  return Object.entries(input ?? {}).reduce((acc, [key, value]) => {
    acc[key] = value !== undefined && value !== null ? String(value) : "";
    return acc;
  }, {} as Record<string, string>);
}

function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
  });
}

function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof (value as {toDate?: unknown}).toDate === "function"
  ) {
    return (value as {toDate: () => Date}).toDate();
  }
  const date = new Date(value as string);
  return Number.isNaN(date.getTime()) ? null : date;
}

function resolveChannels(rule: {channels?: unknown; emailEnabled?: boolean; smsEnabled?: boolean}): string[] {
  if (Array.isArray(rule.channels) && rule.channels.length > 0) {
    return rule.channels.map((c) => String(c));
  }

  const channels: string[] = [];
  if (rule.emailEnabled) channels.push("email");
  if (rule.smsEnabled) channels.push("sms");
  return channels.length ? channels : ["email"];
}

function matchesSlot(entry: WaitlistSlotPrefs, start: Date): boolean {
  const earliest = toDate(entry.earliestDate);
  const latest = toDate(entry.latestDate);
  const startDate = new Date(start.getFullYear(), start.getMonth(), start.getDate());

  if (earliest && startDate < new Date(earliest.getFullYear(), earliest.getMonth(), earliest.getDate())) {
    return false;
  }
  if (latest && startDate > new Date(latest.getFullYear(), latest.getMonth(), latest.getDate())) {
    return false;
  }

  const weekday = start.getDay() === 0 ? 7 : start.getDay();
  if (
    Array.isArray(entry.preferredDaysOfWeek) &&
    entry.preferredDaysOfWeek.length > 0 &&
    !entry.preferredDaysOfWeek.includes(weekday)
  ) {
    return false;
  }

  const preferences: string[] = Array.isArray(entry.timeOfDayPreferences) ?
    entry.timeOfDayPreferences :
    [];
  if (preferences.length) {
    const pref = timePreferenceFor(start);
    if (!preferences.includes("anytime") && !preferences.includes(pref)) {
      return false;
    }
  }

  return true;
}

function timePreferenceFor(date: Date): string {
  const hour = date.getHours();
  if (hour < 12) return "morning";
  if (hour < 17) return "afternoon";
  return "evening";
}

async function sendEmailMessage(params: {
  toEmail: string;
  toName?: string;
  subject: string;
  body: string;
  fromEmail?: string;
  fromName?: string;
  replyTo?: string;
}): Promise<SendResult> {
  if (sendgridApiKey && sgMail) {
    try {
      const [response] = await sgMail.send({
        to: {email: params.toEmail, name: params.toName ?? params.toEmail},
        from: {
          email: params.fromEmail ?? "noreply@scheduler.example.com",
          name: params.fromName ?? "Scheduler",
        },
        subject: params.subject,
        html: params.body,
        ...(params.replyTo && {replyTo: params.replyTo}),
      });

      return {
        success: true,
        messageId:
          (response.headers["x-message-id"] as string | undefined) ??
          (response.headers["X-Message-Id"] as string | undefined),
        provider: "sendgrid",
      };
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("SendGrid send error:", {error});
      return {success: false, error: message ?? "SendGrid error"};
    }
  }

  if (sesClient) {
    try {
      const command = new SendEmailCommand({
        Destination: {ToAddresses: [params.toEmail]},
        FromEmailAddress: params.fromEmail ?? "noreply@scheduler.example.com",
        ReplyToAddresses: params.replyTo ? [params.replyTo] : undefined,
        Content: {
          Simple: {
            Subject: {Data: params.subject},
            Body: {
              Html: {Data: params.body},
            },
          },
        },
      });

      const response = await sesClient.send(command);
      return {
        success: true,
        messageId:
          "MessageId" in response && typeof response.MessageId === "string" ?
            response.MessageId :
            undefined,
        provider: "ses",
      };
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("SES send error:", {error});
      return {success: false, error: message ?? "SES error"};
    }
  }

  return {success: false, error: "No email provider configured"};
}

async function sendSmsMessage(params: {
  to: string;
  message: string;
}): Promise<SendResult> {
  if (twilioClient && twilioPhoneNumber) {
    try {
      const response = await twilioClient.messages.create({
        to: params.to,
        from: twilioPhoneNumber,
        body: params.message,
      });
      return {success: true, messageId: response.sid, provider: "twilio"};
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("Twilio send error:", {error});
      return {success: false, error: message ?? "Twilio error"};
    }
  }

  if (snsClient) {
    try {
      const command = new PublishCommand({
        PhoneNumber: params.to,
        Message: params.message,
      });
      const response = await snsClient.send(command);
      return {
        success: true,
        messageId: response.MessageId,
        provider: "sns",
      };
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("SNS send error:", {error});
      return {success: false, error: message ?? "SNS error"};
    }
  }

  return {success: false, error: "No SMS provider configured"};
}

function renderFallbackBody(
  variables: Record<string, string>,
  trigger: string
): string {
  return `
    <p>Hello ${variables.client_name || "there"},</p>
    <p>There is an update for your appointment${
  variables.date ? ` on ${variables.date}` : ""
} ${variables.time ? `at ${variables.time}` : ""}.</p>
    <p>Provider: ${variables.provider_name ?? ""}</p>
    <p>Location: ${variables.location ?? ""}</p>
    <p>Reason: ${trigger}</p>
    <p>- ${variables.business_name || "Our team"}</p>
  `;
}

function renderFallbackSms(
  variables: Record<string, string>,
  trigger: string
): string {
  const parts = [
    `${variables.business_name || "Scheduler"} update`,
    variables.date && variables.time ?
      `${variables.date} at ${variables.time}` :
      "",
    variables.provider_name ? `with ${variables.provider_name}` : "",
    `(${trigger})`,
  ].filter(Boolean);

  return parts.join(" ");
}

// ============================================================================
// HIPAA Audit Log Archival (Agent HIPAA-F)
// ============================================================================

/**
 * Get the archive bucket name from environment or derive from project ID.
 */
function getArchiveBucketName(): string {
  if (process.env.AUDIT_ARCHIVE_BUCKET) {
    return process.env.AUDIT_ARCHIVE_BUCKET;
  }
  const projectId = app.options.projectId || process.env.GCLOUD_PROJECT || "";
  return `${projectId}-hipaa-audit-archive`;
}

/**
 * Scheduled function to archive audit logs older than 12 months.
 *
 * Runs on the 1st of each month at 02:00 UTC. Archives logs to GCS Coldline
 * storage and deletes from Firestore after successful upload.
 *
 * Schedule: "0 2 1 * *" = 02:00 UTC on the 1st of each month
 */
export const archiveOldAuditLogs = onSchedule(
  {
    schedule: "0 2 1 * *",
    timeZone: "UTC",
    retryCount: 3,
    maxRetrySeconds: 600,
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    logger.info("Starting audit log archival process");

    const now = new Date();
    const cutoffDate = new Date(now);
    cutoffDate.setMonth(cutoffDate.getMonth() - 12);

    const archiveMonth = new Date(cutoffDate);
    archiveMonth.setMonth(archiveMonth.getMonth() - 1);
    const archiveYearMonth = `${archiveMonth.getFullYear()}-${String(
      archiveMonth.getMonth() + 1
    ).padStart(2, "0")}`;

    logger.info(
      `Archiving audit logs older than ${cutoffDate.toISOString()}, ` +
        `target month: ${archiveYearMonth}`
    );

    const bucketName = getArchiveBucketName();
    const bucket = storage.bucket(bucketName);

    // Check if bucket exists and is accessible
    try {
      const [exists] = await bucket.exists();
      if (!exists) {
        logger.error(
          `Archive bucket ${bucketName} does not exist. ` +
            "Please create it with Coldline storage class."
        );
        return;
      }
    } catch (bucketError: unknown) {
      logger.error(`Cannot access archive bucket ${bucketName}`, {error: bucketError});
      return;
    }

    // Get all businesses
    const businessesSnapshot = await db.collection("businesses").get();
    if (businessesSnapshot.empty) {
      logger.info("No businesses found, skipping archival");
      return;
    }

    let totalArchived = 0;
    let totalDeleted = 0;
    let businessesProcessed = 0;

    for (const businessDoc of businessesSnapshot.docs) {
      const businessId = businessDoc.id;

      try {
        const result = await archiveBusinessAuditLogs(
          businessId,
          cutoffDate,
          archiveYearMonth,
          bucket
        );

        totalArchived += result.archived;
        totalDeleted += result.deleted;
        businessesProcessed++;

        if (result.archived > 0) {
          logger.info(
            `Business ${businessId}: archived ${result.archived} logs, ` +
              `deleted ${result.deleted} from Firestore`
          );
        }
      } catch (bizError: unknown) {
        logger.error(
          `Failed to archive logs for business ${businessId}`,
          {error: bizError}
        );
        // Continue with other businesses
      }
    }

    logger.info(
      `Archival complete: ${businessesProcessed} businesses processed, ` +
        `${totalArchived} logs archived, ${totalDeleted} logs deleted`
    );
  }
);

/**
 * Archive audit logs for a single business.
 */
async function archiveBusinessAuditLogs(
  businessId: string,
  cutoffDate: Date,
  archiveYearMonth: string,
  bucket: ReturnType<typeof storage.bucket>
): Promise<{archived: number; deleted: number}> {
  const auditLogsRef = db
    .collection("businesses")
    .doc(businessId)
    .collection("audit_logs");

  // Query logs older than cutoff date
  const cutoffTimestamp = Timestamp.fromDate(cutoffDate);
  const snapshot = await auditLogsRef
    .where("timestamp", "<", cutoffTimestamp)
    .orderBy("timestamp", "asc")
    .get();

  if (snapshot.empty) {
    return {archived: 0, deleted: 0};
  }

  // Collect logs to archive
  const logsToArchive: Array<Record<string, unknown>> = [];
  const docIdsToDelete: string[] = [];

  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    logsToArchive.push({
      id: doc.id,
      ...data,
      timestamp: data.timestamp?.toDate?.()?.toISOString() ?? data.timestamp,
    });
    docIdsToDelete.push(doc.id);
  });

  // Create compressed JSON archive
  const archiveContent = JSON.stringify(logsToArchive, null, 2);
  const compressed = zlib.gzipSync(Buffer.from(archiveContent, "utf-8"));

  // Upload to GCS
  const year = archiveYearMonth.slice(0, 4);
  const month = archiveYearMonth.slice(5, 7);
  const archivePath = `${businessId}/${year}/${month}/audit_logs_${archiveYearMonth}.json.gz`;

  const file = bucket.file(archivePath);
  try {
    await file.save(compressed, {
      contentType: "application/gzip",
      metadata: {
        contentEncoding: "gzip",
        metadata: {
          businessId,
          archiveMonth: archiveYearMonth,
          documentCount: String(logsToArchive.length),
          archivedAt: new Date().toISOString(),
          sourceCollection: `businesses/${businessId}/audit_logs`,
        },
      },
    });
  } catch (uploadError) {
    logger.error(`Failed to upload archive for ${businessId}`, uploadError);
    throw uploadError;
  }

  // Verify upload succeeded before deleting
  const [exists] = await file.exists();
  if (!exists) {
    throw new Error(`Archive upload verification failed for ${businessId}`);
  }

  // Delete archived documents from Firestore (in batches)
  const BATCH_SIZE = 400;
  let deletedCount = 0;

  for (let i = 0; i < docIdsToDelete.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const batchIds = docIdsToDelete.slice(i, i + BATCH_SIZE);

    for (const docId of batchIds) {
      batch.delete(auditLogsRef.doc(docId));
    }

    await batch.commit();
    deletedCount += batchIds.length;
  }

  // Log archival metadata
  await db
    .collection("businesses")
    .doc(businessId)
    .collection("archival_metadata")
    .doc(archiveYearMonth)
    .set({
      archiveMonth: archiveYearMonth,
      archivePath,
      documentCount: logsToArchive.length,
      archiveSizeBytes: compressed.length,
      deletedFromFirestore: deletedCount,
      archivedAt: FieldValue.serverTimestamp(),
      bucketName: bucket.name,
    });

  return {archived: logsToArchive.length, deleted: deletedCount};
}

/**
 * Manual trigger for audit log archival (for testing/recovery).
 *
 * POST /triggerAuditArchival
 * Body: {
 *   businessId?: string,  // Optional: archive only specific business
 *   monthsOld?: number,   // Optional: override 12-month cutoff (default: 12)
 *   dryRun?: boolean      // Optional: preview without actual archival
 * }
 *
 * Requires admin role.
 */
export const triggerAuditArchival = onRequest(async (req, res) => {
  if (applyCors(req, res, {methods: "POST,OPTIONS"})) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp, "triggerAuditArchival")) {
    res.status(429).json({error: "Too many requests"});
    return;
  }

  const {businessId, monthsOld, dryRun, userId: _userId} = req.body ?? {};

  const authContext = await requireAuthWithBusiness(
    req,
    res,
    typeof businessId === "string" ? businessId : undefined
  );
  if (!authContext) return;

  try {
    await verifyUserRole(authContext.uid, authContext.businessId, ["owner", "admin"]);
  } catch {
    res.status(403).json({error: "Insufficient permissions"});
    return;
  }

  const cutoffMonths =
    typeof monthsOld === "number" && monthsOld > 0 ? monthsOld : 12;
  const now = new Date();
  const cutoffDate = new Date(now);
  cutoffDate.setMonth(cutoffDate.getMonth() - cutoffMonths);

  const archiveMonth = new Date(cutoffDate);
  archiveMonth.setMonth(archiveMonth.getMonth() - 1);
  const archiveYearMonth = `${archiveMonth.getFullYear()}-${String(
    archiveMonth.getMonth() + 1
  ).padStart(2, "0")}`;

  logger.info(
    `Manual archival triggered: cutoff=${cutoffDate.toISOString()}, ` +
      `businessId=${businessId || "all"}, dryRun=${!!dryRun}`
  );

  if (dryRun) {
    // Preview mode: count logs without archiving
    const preview: Array<{businessId: string; logCount: number}> = [];

    if (businessId) {
      const count = await countLogsToArchive(businessId, cutoffDate);
      preview.push({businessId, logCount: count});
    } else {
      const businesses = await db.collection("businesses").get();
      for (const doc of businesses.docs) {
        const count = await countLogsToArchive(doc.id, cutoffDate);
        if (count > 0) {
          preview.push({businessId: doc.id, logCount: count});
        }
      }
    }

    res.json({
      dryRun: true,
      cutoffDate: cutoffDate.toISOString(),
      archiveYearMonth,
      preview,
      totalLogs: preview.reduce((sum, p) => sum + p.logCount, 0),
    });
    return;
  }

  // Actual archival
  const bucketName = getArchiveBucketName();
  const bucket = storage.bucket(bucketName);

  try {
    const [exists] = await bucket.exists();
    if (!exists) {
      res.status(500).json({
        error: `Archive bucket ${bucketName} does not exist`,
      });
      return;
    }
  } catch (bucketError: unknown) {
    res.status(500).json({
      error: `Cannot access archive bucket: ${getErrorMessage(bucketError)}`,
    });
    return;
  }

  const results: Array<{
    businessId: string;
    archived: number;
    deleted: number;
    error?: string;
  }> = [];

  if (businessId) {
    try {
      const result = await archiveBusinessAuditLogs(
        businessId,
        cutoffDate,
        archiveYearMonth,
        bucket
      );
      results.push({businessId, ...result});
    } catch (err: unknown) {
      results.push({
        businessId,
        archived: 0,
        deleted: 0,
        error: getErrorMessage(err),
      });
    }
  } else {
    const businesses = await db.collection("businesses").get();
    for (const doc of businesses.docs) {
      try {
        const result = await archiveBusinessAuditLogs(
          doc.id,
          cutoffDate,
          archiveYearMonth,
          bucket
        );
        if (result.archived > 0) {
          results.push({businessId: doc.id, ...result});
        }
      } catch (err: unknown) {
        results.push({
          businessId: doc.id,
          archived: 0,
          deleted: 0,
          error: getErrorMessage(err),
        });
      }
    }
  }

  res.json({
    success: true,
    cutoffDate: cutoffDate.toISOString(),
    archiveYearMonth,
    bucketName,
    results,
    totalArchived: results.reduce((sum, r) => sum + r.archived, 0),
    totalDeleted: results.reduce((sum, r) => sum + r.deleted, 0),
  });
});

async function countLogsToArchive(
  businessId: string,
  cutoffDate: Date
): Promise<number> {
  const cutoffTimestamp = Timestamp.fromDate(cutoffDate);
  const snapshot = await db
    .collection("businesses")
    .doc(businessId)
    .collection("audit_logs")
    .where("timestamp", "<", cutoffTimestamp)
    .count()
    .get();

  return snapshot.data().count;
}

// ------------------------------------------------------------------
// Admin Dashboard callable endpoints (prefixed/kebab names)
// Implemented as onCall handlers to support Admin/CRM callTenantFunction.
// ------------------------------------------------------------------
const getBusinessContextFromCall = (
  request: CallableRequest<Record<string, unknown>>
): {businessId: string; uid: string} => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  const businessId =
    (typeof request.data?.businessId === "string" && request.data.businessId.trim()) ||
    (typeof request.auth.token?.businessId === "string" &&
      (request.auth.token.businessId as string)) ||
    "";
  if (!businessId) {
    throw new HttpsError("invalid-argument", "businessId is required");
  }
  return {businessId, uid: request.auth.uid};
};

const withAuditSafe = async (
  fn: () => Promise<unknown>
): Promise<unknown> => {
  try {
    return await fn();
  } catch (err: unknown) {
    const message = getErrorMessage(err);
    logger.error("Admin callable failed", {error: message});
    throw new HttpsError("internal", message ?? "Internal error");
  }
};

const communicationsSaveTemplate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const template = request.data?.template ?? {};
    const templatesRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("message_templates");

    const templateId =
      (typeof template.id === "string" && template.id) || undefined;
    const payload = {
      ...template,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    };
    if (templateId) {
      await templatesRef.doc(templateId).set(payload, {merge: true});
      return {id: templateId};
    }
    const docRef = await templatesRef.add({
      ...payload,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });
    return {id: docRef.id};
  })
);

const communicationsDeleteTemplate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const templateId = request.data?.templateId;
    if (!templateId || typeof templateId !== "string") {
      throw new HttpsError("invalid-argument", "templateId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("message_templates")
      .doc(templateId)
      .delete();
    return {success: true};
  })
);

const communicationsUpdateAutomationRule = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const ruleId = request.data?.ruleId;
    const updates = request.data?.updates ?? {};
    if (!ruleId || typeof ruleId !== "string") {
      throw new HttpsError("invalid-argument", "ruleId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("automation_rules")
      .doc(ruleId)
      .set(
        {
          ...updates,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const waitlistCreateEntry = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const input = request.data?.input ?? {};
    const docRef = await db
      .collection("businesses")
      .doc(businessId)
      .collection("waitlist_entries")
      .add({
        ...input,
        businessId,
        status: "active",
        createdAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: docRef.id};
  })
);

const waitlistUpdateStatus = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {entryId, status} = request.data ?? {};
    if (!entryId || typeof entryId !== "string") {
      throw new HttpsError("invalid-argument", "entryId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("waitlist_entries")
      .doc(entryId)
      .set(
        {
          status,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const waitlistPerformAction = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {entryId, action, metadata = {}} = request.data ?? {};
    if (!entryId || typeof entryId !== "string") {
      throw new HttpsError("invalid-argument", "entryId is required");
    }
    const ref = db
      .collection("businesses")
      .doc(businessId)
      .collection("waitlist_entries")
      .doc(entryId);
    const updates: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
      ...metadata,
    };
    if (action === "convert") {
      updates.status = "converted";
      updates.convertedAt = FieldValue.serverTimestamp();
    } else if (action === "expire") {
      updates.status = "expired";
      updates.expiredAt = FieldValue.serverTimestamp();
    } else if (action === "notify") {
      updates.lastNotifiedAt = FieldValue.serverTimestamp();
      updates.notificationCount = metadata?.notificationCount ?? FieldValue.increment(1);
    }
    await ref.set(updates, {merge: true});
    return {success: true};
  })
);

const appointmentsCreate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const input = request.data?.input ?? {};
    const ref = await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .add({
        ...input,
        businessId,
        status: input?.status ?? "pending",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: ref.id};
  })
);

const appointmentsUpdate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {appointmentId, updates = {}} = request.data ?? {};
    if (!appointmentId || typeof appointmentId !== "string") {
      throw new HttpsError("invalid-argument", "appointmentId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(appointmentId)
      .set(
        {
          ...updates,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const appointmentsCancel = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {appointmentId, metadata = {}} = request.data ?? {};
    if (!appointmentId || typeof appointmentId !== "string") {
      throw new HttpsError("invalid-argument", "appointmentId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(appointmentId)
      .set(
        {
          status: "cancelled",
          cancelledAt: FieldValue.serverTimestamp(),
          cancelledBy: uid,
          cancellationMetadata: metadata,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

const groupSessionsCreate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const input = request.data?.input ?? {};
    const ref = await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .add({
        ...input,
        businessId,
        isGroupSession: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: ref.id};
  })
);

const groupSessionsUpdate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {sessionId, updates = {}} = request.data ?? {};
    if (!sessionId || typeof sessionId !== "string") {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(sessionId)
      .set(
        {
          ...updates,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const groupSessionsDelete = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {sessionId} = request.data ?? {};
    if (!sessionId || typeof sessionId !== "string") {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(sessionId)
      .delete();
    return {success: true};
  })
);

const groupSessionsAddAttendee = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {sessionId, attendee} = request.data ?? {};
    if (!sessionId || typeof sessionId !== "string") {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }
    const ref = await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(sessionId)
      .collection("attendees")
      .add({
        ...attendee,
        businessId,
        createdAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: ref.id};
  })
);

const groupSessionsUpdateAttendee = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {sessionId, attendeeId, updates = {}} = request.data ?? {};
    if (!sessionId || typeof sessionId !== "string" || !attendeeId || typeof attendeeId !== "string") {
      throw new HttpsError("invalid-argument", "sessionId and attendeeId are required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(sessionId)
      .collection("attendees")
      .doc(attendeeId)
      .set(
        {
          ...updates,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const groupSessionsRemoveAttendee = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {sessionId, attendeeId} = request.data ?? {};
    if (!sessionId || typeof sessionId !== "string" || !attendeeId || typeof attendeeId !== "string") {
      throw new HttpsError("invalid-argument", "sessionId and attendeeId are required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .doc(sessionId)
      .collection("attendees")
      .doc(attendeeId)
      .delete();
    return {success: true};
  })
);

const intakeFormsCreate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const input = request.data?.input ?? {};
    const ref = await db
      .collection("businesses")
      .doc(businessId)
      .collection("intakeFormTemplates")
      .add({
        ...input,
        businessId,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: ref.id};
  })
);

const intakeFormsUpdate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {formId, form = {}} = request.data ?? {};
    if (!formId || typeof formId !== "string") {
      throw new HttpsError("invalid-argument", "formId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("intakeFormTemplates")
      .doc(formId)
      .set(
        {
          ...form,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const intakeFormsDuplicate = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {formId} = request.data ?? {};
    if (!formId || typeof formId !== "string") {
      throw new HttpsError("invalid-argument", "formId is required");
    }
    const src = await db
      .collection("businesses")
      .doc(businessId)
      .collection("intakeFormTemplates")
      .doc(formId)
      .get();
    if (!src.exists) {
      throw new HttpsError("not-found", "Source form not found");
    }
    const dataCopy = src.data() ?? {};
    const ref = await db
      .collection("businesses")
      .doc(businessId)
      .collection("intakeFormTemplates")
      .add({
        ...dataCopy,
        name: `${dataCopy.name ?? "Template"} (Copy)`,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    return {id: ref.id};
  })
);

const intakeFormsArchive = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId, uid} = getBusinessContextFromCall(request);
    const {formId} = request.data ?? {};
    if (!formId || typeof formId !== "string") {
      throw new HttpsError("invalid-argument", "formId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("intakeFormTemplates")
      .doc(formId)
      .set(
        {
          isActive: false,
          archivedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: uid,
        },
        {merge: true}
      );
    return {success: true};
  })
);

const integrationsConnect = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {provider} = request.data ?? {};
    if (!provider || typeof provider !== "string") {
      throw new HttpsError("invalid-argument", "provider is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(provider)
      .set(
        {
          status: "connected",
          connectedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

const integrationsDisconnect = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {provider} = request.data ?? {};
    if (!provider || typeof provider !== "string") {
      throw new HttpsError("invalid-argument", "provider is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(provider)
      .set(
        {
          status: "disconnected",
          disconnectedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

const integrationsRefresh = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {provider} = request.data ?? {};
    if (!provider || typeof provider !== "string") {
      throw new HttpsError("invalid-argument", "provider is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("integrations")
      .doc(provider)
      .set(
        {
          status: "refreshed",
          lastRefreshedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

const integrationsSaveStaffPreference = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {preference} = request.data ?? {};
    const staffId = preference?.staffId;
    if (!staffId || typeof staffId !== "string") {
      throw new HttpsError("invalid-argument", "preference.staffId is required");
    }
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("staff_integrations")
      .doc(staffId)
      .set(
        {
          ...preference,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

const integrationsUpdateTelehealthSettings = onCall(async (request) =>
  withAuditSafe(async () => {
    const {businessId} = getBusinessContextFromCall(request);
    const {updates = {}} = request.data ?? {};
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("settings")
      .doc("telehealth")
      .set(
        {
          ...updates,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    return {success: true};
  })
);

export const appointments = {
  create: appointmentsCreate,
  update: appointmentsUpdate,
  cancel: appointmentsCancel,
};

export const groupSessions = {
  create: groupSessionsCreate,
  update: groupSessionsUpdate,
  delete: groupSessionsDelete,
  addAttendee: groupSessionsAddAttendee,
  updateAttendee: groupSessionsUpdateAttendee,
  removeAttendee: groupSessionsRemoveAttendee,
};

// ------------------------------------------------------------------
// Admin Dashboard compatibility aliases (prefixed/kebab names)
// These mirror existing camelCase exports so Admin/CRM callers using
// dashed names can resolve without changing their call sites.
// ------------------------------------------------------------------

// Legacy namespace export for callers using dotted entrypoints (e.g., waitlist.notifyEntry)
export const waitlist = {
  createEntry: waitlistCreateEntry,
  updateStatus: waitlistUpdateStatus,
  performAction: waitlistPerformAction,
  handleReleasedSlot,
  notifyEntry: notifyWaitlistEntry,
};

// Legacy namespace export for marketing dotted entrypoints
export const marketing = {
  previewAudience: previewCampaign,
  launchCampaign,
  sendTest: testCampaign,
};

// Legacy namespace export for communications dotted entrypoints
export const communications = {
  saveTemplate: communicationsSaveTemplate,
  updateAutomationRule: communicationsUpdateAutomationRule,
  deleteTemplate: communicationsDeleteTemplate,
  sendTestMessage,
};

// Legacy namespace export for integrations dotted entrypoints
export const integrations = {
  connect: integrationsConnect,
  refresh: integrationsRefresh,
  disconnect: integrationsDisconnect,
  saveStaffPreference: integrationsSaveStaffPreference,
  updateTelehealthSettings: integrationsUpdateTelehealthSettings,
};

// Legacy namespace export for intake form dotted entrypoints
export const intakeForms = {
  create: intakeFormsCreate,
  update: intakeFormsUpdate,
  duplicate: intakeFormsDuplicate,
  archive: intakeFormsArchive,
};

// Namespace exports for CRM/Payments/Reporting dotted entrypoints
export const crm = {
  metrics: crmMetrics,
  export: crmExport,
  import: crmImport,
};

export const payments = {
  createIntent: createPaymentIntent,
  refund: refundPayment,
  getCustomerPortalUrl: createPortalSession,
  getReceiptUrl: getPaymentReceiptUrl,
};

export const reporting = {
  exportCsv: exportReportCsv,
  exportPdf: exportReportPdf,
  getMetrics: getReportMetrics,
};

export const publicBooking = {
  createAppointment: publicCreateAppointment,
  resolveBusinessSlug,
  listCatalog: publicListCatalog,
  getAvailableAppointments: publicGetAvailableAppointments,
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["payments-createIntent"] = createPaymentIntent;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["payments-refund"] = refundPayment;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["payments-getCustomerPortalUrl"] = createPortalSession;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["payments-getReceiptUrl"] = getPaymentReceiptUrl;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["ownership-transfer"] = ownershipTransfer;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["staff-save"] = staffSave;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["staff-bulkInvite"] = staffBulkInvite;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["workspace-requestDataExport"] = requestDataExportCallable;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["workspace-initiateBusinessDeletion"] = initiateBusinessDeletionCallable;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["billing-createCheckoutSession"] = billingCreateCheckoutSession;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["billing-createPortalSession"] = billingCreatePortalSession;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["reporting-getMetrics"] = getReportMetrics;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["reporting-exportCsv"] = exportReportCsv;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["reporting-exportPdf"] = exportReportPdf;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["waitlist-handleReleasedSlot"] = handleReleasedSlot;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["waitlist-notifyEntry"] = notifyWaitlistEntry;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["waitlist-createEntry"] = waitlistCreateEntry;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["waitlist-updateStatus"] = waitlistUpdateStatus;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["waitlist-performAction"] = waitlistPerformAction;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["appointments-create"] = appointmentsCreate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["appointments-update"] = appointmentsUpdate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["appointments-cancel"] = appointmentsCancel;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-create"] = groupSessionsCreate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-update"] = groupSessionsUpdate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-delete"] = groupSessionsDelete;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-addAttendee"] = groupSessionsAddAttendee;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-updateAttendee"] = groupSessionsUpdateAttendee;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["groupSessions-removeAttendee"] = groupSessionsRemoveAttendee;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["intakeForms-create"] = intakeFormsCreate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["intakeForms-update"] = intakeFormsUpdate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["intakeForms-duplicate"] = intakeFormsDuplicate;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["intakeForms-archive"] = intakeFormsArchive;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["integrations-connect"] = integrationsConnect;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["integrations-disconnect"] = integrationsDisconnect;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["integrations-refresh"] = integrationsRefresh;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["integrations-saveStaffPreference"] =
  integrationsSaveStaffPreference;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["integrations-updateTelehealthSettings"] =
  integrationsUpdateTelehealthSettings;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["leads-convert"] = leadsConvert;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["crm-metrics"] = crmMetrics;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["deals-stageChange"] = dealsStageChange;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["crm-export"] = crmExport;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["crm-import"] = crmImport;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["public-createAppointment"] = publicCreateAppointment;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["public-resolveBusinessSlug"] = resolveBusinessSlug;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["public-listCatalog"] = publicListCatalog;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["public-getAvailableAppointments"] = publicGetAvailableAppointments;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["auth-provisionWorkspace"] = createWorkspaceCallable;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any).auth = {provisionWorkspace: createWorkspaceCallable};
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(exports as any)["lookup-businessBySlug"] = lookupBusinessBySlugCallable;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
