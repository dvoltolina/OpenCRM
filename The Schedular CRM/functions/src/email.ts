import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import type { Request, Response } from 'express';
import {
  applyCors,
  authenticateRequest,
  buildAccountId,
  buildSyncedMessageId,
  buildThreadId,
  checkRateLimit,
  decodeState,
  decryptToken,
  encryptToken,
  ensureEmailFeature,
  hashIp,
  isEmailIntegrationEnabled,
  parseSyncCursor,
  providerFromUnknown,
  rateLimitKey,
  REGION,
  safeRedirect,
  sanitizeError,
  sanitizeTrackedUrl,
  sendJsonError,
  toDate,
  updateSyncCursor,
  validateOAuthState,
  writeAuditLog,
} from './email-security';
import {
  assertAccountAccess,
  exchangeAuthCode,
  loadAccount,
  persistAccount,
  refreshProviderTokens,
  syncFolder,
} from './email-data';
import { handleTrackClick, handleTrackOpen } from './email-tracking';

const SYNC_WINDOW_MS = 15 * 60 * 1000;
const EMAIL_LIMIT = 100;
const EMAIL_LIMIT_WINDOW_MS = 60 * 60 * 1000;
const SYNC_LIMIT = 20;
const SYNC_LIMIT_WINDOW_MS = 5 * 60 * 1000;
const DEFAULT_REDIRECT = process.env.EMAIL_POST_CONNECT_REDIRECT || '';

async function handleConnect(req: Request, res: Response) {
  ensureEmailFeature();
  if (req.method !== 'POST') {
    sendJsonError(res, 405, 'Method not allowed');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const limit = checkRateLimit(
    rateLimitKey('email-connect', user.businessId, user.uid),
    SYNC_LIMIT,
    SYNC_LIMIT_WINDOW_MS
  );
  if (!limit.allowed) {
    sendJsonError(res, 429, 'Connect rate limit exceeded');
    return;
  }

  try {
    const provider = providerFromUnknown(req.body?.provider);
    const authCode = String(req.body?.authCode || '').trim();
    if (!authCode) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing authorization code');
    }

    if (req.body?.state) {
      validateOAuthState(decodeState(String(req.body.state)), user.businessId, user.uid);
    }

    const tokens = await exchangeAuthCode(provider, authCode, user);
    const accountId = await persistAccount(user, provider, tokens);

    await writeAuditLog(user.businessId, user.uid, user.userName, 'integration', 'integration', accountId, {
      operation: 'connect',
      provider,
    });

    res.status(200).json({
      accountId,
      email: tokens.email,
      displayName: tokens.displayName,
      expiresAt: tokens.expiresAt.toISOString(),
      syncCursor: JSON.stringify(parseSyncCursor(undefined)),
    });
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleRefresh(req: Request, res: Response) {
  ensureEmailFeature();
  if (req.method !== 'POST') {
    sendJsonError(res, 405, 'Method not allowed');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const limit = checkRateLimit(
    rateLimitKey('email-refresh', user.businessId, user.uid),
    SYNC_LIMIT,
    SYNC_LIMIT_WINDOW_MS
  );
  if (!limit.allowed) {
    sendJsonError(res, 429, 'Refresh rate limit exceeded');
    return;
  }

  try {
    const accountId = String(req.body?.accountId || '').trim();
    if (!accountId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing accountId');
    }

    const accountRecord = await loadAccount(user.businessId, accountId);
    if (!accountRecord) {
      throw new functions.https.HttpsError('not-found', 'Account not found');
    }
    assertAccountAccess(user, accountRecord.data);

    const tokens = await refreshProviderTokens(accountRecord.data.provider, accountRecord.data.refreshToken, user);
    await accountRecord.ref.set(
      {
        accessToken: encryptToken(tokens.accessToken),
        refreshToken: encryptToken(tokens.refreshToken),
        tokenExpiresAt: tokens.expiresAt,
        syncStatus: 'synced',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await writeAuditLog(user.businessId, user.uid, user.userName, 'integration', 'integration', accountId, {
      operation: 'refresh_tokens',
      provider: accountRecord.data.provider,
    });

    res.status(200).json({ accountId, expiresAt: tokens.expiresAt.toISOString() });
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleSync(req: Request, res: Response, folder: 'inbox' | 'sent') {
  ensureEmailFeature();
  if (req.method !== 'POST') {
    sendJsonError(res, 405, 'Method not allowed');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const limit = checkRateLimit(
    rateLimitKey('email-sync', user.businessId, user.uid),
    SYNC_LIMIT,
    SYNC_LIMIT_WINDOW_MS
  );
  if (!limit.allowed) {
    sendJsonError(res, 429, 'Sync rate limit exceeded');
    return;
  }

  try {
    const accountId = String(req.body?.accountId || '').trim();
    if (!accountId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing accountId');
    }

    const accountRecord = await loadAccount(user.businessId, accountId);
    if (!accountRecord) {
      throw new functions.https.HttpsError('not-found', 'Account not found');
    }
    assertAccountAccess(user, accountRecord.data);

    const result = await syncFolder(user.businessId, accountId, folder, {
      userId: user.uid,
      userName: user.userName,
    });
    res.status(200).json(result);
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleSend(req: Request, res: Response) {
  ensureEmailFeature();
  if (req.method !== 'POST') {
    sendJsonError(res, 405, 'Method not allowed');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  const limit = checkRateLimit(
    rateLimitKey('email-send', user.businessId, user.uid),
    EMAIL_LIMIT,
    EMAIL_LIMIT_WINDOW_MS
  );
  if (!limit.allowed) {
    sendJsonError(res, 429, 'Email rate limit exceeded');
    return;
  }

  try {
    const accountId = String(req.body?.accountId || '').trim();
    const messageId = String(req.body?.messageId || '').trim();
    if (!accountId || !messageId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing accountId or messageId');
    }

    const accountRecord = await loadAccount(user.businessId, accountId);
    if (!accountRecord) {
      throw new functions.https.HttpsError('not-found', 'Account not found');
    }
    assertAccountAccess(user, accountRecord.data);

    const providerMessageId = `sent-${Date.now().toString(36)}-${messageId.slice(0, 6)}`;
    const providerThreadId = `thread-${accountId}-${messageId.slice(0, 8)}`;
    const threadId = buildThreadId(accountId, providerThreadId);
    const threadRef = admin.firestore().doc(`businesses/${user.businessId}/email_threads/${threadId}`);
    const threadSnap = await threadRef.get();

    await threadRef.set(
      {
        businessId: user.businessId,
        accountId,
        providerThreadId,
        subject: String(req.body?.subject || 'Sent Email'),
        participantEmails: [accountRecord.data.email, ...((req.body?.to as string[]) || [])].filter(Boolean),
        messageCount:
          typeof threadSnap.get('messageCount') === 'number'
            ? Math.max(1, (threadSnap.get('messageCount') as number) + 1)
            : 1,
        lastMessageAt: new Date(),
        lastMessageSnippet: String(req.body?.subject || 'Sent Email'),
        createdAt: threadSnap.exists ? threadSnap.get('createdAt') : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.firestore().doc(`businesses/${user.businessId}/email_messages/${messageId}`).set(
      {
        providerMessageId,
        threadId,
        sentAt: new Date(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await writeAuditLog(user.businessId, user.uid, user.userName, 'integration', 'activity', messageId, {
      operation: 'send_email',
      accountId,
      provider: accountRecord.data.provider,
      hasTracking: Boolean(req.body?.trackingId),
    });

    res.status(200).json({
      providerMessageId,
      threadId,
      trackingId: req.body?.trackingId || undefined,
      sentAt: new Date().toISOString(),
    });
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleDisconnect(req: Request, res: Response) {
  ensureEmailFeature();
  if (req.method !== 'POST') {
    sendJsonError(res, 405, 'Method not allowed');
    return;
  }

  const user = await authenticateRequest(req, res);
  if (!user) return;

  try {
    const accountId = String(req.body?.accountId || '').trim();
    if (!accountId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing accountId');
    }

    const accountRecord = await loadAccount(user.businessId, accountId);
    if (!accountRecord) {
      throw new functions.https.HttpsError('not-found', 'Account not found');
    }
    assertAccountAccess(user, accountRecord.data);

    await accountRecord.ref.set(
      {
        accessToken: '',
        refreshToken: '',
        syncEnabled: false,
        syncStatus: 'disconnected',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await writeAuditLog(user.businessId, user.uid, user.userName, 'integration', 'integration', accountId, {
      operation: 'disconnect',
      provider: accountRecord.data.provider,
    });

    res.status(200).json({ success: true, accountId });
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleOAuthCallback(req: Request, res: Response, provider: 'gmail' | 'outlook') {
  ensureEmailFeature();
  try {
    const code = String(req.query.code || '').trim();
    const state = decodeState(String(req.query.state || ''));
    validateOAuthState(state, state.businessId, state.userId);

    if (!code) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing authorization code');
    }

    const user = {
      uid: state.userId,
      businessId: state.businessId,
      role: 'staff' as const,
      userName: state.userId,
    };
    const tokens = await exchangeAuthCode(provider, code, user);
    const accountId = await persistAccount(user, provider, tokens, state.accountId);
    const redirectBase = safeRedirect(state.redirectUrl) || safeRedirect(DEFAULT_REDIRECT);

    if (!redirectBase) {
      res.status(200).json({ status: 'success', provider, accountId });
      return;
    }

    const redirect = new URL(redirectBase);
    redirect.searchParams.set('status', 'success');
    redirect.searchParams.set('provider', provider);
    redirect.searchParams.set('accountId', accountId);
    res.redirect(302, redirect.toString());
  } catch (error) {
    const redirectBase = safeRedirect(DEFAULT_REDIRECT);
    if (redirectBase) {
      const redirect = new URL(redirectBase);
      redirect.searchParams.set('status', 'error');
      redirect.searchParams.set('provider', provider);
      redirect.searchParams.set('error', sanitizeError(error));
      res.redirect(302, redirect.toString());
      return;
    }

    sendJsonError(res, 400, sanitizeError(error));
  }
}

async function handleWebhook(req: Request, res: Response, provider: 'gmail' | 'outlook') {
  ensureEmailFeature();

  if (provider === 'outlook' && typeof req.query.validationToken === 'string') {
    res.status(200).send(req.query.validationToken);
    return;
  }

  try {
    const accountId = String(req.query.accountId || req.body?.accountId || '').trim();
    const businessId = String(req.query.businessId || req.body?.businessId || '').trim();
    if (!accountId || !businessId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing accountId or businessId');
    }

    const configuredSecret =
      provider === 'gmail'
        ? process.env.EMAIL_GMAIL_WEBHOOK_SECRET
        : process.env.EMAIL_OUTLOOK_WEBHOOK_SECRET;
    const receivedSecret = String(
      req.headers['x-goog-channel-token'] || req.body?.value?.[0]?.clientState || req.query.token || ''
    ).trim();

    if (configuredSecret && configuredSecret !== receivedSecret) {
      throw new functions.https.HttpsError('permission-denied', 'Webhook secret mismatch');
    }

    const result = await syncFolder(businessId, accountId, 'inbox', {
      userId: 'system-email-webhook',
      userName: 'System Email Webhook',
    });

    await writeAuditLog(
      businessId,
      'system-email-webhook',
      'System Email Webhook',
      'webhook',
      'integration',
      accountId,
      {
        provider,
        created: result.created,
        updated: result.updated,
      }
    );

    res.status(202).json({ accepted: true, ...result });
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}

export const connectEmailAccount = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleConnect(req, res);
});

export const refreshEmailTokens = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleRefresh(req, res);
});

export const syncEmailInbox = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleSync(req, res, 'inbox');
});

export const syncEmailSent = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleSync(req, res, 'sent');
});

export const sendIntegratedEmail = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleSend(req, res);
});

export const disconnectEmailAccount = functions.region(REGION).https.onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  await handleDisconnect(req, res);
});

export const gmailOAuthCallback = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleOAuthCallback(req, res, 'gmail');
});

export const outlookOAuthCallback = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleOAuthCallback(req, res, 'outlook');
});

export const gmailWebhook = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleWebhook(req, res, 'gmail');
});

export const outlookWebhook = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleWebhook(req, res, 'outlook');
});

export const trackEmailOpen = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleTrackOpen(req, res);
});

export const trackEmailClick = functions.region(REGION).https.onRequest(async (req, res) => {
  await handleTrackClick(req, res);
});

export const scheduledEmailSync = functions.region(REGION).pubsub.schedule('every 15 minutes').onRun(async () => {
  if (!isEmailIntegrationEnabled()) return null;

  const dueAccounts = await admin.firestore().collectionGroup('email_accounts').where('syncEnabled', '==', true).get();
  let processed = 0;

  for (const doc of dueAccounts.docs) {
    const account = doc.data() as {
      businessId?: string;
      syncStatus?: string;
      syncOutbound?: boolean;
      lastSyncAt?: FirebaseFirestore.Timestamp | Date;
    };
    const businessId = String(account.businessId || doc.ref.parent.parent?.id || '');
    const lastSyncAt = toDate(account.lastSyncAt);
    if (!businessId || account.syncStatus === 'disconnected') continue;
    if (lastSyncAt && Date.now() - lastSyncAt.getTime() < SYNC_WINDOW_MS) continue;

    await syncFolder(businessId, doc.id, 'inbox', {
      userId: 'system-email-scheduler',
      userName: 'System Email Scheduler',
    });

    if (account.syncOutbound) {
      await syncFolder(businessId, doc.id, 'sent', {
        userId: 'system-email-scheduler',
        userName: 'System Email Scheduler',
      });
    }

    processed += 1;
  }

  functions.logger.info('scheduled_email_sync_complete', { processed });
  return null;
});

export const __test__ = {
  decodeState,
  validateOAuthState,
  encryptToken,
  decryptToken,
  sanitizeError,
  safeRedirect,
  sanitizeTrackedUrl,
  parseSyncCursor,
  updateSyncCursor,
  hashIp,
  buildAccountId,
  buildThreadId,
  buildSyncedMessageId,
  checkRateLimit,
};
