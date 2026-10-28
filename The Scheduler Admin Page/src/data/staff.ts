import { type StaffMember } from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { normalizeUserRole } from '../types/auth';
import { logAuditEvent } from './auditLog';
import { callTenantFunction, fetchCollection, scopedCollection } from './firestoreBase';

type ProviderRecord = Omit<StaffMember, 'displayName' | 'role' | 'status'> & {
  displayName?: string;
  role?: string;
  status?: StaffMember['status'];
};

const STAFF_WRITE_BACKEND_GAP =
  'Scheduler backend gap: staff create/update/deactivate is not yet exposed as a canonical shared write surface.';

export class StaffWriteBackendGapError extends Error {
  readonly code = 'staff/write-backend-gap';
  readonly operation: 'create' | 'update' | 'deactivate';
  readonly expectedBackendSurface = 'staff-save';

  constructor(operation: 'create' | 'update' | 'deactivate') {
    super(
      `${STAFF_WRITE_BACKEND_GAP} Attempted operation: ${operation}. Expected backend surface: ${'staff-save'} (Scheduler-owned).`,
    );
    this.name = 'StaffWriteBackendGapError';
    this.operation = operation;
  }
}

export function isStaffWriteBackendGapError(error: unknown): error is StaffWriteBackendGapError {
  return error instanceof StaffWriteBackendGapError;
}

export async function listStaff(businessId: string, userId?: string): Promise<StaffMember[]> {
  const scoped = scopedCollection<ProviderRecord>(businessId, ['providers']);
  const providers = await fetchCollection(scoped);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'Provider',
    entityId: businessId,
    metadata: { source: 'listStaff', count: providers.length },
  });
  return providers.map((provider) => ({
    ...provider,
    displayName: provider.displayName ?? buildProviderName(provider),
    role: normalizeUserRole(provider.role) ?? 'staff',
    status: provider.status ?? 'active',
  }));
}

export async function saveStaff(
  businessId: string,
  staff: Partial<StaffMember>,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('save staff member');
  const operation = inferStaffWriteOperation(staff);
  await callTenantFunction('staff-save', businessId, { staff });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'securityEvent',
    entityType: 'StaffWrite',
    entityId: staff.id ?? 'new',
    metadata: {
      source: 'saveStaff',
      backendSurface: 'staff-save',
      operation,
      hasRole: Boolean(staff.role),
      hasStatus: Boolean(staff.status),
    },
  });
}

function buildProviderName(provider: ProviderRecord): string {
  const inferred = [provider.firstName, provider.lastName].filter(Boolean).join(' ').trim();
  return inferred || provider.displayName || provider.email || 'Unnamed Provider';
}

function inferStaffWriteOperation(
  staff: Partial<StaffMember>,
): 'create' | 'update' | 'deactivate' {
  if (staff.status === 'inactive') {
    return 'deactivate';
  }
  return staff.id ? 'update' : 'create';
}
