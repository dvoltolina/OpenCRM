import { beforeEach, describe, expect, it, vi } from 'vitest';

import { postTenantEndpoint } from './firestoreBase';
import { sendTestMessage } from './templates';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  callTenantFunction: vi.fn(),
  fetchCollection: vi.fn(),
  postTenantEndpoint: vi.fn(),
  scopedCollection: vi.fn(),
}));

const mockPostTenantEndpoint = vi.mocked(postTenantEndpoint);

describe('sendTestMessage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('uses the shared HTTP communications test-send endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue({
      success: true,
      messageId: 'msg_123',
      renderedPreview: 'Hello John Doe',
    });

    const result = await sendTestMessage('biz_123', 'template_123', 'ops@example.com', 'email');

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/sendTestMessage', 'biz_123', {
      templateId: 'template_123',
      recipient: 'ops@example.com',
      channel: 'email',
    });
    expect(result).toEqual(
      expect.objectContaining({
        success: true,
        messageId: 'msg_123',
      }),
    );
  });
});
