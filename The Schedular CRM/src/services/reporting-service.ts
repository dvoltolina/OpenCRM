/**
 * Reporting Service
 * Comprehensive reporting service for running, managing, and scheduling reports.
 *
 * HIPAA Compliance Notes:
 * - Reports aggregate data, not expose individual PHI
 * - All report access is logged via audit service
 * - Export controls track downloads
 * - Reports respect RBAC - users only see data they have access to
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
import type {
  ReportDefinition,
  ReportResult,
  ReportFilter,
  ReportType,
  DateRange,
  ReportDataSource,
  ScheduledReport,
  ScheduledReportFrequency,
  ScheduledReportFormat,
  MetricValue,
} from '../types/reporting';
import {
  SYSTEM_REPORTS,
  createReportDefinitionFromSystem,
  getSystemReportByName,
  getSystemReportsByType,
  type SystemReportDefinition,
} from '../data/system-reports';
import { AuditLogService } from './AuditLogService';
import { AuthorizationError, InvalidArgumentError, failedResult, successResult } from '../data/errors/repository-errors';
import { getFeatureFlags } from '../config/features';
import { validateSecurityContext } from '../lib/security-context';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { buildCsvDocument, buildInlineDataUrl, buildSimplePdfDocument } from './export-document';

// ============================================
// Constants
// ============================================

/** Default cache TTL for report results (15 minutes) */
// const REPORT_CACHE_TTL_MS = 15 * 60 * 1000;

/** Maximum rows returned from a single report execution */
const MAX_REPORT_ROWS = 10000;

/** Maximum date range in days to prevent DoS (366 to account for leap years) */
const MAX_DATE_RANGE_DAYS = 366;

/** Maximum years back for date range queries */
const MAX_YEARS_BACK = 2;

/** Maximum number of dimensions and metrics per report */
// const MAX_REPORT_FIELDS = 50;

const REPORTING_VISIBLE_ROLES = ['sales', 'staff', 'provider', 'manager', 'admin', 'owner'] as const;

/**
 * Allowed filter fields by data source to prevent injection attacks
 * Only these fields can be used in filters
 */
const ALLOWED_FILTER_FIELDS: Record<string, string[]> = {
  deals: [
    'id', 'title', 'status', 'stageId', 'pipelineId', 'valueCents', 'currency',
    'probability', 'tags', 'ownerId', 'ownerName', 'assigneeId', 'assigneeName',
    'teamIds', 'source', 'wonLostReason', 'createdAt', 'updatedAt', 'closedAt',
  ],
  leads: [
    'id', 'status', 'source', 'score', 'tags', 'ownerId', 'ownerName',
    'teamIds', 'createdAt', 'updatedAt', 'convertedToDealId',
  ],
  activities: [
    'id', 'type', 'title', 'isCompleted', 'ownerId', 'ownerName',
    'assigneeId', 'assigneeName', 'teamIds', 'createdAt', 'completedAt', 'dueDate',
  ],
  sequence_enrollments: [
    'id', 'sequenceId', 'status', 'ownerId', 'ownerName', 'teamIds',
    'createdAt', 'completedAt', 'pausedAt',
  ],
  email_messages: [
    'id', 'status', 'direction', 'ownerId', 'ownerName', 'teamIds',
    'createdAt', 'sentAt', 'openedAt',
  ],
};

/**
 * PHI fields that must NEVER be included in report exports
 * These are fields that contain personally identifiable information
 */
const PHI_BLOCKED_FIELDS: string[] = [
  'email', 'phone', 'phoneNumber', 'mobilePhone', 'workPhone',
  'ssn', 'socialSecurityNumber', 'dob', 'dateOfBirth', 'birthDate',
  'firstName', 'lastName', 'fullName', 'name', 'contactName',
  'address', 'streetAddress', 'city', 'state', 'zipCode', 'postalCode',
  'medicalRecordNumber', 'healthInsuranceId', 'patientId',
  'diagnosis', 'treatment', 'prescription', 'healthCondition',
  'emergencyContact', 'emergencyPhone',
];

// ============================================
// Types
// ============================================

export interface ReportingServiceDependencies {
  dealRepository?: DealRepository;
  leadRepository?: LeadRepository;
  activityRepository?: ActivityRepository;
  sequenceEnrollmentRepository?: SequenceEnrollmentRepository;
  auditLogService?: AuditLogService;
  rateLimitService?: RateLimitService;
}

export interface RunReportOptions {
  dateRange?: { start: Date; end: Date };
  additionalFilters?: ReportFilter[];
  forceRefresh?: boolean;
}

export type CreateReportInput = Omit<ReportDefinition, 'id' | 'businessId' | 'createdAt' | 'updatedAt'>;

export interface ScheduleReportInput {
  reportId: string;
  reportName: string;
  frequency: ScheduledReportFrequency;
  dayOfWeek?: number;
  dayOfMonth?: number;
  timeOfDay: string;
  recipientUserIds: string[];
  recipientEmails?: string[];
  format: ScheduledReportFormat;
  includeChart: boolean;
}

// In-memory report definition store (would be replaced with repository in production)
const reportDefinitions: Map<string, ReportDefinition> = new Map();
const scheduledReports: Map<string, ScheduledReport> = new Map();

// ============================================
// Reporting Service
// ============================================

export class ReportingService {
  private readonly dealRepo: DealRepository;
  private readonly leadRepo: LeadRepository;
  private readonly activityRepo: ActivityRepository;
  private readonly enrollmentRepo: SequenceEnrollmentRepository;
  private readonly auditService: AuditLogService;
  private readonly rateLimitService: RateLimitService;

  constructor(dependencies: ReportingServiceDependencies = {}) {
    this.dealRepo = dependencies.dealRepository ?? getDealRepository();
    this.leadRepo = dependencies.leadRepository ?? getLeadRepository();
    this.activityRepo = dependencies.activityRepository ?? getActivityRepository();
    this.enrollmentRepo = dependencies.sequenceEnrollmentRepository ?? getSequenceEnrollmentRepository();
    this.auditService = dependencies.auditLogService ?? new AuditLogService();
    this.rateLimitService = dependencies.rateLimitService ?? getRateLimitService();
  }

  // ============================================
  // Report Execution
  // ============================================

  /**
   * Execute a saved report by ID
   */
  async runReport(
    context: SecurityContext,
    reportId: string,
    options?: RunReportOptions
  ): Promise<RepositoryResult<ReportResult>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      // Check rate limit
      const rateLimit = await this.rateLimitService.checkLimit('report', context.userId, context.businessId);
      if (!rateLimit.allowed) {
        return failedResult(new AuthorizationError(rateLimit.message || 'Report rate limit exceeded'));
      }

      // Get report definition
      const report = reportDefinitions.get(reportId);
      if (!report) {
        return failedResult(new InvalidArgumentError(`Report not found: ${reportId}`, 'reportId'));
      }

      // Check access
      if (!this.canAccessReport(context, report)) {
        return failedResult(new AuthorizationError('Not authorized to run this report'));
      }

      // Resolve date range
      const dateRange = options?.dateRange ?? this.resolveDateRange(report.defaultDateRange);

      // SECURITY: Validate date range bounds
      this.validateDateRange(dateRange);

      // Build combined filters
      const filters = [
        ...report.filters,
        ...(options?.additionalFilters || []),
      ];

      // SECURITY: Validate filter fields against whitelist
      this.validateFilters(filters, report.dataSource);

      // Execute report
      const result = await this.executeReport(context, report, dateRange, filters);

      // Record rate limit action
      await this.rateLimitService.recordAction('report', context.userId, context.businessId);

      // Audit log
      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: reportId,
        metadata: {
          reportName: report.name,
          reportType: report.reportType,
          dateRangeStart: dateRange.start.toISOString(),
          dateRangeEnd: dateRange.end.toISOString(),
          rowCount: result.rowCount,
          queryTimeMs: result.queryTimeMs,
        },
      });

      return successResult(result);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Execute an ad-hoc report without saving
   */
  async runAdHocReport(
    context: SecurityContext,
    config: CreateReportInput
  ): Promise<RepositoryResult<ReportResult>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      // Check rate limit
      const rateLimit = await this.rateLimitService.checkLimit('report', context.userId, context.businessId);
      if (!rateLimit.allowed) {
        return failedResult(new AuthorizationError(rateLimit.message || 'Report rate limit exceeded'));
      }

      // Validate config
      const validationError = this.validateReportConfig(config);
      if (validationError) {
        return failedResult(new InvalidArgumentError(validationError, 'config'));
      }

      // Build temporary report definition
      const tempReport: ReportDefinition = {
        id: `adhoc-${Date.now()}`,
        businessId: context.businessId,
        createdAt: new Date(),
        name: config.name as string,
        description: config.description as string | undefined,
        reportType: config.reportType as ReportDefinition['reportType'],
        chartType: config.chartType as ReportDefinition['chartType'],
        dataSource: config.dataSource as ReportDefinition['dataSource'],
        dimensions: config.dimensions as ReportDefinition['dimensions'],
        metrics: config.metrics as ReportDefinition['metrics'],
        filters: config.filters as ReportDefinition['filters'],
        defaultDateRange: config.defaultDateRange as ReportDefinition['defaultDateRange'],
        dateField: config.dateField as string,
        sortBy: config.sortBy as string | undefined,
        sortOrder: config.sortOrder as ReportDefinition['sortOrder'],
        limit: config.limit as number | undefined,
        isSystemReport: (config.isSystemReport as boolean) ?? false,
        isPublic: (config.isPublic as boolean) ?? false,
        ownerId: (config.ownerId as string) ?? context.userId,
        ownerName: config.ownerName as string | undefined,
        sharedWithUserIds: config.sharedWithUserIds as string[] | undefined,
        sharedWithTeamIds: config.sharedWithTeamIds as string[] | undefined,
        teamIds: config.teamIds as string[] | undefined,
        visibility: config.visibility as ReportDefinition['visibility'],
      };

      // Resolve date range
      const dateRange = this.resolveDateRange(config.defaultDateRange as DateRange);

      // SECURITY: Validate date range bounds
      this.validateDateRange(dateRange);

      // SECURITY: Validate filter fields against whitelist
      this.validateFilters(config.filters as ReportFilter[], config.dataSource as ReportDataSource);

      // Execute report
      const result = await this.executeReport(context, tempReport, dateRange, config.filters as ReportFilter[]);

      // Record rate limit action
      await this.rateLimitService.recordAction('report', context.userId, context.businessId);

      // Audit log
      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: tempReport.id,
        metadata: {
          reportType: config.reportType,
          dataSource: config.dataSource,
          rowCount: result.rowCount,
          queryTimeMs: result.queryTimeMs,
        },
      });

      return successResult(result);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Report CRUD
  // ============================================

  /**
   * Create a new report definition
   */
  async createReport(
    context: SecurityContext,
    report: CreateReportInput
  ): Promise<RepositoryResult<ReportDefinition>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      if (context.userRole === 'frontDesk' || context.userRole === 'client') {
        return failedResult(new AuthorizationError('Not authorized to create reports'));
      }

      // Validate config
      const validationError = this.validateReportConfig(report);
      if (validationError) {
        return failedResult(new InvalidArgumentError(validationError, 'report'));
      }

      const id = `report-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date();

      const newReport: ReportDefinition = {
        id,
        businessId: context.businessId,
        createdAt: now,
        name: report.name as string,
        description: report.description as string | undefined,
        reportType: report.reportType as ReportDefinition['reportType'],
        chartType: report.chartType as ReportDefinition['chartType'],
        dataSource: report.dataSource as ReportDefinition['dataSource'],
        dimensions: report.dimensions as ReportDefinition['dimensions'],
        metrics: report.metrics as ReportDefinition['metrics'],
        filters: report.filters as ReportDefinition['filters'],
        defaultDateRange: report.defaultDateRange as ReportDefinition['defaultDateRange'],
        dateField: report.dateField as string,
        sortBy: report.sortBy as string | undefined,
        sortOrder: report.sortOrder as ReportDefinition['sortOrder'],
        limit: report.limit as number | undefined,
        isSystemReport: (report.isSystemReport as boolean) ?? false,
        isPublic: (report.isPublic as boolean) ?? false,
        ownerId: (report.ownerId as string) || context.userId,
        ownerName: (report.ownerName as string) || context.userName,
        sharedWithUserIds: report.sharedWithUserIds as string[] | undefined,
        sharedWithTeamIds: report.sharedWithTeamIds as string[] | undefined,
        teamIds: (report.teamIds as string[]) || context.teamIds || [],
        visibility: report.visibility as ReportDefinition['visibility'],
      };

      reportDefinitions.set(id, newReport);

      await this.auditService.logAction(context, {
        action: 'create',
        entityType: 'report',
        entityId: id,
        metadata: {
          name: report.name,
          reportType: report.reportType,
          isSystemReport: report.isSystemReport,
        },
      });

      return successResult(newReport);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Update an existing report definition
   */
  async updateReport(
    context: SecurityContext,
    reportId: string,
    updates: Partial<ReportDefinition>
  ): Promise<RepositoryResult<ReportDefinition>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const existing = reportDefinitions.get(reportId);
      if (!existing) {
        return failedResult(new InvalidArgumentError(`Report not found: ${reportId}`, 'reportId'));
      }

      // Check modify permission
      if (!this.canModifyReport(context, existing)) {
        return failedResult(new AuthorizationError('Not authorized to update this report'));
      }

      // System reports cannot be modified by non-admins
      if (existing.isSystemReport && !this.isAdminOrOwner(context)) {
        return failedResult(new AuthorizationError('System reports can only be modified by admins'));
      }

      const updatedReport: ReportDefinition = {
        ...existing,
        ...updates,
        id: existing.id,
        businessId: existing.businessId,
        createdAt: existing.createdAt,
        updatedAt: new Date(),
      };

      reportDefinitions.set(reportId, updatedReport);

      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'report',
        entityId: reportId,
        metadata: {
          updatedFields: Object.keys(updates),
        },
      });

      return successResult(updatedReport);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Delete a report definition
   */
  async deleteReport(
    context: SecurityContext,
    reportId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const existing = reportDefinitions.get(reportId);
      if (!existing) {
        return failedResult(new InvalidArgumentError(`Report not found: ${reportId}`, 'reportId'));
      }

      // Check modify permission
      if (!this.canModifyReport(context, existing)) {
        return failedResult(new AuthorizationError('Not authorized to delete this report'));
      }

      // System reports cannot be deleted
      if (existing.isSystemReport) {
        return failedResult(new AuthorizationError('System reports cannot be deleted'));
      }

      reportDefinitions.delete(reportId);

      // Also delete any scheduled reports for this report
      for (const [scheduleId, schedule] of scheduledReports) {
        if (schedule.reportId === reportId) {
          scheduledReports.delete(scheduleId);
        }
      }

      await this.auditService.logAction(context, {
        action: 'delete',
        entityType: 'report',
        entityId: reportId,
        metadata: {
          name: existing.name,
        },
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get all accessible reports
   */
  async getReports(
    context: SecurityContext,
    options?: { type?: ReportType; includeSystem?: boolean }
  ): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      let reports = Array.from(reportDefinitions.values())
        .filter((report) => report.businessId === context.businessId)
        .filter((report) => this.canAccessReport(context, report));

      // Filter by type if specified
      if (options?.type) {
        reports = reports.filter((report) => report.reportType === options.type);
      }

      // Filter system reports if not requested
      if (options?.includeSystem === false) {
        reports = reports.filter((report) => !report.isSystemReport);
      }

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: 'list',
        metadata: {
          count: reports.length,
          includeSystem: options?.includeSystem,
          typeFilter: options?.type,
        },
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Report Scheduling
  // ============================================

  /**
   * Schedule a report for recurring delivery
   */
  async scheduleReport(
    context: SecurityContext,
    schedule: ScheduleReportInput
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      this.ensureScheduledReportsEnabled();
      validateSecurityContext(context);

      if (context.userRole === 'frontDesk' || context.userRole === 'client') {
        return failedResult(new AuthorizationError('Not authorized to schedule reports'));
      }

      // Validate report exists
      const report = reportDefinitions.get(schedule.reportId);
      if (!report) {
        return failedResult(new InvalidArgumentError(`Report not found: ${schedule.reportId}`, 'reportId'));
      }

      // Check access to report
      if (!this.canAccessReport(context, report)) {
        return failedResult(new AuthorizationError('Not authorized to schedule this report'));
      }

      // SECURITY: Validate recipients (email formats and access)
      await this.validateRecipients(context, schedule.recipientUserIds, schedule.recipientEmails);

      const id = `schedule-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date();
      const nextSendAt = this.calculateNextSendAt(schedule.frequency, schedule.timeOfDay, schedule.dayOfWeek, schedule.dayOfMonth);

      const newSchedule: ScheduledReport = {
        id,
        businessId: context.businessId,
        reportId: schedule.reportId,
        reportName: schedule.reportName,
        frequency: schedule.frequency,
        dayOfWeek: schedule.dayOfWeek,
        dayOfMonth: schedule.dayOfMonth,
        timeOfDay: schedule.timeOfDay,
        recipientUserIds: schedule.recipientUserIds,
        recipientEmails: schedule.recipientEmails,
        format: schedule.format,
        includeChart: schedule.includeChart,
        isActive: true,
        nextSendAt,
        createdById: context.userId,
        createdByName: context.userName,
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: context.teamIds || [],
        createdAt: now,
      };

      scheduledReports.set(id, newSchedule);

      await this.auditService.logAction(context, {
        action: 'create',
        entityType: 'report',
        entityId: id,
        metadata: {
          reportId: schedule.reportId,
          frequency: schedule.frequency,
          recipientCount: schedule.recipientUserIds.length + (schedule.recipientEmails?.length || 0),
        },
      });

      return successResult(newSchedule);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Update a scheduled report
   */
  async updateSchedule(
    context: SecurityContext,
    scheduleId: string,
    updates: Partial<ScheduledReport>
  ): Promise<RepositoryResult<ScheduledReport>> {
    try {
      this.ensureScheduledReportsEnabled();
      validateSecurityContext(context);

      const existing = scheduledReports.get(scheduleId);
      if (!existing) {
        return failedResult(new InvalidArgumentError(`Schedule not found: ${scheduleId}`, 'scheduleId'));
      }

      // Check ownership
      if (existing.createdById !== context.userId && !this.isAdminOrOwner(context)) {
        return failedResult(new AuthorizationError('Not authorized to update this schedule'));
      }

      // Recalculate next send if schedule changed
      let nextSendAt = existing.nextSendAt;
      if (updates.frequency || updates.timeOfDay || updates.dayOfWeek || updates.dayOfMonth) {
        nextSendAt = this.calculateNextSendAt(
          updates.frequency || existing.frequency,
          updates.timeOfDay || existing.timeOfDay,
          updates.dayOfWeek ?? existing.dayOfWeek,
          updates.dayOfMonth ?? existing.dayOfMonth
        );
      }

      const updatedSchedule: ScheduledReport = {
        ...existing,
        ...updates,
        id: existing.id,
        businessId: existing.businessId,
        createdAt: existing.createdAt,
        nextSendAt,
        updatedAt: new Date(),
      };

      scheduledReports.set(scheduleId, updatedSchedule);

      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'report',
        entityId: scheduleId,
        metadata: {
          updatedFields: Object.keys(updates),
        },
      });

      return successResult(updatedSchedule);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Delete a scheduled report
   */
  async deleteSchedule(
    context: SecurityContext,
    scheduleId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureScheduledReportsEnabled();
      validateSecurityContext(context);

      const existing = scheduledReports.get(scheduleId);
      if (!existing) {
        return failedResult(new InvalidArgumentError(`Schedule not found: ${scheduleId}`, 'scheduleId'));
      }

      // Check ownership
      if (existing.createdById !== context.userId && !this.isAdminOrOwner(context)) {
        return failedResult(new AuthorizationError('Not authorized to delete this schedule'));
      }

      scheduledReports.delete(scheduleId);

      await this.auditService.logAction(context, {
        action: 'delete',
        entityType: 'report',
        entityId: scheduleId,
        metadata: {
          reportId: existing.reportId,
        },
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Export
  // ============================================

  /**
   * Export a report to file format
   * HIPAA: Validates that report does not contain PHI fields before export
   */
  async exportReport(
    context: SecurityContext,
    reportId: string,
    format: 'csv' | 'xlsx' | 'pdf',
    dateRange: { start: Date; end: Date }
  ): Promise<RepositoryResult<string>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      // SECURITY: Validate date range for exports
      this.validateDateRange(dateRange);

      // Run the report first
      const reportResult = await this.runReport(context, reportId, { dateRange });
      if (!reportResult.success) {
        return failedResult(reportResult.error);
      }

      const result = reportResult.data;
      const report = reportDefinitions.get(reportId);

      // HIPAA: Check for PHI fields before allowing export
      this.validateExportSafety(result.rows, report?.name || 'Unknown Report');

      // Generate unique export ID for tracking
      const exportId = `export-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

      // Generate export content
      let content: string;
      switch (format) {
        case 'csv':
          content = this.generateCsv(result, report);
          break;
        case 'xlsx':
          // Placeholder for XLSX generation
          content = this.generateCsv(result, report); // Fallback to CSV
          break;
        case 'pdf':
          content = this.generatePdf(result, report, dateRange);
          break;
        default:
          return failedResult(new InvalidArgumentError(`Unsupported format: ${format}`, 'format'));
      }

      // Create data URL (in production, upload to Cloud Storage and return signed URL)
      const mimeType = format === 'csv' ? 'text/csv' : format === 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      const downloadUrl = buildInlineDataUrl(mimeType, content);

      // AUDIT: Log export with tracking ID for HIPAA compliance
      await this.auditService.logAction(context, {
        action: 'export',
        entityType: 'report',
        entityId: reportId,
        metadata: {
          exportId,
          format,
          rowCount: result.rowCount,
          dateRangeStart: dateRange.start.toISOString(),
          dateRangeEnd: dateRange.end.toISOString(),
          phiCheck: 'passed',
        },
      });

      return successResult(downloadUrl);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Quick Metrics
  // ============================================

  /**
   * Get a single metric value for dashboard widgets
   */
  async getMetric(
    context: SecurityContext,
    metric: string,
    dateRange?: DateRange
  ): Promise<RepositoryResult<MetricValue>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const range = this.resolveDateRange(dateRange || 'this_month');
      const previousRange = this.getPreviousPeriod(range, dateRange || 'this_month');

      let value = 0;
      let previousValue = 0;

      switch (metric) {
        case 'deals_won_count':
          value = await this.countDealsWon(context, range);
          previousValue = await this.countDealsWon(context, previousRange);
          break;

        case 'deals_won_value':
        case 'revenue_this_month':
          value = await this.sumDealsWonValue(context, range);
          previousValue = await this.sumDealsWonValue(context, previousRange);
          break;

        case 'leads_created':
          value = await this.countLeadsCreated(context, range);
          previousValue = await this.countLeadsCreated(context, previousRange);
          break;

        case 'activities_completed':
          value = await this.countActivitiesCompleted(context, range);
          previousValue = await this.countActivitiesCompleted(context, previousRange);
          break;

        case 'open_deals_count':
          value = await this.countOpenDeals(context);
          previousValue = value; // No comparison for current state metrics
          break;

        case 'open_deals_value':
          value = await this.sumOpenDealsValue(context);
          previousValue = value;
          break;

        default:
          return failedResult(new InvalidArgumentError(`Unknown metric: ${metric}`, 'metric'));
      }

      const changePercent = previousValue > 0 ? ((value - previousValue) / previousValue) * 100 : 0;

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: metric,
        metadata: {
          dateRange: dateRange || 'this_month',
          value,
          previousValue,
        },
      });

      return successResult({
        value,
        previousValue,
        changePercent: Math.round(changePercent * 100) / 100,
      });
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  // ============================================
  // Private Methods - Report Execution
  // ============================================

  private async executeReport(
    context: SecurityContext,
    report: ReportDefinition,
    dateRange: { start: Date; end: Date },
    filters: ReportFilter[]
  ): Promise<ReportResult> {
    const startTime = Date.now();
    let rows: Record<string, unknown>[] = [];

    // Fetch data based on data source
    switch (report.dataSource) {
      case 'deals':
        rows = await this.fetchDealData(context, dateRange, filters, report);
        break;
      case 'leads':
        rows = await this.fetchLeadData(context, dateRange, filters, report);
        break;
      case 'activities':
        rows = await this.fetchActivityData(context, dateRange, filters, report);
        break;
      case 'sequence_enrollments':
        rows = await this.fetchEnrollmentData(context, dateRange, filters, report);
        break;
      default:
        rows = [];
    }

    // Apply limit
    if (report.limit && rows.length > report.limit) {
      rows = rows.slice(0, report.limit);
    }

    // Apply sorting
    if (report.sortBy) {
      const direction = report.sortOrder === 'desc' ? -1 : 1;
      rows.sort((a, b) => {
        const aVal = a[report.sortBy!];
        const bVal = b[report.sortBy!];
        if (aVal === bVal) return 0;
        if (aVal === null || aVal === undefined) return 1;
        if (bVal === null || bVal === undefined) return -1;
        return aVal < bVal ? -direction : direction;
      });
    }

    // Calculate totals for numeric fields
    const totals: Record<string, number> = {};
    for (const metric of report.metrics) {
      if (metric.format === 'number' || metric.format === 'currency') {
        totals[metric.field] = rows.reduce((sum, row) => {
          const val = row[metric.field];
          return sum + (typeof val === 'number' ? val : 0);
        }, 0);
      }
    }

    return {
      reportId: report.id,
      generatedAt: new Date(),
      dateRange,
      rows: rows.slice(0, MAX_REPORT_ROWS),
      totals,
      rowCount: rows.length,
      queryTimeMs: Date.now() - startTime,
    };
  }

  private async fetchDealData(
    context: SecurityContext,
    dateRange: { start: Date; end: Date },
    filters: ReportFilter[],
    report: ReportDefinition
  ): Promise<Record<string, unknown>[]> {
    const result = await this.dealRepo.getByStatus(context, 'open');
    if (!result.success) return [];

    // Also get won deals in range
    const wonDealsResult = await this.dealRepo.getByStatus(context, 'won');
    const wonDeals = wonDealsResult.success ? wonDealsResult.data.filter((deal) => {
      const closedAt = deal.closedAt;
      if (!closedAt) return false;
      return closedAt >= dateRange.start && closedAt <= dateRange.end;
    }) : [];

    const allDeals = [
      ...result.data,
      ...wonDeals,
    ];

    // Filter by date range and additional filters
    return allDeals
      .filter((deal) => {
        const dateField = report.dateField || 'createdAt';
        const dealDate = (deal as Record<string, unknown>)[dateField] as Date;
        if (dealDate < dateRange.start || dealDate > dateRange.end) return false;
        return this.applyFilters(deal, filters);
      })
      .map((deal) => this.aggregateRow(deal as unknown as Record<string, unknown>, report));
  }

  private async fetchLeadData(
    context: SecurityContext,
    dateRange: { start: Date; end: Date },
    filters: ReportFilter[],
    report: ReportDefinition
  ): Promise<Record<string, unknown>[]> {
    const result = await this.leadRepo.getFiltered(context, {
      dateRange: { start: dateRange.start, end: dateRange.end },
    }, { limit: MAX_REPORT_ROWS });

    if (!result.success) return [];

    return result.data.data
      .filter((lead) => this.applyFilters(lead, filters))
      .map((lead) => this.aggregateRow(lead, report));
  }

  private async fetchActivityData(
    context: SecurityContext,
    dateRange: { start: Date; end: Date },
    filters: ReportFilter[],
    report: ReportDefinition
  ): Promise<Record<string, unknown>[]> {
    const result = await this.activityRepo.getAll(context, {
      limit: MAX_REPORT_ROWS,
    });

    if (!result.success) return [];

    return result.data.data
      .filter((activity) => {
        const activityDate = activity.createdAt as Date;
        if (activityDate < dateRange.start || activityDate > dateRange.end) return false;
        return this.applyFilters(activity, filters);
      })
      .map((activity) => this.aggregateRow(activity, report));
  }

  private async fetchEnrollmentData(
    context: SecurityContext,
    dateRange: { start: Date; end: Date },
    filters: ReportFilter[],
    report: ReportDefinition
  ): Promise<Record<string, unknown>[]> {
    const result = await this.enrollmentRepo.getAll(context, {
      limit: MAX_REPORT_ROWS,
    });

    if (!result.success) return [];

    return result.data.data
      .filter((enrollment) => {
        const enrollmentDate = enrollment.createdAt as Date;
        if (enrollmentDate < dateRange.start || enrollmentDate > dateRange.end) return false;
        return this.applyFilters(enrollment, filters);
      })
      .map((enrollment) => this.aggregateRow(enrollment, report));
  }

  private applyFilters(entity: unknown, filters: ReportFilter[]): boolean {
    const record = entity as Record<string, unknown>;

    for (const filter of filters) {
      const value = record[filter.field];

      switch (filter.operator) {
        case 'eq':
          if (value !== filter.value) return false;
          break;
        case 'neq':
          if (value === filter.value) return false;
          break;
        case 'gt':
          if (typeof value !== 'number' || value <= (filter.value as number)) return false;
          break;
        case 'gte':
          if (typeof value !== 'number' || value < (filter.value as number)) return false;
          break;
        case 'lt':
          if (typeof value !== 'number' || value >= (filter.value as number)) return false;
          break;
        case 'lte':
          if (typeof value !== 'number' || value > (filter.value as number)) return false;
          break;
        case 'in':
          if (!Array.isArray(filter.value) || !filter.value.includes(value)) return false;
          break;
        case 'contains':
          if (typeof value !== 'string' || !value.includes(filter.value as string)) return false;
          break;
      }
    }

    return true;
  }

  private aggregateRow(entity: unknown, report: ReportDefinition): Record<string, unknown> {
    const record = entity as Record<string, unknown>;
    const row: Record<string, unknown> = {};

    // Include dimension fields
    for (const dim of report.dimensions) {
      row[dim.field] = record[dim.field];
    }

    // Include metric fields
    for (const metric of report.metrics) {
      row[metric.field] = record[metric.field];
    }

    return row;
  }

  // ============================================
  // Private Methods - Metrics
  // ============================================

  private async countDealsWon(context: SecurityContext, range: { start: Date; end: Date }): Promise<number> {
    const result = await this.dealRepo.getWonValueRange(context, range.start, range.end);
    return result.success ? result.data.dealCount : 0;
  }

  private async sumDealsWonValue(context: SecurityContext, range: { start: Date; end: Date }): Promise<number> {
    const result = await this.dealRepo.getWonValueRange(context, range.start, range.end);
    return result.success ? result.data.totalValueCents : 0;
  }

  private async countLeadsCreated(context: SecurityContext, range: { start: Date; end: Date }): Promise<number> {
    const result = await this.leadRepo.getFiltered(context, {
      dateRange: { start: range.start, end: range.end },
    }, { limit: undefined });
    return result.success ? result.data.data.length : 0;
  }

  private async countActivitiesCompleted(context: SecurityContext, range: { start: Date; end: Date }): Promise<number> {
    const result = await this.activityRepo.getAll(context, {
      where: [{ field: 'isCompleted', operator: '==', value: true }],
    });
    if (!result.success) return 0;

    return result.data.data.filter((activity) => {
      const completedAt = activity.completedAt as Date | undefined;
      if (!completedAt) return false;
      return completedAt >= range.start && completedAt <= range.end;
    }).length;
  }

  private async countOpenDeals(context: SecurityContext): Promise<number> {
    const result = await this.dealRepo.getByStatus(context, 'open');
    return result.success ? result.data.length : 0;
  }

  private async sumOpenDealsValue(context: SecurityContext): Promise<number> {
    const result = await this.dealRepo.getByStatus(context, 'open');
    if (!result.success) return 0;
    return result.data.reduce((sum, deal) => sum + (deal.valueCents || 0), 0);
  }

  // ============================================
  // Private Methods - Helpers
  // ============================================

  private ensureReportingEnabled(): void {
    const { enableReports } = getFeatureFlags();
    if (!enableReports) {
      throw new AuthorizationError('Reporting is disabled');
    }
  }

  /**
   * SECURITY: Check if scheduled reports feature is enabled
   */
  private ensureScheduledReportsEnabled(): void {
    this.ensureReportingEnabled();
    const { enableScheduledReports } = getFeatureFlags();
    if (!enableScheduledReports) {
      throw new AuthorizationError('Scheduled reports are disabled');
    }
  }

  /**
   * Validate date range to prevent DoS and ensure reasonable bounds
   * SECURITY: Prevents attackers from requesting unreasonably large date ranges
   */
  private validateDateRange(dateRange: { start: Date; end: Date }): void {
    const now = new Date();
    const minDate = new Date(Date.UTC(now.getUTCFullYear() - MAX_YEARS_BACK, 0, 1));

    // Check start date is not too far in the past
    if (dateRange.start < minDate) {
      throw new InvalidArgumentError(
        `Date range cannot go back more than ${MAX_YEARS_BACK} years`,
        'dateRange.start'
      );
    }

    // Check start date is not in the future
    if (dateRange.start > now) {
      throw new InvalidArgumentError(
        'Start date cannot be in the future',
        'dateRange.start'
      );
    }

    // Check end date is not before start date
    if (dateRange.end < dateRange.start) {
      throw new InvalidArgumentError(
        'End date must be after start date',
        'dateRange.end'
      );
    }

    // Check range is not too large
    const rangeDays = Math.ceil(
      (dateRange.end.getTime() - dateRange.start.getTime()) / (1000 * 60 * 60 * 24)
    );
    if (rangeDays > MAX_DATE_RANGE_DAYS) {
      throw new InvalidArgumentError(
        `Date range cannot exceed ${MAX_DATE_RANGE_DAYS} days`,
        'dateRange'
      );
    }
  }

  /**
   * Validate filter fields against allowed whitelist
   * SECURITY: Prevents filter injection attacks
   */
  private validateFilters(filters: ReportFilter[], dataSource: string): void {
    const allowedFields = ALLOWED_FILTER_FIELDS[dataSource] || [];

    for (const filter of filters) {
      // Check field is in whitelist
      if (!allowedFields.includes(filter.field)) {
        throw new InvalidArgumentError(
          `Filter field '${filter.field}' is not allowed for data source '${dataSource}'`,
          'filter.field'
        );
      }

      // Validate operator
      const validOperators = ['eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'in', 'contains'];
      if (!validOperators.includes(filter.operator)) {
        throw new InvalidArgumentError(
          `Invalid filter operator: ${filter.operator}`,
          'filter.operator'
        );
      }

      // Validate value based on operator
      if (['gt', 'gte', 'lt', 'lte'].includes(filter.operator)) {
        if (typeof filter.value !== 'number') {
          throw new InvalidArgumentError(
            `Operator '${filter.operator}' requires a numeric value`,
            'filter.value'
          );
        }
      }

      if (filter.operator === 'in') {
        if (!Array.isArray(filter.value)) {
          throw new InvalidArgumentError(
            "Operator 'in' requires an array value",
            'filter.value'
          );
        }
      }

      if (filter.operator === 'contains') {
        if (typeof filter.value !== 'string') {
          throw new InvalidArgumentError(
            "Operator 'contains' requires a string value",
            'filter.value'
          );
        }
        // Check for suspicious regex patterns that could cause ReDoS
        if (/[{}[\]()*.+?^$|\\]/.test(filter.value)) {
          throw new InvalidArgumentError(
            'Filter value contains invalid characters',
            'filter.value'
          );
        }
      }
    }
  }

  /**
   * Check if report contains PHI fields that would block export
   * HIPAA: Prevents export of reports containing personally identifiable health information
   */
  private checkPhiFields(rows: Record<string, unknown>[]): string[] {
    if (rows.length === 0) return [];

    const firstRow = rows[0];
    const foundPhiFields: string[] = [];

    for (const field of Object.keys(firstRow)) {
      const lowerField = field.toLowerCase();
      if (PHI_BLOCKED_FIELDS.some((phi) => lowerField.includes(phi.toLowerCase()))) {
        foundPhiFields.push(field);
      }
    }

    return foundPhiFields;
  }

  /**
   * Validate that report is safe for export (no PHI)
   * HIPAA: Blocks export of reports containing PHI
   */
  private validateExportSafety(rows: Record<string, unknown>[], reportName: string): void {
    const phiFields = this.checkPhiFields(rows);
    if (phiFields.length > 0) {
      throw new AuthorizationError(
        `Report '${reportName}' contains PHI fields (${phiFields.join(', ')}) and cannot be exported. ` +
        'Only aggregated reports without individual identifying information can be exported.'
      );
    }
  }

  /**
   * Validate scheduled report recipients
   * SECURITY: Ensures recipients are valid and emails are from allowed domains
   */
  private async validateRecipients(
    _context: SecurityContext,
    recipientUserIds: string[],
    recipientEmails?: string[]
  ): Promise<void> {
    // Validate at least one recipient
    if (!recipientUserIds.length && (!recipientEmails || !recipientEmails.length)) {
      throw new InvalidArgumentError('At least one recipient is required', 'recipientUserIds');
    }

    // Validate email format
    if (recipientEmails) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      for (let i = 0; i < recipientEmails.length; i++) {
        if (!emailRegex.test(recipientEmails[i])) {
          // HIPAA: Do not expose recipient details in the error message.
          throw new InvalidArgumentError(`Invalid recipient format at position ${i + 1}`, 'recipientEmails');
        }
      }
    }

    // Note: In production, would also validate:
    // - recipientUserIds exist in the business
    // - recipientEmails are from allowed domains
    // - recipients have permission to view the report data
  }

  private isAdminOrOwner(context: SecurityContext): boolean {
    return context.userRole === 'owner' || context.userRole === 'admin';
  }

  private canAccessReport(context: SecurityContext, report: ReportDefinition): boolean {
    // Admins/owners can access all reports
    if (this.isAdminOrOwner(context)) return true;

    // Front desk/client users can only access their own private reports.
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return report.ownerId === context.userId;
    }

    // Owner can access their own reports
    if (report.ownerId === context.userId) return true;

    // Check shared with users
    if (report.sharedWithUserIds?.includes(context.userId)) return true;

    // Check shared with teams
    const userTeams = context.teamIds || [];
    if (report.sharedWithTeamIds?.some((teamId) => userTeams.includes(teamId))) return true;

    // Check team visibility - only staff+ roles
    if (report.visibility === 'team') {
      if (!REPORTING_VISIBLE_ROLES.includes(context.userRole as typeof REPORTING_VISIBLE_ROLES[number])) {
        return false;
      }
      return report.teamIds?.some((teamId) => userTeams.includes(teamId)) ?? false;
    }

    // Public reports are accessible to staff+ roles
    if (report.isPublic) {
      return REPORTING_VISIBLE_ROLES.includes(context.userRole as typeof REPORTING_VISIBLE_ROLES[number]);
    }

    // Org visibility - only internal business roles with reporting access.
    if (report.visibility === 'org') {
      return REPORTING_VISIBLE_ROLES.includes(context.userRole as typeof REPORTING_VISIBLE_ROLES[number]);
    }

    return false;
  }

  private canModifyReport(context: SecurityContext, report: ReportDefinition): boolean {
    if (this.isAdminOrOwner(context)) return true;
    return report.ownerId === context.userId;
  }

  private validateReportConfig(config: CreateReportInput): string | null {
    const name = config.name as string | undefined;
    const dimensions = config.dimensions as unknown[] | undefined;
    const metrics = config.metrics as unknown[] | undefined;
    if (!name?.trim()) {
      return 'Report name is required';
    }
    if (!config.dataSource) {
      return 'Data source is required';
    }
    if (!config.reportType) {
      return 'Report type is required';
    }
    if (!config.chartType) {
      return 'Chart type is required';
    }
    if (!dimensions?.length && !metrics?.length) {
      return 'At least one dimension or metric is required';
    }
    return null;
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
        // Default to this month
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }

    return { start, end };
  }

  private getPreviousPeriod(range: { start: Date; end: Date }, _dateRange: DateRange): { start: Date; end: Date } {
    const duration = range.end.getTime() - range.start.getTime();
    return {
      start: new Date(range.start.getTime() - duration - 1),
      end: new Date(range.start.getTime() - 1),
    };
  }

  private calculateNextSendAt(
    frequency: ScheduledReportFrequency,
    timeOfDay: string,
    dayOfWeek?: number,
    dayOfMonth?: number
  ): Date {
    const [hours, minutes] = timeOfDay.split(':').map(Number);
    const now = new Date();
    const next = new Date(now);

    next.setHours(hours, minutes, 0, 0);

    switch (frequency) {
      case 'daily':
        if (next <= now) {
          next.setDate(next.getDate() + 1);
        }
        break;
      case 'weekly':
        const targetDay = dayOfWeek ?? 1; // Default to Monday
        const currentDay = next.getDay();
        let daysToAdd = targetDay - currentDay;
        if (daysToAdd <= 0 || (daysToAdd === 0 && next <= now)) {
          daysToAdd += 7;
        }
        next.setDate(next.getDate() + daysToAdd);
        break;
      case 'monthly':
        const targetDate = dayOfMonth ?? 1;
        next.setDate(targetDate);
        if (next <= now) {
          next.setMonth(next.getMonth() + 1);
        }
        break;
    }

    return next;
  }

  private generateCsv(result: ReportResult, _report?: ReportDefinition): string {
    if (!result.rows.length) {
      return '';
    }

    const headers = Object.keys(result.rows[0]);
    const rows = result.rows.map((row) =>
      headers.map((header) => {
        const value = row[header];
        return value instanceof Date ? value.toISOString() : (value as string | number | boolean | null | undefined);
      })
    );

    return buildCsvDocument(headers, rows);
  }

  private generatePdf(
    result: ReportResult,
    report?: ReportDefinition,
    dateRange?: { start: Date; end: Date }
  ): string {
    const title = report?.name || 'Report Export';
    const lines = [
      `Report ID: ${result.reportId}`,
      `Generated: ${result.generatedAt.toISOString()}`,
      `Rows: ${result.rowCount}`,
      `Query Time (ms): ${result.queryTimeMs}`,
    ];

    if (dateRange) {
      lines.push(
        `Date Range: ${dateRange.start.toISOString().slice(0, 10)} -> ${dateRange.end.toISOString().slice(0, 10)}`
      );
    }

    if (result.totals && Object.keys(result.totals).length) {
      lines.push('', 'Totals');
      Object.entries(result.totals).forEach(([key, value]) => {
        lines.push(`${key}: ${value}`);
      });
    }

    if (!result.rows.length) {
      lines.push('', 'No rows returned for this report.');
      return buildSimplePdfDocument(title, lines);
    }

    const headers = Object.keys(result.rows[0]);
    lines.push('', `Columns: ${headers.join(', ')}`, '', 'Rows');

    const maxRows = 50;
    result.rows.slice(0, maxRows).forEach((row, index) => {
      const parts = headers.map((header) => `${header}: ${this.formatExportValue(row[header])}`);
      lines.push(`${index + 1}. ${parts.join(' | ')}`);
    });

    if (result.rowCount > maxRows) {
      lines.push(`... ${result.rowCount - maxRows} additional rows omitted from the PDF preview.`);
    }

    return buildSimplePdfDocument(title, lines);
  }

  private formatExportValue(value: unknown): string {
    if (value === null || value === undefined) {
      return '';
    }
    if (value instanceof Date) {
      return value.toISOString();
    }
    if (typeof value === 'object') {
      try {
        return JSON.stringify(value);
      } catch {
        return '[unserializable]';
      }
    }
    return String(value);
  }

  // ============================================
  // System Reports
  // ============================================

  /**
   * Get all system report definitions (templates, not yet seeded)
   */
  getSystemReportTemplates(): SystemReportDefinition[] {
    return [...SYSTEM_REPORTS];
  }

  /**
   * Get system reports by type
   */
  getSystemReportTemplatesByType(reportType: ReportType): SystemReportDefinition[] {
    return getSystemReportsByType(reportType);
  }

  /**
   * Get a specific system report template by name
   */
  getSystemReportTemplateByName(name: string): SystemReportDefinition | undefined {
    return getSystemReportByName(name);
  }

  /**
   * Seed system reports for a business.
   * Creates all predefined system reports that don't already exist.
   * Should be called when a business is created or on first reporting access.
   */
  async seedSystemReports(
    context: SecurityContext
  ): Promise<RepositoryResult<{ seeded: number; existing: number }>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      // Only admins/owners can seed system reports
      if (!this.isAdminOrOwner(context)) {
        return failedResult(new AuthorizationError('Only admins can seed system reports'));
      }

      let seededCount = 0;
      let existingCount = 0;

      // Get existing system reports for this business
      const existingReports = Array.from(reportDefinitions.values())
        .filter((r) => r.businessId === context.businessId && r.isSystemReport);
      const existingNames = new Set(existingReports.map((r) => r.name));

      // Seed each system report that doesn't exist
      for (const systemReport of SYSTEM_REPORTS) {
        if (existingNames.has(systemReport.name)) {
          existingCount++;
          continue;
        }

        const id = `sys-report-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        const now = new Date();

        const systemReportDef = createReportDefinitionFromSystem(
          systemReport,
          context.businessId,
          context.userId,
          context.userName
        );
        const fullReport = {
          ...systemReportDef,
          id,
          createdAt: now,
        } as ReportDefinition;

        reportDefinitions.set(id, fullReport);
        seededCount++;
      }

      await this.auditService.logAction(context, {
        action: 'create',
        entityType: 'report',
        entityId: 'batch',
        metadata: {
          seeded: seededCount,
          existing: existingCount,
          total: SYSTEM_REPORTS.length,
        },
      });

      return successResult({ seeded: seededCount, existing: existingCount });
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get all seeded system reports for the current business
   */
  async getSystemReports(
    context: SecurityContext
  ): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      const systemReports = Array.from(reportDefinitions.values())
        .filter((r) => r.businessId === context.businessId && r.isSystemReport);

      return successResult(systemReports);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Check if system reports have been seeded for a business.
   */
  async areSystemReportsSeeded(
    context: SecurityContext
  ): Promise<RepositoryResult<boolean>> {
    try {
      validateSecurityContext(context);

      const existingReports = Array.from(reportDefinitions.values())
        .filter((r) => r.businessId === context.businessId && r.isSystemReport);

      // Consider seeded if we have at least half the system reports
      const threshold = Math.floor(SYSTEM_REPORTS.length / 2);
      return successResult(existingReports.length >= threshold);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Reseed a specific system report (useful for updates)
   */
  async reseedSystemReport(
    context: SecurityContext,
    reportName: string
  ): Promise<RepositoryResult<ReportDefinition>> {
    try {
      this.ensureReportingEnabled();
      validateSecurityContext(context);

      if (!this.isAdminOrOwner(context)) {
        return failedResult(new AuthorizationError('Only admins can reseed system reports'));
      }

      const systemReport = getSystemReportByName(reportName);
      if (!systemReport) {
        return failedResult(new InvalidArgumentError(`System report not found: ${reportName}`, 'reportName'));
      }

      // Find existing report
      const existing = Array.from(reportDefinitions.values())
        .find((r) => r.businessId === context.businessId && r.isSystemReport && r.name === reportName);

      if (existing) {
        // Update existing report
        const updatedReport: ReportDefinition = {
          ...existing,
          ...systemReport,
          id: existing.id,
          businessId: existing.businessId,
          createdAt: existing.createdAt,
          updatedAt: new Date(),
        };
        reportDefinitions.set(existing.id, updatedReport);

        await this.auditService.logAction(context, {
          action: 'update',
          entityType: 'report',
          entityId: existing.id,
          metadata: { reportName, action: 'reseed' },
        });

        return successResult(updatedReport);
      }

      // Create new report
      const id = `sys-report-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date();

      const newSystemReportDef = createReportDefinitionFromSystem(
        systemReport,
        context.businessId,
        context.userId,
        context.userName
      );
      const newReport = {
        ...newSystemReportDef,
        id,
        createdAt: now,
      } as ReportDefinition;

      reportDefinitions.set(id, newReport);

      await this.auditService.logAction(context, {
        action: 'create',
        entityType: 'report',
        entityId: id,
        metadata: { reportName, action: 'reseed' },
      });

      return successResult(newReport);
    } catch (error) {
      return failedResult(error as Error);
    }
  }
}

// ============================================
// Export Singleton
// ============================================

let reportingServiceInstance: ReportingService | null = null;

export function getReportingService(): ReportingService {
  if (!reportingServiceInstance) {
    reportingServiceInstance = new ReportingService();
  }
  return reportingServiceInstance;
}
