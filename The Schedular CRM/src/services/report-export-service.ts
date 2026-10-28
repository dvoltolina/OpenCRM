/**
 * Report Export Service
 * Schedules and triggers CSV/PDF exports of reporting aggregates with RBAC, rate limits, and audit logging.
 */

import { getFeatureFlags } from '../config/features';
import { AuditLogService } from './AuditLogService';
import { ReportingAggregationService } from './reporting-aggregation-service';
import { getReportExportRepository } from '../data/repositories/report-export-repository';
import type { ReportExport, ReportExportDelivery, ReportExportFormat, ReportingAggregationFilters } from '../types/reporting';
import type { ReportExportRepository } from '../data/repositories/report-export-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import { AuthorizationError } from '../data/errors/repository-errors';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { buildCsvDocument, buildInlineDataUrl, buildSimplePdfDocument } from './export-document';

export interface ScheduleReportExportInput {
  name: string;
  description?: string;
  format: ReportExportFormat;
  cadence: ReportExport['cadence'];
  startAt?: Date;
  filters: ReportingAggregationFilters;
  delivery: ReportExportDelivery;
  teamIds?: string[];
  visibility?: ReportExport['visibility'];
}

export interface RunReportExportInput {
  exportId?: string;
  format: ReportExportFormat;
  filters: ReportingAggregationFilters;
  delivery: ReportExportDelivery;
}

export interface RunReportExportResult {
  exportId?: string;
  content: string;
  contentType: 'text/csv' | 'application/pdf';
  expiresAt: Date;
  delivery: ReportExportDelivery;
}

function sanitizeFilters(filters: ReportingAggregationFilters): ReportingAggregationFilters {
  return {
    ...filters,
    startDate: filters.startDate ? new Date(filters.startDate) : undefined,
    endDate: filters.endDate ? new Date(filters.endDate) : undefined,
    pipelineIds: filters.pipelineIds?.filter(Boolean),
    ownerIds: filters.ownerIds?.filter(Boolean),
    teamIds: filters.teamIds?.filter(Boolean),
    stageIds: filters.stageIds?.filter(Boolean),
    sources: filters.sources?.filter(Boolean),
    bucket: filters.bucket ?? 'monthly',
    includeStageBreakdown: filters.includeStageBreakdown ?? true,
  };
}

function formatDateRange(filters: ReportingAggregationFilters): string {
  const start = filters.startDate ? new Date(filters.startDate).toISOString().slice(0, 10) : 'any';
  const end = filters.endDate ? new Date(filters.endDate).toISOString().slice(0, 10) : 'any';
  return `${start} -> ${end}`;
}

function formatCurrencyFromCents(valueCents: number): string {
  return `$${(valueCents / 100).toFixed(2)}`;
}

export class ReportExportService {
  private readonly audit: AuditLogService;
  private readonly rateLimit: RateLimitService;
  private readonly reporting: ReportingAggregationService;
  private readonly exportRepo: ReportExportRepository;

  constructor(
    auditService?: AuditLogService,
    rateLimitService?: RateLimitService,
    reportingService?: ReportingAggregationService,
    exportRepository?: ReportExportRepository
  ) {
    this.audit = auditService ?? new AuditLogService();
    this.rateLimit = rateLimitService ?? getRateLimitService();
    this.reporting = reportingService ?? new ReportingAggregationService();
    this.exportRepo = exportRepository ?? getReportExportRepository();
  }

  async listScheduled(context: SecurityContext): Promise<ReportExport[]> {
    this.ensureExportAllowed(context);
    const result = await this.exportRepo.getAccessible(context, context.teamIds);
    if (!result.success) {
      throw result.error;
    }
    return result.data;
  }

  async scheduleExport(
    context: SecurityContext,
    input: ScheduleReportExportInput
  ): Promise<ReportExport> {
    this.ensureExportAllowed(context);
    const nextRunAt = input.startAt ? new Date(input.startAt) : this.computeNextRunDate(input.cadence);

    const scheduled = await this.exportRepo.schedule(context, {
      ...input,
      nextRunAt,
      filters: sanitizeFilters(input.filters),
    });

    if (!scheduled.success) {
      throw scheduled.error;
    }

    await this.audit.logAction(context, {
      action: 'create',
      entityType: 'reportExport',
      entityId: scheduled.data.id,
      metadata: {
        cadence: input.cadence,
        format: input.format,
        nextRunAt: nextRunAt.toISOString(),
        teamIds: input.teamIds?.length,
      },
    });

    return scheduled.data;
  }

  async runExportNow(
    context: SecurityContext,
    input: RunReportExportInput
  ): Promise<RunReportExportResult> {
    this.ensureExportAllowed(context);
    const limit = await this.rateLimit.checkLimit('export', context.userId, context.businessId);
    if (!limit.allowed) {
      throw new AuthorizationError(limit.message || 'Export rate limit exceeded');
    }

    const filters = sanitizeFilters(input.filters);
    const snapshot = await this.reporting.getAggregatedKpis(context, {
      ...filters,
      cacheResults: false,
      preferCache: false,
    });

    const content =
      input.format === 'csv'
        ? this.buildCsv(snapshot)
        : this.buildPdf(snapshot, filters);

    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 6); // 6 hours
    const delivery: ReportExportDelivery = {
      ...input.delivery,
      expiresAt,
      downloadUrl:
        input.delivery.method === 'link'
          ? buildInlineDataUrl(
              input.format === 'csv' ? 'text/csv' : 'application/pdf',
              content
            )
          : input.delivery.downloadUrl,
    };

    await this.rateLimit.recordAction('export', context.userId, context.businessId);
    await this.audit.logAction(context, {
      action: 'export',
      entityType: 'report',
      entityId: input.exportId || 'adhoc-report-export',
      metadata: {
        format: input.format,
        delivery: input.delivery.method,
        expiresAt: expiresAt.toISOString(),
        filterKeys: Object.keys(filters || {}),
      },
    });

    if (input.exportId) {
      await this.exportRepo.updateRunMetadata(context, input.exportId, {
        lastRunAt: new Date(),
        lastRunStatus: 'completed',
        status: 'scheduled',
        delivery,
      });
    }

    return {
      exportId: input.exportId,
      content,
      contentType: input.format === 'csv' ? 'text/csv' : 'application/pdf',
      expiresAt,
      delivery,
    };
  }

  private ensureExportAllowed(context: SecurityContext) {
    const { enableAdvancedReporting, enableImportExport, enableReports } = getFeatureFlags();
    if (!enableReports || enableAdvancedReporting === false || enableImportExport === false) {
      throw new AuthorizationError('Reporting exports are disabled by feature flag');
    }

    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      throw new AuthorizationError('Not authorized to run exports');
    }
  }

  private computeNextRunDate(cadence: ReportExport['cadence']): Date {
    const now = new Date();
    if (cadence === 'daily') {
      now.setDate(now.getDate() + 1);
    } else if (cadence === 'weekly') {
      now.setDate(now.getDate() + 7);
    }
    return now;
  }

  private buildCsv(snapshot: Awaited<ReturnType<ReportingAggregationService['getAggregatedKpis']>>): string {
    const header = [
      'bucket',
      'pipelineId',
      'wonCount',
      'lostCount',
      'openCount',
      'wonValueCents',
      'lostValueCents',
      'winRate',
    ];
    const rows = snapshot.pipelines.map((pipeline) => [
      snapshot.filters.bucket ?? 'monthly',
      pipeline.pipelineId,
      pipeline.metrics.wonCount,
      pipeline.metrics.lostCount,
      pipeline.metrics.openCount,
      pipeline.metrics.wonValueCents,
      pipeline.metrics.lostValueCents,
      pipeline.velocity.winRate.toFixed(2),
    ]);
    return buildCsvDocument(header, rows);
  }

  private buildPdf(
    snapshot: Awaited<ReturnType<ReportingAggregationService['getAggregatedKpis']>>,
    filters: ReportingAggregationFilters
  ): string {
    const lines = [
      `Generated: ${snapshot.generatedAt.toISOString()}`,
      `Date Range: ${formatDateRange(filters)}`,
      `Bucket: ${filters.bucket ?? snapshot.filters.bucket ?? 'monthly'}`,
      `Pipelines Returned: ${snapshot.pipelines.length}`,
      `Won Deals: ${snapshot.summary.wonCount}`,
      `Lost Deals: ${snapshot.summary.lostCount}`,
      `Open Deals: ${snapshot.summary.openCount}`,
      `Won Value: ${formatCurrencyFromCents(snapshot.summary.wonValueCents)}`,
      `Open Value: ${formatCurrencyFromCents(snapshot.summary.openValueCents)}`,
      `Average Cycle Days: ${snapshot.summary.averageCycleDays.toFixed(2)}`,
      `Overall Win Rate: ${snapshot.velocity.winRate.toFixed(2)}%`,
    ];

    if (filters.pipelineIds?.length) {
      lines.push(`Pipeline Filters: ${filters.pipelineIds.join(', ')}`);
    }
    if (filters.ownerIds?.length) {
      lines.push(`Owner Filters: ${filters.ownerIds.join(', ')}`);
    }
    if (filters.teamIds?.length) {
      lines.push(`Team Filters: ${filters.teamIds.join(', ')}`);
    }

    if (snapshot.pipelines.length) {
      lines.push('', 'Pipeline Breakdown');
      snapshot.pipelines.forEach((pipeline, index) => {
        lines.push(
          `${index + 1}. ${pipeline.pipelineId}`,
          `Won ${pipeline.metrics.wonCount} | Lost ${pipeline.metrics.lostCount} | Open ${pipeline.metrics.openCount}`,
          `Won Value ${formatCurrencyFromCents(pipeline.metrics.wonValueCents)} | Win Rate ${pipeline.velocity.winRate.toFixed(2)}%`
        );
      });
    } else {
      lines.push('', 'No pipeline aggregates matched the selected filters.');
    }

    return buildSimplePdfDocument('Reporting Aggregates Export', lines);
  }
}

let reportExportService: ReportExportService | null = null;

export function getReportExportService(): ReportExportService {
  if (!reportExportService) {
    reportExportService = new ReportExportService();
  }
  return reportExportService;
}
