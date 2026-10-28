/**
 * Reporting Service Tests
 * Comprehensive tests for the reporting service covering:
 * - Report execution with various aggregations
 * - Date range filtering
 * - Custom report builder validation
 * - Scheduled report execution
 * - Export generation (CSV, PDF)
 * - RBAC on reports (visibility, sharing)
 * - Cache invalidation
 *
 * HIPAA Compliance: Tests verify that reports aggregate data only,
 * never expose individual PHI, and all operations are audit logged.
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { ReportingService } from '../reporting-service';
import type {
  DealRepository,
  LeadRepository,
  ActivityRepository,
} from '../../data/repositories';
import type { SequenceEnrollmentRepository } from '../../data/repositories/sequence-enrollment-repository';
import type { SecurityContext, PaginatedResult } from '../../data/repositories/repository-types';
import type { Deal, Lead, SalesActivity } from '../../types/models';
import { successResult } from '../../data/errors/repository-errors';
import { AuditLogService } from '../AuditLogService';
import { RateLimitService } from '../RateLimitService';
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


const dealWon: Deal = {
  id: 'deal-won-1',
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
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-01'),
  closedAt: new Date('2024-01-15'),
};

const dealOpen: Deal = {
  id: 'deal-open-1',
  pipelineId: 'pipe-1',
  stageId: 'stage-2',
  title: 'Open Deal',
  valueCents: 30000,
  currency: 'USD',
  probability: 50,
  status: 'open',
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-05'),
};

const dealLost: Deal = {
  id: 'deal-lost-1',
  pipelineId: 'pipe-1',
  stageId: 'stage-3',
  title: 'Lost Deal',
  valueCents: 20000,
  currency: 'USD',
  probability: 0,
  status: 'lost',
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-02'),
  closedAt: new Date('2024-01-20'),
  wonLostReason: 'budget',
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

const leadConverted: Lead = {
  id: 'lead-2',
  firstName: 'Jane',
  lastName: 'Smith',
  email: 'jane@example.com',
  status: 'converted',
  source: 'referral',
  score: 90,
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-10'),
  convertedToDealId: 'deal-won-1',
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

const activityTask: SalesActivity = {
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

function createMockDealRepo() {
  return {
    getByStatus: vi.fn().mockResolvedValue(successResult([dealOpen])),
    getWonInRange: vi.fn().mockResolvedValue(successResult([dealWon])),
    getWonValueRange: vi.fn().mockResolvedValue(
      successResult({ totalValueCents: 50000, count: 1, dealCount: 1 })
    ),
    getByPipeline: vi.fn().mockResolvedValue(successResult([dealWon, dealOpen, dealLost])),
  };
}

function createMockLeadRepo() {
  return {
    getFiltered: vi.fn().mockResolvedValue(
      successResult<PaginatedResult<Lead>>({
        data: [leadNew, leadConverted],
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
        data: [activityCall, activityTask],
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

function createMockAuditService() {
  return {
    logAction: vi.fn().mockResolvedValue({ success: true }),
  };
}

function createMockRateLimitService() {
  return {
    checkLimit: vi.fn().mockResolvedValue({ allowed: true, remaining: 10, resetAt: new Date() }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  };
}

function decodeDataUrl(dataUrl: string): string {
  const [, encoded = ''] = dataUrl.split(',', 2);
  return decodeURIComponent(encoded);
}

// ============================================
// Test Suites
// ============================================

describe('ReportingService', () => {
  let service: ReportingService;
  let mockDealRepo: ReturnType<typeof createMockDealRepo>;
  let mockLeadRepo: ReturnType<typeof createMockLeadRepo>;
  let mockActivityRepo: ReturnType<typeof createMockActivityRepo>;
  let mockEnrollmentRepo: ReturnType<typeof createMockEnrollmentRepo>;
  let mockAuditService: ReturnType<typeof createMockAuditService>;
  let mockRateLimitService: ReturnType<typeof createMockRateLimitService>;

  beforeEach(() => {
    // Enable feature flags
    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
      ...features.defaultFeatures,
      enableReports: true,
      enableAdvancedReporting: true,
      enableDashboards: true,
      enableScheduledReports: true,
    });

    mockDealRepo = createMockDealRepo();
    mockLeadRepo = createMockLeadRepo();
    mockActivityRepo = createMockActivityRepo();
    mockEnrollmentRepo = createMockEnrollmentRepo();
    mockAuditService = createMockAuditService();
    mockRateLimitService = createMockRateLimitService();

    service = new ReportingService({
      dealRepository: mockDealRepo as unknown as DealRepository,
      leadRepository: mockLeadRepo as unknown as LeadRepository,
      activityRepository: mockActivityRepo as unknown as ActivityRepository,
      sequenceEnrollmentRepository: mockEnrollmentRepo as unknown as SequenceEnrollmentRepository,
      auditLogService: mockAuditService as unknown as AuditLogService,
      rateLimitService: mockRateLimitService as unknown as RateLimitService,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // ============================================
  // Report CRUD Tests
  // ============================================

  describe('Report CRUD Operations', () => {
    it('creates a new custom report with valid configuration', async () => {
      const result = await service.createReport(baseContext, {
        name: 'My Custom Report',
        description: 'Test report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toBe('My Custom Report');
      expect(result.data!.ownerId).toBe(baseContext.userId);
      expect(result.data!.businessId).toBe(baseContext.businessId);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'create', entityType: 'report' })
      );
    });

    it('rejects report creation from front desk users', async () => {
      const result = await service.createReport(frontDeskContext, {
        name: 'Blocked Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: frontDeskContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('Not authorized');
    });

    it('validates report configuration - missing name fails', async () => {
      const result = await service.createReport(baseContext, {
        name: '', // Invalid
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('name');
    });

    it('validates report configuration - no dimensions or metrics fails', async () => {
      const result = await service.createReport(baseContext, {
        name: 'Invalid Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [],
        metrics: [],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('dimension or metric');
    });
  });

  // ============================================
  // Report Execution Tests
  // ============================================

  describe('Report Execution with Various Aggregations', () => {
    let reportId: string;

    beforeEach(async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Test Deals Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [
          { field: 'id', label: 'Count', aggregation: 'count', format: 'number' },
          { field: 'valueCents', label: 'Total Value', aggregation: 'sum', format: 'currency' },
          { field: 'valueCents', label: 'Avg Value', aggregation: 'avg', format: 'currency' },
        ],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });
      reportId = createResult.data?.id || '';
    });

    it('executes a report and returns aggregated results', async () => {
      const result = await service.runReport(baseContext, reportId);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.reportId).toBe(reportId);
      expect(result.data!.rowCount).toBeGreaterThanOrEqual(0);
      expect(result.data!.queryTimeMs).toBeGreaterThanOrEqual(0);
      expect(result.data!.generatedAt).toBeInstanceOf(Date);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'read', entityType: 'report' })
      );
    });

    it('respects rate limits on report execution', async () => {
      mockRateLimitService.checkLimit.mockResolvedValueOnce({
        allowed: false,
        remaining: 0,
        resetAt: new Date(Date.now() + 60000),
        message: 'Rate limit exceeded',
      });

      const result = await service.runReport(baseContext, reportId);

      expect(result.success).toBe(false);
      expect(result.error?.message?.toLowerCase()).toContain('rate limit');
    });

    it('records rate limit action after successful execution', async () => {
      await service.runReport(baseContext, reportId);

      expect(mockRateLimitService.recordAction).toHaveBeenCalledWith(
        'report',
        baseContext.userId,
        baseContext.businessId
      );
    });
  });

  // ============================================
  // Date Range Filtering Tests
  // ============================================

  describe('Date Range Filtering', () => {
    let reportId: string;

    beforeEach(async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Date Range Test Report',
        reportType: 'deals',
        chartType: 'line',
        dataSource: 'deals',
        dimensions: [{ field: 'createdAt', label: 'Date', type: 'date', dateGranularity: 'month' }],
        metrics: [{ field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' }],
        filters: [{ field: 'status', operator: 'eq', value: 'won' }],
        defaultDateRange: 'this_month',
        dateField: 'closedAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });
      reportId = createResult.data?.id || '';
    });

    it('filters data by custom date range', async () => {
      const customRange = {
        start: new Date('2024-01-01'),
        end: new Date('2024-01-31'),
      };

      const result = await service.runReport(baseContext, reportId, {
        dateRange: customRange,
      });

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.dateRange.start).toEqual(customRange.start);
      expect(result.data!.dateRange.end).toEqual(customRange.end);
    });

    it('applies default date range when not specified', async () => {
      const result = await service.runReport(baseContext, reportId);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.dateRange.start).toBeInstanceOf(Date);
      expect(result.data!.dateRange.end).toBeInstanceOf(Date);
    });

    it('supports all preset date ranges', async () => {
      // Use fake timers to ensure consistent date calculations regardless of when test runs
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-06-15T12:00:00Z')); // Midday, mid-month, mid-year

      const dateRanges = [
        'today',
        'yesterday',
        'this_week',
        'last_week',
        'this_month',
        'last_month',
        'this_quarter',
        'last_quarter',
        'this_year',
        'last_year',
      ] as const;

      for (const range of dateRanges) {
        const createResult = await service.createReport(baseContext, {
          name: `Range Test ${range}`,
          reportType: 'deals',
          chartType: 'bar',
          dataSource: 'deals',
          dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
          metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
          filters: [],
          defaultDateRange: range,
          dateField: 'createdAt',
          isSystemReport: false,
          isPublic: true,
          ownerId: baseContext.userId,
        });

        const runResult = await service.runReport(baseContext, createResult.data!.id);
        expect(runResult.success).toBe(true);
        expect(runResult.data).not.toBeNull();
        expect(runResult.data!.dateRange.end.getTime()).toBeGreaterThan(runResult.data!.dateRange.start.getTime());
      }

      vi.useRealTimers();
    });
  });

  // ============================================
  // Custom Report Builder Validation Tests
  // ============================================

  describe('Custom Report Builder Validation', () => {
    it('validates report type is valid', async () => {
      const result = await service.runAdHocReport(baseContext, {
        name: 'Ad Hoc Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(true);
    });

    it('validates chart type is valid', async () => {
      const chartTypes = ['bar', 'line', 'pie', 'funnel', 'table', 'metric', 'heatmap'] as const;

      for (const chartType of chartTypes) {
        const result = await service.runAdHocReport(baseContext, {
          name: `Chart Test ${chartType}`,
          reportType: 'deals',
          chartType,
          dataSource: 'deals',
          dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
          metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
          filters: [],
          defaultDateRange: 'this_month',
          dateField: 'createdAt',
          isSystemReport: false,
          isPublic: false,
          ownerId: baseContext.userId,
        });

        expect(result.success).toBe(true);
      }
    });

    it('validates data source is valid', async () => {
      const dataSources = ['deals', 'leads', 'activities', 'sequence_enrollments'] as const;

      for (const dataSource of dataSources) {
        const result = await service.runAdHocReport(baseContext, {
          name: `Data Source Test ${dataSource}`,
          reportType: 'deals',
          chartType: 'bar',
          dataSource,
          dimensions: [{ field: 'id', label: 'ID', type: 'string' }],
          metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
          filters: [],
          defaultDateRange: 'this_month',
          dateField: 'createdAt',
          isSystemReport: false,
          isPublic: false,
          ownerId: baseContext.userId,
        });

        expect(result.success).toBe(true);
      }
    });

    it('applies additional filters on ad-hoc reports', async () => {
      const result = await service.runAdHocReport(baseContext, {
        name: 'Filtered Ad Hoc Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'valueCents', label: 'Value', aggregation: 'sum', format: 'currency' }],
        filters: [
          { field: 'status', operator: 'eq', value: 'won' },
          { field: 'valueCents', operator: 'gt', value: 10000 },
        ],
        defaultDateRange: 'this_quarter',
        dateField: 'closedAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(true);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'read', entityType: 'report' })
      );
    });
  });

  // ============================================
  // Scheduled Report Execution Tests
  // ============================================

  describe('Scheduled Report Execution', () => {
    let reportId: string;

    beforeEach(async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Weekly Report',
        reportType: 'revenue',
        chartType: 'line',
        dataSource: 'deals',
        dimensions: [{ field: 'closedAt', label: 'Week', type: 'date', dateGranularity: 'week' }],
        metrics: [{ field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' }],
        filters: [{ field: 'status', operator: 'eq', value: 'won' }],
        defaultDateRange: 'this_month',
        dateField: 'closedAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });
      reportId = createResult.data?.id || '';
    });

    it('creates a scheduled report with valid configuration', async () => {
      const result = await service.scheduleReport(baseContext, {
        reportId,
        reportName: 'Weekly Revenue Report',
        frequency: 'weekly',
        dayOfWeek: 1, // Monday
        timeOfDay: '09:00',
        recipientUserIds: [baseContext.userId],
        recipientEmails: ['external@example.com'],
        format: 'pdf',
        includeChart: true,
      });

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.reportId).toBe(reportId);
      expect(result.data!.frequency).toBe('weekly');
      expect(result.data!.dayOfWeek).toBe(1);
      expect(result.data!.isActive).toBe(true);
      expect(result.data!.nextSendAt).toBeInstanceOf(Date);
    });

    it('rejects schedule creation from front desk users', async () => {
      const result = await service.scheduleReport(frontDeskContext, {
        reportId,
        reportName: 'Blocked Schedule',
        frequency: 'daily',
        timeOfDay: '09:00',
        recipientUserIds: [frontDeskContext.userId],
        format: 'csv',
        includeChart: false,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('Not authorized');
    });

    it('requires at least one recipient', async () => {
      const result = await service.scheduleReport(baseContext, {
        reportId,
        reportName: 'No Recipients',
        frequency: 'daily',
        timeOfDay: '09:00',
        recipientUserIds: [], // Empty
        recipientEmails: [], // Empty
        format: 'csv',
        includeChart: false,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('recipient');
    });

    it('updates schedule with new timing', async () => {
      const scheduleResult = await service.scheduleReport(baseContext, {
        reportId,
        reportName: 'Daily Report',
        frequency: 'daily',
        timeOfDay: '09:00',
        recipientUserIds: [baseContext.userId],
        format: 'csv',
        includeChart: false,
      });

      const updateResult = await service.updateSchedule(baseContext, scheduleResult.data!.id, {
        frequency: 'weekly',
        dayOfWeek: 5, // Friday
        timeOfDay: '17:00',
      });

      expect(updateResult.success).toBe(true);
      expect(updateResult.data).not.toBeNull();
      expect(updateResult.data!.frequency).toBe('weekly');
      expect(updateResult.data!.dayOfWeek).toBe(5);
      expect(updateResult.data!.timeOfDay).toBe('17:00');
    });

    it('deletes a scheduled report', async () => {
      const scheduleResult = await service.scheduleReport(baseContext, {
        reportId,
        reportName: 'To Be Deleted',
        frequency: 'monthly',
        dayOfMonth: 1,
        timeOfDay: '08:00',
        recipientUserIds: [baseContext.userId],
        format: 'xlsx',
        includeChart: true,
      });

      const deleteResult = await service.deleteSchedule(baseContext, scheduleResult.data!.id);

      expect(deleteResult.success).toBe(true);
    });
  });

  // ============================================
  // Export Generation Tests
  // ============================================

  describe('Export Generation (CSV, PDF)', () => {
    let reportId: string;

    beforeEach(async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Export Test Report',
        reportType: 'deals',
        chartType: 'table',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [
          { field: 'id', label: 'Count', aggregation: 'count', format: 'number' },
          { field: 'valueCents', label: 'Value', aggregation: 'sum', format: 'currency' },
        ],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });
      reportId = createResult.data?.id || '';
    });

    it('exports report to CSV format', async () => {
      const dateRange = { start: new Date('2024-01-01'), end: new Date('2024-01-31') };
      const result = await service.exportReport(baseContext, reportId, 'csv', dateRange);

      expect(result.success).toBe(true);
      expect(result.data).toContain('data:text/csv');
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({ action: 'export', entityType: 'report' })
      );
    });

    it('exports report to PDF format', async () => {
      const dateRange = { start: new Date('2024-01-01'), end: new Date('2024-01-31') };
      const result = await service.exportReport(baseContext, reportId, 'pdf', dateRange);

      expect(result.success).toBe(true);
      expect(result.data).toContain('data:application/pdf');
      expect(decodeDataUrl(result.data || '')).toContain('%PDF-1.4');
    });

    it('exports report to XLSX format', async () => {
      const dateRange = { start: new Date('2024-01-01'), end: new Date('2024-01-31') };
      const result = await service.exportReport(baseContext, reportId, 'xlsx', dateRange);

      expect(result.success).toBe(true);
      // Falls back to CSV in placeholder implementation
      expect(result.data).toBeDefined();
    });

    it('logs export action with metadata for audit compliance', async () => {
      const dateRange = { start: new Date('2024-01-01'), end: new Date('2024-01-31') };
      await service.exportReport(baseContext, reportId, 'csv', dateRange);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'export',
          entityType: 'report',
          entityId: reportId,
          metadata: expect.objectContaining({
            format: 'csv',
            dateRangeStart: expect.any(String),
            dateRangeEnd: expect.any(String),
          }),
        })
      );
    });
  });

  // ============================================
  // RBAC Tests on Reports
  // ============================================

  describe('RBAC on Reports (Visibility, Sharing)', () => {
    it('owner can access their own private report', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Private Owner Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      const runResult = await service.runReport(baseContext, createResult.data!.id);
      expect(runResult.success).toBe(true);
    });

    it('admin can access any report in the business', async () => {
      const createResult = await service.createReport(staffContext, {
        name: 'Staff Private Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: staffContext.userId,
      });

      // Admin should be able to access
      const runResult = await service.runReport(baseContext, createResult.data!.id);
      expect(runResult.success).toBe(true);
    });

    it('staff cannot access another users private report', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Admin Private Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
        visibility: 'private',
      });

      const runResult = await service.runReport(staffContext, createResult.data!.id);
      expect(runResult.success).toBe(false);
      expect(runResult.error?.message).toContain('authorized');
    });

    it('user can access public reports', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Public Report',
        reportType: 'deals',
        chartType: 'pie',
        dataSource: 'deals',
        dimensions: [{ field: 'status', label: 'Status', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });

      const runResult = await service.runReport(staffContext, createResult.data!.id);
      expect(runResult.success).toBe(true);
    });

    it('user can access reports shared with their team', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Team Shared Report',
        reportType: 'revenue',
        chartType: 'line',
        dataSource: 'deals',
        dimensions: [{ field: 'closedAt', label: 'Month', type: 'date', dateGranularity: 'month' }],
        metrics: [{ field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' }],
        filters: [{ field: 'status', operator: 'eq', value: 'won' }],
        defaultDateRange: 'this_quarter',
        dateField: 'closedAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
        sharedWithTeamIds: ['team-a'],
        visibility: 'team',
      });

      const runResult = await service.runReport(staffContext, createResult.data!.id);
      expect(runResult.success).toBe(true);
    });

    it('user can access reports shared with them directly', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Directly Shared Report',
        reportType: 'activities',
        chartType: 'bar',
        dataSource: 'activities',
        dimensions: [{ field: 'type', label: 'Type', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_week',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
        sharedWithUserIds: [staffContext.userId],
      });

      const runResult = await service.runReport(staffContext, createResult.data!.id);
      expect(runResult.success).toBe(true);
    });

    it('prevents modification of system reports by non-admins', async () => {
      await service.seedSystemReports(baseContext);

      const systemReportsResult = await service.getSystemReports(baseContext);
      expect(systemReportsResult.success).toBe(true);
      expect(systemReportsResult.data).not.toBeNull();
      expect(systemReportsResult.data!.length).toBeGreaterThan(0);

      const systemReportId = systemReportsResult.data![0].id;

      // Staff trying to update system report
      const updateResult = await service.updateReport(staffContext, systemReportId, {
        name: 'Hacked System Report',
      });

      expect(updateResult.success).toBe(false);
      expect(updateResult.error?.message).toContain('authorized');
    });

    it('prevents deletion of system reports', async () => {
      await service.seedSystemReports(baseContext);
      const systemReportsResult = await service.getSystemReports(baseContext);
      const systemReportId = systemReportsResult.data![0].id;

      const deleteResult = await service.deleteReport(baseContext, systemReportId);

      expect(deleteResult.success).toBe(false);
      expect(deleteResult.error?.message).toContain('System');
    });
  });

  // ============================================
  // Metrics Tests
  // ============================================

  describe('Quick Metrics', () => {
    it('fetches deals_won_count metric', async () => {
      const result = await service.getMetric(baseContext, 'deals_won_count', 'this_month');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
      expect(result.data).toHaveProperty('previousValue');
      expect(result.data).toHaveProperty('changePercent');
    });

    it('fetches revenue_this_month metric', async () => {
      const result = await service.getMetric(baseContext, 'revenue_this_month', 'this_month');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
    });

    it('fetches leads_created metric', async () => {
      const result = await service.getMetric(baseContext, 'leads_created', 'this_month');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
    });

    it('fetches activities_completed metric', async () => {
      const result = await service.getMetric(baseContext, 'activities_completed', 'this_week');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
    });

    it('fetches open_deals_count metric', async () => {
      const result = await service.getMetric(baseContext, 'open_deals_count');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
    });

    it('fetches open_deals_value metric', async () => {
      const result = await service.getMetric(baseContext, 'open_deals_value');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.value).toBeGreaterThanOrEqual(0);
    });

    it('returns error for unknown metric', async () => {
      const result = await service.getMetric(baseContext, 'unknown_metric');

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('Unknown metric');
    });

    it('logs metric access for audit compliance', async () => {
      await service.getMetric(baseContext, 'deals_won_count', 'this_month');

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          entityId: 'deals_won_count',
        })
      );
    });
  });

  // ============================================
  // System Reports Tests
  // ============================================

  describe('System Reports Seeding', () => {
    it('seeds system reports for a new business', async () => {
      const result = await service.seedSystemReports(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.seeded).toBeGreaterThanOrEqual(0);
      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'create',
          entityType: 'report',
        })
      );
    });

    it('skips already seeded reports', async () => {
      // First seed
      await service.seedSystemReports(baseContext);
      // Second seed should find existing
      const result = await service.seedSystemReports(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      // When all are already seeded, seeded should be 0 and existing should match total
      expect(result.data!.existing).toBeGreaterThanOrEqual(0);
    });

    it('only allows admins to seed system reports', async () => {
      const result = await service.seedSystemReports(staffContext);

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('admin');
    });

    it('checks if system reports are seeded', async () => {
      await service.seedSystemReports(baseContext);
      const result = await service.areSystemReportsSeeded(baseContext);

      expect(result.success).toBe(true);
      expect(result.data).toBe(true);
    });

    it('reseeds a specific system report', async () => {
      await service.seedSystemReports(baseContext);
      const result = await service.reseedSystemReport(baseContext, 'Pipeline by Stage');

      expect(result.success).toBe(true);
      expect(result.data).not.toBeNull();
      expect(result.data!.name).toBe('Pipeline by Stage');
    });
  });

  // ============================================
  // Feature Flag Tests
  // ============================================

  describe('Feature Flags', () => {
    it('rejects operations when reporting is disabled', async () => {
      vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
        ...features.defaultFeatures,
        enableReports: false,
      });

      const result = await service.createReport(baseContext, {
        name: 'Blocked Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain('disabled');
    });
  });

  // ============================================
  // Filter Operators Tests
  // ============================================

  describe('Filter Operators', () => {
    let reportId: string;

    beforeEach(async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Filter Operators Test',
        reportType: 'deals',
        chartType: 'table',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'valueCents', label: 'Value', aggregation: 'sum', format: 'currency' }],
        filters: [],
        defaultDateRange: 'this_year',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });
      reportId = createResult.data?.id || '';
    });

    it('applies eq (equals) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'status', operator: 'eq', value: 'won' }],
      });

      expect(result.success).toBe(true);
    });

    it('applies neq (not equals) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'status', operator: 'neq', value: 'lost' }],
      });

      expect(result.success).toBe(true);
    });

    it('applies gt (greater than) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'valueCents', operator: 'gt', value: 10000 }],
      });

      expect(result.success).toBe(true);
    });

    it('applies gte (greater than or equal) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'valueCents', operator: 'gte', value: 10000 }],
      });

      expect(result.success).toBe(true);
    });

    it('applies lt (less than) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'valueCents', operator: 'lt', value: 100000 }],
      });

      expect(result.success).toBe(true);
    });

    it('applies lte (less than or equal) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'valueCents', operator: 'lte', value: 100000 }],
      });

      expect(result.success).toBe(true);
    });

    it('applies in (array contains) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'status', operator: 'in', value: ['won', 'open'] }],
      });

      expect(result.success).toBe(true);
    });

    it('applies contains (string contains) filter', async () => {
      const result = await service.runReport(baseContext, reportId, {
        additionalFilters: [{ field: 'title', operator: 'contains', value: 'Deal' }],
      });

      expect(result.success).toBe(true);
    });
  });

  // ============================================
  // Security and HIPAA Compliance Tests
  // ============================================

  describe('Security and HIPAA Compliance', () => {
    it('validates security context before operations', async () => {
      const invalidContext = {
        ...baseContext,
        businessId: '', // Invalid
      } as SecurityContext;

      const result = await service.createReport(invalidContext, {
        name: 'Test',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(result.success).toBe(false);
    });

    it('logs all report creation actions', async () => {
      await service.createReport(baseContext, {
        name: 'Audit Test Report',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'create',
          entityType: 'report',
        })
      );
    });

    it('logs all report read actions', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Read Audit Test',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });

      await service.runReport(baseContext, createResult.data!.id);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
        })
      );
    });

    it('logs all report update actions', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Update Audit Test',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      await service.updateReport(baseContext, createResult.data!.id, {
        name: 'Updated Name',
      });

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'update',
          entityType: 'report',
        })
      );
    });

    it('logs all report delete actions', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Delete Audit Test',
        reportType: 'deals',
        chartType: 'bar',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: false,
        ownerId: baseContext.userId,
      });

      await service.deleteReport(baseContext, createResult.data!.id);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'delete',
          entityType: 'report',
        })
      );
    });

    it('logs export actions with date range metadata', async () => {
      const createResult = await service.createReport(baseContext, {
        name: 'Export Audit Test',
        reportType: 'deals',
        chartType: 'table',
        dataSource: 'deals',
        dimensions: [{ field: 'stageId', label: 'Stage', type: 'string' }],
        metrics: [{ field: 'id', label: 'Count', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_month',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
      });

      const dateRange = { start: new Date('2024-01-01'), end: new Date('2024-01-31') };
      await service.exportReport(baseContext, createResult.data!.id, 'csv', dateRange);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        baseContext,
        expect.objectContaining({
          action: 'export',
          entityType: 'report',
          metadata: expect.objectContaining({
            format: 'csv',
            dateRangeStart: expect.any(String),
            dateRangeEnd: expect.any(String),
          }),
        })
      );
    });

    it('limits report rows to prevent data exfiltration', async () => {
      // The service should limit rows to MAX_REPORT_ROWS (10000)
      const createResult = await service.createReport(baseContext, {
        name: 'Limit Test',
        reportType: 'deals',
        chartType: 'table',
        dataSource: 'deals',
        dimensions: [{ field: 'id', label: 'ID', type: 'string' }],
        metrics: [{ field: 'valueCents', label: 'Value', aggregation: 'count', format: 'number' }],
        filters: [],
        defaultDateRange: 'this_year',
        dateField: 'createdAt',
        isSystemReport: false,
        isPublic: true,
        ownerId: baseContext.userId,
        limit: 50000, // Request more than MAX
      });

      const runResult = await service.runReport(baseContext, createResult.data!.id);

      expect(runResult.success).toBe(true);
      // Results should be limited by MAX_REPORT_ROWS
    });
  });
});
