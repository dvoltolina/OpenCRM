/**
 * useForecasting Hook
 * Manages revenue forecasts with period selection and pipeline filtering
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getForecastRepository } from '../data/repositories/forecast-repository';
import { getForecastingService } from '../services/forecasting-service';
import { createSecurityContext } from './usePipeline';
import { getFeatureFlags } from '../config/features';
import type {
  Forecast,
  GoalPeriod,
  ForecastSummary,
} from '../types/goals';

// ============================================
// Types
// ============================================

export interface UseForecastResult {
  /** Current forecast for the period */
  forecast: Forecast | null;
  /** True while loading */
  isLoading: boolean;
  /** Error if operation failed */
  error: Error | null;
  /** Refresh forecast data */
  refresh: () => void;
  /** Recalculate forecast from current deals */
  recalculate: () => Promise<void>;
  /** Feature flag check */
  isEnabled: boolean;
}

export interface UseForecastSummaryResult {
  /** Forecast summary with analysis */
  summary: ForecastSummary | null;
  /** True while loading */
  isLoading: boolean;
  /** Error if operation failed */
  error: Error | null;
  /** Refresh summary */
  refresh: () => void;
}

export interface UseForecastHistoryResult {
  /** Historical forecasts */
  forecasts: Forecast[];
  /** True while loading */
  isLoading: boolean;
  /** Error if operation failed */
  error: Error | null;
  /** Refresh history */
  refresh: () => void;
}

export interface ForecastOptions {
  period: GoalPeriod;
  pipelineId?: string;
  targetRevenue?: number;
}

// ============================================
// useForecast Hook
// ============================================

/**
 * Hook for fetching current forecast for a period
 */
export function useForecast(options: ForecastOptions): UseForecastResult {
  const { crmUser, businessId } = useAuth();
  const [forecast, setForecast] = useState<Forecast | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const isEnabled = getFeatureFlags().enableForecasting;
  const { period, pipelineId } = options;

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

  // Fetch forecast
  const fetchForecast = useCallback(async () => {
    if (!businessId || !crmUser || !isEnabled) {
      setForecast(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getForecastRepository();
      const result = await repo.getCurrentForecast(context, period, pipelineId);

      if (result.success) {
        setForecast(result.data);
      } else {
        throw new Error(result.error?.message || 'Failed to fetch forecast');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch forecast'));
      setForecast(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, isEnabled, period, pipelineId]);

  useEffect(() => {
    fetchForecast();
  }, [fetchForecast, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  const recalculate = useCallback(async () => {
    if (!businessId || !crmUser) return;

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getForecastingService();
      const { startDate, endDate } = service.getPeriodDateRange(period);

      const result = await service.calculateForecast(context, {
        period,
        startDate,
        endDate,
        pipelineId,
      });

      if (result.success && result.data) {
        setForecast(result.data);
      } else {
        throw result.error || new Error('Failed to recalculate forecast');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to recalculate forecast'));
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, period, pipelineId]);

  return {
    forecast,
    isLoading,
    error,
    refresh,
    recalculate,
    isEnabled,
  };
}

// ============================================
// useForecastSummary Hook
// ============================================

/**
 * Hook for forecast summary with analysis
 */
export function useForecastSummary(options: ForecastOptions): UseForecastSummaryResult {
  const { crmUser, businessId } = useAuth();
  const [summary, setSummary] = useState<ForecastSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const isEnabled = getFeatureFlags().enableForecasting;
  const { period, pipelineId, targetRevenue } = options;

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

  const fetchSummary = useCallback(async () => {
    if (!businessId || !crmUser || !isEnabled) {
      setSummary(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getForecastingService();
      const result = await service.getForecastSummary(context, period, pipelineId, targetRevenue);

      if (result.success && result.data) {
        setSummary(result.data);
      } else {
        throw result.error || new Error('Failed to fetch forecast summary');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch forecast summary'));
      setSummary(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, isEnabled, period, pipelineId, targetRevenue]);

  useEffect(() => {
    fetchSummary();
  }, [fetchSummary, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    summary,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useForecastHistory Hook
// ============================================

/**
 * Hook for historical forecast data
 */
export function useForecastHistory(
  periods: number = 6,
  periodType: GoalPeriod = 'monthly',
  pipelineId?: string
): UseForecastHistoryResult {
  const { crmUser, businessId } = useAuth();
  const [forecasts, setForecasts] = useState<Forecast[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const isEnabled = getFeatureFlags().enableForecasting;

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

  const fetchHistory = useCallback(async () => {
    if (!businessId || !crmUser || !isEnabled) {
      setForecasts([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getForecastingService();
      const result = await service.getForecastHistory(context, periods, periodType, pipelineId);

      if (result.success && result.data) {
        setForecasts(result.data);
      } else {
        throw result.error || new Error('Failed to fetch forecast history');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch forecast history'));
      setForecasts([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, isEnabled, periods, periodType, pipelineId]);

  useEffect(() => {
    fetchHistory();
  }, [fetchHistory, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    forecasts,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useForecastComparison Hook
// ============================================

export interface ForecastComparison {
  current: Forecast | null;
  previous: Forecast | null;
  percentChange: number;
  trendDirection: 'up' | 'down' | 'flat';
}

export interface UseForecastComparisonResult {
  comparison: ForecastComparison | null;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

/**
 * Hook for comparing current forecast to previous period
 */
export function useForecastComparison(options: ForecastOptions): UseForecastComparisonResult {
  const { forecast: current, isLoading: currentLoading, error: currentError, refresh } = useForecast(options);
  const { forecasts: history, isLoading: historyLoading } = useForecastHistory(
    2,
    options.period,
    options.pipelineId
  );

  const comparison = useMemo((): ForecastComparison | null => {
    if (!current) return null;

    // Find the previous period forecast from history
    const previous = history.length > 1 ? history[1] : null;

    if (!previous) {
      return {
        current,
        previous: null,
        percentChange: 0,
        trendDirection: 'flat',
      };
    }

    const prevValue = previous.projectedRevenue || 0;
    const currValue = current.projectedRevenue || 0;

    const percentChange = prevValue > 0
      ? ((currValue - prevValue) / prevValue) * 100
      : currValue > 0 ? 100 : 0;

    const trendDirection: 'up' | 'down' | 'flat' =
      percentChange > 5 ? 'up' : percentChange < -5 ? 'down' : 'flat';

    return {
      current,
      previous,
      percentChange,
      trendDirection,
    };
  }, [current, history]);

  return {
    comparison,
    isLoading: currentLoading || historyLoading,
    error: currentError,
    refresh,
  };
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format cents as currency string
 */
export function formatCurrency(cents: number, currency: string = 'USD'): string {
  const dollars = cents / 100;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(dollars);
}

/**
 * Get period display name
 */
export function getPeriodDisplayName(period: GoalPeriod): string {
  switch (period) {
    case 'weekly':
      return 'This Week';
    case 'monthly':
      return 'This Month';
    case 'quarterly':
      return 'This Quarter';
    case 'yearly':
      return 'This Year';
    default:
      return period;
  }
}

/**
 * Get confidence level color
 */
export function getConfidenceColor(level: 'high' | 'medium' | 'low'): string {
  switch (level) {
    case 'high':
      return 'text-green-600';
    case 'medium':
      return 'text-yellow-600';
    case 'low':
      return 'text-red-600';
    default:
      return 'text-gray-600';
  }
}

export default useForecast;
