/**
 * Deal Rotting Service
 * Identifies deals without recent activity and calculates rotting status
 *
 * Agent CRM-41 Implementation
 * Dependencies: CRM-09 (Deal hooks), CRM-20 (Settings)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { getDealRepository } from '../data/repositories/deal-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import { getSettingsRepository } from '../data/repositories/settings-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Deal, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

/**
 * Configuration for deal rotting detection
 */
export interface RottingConfig {
  /** Whether rotting detection is enabled */
  enabled: boolean;
  /** Days without activity before a deal is considered rotting */
  thresholdDays: number;
  /** Days before threshold to show warning (optional, defaults to threshold/2) */
  warningDays?: number;
}

/**
 * Status of a deal regarding rotting
 */
export interface DealRottingStatus {
  /** ID of the deal */
  dealId: string;
  /** Whether the deal is rotting (past threshold) */
  isRotting: boolean;
  /** Whether the deal is in warning zone (approaching threshold) */
  isWarning: boolean;
  /** Number of days since last activity */
  daysSinceActivity: number;
  /** Date of most recent activity (or deal creation if no activities) */
  lastActivityDate: Date | null;
  /** Days remaining until deal becomes rotting (negative if already rotting) */
  daysUntilRotting: number;
}

/**
 * Deal with rotting status attached
 */
export interface DealWithRottingStatus extends Deal {
  rottingStatus: DealRottingStatus;
}

export interface RottingServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// Deal Rotting Service
// ============================================

export class DealRottingService {
  /**
   * Get the last activity date for a deal
   * Returns the deal creation date if no activities exist
   */
  async getLastActivityDate(
    _context: SecurityContext,
    dealId: string,
    dealCreatedAt: Date
  ): Promise<Date> {
    const activityRepo = getActivityRepository();
    const result = await activityRepo.getByDeal(_context, dealId);

    if (!result.success || result.data.data.length === 0) {
      // No activities - use deal creation date
      return dealCreatedAt;
    }

    // Find the most recent activity
    const activities = result.data.data;
    const mostRecent = activities.reduce((latest: SalesActivity, current: SalesActivity) => {
      return current.createdAt > latest.createdAt ? current : latest;
    });

    return mostRecent.createdAt;
  }

  /**
   * Calculate days between two dates
   */
  private calculateDaysBetween(from: Date, to: Date): number {
    const msPerDay = 1000 * 60 * 60 * 24;
    const diffMs = to.getTime() - from.getTime();
    return Math.floor(diffMs / msPerDay);
  }

  /**
   * Check the rotting status of a single deal
   */
  async checkDealRotting(
    _context: SecurityContext,
    deal: Deal,
    activities: SalesActivity[],
    config: RottingConfig
  ): Promise<DealRottingStatus> {
    // If rotting detection is disabled, return normal status
    if (!config.enabled) {
      return {
        dealId: deal.id,
        isRotting: false,
        isWarning: false,
        daysSinceActivity: 0,
        lastActivityDate: null,
        daysUntilRotting: 0,
      };
    }

    // Closed deals (won or lost) should not be marked as rotting
    if (deal.status === 'won' || deal.status === 'lost') {
      return {
        dealId: deal.id,
        isRotting: false,
        isWarning: false,
        daysSinceActivity: 0,
        lastActivityDate: deal.closedAt || null,
        daysUntilRotting: 0,
      };
    }

    // Find the most recent activity date
    let lastActivityDate: Date;
    if (activities.length === 0) {
      // No activities - use deal creation date
      lastActivityDate = deal.createdAt;
    } else {
      // Find the most recent activity
      const mostRecent = activities.reduce((latest, current) => {
        return current.createdAt > latest.createdAt ? current : latest;
      });
      lastActivityDate = mostRecent.createdAt;
    }

    // Calculate days since last activity
    const now = new Date();
    const daysSinceActivity = this.calculateDaysBetween(lastActivityDate, now);

    // Determine warning threshold (default to half of rotting threshold)
    const warningDays = config.warningDays ?? Math.floor(config.thresholdDays / 2);

    // Determine status
    const isRotting = daysSinceActivity >= config.thresholdDays;
    const isWarning = !isRotting && daysSinceActivity >= warningDays;
    const daysUntilRotting = config.thresholdDays - daysSinceActivity;

    return {
      dealId: deal.id,
      isRotting,
      isWarning,
      daysSinceActivity,
      lastActivityDate,
      daysUntilRotting,
    };
  }

  /**
   * Get all rotting deals for a business
   * Returns only deals that are past the threshold
   */
  async getRottingDeals(
    context: SecurityContext
  ): Promise<RottingServiceResult<DealWithRottingStatus[]>> {
    try {
      // Get current settings
      const settingsRepo = getSettingsRepository();
      const settingsResult = await settingsRepo.getSettings(context);

      if (!settingsResult.success) {
        return {
          success: false,
          error: {
            code: 'SETTINGS_ERROR',
            message: 'Failed to load settings',
          },
        };
      }

      const config = settingsResult.data.dealRotting;

      // If rotting detection is disabled, return empty array
      if (!config?.enabled) {
        return {
          success: true,
          data: [],
        };
      }

      // Get all open deals
      const dealRepo = getDealRepository();
      const dealsResult = await dealRepo.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit: 1000, // Reasonable limit
      });

      if (!dealsResult.success) {
        return {
          success: false,
          error: {
            code: 'DEALS_ERROR',
            message: 'Failed to load deals',
          },
        };
      }

      // Filter to open deals only
      const openDeals = dealsResult.data.data.filter((deal: Deal) => deal.status === 'open');

      // Get activities for each deal and check rotting status
      const activityRepo = getActivityRepository();
      const dealsWithStatus: DealWithRottingStatus[] = [];

      for (const deal of openDeals) {
        // Get activities for this deal
        const activitiesResult = await activityRepo.getByDeal(context, deal.id);
        const activities = activitiesResult.success ? activitiesResult.data.data : [];

        // Check rotting status
        const status = await this.checkDealRotting(context, deal, activities, config);

        // Only include if rotting
        if (status.isRotting) {
          dealsWithStatus.push({
            ...deal,
            rottingStatus: status,
          });
        }
      }

      // Sort by days since activity (most stale first)
      dealsWithStatus.sort((a, b) => {
        return b.rottingStatus.daysSinceActivity - a.rottingStatus.daysSinceActivity;
      });

      return {
        success: true,
        data: dealsWithStatus,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get rotting deals',
        },
      };
    }
  }

  /**
   * Get deals in the warning zone (approaching rotting)
   * Returns deals that are between warning threshold and rotting threshold
   */
  async getAtRiskDeals(
    context: SecurityContext
  ): Promise<RottingServiceResult<DealWithRottingStatus[]>> {
    try {
      // Get current settings
      const settingsRepo = getSettingsRepository();
      const settingsResult = await settingsRepo.getSettings(context);

      if (!settingsResult.success) {
        return {
          success: false,
          error: {
            code: 'SETTINGS_ERROR',
            message: 'Failed to load settings',
          },
        };
      }

      const config = settingsResult.data.dealRotting;

      // If rotting detection is disabled, return empty array
      if (!config?.enabled) {
        return {
          success: true,
          data: [],
        };
      }

      // Get all open deals
      const dealRepo = getDealRepository();
      const dealsResult = await dealRepo.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit: 1000,
      });

      if (!dealsResult.success) {
        return {
          success: false,
          error: {
            code: 'DEALS_ERROR',
            message: 'Failed to load deals',
          },
        };
      }

      // Filter to open deals only
      const openDeals = dealsResult.data.data.filter((deal: Deal) => deal.status === 'open');

      // Get activities for each deal and check rotting status
      const activityRepo = getActivityRepository();
      const dealsWithStatus: DealWithRottingStatus[] = [];

      for (const deal of openDeals) {
        // Get activities for this deal
        const activitiesResult = await activityRepo.getByDeal(context, deal.id);
        const activities = activitiesResult.success ? activitiesResult.data.data : [];

        // Check rotting status
        const status = await this.checkDealRotting(context, deal, activities, config);

        // Only include if in warning zone
        if (status.isWarning) {
          dealsWithStatus.push({
            ...deal,
            rottingStatus: status,
          });
        }
      }

      // Sort by days since activity (most stale first)
      dealsWithStatus.sort((a, b) => {
        return b.rottingStatus.daysSinceActivity - a.rottingStatus.daysSinceActivity;
      });

      return {
        success: true,
        data: dealsWithStatus,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get at-risk deals',
        },
      };
    }
  }

  /**
   * Get rotting status for a specific deal
   */
  async getDealRottingStatus(
    context: SecurityContext,
    dealId: string
  ): Promise<RottingServiceResult<DealRottingStatus>> {
    try {
      // Get settings
      const settingsRepo = getSettingsRepository();
      const settingsResult = await settingsRepo.getSettings(context);

      if (!settingsResult.success) {
        return {
          success: false,
          error: {
            code: 'SETTINGS_ERROR',
            message: 'Failed to load settings',
          },
        };
      }

      const config = settingsResult.data.dealRotting;

      // Get the deal
      const dealRepo = getDealRepository();
      const dealResult = await dealRepo.getById(context, dealId);

      if (!dealResult.success) {
        return {
          success: false,
          error: {
            code: 'DEAL_NOT_FOUND',
            message: 'Deal not found',
          },
        };
      }

      const deal = dealResult.data;

      // Get activities
      const activityRepo = getActivityRepository();
      const activitiesResult = await activityRepo.getByDeal(context, dealId);
      const activities = activitiesResult.success ? activitiesResult.data.data : [];

      // Check rotting status
      const status = await this.checkDealRotting(context, deal, activities, config!);

      return {
        success: true,
        data: status,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get deal rotting status',
        },
      };
    }
  }

  /**
   * Get combined rotting and at-risk deals
   */
  async getAllStaleDeals(
    context: SecurityContext
  ): Promise<RottingServiceResult<{ rotting: DealWithRottingStatus[]; atRisk: DealWithRottingStatus[] }>> {
    try {
      const [rottingResult, atRiskResult] = await Promise.all([
        this.getRottingDeals(context),
        this.getAtRiskDeals(context),
      ]);

      if (!rottingResult.success || !atRiskResult.success) {
        return {
          success: false,
          error: {
            code: 'LOAD_ERROR',
            message: 'Failed to load stale deals',
          },
        };
      }

      return {
        success: true,
        data: {
          rotting: rottingResult.data || [],
          atRisk: atRiskResult.data || [],
        },
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get stale deals',
        },
      };
    }
  }
}

// ============================================
// Singleton Export
// ============================================

let dealRottingServiceInstance: DealRottingService | null = null;

export function getDealRottingService(): DealRottingService {
  if (!dealRottingServiceInstance) {
    dealRottingServiceInstance = new DealRottingService();
  }
  return dealRottingServiceInstance;
}

// For testing - reset instance
export function resetDealRottingService(): void {
  dealRottingServiceInstance = null;
}
