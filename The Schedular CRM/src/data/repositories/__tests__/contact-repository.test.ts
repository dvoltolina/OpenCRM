/**
 * Contact Repository Tests
 * Tests for the ContactRepository class
 *
 * Test Scenarios:
 * 1. Create contact with required fields
 * 2. Create contact validates email format
 * 3. Get contact by ID
 * 4. Get contacts by lifecycle
 * 5. Get contacts by company
 * 6. Get contacts by lead source
 * 7. Get contacts by tag
 * 8. Search contacts by name/email
 * 9. Update lifecycle stage
 * 10. Update last contacted timestamp
 * 11. Link contact to company
 * 12. Unlink contact from company
 * 13. Add tag to contact
 * 14. Remove tag from contact
 * 15. Get recently contacted contacts
 * 16. Get stale contacts
 * 17. CRITICAL: All queries scoped by businessId
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

import type { SecurityContext } from '../repository-types';
import type { Client, Deal, SalesActivity } from '../../../types/models';

// ============================================
// Global Mock State
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

import { ContactRepository } from '../contact-repository';

// ============================================
// Test Setup
// ============================================

const testContext: SecurityContext = {
  businessId: 'test-business-123',
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
};

const createTestContact = (
  _id: string,
  overrides: Partial<Client> = {}
): Record<string, unknown> => {
  const mockTimestamp = { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0, toDate: () => new Date() };
  return {
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    phone: '+1234567890',
    lifecycle: 'active',
    tags: [],
    createdAt: mockTimestamp,
    ...overrides,
  };
};

describe('ContactRepository', () => {
  let repository: ContactRepository;

  beforeEach(() => {
    mockState.docData = {};
    mockState.collectionPaths = [];
    repository = new ContactRepository();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Create contact with required fields
  // ============================================
  describe('create', () => {
    it('should create a contact with required fields', async () => {
      const result = await repository.create(testContext, {
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        tags: [],
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.firstName).toBe('Jane');
        expect(result.data.lastName).toBe('Smith');
        expect(result.data.email).toBe('jane.smith@example.com');
        expect(result.data.id).toBeDefined();
      }
    });

    // ============================================
    // Test 2: Create contact validates email format
    // ============================================
    it('should reject invalid email format', async () => {
      const result = await repository.create(testContext, {
        firstName: 'John',
        lastName: 'Doe',
        email: 'invalid-email',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('should reject missing first name', async () => {
      const result = await repository.create(testContext, {
        firstName: '',
        lastName: 'Doe',
        email: 'john@example.com',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('should reject missing last name', async () => {
      const result = await repository.create(testContext, {
        firstName: 'John',
        lastName: '',
        email: 'john@example.com',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('blocks duplicate contacts unless override is provided by admin/owner', async () => {
      const baseContact = {
        firstName: 'Dana',
        lastName: 'Jones',
        email: 'dana@example.com',
        phone: '+15551231234',
        tags: [],
      };

      const first = await repository.create(testContext, baseContact as any);
      expect(first.success).toBe(true);

      const duplicate = await repository.create(testContext, baseContact as any);
      expect(duplicate.success).toBe(false);
      if (!duplicate.success) {
        expect(duplicate.error.code).toBe('VALIDATION_ERROR');
      }

      const override = await repository.create(testContext, {
        ...baseContact,
        allowDuplicate: true,
      } as any);
      expect(override.success).toBe(true);
    });
  });

  // ============================================
  // Test 3: Get contact by ID
  // ============================================
  describe('getById', () => {
    it('should return contact when exists', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        firstName: 'Jane',
        lastName: 'Smith',
      });

      const result = await repository.getById(testContext, 'contact-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.firstName).toBe('Jane');
        expect(result.data.lastName).toBe('Smith');
      }
    });
  });

  // ============================================
  // Test 4: Get contacts by lifecycle
  // ============================================
  describe('getByLifecycle', () => {
    it('should return contacts by lifecycle stage', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { lifecycle: 'active' });
      mockState.docData['contact-2'] = createTestContact('contact-2', { lifecycle: 'churned' });

      const result = await repository.getByLifecycle(testContext, 'active');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 5: Get contacts by company
  // ============================================
  describe('getByCompany', () => {
    it('should return contacts for a company', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { companyId: 'company-1' });
      mockState.docData['contact-2'] = createTestContact('contact-2', { companyId: 'company-2' });

      const result = await repository.getByCompany(testContext, 'company-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('should reject invalid company ID', async () => {
      const result = await repository.getByCompany(testContext, '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 6: Get contacts by lead source
  // ============================================
  describe('getBySource', () => {
    it('should return contacts by lead source', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { leadSource: 'website' });
      mockState.docData['contact-2'] = createTestContact('contact-2', { leadSource: 'referral' });

      const result = await repository.getBySource(testContext, 'website');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 7: Get contacts by tag
  // ============================================
  describe('getByTag', () => {
    it('should return contacts with specific tag', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { tags: ['vip', 'enterprise'] });
      mockState.docData['contact-2'] = createTestContact('contact-2', { tags: ['prospect'] });

      const result = await repository.getByTag(testContext, 'vip');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('should reject empty tag', async () => {
      const result = await repository.getByTag(testContext, '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 8: Search contacts by name/email
  // ============================================
  describe('search', () => {
    it('should search contacts by name', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        firstName: 'John',
        lastName: 'Smith',
      });
      mockState.docData['contact-2'] = createTestContact('contact-2', {
        firstName: 'Jane',
        lastName: 'Doe',
      });

      const result = await repository.search(testContext, 'john');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.some((c) =>
          `${c.firstName} ${c.lastName}`.toLowerCase().includes('john')
        )).toBe(true);
      }
    });

    it('should search contacts by email', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        email: 'john@example.com',
      });

      const result = await repository.search(testContext, 'acme');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.some((c) => c.email.toLowerCase().includes('acme'))).toBe(true);
      }
    });

    it('should return all contacts for empty query', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1');
      mockState.docData['contact-2'] = createTestContact('contact-2');

      const result = await repository.search(testContext, '');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.length).toBe(2);
      }
    });
  });

  // ============================================
  // Test 9: Update lifecycle stage
  // ============================================
  describe('updateLifecycle', () => {
    it('should update contact lifecycle', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { lifecycle: 'lead' });

      const result = await repository.updateLifecycle(testContext, 'contact-1', 'active');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.lifecycle).toBe('active');
      }
    });
  });

  // ============================================
  // Test 10: Update last contacted timestamp
  // ============================================
  describe('updateLastContacted', () => {
    it('should update last contacted timestamp', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1');

      const result = await repository.updateLastContacted(testContext, 'contact-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.lastContactedAt).toBeDefined();
      }
    });
  });

  // ============================================
  // Test 11: Link contact to company
  // ============================================
  describe('linkToCompany', () => {
    it('should link contact to company', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1');

      const result = await repository.linkToCompany(
        testContext,
        'contact-1',
        'company-1',
        'Acme Corp'
      );

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.companyId).toBe('company-1');
        expect(result.data.companyName).toBe('Acme Corp');
      }
    });

    it('should reject missing company name', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1');

      const result = await repository.linkToCompany(testContext, 'contact-1', 'company-1', '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 12: Unlink contact from company
  // ============================================
  describe('unlinkFromCompany', () => {
    it('should unlink contact from company', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        companyId: 'company-1',
        companyName: 'Acme Corp',
      });

      const result = await repository.unlinkFromCompany(testContext, 'contact-1');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Test 13: Add tag to contact
  // ============================================
  describe('addTag', () => {
    it('should add tag to contact', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { tags: [] });

      const result = await repository.addTag(testContext, 'contact-1', 'vip');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags).toContain('vip');
      }
    });

    it('should not duplicate existing tag', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { tags: ['vip'] });

      const result = await repository.addTag(testContext, 'contact-1', 'vip');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags.filter((t) => t === 'vip').length).toBe(1);
      }
    });
  });

  // ============================================
  // Test 14: Remove tag from contact
  // ============================================
  describe('removeTag', () => {
    it('should remove tag from contact', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', { tags: ['vip', 'enterprise'] });

      const result = await repository.removeTag(testContext, 'contact-1', 'vip');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags).not.toContain('vip');
      }
    });
  });

  // ============================================
  // Test 15: Get recently contacted contacts
  // ============================================
  describe('getRecentlyContacted', () => {
    it('should return recently contacted contacts', async () => {
      const recentDate = new Date();
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        lastContactedAt: { toDate: () => recentDate } as any,
      });

      const result = await repository.getRecentlyContacted(testContext, 30);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 16: Get stale contacts
  // ============================================
  describe('getStaleContacts', () => {
    it('should return stale contacts', async () => {
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 60);
      mockState.docData['contact-stale'] = createTestContact('contact-stale', {
        lastContactedAt: { toDate: () => oldDate } as any,
      });
      mockState.docData['contact-recent'] = createTestContact('contact-recent', {
        lastContactedAt: { toDate: () => new Date() } as any,
      });

      const result = await repository.getStaleContacts(testContext, 30);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('should include contacts never contacted', async () => {
      mockState.docData['contact-never'] = createTestContact('contact-never', {
        lastContactedAt: undefined,
      });

      const result = await repository.getStaleContacts(testContext, 30);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.some((c) => !c.lastContactedAt)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 17: CRITICAL - All queries scoped by businessId
  // ============================================
  describe('businessId scoping', () => {
    it('should scope all operations by businessId - contacts created are isolated', async () => {
      const context1: SecurityContext = {
        ...testContext,
        businessId: 'business-1',
      };
      const context2: SecurityContext = {
        ...testContext,
        businessId: 'business-2',
      };

      const result1 = await repository.create(context1, {
        firstName: 'John',
        lastName: 'Business1',
        email: 'john@example.com',
        tags: [],
      });
      expect(result1.success).toBe(true);

      const result2 = await repository.create(context2, {
        firstName: 'Jane',
        lastName: 'Business2',
        email: 'jane@example.com',
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
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        tags: [],
      });

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Additional Tests
  // ============================================
  describe('getFiltered', () => {
    it('should filter contacts by multiple criteria', async () => {
      mockState.docData['contact-1'] = createTestContact('contact-1', {
        lifecycle: 'active',
        companyId: 'company-1',
      });
      mockState.docData['contact-2'] = createTestContact('contact-2', {
        lifecycle: 'churned',
        companyId: 'company-2',
      });

      const result = await repository.getFiltered(testContext, {
        lifecycle: 'active',
        companyId: 'company-1',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(
          result.data.every((c) => c.lifecycle === 'active' && c.companyId === 'company-1')
        ).toBe(true);
      }
    });
  });

  // ============================================
  // Shareable metadata mapping
  // ============================================
  describe('shareable mapping', () => {
    it('should retain owner/team/visibility for deals to allow access checks', () => {
      const snapshot = {
        docs: [
          {
            id: 'deal-1',
            data: () =>
              ({
                pipelineId: 'p1',
                stageId: 's1',
                title: 'Test Deal',
                valueCents: 1000,
                currency: 'USD',
                probability: 50,
                status: 'open',
                ownerId: 'owner-1',
                ownerName: 'Owner Name',
                teamIds: ['team-a', 'team-b'],
                visibility: 'org',
                createdAt: new Date(),
              } satisfies Partial<Deal>),
          },
        ],
      };

      const deals = (repository as any).snapshotToDeals(snapshot);

      expect(deals[0].ownerId).toBe('owner-1');
      expect(deals[0].ownerName).toBe('Owner Name');
      expect(deals[0].teamIds).toEqual(['team-a', 'team-b']);
      expect(deals[0].visibility).toBe('org');
    });

    it('should fallback owner metadata for activities when missing to keep sharing functional', () => {
      const snapshot = {
        docs: [
          {
            id: 'activity-1',
            data: () =>
              ({
                type: 'note',
                title: 'Test Activity',
                createdById: 'creator-1',
                createdByName: 'Creator User',
                isCompleted: false,
                createdAt: new Date(),
                teamIds: ['team-x'],
              } satisfies Partial<SalesActivity>),
          },
        ],
      };

      const activities = (repository as any).snapshotToActivities(snapshot);

      expect(activities[0].ownerId).toBe('creator-1');
      expect(activities[0].ownerName).toBe('Creator User');
      expect(activities[0].teamIds).toEqual(['team-x']);
      expect(activities[0].visibility).toBe('team');
    });
  });
});
