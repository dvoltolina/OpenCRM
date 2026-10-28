import { beforeEach, describe, expect, it, vi } from 'vitest';

import { sendBulkInvites } from './bulkInvites';
import { callTenantFunction } from './firestoreBase';
import { logAuditEvent } from './auditLog';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  callTenantFunction: vi.fn(),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

const mockCallTenantFunction = vi.mocked(callTenantFunction);
const mockLogAuditEvent = vi.mocked(logAuditEvent);

describe('sendBulkInvites', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('calls the canonical shared function name', async () => {
    mockCallTenantFunction.mockResolvedValue({
      success: true,
      sent: 1,
      failed: 0,
    });

    const input = {
      invites: [{email: 'admin@example.com', role: 'admin' as const, name: 'Admin'}],
    };

    const result = await sendBulkInvites('biz-1', 'user-1', input);

    expect(result.success).toBe(true);
    expect(mockCallTenantFunction).toHaveBeenCalledWith(
      'staffBulkInvite',
      'biz-1',
      input,
      expect.objectContaining({
        fallbackValue: expect.objectContaining({
          success: true,
          sent: 1,
          failed: 0,
        }),
      }),
    );
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: 'biz-1',
        userId: 'user-1',
        actionType: 'bulk_invite_sent',
      }),
    );
  });
});
