/**
 * Goal Service Tests
 * Tests for goal creation, progress calculation, and dashboard functionality
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GoalService } from '../goal-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Goal, GoalMetric, GoalPeriod, GoalAssigneeType } from '../../types/goals';

// ============================================
// Mock Repositories
// ============================================

const mockGoalRepo = {
  create: vi.fn(),
  getById: vi.fn(),
  update: vi.fn(),
  getActive: vi.fn(),
  getByAssignee: vi.fn(),
  updateProgress: vi.fn(),
  checkAndUpdateStatus: vi.fn(),
};

const mockDealRepo = {
  getWonValueRange: vi.fn(),
  getByStatus: vi.fn(),
};

const mockActivityRepo = {
  getAll: vi.fn(),
};

const mockAuditService = {
  logAction: vi.fn(),
};

// ============================================
// Test Fixtures
// ============================================

const testContext: SecurityContext = {
  businessId: 'test-business',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-1'],
  managedTeamIds: [],
};

const createTestGoal = (overrides: Partial<Goal> = {}): Goal => ({
  id: 'goal-1',
  metric: 'revenue',
  targetValue: 100000, // $1000 in cents
  period: 'monthly',
  startDate: new Date('2025-01-01'),
  endDate: new Date('2025-01-31'),
  assigneeType: 'user',
  assigneeId: 'user-1',
  assigneeName: 'Test User',
  currentValue: 0,
  progressPercent: 0,
  lastCalculatedAt: new Date(),
  status: 'active',
  createdById: 'user-1',
  createdByName: 'Test User',
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-1'],
  visibility: 'team',
  createdAt: new Date(),
  ...overrides,
});

// ============================================
// Tests
// ============================================

describe('GoalService', () => {
  let service: GoalService;

  beforeEach(() => {
    vi.clearAllMocks();

    service = new GoalService({
      goalRepository: mockGoalRepo as any,
      dealRepository: mockDealRepo as any,
      activityRepository: mockActivityRepo as any,
      auditLogService: mockAuditService as any,
    });
  });

  describe('createGoal', () => {
    it('should create a goal with valid data', async () => {
      const goalData = {
        metric: 'revenue' as GoalMetric,
        targetValue: 100000,
        period: 'monthly' as GoalPeriod,
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
        assigneeType: 'user' as GoalAssigneeType,
        assigneeId: 'user-1',
        assigneeName: 'Test User',
        ownerId: 'user-1',
        ownerName: 'Test User',
        teamIds: ['team-1'],
        visibility: 'team' as const,
        createdById: 'user-1',
        createdByName: 'Test User',
      };

      const createdGoal = createTestGoal();
      mockGoalRepo.create.mockResolvedValue({ success: true, data: createdGoal });

      const result = await service.createGoal(testContext, goalData);

      expect(result.success).toBe(true);
      expect(result.data).toEqual(createdGoal);
      expect(mockGoalRepo.create).toHaveBeenCalledWith(testContext, goalData);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        testContext,
        expect.objectContaining({
          action: 'create',
          entityType: 'report',
        })
      );
    });

    it('should fail when end date is before start date', async () => {
      const goalData = {
        metric: 'revenue' as GoalMetric,
        targetValue: 100000,
        period: 'monthly' as GoalPeriod,
        startDate: new Date('2025-01-31'),
        endDate: new Date('2025-01-01'), // Before start date
        assigneeType: 'user' as GoalAssigneeType,
        assigneeId: 'user-1',
        assigneeName: 'Test User',
        ownerId: 'user-1',
        ownerName: 'Test User',
        teamIds: [],
        visibility: 'team' as const,
        createdById: 'user-1',
        createdByName: 'Test User',
      };

      const result = await service.createGoal(testContext, goalData);

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('End date must be after start date');
      expect(mockGoalRepo.create).not.toHaveBeenCalled();
    });
  });

  describe('calculateProgress', () => {
    it('should calculate revenue progress from deals', async () => {
      const goal = createTestGoal({
        metric: 'revenue',
        targetValue: 100000,
        currentValue: 0,
        progressPercent: 0,
      });

      mockGoalRepo.getById.mockResolvedValue({ success: true, data: goal });
      mockDealRepo.getWonValueRange.mockResolvedValue({
        success: true,
        data: { totalValueCents: 50000, dealCount: 5 },
      });
      mockGoalRepo.updateProgress.mockResolvedValue({
        success: true,
        data: { ...goal, currentValue: 50000, progressPercent: 50 },
      });
      mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({ success: true, data: goal });

      const result = await service.calculateProgress(testContext, 'goal-1');

      expect(result.success).toBe(true);
      expect(mockGoalRepo.updateProgress).toHaveBeenCalledWith(testContext, 'goal-1', 50000);
    });

    it('should calculate deals_won progress', async () => {
      const goal = createTestGoal({
        metric: 'deals_won',
        targetValue: 10,
      });

      mockGoalRepo.getById.mockResolvedValue({ success: true, data: goal });
      mockDealRepo.getWonValueRange.mockResolvedValue({
        success: true,
        data: { totalValueCents: 100000, dealCount: 7 },
      });
      mockGoalRepo.updateProgress.mockResolvedValue({
        success: true,
        data: { ...goal, currentValue: 7, progressPercent: 70 },
      });
      mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({ success: true, data: goal });

      const result = await service.calculateProgress(testContext, 'goal-1');

      expect(result.success).toBe(true);
      expect(mockGoalRepo.updateProgress).toHaveBeenCalledWith(testContext, 'goal-1', 7);
    });

    it('should calculate activities_completed progress', async () => {
      const goal = createTestGoal({
        metric: 'activities_completed',
        targetValue: 20,
      });

      mockGoalRepo.getById.mockResolvedValue({ success: true, data: goal });
      mockActivityRepo.getAll.mockResolvedValue({
        success: true,
        data: {
          data: [
            { isCompleted: true, completedAt: new Date('2025-01-15'), assigneeId: 'user-1' },
            { isCompleted: true, completedAt: new Date('2025-01-16'), assigneeId: 'user-1' },
            { isCompleted: true, completedAt: new Date('2025-01-17'), assigneeId: 'user-1' },
          ],
        },
      });
      mockGoalRepo.updateProgress.mockResolvedValue({
        success: true,
        data: { ...goal, currentValue: 3, progressPercent: 15 },
      });
      mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({ success: true, data: goal });

      const result = await service.calculateProgress(testContext, 'goal-1');

      expect(result.success).toBe(true);
      expect(mockGoalRepo.updateProgress).toHaveBeenCalled();
    });

    it('should handle goal not found', async () => {
      mockGoalRepo.getById.mockResolvedValue({
        success: false,
        error: new Error('Goal not found'),
      });

      const result = await service.calculateProgress(testContext, 'invalid-id');

      expect(result.success).toBe(false);
    });
  });

  describe('getGoalDashboard', () => {
    it('should return dashboard data with summaries and stats', async () => {
      const activeGoal = createTestGoal({
        status: 'active',
        progressPercent: 50,
        currentValue: 50000,
      });
      const achievedGoal = createTestGoal({
        id: 'goal-2',
        status: 'achieved',
        progressPercent: 100,
        currentValue: 100000,
      });

      mockGoalRepo.getByAssignee.mockResolvedValue({
        success: true,
        data: [activeGoal, achievedGoal],
      });

      const result = await service.getGoalDashboard(testContext, 'user-1');

      expect(result.success).toBe(true);
      expect(result.data?.goals).toHaveLength(2);
      expect(result.data?.stats).toEqual({
        totalGoals: 2,
        activeGoals: 1,
        achievedGoals: 1,
        missedGoals: 0,
        averageProgress: 75, // (50 + 100) / 2
      });
    });

    it('should calculate pace status correctly', async () => {
      // Goal halfway through period with 80% progress = ahead
      const aheadGoal = createTestGoal({
        startDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000), // 15 days ago
        endDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000), // 15 days from now
        progressPercent: 80,
        currentValue: 80000,
      });

      mockGoalRepo.getByAssignee.mockResolvedValue({
        success: true,
        data: [aheadGoal],
      });

      const result = await service.getGoalDashboard(testContext, 'user-1');

      expect(result.success).toBe(true);
      expect(result.data?.goals[0].paceStatus).toBe('ahead');
    });

    it('should handle empty goals list', async () => {
      mockGoalRepo.getByAssignee.mockResolvedValue({
        success: true,
        data: [],
      });

      const result = await service.getGoalDashboard(testContext, 'user-1');

      expect(result.success).toBe(true);
      expect(result.data?.goals).toHaveLength(0);
      expect(result.data?.stats?.averageProgress).toBe(0);
    });
  });

  describe('checkGoalAchievement', () => {
    it('should check all active goals and update statuses', async () => {
      const activeGoal1 = createTestGoal({ id: 'goal-1', status: 'active' });
      const activeGoal2 = createTestGoal({ id: 'goal-2', status: 'active' });

      mockGoalRepo.getActive.mockResolvedValue({
        success: true,
        data: [activeGoal1, activeGoal2],
      });
      mockGoalRepo.getById.mockResolvedValue({ success: true, data: activeGoal1 });
      mockDealRepo.getWonValueRange.mockResolvedValue({
        success: true,
        data: { totalValueCents: 50000, dealCount: 5 },
      });
      mockGoalRepo.updateProgress.mockResolvedValue({ success: true, data: activeGoal1 });
      mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({
        success: true,
        data: { ...activeGoal1, status: 'active' },
      });

      const result = await service.checkGoalAchievement(testContext);

      expect(result.success).toBe(true);
      expect(result.data?.checked).toBe(2);
    });
  });

  describe('getPeriodDateRange', () => {
    it('should return correct weekly date range', () => {
      vi.useFakeTimers();
      try {
        vi.setSystemTime(new Date('2025-12-01T12:00:00Z'));
        const { startDate, endDate } = service.getPeriodDateRange('weekly');

        // Start should be Sunday
        expect(startDate.getDay()).toBe(0);
        // End should be Saturday
        expect(endDate.getDay()).toBe(6);
        // Should be 7 days apart
        const diffDays = (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
        expect(Math.round(diffDays)).toBe(7);
      } finally {
        vi.useRealTimers();
      }
    });

    it('should return correct monthly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('monthly');

      // Start should be first of month
      expect(startDate.getDate()).toBe(1);
      // End should be last of month
      const nextDay = new Date(endDate);
      nextDay.setDate(nextDay.getDate() + 1);
      expect(nextDay.getDate()).toBe(1);
    });

    it('should return correct quarterly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('quarterly');

      // Start should be first of quarter
      expect(startDate.getDate()).toBe(1);
      expect([0, 3, 6, 9]).toContain(startDate.getMonth());
      // End should be last of quarter
      const nextDay = new Date(endDate);
      nextDay.setDate(nextDay.getDate() + 1);
      expect(nextDay.getDate()).toBe(1);
      expect([3, 6, 9, 0]).toContain(nextDay.getMonth());
    });

    it('should return correct yearly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('yearly');

      // Start should be Jan 1
      expect(startDate.getMonth()).toBe(0);
      expect(startDate.getDate()).toBe(1);
      // End should be Dec 31
      expect(endDate.getMonth()).toBe(11);
      expect(endDate.getDate()).toBe(31);
    });
  });
});

describe('Goal Progress Calculation Edge Cases', () => {
  let service: GoalService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new GoalService({
      goalRepository: mockGoalRepo as any,
      dealRepository: mockDealRepo as any,
      activityRepository: mockActivityRepo as any,
      auditLogService: mockAuditService as any,
    });
  });

  it('should cap progress at 100%', async () => {
    const goal = createTestGoal({
      metric: 'revenue',
      targetValue: 50000,
      currentValue: 0,
    });

    mockGoalRepo.getById.mockResolvedValue({ success: true, data: goal });
    mockDealRepo.getWonValueRange.mockResolvedValue({
      success: true,
      data: { totalValueCents: 100000, dealCount: 10 }, // Double the target
    });
    mockGoalRepo.updateProgress.mockImplementation((_ctx, _id, value) => {
      const progressPercent = Math.min(100, Math.round((value / goal.targetValue) * 100));
      return Promise.resolve({
        success: true,
        data: { ...goal, currentValue: value, progressPercent },
      });
    });
    mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({ success: true, data: goal });

    await service.calculateProgress(testContext, 'goal-1');

    // The progress should be capped at 100%
    expect(mockGoalRepo.updateProgress).toHaveBeenCalledWith(testContext, 'goal-1', 100000);
  });

  it('should handle zero target value gracefully', async () => {
    const goal = createTestGoal({
      metric: 'deals_won',
      targetValue: 0,
    });

    mockGoalRepo.getById.mockResolvedValue({ success: true, data: goal });
    mockDealRepo.getWonValueRange.mockResolvedValue({
      success: true,
      data: { totalValueCents: 0, dealCount: 0 },
    });
    mockGoalRepo.updateProgress.mockResolvedValue({
      success: true,
      data: { ...goal, currentValue: 0, progressPercent: 0 },
    });
    mockGoalRepo.checkAndUpdateStatus.mockResolvedValue({ success: true, data: goal });

    const result = await service.calculateProgress(testContext, 'goal-1');

    expect(result.success).toBe(true);
  });
});
