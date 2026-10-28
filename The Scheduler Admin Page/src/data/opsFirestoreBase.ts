/**
 * Ops Firestore Base
 * Collection references for ops-only data (super-admin access only).
 * These are top-level collections, not tenant-scoped.
 */

import { collection, type CollectionReference } from 'firebase/firestore';
import { getDb } from '../lib/firebase';
import type { OpsNote, OpsAuditLog, OpsOwnerInvite } from '../types/ops';
import type { WorkspaceInfo } from '../types/models';

/**
 * Top-level businesses collection for cross-tenant listing.
 * Super-admin only via Firestore rules.
 */
export function businessesCollection(): CollectionReference<WorkspaceInfo> {
  return collection(getDb(), 'businesses') as CollectionReference<WorkspaceInfo>;
}

/**
 * Ops support notes for a specific tenant.
 * Path: ops_notes/{businessId}/notes/{noteId}
 */
export function opsNotesCollection(businessId: string): CollectionReference<OpsNote> {
  return collection(getDb(), 'ops_notes', businessId, 'notes') as CollectionReference<OpsNote>;
}

/**
 * Ops audit logs (immutable).
 * Path: ops_audit_logs/{logId}
 */
export function opsAuditCollection(): CollectionReference<OpsAuditLog> {
  return collection(getDb(), 'ops_audit_logs') as CollectionReference<OpsAuditLog>;
}

/**
 * Owner invites created by ops.
 * Path: ops_invites/{inviteId}
 */
export function opsInvitesCollection(): CollectionReference<OpsOwnerInvite> {
  return collection(getDb(), 'ops_invites') as CollectionReference<OpsOwnerInvite>;
}
