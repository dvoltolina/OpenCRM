/**
 * Forecast Repository
 * Manages revenue forecasts with RBAC and calculation updates
 *
 * HIPAA Compliance:
 * - Forecasts contain no PHI (deal values, counts only)
 * - Rep names in forecasts are internal staff, not clients
 * - All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
  WhereClause,
} from './repository-types';
import {
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId, generateId } from './firestore-utils';
import type {
  Forecast,
  GoalPeriod,
  ForecastStageBreakdown,
  ForecastRepBreakdown,
} from '../../types/goals';

// ============================================
// Validation
// ============================================

const VALID_PERIODS: GoalPeriod[] = ['weekly', 'monthly', 'quarterly', 'yearly'];

const forecastValidator: Validator<Forecast> = (data: Partial<Forecast>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.period !== undefined && !VALID_PERIODS.includes(data.period)) {
    errors.push({
      field: 'period',
      message: `Invalid period. Must be one of: ${VALID_PERIODS.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.startDate && data.endDate && data.startDate > data.endDate) {
    errors.push({
      field: 'endDate',
      message: 'End date must be after start date',
      code: 'INVALID_VALUE',
    });
  }

  if (data.projectedRevenue !== undefined && data.projectedRevenue < 0) {
    errors.push({
      field: 'projectedRevenue',
      message: 'Projected revenue must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  if (data.bestCase !== undefined && data.bestCase < 0) {
    errors.push({
      field: 'bestCase',
      message: 'Best case must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  if (data.committed !== undefined && data.committed < 0) {
    errors.push({
      field: 'committed',
      message: 'Committed must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  if (data.closed !== undefined && data.closed < 0) {
    errors.push({
      field: 'closed',
      message: 'Closed must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Forecast Repository
// ============================================

/**
 * Forecast Repository
 * Handles CRUD operations for revenue forecasts with RBAC
 */
export class ForecastRepository extends ShareableRepository<Forecast> {
  protected entityName = 'forecast';
  protected sensitiveFields: Array<keyof Forecast> = [];

  constructor() {
    super({ collectionName: 'forecasts' });
    this.setValidator(forecastValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get the current forecast for a period, optionally filtered by pipeline
   * Creates one if it doesn't exist
   */
  async getCurrentForecast(
    context: SecurityContext,
    period: GoalPeriod,
    pipelineId?: string
  ): Promise<RepositoryResult<Forecast>> {
    try {
      const now = new Date();
      const { startDate, endDate } = this.getPeriodDates(now, period);

      // Try to find existing forecast
      const existingResult = await this.findForecast(context, period, startDate, pipelineId);
      if (existingResult.success && existingResult.data) {
        return successResult(existingResult.data);
      }

      // Create new forecast if not found
      const newForecast: Omit<Forecast, 'id' | 'createdAt' | 'updatedAt'> = {
        period,
        startDate,
        endDate,
        pipelineId,
        teamIds: context.teamIds || [],
        projectedRevenue: 0,
        bestCase: 0,
        committed: 0,
        closed: 0,
        stageBreakdown: [],
        lastCalculatedAt: now,
        ownerId: context.userId,
        ownerName: context.userName,
        visibility: 'team',
      };

      const customId = this.buildForecastId(period, startDate, pipelineId);
      return this.create(context, newForecast, customId);
    } catch (error) {
      return failedResult(error, 'Failed to get current forecast');
    }
  }

  /**
   * Find an existing forecast for a period and optional pipeline
   */
  async findForecast(
    context: SecurityContext,
    period: GoalPeriod,
    startDate: Date,
    pipelineId?: string
  ): Promise<RepositoryResult<Forecast | null>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const whereConditions: WhereClause[] = [
        { field: 'period', operator: '==' as const, value: period },
        { field: 'startDate', operator: '==' as const, value: Timestamp.fromDate(startDate) },
      ];

      if (pipelineId) {
        whereConditions.push({ field: 'pipelineId', operator: '==' as const, value: pipelineId });
      }

      const q = buildQuery(collectionRef, {
        where: whereConditions,
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const forecasts = this.filterAccessibleForecasts(context, this.snapshotToForecasts(snapshot));
      return successResult(forecasts[0] || null);
    } catch (error) {
      return failedResult(error, 'Failed to find forecast');
    }
  }

  /**
   * Get forecasts for a date range
   */
  async getByDateRange(
    context: SecurityContext,
    startDate: Date,
    endDate: Date,
    pipelineId?: string
  ): Promise<RepositoryResult<Forecast[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const whereConditions: WhereClause[] = [
        { field: 'startDate', operator: '>=' as const, value: Timestamp.fromDate(startDate) },
        { field: 'endDate', operator: '<=' as const, value: Timestamp.fromDate(endDate) },
      ];

      if (pipelineId) {
        whereConditions.push({ field: 'pipelineId', operator: '==' as const, value: pipelineId });
      }

      const q = buildQuery(collectionRef, {
        where: whereConditions,
        orderBy: { field: 'startDate', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const forecasts = this.filterAccessibleForecasts(context, this.snapshotToForecasts(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByDateRange',
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        pipelineId,
        count: forecasts.length,
      });

      return successResult(forecasts);
    } catch (error) {
      return failedResult(error, 'Failed to get forecasts by date range');
    }
  }

  /**
   * Get forecasts by pipeline
   */
  async getByPipeline(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<Forecast[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'pipelineId', operator: '==', value: pipelineId }],
        orderBy: { field: 'startDate', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const forecasts = this.filterAccessibleForecasts(context, this.snapshotToForecasts(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByPipeline',
        pipelineId,
        count: forecasts.length,
      });

      return successResult(forecasts);
    } catch (error) {
      return failedResult(error, 'Failed to get forecasts by pipeline');
    }
  }

  // ============================================
  // Calculation Updates
  // ============================================

  /**
   * Update forecast calculations
   */
  async updateCalculations(
    context: SecurityContext,
    forecastId: string,
    data: {
      projectedRevenue: number;
      bestCase: number;
      committed: number;
      closed: number;
      stageBreakdown: ForecastStageBreakdown[];
      repBreakdown?: ForecastRepBreakdown[];
    }
  ): Promise<RepositoryResult<Forecast>> {
    try {
      if (!isValidDocumentId(forecastId)) {
        return failedResult(new InvalidArgumentError('Invalid forecast ID', 'forecastId'));
      }

      const updateData: Partial<Forecast> = {
        projectedRevenue: data.projectedRevenue,
        bestCase: data.bestCase,
        committed: data.committed,
        closed: data.closed,
        stageBreakdown: data.stageBreakdown,
        repBreakdown: data.repBreakdown,
        lastCalculatedAt: new Date(),
      };

      const result = await this.update(context, forecastId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', forecastId, {
          action: 'updateCalculations',
          projectedRevenue: data.projectedRevenue,
          bestCase: data.bestCase,
          committed: data.committed,
          closed: data.closed,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update forecast calculations');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleForecasts(context: SecurityContext, forecasts: Forecast[]): Forecast[] {
    return filterAuthorizedEntities(context, forecasts, this.sensitiveFields);
  }

  /**
   * Build a deterministic forecast ID based on period and start date
   */
  private buildForecastId(period: GoalPeriod, startDate: Date, pipelineId?: string): string {
    const dateStr = startDate.toISOString().split('T')[0];
    const base = `${period}-${dateStr}`;
    return pipelineId ? `${base}-${pipelineId}` : `${base}-${generateId().slice(0, 8)}`;
  }

  /**
   * Get period start and end dates based on current date
   */
  private getPeriodDates(date: Date, period: GoalPeriod): { startDate: Date; endDate: Date } {
    const start = new Date(date);
    const end = new Date(date);

    switch (period) {
      case 'weekly':
        // Start of week (Sunday)
        start.setDate(start.getDate() - start.getDay());
        end.setDate(start.getDate() + 6);
        break;
      case 'monthly':
        start.setDate(1);
        end.setMonth(end.getMonth() + 1);
        end.setDate(0); // Last day of current month
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

    // Reset time components
    start.setHours(0, 0, 0, 0);
    end.setHours(23, 59, 59, 999);

    return { startDate: start, endDate: end };
  }

  /**
   * Convert Firestore snapshot to Forecast array
   */
  private snapshotToForecasts(snapshot: QuerySnapshot<DocumentData>): Forecast[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        period: data.period as GoalPeriod,
        startDate: data.startDate?.toDate?.() || data.startDate,
        endDate: data.endDate?.toDate?.() || data.endDate,
        pipelineId: data.pipelineId as string | undefined,
        ownerId: data.ownerId as string | undefined,
        teamIds: (data.teamIds as string[]) || [],
        projectedRevenue: data.projectedRevenue as number,
        bestCase: data.bestCase as number,
        committed: data.committed as number,
        closed: data.closed as number,
        stageBreakdown: (data.stageBreakdown as ForecastStageBreakdown[]) || [],
        repBreakdown: data.repBreakdown as ForecastRepBreakdown[] | undefined,
        lastCalculatedAt: data.lastCalculatedAt?.toDate?.() || data.lastCalculatedAt,
        ownerName: data.ownerName as string | undefined,
        visibility: data.visibility || 'team',
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let forecastRepository: ForecastRepository | null = null;

export function getForecastRepository(): ForecastRepository {
  if (!forecastRepository) {
    forecastRepository = new ForecastRepository();
  }
  return forecastRepository;
}
