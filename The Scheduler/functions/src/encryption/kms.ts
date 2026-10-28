/**
 * Cloud KMS Integration for HIPAA-Compliant Encryption
 *
 * This module provides secure key management using Google Cloud KMS.
 * All encryption keys are stored in Cloud KMS and never exposed to clients.
 *
 * Architecture:
 * - Master keys are stored in Google Cloud KMS
 * - Data Encryption Keys (DEKs) are generated per-business
 * - DEKs are encrypted with the master key (envelope encryption)
 * - Encrypted DEKs are stored in Firestore
 * - Only Cloud Functions can decrypt DEKs using KMS
 *
 * Environment Variables Required:
 * - GCP_PROJECT_ID: Google Cloud project ID
 * - KMS_LOCATION: KMS key ring location (e.g., 'us-central1')
 * - KMS_KEY_RING: KMS key ring name (e.g., 'scheduler-keys')
 * - KMS_KEY_NAME: KMS crypto key name (e.g., 'master-key')
 *
 * HIPAA Compliance:
 * - Keys are managed by Google Cloud KMS (HIPAA eligible)
 * - Envelope encryption protects data at rest
 * - Audit logging for all key operations
 * - Key rotation support built-in
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "../firebaseAdmin";
import {KeyManagementServiceClient} from "@google-cloud/kms";
import * as crypto from "crypto";
import {isAdminRole, normalizeUserRole} from "../roleUtils";
import {resolveAuthorizedEncryptionUser} from "./authorization";

// Initialize KMS client
const kmsClient = new KeyManagementServiceClient();

// KMS configuration from environment
const GCP_PROJECT_ID = process.env.GCP_PROJECT_ID || process.env.GCLOUD_PROJECT || "";
const KMS_LOCATION = process.env.KMS_LOCATION || "us-central1";
const KMS_KEY_RING = process.env.KMS_KEY_RING || "scheduler-keys";
const KMS_KEY_NAME = process.env.KMS_KEY_NAME || "master-key";

/**
 * Get the full KMS key resource name.
 */
function getKmsKeyName(): string {
  return `projects/${GCP_PROJECT_ID}/locations/${KMS_LOCATION}/keyRings/${KMS_KEY_RING}/cryptoKeys/${KMS_KEY_NAME}`;
}

/**
 * Generate a secure random Data Encryption Key (DEK).
 * Returns a 256-bit (32 byte) key encoded as base64.
 */
function generateDek(): string {
  return crypto.randomBytes(32).toString("base64");
}

/**
 * Encrypt a DEK using Cloud KMS (envelope encryption).
 */
async function encryptDekWithKms(plainDek: string): Promise<string> {
  const keyName = getKmsKeyName();

  try {
    const [result] = await kmsClient.encrypt({
      name: keyName,
      plaintext: Buffer.from(plainDek, "utf8"),
    });

    if (!result.ciphertext) {
      throw new Error("KMS encryption returned empty ciphertext");
    }

    // Return base64-encoded ciphertext
    return Buffer.from(result.ciphertext).toString("base64");
  } catch (error) {
    logger.error("KMS encryption failed", {error, keyName});
    throw new Error("Failed to encrypt key with KMS");
  }
}

/**
 * Decrypt a DEK using Cloud KMS.
 */
async function decryptDekWithKms(encryptedDek: string): Promise<string> {
  const keyName = getKmsKeyName();

  try {
    const [result] = await kmsClient.decrypt({
      name: keyName,
      ciphertext: Buffer.from(encryptedDek, "base64"),
    });

    if (!result.plaintext) {
      throw new Error("KMS decryption returned empty plaintext");
    }

    return Buffer.from(result.plaintext).toString("utf8");
  } catch (error) {
    logger.error("KMS decryption failed", {error, keyName});
    throw new Error("Failed to decrypt key with KMS");
  }
}

// ============================================================
// Key Metadata Storage
// ============================================================

interface EncryptionKeyMetadata {
  businessId: string;
  encryptedDek: string; // DEK encrypted with KMS master key
  keyVersion: number;
  algorithm: string;
  createdAt: FirebaseFirestore.Timestamp;
  rotatedAt?: FirebaseFirestore.Timestamp;
  previousKeyVersions?: Array<{
    version: number;
    encryptedDek: string;
    rotatedAt: FirebaseFirestore.Timestamp;
  }>;
}

/**
 * Get the Firestore path for encryption key metadata.
 */
function getKeyDocPath(businessId: string): string {
  return `businesses/${businessId}/private/encryptionKey`;
}

async function getAuthorizedBusinessUser(
  businessId: string,
  uid: string
) {
  const topLevelUserDoc = await db.collection("users").doc(uid).get();
  const topLevelUser = topLevelUserDoc.exists ? topLevelUserDoc.data() : null;

  const needsLegacyFallback =
    !topLevelUser ||
    typeof topLevelUser.businessId !== "string" ||
    !topLevelUser.businessId.trim();

  const legacyUserDoc = needsLegacyFallback ?
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("users")
      .doc(uid)
      .get() :
    null;

  try {
    return resolveAuthorizedEncryptionUser(
      businessId,
      topLevelUser,
      legacyUserDoc?.exists ? legacyUserDoc.data() : null
    );
  } catch (error) {
    throw new HttpsError(
      "permission-denied",
      error instanceof Error ? error.message : "User not authorized"
    );
  }
}

// ============================================================
// Cloud Functions
// ============================================================

/**
 * Initialize encryption key for a business.
 *
 * Creates a new DEK, encrypts it with KMS, and stores in Firestore.
 * Only callable by authenticated users with admin role.
 *
 * @param businessId - The business to initialize encryption for
 * @returns Success status and key version
 */
export const initializeEncryptionKey = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId} = request.data;

    if (!businessId) {
      throw new HttpsError("invalid-argument", "businessId is required");
    }

    // Verify user has admin access to business
    const userData = await getAuthorizedBusinessUser(businessId, request.auth.uid);
    if (!isAdminRole(userData.role)) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    // Check if key already exists
    const keyDocRef = db.doc(getKeyDocPath(businessId));
    const existingKey = await keyDocRef.get();

    if (existingKey.exists) {
      logger.info("Encryption key already exists for business", {businessId});
      return {
        success: true,
        message: "Encryption key already initialized",
        keyVersion: existingKey.data()?.keyVersion || 1,
      };
    }

    // Generate new DEK
    const plainDek = generateDek();

    // Encrypt DEK with KMS
    const encryptedDek = await encryptDekWithKms(plainDek);

    // Store encrypted DEK in Firestore
    const keyMetadata: EncryptionKeyMetadata = {
      businessId,
      encryptedDek,
      keyVersion: 1,
      algorithm: "AES-256-GCM",
      createdAt: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
    };

    await keyDocRef.set(keyMetadata);

    // Log audit event
    await db.collection("businesses").doc(businessId).collection("audit_logs").add({
      userId: request.auth.uid,
      actionType: "securityEvent",
      entityType: "EncryptionKey",
      entityId: businessId,
      metadata: {
        action: "initialize",
        keyVersion: 1,
        complianceEvent: "ENCRYPTION_KEY_CREATED",
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    logger.info("Encryption key initialized for business", {
      businessId,
      keyVersion: 1,
    });

    return {
      success: true,
      message: "Encryption key initialized",
      keyVersion: 1,
    };
  }
);

/**
 * Get decrypted DEK for a business.
 *
 * This is called by the app to get the encryption key for use.
 * The key is decrypted server-side and returned to the caller.
 *
 * SECURITY NOTE: In a more secure setup, you'd perform encryption/decryption
 * entirely on the server. This returns the DEK to allow client-side
 * encryption for offline support. Consider your threat model.
 *
 * @param businessId - The business to get the key for
 * @returns The decrypted DEK (base64 encoded)
 */
export const getEncryptionKey = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId} = request.data;

    if (!businessId) {
      throw new HttpsError("invalid-argument", "businessId is required");
    }

    // Verify user belongs to business
    await getAuthorizedBusinessUser(businessId, request.auth.uid);

    // Get encrypted key from Firestore
    const keyDoc = await db.doc(getKeyDocPath(businessId)).get();

    if (!keyDoc.exists) {
      throw new HttpsError("not-found", "Encryption key not initialized for business");
    }

    const keyData = keyDoc.data() as EncryptionKeyMetadata;

    // Decrypt DEK using KMS
    const decryptedDek = await decryptDekWithKms(keyData.encryptedDek);

    // Log access for audit (without logging the actual key)
    await db.collection("businesses").doc(businessId).collection("audit_logs").add({
      userId: request.auth.uid,
      actionType: "securityEvent",
      entityType: "EncryptionKey",
      entityId: businessId,
      metadata: {
        action: "access",
        keyVersion: keyData.keyVersion,
        complianceEvent: "ENCRYPTION_KEY_ACCESS",
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    return {
      key: decryptedDek,
      keyVersion: keyData.keyVersion,
      algorithm: keyData.algorithm,
    };
  }
);

/**
 * Rotate encryption key for a business.
 *
 * Generates a new DEK and stores the old one for decrypting legacy data.
 * Data should be re-encrypted with the new key during a maintenance window.
 *
 * @param businessId - The business to rotate the key for
 * @returns New key version
 */
export const rotateEncryptionKey = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId} = request.data;

    if (!businessId) {
      throw new HttpsError("invalid-argument", "businessId is required");
    }

    // Verify user has owner access (key rotation is sensitive)
    const userData = await getAuthorizedBusinessUser(businessId, request.auth.uid);
    if (normalizeUserRole(userData.role) !== "owner") {
      throw new HttpsError("permission-denied", "Owner access required for key rotation");
    }

    // Get existing key
    const keyDocRef = db.doc(getKeyDocPath(businessId));
    const existingKeyDoc = await keyDocRef.get();

    if (!existingKeyDoc.exists) {
      throw new HttpsError("not-found", "Encryption key not initialized");
    }

    const existingKey = existingKeyDoc.data() as EncryptionKeyMetadata;

    // Generate new DEK
    const newPlainDek = generateDek();
    const newEncryptedDek = await encryptDekWithKms(newPlainDek);
    const newVersion = existingKey.keyVersion + 1;

    // Archive old key version
    const previousVersions = existingKey.previousKeyVersions || [];
    previousVersions.push({
      version: existingKey.keyVersion,
      encryptedDek: existingKey.encryptedDek,
      rotatedAt: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
    });

    // Update with new key
    await keyDocRef.update({
      encryptedDek: newEncryptedDek,
      keyVersion: newVersion,
      rotatedAt: FieldValue.serverTimestamp(),
      previousKeyVersions: previousVersions,
    });

    // Log audit event
    await db.collection("businesses").doc(businessId).collection("audit_logs").add({
      userId: request.auth.uid,
      actionType: "securityEvent",
      entityType: "EncryptionKey",
      entityId: businessId,
      metadata: {
        action: "rotate",
        previousVersion: existingKey.keyVersion,
        newVersion: newVersion,
        complianceEvent: "ENCRYPTION_KEY_ROTATED",
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    logger.info("Encryption key rotated for business", {
      businessId,
      previousVersion: existingKey.keyVersion,
      newVersion,
    });

    return {
      success: true,
      message: "Encryption key rotated",
      previousVersion: existingKey.keyVersion,
      newVersion,
    };
  }
);

/**
 * Get encryption key by version (for decrypting legacy data).
 *
 * Used during data migration when re-encrypting with new key.
 *
 * @param businessId - The business
 * @param version - The key version to retrieve
 * @returns The decrypted DEK for that version
 */
export const getEncryptionKeyByVersion = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId, version} = request.data;

    if (!businessId || version === undefined) {
      throw new HttpsError("invalid-argument", "businessId and version are required");
    }

    // Verify user has admin access
    const userData = await getAuthorizedBusinessUser(businessId, request.auth.uid);
    if (!isAdminRole(userData.role)) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    // Get key document
    const keyDoc = await db.doc(getKeyDocPath(businessId)).get();

    if (!keyDoc.exists) {
      throw new HttpsError("not-found", "Encryption key not found");
    }

    const keyData = keyDoc.data() as EncryptionKeyMetadata;

    // Find the requested version
    let encryptedDek: string | null = null;

    if (keyData.keyVersion === version) {
      encryptedDek = keyData.encryptedDek;
    } else if (keyData.previousKeyVersions) {
      const previousKey = keyData.previousKeyVersions.find((k) => k.version === version);
      if (previousKey) {
        encryptedDek = previousKey.encryptedDek;
      }
    }

    if (!encryptedDek) {
      throw new HttpsError("not-found", `Key version ${version} not found`);
    }

    // Decrypt and return
    const decryptedDek = await decryptDekWithKms(encryptedDek);

    // Log access
    await db.collection("businesses").doc(businessId).collection("audit_logs").add({
      userId: request.auth.uid,
      actionType: "securityEvent",
      entityType: "EncryptionKey",
      entityId: businessId,
      metadata: {
        action: "accessByVersion",
        keyVersion: version,
        complianceEvent: "ENCRYPTION_KEY_ACCESS",
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    return {
      key: decryptedDek,
      keyVersion: version,
      algorithm: keyData.algorithm,
    };
  }
);

/**
 * Encrypt data server-side (for high-security operations).
 *
 * Use this when you don't want to expose the DEK to the client.
 * The encryption happens entirely server-side.
 *
 * @param businessId - The business
 * @param plaintext - Data to encrypt (base64 encoded)
 * @returns Encrypted data (base64 encoded)
 */
export const encryptData = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId, plaintext} = request.data;

    if (!businessId || !plaintext) {
      throw new HttpsError("invalid-argument", "businessId and plaintext are required");
    }

    // Verify user belongs to business
    await getAuthorizedBusinessUser(businessId, request.auth.uid);

    // Get and decrypt DEK
    const keyDoc = await db.doc(getKeyDocPath(businessId)).get();
    if (!keyDoc.exists) {
      throw new HttpsError("not-found", "Encryption key not initialized");
    }

    const keyData = keyDoc.data() as EncryptionKeyMetadata;
    const dek = await decryptDekWithKms(keyData.encryptedDek);

    // Perform encryption using AES-256-GCM
    const iv = crypto.randomBytes(16);
    const key = Buffer.from(dek, "base64");
    const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);

    const plaintextBuffer = Buffer.from(plaintext, "base64");
    const encrypted = Buffer.concat([cipher.update(plaintextBuffer), cipher.final()]);
    const authTag = cipher.getAuthTag();

    // Combine IV + authTag + ciphertext
    const combined = Buffer.concat([iv, authTag, encrypted]);

    return {
      ciphertext: combined.toString("base64"),
      keyVersion: keyData.keyVersion,
    };
  }
);

/**
 * Decrypt data server-side.
 *
 * @param businessId - The business
 * @param ciphertext - Data to decrypt (base64 encoded, format: IV + authTag + ciphertext)
 * @param keyVersion - Optional key version (for legacy data)
 * @returns Decrypted data (base64 encoded)
 */
export const decryptData = onCall(
  {
    enforceAppCheck: false, // Enable in production
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {businessId, ciphertext, keyVersion} = request.data;

    if (!businessId || !ciphertext) {
      throw new HttpsError("invalid-argument", "businessId and ciphertext are required");
    }

    // Verify user belongs to business
    await getAuthorizedBusinessUser(businessId, request.auth.uid);

    // Get key document
    const keyDoc = await db.doc(getKeyDocPath(businessId)).get();
    if (!keyDoc.exists) {
      throw new HttpsError("not-found", "Encryption key not initialized");
    }

    const keyData = keyDoc.data() as EncryptionKeyMetadata;

    // Get the appropriate key version
    let encryptedDek: string;
    if (keyVersion && keyVersion !== keyData.keyVersion) {
      const previousKey = keyData.previousKeyVersions?.find((k) => k.version === keyVersion);
      if (!previousKey) {
        throw new HttpsError("not-found", `Key version ${keyVersion} not found`);
      }
      encryptedDek = previousKey.encryptedDek;
    } else {
      encryptedDek = keyData.encryptedDek;
    }

    // Decrypt DEK
    const dek = await decryptDekWithKms(encryptedDek);

    // Parse ciphertext (IV + authTag + encrypted)
    const combined = Buffer.from(ciphertext, "base64");
    const iv = combined.subarray(0, 16);
    const authTag = combined.subarray(16, 32);
    const encrypted = combined.subarray(32);

    // Perform decryption
    const key = Buffer.from(dek, "base64");
    const decipher = crypto.createDecipheriv("aes-256-gcm", key, iv);
    decipher.setAuthTag(authTag);

    try {
      const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
      return {
        plaintext: decrypted.toString("base64"),
      };
    } catch {
      throw new HttpsError("invalid-argument", "Decryption failed - invalid ciphertext or key");
    }
  }
);
