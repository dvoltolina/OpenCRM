import { where } from 'firebase/firestore';

import type { GroupSession, GroupSessionAttendee } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { callTenantFunction, fetchCollection, scopedCollection } from './firestoreBase';
import { logAuditEvent } from './auditLog';

type GroupSessionRecord = Partial<GroupSession> & {
  id?: string;
  businessId?: string;
  isGroupSession?: boolean;
  providerId?: string;
  startTime?: string;
  endTime?: string;
};

type GroupSessionAttendeeRecord = Partial<GroupSessionAttendee> & {
  id?: string;
  status?: string;
  createdAt?: string;
};

export type GroupSessionInput = Omit<GroupSession, 'id' | 'attendeeIds' | 'waitlistIds'> & {
  attendeeIds?: string[];
  waitlistIds?: string[];
};

export type GroupSessionAttendeeInput = Pick<GroupSessionAttendee, 'clientId' | 'status'> & {
  checkedInAt?: string;
};

export async function listGroupSessions(
  businessId: string,
  userId?: string,
): Promise<GroupSession[]> {
  if (!businessId) {
    throw new Error('businessId is required to list group sessions');
  }

  const scoped = scopedCollection<GroupSessionRecord>(businessId, ['appointments']);
  const rows = await fetchCollection(scoped, [where('isGroupSession', '==', true)]);
  const sessions = rows
    .map((row) => normalizeGroupSessionRow(row, businessId))
    .sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'GroupSession',
    entityId: businessId,
    metadata: { source: 'listGroupSessions', count: sessions.length },
  });

  return sessions;
}

export async function listGroupSessionAttendees(
  businessId: string,
  sessionId: string,
  userId?: string,
): Promise<GroupSessionAttendee[]> {
  if (!businessId) {
    throw new Error('businessId is required to list group session attendees');
  }
  if (!sessionId) {
    throw new Error('sessionId is required to list group session attendees');
  }

  const scoped = scopedCollection<GroupSessionAttendeeRecord>(businessId, [
    'appointments',
    sessionId,
    'attendees',
  ]);
  const rows = await fetchCollection(scoped);
  const attendees = rows.map((row) => normalizeAttendeeRow(row, sessionId));

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'GroupSessionAttendee',
    entityId: sessionId,
    metadata: { source: 'listGroupSessionAttendees', count: attendees.length },
  });

  return attendees;
}

export async function createGroupSession(
  businessId: string,
  input: GroupSessionInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('create group session');
  if (!businessId) throw new Error('businessId is required to create a group session');

  await callTenantFunction('groupSessions-create', businessId, {
    input: toGroupSessionWriteInput(input),
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSession',
    entityId: 'new',
    metadata: { source: 'createGroupSession', serviceId: input.serviceId, locationId: input.locationId },
  });
}

export async function updateGroupSession(
  businessId: string,
  sessionId: string,
  updates: Partial<GroupSessionInput>,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('update group session');
  if (!businessId) throw new Error('businessId is required to update a group session');

  await callTenantFunction('groupSessions-update', businessId, {
    sessionId,
    updates: toGroupSessionUpdateInput(updates),
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSession',
    entityId: sessionId,
    metadata: { source: 'updateGroupSession' },
  });
}

export async function deleteGroupSession(
  businessId: string,
  sessionId: string,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('delete group session');
  if (!businessId) throw new Error('businessId is required to delete a group session');

  await callTenantFunction('groupSessions-delete', businessId, { sessionId });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSession',
    entityId: sessionId,
    metadata: { source: 'deleteGroupSession' },
  });
}

export async function addGroupSessionAttendee(
  businessId: string,
  sessionId: string,
  attendee: GroupSessionAttendeeInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('add group session attendee');
  if (!businessId) throw new Error('businessId is required to add a group session attendee');

  await callTenantFunction('groupSessions-addAttendee', businessId, {
    sessionId,
    attendee: toAttendeeWriteInput(attendee),
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSessionAttendee',
    entityId: sessionId,
    metadata: { source: 'addGroupSessionAttendee', clientId: attendee.clientId },
  });
}

export async function updateGroupSessionAttendee(
  businessId: string,
  sessionId: string,
  attendeeId: string,
  updates: Partial<GroupSessionAttendeeInput>,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('update group session attendee');
  if (!businessId) throw new Error('businessId is required to update a group session attendee');

  await callTenantFunction('groupSessions-updateAttendee', businessId, {
    sessionId,
    attendeeId,
    updates: toAttendeeUpdateInput(updates),
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSessionAttendee',
    entityId: attendeeId,
    metadata: { source: 'updateGroupSessionAttendee' },
  });
}

export async function removeGroupSessionAttendee(
  businessId: string,
  sessionId: string,
  attendeeId: string,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('remove group session attendee');
  if (!businessId) throw new Error('businessId is required to remove a group session attendee');

  await callTenantFunction('groupSessions-removeAttendee', businessId, {
    sessionId,
    attendeeId,
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'GroupSessionAttendee',
    entityId: attendeeId,
    metadata: { source: 'removeGroupSessionAttendee' },
  });
}

function normalizeGroupSessionRow(row: GroupSessionRecord, businessId: string): GroupSession {
  const start = row.start ?? row.startTime ?? new Date().toISOString();
  const end = row.end ?? row.endTime ?? start;
  const providerIds = normalizeProviderIds(row.providerIds, row.providerId);
  const attendeeIds = Array.isArray(row.attendeeIds)
    ? row.attendeeIds.filter((id): id is string => typeof id === 'string')
    : [];
  const waitlistIds = Array.isArray(row.waitlistIds)
    ? row.waitlistIds.filter((id): id is string => typeof id === 'string')
    : [];

  return {
    id: row.id ?? '',
    businessId: row.businessId ?? businessId,
    title: row.title ?? 'Group session',
    serviceId: row.serviceId ?? '',
    providerIds,
    locationId: row.locationId,
    start,
    end,
    capacity: typeof row.capacity === 'number' && row.capacity > 0 ? row.capacity : 1,
    attendeeIds,
    waitlistIds,
    visibility: row.visibility === 'public' ? 'public' : 'internal',
    registrationDeadline: row.registrationDeadline,
    allowWaitlist: row.allowWaitlist ?? true,
    notes: row.notes,
    requiredResourceIds: row.requiredResourceIds ?? [],
  };
}

function normalizeProviderIds(providerIds?: string[], providerId?: string): string[] {
  if (Array.isArray(providerIds) && providerIds.length > 0) {
    return providerIds.filter((id): id is string => typeof id === 'string');
  }
  return providerId ? [providerId] : [];
}

function normalizeAttendeeRow(row: GroupSessionAttendeeRecord, sessionId: string): GroupSessionAttendee {
  const normalizedStatus = normalizeAttendeeStatus(row.status);

  return {
    id: row.id ?? '',
    sessionId: row.sessionId ?? sessionId,
    clientId: row.clientId ?? '',
    status: normalizedStatus,
    joinedAt: row.joinedAt ?? row.createdAt ?? new Date().toISOString(),
    checkedInAt: row.checkedInAt,
  };
}

function normalizeAttendeeStatus(status: string | undefined): GroupSessionAttendee['status'] {
  if (status === 'waitlisted') return 'waitlisted';
  if (status === 'cancelled' || status === 'noShow') return 'cancelled';
  return 'confirmed';
}

function toGroupSessionWriteInput(input: GroupSessionInput) {
  return {
    ...input,
    isGroupSession: true,
    startTime: input.start,
    endTime: input.end,
    providerId: input.providerIds[0] ?? null,
    attendeeIds: input.attendeeIds ?? [],
    waitlistIds: input.waitlistIds ?? [],
  };
}

function toGroupSessionUpdateInput(updates: Partial<GroupSessionInput>) {
  const normalized: Record<string, unknown> = {
    ...updates,
    isGroupSession: true,
  };

  if (updates.start) normalized.startTime = updates.start;
  if (updates.end) normalized.endTime = updates.end;
  if (updates.providerIds) normalized.providerId = updates.providerIds[0] ?? null;

  return normalized;
}

function toAttendeeWriteInput(attendee: GroupSessionAttendeeInput) {
  return {
    ...attendee,
    status: toBackendAttendeeStatus(attendee.status),
  };
}

function toAttendeeUpdateInput(updates: Partial<GroupSessionAttendeeInput>) {
  if (!updates.status) return updates;
  return {
    ...updates,
    status: toBackendAttendeeStatus(updates.status),
  };
}

function toBackendAttendeeStatus(status: GroupSessionAttendee['status']) {
  if (status === 'confirmed') return 'registered';
  return status;
}
