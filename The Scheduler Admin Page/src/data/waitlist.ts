import {
  type WaitlistEntry,
  type WaitlistEntryStatus,
  type WaitlistPriority,
} from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import {
  callTenantFunction,
  fetchCollection,
  postTenantEndpoint,
  scopedCollection,
} from './firestoreBase';
import { logAuditEvent } from './auditLog';

export async function listWaitlistEntries(
  businessId: string,
  userId?: string,
): Promise<WaitlistEntry[]> {
  const scoped = scopedCollection<WaitlistEntry>(businessId, ['waitlist_entries']);
  const rows = (await fetchCollection(scoped)).map(normalizeWaitlistEntry);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'WaitlistEntry',
    entityId: businessId,
    metadata: { source: 'listWaitlistEntries', count: rows.length },
  });
  return rows;
}

export type WaitlistEntryInput = {
  clientId: string;
  serviceId: string;
  providerId?: string;
  locationId?: string;
  earliestDate?: string;
  latestDate?: string;
  preferredStart?: string;
  preferredEnd?: string;
  preferredDaysOfWeek?: string[];
  timeOfDayPreferences?: string[];
  notes?: string;
  priority?: WaitlistPriority;
  priorityScore?: number;
  notificationChannel?: 'sms' | 'email' | 'both';
  notificationPreference?: 'sms' | 'email' | 'both';
};

export type ReleasedSlotPayload = {
  serviceId: string;
  start: string;
  end: string;
  providerId: string;
  locationId?: string;
  maxNotifications?: number;
  responseWindowMinutes?: number;
  bookingLink?: string;
  notifyChannel?: 'sms' | 'email' | 'both';
};

export type WaitlistAction = 'convert' | 'expire' | 'notify';

export async function createWaitlistEntry(
  businessId: string,
  input: WaitlistEntryInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('create waitlist entry');
  if (!businessId) throw new Error('businessId is required to create a waitlist entry');
  const normalizedInput = {
    ...input,
    earliestDate: input.earliestDate ?? input.preferredStart,
    latestDate: input.latestDate ?? input.preferredEnd,
    notificationPreference: input.notificationPreference ?? input.notificationChannel,
    priorityScore:
      typeof input.priorityScore === 'number'
        ? input.priorityScore
        : input.priority === 'vip'
          ? 0
          : 50,
  };
  await callTenantFunction('waitlist-createEntry', businessId, { input: normalizedInput });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'WaitlistEntry',
    entityId: 'new',
    metadata: {
      source: 'createWaitlistEntry',
      hasNotes: Boolean(input.notes),
      serviceId: input.serviceId,
      providerId: input.providerId,
    },
  });
}

export async function updateWaitlistEntryStatus(
  businessId: string,
  entryId: string,
  status: WaitlistEntryStatus,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('update waitlist entry');
  if (!businessId) throw new Error('businessId is required to update a waitlist entry');
  await callTenantFunction('waitlist-updateStatus', businessId, { entryId, status });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'WaitlistEntry',
    entityId: entryId,
    metadata: { source: 'updateWaitlistEntryStatus', status },
  });
}

export async function performWaitlistAction(
  businessId: string,
  entryId: string,
  action: WaitlistAction,
  metadata: Record<string, unknown> = {},
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed(`waitlist action: ${action}`);
  if (!businessId) throw new Error('businessId is required to update a waitlist entry');
  await callTenantFunction('waitlist-performAction', businessId, {
    entryId,
    action,
    metadata,
  });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'WaitlistEntry',
    entityId: entryId,
    metadata: { source: 'performWaitlistAction', action },
  });
}

export async function handleReleasedSlot(
  businessId: string,
  payload: ReleasedSlotPayload,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('broadcast released slot');
  if (!businessId) throw new Error('businessId is required to handle released slots');
  await postTenantEndpoint('/handleReleasedSlot', businessId, {
    serviceId: payload.serviceId,
    providerId: payload.providerId,
    locationId: payload.locationId,
    startTime: payload.start,
    endTime: payload.end,
    maxNotifications: payload.maxNotifications,
    responseWindowMinutes: payload.responseWindowMinutes,
    bookingLink: payload.bookingLink,
    notifyChannel: payload.notifyChannel,
  });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'WaitlistEntry',
    entityId: 'releasedSlot',
    metadata: { source: 'handleReleasedSlot', serviceId: payload.serviceId, providerId: payload.providerId },
  });
}

function normalizeWaitlistEntry(entry: WaitlistEntry): WaitlistEntry {
  const priorityScore =
    typeof entry.priorityScore === 'number'
      ? entry.priorityScore
      : entry.priority === 'vip'
        ? 0
        : 50;
  const priority = entry.priority ?? (priorityScore <= 20 ? 'vip' : 'standard');

  return {
    ...entry,
    earliestDate: entry.earliestDate ?? entry.preferredStart,
    latestDate: entry.latestDate ?? entry.preferredEnd,
    preferredStart: entry.preferredStart ?? entry.earliestDate,
    preferredEnd: entry.preferredEnd ?? entry.latestDate,
    notificationPreference: entry.notificationPreference ?? entry.notificationChannel,
    notificationChannel: entry.notificationChannel ?? entry.notificationPreference,
    priorityScore,
    priority,
  };
}
