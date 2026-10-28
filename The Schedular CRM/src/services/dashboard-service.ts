/**
 * Dashboard Service
 * Comprehensive service for managing customizable dashboards and widgets.
 *
 * HIPAA Compliance Notes:
 * - Dashboards contain no PHI (configuration only)
 * - Widget data respects RBAC - users only see data they have access to
 * - All dashboard access is logged via audit service
 * - Quick stats aggregate data, never expose individual PHI
 */

import type { SecurityContext, RepositoryResult } from '../data/repositories/repository-types';
import {
  getDealRepository,
  getLeadRepository,
  getActivityRepository,
  getSequenceEnrollmentRepository,
} from '../data/repositories';
import type {
  DealRepository,
  LeadRepository,
  ActivityRepository,
} from '../data/repositories';
import type { SequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { DashboardRepository, getDashboardRepository } from '../data/repositories/dashboard-repository';
import type {
  Dashboard,
  DashboardWidget,
  QuickStats,
  MetricValue,
  DateRange,
} from '../types/reporting';
import type { SalesActivity } from '../types/models';
import { AuditLogService } from './AuditLogService';
import { getReportingService, ReportingService } from './reporting-service';
import { AuthorizationError, InvalidArgumentError, failedResult, successResult } from '../data/errors/repository-errors';
import { getFeatureFlags } from '../config/features';
import { validateSecurityContext } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface DashboardServiceDependencies {
  dashboardRepository?: DashboardRepository;
  dealRepository?: DealRepository;
  leadRepository?: LeadRepository;
  activityRepository?: ActivityRepository;
  sequenceEnrollmentRepository?: SequenceEnrollmentRepository;
  reportingService?: ReportingService;
  auditLogService?: AuditLogService;
}

export type CreateDashboardInput = Omit<Dashboard, 'id' | 'businessId' | 'createdAt' | 'updatedAt'>;

export interface WidgetDataResult {
  widgetId: string;
  widgetType: string;
  data: unknown;
  generatedAt: Date;
  error?: string;
}

export interface LeaderboardEntry {
  id: string;
  name: string;
  value: number;
  rank: number;
  /** Whether this entry represents the current user */
  isCurrentUser?: boolean;
}

export interface ActivityFeedItem {
  id: string;
  type: string;
  title: string;
  description?: string;
  entityType?: string;
  entityId?: string;
  entityName?: string;
  createdAt: Date;
  createdByName?: string;
}

export interface TaskItem {
  id: string;
  title: string;
  dueDate?: Date;
  isCompleted: boolean;
  assigneeName?: string;
  entityType?: string;
  entityId?: string;
  entityName?: string;
}

// ============================================
// Dashboard Service
// ============================================

export class DashboardService {
  private readonly dashboardRepo: DashboardRepository;
  private readonly dealRepo: DealRepository;
  private readonly leadRepo: LeadRepository;
  private readonly activityRepo: ActivityRepository;
  private readonly enrollmentRepo: SequenceEnrollmentRepository;
  private readonly reportingService: ReportingService;
  private readonly auditService: AuditLogService;

  constructor(dependencies: DashboardServiceDependencies = {}) {
    this.dashboardRepo = dependencies.dashboardRepository ?? getDashboardRepository();
    this.dealRepo = dependencies.dealRepository ?? getDealRepository();
    this.leadRepo = dependencies.leadRepository ?? getLeadRepository();
    this.activityRepo = dependencies.activityRepository ?? getActivityRepository();
    this.enrollmentRepo = dependencies.sequenceEnrollmentRepository ?? getSequenceEnrollmentRepository();
    this.reportingService = dependencies.reportingService ?? getReportingService();
    this.auditService = dependencies.auditLogService ?? new AuditLogService();
  }

  // ============================================
  // Dashboard CRUD
  // ============================================

  /**
   * Create a new dashboard
   */
  async createDashboard(
    context: SecurityContext,
    dashboard: CreateDashboardInput
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      if (context.userRole === 'frontDesk' || context.userRole === 'client') {
        return failedResult(new AuthorizationError('Not authorized to create dashboards'));
      }

      const result = await this.dashboardRepo.create(context, {
        ...dashboard,
        businessId: context.businessId,
        ownerId: dashboard.ownerId || context.userId,
        ownerName: dashboard.ownerName || context.userName,
        teamIds: dashboard.teamIds || context.teamIds || [],
        widgets: dashboard.widgets || [],
        layout: dashboard.layout || 'grid',
        isDefault: dashboard.isDefault || false,
        isPublic: dashboard.isPublic || false,
      });

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'create',
          entityType: 'report',
          entityId: result.data.id,
          metadata: {
            name: dashboard.name,
            widgetCount: Array.isArray(dashboard.widgets) ? dashboard.widgets.length : 0,
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Update an existing dashboard
   */
  async updateDashboard(
    context: SecurityContext,
    dashboardId: string,
    updates: Partial<Dashboard>
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const result = await this.dashboardRepo.update(context, dashboardId, updates);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'update',
          entityType: 'report',
          entityId: dashboardId,
          metadata: {
            updatedFields: Object.keys(updates),
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Delete a dashboard
   */
  async deleteDashboard(
    context: SecurityContext,
    dashboardId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      // Get dashboard first for audit log
      const existing = await this.dashboardRepo.getById(context, dashboardId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const result = await this.dashboardRepo.delete(context, dashboardId);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'delete',
          entityType: 'report',
          entityId: dashboardId,
          metadata: {
            name: existing.data.name,
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get all dashboards accessible to the user
   */
  async getDashboards(context: SecurityContext): Promise<RepositoryResult<Dashboard[]>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const result = await this.dashboardRepo.getAccessible(context);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'read',
          entityType: 'report',
          entityId: 'list',
          metadata: {
            count: result.data.length,
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get a specific dashboard by ID
   */
  async getDashboard(
    context: SecurityContext,
    dashboardId: string
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const result = await this.dashboardRepo.getById(context, dashboardId);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'read',
          entityType: 'report',
          entityId: dashboardId,
          metadata: {
            name: result.data.name,
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get the default dashboard for the user
   */
  async getDefaultDashboard(
    context: SecurityContext
  ): Promise<RepositoryResult<Dashboard | null>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const result = await this.dashboardRepo.getDefaultForRole(context);

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'read',
          entityType: 'report',
          entityId: result.data?.id || 'none',
          metadata: {
            action: 'getDefault',
            role: context.userRole,
            found: Boolean(result.data),
          },
        });
      }

      return result;
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Widget Data
  // ============================================

  /**
   * Get data for a specific widget
   */
  async getWidgetData(
    context: SecurityContext,
    widget: DashboardWidget
  ): Promise<RepositoryResult<WidgetDataResult>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      let data: unknown;

      switch (widget.type) {
        case 'report':
          data = await this.getReportWidgetData(context, widget);
          break;
        case 'metric':
          data = await this.getMetricWidgetData(context, widget);
          break;
        case 'leaderboard':
          data = await this.getLeaderboardWidgetData(context, widget);
          break;
        case 'activity_feed':
          data = await this.getActivityFeedWidgetData(context, widget);
          break;
        case 'tasks':
          data = await this.getTasksWidgetData(context, widget);
          break;
        default:
          return failedResult(new InvalidArgumentError(`Unknown widget type: ${widget.type}`, 'widget.type'));
      }

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: widget.id,
        metadata: {
          widgetType: widget.type,
          widgetTitle: widget.title,
        },
      });

      return successResult({
        widgetId: widget.id,
        widgetType: widget.type,
        data,
        generatedAt: new Date(),
      });
    } catch (error) {
      return successResult({
        widgetId: widget.id,
        widgetType: widget.type,
        data: null,
        generatedAt: new Date(),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Get data for all widgets in a dashboard
   */
  async getAllWidgetData(
    context: SecurityContext,
    dashboardId: string
  ): Promise<RepositoryResult<WidgetDataResult[]>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const dashboardResult = await this.dashboardRepo.getById(context, dashboardId);
      if (!dashboardResult.success) {
        return failedResult(dashboardResult.error);
      }

      const results: WidgetDataResult[] = [];

      for (const widget of dashboardResult.data.widgets) {
        const widgetResult = await this.getWidgetData(context, widget);
        if (widgetResult.success) {
          results.push(widgetResult.data);
        }
      }

      return successResult(results);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  private async getReportWidgetData(
    context: SecurityContext,
    widget: DashboardWidget
  ): Promise<unknown> {
    if (!widget.reportId) {
      throw new InvalidArgumentError('Report widget requires reportId', 'reportId');
    }

    const result = await this.reportingService.runReport(context, widget.reportId);
    if (!result.success) {
      throw result.error || new Error('Failed to run report');
    }

    return result.data;
  }

  private async getMetricWidgetData(
    context: SecurityContext,
    widget: DashboardWidget
  ): Promise<MetricValue> {
    if (!widget.metricConfig) {
      throw new InvalidArgumentError('Metric widget requires metricConfig', 'metricConfig');
    }

    const result = await this.reportingService.getMetric(context, widget.metricConfig.metric);
    if (!result.success) {
      throw result.error || new Error('Failed to get metric');
    }

    return result.data;
  }

  private async getLeaderboardWidgetData(
    context: SecurityContext,
    widget: DashboardWidget
  ): Promise<LeaderboardEntry[]> {
    if (!widget.leaderboardConfig) {
      throw new InvalidArgumentError('Leaderboard widget requires leaderboardConfig', 'leaderboardConfig');
    }

    const config = widget.leaderboardConfig;
    const dateRange = this.resolveDateRange(config.dateRange);

    // SECURITY: Check if user can see individual names
    // Assistants and staff can only see their own data or anonymized data
    const canSeeAllNames = this.canViewLeaderboardNames(context);

    // Fetch data based on metric
    const entries: LeaderboardEntry[] = [];

    if (config.entityType === 'user') {
      // Get deals won by assignee
      const dealsResult = await this.dealRepo.getByStatus(context, 'won');
      if (dealsResult.success) {
        const wonDeals = dealsResult.data.filter((deal) => {
          const closedAt = deal.closedAt;
          if (!closedAt) return false;
          return closedAt >= dateRange.start && closedAt <= dateRange.end;
        });

        const dealsByUser = new Map<string, { name: string; value: number }>();

        for (const deal of wonDeals) {
          const userId = deal.assigneeId || 'unassigned';
          const userName = deal.assigneeName || 'Unassigned';
          const existing = dealsByUser.get(userId) || { name: userName, value: 0 };

          if (config.metric === 'deals_won') {
            existing.value += 1;
          } else if (config.metric === 'revenue') {
            existing.value += deal.valueCents || 0;
          }

          dealsByUser.set(userId, existing);
        }

        let rank = 1;
        const sorted = Array.from(dealsByUser.entries())
          .sort((a, b) => b[1].value - a[1].value)
          .slice(0, config.limit);

        for (const [userId, data] of sorted) {
          const isCurrentUser = userId === context.userId;
          entries.push({
            id: userId,
            // SECURITY: Redact names for lower-privileged users (only show their own name)
            name: canSeeAllNames || isCurrentUser ? data.name : this.redactLeaderboardName(rank),
            value: data.value,
            rank: rank++,
            isCurrentUser,
          });
        }
      }
    }

    return entries;
  }

  /**
   * Check if user can view individual names in leaderboards
   * SECURITY: Lower-privileged users see anonymized data to protect privacy
   */
  private canViewLeaderboardNames(context: SecurityContext): boolean {
    // Managers and above can see all names
    const allowedRoles = ['manager', 'admin', 'owner'];
    return allowedRoles.includes(context.userRole);
  }

  /**
   * Generate anonymized name for leaderboard position
   * SECURITY: Protects individual performance data from lower-privileged users
   */
  private redactLeaderboardName(rank: number): string {
    return `Team Member #${rank}`;
  }

  private async getActivityFeedWidgetData(
    context: SecurityContext,
    _widget: DashboardWidget
  ): Promise<ActivityFeedItem[]> {
    const result = await this.activityRepo.getAll(context, {
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: 10,
    });

    if (!result.success) {
      return [];
    }

    return result.data.data.map((activity: SalesActivity) => ({
      id: activity.id,
      type: activity.type,
      title: activity.title,
      description: activity.description,
      entityType: activity.dealId ? 'deal' : activity.leadId ? 'lead' : activity.clientId ? 'client' : undefined,
      entityId: activity.dealId || activity.leadId || activity.clientId,
      createdAt: activity.createdAt,
      createdByName: activity.createdByName,
    }));
  }

  private async getTasksWidgetData(
    context: SecurityContext,
    _widget: DashboardWidget
  ): Promise<TaskItem[]> {
    const result = await this.activityRepo.getAll(context, {
      where: [
        { field: 'type', operator: '==', value: 'task' },
        { field: 'isCompleted', operator: '==', value: false },
      ],
      orderBy: { field: 'dueDate', direction: 'asc' },
      limit: 10,
    });

    if (!result.success) {
      return [];
    }

    return result.data.data.map((activity: SalesActivity) => ({
      id: activity.id,
      title: activity.title,
      dueDate: activity.dueDate,
      isCompleted: activity.isCompleted || false,
      assigneeName: activity.assigneeName,
      entityType: activity.dealId ? 'deal' : activity.leadId ? 'lead' : activity.clientId ? 'client' : undefined,
      entityId: activity.dealId || activity.leadId || activity.clientId,
    }));
  }

  // ============================================
  // Quick Stats
  // ============================================

  /**
   * Get commonly used metrics for dashboard widgets
   */
  async getQuickStats(context: SecurityContext): Promise<RepositoryResult<QuickStats>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const now = new Date();
      const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
      const thisWeekStart = new Date(now);
      thisWeekStart.setDate(now.getDate() - now.getDay());
      thisWeekStart.setHours(0, 0, 0, 0);

      // Fetch all stats in parallel
      const [
        leadsThisMonth,
        dealsWonThisMonth,
        revenueThisMonth,
        activitiesThisWeek,
        openTasks,
        sequenceEnrollments,
      ] = await Promise.all([
        this.countLeadsThisMonth(context, thisMonthStart),
        this.countDealsWonThisMonth(context, thisMonthStart),
        this.getRevenueThisMonth(context, thisMonthStart),
        this.countActivitiesThisWeek(context, thisWeekStart),
        this.countOpenTasks(context),
        this.countActiveSequenceEnrollments(context),
      ]);

      const stats: QuickStats = {
        leadsThisMonth,
        dealsWonThisMonth,
        revenueThisMonth,
        activitiesThisWeek,
        openTasks,
        sequenceEnrollments,
      };

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: 'quickStats',
        metadata: {
          stats: {
            leadsThisMonth,
            dealsWonThisMonth,
            activitiesThisWeek,
            openTasks,
          },
        },
      });

      return successResult(stats);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  private async countLeadsThisMonth(context: SecurityContext, startDate: Date): Promise<number> {
    try {
      const result = await this.leadRepo.getFiltered(context, {
        dateRange: { start: startDate, end: new Date() },
      }, { limit: undefined });
      return result.success ? result.data.data.length : 0;
    } catch {
      return 0;
    }
  }

  private async countDealsWonThisMonth(context: SecurityContext, startDate: Date): Promise<number> {
    try {
      const result = await this.dealRepo.getWonValueRange(context, startDate, new Date());
      return result.success ? result.data.dealCount : 0;
    } catch {
      return 0;
    }
  }

  private async getRevenueThisMonth(context: SecurityContext, startDate: Date): Promise<number> {
    try {
      const result = await this.dealRepo.getWonValueRange(context, startDate, new Date());
      return result.success ? result.data.totalValueCents : 0;
    } catch {
      return 0;
    }
  }

  private async countActivitiesThisWeek(context: SecurityContext, startDate: Date): Promise<number> {
    try {
      const result = await this.activityRepo.getAll(context, {
        limit: 1000,
      });
      if (!result.success) return 0;

      return result.data.data.filter((activity: SalesActivity) => {
        const createdAt = activity.createdAt;
        return createdAt >= startDate;
      }).length;
    } catch {
      return 0;
    }
  }

  private async countOpenTasks(context: SecurityContext): Promise<number> {
    try {
      const result = await this.activityRepo.getAll(context, {
        where: [
          { field: 'type', operator: '==', value: 'task' },
          { field: 'isCompleted', operator: '==', value: false },
        ],
        limit: 1000,
      });
      return result.success ? result.data.data.length : 0;
    } catch {
      return 0;
    }
  }

  private async countActiveSequenceEnrollments(context: SecurityContext): Promise<number> {
    try {
      const result = await this.enrollmentRepo.getAll(context, {
        where: [{ field: 'status', operator: '==', value: 'active' }],
        limit: 1000,
      });
      return result.success ? result.data.data.length : 0;
    } catch {
      return 0;
    }
  }

  // ============================================
  // Widget Management Passthrough
  // ============================================

  /**
   * Add a widget to a dashboard
   */
  async addWidget(
    context: SecurityContext,
    dashboardId: string,
    widget: DashboardWidget
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.addWidget(context, dashboardId, widget);
  }

  /**
   * Update a widget in a dashboard
   */
  async updateWidget(
    context: SecurityContext,
    dashboardId: string,
    widgetId: string,
    updates: Partial<DashboardWidget>
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.updateWidget(context, dashboardId, widgetId, updates);
  }

  /**
   * Remove a widget from a dashboard
   */
  async removeWidget(
    context: SecurityContext,
    dashboardId: string,
    widgetId: string
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.removeWidget(context, dashboardId, widgetId);
  }

  /**
   * Reorder widgets in a dashboard
   */
  async reorderWidgets(
    context: SecurityContext,
    dashboardId: string,
    widgetPositions: Array<{ id: string; x: number; y: number; width?: number; height?: number }>
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.reorderWidgets(context, dashboardId, widgetPositions);
  }

  /**
   * Set a dashboard as default
   */
  async setAsDefault(
    context: SecurityContext,
    dashboardId: string,
    forRoles?: string[]
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.setAsDefault(context, dashboardId, forRoles);
  }

  /**
   * Remove default status from a dashboard
   */
  async removeDefault(
    context: SecurityContext,
    dashboardId: string
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.removeDefault(context, dashboardId);
  }

  /**
   * Duplicate a dashboard
   */
  async duplicateDashboard(
    context: SecurityContext,
    dashboardId: string,
    newName?: string
  ): Promise<RepositoryResult<Dashboard>> {
    this.ensureReportingEnabled();
    validateSecurityContext(context);
    return this.dashboardRepo.duplicate(context, dashboardId, newName);
  }

  // ============================================
  // Private Helpers
  // ============================================

  private ensureReportingEnabled(): void {
    const { enableReports, enableDashboards } = getFeatureFlags();
    if (!enableReports && !enableDashboards) {
      throw new AuthorizationError('Reporting and dashboards are disabled');
    }
  }

  private resolveDateRange(dateRange: DateRange): { start: Date; end: Date } {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let start: Date;
    let end: Date;

    switch (dateRange) {
      case 'today':
        start = today;
        end = new Date(today.getTime() + 24 * 60 * 60 * 1000 - 1);
        break;
      case 'yesterday':
        start = new Date(today.getTime() - 24 * 60 * 60 * 1000);
        end = new Date(today.getTime() - 1);
        break;
      case 'this_week':
        const dayOfWeek = today.getDay();
        start = new Date(today.getTime() - dayOfWeek * 24 * 60 * 60 * 1000);
        end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000 - 1);
        break;
      case 'last_week':
        const lastWeekStart = new Date(today.getTime() - (today.getDay() + 7) * 24 * 60 * 60 * 1000);
        start = lastWeekStart;
        end = new Date(lastWeekStart.getTime() + 7 * 24 * 60 * 60 * 1000 - 1);
        break;
      case 'this_month':
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
        break;
      case 'last_month':
        start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
        break;
      case 'this_quarter':
        const currentQuarter = Math.floor(now.getMonth() / 3);
        start = new Date(now.getFullYear(), currentQuarter * 3, 1);
        end = new Date(now.getFullYear(), currentQuarter * 3 + 3, 0, 23, 59, 59, 999);
        break;
      case 'last_quarter':
        const lastQuarter = Math.floor(now.getMonth() / 3) - 1;
        const lastQuarterYear = lastQuarter < 0 ? now.getFullYear() - 1 : now.getFullYear();
        const adjustedQuarter = lastQuarter < 0 ? 3 : lastQuarter;
        start = new Date(lastQuarterYear, adjustedQuarter * 3, 1);
        end = new Date(lastQuarterYear, adjustedQuarter * 3 + 3, 0, 23, 59, 59, 999);
        break;
      case 'this_year':
        start = new Date(now.getFullYear(), 0, 1);
        end = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
        break;
      case 'last_year':
        start = new Date(now.getFullYear() - 1, 0, 1);
        end = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59, 999);
        break;
      case 'custom':
      default:
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }

    return { start, end };
  }
}

// ============================================
// Export Singleton
// ============================================

let dashboardServiceInstance: DashboardService | null = null;

export function getDashboardService(): DashboardService {
  if (!dashboardServiceInstance) {
    dashboardServiceInstance = new DashboardService();
  }
  return dashboardServiceInstance;
}
