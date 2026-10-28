/**
 * OAuth Token Management for Accounting Integrations
 *
 * Handles OAuth 2.0 token exchange, refresh, and revocation for
 * QuickBooks Online and Xero.
 *
 * Environment Variables Required:
 * - QUICKBOOKS_CLIENT_ID, QUICKBOOKS_CLIENT_SECRET
 * - XERO_CLIENT_ID, XERO_CLIENT_SECRET
 * - ENCRYPTION_KEY (for encrypting tokens at rest)
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "../firebaseAdmin";
import * as crypto from "crypto";
import {isAdminRole, normalizeUserRole} from "../roleUtils";

// Environment configuration
const config = {
  quickbooks: {
    clientId: process.env.QUICKBOOKS_CLIENT_ID ?? "",
    clientSecret: process.env.QUICKBOOKS_CLIENT_SECRET ?? "",
    tokenUrl: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer",
    revokeUrl: "https://developer.api.intuit.com/v2/oauth2/tokens/revoke",
    userInfoUrl: "https://accounts.platform.intuit.com/v1/openid_connect/userinfo",
  },
  xero: {
    clientId: process.env.XERO_CLIENT_ID ?? "",
    clientSecret: process.env.XERO_CLIENT_SECRET ?? "",
    tokenUrl: "https://identity.xero.com/connect/token",
    revokeUrl: "https://identity.xero.com/connect/revocation",
    connectionsUrl: "https://api.xero.com/connections",
  },
  encryptionKey: process.env.ENCRYPTION_KEY ?? "",
};

function requireEncryptionKey(): Buffer {
  const key = config.encryptionKey;
  if (!key || key.length !== 64 || !/^[0-9a-fA-F]+$/.test(key)) {
    throw new HttpsError(
      "failed-precondition",
      "ENCRYPTION_KEY must be a 64-character hex string for token encryption"
    );
  }
  return Buffer.from(key, "hex");
}

async function requireAuthForBusiness(
  request: CallableRequest<unknown>,
  businessId: string
): Promise<string> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid as string;
  const tokenBiz = typeof request.auth.token.businessId === "string" ?
    request.auth.token.businessId :
    undefined;

  if (tokenBiz && tokenBiz !== businessId) {
    throw new HttpsError("permission-denied", "Business mismatch");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("permission-denied", "User not found");
  }
  const data = userDoc.data() ?? {};

  if (data.businessId && data.businessId !== businessId) {
    throw new HttpsError("permission-denied", "User not in this business");
  }

  const role = normalizeUserRole(request.auth.token.role) ?? normalizeUserRole(data.role);
  if (!isAdminRole(role)) {
    throw new HttpsError("permission-denied", "Insufficient permissions");
  }

  // Optional: ensure business exists
  const businessDoc = await db.collection("businesses").doc(businessId).get();
  if (!businessDoc.exists) {
    throw new HttpsError("not-found", "Business not found");
  }

  return uid;
}

// Encryption helpers for token storage
function encrypt(text: string): string {
  const key = requireEncryptionKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(
    "aes-256-cbc",
    key,
    iv
  );
  let encrypted = cipher.update(text, "utf8", "hex");
  encrypted += cipher.final("hex");
  return iv.toString("hex") + ":" + encrypted;
}

function decrypt(encrypted: string): string {
  if (!encrypted.includes(":")) {
    return encrypted;
  }
  const key = requireEncryptionKey();
  const [ivHex, encryptedText] = encrypted.split(":");
  const iv = Buffer.from(ivHex, "hex");
  const decipher = crypto.createDecipheriv(
    "aes-256-cbc",
    key,
    iv
  );
  let decrypted = decipher.update(encryptedText, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}

interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  companyId?: string;
  companyName?: string;
}

/**
 * Exchange authorization code for access tokens.
 *
 * Called after user completes OAuth flow and redirects back with auth code.
 */
export const exchangeAccountingOAuthCode = onCall(async (request) => {
  const {provider, code, redirectUri, businessId} = request.data;

  if (!provider || !code || !redirectUri || !businessId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: provider, code, redirectUri, businessId"
    );
  }

  // Validate provider
  if (provider !== "quickbooks" && provider !== "xero") {
    throw new HttpsError("invalid-argument", `Invalid provider: ${provider}`);
  }

  try {
    await requireAuthForBusiness(request, businessId);
    requireEncryptionKey();

    const providerConfig = config[provider as keyof typeof config] as {
      clientId: string;
      clientSecret: string;
      tokenUrl: string;
    };

    if (!providerConfig.clientId || !providerConfig.clientSecret) {
      throw new HttpsError(
        "failed-precondition",
        `${provider} credentials not configured`
      );
    }

    // Exchange code for tokens
    const tokenResponse = await fetch(providerConfig.tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${Buffer.from(
          `${providerConfig.clientId}:${providerConfig.clientSecret}`
        ).toString("base64")}`,
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      logger.error(`Token exchange failed for ${provider}:`, errorText);
      throw new HttpsError(
        "internal",
        `Token exchange failed: ${tokenResponse.status}`
      );
    }

    const tokens = await tokenResponse.json();
    const expiresAt = new Date(
      Date.now() + (tokens.expires_in || 3600) * 1000
    ).toISOString();

    // Get company info for QuickBooks
    let companyId = "";
    let companyName: string | undefined;

    if (provider === "quickbooks") {
      // QuickBooks returns realmId in the callback URL, but we can also get it from userinfo
      // The realmId should be passed from the client
      companyId = request.data.realmId || tokens.realmId || "";
    } else if (provider === "xero") {
      // Get Xero tenant info
      const connectionInfo = await getXeroTenantInfo(tokens.access_token);
      if (connectionInfo) {
        companyId = connectionInfo.tenantId;
        companyName = connectionInfo.tenantName;
      }
    }

    const result: TokenResponse = {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt,
      companyId,
      companyName,
    };

    // Log successful connection (without tokens)
    logger.info(`OAuth token exchange successful for ${provider}`, {
      businessId,
      provider,
      companyId,
    });

    return result;
  } catch (error) {
    logger.error(`OAuth token exchange error for ${provider}:`, error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", `Token exchange failed: ${error}`);
  }
});

/**
 * Refresh an expired access token.
 *
 * Called when access token is expired or about to expire.
 */
export const refreshAccountingOAuthToken = onCall(async (request) => {
  const {provider, refreshToken, businessId} = request.data;

  if (!provider || !refreshToken || !businessId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: provider, refreshToken, businessId"
    );
  }

  if (provider !== "quickbooks" && provider !== "xero") {
    throw new HttpsError("invalid-argument", `Invalid provider: ${provider}`);
  }

  try {
    await requireAuthForBusiness(request, businessId);
    requireEncryptionKey();

    const providerConfig = config[provider as keyof typeof config] as {
      clientId: string;
      clientSecret: string;
      tokenUrl: string;
    };

    if (!providerConfig.clientId || !providerConfig.clientSecret) {
      throw new HttpsError(
        "failed-precondition",
        `${provider} credentials not configured`
      );
    }

    // Decrypt refresh token if encrypted
    const decryptedRefreshToken = decrypt(refreshToken);

    // Refresh the token
    const tokenResponse = await fetch(providerConfig.tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${Buffer.from(
          `${providerConfig.clientId}:${providerConfig.clientSecret}`
        ).toString("base64")}`,
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: decryptedRefreshToken,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      logger.error(`Token refresh failed for ${provider}:`, errorText);

      // Check for specific error types
      if (tokenResponse.status === 401 || tokenResponse.status === 400) {
        throw new HttpsError(
          "unauthenticated",
          "Refresh token expired or revoked. Please reconnect."
        );
      }
      throw new HttpsError(
        "internal",
        `Token refresh failed: ${tokenResponse.status}`
      );
    }

    const tokens = await tokenResponse.json();
    const expiresAt = new Date(
      Date.now() + (tokens.expires_in || 3600) * 1000
    ).toISOString();

    logger.info(`OAuth token refresh successful for ${provider}`, {
      businessId,
      provider,
    });

    return {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token || refreshToken,
      expiresAt,
    };
  } catch (error) {
    logger.error(`OAuth token refresh error for ${provider}:`, error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", `Token refresh failed: ${error}`);
  }
});

/**
 * Revoke OAuth tokens when user disconnects.
 *
 * Calls provider's revoke endpoint to invalidate tokens.
 */
export const revokeAccountingOAuthToken = onCall(async (request) => {
  const {provider, accessToken, businessId} = request.data;

  if (!provider || !accessToken || !businessId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: provider, accessToken, businessId"
    );
  }

  if (provider !== "quickbooks" && provider !== "xero") {
    throw new HttpsError("invalid-argument", `Invalid provider: ${provider}`);
  }

  try {
    await requireAuthForBusiness(request, businessId);

    const providerConfig = config[provider as keyof typeof config] as {
      clientId: string;
      clientSecret: string;
      revokeUrl: string;
    };

    // Revoke the token
    const revokeResponse = await fetch(providerConfig.revokeUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${Buffer.from(
          `${providerConfig.clientId}:${providerConfig.clientSecret}`
        ).toString("base64")}`,
      },
      body: new URLSearchParams({
        token: accessToken,
      }),
    });

    // Most providers return 200 even if token is already invalid
    if (!revokeResponse.ok && revokeResponse.status !== 400) {
      logger.warn(`Token revoke returned ${revokeResponse.status} for ${provider}`);
    }

    logger.info(`OAuth token revoked for ${provider}`, {
      businessId,
      provider,
    });

    return {success: true};
  } catch (error) {
    // Don't fail if revoke fails - the user still wants to disconnect
    logger.error(`OAuth token revoke error for ${provider}:`, error);
    return {success: true, warning: "Token revocation may have failed"};
  }
});

/**
 * Get Xero tenant information from connections endpoint.
 */
async function getXeroTenantInfo(
  accessToken: string
): Promise<{tenantId: string; tenantName: string} | null> {
  try {
    const response = await fetch(config.xero.connectionsUrl, {
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      logger.error("Failed to get Xero connections:", response.status);
      return null;
    }

    const connections = await response.json();
    if (connections.length === 0) {
      logger.warn("No Xero tenants found");
      return null;
    }

    // Return the first connected tenant
    const tenant = connections[0];
    return {
      tenantId: tenant.tenantId,
      tenantName: tenant.tenantName,
    };
  } catch (error) {
    logger.error("Error getting Xero tenant info:", error);
    return null;
  }
}

// Helper to store encrypted tokens in Firestore
export async function storeEncryptedTokens(
  businessId: string,
  connectionId: string,
  accessToken: string,
  refreshToken: string
): Promise<void> {
  const encryptedAccess = encrypt(accessToken);
  const encryptedRefresh = encrypt(refreshToken);

  await db
    .collection("businesses")
    .doc(businessId)
    .collection("accountingConnections")
    .doc(connectionId)
    .update({
      accessToken: encryptedAccess,
      refreshToken: encryptedRefresh,
      updatedAt: FieldValue.serverTimestamp(),
    });
}

// Helper to retrieve and decrypt tokens
export async function getDecryptedTokens(
  businessId: string,
  connectionId: string
): Promise<{accessToken: string; refreshToken: string} | null> {
  const doc = await db
    .collection("businesses")
    .doc(businessId)
    .collection("accountingConnections")
    .doc(connectionId)
    .get();

  if (!doc.exists) {
    return null;
  }

  const data = doc.data();
  if (!data) {
    return null;
  }

  return {
    accessToken: decrypt(data.accessToken),
    refreshToken: decrypt(data.refreshToken),
  };
}
