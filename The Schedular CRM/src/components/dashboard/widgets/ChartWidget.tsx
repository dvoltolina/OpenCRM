/**
 * ChartWidget Component
 * Displays a report chart within a dashboard widget.
 *
 * HIPAA Compliance:
 * - Displays aggregated data only, no PHI
 * - All chart access logged via parent components
 *
 * Agent CRM - Task 7 Implementation
 */

import { useState, useCallback } from 'react';
import { ChartRenderer } from '../../reports/ChartRenderer';
import type {
  ReportDefinition,
  ReportResult,
  ChartType,
} from '../../../types/reporting';

// ============================================
// Types
// ============================================

export interface ChartWidgetProps {
  /** Widget title */
  title: string;
  /** Report definition */
  report?: ReportDefinition;
  /** Report result data */
  result?: ReportResult | null;
  /** Override chart type */
  chartType?: ChartType;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Currency for value formatting */
  currency?: string;
  /** Widget height */
  height?: number;
  /** Click handler for data points */
  onDataClick?: (data: Record<string, unknown>) => void;
  /** Click handler for view full report */
  onViewReport?: () => void;
  /** Click handler to refresh */
  onRefresh?: () => void;
}

// ============================================
// Main Component
// ============================================

/**
 * ChartWidget - Report chart display in dashboard
 *
 * Features:
 * - Displays report chart visualization
 * - Supports all chart types (bar, line, pie, etc.)
 * - Interactive data points
 * - Quick refresh action
 * - Link to full report view
 *
 * @example
 * ```tsx
 * <ChartWidget
 *   title="Deals by Stage"
 *   report={pipelineReport}
 *   result={pipelineResult}
 *   chartType="bar"
 *   currency="USD"
 *   onViewReport={() => navigate('/reports/pipeline')}
 * />
 * ```
 */
export function ChartWidget({
  title,
  report,
  result,
  chartType,
  isLoading = false,
  error = null,
  currency = 'USD',
  height = 250,
  onDataClick,
  onViewReport,
  onRefresh,
}: ChartWidgetProps) {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = useCallback(async () => {
    if (!onRefresh) return;
    setIsRefreshing(true);
    try {
      await onRefresh();
    } finally {
      setIsRefreshing(false);
    }
  }, [onRefresh]);

  // Loading state
  if (isLoading || isRefreshing) {
    return (
      <div className="chart-widget chart-widget--loading">
        <div className="chart-widget__header">
          <h3 className="chart-widget__title">{title}</h3>
        </div>
        <div className="chart-widget__content" style={{ height }}>
          <div className="chart-widget__spinner" />
          <p>Loading chart...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="chart-widget chart-widget--error">
        <div className="chart-widget__header">
          <h3 className="chart-widget__title">{title}</h3>
        </div>
        <div className="chart-widget__content" style={{ height }}>
          <p className="chart-widget__error-message">{error}</p>
          {onRefresh && (
            <button type="button" className="btn btn-sm btn-ghost" onClick={handleRefresh}>
              Retry
            </button>
          )}
        </div>
      </div>
    );
  }

  // No data state
  if (!report || !result || result.rows.length === 0) {
    return (
      <div className="chart-widget chart-widget--empty">
        <div className="chart-widget__header">
          <h3 className="chart-widget__title">{title}</h3>
        </div>
        <div className="chart-widget__content" style={{ height }}>
          <p>No data available</p>
        </div>
      </div>
    );
  }

  return (
    <div className="chart-widget">
      <div className="chart-widget__header">
        <h3 className="chart-widget__title">{title}</h3>
        <div className="chart-widget__actions">
          {onRefresh && (
            <button
              type="button"
              className="chart-widget__action-btn"
              onClick={handleRefresh}
              title="Refresh"
              disabled={isRefreshing}
            >
              🔄
            </button>
          )}
          {onViewReport && (
            <button
              type="button"
              className="chart-widget__action-btn"
              onClick={onViewReport}
              title="View Full Report"
            >
              ↗️
            </button>
          )}
        </div>
      </div>

      <div className="chart-widget__content">
        <ChartRenderer
          type={chartType || report.chartType}
          data={result.rows}
          dimensions={report.dimensions}
          metrics={report.metrics}
          height={height - 48} // Account for header
          currency={currency}
          onClick={onDataClick}
        />
      </div>

      <div className="chart-widget__footer">
        <span className="chart-widget__meta">
          {result.rowCount} records | Updated {new Date(result.generatedAt).toLocaleTimeString()}
        </span>
      </div>
    </div>
  );
}

export default ChartWidget;
