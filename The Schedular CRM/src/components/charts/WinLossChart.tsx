/**
 * WinLossChart Component
 * Comparison chart of won vs lost deals
 *
 * Agent CRM-19 Implementation
 */

import { useCallback } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  ReferenceLine,
} from 'recharts';
import { ChartContainer } from './ChartContainer';
import type { SalesDataPoint } from '../../hooks/useSalesChartData';
import './charts.css';

// ============================================
// Types
// ============================================

export interface WinLossChartProps {
  /** Sales data points */
  data: SalesDataPoint[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
  /** Currency for value formatting */
  currency?: string;
  /** Show value or count */
  metric?: 'value' | 'count';
}

interface WinLossTooltipPayload {
  dataKey?: 'won' | 'lost';
  value?: number;
}

interface WinLossTooltipArgs {
  active?: boolean;
  payload?: readonly WinLossTooltipPayload[];
  label?: string | number;
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
  }).format(value);
}

// ============================================
// Component
// ============================================

/**
 * WinLossChart - Won vs Lost comparison
 *
 * @example
 * ```tsx
 * const { data } = useSalesChartData(deals, { granularity: 'monthly', periods: 6 });
 *
 * <WinLossChart
 *   data={data}
 *   metric="value"
 *   currency="USD"
 * />
 * ```
 */
export function WinLossChart({
  data,
  isLoading = false,
  height = 300,
  currency = 'USD',
  metric = 'count',
}: WinLossChartProps) {
  const isEmpty = data.every((d) => d.wonCount === 0 && d.lostCount === 0);

  // Calculate totals for summary
  const totals = data.reduce(
    (acc, d) => ({
      won: acc.won + d.wonCount,
      lost: acc.lost + d.lostCount,
      wonValue: acc.wonValue + d.wonValue,
      lostValue: acc.lostValue + d.lostValue,
    }),
    { won: 0, lost: 0, wonValue: 0, lostValue: 0 }
  );

  const winRate = totals.won + totals.lost > 0
    ? Math.round((totals.won / (totals.won + totals.lost)) * 100)
    : 0;

  const chartData = data.map((d) => ({
    ...d,
    won: metric === 'value' ? d.wonValue / 100 : d.wonCount,
    lost: metric === 'value' ? -(d.lostValue / 100) : -d.lostCount,
  }));

  const renderTooltip = useCallback(
    ({ active, payload, label }: WinLossTooltipArgs) => {
      if (!active || !payload || payload.length === 0) return null;

      const wonData = payload.find((entry) => entry.dataKey === 'won');
      const lostData = payload.find((entry) => entry.dataKey === 'lost');

      return (
        <div className="recharts-default-tooltip">
          <p className="recharts-tooltip-label">{label}</p>
          {wonData && typeof wonData.value === 'number' && (
            <p className="recharts-tooltip-item" style={{ color: 'var(--color-success)' }}>
              Won: {metric === 'value'
                ? formatCurrency(Math.abs(wonData.value), currency)
                : `${Math.abs(wonData.value)} opportunities`}
            </p>
          )}
          {lostData && typeof lostData.value === 'number' && (
            <p className="recharts-tooltip-item" style={{ color: 'var(--color-danger)' }}>
              Lost: {metric === 'value'
                ? formatCurrency(Math.abs(lostData.value), currency)
                : `${Math.abs(lostData.value)} opportunities`}
            </p>
          )}
        </div>
      );
    },
    [currency, metric]
  );

  return (
    <ChartContainer
      title="Win/Loss Analysis"
      subtitle={`Win rate: ${winRate}%`}
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height + 80}
      emptyMessage="No closed opportunities to analyze"
    >
      <div style={{ width: '100%', height: '100%' }}>
        {/* Summary */}
        <div className="win-loss-chart__summary">
          <div className="win-loss-chart__stat">
            <div className="win-loss-chart__stat-value win-loss-chart__stat-value--won">
              {metric === 'value' ? formatCurrency(totals.wonValue / 100, currency) : totals.won}
            </div>
            <div className="win-loss-chart__stat-label">
              {metric === 'value' ? 'Won Revenue' : 'Opportunities Won'}
            </div>
          </div>
          <div className="win-loss-chart__stat">
            <div className="win-loss-chart__stat-value win-loss-chart__stat-value--lost">
              {metric === 'value' ? formatCurrency(totals.lostValue / 100, currency) : totals.lost}
            </div>
            <div className="win-loss-chart__stat-label">
              {metric === 'value' ? 'Lost Revenue' : 'Opportunities Lost'}
            </div>
          </div>
        </div>

        {/* Chart */}
        <ResponsiveContainer width="100%" height={height - 80}>
          <BarChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
            <XAxis
              dataKey="label"
              stroke="var(--color-text-muted)"
              fontSize={12}
              tickLine={false}
            />
            <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
            <Tooltip content={renderTooltip} />
            <Legend />
            <ReferenceLine y={0} stroke="var(--color-border)" />
            <Bar
              dataKey="won"
              name="Won"
              fill="var(--color-success)"
              radius={[4, 4, 0, 0]}
            />
            <Bar
              dataKey="lost"
              name="Lost"
              fill="var(--color-danger)"
              radius={[0, 0, 4, 4]}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ChartContainer>
  );
}

export default WinLossChart;
