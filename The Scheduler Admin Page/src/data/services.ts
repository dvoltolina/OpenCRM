import { type Service } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { logAuditEvent } from './auditLog';
import { fetchCollection, scopedCollection } from './firestoreBase';
import { addDoc, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { getDb } from '../lib/firebase';

type ServiceRecord = Omit<Service, 'resourceIds'> & {
  requiredResources?: string[];
  resourceIds?: string[];
  updatedAt?: string;
};

export type ServiceInput = Omit<Service, 'id' | 'businessId'>;

export async function listServices(businessId: string, userId?: string): Promise<Service[]> {
  const scoped = scopedCollection<ServiceRecord>(businessId, ['services']);
  const results = (await fetchCollection(scoped)).map((record) => fromServiceRecord(record));
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Service',
    entityId: businessId,
    metadata: { source: 'listServices', count: results.length },
  });
  return results;
}

export async function createService(
  businessId: string,
  input: ServiceInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('create service');
  if (!businessId) throw new Error('businessId is required to create a service');

  const db = getDb();
  const now = new Date().toISOString();
  await addDoc(scopedCollection<ServiceRecord>(businessId, ['services'], db).ref, {
    ...toServiceRecord({
      ...input,
      isActive: input.isActive ?? true,
      resourceIds: input.resourceIds ?? [],
    }),
    businessId,
    createdAt: now,
    updatedAt: now,
  } as ServiceRecord);

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Service',
    entityId: 'new',
    metadata: {
      source: 'createService',
      hasPrice: typeof input.price === 'number',
      hasBuffer: typeof input.bufferMinutes === 'number',
      hasRequiredResources: (input.resourceIds ?? []).length > 0,
    },
  });
}

export async function updateService(
  businessId: string,
  serviceId: string,
  updates: Partial<ServiceInput>,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('update service');
  if (!businessId) throw new Error('businessId is required to update a service');

  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'services', serviceId);
  await updateDoc(ref, {
    ...toServiceRecord(updates),
    updatedAt: new Date().toISOString(),
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Service',
    entityId: serviceId,
    metadata: {
      source: 'updateService',
      hasRequiredResources: Array.isArray(updates.resourceIds),
      hasActiveFlag: typeof updates.isActive === 'boolean',
    },
  });
}

export async function deleteService(
  businessId: string,
  serviceId: string,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('delete service');
  if (!businessId) throw new Error('businessId is required to delete a service');

  const db = getDb();
  await deleteDoc(doc(db, 'businesses', businessId, 'services', serviceId));

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Service',
    entityId: serviceId,
    metadata: { source: 'deleteService' },
  });
}

function fromServiceRecord(record: ServiceRecord): Service {
  const requiredResources = Array.isArray(record.requiredResources)
    ? record.requiredResources
    : record.resourceIds ?? [];
  const { requiredResources: _requiredResources, ...rest } = record;
  return {
    ...rest,
    resourceIds: requiredResources ?? [],
  };
}

function toServiceRecord(input: Partial<ServiceInput>): Partial<ServiceRecord> {
  const requiredResources = Array.isArray(input.resourceIds)
    ? input.resourceIds.filter(Boolean)
    : undefined;
  const record: Partial<ServiceRecord> = {
    ...input,
    ...(requiredResources ? { requiredResources, resourceIds: requiredResources } : {}),
  };
  return stripUndefined(record);
}

function stripUndefined<T extends Record<string, unknown>>(value: T): T {
  const entries = Object.entries(value).filter(([, v]) => v !== undefined);
  return Object.fromEntries(entries) as T;
}
