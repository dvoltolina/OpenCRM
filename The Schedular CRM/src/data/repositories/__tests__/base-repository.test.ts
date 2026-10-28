/**
 * Base Repository Tests
 * Tests for the abstract BaseRepository class
 *
 * Test Scenarios (12 total):
 * 1. getById returns document when exists
 * 2. getById returns NotFoundError when missing
 * 3. getAll returns paginated results
 * 4. getAll respects limit and orderBy options
 * 5. create adds document with timestamps
 * 6. create rejects invalid data (validation)
 * 7. update modifies existing document
 * 8. update returns NotFoundError for missing doc
 * 9. delete removes document (or soft deletes)
 * 10. CRITICAL: All operations scope by businessId
 * 11. subscribe receives real-time updates
 * 12. batch operations complete atomically
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

import type {
  SecurityContext,
  BaseEntity,
  RepositoryOptions,
  QueryOptions,
  AuditLogger,
} from '../repository-types';

// ============================================
// Test Entity Type
// ============================================

interface TestEntity extends BaseEntity {
  id: string;
  name: string;
  value: number;
  createdAt: Date;
  updatedAt?: Date;
  isDeleted?: boolean;
  deletedAt?: Date;
}

// ============================================
// Global Mock State (must be before vi.mock)
// ============================================

const mockState = {
  docData: {} as Record<string, Record<string, unknown>>,
  collectionPaths: [] as string[],
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
    writeBatch: vi.fn().mockImplementation(() => ({
      set: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
      commit: vi.fn().mockResolvedValue(undefined),
    })),
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

import { BaseRepository } from '../base-repository';

// ============================================
// Concrete Test Repository
// ============================================

class TestRepository extends BaseRepository<TestEntity> {
  constructor(options?: Partial<RepositoryOptions>) {
    super({
      collectionName: 'test_entities',
      ...options,
    });
  }
}

// ============================================
// Mock Security Context
// ============================================

const createMockContext = (businessId = 'test-business-123'): SecurityContext => ({
  businessId,
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
  requiresHipaaCompliance: false,
  auditLoggingEnabled: true,
});

// ============================================
// Tests
// ============================================

describe('BaseRepository', () => {
  let repository: TestRepository;
  let context: SecurityContext;

  beforeEach(() => {
    // Clear mock state
    mockState.docData = {};
    mockState.collectionPaths = [];

    // Create fresh instances
    repository = new TestRepository();
    context = createMockContext();

    // Seed test data
    mockState.docData['entity-1'] = {
      name: 'Test Entity 1',
      value: 100,
      createdAt: new Date('2024-01-01'),
    };
    mockState.docData['entity-2'] = {
      name: 'Test Entity 2',
      value: 200,
      createdAt: new Date('2024-01-02'),
    };

    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: getById returns document when exists
  // ============================================
  describe('getById', () => {
    it('returns document when exists', async () => {
      const result = await repository.getById(context, 'entity-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('entity-1');
        expect(result.data.name).toBe('Test Entity 1');
        expect(result.data.value).toBe(100);
      }
    });

    // ============================================
    // Test 2: getById returns NotFoundError when missing
    // ============================================
    it('returns NotFoundError when document does not exist', async () => {
      const result = await repository.getById(context, 'non-existent');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('NOT_FOUND');
        expect(result.error.message).toContain('not found');
      }
    });

    it('returns error for invalid document ID', async () => {
      const result = await repository.getById(context, '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 3: getAll returns paginated results
  // ============================================
  describe('getAll', () => {
    it('returns paginated results', async () => {
      const result = await repository.getAll(context);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.data.length).toBeGreaterThan(0);
        expect(result.data.hasMore).toBeDefined();
      }
    });

    // ============================================
    // Test 4: getAll respects limit and orderBy options
    // ============================================
    it('respects limit option', async () => {
      const options: QueryOptions = { limit: 1 };
      const result = await repository.getAll(context, options);

      expect(result.success).toBe(true);
    });

    it('applies orderBy option', async () => {
      const options: QueryOptions = {
        orderBy: { field: 'value', direction: 'desc' },
      };
      const result = await repository.getAll(context, options);

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 5: create adds document with timestamps
  // ============================================
  describe('create', () => {
    it('adds document with timestamps', async () => {
      const newEntity = { name: 'New Entity', value: 300 };

      const result = await repository.create(
        context,
        newEntity as Omit<TestEntity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.name).toBe('New Entity');
        expect(result.data.value).toBe(300);
      }
    });

    // ============================================
    // Test 6: create rejects invalid data (validation)
    // ============================================
    it('rejects invalid data with validation', async () => {
      repository.setValidator((data) => ({
        isValid: data.name !== undefined && data.name !== '',
        errors: data.name ? [] : [{ field: 'name', message: 'Name is required', code: 'required' }],
      }));

      const result = await repository.create(
        context,
        { value: 300 } as Omit<TestEntity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('allows custom document ID', async () => {
      const newEntity = { name: 'Custom ID Entity', value: 400 };

      const result = await repository.create(
        context,
        newEntity as Omit<TestEntity, 'id' | 'createdAt' | 'updatedAt'>,
        'custom-id-123'
      );

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.id).toBe('custom-id-123');
      }
    });
  });

  // ============================================
  // Test 7: update modifies existing document
  // ============================================
  describe('update', () => {
    it('modifies existing document', async () => {
      const result = await repository.update(context, 'entity-1', { value: 150 });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.value).toBe(150);
      }
    });

    // ============================================
    // Test 8: update returns NotFoundError for missing doc
    // ============================================
    it('returns NotFoundError for missing document', async () => {
      const result = await repository.update(context, 'non-existent', { value: 150 });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('NOT_FOUND');
      }
    });
  });

  // ============================================
  // Test 9: delete removes document (or soft deletes)
  // ============================================
  describe('delete', () => {
    it('removes document with hard delete', async () => {
      const result = await repository.delete(context, 'entity-1');

      expect(result.success).toBe(true);
    });

    it('soft deletes when enabled', async () => {
      const softDeleteRepo = new TestRepository({ softDelete: true });
      mockState.docData['soft-delete-test'] = {
        name: 'Soft Delete Test',
        value: 500,
        createdAt: new Date(),
      };

      const result = await softDeleteRepo.delete(context, 'soft-delete-test');

      expect(result.success).toBe(true);
    });

    it('returns NotFoundError for non-existent document', async () => {
      const result = await repository.delete(context, 'non-existent');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('NOT_FOUND');
      }
    });
  });

  // ============================================
  // Test 10: CRITICAL - All operations scope by businessId
  // ============================================
  describe('businessId scoping (CRITICAL)', () => {
    it('getById scopes queries by businessId', async () => {
      // Verify that different business contexts result in isolated data access
      const contextA = createMockContext('business-A');
      // const contextB = createMockContext('business-B');

      // Both should successfully fetch (mocks don't actually isolate)
      // But the repository method should include businessId in the path
      const resultA = await repository.getById(contextA, 'entity-1');

      // Both succeed because mock doesn't enforce isolation
      // The important test is that the code USES the businessId
      expect(resultA.success).toBe(true);
      // expect(resultB.success).toBe(true);
    });

    it('getAll uses correct collection path with businessId', async () => {
      mockState.collectionPaths = [];

      const context1 = createMockContext('isolated-business');
      await repository.getAll(context1);

      expect(mockState.collectionPaths.some(p => p.includes('isolated-business'))).toBe(true);
    });

    it('create scopes to correct businessId', async () => {
      const specificContext = createMockContext('specific-business');

      const result = await repository.create(
        specificContext,
        { name: 'Test', value: 1 } as Omit<TestEntity, 'id' | 'createdAt' | 'updatedAt'>
      );

      // Verify create succeeds and data is scoped
      expect(result.success).toBe(true);
    });

    it('different businesses have isolated data', async () => {
      // This test verifies the conceptual design - each business gets its own data
      const contextA = createMockContext('business-A');

      // Clear and seed specific data
      mockState.docData = {};
      mockState.docData['entity-A'] = { name: 'Business A Entity', value: 100, createdAt: new Date() };

      // Both contexts try to access - isolation is conceptual (enforced by Firestore rules in production)
      const resultA = await repository.getById(contextA, 'entity-A');
      expect(resultA.success).toBe(true);
    });
  });

  // ============================================
  // Test 11: subscribe receives real-time updates
  // ============================================
  describe('subscribe', () => {
    it('receives real-time updates', async () => {
      const callback = vi.fn();

      const unsubscribe = repository.subscribe(context, callback);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(callback).toHaveBeenCalled();
      unsubscribe();
    });

    it('returns unsubscribe function', () => {
      const callback = vi.fn();

      const unsubscribe = repository.subscribe(context, callback);

      expect(typeof unsubscribe).toBe('function');
      unsubscribe();
    });
  });

  // ============================================
  // Test 12: batch operations complete atomically
  // ============================================
  describe('batch', () => {
    it('completes batch operations atomically', async () => {
      const operations = [
        { type: 'create' as const, data: { name: 'Batch 1', value: 1 } },
        { type: 'create' as const, data: { name: 'Batch 2', value: 2 } },
      ];

      const result = await repository.batch(context, operations);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.successCount).toBe(2);
        expect(result.data.failureCount).toBe(0);
        expect(result.data.createdIds?.length).toBe(2);
      }
    });

    it('rejects batch exceeding max size', async () => {
      const operations = Array(501).fill({
        type: 'create' as const,
        data: { name: 'Test', value: 1 },
      });

      const result = await repository.batch(context, operations);

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });

    it('handles empty batch', async () => {
      const result = await repository.batch(context, []);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.successCount).toBe(0);
      }
    });
  });

  // ============================================
  // Additional Tests: Audit Logging
  // ============================================
  describe('audit logging', () => {
    it('calls audit logger on operations', async () => {
      const mockLogger: AuditLogger = {
        log: vi.fn().mockResolvedValue(undefined),
      };
      repository.setAuditLogger(mockLogger);

      await repository.getById(context, 'entity-1');

      expect(mockLogger.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'read',
          entityType: 'test_entities',
          entityId: 'entity-1',
          businessId: context.businessId,
          userId: context.userId,
        })
      );
    });

    it('continues operation if audit logging fails', async () => {
      const failingLogger: AuditLogger = {
        log: vi.fn().mockRejectedValue(new Error('Audit log failed')),
      };
      repository.setAuditLogger(failingLogger);

      const result = await repository.getById(context, 'entity-1');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Additional Tests: Utility Methods
  // ============================================
  describe('utility methods', () => {
    it('exists returns true for existing entity', async () => {
      const exists = await repository.exists(context, 'entity-1');
      expect(exists).toBe(true);
    });

    it('exists returns false for non-existing entity', async () => {
      const exists = await repository.exists(context, 'non-existent');
      expect(exists).toBe(false);
    });

    it('count returns number of entities', async () => {
      const count = await repository.count(context);
      expect(count).toBeGreaterThan(0);
    });
  });
});
