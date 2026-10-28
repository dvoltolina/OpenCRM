/**
 * Forecasting Service
 * Business logic for revenue forecasting using weighted pipeline analysis
 *
 * HIPAA Compliance Notes:
 * - Forecasts contain no PHI (deal values, counts only)
 * - Rep names are internal staff, not client data
 * - Audit logs include IDs only, no names/notes
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getForecastRepository,
  getDealRepository,
  getStageRepository,
} from '../data/repositories';
import type {
  ForecastRepository,
  DealRepository,
  StageRepository,
} from '../data/repositories';
import type { Deal, Stage } from '../types/models';
import type {
  Forecast,
  GoalPeriod,
  ForecastStageBreakdown,
  ForecastRepBreakdown,
  ForecastSummary,
  ForecastCalculationOptions,
} from '../types/goals';
import { AuditLogService } from './AuditLogService';

// ============================================
// Constants
// ============================================

/** Probability threshold for "committed" deals (high confidence) */
const COMMITTED_THRESHOLD = 80;

// ============================================
// Types
// ============================================

export interface ForecastServiceDependencies {
  forecastRepository?: ForecastRepository;
  dealRepository?: DealRepository;
  stageRepository?: StageRepository;
  auditLogService?: AuditLogService;
}

// ============================================
// Forecasting Service
// ============================================

export class ForecastingService {
  private readonly forecastRepo: ForecastRepository;
  private readonly dealRepo: DealRepository;
  private readonly stageRepo: StageRepository;
  private readonly auditService: AuditLogService;

  constructor(dependencies: ForecastServiceDependencies = {}) {
    this.forecastRepo = dependencies.forecastRepository ?? getForecastRepository();
    this.dealRepo = dependencies.dealRepository ?? getDealRepository();
    this.stageRepo = dependencies.stageRepository ?? getStageRepository();
    this.auditService = dependencies.auditLogService ?? new AuditLogService();
  }

  // ============================================
  // Forecast Calculation
  // ============================================

  /**
   * Calculate and update forecast for a period
   */
  async calculateForecast(
    context: SecurityContext,
    options: ForecastCalculationOptions
  ): Promise<{ success: boolean; data: Forecast | null; error?: Error }> {
    try {
      const { period, startDate, endDate, pipelineId, ownerId, teamIds } = options;

      // Get or create forecast
      const forecastResult = await this.forecastRepo.getCurrentForecast(
        context,
        period,
        pipelineId
      );

      if (!forecastResult.success) {
        return { success: false, data: null, error: new Error(forecastResult.error?.message || 'Failed to get forecast') };
      }

      const forecastId = forecastResult.data.id;

      // Get stages for the pipeline (with probabilities)
      const stagesResult = pipelineId
        ? await this.stageRepo.getByPipeline(context, pipelineId)
        : await this.stageRepo.getAll(context);

      if (!stagesResult.success) {
        return { success: false, data: null, error: new Error('Failed to fetch stages') };
      }

      const stages = stagesResult.success
        ? ('data' in stagesResult.data ? stagesResult.data.data : stagesResult.data)
        : [];

      // Get open deals for the period
      const dealsResult = await this.getDealsForForecast(
        context,
        startDate,
        endDate,
        pipelineId,
        ownerId,
        teamIds
      );

      if (!dealsResult.success) {
        return { success: false, data: null, error: dealsResult.error };
      }

      const deals = dealsResult.data;

      // Calculate stage breakdown
      const stageBreakdown = this.calculateStageBreakdown(deals, stages);

      // Calculate rep breakdown if applicable
      const repBreakdown = this.calculateRepBreakdown(deals);

      // Calculate summary metrics
      const projectedRevenue = stageBreakdown.reduce(
        (sum, stage) => sum + stage.weightedValueCents,
        0
      );

      const bestCase = deals
        .filter((d) => d.status === 'open')
        .reduce((sum, d) => sum + d.valueCents, 0);

      const committed = deals
        .filter((d) => d.status === 'open' && d.probability >= COMMITTED_THRESHOLD)
        .reduce((sum, d) => sum + d.valueCents, 0);

      const closed = deals
        .filter((d) => d.status === 'won')
        .reduce((sum, d) => sum + d.valueCents, 0);

      // Update forecast with calculated values
      const updateResult = await this.forecastRepo.updateCalculations(context, forecastId, {
        projectedRevenue,
        bestCase,
        committed,
        closed,
        stageBreakdown,
        repBreakdown,
      });

      if (updateResult.success) {
        await this.auditService.logAction(context, {
          action: 'update',
          entityType: 'report',
          entityId: forecastId,
          metadata: {
            period,
            pipelineId,
            dealCount: deals.length,
            projectedRevenue,
            bestCase,
            committed,
            closed,
          },
        });
      }

      return {
        success: updateResult.success,
        data: updateResult.success ? updateResult.data : null,
        error: updateResult.success ? undefined : new Error(updateResult.error?.message || 'Failed to update forecast'),
      };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  /**
   * Get forecast summary with analysis
   */
  async getForecastSummary(
    context: SecurityContext,
    period: GoalPeriod,
    pipelineId?: string,
    targetRevenue?: number
  ): Promise<{ success: boolean; data: ForecastSummary | null; error?: Error }> {
    try {
      // Get or calculate current forecast
      const forecastResult = await this.forecastRepo.getCurrentForecast(
        context,
        period,
        pipelineId
      );

      if (!forecastResult.success) {
        return { success: false, data: null, error: new Error(forecastResult.error?.message || 'Failed to get forecast') };
      }

      const forecast = forecastResult.data;
      const target = targetRevenue ?? forecast.projectedRevenue;

      // Calculate commitment ratio
      const commitmentRatio = target > 0 ? (forecast.committed / target) * 100 : 0;

      // Calculate gap to target (negative means ahead of target)
      const gapToTarget = target - (forecast.closed + forecast.projectedRevenue);

      // Calculate confidence level based on stage distribution
      const confidenceLevel = this.calculateConfidenceLevel(forecast);

      // Determine if on track to meet target
      const isOnTrack = gapToTarget <= 0;

      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'report',
        entityId: forecast.id,
        metadata: {
          period,
          pipelineId,
          commitmentRatio,
          confidenceLevel,
          isOnTrack,
        },
      });

      return {
        success: true,
        data: {
          forecast,
          commitmentRatio,
          gapToTarget,
          confidenceLevel,
          isOnTrack,
        },
      };
    } catch (error) {
      return { success: false, data: null, error: error as Error };
    }
  }

  /**
   * Get historical forecasts for trend analysis
   */
  async getForecastHistory(
    context: SecurityContext,
    periods: number,
    periodType: GoalPeriod,
    pipelineId?: string
  ): Promise<{ success: boolean; data: Forecast[] | null; error?: Error }> {
    try {
      const now = new Date();
      const startDate = this.getHistoricalStartDate(now, periods, periodType);

      const result = await this.forecastRepo.getByDateRange(
        context,
        startDate,
        now,
        pipelineId
      );

      if (result.success) {
        await this.auditService.logAction(context, {
          action: 'read',
          entityType: 'report',
          entityId: 'forecastHistory',
          metadata: {
            periods,
            periodType,
            pipelineId,
            count: result.data.length,
          },
        });
      }

      return {
        success: result.success,
        data: result.success ? result.data : [],
        error: result.success ? undefined : new Error(result.error?.message || 'Failed to get forecasts'),
      };
    } catch (error) {
      return { success: false, data: [], error: error as Error };
    }
  }

  // ============================================
  // Private Calculation Methods
  // ============================================

  /**
   * Get deals for forecast calculation
   */
  private async getDealsForForecast(
    context: SecurityContext,
    startDate: Date,
    endDate: Date,
    pipelineId?: string,
    ownerId?: string,
    __teamIds?: string[]
  ): Promise<{ success: boolean; data: Deal[]; error?: Error }> {
    try {
      // Get open deals
      const openResult = await this.dealRepo.getByStatus(context, 'open');
      if (!openResult.success) {
        return { success: false, data: [], error: openResult.error ? new Error(openResult.error.message) : new Error('Unknown error') };
      }

      // Get won deals in period
      const wonDealsResult = await this.dealRepo.getByStatus(context, 'won');
      const wonDeals = wonDealsResult.success ? wonDealsResult.data.filter((deal) => {
        const closedAt = deal.closedAt;
        if (!closedAt) return false;
        return closedAt >= startDate && closedAt <= endDate;
      }) : [];

      let deals = [...openResult.data, ...wonDeals];

      // Filter by pipeline if specified
      if (pipelineId) {
        deals = deals.filter((d) => d.pipelineId === pipelineId);
      }

      // Filter by owner if specified
      if (ownerId) {
        deals = deals.filter((d) => d.ownerId === ownerId);
      }

      return { success: true, data: deals };
    } catch (error) {
      return { success: false, data: [], error: error as Error };
    }
  }

  /**
   * Calculate breakdown by stage
   */
  private calculateStageBreakdown(deals: Deal[], stages: Stage[]): ForecastStageBreakdown[] {
    const stageMap = new Map<string, Stage>();
    stages.forEach((s) => stageMap.set(s.id, s));

    // Group deals by stage
    const dealsByStage = new Map<string, Deal[]>();
    deals.forEach((deal) => {
      if (deal.status !== 'open') return; // Only count open deals
      const existing = dealsByStage.get(deal.stageId) || [];
      existing.push(deal);
      dealsByStage.set(deal.stageId, existing);
    });

    // Build breakdown
    const breakdown: ForecastStageBreakdown[] = [];
    dealsByStage.forEach((stageDeals, stageId) => {
      const stage = stageMap.get(stageId);
      const probability = stage?.probability ?? 50; // Default to 50% if unknown
      const totalValueCents = stageDeals.reduce((sum, d) => sum + d.valueCents, 0);
      const weightedValueCents = Math.round((totalValueCents * probability) / 100);

      breakdown.push({
        stageId,
        stageName: stage?.name || 'Unknown',
        probability,
        dealCount: stageDeals.length,
        totalValueCents,
        weightedValueCents,
      });
    });

    // Sort by stage order
    breakdown.sort((a, b) => {
      const stageA = stageMap.get(a.stageId);
      const stageB = stageMap.get(b.stageId);
      return (stageA?.order ?? 0) - (stageB?.order ?? 0);
    });

    return breakdown;
  }

  /**
   * Calculate breakdown by sales rep
   */
  private calculateRepBreakdown(deals: Deal[]): ForecastRepBreakdown[] {
    const repMap = new Map<string, { userId: string; userName: string; deals: Deal[] }>();

    deals.forEach((deal) => {
      if (deal.status !== 'open') return;
      if (!deal.assigneeId) return;

      const existing = repMap.get(deal.assigneeId);
      if (existing) {
        existing.deals.push(deal);
      } else {
        repMap.set(deal.assigneeId, {
          userId: deal.assigneeId,
          userName: deal.assigneeName || 'Unknown',
          deals: [deal],
        });
      }
    });

    const breakdown: ForecastRepBreakdown[] = [];
    repMap.forEach(({ userId, userName, deals: repDeals }) => {
      // Calculate weighted revenue for rep
      const projectedRevenue = repDeals.reduce((sum, d) => {
        return sum + Math.round((d.valueCents * d.probability) / 100);
      }, 0);

      breakdown.push({
        userId,
        userName,
        projectedRevenue,
        dealCount: repDeals.length,
      });
    });

    // Sort by projected revenue descending
    breakdown.sort((a, b) => b.projectedRevenue - a.projectedRevenue);

    return breakdown;
  }

  /**
   * Calculate confidence level based on stage distribution
   */
  private calculateConfidenceLevel(forecast: Forecast): 'high' | 'medium' | 'low' {
    const { stageBreakdown, committed, projectedRevenue } = forecast;

    // High confidence if most value is committed
    if (projectedRevenue > 0 && committed / projectedRevenue >= 0.7) {
      return 'high';
    }

    // Check stage distribution
    const highProbStages = stageBreakdown.filter((s) => s.probability >= 60);
    const highProbValue = highProbStages.reduce((sum, s) => sum + s.totalValueCents, 0);

    if (projectedRevenue > 0 && highProbValue / projectedRevenue >= 0.5) {
      return 'medium';
    }

    return 'low';
  }

  /**
   * Get historical start date for trend analysis
   */
  private getHistoricalStartDate(now: Date, periods: number, periodType: GoalPeriod): Date {
    const start = new Date(now);

    switch (periodType) {
      case 'weekly':
        start.setDate(start.getDate() - periods * 7);
        break;
      case 'monthly':
        start.setMonth(start.getMonth() - periods);
        break;
      case 'quarterly':
        start.setMonth(start.getMonth() - periods * 3);
        break;
      case 'yearly':
        start.setFullYear(start.getFullYear() - periods);
        break;
    }

    return start;
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
let forecastingServiceInstance: ForecastingService | null = null;

export function getForecastingService(): ForecastingService {
  if (!forecastingServiceInstance) {
    forecastingServiceInstance = new ForecastingService();
  }
  return forecastingServiceInstance;
}
