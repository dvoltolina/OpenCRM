/**
 * DealValueChart Component
 * Pie/donut chart showing deal value distribution
 *
 * Agent CRM-19 Implementation
 */

import { useCallback } from 'react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { ChartContainer } from './ChartContainer';
import './charts.css';

interface DealValueChartDataPoint {
  name: string;
  value: number;
  totalValue: number;
  color: string;
}

// ============================================
// Types
// ============================================

export interface ValueRange {
  id: string;
  label: string;
  min: number;
  max: number;
  color: string;
}

export interface DealValueChartProps {
  /** Deal values in cents */
  values: number[];
  /** Value ranges for bucketing */
  ranges?: ValueRange[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
  /** Currency for formatting */
  currency?: string;
  /** Whether to show as donut */
  donut?: boolean;
}

// ============================================
// Default Ranges
// ============================================

const DEFAULT_RANGES: ValueRange[] = [
  { id: 'small', label: 'Under $10K', min: 0, max: 1000000, color: '#6366f1' },
  { id: 'medium', label: '$10K - $50K', min: 1000000, max: 5000000, color: '#8b5cf6' },
  { id: 'large', label: '$50K - $100K', min: 5000000, max: 10000000, color: '#a855f7' },
  { id: 'enterprise', label: 'Over $100K', min: 10000000, max: Infinity, color: '#d946ef' },
];

// ============================================
// Component
// ============================================

/**
 * DealValueChart - Distribution of deal values
 *
 * @example
 * ```tsx
 * const dealValues = deals.map(d => d.valueCents);
 *
 * <DealValueChart
 *   values={dealValues}
 *   currency="USD"
 *   donut
 * />
 * ```
 */
export function DealValueChart({
  values,
  ranges = DEFAULT_RANGES,
  isLoading = false,
  height = 300,
  currency = 'USD',
  donut = true,
}: DealValueChartProps) {
  const isEmpty = values.length === 0;

  // Bucket values into ranges
  const chartData = ranges.map((range) => {
    const count = values.filter(
      (v) => v >= range.min && v < range.max
    ).length;
    const totalValue = values
      .filter((v) => v >= range.min && v < range.max)
      .reduce((sum, v) => sum + v, 0);

    return {
      name: range.label,
      value: count,
      totalValue,
      color: range.color,
    };
  }).filter((d) => d.value > 0);

  const formatCurrency = useCallback(
    (valueCents: number): string =>
      new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(valueCents / 100),
    [currency]
  );

  const renderTooltip = useCallback(
    ({
      active,
      payload,
    }: {
      active?: boolean;
      payload?: { payload: DealValueChartDataPoint }[];
    }) => {
      if (!active || !payload || payload.length === 0) return null;

      const data = payload[0]?.payload;
      if (!data) return null;

      return (
        <div className="recharts-default-tooltip">
          <p className="recharts-tooltip-label">{data.name}</p>
          <p className="recharts-tooltip-item">{data.value} deals</p>
          <p className="recharts-tooltip-item">{formatCurrency(data.totalValue)} total</p>
        </div>
      );
    },
    [formatCurrency]
  );

  return (
    <ChartContainer
      title="Deal Value Distribution"
      subtitle="Deals by value range"
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height}
      emptyMessage="No deals to display"
    >
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={donut ? 60 : 0}
            outerRadius={90}
            paddingAngle={2}
            dataKey="value"
            label={({ name, percent }) =>
              percent && percent > 0.05 ? `${name} (${(percent * 100).toFixed(0)}%)` : ''
            }
            labelLine={false}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip content={renderTooltip as any} />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
}

export default DealValueChart;
