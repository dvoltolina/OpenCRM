/**
 * usePipelineChartData Hook
 * Transforms pipeline data for chart visualizations
 *
 * Agent CRM-19 Implementation
 */

import { useMemo } from 'react';
import type { Deal, Stage } from '../types/models';

// ============================================
// Types
// ============================================

export interface PipelineChartDataPoint {
  stageId: string;
  stageName: string;
  stageColor: string;
  dealCount: number;
  totalValue: number;
  order: number;
}

export interface UsePipelineChartDataResult {
  /** Chart data points by stage */
  data: PipelineChartDataPoint[];
  /** Total deals across all stages */
  totalDeals: number;
  /** Total value across all stages */
  totalValue: number;
  /** Whether data is empty */
  isEmpty: boolean;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for transforming pipeline data into chart format
 *
 * @param deals - Array of deals to chart
 * @param stages - Array of stages for the pipeline
 * @returns Formatted chart data
 *
 * @example
 * ```tsx
 * const { dealsByStage, stages } = useDealsByStage(pipelineId);
 * const { data, totalDeals, totalValue } = usePipelineChartData(
 *   Object.values(dealsByStage).flatMap(s => s.deals),
 *   stages
 * );
 * ```
 */
export function usePipelineChartData(
  deals: Deal[],
  stages: Stage[]
): UsePipelineChartDataResult {
  const data = useMemo(() => {
    // Group deals by stage
    const dealsByStage = deals.reduce<Record<string, Deal[]>>((acc, deal) => {
      const stageId = deal.stageId;
      if (!acc[stageId]) {
        acc[stageId] = [];
      }
      acc[stageId].push(deal);
      return acc;
    }, {});

    // Map stages to chart data points
    return stages
      .filter((stage) => stage.isActive)
      .sort((a, b) => a.order - b.order)
      .map((stage) => {
        const stageDeals = dealsByStage[stage.id] || [];
        return {
          stageId: stage.id,
          stageName: stage.name,
          stageColor: stage.colorHex || '#6366f1',
          dealCount: stageDeals.length,
          totalValue: stageDeals.reduce((sum, d) => sum + (d.valueCents || 0), 0),
          order: stage.order,
        };
      });
  }, [deals, stages]);

  const totalDeals = useMemo(
    () => data.reduce((sum, d) => sum + d.dealCount, 0),
    [data]
  );

  const totalValue = useMemo(
    () => data.reduce((sum, d) => sum + d.totalValue, 0),
    [data]
  );

  return {
    data,
    totalDeals,
    totalValue,
    isEmpty: data.length === 0 || totalDeals === 0,
  };
}

export default usePipelineChartData;
