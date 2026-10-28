/**
 * Activity Service Tests
 *
 * Agent CRM-13 Implementation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { ActivityService, getActivityService } from '../activity-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { SalesActivity } from '../../types/models';

// ============================================
// Mock Activity Repository
// ============================================

const mockCreate = vi.fn();
const mockGetById = vi.fn();
const mockUpdate = vi.fn();
const mockDelete = vi.fn();
const mockMarkComplete = vi.fn();
const mockMarkIncomplete = vi.fn();
const mockGetTimeline = vi.fn();
const mockGetUnifiedTimeline = vi.fn();
const mockGetPendingTasks = vi.fn();
const mockGetOverdueTasks = vi.fn();
const mockGetUpcomingTasks = vi.fn();
const mockGetRecent = vi.fn();

vi.mock('../../data/repositories/activity-repository', () => ({
  getActivityRepository: vi.fn(() => ({
    create: mockCreate,
    getById: mockGetById,
    update: mockUpdate,
    delete: mockDelete,
    markComplete: mockMarkComplete,
    markIncomplete: mockMarkIncomplete,
    getTimeline: mockGetTimeline,
    getUnifiedTimeline: mockGetUnifiedTimeline,
    getPendingTasks: mockGetPendingTasks,
    getOverdueTasks: mockGetOverdueTasks,
    getUpcomingTasks: mockGetUpcomingTasks,
    getRecent: mockGetRecent,
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
};

const mockActivity: SalesActivity = {
  id: 'activity-123',
  type: 'call',
  title: 'Phone Call',
  description: 'Discussed pricing',
  dealId: 'deal-123',
  createdById: 'user-123',
  createdByName: 'Test User',
  isCompleted: false,
  teamIds: ['team-1'],
  createdAt: new Date(),
};

const mockTask: SalesActivity = {
  id: 'task-123',
  type: 'task',
  title: 'Follow up',
  description: 'Send proposal',
  dealId: 'deal-123',
  dueDate: new Date(Date.now() + 86400000), // Tomorrow
  assigneeId: 'user-123',
  assigneeName: 'Test User',
  createdById: 'user-123',
  createdByName: 'Test User',
  isCompleted: false,
  teamIds: ['team-1'],
  createdAt: new Date(),
};

// ============================================
// Tests
// ============================================

describe('ActivityService', () => {
  let service: ActivityService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new ActivityService();

    // Default successful responses
    mockGetById.mockResolvedValue({
      success: true,
      data: mockTask,
    });
    mockCreate.mockResolvedValue({
      success: true,
      data: mockActivity,
    });
    mockUpdate.mockResolvedValue({
      success: true,
      data: mockTask,
    });

    mockMarkComplete.mockResolvedValue({
      success: true,
      data: { ...mockTask, isCompleted: true, completedAt: new Date() },
    });

    mockGetTimeline.mockResolvedValue({
      success: true,
      data: { data: [mockActivity], hasMore: false },
    });

    mockGetUnifiedTimeline.mockResolvedValue({
      success: true,
      data: { data: [mockActivity], hasMore: false },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // logActivity Tests
  // ============================================

  describe('logActivity', () => {
    it('creates activity with all fields', async () => {
      const result = await service.logActivity(mockContext, {
        type: 'call',
        title: 'Phone Call',
        description: 'Discussed pricing',
        dealId: 'deal-123',
        clientId: 'client-123',
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'call',
          title: 'Phone Call',
          description: 'Discussed pricing',
          dealId: 'deal-123',
          clientId: 'client-123',
          createdById: 'user-123',
          createdByName: 'Test User',
          isCompleted: false,
        })
      );
    });

    it('auto-fills createdById from auth context', async () => {
      await service.logActivity(mockContext, {
        type: 'note',
        title: 'Note',
        dealId: 'deal-123',
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          createdById: 'user-123',
          createdByName: 'Test User',
        })
      );
    });

    it('validates at least one entityId is required', async () => {
      const result = await service.logActivity(mockContext, {
        type: 'call',
        title: 'Phone Call',
        // No entity IDs
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('VALIDATION_ERROR');
      expect(mockCreate).not.toHaveBeenCalled();
    });

    it('supports multiple entity links', async () => {
      await service.logActivity(mockContext, {
        type: 'meeting',
        title: 'Meeting',
        dealId: 'deal-123',
        clientId: 'client-123',
        companyId: 'company-123',
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          dealId: 'deal-123',
          clientId: 'client-123',
          companyId: 'company-123',
        })
      );
    });
  });

  // ============================================
  // Quick Log Methods Tests
  // ============================================

  describe('logCall', () => {
    it('sets type to call', async () => {
      await service.logCall(mockContext, 'deal-123', 'deal', 'Discussed pricing');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'call',
          title: 'Phone Call',
          description: 'Discussed pricing',
          dealId: 'deal-123',
        })
      );
    });
  });

  describe('logEmail', () => {
    it('sets type to email', async () => {
      await service.logEmail(mockContext, 'client-123', 'client', 'Proposal Sent', 'Attached proposal PDF');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'email',
          title: 'Proposal Sent',
          description: 'Attached proposal PDF',
          clientId: 'client-123',
        })
      );
    });
  });

  describe('logMeeting', () => {
    it('sets type to meeting', async () => {
      await service.logMeeting(mockContext, 'company-123', 'company', 'Quarterly review');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'meeting',
          title: 'Meeting',
          description: 'Quarterly review',
          companyId: 'company-123',
        })
      );
    });
  });

  describe('logNote', () => {
    it('sets type to note', async () => {
      await service.logNote(mockContext, 'lead-123', 'lead', 'Interested in premium plan');

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'note',
          title: 'Note',
          description: 'Interested in premium plan',
          leadId: 'lead-123',
        })
      );
    });
  });

  // ============================================
  // Task Tests
  // ============================================

  describe('createTask', () => {
    it('requires dueDate', async () => {
      const result = await service.createTask(mockContext, {
        type: 'task',
        title: 'Follow up',
        dealId: 'deal-123',
        dueDate: undefined as unknown as Date, // Missing dueDate
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('VALIDATION_ERROR');
      expect(result.error?.message).toContain('Due date');
    });

    it('sets isCompleted false', async () => {
      const dueDate = new Date(Date.now() + 86400000);

      await service.createTask(mockContext, {
        type: 'task',
        title: 'Follow up',
        dealId: 'deal-123',
        dueDate,
      });

      expect(mockCreate).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'task',
          isCompleted: false,
        })
      );
    });
  });

  describe('completeTask', () => {
    it('sets isCompleted and completedAt', async () => {
      const result = await service.completeTask(mockContext, 'task-123');

      expect(result.success).toBe(true);
      expect(result.data?.isCompleted).toBe(true);
      expect(result.data?.completedAt).toBeDefined();
      expect(mockMarkComplete).toHaveBeenCalledWith(mockContext, 'task-123');
    });
  });

  // ============================================
  // Timeline Tests
  // ============================================

  describe('updateActivity', () => {
    it('allows manager with team access to update activity assignments', async () => {
      const managerContext: SecurityContext = {
        ...mockContext,
        userId: 'manager-1',
        userRole: 'manager',
        teamIds: ['team-1'],
        managedTeamIds: ['team-1'],
      };

      mockGetById.mockResolvedValueOnce({
        success: true,
        data: { ...mockTask, createdById: 'someone-else' },
      });

      const result = await service.updateActivity(managerContext, mockTask.id, {
        assigneeId: 'new-user',
        assigneeName: 'New User',
        teamIds: ['team-1'],
      });

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        managerContext,
        mockTask.id,
        expect.objectContaining({
          assigneeId: 'new-user',
          assigneeName: 'New User',
          teamIds: ['team-1'],
        })
      );
    });

    it('denies manager without team access', async () => {
      const managerContext: SecurityContext = {
        ...mockContext,
        userId: 'manager-1',
        userRole: 'manager',
        teamIds: ['other-team'],
        managedTeamIds: ['other-team'],
      };

      mockGetById.mockResolvedValueOnce({
        success: true,
        data: { ...mockTask, createdById: 'someone-else', teamIds: ['team-1'] },
      });

      const result = await service.updateActivity(managerContext, mockTask.id, {
        assigneeId: 'new-user',
        assigneeName: 'New User',
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });
  });

  describe('getEntityTimeline', () => {
    it('returns chronological activities', async () => {
      const result = await service.getEntityTimeline(mockContext, 'deal', 'deal-123');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(mockGetTimeline).toHaveBeenCalledWith(
        mockContext,
        'deal',
        'deal-123',
        expect.objectContaining({
          orderBy: { field: 'createdAt', direction: 'desc' },
        })
      );
    });
  });

  describe('getUnifiedTimeline', () => {
    it('merges activities from related entities', async () => {
      const result = await service.getUnifiedTimeline(mockContext, {
        dealId: 'deal-123',
        clientId: 'client-123',
      });

      expect(result.success).toBe(true);
      expect(mockGetUnifiedTimeline).toHaveBeenCalledWith(
        mockContext,
        { dealId: 'deal-123', clientId: 'client-123' },
        { limit: undefined }
      );
    });
  });

  // ============================================
  // Security Tests
  // ============================================

  describe('businessId scoping', () => {
    it('all operations scoped by businessId', async () => {
      // Log activity
      await service.logActivity(mockContext, {
        type: 'note',
        title: 'Test',
        dealId: 'deal-123',
      });

      expect(mockCreate).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(Object)
      );

      // Get timeline
      await service.getEntityTimeline(mockContext, 'deal', 'deal-123');

      expect(mockGetTimeline).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'deal',
        'deal-123',
        expect.any(Object)
      );
    });
  });
});

// ============================================
// Singleton Tests
// ============================================

describe('getActivityService', () => {
  it('returns singleton instance', () => {
    const instance1 = getActivityService();
    const instance2 = getActivityService();
    expect(instance1).toBe(instance2);
  });
});
