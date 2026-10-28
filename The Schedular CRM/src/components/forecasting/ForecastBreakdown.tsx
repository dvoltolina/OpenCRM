/**
 * ForecastBreakdown Component
 * Detailed breakdown of forecast by stage and rep
 */

import { useState } from 'react';
import { useForecast, formatCurrency } from '../../hooks/useForecasting';
import type { GoalPeriod, ForecastStageBreakdown, ForecastRepBreakdown } from '../../types/goals';

// ============================================
// Types
// ============================================

export interface ForecastBreakdownProps {
  /** Period for forecast */
  period: GoalPeriod;
  /** Pipeline to filter by (optional) */
  pipelineId?: string;
  /** Default view tab */
  defaultView?: 'stage' | 'rep';
}

// ============================================
// Sub-components
// ============================================

function StageBreakdownTable({ breakdown }: { breakdown: ForecastStageBreakdown[] }) {
  if (breakdown.length === 0) {
    return (
      <div className="forecast-breakdown__empty">
        No deals in pipeline for this period.
      </div>
    );
  }

  // Sort by probability (pipeline order)
  const sorted = [...breakdown].sort((a, b) => a.probability - b.probability);

  return (
    <table className="forecast-breakdown__table" data-testid="stage-breakdown-table">
      <thead>
        <tr>
          <th className="forecast-breakdown__th">Stage</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Probability</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Deals</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Total Value</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Weighted</th>
        </tr>
      </thead>
      <tbody>
        {sorted.map((stage) => (
          <tr key={stage.stageId} className="forecast-breakdown__row">
            <td className="forecast-breakdown__td">
              <span className="forecast-breakdown__stage-name">{stage.stageName}</span>
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              <span
                className={`forecast-breakdown__probability ${stage.probability >= 80 ? 'forecast-breakdown__probability--high' : stage.probability >= 50 ? 'forecast-breakdown__probability--medium' : 'forecast-breakdown__probability--low'}`}
              >
                {stage.probability}%
              </span>
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              {stage.dealCount}
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              {formatCurrency(stage.totalValueCents)}
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              <strong>{formatCurrency(stage.weightedValueCents)}</strong>
            </td>
          </tr>
        ))}
      </tbody>
      <tfoot>
        <tr className="forecast-breakdown__total-row">
          <td className="forecast-breakdown__td">Total</td>
          <td className="forecast-breakdown__td"></td>
          <td className="forecast-breakdown__td forecast-breakdown__td--right">
            {sorted.reduce((sum, s) => sum + s.dealCount, 0)}
          </td>
          <td className="forecast-breakdown__td forecast-breakdown__td--right">
            {formatCurrency(sorted.reduce((sum, s) => sum + s.totalValueCents, 0))}
          </td>
          <td className="forecast-breakdown__td forecast-breakdown__td--right">
            <strong>
              {formatCurrency(sorted.reduce((sum, s) => sum + s.weightedValueCents, 0))}
            </strong>
          </td>
        </tr>
      </tfoot>
    </table>
  );
}

function RepBreakdownTable({ breakdown }: { breakdown: ForecastRepBreakdown[] }) {
  if (!breakdown || breakdown.length === 0) {
    return (
      <div className="forecast-breakdown__empty">
        No rep-level data available.
      </div>
    );
  }

  // Sort by projected revenue descending
  const sorted = [...breakdown].sort((a, b) => b.projectedRevenue - a.projectedRevenue);

  return (
    <table className="forecast-breakdown__table" data-testid="rep-breakdown-table">
      <thead>
        <tr>
          <th className="forecast-breakdown__th">#</th>
          <th className="forecast-breakdown__th">Rep</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Deals</th>
          <th className="forecast-breakdown__th forecast-breakdown__th--right">Projected</th>
        </tr>
      </thead>
      <tbody>
        {sorted.map((rep, index) => (
          <tr key={rep.userId} className="forecast-breakdown__row">
            <td className="forecast-breakdown__td">
              {index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : index + 1}
            </td>
            <td className="forecast-breakdown__td">
              <span className="forecast-breakdown__rep-name">{rep.userName}</span>
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              {rep.dealCount}
            </td>
            <td className="forecast-breakdown__td forecast-breakdown__td--right">
              <strong>{formatCurrency(rep.projectedRevenue)}</strong>
            </td>
          </tr>
        ))}
      </tbody>
      <tfoot>
        <tr className="forecast-breakdown__total-row">
          <td className="forecast-breakdown__td"></td>
          <td className="forecast-breakdown__td">Total</td>
          <td className="forecast-breakdown__td forecast-breakdown__td--right">
            {sorted.reduce((sum, r) => sum + r.dealCount, 0)}
          </td>
          <td className="forecast-breakdown__td forecast-breakdown__td--right">
            <strong>
              {formatCurrency(sorted.reduce((sum, r) => sum + r.projectedRevenue, 0))}
            </strong>
          </td>
        </tr>
      </tfoot>
    </table>
  );
}

// ============================================
// Main Component
// ============================================

export function ForecastBreakdown({
  period,
  pipelineId,
  defaultView = 'stage',
}: ForecastBreakdownProps) {
  const [activeView, setActiveView] = useState<'stage' | 'rep'>(defaultView);

  const { forecast, isLoading, error, refresh, recalculate } = useForecast({
    period,
    pipelineId,
  });

  // Loading state
  if (isLoading) {
    return (
      <div className="forecast-breakdown forecast-breakdown--loading" data-testid="forecast-breakdown">
        <div className="forecast-breakdown__loading">Loading breakdown...</div>
      </div>
    );
  }

  // Error state
  if (error || !forecast) {
    return (
      <div className="forecast-breakdown forecast-breakdown--error" data-testid="forecast-breakdown">
        <div className="forecast-breakdown__error">
          <span>Unable to load forecast breakdown</span>
          <button className="forecast-breakdown__retry-btn" onClick={refresh}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="forecast-breakdown" data-testid="forecast-breakdown">
      {/* Header with tabs */}
      <div className="forecast-breakdown__header">
        <div className="forecast-breakdown__tabs">
          <button
            className={`forecast-breakdown__tab ${activeView === 'stage' ? 'forecast-breakdown__tab--active' : ''}`}
            onClick={() => setActiveView('stage')}
          >
            By Stage
          </button>
          <button
            className={`forecast-breakdown__tab ${activeView === 'rep' ? 'forecast-breakdown__tab--active' : ''}`}
            onClick={() => setActiveView('rep')}
          >
            By Rep
          </button>
        </div>
        <button
          className="forecast-breakdown__recalculate-btn"
          onClick={() => recalculate()}
          title="Recalculate forecast from current deals"
        >
          Recalculate
        </button>
      </div>

      {/* Content */}
      <div className="forecast-breakdown__content">
        {activeView === 'stage' ? (
          <StageBreakdownTable breakdown={forecast.stageBreakdown || []} />
        ) : (
          <RepBreakdownTable breakdown={forecast.repBreakdown || []} />
        )}
      </div>

      {/* Footer with last calculated time */}
      <div className="forecast-breakdown__footer">
        <span className="forecast-breakdown__last-updated">
          Last calculated: {new Date(forecast.lastCalculatedAt).toLocaleString()}
        </span>
      </div>
    </div>
  );
}

export default ForecastBreakdown;
