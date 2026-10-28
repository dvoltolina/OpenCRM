import { beforeEach, describe, expect, it, vi } from 'vitest';

import { getPaymentReceiptUrl } from './payments';
import { logAuditEvent } from './auditLog';
import { postTenantEndpoint } from './firestoreBase';
import { doc, getDoc } from 'firebase/firestore';
import { getDb } from '../lib/firebase';

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

vi.mock('../lib/firebase', () => ({
  getDb: vi.fn(() => ({})),
}));

vi.mock('./firestoreBase', () => ({
  callTenantFunction: vi.fn(),
  fetchCollection: vi.fn(),
  postTenantEndpoint: vi.fn(),
  scopedCollection: vi.fn(),
}));

vi.mock('firebase/firestore', () => ({
  doc: vi.fn(() => ({ id: 'mock-doc' })),
  getDoc: vi.fn(),
}));

const mockDoc = vi.mocked(doc);
const mockGetDoc = vi.mocked(getDoc);
const mockGetDb = vi.mocked(getDb);
const mockLogAuditEvent = vi.mocked(logAuditEvent);
const mockPostTenantEndpoint = vi.mocked(postTenantEndpoint);

describe('getPaymentReceiptUrl', () => {
  beforeEach(() => {
    mockDoc.mockClear();
    mockGetDoc.mockReset();
    mockGetDb.mockClear();
    mockLogAuditEvent.mockReset();
    mockPostTenantEndpoint.mockReset();
  });

  it('returns the receipt URL from the payment document', async () => {
    mockGetDoc.mockResolvedValue({
      exists: () => true,
      data: () => ({ receiptUrl: 'https://receipts.example.com/r/123' }),
    } as any);

    const url = await getPaymentReceiptUrl('biz_123', 'payment_123', 'user_123');

    expect(mockGetDb).toHaveBeenCalledTimes(1);
    expect(mockDoc).toHaveBeenCalled();
    expect(url).toBe('https://receipts.example.com/r/123');
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: 'biz_123',
        entityId: 'payment_123',
        metadata: expect.objectContaining({
          source: 'getPaymentReceiptUrl',
          foundReceiptUrl: true,
        }),
      }),
    );
  });

  it('returns null when no receipt URL fields exist', async () => {
    mockGetDoc.mockResolvedValue({
      exists: () => true,
      data: () => ({ stripeInvoiceId: 'in_123' }),
    } as any);
    mockPostTenantEndpoint.mockResolvedValue({ success: true, url: null });

    const url = await getPaymentReceiptUrl('biz_123', 'payment_123', 'user_123');

    expect(url).toBeNull();
    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/getPaymentReceiptUrl', 'biz_123', {
      paymentId: 'payment_123',
    });
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        metadata: expect.objectContaining({
          foundReceiptUrl: false,
        }),
      }),
    );
  });

  it('falls back to the shared receipt helper when the payment doc lacks a receipt URL', async () => {
    mockGetDoc.mockResolvedValue({
      exists: () => true,
      data: () => ({ stripeInvoiceId: 'in_123' }),
    } as any);
    mockPostTenantEndpoint.mockResolvedValue({
      success: true,
      url: 'https://receipts.example.com/r/456',
    });

    const url = await getPaymentReceiptUrl('biz_123', 'payment_123', 'user_123');

    expect(url).toBe('https://receipts.example.com/r/456');
    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/getPaymentReceiptUrl', 'biz_123', {
      paymentId: 'payment_123',
    });
  });
});
