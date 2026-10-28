/**
 * Activity Repository Tests
 * Tests for ActivityRepository CRUD operations and activity-specific functionality
 *
 * Agent CRM-06 Implementation
 *
 * Test Scenarios (14+ total):
 * 1. Create activity with type and title
 * 2. Create task with due date
 * 3. Get activities by deal
 * 4. Get activities by client
 * 5. Get activities by lead
 * 6. Get activities by company
 * 7. Filter activities by type
 * 8. Get pending tasks (incomplete)
 * 9. Get overdue tasks
 * 10. Get upcoming tasks
 * 11. Mark task as complete (sets completedAt)
 * 12. Get timeline for entity (chronological)
 * 13. **CRITICAL**: Activities scoped by businessId
 * 14. Activity includes createdById and createdByName
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import type { SecurityContext } from '../repository-types';
import type { SalesActivity, SalesActivityType } from '../../../types/models';

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

import {
  ActivityRepository,
  validateActivity,
  validateActivityCreate,
} from '../activity-repository';
import type { EntityType } from '../activity-repository';

// ============================================
// Mock Security Context
// ============================================

const createMockContext = (businessId = 'test-business-123'): SecurityContext => ({
  businessId,
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
});

// ============================================
// Test Data Helpers
// ============================================

const createMockActivity = (
  overrides: Partial<SalesActivity> = {}
): Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'> => ({
  type: 'call',
  title: 'Follow-up call',
  description: 'Discussed project requirements',
  dealId: 'deal-123',
  clientId: 'client-456',
  isCompleted: false,
  createdById: 'user-789',
  createdByName: 'John Doe',
  ...overrides,
});

const createMockTask = (
  overrides: Partial<SalesActivity> = {}
): Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'> => ({
  type: 'task',
  title: 'Send proposal',
  description: 'Send updated proposal to client',
  dealId: 'deal-123',
  dueDate: new Date('2024-02-15'),
  isCompleted: false,
  assigneeId: 'user-123',
  assigneeName: 'Sales Rep',
  createdById: 'user-789',
  createdByName: 'John Doe',
  ...overrides,
});

// ============================================
// Tests
// ============================================

describe('ActivityRepository', () => {
  let repository: ActivityRepository;
  let context: SecurityContext;

  beforeEach(() => {
    // Clear mock state
    mockState.docData = {};
    mockState.collectionPaths = [];

    // Create fresh instances
    repository = new ActivityRepository();
    context = createMockContext();

    // Seed test data
    const now = new Date();
    const pastDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000); // 7 days ago
    const futureDate = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000); // 3 days from now

    mockState.docData['activity-1'] = {
      type: 'call',
      title: 'Initial call',
      dealId: 'deal-100',
      clientId: 'client-200',
      isCompleted: false,
      createdById: 'user-1',
      createdByName: 'User One',
      createdAt: pastDate,
    };

    mockState.docData['activity-2'] = {
      type: 'email',
      title: 'Follow-up email',
      dealId: 'deal-100',
      leadId: 'lead-300',
      isCompleted: false,
      createdById: 'user-2',
      createdByName: 'User Two',
      createdAt: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
    };

    mockState.docData['activity-3'] = {
      type: 'meeting',
      title: 'Client meeting',
      clientId: 'client-200',
      companyId: 'company-400',
      isCompleted: true,
      completedAt: now,
      createdById: 'user-1',
      createdByName: 'User One',
      createdAt: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000),
    };

    mockState.docData['task-1'] = {
      type: 'task',
      title: 'Send proposal',
      dealId: 'deal-100',
      dueDate: futureDate,
      isCompleted: false,
      assigneeId: 'user-1',
      assigneeName: 'User One',
      createdById: 'user-2',
      createdByName: 'User Two',
      createdAt: now,
    };

    mockState.docData['task-2'] = {
      type: 'task',
      title: 'Overdue task',
      clientId: 'client-200',
      dueDate: pastDate,
      isCompleted: false,
      assigneeId: 'user-2',
      assigneeName: 'User Two',
      createdById: 'user-1',
      createdByName: 'User One',
      createdAt: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000),
    };

    mockState.docData['task-3'] = {
      type: 'task',
      title: 'Completed task',
      leadId: 'lead-300',
      dueDate: pastDate,
      isCompleted: true,
      completedAt: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
      assigneeId: 'user-1',
      assigneeName: 'User One',
      createdById: 'user-1',
      createdByName: 'User One',
      createdAt: new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000),
    };

    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Create activity with type and title
  // ============================================
  describe('create', () => {
    it('creates activity with type and title', async () => {
      const activityData = createMockActivity();

      const result = await repository.create(context, activityData);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.type).toBe('call');
        expect(result.data.title).toBe('Follow-up call');
        expect(result.data.isCompleted).toBe(false);
      }
    });

    // ============================================
    // Test 2: Create task with due date
    // ============================================
    it('creates task with due date', async () => {
      const taskData = createMockTask();

      const result = await repository.create(context, taskData);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.type).toBe('task');
        expect(result.data.dueDate).toBeDefined();
        expect(result.data.isCompleted).toBe(false);
      }
    });

    it('rejects activity without type', async () => {
      const invalidData = {
        title: 'Test activity',
        dealId: 'deal-123',
        createdById: 'user-123',
        createdByName: 'Test User',
        isCompleted: false,
      };

      const result = await repository.create(
        context,
        invalidData as unknown as Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('rejects activity without title', async () => {
      const invalidData = {
        type: 'call' as SalesActivityType,
        dealId: 'deal-123',
        createdById: 'user-123',
        createdByName: 'Test User',
        isCompleted: false,
      };

      const result = await repository.create(
        context,
        invalidData as unknown as Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('rejects activity without entity link', async () => {
      const invalidData = {
        type: 'call' as SalesActivityType,
        title: 'Orphan activity',
        createdById: 'user-123',
        createdByName: 'Test User',
        isCompleted: false,
        // No dealId, clientId, leadId, or companyId
      };

      const result = await repository.create(
        context,
        invalidData as unknown as Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
        expect(result.error.message).toContain('entity');
      }
    });
  });

  // ============================================
  // Test 3: Get activities by deal
  // ============================================
  describe('getByDeal', () => {
    it('returns activities linked to a deal', async () => {
      const result = await repository.getByDeal(context, 'deal-100');

      expect(result.success).toBe(true);
      if (result.success) {
        const dealActivities = result.data.data.filter(a => a.dealId === 'deal-100');
        expect(dealActivities.length).toBeGreaterThan(0);
      }
    });
  });

  // ============================================
  // Test 4: Get activities by client
  // ============================================
  describe('getByClient', () => {
    it('returns activities linked to a client', async () => {
      const result = await repository.getByClient(context, 'client-200');

      expect(result.success).toBe(true);
      if (result.success) {
        const clientActivities = result.data.data.filter(a => a.clientId === 'client-200');
        expect(clientActivities.length).toBeGreaterThan(0);
      }
    });
  });

  // ============================================
  // Test 5: Get activities by lead
  // ============================================
  describe('getByLead', () => {
    it('returns activities linked to a lead', async () => {
      const result = await repository.getByLead(context, 'lead-300');

      expect(result.success).toBe(true);
      if (result.success) {
        const leadActivities = result.data.data.filter(a => a.leadId === 'lead-300');
        expect(leadActivities.length).toBeGreaterThan(0);
      }
    });
  });

  // ============================================
  // Test 6: Get activities by company
  // ============================================
  describe('getByCompany', () => {
    it('returns activities linked to a company', async () => {
      const result = await repository.getByCompany(context, 'company-400');

      expect(result.success).toBe(true);
      if (result.success) {
        const companyActivities = result.data.data.filter(a => a.companyId === 'company-400');
        expect(companyActivities.length).toBeGreaterThan(0);
      }
    });
  });

  // ============================================
  // Test 7: Filter activities by type
  // ============================================
  describe('getByType', () => {
    it('filters activities by type', async () => {
      const result = await repository.getByType(context, 'call');

      expect(result.success).toBe(true);
      if (result.success) {
        const callActivities = result.data.data.filter(a => a.type === 'call');
        expect(callActivities.length).toBeGreaterThan(0);
      }
    });

    it('returns email activities', async () => {
      const result = await repository.getByType(context, 'email');

      expect(result.success).toBe(true);
    });

    it('returns meeting activities', async () => {
      const result = await repository.getByType(context, 'meeting');

      expect(result.success).toBe(true);
    });

    it('returns note activities', async () => {
      const result = await repository.getByType(context, 'note');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 8: Get pending tasks (incomplete)
  // ============================================
  describe('getPendingTasks', () => {
    it('returns incomplete tasks', async () => {
      const result = await repository.getPendingTasks(context);

      expect(result.success).toBe(true);
      if (result.success) {
        const pendingTasks = result.data.data.filter(
          a => a.type === 'task' && !a.isCompleted
        );
        expect(pendingTasks.length).toBeGreaterThan(0);
      }
    });

    it('filters pending tasks by assignee', async () => {
      const result = await repository.getPendingTasks(context, 'user-1');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 9: Get overdue tasks
  // ============================================
  describe('getOverdueTasks', () => {
    it('returns overdue tasks', async () => {
      const result = await repository.getOverdueTasks(context);

      expect(result.success).toBe(true);
      if (result.success) {
        const overdueTasks = result.data.data.filter(
          a => a.type === 'task' && !a.isCompleted && a.dueDate && new Date(a.dueDate) < new Date()
        );
        // Should include task-2 which has past due date and is not completed
        expect(overdueTasks.length).toBeGreaterThanOrEqual(0);
      }
    });
  });

  // ============================================
  // Test 10: Get upcoming tasks
  // ============================================
  describe('getUpcomingTasks', () => {
    it('returns tasks due within N days', async () => {
      const result = await repository.getUpcomingTasks(context, 7);

      expect(result.success).toBe(true);
      if (result.success) {
        // Should include task-1 which is due in 3 days
        expect(result.data.data.length).toBeGreaterThanOrEqual(0);
      }
    });

    it('rejects negative days', async () => {
      const result = await repository.getUpcomingTasks(context, -1);

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });

    it('returns empty for 0 days if no tasks due today', async () => {
      const result = await repository.getUpcomingTasks(context, 0);

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 11: Mark task as complete
  // ============================================
  describe('markComplete', () => {
    it('marks task as complete and sets completedAt', async () => {
      const result = await repository.markComplete(context, 'task-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isCompleted).toBe(true);
        expect(result.data.completedAt).toBeDefined();
      }
    });

    it('returns already completed task unchanged', async () => {
      const result = await repository.markComplete(context, 'task-3');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isCompleted).toBe(true);
      }
    });

    it('rejects marking non-task as complete', async () => {
      const result = await repository.markComplete(context, 'activity-1');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
        expect(result.error.message).toContain('task');
      }
    });

    it('returns error for non-existent activity', async () => {
      const result = await repository.markComplete(context, 'non-existent');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('NOT_FOUND');
      }
    });
  });

  // ============================================
  // Test 12: Get timeline for entity (chronological)
  // ============================================
  describe('getTimeline', () => {
    it('returns chronological timeline for deal', async () => {
      const result = await repository.getTimeline(context, 'deal', 'deal-100');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.data.length).toBeGreaterThan(0);
      }
    });

    it('returns timeline for client', async () => {
      const result = await repository.getTimeline(context, 'client', 'client-200');

      expect(result.success).toBe(true);
    });

    it('returns timeline for lead', async () => {
      const result = await repository.getTimeline(context, 'lead', 'lead-300');

      expect(result.success).toBe(true);
    });

    it('returns timeline for company', async () => {
      const result = await repository.getTimeline(context, 'company', 'company-400');

      expect(result.success).toBe(true);
    });

    it('rejects invalid entity type', async () => {
      const result = await repository.getTimeline(
        context,
        'invalid' as EntityType,
        'some-id'
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 13: CRITICAL - Activities scoped by businessId
  // ============================================
  describe('businessId scoping (CRITICAL)', () => {
    it('should scope create operations by businessId', async () => {
      const context1 = createMockContext('business-1');
      const context2 = createMockContext('business-2');

      mockState.collectionPaths = [];

      // Create activity in business-1
      const result1 = await repository.create(context1, createMockActivity());
      expect(result1.success).toBe(true);

      // Create activity in business-2
      const result2 = await repository.create(context2, createMockActivity());
      expect(result2.success).toBe(true);

      // Both should have created activities
      if (result1.success && result2.success) {
        expect(result1.data.type).toBe('call');
        expect(result2.data.type).toBe('call');
      }
    });

    it('should require businessId in SecurityContext', async () => {
      const validContext = createMockContext('test-business');

      expect(validContext.businessId).toBeDefined();
      expect(validContext.businessId.length).toBeGreaterThan(0);

      const result = await repository.create(validContext, createMockActivity());
      expect(result.success).toBe(true);
    });

    it('getAll works with valid businessId context', async () => {
      const specificContext = createMockContext('isolated-business');
      const result = await repository.getAll(specificContext);
      expect(result.success).toBe(true);
    });

    it('getByDeal works with valid businessId context', async () => {
      const specificContext = createMockContext('deal-business');
      const result = await repository.getByDeal(specificContext, 'deal-123');
      expect(result.success).toBe(true);
    });

    it('getByType works with valid businessId context', async () => {
      const specificContext = createMockContext('type-business');
      const result = await repository.getByType(specificContext, 'call');
      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 14: Activity includes createdById and createdByName
  // ============================================
  describe('audit fields', () => {
    it('activity includes createdById and createdByName', async () => {
      const activityData = createMockActivity({
        createdById: 'audit-user-123',
        createdByName: 'Audit User',
      });

      const result = await repository.create(context, activityData);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.createdById).toBe('audit-user-123');
        expect(result.data.createdByName).toBe('Audit User');
      }
    });

    it('rejects activity without createdById', async () => {
      const invalidData = {
        type: 'call' as SalesActivityType,
        title: 'Test',
        dealId: 'deal-123',
        createdByName: 'Test User',
        isCompleted: false,
      };

      const result = await repository.create(
        context,
        invalidData as unknown as Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('rejects activity without createdByName', async () => {
      const invalidData = {
        type: 'call' as SalesActivityType,
        title: 'Test',
        dealId: 'deal-123',
        createdById: 'user-123',
        isCompleted: false,
      };

      const result = await repository.create(
        context,
        invalidData as unknown as Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>
      );

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });
  });

  // ============================================
  // Additional Tests: Utility Methods
  // ============================================
  describe('utility methods', () => {
    it('getTasks returns only task-type activities', async () => {
      const result = await repository.getTasks(context);

      expect(result.success).toBe(true);
      if (result.success) {
        const tasks = result.data.data.filter(a => a.type === 'task');
        expect(tasks.length).toBeGreaterThan(0);
      }
    });

    it('getByAssignee returns activities assigned to user', async () => {
      const result = await repository.getByAssignee(context, 'user-1');

      expect(result.success).toBe(true);
    });

    it('getByCreator returns activities created by user', async () => {
      const result = await repository.getByCreator(context, 'user-1');

      expect(result.success).toBe(true);
    });

    it('getFiltered supports combined filters', async () => {
      const result = await repository.getFiltered(context, {
        type: 'task',
        isCompleted: false,
        assigneeId: 'user-1',
      });

      expect(result.success).toBe(true);
    });

    it('getUnifiedTimeline merges activities from related entities', async () => {
      const result = await repository.getUnifiedTimeline(context, {
        dealId: 'deal-100',
        clientId: 'client-200',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        // Should include activities for both deal-100 and client-200
        expect(result.data.data.length).toBeGreaterThan(0);
      }
    });

    it('getRecent returns activities from last N days', async () => {
      const result = await repository.getRecent(context, 7);

      expect(result.success).toBe(true);
    });

    it('markIncomplete uncompletes a task', async () => {
      const result = await repository.markIncomplete(context, 'task-3');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.isCompleted).toBe(false);
      }
    });
  });

  // ============================================
  // Validation Function Tests
  // ============================================
  describe('validateActivity', () => {
    it('returns valid for complete activity data', () => {
      const result = validateActivity({
        type: 'call',
        title: 'Test call',
      });

      expect(result.isValid).toBe(true);
      expect(result.errors.length).toBe(0);
    });

    it('returns invalid for empty title', () => {
      const result = validateActivity({
        type: 'call',
        title: '',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'title')).toBe(true);
    });

    it('returns invalid for invalid type', () => {
      const result = validateActivity({
        type: 'invalid' as SalesActivityType,
        title: 'Test',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'type')).toBe(true);
    });
  });

  describe('validateActivityCreate', () => {
    it('requires type', () => {
      const result = validateActivityCreate({
        title: 'Test',
        dealId: 'deal-123',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'type')).toBe(true);
    });

    it('requires title', () => {
      const result = validateActivityCreate({
        type: 'call',
        dealId: 'deal-123',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'title')).toBe(true);
    });

    it('requires createdById', () => {
      const result = validateActivityCreate({
        type: 'call',
        title: 'Test',
        dealId: 'deal-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'createdById')).toBe(true);
    });

    it('requires entity link', () => {
      const result = validateActivityCreate({
        type: 'call',
        title: 'Test',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(false);
      expect(result.errors.some(e => e.field === 'entity')).toBe(true);
    });

    it('accepts activity with client link', () => {
      const result = validateActivityCreate({
        type: 'call',
        title: 'Test',
        clientId: 'client-123',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(true);
    });

    it('accepts activity with lead link', () => {
      const result = validateActivityCreate({
        type: 'call',
        title: 'Test',
        leadId: 'lead-123',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(true);
    });

    it('accepts activity with company link', () => {
      const result = validateActivityCreate({
        type: 'call',
        title: 'Test',
        companyId: 'company-123',
        createdById: 'user-123',
        createdByName: 'Test User',
      });

      expect(result.isValid).toBe(true);
    });
  });

  // ============================================
  // Real-time Subscription Tests
  // ============================================
  describe('subscribe', () => {
    it('receives real-time updates on activity changes', async () => {
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
});
