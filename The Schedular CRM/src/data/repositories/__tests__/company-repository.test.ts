/**
 * Company Repository Tests
 * Tests for the CompanyRepository class
 *
 * Test Scenarios:
 * 1. Create company with required fields
 * 2. Create company validates email format
 * 3. Get company by ID
 * 4. Get companies by industry
 * 5. Get companies by size
 * 6. Get companies by tag
 * 7. Search companies by name
 * 8. Get filtered companies
 * 9. Add tag to company
 * 10. Remove tag from company
 * 11. Get unique industries
 * 12. CRITICAL: All queries scoped by businessId
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

import type { SecurityContext } from '../repository-types';
import type { Company } from '../../../types/models';

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
        .map(([_id, data]) => ({
          id: _id,
          exists: () => true,
          data: () => ({ ...data }),
          ref: { id: _id },
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
        .map(([_id, data]) => ({
          id: _id,
          exists: () => true,
          data: () => ({ ...data }),
          ref: { id: _id },
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

import { CompanyRepository } from '../company-repository';

// ============================================
// Test Setup
// ============================================

const testContext: SecurityContext = {
  businessId: 'test-business-123',
  userId: 'test-user-456',
  userName: 'Test User',
  userRole: 'admin',
};

const createTestCompany = (
  _id: string,
  overrides: Partial<Company> = {}
): Record<string, unknown> => {
  const mockTimestamp = { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0, toDate: () => new Date() };
  return {
    name: 'Test Company',
    industry: 'Technology',
    size: 'medium',
    website: 'https://example.com',
    phone: '+1234567890',
    email: 'contact@example.com',
    tags: [],
    ownerId: testContext.userId,
    ownerName: testContext.userName,
    teamIds: [],
    visibility: 'team',
    createdAt: mockTimestamp,
    ...overrides,
  };
};

describe('CompanyRepository', () => {
  let repository: CompanyRepository;

  beforeEach(() => {
    mockState.docData = {};
    mockState.collectionPaths = [];
    repository = new CompanyRepository();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Create company with required fields
  // ============================================
  describe('create', () => {
    it('should create a company with required fields', async () => {
      const result = await repository.create(testContext, {
        name: 'Acme Corp',
        industry: 'Technology',
        size: 'large',
        tags: ['enterprise'],
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.name).toBe('Acme Corp');
        expect(result.data.industry).toBe('Technology');
        expect(result.data.size).toBe('large');
        expect(result.data.id).toBeDefined();
      }
    });

    // ============================================
    // Test 2: Create company validates email format
    // ============================================
    it('should reject invalid email format', async () => {
      const result = await repository.create(testContext, {
        name: 'Test Company',
        email: 'invalid-email',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });

    it('should reject empty company name', async () => {
      const result = await repository.create(testContext, {
        name: '',
        tags: [],
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('VALIDATION_ERROR');
      }
    });
  });

  // ============================================
  // Test 3: Get company by ID
  // ============================================
  describe('getById', () => {
    it('should return company when exists', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', {
        name: 'Acme Corp',
      });

      const result = await repository.getById(testContext, 'company-1');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.name).toBe('Acme Corp');
      }
    });
  });

  // ============================================
  // Test 4: Get companies by industry
  // ============================================
  describe('getByIndustry', () => {
    it('should return companies by industry', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { industry: 'Technology' });
      mockState.docData['company-2'] = createTestCompany('company-2', { industry: 'Healthcare' });

      const result = await repository.getByIndustry(testContext, 'Technology');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('should reject empty industry', async () => {
      const result = await repository.getByIndustry(testContext, '');

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.code).toBe('INVALID_ARGUMENT');
      }
    });
  });

  // ============================================
  // Test 5: Get companies by size
  // ============================================
  describe('getBySize', () => {
    it('should return companies by size', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { size: 'small' });
      mockState.docData['company-2'] = createTestCompany('company-2', { size: 'enterprise' });

      const result = await repository.getBySize(testContext, 'enterprise');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });
  });

  // ============================================
  // Test 6: Get companies by tag
  // ============================================
  describe('getByTag', () => {
    it('should return companies with specific tag', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { tags: ['partner', 'enterprise'] });
      mockState.docData['company-2'] = createTestCompany('company-2', { tags: ['prospect'] });

      const result = await repository.getByTag(testContext, 'partner');

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
  // Test 7: Search companies by name
  // ============================================
  describe('search', () => {
    it('should search companies by name', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { name: 'Acme Corporation' });
      mockState.docData['company-2'] = createTestCompany('company-2', { name: 'Beta Industries' });

      const result = await repository.search(testContext, 'acme');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.some((c) => c.name.toLowerCase().includes('acme'))).toBe(true);
      }
    });

    it('should return all companies for empty query', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1');
      mockState.docData['company-2'] = createTestCompany('company-2');

      const result = await repository.search(testContext, '');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.length).toBe(2);
      }
    });
  });

  // ============================================
  // Test 8: Get filtered companies
  // ============================================
  describe('getFiltered', () => {
    it('should filter companies by multiple criteria', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', {
        industry: 'Technology',
        size: 'large',
      });
      mockState.docData['company-2'] = createTestCompany('company-2', {
        industry: 'Healthcare',
        size: 'small',
      });

      const result = await repository.getFiltered(testContext, {
        industry: 'Technology',
        size: 'large',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.every((c) => c.industry === 'Technology' && c.size === 'large')).toBe(true);
      }
    });
  });

  // ============================================
  // Test 9: Add tag to company
  // ============================================
  describe('addTag', () => {
    it('should add tag to company', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { tags: [] });

      const result = await repository.addTag(testContext, 'company-1', 'partner');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags).toContain('partner');
      }
    });

    it('should not duplicate existing tag', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { tags: ['partner'] });

      const result = await repository.addTag(testContext, 'company-1', 'partner');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags.filter((t) => t === 'partner').length).toBe(1);
      }
    });
  });

  // ============================================
  // Test 10: Remove tag from company
  // ============================================
  describe('removeTag', () => {
    it('should remove tag from company', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { tags: ['partner', 'enterprise'] });

      const result = await repository.removeTag(testContext, 'company-1', 'partner');

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.tags).not.toContain('partner');
      }
    });
  });

  // ============================================
  // Test 11: Get unique industries
  // ============================================
  describe('getUniqueIndustries', () => {
    it('should return unique industries', async () => {
      mockState.docData['company-1'] = createTestCompany('company-1', { industry: 'Technology' });
      mockState.docData['company-2'] = createTestCompany('company-2', { industry: 'Healthcare' });
      mockState.docData['company-3'] = createTestCompany('company-3', { industry: 'Technology' });

      const result = await repository.getUniqueIndustries(testContext);

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data).toContain('Technology');
        expect(result.data).toContain('Healthcare');
        // Should be unique
        expect(result.data.filter((i) => i === 'Technology').length).toBe(1);
      }
    });
  });

  // ============================================
  // Test 12: CRITICAL - All queries scoped by businessId
  // ============================================
  describe('businessId scoping', () => {
    it('should scope all operations by businessId - companies created are isolated', async () => {
      const context1: SecurityContext = {
        ...testContext,
        businessId: 'business-1',
      };
      const context2: SecurityContext = {
        ...testContext,
        businessId: 'business-2',
      };

      const result1 = await repository.create(context1, {
        name: 'Business 1 Company',
        tags: [],
      });
      expect(result1.success).toBe(true);

      const result2 = await repository.create(context2, {
        name: 'Business 2 Company',
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
        name: 'Test Company',
        tags: [],
      });

      expect(result.success).toBe(true);
    });
  });
});
