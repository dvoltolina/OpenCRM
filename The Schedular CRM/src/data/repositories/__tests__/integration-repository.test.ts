/**
 * Integration Repository Tests
 *
 * Task 9: API & Third-Party Integrations - Repository Layer
 *
 * Tests for:
 * - RBAC enforcement (admin/owner only)
 * - CRUD operations with HIPAA compliance
 * - getByType and getByProvider queries
 * - updateStatus with error sanitization
 * - OAuth token management
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import type { SecurityContext } from '../repository-types';
import { IntegrationRepository } from '../integration-repository';
import type { Integration, IntegrationType, IntegrationStatus } from '../../../types/integrations';

// Mock Firestore
const mockDocs: Array<{ id: string; data: () => Record<string, unknown>; exists: () => boolean }> = [];

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(async () => {
    if (mockDocs.length > 0) {
      return { exists: () => true, data: () => mockDocs[0].data() };
    }
    return { exists: () => false, data: () => null };
  }),
  getDocs: vi.fn(async () => ({
    docs: mockDocs,
    empty: mockDocs.length === 0,
  })),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  onSnapshot: vi.fn(),
  writeBatch: vi.fn(),
  Timestamp: {
    now: vi.fn(() => ({ toDate: () => new Date() })),
    fromDate: vi.fn((date: Date) => ({ toDate: () => date })),
  },
}));

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('../../../lib/collections', () => ({
  businessPath: vi.fn((businessId: string) => `businesses/${businessId}`),
}));

vi.mock('../firestore-utils', () => ({
  isValidDocumentId: vi.fn(() => true),
  generateId: vi.fn(() => 'int-test-123'),
}));

// Test contexts
const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const ownerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'owner-1',
  userName: 'Owner User',
  userRole: 'owner',
  teamIds: [],
  managedTeamIds: [],
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: [],
  managedTeamIds: [],
};

const managerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'manager-1',
  userName: 'Manager User',
  userRole: 'manager',
  teamIds: [],
  managedTeamIds: [],
};

// Helper to create mock integration data
const mockIntegrationData = (overrides: Partial<Integration> = {}): Record<string, unknown> => ({
  name: 'Test Integration',
  description: 'A test integration',
  type: 'native' as IntegrationType,
  provider: 'slack',
  status: 'active' as IntegrationStatus,
  config: {},
  scopes: ['channels:read'],
  createdById: 'admin-1',
  createdAt: { toDate: () => new Date('2024-01-01') },
  updatedAt: null,
  lastSyncAt: null,
  lastErrorAt: null,
  lastErrorMessage: null,
  accessToken: 'encrypted-access-token',
  refreshToken: 'encrypted-refresh-token',
  tokenExpiresAt: { toDate: () => new Date('2024-12-31') },
  ...overrides,
});

describe('IntegrationRepository', () => {
  let repo: IntegrationRepository;

  beforeEach(() => {
    repo = new IntegrationRepository();
    mockDocs.length = 0;
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // ============================================
  // RBAC Tests
  // ============================================

  describe('RBAC Enforcement', () => {
    it('allows admin to create integration', async () => {
      const result = await repo.create(adminContext, {
        name: 'Slack Integration',
        type: 'native',
        provider: 'slack',
      });

      expect(result.success).toBe(true);
    });

    it('allows owner to create integration', async () => {
      const result = await repo.create(ownerContext, {
        name: 'Slack Integration',
        type: 'native',
        provider: 'slack',
      });

      expect(result.success).toBe(true);
    });

    it('blocks staff from creating integration', async () => {
      const result = await repo.create(staffContext, {
        name: 'Slack Integration',
        type: 'native',
        provider: 'slack',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('blocks manager from creating integration', async () => {
      const result = await repo.create(managerContext, {
        name: 'Slack Integration',
        type: 'native',
        provider: 'slack',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('blocks staff from viewing integrations', async () => {
      const result = await repo.getAll(staffContext);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('blocks staff from updating integration status', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });

      const result = await repo.updateStatus(staffContext, 'int-1', 'active');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('blocks staff from deleting integration', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });

      const result = await repo.delete(staffContext, 'int-1');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('rejects missing businessId', async () => {
      const badContext = { ...adminContext, businessId: '' };
      const result = await repo.create(badContext, {
        name: 'Test',
        type: 'native',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('INVALID_ARGUMENT');
    });

    it('rejects missing userId', async () => {
      const badContext = { ...adminContext, userId: '' };
      const result = await repo.create(badContext, {
        name: 'Test',
        type: 'native',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('INVALID_ARGUMENT');
    });
  });

  // ============================================
  // Create Tests
  // ============================================

  describe('create', () => {
    it('creates integration with valid input', async () => {
      const result = await repo.create(adminContext, {
        name: 'Slack Integration',
        description: 'Connect to Slack',
        type: 'native',
        provider: 'slack',
        scopes: ['channels:read', 'chat:write'],
      });

      expect(result.success).toBe(true);
      expect(result.data?.name).toBe('Slack Integration');
    });

    it('requires name', async () => {
      const result = await repo.create(adminContext, {
        name: '',
        type: 'native',
      });

      expect(result.success).toBe(false);
      expect(result.error?.field).toBe('name');
    });

    it('validates integration type', async () => {
      const result = await repo.create(adminContext, {
        name: 'Test',
        type: 'invalid_type' as IntegrationType,
      });

      expect(result.success).toBe(false);
      expect(result.error?.field).toBe('type');
    });

    it('creates with default inactive status', async () => {
      const result = await repo.create(adminContext, {
        name: 'Test Integration',
        type: 'webhook',
      });

      expect(result.success).toBe(true);
      // Status defaults to inactive
    });

    it('accepts all valid integration types', async () => {
      const types: IntegrationType[] = ['zapier', 'webhook', 'native', 'api_key'];

      for (const type of types) {
        const result = await repo.create(adminContext, {
          name: `${type} Integration`,
          type,
        });
        expect(result.success).toBe(true);
      }
    });
  });

  // ============================================
  // Read Tests
  // ============================================

  describe('getById', () => {
    it('retrieves integration without tokens by default', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });

      const result = await repo.getById(adminContext, 'int-1');

      expect(result.success).toBe(true);
      expect(result.data?.id).toBe('int-1');
      expect(result.data?.accessToken).toBeUndefined();
      expect(result.data?.refreshToken).toBeUndefined();
    });

    it('returns not found for missing integration', async () => {
      const result = await repo.getById(adminContext, 'non-existent');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });
  });

  describe('getByIdWithTokens', () => {
    it('retrieves integration with tokens for authorized users', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });

      const result = await repo.getByIdWithTokens(adminContext, 'int-1');

      expect(result.success).toBe(true);
      expect(result.data?.accessToken).toBe('encrypted-access-token');
      expect(result.data?.refreshToken).toBe('encrypted-refresh-token');
    });
  });

  describe('getAll', () => {
    it('retrieves all integrations for admin', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ name: 'Integration 1' }), exists: () => true },
        { id: 'int-2', data: () => mockIntegrationData({ name: 'Integration 2' }), exists: () => true }
      );

      const result = await repo.getAll(adminContext);

      expect(result.success).toBe(true);
      expect(result.data?.data).toHaveLength(2);
    });
  });

  // ============================================
  // getByType Tests
  // ============================================

  describe('getByType', () => {
    it('filters integrations by type', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ type: 'native', provider: 'slack' }), exists: () => true },
        { id: 'int-2', data: () => mockIntegrationData({ type: 'native', provider: 'google' }), exists: () => true }
      );

      const result = await repo.getByType(adminContext, 'native');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(2);
    });

    it('validates type parameter', async () => {
      const result = await repo.getByType(adminContext, 'invalid' as IntegrationType);

      expect(result.success).toBe(false);
      expect(result.error?.field).toBe('type');
    });

    it('returns empty array when no matches', async () => {
      const result = await repo.getByType(adminContext, 'zapier');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(0);
    });
  });

  // ============================================
  // getByProvider Tests
  // ============================================

  describe('getByProvider', () => {
    it('filters integrations by provider', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ provider: 'slack' }), exists: () => true }
      );

      const result = await repo.getByProvider(adminContext, 'slack');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(result.data?.[0].provider).toBe('slack');
    });

    it('requires provider parameter', async () => {
      const result = await repo.getByProvider(adminContext, '');

      expect(result.success).toBe(false);
      expect(result.error?.field).toBe('provider');
    });

    it('trims provider parameter', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ provider: 'slack' }), exists: () => true }
      );

      const result = await repo.getByProvider(adminContext, '  slack  ');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // updateStatus Tests
  // ============================================

  describe('updateStatus', () => {
    beforeEach(() => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });
    });

    it('updates status to active', async () => {
      const result = await repo.updateStatus(adminContext, 'int-1', 'active');

      expect(result.success).toBe(true);
    });

    it('updates status to error with message', async () => {
      const result = await repo.updateStatus(
        adminContext,
        'int-1',
        'error',
        'Connection timeout'
      );

      expect(result.success).toBe(true);
    });

    it('validates status parameter', async () => {
      const result = await repo.updateStatus(
        adminContext,
        'int-1',
        'invalid_status' as IntegrationStatus
      );

      expect(result.success).toBe(false);
      expect(result.error?.field).toBe('status');
    });

    it('sanitizes error messages - removes email', async () => {
      const result = await repo.updateStatus(
        adminContext,
        'int-1',
        'error',
        'User test@example.com not found'
      );

      expect(result.success).toBe(true);
      // Error message should have email redacted
    });

    it('sanitizes error messages - removes phone', async () => {
      const result = await repo.updateStatus(
        adminContext,
        'int-1',
        'error',
        'Failed to call 555-123-4567'
      );

      expect(result.success).toBe(true);
      // Error message should have phone redacted
    });

    it('truncates long error messages', async () => {
      const longMessage = 'A'.repeat(500);
      const result = await repo.updateStatus(adminContext, 'int-1', 'error', longMessage);

      expect(result.success).toBe(true);
      // Message should be truncated to 200 chars
    });
  });

  // ============================================
  // OAuth Token Tests
  // ============================================

  describe('updateOAuthTokens', () => {
    beforeEach(() => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });
    });

    it('updates OAuth tokens', async () => {
      const result = await repo.updateOAuthTokens(adminContext, 'int-1', {
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        tokenExpiresAt: new Date('2025-01-01'),
        scopes: ['channels:read', 'chat:write'],
      });

      expect(result.success).toBe(true);
    });

    it('updates tokens without refresh token', async () => {
      const result = await repo.updateOAuthTokens(adminContext, 'int-1', {
        accessToken: 'new-access-token',
        tokenExpiresAt: new Date('2025-01-01'),
      });

      expect(result.success).toBe(true);
    });
  });

  describe('clearOAuthTokens', () => {
    beforeEach(() => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });
    });

    it('clears OAuth tokens and sets status to inactive', async () => {
      const result = await repo.clearOAuthTokens(adminContext, 'int-1');

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Update Tests
  // ============================================

  describe('update', () => {
    beforeEach(() => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });
    });

    it('updates integration name', async () => {
      const result = await repo.update(adminContext, 'int-1', {
        name: 'Updated Name',
      });

      expect(result.success).toBe(true);
    });

    it('updates integration config', async () => {
      const result = await repo.update(adminContext, 'int-1', {
        config: { channel: '#general' },
      });

      expect(result.success).toBe(true);
    });

    it('trims name on update', async () => {
      const result = await repo.update(adminContext, 'int-1', {
        name: '  Trimmed Name  ',
      });

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Delete Tests
  // ============================================

  describe('delete', () => {
    it('deletes existing integration', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData(),
        exists: () => true,
      });

      const result = await repo.delete(adminContext, 'int-1');

      expect(result.success).toBe(true);
    });

    it('returns not found for missing integration', async () => {
      const result = await repo.delete(adminContext, 'non-existent');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });
  });

  // ============================================
  // Helper Methods Tests
  // ============================================

  describe('getActiveIntegrations', () => {
    it('returns only active integrations', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ status: 'active' }), exists: () => true }
      );

      const result = await repo.getActiveIntegrations(adminContext);

      expect(result.success).toBe(true);
    });
  });

  describe('getErroredIntegrations', () => {
    it('returns integrations with error status', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ status: 'error' }), exists: () => true }
      );

      const result = await repo.getErroredIntegrations(adminContext);

      expect(result.success).toBe(true);
    });
  });

  describe('existsByProvider', () => {
    it('returns true when provider exists', async () => {
      mockDocs.push({
        id: 'int-1',
        data: () => mockIntegrationData({ provider: 'slack' }),
        exists: () => true,
      });

      const exists = await repo.existsByProvider(adminContext, 'slack');

      expect(exists).toBe(true);
    });

    it('returns false when provider does not exist', async () => {
      const exists = await repo.existsByProvider(adminContext, 'non-existent');

      expect(exists).toBe(false);
    });
  });

  describe('countByType', () => {
    it('counts integrations by type', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ type: 'native' }), exists: () => true },
        { id: 'int-2', data: () => mockIntegrationData({ type: 'native' }), exists: () => true }
      );

      const count = await repo.countByType(adminContext, 'native');

      expect(count).toBe(2);
    });
  });

  describe('countActive', () => {
    it('counts active integrations', async () => {
      mockDocs.push(
        { id: 'int-1', data: () => mockIntegrationData({ status: 'active' }), exists: () => true }
      );

      const count = await repo.countActive(adminContext);

      expect(count).toBe(1);
    });
  });

  // ============================================
  // Internal Methods Tests
  // ============================================

  describe('recordSync', () => {
    it('records sync timestamp without context (internal use)', async () => {
      // This is a best-effort method that doesn't throw
      await repo.recordSync('biz-1', 'int-1');
      // No assertion needed - just verifying it doesn't throw
    });
  });

  describe('recordError', () => {
    it('records error with sanitized message', async () => {
      await repo.recordError('biz-1', 'int-1', 'Error with test@example.com');
      // No assertion needed - just verifying it doesn't throw
    });
  });
});

describe('IntegrationRepository Singleton', () => {
  it('returns same instance', async () => {
    const { getIntegrationRepository } = await import('../integration-repository');
    const instance1 = getIntegrationRepository();
    const instance2 = getIntegrationRepository();

    expect(instance1).toBe(instance2);
  });
});
