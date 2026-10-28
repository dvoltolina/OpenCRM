/**
 * MetricWidget Component
 * Displays a single key metric with comparison to previous period.
 *
 * HIPAA Compliance:
 * - Displays aggregated metrics only, no PHI
 * - All metric access logged via parent components
 *
 * Agent CRM - Task 7 Implementation
 */

import { useMemo } from 'react';
import type { MetricValue, MetricWidgetConfig } from '../../../types/reporting';

// ============================================
// Types
// ============================================

export interface MetricWidgetProps {
  /** Widget title */
  title: string;
  /** Metric configuration */
  config?: MetricWidgetConfig;
  /** Current metric value */
  value: MetricValue | null;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Currency for value formatting */
  currency?: string;
  /** Click handler */
  onClick?: () => void;
}

// ============================================
// Helper Functions
// ============================================

function formatValue(
  value: number,
  format: 'number' | 'currency' | 'percent' | undefined,
  currency: string
): string {
  switch (format) {
    case 'currency':
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(value / 100);

    case 'percent':
      return `${value.toFixed(1)}%`;

    case 'number':
    default:
      if (value >= 1000000) {
        return `${(value / 1000000).toFixed(1)}M`;
      }
      if (value >= 1000) {
        return `${(value / 1000).toFixed(1)}K`;
      }
      return new Intl.NumberFormat('en-US').format(value);
  }
}

function getTrendClass(changePercent: number): string {
  if (changePercent > 0) return 'metric-widget__trend--up';
  if (changePercent < 0) return 'metric-widget__trend--down';
  return 'metric-widget__trend--neutral';
}

function getTrendIcon(changePercent: number): string {
  if (changePercent > 0) return '↑';
  if (changePercent < 0) return '↓';
  return '→';
}

// ============================================
// Main Component
// ============================================

/**
 * MetricWidget - Single metric display with trend indicator
 *
 * Features:
 * - Displays current value
 * - Shows change from previous period
 * - Trend indicator (up/down/neutral)
 * - Support for different formats (number, currency, percent)
 *
 * @example
 * ```tsx
 * <MetricWidget
 *   title="Revenue This Month"
 *   config={{ metric: 'revenue_this_month', format: 'currency' }}
 *   value={{ value: 15000000, previousValue: 12000000, changePercent: 25 }}
 *   currency="USD"
 * />
 * ```
 */
export function MetricWidget({
  title,
  config,
  value,
  isLoading = false,
  error = null,
  currency = 'USD',
  onClick,
}: MetricWidgetProps) {
  const format = config?.format || 'number';

  const displayValue = useMemo(() => {
    if (!value) return '-';
    return formatValue(value.value, format, currency);
  }, [value, format, currency]);

  const previousDisplayValue = useMemo(() => {
    if (!value?.previousValue) return null;
    return formatValue(value.previousValue, format, currency);
  }, [value, format, currency]);

  const changePercent = value?.changePercent ?? 0;
  const trendClass = getTrendClass(changePercent);
  const trendIcon = getTrendIcon(changePercent);

  if (isLoading) {
    return (
      <div className="metric-widget metric-widget--loading">
        <div className="metric-widget__header">
          <h3 className="metric-widget__title">{title}</h3>
        </div>
        <div className="metric-widget__content">
          <div className="metric-widget__skeleton" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="metric-widget metric-widget--error">
        <div className="metric-widget__header">
          <h3 className="metric-widget__title">{title}</h3>
        </div>
        <div className="metric-widget__content">
          <p className="metric-widget__error">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`metric-widget ${onClick ? 'metric-widget--clickable' : ''}`}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
      onKeyDown={onClick ? (e) => e.key === 'Enter' && onClick() : undefined}
    >
      <div className="metric-widget__header">
        <h3 className="metric-widget__title">{title}</h3>
        {config?.showSparkline && (
          <span className="metric-widget__sparkline-placeholder">
            {/* Sparkline would go here */}
          </span>
        )}
      </div>

      <div className="metric-widget__content">
        <span className="metric-widget__value">{displayValue}</span>

        {value && (
          <div className={`metric-widget__trend ${trendClass}`}>
            <span className="metric-widget__trend-icon">{trendIcon}</span>
            <span className="metric-widget__trend-value">
              {Math.abs(changePercent).toFixed(1)}%
            </span>
            {previousDisplayValue && (
              <span className="metric-widget__previous">
                vs {previousDisplayValue}
              </span>
            )}
          </div>
        )}
      </div>

      {config?.subtitle && (
        <div className="metric-widget__footer">
          <span className="metric-widget__subtitle">{config.subtitle}</span>
        </div>
      )}
    </div>
  );
}

export default MetricWidget;
