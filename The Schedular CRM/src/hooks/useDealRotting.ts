/**
 * useDealRotting Hook
 * React hook for deal rotting detection and management
 *
 * Agent CRM-41 Implementation
 * Dependencies: CRM-41 (Deal Rotting Service), CRM-20 (Settings)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import {
  getDealRottingService,
  type DealRottingStatus,
  type DealWithRottingStatus,
  type RottingConfig,
} from '../services/deal-rotting-service';
import { useSettings } from './useSettings';

// ============================================
// Types
// ============================================

export interface UseDealRottingResult {
  /** Current rotting configuration */
  config: RottingConfig | null;
  /** All rotting deals (past threshold) */
  rottingDeals: DealWithRottingStatus[];
  /** Deals at risk (in warning zone) */
  atRiskDeals: DealWithRottingStatus[];
  /** Total count of stale deals (rotting + at risk) */
  totalStaleCount: number;
  /** Get rotting status for a specific deal */
  getRottingStatus: (dealId: string) => Promise<DealRottingStatus | null>;
  /** Refresh all rotting data */
  refresh: () => Promise<void>;
  /** True while loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing deal rotting detection
 *
 * @returns Rotting deals data and operations
 *
 * @example
 * ```tsx
 * const {
 *   config,
 *   rottingDeals,
 *   atRiskDeals,
 *   totalStaleCount,
 *   getRottingStatus,
 *   isLoading,
 * } = useDealRotting();
 *
 * if (isLoading) return <Loading />;
 *
 * return (
 *   <div>
 *     <h2>Stale Deals: {totalStaleCount}</h2>
 *     <DealsAtRisk deals={atRiskDeals} />
 *     <RottingDeals deals={rottingDeals} />
 *   </div>
 * );
 * ```
 */
export function useDealRotting(): UseDealRottingResult {
  const { crmUser, businessId } = useAuth();
  const { settings } = useSettings();
  const [rottingDeals, setRottingDeals] = useState<DealWithRottingStatus[]>([]);
  const [atRiskDeals, setAtRiskDeals] = useState<DealWithRottingStatus[]>([]);
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

  // Get current config from settings
  const config = settings?.dealRotting || null;

  // Fetch rotting and at-risk deals
  const fetchStaleDeals = useCallback(async () => {
    if (!businessId || !crmUser) {
      setRottingDeals([]);
      setAtRiskDeals([]);
      setIsLoading(false);
      return;
    }

    // If rotting detection is disabled, clear data
    if (!config?.enabled) {
      setRottingDeals([]);
      setAtRiskDeals([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getDealRottingService();

      // Get both rotting and at-risk deals
      const result = await service.getAllStaleDeals(context);

      if (result.success && result.data) {
        setRottingDeals(result.data.rotting);
        setAtRiskDeals(result.data.atRisk);
      } else {
        throw new Error(result.error?.message || 'Failed to load stale deals');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load stale deals'));
      setRottingDeals([]);
      setAtRiskDeals([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, config?.enabled, getContext]);

  // Initial fetch and refetch when config changes
  useEffect(() => {
    fetchStaleDeals();
  }, [fetchStaleDeals]);

  // Get rotting status for a specific deal
  const getRottingStatus = useCallback(
    async (dealId: string): Promise<DealRottingStatus | null> => {
      if (!businessId || !crmUser) {
        return null;
      }

      try {
        const context = getContext();
        const service = getDealRottingService();
        const result = await service.getDealRottingStatus(context, dealId);

        if (result.success && result.data) {
          return result.data;
        }

        return null;
      } catch (err) {
        console.error('Failed to get rotting status:', err);
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Manual refresh
  const refresh = useCallback(async () => {
    await fetchStaleDeals();
  }, [fetchStaleDeals]);

  // Calculate total stale count
  const totalStaleCount = rottingDeals.length + atRiskDeals.length;

  return {
    config,
    rottingDeals,
    atRiskDeals,
    totalStaleCount,
    getRottingStatus,
    refresh,
    isLoading,
    error,
  };
}

export default useDealRotting;
