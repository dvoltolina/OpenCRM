/**
 * QuotaProgress Component
 * Shows personal quota progress for sales reps (Hunter View)
 */

import { useMemo } from 'react';

export interface QuotaProgressProps {
  /** Current achieved value in cents */
  currentValueCents: number;
  /** Target quota value in cents */
  targetValueCents: number;
  /** Label for the progress bar */
  label?: string;
  /** Currency code */
  currency?: string;
  /** Show percentage */
  showPercentage?: boolean;
}

function formatCurrency(cents: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(
    cents / 100
  );
}

export function QuotaProgress({
  currentValueCents,
  targetValueCents,
  label = 'My Quota Progress',
  currency = 'USD',
  showPercentage = true,
}: QuotaProgressProps) {
  const progressPercent = useMemo(() => {
    if (targetValueCents <= 0) return 0;
    return Math.min(100, (currentValueCents / targetValueCents) * 100);
  }, [currentValueCents, targetValueCents]);

  const isAhead = progressPercent >= 100;
  const isOnTrack = progressPercent >= 75;
  const isBehind = progressPercent < 50;

  const statusClass = isAhead
    ? 'quota-progress--ahead'
    : isOnTrack
      ? 'quota-progress--on-track'
      : isBehind
        ? 'quota-progress--behind'
        : 'quota-progress--warning';

  const statusEmoji = isAhead ? '🎉' : isOnTrack ? '💪' : isBehind ? '📈' : '⚡';
  const statusText = isAhead
    ? 'Quota achieved!'
    : isOnTrack
      ? 'On track'
      : isBehind
        ? 'Push harder!'
        : 'Almost there';

  return (
    <div className={`quota-progress ${statusClass}`}>
      <div className="quota-progress__header">
        <span className="quota-progress__label">{label}</span>
        {showPercentage && (
          <span className="quota-progress__percent">
            {progressPercent.toFixed(0)}%
          </span>
        )}
      </div>
      <div className="quota-progress__bar-container">
        <div
          className="quota-progress__bar"
          style={{ width: `${Math.min(100, progressPercent)}%` }}
        />
        {progressPercent > 100 && (
          <div
            className="quota-progress__bar quota-progress__bar--overflow"
            style={{ width: `${Math.min(20, progressPercent - 100)}%` }}
          />
        )}
      </div>
      <div className="quota-progress__footer">
        <span className="quota-progress__current">
          {formatCurrency(currentValueCents, currency)}
        </span>
        <span className="quota-progress__separator">/</span>
        <span className="quota-progress__target">
          {formatCurrency(targetValueCents, currency)}
        </span>
      </div>
      <div className="quota-progress__status">
        <span className="quota-progress__status-emoji">{statusEmoji}</span>
        <span className="quota-progress__status-text">{statusText}</span>
      </div>
    </div>
  );
}

export default QuotaProgress;
