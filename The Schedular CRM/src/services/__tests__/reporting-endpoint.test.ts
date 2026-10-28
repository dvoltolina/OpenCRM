import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { fetchReportingSnapshot } from '../reporting-endpoint';
import type { ReportingAggregationFilters, ReportingAggregationResult } from '../../types/reporting';
import type { SecurityContext } from '../../data/repositories/repository-types';
import * as features from '../../config/features';
import { AuthorizationError } from '../../data/errors/repository-errors';

const baseContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-a'],
  managedTeamIds: [],
};

const filters: ReportingAggregationFilters = {
  startDate: new Date('2024-01-01'),
  endDate: new Date('2024-01-31'),
  pipelineIds: ['pipe-1'],
};

const mockResult: ReportingAggregationResult = {
  generatedAt: new Date(),
  filters,
  summary: {
    openCount: 1,
    wonCount: 2,
    lostCount: 0,
    openValueCents: 1000,
    wonValueCents: 2000,
    lostValueCents: 0,
    averageCycleDays: 5,
  },
  pipelines: [],
  timeBuckets: [],
  stageConversions: [],
  velocity: {
    averageCycleDays: 5,
    averageOpenDays: 0,
    throughputPerDay: 0.1,
    winRate: 100,
  },
  ownerPerformance: [],
  teamPerformance: [],
  lostReasons: [],
  cohorts: [],
};

describe('fetchReportingSnapshot', () => {
  beforeEach(() => {
    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
      ...features.defaultFeatures,
      enableReports: true,
      enableAdvancedReporting: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('forwards sanitized filters to aggregation service when enabled', async () => {
    const service = {
      getAggregatedKpis: vi.fn().mockResolvedValue(mockResult),
    };

    const result = await fetchReportingSnapshot(baseContext, filters, service as any);

    expect(result.summary.wonCount).toBe(2);
    expect(service.getAggregatedKpis).toHaveBeenCalledWith(
      baseContext,
      expect.objectContaining({
        pipelineIds: ['pipe-1'],
        bucket: 'monthly',
      })
    );
  });

  it('fails closed when feature flag is disabled', async () => {
    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({
      ...features.defaultFeatures,
      enableReports: false,
      enableAdvancedReporting: false,
    });

    await expect(
      fetchReportingSnapshot(baseContext, filters, {
        getAggregatedKpis: vi.fn(),
      } as any)
    ).rejects.toBeInstanceOf(AuthorizationError);
  });

  it('calls remote endpoint when URL is configured', async () => {
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockResult),
      status: 200,
      statusText: 'OK',
    });
    vi.stubGlobal('fetch', fetchSpy);

    await fetchReportingSnapshot(
      baseContext,
      filters,
      { getAggregatedKpis: vi.fn() } as any,
      { endpointUrl: 'https://example.com/reporting' }
    );

    expect(fetchSpy).toHaveBeenCalledWith(
      'https://example.com/reporting',
      expect.objectContaining({
        method: 'POST',
      })
    );
  });
});
