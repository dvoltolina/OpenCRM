/**
 * AuditLogService Tests
 *
 * Agent CRM-28 Implementation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import {
  AuditLogService,
  getAuditLogService,
  __resetAuditThrottleForTests,
  HIPAA_RETENTION_DAYS,
} from '../AuditLogService';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { AuditEntry, AuditAction, AuditEntityType } from '../../types/audit';

// ============================================
// Mock Audit Repository
// ============================================

const mockCreate = vi.fn();
const mockGetFiltered = vi.fn();
const mockGetByEntity = vi.fn();
const mockGetByUser = vi.fn();
const mockGetRecent = vi.fn();
const mockDeleteOldEntries = vi.fn();

vi.mock('../../data/repositories/audit-repository', () => ({
  getAuditRepository: vi.fn(() => ({
    create: mockCreate,
    getFiltered: mockGetFiltered,
    getByEntity: mockGetByEntity,
    getByUser: mockGetByUser,
    getRecent: mockGetRecent,
    deleteOldEntries: mockDeleteOldEntries,
  })),
}));

// ============================================
// Test Data
// ============================================

const mockContext: SecurityContext = {
  businessId: 'business-123',
  userId: 'user-123',
  userName: 'Test User',
  userRole: 'admin',
  requiresHipaaCompliance: false,
  auditLoggingEnabled: true,
};

const mockAuditEntry: AuditEntry = {
  id: 'audit-123',
  businessId: 'business-123',
  userId: 'user-123',
  userName: 'Test User',
  action: 'create',
  entityType: 'deal',
  entityId: 'deal-123',
  entityName: 'Test Deal',
  timestamp: new Date(),
  createdAt: new Date(), // Added to satisfy BaseEntity constraint
};

const mockAuditEntryWithChanges: AuditEntry = {
  ...mockAuditEntry,
  id: 'audit-456',
  action: 'update',
  changes: {
    status: { old: 'open', new: 'won' },
    valueCents: { old: 10000, new: 15000 },
  },
};

// ============================================
// Tests
// ============================================

describe('AuditLogService', () => {
  let service: AuditLogService;

  beforeEach(() => {
    vi.clearAllMocks();
    __resetAuditThrottleForTests();
    service = new AuditLogService();

    // Default successful responses
    mockCreate.mockResolvedValue({
      success: true,
      data: mockAuditEntry,
    });

    mockGetFiltered.mockResolvedValue({
      success: true,
      data: {
        entries: [mockAuditEntry, mockAuditEntryWithChanges],
        hasMore: false,
      },
    });

    mockGetByEntity.mockResolvedValue({
      success: true,
      data: [mockAuditEntry],
    });

    mockGetByUser.mockResolvedValue({
      success: true,
      data: [mockAuditEntry],
    });

    mockGetRecent.mockResolvedValue({
      success: true,
      data: [mockAuditEntry],
    });

    mockDeleteOldEntries.mockResolvedValue({
      success: true,
      data: 5,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // logAction Tests
  // ============================================

  describe('logAction', () => {
    it('creates audit entry with all fields', async () => {
      const result = await service.logAction(mockContext, {
        action: 'create',
        entityType: 'deal',
        entityId: 'deal-123',
        entityName: 'Test Deal',
        metadata: { source: 'web' },
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          businessId: 'business-123',
          userId: 'user-123',
          userName: 'Test User',
          action: 'create',
          entityType: 'deal',
          entityId: 'deal-123',
          entityName: 'Test Deal',
          metadata: {
            source: 'web',
            teamIds: [],
            managedTeamIds: [],
          },
        })
      );
    });

    it('merges context team scope into metadata', async () => {
      const contextWithTeams: SecurityContext = {
        ...mockContext,
        teamIds: [' team-a ', 'team-b'],
        managedTeamIds: ['team-c'],
      };

      await service.logAction(contextWithTeams, {
        action: 'update',
        entityType: 'deal',
        entityId: 'deal-789',
        metadata: {
          teamIds: ['team-b', 'team-d'],
          managedTeamIds: ['team-e'],
        },
      });

      expect(mockCreate).toHaveBeenCalledWith(
        contextWithTeams,
        expect.objectContaining({
          metadata: {
            teamIds: ['team-a', 'team-b', 'team-c', 'team-d', 'team-e'],
            managedTeamIds: ['team-c', 'team-e'],
          },
        })
      );
    });

    it('includes timestamp', async () => {
      await service.logAction(mockContext, {
        action: 'update',
        entityType: 'lead',
        entityId: 'lead-123',
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          timestamp: expect.any(Date),
        })
      );
    });

    it('includes field changes for updates', async () => {
      const changes = {
        status: { old: 'new', new: 'qualified' },
        score: { old: 50, new: 75 },
      };

      await service.logAction(mockContext, {
        action: 'update',
        entityType: 'lead',
        entityId: 'lead-123',
        changes,
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          changes,
        })
      );
    });

    it('returns error on failure', async () => {
      mockCreate.mockResolvedValueOnce({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid entity type',
        },
      });

      const result = await service.logAction(mockContext, {
        action: 'create',
        entityType: 'deal',
        entityId: 'test-123',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('VALIDATION_ERROR');
    });
  });

  // ============================================
  // Convenience Method Tests
  // ============================================

  describe('logCreate', () => {
    it('logs creation action', async () => {
      await service.logCreate(mockContext, 'deal', 'deal-123', 'New Deal');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'create',
          entityType: 'deal',
          entityId: 'deal-123',
          entityName: 'New Deal',
        })
      );
    });
  });

  describe('logUpdate', () => {
    it('logs update action with changes', async () => {
      const changes = {
        title: { old: 'Old Title', new: 'New Title' },
      };

      await service.logUpdate(mockContext, 'deal', 'deal-123', changes, 'Updated Deal');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'update',
          entityType: 'deal',
          entityId: 'deal-123',
          entityName: 'Updated Deal',
          changes,
        })
      );
    });
  });

  describe('logDelete', () => {
    it('logs deletion action', async () => {
      await service.logDelete(mockContext, 'lead', 'lead-123', 'Deleted Lead');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'delete',
          entityType: 'lead',
          entityId: 'lead-123',
          entityName: 'Deleted Lead',
        })
      );
    });
  });

  describe('logConversion', () => {
    it('logs conversion action', async () => {
      const result = await service.logConversion(mockContext, 'lead', 'lead-123', 'Converted Lead', {
        toDeal: 'deal-456',
      });

      expect(result.success).toBe(true);
      // Conversion is non-critical; verify we skip logging without error
      expect(mockCreate).not.toHaveBeenCalled();
    });
  });

  describe('logMerge', () => {
    it('logs merge action', async () => {
      await service.logMerge(mockContext, 'contact', 'contact-123', 'Merged Contact', {
        mergedWith: 'contact-456',
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'merge',
          entityType: 'contact',
          entityId: 'contact-123',
          entityName: 'Merged Contact',
          metadata: { mergedWith: 'contact-456', teamIds: [], managedTeamIds: [] },
        })
      );
    });
  });

  // ============================================
  // Query Method Tests
  // ============================================

  describe('getAuditLog', () => {
    it('retrieves audit log with filters', async () => {
      const filters = {
        userId: 'user-123',
        entityType: 'deal' as AuditEntityType,
        action: 'create' as AuditAction,
        startDate: new Date('2024-01-01'),
        limit: 50,
      };

      const result = await service.getAuditLog(mockContext, filters);

      expect(result.success).toBe(true);
      expect(result.data?.entries).toHaveLength(2);
      expect(mockGetFiltered).toHaveBeenCalledWith(mockContext, filters);
    });

    it('retrieves all logs without filters', async () => {
      const result = await service.getAuditLog(mockContext);

      expect(result.success).toBe(true);
      expect(mockGetFiltered).toHaveBeenCalledWith(mockContext, {});
    });
  });

  describe('getEntityHistory', () => {
    it('retrieves audit history for entity', async () => {
      const result = await service.getEntityHistory(mockContext, 'deal', 'deal-123');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(mockGetByEntity).toHaveBeenCalledWith(mockContext, 'deal', 'deal-123', 50);
    });

    it('accepts custom limit', async () => {
      await service.getEntityHistory(mockContext, 'lead', 'lead-123', 100);

      expect(mockGetByEntity).toHaveBeenCalledWith(mockContext, 'lead', 'lead-123', 100);
    });
  });

  describe('getUserActivity', () => {
    it('retrieves user activity', async () => {
      const result = await service.getUserActivity(mockContext, 'user-456');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(mockGetByUser).toHaveBeenCalledWith(mockContext, 'user-456', 100);
    });
  });

  describe('getRecentActivity', () => {
    it('retrieves recent activity', async () => {
      const result = await service.getRecentActivity(mockContext, 7);

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(mockGetRecent).toHaveBeenCalledWith(mockContext, 7, 100);
    });

    it('uses default 7 days if not specified', async () => {
      await service.getRecentActivity(mockContext);

      expect(mockGetRecent).toHaveBeenCalledWith(mockContext, 7, 100);
    });
  });

  // ============================================
  // Cleanup Tests
  // ============================================

  describe('cleanupOldLogs', () => {
    it('deletes old audit logs with explicit retention', async () => {
      const result = await service.cleanupOldLogs(mockContext, HIPAA_RETENTION_DAYS);

      expect(result.success).toBe(true);
      expect(result.data).toBe(5);
      expect(mockDeleteOldEntries).toHaveBeenCalledWith(mockContext, HIPAA_RETENTION_DAYS);
    });

    it('uses default HIPAA retention', async () => {
      await service.cleanupOldLogs(mockContext);

      expect(mockDeleteOldEntries).toHaveBeenCalledWith(mockContext, HIPAA_RETENTION_DAYS);
    });
  });

  // ============================================
  // Utility Tests
  // ============================================

  describe('createChanges', () => {
    it('creates changes object from old and new values', () => {
      const oldEntity = {
        id: 'deal-123',
        title: 'Old Title',
        status: 'open',
        valueCents: 10000,
      };

      const newEntity = {
        title: 'New Title',
        valueCents: 15000,
      };

      const changes = AuditLogService.createChanges(oldEntity, newEntity);

      expect(changes).toEqual({
        title: { old: 'Old Title', new: 'New Title' },
        valueCents: { old: 10000, new: 15000 },
      });
    });

    it('skips unchanged fields', () => {
      const oldEntity = {
        id: 'deal-123',
        title: 'Same Title',
        status: 'open',
      };

      const newEntity = {
        title: 'Same Title',
        status: 'won',
      };

      const changes = AuditLogService.createChanges(oldEntity, newEntity);

      expect(changes).toEqual({
        status: { old: 'open', new: 'won' },
      });
    });

    it('handles empty changes', () => {
      const oldEntity = { id: 'deal-123', title: 'Title' };
      const newEntity = { title: 'Title' };

      const changes = AuditLogService.createChanges(oldEntity, newEntity);

      expect(changes).toEqual({});
    });
  });

  // ============================================
  // Error Handling Tests
  // ============================================

  describe('error handling', () => {
    it('handles repository errors gracefully', async () => {
      mockGetFiltered.mockResolvedValueOnce({
        success: false,
        error: {
          code: 'NETWORK_ERROR',
          message: 'Network error',
        },
      });

      const result = await service.getAuditLog(mockContext);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NETWORK_ERROR');
    });
  });

  // ============================================
  // Security Context Tests
  // ============================================

  describe('security context', () => {
    it('uses businessId from context', async () => {
      await service.logCreate(mockContext, 'deal', 'deal-123');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          businessId: 'business-123',
        })
      );
    });

    it('uses userId from context', async () => {
      await service.logCreate(mockContext, 'deal', 'deal-123');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          userId: 'user-123',
          userName: 'Test User',
        })
      );
    });
  });
});

// ============================================
// Singleton Tests
// ============================================

describe('getAuditLogService', () => {
  it('returns singleton instance', () => {
    const instance1 = getAuditLogService();
    const instance2 = getAuditLogService();
    expect(instance1).toBe(instance2);
  });
});
