import { beforeEach, describe, expect, it, vi, type Mock } from 'vitest';
import { ReportExportService } from '../report-export-service';
import type { ReportExportRepository } from '../../data/repositories/report-export-repository';
import type { RateLimitService } from '../RateLimitService';
import type { ReportingAggregationService } from '../reporting-aggregation-service';
import type { AuditLogService } from '../AuditLogService';
import type { ReportingAggregationResult } from '../../types/reporting';
import * as features from '../../config/features';
import { successResult } from '../../data/errors/repository-errors';

const context = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-a'],
};

const aggregation: ReportingAggregationResult = {
  generatedAt: new Date('2024-01-01'),
  filters: {},
  summary: {
    openCount: 1,
    wonCount: 2,
    lostCount: 0,
    openValueCents: 1000,
    wonValueCents: 2000,
    lostValueCents: 0,
    averageCycleDays: 3,
  },
  pipelines: [
    {
      pipelineId: 'pipe-1',
      ownerId: 'owner-1',
      teamIds: ['team-a'],
      metrics: {
        openCount: 1,
        wonCount: 1,
        lostCount: 0,
        openValueCents: 5000,
        wonValueCents: 7500,
        lostValueCents: 0,
        averageCycleDays: 2,
      },
      stageBreakdown: [],
      stageConversions: [],
      lostReasons: [],
      velocity: {
        averageCycleDays: 2,
        averageOpenDays: 1,
        throughputPerDay: 0.1,
        winRate: 100,
      },
    },
  ],
  timeBuckets: [],
  stageConversions: [],
  velocity: {
    averageCycleDays: 2,
    averageOpenDays: 1,
    throughputPerDay: 0.2,
    winRate: 100,
  },
  ownerPerformance: [],
  teamPerformance: [],
  lostReasons: [],
  cohorts: [],
};

describe('ReportExportService', () => {
  let repo: ReportExportRepository;
  let rateLimit: RateLimitService;
  let reporting: ReportingAggregationService;
  let audit: AuditLogService;
  let service: ReportExportService;

  beforeEach(() => {
    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
      ...features.defaultFeatures,
      enableReports: true,
      enableAdvancedReporting: true,
      enableImportExport: true,
    });

    repo = {
      getAccessible: vi.fn().mockResolvedValue(successResult([])),
      schedule: vi.fn(),
      updateRunMetadata: vi.fn().mockResolvedValue(successResult({
        id: 'export-1',
        name: 'Reporting export',
        format: 'csv',
        cadence: 'once',
        status: 'scheduled',
        nextRunAt: new Date(),
        filters: {},
        delivery: { method: 'link' },
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: ['team-a'],
        createdAt: new Date(),
      })),
    } as unknown as ReportExportRepository;

    rateLimit = {
      checkLimit: vi.fn().mockResolvedValue({
        allowed: true,
        remaining: 10,
        resetAt: new Date(),
      }),
      recordAction: vi.fn().mockResolvedValue(undefined),
    } as unknown as RateLimitService;

    reporting = {
      getAggregatedKpis: vi.fn().mockResolvedValue(aggregation),
    } as unknown as ReportingAggregationService;

    audit = {
      logAction: vi.fn().mockResolvedValue({ success: true }),
    } as unknown as AuditLogService;

    service = new ReportExportService(audit, rateLimit, reporting, repo);
  });

  it('schedules exports with sanitized defaults', async () => {
    (repo.schedule as unknown as Mock).mockResolvedValue(
      successResult({
        id: 'export-1',
        name: 'Reporting export',
        description: 'Scheduled reporting export',
        format: 'csv',
        cadence: 'daily',
        status: 'scheduled',
        nextRunAt: new Date('2024-01-02'),
        filters: { bucket: 'monthly' },
        delivery: { method: 'link' },
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: ['team-a'],
        createdAt: new Date(),
      })
    );

    const scheduled = await service.scheduleExport(context, {
      name: 'Reporting export',
      format: 'csv',
      cadence: 'daily',
      filters: {},
      delivery: { method: 'link' },
      description: 'Scheduled reporting export',
    });

    expect(scheduled.id).toBe('export-1');
    expect(repo.schedule).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        filters: expect.objectContaining({ bucket: 'monthly' }),
      })
    );
    expect((audit.logAction as unknown as Mock)).toHaveBeenCalled();
  });

  it('runs exports now and updates metadata', async () => {
    const result = await service.runExportNow(context, {
      exportId: 'export-1',
      format: 'csv',
      filters: {},
      delivery: { method: 'link' },
    });

    expect(result.contentType).toBe('text/csv');
    expect(result.content).toContain('bucket,pipelineId,wonCount,lostCount,openCount,wonValueCents,lostValueCents,winRate');
    expect(rateLimit.recordAction).toHaveBeenCalledWith('export', context.userId, context.businessId);
    expect((repo.updateRunMetadata as unknown as Mock)).toHaveBeenCalledWith(
      context,
      'export-1',
      expect.objectContaining({ lastRunStatus: 'completed' })
    );
  });

  it('builds a real PDF document for run-now exports', async () => {
    const result = await service.runExportNow(context, {
      format: 'pdf',
      filters: {},
      delivery: { method: 'link' },
    });

    expect(result.contentType).toBe('application/pdf');
    expect(result.content.startsWith('%PDF-1.4')).toBe(true);
    expect(result.content).toContain('Reporting Aggregates Export');
    expect(result.delivery.downloadUrl).toContain('data:application/pdf');
  });
});
