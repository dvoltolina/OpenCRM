import { orderBy, where } from 'firebase/firestore';

import { type Appointment, type AppointmentStatus } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import {
  callTenantFunction,
  fetchCollection,
  scopedCollection,
} from './firestoreBase';
import { logAuditEvent } from './auditLog';

export type AppointmentFilters = {
  clientId?: string;
  status?: AppointmentStatus;
  providerId?: string;
  serviceId?: string;
  locationId?: string;
  startAfter?: string;
  startBefore?: string;
};

export type AppointmentInput = {
  clientId: string;
  providerId: string;
  serviceId: string;
  startTime: string;
  endTime: string;
  locationId?: string;
  notes?: string;
  paymentIntentId?: string;
};

export type AppointmentUpdateInput = Partial<Omit<AppointmentInput, 'clientId'>> & {
  status?: AppointmentStatus;
};

export async function listAppointments(
  businessId: string,
  filters: AppointmentFilters = {},
  userId?: string,
): Promise<Appointment[]> {
  const scoped = scopedCollection<Appointment>(businessId, ['appointments']);
  let results = await fetchCollection(
    scoped,
    buildAppointmentConstraints(filters, 'providerId'),
  );

  // Read compatibility only: older docs may still use staffId while canonical writes use providerId.
  if (filters.providerId) {
    const legacyRows = await fetchCollection(scoped, buildAppointmentConstraints(filters, 'staffId'));
    if (legacyRows.length > 0) {
      const deduped = new Map<string, Appointment>();
      [...results, ...legacyRows].forEach((row) => deduped.set(row.id, row));
      results = Array.from(deduped.values()).sort(
        (a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime(),
      );
    }
  }

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Appointment',
    entityId: businessId,
    metadata: {
      source: 'listAppointments',
      hasClientFilter: Boolean(filters.clientId),
      hasProviderFilter: Boolean(filters.providerId),
      hasServiceFilter: Boolean(filters.serviceId),
      count: results.length,
    },
  });
  return results;
}

export async function createAppointment(
  businessId: string,
  input: AppointmentInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('create appointment');
  if (!businessId) throw new Error('businessId is required to create an appointment');
  await callTenantFunction('appointments-create', businessId, { input });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Appointment',
    entityId: 'new',
    metadata: {
      source: 'createAppointment',
      hasNotes: Boolean(input.notes),
      serviceId: input.serviceId,
      providerId: input.providerId,
    },
  });
}

export async function updateAppointment(
  businessId: string,
  appointmentId: string,
  updates: AppointmentUpdateInput,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('update appointment');
  if (!businessId) throw new Error('businessId is required to update an appointment');
  await callTenantFunction('appointments-update', businessId, { appointmentId, updates });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Appointment',
    entityId: appointmentId,
    metadata: {
      source: 'updateAppointment',
      status: updates.status,
      hasNotes: Boolean(updates.notes),
    },
  });
}

export async function cancelAppointment(
  businessId: string,
  appointmentId: string,
  metadata: { reason?: string; notifyClient?: boolean } = {},
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('cancel appointment');
  if (!businessId) throw new Error('businessId is required to cancel an appointment');
  await callTenantFunction('appointments-cancel', businessId, { appointmentId, metadata });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'Appointment',
    entityId: appointmentId,
    metadata: {
      source: 'cancelAppointment',
      reasonProvided: Boolean(metadata.reason),
      notifyClient: metadata.notifyClient ?? false,
    },
  });
}

function buildAppointmentConstraints(
  filters: AppointmentFilters,
  providerField: 'providerId' | 'staffId',
) {
  const constraints = [];

  if (filters.clientId) {
    constraints.push(where('clientId', '==', filters.clientId));
  }
  if (filters.status) {
    constraints.push(where('status', '==', filters.status));
  }
  if (filters.providerId) {
    constraints.push(where(providerField, '==', filters.providerId));
  }
  if (filters.serviceId) {
    constraints.push(where('serviceId', '==', filters.serviceId));
  }
  if (filters.locationId) {
    constraints.push(where('locationId', '==', filters.locationId));
  }

  if (filters.startAfter) {
    constraints.push(where('startTime', '>=', filters.startAfter));
  }
  if (filters.startBefore) {
    constraints.push(where('startTime', '<=', filters.startBefore));
  }
  constraints.push(orderBy('startTime', 'desc'));

  return constraints;
}
