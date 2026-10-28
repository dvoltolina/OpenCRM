import { doc, setDoc, updateDoc, deleteDoc, where, type QueryConstraint } from 'firebase/firestore';

import type { SessionNote, SessionNoteAudit, UserRole } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { getDb } from '../lib/firebase';
import { logAuditEvent } from './auditLog';
import { callTenantFunction, fetchCollection, fetchDoc, scopedCollection } from './firestoreBase';

const SESSION_NOTE_PROVIDER_ROLES: ReadonlySet<UserRole> = new Set(['staff', 'provider']);
const SESSION_NOTE_ADMIN_ROLES: ReadonlySet<UserRole> = new Set(['owner', 'admin']);

export type SessionNoteActor = {
  role?: UserRole;
  providerId?: string;
  userId?: string;
  userDisplayName?: string | null;
};

type CreateSessionNoteInput = {
  clientId: string;
  appointmentId?: string;
  noteType?: SessionNote['noteType'];
  visibility?: SessionNote['visibility'];
  encryptedContent: string;
  title?: string;
  tags?: string[];
  isLocked?: boolean;
  retainIndefinitely?: boolean;
  isPsychotherapyNote?: boolean;
  providerId?: string;
};

type CreateSessionNoteFromPlaintextInput = Omit<CreateSessionNoteInput, 'encryptedContent'> & {
  plaintextContent: string;
};

type EncryptDataResponse = {
  ciphertext: string;
};

type DecryptDataResponse = {
  plaintext: string;
};

function encodeUtf8ToBase64(value: string): string {
  const bytes = new TextEncoder().encode(value);
  let binary = '';
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
}

function decodeUtf8FromBase64(value: string): string {
  const binary = atob(value);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function getFunctionErrorCode(error: unknown): string | undefined {
  if (
    error &&
    typeof error === 'object' &&
    'code' in error &&
    typeof (error as { code?: unknown }).code === 'string'
  ) {
    return (error as { code: string }).code;
  }
  return undefined;
}

function getFunctionErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (
    error &&
    typeof error === 'object' &&
    'message' in error &&
    typeof (error as { message?: unknown }).message === 'string'
  ) {
    return (error as { message: string }).message;
  }
  return 'Unknown error';
}

function isEncryptionKeyMissing(error: unknown): boolean {
  const code = getFunctionErrorCode(error);
  const message = getFunctionErrorMessage(error).toLowerCase();
  return code === 'functions/not-found' && message.includes('encryption key not initialized');
}

function normalizeEncryptionError(error: unknown, action: 'encrypt' | 'decrypt'): Error {
  const message = getFunctionErrorMessage(error);
  if (message.toLowerCase().includes('permission')) {
    return new Error(`You do not have permission to ${action} session note content.`);
  }
  if (action === 'encrypt') {
    return new Error('Failed to encrypt session note content.');
  }
  return new Error('Failed to decrypt session note content.');
}

function isSessionNoteAdmin(role?: UserRole): boolean {
  return role !== undefined && SESSION_NOTE_ADMIN_ROLES.has(role);
}

function isSessionNoteProviderScoped(role?: UserRole): boolean {
  return role !== undefined && SESSION_NOTE_PROVIDER_ROLES.has(role);
}

export function canAccessSessionNotes(role?: UserRole, providerId?: string): boolean {
  if (isSessionNoteAdmin(role)) {
    return true;
  }
  if (!isSessionNoteProviderScoped(role)) {
    return false;
  }
  return typeof providerId === 'string' && providerId.trim().length > 0;
}

function resolveActorProviderId(actor: SessionNoteActor): string {
  if (actor.providerId && actor.providerId.trim().length > 0) {
    return actor.providerId;
  }
  throw new Error('A providerId is required for session-note access for this role.');
}

function ensureSessionNoteAccess(actor: SessionNoteActor): void {
  if (!canAccessSessionNotes(actor.role, actor.providerId)) {
    throw new Error('This role cannot access session notes.');
  }
}

function normalizeIsoTimestamp(value: unknown): string {
  if (typeof value === 'string') return value;
  if (value instanceof Date) return value.toISOString();
  if (
    value &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    return ((value as { toDate: () => Date }).toDate()).toISOString();
  }
  return new Date().toISOString();
}

function normalizeSessionNote(input: SessionNote): SessionNote {
  return {
    ...input,
    createdAt: normalizeIsoTimestamp(input.createdAt),
    updatedAt: input.updatedAt ? normalizeIsoTimestamp(input.updatedAt) : undefined,
    date: input.date ? normalizeIsoTimestamp(input.date) : input.date,
  };
}

function buildAuditEntry(params: {
  action: SessionNoteAudit['action'];
  actorUserId: string;
  actorName: string;
  timestamp: string;
}): SessionNoteAudit {
  return {
    id: `audit-${Date.now()}`,
    action: params.action,
    userId: params.actorUserId,
    userFullName: params.actorName,
    timestamp: params.timestamp,
  };
}

export async function listSessionNotes(
  businessId: string,
  clientId: string,
  actor: SessionNoteActor = {},
): Promise<SessionNote[]> {
  ensureSessionNoteAccess(actor);
  const constraints: QueryConstraint[] = [where('clientId', '==', clientId)];
  if (isSessionNoteProviderScoped(actor.role)) {
    constraints.push(where('providerId', '==', resolveActorProviderId(actor)));
  }

  const scoped = scopedCollection<SessionNote>(businessId, ['session_notes']);
  const rows = await fetchCollection(scoped, constraints);
  const normalizedRows = rows.map(normalizeSessionNote);
  await logAuditEvent({
    businessId,
    userId: actor.userId,
    actionType: 'phiReadList',
    entityType: 'SessionNote',
    entityId: clientId,
    metadata: { source: 'listSessionNotes', count: normalizedRows.length },
  });

  return normalizedRows
    .filter((row) => row.clientId === clientId)
    .sort((a, b) => {
      const aTime = new Date(a.updatedAt ?? a.createdAt ?? a.date ?? '').getTime();
      const bTime = new Date(b.updatedAt ?? b.createdAt ?? b.date ?? '').getTime();
      return bTime - aTime;
    });
}

export async function createSessionNote(
  businessId: string,
  input: CreateSessionNoteInput,
  actor: SessionNoteActor,
): Promise<SessionNote> {
  assertDemoMutationAllowed('create session note');
  ensureSessionNoteAccess(actor);

  const actorUserId = actor.userId?.trim() || 'unknown';
  const actorName = actor.userDisplayName?.trim() || 'Unknown User';
  const providerId = isSessionNoteAdmin(actor.role)
    ? (input.providerId?.trim() || actor.providerId?.trim() || actorUserId)
    : resolveActorProviderId(actor);

  if (isSessionNoteProviderScoped(actor.role) && input.providerId && input.providerId !== providerId) {
    throw new Error('Provider-scoped roles may only create their own session notes.');
  }

  const nowIso = new Date().toISOString();
  const db = getDb();
  const noteRef = doc(scopedCollection<SessionNote>(businessId, ['session_notes'], db).ref);
  const auditEntry = buildAuditEntry({
    action: 'created',
    actorUserId,
    actorName,
    timestamp: nowIso,
  });

  const payload: SessionNote = {
    id: noteRef.id,
    businessId,
    appointmentId: input.appointmentId ?? '',
    clientId: input.clientId,
    providerId,
    noteType: input.noteType ?? 'progressNote',
    visibility: input.visibility ?? 'providerOnly',
    encryptedContent: input.encryptedContent,
    title: input.title,
    tags: input.tags ?? [],
    isLocked: input.isLocked ?? false,
    createdAt: nowIso,
    updatedAt: nowIso,
    createdBy: actorUserId,
    createdByName: actorName,
    retainIndefinitely: input.retainIndefinitely ?? false,
    isPsychotherapyNote: input.isPsychotherapyNote ?? false,
    auditLog: [auditEntry],
    providerName: actorName,
    date: nowIso,
  };

  await setDoc(noteRef, payload);
  await logAuditEvent({
    businessId,
    userId: actor.userId,
    actionType: 'phiWrite',
    entityType: 'SessionNote',
    entityId: payload.id,
    metadata: {
      source: 'createSessionNote',
      clientId: input.clientId,
      noteType: payload.noteType,
    },
  });

  return payload;
}

export async function encryptSessionNoteContent(
  businessId: string,
  plaintextContent: string,
): Promise<string> {
  const trimmed = plaintextContent.trim();
  if (!trimmed) {
    throw new Error('Session note content is required.');
  }

  const plaintext = encodeUtf8ToBase64(trimmed);

  const runEncrypt = async () => {
    const result = await callTenantFunction<{ plaintext: string }, EncryptDataResponse>(
      'encryptData',
      businessId,
      { plaintext },
    );
    if (!result.ciphertext) {
      throw new Error('Encryption returned empty ciphertext.');
    }
    return result.ciphertext;
  };

  try {
    return await runEncrypt();
  } catch (error) {
    if (isEncryptionKeyMissing(error)) {
      try {
        await callTenantFunction('initializeEncryptionKey', businessId, {});
        return await runEncrypt();
      } catch (retryError) {
        throw normalizeEncryptionError(retryError, 'encrypt');
      }
    }
    throw normalizeEncryptionError(error, 'encrypt');
  }
}

export async function decryptSessionNoteContent(
  businessId: string,
  encryptedContent: string,
): Promise<string> {
  if (!encryptedContent.trim()) {
    throw new Error('Encrypted session note content is required.');
  }

  try {
    const result = await callTenantFunction<{ ciphertext: string }, DecryptDataResponse>(
      'decryptData',
      businessId,
      { ciphertext: encryptedContent },
    );
    if (!result.plaintext) {
      throw new Error('Decryption returned empty plaintext.');
    }
    return decodeUtf8FromBase64(result.plaintext);
  } catch (error) {
    throw normalizeEncryptionError(error, 'decrypt');
  }
}

export async function createSessionNoteFromPlaintext(
  businessId: string,
  input: CreateSessionNoteFromPlaintextInput,
  actor: SessionNoteActor,
): Promise<SessionNote> {
  const { plaintextContent, ...noteInput } = input;
  const encryptedContent = await encryptSessionNoteContent(businessId, plaintextContent);
  return createSessionNote(
    businessId,
    {
      ...noteInput,
      encryptedContent,
    },
    actor,
  );
}

export async function updateSessionNote(
  businessId: string,
  noteId: string,
  updates: Partial<Pick<SessionNote, 'encryptedContent' | 'tags' | 'title'>>,
  actor: SessionNoteActor,
): Promise<void> {
  assertDemoMutationAllowed('update session note');
  ensureSessionNoteAccess(actor);

  const existingRaw = await fetchDoc<SessionNote>(businessId, ['session_notes'], noteId);
  const existing = existingRaw ? normalizeSessionNote(existingRaw) : null;
  if (!existing) {
    throw new Error('Session note not found.');
  }

  if (isSessionNoteProviderScoped(actor.role)) {
    const providerId = resolveActorProviderId(actor);
    if (existing.providerId !== providerId) {
      throw new Error('Provider-scoped roles may only edit their own session notes.');
    }
  }

  const nowIso = new Date().toISOString();
  const actorUserId = actor.userId?.trim() || 'unknown';
  const actorName = actor.userDisplayName?.trim() || 'Unknown User';
  const auditEntry = buildAuditEntry({
    action: 'updated',
    actorUserId,
    actorName,
    timestamp: nowIso,
  });

  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'session_notes', noteId);
  await updateDoc(ref, {
    ...updates,
    updatedAt: nowIso,
    lastEditedBy: actorUserId,
    lastEditedByName: actorName,
    auditLog: [...(existing.auditLog ?? []), auditEntry],
  });

  await logAuditEvent({
    businessId,
    userId: actor.userId,
    actionType: 'phiWrite',
    entityType: 'SessionNote',
    entityId: noteId,
    metadata: {
      source: 'updateSessionNote',
      hasTags: Boolean(updates.tags?.length),
      hasTitle: Boolean(updates.title),
      hasContent: Boolean(updates.encryptedContent),
    },
  });
}

export async function deleteSessionNote(
  businessId: string,
  noteId: string,
  actor: SessionNoteActor,
): Promise<void> {
  assertDemoMutationAllowed('delete session note');
  ensureSessionNoteAccess(actor);

  const existingRaw = await fetchDoc<SessionNote>(businessId, ['session_notes'], noteId);
  const existing = existingRaw ? normalizeSessionNote(existingRaw) : null;
  if (!existing) {
    throw new Error('Session note not found.');
  }

  if (isSessionNoteProviderScoped(actor.role)) {
    const providerId = resolveActorProviderId(actor);
    if (existing.providerId !== providerId) {
      throw new Error('Provider-scoped roles may only delete their own session notes.');
    }
  }

  const db = getDb();
  await deleteDoc(doc(db, 'businesses', businessId, 'session_notes', noteId));

  await logAuditEvent({
    businessId,
    userId: actor.userId,
    actionType: 'phiWrite',
    entityType: 'SessionNote',
    entityId: noteId,
    metadata: { source: 'deleteSessionNote' },
  });
}
