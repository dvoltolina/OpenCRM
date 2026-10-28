/**
 * useLeadScoring Hook
 * React hook for lead scoring operations
 *
 * Agent CRM-40 Implementation
 * Dependencies: CRM-08 (Lead hooks), CRM-20 (Settings)
 */

import { useState, useCallback, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import { getSettingsRepository } from '../data/repositories/settings-repository';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import {
  calculateScore,
  calculateBatchScores,
  getDefaultConfig,
  validateConfig,
} from '../services/lead-scoring-service';
import type { Lead } from '../types/models';
import type { LeadScoringConfig, LeadScore } from '../types/lead-scoring';

// ============================================
// Types
// ============================================

export interface UseLeadScoringResult {
  /** Current scoring configuration */
  config: LeadScoringConfig | null;
  /** True while loading config */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Calculate score for a single lead */
  calculateScore: (lead: Lead) => Promise<LeadScore>;
  /** Recalculate scores for all leads */
  recalculateAll: () => Promise<void>;
  /** Get current configuration */
  getConfig: () => LeadScoringConfig | null;
  /** Update configuration */
  updateConfig: (config: Partial<LeadScoringConfig>) => Promise<void>;
  /** Enable/disable lead scoring */
  toggleScoring: (enabled: boolean) => Promise<void>;
  /** Refresh configuration */
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing lead scoring
 *
 * @returns Lead scoring functions and configuration
 *
 * @example
 * ```tsx
 * const {
 *   config,
 *   calculateScore,
 *   updateConfig,
 *   isLoading,
 * } = useLeadScoring();
 *
 * // Calculate score for a lead
 * const score = await calculateScore(lead);
 *
 * // Update configuration
 * await updateConfig({
 *   decayEnabled: true,
 *   decayPointsPerDay: 2,
 * });
 * ```
 */
export function useLeadScoring(): UseLeadScoringResult {
  const { crmUser, businessId } = useAuth();
  const [config, setConfig] = useState<LeadScoringConfig | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Load configuration from settings
  const loadConfig = useCallback(async () => {
    if (!businessId || !crmUser) {
      setConfig(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const settingsRepo = getSettingsRepository();
      const result = await settingsRepo.getSettings(context);

      if (result.success) {
        const settings = result.data;

        // Build config from settings
        let scoringConfig: LeadScoringConfig;

        if (settings.leadScoringRules && settings.leadScoringRules.length > 0) {
          // Use existing config from settings
          scoringConfig = {
            businessId,
            enabled: settings.leadScoringEnabled,
            rules: settings.leadScoringRules.map(rule => ({
              id: rule.id,
              name: rule.field, // Use field as name since name is not in model
              condition: rule.condition as any, // Type assertion for condition
              conditionValue: rule.value?.toString(),
              points: rule.points,
              isActive: true, // Old rules don't have isActive, default to true
            })),
            decayEnabled: false, // Old settings don't have decay settings
            decayPointsPerDay: 1,
            decayStartDays: 30,
          };
        } else {
          // Use default config
          scoringConfig = getDefaultConfig(businessId);
          scoringConfig.enabled = settings.leadScoringEnabled;
        }

        setConfig(scoringConfig);
      } else {
        throw new Error(result.error.message);
      }
    } catch (err) {
      const errorObj = err instanceof Error ? err : new Error('Failed to load scoring config');
      setError(errorObj);
      // Set default config on error
      if (businessId) {
        setConfig(getDefaultConfig(businessId));
      }
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext]);

  // Load config on mount
  useEffect(() => {
    loadConfig();
  }, [loadConfig]);

  // Calculate score for a single lead
  const calculateLeadScore = useCallback(
    async (lead: Lead): Promise<LeadScore> => {
      if (!config) {
        throw new Error('Scoring configuration not loaded');
      }

      try {
        const context = getContext();

        // Check if lead has recent activity (last 7 days)
        let hasRecentActivity = false;
        try {
          const activityRepo = getActivityRepository();
          const activityResult = await activityRepo.getTimeline(context, 'lead', lead.id, {
            limit: 1,
          });

          if (activityResult.success && activityResult.data.data.length > 0) {
            const latestActivity = activityResult.data.data[0];
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
            const activityDate = latestActivity.createdAt instanceof Date
              ? latestActivity.createdAt
              : new Date(latestActivity.createdAt);
            hasRecentActivity = activityDate >= sevenDaysAgo;
          }
        } catch {
          // Ignore activity check errors
          hasRecentActivity = false;
        }

        return calculateScore(lead, config, hasRecentActivity);
      } catch (err) {
        throw err instanceof Error ? err : new Error('Failed to calculate score');
      }
    },
    [config, getContext]
  );

  // Recalculate all leads
  const recalculateAll = useCallback(async () => {
    if (!config || !businessId || !crmUser) {
      throw new Error('Cannot recalculate: configuration or auth not available');
    }

    setError(null);

    try {
      const context = getContext();
      const leadRepo = getLeadRepository();

      // Get all leads
      const leadsResult = await leadRepo.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!leadsResult.success) {
        throw new Error(leadsResult.error.message);
      }

      const leads = leadsResult.data.data;

      // Build activity map (check last 7 days for each lead)
      const activityMap = new Map<string, boolean>();
      const activityRepo = getActivityRepository();
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      for (const lead of leads) {
        try {
          const activityResult = await activityRepo.getTimeline(context, 'lead', lead.id, {
            limit: 1,
          });

          if (activityResult.success && activityResult.data.data.length > 0) {
            const latestActivity = activityResult.data.data[0];
            const activityDate = latestActivity.createdAt instanceof Date
              ? latestActivity.createdAt
              : new Date(latestActivity.createdAt);
            activityMap.set(lead.id, activityDate >= sevenDaysAgo);
          } else {
            activityMap.set(lead.id, false);
          }
        } catch {
          activityMap.set(lead.id, false);
        }
      }

      // Calculate scores
      const scores = calculateBatchScores(leads, config, activityMap);

      // Update each lead with new score
      for (let i = 0; i < leads.length; i++) {
        const lead = leads[i];
        const score = scores[i];

        if (lead.score !== score.score) {
          await leadRepo.update(context, lead.id, {
            score: score.score,
          });
        }
      }
    } catch (err) {
      const errorObj = err instanceof Error ? err : new Error('Failed to recalculate scores');
      setError(errorObj);
      throw errorObj;
    }
  }, [config, businessId, crmUser, getContext]);

  // Get current config
  const getConfigValue = useCallback(() => {
    return config;
  }, [config]);

  // Update configuration
  const updateConfigValue = useCallback(
    async (updates: Partial<LeadScoringConfig>): Promise<void> => {
      if (!config) {
        throw new Error('Configuration not loaded');
      }

      const newConfig: LeadScoringConfig = {
        ...config,
        ...updates,
      };

      // Validate configuration
      const validation = validateConfig(newConfig);
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      setError(null);

      try {
        const context = getContext();
        const settingsRepo = getSettingsRepository();

        // Convert config to settings format
        const settingsUpdate = {
          leadScoringEnabled: newConfig.enabled,
          leadScoringRules: newConfig.rules.map(rule => ({
            id: rule.id,
            field: rule.name, // Map name back to field
            condition: rule.condition as any,
            value: rule.conditionValue || '',
            points: rule.points,
          })),
        };

        const result = await settingsRepo.updateSettings(context, settingsUpdate);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        setConfig(newConfig);
      } catch (err) {
        const errorObj = err instanceof Error ? err : new Error('Failed to update configuration');
        setError(errorObj);
        throw errorObj;
      }
    },
    [config, getContext]
  );

  // Toggle scoring enabled/disabled
  const toggleScoring = useCallback(
    async (enabled: boolean): Promise<void> => {
      await updateConfigValue({ enabled });
    },
    [updateConfigValue]
  );

  // Manual refresh
  const refresh = useCallback(() => {
    loadConfig();
  }, [loadConfig]);

  return {
    config,
    isLoading,
    error,
    calculateScore: calculateLeadScore,
    recalculateAll,
    getConfig: getConfigValue,
    updateConfig: updateConfigValue,
    toggleScoring,
    refresh,
  };
}

export default useLeadScoring;
