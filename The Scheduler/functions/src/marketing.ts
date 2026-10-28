/**
 * Cloud Functions for Marketing Campaigns
 *
 * Priority 5: Marketing Campaign Functions
 *
 * Handles:
 * - Campaign template preview
 * - Campaign launch (batch email/SMS sending)
 * - Test campaign sending
 *
 * Environment Variables Required:
 * - SENDGRID_API_KEY (inherited from index.ts)
 * - TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN (inherited)
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, auth} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import {
  normalizeCampaignChannel,
  resolveCampaignContent,
  type CampaignRecord,
} from "./marketingHelpers";
import {isAdminRole, normalizeUserRole} from "./roleUtils";

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const logMarketingError = (
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
 * HIPAA-compliant authentication helper for marketing endpoints.
 * Verifies Firebase ID token and checks user has access to the business.
 * Returns uid and verified businessId, or sends error response.
 */
const requireMarketingAuth = async (
  req: {headers: {authorization?: string}; body: {businessId?: string}},
  res: {status: (code: number) => {json: (data: unknown) => void}}
): Promise<{uid: string; businessId: string} | null> => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({error: "Unauthorized"});
    return null;
  }

  const token = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await auth.verifyIdToken(token);
    const uid = decodedToken.uid;
    const businessId = req.body.businessId;

    if (!businessId) {
      res.status(400).json({success: false, error: "businessId is required"});
      return null;
    }

    // Verify user has access to this business
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      res.status(403).json({error: "User not found"});
      return null;
    }

    const userData = userDoc.data();
    if (userData?.businessId !== businessId) {
      res.status(403).json({error: "Access denied to this business"});
      return null;
    }

    // Check role - marketing requires owner or admin
    const role = normalizeUserRole(decodedToken.role) ?? normalizeUserRole(userData?.role);
    if (!isAdminRole(role)) {
      res.status(403).json({error: "Marketing access requires owner or admin role"});
      return null;
    }

    return {uid, businessId};
  } catch (error) {
    logMarketingError("Auth verification failed", error);
    res.status(401).json({error: "Invalid or expired token"});
    return null;
  }
};

interface CampaignPreviewResponse {
  success: boolean;
  preview?: string;
  subject?: string;
  channel?: "email" | "sms";
  variables?: string[];
  error?: string;
}

interface CampaignLaunchResponse {
  success: boolean;
  queuedCount?: number;
  error?: string;
}

interface CampaignTestResponse {
  success: boolean;
  messageId?: string;
  renderedPreview?: string;
  subject?: string;
  channel?: "email" | "sms";
  error?: string;
}

/**
 * Render template variables for a campaign
 */
const renderTemplate = (
  template: string,
  variables: Record<string, string>
): string => {
  let rendered = template;
  for (const [key, value] of Object.entries(variables)) {
    const regex = new RegExp(`{{${key}}}`, "g");
    rendered = rendered.replace(regex, value);
  }
  return rendered;
};

/**
 * Extract variable names from template
 */
const extractVariables = (template: string): string[] => {
  const regex = /{{(\w+)}}/g;
  const variables: string[] = [];
  let match;

  while ((match = regex.exec(template)) !== null) {
    if (!variables.includes(match[1])) {
      variables.push(match[1]);
    }
  }

  return variables;
};


/**
 * Preview campaign with sample data
 *
 * POST /previewCampaign
 * Body: {
 *   businessId: string,
 *   campaignId: string,
 *   sampleData?: Record<string, string>,
 *   channel?: 'email' | 'sms'
 * }
 *
 * Returns: {
 *   success: true,
 *   preview: string,
 *   subject?: string,
 *   channel: 'email' | 'sms',
 *   variables: string[]
 * }
 */
export const previewCampaign = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // HIPAA: Require authentication
  const authResult = await requireMarketingAuth(req, res);
  if (!authResult) return;

  try {
    const {campaignId, sampleData} = req.body;
    const {businessId} = authResult; // Use verified businessId from auth

    if (!campaignId) {
      res.status(400).json({
        success: false,
        error: "campaignId is required",
      });
      return;
    }

    // Get campaign
    const campaignDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("campaigns")
      .doc(campaignId)
      .get();

    if (!campaignDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Campaign not found",
      });
      return;
    }

    const requestedChannel = normalizeCampaignChannel(req.body?.channel, "email");
    const previewChannel = requestedChannel === "both" ? "email" : requestedChannel;
    const campaign = campaignDoc.data() as CampaignRecord | undefined;
    const {template, subject} = resolveCampaignContent(campaign, previewChannel);

    if (!template) {
      res.status(400).json({
        success: false,
        error: `Campaign has no template content for ${previewChannel}.`,
      });
      return;
    }

    // Extract variables
    const variables = extractVariables(template);

    // Use sample data or defaults
    const defaultSampleData: Record<string, string> = {
      firstName: "John",
      lastName: "Doe",
      email: "john.doe@example.com",
      appointmentDate: "Monday, January 15, 2025",
      appointmentTime: "2:00 PM",
      providerName: "Dr. Smith",
      businessName: "The Scheduler",
    };

    const data = {...defaultSampleData, ...(sampleData || {})};

    // Render preview
    const preview = renderTemplate(template, data);

    const response: CampaignPreviewResponse = {
      success: true,
      preview,
      subject,
      channel: previewChannel,
      variables,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logMarketingError("Error previewing campaign", error, {
      campaignId: req.body?.campaignId ?? null,
    });
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Launch campaign - queue emails/SMS for batch sending
 *
 * POST /launchCampaign
 * Body: {
 *   businessId: string,
 *   campaignId: string,
 *   recipientIds: string[] (client IDs),
 *   channel: 'email' | 'sms' | 'both'
 * }
 *
 * Returns: {
 *   success: true,
 *   queuedCount: number
 * }
 */
export const launchCampaign = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // HIPAA: Require authentication
  const authResult = await requireMarketingAuth(req, res);
  if (!authResult) return;

  try {
    const {campaignId, recipientIds, channel} = req.body;
    const {businessId} = authResult; // Use verified businessId from auth

    if (!campaignId || !recipientIds || !channel) {
      res.status(400).json({
        success: false,
        error: "campaignId, recipientIds, and channel are required",
      });
      return;
    }

    if (!Array.isArray(recipientIds)) {
      res.status(400).json({
        success: false,
        error: "recipientIds must be an array",
      });
      return;
    }

    // Get campaign
    const campaignDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("campaigns")
      .doc(campaignId)
      .get();

    if (!campaignDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Campaign not found",
      });
      return;
    }

    const campaign = campaignDoc.data() as CampaignRecord | undefined;
    const requestedChannel = normalizeCampaignChannel(channel, "email");
    const channelsToQueue =
      requestedChannel === "both" ? ["email", "sms"] as const : [requestedChannel];
    const channelPayloads = channelsToQueue
      .map((resolvedChannel) => ({
        channel: resolvedChannel,
        ...resolveCampaignContent(campaign, resolvedChannel),
      }))
      .filter((payload) => payload.template);

    if (!channelPayloads.length) {
      res.status(400).json({
        success: false,
        error: "Campaign has no template content for the requested channels.",
      });
      return;
    }

    // Queue messages for each recipient
    const queueBatch = db.batch();
    let queuedCount = 0;

    for (const clientId of recipientIds) {
      // Get client data
      const clientDoc = await db
        .collection("businesses")
        .doc(businessId)
        .collection("clients")
        .doc(clientId)
        .get();

      if (!clientDoc.exists) continue;

      const client = clientDoc.data();

      // Prepare variables
      const variables: Record<string, string> = {
        firstName: client?.firstName || "",
        lastName: client?.lastName || "",
        email: client?.email || "",
        phone: client?.phone || "",
      };

      for (const payload of channelPayloads) {
        const queueRef = db
          .collection("businesses")
          .doc(businessId)
          .collection("message_queue")
          .doc();

        queueBatch.set(queueRef, {
          campaignId,
          clientId,
          channel: [payload.channel],
          template: payload.template,
          subject: payload.subject,
          variables,
          status: "pending",
          createdAt: new Date(),
          scheduledFor: new Date(), // Send immediately
        });

        queuedCount++;
      }
    }

    // Commit batch
    await queueBatch.commit();

    // Update campaign status
    await campaignDoc.ref.update({
      status: "sent",
      sentAt: new Date(),
      updatedAt: new Date(),
      recipientCount: queuedCount,
    });

    const response: CampaignLaunchResponse = {
      success: true,
      queuedCount,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logMarketingError("Error launching campaign", error, {
      campaignId: req.body?.campaignId ?? null,
    });
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Send test campaign to single recipient
 *
 * POST /testCampaign
 * Body: {
 *   businessId: string,
 *   campaignId: string,
 *   recipient: string (email or phone),
 *   channel: 'email' | 'sms'
 * }
 *
 * Returns: { success: true, renderedPreview, subject?, channel, messageId }
 */
export const testCampaign = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // HIPAA: Require authentication
  const authResult = await requireMarketingAuth(req, res);
  if (!authResult) return;

  try {
    const {campaignId, recipient, channel} = req.body;
    const {businessId} = authResult; // Use verified businessId from auth

    if (!campaignId || !recipient || !channel) {
      res.status(400).json({
        success: false,
        error: "campaignId, recipient, and channel are required",
      });
      return;
    }

    // Get campaign
    const campaignDoc = await db
      .collection("businesses")
      .doc(businessId)
      .collection("campaigns")
      .doc(campaignId)
      .get();

    if (!campaignDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Campaign not found",
      });
      return;
    }

    const campaign = campaignDoc.data() as CampaignRecord | undefined;
    const resolvedChannel = normalizeCampaignChannel(channel, "email");
    if (resolvedChannel === "both") {
      res.status(400).json({
        success: false,
        error: "Campaign test requires a single channel.",
      });
      return;
    }
    const {template, subject} = resolveCampaignContent(campaign, resolvedChannel);

    if (!template) {
      res.status(400).json({
        success: false,
        error: `Campaign has no template content for ${resolvedChannel}.`,
      });
      return;
    }

    // Use sample data
    const sampleVariables: Record<string, string> = {
      firstName: "Test",
      lastName: "User",
      email: resolvedChannel === "email" ? recipient : "test@example.com",
      phone: resolvedChannel === "sms" ? recipient : "+15551234567",
      appointmentDate: "Monday, January 15, 2025",
      appointmentTime: "2:00 PM",
      providerName: "Dr. Smith",
      businessName: "The Scheduler",
    };

    // Render template
    const renderedPreview = renderTemplate(template, sampleVariables);
    const messageId = `test-${campaignId}-${Date.now()}`;

    // Log test send (in production, would call actual email/SMS service)
    logger.info("Test campaign sent", {
      businessId,
      campaignId,
      channel: resolvedChannel,
      messageId,
    });

    const response: CampaignTestResponse = {
      success: true,
      messageId,
      renderedPreview,
      subject,
      channel: resolvedChannel,
    };

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logMarketingError("Error sending test campaign", error, {
      campaignId: req.body?.campaignId ?? null,
    });
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});
