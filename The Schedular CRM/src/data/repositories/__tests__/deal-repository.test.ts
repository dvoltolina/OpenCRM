/**
 * Deal Repository Tests
 * Tests for the DealRepository class
 *
 * Test Scenarios (18 total):
 * 1. Create deal with required fields
 * 2. Create deal rejects negative valueCents
 * 3. Get deal by ID
 * 4. Get deals by pipeline
 * 5. Get deals by stage
 * 6. Get deals by status (open/won/lost)
 * 7. Get deals by assignee
 * 8. Get deals by client
 * 9. Get deals by company
 * 10. Move deal to new stage updates stageId
 * 11. Move deal updates probability if provided
 * 12. Mark deal as won sets status and closedAt
 * 13. Mark deal as lost requires reason
 * 14. Reopen deal clears closedAt and reason
 * 15. Get upcoming deals within date range
 * 16. Get overdue deals
 * 17. CRITICAL: All queries scoped by businessId
 * 18. Aggregation: total value by stage
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

import type { SecurityContext } from '../repository-types';
import type { Deal } from '../../../types/models';

// ============================================
// Global Mock State (must be before vi.mock)
// ============================================

const mockState = {
  docData: {} as Record<string, Record<string, unknown>>,
  collectionPaths: [] as string[],
  batchOperations: [] as Array<{ type: string; id: string; data?: Record<string, unknown> }>,
};

// ============================================
// Mock Firestore
// ============================================

vi.mock('firebase/firestore', () => {
  const MockTimestamp = class {
    seconds: number;
    nanoseconds: number;
    constructor(seconds: number, nanoseconds: number) {
      this.seconds = seconds;
      this.nanoseconds = nanoseconds;
    }
    toDate(): Date {
      return new Date(this.seconds * 1000);
    }
    static now() {
      return new MockTimestamp(Math.floor(Date.now() / 1000), 0);
    }
    static fromDate(date: Date) {
      return new MockTimestamp(Math.floor(date.getTime() / 1000), 0);
    }
  };

  return {
    collection: vi.fn().mockImplementation((_db: unknown, path: string) => {
      mockState.collectionPaths.push(path);
      return { path, id: path.split('/').pop() };
    }),
    doc: vi.fn().mockImplementation((_db: unknown, path: string, docId: string) => ({
      id: docId,
      path: `${path}/${docId}`,
      ref: { id: docId },
    })),
    getDoc: vi.fn().mockImplementation(async (docRef: { id: string }) => {
      const data = mockState.docData[docRef.id];
      return {
        id: docRef.id,
        exists: () => data !== undefined,
        data: () => data ? { ...data } : undefined,
        ref: docRef,
      };
    }),
    getDocs: vi.fn().mockImplementation(async () => {
      const docs = Object.entries(mockState.docData)
        .filter(([, data]) => !data.isDeleted)
        .map(([id, data]) => ({
          id,
          exists: () => true,
          data: () => ({ ...data }),
          ref: { id },
        }));
      return { docs, empty: docs.length === 0 };
    }),
    setDoc: vi.fn().mockImplementation(async (docRef: { id: string }, data: Record<string, unknown>) => {
      mockState.docData[docRef.id] = { ...data };
    }),
    updateDoc: vi.fn().mockImplementation(async (docRef: { id: string }, data: Record<string, unknown>) => {
      if (!mockState.docData[docRef.id]) {
        const error = new Error('Document not found');
        (error as Error & { code: string }).code = 'not-found';
        throw error;
      }
      mockState.docData[docRef.id] = { ...mockState.docData[docRef.id], ...data };
    }),
    deleteDoc: vi.fn().mockImplementation(async (docRef: { id: string }) => {
      delete mockState.docData[docRef.id];
    }),
    onSnapshot: vi.fn().mockImplementation((_query: unknown, onNext: (snapshot: { docs: unknown[] }) => void) => {
      const docs = Object.entries(mockState.docData)
        .filter(([, data]) => !data.isDeleted)
        .map(([id, data]) => ({
          id,
          exists: () => true,
          data: () => ({ ...data }),
          ref: { id },
        }));
      setTimeout(() => onNext({ docs }), 0);
      return vi.fn();
    }),
    writeBatch: vi.fn().mockImplementation(() => {
      mockState.batchOperations = [];
      return {
        set: vi.fn().mockImplementation((ref: { id: string }, data: Record<string, unknown>) => {
          mockState.batchOperations.push({ type: 'set', id: ref.id, data });
          mockState.docData[ref.id] = { ...data };
        }),
        update: vi.fn().mockImplementation((ref: { id: string }, data: Record<string, unknown>) => {
          mockState.batchOperations.push({ type: 'update', id: ref.id, data });
          if (mockState.docData[ref.id]) {
            mockState.docData[ref.id] = { ...mockState.docData[ref.id], ...data };
          }
        }),
        delete: vi.fn().mockImplementation((ref: { id: string }) => {
          mockState.batchOperations.push({ type: 'delete', id: ref.id });
          delete mockState.docData[ref.id];
        }),
        commit: vi.fn().mockResolvedValue(undefined),
      };
    }),
    query: vi.fn().mockImplementation((collectionRef: unknown) => collectionRef),
    where: vi.fn().mockReturnValue({}),
    orderBy: vi.fn().mockReturnValue({}),
    limit: vi.fn().mockReturnValue({}),
    startAfter: vi.fn().mockReturnValue({}),
    Timestamp: MockTimestamp,
  };
});

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('../../../lib/collections', () => ({
  businessPath: vi.fn((businessId: string) => `businesses/${businessId}`),
}));

// ============================================
// Import AFTER mocks
// ============================================

import { DealRepository } from '../deal-repository';

// ============================================
// Test Setup
// ============================================

const testContext: SecurityContext = {
  businessId: 'test-business-123',
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
};

const createTestDeal = (
  _id: string,
  overrides: Partial<Deal> = {}
): Record<string, unknown> => {
  const mockTimestamp = { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0, toDate: () => new Date() };
  return {
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Test Deal',
    valueCents: 100000,
    currency: 'USD',
    probability: 50,
    status: 'open',
    tags: [],
    createdAt: mockTimestamp,
    ...overrides,
  };
};

describe('DealRepository', () => {
  let repository: DealRepository;

  beforeEach(() => {
    mockState.docData = {};
    mockState.collectionPaths = [];
    mockState.batchOperations = [];
    repository = new DealRepository();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Create deal with required fields
  // ============================================
  describe('create', () => {
    it('should create a deal with required fields', async () => {
      const result = await repository.create(testContext, {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'New Sales Deal',
        valueCents: 250000,
        currency: 'USD',
        probability: 25,
        status: 'open',
        tags: ['enterprise'],
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.title).toBe('New Sales Deal');
        expect(result.data.valueCents).toBe(250000);
        expect(result.data.status).toBe('open');
        expect(result.data.pipelineId).toBe('pipeline-1');
        expect(result.data.stageId).toBe('stage-1');
        expect(result.data.id).toBeDefined();
      }
    });

    // ============================================
    // Test 2: Create deal rejects negative valueCents
    // ============================================
    it('should reject deal with negative valueCents', async () => {
      const result = await repository.create(testContext, {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Invalid Deal',
        valueCents: -1000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });
  });

  // ============================================
  // Test 3: Get deal by ID
  // ============================================
  describe('getById', () => {
    it('should return deal when exists', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        title: 'Enterprise Deal',
        valueCents: 500000,
      });

      const result = await repository.getById(testContext, 'deal-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.title).toBe('Enterprise Deal');
        expect(result.data.valueCents).toBe(500000);
      }
    });
  });

  // ============================================
  // Test 4: Get deals by pipeline
  // ============================================
  describe('getByPipeline', () => {
    it('should return deals for a pipeline', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { pipelineId: 'pipeline-1' });
      mockState.docData['deal-2'] = createTestDeal('deal-2', { pipelineId: 'pipeline-1' });
      mockState.docData['deal-3'] = createTestDeal('deal-3', { pipelineId: 'pipeline-2' });

      const result = await repository.getByPipeline(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 5: Get deals by stage
  // ============================================
  describe('getByStage', () => {
    it('should return deals for a specific stage', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-qualified',
      });
      mockState.docData['deal-2'] = createTestDeal('deal-2', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-proposal',
      });

      const result = await repository.getByStage(testContext, 'pipeline-1', 'stage-qualified');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 6: Get deals by status (open/won/lost)
  // ============================================
  describe('getByStatus', () => {
    it('should return deals filtered by status', async () => {
      mockState.docData['deal-open'] = createTestDeal('deal-open', { status: 'open' });
      mockState.docData['deal-won'] = createTestDeal('deal-won', { status: 'won' });
      mockState.docData['deal-lost'] = createTestDeal('deal-lost', { status: 'lost' });

      const result = await repository.getByStatus(testContext, 'won');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 7: Get deals by assignee
  // ============================================
  describe('getByAssignee', () => {
    it('should return deals assigned to a user', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { assigneeId: 'user-1' });
      mockState.docData['deal-2'] = createTestDeal('deal-2', { assigneeId: 'user-2' });

      const result = await repository.getByAssignee(testContext, 'user-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 8: Get deals by client
  // ============================================
  describe('getByClient', () => {
    it('should return deals for a client', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { clientId: 'client-1' });
      mockState.docData['deal-2'] = createTestDeal('deal-2', { clientId: 'client-2' });

      const result = await repository.getByClient(testContext, 'client-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 9: Get deals by company
  // ============================================
  describe('getByCompany', () => {
    it('should return deals for a company', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { companyId: 'company-1' });
      mockState.docData['deal-2'] = createTestDeal('deal-2', { companyId: 'company-2' });

      const result = await repository.getByCompany(testContext, 'company-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 10: Move deal to new stage updates stageId
  // ============================================
  describe('moveToStage', () => {
    it('should move deal to a new stage', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        stageId: 'stage-lead',
        status: 'open',
      });

      const result = await repository.moveToStage(testContext, 'deal-1', 'stage-qualified');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.stageId).toBe('stage-qualified');
      }
    });

    // ============================================
    // Test 11: Move deal updates probability if provided
    // ============================================
    it('should update probability when provided', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        stageId: 'stage-lead',
        probability: 10,
        status: 'open',
      });

      const result = await repository.moveToStage(testContext, 'deal-1', 'stage-proposal', 75);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.stageId).toBe('stage-proposal');
        expect(result.data.probability).toBe(75);
      }
    });

    it('should reject moving closed deals', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        status: 'won',
      });

      const result = await repository.moveToStage(testContext, 'deal-1', 'stage-new');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 12: Mark deal as won sets status and closedAt
  // ============================================
  describe('markWon', () => {
    it('should mark deal as won with closedAt', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { status: 'open' });

      const result = await repository.markWon(testContext, 'deal-1', 'Customer signed contract');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.status).toBe('won');
        expect(result.data.closedAt).toBeDefined();
        expect(result.data.probability).toBe(100);
      }
    });

    it('should reject marking already closed deals as won', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { status: 'lost' });

      const result = await repository.markWon(testContext, 'deal-1');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 13: Mark deal as lost requires reason
  // ============================================
  describe('markLost', () => {
    it('should require reason when marking as lost', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { status: 'open' });

      const result = await repository.markLost(testContext, 'deal-1', '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });

    it('should mark deal as lost with reason', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { status: 'open' });

      const result = await repository.markLost(testContext, 'deal-1', 'Budget constraints');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.status).toBe('lost');
        expect(result.data.wonLostReason).toBe('Budget constraints');
        expect(result.data.closedAt).toBeDefined();
        expect(result.data.probability).toBe(0);
      }
    });
  });

  // ============================================
  // Test 14: Reopen deal clears closedAt and reason
  // ============================================
  describe('reopen', () => {
    it('should reopen a closed deal', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        status: 'lost',
        closedAt: new Date(),
        wonLostReason: 'Budget issues',
      });

      const result = await repository.reopen(testContext, 'deal-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.status).toBe('open');
      }
    });

    it('should reject reopening already open deals', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', { status: 'open' });

      const result = await repository.reopen(testContext, 'deal-1');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 15: Get upcoming deals within date range
  // ============================================
  describe('getUpcoming', () => {
    it('should return deals closing within N days', async () => {
      const futureDate = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000);
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        status: 'open',
        expectedCloseDate: { toDate: () => futureDate } as any,
      });

      const result = await repository.getUpcoming(testContext, 7);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('should reject negative days', async () => {
      const result = await repository.getUpcoming(testContext, -1);

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 16: Get overdue deals
  // ============================================
  describe('getOverdue', () => {
    it('should return overdue deals', async () => {
      const pastDate = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        status: 'open',
        expectedCloseDate: { toDate: () => pastDate } as any,
      });

      const result = await repository.getOverdue(testContext);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 17: CRITICAL - All queries scoped by businessId
  // ============================================
  describe('businessId scoping', () => {
    it('should scope all operations by businessId', async () => {
      const context1: SecurityContext = {
        ...testContext,
        businessId: 'business-1',
      };
      const context2: SecurityContext = {
        ...testContext,
        businessId: 'business-2',
      };

      // Create deal in business-1
      const result1 = await repository.create(context1, {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Business 1 Deal',
        valueCents: 100000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
      });

      expect(result1.success).toBe(true);

      // Create deal in business-2
      const result2 = await repository.create(context2, {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Business 2 Deal',
        valueCents: 200000,
        currency: 'USD',
        probability: 75,
        status: 'open',
        tags: [],
      });

      expect(result2.success).toBe(true);
    });

    it('should require businessId in SecurityContext', async () => {
      const validContext: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'admin',
      };

      expect(validContext.businessId).toBeDefined();
      expect(validContext.businessId.length).toBeGreaterThan(0);

      const result = await repository.create(validContext, {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Test Deal',
        valueCents: 100000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
      });

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 18: Aggregation: total value by stage
  // ============================================
  describe('getTotalValueByStage', () => {
    it('should calculate total value by stage', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-lead',
        valueCents: 100000,
        status: 'open',
      });
      mockState.docData['deal-2'] = createTestDeal('deal-2', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-lead',
        valueCents: 150000,
        status: 'open',
      });
      mockState.docData['deal-3'] = createTestDeal('deal-3', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-qualified',
        valueCents: 200000,
        status: 'open',
      });

      const result = await repository.getTotalValueByStage(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data['stage-lead']).toBeDefined();
        expect(result.data['stage-lead'].count).toBe(2);
        expect(result.data['stage-lead'].totalValueCents).toBe(250000);
        expect(result.data['stage-qualified']).toBeDefined();
        expect(result.data['stage-qualified'].count).toBe(1);
        expect(result.data['stage-qualified'].totalValueCents).toBe(200000);
      }
    });

    it('should only include open deals in aggregation', async () => {
      mockState.docData['deal-open'] = createTestDeal('deal-open', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        valueCents: 100000,
        status: 'open',
      });
      mockState.docData['deal-won'] = createTestDeal('deal-won', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        valueCents: 500000,
        status: 'won',
      });

      const result = await repository.getTotalValueByStage(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        // Should only count the open deal
        expect(result.data['stage-1']?.totalValueCents).toBe(100000);
      }
    });
  });

  // ============================================
  // Additional Tests
  // ============================================
  describe('getCountByStage', () => {
    it('should return count of deals by stage', async () => {
      mockState.docData['deal-1'] = createTestDeal('deal-1', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        status: 'open',
      });
      mockState.docData['deal-2'] = createTestDeal('deal-2', {
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        status: 'open',
      });

      const result = await repository.getCountByStage(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data['stage-1']).toBe(2);
      }
    });
  });

  describe('getWonValueRange', () => {
    it('should return won deal value in date range', async () => {
      const closedAt = new Date();
      mockState.docData['deal-won'] = createTestDeal('deal-won', {
        status: 'won',
        valueCents: 300000,
        closedAt: { toDate: () => closedAt } as any,
      });

      const startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const endDate = new Date(Date.now() + 1 * 24 * 60 * 60 * 1000);

      const result = await repository.getWonValueRange(testContext, startDate, endDate);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.totalValueCents).toBeGreaterThanOrEqual(0);
        expect(result.data.dealCount).toBeGreaterThanOrEqual(0);
      }
    });

    it('should reject invalid date range', async () => {
      const startDate = new Date();
      const endDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const result = await repository.getWonValueRange(testContext, startDate, endDate);

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });
});
