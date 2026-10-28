import { beforeEach, describe, expect, it, vi } from 'vitest';

import { logAuditEvent } from './auditLog';
import { callTenantFunction } from './firestoreBase';
import { saveStaff } from './staff';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  callTenantFunction: vi.fn(),
  fetchCollection: vi.fn(),
  scopedCollection: vi.fn(),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

const mockLogAuditEvent = vi.mocked(logAuditEvent);
const mockCallTenantFunction = vi.mocked(callTenantFunction);

describe('saveStaff', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('calls the shared staff-save backend surface for new staff writes', async () => {
    await expect(saveStaff('biz-1', { email: 'provider@example.com' })).resolves.toBeUndefined();

    expect(mockCallTenantFunction).toHaveBeenCalledWith('staff-save', 'biz-1', {
      staff: { email: 'provider@example.com' },
    });

    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: 'biz-1',
        actionType: 'securityEvent',
        entityType: 'StaffWrite',
        metadata: expect.objectContaining({
          backendSurface: 'staff-save',
          operation: 'create',
        }),
      }),
    );
  });

  it('records deactivate operations when sending inactive staff writes', async () => {
    await expect(saveStaff('biz-1', { id: 'provider-1', status: 'inactive' })).resolves.toBeUndefined();

    expect(mockCallTenantFunction).toHaveBeenCalledWith('staff-save', 'biz-1', {
      staff: { id: 'provider-1', status: 'inactive' },
    });
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        metadata: expect.objectContaining({
          operation: 'deactivate',
        }),
      }),
    );
  });
});
