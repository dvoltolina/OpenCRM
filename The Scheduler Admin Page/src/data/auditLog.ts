import {
  addDoc,
  collection,
  doc,
  getDoc,
  serverTimestamp,
  type Firestore,
} from 'firebase/firestore';

import { isDemoMode } from '../config/demo';
import { getDb } from '../lib/firebase';

export type AuditActionType =
  | 'phiRead'
  | 'phiReadList'
  | 'phiWrite'
  | 'dataExport'
  | 'securityEvent'
  | 'authEvent'
  | 'configRead'
  | 'configWrite'
  | 'mfa_enrolled'
  | 'mfa_challenge_success'
  | 'mfa_challenge_failure'
  | 'backup_codes_generated'
  | 'backup_code_used'
  | 'bulk_invite_sent';

export type AuditLogInput = {
  businessId: string;
  userId?: string;
  actionType: AuditActionType;
  entityType: string;
  entityId: string;
  metadata?: Record<string, unknown>;
  db?: Firestore;
};

const MAX_STRING_LENGTH = 120;
const MAX_ARRAY_ITEMS = 10;
const auditLoggingCache = new Map<string, boolean>();

function sanitizeMetadata(metadata?: Record<string, unknown>) {
  if (!metadata) return {};
  const safe: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(metadata)) {
    if (value === undefined || value === null) continue;
    if (typeof value === 'string') {
      safe[key] =
        value.length > MAX_STRING_LENGTH ? `${value.slice(0, MAX_STRING_LENGTH)}…` : value;
      continue;
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
      safe[key] = value;
      continue;
    }
    if (Array.isArray(value)) {
      safe[key] = value
        .slice(0, MAX_ARRAY_ITEMS)
        .map((item) =>
          typeof item === 'string'
            ? item.slice(0, Math.min(item.length, MAX_STRING_LENGTH))
            : item,
        );
      continue;
    }
  }
  return safe;
}

async function isAuditLoggingEnabled(businessId: string, db: Firestore): Promise<boolean> {
  if (isDemoMode) {
    return false;
  }
  const cached = auditLoggingCache.get(businessId);
  if (cached !== undefined) return cached;

  try {
    const snap = await getDoc(doc(db, 'businesses', businessId));
    if (!snap.exists()) {
      auditLoggingCache.set(businessId, true);
      return true;
    }

    const data = snap.data() as { requiresHipaaCompliance?: boolean; auditLoggingEnabled?: boolean };
    const enabled = data?.requiresHipaaCompliance === true || data?.auditLoggingEnabled === true;
    auditLoggingCache.set(businessId, enabled);
    return enabled;
  } catch (error) {
    console.warn('[audit] failed to read business flags; defaulting to enabled', error);
    return true;
  }
}

export async function logAuditEvent({
  businessId,
  userId,
  actionType,
  entityType,
  entityId,
  metadata,
  db,
}: AuditLogInput): Promise<void> {
  if (!businessId || isDemoMode) return;

  const database = db ?? getDb();
  const auditEnabled = await isAuditLoggingEnabled(businessId, database);
  if (!auditEnabled) return;

  try {
    await addDoc(collection(database, 'businesses', businessId, 'audit_logs'), {
      businessId,
      userId: userId ?? 'unknown',
      actionType,
      entityType,
      entityId,
      metadata: sanitizeMetadata(metadata),
      timestamp: serverTimestamp(),
    });
  } catch (error) {
    // Best-effort logging: never block the primary action
    console.warn('[audit] failed to write audit log', actionType, entityType, entityId);
  }
}
