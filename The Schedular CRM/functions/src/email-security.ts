import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import type { Request, Response } from 'express';
import crypto from 'crypto';

if (!admin.apps.length) {
  admin.initializeApp();
}

export type EmailProvider = 'gmail' | 'outlook';
export type EmailFolder = 'inbox' | 'sent';
export type UserRole =
  | 'owner'
  | 'admin'
  | 'manager'
  | 'staff'
  | 'sales'
  | 'provider'
  | 'frontDesk'
  | 'client'
  | 'system';

export interface UserContext {
  uid: string;
  businessId: string;
  role: UserRole;
  userName: string;
  email?: string;
}

export interface OAuthStatePayload {
  userId: string;
  businessId: string;
  nonce: string;
  redirectUrl?: string;
  accountId?: string;
  issuedAt?: number;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
  email: string;
  displayName?: string;
}

export interface SyncCursorState {
  inbox?: string;
  sent?: string;
}

export interface SyncResult {
  success: boolean;
  created: number;
  updated: number;
  skipped: number;
  cursor?: string;
  errors?: string[];
}

export interface EmailAccountDoc {
  businessId: string;
  userId: string;
  provider: EmailProvider;
  email: string;
  displayName?: string;
  accessToken: string;
  refreshToken: string;
  tokenExpiresAt: FirebaseFirestore.Timestamp | Date;
  syncStatus: 'syncing' | 'synced' | 'error' | 'disconnected';
  lastSyncAt?: FirebaseFirestore.Timestamp | Date;
  syncCursor?: string;
  syncEnabled: boolean;
  syncInbound: boolean;
  syncOutbound: boolean;
  autoAssociate: boolean;
  createdAt?: FirebaseFirestore.Timestamp | Date;
  updatedAt?: FirebaseFirestore.Timestamp | Date;
}

const STATE_MAX_AGE_MS = 10 * 60 * 1000;
const TOKEN_SECRET =
  process.env.EMAIL_TOKEN_SECRET ||
  process.env.API_TOKEN_SECRET ||
  'dev-email-token-secret-please-override';
const rateLimitStore = new Map<string, number[]>();
const defaultOrigins = ['http://localhost:3000', 'http://localhost:5173'];

function normalizeUserRole(role: string | null | undefined): UserRole | undefined {
  if (!role) return undefined;
  const trimmed = role.trim();
  if (!trimmed) return undefined;
  if (
    [
      'owner',
      'admin',
      'manager',
      'staff',
      'sales',
      'provider',
      'frontDesk',
      'client',
      'system',
    ].includes(trimmed)
  ) {
    return trimmed as UserRole;
  }
  if (trimmed === 'assistant') return 'frontDesk';
  if (trimmed === 'sales_rep' || trimmed === 'marketing') return 'sales';
  if (trimmed === 'user') return 'staff';
  return undefined;
}

export const REGION = process.env.FUNCTION_REGION || 'us-central1';
export const TRACKING_PIXEL = Buffer.from(
  'R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
  'base64'
);

export function isEmailIntegrationEnabled(): boolean {
  const flag = process.env.ENABLE_EMAIL_INTEGRATION;
  return flag === undefined ? true : flag === 'true' || flag === '1';
}

function allowedOrigins(): string[] {
  return Array.from(
    new Set([
      ...defaultOrigins,
      ...(process.env.EMAIL_ALLOWED_ORIGINS || '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean),
    ])
  );
}

export function applyCors(req: Request, res: Response): boolean {
  const origin = req.headers.origin;
  if (origin && allowedOrigins().includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Business-Id');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  }

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return true;
  }

  return false;
}

export function parseBearerToken(header?: string): string | null {
  if (!header || !header.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length);
}

export function ensureEmailFeature() {
  if (!isEmailIntegrationEnabled()) {
    throw new functions.https.HttpsError('failed-precondition', 'Email integration disabled');
  }
}

export function sanitizeError(error: unknown): string {
  const message =
    typeof error === 'string'
      ? error
      : error instanceof Error
        ? error.message
        : 'Email request failed';

  return message
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, '[redacted-email]')
    .replace(/\b([A-Za-z0-9_\-]{20,})\b/g, '[redacted-token]')
    .slice(0, 320);
}

export function sendJsonError(res: Response, status: number, message: string) {
  res.status(status).json({ error: message });
}

export function hashValue(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex');
}

export function hashIp(ip: string): string {
  return hashValue(ip || 'unknown-ip');
}

function encryptionKey(): Buffer {
  return crypto.createHash('sha256').update(TOKEN_SECRET).digest().subarray(0, 32);
}

export function encryptToken(token: string): string {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const encrypted = Buffer.concat([cipher.update(token, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, encrypted]).toString('base64');
}

export function decryptToken(token: string): string {
  const payload = Buffer.from(token, 'base64');
  const iv = payload.subarray(0, 12);
  const authTag = payload.subarray(12, 28);
  const encrypted = payload.subarray(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', encryptionKey(), iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(encrypted), decipher.final()]).toString('utf8');
}

export function decodeState(state: string): OAuthStatePayload {
  if (!state) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing OAuth state');
  }

  try {
    return JSON.parse(Buffer.from(state, 'base64').toString('utf8')) as OAuthStatePayload;
  } catch {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid OAuth state');
  }
}

export function validateOAuthState(
  state: OAuthStatePayload,
  expectedBusinessId: string,
  expectedUserId: string
) {
  if (!state.userId || !state.businessId || !state.nonce) {
    throw new functions.https.HttpsError('invalid-argument', 'OAuth state missing required fields');
  }

  if (state.userId !== expectedUserId || state.businessId !== expectedBusinessId) {
    throw new functions.https.HttpsError('permission-denied', 'OAuth state mismatch');
  }

  const issuedAt = state.issuedAt ?? Date.now();
  if (Date.now() - issuedAt > STATE_MAX_AGE_MS) {
    throw new functions.https.HttpsError('deadline-exceeded', 'OAuth state expired');
  }
}

export function toDate(value?: FirebaseFirestore.Timestamp | Date | string): Date | undefined {
  if (!value) return undefined;
  if (value instanceof Date) return value;
  if (typeof value === 'string') return new Date(value);
  return value.toDate();
}

export function parseSyncCursor(raw?: string): SyncCursorState {
  if (!raw) return {};

  try {
    const parsed = JSON.parse(raw) as SyncCursorState;
    return typeof parsed === 'object' && parsed ? parsed : {};
  } catch {
    return { inbox: raw };
  }
}

export function updateSyncCursor(raw: string | undefined, folder: EmailFolder, value: string): string {
  const parsed = parseSyncCursor(raw);
  parsed[folder] = value;
  return JSON.stringify(parsed);
}

export function safeRedirect(raw?: string | null): string | null {
  if (!raw) return null;

  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') {
      return null;
    }
    return url.toString();
  } catch {
    return null;
  }
}

export function sanitizeTrackedUrl(raw?: string | null): string | undefined {
  const safe = safeRedirect(raw || undefined);
  if (!safe) return undefined;
  const url = new URL(safe);
  return `${url.origin}${url.pathname}`;
}

export function rateLimitKey(scope: string, businessId: string, userId: string): string {
  return `${scope}:${businessId}:${userId}`;
}

export function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number
): { allowed: boolean; retryAfterMs: number } {
  const now = Date.now();
  const kept = (rateLimitStore.get(key) || []).filter((timestamp) => now - timestamp < windowMs);
  if (kept.length >= limit) {
    rateLimitStore.set(key, kept);
    return { allowed: false, retryAfterMs: windowMs - (now - kept[0]) };
  }

  kept.push(now);
  rateLimitStore.set(key, kept);
  return { allowed: true, retryAfterMs: 0 };
}

export function buildAccountId(userId: string, provider: EmailProvider, email: string): string {
  return hashValue(`${userId}:${provider}:${email}`).slice(0, 32);
}

export function buildThreadId(accountId: string, providerThreadId: string): string {
  return hashValue(`${accountId}:${providerThreadId}`).slice(0, 32);
}

export function buildSyncedMessageId(accountId: string, providerMessageId: string): string {
  return hashValue(`${accountId}:${providerMessageId}`).slice(0, 32);
}

export function extractIp(req: Request): string {
  const forwarded = req.headers['x-forwarded-for'];
  const headerIp = Array.isArray(forwarded) ? forwarded[0] : forwarded;
  return String(headerIp || req.ip || '').split(',')[0].trim();
}

async function loadUserContext(uid: string, decoded: admin.auth.DecodedIdToken): Promise<UserContext | null> {
  const db = admin.firestore();
  const userSnap = await db.doc(`users/${uid}`).get();
  const data = userSnap.exists ? userSnap.data() || {} : {};
  const businessId = String(
    data.businessId ||
      (decoded as Record<string, unknown>).businessId ||
      (decoded as Record<string, unknown>).bid ||
      decoded.tenant_id ||
      ''
  );
  const role =
    normalizeUserRole(
      typeof data.role === 'string'
        ? data.role
        : typeof (decoded as Record<string, unknown>).role === 'string'
          ? String((decoded as Record<string, unknown>).role)
          : 'staff'
    ) || 'staff';

  if (!businessId) return null;

  return {
    uid,
    businessId,
    role,
    userName: String(data.displayName || data.name || decoded.name || decoded.email || uid),
    email: decoded.email || (typeof data.email === 'string' ? data.email : undefined),
  };
}

export async function authenticateRequest(
  req: Request,
  res: Response,
  allowedRoles: UserRole[] = ['owner', 'admin', 'manager', 'staff', 'sales', 'provider']
): Promise<UserContext | null> {
  try {
    const idToken = parseBearerToken(req.headers.authorization as string | undefined);
    if (!idToken) {
      sendJsonError(res, 401, 'Missing auth token');
      return null;
    }

    const decoded = await admin.auth().verifyIdToken(idToken);
    const user = await loadUserContext(decoded.uid, decoded);
    if (!user) {
      sendJsonError(res, 403, 'User context unavailable');
      return null;
    }

    const requestedBusinessId =
      (req.headers['x-business-id'] as string | undefined) ||
      (req.body?.businessId as string | undefined);
    if (!requestedBusinessId || requestedBusinessId !== user.businessId) {
      sendJsonError(res, 403, 'Business mismatch');
      return null;
    }

    if (user.role === 'frontDesk' || !allowedRoles.includes(user.role)) {
      sendJsonError(res, 403, 'Role not permitted');
      return null;
    }

    if (req.body?.userId && req.body.userId !== user.uid) {
      sendJsonError(res, 403, 'User mismatch');
      return null;
    }

    return user;
  } catch (error) {
    functions.logger.error('email_auth_error', { message: sanitizeError(error) });
    sendJsonError(res, 401, 'Authentication failed');
    return null;
  }
}

export async function writeAuditLog(
  businessId: string,
  userId: string,
  userName: string,
  action: 'integration' | 'webhook',
  entityType: 'integration' | 'activity',
  entityId: string,
  metadata: Record<string, unknown>
) {
  await admin.firestore().collection(`businesses/${businessId}/auditLogs`).add({
    businessId,
    userId,
    userName,
    action,
    entityType,
    entityId,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export function providerFromUnknown(value: unknown): EmailProvider {
  if (value === 'gmail' || value === 'outlook') return value;
  throw new functions.https.HttpsError('invalid-argument', 'Unsupported email provider');
}
