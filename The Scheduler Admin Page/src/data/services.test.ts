import { beforeEach, describe, expect, it, vi } from 'vitest';

import { addDoc } from 'firebase/firestore';

import { logAuditEvent } from './auditLog';
import { fetchCollection, scopedCollection } from './firestoreBase';
import { createService, listServices } from './services';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('../lib/firebase', () => ({
  getDb: vi.fn(() => ({ __db: true })),
}));

vi.mock('./auditLog', () => ({
  logAuditEvent: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  fetchCollection: vi.fn(),
  scopedCollection: vi.fn(),
}));

vi.mock('firebase/firestore', () => ({
  addDoc: vi.fn(),
  deleteDoc: vi.fn(),
  doc: vi.fn(),
  updateDoc: vi.fn(),
}));

const mockFetchCollection = vi.mocked(fetchCollection);
const mockScopedCollection = vi.mocked(scopedCollection);
const mockAddDoc = vi.mocked(addDoc);
const mockLogAuditEvent = vi.mocked(logAuditEvent);

describe('services data contract mapping', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockScopedCollection.mockReturnValue({
      path: 'businesses/biz-1/services',
      ref: 'services-ref',
    } as any);
  });

  it('maps canonical requiredResources into resourceIds for UI consumption', async () => {
    mockFetchCollection.mockResolvedValue([
      {
        id: 'svc-1',
        businessId: 'biz-1',
        name: 'Consult',
        durationMinutes: 60,
        requiredResources: ['res-1', 'res-2'],
      } as any,
    ]);

    const rows = await listServices('biz-1', 'user-1');

    expect(rows).toEqual([
      expect.objectContaining({
        id: 'svc-1',
        name: 'Consult',
        resourceIds: ['res-1', 'res-2'],
      }),
    ]);
    expect(mockLogAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: 'biz-1',
        actionType: 'phiReadList',
      }),
    );
  });

  it('writes requiredResources alongside resourceIds on create', async () => {
    mockAddDoc.mockResolvedValue({ id: 'svc-created' } as any);

    await createService(
      'biz-1',
      {
        name: 'Laser',
        durationMinutes: 45,
        resourceIds: ['res-laser'],
      },
      'user-1',
    );

    expect(mockAddDoc).toHaveBeenCalledWith(
      'services-ref',
      expect.objectContaining({
        name: 'Laser',
        durationMinutes: 45,
        requiredResources: ['res-laser'],
        resourceIds: ['res-laser'],
      }),
    );
  });
});
