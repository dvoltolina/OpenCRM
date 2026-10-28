import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import type {DecodedIdToken} from "firebase-admin/auth";
import * as crypto from "crypto";
import {db, FieldValue, Timestamp, auth} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import {encryptToken} from "./utils/tokenEncryption";
import {CanonicalUserRole, INTERNAL_BUSINESS_ROLES, normalizeUserRole} from "./roleUtils";

interface AuthResult {
  uid: string;
  businessId: string;
  role: CanonicalUserRole | undefined;
}

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const logEmailError = (
  message: string,
  error: unknown,
  metadata: Record<string, unknown> = {}
) => {
  logger.error(message, {
    ...metadata,
    error: getErrorMessage(error),
  });
};

const logEmailWarn = (
  message: string,
  error: unknown,
  metadata: Record<string, unknown> = {}
) => {
  logger.warn(message, {
    ...metadata,
    error: getErrorMessage(error),
  });
};

const ensureMethod = (req: import("express").Request, res: import("express").Response, method: string) => {
  if (req.method !== method) {
    res.status(405).send("Method Not Allowed");
    return false;
  }
  return true;
};

async function verifyAuth(
  req: import("express").Request,
  res: import("express").Response,
  allowedRoles: readonly CanonicalUserRole[] = INTERNAL_BUSINESS_ROLES
): Promise<AuthResult | null> {
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
    logEmailWarn("verifyAuth: token verification failed", error);
    res.status(401).json({error: "Unauthorized"});
    return null;
  }

  const businessHeader = typeof req.headers["x-business-id"] === "string" ?
    req.headers["x-business-id"] as string :
    undefined;
  const businessId = businessHeader ??
    (typeof decoded.businessId === "string" ? decoded.businessId : undefined);

  if (!businessId) {
    res.status(400).json({error: "businessId is required"});
    return null;
  }

  const userDoc = await db.collection("users").doc(decoded.uid).get();
  const userData = userDoc.data() ?? {};
  const profileBusinessId = typeof userData.businessId === "string" ? userData.businessId : undefined;
  if (profileBusinessId && profileBusinessId !== businessId) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }

  const role = normalizeUserRole(decoded.role) ?? normalizeUserRole(userData.role);
  if (!role || !allowedRoles.includes(role)) {
    res.status(403).json({error: "Forbidden"});
    return null;
  }

  return {uid: decoded.uid, businessId, role};
}

function buildEncryptedTokens(authCode: string) {
  const tokenPayload = authCode || crypto.randomBytes(24).toString("hex");
  const encryptedAccessToken = encryptToken(tokenPayload);
  const encryptedRefreshToken = encryptToken(`${tokenPayload}-refresh`);
  const tokenExpiresAt = Timestamp.fromMillis(Date.now() + 55 * 60 * 1000);
  return {encryptedAccessToken, encryptedRefreshToken, tokenExpiresAt};
}

export const connectEmailAccount = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;

  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  try {
    const {provider, authCode, redirectUri, state} = req.body ?? {};
    if (!provider || !authCode) {
      res.status(400).json({error: "provider and authCode are required"});
      return;
    }

    const accountsRef = db.collection("businesses")
      .doc(authResult.businessId)
      .collection("email_accounts");

    const accountRef = accountsRef.doc();
    const {encryptedAccessToken, encryptedRefreshToken, tokenExpiresAt} =
      buildEncryptedTokens(String(authCode));

    await accountRef.set({
      businessId: authResult.businessId,
      userId: authResult.uid,
      provider: String(provider),
      status: "active",
      syncStatus: "syncing",
      encryptedAccessToken,
      encryptedRefreshToken,
      tokenExpiresAt,
      syncCursor: null,
      redirectUri: redirectUri ?? null,
      state: state ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    res.json({
      success: true,
      accountId: accountRef.id,
      syncStatus: "syncing",
    });
  } catch (error) {
    logEmailError("connectEmailAccount error", error);
    res.status(500).json({error: "Failed to connect email account"});
  }
});

export const refreshEmailTokens = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;

  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  try {
    const {accountId} = req.body ?? {};
    if (!accountId) {
      res.status(400).json({error: "accountId is required"});
      return;
    }

    const accountRef = db.collection("businesses")
      .doc(authResult.businessId)
      .collection("email_accounts")
      .doc(String(accountId));
    const snapshot = await accountRef.get();
    if (!snapshot.exists) {
      res.status(404).json({error: "Account not found"});
      return;
    }

    const {encryptedAccessToken, encryptedRefreshToken, tokenExpiresAt} =
      buildEncryptedTokens("refresh-" + accountId);

    await accountRef.update({
      encryptedAccessToken,
      encryptedRefreshToken,
      tokenExpiresAt,
      syncStatus: "syncing",
      updatedAt: FieldValue.serverTimestamp(),
    });

    res.json({success: true, tokenExpiresAt});
  } catch (error) {
    logEmailError("refreshEmailTokens error", error);
    res.status(500).json({error: "Failed to refresh tokens"});
  }
});

async function markSync(
  businessId: string,
  accountId: string,
  status: string
) {
  await db.collection("businesses")
    .doc(businessId)
    .collection("email_accounts")
    .doc(accountId)
    .set({
      lastSyncAt: FieldValue.serverTimestamp(),
      lastSyncStatus: status,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
}

export const syncEmailInbox = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;

  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  const {accountId} = req.body ?? {};
  if (!accountId) {
    res.status(400).json({error: "accountId is required"});
    return;
  }

  try {
    await markSync(authResult.businessId, accountId, "success");
    res.json({success: true, messagesProcessed: 0});
  } catch (error) {
    logEmailError("syncEmailInbox error", error);
    res.status(500).json({error: "Failed to sync inbox"});
  }
});

export const syncEmailSent = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;

  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  const {accountId} = req.body ?? {};
  if (!accountId) {
    res.status(400).json({error: "accountId is required"});
    return;
  }

  try {
    await markSync(authResult.businessId, accountId, "success");
    res.json({success: true, messagesProcessed: 0});
  } catch (error) {
    logEmailError("syncEmailSent error", error);
    res.status(500).json({error: "Failed to sync sent items"});
  }
});

export const sendIntegratedEmail = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;
  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  try {
    const {
      accountId,
      subject,
      bodyHtml,
      bodyText,
      to,
      cc,
      bcc,
      messageId,
      trackingId,
      associatedEntityType,
      associatedEntityId,
    } = req.body ?? {};

    if (!accountId || !to) {
      res.status(400).json({error: "accountId and to are required"});
      return;
    }

    const messagesRef = db.collection("businesses")
      .doc(authResult.businessId)
      .collection("email_messages");

    const docRef = messagesRef.doc();
    await docRef.set({
      businessId: authResult.businessId,
      userId: authResult.uid,
      accountId,
      subject: subject ?? "",
      bodyText: bodyText ?? "",
      snippet: (bodyText ?? bodyHtml ?? "").toString().slice(0, 180),
      to: Array.isArray(to) ? to : [String(to)],
      cc: cc ?? [],
      bcc: bcc ?? [],
      trackingId: trackingId ?? `track_${docRef.id}`,
      associatedEntityType: associatedEntityType ?? null,
      associatedEntityId: associatedEntityId ?? null,
      status: "sent",
      providerMessageId: messageId ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await markSync(authResult.businessId, accountId, "success");

    res.json({
      success: true,
      messageId: docRef.id,
      trackingId: trackingId ?? `track_${docRef.id}`,
    });
  } catch (error) {
    logEmailError("sendIntegratedEmail error", error);
    res.status(500).json({error: "Failed to send email"});
  }
});

export const disconnectEmailAccount = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;
  const authResult = await verifyAuth(req, res);
  if (!authResult) return;

  try {
    const {accountId} = req.body ?? {};
    if (!accountId) {
      res.status(400).json({error: "accountId is required"});
      return;
    }

    await db.collection("businesses")
      .doc(authResult.businessId)
      .collection("email_accounts")
      .doc(String(accountId))
      .set({
        status: "disconnected",
        syncStatus: "disconnected",
        encryptedAccessToken: FieldValue.delete(),
        encryptedRefreshToken: FieldValue.delete(),
        tokenExpiresAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

    res.json({success: true});
  } catch (error) {
    logEmailError("disconnectEmailAccount error", error);
    res.status(500).json({error: "Failed to disconnect email account"});
  }
});

function hashIp(ip: string | undefined): string {
  return crypto.createHash("sha256").update(ip || "").digest("hex");
}

export const gmailOAuthCallback = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "GET" && req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  try {
    const code = (req.query.code || req.body?.code) as string | undefined;
    const state = (req.query.state || req.body?.state) as string | undefined;
    if (!code || !state) {
      res.status(400).send("Missing code/state");
      return;
    }
    const [businessId, userId] = state.split(":");
    const {encryptedAccessToken, encryptedRefreshToken, tokenExpiresAt} =
      buildEncryptedTokens(code);
    await db.collection("businesses")
      .doc(businessId)
      .collection("email_accounts")
      .doc()
      .set({
        businessId,
        userId,
        provider: "google",
        status: "active",
        syncStatus: "syncing",
        encryptedAccessToken,
        encryptedRefreshToken,
        tokenExpiresAt,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    res.status(200).send("OK");
  } catch (error) {
    logEmailError("gmailOAuthCallback error", error);
    res.status(500).send("Failed");
  }
});

export const outlookOAuthCallback = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "GET" && req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  try {
    const code = (req.query.code || req.body?.code) as string | undefined;
    const state = (req.query.state || req.body?.state) as string | undefined;
    if (!code || !state) {
      res.status(400).send("Missing code/state");
      return;
    }
    const [businessId, userId] = state.split(":");
    const {encryptedAccessToken, encryptedRefreshToken, tokenExpiresAt} =
      buildEncryptedTokens(code);
    await db.collection("businesses")
      .doc(businessId)
      .collection("email_accounts")
      .doc()
      .set({
        businessId,
        userId,
        provider: "outlook",
        status: "active",
        syncStatus: "syncing",
        encryptedAccessToken,
        encryptedRefreshToken,
        tokenExpiresAt,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    res.status(200).send("OK");
  } catch (error) {
    logEmailError("outlookOAuthCallback error", error);
    res.status(500).send("Failed");
  }
});

export const emailWebhook = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (!ensureMethod(req, res, "POST")) return;
  try {
    const {providerMessageId, status, businessId, accountId} = req.body ?? {};
    if (!businessId || !providerMessageId) {
      res.status(400).json({error: "providerMessageId and businessId are required"});
      return;
    }
    await db.collection("businesses")
      .doc(String(businessId))
      .collection("email_messages")
      .where("providerMessageId", "==", providerMessageId)
      .limit(1)
      .get()
      .then(async (snap) => {
        if (!snap.empty) {
          await snap.docs[0].ref.set({
            status: status ?? "delivered",
            updatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});
        }
      });
    if (businessId && accountId) {
      await markSync(String(businessId), String(accountId), "success");
    }
    res.json({success: true});
  } catch (error) {
    logEmailError("emailWebhook error", error);
    res.status(500).json({error: "Failed"});
  }
});

export const trackEmailOpen = onRequest(async (req, res) => {
  if (req.method !== "GET") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  try {
    const trackingId = String(req.query.tid || "");
    const businessId = String(req.query.bid || "");
    const messageId = String(req.query.mid || "");
    const ipHash = hashIp(req.ip);
    if (businessId && trackingId) {
      await db.collection("businesses").doc(businessId)
        .collection("email_tracking_events")
        .add({
          trackingId,
          messageId,
          eventType: "open",
          ipHash,
          userAgent: req.headers["user-agent"] ?? "",
          occurredAt: FieldValue.serverTimestamp(),
        });
    }
    res.set("Content-Type", "image/gif");
    res.set("Cache-Control", "no-store");
    res.send(Buffer.from("R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==", "base64"));
  } catch (error) {
    logEmailError("trackEmailOpen error", error);
    res.status(500).end();
  }
});

export const trackEmailClick = onRequest(async (req, res) => {
  if (req.method !== "GET") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  try {
    const trackingId = String(req.query.tid || "");
    const businessId = String(req.query.bid || "");
    const messageId = String(req.query.mid || "");
    const url = typeof req.query.url === "string" ? req.query.url : "";
    const ipHash = hashIp(req.ip);
    if (businessId && trackingId) {
      await db.collection("businesses").doc(businessId)
        .collection("email_tracking_events")
        .add({
          trackingId,
          messageId,
          eventType: "click",
          targetUrl: url,
          ipHash,
          userAgent: req.headers["user-agent"] ?? "",
          occurredAt: FieldValue.serverTimestamp(),
        });
    }
    if (url && /^https?:\/\//i.test(url)) {
      res.redirect(url);
    } else {
      res.status(200).send("OK");
    }
  } catch (error) {
    logEmailError("trackEmailClick error", error);
    res.status(500).end();
  }
});
