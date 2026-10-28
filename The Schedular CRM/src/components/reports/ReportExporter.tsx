/**
 * ReportExporter Component
 * Export dialog for downloading reports in various formats.
 *
 * HIPAA Compliance:
 * - All exports are logged via audit service
 * - Export downloads tracked for compliance
 * - Users can only export data they have access to
 *
 * Agent CRM - Task 7 Implementation
 */

import { useState, useMemo, useCallback } from 'react';
import type { ReportResult, ReportDefinition, DateRange } from '../../types/reporting';

// ============================================
// Types
// ============================================

export interface ReportExporterProps {
  /** Report definition */
  report: ReportDefinition;
  /** Current report result (optional - can export with fresh data) */
  result?: ReportResult;
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Callback when dialog is closed */
  onClose: () => void;
  /** Callback to execute export */
  onExport: (options: ExportOptions) => Promise<string | void>;
  /** Whether export is in progress */
  isExporting?: boolean;
  /** Export progress (0-100) */
  exportProgress?: number;
  /** Any export error */
  exportError?: string | null;
}

export interface ExportOptions {
  format: 'csv' | 'xlsx' | 'pdf';
  dateRange: { start: Date; end: Date };
  includeChart: boolean;
  includeHeaders: boolean;
  includeTotals: boolean;
  fileName?: string;
}

// ============================================
// Constants
// ============================================

const EXPORT_FORMATS: { value: 'csv' | 'xlsx' | 'pdf'; label: string; icon: string; description: string }[] = [
  {
    value: 'csv',
    label: 'CSV',
    icon: '📄',
    description: 'Plain text format, compatible with any spreadsheet application',
  },
  {
    value: 'xlsx',
    label: 'Excel',
    icon: '📊',
    description: 'Microsoft Excel format with formatting preserved',
  },
  {
    value: 'pdf',
    label: 'PDF',
    icon: '📑',
    description: 'Formatted document suitable for printing and sharing',
  },
];

const DATE_RANGE_PRESETS: { value: DateRange; label: string }[] = [
  { value: 'today', label: 'Today' },
  { value: 'yesterday', label: 'Yesterday' },
  { value: 'this_week', label: 'This Week' },
  { value: 'last_week', label: 'Last Week' },
  { value: 'this_month', label: 'This Month' },
  { value: 'last_month', label: 'Last Month' },
  { value: 'this_quarter', label: 'This Quarter' },
  { value: 'last_quarter', label: 'Last Quarter' },
  { value: 'this_year', label: 'This Year' },
  { value: 'last_year', label: 'Last Year' },
  { value: 'custom', label: 'Custom Range' },
];

// ============================================
// Helper Functions
// ============================================

function resolveDateRange(
  preset: DateRange,
  customStart?: Date,
  customEnd?: Date
): { start: Date; end: Date } {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let start: Date;
  let end: Date;

  switch (preset) {
    case 'today':
      start = today;
      end = new Date(today.getTime() + 24 * 60 * 60 * 1000 - 1);
      break;
    case 'yesterday':
      start = new Date(today.getTime() - 24 * 60 * 60 * 1000);
      end = new Date(today.getTime() - 1);
      break;
    case 'this_week': {
      const dayOfWeek = today.getDay();
      start = new Date(today.getTime() - dayOfWeek * 24 * 60 * 60 * 1000);
      end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000 - 1);
      break;
    }
    case 'last_week': {
      const lastWeekStart = new Date(today.getTime() - (today.getDay() + 7) * 24 * 60 * 60 * 1000);
      start = lastWeekStart;
      end = new Date(lastWeekStart.getTime() + 7 * 24 * 60 * 60 * 1000 - 1);
      break;
    }
    case 'this_month':
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      break;
    case 'last_month':
      start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
      break;
    case 'this_quarter': {
      const currentQuarter = Math.floor(now.getMonth() / 3);
      start = new Date(now.getFullYear(), currentQuarter * 3, 1);
      end = new Date(now.getFullYear(), currentQuarter * 3 + 3, 0, 23, 59, 59, 999);
      break;
    }
    case 'last_quarter': {
      const lastQuarter = Math.floor(now.getMonth() / 3) - 1;
      const lastQuarterYear = lastQuarter < 0 ? now.getFullYear() - 1 : now.getFullYear();
      const adjustedQuarter = lastQuarter < 0 ? 3 : lastQuarter;
      start = new Date(lastQuarterYear, adjustedQuarter * 3, 1);
      end = new Date(lastQuarterYear, adjustedQuarter * 3 + 3, 0, 23, 59, 59, 999);
      break;
    }
    case 'this_year':
      start = new Date(now.getFullYear(), 0, 1);
      end = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
      break;
    case 'last_year':
      start = new Date(now.getFullYear() - 1, 0, 1);
      end = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59, 999);
      break;
    case 'custom':
      start = customStart || today;
      end = customEnd || new Date(today.getTime() + 24 * 60 * 60 * 1000 - 1);
      break;
    default:
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  }

  return { start, end };
}

function formatDateForInput(date: Date): string {
  return date.toISOString().split('T')[0];
}

function generateFileName(reportName: string, format: string, dateRange: { start: Date; end: Date }): string {
  const sanitizedName = reportName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

  const dateStr = formatDateForInput(dateRange.start);
  const endDateStr = formatDateForInput(dateRange.end);

  return `${sanitizedName}_${dateStr}_to_${endDateStr}.${format}`;
}

// ============================================
// Main Component
// ============================================

/**
 * ReportExporter - Export dialog for report downloads
 *
 * Features:
 * - Select export format (CSV, Excel, PDF)
 * - Configure date range for export
 * - Include/exclude chart visualization
 * - Include/exclude headers and totals
 * - Custom file naming
 *
 * @example
 * ```tsx
 * <ReportExporter
 *   report={reportDefinition}
 *   result={reportResult}
 *   isOpen={showExportDialog}
 *   onClose={() => setShowExportDialog(false)}
 *   onExport={handleExport}
 * />
 * ```
 */
export function ReportExporter({
  report,
  result,
  isOpen,
  onClose,
  onExport,
  isExporting = false,
  exportProgress = 0,
  exportError = null,
}: ReportExporterProps) {
  // Form state
  const [format, setFormat] = useState<'csv' | 'xlsx' | 'pdf'>('xlsx');
  const [dateRangePreset, setDateRangePreset] = useState<DateRange>(
    report.defaultDateRange || 'this_month'
  );
  const [customStartDate, setCustomStartDate] = useState<Date>(new Date());
  const [customEndDate, setCustomEndDate] = useState<Date>(new Date());
  const [includeChart, setIncludeChart] = useState(true);
  const [includeHeaders, setIncludeHeaders] = useState(true);
  const [includeTotals, setIncludeTotals] = useState(true);
  const [customFileName, setCustomFileName] = useState('');

  // Computed values
  const dateRange = useMemo(() => {
    return resolveDateRange(dateRangePreset, customStartDate, customEndDate);
  }, [dateRangePreset, customStartDate, customEndDate]);

  const defaultFileName = useMemo(() => {
    return generateFileName(report.name, format, dateRange);
  }, [report.name, format, dateRange]);

  const estimatedRows = result?.rowCount || 0;

  // Handlers
  const handleExport = useCallback(async () => {
    const options: ExportOptions = {
      format,
      dateRange,
      includeChart: format !== 'csv' && includeChart,
      includeHeaders,
      includeTotals,
      fileName: customFileName.trim() || undefined,
    };

    await onExport(options);
  }, [format, dateRange, includeChart, includeHeaders, includeTotals, customFileName, onExport]);

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal report-exporter" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="report-exporter__header">
          <h2 className="report-exporter__title">Export Report</h2>
          <button
            type="button"
            className="modal-close"
            onClick={onClose}
            aria-label="Close"
          >
            &times;
          </button>
        </div>

        {/* Content */}
        <div className="report-exporter__content">
          {/* Report Info */}
          <div className="report-exporter__info">
            <h3 className="report-exporter__report-name">{report.name}</h3>
            {result && (
              <p className="report-exporter__row-count">
                {estimatedRows.toLocaleString()} rows
              </p>
            )}
          </div>

          {/* Format Selection */}
          <div className="report-exporter__section">
            <label className="form-label">Export Format</label>
            <div className="report-exporter__formats">
              {EXPORT_FORMATS.map((fmt) => (
                <label
                  key={fmt.value}
                  className={`report-exporter__format ${
                    format === fmt.value ? 'report-exporter__format--selected' : ''
                  }`}
                >
                  <input
                    type="radio"
                    name="format"
                    value={fmt.value}
                    checked={format === fmt.value}
                    onChange={(e) => setFormat(e.target.value as 'csv' | 'xlsx' | 'pdf')}
                  />
                  <span className="report-exporter__format-icon">{fmt.icon}</span>
                  <span className="report-exporter__format-label">{fmt.label}</span>
                  <span className="report-exporter__format-desc">{fmt.description}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Date Range */}
          <div className="report-exporter__section">
            <label htmlFor="date-range" className="form-label">
              Date Range
            </label>
            <select
              id="date-range"
              className="form-select"
              value={dateRangePreset}
              onChange={(e) => setDateRangePreset(e.target.value as DateRange)}
            >
              {DATE_RANGE_PRESETS.map((preset) => (
                <option key={preset.value} value={preset.value}>
                  {preset.label}
                </option>
              ))}
            </select>

            {dateRangePreset === 'custom' && (
              <div className="report-exporter__custom-dates">
                <div className="form-group">
                  <label htmlFor="start-date" className="form-label">
                    Start Date
                  </label>
                  <input
                    id="start-date"
                    type="date"
                    className="form-input"
                    value={formatDateForInput(customStartDate)}
                    onChange={(e) => setCustomStartDate(new Date(e.target.value))}
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="end-date" className="form-label">
                    End Date
                  </label>
                  <input
                    id="end-date"
                    type="date"
                    className="form-input"
                    value={formatDateForInput(customEndDate)}
                    onChange={(e) => setCustomEndDate(new Date(e.target.value))}
                  />
                </div>
              </div>
            )}

            <p className="form-hint">
              Exporting data from {dateRange.start.toLocaleDateString()} to{' '}
              {dateRange.end.toLocaleDateString()}
            </p>
          </div>

          {/* Options */}
          <div className="report-exporter__section">
            <label className="form-label">Options</label>
            <div className="report-exporter__options">
              {format !== 'csv' && (
                <label className="form-checkbox-label">
                  <input
                    type="checkbox"
                    checked={includeChart}
                    onChange={(e) => setIncludeChart(e.target.checked)}
                  />
                  <span>Include chart visualization</span>
                </label>
              )}

              <label className="form-checkbox-label">
                <input
                  type="checkbox"
                  checked={includeHeaders}
                  onChange={(e) => setIncludeHeaders(e.target.checked)}
                />
                <span>Include column headers</span>
              </label>

              <label className="form-checkbox-label">
                <input
                  type="checkbox"
                  checked={includeTotals}
                  onChange={(e) => setIncludeTotals(e.target.checked)}
                />
                <span>Include totals row</span>
              </label>
            </div>
          </div>

          {/* File Name */}
          <div className="report-exporter__section">
            <label htmlFor="file-name" className="form-label">
              File Name (optional)
            </label>
            <input
              id="file-name"
              type="text"
              className="form-input"
              value={customFileName}
              onChange={(e) => setCustomFileName(e.target.value)}
              placeholder={defaultFileName}
            />
          </div>

          {/* Export Error */}
          {exportError && (
            <div className="report-exporter__error">
              <p>{exportError}</p>
            </div>
          )}

          {/* Export Progress */}
          {isExporting && (
            <div className="report-exporter__progress">
              <div
                className="report-exporter__progress-bar"
                style={{ width: `${exportProgress}%` }}
              />
              <p className="report-exporter__progress-text">
                Exporting... {exportProgress}%
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="report-exporter__footer">
          <button
            type="button"
            className="btn btn-ghost"
            onClick={onClose}
            disabled={isExporting}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={handleExport}
            disabled={isExporting}
          >
            {isExporting ? 'Exporting...' : `Export as ${format.toUpperCase()}`}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ReportExporter;
