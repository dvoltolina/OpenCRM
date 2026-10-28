import { type Client } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { logAuditEvent } from './auditLog';
import { fetchCollection, fetchDoc, scopedCollection } from './firestoreBase';
import {
  addDoc,
  doc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { getDb } from '../lib/firebase';

export type ClientInput = {
  name?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  notes?: string;
};

export async function listClients(businessId: string, userId?: string): Promise<Client[]> {
  const scoped = scopedCollection<Client>(businessId, ['clients']);
  const rows = await fetchCollection(scoped);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Client',
    entityId: businessId,
    metadata: { source: 'listClients', count: rows.length },
  });
  return rows.map(applyClientNameFallback);
}

export async function getClient(
  businessId: string,
  clientId: string,
  userId?: string,
): Promise<Client | null> {
  const client = await fetchDoc<Client>(businessId, ['clients'], clientId);
  if (client) {
    await logAuditEvent({
      businessId,
      userId,
      actionType: 'phiRead',
      entityType: 'Client',
      entityId: clientId,
      metadata: { source: 'getClient' },
    });
  }
  return client ? applyClientNameFallback(client) : null;
}

export async function saveClient(
  businessId: string,
  input: ClientInput & { id?: string },
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('save client');
  if (!businessId) {
    throw new Error('businessId is required to save a client');
  }

  const db = getDb();
  const payload: Partial<Client> = {
    ...input,
    businessId,
  };
  if (!input.id) {
    payload.createdAt = new Date().toISOString();
  }

  if (input.id) {
    const ref = doc(db, 'businesses', businessId, 'clients', input.id);
    await setDoc(ref, payload, { merge: true });
    await logAuditEvent({
      businessId,
      userId,
      actionType: 'phiWrite',
      entityType: 'Client',
      entityId: input.id,
      metadata: { source: 'saveClient', operation: 'update' },
    });
    return;
  }

  const ref = await addDoc(
    scopedCollection<Client>(businessId, ['clients'], db).ref,
    payload as Client,
  );
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Client',
    entityId: ref.id,
    metadata: { source: 'saveClient', operation: 'create' },
  });
}

export async function archiveClient(
  businessId: string,
  clientId: string,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('archive client');
  if (!businessId) {
    throw new Error('businessId is required to archive a client');
  }
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'clients', clientId);
  await updateDoc(ref, {
    archived: true,
    archivedAt: new Date().toISOString(),
  });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Client',
    entityId: clientId,
    metadata: { source: 'archiveClient' },
  });
}

function normalizeIsoTimestamp(value: unknown): string | undefined {
  if (!value) return undefined;
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
  return undefined;
}

function applyClientNameFallback(client: Client): Client {
  const normalized: Client = {
    ...client,
    createdAt: normalizeIsoTimestamp(client.createdAt),
    lastVisitAt: normalizeIsoTimestamp(client.lastVisitAt),
    nextAppointmentAt: normalizeIsoTimestamp(client.nextAppointmentAt),
  };

  if (normalized.name && normalized.name.trim().length > 0) {
    return normalized;
  }
  const inferred = [normalized.firstName, normalized.lastName].filter(Boolean).join(' ').trim();
  return {
    ...normalized,
    name: inferred || normalized.email || 'Unnamed Client',
  };
}
