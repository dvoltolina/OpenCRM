/**
 * SalesTrendChart Component
 * Line chart showing sales trends over time
 *
 * Agent CRM-19 Implementation
 */

import { useCallback, useState } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { ChartContainer } from './ChartContainer';
import type { SalesDataPoint, TimeGranularity } from '../../hooks/useSalesChartData';
import './charts.css';

// ============================================
// Types
// ============================================

export interface SalesTrendChartProps {
  /** Chart data points */
  data: SalesDataPoint[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
  /** Currency for value formatting */
  currency?: string;
  /** Whether to show value or count */
  metric?: 'value' | 'count';
  /** Show granularity controls */
  showControls?: boolean;
  /** Current granularity */
  granularity?: TimeGranularity;
  /** Granularity change handler */
  onGranularityChange?: (granularity: TimeGranularity) => void;
}

// ============================================
// Helper Functions
// ============================================

function formatCurrency(value: number, currency: string): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value / 100);
}

// ============================================
// Component
// ============================================

/**
 * SalesTrendChart - Line chart of sales over time
 *
 * @example
 * ```tsx
 * const { data } = useSalesChartData(deals, { granularity: 'monthly', periods: 12 });
 *
 * <SalesTrendChart
 *   data={data}
 *   metric="value"
 *   currency="USD"
 *   showControls
 *   granularity={granularity}
 *   onGranularityChange={setGranularity}
 * />
 * ```
 */
export function SalesTrendChart({
  data,
  isLoading = false,
  height = 300,
  currency = 'USD',
  metric = 'value',
  showControls = false,
  granularity = 'monthly',
  onGranularityChange,
}: SalesTrendChartProps) {
  const [localMetric, setLocalMetric] = useState<'value' | 'count'>(metric);
  const isEmpty = data.every((d) => d.wonCount === 0 && d.lostCount === 0);

  const chartData = data.map((d) => ({
    ...d,
    won: localMetric === 'value' ? d.wonValue / 100 : d.wonCount,
    lost: localMetric === 'value' ? d.lostValue / 100 : d.lostCount,
  }));

  const renderTooltip = useCallback(
    ({
      active,
      payload,
      label,
    }: {
      active?: boolean;
      payload?: { dataKey?: string; value?: number }[];
      label?: string;
    }) => {
      if (!active || !payload || payload.length === 0) return null;

      const wonData = payload.find((p) => p.dataKey === 'won');
      const lostData = payload.find((p) => p.dataKey === 'lost');

      return (
        <div className="recharts-default-tooltip">
          <p className="recharts-tooltip-label">{label}</p>
          {wonData && typeof wonData.value === 'number' && (
            <p className="recharts-tooltip-item" style={{ color: 'var(--color-success)' }}>
              Won:{' '}
              {localMetric === 'value'
                ? formatCurrency(wonData.value * 100, currency)
                : `${wonData.value} deals`}
            </p>
          )}
          {lostData && typeof lostData.value === 'number' && (
            <p className="recharts-tooltip-item" style={{ color: 'var(--color-danger)' }}>
              Lost:{' '}
              {localMetric === 'value'
                ? formatCurrency(lostData.value * 100, currency)
                : `${lostData.value} deals`}
            </p>
          )}
        </div>
      );
    },
    [currency, localMetric]
  );

  return (
    <ChartContainer
      title="Sales Trend"
      subtitle={localMetric === 'value' ? 'Revenue over time' : 'Opportunities over time'}
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height + (showControls ? 50 : 0)}
      emptyMessage="No closed opportunities in this period"
    >
      <div style={{ width: '100%', height: '100%' }}>
        {showControls && (
          <div className="sales-trend-chart__controls">
            <button
              className={`sales-trend-chart__control ${localMetric === 'value' ? 'sales-trend-chart__control--active' : ''}`}
              onClick={() => setLocalMetric('value')}
            >
              Value
            </button>
            <button
              className={`sales-trend-chart__control ${localMetric === 'count' ? 'sales-trend-chart__control--active' : ''}`}
              onClick={() => setLocalMetric('count')}
            >
              Count
            </button>
            <span style={{ flex: 1 }} />
            {onGranularityChange && (
              <>
                <button
                  className={`sales-trend-chart__control ${granularity === 'daily' ? 'sales-trend-chart__control--active' : ''}`}
                  onClick={() => onGranularityChange('daily')}
                >
                  Daily
                </button>
                <button
                  className={`sales-trend-chart__control ${granularity === 'weekly' ? 'sales-trend-chart__control--active' : ''}`}
                  onClick={() => onGranularityChange('weekly')}
                >
                  Weekly
                </button>
                <button
                  className={`sales-trend-chart__control ${granularity === 'monthly' ? 'sales-trend-chart__control--active' : ''}`}
                  onClick={() => onGranularityChange('monthly')}
                >
                  Monthly
                </button>
              </>
            )}
          </div>
        )}
        <ResponsiveContainer width="100%" height={showControls ? height - 50 : '100%'}>
          <LineChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
            <XAxis
              dataKey="label"
              stroke="var(--color-text-muted)"
              fontSize={12}
              tickLine={false}
            />
            <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
            <Tooltip content={renderTooltip as any} />
            <Legend />
            <Line
              type="monotone"
              dataKey="won"
              name="Won"
              stroke="var(--color-success)"
              strokeWidth={2}
              dot={{ r: 4 }}
              activeDot={{ r: 6 }}
            />
            <Line
              type="monotone"
              dataKey="lost"
              name="Lost"
              stroke="var(--color-danger)"
              strokeWidth={2}
              dot={{ r: 4 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ChartContainer>
  );
}

export default SalesTrendChart;
