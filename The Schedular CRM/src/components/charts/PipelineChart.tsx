/**
 * PipelineChart Component
 * Bar chart visualization of deals by pipeline stage
 *
 * Agent CRM-19 Implementation
 */

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import { useCallback } from 'react';
import { ChartContainer } from './ChartContainer';
import type { PipelineChartDataPoint } from '../../hooks/usePipelineChartData';
import './charts.css';

// ============================================
// Types
// ============================================

export interface PipelineChartProps {
  /** Chart data points */
  data: PipelineChartDataPoint[];
  /** Whether to show values or counts */
  metric?: 'count' | 'value';
  /** Chart orientation */
  orientation?: 'horizontal' | 'vertical';
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
  /** Currency for value formatting */
  currency?: string;
  /** Click handler for bar */
  onBarClick?: (stageId: string) => void;
}

// ============================================
// Helper Functions
// ============================================

function formatValue(value: number, currency: string): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value / 100);
}

function formatCount(count: number): string {
  return count === 1 ? '1 opportunity' : `${count} opportunities`;
}

// ============================================
// Component
// ============================================

/**
 * PipelineChart - Bar chart of deals by stage
 *
 * @example
 * ```tsx
 * const { data } = usePipelineChartData(deals, stages);
 *
 * <PipelineChart
 *   data={data}
 *   metric="value"
 *   orientation="vertical"
 *   currency="USD"
 *   onBarClick={(stageId) => filterByStage(stageId)}
 * />
 * ```
 */
export function PipelineChart({
  data,
  metric = 'count',
  orientation = 'vertical',
  isLoading = false,
  height = 300,
  currency = 'USD',
  onBarClick,
}: PipelineChartProps) {
  const isEmpty = data.length === 0 || data.every((d) => d.dealCount === 0);

  const chartData = data.map((d) => ({
    ...d,
    displayValue: metric === 'value' ? d.totalValue / 100 : d.dealCount,
  }));

  const renderTooltip = useCallback(
    ({
      active,
      payload,
    }: {
      active?: boolean;
      payload?: { payload: PipelineChartDataPoint & { displayValue: number } }[];
    }) => {
      if (!active || !payload || payload.length === 0) return null;
      const item = payload[0]?.payload;
      if (!item) return null;

      return (
        <div className="recharts-default-tooltip">
          <p className="recharts-tooltip-label">{item.stageName}</p>
          <p className="recharts-tooltip-item">
            {formatCount(item.dealCount)}
          </p>
          <p className="recharts-tooltip-item">
            {formatValue(item.totalValue, currency)}
          </p>
        </div>
      );
    },
    [currency]
  );

  const handleBarClick = (data: { stageId?: string } | undefined) => {
    if (onBarClick && data?.stageId) {
      onBarClick(data.stageId);
    }
  };

  const isHorizontal = orientation === 'horizontal';

  return (
    <ChartContainer
      title="Pipeline Overview"
      subtitle={metric === 'value' ? 'Opportunity value by stage' : 'Opportunity count by stage'}
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height}
      emptyMessage="No opportunities in pipeline"
    >
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={chartData}
          layout={isHorizontal ? 'vertical' : 'horizontal'}
          margin={{ top: 10, right: 30, left: 20, bottom: 10 }}
        >
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
          {isHorizontal ? (
            <>
              <XAxis type="number" stroke="var(--color-text-muted)" fontSize={12} />
              <YAxis
                type="category"
                dataKey="stageName"
                stroke="var(--color-text-muted)"
                fontSize={12}
                width={100}
              />
            </>
          ) : (
            <>
              <XAxis
                dataKey="stageName"
                stroke="var(--color-text-muted)"
                fontSize={12}
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis stroke="var(--color-text-muted)" fontSize={12} />
            </>
          )}
          <Tooltip content={renderTooltip as any} />
          <Bar
            dataKey="displayValue"
            radius={[4, 4, 0, 0]}
            onClick={handleBarClick as any}
            cursor={onBarClick ? 'pointer' : undefined}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.stageColor} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
}

export default PipelineChart;
