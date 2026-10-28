/**
 * Admin Cloud Functions for The Scheduler
 *
 * HIPAA-compliant admin operations:
 * - MFA backup code verification
 * - Business ownership transfer
 * - Bulk staff invites
 *
 * Security Features:
 * - SHA-256 hashed backup codes
 * - Owner-only operations with re-verification
 * - Audit logging (no PHI)
 * - Multi-tenant isolation
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import {db, auth, FieldValue, Timestamp} from "./firebaseAdmin";
import sgMail from "@sendgrid/mail";
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

interface BackupCodeDoc {
  codeHash: string;
  usedAt: FirebaseFirestore.Timestamp | null;
  createdAt: FirebaseFirestore.Timestamp;
}

interface AuditLogEntry {
  userId: string;
  action: string;
  entityType?: string;
  entityId?: string;
  metadata: Record<string, unknown>;
  timestamp: FirebaseFirestore.FieldValue;
  ipAddress?: string;
}

interface BulkInviteInput {
  email: string;
  role: InvitableUserRole;
  name?: string;
}

interface StaffSaveInput {
  id?: string;
  firstName?: string;
  lastName?: string;
  displayName?: string;
  email?: string;
  phone?: string;
  role?: string;
  status?: string;
  serviceIds?: unknown;
  locationIds?: unknown;
  colorHex?: string;
  telehealthLink?: string;
  appAccess?: unknown;
  moduleAccess?: unknown;
}

// ============================================================================
// Utility Functions
// ============================================================================

function hashCode(code: string): string {
  return crypto.createHash("sha256").update(code.toUpperCase().replace(/-/g, "")).digest("hex");
}

function generateInviteToken(): string {
  return crypto.randomBytes(32).toString("base64url");
}

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

async function logAuditEvent(
  businessId: string,
  entry: AuditLogEntry
): Promise<void> {
  try {
    const auditRef = db.collection(`businesses/${businessId}/audit_logs`).doc();
    await auditRef.set(entry);
  } catch (err) {
    // Don't fail the operation if audit logging fails, but log the error
    logger.error("Failed to write audit log", {businessId, action: entry.action});
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

  // Check custom claims first
  const tokenRole = request.auth.token.role as string | undefined;
  const tokenBusinessId = request.auth.token.businessId as string | undefined;

  if (tokenBusinessId === businessId && tokenRole === "owner") {
    return {uid};
  }

  // Fallback: Check users collection
  const userDoc = await db.doc(`users/${uid}`).get();
  const userData = userDoc.data();

  if (!userData) {
    throw new HttpsError("permission-denied", "User not found");
  }

  if (userData.businessId !== businessId) {
    throw new HttpsError("permission-denied", "Access denied to this business");
  }

  if (normalizeUserRole(userData.role) !== "owner") {
    throw new HttpsError("permission-denied", "Owner access required");
  }

  return {uid};
}

async function verifyAdminAccess(
  request: CallableRequest,
  businessId: string
): Promise<{uid: string; role: UserRole}> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid;
  const tokenRole = request.auth.token.role as string | undefined;
  const tokenBusinessId = request.auth.token.businessId as string | undefined;
  const normalizedTokenRole = normalizeUserRole(tokenRole);

  if (
    tokenBusinessId === businessId &&
    (normalizedTokenRole === "owner" || normalizedTokenRole === "admin")
  ) {
    return {uid, role: normalizedTokenRole};
  }

  // Fallback: Check users collection
  const userDoc = await db.doc(`users/${uid}`).get();
  const userData = userDoc.data();

  if (!userData || userData.businessId !== businessId) {
    throw new HttpsError("permission-denied", "Access denied");
  }

  const normalizedUserRole = normalizeUserRole(userData.role);
  if (normalizedUserRole !== "owner" && normalizedUserRole !== "admin") {
    throw new HttpsError("permission-denied", "Admin access required");
  }

  return {uid, role: normalizedUserRole};
}

function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeStringArray(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }

  const normalized = value
    .map((entry) => normalizeString(entry))
    .filter((entry): entry is string => Boolean(entry));

  return normalized.length > 0 ? Array.from(new Set(normalized)) : undefined;
}

function buildDisplayName(input: StaffSaveInput, fallbackEmail?: string): string {
  const firstName = normalizeString(input.firstName);
  const lastName = normalizeString(input.lastName);
  const displayName = normalizeString(input.displayName);
  const fullName = [firstName, lastName].filter(Boolean).join(" ").trim();

  return fullName || displayName || fallbackEmail || "Unnamed Staff";
}

async function resolveStaffRecord(
  businessId: string,
  staffId: string | undefined,
  email?: string
): Promise<{ref: FirebaseFirestore.DocumentReference; exists: boolean; data?: FirebaseFirestore.DocumentData}> {
  const providersRef = db.collection(`businesses/${businessId}/providers`);

  if (staffId) {
    const ref = providersRef.doc(staffId);
    const snapshot = await ref.get();
    if (snapshot.exists) {
      return {ref, exists: true, data: snapshot.data()};
    }
  }

  if (email) {
    const snapshot = await providersRef.where("email", "==", email).limit(1).get();
    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      return {ref: doc.ref, exists: true, data: doc.data()};
    }
  }

  const ref = providersRef.doc(staffId || crypto.randomUUID());
  return {ref, exists: false};
}

function toCanonicalStatus(status: unknown): "active" | "inactive" {
  return normalizeString(status)?.toLowerCase() === "inactive" ? "inactive" : "active";
}

function deriveStaffOperation(exists: boolean, status: "active" | "inactive"): "create" | "update" | "deactivate" {
  if (status === "inactive") {
    return "deactivate";
  }

  return exists ? "update" : "create";
}

function currentValue<T>(value: unknown, fallback: T): T {
  return value === undefined ? fallback : (value as T);
}

/**
 * Create, update, or deactivate a staff/provider record.
 * Uses the canonical providers path and mirrors the legacy staff path so
 * existing Admin consumers stay aligned with the shared contract.
 */
export const staffSave = onCall(async (request: CallableRequest) => {
  const {businessId, staff} = request.data as {
    businessId?: string;
    staff?: StaffSaveInput;
  };

  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  if (!staff || typeof staff !== "object") {
    throw new HttpsError("invalid-argument", "staff is required");
  }

  const {uid: actorId} = await verifyAdminAccess(request, businessId);
  const normalizedEmail = normalizeString(staff.email)?.toLowerCase();
  const normalizedRole = normalizeUserRole(staff.role) ?? "staff";
  const normalizedStatus = toCanonicalStatus(staff.status);
  const displayName = buildDisplayName(staff, normalizedEmail);

  if (!normalizeString(staff.id) && !normalizedEmail && displayName === "Unnamed Staff") {
    throw new HttpsError("invalid-argument", "staff requires an id, email, or displayName");
  }

  const resolved = await resolveStaffRecord(businessId, normalizeString(staff.id), normalizedEmail);
  const now = FieldValue.serverTimestamp();
  const existingData = resolved.data ?? {};
  const providerPayload: Record<string, unknown> = {
    id: resolved.ref.id,
    businessId,
    role: normalizedRole,
    status: normalizedStatus,
    displayName,
    updatedAt: now,
    updatedBy: actorId,
  };

  const firstName = normalizeString(staff.firstName);
  const lastName = normalizeString(staff.lastName);
  const phone = normalizeString(staff.phone);
  const colorHex = normalizeString(staff.colorHex);
  const telehealthLink = normalizeString(staff.telehealthLink);
  const serviceIds = normalizeStringArray(staff.serviceIds);
  const locationIds = normalizeStringArray(staff.locationIds);

  providerPayload.firstName = firstName ?? currentValue(existingData.firstName, "");
  providerPayload.lastName = lastName ?? currentValue(existingData.lastName, "");
  if (normalizedEmail || typeof existingData.email === "string") {
    providerPayload.email = normalizedEmail ?? existingData.email;
  }
  if (phone || typeof existingData.phone === "string") {
    providerPayload.phone = phone ?? existingData.phone;
  }
  if (colorHex || typeof existingData.colorHex === "string") {
    providerPayload.colorHex = colorHex ?? existingData.colorHex;
  }
  if (telehealthLink || typeof existingData.telehealthLink === "string") {
    providerPayload.telehealthLink = telehealthLink ?? existingData.telehealthLink;
  }
  providerPayload.serviceIds = serviceIds ?? existingData.serviceIds ?? [];
  providerPayload.locationIds = locationIds ?? existingData.locationIds ?? [];
  if (staff.appAccess !== undefined) {
    providerPayload.appAccess = staff.appAccess;
  } else if (existingData.appAccess !== undefined) {
    providerPayload.appAccess = existingData.appAccess;
  }
  if (staff.moduleAccess !== undefined) {
    providerPayload.moduleAccess = staff.moduleAccess;
  } else if (existingData.moduleAccess !== undefined) {
    providerPayload.moduleAccess = existingData.moduleAccess;
  }
  if (normalizedStatus === "inactive") {
    providerPayload.deactivatedAt = now;
  } else if (existingData.deactivatedAt !== undefined) {
    providerPayload.deactivatedAt = existingData.deactivatedAt;
  }
  providerPayload.createdAt = existingData.createdAt ?? now;
  if (existingData.createdBy !== undefined) {
    providerPayload.createdBy = existingData.createdBy;
  } else {
    providerPayload.createdBy = actorId;
  }

  const legacyStaffRef = db.doc(`businesses/${businessId}/staff/${resolved.ref.id}`);
  const legacyStaffPayload: Record<string, unknown> = {
    ...providerPayload,
    source: "staffSave",
    legacyPath: true,
    lastUpdatedBy: actorId,
  };

  const batch = db.batch();
  batch.set(resolved.ref, providerPayload, {merge: true});
  batch.set(legacyStaffRef, legacyStaffPayload, {merge: true});
  await batch.commit();

  await logAuditEvent(businessId, {
    userId: actorId,
    action: "staff_saved",
    entityType: "Provider",
    entityId: resolved.ref.id,
    metadata: {
      operation: deriveStaffOperation(resolved.exists, normalizedStatus),
      role: normalizedRole,
      status: normalizedStatus,
      hasEmail: Boolean(normalizedEmail),
      hasPhone: Boolean(phone),
      hasServiceIds: Boolean(serviceIds?.length),
      hasLocationIds: Boolean(locationIds?.length),
    },
    timestamp: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    staffId: resolved.ref.id,
    operation: deriveStaffOperation(resolved.exists, normalizedStatus),
    status: normalizedStatus,
  };
});

// ============================================================================
// MFA Backup Code Verification
// ============================================================================

/**
 * Verify a backup code for MFA
 * Called when user cannot access their authenticator app
 */
export const mfaVerifyBackupCode = onCall(async (request: CallableRequest) => {
  const {code, uid} = request.data as {code?: string; uid?: string};

  if (!code || typeof code !== "string") {
    throw new HttpsError("invalid-argument", "Backup code is required");
  }

  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "User ID is required");
  }

  // Hash the provided code
  const codeHash = hashCode(code);

  // Find matching backup code
  const codesRef = db.collection(`users/${uid}/mfaBackupCodes`);
  const matchingCodes = await codesRef.where("codeHash", "==", codeHash).limit(1).get();

  if (matchingCodes.empty) {
    // Log failed attempt (NO PHI - just counts)
    logger.warn("Backup code verification failed", {uid, reason: "no_match"});

    // Get businessId for audit log
    const userDoc = await db.doc(`users/${uid}`).get();
    const businessId = userDoc.data()?.businessId;
    if (businessId) {
      await logAuditEvent(businessId, {
        userId: uid,
        action: "mfa_backup_code_failure",
        metadata: {reason: "invalid_code"},
        timestamp: FieldValue.serverTimestamp(),
      });
    }

    throw new HttpsError("invalid-argument", "Invalid backup code");
  }

  const codeDoc = matchingCodes.docs[0];
  const codeData = codeDoc.data() as BackupCodeDoc;

  // Check if already used
  if (codeData.usedAt) {
    logger.warn("Backup code already used", {uid, codeId: codeDoc.id});
    throw new HttpsError("invalid-argument", "This backup code has already been used");
  }

  // Mark code as used
  await codeDoc.ref.update({
    usedAt: Timestamp.now(),
  });

  // Get user's businessId for audit log
  const userDoc = await db.doc(`users/${uid}`).get();
  const businessId = userDoc.data()?.businessId;

  if (businessId) {
    await logAuditEvent(businessId, {
      userId: uid,
      action: "backup_code_used",
      entityType: "BackupCode",
      entityId: codeDoc.id,
      metadata: {}, // NO PHI
      timestamp: FieldValue.serverTimestamp(),
    });
  }

  // Generate a custom token to complete sign-in
  const customToken = await auth.createCustomToken(uid, {
    mfaVerified: true,
    mfaMethod: "backup_code",
  });

  logger.info("Backup code verified successfully", {uid, codeId: codeDoc.id});

  return {
    success: true,
    customToken,
    remainingCodes: await getRemainingBackupCodeCount(uid),
  };
});

async function getRemainingBackupCodeCount(uid: string): Promise<number> {
  const codesRef = db.collection(`users/${uid}/mfaBackupCodes`);
  const unusedCodes = await codesRef.where("usedAt", "==", null).get();
  return unusedCodes.size;
}

// ============================================================================
// Ownership Transfer
// ============================================================================

/**
 * Transfer business ownership to another admin
 * Only the current owner can initiate this
 */
export const ownershipTransfer = onCall(async (request: CallableRequest) => {
  const {businessId, newOwnerId} = request.data as {
    businessId?: string;
    newOwnerId?: string;
  };

  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  if (!newOwnerId || typeof newOwnerId !== "string") {
    throw new HttpsError("invalid-argument", "newOwnerId is required");
  }

  // Verify current user is the owner
  const {uid: currentOwnerId} = await verifyOwnerAccess(request, businessId);

  if (currentOwnerId === newOwnerId) {
    throw new HttpsError("invalid-argument", "Cannot transfer ownership to yourself");
  }

  // Verify new owner exists and is currently an admin in this business
  const newOwnerUserDoc = await db.doc(`users/${newOwnerId}`).get();
  const newOwnerData = newOwnerUserDoc.data();

  if (!newOwnerData) {
    throw new HttpsError("not-found", "New owner user not found");
  }

  if (newOwnerData.businessId !== businessId) {
    throw new HttpsError("invalid-argument", "New owner must belong to this business");
  }

  if (normalizeUserRole(newOwnerData.role) !== "admin") {
    throw new HttpsError("invalid-argument", "New owner must currently be an admin");
  }

  // Perform atomic transfer using batch write
  const batch = db.batch();

  // 1. Update business document
  const businessRef = db.doc(`businesses/${businessId}`);
  batch.update(businessRef, {
    ownerId: newOwnerId,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // 2. Update old owner's role to admin
  const oldOwnerUserRef = db.doc(`users/${currentOwnerId}`);
  batch.update(oldOwnerUserRef, {
    role: "admin",
    updatedAt: FieldValue.serverTimestamp(),
  });

  // 3. Update new owner's role to owner
  const newOwnerUserRef = db.doc(`users/${newOwnerId}`);
  batch.update(newOwnerUserRef, {
    role: "owner",
    updatedAt: FieldValue.serverTimestamp(),
  });

  // 4. Update workforce records under the canonical providers path and the
  //    legacy staff path so older admin surfaces do not drift from live role truth.
  const workforceRecordUpdates = [
    {
      ref: db.doc(`businesses/${businessId}/providers/${currentOwnerId}`),
      role: "admin",
    },
    {
      ref: db.doc(`businesses/${businessId}/providers/${newOwnerId}`),
      role: "owner",
    },
    {
      ref: db.doc(`businesses/${businessId}/staff/${currentOwnerId}`),
      role: "admin",
    },
    {
      ref: db.doc(`businesses/${businessId}/staff/${newOwnerId}`),
      role: "owner",
    },
  ] as const;

  for (const update of workforceRecordUpdates) {
    const workforceDoc = await update.ref.get();
    if (!workforceDoc.exists) {
      continue;
    }

    batch.update(update.ref, {
      role: update.role,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Commit the batch
  await batch.commit();

  // Update custom claims for both users
  try {
    await setCanonicalCustomClaims(currentOwnerId, {
      businessId,
      role: "admin",
    });
    await setCanonicalCustomClaims(newOwnerId, {
      businessId,
      role: "owner",
    });
  } catch (err) {
    logger.error("Failed to update custom claims", {businessId, error: err});
    // Don't fail the operation - Firestore is the source of truth
  }

  // Audit log (NO PHI - only IDs)
  await logAuditEvent(businessId, {
    userId: currentOwnerId,
    action: "ownership_transferred",
    entityType: "Business",
    entityId: businessId,
    metadata: {
      newOwnerId,
      previousOwnerId: currentOwnerId,
    },
    timestamp: FieldValue.serverTimestamp(),
  });

  logger.info("Ownership transferred", {
    businessId,
    previousOwnerId: currentOwnerId,
    newOwnerId,
  });

  return {success: true};
});

// ============================================================================
// Bulk Staff Invites
// ============================================================================

/**
 * Send bulk staff invites from CSV data
 * Only admins and owners can use this
 */
export const staffBulkInvite = onCall(async (request: CallableRequest) => {
  const {businessId, invites} = request.data as {
    businessId?: string;
    invites?: BulkInviteInput[];
  };

  if (!businessId || typeof businessId !== "string") {
    throw new HttpsError("invalid-argument", "businessId is required");
  }

  if (!invites || !Array.isArray(invites) || invites.length === 0) {
    throw new HttpsError("invalid-argument", "invites array is required");
  }

  if (invites.length > 50) {
    throw new HttpsError("invalid-argument", "Maximum 50 invites per batch");
  }

  // Verify caller has admin access
  const {uid: senderId} = await verifyAdminAccess(request, businessId);

  // Get business info for emails
  const businessDoc = await db.doc(`businesses/${businessId}`).get();
  const businessData = businessDoc.data();
  const businessName = businessData?.name || "The Scheduler";

  // Process each invite
  const results: {sent: number; failed: number; errors: Array<{email: string; error: string}>} = {
    sent: 0,
    failed: 0,
    errors: [],
  };

  const batch = db.batch();
  const emailPromises: Promise<void>[] = [];

  for (const invite of invites) {
    try {
      // Validate email
      if (!invite.email || !isValidEmail(invite.email)) {
        results.failed++;
        results.errors.push({email: invite.email || "unknown", error: "Invalid email format"});
        continue;
      }

      // Validate role (cannot invite as owner)
      const role = normalizeInvitableUserRole(invite.role);
      if (!role) {
        results.failed++;
        results.errors.push({
          email: invite.email,
          error: `Invalid role. Allowed: ${INVITABLE_USER_ROLES.join(", ")}`,
        });
        continue;
      }

      // Check if user already exists in this business
      const existingUsers = await db.collection("users")
        .where("email", "==", invite.email.toLowerCase())
        .where("businessId", "==", businessId)
        .limit(1)
        .get();

      if (!existingUsers.empty) {
        results.failed++;
        results.errors.push({email: invite.email, error: "User already exists in this business"});
        continue;
      }

      // Check for existing pending invite
      const existingInvites = await db.collection(`businesses/${businessId}/invites`)
        .where("email", "==", invite.email.toLowerCase())
        .where("status", "==", "active")
        .limit(1)
        .get();

      if (!existingInvites.empty) {
        results.failed++;
        results.errors.push({email: invite.email, error: "Invite already pending"});
        continue;
      }

      // Generate invite token
      const token = generateInviteToken();
      const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

      // Create invite document
      const inviteRef = db.collection(`businesses/${businessId}/invites`).doc();
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7); // 7 day expiration

      batch.set(inviteRef, {
        email: invite.email.toLowerCase(),
        name: invite.name || null,
        role,
        tokenHash,
        status: "active",
        createdBy: senderId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromDate(expiresAt),
      });

      // Queue email send (don't block on it)
      if (process.env.SENDGRID_API_KEY) {
        emailPromises.push(sendInviteEmail(
          invite.email,
          invite.name || invite.email,
          businessName,
          token,
          role
        ));
      }

      results.sent++;
    } catch (err) {
      results.failed++;
      results.errors.push({
        email: invite.email || "unknown",
        error: "Failed to process invite",
      });
      logger.error("Failed to process invite", {error: err});
    }
  }

  // Commit all invite documents
  await batch.commit();

  // Wait for emails (with timeout)
  try {
    await Promise.race([
      Promise.allSettled(emailPromises),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Email timeout")), 10000)),
    ]);
  } catch (err) {
    logger.warn("Some invite emails may not have been sent", {error: err});
  }

  // Audit log (NO PHI - only counts)
  await logAuditEvent(businessId, {
    userId: senderId,
    action: "bulk_invite_sent",
    metadata: {
      totalAttempted: invites.length,
      successCount: results.sent,
      failedCount: results.failed,
    },
    timestamp: FieldValue.serverTimestamp(),
  });

  logger.info("Bulk invites processed", {
    businessId,
    senderId,
    total: invites.length,
    sent: results.sent,
    failed: results.failed,
  });

  return {
    success: results.sent > 0,
    sent: results.sent,
    failed: results.failed,
    errors: results.errors.length > 0 ? results.errors : undefined,
  };
});

async function sendInviteEmail(
  email: string,
  name: string,
  businessName: string,
  token: string,
  role: string
): Promise<void> {
  if (!process.env.SENDGRID_API_KEY) {
    logger.warn("SendGrid not configured, skipping invite email");
    return;
  }

  sgMail.setApiKey(process.env.SENDGRID_API_KEY);

  const inviteUrl = `${process.env.APP_URL || "https://app.example.com"}/accept-invite?token=${token}`;

  const msg = {
    to: email,
    from: process.env.SENDGRID_FROM_EMAIL || "noreply@scheduler.example.com",
    subject: `You've been invited to join ${businessName}`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #0f172a;">You're Invited!</h2>
        <p style="color: #475569; font-size: 16px;">
          Hello ${name},
        </p>
        <p style="color: #475569; font-size: 16px;">
          You've been invited to join <strong>${businessName}</strong> as a${role === "admin" ? "n" : ""} <strong>${role}</strong>.
        </p>
        <div style="margin: 32px 0;">
          <a href="${inviteUrl}"
             style="background: #0ea5e9; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;">
            Accept Invitation
          </a>
        </div>
        <p style="color: #94a3b8; font-size: 14px;">
          This invitation will expire in 7 days.
        </p>
        <p style="color: #94a3b8; font-size: 14px;">
          If you didn't expect this invitation, you can safely ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="color: #94a3b8; font-size: 12px;">
          The Scheduler - Professional Scheduling Software
        </p>
      </div>
    `,
    text: `
      You're Invited!

      Hello ${name},

      You've been invited to join ${businessName} as a ${role}.

      Accept your invitation: ${inviteUrl}

      This invitation will expire in 7 days.

      If you didn't expect this invitation, you can safely ignore this email.

      - The Scheduler
    `,
  };

  try {
    await sgMail.send(msg);
    logger.info("Invite email sent", {role});
  } catch (err) {
    logger.error("Failed to send invite email", {error: err});
    throw err;
  }
}
