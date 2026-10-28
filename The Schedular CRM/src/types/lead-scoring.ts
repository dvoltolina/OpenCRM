/**
 * Lead Scoring Types
 * Type definitions for the lead scoring system
 *
 * Agent CRM-40 Implementation
 * Dependencies: CRM-08 (Lead hooks), CRM-20 (Settings)
 */

// ============================================
// Scoring Rule Conditions
// ============================================

export type LeadScoringCondition =
  | 'has_email'
  | 'has_phone'
  | 'has_company'
  | 'source_equals'
  | 'days_since_created'
  | 'status_equals'
  | 'has_activity';

// ============================================
// Scoring Rule
// ============================================

export interface LeadScoringRule {
  /** Unique identifier for the rule */
  id: string;
  /** Display name of the rule */
  name: string;
  /** Condition to evaluate */
  condition: LeadScoringCondition;
  /** Value to compare against (for equals conditions) */
  conditionValue?: string;
  /** Points awarded if condition is met (can be negative) */
  points: number;
  /** Whether this rule is currently active */
  isActive: boolean;
}

// ============================================
// Scoring Configuration
// ============================================

export interface LeadScoringConfig {
  /** Business ID this configuration belongs to */
  businessId: string;
  /** Whether lead scoring is enabled */
  enabled: boolean;
  /** Active scoring rules */
  rules: LeadScoringRule[];
  /** Whether time decay is enabled */
  decayEnabled: boolean;
  /** Points to subtract per day after decay starts */
  decayPointsPerDay: number;
  /** Number of days before decay starts */
  decayStartDays: number;
}

// ============================================
// Score Result
// ============================================

export interface LeadScoreFactor {
  /** Name/description of the scoring factor */
  rule: string;
  /** Points awarded by this factor */
  points: number;
}

export interface LeadScore {
  /** Lead ID */
  leadId: string;
  /** Final calculated score (0-100) */
  score: number;
  /** Breakdown of scoring factors */
  factors: LeadScoreFactor[];
  /** When this score was calculated */
  calculatedAt: Date;
}

// ============================================
// Score Tier/Quality
// ============================================

export type LeadScoreTier = 'hot' | 'warm' | 'cold';

export interface LeadScoreTierConfig {
  tier: LeadScoreTier;
  minScore: number;
  maxScore: number;
  color: string;
  label: string;
}

// ============================================
// Default Tier Configuration
// ============================================

export const DEFAULT_SCORE_TIERS: LeadScoreTierConfig[] = [
  {
    tier: 'hot',
    minScore: 70,
    maxScore: 100,
    color: '#22c55e', // green-500
    label: 'Hot Lead',
  },
  {
    tier: 'warm',
    minScore: 40,
    maxScore: 69,
    color: '#eab308', // yellow-500
    label: 'Warm Lead',
  },
  {
    tier: 'cold',
    minScore: 0,
    maxScore: 39,
    color: '#ef4444', // red-500
    label: 'Cold Lead',
  },
];

/**
 * Get the tier for a given score
 */
export function getScoreTier(score: number): LeadScoreTierConfig {
  for (const tier of DEFAULT_SCORE_TIERS) {
    if (score >= tier.minScore && score <= tier.maxScore) {
      return tier;
    }
  }
  // Fallback to cold if no tier matches
  return DEFAULT_SCORE_TIERS[2];
}
