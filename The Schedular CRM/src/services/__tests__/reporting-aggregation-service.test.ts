import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ReportingAggregationService } from '../reporting-aggregation-service';
import type { Deal, Lead, Pipeline } from '../../types/models';
import type { ReportingAggregate } from '../../types/reporting';
import type {
  DealRepository,
  LeadRepository,
  PipelineRepository,
  ReportingAggregateRepository,
} from '../../data/repositories';
import type { SecurityContext, PaginatedResult } from '../../data/repositories/repository-types';
import { successResult, AuthorizationError } from '../../data/errors/repository-errors';
import { AuditLogService } from '../AuditLogService';

const context: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-a'],
};

const pipelineA: Pipeline = {
  id: 'pipe-a',
  name: 'Pipeline A',
  isDefault: true,
  isActive: true,
  ownerId: 'owner-a',
  ownerName: 'Owner A',
  teamIds: ['team-a'],
  createdAt: new Date(),
};

const pipelineB: Pipeline = {
  ...pipelineA,
  id: 'pipe-b',
  name: 'Pipeline B',
  ownerId: 'owner-b',
  ownerName: 'Owner B',
  teamIds: ['team-b'],
};

const dealForPipelineA: Deal = {
  id: 'deal-1',
  pipelineId: 'pipe-a',
  stageId: 'stage-1',
  title: 'Open deal',
  valueCents: 10000,
  currency: 'USD',
  probability: 30,
  status: 'open',
  tags: [],
  ownerId: 'owner-a',
  ownerName: 'Owner A',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-05'),
};

const wonDealForPipelineA: Deal = {
  ...dealForPipelineA,
  id: 'deal-2',
  title: 'Won deal',
  status: 'won',
  valueCents: 20000,
  closedAt: new Date('2024-01-10'),
  createdAt: new Date('2024-01-01'),
  stageId: 'stage-2',
};

const lostDealForPipelineB: Deal = {
  ...dealForPipelineA,
  id: 'deal-3',
  pipelineId: 'pipe-b',
  status: 'lost',
  valueCents: 30000,
  closedAt: new Date('2024-01-15'),
  createdAt: new Date('2024-01-05'),
  stageId: 'stage-3',
  ownerId: 'owner-b',
  ownerName: 'Owner B',
  teamIds: ['team-b'],
  wonLostReason: 'budget',
};

const convertedLead: Lead = {
  id: 'lead-1',
  firstName: 'Casey',
  lastName: 'Lead',
  email: 'casey@example.com',
  status: 'converted',
  source: 'website',
  score: 80,
  tags: [],
  ownerId: 'owner-a',
  ownerName: 'Owner A',
  teamIds: ['team-a'],
  createdAt: new Date('2024-01-01'),
  convertedToDealId: 'deal-2',
};

const newLead: Lead = {
  ...convertedLead,
  id: 'lead-2',
  status: 'new',
  source: 'referral',
  ownerId: 'owner-b',
  ownerName: 'Owner B',
  teamIds: ['team-b'],
  createdAt: new Date('2024-01-06'),
  convertedToDealId: undefined,
};

describe('ReportingAggregationService', () => {
  let mockDealsRepo: { getByPipeline: ReturnType<typeof vi.fn> };
  let mockLeadsRepo: { getFiltered: ReturnType<typeof vi.fn> };
  let mockPipelineRepo: { getActive: ReturnType<typeof vi.fn> };
  let mockAggregateRepo: {
    getByFilters: ReturnType<typeof vi.fn>;
    createAggregate: ReturnType<typeof vi.fn>;
  };
  let mockAuditService: { logAction: ReturnType<typeof vi.fn> };
  let service: ReportingAggregationService;

  beforeEach(() => {
    mockDealsRepo = {
      getByPipeline: vi.fn(),
    };
    mockLeadsRepo = {
      getFiltered: vi.fn(),
    };
    mockPipelineRepo = {
      getActive: vi.fn(),
    };
    mockAggregateRepo = {
      getByFilters: vi.fn(),
      createAggregate: vi.fn(),
    };
    mockAuditService = {
      logAction: vi.fn(),
    };

    const pipelineResult = successResult<PaginatedResult<Pipeline>>({
      data: [pipelineA, pipelineB],
      hasMore: false,
      lastDoc: null,
    });
    mockPipelineRepo.getActive.mockResolvedValue(pipelineResult);

    mockDealsRepo.getByPipeline.mockImplementation((_, pipelineId: string) => {
      if (pipelineId === 'pipe-a') {
        return Promise.resolve(successResult([dealForPipelineA, wonDealForPipelineA]));
      }
      if (pipelineId === 'pipe-b') {
        return Promise.resolve(successResult([lostDealForPipelineB]));
      }
      return Promise.resolve(successResult([]));
    });

    mockAggregateRepo.getByFilters.mockResolvedValue(successResult<ReportingAggregate[]>([]));
    mockAggregateRepo.createAggregate.mockResolvedValue(
      successResult<ReportingAggregate>({
        id: 'agg-1',
        pipelineId: 'pipe-a',
        ownerId: 'owner-a',
        teamIds: ['team-a'],
        bucket: 'monthly',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-01-31'),
        metrics: {
          openCount: 0,
          wonCount: 0,
          lostCount: 0,
          openValueCents: 0,
          wonValueCents: 0,
          lostValueCents: 0,
          averageCycleDays: 0,
        },
        stageBreakdown: [],
        stageConversions: [],
        lostReasons: [],
        velocity: {
          averageCycleDays: 0,
          averageOpenDays: 0,
          throughputPerDay: 0,
          winRate: 0,
        },
        createdAt: new Date(),
      })
    );

    mockLeadsRepo.getFiltered.mockResolvedValue(
      successResult({
        data: [convertedLead, newLead],
        hasMore: false,
        lastDoc: null,
      })
    );

    service = new ReportingAggregationService({
      dealRepository: mockDealsRepo as unknown as DealRepository,
      leadRepository: mockLeadsRepo as unknown as LeadRepository,
      pipelineRepository: mockPipelineRepo as unknown as PipelineRepository,
      aggregateRepository: mockAggregateRepo as unknown as ReportingAggregateRepository,
      auditLogService: mockAuditService as unknown as AuditLogService,
    });
  });

  it('computes per-pipeline KPIs with stage breakdown and time buckets', async () => {
    const result = await service.getAggregatedKpis(context, {
      includeStageBreakdown: true,
      bucket: 'daily',
    });

    expect(result.pipelines).toHaveLength(2);

    const pipelineMetrics = result.pipelines.find((p) => p.pipelineId === 'pipe-a');
    expect(pipelineMetrics?.metrics.wonCount).toBe(1);
    expect(pipelineMetrics?.metrics.openCount).toBe(1);
    expect(pipelineMetrics?.stageBreakdown).toHaveLength(2);
    expect(pipelineMetrics?.stageConversions.find((c) => c.stageId === 'stage-2')?.won).toBe(1);

    expect(result.summary.wonValueCents).toBe(20000);
    expect(result.summary.lostValueCents).toBe(30000);
    expect(result.timeBuckets.length).toBeGreaterThan(0);
    expect(result.lostReasons.find((r) => r.reason === 'budget')?.count).toBe(1);
    expect(result.ownerPerformance.find((p) => p.ownerOrTeamId === 'owner-a')?.metrics.wonCount).toBe(
      1
    );
    expect(result.cohorts.find((c) => c.source === 'website')?.convertedCount).toBe(1);
  });

  it('filters pipelines by requested team IDs', async () => {
    const result = await service.getAggregatedKpis(
      { ...context, teamIds: ['team-a', 'team-b'] },
      { teamIds: ['team-b'] }
    );

    expect(result.pipelines).toHaveLength(1);
    expect(result.pipelines[0].pipelineId).toBe('pipe-b');
    expect(mockDealsRepo.getByPipeline).toHaveBeenCalledTimes(1);
  });

  it('denies access when requesting an inaccessible pipeline', async () => {
    mockPipelineRepo.getActive.mockResolvedValue(
      successResult<PaginatedResult<Pipeline>>({
        data: [pipelineA],
        hasMore: false,
        lastDoc: null,
      })
    );

    await expect(
      service.getAggregatedKpis(
        { ...context, userRole: 'manager', teamIds: ['team-a'] },
        { pipelineIds: ['pipe-b'] }
      )
    ).rejects.toBeInstanceOf(AuthorizationError);
  });

  it('denies access when requesting teams outside the user scope', async () => {
    mockPipelineRepo.getActive.mockResolvedValue(
      successResult<PaginatedResult<Pipeline>>({
        data: [pipelineA],
        hasMore: false,
        lastDoc: null,
      })
    );

    await expect(
      service.getAggregatedKpis(
        { ...context, userRole: 'staff', teamIds: ['team-a'], managedTeamIds: [] },
        { teamIds: ['team-b'] }
      )
    ).rejects.toBeInstanceOf(AuthorizationError);
  });

  it('returns cached aggregates when preferCache is true', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(
      successResult<ReportingAggregate[]>([
        {
          id: 'agg-cached',
          pipelineId: 'pipe-a',
          ownerId: 'owner-a',
          teamIds: ['team-a'],
          bucket: 'monthly',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-01-31'),
          metrics: {
            openCount: 1,
            wonCount: 2,
            lostCount: 0,
            openValueCents: 5000,
            wonValueCents: 30000,
            lostValueCents: 0,
            averageCycleDays: 5,
          },
          stageBreakdown: [],
          stageConversions: [
            { stageId: 'stage-1', entered: 1, won: 1, lost: 0, conversionRate: 100 },
          ],
          lostReasons: [],
          velocity: {
            averageCycleDays: 5,
            averageOpenDays: 0,
            throughputPerDay: 0.5,
            winRate: 100,
          },
          createdAt: new Date(),
        },
      ])
    );

    const result = await service.getAggregatedKpis(context, { preferCache: true });

    expect(result.pipelines).toHaveLength(1);
    expect(result.summary.wonCount).toBe(2);
    expect(result.stageConversions[0]?.stageId).toBe('stage-1');
    expect(mockDealsRepo.getByPipeline).not.toHaveBeenCalled();
    expect(mockAuditService.logAction).toHaveBeenCalled();
  });

  it('returns empty result when no pipelines are accessible', async () => {
    mockPipelineRepo.getActive.mockResolvedValue(
      successResult<PaginatedResult<Pipeline>>({
        data: [],
        hasMore: false,
        lastDoc: null,
      })
    );

    const result = await service.getAggregatedKpis(context, {});

    expect(result.pipelines).toHaveLength(0);
    expect(result.summary.openCount).toBe(0);
  });

  it('tries cache first by default (without preferCache flag)', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(
      successResult<ReportingAggregate[]>([
        {
          id: 'agg-default-cache',
          pipelineId: 'pipe-a',
          ownerId: 'owner-a',
          teamIds: ['team-a'],
          bucket: 'monthly',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-01-31'),
          metrics: {
            openCount: 0,
            wonCount: 5,
            lostCount: 0,
            openValueCents: 0,
            wonValueCents: 50000,
            lostValueCents: 0,
            averageCycleDays: 3,
          },
          stageBreakdown: [],
          stageConversions: [],
          lostReasons: [],
          velocity: {
            averageCycleDays: 3,
            averageOpenDays: 0,
            throughputPerDay: 0.2,
            winRate: 100,
          },
          createdAt: new Date(), // Fresh cache
        },
      ])
    );

    // No preferCache flag - should still use cache
    const result = await service.getAggregatedKpis(context, {});

    expect(result.summary.wonCount).toBe(5);
    expect(mockDealsRepo.getByPipeline).not.toHaveBeenCalled();
  });

  it('bypasses stale cache and computes fresh data', async () => {
    const staleDate = new Date(Date.now() - 2 * 60 * 60 * 1000); // 2 hours ago
    mockAggregateRepo.getByFilters.mockResolvedValue(
      successResult<ReportingAggregate[]>([
        {
          id: 'agg-stale',
          pipelineId: 'pipe-a',
          ownerId: 'owner-a',
          teamIds: ['team-a'],
          bucket: 'monthly',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-01-31'),
          metrics: {
            openCount: 0,
            wonCount: 99, // Stale data
            lostCount: 0,
            openValueCents: 0,
            wonValueCents: 0,
            lostValueCents: 0,
            averageCycleDays: 0,
          },
          stageBreakdown: [],
          stageConversions: [],
          lostReasons: [],
          velocity: {
            averageCycleDays: 0,
            averageOpenDays: 0,
            throughputPerDay: 0,
            winRate: 0,
          },
          createdAt: staleDate, // Stale!
        },
      ])
    );

    const result = await service.getAggregatedKpis(context, {});

    // Should compute fresh - wonCount from actual deals, not stale cache
    expect(result.summary.wonCount).toBe(1); // From wonDealForPipelineA
    expect(mockDealsRepo.getByPipeline).toHaveBeenCalled();
  });

  it('skips cache entirely when preferCache is false', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(
      successResult<ReportingAggregate[]>([
        {
          id: 'agg-skip',
          pipelineId: 'pipe-a',
          ownerId: 'owner-a',
          teamIds: ['team-a'],
          bucket: 'monthly',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-01-31'),
          metrics: {
            openCount: 0,
            wonCount: 999,
            lostCount: 0,
            openValueCents: 0,
            wonValueCents: 0,
            lostValueCents: 0,
            averageCycleDays: 0,
          },
          stageBreakdown: [],
          stageConversions: [],
          lostReasons: [],
          velocity: {
            averageCycleDays: 0,
            averageOpenDays: 0,
            throughputPerDay: 0,
            winRate: 0,
          },
          createdAt: new Date(),
        },
      ])
    );

    const result = await service.getAggregatedKpis(context, { preferCache: false });

    // Should NOT use cached value of 999
    expect(result.summary.wonCount).toBe(1);
    expect(mockDealsRepo.getByPipeline).toHaveBeenCalled();
  });

  it('auto-persists aggregates for privileged users by default', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(successResult<ReportingAggregate[]>([]));

    await service.getAggregatedKpis(context, {}); // admin context

    expect(mockAggregateRepo.createAggregate).toHaveBeenCalled();
  });

  it('does not auto-persist when cacheResults is false', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(successResult<ReportingAggregate[]>([]));

    await service.getAggregatedKpis(context, { cacheResults: false });

    expect(mockAggregateRepo.createAggregate).not.toHaveBeenCalled();
  });

  it('does not auto-persist for non-privileged users', async () => {
    mockAggregateRepo.getByFilters.mockResolvedValue(successResult<ReportingAggregate[]>([]));

    await service.getAggregatedKpis(
      { ...context, userRole: 'staff' },
      {}
    );

    expect(mockAggregateRepo.createAggregate).not.toHaveBeenCalled();
  });
});
