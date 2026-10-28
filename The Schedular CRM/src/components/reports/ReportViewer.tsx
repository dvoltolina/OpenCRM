/**
 * ReportViewer Component
 * Displays report results with chart and data table views.
 *
 * HIPAA Compliance:
 * - Displays aggregated data only, no individual PHI
 * - Report access is logged via parent components
 * - Export controls track downloads via audit service
 *
 * Agent CRM - Task 7 Implementation
 */

import { useState, useMemo, useCallback } from 'react';
import { ChartRenderer } from './ChartRenderer';
import type {
  ReportDefinition,
  ReportResult,
  ChartType,
} from '../../types/reporting';

// ============================================
// Types
// ============================================

export interface ReportViewerProps {
  /** Report definition */
  report: ReportDefinition;
  /** Report execution result */
  result: ReportResult;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Currency for value formatting */
  currency?: string;
  /** Callback when user clicks refresh */
  onRefresh?: () => void;
  /** Callback when user clicks export */
  onExport?: (format: 'csv' | 'xlsx' | 'pdf') => void;
  /** Callback when user clicks schedule */
  onSchedule?: () => void;
  /** Callback when user clicks edit (for custom reports) */
  onEdit?: () => void;
  /** Callback when row/element is clicked */
  onDataClick?: (data: Record<string, unknown>) => void;
  /** Whether export is in progress */
  isExporting?: boolean;
  /** Whether user can edit this report */
  canEdit?: boolean;
  /** Whether user can schedule this report */
  canSchedule?: boolean;
}

type ViewMode = 'chart' | 'table' | 'both';

// ============================================
// Formatters
// ============================================

function formatValue(
  value: unknown,
  format: 'number' | 'currency' | 'percent' | undefined,
  currency: string
): string {
  if (value === null || value === undefined) return '-';

  const numValue = typeof value === 'number' ? value : Number(value);
  if (isNaN(numValue)) return String(value);

  switch (format) {
    case 'currency':
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(numValue / 100);

    case 'percent':
      return `${(numValue * 100).toFixed(1)}%`;

    case 'number':
    default:
      return new Intl.NumberFormat('en-US').format(numValue);
  }
}

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

// ============================================
// Chart Type Selector
// ============================================

interface ChartTypeSelectorProps {
  currentType: ChartType;
  onTypeChange: (type: ChartType) => void;
  availableTypes: ChartType[];
}

function ChartTypeSelector({
  currentType,
  onTypeChange,
  availableTypes,
}: ChartTypeSelectorProps) {
  const typeLabels: Record<ChartType, string> = {
    bar: 'Bar',
    line: 'Line',
    pie: 'Pie',
    funnel: 'Funnel',
    table: 'Table',
    metric: 'Metric',
    heatmap: 'Heatmap',
  };

  const typeIcons: Record<ChartType, string> = {
    bar: '📊',
    line: '📈',
    pie: '🥧',
    funnel: '🔻',
    table: '📋',
    metric: '🔢',
    heatmap: '🗺️',
  };

  return (
    <div className="report-viewer__chart-type-selector">
      {availableTypes.map((type) => (
        <button
          key={type}
          type="button"
          className={`btn btn-icon ${currentType === type ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => onTypeChange(type)}
          title={typeLabels[type]}
          aria-pressed={currentType === type}
        >
          <span aria-hidden="true">{typeIcons[type]}</span>
          <span className="sr-only">{typeLabels[type]}</span>
        </button>
      ))}
    </div>
  );
}

// ============================================
// View Mode Toggle
// ============================================

interface ViewModeToggleProps {
  mode: ViewMode;
  onModeChange: (mode: ViewMode) => void;
}

function ViewModeToggle({ mode, onModeChange }: ViewModeToggleProps) {
  return (
    <div className="report-viewer__view-mode" role="radiogroup" aria-label="View mode">
      <button
        type="button"
        className={`btn btn-sm ${mode === 'chart' ? 'btn-primary' : 'btn-ghost'}`}
        onClick={() => onModeChange('chart')}
        role="radio"
        aria-checked={mode === 'chart'}
      >
        Chart
      </button>
      <button
        type="button"
        className={`btn btn-sm ${mode === 'table' ? 'btn-primary' : 'btn-ghost'}`}
        onClick={() => onModeChange('table')}
        role="radio"
        aria-checked={mode === 'table'}
      >
        Table
      </button>
      <button
        type="button"
        className={`btn btn-sm ${mode === 'both' ? 'btn-primary' : 'btn-ghost'}`}
        onClick={() => onModeChange('both')}
        role="radio"
        aria-checked={mode === 'both'}
      >
        Both
      </button>
    </div>
  );
}

// ============================================
// Data Table
// ============================================

interface DataTableProps {
  data: Record<string, unknown>[];
  dimensions: { field: string; label: string }[];
  metrics: { field: string; label: string; format?: 'number' | 'currency' | 'percent' }[];
  currency: string;
  totals?: Record<string, number>;
  onClick?: (row: Record<string, unknown>) => void;
}

function DataTable({
  data,
  dimensions,
  metrics,
  currency,
  totals,
  onClick,
}: DataTableProps) {
  const columns = [...dimensions, ...metrics];

  return (
    <div className="report-viewer__table-wrapper">
      <table className="report-viewer__table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.field} className="report-viewer__table-header">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, rowIdx) => (
            <tr
              key={rowIdx}
              className={`report-viewer__table-row ${onClick ? 'report-viewer__table-row--clickable' : ''}`}
              onClick={onClick ? () => onClick(row) : undefined}
            >
              {columns.map((col) => (
                <td key={col.field} className="report-viewer__table-cell">
                  {'format' in col
                    ? formatValue(
                        row[col.field],
                        (col as { format?: 'number' | 'currency' | 'percent' }).format,
                        currency
                      )
                    : String(row[col.field] ?? '-')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
        {totals && Object.keys(totals).length > 0 && (
          <tfoot>
            <tr className="report-viewer__table-totals">
              {columns.map((col, idx) => (
                <td key={col.field} className="report-viewer__table-cell report-viewer__table-cell--total">
                  {idx === 0 ? (
                    <strong>Total</strong>
                  ) : 'format' in col && totals[col.field] !== undefined ? (
                    <strong>
                      {formatValue(
                        totals[col.field],
                        (col as { format?: 'number' | 'currency' | 'percent' }).format,
                        currency
                      )}
                    </strong>
                  ) : (
                    '-'
                  )}
                </td>
              ))}
            </tr>
          </tfoot>
        )}
      </table>
    </div>
  );
}

// ============================================
// Main Component
// ============================================

/**
 * ReportViewer - Display report results with chart and table views
 *
 * Features:
 * - Toggle between chart, table, or both views
 * - Switch chart type dynamically
 * - Export to CSV, XLSX, or PDF
 * - Schedule report for recurring delivery
 * - Edit custom reports
 *
 * @example
 * ```tsx
 * <ReportViewer
 *   report={reportDefinition}
 *   result={reportResult}
 *   onRefresh={handleRefresh}
 *   onExport={handleExport}
 *   onSchedule={handleSchedule}
 *   currency="USD"
 * />
 * ```
 */
export function ReportViewer({
  report,
  result,
  isLoading = false,
  error = null,
  currency = 'USD',
  onRefresh,
  onExport,
  onSchedule,
  onEdit,
  onDataClick,
  isExporting = false,
  canEdit = false,
  canSchedule = true,
}: ReportViewerProps) {
  const [viewMode, setViewMode] = useState<ViewMode>('chart');
  const [chartType, setChartType] = useState<ChartType>(report.chartType);

  // Available chart types based on data structure
  const availableChartTypes = useMemo<ChartType[]>(() => {
    const types: ChartType[] = ['bar', 'line', 'table'];

    // Pie charts work well with single-dimension, single-metric reports
    if (report.dimensions.length === 1 && report.metrics.length === 1) {
      types.push('pie');
    }

    // Funnel for ordered stages
    if (report.reportType === 'pipeline' || report.reportType === 'conversion') {
      types.push('funnel');
    }

    // Metric display for summary views
    if (report.metrics.length > 0 && result.rows.length <= 1) {
      types.push('metric');
    }

    return types;
  }, [report, result.rows.length]);

  const handleExport = useCallback(
    (format: 'csv' | 'xlsx' | 'pdf') => {
      if (onExport) {
        onExport(format);
      }
    },
    [onExport]
  );

  // Loading state
  if (isLoading) {
    return (
      <div className="report-viewer report-viewer--loading">
        <div className="report-viewer__header">
          <h2 className="report-viewer__title">{report.name}</h2>
          {report.description && (
            <p className="report-viewer__description">{report.description}</p>
          )}
        </div>
        <div className="report-viewer__loading">
          <div className="spinner" />
          <p>Running report...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="report-viewer report-viewer--error">
        <div className="report-viewer__header">
          <h2 className="report-viewer__title">{report.name}</h2>
        </div>
        <div className="report-viewer__error">
          <p className="report-viewer__error-message">{error}</p>
          {onRefresh && (
            <button type="button" className="btn btn-primary" onClick={onRefresh}>
              Retry
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="report-viewer">
      {/* Header */}
      <div className="report-viewer__header">
        <div className="report-viewer__header-content">
          <h2 className="report-viewer__title">{report.name}</h2>
          {report.description && (
            <p className="report-viewer__description">{report.description}</p>
          )}
          <div className="report-viewer__meta">
            <span className="report-viewer__meta-item">
              {formatDate(result.dateRange.start)} - {formatDate(result.dateRange.end)}
            </span>
            <span className="report-viewer__meta-item">
              {result.rowCount.toLocaleString()} rows
            </span>
            <span className="report-viewer__meta-item">
              {formatDuration(result.queryTimeMs)}
            </span>
          </div>
        </div>

        {/* Actions */}
        <div className="report-viewer__actions">
          <ViewModeToggle mode={viewMode} onModeChange={setViewMode} />

          {viewMode !== 'table' && (
            <ChartTypeSelector
              currentType={chartType}
              onTypeChange={setChartType}
              availableTypes={availableChartTypes}
            />
          )}

          <div className="report-viewer__action-buttons">
            {onRefresh && (
              <button
                type="button"
                className="btn btn-ghost btn-sm"
                onClick={onRefresh}
                title="Refresh"
              >
                Refresh
              </button>
            )}

            {onExport && (
              <div className="dropdown">
                <button
                  type="button"
                  className="btn btn-ghost btn-sm"
                  disabled={isExporting}
                >
                  {isExporting ? 'Exporting...' : 'Export'}
                </button>
                <div className="dropdown-menu">
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => handleExport('csv')}
                  >
                    Export as CSV
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => handleExport('xlsx')}
                  >
                    Export as Excel
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => handleExport('pdf')}
                  >
                    Export as PDF
                  </button>
                </div>
              </div>
            )}

            {canSchedule && onSchedule && (
              <button
                type="button"
                className="btn btn-ghost btn-sm"
                onClick={onSchedule}
                title="Schedule"
              >
                Schedule
              </button>
            )}

            {canEdit && onEdit && !report.isSystemReport && (
              <button
                type="button"
                className="btn btn-ghost btn-sm"
                onClick={onEdit}
                title="Edit"
              >
                Edit
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="report-viewer__content">
        {/* Chart View */}
        {(viewMode === 'chart' || viewMode === 'both') && (
          <div className="report-viewer__chart-section">
            <ChartRenderer
              type={chartType}
              data={result.rows}
              dimensions={report.dimensions}
              metrics={report.metrics}
              currency={currency}
              height={viewMode === 'both' ? 250 : 350}
              onClick={onDataClick}
            />
          </div>
        )}

        {/* Table View */}
        {(viewMode === 'table' || viewMode === 'both') && (
          <div className="report-viewer__table-section">
            <DataTable
              data={result.rows}
              dimensions={report.dimensions}
              metrics={report.metrics}
              currency={currency}
              totals={result.totals}
              onClick={onDataClick}
            />
          </div>
        )}
      </div>

      {/* Footer with generated timestamp */}
      <div className="report-viewer__footer">
        <span className="report-viewer__generated">
          Generated: {new Date(result.generatedAt).toLocaleString()}
        </span>
        {report.isSystemReport && (
          <span className="report-viewer__badge report-viewer__badge--system">
            System Report
          </span>
        )}
      </div>
    </div>
  );
}

export default ReportViewer;
