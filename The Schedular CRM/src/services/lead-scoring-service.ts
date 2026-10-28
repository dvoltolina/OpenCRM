/**
 * Lead Scoring Service
 * Calculates and manages lead scores based on configurable rules
 *
 * Agent CRM-40 Implementation
 * Dependencies: CRM-08 (Lead hooks), CRM-20 (Settings)
 */

import type { Lead } from '../types/models';
import type {
  LeadScoringConfig,
  LeadScoringRule,
  LeadScore,
  LeadScoreFactor,
} from '../types/lead-scoring';

// ============================================
// Default Scoring Rules
// ============================================

export function getDefaultRules(): LeadScoringRule[] {
  return [
    {
      id: 'rule-email',
      name: 'Email provided',
      condition: 'has_email',
      points: 10,
      isActive: true,
    },
    {
      id: 'rule-phone',
      name: 'Phone provided',
      condition: 'has_phone',
      points: 10,
      isActive: true,
    },
    {
      id: 'rule-company',
      name: 'Company name provided',
      condition: 'has_company',
      points: 15,
      isActive: true,
    },
    {
      id: 'rule-source-referral',
      name: 'Source is referral',
      condition: 'source_equals',
      conditionValue: 'referral',
      points: 20,
      isActive: true,
    },
    {
      id: 'rule-source-website',
      name: 'Source is website',
      condition: 'source_equals',
      conditionValue: 'website',
      points: 15,
      isActive: true,
    },
    {
      id: 'rule-source-scheduler',
      name: 'Source is scheduler',
      condition: 'source_equals',
      conditionValue: 'scheduler',
      points: 25,
      isActive: true,
    },
    {
      id: 'rule-has-activity',
      name: 'Has recent activity (7 days)',
      condition: 'has_activity',
      conditionValue: '7',
      points: 10,
      isActive: true,
    },
  ];
}

// ============================================
// Default Configuration
// ============================================

export function getDefaultConfig(businessId: string): LeadScoringConfig {
  return {
    businessId,
    enabled: true,
    rules: getDefaultRules(),
    decayEnabled: true,
    decayPointsPerDay: 1,
    decayStartDays: 30,
  };
}

// ============================================
// Score Calculation
// ============================================

/**
 * Calculate the score for a lead based on the configuration
 *
 * @param lead - The lead to score
 * @param config - Scoring configuration
 * @param hasRecentActivity - Optional: whether the lead has recent activity
 * @returns Calculated lead score with breakdown
 */
export function calculateScore(
  lead: Lead,
  config: LeadScoringConfig,
  hasRecentActivity?: boolean
): LeadScore {
  if (!config.enabled) {
    return {
      leadId: lead.id,
      score: 0,
      factors: [],
      calculatedAt: new Date(),
    };
  }

  const factors: LeadScoreFactor[] = [];
  let totalPoints = 0;

  // Evaluate each active rule
  for (const rule of config.rules) {
    if (!rule.isActive) continue;

    const points = evaluateRule(lead, rule, hasRecentActivity);
    if (points !== 0) {
      factors.push({
        rule: rule.name,
        points,
      });
      totalPoints += points;
    }
  }

  // Apply time decay if enabled
  if (config.decayEnabled) {
    const decayPoints = applyTimeDecay(lead, config);
    if (decayPoints !== 0) {
      factors.push({
        rule: 'Time decay',
        points: decayPoints,
      });
      totalPoints += decayPoints;
    }
  }

  // Clamp score between 0 and 100
  const finalScore = Math.max(0, Math.min(100, totalPoints));

  return {
    leadId: lead.id,
    score: finalScore,
    factors,
    calculatedAt: new Date(),
  };
}

/**
 * Evaluate a single scoring rule against a lead
 */
function evaluateRule(
  lead: Lead,
  rule: LeadScoringRule,
  hasRecentActivity?: boolean
): number {
  switch (rule.condition) {
    case 'has_email':
      return lead.email && lead.email.trim() !== '' ? rule.points : 0;

    case 'has_phone':
      return lead.phone && lead.phone.trim() !== '' ? rule.points : 0;

    case 'has_company':
      return lead.companyName && lead.companyName.trim() !== '' ? rule.points : 0;

    case 'source_equals':
      return lead.source === rule.conditionValue ? rule.points : 0;

    case 'status_equals':
      return lead.status === rule.conditionValue ? rule.points : 0;

    case 'has_activity':
      // This requires external data about recent activities
      // The caller should pass hasRecentActivity flag
      return hasRecentActivity === true ? rule.points : 0;

    case 'days_since_created':
      // This is typically used for custom rules
      // For now, return 0 as it's usually handled by decay
      return 0;

    default:
      return 0;
  }
}

/**
 * Apply time decay to a lead's score
 *
 * @param lead - The lead to apply decay to
 * @param config - Scoring configuration
 * @returns Negative points to subtract (or 0 if no decay)
 */
export function applyTimeDecay(
  lead: Lead,
  config: LeadScoringConfig
): number {
  if (!config.decayEnabled) {
    return 0;
  }

  const now = new Date();
  const createdAt = lead.createdAt instanceof Date ? lead.createdAt : new Date(lead.createdAt);
  const daysSinceCreated = Math.floor((now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));

  // Only apply decay after the threshold
  if (daysSinceCreated <= config.decayStartDays) {
    return 0;
  }

  const daysOverThreshold = daysSinceCreated - config.decayStartDays;
  const decayPoints = -1 * (daysOverThreshold * config.decayPointsPerDay);

  return decayPoints;
}

/**
 * Calculate days since a lead was created
 */
export function getDaysSinceCreated(lead: Lead): number {
  const now = new Date();
  const createdAt = lead.createdAt instanceof Date ? lead.createdAt : new Date(lead.createdAt);
  return Math.floor((now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
}

/**
 * Batch calculate scores for multiple leads
 *
 * @param leads - Array of leads to score
 * @param config - Scoring configuration
 * @param activityMap - Optional map of leadId to hasRecentActivity boolean
 * @returns Array of lead scores
 */
export function calculateBatchScores(
  leads: Lead[],
  config: LeadScoringConfig,
  activityMap?: Map<string, boolean>
): LeadScore[] {
  return leads.map((lead) => {
    const hasActivity = activityMap?.get(lead.id);
    return calculateScore(lead, config, hasActivity);
  });
}

/**
 * Update a lead's score field (utility function)
 * This doesn't save to the database - the caller should do that
 *
 * @param lead - The lead to update
 * @param score - The calculated score
 * @returns Updated lead object
 */
export function updateLeadWithScore(lead: Lead, score: number): Lead {
  return {
    ...lead,
    score: Math.round(score),
  };
}

// ============================================
// Rule Validation
// ============================================

/**
 * Validate a scoring rule
 */
export function validateRule(rule: LeadScoringRule): { valid: boolean; error?: string } {
  if (!rule.name || rule.name.trim() === '') {
    return { valid: false, error: 'Rule name is required' };
  }

  if (!rule.condition) {
    return { valid: false, error: 'Rule condition is required' };
  }

  // Validate condition-specific requirements
  if (rule.condition === 'source_equals' || rule.condition === 'status_equals') {
    if (!rule.conditionValue || rule.conditionValue.trim() === '') {
      return { valid: false, error: `Condition value is required for ${rule.condition}` };
    }
  }

  if (typeof rule.points !== 'number') {
    return { valid: false, error: 'Points must be a number' };
  }

  // Points should be reasonable (-100 to 100)
  if (rule.points < -100 || rule.points > 100) {
    return { valid: false, error: 'Points must be between -100 and 100' };
  }

  return { valid: true };
}

/**
 * Validate a scoring configuration
 */
export function validateConfig(config: LeadScoringConfig): { valid: boolean; error?: string } {
  if (!config.businessId) {
    return { valid: false, error: 'Business ID is required' };
  }

  if (!Array.isArray(config.rules)) {
    return { valid: false, error: 'Rules must be an array' };
  }

  // Validate each rule
  for (const rule of config.rules) {
    const validation = validateRule(rule);
    if (!validation.valid) {
      return { valid: false, error: `Invalid rule "${rule.name}": ${validation.error}` };
    }
  }

  // Validate decay settings
  if (config.decayEnabled) {
    if (typeof config.decayPointsPerDay !== 'number' || config.decayPointsPerDay < 0) {
      return { valid: false, error: 'Decay points per day must be a positive number' };
    }

    if (typeof config.decayStartDays !== 'number' || config.decayStartDays < 0) {
      return { valid: false, error: 'Decay start days must be a positive number' };
    }
  }

  return { valid: true };
}
