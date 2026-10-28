/**
 * Goals, Quotas & Forecasting Types
 * Enables sales managers to set goals/quotas and forecast revenue
 *
 * HIPAA Compliance Notes:
 * - Goals and forecasts contain no PHI (deal values, counts only)
 * - Rep names in forecasts are internal staff, not clients
 * - Audit log goal creation/updates with IDs only
 */

import type { ShareableFields, Visibility } from './models';

// ============================================
// Goal Period & Metric Types
// ============================================

/** Time period for goals and forecasts */
export type GoalPeriod = 'weekly' | 'monthly' | 'quarterly' | 'yearly';

/** Metrics that can be tracked as goals */
export type GoalMetric =
  | 'revenue'
  | 'deals_won'
  | 'deals_created'
  | 'activities_completed'
  | 'calls_made'
  | 'emails_sent';

/** Goal status lifecycle */
export type GoalStatus = 'active' | 'achieved' | 'missed' | 'cancelled';

/** Who the goal is assigned to */
export type GoalAssigneeType = 'user' | 'team' | 'business';

// ============================================
// Goal Interface
// ============================================

/**
 * Goal/Quota entity
 * Path: businesses/{businessId}/goals/{goalId}
 */
export interface Goal extends ShareableFields {
  id: string;

  // What this goal measures
  metric: GoalMetric;
  /** Target value in cents for revenue, count for others */
  targetValue: number;

  // Time period
  period: GoalPeriod;
  startDate: Date;
  endDate: Date;

  // Who this goal is for
  assigneeType: GoalAssigneeType;
  /** userId, teamId, or businessId */
  assigneeId: string;
  assigneeName: string;

  // Optional filters
  /** Only count deals from this pipeline */
  pipelineId?: string;

  // Progress tracking (denormalized, updated by scheduled job)
  currentValue: number;
  /** Progress as percentage 0-100 */
  progressPercent: number;
  lastCalculatedAt: Date;

  // Status
  status: GoalStatus;

  // Ownership (from ShareableFields)
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  visibility: Visibility;

  // Audit
  createdById: string;
  createdByName: string;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Forecast Interface
// ============================================

/**
 * Stage breakdown for forecast calculations
 */
export interface ForecastStageBreakdown {
  stageId: string;
  stageName: string;
  /** Stage probability 0-100 */
  probability: number;
  dealCount: number;
  /** Total value of deals at this stage in cents */
  totalValueCents: number;
  /** Weighted value (totalValueCents * probability / 100) */
  weightedValueCents: number;
}

/**
 * Rep breakdown for team/business forecasts
 */
export interface ForecastRepBreakdown {
  userId: string;
  userName: string;
  /** Projected revenue (weighted) in cents */
  projectedRevenue: number;
  dealCount: number;
}

/**
 * Forecast entity
 * Path: businesses/{businessId}/forecasts/{forecastId}
 */
export interface Forecast extends ShareableFields {
  id: string;

  // Forecast period
  period: GoalPeriod;
  startDate: Date;
  endDate: Date;

  // Scope filters
  pipelineId?: string;
  /** Filter by deal owner */
  ownerId?: string;
  teamIds: string[];

  // Calculated values (updated by scheduled job)
  /** Sum of (deal value * stage probability) in cents */
  projectedRevenue: number;
  /** Sum of all open deal values in cents */
  bestCase: number;
  /** Sum of deals in final stages (>80% probability) in cents */
  committed: number;
  /** Sum of already-won deals in period in cents */
  closed: number;

  // Breakdown by stage
  stageBreakdown: ForecastStageBreakdown[];

  // Breakdown by rep (if team/business scope)
  repBreakdown?: ForecastRepBreakdown[];

  // Calculation metadata
  lastCalculatedAt: Date;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Stage Probability Extension
// ============================================

/**
 * Extended stage interface with probability
 * Used for forecast calculations
 */
export interface StageWithProbability {
  id: string;
  name: string;
  order: number;
  /** Win probability 0-100, default based on position */
  probability: number;
}

// ============================================
// Goal Creation/Update DTOs
// ============================================

/** Data required to create a new goal */
export type CreateGoalData = Omit<Goal, 'id' | 'createdAt' | 'updatedAt' | 'currentValue' | 'progressPercent' | 'lastCalculatedAt' | 'status'> & {
  status?: GoalStatus;
};

/** Data allowed when updating a goal */
export type UpdateGoalData = Partial<Omit<Goal, 'id' | 'createdAt' | 'createdById' | 'createdByName'>>;

// ============================================
// Forecast Calculation Options
// ============================================

/** Options for calculating forecasts */
export interface ForecastCalculationOptions {
  period: GoalPeriod;
  startDate: Date;
  endDate: Date;
  pipelineId?: string;
  ownerId?: string;
  teamIds?: string[];
}

// ============================================
// Goal Dashboard Types
// ============================================

/** Summary of goal progress for dashboard display */
export interface GoalProgressSummary {
  goal: Goal;
  daysRemaining: number;
  dailyTarget: number;
  paceStatus: 'on_track' | 'ahead' | 'behind' | 'at_risk';
  projectedEndValue: number;
}

/** Aggregated goal statistics */
export interface GoalDashboardStats {
  totalGoals: number;
  activeGoals: number;
  achievedGoals: number;
  missedGoals: number;
  averageProgress: number;
}

// ============================================
// Forecast Summary Types
// ============================================

/** Forecast summary for widgets */
export interface ForecastSummary {
  forecast: Forecast;
  /** Percentage of committed vs target */
  commitmentRatio: number;
  /** Gap between projected and target (negative means ahead) */
  gapToTarget: number;
  /** Confidence level based on stage distribution */
  confidenceLevel: 'high' | 'medium' | 'low';
  /** Whether projected + closed meets or exceeds target */
  isOnTrack: boolean;
}
