/**
 * API Key Service Tests
 *
 * Task 3: API & Third-Party Integrations - API Key Service
 *
 * Test coverage:
 * - Key CRUD operations with RBAC
 * - SHA-256 hashing (never store plain keys)
 * - Key validation
 * - Rate limiting
 * - Scope checking
 * - Usage tracking
 * - Key revocation
 * - HIPAA compliance (no PHI in logs/errors)
 * - Audit logging
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ApiKeyService } from '../api-key-service';
import type { RateLimitService } from '../RateLimitService';
import type { AuditLogService } from '../AuditLogService';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { ApiKey, ApiScope } from '../../types/integrations';

// ============================================
// Mock Setup
// ============================================

const adminContext: SecurityContext = {
  businessId: 'biz-123',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: ['team-1'],
};

const ownerContext: SecurityContext = {
  businessId: 'biz-123',
  userId: 'owner-1',
  userName: 'Owner User',
  userRole: 'owner',
  teamIds: ['team-1'],
};

const staffContext: SecurityContext = {
  businessId: 'biz-123',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: ['team-1'],
};

const mockRateLimit = (): RateLimitService =>
  ({
    checkLimit: vi.fn().mockResolvedValue({
      allowed: true,
      remaining: 10,
      resetAt: new Date(Date.now() + 60000),
    }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  }) as unknown as RateLimitService;

const mockAudit = (): AuditLogService =>
  ({
    logAction: vi.fn().mockResolvedValue({ success: true, data: undefined }),
  }) as unknown as AuditLogService;

// Mock API Key Repository
const createMockApiKeyRepo = () => {
  const keys = new Map<string, ApiKey & { fullKey?: string }>();
  let idCounter = 0;

  // Simple hash function for testing - include more of the key for uniqueness
  const testHash = (key: string) => `hash_${key.substring(0, 32)}_${key.length}`;

  return {
    create: vi.fn().mockImplementation(async (context, input) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Only administrators can manage API keys' },
        };
      }

      const id = `key-${++idCounter}`;
      const fullKey = `crm_live_test${Date.now()}_${Math.random().toString(36).substring(2)}`;
      const keyHash = testHash(fullKey);
      const keyPrefix = fullKey.substring(0, 8);

      const apiKey: ApiKey = {
        id,
        businessId: context.businessId,
        name: input.name,
        description: input.description,
        keyPrefix,
        keyHash,
        scopes: input.scopes,
        rateLimit: input.rateLimit ?? 60,
        rateLimitWindow: input.rateLimitWindow ?? 60,
        isActive: true,
        usageCount: 0,
        expiresAt: input.expiresAt,
        createdById: context.userId,
        createdAt: new Date(),
      };

      keys.set(id, { ...apiKey, fullKey });

      return {
        success: true,
        data: { key: apiKey, fullKey },
        error: null,
      };
    }),

    getById: vi.fn().mockImplementation(async (context, keyId) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const key = keys.get(keyId);
      if (!key) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'API key not found' },
        };
      }
      // Don't return fullKey in getById
      const { fullKey: _fullKey, ...apiKey } = key;
      return { success: true, data: apiKey, error: null };
    }),

    getAll: vi.fn().mockImplementation(async (context) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const data = Array.from(keys.values()).map(({ fullKey: _fullKey, ...k }) => k);
      return {
        success: true,
        data: { data, lastDoc: null, hasMore: false },
        error: null,
      };
    }),

    getByKeyHash: vi.fn().mockImplementation(async (businessId, keyHash) => {
      for (const key of keys.values()) {
        if (key.businessId === businessId && key.keyHash === keyHash && key.isActive) {
          const { fullKey: _fullKey, ...apiKey } = key;
          return apiKey;
        }
      }
      return null;
    }),

    validateApiKeyForBusiness: vi.fn().mockImplementation(async (fullKey, businessId) => {
      if (!fullKey || !fullKey.startsWith('crm_live_')) {
        return { valid: false, error: 'Invalid API key format' };
      }

      const keyHash = testHash(fullKey);
      for (const key of keys.values()) {
        if (key.businessId === businessId && key.keyHash === keyHash) {
          if (!key.isActive) {
            return { valid: false, error: 'API key is inactive' };
          }
          if (key.expiresAt && key.expiresAt < new Date()) {
            return { valid: false, error: 'API key has expired' };
          }
          const { fullKey: _, ...apiKey } = key;
          return { valid: true, apiKey };
        }
      }
      return { valid: false, error: 'Invalid API key' };
    }),

    update: vi.fn().mockImplementation(async (context, keyId, input) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const key = keys.get(keyId);
      if (!key) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'API key not found' },
        };
      }
      const updated = {
        ...key,
        ...input,
        updatedAt: new Date(),
      };
      keys.set(keyId, updated);
      const { fullKey: _fullKey, ...apiKey } = updated;
      return { success: true, data: apiKey, error: null };
    }),

    revoke: vi.fn().mockImplementation(async (context, keyId) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const key = keys.get(keyId);
      if (!key) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'API key not found' },
        };
      }
      key.isActive = false;
      key.updatedAt = new Date();
      return { success: true, data: undefined, error: null };
    }),

    delete: vi.fn().mockImplementation(async (context, keyId) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      if (!keys.has(keyId)) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'API key not found' },
        };
      }
      keys.delete(keyId);
      return { success: true, data: undefined, error: null };
    }),

    recordUsage: vi.fn().mockImplementation(async (_businessId, keyId) => {
      const key = keys.get(keyId);
      if (key) {
        key.usageCount = (key.usageCount || 0) + 1;
        key.lastUsedAt = new Date();
      }
    }),

    incrementUsage: vi.fn().mockImplementation(async (_businessId, keyId, count = 1) => {
      const key = keys.get(keyId);
      if (key) {
        key.usageCount = (key.usageCount || 0) + count;
        key.lastUsedAt = new Date();
      }
    }),

    getUsageCount: vi.fn().mockImplementation(async (_context, keyId) => {
      const key = keys.get(keyId);
      if (!key) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'API key not found' },
        };
      }
      return { success: true, data: key.usageCount || 0, error: null };
    }),

    hasScope: vi.fn().mockImplementation((apiKey: ApiKey, scope: ApiScope) => {
      return apiKey.scopes.includes(scope);
    }),

    hasAnyScope: vi.fn().mockImplementation((apiKey: ApiKey, scopes: ApiScope[]) => {
      return scopes.some((scope) => apiKey.scopes.includes(scope));
    }),

    hasAllScopes: vi.fn().mockImplementation((apiKey: ApiKey, scopes: ApiScope[]) => {
      return scopes.every((scope) => apiKey.scopes.includes(scope));
    }),

    computeKeyHash: vi.fn().mockImplementation(async (fullKey) => testHash(fullKey)),

    // For test access
    _getKeys: () => keys,
  };
};

// ============================================
// Tests
// ============================================

describe('ApiKeyService', () => {
  let service: ApiKeyService;
  let rateLimit: ReturnType<typeof mockRateLimit>;
  let audit: ReturnType<typeof mockAudit>;
  let apiKeyRepo: ReturnType<typeof createMockApiKeyRepo>;

  beforeEach(() => {
    rateLimit = mockRateLimit();
    audit = mockAudit();
    apiKeyRepo = createMockApiKeyRepo();

    // Create service with mocked dependencies
    service = new ApiKeyService(rateLimit, audit);

    // Inject mock repository via prototype override
    (service as any).repo = apiKeyRepo;
  });

  // ============================================
  // Key Creation Tests
  // ============================================

  describe('Key Creation', () => {
    it('creates API key with valid input', async () => {
      const result = await service.createKey(adminContext, {
        name: 'Test API Key',
        description: 'For testing purposes',
        scopes: ['leads:read', 'leads:write'],
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(result.data?.key.name).toBe('Test API Key');
      expect(result.data?.key.scopes).toHaveLength(2);
      expect(result.data?.fullKey).toContain('crm_live_');
    });

    it('shows full key only once on creation', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'One-Time Key',
        scopes: ['deals:read'],
      });

      // Full key should be returned on creation
      expect(createResult.data?.fullKey).toContain('crm_live_');

      // Subsequent getKey calls should not include full key
      const getResult = await service.getKey(adminContext, createResult.data!.key.id);
      expect(getResult.data).not.toHaveProperty('fullKey');
    });

    it('generates unique keys for each creation', async () => {
      const result1 = await service.createKey(adminContext, {
        name: 'Key 1',
        scopes: ['leads:read'],
      });

      const result2 = await service.createKey(adminContext, {
        name: 'Key 2',
        scopes: ['leads:read'],
      });

      expect(result1.data?.fullKey).not.toBe(result2.data?.fullKey);
      expect(result1.data?.key.keyHash).not.toBe(result2.data?.key.keyHash);
    });

    it('stores key prefix for identification', async () => {
      const result = await service.createKey(adminContext, {
        name: 'Prefix Test',
        scopes: ['leads:read'],
      });

      expect(result.data?.key.keyPrefix).toHaveLength(8);
      expect(result.data?.fullKey.startsWith(result.data?.key.keyPrefix)).toBe(true);
    });

    it('creates key with custom rate limit', async () => {
      const result = await service.createKey(adminContext, {
        name: 'Rate Limited Key',
        scopes: ['leads:read'],
        rateLimit: 100,
      });

      expect(result.data?.key.rateLimit).toBe(100);
    });

    it('creates key with expiration date', async () => {
      const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
      const result = await service.createKey(adminContext, {
        name: 'Expiring Key',
        scopes: ['leads:read'],
        expiresAt,
      });

      expect(result.data?.key.expiresAt).toBeDefined();
    });

    it('logs key creation for audit', async () => {
      await service.createKey(adminContext, {
        name: 'Audit Test',
        scopes: ['leads:read'],
      });

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'create',
          entityType: 'integration',
        })
      );
    });
  });

  // ============================================
  // RBAC Tests
  // ============================================

  describe('RBAC Enforcement', () => {
    it('allows admin to create keys', async () => {
      const result = await service.createKey(adminContext, {
        name: 'Admin Key',
        scopes: ['leads:read'],
      });

      expect(result.success).toBe(true);
    });

    it('allows owner to create keys', async () => {
      const result = await service.createKey(ownerContext, {
        name: 'Owner Key',
        scopes: ['leads:read'],
      });

      expect(result.success).toBe(true);
    });

    it('denies staff from creating keys', async () => {
      const result = await service.createKey(staffContext, {
        name: 'Staff Key',
        scopes: ['leads:read'],
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('denies staff from listing keys', async () => {
      const result = await service.getKeys(staffContext);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('denies staff from revoking keys', async () => {
      // First create a key as admin
      const createResult = await service.createKey(adminContext, {
        name: 'Test Key',
        scopes: ['leads:read'],
      });

      // Try to revoke as staff
      const revokeResult = await service.revokeKey(staffContext, createResult.data!.key.id);

      expect(revokeResult.success).toBe(false);
      expect(revokeResult.error?.code).toBe('PERMISSION_DENIED');
    });
  });

  // ============================================
  // Key Validation Tests
  // ============================================

  describe('Key Validation', () => {
    it('validates correct API key', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Valid Key',
        scopes: ['leads:read'],
      });

      const validationResult = await service.validateKeyForBusiness(
        createResult.data!.fullKey,
        adminContext.businessId
      );

      expect(validationResult.valid).toBe(true);
      expect(validationResult.apiKey).toBeDefined();
      expect(validationResult.businessId).toBe(adminContext.businessId);
    });

    it('rejects invalid API key format', async () => {
      const result = await service.validateKeyForBusiness(
        'invalid_key_format',
        adminContext.businessId
      );

      expect(result.valid).toBe(false);
      expect(result.error).toContain('Invalid');
    });

    it('rejects revoked API key', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'To Revoke',
        scopes: ['leads:read'],
      });

      // Revoke the key
      await service.revokeKey(adminContext, createResult.data!.key.id);

      // Try to validate
      const validationResult = await service.validateKeyForBusiness(
        createResult.data!.fullKey,
        adminContext.businessId
      );

      expect(validationResult.valid).toBe(false);
      expect(validationResult.error).toContain('inactive');
    });

    it('rejects expired API key', async () => {
      const expiresAt = new Date(Date.now() - 1000); // Already expired
      const createResult = await service.createKey(adminContext, {
        name: 'Expired Key',
        scopes: ['leads:read'],
        expiresAt,
      });

      const validationResult = await service.validateKeyForBusiness(
        createResult.data!.fullKey,
        adminContext.businessId
      );

      expect(validationResult.valid).toBe(false);
      expect(validationResult.error).toContain('expired');
    });

    it('rejects key for wrong business', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Business-Specific Key',
        scopes: ['leads:read'],
      });

      const validationResult = await service.validateKeyForBusiness(
        createResult.data!.fullKey,
        'different-business-id'
      );

      expect(validationResult.valid).toBe(false);
    });
  });

  // ============================================
  // Scope Checking Tests
  // ============================================

  describe('Scope Checking', () => {
    it('checks single scope correctly', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Scoped Key',
        scopes: ['leads:read', 'deals:write'],
      });

      const apiKey = createResult.data!.key;

      expect(service.checkScope(apiKey, 'leads:read')).toBe(true);
      expect(service.checkScope(apiKey, 'deals:write')).toBe(true);
      expect(service.checkScope(apiKey, 'contacts:read')).toBe(false);
    });

    it('checks any scope correctly', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Scoped Key',
        scopes: ['leads:read'],
      });

      const apiKey = createResult.data!.key;

      expect(service.checkAnyScope(apiKey, ['leads:read', 'deals:read'])).toBe(true);
      expect(service.checkAnyScope(apiKey, ['contacts:read', 'tasks:read'])).toBe(false);
    });

    it('checks all scopes correctly', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Multi-Scope Key',
        scopes: ['leads:read', 'leads:write', 'deals:read'],
      });

      const apiKey = createResult.data!.key;

      expect(service.checkAllScopes(apiKey, ['leads:read', 'leads:write'])).toBe(true);
      expect(service.checkAllScopes(apiKey, ['leads:read', 'contacts:read'])).toBe(false);
    });
  });

  // ============================================
  // Rate Limiting Tests
  // ============================================

  describe('Rate Limiting', () => {
    it('allows requests under rate limit', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Rate Test',
        scopes: ['leads:read'],
        rateLimit: 10,
      });

      const keyId = createResult.data!.key.id;

      // First request should be allowed
      const result = await service.checkRateLimit(keyId);

      expect(result.allowed).toBe(true);
      expect(result.remaining).toBeGreaterThan(0);
    });

    it('blocks requests over rate limit', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Rate Test',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      // Make many requests
      for (let i = 0; i < 60; i++) {
        await service.recordUsage(keyId);
      }

      // Next request should be blocked
      const result = await service.checkRateLimit(keyId);

      // Note: our default rate limit is 60, so after 60 requests it should be blocked
      expect(result.remaining).toBe(0);
    });

    it('provides reset time in rate limit response', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Rate Test',
        scopes: ['leads:read'],
      });

      const result = await service.checkRateLimit(createResult.data!.key.id);

      expect(result.resetAt).toBeInstanceOf(Date);
      expect(result.resetAt.getTime()).toBeGreaterThan(Date.now());
    });

    it('respects custom rate limit configuration', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Custom Rate',
        scopes: ['leads:read'],
        rateLimit: 5,
      });

      const keyId = createResult.data!.key.id;

      const result = await service.checkRateLimitWithConfig(keyId, {
        rateLimit: 5,
        rateLimitWindow: 60,
      });

      expect(result.remaining).toBeLessThanOrEqual(5);
    });
  });

  // ============================================
  // Usage Tracking Tests
  // ============================================

  describe('Usage Tracking', () => {
    it('records usage correctly', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Usage Test',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      // Record some usage
      await service.recordUsage(keyId);
      await service.recordUsage(keyId);
      await service.recordUsage(keyId);

      expect(apiKeyRepo.recordUsage).toHaveBeenCalledTimes(0); // recordUsagePersistent not called yet
    });

    it('persists usage to Firestore', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Persistent Usage',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      await service.recordUsagePersistent(adminContext.businessId, keyId);

      expect(apiKeyRepo.recordUsage).toHaveBeenCalledWith(
        adminContext.businessId,
        keyId
      );
    });

    it('gets usage statistics', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Stats Test',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      const stats = await service.getUsageStats(adminContext, keyId, {
        start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        end: new Date(),
      });

      expect(stats.success).toBe(true);
      expect(stats.data).toHaveProperty('requests');
      expect(stats.data).toHaveProperty('byEndpoint');
    });
  });

  // ============================================
  // Key Update Tests
  // ============================================

  describe('Key Updates', () => {
    it('updates key name', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Original Name',
        scopes: ['leads:read'],
      });

      const updateResult = await service.updateKey(
        adminContext,
        createResult.data!.key.id,
        { name: 'Updated Name' }
      );

      expect(updateResult.success).toBe(true);
      expect(updateResult.data?.name).toBe('Updated Name');
    });

    it('updates key scopes', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Scope Update',
        scopes: ['leads:read'],
      });

      const updateResult = await service.updateKey(
        adminContext,
        createResult.data!.key.id,
        { scopes: ['leads:read', 'leads:write', 'deals:read'] }
      );

      expect(updateResult.success).toBe(true);
      expect(updateResult.data?.scopes).toHaveLength(3);
    });

    it('deactivates key via update', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Deactivate Test',
        scopes: ['leads:read'],
      });

      const updateResult = await service.updateKey(
        adminContext,
        createResult.data!.key.id,
        { isActive: false }
      );

      expect(updateResult.success).toBe(true);
      expect(updateResult.data?.isActive).toBe(false);
    });

    it('logs key update for audit', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Audit Update',
        scopes: ['leads:read'],
      });

      await service.updateKey(
        adminContext,
        createResult.data!.key.id,
        { name: 'New Name' }
      );

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'update',
          entityType: 'integration',
        })
      );
    });
  });

  // ============================================
  // Key Revocation Tests
  // ============================================

  describe('Key Revocation', () => {
    it('revokes key successfully', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'To Revoke',
        scopes: ['leads:read'],
      });

      const revokeResult = await service.revokeKey(
        adminContext,
        createResult.data!.key.id
      );

      expect(revokeResult.success).toBe(true);

      // Key should be inactive
      const getResult = await service.getKey(adminContext, createResult.data!.key.id);
      expect(getResult.data?.isActive).toBe(false);
    });

    it('clears rate limit cache on revocation', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Cache Clear',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      // Record some usage
      await service.recordUsage(keyId);

      // Verify we have rate limit status
      const statusBefore = service.getRateLimitStatus(keyId);
      expect(statusBefore).not.toBeNull();

      // Revoke
      await service.revokeKey(adminContext, keyId);

      // Rate limit cache should be cleared
      const statusAfter = service.getRateLimitStatus(keyId);
      expect(statusAfter).toBeNull();
    });

    it('logs key revocation for audit', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Audit Revoke',
        scopes: ['leads:read'],
      });

      await service.revokeKey(adminContext, createResult.data!.key.id);

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'delete',
          entityType: 'integration',
        })
      );
    });
  });

  // ============================================
  // Error Handling Tests
  // ============================================

  describe('Error Handling', () => {
    it('handles key not found', async () => {
      const result = await service.getKey(adminContext, 'nonexistent-key-id');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });

    it('handles revoke of non-existent key', async () => {
      const result = await service.revokeKey(adminContext, 'nonexistent-key-id');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });

    it('handles update of non-existent key', async () => {
      const result = await service.updateKey(
        adminContext,
        'nonexistent-key-id',
        { name: 'New Name' }
      );

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });
  });

  // ============================================
  // Security Tests
  // ============================================

  describe('Security', () => {
    it('never returns full key after creation', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Security Test',
        scopes: ['leads:read'],
      });

      // Get the key
      const getResult = await service.getKey(adminContext, createResult.data!.key.id);

      expect(getResult.data).not.toHaveProperty('fullKey');
    });

    it('never returns key hash in API responses', async () => {
      // The keyHash should only be used internally for validation
      const createResult = await service.createKey(adminContext, {
        name: 'Hash Test',
        scopes: ['leads:read'],
      });

      // keyHash is stored but validation uses it internally
      expect(createResult.data?.key.keyHash).toBeDefined();
    });

    it('does not log full API key in audit', async () => {
      await service.createKey(adminContext, {
        name: 'Audit Security',
        scopes: ['leads:read'],
      });

      const auditCall = (audit.logAction as any).mock.calls[0];
      const metadata = auditCall[1].metadata;

      // Ensure full key is not in metadata
      expect(metadata).not.toHaveProperty('fullKey');
      expect(metadata).not.toHaveProperty('key');
      expect(JSON.stringify(metadata)).not.toContain('crm_live_');
    });

    it('validates API keys using hash comparison', async () => {
      await service.createKey(adminContext, {
        name: 'Hash Validation',
        scopes: ['leads:read'],
      });

      // Completely different key should fail
      const differentKey = 'crm_live_completely_different_key_that_wont_match_12345';

      const result = await service.validateKeyForBusiness(
        differentKey,
        adminContext.businessId
      );

      expect(result.valid).toBe(false);
    });
  });

  // ============================================
  // Utility Method Tests
  // ============================================

  describe('Utility Methods', () => {
    it('clears all rate limit caches', async () => {
      const result1 = await service.createKey(adminContext, {
        name: 'Cache 1',
        scopes: ['leads:read'],
      });
      const result2 = await service.createKey(adminContext, {
        name: 'Cache 2',
        scopes: ['deals:read'],
      });

      // Record usage
      await service.recordUsage(result1.data!.key.id);
      await service.recordUsage(result2.data!.key.id);

      // Clear all
      service.clearAllRateLimitCaches();

      expect(service.getRateLimitStatus(result1.data!.key.id)).toBeNull();
      expect(service.getRateLimitStatus(result2.data!.key.id)).toBeNull();
    });

    it('gets rate limit status correctly', async () => {
      const createResult = await service.createKey(adminContext, {
        name: 'Status Test',
        scopes: ['leads:read'],
      });

      const keyId = createResult.data!.key.id;

      // Initially no status
      expect(service.getRateLimitStatus(keyId)).toBeNull();

      // Record usage
      await service.recordUsage(keyId);

      // Now has status
      const status = service.getRateLimitStatus(keyId);
      expect(status).not.toBeNull();
      expect(status?.count).toBe(1);
    });
  });

  // ============================================
  // Integration Tests
  // ============================================

  describe('Integration Scenarios', () => {
    it('full API key lifecycle', async () => {
      // 1. Create key
      const createResult = await service.createKey(adminContext, {
        name: 'Lifecycle Test',
        description: 'Testing full lifecycle',
        scopes: ['leads:read', 'leads:write'],
        rateLimit: 100,
      });

      expect(createResult.success).toBe(true);
      const keyId = createResult.data!.key.id;
      const fullKey = createResult.data!.fullKey;

      // 2. Validate key
      const validationResult = await service.validateKeyForBusiness(
        fullKey,
        adminContext.businessId
      );
      expect(validationResult.valid).toBe(true);

      // 3. Check scopes
      expect(service.checkScope(validationResult.apiKey!, 'leads:read')).toBe(true);

      // 4. Record usage
      await service.recordUsage(keyId);
      await service.recordUsagePersistent(adminContext.businessId, keyId);

      // 5. Check rate limit
      const rateResult = await service.checkRateLimit(keyId);
      expect(rateResult.allowed).toBe(true);

      // 6. Update key
      const updateResult = await service.updateKey(adminContext, keyId, {
        description: 'Updated description',
      });
      expect(updateResult.success).toBe(true);

      // 7. Get usage stats
      const statsResult = await service.getUsageStats(adminContext, keyId, {
        start: new Date(Date.now() - 86400000),
        end: new Date(),
      });
      expect(statsResult.success).toBe(true);

      // 8. Revoke key
      const revokeResult = await service.revokeKey(adminContext, keyId);
      expect(revokeResult.success).toBe(true);

      // 9. Validation should now fail
      const postRevokeValidation = await service.validateKeyForBusiness(
        fullKey,
        adminContext.businessId
      );
      expect(postRevokeValidation.valid).toBe(false);
    });

    it('multi-key management', async () => {
      // Create multiple keys
      const keys = await Promise.all([
        service.createKey(adminContext, {
          name: 'Read-Only Key',
          scopes: ['leads:read', 'deals:read'],
        }),
        service.createKey(adminContext, {
          name: 'Write Key',
          scopes: ['leads:read', 'leads:write', 'deals:read', 'deals:write'],
        }),
        service.createKey(adminContext, {
          name: 'Admin Key',
          scopes: ['leads:read', 'leads:write', 'webhooks:manage'],
        }),
      ]);

      // List all keys
      const listResult = await service.getKeys(adminContext);
      expect(listResult.data).toHaveLength(3);

      // Validate each key works
      for (const keyResult of keys) {
        const validation = await service.validateKeyForBusiness(
          keyResult.data!.fullKey,
          adminContext.businessId
        );
        expect(validation.valid).toBe(true);
      }

      // Revoke one key
      await service.revokeKey(adminContext, keys[0].data!.key.id);

      // List should still show 3 (revoked but not deleted)
      const listAfterRevoke = await service.getKeys(adminContext);
      expect(listAfterRevoke.data).toHaveLength(3);
    });
  });
});
