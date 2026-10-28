/**
 * Cloud Functions for Workspace/Business Management
 *
 * HIPAA-compliant workspace creation and management with multi-tenant security.
 * Implements workspace creation with ULID IDs, invite codes, and public booking URLs.
 *
 * Security Features:
 * - ULID-based workspace IDs for new businesses
 * - Unique slug validation for public booking URLs
 * - Unique invite code generation (6-8 alphanumeric characters)
 * - Audit logging (no PHI)
 * - Business isolation (SecurityContext enforcement)
 * - Owner role assignment for workspace creator
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import {db, auth, FieldValue} from "./firebaseAdmin";
import {generateUlid} from "./utils/ulidGenerator";
import {CanonicalUserRole, normalizeUserRole} from "./roleUtils";
import {setCanonicalCustomClaims} from "./authClaims";

// ============================================================================
// Types & Interfaces
// ============================================================================

type UserRole = CanonicalUserRole;

/**
 * Industry types for businesses.
 * Must match mobile app enum in lib/data/models/business_industry.dart
 */
type BusinessIndustry =
  | "healthcare_medical"      // HIPAA required
  | "behavioral_health"       // HIPAA required
  | "dental_optometry"        // HIPAA required
  | "wellness"
  | "beauty_salon"
  | "fitness"
  | "real_estate"
  | "coaching"
  | "professional_services"
  | "education"
  | "other";

interface CreateWorkspaceRequest {
  businessName: string;
  ownerEmail: string;
  ownerDisplayName: string;
  industry?: BusinessIndustry;
  slug?: string; // Optional public booking URL slug
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
}

interface CreateWorkspaceResponse {
  workspaceId: string;
  businessId: string; // Same as workspaceId
  inviteCode: string;
  publicSlug: string;
  publicBookingUrl: string;
  requiresHipaaCompliance: boolean;
  mfaEnabled: boolean;
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Generate a secure random invite code (6-8 alphanumeric characters)
 * Uses same logic as staffOnboarding.ts for consistency
 */
function generateInviteCode(length = 8): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Exclude ambiguous: I, O, 0, 1
  let code = "";
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    code += chars[randomBytes[i] % chars.length];
  }
  return code;
}

/**
 * Generate a unique, URL-safe slug from business name
 */
function generateSlugFromName(businessName: string): string {
  return businessName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-") // Replace non-alphanumeric with hyphens
    .replace(/^-+|-+$/g, "") // Remove leading/trailing hyphens
    .substring(0, 50); // Limit length
}

/**
 * Check if a slug is already in use
 */
async function isSlugTaken(slug: string): Promise<boolean> {
  const snapshot = await db
    .collection("businesses")
    .where("slug", "==", slug)
    .limit(1)
    .get();

  return !snapshot.empty;
}

/**
 * Check if an invite code is already in use across all businesses
 */
async function isInviteCodeTaken(inviteCode: string): Promise<boolean> {
  const snapshot = await db
    .collection("businesses")
    .where("inviteCode", "==", inviteCode)
    .limit(1)
    .get();

  return !snapshot.empty;
}

/**
 * Generate a unique slug with fallback numbering
 */
async function generateUniqueSlug(businessName: string): Promise<string> {
  let slug = generateSlugFromName(businessName);
  let counter = 1;

  while (await isSlugTaken(slug)) {
    slug = `${generateSlugFromName(businessName)}-${counter}`;
    counter++;

    if (counter > 100) {
      throw new Error("Failed to generate unique slug after 100 attempts");
    }
  }

  return slug;
}

/**
 * Generate a unique invite code with retry logic
 */
async function generateUniqueInviteCode(): Promise<string> {
  let attempts = 0;
  const maxAttempts = 10;

  while (attempts < maxAttempts) {
    const code = generateInviteCode(8);

    if (!(await isInviteCodeTaken(code))) {
      return code;
    }

    attempts++;
  }

  throw new Error("Failed to generate unique invite code after maximum attempts");
}

/**
 * Audit logging helper
 */
async function logAuditEvent(
  businessId: string,
  userId: string,
  actionType: string,
  metadata: Record<string, unknown>
): Promise<void> {
  try {
    await db.collection("businesses").doc(businessId).collection("audit_logs").add({
      businessId,
      userId,
      actionType: "securityEvent",
      entityType: "workspace",
      entityId: businessId,
      timestamp: FieldValue.serverTimestamp(),
      metadata: {
        event: actionType,
        ...metadata,
      },
    });
  } catch (error) {
    logger.error("Failed to write audit log:", error);
    // Don't fail the operation if audit logging fails
  }
}

async function verifyOwnerAccess(
  request: CallableRequest,
  businessId: string
): Promise<{uid: string}> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid;
  const tokenRole = request.auth.token.role as string | undefined;
  const tokenBusinessId = request.auth.token.businessId as string | undefined;

  if (tokenBusinessId === businessId && normalizeUserRole(tokenRole) === "owner") {
    return {uid};
  }

  const userDoc = await db.doc(`users/${uid}`).get();
  const userData = userDoc.data();

  if (!userData || userData.businessId !== businessId) {
    throw new HttpsError("permission-denied", "Access denied to this business");
  }

  if (normalizeUserRole(userData.role) !== "owner") {
    throw new HttpsError("permission-denied", "Owner access required");
  }

  return {uid};
}

// ============================================================================
// Callable Functions
// ============================================================================

/**
 * Create Workspace
 *
 * Creates a new business/workspace with ULID-based ID, invite code, and public booking URL.
 * Assigns the caller as the owner and creates their user profile.
 *
 * This function is called during user registration to set up their workspace.
 *
 * @param businessName - Name of the business/workspace
 * @param ownerEmail - Email of the owner (should match authenticated user)
 * @param ownerDisplayName - Display name of the owner
 * @param industry - Industry type (optional, default: "other")
 * @param slug - Custom public booking URL slug (optional, auto-generated if not provided)
 * @param requiresHipaaCompliance - Whether HIPAA compliance is required (default: auto-detected from industry)
 * @param mfaEnabled - Whether MFA is enabled (default: auto-detected from HIPAA requirement)
 * @returns {workspaceId, businessId, inviteCode, publicSlug, publicBookingUrl, requiresHipaaCompliance, mfaEnabled}
 */
export const createWorkspace = onCall(async (request: CallableRequest) => {
  const {
    businessName,
    ownerEmail,
    ownerDisplayName,
    industry = "other",
    slug,
    requiresHipaaCompliance,
    mfaEnabled,
  } = request.data as CreateWorkspaceRequest;

  // Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const ownerUid = request.auth.uid;

  // Validate inputs
  if (!businessName || typeof businessName !== "string" || businessName.trim().length === 0) {
    throw new HttpsError("invalid-argument", "businessName is required");
  }

  if (!ownerEmail || typeof ownerEmail !== "string" || !ownerEmail.includes("@")) {
    throw new HttpsError("invalid-argument", "Valid ownerEmail is required");
  }

  if (!ownerDisplayName || typeof ownerDisplayName !== "string" || ownerDisplayName.trim().length === 0) {
    throw new HttpsError("invalid-argument", "ownerDisplayName is required");
  }

  // Verify the authenticated user's email matches the provided ownerEmail
  const authUser = await auth.getUser(ownerUid);
  if (authUser.email?.toLowerCase() !== ownerEmail.toLowerCase()) {
    throw new HttpsError("permission-denied", "Email does not match authenticated user");
  }

  // Check if user already belongs to a business (allow 'pending' to be updated)
  const existingUserDoc = await db.collection("users").doc(ownerUid).get();
  if (existingUserDoc.exists) {
    const existingData = existingUserDoc.data();
    // Allow users with 'pending' businessId to create a workspace
    if (existingData?.businessId && existingData.businessId !== "pending") {
      throw new HttpsError(
        "already-exists",
        "User already belongs to a business. Cannot create a new workspace."
      );
    }
  }

  try {
    // Generate ULID for workspace ID
    const workspaceId = generateUlid();
    const businessId = workspaceId; // workspaceId === businessId

    // Determine HIPAA compliance and MFA settings
    // HIPAA industries - must match mobile app's BusinessIndustry.hipaaIndustries
    const hipaaIndustries: BusinessIndustry[] = [
      "healthcare_medical",
      "behavioral_health",
      "dental_optometry",
    ];
    const autoRequiresHipaa = hipaaIndustries.includes(industry as BusinessIndustry);
    const finalRequiresHipaa = requiresHipaaCompliance ?? autoRequiresHipaa;
    const finalMfaEnabled = mfaEnabled ?? finalRequiresHipaa;

    // Generate or validate slug
    let finalSlug: string;
    if (slug) {
      // Validate custom slug
      if (!/^[a-z0-9-]+$/.test(slug)) {
        throw new HttpsError("invalid-argument", "Slug must contain only lowercase letters, numbers, and hyphens");
      }

      if (await isSlugTaken(slug)) {
        throw new HttpsError("already-exists", "This slug is already taken. Please choose another.");
      }

      finalSlug = slug;
    } else {
      // Auto-generate unique slug
      finalSlug = await generateUniqueSlug(businessName);
    }

    // Generate unique invite code
    const inviteCode = await generateUniqueInviteCode();

    // Build public booking URL
    const publicBookingUrl = `https://app.example.com/book/${finalSlug}`;

    // Create business document
    const businessData = {
      id: businessId,
      name: businessName.trim(),
      slug: finalSlug,
      inviteCode,
      publicBookingUrl,
      ownerUid,
      contactEmail: ownerEmail.toLowerCase(),
      industry,
      requiresHipaaCompliance: finalRequiresHipaa,
      mfaEnabled: finalMfaEnabled,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      isActive: true,
    };

    await db.collection("businesses").doc(businessId).set(businessData);

    // Seed subscription placeholder so billing gate starts in a known state
    const subscriptionRef = db.doc(`businesses/${businessId}/subscriptions/current`);
    await subscriptionRef.set(
      {
        status: "incomplete",
        planId: null,
        seats: 0,
        addOnIds: [],
        currentPeriodStart: null,
        currentPeriodEnd: null,
        cancelAtPeriodEnd: false,
        usage: {},
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    // Create owner user profile
    const userProfileData = {
      businessId,
      role: "owner" as UserRole,
      email: ownerEmail.toLowerCase(),
      displayName: ownerDisplayName.trim(),
      createdAt: FieldValue.serverTimestamp(),
      emailVerified: authUser.emailVerified || false,
    };

    await db.collection("users").doc(ownerUid).set(userProfileData, {merge: true});

    // Set auth claims so downstream rules can rely on token values
    try {
      await setCanonicalCustomClaims(ownerUid, {
        businessId,
        role: "owner",
      });
    } catch (claimError) {
      logger.warn("Failed to set custom claims for owner", claimError);
    }

    // Audit log
    await logAuditEvent(businessId, ownerUid, "workspaceCreated", {
      businessName: businessName.trim(),
      slug: finalSlug,
      industry,
      requiresHipaaCompliance: finalRequiresHipaa,
      mfaEnabled: finalMfaEnabled,
    });

    logger.info("Workspace created successfully", {
      businessId,
      ownerUid,
      slug: finalSlug,
      industry,
    });

    const response: CreateWorkspaceResponse = {
      workspaceId,
      businessId,
      inviteCode,
      publicSlug: finalSlug,
      publicBookingUrl,
      requiresHipaaCompliance: finalRequiresHipaa,
      mfaEnabled: finalMfaEnabled,
    };

    return response;
  } catch (error: unknown) {
    logger.error("Failed to create workspace:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    const errorMessage = error instanceof Error ? error.message : "Internal server error";
    throw new HttpsError("internal", `Failed to create workspace: ${errorMessage}`);
  }
});

/**
 * Lookup Business By Slug
 *
 * Looks up a business by its public booking slug.
 * Used by the client portal to find the correct business to authenticate against.
 *
 * @param slug - The public booking slug (e.g., "my-therapy-practice")
 * @returns {found: boolean, businessId?: string, businessName?: string}
 */
export const lookupBusinessBySlug = onCall(async (request: CallableRequest) => {
  const {slug} = request.data;

  if (!slug || typeof slug !== "string") {
    throw new HttpsError("invalid-argument", "slug is required");
  }

  try {
    const normalizedSlug = slug.toLowerCase().trim();
    const snapshot = await db
      .collection("businesses")
      .where("slug", "==", normalizedSlug)
      .where("isActive", "==", true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return {found: false};
    }

    const businessDoc = snapshot.docs[0];
    const businessData = businessDoc.data();

    return {
      found: true,
      businessId: businessDoc.id,
      businessName: businessData.name,
    };
  } catch (error) {
    logger.error("Failed to lookup business by slug:", error);
    throw new HttpsError("internal", "Failed to lookup business");
  }
});

/**
 * Validate Invite Code
 *
 * Validates that an invite code exists and is valid (not used by another business).
 * Used by the join flow to check if a code is valid before creating an account.
 * Returns HIPAA/MFA requirements so the client can enforce MFA enrollment at registration.
 *
 * @param inviteCode - The invite code to validate
 * @returns {valid: boolean, businessId?: string, businessName?: string,
 * requiresHipaaCompliance?: boolean, mfaEnabled?: boolean}
 */
export const validateInviteCode = onCall(async (request: CallableRequest) => {
  const {inviteCode} = request.data;

  if (!inviteCode || typeof inviteCode !== "string") {
    throw new HttpsError("invalid-argument", "inviteCode is required");
  }

  try {
    const snapshot = await db
      .collection("businesses")
      .where("inviteCode", "==", inviteCode.toUpperCase())
      .limit(1)
      .get();

    if (snapshot.empty) {
      return {valid: false};
    }

    const businessDoc = snapshot.docs[0];
    const businessData = businessDoc.data();

    return {
      valid: true,
      businessId: businessDoc.id,
      businessName: businessData.name,
      requiresHipaaCompliance: businessData.requiresHipaaCompliance ?? false,
      mfaEnabled: businessData.mfaEnabled ?? false,
    };
  } catch (error) {
    logger.error("Failed to validate invite code:", error);
    throw new HttpsError("internal", "Failed to validate invite code");
  }
});

/**
 * Request a workspace data export.
 *
 * Creates a queued export job in the shared exportJobs collection so the
 * existing HTTP export handler or a background worker can fulfill it.
 */
export const requestDataExport = onCall(async (request: CallableRequest) => {
  const {businessId, format = "csv", scope = "full"} = request.data as {
    businessId?: string;
    format?: string;
    scope?: string;
  };

  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  const {uid} = await verifyOwnerAccess(request, businessId);
  const businessDoc = await db.doc(`businesses/${businessId}`).get();

  if (!businessDoc.exists) {
    throw new HttpsError("not-found", "Business not found");
  }

  const normalizedFormat = typeof format === "string" && format.trim() ? format.trim().toLowerCase() : "csv";
  const normalizedScope = typeof scope === "string" && scope.trim() ? scope.trim().toLowerCase() : "full";
  const exportId = crypto.randomUUID();

  await db.doc(`businesses/${businessId}/exportJobs/${exportId}`).set({
    businessId,
    requestedBy: uid,
    status: "queued",
    format: normalizedFormat,
    scope: normalizedScope,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  await logAuditEvent(businessId, uid, "dataExportRequested", {
    exportId,
    format: normalizedFormat,
    scope: normalizedScope,
  });

  return {
    success: true,
    exportId,
    status: "queued",
    format: normalizedFormat,
    scope: normalizedScope,
  };
});

/**
 * Initiate a workspace deletion request.
 *
 * Marks the business for deletion and records a queued deletion request so
 * downstream cleanup can be handled asynchronously.
 */
export const initiateBusinessDeletion = onCall(async (request: CallableRequest) => {
  const {businessId, reason} = request.data as {
    businessId?: string;
    reason?: string;
  };

  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  const {uid} = await verifyOwnerAccess(request, businessId);
  const businessRef = db.doc(`businesses/${businessId}`);
  const businessDoc = await businessRef.get();

  if (!businessDoc.exists) {
    throw new HttpsError("not-found", "Business not found");
  }

  const businessData = businessDoc.data() ?? {};
  if ((businessData.deletionStatus === "requested" || businessData.deletionStatus === "pending") &&
      typeof businessData.deletionRequestId === "string") {
    return {
      success: true,
      deletionRequestId: businessData.deletionRequestId,
      status: businessData.deletionStatus,
      alreadyRequested: true,
    };
  }

  const deletionRequestId = crypto.randomUUID();
  const deletionRequestRef = db.doc(`businesses/${businessId}/workspaceDeletionRequests/${deletionRequestId}`);

  await db.runTransaction(async (transaction) => {
    transaction.set(deletionRequestRef, {
      businessId,
      requestedBy: uid,
      status: "requested",
      reason: typeof reason === "string" && reason.trim() ? reason.trim() : null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.set(
      businessRef,
      {
        deletionStatus: "requested",
        deletionRequestId,
        deletionRequestedAt: FieldValue.serverTimestamp(),
        deletionRequestedBy: uid,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  });

  await logAuditEvent(businessId, uid, "workspaceDeletionRequested", {
    deletionRequestId,
    hasReason: Boolean(typeof reason === "string" && reason.trim()),
  });

  return {
    success: true,
    deletionRequestId,
    status: "requested",
  };
});
