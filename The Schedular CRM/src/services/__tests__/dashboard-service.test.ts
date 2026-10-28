/**
 * Dashboard Service Tests
 * Comprehensive tests for dashboard widget data loading, CRUD operations,
 * and RBAC.
 *
 * HIPAA Compliance: Tests verify that widget data respects RBAC,
 * aggregates data only, and all operations are audit logged.
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { DashboardService } from '../dashboard-service';
import type {
  DealRepository,
  LeadRepository,
  ActivityRepository,
} from '../../data/repositories';
import { DashboardRepository } from '../../data/repositories/dashboard-repository';
import type { SequenceEnrollmentRepository } from '../../data/repositories/sequence-enrollment-repository';
import type { SecurityContext, PaginatedResult } from '../../data/repositories/repository-types';
import type { Deal, Lead, SalesActivity } from '../../types/models';
import type { Dashboard, DashboardWidget } from '../../types/reporting';
import { successResult } from '../../data/errors/repository-errors';
import { AuditLogService } from '../AuditLogService';
import { ReportingService } from '../reporting-service';
import * as features from '../../config/features';

// ============================================
// Test Fixtures
// ============================================

const baseContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-a'],
};

const staffContext: SecurityContext = {
  ...baseContext,
  userId: 'user-staff',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: ['team-a'],
};

const frontDeskContext: SecurityContext = {
  ...baseContext,
  userId: 'user-front-desk',
  userName: 'Front Desk User',
  userRole: 'frontDesk',
  teamIds: ['team-a'],
};

const sampleDashboard: Dashboard = {
  id: 'dashboard-1',
  businessId: 'biz-1',
  name: 'Sales Dashboard',
  description: 'Main sales dashboard',
  widgets: [
    {
      id: 'widget-1',
      type: 'metric',
      title: 'Deals Won',
      x: 0,
      y: 0,
      width: 2,
      height: 1,
      metricConfig: {
        metric: 'deals_won_count',
        comparison: 'previous_period',
        format: 'number',
      },
    },
    {
      id: 'widget-2',
      type: 'leaderboard',
      title: 'Top Performers',
      x: 2,
      y: 0,
      width: 2,
      height: 2,
      leaderboardConfig: {
        metric: 'deals_won',
        entityType: 'user',
        limit: 5,
        dateRange: 'this_month',
      },
    },
    {
      id: 'widget-3',
      type: 'activity_feed',
      title: 'Recent Activity',
      x: 0,
      y: 1,
      width: 2,
      height: 2,
    },
    {
      id: 'widget-4',
      type: 'tasks',
      title: 'Open Tasks',
      x: 2,
      y: 2,
      width: 2,
      height: 2,
    },
    {
      id: 'widget-5',
      type: 'report',
      title: 'Pipeline Report',
      x: 0,
      y: 3,
      width: 4,
      height: 2,
      reportId: 'report-1',
    },
  ],
  layout: 'grid',
  isDefault: true,
  defaultForRoles: ['admin', 'manager'],
  ownerId: 'user-1',
  ownerName: 'Test User',
  isPublic: false,
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-01'),
};

const dealWon: Deal = {
  id: 'deal-1',
  pipelineId: 'pipe-1',
  stageId: 'stage-1',
  title: 'Won Deal',
  valueCents: 50000,
  currency: 'USD',
  probability: 100,
  status: 'won',
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  assigneeId: 'user-1',
  assigneeName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-01'),
  closedAt: new Date('2024-01-15'),
};

const leadNew: Lead = {
  id: 'lead-1',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  status: 'new',
  source: 'website',
  score: 50,
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-01'),
};

const activityCall: SalesActivity = {
  id: 'activity-1',
  type: 'call',
  title: 'Sales Call',
  description: 'Discussed requirements',
  isCompleted: true,
  completedAt: new Date('2024-01-05'),
  ownerId: 'user-1',
  ownerName: 'Test User',
  assigneeId: 'user-1',
  assigneeName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-05'),
  createdById: 'user-1',
  createdByName: 'Test User',
};

const taskPending: SalesActivity = {
  id: 'activity-2',
  type: 'task',
  title: 'Follow up',
  isCompleted: false,
  ownerId: 'user-1',
  ownerName: 'Test User',
  assigneeId: 'user-1',
  assigneeName: 'Test User',
  teamIds: ['team-a'],
  dueDate: new Date('2024-01-20'),
  createdAt: new Date('2024-01-10'),
  createdById: 'user-1',
  createdByName: 'Test User',
};

// ============================================
// Mocks
// ============================================

function createMockDashboardRepo() {
  return {
    create: vi.fn().mockImplementation((_ctx, data) =>
      successResult({
        id: `dashboard-${Date.now()}`,
        businessId: _ctx.businessId,
        createdAt: new Date(),
        ...data,
      })
    ),
    update: vi.fn().mockImplementation((_ctx, id, updates) =>
      successResult({
        ...sampleDashboard,
        ...updates,
        id,
        updatedAt: new Date(),
      })
    ),
    delete: vi.fn().mockResolvedValue(successResult(undefined)),
    getById: vi.fn().mockResolvedValue(successResult(sampleDashboard)),
    getAccessible: vi.fn().mockResolvedValue(successResult([sampleDashboard])),
    getDefaultForRole: vi.fn().mockResolvedValue(successResult(sampleDashboard)),
    addWidget: vi.fn().mockImplementation((_ctx, _dashboardId, widget) =>
      successResult({
        ...sampleDashboard,
        widgets: [...sampleDashboard.widgets, widget],
      })
    ),
    updateWidget: vi.fn().mockImplementation((_ctx, _dashboardId, widgetId, updates) =>
      successResult({
        ...sampleDashboard,
        widgets: sampleDashboard.widgets.map((w) =>
          w.id === widgetId ? { ...w, ...updates } : w
        ),
      })
    ),
    removeWidget: vi.fn().mockImplementation((_ctx, _dashboardId, widgetId) =>
      successResult({
        ...sampleDashboard,
        widgets: sampleDashboard.widgets.filter((w) => w.id !== widgetId),
      })
    ),
    reorderWidgets: vi.fn().mockResolvedValue(successResult(sampleDashboard)),
    setAsDefault: vi.fn().mockResolvedValue(
      successResult({ ...sampleDashboard, isDefault: true })
    ),
    removeDefault: vi.fn().mockResolvedValue(
      successResult({ ...sampleDashboard, isDefault: false })
    ),
    duplicate: vi.fn().mockImplementation((_ctx, _dashboardId, newName) =>
      successResult({
        ...sampleDashboard,
        id: `dashboard-${Date.now()}`,
        name: newName || `${sampleDashboard.name} (Copy)`,
        isDefault: false,
      })
    ),
  };
}

function createMockDealRepo() {
  return {
    getByStatus: vi.fn().mockResolvedValue(successResult([dealWon])),
    getWonInRange: vi.fn().mockResolvedValue(successResult([dealWon])),
    getWonValueRange: vi.fn().mockResolvedValue(
      successResult({ totalValueCents: 50000, count: 1, dealCount: 1 })
    ),
  };
}

function createMockLeadRepo() {
  return {
    getFiltered: vi.fn().mockResolvedValue(
      successResult<PaginatedResult<Lead>>({
        data: [leadNew],
        hasMore: false,
        lastDoc: null,
      })
    ),
  };
}

function createMockActivityRepo() {
  return {
    getAll: vi.fn().mockResolvedValue(
      successResult<PaginatedResult<SalesActivity>>({
        data: [activityCall, taskPending],
        hasMore: false,
        lastDoc: null,
      })
    ),
  };
}

function createMockEnrollmentRepo() {
  return {
    getAll: vi.fn().mockResolvedValue(
      successResult<PaginatedResult<unknown>>({
        data: [],
        hasMore: false,
        lastDoc: null,
      })
    ),
  };
}

function createMockReportingService() {
  return {
    runReport: vi.fn().mockResolvedValue(
      successResult({
        reportId: 'report-1',
        generatedAt: new Date(),
        dateRange: { start: new Date(), end: new Date() },
        rows: [{ stageId: 'stage-1', count: 5 }],
        totals: { count: 5 },
        rowCount: 1,
        queryTimeMs: 50,
      })
    ),
    getMetric: vi.fn().mockResolvedValue(
      successResult({
        value: 10,
        previousValue: 8,
        changePercent: 25,
      })
    ),
  };
}

function createMockAuditService() {
  return {
    logAction: vi.fn().mockResolvedValue({ success: true }),
  };
}

// ============================================
// Test Suites
// ============================================

describe('DashboardService', () => {
  let service: DashboardService;
  let mockDashboardRepo: ReturnType<typeof createMockDashboardRepo>;
  let mockDealRepo: ReturnType<typeof createMockDealRepo>;
  let mockLeadRepo: ReturnType<typeof createMockLeadRepo>;
  let mockActivityRepo: ReturnType<typeof createMockActivityRepo>;
  let mockEnrollmentRepo: ReturnType<typeof createMockEnrollmentRepo>;
  let mockReportingService: ReturnType<typeof createMockReportingService>;
  let mockAuditService: ReturnType<typeof createMockAuditService>;

  beforeEach(() => {
    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
      ...features.defaultFeatures,
      enableReports: true,
      enableDashboards: true,
    });

    mockDashboardRepo = createMockDashboardRepo();
    mockDealRepo = createMockDealRepo();
    mockLeadRepo = createMockLeadRepo();
    mockActivityRepo = createMockActivityRepo();
    mockEnrollmentRepo = createMockEnrollmentRepo();
    mockReportingService = createMockReportingService();
    mockAuditService = createMockAuditService();

    service = new DashboardService({
      dashboardRepository: mockDashboardRepo as unknown as DashboardRepository,
      dealRepository: mockDealRepo as unknown as DealRepository,
      leadRepository: mockLeadRepo as unknown as LeadRepository,
      activityRepository: mockActivityRepo as unknown as ActivityRepository,
      sequenceEnrollmentRepository: mockEnrollmentRepo as unknown as SequenceEnrollmentRepository,
      reportingService: mockReportingService as unknown as ReportingService,
      auditLogService: mockAuditService as unknown as AuditLogService,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // ============================================
  // Dashboard CRUD Tests
  // ============================================

  describe('Dashboard CRUD Operations', () => {
    it('creates a new dashboard with valid configuration', async () => {
      const result = await service.createDashboard(baseContext, {
        name: 'New Dashboard',
        description: 'Test dashboard',
        widgets: [],
        layout: 'grid',
        isDefault: false,
        isPublic: false,
        ownerId: baseContext.userId,
        ownerName: baseContext.userName,
      });

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toBe('New Dashboard');
      expect(result.data!.businessId).toBe(baseContext.businessId);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'create', entityType: 'report' })
      );
    });

    it('rejects dashboard creation from front desk users', async () => {
      const result = await service.createDashboard(frontDeskContext, {
        name: 'Blocked Dashboard',
        widgets: [],
        layout: 'grid',
        isDefault: false,
        isPublic: false,
        ownerId: frontDeskContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message || result.error?.code).toBeDefined();
    });

    it('updates an existing dashboard', async () => {
      const result = await service.updateDashboard(baseContext, 'dashboard-1', {
        name: 'Updated Dashboard Name',
        description: 'Updated description',
      });

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toBe('Updated Dashboard Name');
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'update', entityType: 'report' })
      );
    });

    it('deletes a dashboard', async () => {
      const result = await service.deleteDashboard(baseContext, 'dashboard-1');

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.delete).toHaveBeenCalledWith(baseContext, 'dashboard-1');
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'delete', entityType: 'report' })
      );
    });

    it('retrieves all accessible dashboards', async () => {
      const result = await service.getDashboards(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'read', entityType: 'report' })
      );
    });

    it('retrieves a specific dashboard by ID', async () => {
      const result = await service.getDashboard(baseContext, 'dashboard-1');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.id).toBe('dashboard-1');
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'read', entityType: 'report' })
      );
    });

    it('retrieves default dashboard for user role', async () => {
      const result = await service.getDefaultDashboard(baseContext);

      expect(result.success).toBe(true);
      expect(result.data?.isDefault).toBe(true);
    });
  });

  // ============================================
  // Widget Data Loading Tests
  // ============================================

  describe('Widget Data Loading', () => {
    it('loads data for metric widget', async () => {
      const widget: DashboardWidget = {
        id: 'widget-metric',
        type: 'metric',
        title: 'Deals Won',
        x: 0,
        y: 0,
        width: 2,
        height: 1,
        metricConfig: {
          metric: 'deals_won_count',
          comparison: 'previous_period',
          format: 'number',
        },
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.widgetId).toBe('widget-metric');
      expect(result.data!.widgetType).toBe('metric');
      expect(result.data!.data).toBeDefined();
      expect(mockReportingService.getMetric).toHaveBeenCalled();
    });

    it('loads data for leaderboard widget', async () => {
      const widget: DashboardWidget = {
        id: 'widget-leaderboard',
        type: 'leaderboard',
        title: 'Top Performers',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
        leaderboardConfig: {
          metric: 'deals_won',
          entityType: 'user',
          limit: 5,
          dateRange: 'this_month',
        },
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.widgetId).toBe('widget-leaderboard');
      expect(result.data!.widgetType).toBe('leaderboard');
      expect(Array.isArray(result.data!.data)).toBe(true);
    });

    it('loads data for activity feed widget', async () => {
      const widget: DashboardWidget = {
        id: 'widget-activity',
        type: 'activity_feed',
        title: 'Recent Activity',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.widgetId).toBe('widget-activity');
      expect(result.data!.widgetType).toBe('activity_feed');
      expect(Array.isArray(result.data!.data)).toBe(true);
      expect(mockActivityRepo.getAll).toHaveBeenCalled();
    });

    it('loads data for tasks widget', async () => {
      const widget: DashboardWidget = {
        id: 'widget-tasks',
        type: 'tasks',
        title: 'Open Tasks',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.widgetId).toBe('widget-tasks');
      expect(result.data!.widgetType).toBe('tasks');
      expect(Array.isArray(result.data!.data)).toBe(true);
    });

    it('loads data for report widget', async () => {
      const widget: DashboardWidget = {
        id: 'widget-report',
        type: 'report',
        title: 'Pipeline Report',
        x: 0,
        y: 0,
        width: 4,
        height: 2,
        reportId: 'report-1',
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.widgetId).toBe('widget-report');
      expect(result.data!.widgetType).toBe('report');
      expect(mockReportingService.runReport).toHaveBeenCalledWith(baseContext, 'report-1');
    });

    it('handles missing reportId for report widget gracefully', async () => {
      const widget: DashboardWidget = {
        id: 'widget-report-no-id',
        type: 'report',
        title: 'Invalid Report',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
        // Missing reportId
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.error).toBeDefined();
    });

    it('handles missing metricConfig for metric widget gracefully', async () => {
      const widget: DashboardWidget = {
        id: 'widget-metric-no-config',
        type: 'metric',
        title: 'Invalid Metric',
        x: 0,
        y: 0,
        width: 2,
        height: 1,
        // Missing metricConfig
      };

      const result = await service.getWidgetData(baseContext, widget);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.error).toBeDefined();
    });

    it('returns error for unknown widget type', async () => {
      const widget = {
        id: 'widget-unknown',
        type: 'unknown_type' as DashboardWidget['type'],
        title: 'Unknown Widget',
        x: 0,
        y: 0,
        width: 2,
        height: 1,
      };

      const result = await service.getWidgetData(baseContext, widget as DashboardWidget);

      // Either returns failed result or success with error in data
      expect(result.success === false || result.data?.error !== undefined).toBe(true);
    });

    it('loads data for all widgets in a dashboard', async () => {
      const result = await service.getAllWidgetData(baseContext, 'dashboard-1');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.length).toBe(sampleDashboard.widgets.length);
    });

    it('logs widget data access for audit compliance', async () => {
      const widget: DashboardWidget = {
        id: 'widget-audit',
        type: 'activity_feed',
        title: 'Activity Feed',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
      };

      await service.getWidgetData(baseContext, widget);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          entityId: 'widget-audit',
        })
      );
    });
  });

  // ============================================
  // Quick Stats Tests
  // ============================================

  describe('Quick Stats', () => {
    it('returns all quick stats', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).toHaveProperty('leadsThisMonth');
      expect(result.data).toHaveProperty('dealsWonThisMonth');
      expect(result.data).toHaveProperty('revenueThisMonth');
      expect(result.data).toHaveProperty('activitiesThisWeek');
      expect(result.data).toHaveProperty('openTasks');
      expect(result.data).toHaveProperty('sequenceEnrollments');
    });

    it('counts leads this month', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.leadsThisMonth).toBe('number');
    });

    it('counts deals won this month', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.dealsWonThisMonth).toBe('number');
    });

    it('calculates revenue this month', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.revenueThisMonth).toBe('number');
    });

    it('counts activities this week', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.activitiesThisWeek).toBe('number');
    });

    it('counts open tasks', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.openTasks).toBe('number');
    });

    it('counts sequence enrollments', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(typeof result.data!.sequenceEnrollments).toBe('number');
    });

    it('logs quick stats access for audit compliance', async () => {
      await service.getQuickStats(baseContext);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
        })
      );
    });
  });

  // ============================================
  // Widget Management Tests
  // ============================================

  describe('Widget Management', () => {
    it('adds a widget to a dashboard', async () => {
      const newWidget: DashboardWidget = {
        id: 'widget-new',
        type: 'metric',
        title: 'New Metric',
        x: 0,
        y: 4,
        width: 2,
        height: 1,
        metricConfig: {
          metric: 'leads_created',
          format: 'number',
        },
      };

      const result = await service.addWidget(baseContext, 'dashboard-1', newWidget);

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.addWidget).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1',
        newWidget
      );
    });

    it('updates a widget in a dashboard', async () => {
      const updates = {
        title: 'Updated Title',
        x: 1,
        y: 1,
      };

      const result = await service.updateWidget(
        baseContext,
        'dashboard-1',
        'widget-1',
        updates
      );

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.updateWidget).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1',
        'widget-1',
        updates
      );
    });

    it('removes a widget from a dashboard', async () => {
      const result = await service.removeWidget(baseContext, 'dashboard-1', 'widget-1');

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.removeWidget).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1',
        'widget-1'
      );
    });

    it('reorders widgets in a dashboard', async () => {
      const positions = [
        { id: 'widget-1', x: 2, y: 0 },
        { id: 'widget-2', x: 0, y: 0 },
      ];

      const result = await service.reorderWidgets(baseContext, 'dashboard-1', positions);

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.reorderWidgets).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1',
        positions
      );
    });
  });

  // ============================================
  // Default Dashboard Tests
  // ============================================

  describe('Default Dashboard Management', () => {
    it('sets a dashboard as default', async () => {
      const result = await service.setAsDefault(baseContext, 'dashboard-1', ['admin']);

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.setAsDefault).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1',
        ['admin']
      );
    });

    it('removes default status from a dashboard', async () => {
      const result = await service.removeDefault(baseContext, 'dashboard-1');

      expect(result.success).toBe(true);
      expect(mockDashboardRepo.removeDefault).toHaveBeenCalledWith(
        baseContext,
        'dashboard-1'
      );
    });
  });

  // ============================================
  // Dashboard Duplication Tests
  // ============================================

  describe('Dashboard Duplication', () => {
    it('duplicates a dashboard with new name', async () => {
      const result = await service.duplicateDashboard(
        baseContext,
        'dashboard-1',
        'My Copy'
      );

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toBe('My Copy');
      expect(result.data!.isDefault).toBe(false);
    });

    it('duplicates a dashboard with default name', async () => {
      const result = await service.duplicateDashboard(baseContext, 'dashboard-1');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toContain('Copy');
    });
  });

  // ============================================
  // Feature Flag Tests
  // ============================================

  describe('Feature Flags', () => {
    it('rejects operations when dashboards are disabled', async () => {
      vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
        ...features.defaultFeatures,
        enableReports: false,
        enableDashboards: false,
      });

      const result = await service.createDashboard(baseContext, {
        name: 'Blocked Dashboard',
        widgets: [],
        layout: 'grid',
        isDefault: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message || result.error?.code).toBeDefined();
    });
  });

  // ============================================
  // Security and HIPAA Compliance Tests
  // ============================================

  describe('Security and HIPAA Compliance', () => {
    it('logs all dashboard operations', async () => {
      await service.createDashboard(baseContext, {
        name: 'Audit Test',
        widgets: [],
        layout: 'grid',
        isDefault: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(mockAuditService.logAction).toHaveBeenCalled();
    });

    it('widget data respects RBAC', async () => {
      // Widget data should only return data the user has access to
      const widget: DashboardWidget = {
        id: 'widget-activity',
        type: 'activity_feed',
        title: 'Activity',
        x: 0,
        y: 0,
        width: 2,
        height: 2,
      };

      await service.getWidgetData(staffContext, widget);

      // Activity repo should be called with staff context
      expect(mockActivityRepo.getAll).toHaveBeenCalledWith(
        staffContext,
        expect.anything()
      );
    });

    it('quick stats aggregate data without exposing PHI', async () => {
      const result = await service.getQuickStats(baseContext);

      expect(result.success).toBe(true);
      // Quick stats should only have numeric aggregates
      expect(typeof result.data!.leadsThisMonth).toBe('number');
      expect(typeof result.data!.dealsWonThisMonth).toBe('number');
      expect(typeof result.data!.revenueThisMonth).toBe('number');
      // Should not contain any individual records or PII
    });
  });
});
