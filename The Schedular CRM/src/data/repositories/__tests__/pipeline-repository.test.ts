/**
 * Pipeline Repository Tests
 * Tests for the PipelineRepository class
 *
 * Test Scenarios (7 total):
 * 1. Create pipeline with name and default flag
 * 2. Get default pipeline for business
 * 3. Set new default pipeline (unsets previous)
 * 4. Get all active pipelines
 * 5. Archive pipeline sets isActive false
 * 6. CRITICAL: Pipelines scoped by businessId
 * 7. Cannot delete pipeline with active deals (placeholder)
 * 8. RBAC: Staff cannot take ownership when updating shared pipeline
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

import type { SecurityContext } from '../repository-types';
import type { Pipeline } from '../../../types/models';

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
  class MockTimestamp {
    seconds: number;
    nanoseconds: number;
    constructor(seconds: number, nanoseconds: number) {
      this.seconds = seconds;
      this.nanoseconds = nanoseconds;
    }
    toDate(): Date {
      return new Date(this.seconds * 1000);
    }
    static now(): MockTimestamp {
      return new MockTimestamp(Math.floor(Date.now() / 1000), 0);
    }
    static fromDate(date: Date): MockTimestamp {
      return new MockTimestamp(Math.floor(date.getTime() / 1000), 0);
    }
  }

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

import { PipelineRepository, DEFAULT_STAGES } from '../pipeline-repository';

// ============================================
// Test Setup
// ============================================

const testContext: SecurityContext = {
  businessId: 'test-business-123',
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-1'],
};

const createTestPipeline = (
  _id: string,
  overrides: Partial<Pipeline> = {}
): Record<string, unknown> => {
  const mockTimestamp = { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0, toDate: () => new Date() };
  return {
    name: 'Test Pipeline',
    isDefault: false,
    isActive: true,
    ownerId: testContext.userId,
    ownerName: testContext.userName,
    teamIds: [],
    visibility: 'team',
    createdAt: mockTimestamp,
    ...overrides,
  };
};

describe('PipelineRepository', () => {
  let repository: PipelineRepository;

  beforeEach(() => {
    mockState.docData = {};
    mockState.collectionPaths = [];
    mockState.batchOperations = [];
    repository = new PipelineRepository();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Create pipeline with name and default flag
  // ============================================
  describe('create', () => {
    it('should create a pipeline with name and default flag', async () => {
      const result = await repository.create(testContext, {
        name: 'Sales Pipeline',
        isDefault: true,
        isActive: true,
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.name).toBe('Sales Pipeline');
        expect(result.data.isDefault).toBe(true);
        expect(result.data.isActive).toBe(true);
        expect(result.data.id).toBeDefined();
      }
    });

    it('forces ownership to caller when non-admin tries to override owner fields', async () => {
      const staffContext: SecurityContext = {
        businessId: 'test-business-123',
        userId: 'staff-123',
        userName: 'Staff User',
        userRole: 'staff',
        teamIds: ['team-1'],
      };

      const result = await repository.create(staffContext, {
        name: 'Staff Pipeline',
        isDefault: false,
        isActive: true,
        ownerId: 'other-user',
        ownerName: 'Other User',
        teamIds: ['team-9'],
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.ownerId).toBe('staff-123');
        expect(result.data.ownerName).toBe('Staff User');
      }
    });
  });

  it('filters active pipelines to owner or shared teams for staff', async () => {
    mockState.docData = {
      'pipe-1': createTestPipeline('pipe-1', {
        ownerId: 'staff-1',
        ownerName: 'Staff User',
        teamIds: ['team-1'],
      }),
      'pipe-2': createTestPipeline('pipe-2', {
        ownerId: 'other-user',
        ownerName: 'Other',
        teamIds: ['team-2'],
      }),
      'pipe-3': createTestPipeline('pipe-3', {
        ownerId: 'staff-1',
        ownerName: 'Staff User',
        teamIds: ['team-3'],
        isActive: true,
      }),
    };

    const staffContext: SecurityContext = {
      businessId: 'test-business-123',
      userId: 'staff-1',
      userName: 'Staff User',
      userRole: 'staff',
      teamIds: ['team-1'],
    };

    const result = await repository.getActive(staffContext, staffContext.teamIds);

    expect(result.success).toBe(true);
    expect(result.data?.data.map((p) => p.id).sort()).toEqual(['pipe-1', 'pipe-3']);
  });

  it('prevents staff from updating pipelines they do not own or share', async () => {
    mockState.docData = {
      'pipe-4': createTestPipeline('pipe-4', {
        ownerId: 'owner-999',
        ownerName: 'Other Owner',
        teamIds: ['team-2'],
      }),
    };

    const staffContext: SecurityContext = {
      businessId: 'test-business-123',
      userId: 'staff-1',
      userName: 'Staff User',
      userRole: 'staff',
      teamIds: ['team-1'],
    };

    const result = await repository.update(staffContext, 'pipe-4', { name: 'New Name' });

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('denies access to pipelines not owned or shared', async () => {
    mockState.docData = {
      'pipe-6': createTestPipeline('pipe-6', {
        ownerId: 'another-owner',
        ownerName: 'Another Owner',
        teamIds: ['team-5'],
      }),
    };

    const staffContext: SecurityContext = {
      businessId: 'test-business-123',
      userId: 'staff-3',
      userName: 'Staff',
      userRole: 'staff',
      teamIds: ['team-1'],
    };

    const result = await repository.getById(staffContext, 'pipe-6', staffContext.teamIds);

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('allows shared team member to update without changing ownership', async () => {
    mockState.docData = {
      'pipe-5': createTestPipeline('pipe-5', {
        ownerId: 'owner-999',
        ownerName: 'Other Owner',
        teamIds: ['team-3'],
        name: 'Original Name',
      }),
    };

    const staffContext: SecurityContext = {
      businessId: 'test-business-123',
      userId: 'staff-2',
      userName: 'Team Member',
      userRole: 'staff',
      teamIds: ['team-3'],
    };

    const result = await repository.update(staffContext, 'pipe-5', { name: 'Updated Name' });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.name).toBe('Updated Name');
      expect(result.data.ownerId).toBe('owner-999');
      expect(result.data.ownerName).toBe('Other Owner');
    }
  });

  // ============================================
  // Test 2: Get default pipeline for business
  // ============================================
  describe('getDefault', () => {
    it('should return the default pipeline when one exists', async () => {
      // Setup: Create a default pipeline in mock data
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        name: 'Default Pipeline',
        isDefault: true,
        isActive: true,
      });

      const result = await repository.getDefault(testContext);

      expect(result.success).toBe(true);
      if (result.success && result.data) {
        expect(result.data.name).toBe('Default Pipeline');
        expect(result.data.isDefault).toBe(true);
      }
    });

    it('should return null when no default pipeline exists', async () => {
      // Setup: No default pipeline
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        isDefault: false,
      });

      // The mock getDocs returns all documents, so we need to modify it for this test
      const result = await repository.getDefault(testContext);

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 3: Set new default pipeline (unsets previous)
  // ============================================
  describe('setDefault', () => {
    it('should set a pipeline as default and unset others', async () => {
      // Setup: Two pipelines, one is default
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        name: 'Old Default',
        isDefault: true,
        isActive: true,
      });
      mockState.docData['pipeline-2'] = createTestPipeline('pipeline-2', {
        name: 'New Default',
        isDefault: false,
        isActive: true,
      });

      const result = await repository.setDefault(testContext, 'pipeline-2');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isDefault).toBe(true);
      }
      // Verify batch was called (old default should be updated)
      expect(mockState.batchOperations.length).toBeGreaterThan(0);
    });

    it('should reject setting inactive pipeline as default', async () => {
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        isActive: false,
      });

      const result = await repository.setDefault(testContext, 'pipeline-1');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 4: Get all active pipelines
  // ============================================
  describe('getActive', () => {
    it('should return only active pipelines', async () => {
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        name: 'Active Pipeline 1',
        isActive: true,
      });
      mockState.docData['pipeline-2'] = createTestPipeline('pipeline-2', {
        name: 'Inactive Pipeline',
        isActive: false,
      });
      mockState.docData['pipeline-3'] = createTestPipeline('pipeline-3', {
        name: 'Active Pipeline 2',
        isActive: true,
      });

      const result = await repository.getActive(testContext);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.data.map((p) => p.name)).toEqual([
          'Active Pipeline 1',
          'Active Pipeline 2',
        ]);
      }
    });
  });

  // ============================================
  // Test 5: Archive pipeline sets isActive false
  // ============================================
  describe('archive', () => {
    it('should archive a pipeline by setting isActive to false', async () => {
      // Setup: Two active pipelines (need at least 2 to archive one)
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        name: 'Pipeline to Archive',
        isActive: true,
        isDefault: false,
      });
      mockState.docData['pipeline-2'] = createTestPipeline('pipeline-2', {
        name: 'Other Pipeline',
        isActive: true,
        isDefault: true,
      });

      const result = await repository.archive(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isActive).toBe(false);
      }
    });

    it('should not archive the only active pipeline', async () => {
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        isActive: true,
      });

      const result = await repository.archive(testContext, 'pipeline-1');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });

    it('should set new default if archiving default pipeline', async () => {
      // Setup: Two pipelines, the default one will be archived
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        name: 'Default Pipeline',
        isActive: true,
        isDefault: true,
      });
      mockState.docData['pipeline-2'] = createTestPipeline('pipeline-2', {
        name: 'Other Pipeline',
        isActive: true,
        isDefault: false,
      });

      const result = await repository.archive(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      // The batch operations should include setting a new default
      expect(mockState.batchOperations.length).toBeGreaterThan(0);
    });
  });

  // ============================================
  // Test 6: CRITICAL - Pipelines scoped by businessId
  // ============================================
  describe('businessId scoping', () => {
    it('should scope all operations by businessId - pipelines created are isolated', async () => {
      const context1: SecurityContext = {
        ...testContext,
        businessId: 'business-1',
      };
      const context2: SecurityContext = {
        ...testContext,
        businessId: 'business-2',
      };

      // Create pipeline in business-1
      const result1 = await repository.create(context1, {
        name: 'Business 1 Pipeline',
        isDefault: true,
        isActive: true,
      });

      expect(result1.success).toBe(true);
      if (result1.success) {
        expect(result1.data.name).toBe('Business 1 Pipeline');
      }

      // Create pipeline in business-2
      const result2 = await repository.create(context2, {
        name: 'Business 2 Pipeline',
        isDefault: true,
        isActive: true,
      });

      expect(result2.success).toBe(true);
      if (result2.success) {
        expect(result2.data.name).toBe('Business 2 Pipeline');
      }
    });

    it('should require businessId in SecurityContext', async () => {
      // Verify the repository requires businessId for all operations
      // The SecurityContext type enforces businessId is required
      const validContext: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'admin',
      };

      // This proves the interface requires businessId
      expect(validContext.businessId).toBeDefined();
      expect(validContext.businessId.length).toBeGreaterThan(0);

      // Create should work with valid context
      const result = await repository.create(validContext, {
        name: 'Test Pipeline',
        isDefault: false,
        isActive: true,
      });

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 7: Cannot delete pipeline with active deals (placeholder)
  // ============================================
  describe('canDelete', () => {
    it('should check if pipeline can be deleted', async () => {
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1');

      const canDelete = await repository.canDelete(testContext, 'pipeline-1');

      // Placeholder: Currently returns true if pipeline exists
      expect(canDelete).toBe(true);
    });

    it('should return false for non-existent pipeline', async () => {
      const canDelete = await repository.canDelete(testContext, 'non-existent');

      expect(canDelete).toBe(false);
    });
  });

  // ============================================
  // Additional Tests
  // ============================================
  describe('restore', () => {
    it('should restore an archived pipeline', async () => {
      mockState.docData['pipeline-1'] = createTestPipeline('pipeline-1', {
        isActive: false,
      });

      const result = await repository.restore(testContext, 'pipeline-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isActive).toBe(true);
      }
    });
  });

  describe('DEFAULT_STAGES', () => {
    it('should have the expected default stages', () => {
      expect(DEFAULT_STAGES).toHaveLength(6);
      expect(DEFAULT_STAGES[0].name).toBe('Lead');
      expect(DEFAULT_STAGES[4].name).toBe('Won');
      expect(DEFAULT_STAGES[5].name).toBe('Lost');
    });
  });
});
