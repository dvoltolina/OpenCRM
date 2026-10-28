/**
 * ForecastVsGoal Component
 * Shows company forecast vs monthly goal (Empire View)
 */

import { useMemo } from 'react';

export interface ForecastVsGoalProps {
  /** Current won revenue in cents */
  wonRevenueCents: number;
  /** Weighted forecast (open deals * probability) in cents */
  forecastCents: number;
  /** Monthly goal in cents */
  goalCents: number;
  /** Currency code */
  currency?: string;
  /** Period label */
  periodLabel?: string;
}

function formatCurrency(cents: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(
    cents / 100
  );
}

function formatCompact(cents: number, currency: string = 'USD') {
  const value = cents / 100;
  if (value >= 1000000) {
    return `${currency === 'USD' ? '$' : ''}${(value / 1000000).toFixed(1)}M`;
  }
  if (value >= 1000) {
    return `${currency === 'USD' ? '$' : ''}${(value / 1000).toFixed(0)}K`;
  }
  return formatCurrency(cents, currency);
}

export function ForecastVsGoal({
  wonRevenueCents,
  forecastCents,
  goalCents,
  currency = 'USD',
  periodLabel = 'This Month',
}: ForecastVsGoalProps) {
  const progressPercent = useMemo(() => {
    if (goalCents <= 0) return 0;
    return (wonRevenueCents / goalCents) * 100;
  }, [wonRevenueCents, goalCents]);

  const projectedPercent = useMemo(() => {
    if (goalCents <= 0) return 0;
    return ((wonRevenueCents + forecastCents) / goalCents) * 100;
  }, [wonRevenueCents, forecastCents, goalCents]);

  const gapCents = goalCents - wonRevenueCents - forecastCents;
  const isOnTrack = projectedPercent >= 100;
  const isAtRisk = projectedPercent < 80;

  const statusClass = isOnTrack
    ? 'forecast-goal--on-track'
    : isAtRisk
      ? 'forecast-goal--at-risk'
      : 'forecast-goal--warning';

  return (
    <div className={`forecast-goal ${statusClass}`}>
      <div className="forecast-goal__header">
        <h3 className="forecast-goal__title">Forecast vs Goal</h3>
        <span className="forecast-goal__period">{periodLabel}</span>
      </div>

      {/* Visual Progress Bar */}
      <div className="forecast-goal__visual">
        <div className="forecast-goal__bar-container">
          {/* Won segment */}
          <div
            className="forecast-goal__bar forecast-goal__bar--won"
            style={{ width: `${Math.min(100, progressPercent)}%` }}
            title={`Won: ${formatCurrency(wonRevenueCents, currency)}`}
          />
          {/* Forecast segment */}
          <div
            className="forecast-goal__bar forecast-goal__bar--forecast"
            style={{
              width: `${Math.min(100 - Math.min(100, progressPercent), (forecastCents / goalCents) * 100)}%`,
              left: `${Math.min(100, progressPercent)}%`,
            }}
            title={`Forecast: ${formatCurrency(forecastCents, currency)}`}
          />
          {/* Goal marker */}
          <div className="forecast-goal__marker" style={{ left: '100%' }} />
        </div>
        <div className="forecast-goal__labels">
          <span>0</span>
          <span className="forecast-goal__goal-label">
            Goal: {formatCompact(goalCents, currency)}
          </span>
        </div>
      </div>

      {/* Breakdown */}
      <div className="forecast-goal__breakdown">
        <div className="forecast-goal__item forecast-goal__item--won">
          <span className="forecast-goal__item-icon">✅</span>
          <div className="forecast-goal__item-info">
            <span className="forecast-goal__item-label">Won</span>
            <span className="forecast-goal__item-value">
              {formatCurrency(wonRevenueCents, currency)}
            </span>
          </div>
          <span className="forecast-goal__item-percent">
            {progressPercent.toFixed(0)}%
          </span>
        </div>

        <div className="forecast-goal__item forecast-goal__item--forecast">
          <span className="forecast-goal__item-icon">📊</span>
          <div className="forecast-goal__item-info">
            <span className="forecast-goal__item-label">Forecast</span>
            <span className="forecast-goal__item-value">
              {formatCurrency(forecastCents, currency)}
            </span>
          </div>
          <span className="forecast-goal__item-percent">
            +{((forecastCents / goalCents) * 100).toFixed(0)}%
          </span>
        </div>

        {gapCents > 0 && (
          <div className="forecast-goal__item forecast-goal__item--gap">
            <span className="forecast-goal__item-icon">🎯</span>
            <div className="forecast-goal__item-info">
              <span className="forecast-goal__item-label">Gap to Goal</span>
              <span className="forecast-goal__item-value">
                {formatCurrency(gapCents, currency)}
              </span>
            </div>
          </div>
        )}
      </div>

      {/* Status Message */}
      <div className="forecast-goal__status">
        {isOnTrack ? (
          <span className="forecast-goal__status--positive">
            🎉 On track to hit {projectedPercent.toFixed(0)}% of goal!
          </span>
        ) : isAtRisk ? (
          <span className="forecast-goal__status--negative">
            ⚠️ At risk - projected {projectedPercent.toFixed(0)}% of goal
          </span>
        ) : (
          <span className="forecast-goal__status--warning">
            ⚡ Push needed - projected {projectedPercent.toFixed(0)}% of goal
          </span>
        )}
      </div>
    </div>
  );
}

export default ForecastVsGoal;
