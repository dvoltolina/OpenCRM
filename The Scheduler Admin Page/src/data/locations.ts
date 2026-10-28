import { addDoc, deleteDoc, doc, updateDoc } from 'firebase/firestore';

import { assertDemoMutationAllowed } from '../config/demo';
import { getDb } from '../lib/firebase';
import type {
  Location,
  LocationInput,
  Resource,
  ResourceConflict,
  ResourceInput,
  ResourceMaintenanceLog,
  ResourceStatus,
} from '../types/models';
import { logAuditEvent } from './auditLog';
import { fetchCollection, scopedCollection } from './firestoreBase';

type LocationRecord = Location & {
  city?: string;
  state?: string;
  zipCode?: string;
  isActive?: boolean;
};

type ResourceRecord = Omit<Resource, 'type' | 'status'> & {
  type?: 'room' | 'equipment' | 'vehicle' | 'other';
  status?: ResourceStatus;
  isActive?: boolean;
  maintenanceSchedule?: unknown;
  description?: string;
  updatedAt?: string;
};

// Backward-compatible export used by non-scope pages that still render static conflict panels.
export const resourceConflicts: ResourceConflict[] = [];

// Locations
export async function listLocations(businessId: string, userId?: string): Promise<Location[]> {
  if (!businessId) {
    throw new Error('businessId is required to list locations');
  }
  const scoped = scopedCollection<LocationRecord>(businessId, ['locations']);
  const results = (await fetchCollection(scoped)).map((row) => fromLocationRecord(row));
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Location',
    entityId: businessId,
    metadata: { source: 'listLocations', count: results.length },
  });
  return results;
}

export async function createLocation(
  businessId: string,
  input: LocationInput,
): Promise<void> {
  assertDemoMutationAllowed('create location');
  if (!businessId) throw new Error('businessId is required to create a location');
  const db = getDb();
  const now = new Date().toISOString();
  await addDoc(scopedCollection<LocationRecord>(businessId, ['locations'], db).ref, {
    ...toLocationRecord(input),
    businessId,
    createdAt: now,
    updatedAt: now,
  });
}

export async function updateLocation(
  businessId: string,
  locationId: string,
  updates: Partial<LocationInput>,
): Promise<void> {
  assertDemoMutationAllowed('update location');
  if (!businessId) throw new Error('businessId is required to update a location');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'locations', locationId);
  await updateDoc(ref, {
    ...toLocationRecord(updates),
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteLocation(businessId: string, locationId: string): Promise<void> {
  assertDemoMutationAllowed('delete location');
  if (!businessId) throw new Error('businessId is required to delete a location');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'locations', locationId);
  await deleteDoc(ref);
}

// Resources
export async function listResources(businessId: string, locationId?: string): Promise<Resource[]> {
  if (!businessId) {
    throw new Error('businessId is required to list resources');
  }
  const scoped = scopedCollection<ResourceRecord>(businessId, ['resources']);
  const all = (await fetchCollection(scoped)).map((row) => fromResourceRecord(row));
  return locationId ? all.filter((r) => r.locationId === locationId) : all;
}

export async function createResource(
  businessId: string,
  input: ResourceInput,
): Promise<void> {
  assertDemoMutationAllowed('create resource');
  if (!businessId) throw new Error('businessId is required to create a resource');
  const db = getDb();
  const now = new Date().toISOString();
  await addDoc(scopedCollection<ResourceRecord>(businessId, ['resources'], db).ref, {
    ...toResourceRecord(input),
    businessId,
    createdAt: now,
    updatedAt: now,
  });
}

export async function updateResource(
  businessId: string,
  resourceId: string,
  updates: Partial<ResourceInput>,
): Promise<void> {
  assertDemoMutationAllowed('update resource');
  if (!businessId) throw new Error('businessId is required to update a resource');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'resources', resourceId);
  await updateDoc(ref, {
    ...toResourceRecord(updates),
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteResource(businessId: string, resourceId: string): Promise<void> {
  assertDemoMutationAllowed('delete resource');
  if (!businessId) throw new Error('businessId is required to delete a resource');
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'resources', resourceId);
  await deleteDoc(ref);
}

export async function toggleResourceMaintenance(
  businessId: string,
  resourceId: string,
  maintenanceNote?: string,
): Promise<void> {
  assertDemoMutationAllowed('toggle resource maintenance');
  if (!businessId) throw new Error('businessId is required to toggle maintenance');
  const db = getDb();
  const now = new Date().toISOString();
  const status: ResourceStatus = maintenanceNote ? 'maintenance' : 'available';
  const ref = doc(db, 'businesses', businessId, 'resources', resourceId);
  await updateDoc(ref, {
    status,
    isActive: status !== 'maintenance',
    description: maintenanceNote ?? null,
    maintenanceNote: maintenanceNote ?? null,
    maintenanceSchedule: maintenanceNote
      ? [{ status: 'maintenance', note: maintenanceNote, changedAt: now }]
      : [],
    maintenanceSince: maintenanceNote ? now : null,
    updatedAt: now,
  });
}

export async function listResourceMaintenanceLogs(
  businessId: string,
  resourceId: string,
): Promise<ResourceMaintenanceLog[]> {
  if (!businessId) {
    throw new Error('businessId is required to list resource maintenance logs');
  }
  if (!resourceId) {
    throw new Error('resourceId is required to list resource maintenance logs');
  }
  const scoped = scopedCollection<ResourceMaintenanceLog>(businessId, ['resourceMaintenanceLogs']);
  const logs = await fetchCollection(scoped);
  return logs.filter((log) => log.resourceId === resourceId);
}

export async function addResourceMaintenanceLog(
  businessId: string,
  resourceId: string,
  log: Pick<ResourceMaintenanceLog, 'note' | 'status' | 'createdBy'>,
): Promise<void> {
  assertDemoMutationAllowed('add maintenance log');
  if (!businessId) throw new Error('businessId is required to add a maintenance log');
  const db = getDb();
  await addDoc(scopedCollection<ResourceMaintenanceLog>(businessId, ['resourceMaintenanceLogs'], db).ref, {
    resourceId,
    note: log.note,
    status: log.status,
    createdBy: log.createdBy,
    createdAt: new Date().toISOString(),
  });
}

// Resource conflicts
export async function listResourceConflicts(businessId: string): Promise<ResourceConflict[]> {
  if (!businessId) {
    throw new Error('businessId is required to list resource conflicts');
  }
  const scoped = scopedCollection<ResourceConflict>(businessId, ['resourceConflicts']);
  return fetchCollection(scoped);
}

export async function resolveResourceConflict(
  businessId: string,
  conflictId: string,
  resolution: string,
): Promise<void> {
  assertDemoMutationAllowed('resolve resource conflict');
  if (!businessId) {
    throw new Error('businessId is required to resolve a resource conflict');
  }
  const db = getDb();
  const ref = doc(db, 'businesses', businessId, 'resourceConflicts', conflictId);
  await updateDoc(ref, {
    resolvedAt: new Date().toISOString(),
    resolutionNote: resolution,
    severity: 'info',
  });
  await logAuditEvent({
    businessId,
    actionType: 'phiWrite',
    entityType: 'ResourceConflict',
    entityId: conflictId,
    metadata: {
      source: 'resolveResourceConflict',
      hasResolutionNote: Boolean(resolution.trim()),
    },
  });
}

function fromLocationRecord(record: LocationRecord): Location {
  const status =
    record.status ?? (record.isActive === false ? 'inactive' : 'active');
  return {
    ...record,
    status,
  };
}

function toLocationRecord(input: Partial<LocationInput>): Partial<LocationRecord> {
  const status = input.status;
  const withCanonical = {
    ...input,
    ...(status ? { isActive: status !== 'inactive' } : {}),
  };
  return stripUndefined(withCanonical);
}

function fromResourceRecord(record: ResourceRecord): Resource {
  const rawType = record.type ?? 'equipment';
  const type: Resource['type'] = rawType === 'room' || rawType === 'equipment' ? rawType : 'equipment';
  const status = record.status ?? (record.isActive === false ? 'maintenance' : 'available');
  return {
    ...(record as Resource),
    type,
    status,
    maintenanceNote: record.maintenanceNote ?? record.description,
  };
}

function toResourceRecord(input: Partial<ResourceInput>): Partial<ResourceRecord> {
  const status = input.status;
  const maintenanceNote = input.maintenanceNote;
  const withCanonical: Partial<ResourceRecord> = {
    ...input,
    ...(status ? { isActive: status !== 'maintenance' } : {}),
    ...(maintenanceNote !== undefined ? { description: maintenanceNote } : {}),
    ...(status === 'maintenance'
      ? {
          maintenanceSchedule: [
            {
              status: 'maintenance',
              note: maintenanceNote ?? '',
              changedAt: new Date().toISOString(),
            },
          ],
        }
      : {}),
  };
  return stripUndefined(withCanonical);
}

function stripUndefined<T extends Record<string, unknown>>(value: T): T {
  const entries = Object.entries(value).filter(([, v]) => v !== undefined);
  return Object.fromEntries(entries) as T;
}
