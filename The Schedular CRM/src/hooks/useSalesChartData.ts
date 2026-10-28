/**
 * useSalesChartData Hook
 * Transforms sales data for trend chart visualizations
 *
 * Agent CRM-19 Implementation
 */

import { useMemo } from 'react';
import type { Deal } from '../types/models';

// ============================================
// Types
// ============================================

export type TimeGranularity = 'daily' | 'weekly' | 'monthly';

export interface SalesDataPoint {
  date: string;
  label: string;
  wonCount: number;
  wonValue: number;
  lostCount: number;
  lostValue: number;
  totalCount: number;
  totalValue: number;
}

export interface UseSalesChartDataOptions {
  /** Time granularity */
  granularity?: TimeGranularity;
  /** Number of periods to include */
  periods?: number;
}

export interface UseSalesChartDataResult {
  /** Chart data points over time */
  data: SalesDataPoint[];
  /** Total won deals in period */
  totalWon: number;
  /** Total won value in period */
  totalWonValue: number;
  /** Total lost deals in period */
  totalLost: number;
  /** Total lost value in period */
  totalLostValue: number;
  /** Whether data is empty */
  isEmpty: boolean;
}

// ============================================
// Helper Functions
// ============================================

function getDateKey(date: Date, granularity: TimeGranularity): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  switch (granularity) {
    case 'daily':
      return `${year}-${month}-${day}`;
    case 'weekly': {
      // Get week start (Sunday)
      const weekStart = new Date(date);
      weekStart.setDate(date.getDate() - date.getDay());
      return `${weekStart.getFullYear()}-${String(weekStart.getMonth() + 1).padStart(2, '0')}-${String(weekStart.getDate()).padStart(2, '0')}`;
    }
    case 'monthly':
      return `${year}-${month}`;
  }
}

function getDateLabel(dateKey: string, granularity: TimeGranularity): string {
  const parts = dateKey.split('-');
  const year = parseInt(parts[0]);
  const month = parseInt(parts[1]) - 1;
  const day = parts[2] ? parseInt(parts[2]) : 1;

  const date = new Date(year, month, day);

  switch (granularity) {
    case 'daily':
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    case 'weekly':
      return `Week of ${date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`;
    case 'monthly':
      return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
  }
}

function generatePeriodKeys(
  granularity: TimeGranularity,
  periods: number
): string[] {
  const keys: string[] = [];
  const now = new Date();

  for (let i = periods - 1; i >= 0; i--) {
    const date = new Date(now);
    switch (granularity) {
      case 'daily':
        date.setDate(date.getDate() - i);
        break;
      case 'weekly':
        date.setDate(date.getDate() - i * 7);
        break;
      case 'monthly':
        date.setMonth(date.getMonth() - i);
        break;
    }
    keys.push(getDateKey(date, granularity));
  }

  return keys;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for transforming deal data into sales trend chart format
 *
 * @param deals - Array of closed deals
 * @param options - Chart options
 * @returns Formatted chart data
 *
 * @example
 * ```tsx
 * const { deals } = useDeals({ status: 'won' });
 * const { data, totalWon, totalWonValue } = useSalesChartData(deals, {
 *   granularity: 'monthly',
 *   periods: 12,
 * });
 * ```
 */
export function useSalesChartData(
  deals: Deal[],
  options: UseSalesChartDataOptions = {}
): UseSalesChartDataResult {
  const { granularity = 'monthly', periods = 12 } = options;

  const data = useMemo(() => {
    // Generate all period keys
    const periodKeys = generatePeriodKeys(granularity, periods);

    // Initialize data map with all periods
    const dataMap: Record<string, SalesDataPoint> = {};
    for (const key of periodKeys) {
      dataMap[key] = {
        date: key,
        label: getDateLabel(key, granularity),
        wonCount: 0,
        wonValue: 0,
        lostCount: 0,
        lostValue: 0,
        totalCount: 0,
        totalValue: 0,
      };
    }

    // Aggregate deals by period
    for (const deal of deals) {
      if (!deal.closedAt) continue;

      const closedDate = new Date(deal.closedAt);
      const key = getDateKey(closedDate, granularity);

      if (!dataMap[key]) continue; // Outside our period range

      if (deal.status === 'won') {
        dataMap[key].wonCount += 1;
        dataMap[key].wonValue += deal.valueCents || 0;
      } else if (deal.status === 'lost') {
        dataMap[key].lostCount += 1;
        dataMap[key].lostValue += deal.valueCents || 0;
      }

      dataMap[key].totalCount += 1;
      dataMap[key].totalValue += deal.valueCents || 0;
    }

    // Return in chronological order
    return periodKeys.map((key) => dataMap[key]);
  }, [deals, granularity, periods]);

  const totalWon = useMemo(() => data.reduce((sum, d) => sum + d.wonCount, 0), [data]);
  const totalWonValue = useMemo(() => data.reduce((sum, d) => sum + d.wonValue, 0), [data]);
  const totalLost = useMemo(() => data.reduce((sum, d) => sum + d.lostCount, 0), [data]);
  const totalLostValue = useMemo(() => data.reduce((sum, d) => sum + d.lostValue, 0), [data]);

  return {
    data,
    totalWon,
    totalWonValue,
    totalLost,
    totalLostValue,
    isEmpty: totalWon === 0 && totalLost === 0,
  };
}

export default useSalesChartData;
