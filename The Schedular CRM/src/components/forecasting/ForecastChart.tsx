/**
 * ForecastChart Component
 * Visual chart showing forecast pipeline distribution
 */

import { useMemo } from 'react';
import { useForecast, formatCurrency } from '../../hooks/useForecasting';
import type { GoalPeriod, ForecastStageBreakdown } from '../../types/goals';

// ============================================
// Types
// ============================================

export interface ForecastChartProps {
  /** Period for forecast */
  period: GoalPeriod;
  /** Pipeline to filter by (optional) */
  pipelineId?: string;
  /** Chart type */
  chartType?: 'funnel' | 'bar' | 'waterfall';
  /** Height in pixels */
  height?: number;
}

// ============================================
// Constants
// ============================================

const STAGE_COLORS = [
  '#f87171', // red-400
  '#fb923c', // orange-400
  '#fbbf24', // amber-400
  '#a3e635', // lime-400
  '#34d399', // emerald-400
  '#22d3ee', // cyan-400
  '#60a5fa', // blue-400
  '#a78bfa', // violet-400
];

// ============================================
// Sub-components
// ============================================

function FunnelChart({
  breakdown,
  height,
}: {
  breakdown: ForecastStageBreakdown[];
  height: number;
}) {
  // Sort by probability (pipeline order)
  const sorted = useMemo(
    () => [...breakdown].sort((a, b) => a.probability - b.probability),
    [breakdown]
  );

  const maxValue = useMemo(
    () => Math.max(...sorted.map((s) => s.totalValueCents), 1),
    [sorted]
  );

  if (sorted.length === 0) {
    return (
      <div className="forecast-chart__empty" style={{ height }}>
        No pipeline data available
      </div>
    );
  }

  return (
    <div className="forecast-chart__funnel" style={{ height }}>
      {sorted.map((stage, index) => {
        const widthPercent = Math.max(20, (stage.totalValueCents / maxValue) * 100);
        const color = STAGE_COLORS[index % STAGE_COLORS.length];

        return (
          <div
            key={stage.stageId}
            className="forecast-chart__funnel-stage"
            style={{
              width: `${widthPercent}%`,
              backgroundColor: color,
            }}
            title={`${stage.stageName}: ${formatCurrency(stage.totalValueCents)} (${stage.dealCount} deals)`}
          >
            <span className="forecast-chart__funnel-label">
              {stage.stageName}
            </span>
            <span className="forecast-chart__funnel-value">
              {formatCurrency(stage.weightedValueCents)}
            </span>
            <span className="forecast-chart__funnel-count">
              {stage.dealCount} deal{stage.dealCount !== 1 ? 's' : ''}
            </span>
          </div>
        );
      })}
    </div>
  );
}

function BarChart({
  breakdown,
  height,
}: {
  breakdown: ForecastStageBreakdown[];
  height: number;
}) {
  // Sort by probability (pipeline order)
  const sorted = useMemo(
    () => [...breakdown].sort((a, b) => a.probability - b.probability),
    [breakdown]
  );

  const maxValue = useMemo(
    () => Math.max(...sorted.map((s) => s.totalValueCents), 1),
    [sorted]
  );

  if (sorted.length === 0) {
    return (
      <div className="forecast-chart__empty" style={{ height }}>
        No pipeline data available
      </div>
    );
  }

  const barHeight = Math.max(30, (height - 40) / sorted.length);

  return (
    <div className="forecast-chart__bar-container" style={{ height }}>
      {sorted.map((stage, index) => {
        const widthPercent = (stage.totalValueCents / maxValue) * 100;
        const weightedWidthPercent = (stage.weightedValueCents / maxValue) * 100;
        const color = STAGE_COLORS[index % STAGE_COLORS.length];

        return (
          <div
            key={stage.stageId}
            className="forecast-chart__bar-row"
            style={{ height: barHeight }}
          >
            <div className="forecast-chart__bar-label">
              <span className="forecast-chart__bar-stage-name">{stage.stageName}</span>
              <span className="forecast-chart__bar-probability">{stage.probability}%</span>
            </div>
            <div className="forecast-chart__bar-track">
              {/* Total value (lighter) */}
              <div
                className="forecast-chart__bar-total"
                style={{
                  width: `${widthPercent}%`,
                  backgroundColor: `${color}40`,
                }}
              />
              {/* Weighted value (solid) */}
              <div
                className="forecast-chart__bar-weighted"
                style={{
                  width: `${weightedWidthPercent}%`,
                  backgroundColor: color,
                }}
                title={`Weighted: ${formatCurrency(stage.weightedValueCents)}`}
              />
            </div>
            <div className="forecast-chart__bar-value">
              {formatCurrency(stage.weightedValueCents)}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function WaterfallChart({
  breakdown,
  height,
}: {
  breakdown: ForecastStageBreakdown[];
  height: number;
}) {
  // Sort by probability descending (highest first for waterfall)
  const sorted = useMemo(
    () => [...breakdown].sort((a, b) => b.probability - a.probability),
    [breakdown]
  );

  const total = useMemo(
    () => sorted.reduce((sum, s) => sum + s.weightedValueCents, 0),
    [sorted]
  );

  const segments = useMemo(() => {
    let cumulative = 0;
    return sorted.map((stage, index) => {
      const startPercent = (cumulative / total) * 100;
      const widthPercent = (stage.weightedValueCents / total) * 100;
      cumulative += stage.weightedValueCents;

      return {
        stage,
        index,
        startPercent,
        widthPercent,
        color: STAGE_COLORS[index % STAGE_COLORS.length],
      };
    });
  }, [sorted, total]);

  if (sorted.length === 0 || total === 0) {
    return (
      <div className="forecast-chart__empty" style={{ height }}>
        No pipeline data available
      </div>
    );
  }

  return (
    <div className="forecast-chart__waterfall" style={{ height }}>
      <div className="forecast-chart__waterfall-bars">
        {segments.map(({ stage, startPercent, widthPercent, color }) => (
          <div
            key={stage.stageId}
            className="forecast-chart__waterfall-segment"
            style={{
              left: `${startPercent}%`,
              width: `${widthPercent}%`,
              backgroundColor: color,
            }}
            title={`${stage.stageName}: ${formatCurrency(stage.weightedValueCents)}`}
          >
            {widthPercent > 10 && (
              <span className="forecast-chart__waterfall-label">
                {stage.stageName}
              </span>
            )}
          </div>
        ))}
      </div>
      <div className="forecast-chart__waterfall-legend">
        {sorted.map((stage, index) => (
          <div key={stage.stageId} className="forecast-chart__waterfall-legend-item">
            <span
              className="forecast-chart__waterfall-legend-color"
              style={{ backgroundColor: STAGE_COLORS[index % STAGE_COLORS.length] }}
            />
            <span className="forecast-chart__waterfall-legend-name">{stage.stageName}</span>
            <span className="forecast-chart__waterfall-legend-value">
              {formatCurrency(stage.weightedValueCents)}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================
// Main Component
// ============================================

export function ForecastChart({
  period,
  pipelineId,
  chartType = 'bar',
  height = 300,
}: ForecastChartProps) {
  const { forecast, isLoading, error, refresh } = useForecast({
    period,
    pipelineId,
  });

  // Loading state
  if (isLoading) {
    return (
      <div
        className="forecast-chart forecast-chart--loading"
        style={{ height }}
        data-testid="forecast-chart"
      >
        <div className="forecast-chart__loading">Loading chart...</div>
      </div>
    );
  }

  // Error state
  if (error || !forecast) {
    return (
      <div
        className="forecast-chart forecast-chart--error"
        style={{ height }}
        data-testid="forecast-chart"
      >
        <div className="forecast-chart__error">
          <span>Unable to load chart data</span>
          <button className="forecast-chart__retry-btn" onClick={refresh}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  const breakdown = forecast.stageBreakdown || [];

  return (
    <div className="forecast-chart" data-testid="forecast-chart">
      <div className="forecast-chart__header">
        <h4 className="forecast-chart__title">Pipeline Distribution</h4>
        <span className="forecast-chart__total">
          Total Weighted: {formatCurrency(forecast.projectedRevenue)}
        </span>
      </div>

      <div className="forecast-chart__body">
        {chartType === 'funnel' && <FunnelChart breakdown={breakdown} height={height - 60} />}
        {chartType === 'bar' && <BarChart breakdown={breakdown} height={height - 60} />}
        {chartType === 'waterfall' && <WaterfallChart breakdown={breakdown} height={height - 60} />}
      </div>
    </div>
  );
}

export default ForecastChart;
