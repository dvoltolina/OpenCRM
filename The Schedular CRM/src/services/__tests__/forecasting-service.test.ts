/**
 * Forecasting Service Tests
 * Tests for revenue forecasting, weighted calculations, and confidence analysis
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ForecastingService } from '../forecasting-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Forecast, ForecastStageBreakdown } from '../../types/goals';
import type { Deal, Stage } from '../../types/models';

// ============================================
// Mock Repositories
// ============================================

const mockForecastRepo = {
  getCurrentForecast: vi.fn(),
  updateCalculations: vi.fn(),
  getByDateRange: vi.fn(),
};

const mockDealRepo = {
  getByStatus: vi.fn(),
  getWonInRange: vi.fn(),
};

const mockStageRepo = {
  getByPipeline: vi.fn(),
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

const createTestStage = (overrides: Partial<Stage> = {}): Stage => ({
  id: 'stage-1',
  pipelineId: 'pipeline-1',
  name: 'Qualification',
  order: 1,
  colorHex: '#3b82f6',
  probability: 20,
  isActive: true,
  createdAt: new Date(),
  ...overrides,
});

const createTestDeal = (overrides: Partial<Deal> = {}): Deal => ({
  id: 'deal-1',
  pipelineId: 'pipeline-1',
  stageId: 'stage-1',
  title: 'Test Deal',
  valueCents: 10000,
  currency: 'USD',
  probability: 20,
  status: 'open',
  tags: [],
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-1'],
  createdAt: new Date(),
  ...overrides,
});

const createTestForecast = (overrides: Partial<Forecast> = {}): Forecast => ({
  id: 'forecast-1',
  period: 'monthly',
  startDate: new Date('2025-01-01'),
  endDate: new Date('2025-01-31'),
  teamIds: ['team-1'],
  projectedRevenue: 0,
  bestCase: 0,
  committed: 0,
  closed: 0,
  stageBreakdown: [],
  lastCalculatedAt: new Date(),
  createdAt: new Date(),
  visibility: 'team',
  ...overrides,
});

// ============================================
// Tests
// ============================================

describe('ForecastingService', () => {
  let service: ForecastingService;

  beforeEach(() => {
    vi.clearAllMocks();

    service = new ForecastingService({
      forecastRepository: mockForecastRepo as any,
      dealRepository: mockDealRepo as any,
      stageRepository: mockStageRepo as any,
      auditLogService: mockAuditService as any,
    });

    mockDealRepo.getByStatus.mockImplementation(async (_ctx, status) => {
      if (status === 'open') {
        return {
          success: true,
          data: [createTestDeal(), createTestDeal({ id: 'deal-2', valueCents: 30000 })],
        };
      }
      if (status === 'won') {
        return {
          success: true,
          data: [createTestDeal({ id: 'deal-won', status: 'won', valueCents: 40000, closedAt: new Date('2025-01-15') })],
        };
      }
      return { success: true, data: [] };
    });

    mockDealRepo.getWonInRange.mockResolvedValue({
      success: true,
      data: [createTestDeal({ status: 'won', valueCents: 40000 })],
    });
  });

  describe('calculateForecast', () => {
    it('should calculate weighted revenue from open deals', async () => {
      const stages = [
        createTestStage({ id: 'stage-1', name: 'Qualification', probability: 20, order: 1 }),
        createTestStage({ id: 'stage-2', name: 'Demo', probability: 50, order: 2 }),
        createTestStage({ id: 'stage-3', name: 'Proposal', probability: 80, order: 3 }),
      ];

      const deals = [
        createTestDeal({ id: 'deal-1', stageId: 'stage-1', valueCents: 10000, probability: 20 }),
        createTestDeal({ id: 'deal-2', stageId: 'stage-2', valueCents: 20000, probability: 50 }),
        createTestDeal({ id: 'deal-3', stageId: 'stage-3', valueCents: 15000, probability: 80 }),
      ];

      const forecast = createTestForecast();

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
      mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
      mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
      mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
      mockForecastRepo.updateCalculations.mockResolvedValue({
        success: true,
        data: { ...forecast, projectedRevenue: 26000 }, // 2000 + 10000 + 12000
      });

      const result = await service.calculateForecast(testContext, {
        period: 'monthly',
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
      });

      expect(result.success).toBe(true);
      expect(mockForecastRepo.updateCalculations).toHaveBeenCalled();

      // Verify the calculation call
      const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
      const updateData = updateCall[2];

      // Projected revenue = weighted sum
      // Stage 1: 10000 * 0.20 = 2000
      // Stage 2: 20000 * 0.50 = 10000
      // Stage 3: 15000 * 0.80 = 12000
      // Total = 24000
      expect(updateData.projectedRevenue).toBe(24000);

      // Best case = sum of all open deal values
      expect(updateData.bestCase).toBe(45000);

      // Committed = deals with probability >= 80%
      expect(updateData.committed).toBe(15000);
    });

    it('should include won deals in closed amount', async () => {
      const stages = [createTestStage({ probability: 50 })];
      const openDeals = [createTestDeal({ valueCents: 10000 })];
      const wonDeals = [
        createTestDeal({ id: 'won-1', valueCents: 25000, status: 'won', closedAt: new Date('2025-01-10') }),
        createTestDeal({ id: 'won-2', valueCents: 15000, status: 'won', closedAt: new Date('2025-01-20') }),
      ];

      const forecast = createTestForecast();

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
      mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
      mockDealRepo.getByStatus.mockImplementation(async (_ctx, status) => {
        if (status === 'open') return { success: true, data: openDeals };
        if (status === 'won') return { success: true, data: wonDeals };
        return { success: true, data: [] };
      });
      mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: wonDeals });
      mockForecastRepo.updateCalculations.mockResolvedValue({
        success: true,
        data: { ...forecast, closed: 40000 },
      });

      await service.calculateForecast(testContext, {
        period: 'monthly',
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
      });

      const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
      const updateData = updateCall[2];

      expect(updateData.closed).toBe(40000); // 25000 + 15000
    });

    it('should calculate stage breakdown correctly', async () => {
      const stages = [
        createTestStage({ id: 'stage-1', name: 'Stage A', probability: 25, order: 1 }),
        createTestStage({ id: 'stage-2', name: 'Stage B', probability: 75, order: 2 }),
      ];

      const deals = [
        createTestDeal({ id: 'deal-1', stageId: 'stage-1', valueCents: 10000 }),
        createTestDeal({ id: 'deal-2', stageId: 'stage-1', valueCents: 20000 }),
        createTestDeal({ id: 'deal-3', stageId: 'stage-2', valueCents: 40000 }),
      ];

      const forecast = createTestForecast();

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
      mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
      mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
      mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
      mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

      await service.calculateForecast(testContext, {
        period: 'monthly',
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
      });

      const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
      const stageBreakdown: ForecastStageBreakdown[] = updateCall[2].stageBreakdown;

      // Stage A: 2 deals, 30000 total, 7500 weighted (30000 * 0.25)
      const stageA = stageBreakdown.find((s) => s.stageId === 'stage-1');
      expect(stageA?.dealCount).toBe(2);
      expect(stageA?.totalValueCents).toBe(30000);
      expect(stageA?.weightedValueCents).toBe(7500);

      // Stage B: 1 deal, 40000 total, 30000 weighted (40000 * 0.75)
      const stageB = stageBreakdown.find((s) => s.stageId === 'stage-2');
      expect(stageB?.dealCount).toBe(1);
      expect(stageB?.totalValueCents).toBe(40000);
      expect(stageB?.weightedValueCents).toBe(30000);
    });

    it('should calculate rep breakdown for team forecasts', async () => {
      const stages = [createTestStage({ probability: 50 })];

      const deals = [
        createTestDeal({ id: 'deal-1', assigneeId: 'user-1', assigneeName: 'Rep A', valueCents: 10000, probability: 50 }),
        createTestDeal({ id: 'deal-2', assigneeId: 'user-1', assigneeName: 'Rep A', valueCents: 20000, probability: 50 }),
        createTestDeal({ id: 'deal-3', assigneeId: 'user-2', assigneeName: 'Rep B', valueCents: 30000, probability: 50 }),
      ];

      const forecast = createTestForecast();

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
      mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
      mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
      mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
      mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

      await service.calculateForecast(testContext, {
        period: 'monthly',
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
      });

      const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
      const repBreakdown = updateCall[2].repBreakdown;

      // Rep A: 2 deals, (10000 + 20000) * 0.5 = 15000 projected
      const repA = repBreakdown.find((r: any) => r.userId === 'user-1');
      expect(repA?.dealCount).toBe(2);
      expect(repA?.projectedRevenue).toBe(15000);

      // Rep B: 1 deal, 30000 * 0.5 = 15000 projected
      const repB = repBreakdown.find((r: any) => r.userId === 'user-2');
      expect(repB?.dealCount).toBe(1);
      expect(repB?.projectedRevenue).toBe(15000);
    });

    it('should filter by pipeline when specified', async () => {
      const stages = [createTestStage({ pipelineId: 'pipeline-1' })];
      const deals = [createTestDeal({ pipelineId: 'pipeline-1' })];
      const forecast = createTestForecast();

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
      mockStageRepo.getByPipeline.mockResolvedValue({ success: true, data: stages });
      mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
      mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
      mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

      await service.calculateForecast(testContext, {
        period: 'monthly',
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-01-31'),
        pipelineId: 'pipeline-1',
      });

      expect(mockStageRepo.getByPipeline).toHaveBeenCalledWith(testContext, 'pipeline-1');
    });
  });

  describe('getForecastSummary', () => {
    it('should return forecast with confidence analysis', async () => {
      const forecast = createTestForecast({
        projectedRevenue: 100000,
        committed: 80000, // 80% committed = high confidence
        closed: 20000,
        stageBreakdown: [
          { stageId: 'stage-1', stageName: 'Proposal', probability: 80, dealCount: 5, totalValueCents: 80000, weightedValueCents: 64000 },
        ],
      });

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });

      const result = await service.getForecastSummary(testContext, 'monthly');

      expect(result.success).toBe(true);
      expect(result.data?.forecast).toEqual(forecast);
      expect(result.data?.confidenceLevel).toBe('high');
      expect(result.data?.commitmentRatio).toBe(80);
    });

    it('should calculate gap to target correctly', async () => {
      const forecast = createTestForecast({
        projectedRevenue: 80000,
        closed: 10000,
      });

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });

      const targetRevenue = 100000;
      const result = await service.getForecastSummary(testContext, 'monthly', undefined, targetRevenue);

      expect(result.success).toBe(true);
      // Gap = target - (closed + projected) = 100000 - (10000 + 80000) = 10000
      expect(result.data?.gapToTarget).toBe(10000);
    });

    it('should return medium confidence for moderate stage distribution', async () => {
      const forecast = createTestForecast({
        projectedRevenue: 100000,
        committed: 40000, // 40% committed
        stageBreakdown: [
          { stageId: 'stage-1', stageName: 'Demo', probability: 60, dealCount: 5, totalValueCents: 60000, weightedValueCents: 36000 },
          { stageId: 'stage-2', stageName: 'Early', probability: 30, dealCount: 3, totalValueCents: 40000, weightedValueCents: 12000 },
        ],
      });

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });

      const result = await service.getForecastSummary(testContext, 'monthly');

      // Medium: committed < 70% but >50% value in high-prob stages
      expect(result.data?.confidenceLevel).toBe('medium');
    });

    it('should return low confidence for early-stage heavy distribution', async () => {
      const forecast = createTestForecast({
        projectedRevenue: 100000,
        committed: 10000, // Only 10% committed
        stageBreakdown: [
          { stageId: 'stage-1', stageName: 'Early', probability: 20, dealCount: 10, totalValueCents: 80000, weightedValueCents: 16000 },
        ],
      });

      mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });

      const result = await service.getForecastSummary(testContext, 'monthly');

      expect(result.data?.confidenceLevel).toBe('low');
    });
  });

  describe('getForecastHistory', () => {
    it('should return historical forecasts for trend analysis', async () => {
      const forecasts = [
        createTestForecast({ id: 'f1', startDate: new Date('2025-01-01') }),
        createTestForecast({ id: 'f2', startDate: new Date('2024-12-01') }),
        createTestForecast({ id: 'f3', startDate: new Date('2024-11-01') }),
      ];

      mockForecastRepo.getByDateRange.mockResolvedValue({ success: true, data: forecasts });

      const result = await service.getForecastHistory(testContext, 6, 'monthly');

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(3);
    });
  });

  describe('getPeriodDateRange', () => {
    it('should return correct weekly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('weekly');

      expect(startDate.getDay()).toBe(0); // Sunday
      expect(endDate.getDay()).toBe(6); // Saturday
    });

    it('should return correct monthly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('monthly');

      expect(startDate.getDate()).toBe(1);
      // End should be last day of month
      const nextMonth = new Date(endDate);
      nextMonth.setDate(nextMonth.getDate() + 1);
      expect(nextMonth.getDate()).toBe(1);
    });

    it('should return correct quarterly date range', () => {
      const { startDate } = service.getPeriodDateRange('quarterly');

      // Start should be first of quarter (Jan, Apr, Jul, Oct)
      expect([0, 3, 6, 9]).toContain(startDate.getMonth());
      expect(startDate.getDate()).toBe(1);
    });

    it('should return correct yearly date range', () => {
      const { startDate, endDate } = service.getPeriodDateRange('yearly');

      expect(startDate.getMonth()).toBe(0);
      expect(startDate.getDate()).toBe(1);
      expect(endDate.getMonth()).toBe(11);
      expect(endDate.getDate()).toBe(31);
    });
  });
});

describe('Forecast Edge Cases', () => {
  let service: ForecastingService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new ForecastingService({
      forecastRepository: mockForecastRepo as any,
      dealRepository: mockDealRepo as any,
      stageRepository: mockStageRepo as any,
      auditLogService: mockAuditService as any,
    });
  });

  it('should handle empty deal pipeline gracefully', async () => {
    const forecast = createTestForecast();

    mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
    mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: [] } });
    mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: [] });
    mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
    mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

    const result = await service.calculateForecast(testContext, {
      period: 'monthly',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    });

    expect(result.success).toBe(true);

    const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
    const updateData = updateCall[2];

    expect(updateData.projectedRevenue).toBe(0);
    expect(updateData.bestCase).toBe(0);
    expect(updateData.committed).toBe(0);
    expect(updateData.closed).toBe(0);
    expect(updateData.stageBreakdown).toHaveLength(0);
  });

  it('should use default probability for unknown stages', async () => {
    const stages: Stage[] = []; // No stages defined
    const deals = [
      createTestDeal({ stageId: 'unknown-stage', valueCents: 10000 }),
    ];

    const forecast = createTestForecast();

    mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
    mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
    mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
    mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
    mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

    await service.calculateForecast(testContext, {
      period: 'monthly',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    });

    const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
    const stageBreakdown = updateCall[2].stageBreakdown;

    // Should use default 50% probability for unknown stage
    expect(stageBreakdown[0].probability).toBe(50);
    expect(stageBreakdown[0].weightedValueCents).toBe(5000); // 10000 * 0.5
  });

  it('should exclude won/lost deals from open metrics', async () => {
    const stages = [createTestStage()];
    const deals = [
      createTestDeal({ id: 'open-1', status: 'open', valueCents: 10000 }),
      createTestDeal({ id: 'won-1', status: 'won', valueCents: 20000 }),
      createTestDeal({ id: 'lost-1', status: 'lost', valueCents: 30000 }),
    ];

    const forecast = createTestForecast();

    mockForecastRepo.getCurrentForecast.mockResolvedValue({ success: true, data: forecast });
    mockStageRepo.getAll.mockResolvedValue({ success: true, data: { data: stages } });
    mockDealRepo.getByStatus.mockResolvedValue({ success: true, data: deals });
    mockDealRepo.getWonInRange.mockResolvedValue({ success: true, data: [] });
    mockForecastRepo.updateCalculations.mockResolvedValue({ success: true, data: forecast });

    await service.calculateForecast(testContext, {
      period: 'monthly',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    });

    const updateCall = mockForecastRepo.updateCalculations.mock.calls[0];
    const updateData = updateCall[2];

    // Only open deals count toward best case
    expect(updateData.bestCase).toBe(10000);
  });
});
