/**
 * ForecastWidget Component
 * Displays revenue forecast summary with key metrics
 */

import { useState } from 'react';
import { useForecastSummary, formatCurrency, getPeriodDisplayName } from '../../hooks/useForecasting';
import type { GoalPeriod } from '../../types/goals';

// ============================================
// Types
// ============================================

export interface ForecastWidgetProps {
  /** Initial period to display */
  initialPeriod?: GoalPeriod;
  /** Pipeline to filter by (optional) */
  pipelineId?: string;
  /** Target revenue for comparison (optional) */
  targetRevenue?: number;
  /** Show period selector */
  showPeriodSelector?: boolean;
  /** Compact display mode */
  compact?: boolean;
}

// ============================================
// Constants
// ============================================

const PERIOD_OPTIONS: { value: GoalPeriod; label: string }[] = [
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'yearly', label: 'Yearly' },
];

const CONFIDENCE_STYLES: Record<string, { label: string; className: string }> = {
  high: { label: 'High Confidence', className: 'forecast-widget__confidence--high' },
  medium: { label: 'Medium Confidence', className: 'forecast-widget__confidence--medium' },
  low: { label: 'Low Confidence', className: 'forecast-widget__confidence--low' },
};

// ============================================
// Sub-components
// ============================================

function MetricCard({
  label,
  value,
  subtext,
  highlight,
}: {
  label: string;
  value: string;
  subtext?: string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`forecast-widget__metric ${highlight ? 'forecast-widget__metric--highlight' : ''}`}
    >
      <span className="forecast-widget__metric-label">{label}</span>
      <span className="forecast-widget__metric-value">{value}</span>
      {subtext && <span className="forecast-widget__metric-subtext">{subtext}</span>}
    </div>
  );
}

// ============================================
// Main Component
// ============================================

export function ForecastWidget({
  initialPeriod = 'monthly',
  pipelineId,
  targetRevenue,
  showPeriodSelector = true,
  compact = false,
}: ForecastWidgetProps) {
  const [period, setPeriod] = useState<GoalPeriod>(initialPeriod);

  const { summary, isLoading, error, refresh } = useForecastSummary({
    period,
    pipelineId,
    targetRevenue,
  });

  // Loading state
  if (isLoading) {
    return (
      <div
        className={`forecast-widget forecast-widget--loading ${compact ? 'forecast-widget--compact' : ''}`}
        data-testid="forecast-widget"
      >
        <div className="forecast-widget__loading-spinner" />
        <span>Loading forecast...</span>
      </div>
    );
  }

  // Error state
  if (error || !summary) {
    return (
      <div
        className={`forecast-widget forecast-widget--error ${compact ? 'forecast-widget--compact' : ''}`}
        data-testid="forecast-widget"
      >
        <span className="forecast-widget__error-message">
          Unable to load forecast data
        </span>
        <button className="forecast-widget__retry-btn" onClick={refresh}>
          Retry
        </button>
      </div>
    );
  }

  const { forecast, commitmentRatio, confidenceLevel, gapToTarget, isOnTrack } = summary;
  const confidenceStyle = CONFIDENCE_STYLES[confidenceLevel];

  return (
    <div
      className={`forecast-widget ${compact ? 'forecast-widget--compact' : ''}`}
      data-testid="forecast-widget"
    >
      {/* Header */}
      <div className="forecast-widget__header">
        <div className="forecast-widget__title-group">
          <h3 className="forecast-widget__title">Revenue Forecast</h3>
          <span className="forecast-widget__period-label">{getPeriodDisplayName(period)}</span>
        </div>
        {showPeriodSelector && (
          <select
            className="forecast-widget__period-select"
            value={period}
            onChange={(e) => setPeriod(e.target.value as GoalPeriod)}
            aria-label="Select forecast period"
          >
            {PERIOD_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        )}
      </div>

      {/* Metrics Grid */}
      <div className="forecast-widget__metrics">
        <MetricCard
          label="Projected"
          value={formatCurrency(forecast.projectedRevenue)}
          subtext="Weighted by stage probability"
          highlight
        />
        <MetricCard
          label="Committed"
          value={formatCurrency(forecast.committed)}
          subtext="Deals with 80%+ probability"
        />
        <MetricCard
          label="Closed"
          value={formatCurrency(forecast.closed)}
          subtext="Already won this period"
        />
        <MetricCard
          label="Best Case"
          value={formatCurrency(forecast.bestCase)}
          subtext="All open deals"
        />
      </div>

      {/* Target Progress (if target provided) */}
      {targetRevenue !== undefined && targetRevenue > 0 && (
        <div className="forecast-widget__target-section">
          <div className="forecast-widget__target-header">
            <span className="forecast-widget__target-label">Target: {formatCurrency(targetRevenue)}</span>
            <span
              className={`forecast-widget__target-status ${isOnTrack ? 'forecast-widget__target-status--on-track' : 'forecast-widget__target-status--behind'}`}
            >
              {isOnTrack ? 'On Track' : `${formatCurrency(Math.abs(gapToTarget || 0))} behind`}
            </span>
          </div>
          <div className="forecast-widget__target-bar">
            <div
              className="forecast-widget__target-fill"
              style={{
                width: `${Math.min(100, (forecast.projectedRevenue / targetRevenue) * 100)}%`,
              }}
            />
            <div
              className="forecast-widget__target-closed"
              style={{
                width: `${Math.min(100, (forecast.closed / targetRevenue) * 100)}%`,
              }}
            />
          </div>
        </div>
      )}

      {/* Footer */}
      <div className="forecast-widget__footer">
        <span className={`forecast-widget__confidence ${confidenceStyle.className}`}>
          {confidenceStyle.label}
        </span>
        <span className="forecast-widget__commitment-ratio">
          {Math.round(commitmentRatio)}% committed
        </span>
      </div>
    </div>
  );
}

export default ForecastWidget;
