/**
 * Goal Service
 * Business logic for goal management and progress calculation
 *
 * HIPAA Compliance Notes:
 * - Goals contain no PHI (deal values, counts only)
 * - Audit logs include IDs only, no names/notes
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getGoalRepository, getDealRepository, getActivityRepository } from '../data/repositories';
import type { GoalRepository, DealRepository, ActivityRepository } from '../data/repositories';
import type {
  Goal,
  GoalMetric,
  GoalPeriod,
  GoalAssigneeType,
  GoalProgressSummary,
  GoalDashboardStats,
  CreateGoalData,
} from '../types/goals';
import { AuditLogService } from './AuditLogService';

// ============================================
// Types
// ============================================

export interface GoalServiceDependencies {
  goalRepository?: GoalRepository;
  dealRepository?: DealRepository;
  activityRepository?: ActivityRepository;
  auditLogService?: AuditLogService;
}

// ============================================
// Goal Service
// ============================================

export class GoalService {
  private readonly goalRepo: GoalRepository;
  private readonly dealRepo: DealRepository;
  private readonly activityRepo: ActivityRepository;
  private readonly auditService: AuditLogService;

  constructor(dependencies: GoalServiceDependencies = {}) {
    this.goalRepo = dependencies.goalRepository ?? getGoalRepository();
    this.dealRepo = dependencies.dealRepository ?? getDealRepository();
    this.activityRepo = dependencies.activityRepository ?? getActivityRepository();
    this.auditService = dependencies.auditLogService ?? new AuditLogService();
  }

  // ============================================
  // Goal Creation
  // ============================================

  /**
   * Create a new goal with validation
   */
  async createGoal(
    context: SecurityContext,
    goalData: CreateGoalData
  ): Promise<{ success: boolean; data: Goal | null; error?: Error }> {
    try {
      // Validate date range - cast to Date for comparison
      const startDate = goalData.startDate as Date;
      const endDate = goalData.endDate as Date;
      if (startDate >= endDate) {
        return {
          success: false,
          data: null,
          error: new Error('End date must be after start date'),
        };
      }

      // Create goal
      const result = await this.goalRepo.create(context, goalData as any);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'create',
          entityType: 'report',
          entityId: result.data.id,
          metadata: {
            metric: goalData.metric,
            period: goalData.period,
            assigneeType: goalData.assigneeType,
            assigneeId: goalData.assigneeId,
          },
        });
      }

      return {
        success: result.success,
        data: result.success ? result.data : null,
        error: result.success ? undefined : new Error(result.error?.message || 'Failed to create goal'),
      };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  // ============================================
  // Progress Calculation
  // ============================================

  /**
   * Calculate and update progress for a single goal
   */
  async calculateProgress(
    context: SecurityContext,
    goalId: string
  ): Promise<{ success: boolean; data: Goal | null; error?: Error }> {
    try {
      // Get the goal
      const goalResult = await this.goalRepo.getById(context, goalId);
      if (!goalResult.success) {
        return { success: false, data: null, error: new Error(goalResult.error?.message || 'Goal not found') };
      }

      const goal = goalResult.data;

      // Calculate current value based on metric type
      const currentValue = await this.calculateMetricValue(
        context,
        goal.metric,
        goal.assigneeType,
        goal.assigneeId,
        goal.startDate,
        goal.endDate,
        goal.pipelineId
      );

      // Update goal progress
      const updateResult = await this.goalRepo.updateProgress(context, goalId, currentValue);

      if (updateResult.success) {
        // Check if goal should be marked as achieved/missed
        await this.goalRepo.checkAndUpdateStatus(context, goalId);
      }

      return { success: true, data: updateResult.data, error: updateResult.error ? new Error(updateResult.error.message) : undefined };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  /**
   * Calculate metric value based on type
   */
  private async calculateMetricValue(
    context: SecurityContext,
    metric: GoalMetric,
    assigneeType: GoalAssigneeType,
    assigneeId: string,
    startDate: Date,
    endDate: Date,
    pipelineId?: string
  ): Promise<number> {
    switch (metric) {
      case 'revenue':
        return this.calculateRevenue(context, assigneeType, assigneeId, startDate, endDate, pipelineId);

      case 'deals_won':
        return this.calculateDealsWon(context, assigneeType, assigneeId, startDate, endDate, pipelineId);

      case 'deals_created':
        return this.calculateDealsCreated(context, assigneeType, assigneeId, startDate, endDate, pipelineId);

      case 'activities_completed':
        return this.calculateActivitiesCompleted(context, assigneeType, assigneeId, startDate, endDate);

      case 'calls_made':
        return this.calculateCallsMade(context, assigneeType, assigneeId, startDate, endDate);

      case 'emails_sent':
        return this.calculateEmailsSent(context, assigneeType, assigneeId, startDate, endDate);

      default:
        return 0;
    }
  }

  /**
   * Calculate total revenue from won deals
   */
  private async calculateRevenue(
    context: SecurityContext,
    _assigneeType: GoalAssigneeType,
    _assigneeId: string,
    startDate: Date,
    endDate: Date,
    __pipelineId?: string
  ): Promise<number> {
    const result = await this.dealRepo.getWonValueRange(context, startDate, endDate);
    if (!result.success) return 0;

    // TODO: Filter by assignee if needed
    // For now, returns total won value
    return result.data.totalValueCents;
  }

  /**
   * Calculate number of won deals
   */
  private async calculateDealsWon(
    context: SecurityContext,
    _assigneeType: GoalAssigneeType,
    _assigneeId: string,
    startDate: Date,
    endDate: Date,
    __pipelineId?: string
  ): Promise<number> {
    const result = await this.dealRepo.getWonValueRange(context, startDate, endDate);
    if (!result.success) return 0;

    // TODO: Filter by assignee if needed
    return result.data.dealCount;
  }

  /**
   * Calculate number of deals created
   */
  private async calculateDealsCreated(
    context: SecurityContext,
    _assigneeType: GoalAssigneeType,
    _assigneeId: string,
    startDate: Date,
    endDate: Date,
    __pipelineId?: string
  ): Promise<number> {
    // Get all deals and filter by date range
    const result = await this.dealRepo.getByStatus(context, 'open');
    if (!result.success) return 0;

    // Count deals created in date range
    // Note: In production, this should be a more efficient query
    const dealsInRange = result.data.filter((deal) => {
      const createdAt = deal.createdAt instanceof Date ? deal.createdAt : new Date(deal.createdAt);
      return createdAt >= startDate && createdAt <= endDate;
    });

    // TODO: Filter by assignee if needed
    return dealsInRange.length;
  }

  /**
   * Calculate completed activities
   */
  private async calculateActivitiesCompleted(
    context: SecurityContext,
    assigneeType: GoalAssigneeType,
    assigneeId: string,
    startDate: Date,
    endDate: Date
  ): Promise<number> {
    // Use activity repository to get completed activities
    const result = await this.activityRepo.getAll(context, {
      where: [{ field: 'isCompleted', operator: '==', value: true }],
    });

    if (!result.success) return 0;

    // Filter by date range and assignee
    const activitiesInRange = result.data.data.filter((activity) => {
      if (!activity.completedAt) return false;
      const completedAt = activity.completedAt instanceof Date
        ? activity.completedAt
        : new Date(activity.completedAt);

      const inDateRange = completedAt >= startDate && completedAt <= endDate;

      // Filter by assignee if user-scoped goal
      if (assigneeType === 'user') {
        return inDateRange && activity.assigneeId === assigneeId;
      }

      return inDateRange;
    });

    return activitiesInRange.length;
  }

  /**
   * Calculate calls made
   */
  private async calculateCallsMade(
    context: SecurityContext,
    assigneeType: GoalAssigneeType,
    assigneeId: string,
    startDate: Date,
    endDate: Date
  ): Promise<number> {
    const result = await this.activityRepo.getAll(context, {
      where: [
        { field: 'type', operator: '==', value: 'call' },
        { field: 'isCompleted', operator: '==', value: true },
      ],
    });

    if (!result.success) return 0;

    // Filter by date range and assignee
    const callsInRange = result.data.data.filter((activity) => {
      if (!activity.completedAt) return false;
      const completedAt = activity.completedAt instanceof Date
        ? activity.completedAt
        : new Date(activity.completedAt);

      const inDateRange = completedAt >= startDate && completedAt <= endDate;

      if (assigneeType === 'user') {
        return inDateRange && activity.assigneeId === assigneeId;
      }

      return inDateRange;
    });

    return callsInRange.length;
  }

  /**
   * Calculate emails sent
   */
  private async calculateEmailsSent(
    context: SecurityContext,
    assigneeType: GoalAssigneeType,
    assigneeId: string,
    startDate: Date,
    endDate: Date
  ): Promise<number> {
    const result = await this.activityRepo.getAll(context, {
      where: [
        { field: 'type', operator: '==', value: 'email' },
        { field: 'isCompleted', operator: '==', value: true },
      ],
    });

    if (!result.success) return 0;

    // Filter by date range and assignee
    const emailsInRange = result.data.data.filter((activity) => {
      if (!activity.completedAt) return false;
      const completedAt = activity.completedAt instanceof Date
        ? activity.completedAt
        : new Date(activity.completedAt);

      const inDateRange = completedAt >= startDate && completedAt <= endDate;

      if (assigneeType === 'user') {
        return inDateRange && activity.assigneeId === assigneeId;
      }

      return inDateRange;
    });

    return emailsInRange.length;
  }

  // ============================================
  // Goal Dashboard
  // ============================================

  /**
   * Get goal dashboard data for a user
   */
  async getGoalDashboard(
    context: SecurityContext,
    userId: string
  ): Promise<{
    success: boolean;
    data: { goals: GoalProgressSummary[]; stats: GoalDashboardStats } | null;
    error?: Error;
  }> {
    try {
      // Get user's goals
      const goalsResult = await this.goalRepo.getByAssignee(context, 'user', userId);
      if (!goalsResult.success) {
        return { success: false, data: null, error: new Error(goalsResult.error?.message || 'Failed to get goals') };
      }

      const goals = goalsResult.data;
      const now = new Date();

      // Build progress summaries
      const progressSummaries: GoalProgressSummary[] = goals.map((goal) => {
        const daysRemaining = this.calculateDaysRemaining(goal.endDate, now);
        const dailyTarget = this.calculateDailyTarget(goal, daysRemaining);
        const paceStatus = this.calculatePaceStatus(goal, daysRemaining);
        const projectedEndValue = this.projectEndValue(goal, daysRemaining);

        return {
          goal,
          daysRemaining,
          dailyTarget,
          paceStatus,
          projectedEndValue,
        };
      });

      // Calculate stats
      const stats: GoalDashboardStats = {
        totalGoals: goals.length,
        activeGoals: goals.filter((g) => g.status === 'active').length,
        achievedGoals: goals.filter((g) => g.status === 'achieved').length,
        missedGoals: goals.filter((g) => g.status === 'missed').length,
        averageProgress: goals.length > 0
          ? goals.reduce((sum, g) => sum + g.progressPercent, 0) / goals.length
          : 0,
      };

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: userId,
        metadata: {
          totalGoals: stats.totalGoals,
          activeGoals: stats.activeGoals,
        },
      });

      return {
        success: true,
        data: { goals: progressSummaries, stats },
      };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  /**
   * Check all active goals and update status
   */
  async checkGoalAchievement(context: SecurityContext): Promise<{
    success: boolean;
    data: { checked: number; achieved: number; missed: number } | null;
    error?: Error;
  }> {
    try {
      const activeResult = await this.goalRepo.getActive(context);
      if (!activeResult.success) {
        return { success: false, data: null, error: new Error(activeResult.error?.message || 'Failed to get active goals') };
      }

      let achieved = 0;
      let missed = 0;

      for (const goal of activeResult.data) {
        // Calculate current progress
        await this.calculateProgress(context, goal.id);

        // Check and update status
        const statusResult = await this.goalRepo.checkAndUpdateStatus(context, goal.id);
        if (statusResult.success) {
          if (statusResult.data.status === 'achieved') achieved++;
          if (statusResult.data.status === 'missed') missed++;
        }
      }

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: 'check-achievement',
        metadata: {
          checked: activeResult.data.length,
          achieved,
          missed,
        },
      });

      return {
        success: true,
        data: {
          checked: activeResult.data.length,
          achieved,
          missed,
        },
      };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private calculateDaysRemaining(endDate: Date, now: Date): number {
    const end = endDate instanceof Date ? endDate : new Date(endDate);
    const diffMs = end.getTime() - now.getTime();
    return Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
  }

  private calculateDailyTarget(goal: Goal, daysRemaining: number): number {
    if (daysRemaining <= 0) return 0;
    const remaining = goal.targetValue - goal.currentValue;
    return Math.max(0, remaining / daysRemaining);
  }

  private calculatePaceStatus(
    goal: Goal,
    daysRemaining: number
  ): 'on_track' | 'ahead' | 'behind' | 'at_risk' {
    if (goal.progressPercent >= 100) return 'ahead';

    // Calculate expected progress based on time elapsed
    const start = goal.startDate instanceof Date ? goal.startDate : new Date(goal.startDate);
    const end = goal.endDate instanceof Date ? goal.endDate : new Date(goal.endDate);
    const totalDays = Math.max(1, (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
    const elapsedDays = totalDays - daysRemaining;
    const expectedProgress = (elapsedDays / totalDays) * 100;

    const progressDiff = goal.progressPercent - expectedProgress;

    if (progressDiff >= 10) return 'ahead';
    if (progressDiff >= -5) return 'on_track';
    if (progressDiff >= -20) return 'behind';
    return 'at_risk';
  }

  private projectEndValue(goal: Goal, daysRemaining: number): number {
    if (daysRemaining <= 0) return goal.currentValue;

    const start = goal.startDate instanceof Date ? goal.startDate : new Date(goal.startDate);
    const now = new Date();
    const elapsedDays = Math.max(1, (now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
    const dailyRate = goal.currentValue / elapsedDays;

    return goal.currentValue + dailyRate * daysRemaining;
  }

  // ============================================
  // Period Helpers
  // ============================================

  /**
   * Get date range for a period starting from today
   */
  getPeriodDateRange(period: GoalPeriod): { startDate: Date; endDate: Date } {
    const now = new Date();
    const start = new Date(now);
    const end = new Date(now);

    switch (period) {
      case 'weekly':
        {
          const dayMs = 24 * 60 * 60 * 1000;
          const todayStart = new Date(now);
          todayStart.setHours(0, 0, 0, 0);
          const startMs = todayStart.getTime() - todayStart.getDay() * dayMs;
          start.setTime(startMs);
          end.setTime(startMs + 6 * dayMs);
        }
        break;
      case 'monthly':
        start.setDate(1);
        end.setMonth(end.getMonth() + 1);
        end.setDate(0);
        break;
      case 'quarterly':
        const quarter = Math.floor(start.getMonth() / 3);
        start.setMonth(quarter * 3);
        start.setDate(1);
        end.setMonth(quarter * 3 + 3);
        end.setDate(0);
        break;
      case 'yearly':
        start.setMonth(0);
        start.setDate(1);
        end.setMonth(11);
        end.setDate(31);
        break;
    }

    start.setHours(0, 0, 0, 0);
    end.setHours(23, 59, 59, 999);

    return { startDate: start, endDate: end };
  }
}

// Export singleton instance
let goalServiceInstance: GoalService | null = null;

export function getGoalService(): GoalService {
  if (!goalServiceInstance) {
    goalServiceInstance = new GoalService();
  }
  return goalServiceInstance;
}
