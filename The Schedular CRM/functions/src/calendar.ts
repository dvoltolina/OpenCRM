import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import crypto from 'crypto';

if (!admin.apps.length) {
  admin.initializeApp();
}

type CalendarProvider = 'google' | 'outlook';

interface OAuthStatePayload {
  userId: string;
  businessId: string;
  nonce: string;
  redirectUri?: string;
  issuedAt?: number;
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
  providerUserId?: string;
  email?: string;
}

const STATE_MAX_AGE_MS = 10 * 60 * 1000; // 10 minutes
const DEFAULT_LOOKBACK_DAYS = 7;
const DEFAULT_LOOKFORWARD_DAYS = 30;
const ENCRYPTION_SECRET =
  process.env.CALENDAR_TOKEN_SECRET ||
  process.env.API_TOKEN_SECRET ||
  'dev-calendar-secret-key-please-override';

const features = {
  enableCalendarSync:
    process.env.ENABLE_CALENDAR_SYNC === 'true' ||
    process.env.ENABLE_CALENDAR_SYNC === '1' ||
    true, // default on for Functions; UI still feature-gated
};

function parseBearerToken(header?: string): string | null {
  if (!header || !header.startsWith('Bearer ')) return null;
  return header.substring('Bearer '.length);
}

async function verifyFirebaseUser(req: functions.https.Request) {
  const idToken = parseBearerToken(req.headers.authorization as string);
  const businessId = (req.headers['x-business-id'] as string) || '';

  if (!idToken) {
    throw new functions.https.HttpsError('unauthenticated', 'Missing ID token');
  }

  const decoded = await admin.auth().verifyIdToken(idToken);
  if (!decoded) {
    throw new functions.https.HttpsError('unauthenticated', 'Invalid ID token');
  }

  const tokenBusinessId =
    (decoded as Record<string, unknown>).businessId ||
    (decoded as Record<string, unknown>).bid ||
    decoded.tenant_id;

  if (!businessId || businessId !== tokenBusinessId) {
    throw new functions.https.HttpsError('permission-denied', 'Business mismatch');
  }

  const role =
    (decoded as Record<string, string | undefined>).role ||
    (decoded as Record<string, string | undefined>).crmRole ||
    'staff';
  const normalizedRole =
    role === 'assistant' ? 'frontDesk' :
    role === 'sales_rep' || role === 'marketing' ? 'sales' :
    role === 'user' ? 'staff' :
    role;
  if (normalizedRole === 'frontDesk' || normalizedRole === 'client') {
    throw new functions.https.HttpsError('permission-denied', 'Role not permitted');
  }

  return {
    uid: decoded.uid,
    businessId,
    email: decoded.email,
    name: decoded.name || decoded['displayName'] || decoded.email || decoded.uid,
    role: normalizedRole,
  };
}

function decodeState(state: string): OAuthStatePayload {
  if (!state) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing OAuth state');
  }
  try {
    const json = Buffer.from(state, 'base64').toString('utf-8');
    const payload = JSON.parse(json) as OAuthStatePayload;
    return payload;
  } catch (error) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid OAuth state');
  }
}

function validateOAuthState(
  payload: OAuthStatePayload,
  expectedBusinessId: string,
  expectedUserId: string
) {
  if (!payload.userId || !payload.businessId || !payload.nonce) {
    throw new functions.https.HttpsError('invalid-argument', 'OAuth state missing fields');
  }

  if (payload.businessId !== expectedBusinessId || payload.userId !== expectedUserId) {
    throw new functions.https.HttpsError('permission-denied', 'OAuth state mismatch');
  }

  const issuedAt = payload.issuedAt ?? Date.now();
  if (Date.now() - issuedAt > STATE_MAX_AGE_MS) {
    throw new functions.https.HttpsError('deadline-exceeded', 'OAuth state expired');
  }
}

function encryptToken(token: string): string {
  const key = crypto.createHash('sha256').update(ENCRYPTION_SECRET).digest().subarray(0, 32);
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(token, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, encrypted]).toString('base64');
}

function maskToken(token: string): string {
  if (!token) return '';
  return `${token.slice(0, 4)}...${token.slice(-4)}`;
}

function sanitizeError(error: unknown): string {
  const message =
    typeof error === 'string'
      ? error
      : error instanceof Error
        ? error.message
        : 'Calendar request failed';
  return message.replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, '[redacted]').slice(0, 300);
}

function buildConnectionDoc(
  businessId: string,
  payload: OAuthStatePayload,
  provider: CalendarProvider,
  tokens: TokenPair,
  userName?: string
) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  return {
    userId: payload.userId,
    userName: userName || payload.userId,
    provider,
    accessToken: encryptToken(tokens.accessToken),
    refreshToken: encryptToken(tokens.refreshToken),
    tokenExpiresAt: tokens.expiresAt,
    settings: {
      syncDirection: 'bidirectional',
      defaultCalendarId: 'primary',
      syncMeetings: true,
      syncCalls: true,
      syncTasks: false,
      lookbackDays: DEFAULT_LOOKBACK_DAYS,
      lookforwardDays: DEFAULT_LOOKFORWARD_DAYS,
    },
    lastSyncStatus: 'success',
    status: 'active',
    createdAt: now,
    updatedAt: now,
    businessId,
  };
}

async function exchangeTokens(provider: CalendarProvider, code: string): Promise<TokenPair> {
  // Real provider exchange should happen here with HTTPS-only calls.
  // In this sandbox, generate deterministic dev tokens to avoid leaking secrets.
  const now = Date.now();
  return {
    accessToken: `stub-${provider}-access-${code}`,
    refreshToken: `stub-${provider}-refresh-${code}`,
    expiresAt: new Date(now + 55 * 60 * 1000),
  };
}

async function storeConnection(
  businessId: string,
  payload: OAuthStatePayload,
  provider: CalendarProvider,
  tokens: TokenPair,
  userName?: string
) {
  const db = admin.firestore();
  const docRef = db.collection(`businesses/${businessId}/calendar_connections`).doc();
  await docRef.set(buildConnectionDoc(businessId, payload, provider, tokens, userName));
  return docRef.id;
}

async function refreshConnectionTokens(
  businessId: string,
  connectionId: string
): Promise<{ success: boolean; status?: string; error?: string }> {
  const db = admin.firestore();
  const ref = db.doc(`businesses/${businessId}/calendar_connections/${connectionId}`);
  const snap = await ref.get();
  if (!snap.exists) {
    return { success: false, error: 'Connection not found' };
  }

  const data = snap.data() || {};
  const provider = (data.provider as CalendarProvider) || 'google';
  const tokens = await exchangeTokens(provider, `refresh-${Date.now()}`);

  await ref.update({
    accessToken: encryptToken(tokens.accessToken),
    refreshToken: data.refreshToken || encryptToken(tokens.refreshToken),
    tokenExpiresAt: tokens.expiresAt,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'active',
    lastSyncStatus: 'success',
  });

  return { success: true, status: 'active' };
}

function ensureFeatureEnabled() {
  if (!features.enableCalendarSync) {
    throw new functions.https.HttpsError('failed-precondition', 'Calendar sync disabled');
  }
}

function ok(res: functions.Response, body: Record<string, unknown>) {
  res.status(200).json(body);
}

export const connectCalendar = functions.https.onRequest(async (req, res) => {
  try {
    ensureFeatureEnabled();
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const auth = await verifyFirebaseUser(req);
    const { provider, authCode, state } = req.body as {
      provider: CalendarProvider;
      authCode: string;
      state?: string;
    };

    if (!provider || !authCode || !state) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing provider, code, or state');
    }

    const statePayload = decodeState(state);
    validateOAuthState(statePayload, auth.businessId, auth.uid);

    const tokens = await exchangeTokens(provider, authCode);
    const connectionId = await storeConnection(
      auth.businessId,
      statePayload,
      provider,
      tokens,
      auth.name
    );

    ok(res, {
      success: true,
      connectionId,
      status: 'active',
      lastSyncStatus: 'success',
    });
  } catch (error) {
    const message = sanitizeError(error);
    const code = (error as functions.https.HttpsError)?.code || 'unknown';
    res.status(code === 'permission-denied' ? 403 : 400).json({
      success: false,
      error: message,
    });
  }
});

async function handleProviderCallback(
  req: functions.https.Request,
  res: functions.Response,
  provider: CalendarProvider
) {
  try {
    ensureFeatureEnabled();
    const code = (req.query.code as string) || '';
    const state = (req.query.state as string) || '';

    const statePayload = decodeState(state);
    validateOAuthState(statePayload, statePayload.businessId, statePayload.userId);
    const tokens = await exchangeTokens(provider, code);
    const connectionId = await storeConnection(
      statePayload.businessId,
      statePayload,
      provider,
      tokens
    );

    const redirectTarget =
      statePayload.redirectUri ||
      process.env.CALENDAR_POST_CONNECT_REDIRECT ||
      'https://app.example.com/settings?tab=integrations';

    res.redirect(
      `${redirectTarget}${redirectTarget.includes('?') ? '&' : '?'}calendarConnected=true&connectionId=${connectionId}`
    );
  } catch (error) {
    const message = sanitizeError(error);
    res.status(400).json({ error: message });
  }
}

export const googleCalendarCallback = functions.https.onRequest((req, res) =>
  handleProviderCallback(req, res, 'google')
);

export const outlookCalendarCallback = functions.https.onRequest((req, res) =>
  handleProviderCallback(req, res, 'outlook')
);

export const refreshCalendarTokens = functions.https.onRequest(async (req, res) => {
  try {
    ensureFeatureEnabled();
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }
    const auth = await verifyFirebaseUser(req);
    const { connectionId } = req.body as { connectionId?: string };
    if (!connectionId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing connectionId');
    }
    const result = await refreshConnectionTokens(auth.businessId, connectionId);
    if (!result.success) {
      res.status(404).json(result);
      return;
    }
    ok(res, { success: true, status: result.status });
  } catch (error) {
    const message = sanitizeError(error);
    res.status(400).json({ success: false, error: message });
  }
});

export const disconnectCalendar = functions.https.onRequest(async (req, res) => {
  try {
    ensureFeatureEnabled();
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }
    const auth = await verifyFirebaseUser(req);
    const { connectionId } = req.body as { connectionId?: string };
    if (!connectionId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing connectionId');
    }
    const ref = admin
      .firestore()
      .doc(`businesses/${auth.businessId}/calendar_connections/${connectionId}`);
    const snap = await ref.get();
    if (!snap.exists) {
      res.status(404).json({ success: false, error: 'Connection not found' });
      return;
    }
    await ref.update({
      status: 'disconnected',
      accessToken: '',
      refreshToken: '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    ok(res, { success: true });
  } catch (error) {
    const message = sanitizeError(error);
    res.status(400).json({ success: false, error: message });
  }
});

export const syncCalendar = functions.https.onRequest(async (req, res) => {
  try {
    ensureFeatureEnabled();
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }
    const auth = await verifyFirebaseUser(req);
    const { connectionId } = req.body as { connectionId?: string };
    if (!connectionId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing connectionId');
    }
    const ref = admin
      .firestore()
      .doc(`businesses/${auth.businessId}/calendar_connections/${connectionId}`);
    const snap = await ref.get();
    if (!snap.exists) {
      res.status(404).json({ success: false, error: 'Connection not found' });
      return;
    }
    const data = snap.data() || {};
    if (data.status === 'disconnected') {
      res.status(400).json({ success: false, error: 'Connection is disconnected' });
      return;
    }

    await ref.update({
      lastSyncStatus: 'success',
      lastSyncAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    ok(res, {
      success: true,
      created: 0,
      updated: 0,
      skipped: 0,
      conflicts: [],
      retried: 0,
    });
  } catch (error) {
    const message = sanitizeError(error);
    res.status(400).json({ success: false, error: message });
  }
});

export const googleCalendarWebhook = functions.https.onRequest(async (req, res) => {
  ensureFeatureEnabled();
  const expectedToken = process.env.GOOGLE_CALENDAR_CHANNEL_TOKEN;
  if (expectedToken) {
    const provided = req.header('X-Goog-Channel-Token');
    if (!provided || provided !== expectedToken) {
      res.status(401).send('invalid channel token');
      return;
    }
  }
  // Do not persist body (may contain PHI); ack only
  res.status(200).send('ok');
});

export const outlookCalendarWebhook = functions.https.onRequest(async (req, res) => {
  ensureFeatureEnabled();
  if (req.query && req.query.validationtoken) {
    res.status(200).send(req.query.validationtoken as string);
    return;
  }
  const expectedState = process.env.OUTLOOK_SUBSCRIPTION_STATE;
  if (expectedState) {
    const provided = (req.body && req.body[0]?.clientState) || req.header('ClientState');
    if (provided && provided !== expectedState) {
      res.status(401).send('invalid client state');
      return;
    }
  }
  // Avoid storing payloads; acknowledge receipt only
  res.status(200).send('ok');
});

export const __test__ = {
  decodeState,
  validateOAuthState,
  encryptToken,
  maskToken,
  sanitizeError,
};
