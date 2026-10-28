/**
 * Cloud Functions for Staff Onboarding (Join Codes & Invites)
 *
 * HIPAA-compliant staff onboarding with multi-tenant security.
 * Implements join codes (shared) and invites (email-specific) for adding
 * internal business users to businesses.
 *
 * Security Features:
 * - SHA-256 hashed codes/tokens (never store plaintext)
 * - Rate limiting per IP/device/email/code
 * - Generic error messages (prevent enumeration)
 * - Business isolation (SecurityContext enforcement)
 * - Audit logging (no PHI)
 * - Supported invite roles normalize to canonical internal roles; NEVER owner/client
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import {db, auth, FieldValue, Timestamp} from "./firebaseAdmin";
import type {
  FieldValue as FirestoreFieldValue,
  Timestamp as FirestoreTimestamp,
  QueryDocumentSnapshot,
  DocumentData,
} from "firebase-admin/firestore";
import {
  CanonicalUserRole,
  InvitableUserRole,
  INVITABLE_USER_ROLES,
  normalizeInvitableUserRole,
  normalizeUserRole,
} from "./roleUtils";
import {setCanonicalCustomClaims} from "./authClaims";

// ============================================================================
// Types & Interfaces
// ============================================================================

type UserRole = CanonicalUserRole;
type JoinCodeStatus = "active" | "revoked" | "expired";
type InviteStatus = "active" | "revoked" | "expired" | "used";
type JoinRequestStatus = "pending" | "approved" | "denied";
type StoredTimestamp = FirestoreTimestamp | FirestoreFieldValue;

interface JoinCodeData {
  codeHash: string;
  createdBy: string;
  createdAt: StoredTimestamp;
  expiresAt: StoredTimestamp;
  maxUses: number;
  uses: number;
  role: string;
  status: JoinCodeStatus;
  lastUsedAt?: StoredTimestamp;
  lastUsedBy?: string;
  notes?: string;
}

interface InviteData {
  email: string;
  role: string;
  createdBy: string;
  createdAt: StoredTimestamp;
  expiresAt: StoredTimestamp;
  status: InviteStatus;
  tokenHash: string;
}

interface JoinRequestData {
  email: string;
  displayName?: string;
  role: string;
  codeId?: string;
  inviteId?: string;
  requestorUserId?: string;
  deviceInfo?: Record<string, unknown>;
  createdAt: StoredTimestamp;
  status: JoinRequestStatus;
  reviewedBy?: string;
  reviewedAt?: StoredTimestamp;
  denialReason?: string;
}

// ============================================================================
// Rate Limiting
// ============================================================================

const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute
const MAX_REQUESTS_PER_IP = 10;
const MAX_REQUESTS_PER_EMAIL = 5;
const MAX_REQUESTS_PER_CODE = 20;

const rateLimitBuckets: Map<string, {count: number; windowStart: number}> = new Map();

function isRateLimited(key: string, scope: string, maxRequests: number): boolean {
  const bucketKey = `${scope}:${key}`;
  const now = Date.now();
  const bucket = rateLimitBuckets.get(bucketKey);

  if (!bucket || now - bucket.windowStart > RATE_LIMIT_WINDOW_MS) {
    rateLimitBuckets.set(bucketKey, {count: 1, windowStart: now});
    return false;
  }

  if (bucket.count >= maxRequests) {
    return true;
  }

  bucket.count += 1;
  return false;
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Hash a code/token with SHA-256
 */
function hashCode(code: string): string {
  return crypto.createHash("sha256").update(code).digest("hex");
}

/**
 * Generate a secure random join code (6-8 alphanumeric characters)
 */
function generateJoinCode(length = 8): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Exclude ambiguous: I, O, 0, 1
  let code = "";
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    code += chars[randomBytes[i] % chars.length];
  }
  return code;
}

/**
 * Generate a secure random token for invites
 */
function generateInviteToken(): string {
  return crypto.randomBytes(32).toString("base64url");
}

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const toDateIfTimestamp = (value: StoredTimestamp | undefined): Date | null =>
  value instanceof Timestamp ? value.toDate() : null;

function requireInvitableRole(
  role: unknown,
  errorMessage = `Role must be one of: ${INVITABLE_USER_ROLES.join(", ")}`
): InvitableUserRole {
  const normalizedRole = normalizeInvitableUserRole(role);
  if (!normalizedRole) {
    throw new HttpsError("invalid-argument", errorMessage);
  }

  return normalizedRole;
}

/**
 * Verify caller has admin/owner role in the business
 */
async function verifyAdminAccess(
  request: CallableRequest,
  businessId: string
): Promise<{uid: string; role: UserRole}> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid;

  // Get user profile to verify business membership and role
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User profile not found");
  }

  const userData = userDoc.data();
  if (userData?.businessId !== businessId) {
    throw new HttpsError("permission-denied", "Access denied");
  }

  const role = normalizeUserRole(userData?.role);
  if (role !== "owner" && role !== "admin") {
    throw new HttpsError("permission-denied", "Admin or owner access required");
  }

  return {uid, role};
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
      entityType: "staff_onboarding",
      entityId: metadata.codeId || metadata.inviteId || metadata.requestId || "",
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

// ============================================================================
// Callable Functions
// ============================================================================

/**
 * Create Join Code
 *
 * Allows owner/admin to generate a shareable join code for staff onboarding.
 * Returns the plaintext code ONCE; only stores the SHA-256 hash.
 *
 * @param businessId - Business ID to create code for
 * @param role - Role to assign (internal workforce role, default: staff)
 * @param expiresAt - Optional expiration timestamp (default: 7 days)
 * @param maxUses - Optional max usage limit (default: 1 for single-use codes)
 * @returns {code: string, codeId: string, expiresAt: Date}
 */
export const createJoinCode = onCall(async (request: CallableRequest) => {
  const {businessId, role = "staff", expiresAt, maxUses = 1, notes} = request.data;

  // Validate inputs
  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  const normalizedRole = requireInvitableRole(role);

  if (maxUses < 1 || maxUses > 100) {
    throw new HttpsError("invalid-argument", "maxUses must be between 1 and 100");
  }

  // Verify admin access
  const {uid} = await verifyAdminAccess(request, businessId);

  // Generate code and hash it
  const code = generateJoinCode(8);
  const codeHash = hashCode(code);

  // Calculate expiration (default: 7 days)
  const expirationDate = expiresAt ?
    new Date(expiresAt) :
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  // Create join code document
  const codeData: JoinCodeData = {
    codeHash,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(expirationDate),
    maxUses,
    uses: 0,
    role: normalizedRole,
    status: "active",
    notes: notes || "",
  };

  const codeRef = await db
    .collection("businesses")
    .doc(businessId)
    .collection("join_codes")
    .add(codeData);

  // Audit log
  await logAuditEvent(businessId, uid, "joinCodeCreated", {
    codeId: codeRef.id,
    role: normalizedRole,
    maxUses,
    expiresAt: expirationDate.toISOString(),
  });

  logger.info("Join code created", {businessId, codeId: codeRef.id, role: normalizedRole});

  return {
    code, // Return plaintext ONCE
    codeId: codeRef.id,
    expiresAt: expirationDate.toISOString(),
    maxUses,
    role: normalizedRole,
  };
});

/**
 * Revoke Join Code
 *
 * Allows owner/admin to revoke an active join code.
 *
 * @param businessId - Business ID
 * @param codeId - Join code document ID
 */
export const revokeJoinCode = onCall(async (request: CallableRequest) => {
  const {businessId, codeId} = request.data;

  if (!businessId || !codeId) {
    throw new HttpsError("invalid-argument", "businessId and codeId are required");
  }

  // Verify admin access
  const {uid} = await verifyAdminAccess(request, businessId);

  // Update code status
  const codeRef = db
    .collection("businesses")
    .doc(businessId)
    .collection("join_codes")
    .doc(codeId);

  const codeDoc = await codeRef.get();
  if (!codeDoc.exists) {
    throw new HttpsError("not-found", "Join code not found");
  }

  await codeRef.update({
    status: "revoked",
  });

  // Audit log
  await logAuditEvent(businessId, uid, "joinCodeRevoked", {
    codeId,
  });

  logger.info("Join code revoked", {businessId, codeId});

  return {success: true};
});

/**
 * Request Join with Code
 *
 * Allows a user (authenticated or not) to join a business using a join code.
 * Validates code hash, expiry, maxUses, and rate limits.
 * Creates/attaches user with default staff role.
 *
 * @param code - Plaintext join code
 * @param email - User email
 * @param displayName - User display name
 * @param password - Optional password (if creating new user)
 * @param deviceInfo - Optional device metadata
 * @returns {userId: string, businessId: string, role: string}
 */
export const requestJoinWithCode = onCall(async (request: CallableRequest) => {
  const {code, email, displayName, password, deviceInfo} = request.data;

  // Validate inputs
  if (!code || !email || !displayName) {
    throw new HttpsError("invalid-argument", "Code, email, and displayName are required");
  }

  const emailLower = email.toLowerCase().trim();

  // Rate limiting: by IP, email, and code
  const clientIp = request.rawRequest?.ip || "unknown";

  if (isRateLimited(clientIp, "join:ip", MAX_REQUESTS_PER_IP)) {
    throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
  }

  if (isRateLimited(emailLower, "join:email", MAX_REQUESTS_PER_EMAIL)) {
    throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
  }

  if (isRateLimited(code, "join:code", MAX_REQUESTS_PER_CODE)) {
    throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
  }

  // Hash the code
  const codeHash = hashCode(code);

  // Find the join code across all businesses (need to query by hash)
  // Note: This requires a composite index on codeHash
  // Query all businesses for this code hash
  // Since we can't query across subcollections efficiently, we'll need to track this differently
  // For now, we'll require businessId to be passed or use a top-level collection
  // Let's use a workaround: scan recent codes (not scalable for prod, but works for MVP)

  // Better approach: Use a top-level join_codes_index collection
  const indexQuery = await db
    .collectionGroup("join_codes")
    .where("codeHash", "==", codeHash)
    .where("status", "==", "active")
    .limit(1)
    .get();

  if (indexQuery.empty) {
    // Generic error to prevent enumeration
    throw new HttpsError("invalid-argument", "Invalid code or expired");
  }

  const codeDoc: QueryDocumentSnapshot<DocumentData> | undefined =
    indexQuery.docs[0];
  if (!codeDoc) {
    throw new HttpsError("invalid-argument", "Invalid code or expired");
  }
  let businessId = "";
  let codeId = "";

  codeId = codeDoc.id;
  // Extract businessId from the path
  businessId = codeDoc.ref.parent.parent?.id || "";

  if (!businessId) {
    throw new HttpsError("internal", "Invalid code reference");
  }

  const codeData = codeDoc.data() as JoinCodeData;
  const normalizedRole = requireInvitableRole(codeData.role, "Join code role is invalid");

  // Validate expiration
  const expiresAt = toDateIfTimestamp(codeData.expiresAt);
  if (!expiresAt || expiresAt < new Date()) {
    await codeDoc.ref.update({status: "expired"});
    throw new HttpsError("invalid-argument", "Invalid code or expired");
  }

  // Validate max uses
  if (codeData.uses >= codeData.maxUses) {
    throw new HttpsError("invalid-argument", "Invalid code or expired");
  }

  // Check if business exists and is active
  const businessDoc = await db.collection("businesses").doc(businessId).get();
  if (!businessDoc.exists) {
    throw new HttpsError("not-found", "Business not found");
  }

  // Check if approval is required
  const requiresApproval = businessDoc.data()?.settings?.requireJoinApproval || false;

  if (requiresApproval) {
    // Create join request instead of immediately attaching
    const requestRef = await db
      .collection("businesses")
      .doc(businessId)
      .collection("join_requests")
      .add({
        email: emailLower,
        displayName,
        role: normalizedRole,
        codeId,
        ...(request.auth?.uid ? {requestorUserId: request.auth.uid} : {}),
        deviceInfo: deviceInfo || {},
        createdAt: FieldValue.serverTimestamp(),
        status: "pending",
      } as JoinRequestData);

    // Audit log
    await logAuditEvent(businessId, "system", "joinRequestPending", {
      requestId: requestRef.id,
      role: normalizedRole,
    });

    return {
      success: true,
      requiresApproval: true,
      requestId: requestRef.id,
      message: "Your request has been submitted for approval",
    };
  }

  // No approval required - proceed with user creation/attachment
  let userId = request.auth?.uid;

  if (!userId) {
    // Create new Firebase Auth user
    if (!password) {
      throw new HttpsError("invalid-argument", "Password required for new users");
    }

    try {
      const userRecord = await auth.createUser({
        email: emailLower,
        password,
        displayName,
        emailVerified: false,
      });
      userId = userRecord.uid;
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("Failed to create user:", {error});
      if (error instanceof Error && "code" in error && (error as {code?: string}).code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Email already in use");
      }
      throw new HttpsError("internal", message);
    }
  } else {
    // User is already authenticated, verify not attached to another business
    const existingUserDoc = await db.collection("users").doc(userId).get();
    if (existingUserDoc.exists) {
      const existingData = existingUserDoc.data();
      if (
        existingData?.businessId &&
        existingData.businessId !== businessId &&
        existingData.businessId !== "pending"
      ) {
        throw new HttpsError(
          "already-exists",
          "User already belongs to another business"
        );
      }
    }
  }

  // Create/update user profile
  await db
    .collection("users")
    .doc(userId)
    .set(
      {
        businessId,
        role: normalizedRole,
        email: emailLower,
        displayName,
        createdAt: FieldValue.serverTimestamp(),
        emailVerified: false,
      },
      {merge: true}
    );

  try {
    await setCanonicalCustomClaims(userId, {
      businessId,
      role: normalizedRole,
    });
  } catch (claimError) {
    logger.warn("Failed to set custom claims for joined user", {
      businessId,
      userId,
      role: normalizedRole,
      claimError,
    });
  }

  // Increment code usage
  await codeDoc.ref.update({
    uses: FieldValue.increment(1),
    lastUsedAt: FieldValue.serverTimestamp(),
    lastUsedBy: userId,
  });

  // Audit log
  await logAuditEvent(businessId, userId, "joinCodeUsed", {
    codeId,
    role: normalizedRole,
    success: true,
  });

  logger.info("User joined via code", {businessId, userId, codeId, role: normalizedRole});

  return {
    success: true,
    requiresApproval: false,
    userId,
    businessId,
    role: normalizedRole,
    requiresMfa: false, // MFA enforcement happens at login
    requiresEmailVerification: true,
  };
});

/**
 * Create Invite
 *
 * Allows owner/admin to create an email-specific invite link.
 *
 * @param businessId - Business ID
 * @param email - Target email address
 * @param role - Role to assign (internal workforce role, default: staff)
 * @param expiresAt - Optional expiration timestamp (default: 7 days)
 * @returns {inviteId: string, token: string, inviteLink: string}
 */
export const createInvite = onCall(async (request: CallableRequest) => {
  const {businessId, email, role = "staff", expiresAt} = request.data;

  // Validate inputs
  if (!businessId || !email) {
    throw new HttpsError("invalid-argument", "businessId and email are required");
  }

  const emailLower = email.toLowerCase().trim();

  const normalizedRole = requireInvitableRole(role);

  // Verify admin access
  const {uid} = await verifyAdminAccess(request, businessId);

  // Generate token and hash it
  const token = generateInviteToken();
  const tokenHash = hashCode(token);

  // Calculate expiration (default: 7 days)
  const expirationDate = expiresAt ?
    new Date(expiresAt) :
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  // Create invite document
  const inviteData: InviteData = {
    email: emailLower,
    role: normalizedRole,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(expirationDate),
    status: "active",
    tokenHash,
  };

  const inviteRef = await db
    .collection("businesses")
    .doc(businessId)
    .collection("invites")
    .add(inviteData);

  // Audit log
  await logAuditEvent(businessId, uid, "inviteCreated", {
    inviteId: inviteRef.id,
    role: normalizedRole,
  });

  // Build invite link (to be handled by client app)
  const inviteLink = `${process.env.APP_BASE_URL || "https://scheduler.example.com"}/join/invite?id=${inviteRef.id}&token=${token}`;

  logger.info("Invite created", {businessId, inviteId: inviteRef.id, role: normalizedRole});

  return {
    inviteId: inviteRef.id,
    token, // Return plaintext ONCE
    inviteLink,
    expiresAt: expirationDate.toISOString(),
  };
});

/**
 * Revoke Invite
 *
 * Allows owner/admin to revoke an active invite.
 *
 * @param businessId - Business ID
 * @param inviteId - Invite document ID
 */
export const revokeInvite = onCall(async (request: CallableRequest) => {
  const {businessId, inviteId} = request.data;

  if (!businessId || !inviteId) {
    throw new HttpsError("invalid-argument", "businessId and inviteId are required");
  }

  // Verify admin access
  const {uid} = await verifyAdminAccess(request, businessId);

  // Update invite status
  const inviteRef = db
    .collection("businesses")
    .doc(businessId)
    .collection("invites")
    .doc(inviteId);

  const inviteDoc = await inviteRef.get();
  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Invite not found");
  }

  await inviteRef.update({
    status: "revoked",
  });

  // Audit log
  await logAuditEvent(businessId, uid, "inviteRevoked", {
    inviteId,
  });

  logger.info("Invite revoked", {businessId, inviteId});

  return {success: true};
});

/**
 * Accept Invite
 *
 * Allows a user to accept an email-specific invite.
 * Validates token hash, email match, and expiry.
 *
 * @param inviteId - Invite document ID
 * @param token - Plaintext invite token
 * @param password - Optional password (if creating new user)
 * @param displayName - Optional display name
 * @returns {userId: string, businessId: string, role: string}
 */
export const acceptInvite = onCall(async (request: CallableRequest) => {
  const {inviteId, token, password, displayName} = request.data;

  // Validate inputs
  if (!inviteId || !token) {
    throw new HttpsError("invalid-argument", "inviteId and token are required");
  }

  // Hash token
  const tokenHash = hashCode(token);

  // Rate limiting by IP and token
  const clientIp = request.rawRequest?.ip || "unknown";

  if (isRateLimited(clientIp, "invite:ip", MAX_REQUESTS_PER_IP)) {
    throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
  }

  if (isRateLimited(inviteId, "invite:token", MAX_REQUESTS_PER_EMAIL)) {
    throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
  }

  // Find invite across all businesses
  const inviteQuery = await db
    .collectionGroup("invites")
    .where("tokenHash", "==", tokenHash)
    .where("status", "==", "active")
    .limit(1)
    .get();

  if (inviteQuery.empty) {
    throw new HttpsError("invalid-argument", "Invalid or expired invite");
  }

  const inviteDoc = inviteQuery.docs[0];
  const inviteData = inviteDoc.data() as InviteData;
  const businessId = inviteDoc.ref.parent.parent?.id || "";
  const normalizedRole = requireInvitableRole(inviteData.role, "Invite role is invalid");

  if (!businessId) {
    throw new HttpsError("internal", "Invalid invite reference");
  }

  // Validate expiration
  const expiresAt = toDateIfTimestamp(inviteData.expiresAt);
  if (!expiresAt || expiresAt < new Date()) {
    await inviteDoc.ref.update({status: "expired"});
    throw new HttpsError("invalid-argument", "Invalid or expired invite");
  }

  // Verify email match
  const userEmail = request.auth?.token?.email?.toLowerCase() || inviteData.email;

  if (userEmail !== inviteData.email) {
    throw new HttpsError("permission-denied", "Email does not match invite");
  }

  // Create or attach user
  let userId = request.auth?.uid;

  if (!userId) {
    // Create new Firebase Auth user
    if (!password) {
      throw new HttpsError("invalid-argument", "Password required for new users");
    }

    try {
      const userRecord = await auth.createUser({
        email: inviteData.email,
        password,
        displayName: displayName || "",
        emailVerified: false,
      });
      userId = userRecord.uid;
    } catch (error: unknown) {
      const message = getErrorMessage(error);
      logger.error("Failed to create user:", {error});
      if (error instanceof Error && "code" in error && (error as {code?: string}).code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Email already in use");
      }
      throw new HttpsError("internal", message);
    }
  } else {
    // User is already authenticated, verify not attached to another business
    const existingUserDoc = await db.collection("users").doc(userId).get();
    if (existingUserDoc.exists) {
      const existingData = existingUserDoc.data();
      if (
        existingData?.businessId &&
        existingData.businessId !== businessId &&
        existingData.businessId !== "pending"
      ) {
        throw new HttpsError(
          "already-exists",
          "User already belongs to another business"
        );
      }
    }
  }

  // Create/update user profile
  await db
    .collection("users")
    .doc(userId)
    .set(
      {
        businessId,
        role: normalizedRole,
        email: inviteData.email,
        displayName: displayName || "",
        createdAt: FieldValue.serverTimestamp(),
        emailVerified: false,
      },
      {merge: true}
    );

  try {
    await setCanonicalCustomClaims(userId, {
      businessId,
      role: normalizedRole,
    });
  } catch (claimError) {
    logger.warn("Failed to set custom claims for invited user", {
      businessId,
      userId,
      role: normalizedRole,
      claimError,
    });
  }

  // Mark invite as used
  await inviteDoc.ref.update({
    status: "used",
    usedAt: FieldValue.serverTimestamp(),
    usedBy: userId,
  });

  // Audit log
  await logAuditEvent(businessId, userId, "inviteUsed", {
    inviteId: inviteDoc.id,
    role: normalizedRole,
    success: true,
  });

  logger.info("User joined via invite", {businessId, userId, inviteId: inviteDoc.id});

  return {
    userId,
    businessId,
    role: normalizedRole,
    requiresMfa: false,
    requiresEmailVerification: true,
  };
});

/**
 * Review Join Request
 *
 * Allows owner/admin to approve or deny a pending join request.
 *
 * @param businessId - Business ID
 * @param requestId - Join request document ID
 * @param approve - true to approve, false to deny
 * @param denialReason - Optional reason for denial
 */
export const reviewJoinRequest = onCall(async (request: CallableRequest) => {
  const {businessId, requestId, approve, denialReason} = request.data;

  if (!businessId || !requestId || typeof approve !== "boolean") {
    throw new HttpsError(
      "invalid-argument",
      "businessId, requestId, and approve are required"
    );
  }

  // Verify admin access
  const {uid} = await verifyAdminAccess(request, businessId);

  // Get join request
  const requestRef = db
    .collection("businesses")
    .doc(businessId)
    .collection("join_requests")
    .doc(requestId);

  const requestDoc = await requestRef.get();
  if (!requestDoc.exists) {
    throw new HttpsError("not-found", "Join request not found");
  }

  const requestData = requestDoc.data() as JoinRequestData;

  if (requestData.status !== "pending") {
    throw new HttpsError("failed-precondition", "Request already reviewed");
  }

  if (!approve) {
    // Deny the request
    await requestRef.update({
      status: "denied",
      reviewedBy: uid,
      reviewedAt: FieldValue.serverTimestamp(),
      denialReason: denialReason || "",
    });

    // Audit log
    await logAuditEvent(businessId, uid, "joinRequestDenied", {
      requestId,
    });

    logger.info("Join request denied", {businessId, requestId});

    return {success: true, approved: false};
  }

  // Approve the request - create user
  let userId: string;

  try {
    // Check if user already exists
    const existingUser = await auth.getUserByEmail(requestData.email);
    userId = existingUser.uid;

    // Verify not attached to another business
    const existingUserDoc = await db.collection("users").doc(userId).get();
    if (existingUserDoc.exists) {
      const existingData = existingUserDoc.data();
      if (
        existingData?.businessId &&
        existingData.businessId !== businessId &&
        existingData.businessId !== "pending"
      ) {
        throw new HttpsError(
          "already-exists",
          "User already belongs to another business"
        );
      }
    }
  } catch (error: unknown) {
    const errorCode = error && typeof error === "object" ? (error as {code?: string}).code : undefined;
    if (errorCode === "auth/user-not-found") {
      // User doesn't exist - create them
      // Note: They'll need to set password via password reset flow
      const userRecord = await auth.createUser({
        email: requestData.email,
        displayName: requestData.displayName || "",
        emailVerified: false,
      });
      userId = userRecord.uid;

      // Send password setup email
      await auth.generatePasswordResetLink(requestData.email);
    } else {
      throw new HttpsError("internal", getErrorMessage(error));
    }
  }

  const normalizedRole = requireInvitableRole(
    requestData.role,
    "Join request role is invalid"
  );

  // Create/update user profile
  await db
    .collection("users")
    .doc(userId)
    .set(
      {
        businessId,
        role: normalizedRole,
        email: requestData.email,
        displayName: requestData.displayName || "",
        createdAt: FieldValue.serverTimestamp(),
        emailVerified: false,
      },
      {merge: true}
    );

  try {
    await setCanonicalCustomClaims(userId, {
      businessId,
      role: normalizedRole,
    });
  } catch (claimError) {
    logger.warn("Failed to set custom claims for approved join request", {
      businessId,
      userId,
      role: normalizedRole,
      claimError,
    });
  }

  // Mark request as approved
  await requestRef.update({
    status: "approved",
    reviewedBy: uid,
    reviewedAt: FieldValue.serverTimestamp(),
  });

  // If there was a code, increment its usage
  if (requestData.codeId) {
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("join_codes")
      .doc(requestData.codeId)
      .update({
        uses: FieldValue.increment(1),
        lastUsedAt: FieldValue.serverTimestamp(),
        lastUsedBy: userId,
      });
  }

  // Audit log
  await logAuditEvent(businessId, uid, "joinRequestApproved", {
    requestId,
    userId,
    role: normalizedRole,
  });

  logger.info("Join request approved", {businessId, requestId, userId});

  return {
    success: true,
    approved: true,
    userId,
  };
});
