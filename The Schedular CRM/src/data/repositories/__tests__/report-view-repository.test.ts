/**
 * Report View Repository Tests
 * Verifies RBAC for saved report views with owner/team sharing
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import type { SecurityContext } from '../repository-types';
import type { ReportView } from '../../../types/models';

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
        data: () => (data ? { ...data } : undefined),
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
    onSnapshot: vi.fn(),
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

import { ReportViewRepository } from '../report-view-repository';

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: ['team-a'],
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: ['team-a'],
};

const managerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'manager-1',
  userName: 'Manager User',
  userRole: 'manager',
  teamIds: [],
  managedTeamIds: ['team-b'],
};

const otherStaffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-2',
  userName: 'Other Staff',
  userRole: 'staff',
  teamIds: ['team-b'],
};

const createTestView = (
  _id: string,
  overrides: Partial<ReportView> = {}
): Record<string, unknown> => {
  const mockTimestamp = { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0, toDate: () => new Date() };
  return {
    name: 'Pipeline Health',
    description: 'Wins by pipeline',
    filters: {},
    ownerId: staffContext.userId,
    ownerName: staffContext.userName,
    teamIds: ['team-a'],
    createdAt: mockTimestamp,
    ...overrides,
  };
};

describe('ReportViewRepository', () => {
  let repository: ReportViewRepository;

  beforeEach(() => {
    mockState.docData = {};
    mockState.collectionPaths = [];
    repository = new ReportViewRepository();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('creates a report view and assigns ownership defaults', async () => {
    const result = await repository.create(staffContext, {
      name: 'My Deals',
      filters: { pipelineId: 'pipe-1', statuses: ['open'] },
      teamIds: ['team-a', 'team-a'],
    });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.ownerId).toBe(staffContext.userId);
      expect(result.data.teamIds).toEqual(['team-a']);
      expect(result.data.filters.pipelineId).toBe('pipe-1');
    }
  });

  it('filters accessible views by owner and shared teams', async () => {
    mockState.docData = {
      'view-1': createTestView('view-1', { ownerId: staffContext.userId, teamIds: [] }),
      'view-2': createTestView('view-2', { ownerId: otherStaffContext.userId, teamIds: ['team-b'] }),
      'view-3': createTestView('view-3', { ownerId: otherStaffContext.userId, teamIds: ['team-a'] }),
    };

    const result = await repository.getAccessible(staffContext, staffContext.teamIds);

    expect(result.success).toBe(true);
    if (result.success) {
      const ids = result.data.map((view) => view.ownerId);
      expect(result.data).toHaveLength(2);
      expect(ids).toContain(staffContext.userId);
      expect(ids).toContain(otherStaffContext.userId);
    }
  });

  it('allows managers to access views shared with managed teams', async () => {
    mockState.docData = {
      'view-1': createTestView('view-1', { ownerId: otherStaffContext.userId, teamIds: ['team-b'] }),
    };

    const result = await repository.getAccessible(managerContext, managerContext.managedTeamIds);

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).toHaveLength(1);
      expect(result.data[0].ownerId).toBe(otherStaffContext.userId);
    }
  });

  it('prevents staff from updating a view they do not own or share', async () => {
    mockState.docData = {
      'view-1': createTestView('view-1', { ownerId: otherStaffContext.userId, teamIds: ['team-b'] }),
    };

    const result = await repository.update(staffContext, 'view-1', { name: 'Unauthorized edit' });

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('allows admin to delete any view', async () => {
    mockState.docData = {
      'view-1': createTestView('view-1', { ownerId: otherStaffContext.userId, teamIds: ['team-b'] }),
    };

    const result = await repository.delete(adminContext, 'view-1');
    expect(result.success).toBe(true);
  });

  it('denies access when view is not owned or shared', async () => {
    mockState.docData = {
      'view-1': createTestView('view-1', { ownerId: otherStaffContext.userId, teamIds: ['team-b'] }),
    };

    const result = await repository.getById(staffContext, 'view-1', staffContext.teamIds);

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });
});
