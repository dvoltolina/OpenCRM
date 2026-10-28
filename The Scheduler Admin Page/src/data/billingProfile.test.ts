import { describe, expect, it, vi, beforeEach } from 'vitest';

import { getBillingProfile } from './billingProfile';
import type { BillingProfile } from '../types/models';
import { fetchDoc } from './firestoreBase';

vi.mock('./firestoreBase', () => ({
  fetchDoc: vi.fn(),
  callTenantFunction: vi.fn(),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

vi.mock('./payments', () => ({
  getCustomerPortalUrl: vi.fn(),
}));

const mockFetchDoc = vi.mocked(fetchDoc);

describe('getBillingProfile', () => {
  beforeEach(() => {
    mockFetchDoc.mockReset();
  });

  it('defaults to incomplete when no subscription doc exists', async () => {
    mockFetchDoc.mockResolvedValue(null);

    const profile = await getBillingProfile('biz_123');

    expect(profile.status).toBe('incomplete');
    expect(profile.seats).toBe(0);
    expect(profile.addonIds).toEqual([]);
  });

  it('maps entitlement objects into arrays', async () => {
    const doc = {
      status: 'active',
      seats: 5,
      addOnIds: ['addon-marketing'],
      entitlements: {
        enableReporting: true,
        enableMarketing: false,
      },
    } as unknown as Partial<BillingProfile>;
    mockFetchDoc.mockResolvedValue(doc);

    const profile = await getBillingProfile('biz_123');

    expect(profile.entitlements).toEqual([
      { id: 'enableReporting', label: 'enableReporting', enabled: true, source: 'plan' },
      { id: 'enableMarketing', label: 'enableMarketing', enabled: false, source: 'plan' },
    ]);
  });
});
