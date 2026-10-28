/**
 * ChartRenderer Component
 * Unified chart rendering for various chart types based on report configuration.
 *
 * HIPAA Compliance:
 * - Charts display aggregated data only, no PHI
 * - All chart interactions are logged via parent components
 *
 * Agent CRM - Task 7 Implementation
 */

import { useMemo, useCallback } from 'react';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  FunnelChart,
  Funnel,
  LabelList,
} from 'recharts';
import { ChartContainer } from '../charts/ChartContainer';
import type {
  ChartType,
  ReportDimension,
  ReportMetric,
} from '../../types/reporting';

// ============================================
// Types
// ============================================

export interface ChartRendererProps {
  /** Chart type to render */
  type: ChartType;
  /** Data rows from report result */
  data: Record<string, unknown>[];
  /** Report dimensions (groupings) */
  dimensions: ReportDimension[];
  /** Report metrics (aggregations) */
  metrics: ReportMetric[];
  /** Chart title */
  title?: string;
  /** Chart subtitle */
  subtitle?: string;
  /** Chart height in pixels */
  height?: number;
  /** Currency for value formatting */
  currency?: string;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Click handler for chart elements */
  onClick?: (data: Record<string, unknown>) => void;
}

// ============================================
// Constants
// ============================================

const CHART_COLORS = [
  '#3b82f6', // blue-500
  '#10b981', // emerald-500
  '#f59e0b', // amber-500
  '#ef4444', // red-500
  '#8b5cf6', // violet-500
  '#ec4899', // pink-500
  '#06b6d4', // cyan-500
  '#84cc16', // lime-500
];

const FUNNEL_COLORS = [
  '#3b82f6', // blue-500
  '#60a5fa', // blue-400
  '#93c5fd', // blue-300
  '#bfdbfe', // blue-200
  '#dbeafe', // blue-100
];

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

function formatAxisTick(value: unknown): string {
  if (typeof value === 'number') {
    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(1)}M`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}K`;
    }
    return String(value);
  }
  return String(value);
}

// ============================================
// Custom Tooltip
// ============================================

interface TooltipProps {
  active?: boolean;
  payload?: Array<{
    name: string;
    value: number;
    payload: Record<string, unknown>;
    dataKey: string;
  }>;
  label?: string;
  metrics: ReportMetric[];
  currency: string;
}

function CustomTooltip({ active, payload, label, metrics, currency }: TooltipProps) {
  if (!active || !payload || payload.length === 0) return null;

  const item = payload[0]?.payload;
  if (!item) return null;

  return (
    <div className="chart-tooltip">
      <p className="chart-tooltip__label">{label || String(item.name || '-')}</p>
      {metrics.map((metric) => (
        <p key={metric.field} className="chart-tooltip__item">
          <span className="chart-tooltip__item-label">{metric.label}:</span>
          <span className="chart-tooltip__item-value">
            {formatValue(item[metric.field], metric.format, currency)}
          </span>
        </p>
      ))}
    </div>
  );
}

// ============================================
// Bar Chart
// ============================================

interface BarChartRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function BarChartRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: BarChartRendererProps) {
  const dimensionKey = dimensions[0]?.field || 'name';

  const handleClick = useCallback(
    (data: { payload?: Record<string, unknown> } | undefined) => {
      if (onClick && data?.payload) {
        onClick(data.payload);
      }
    },
    [onClick]
  );

  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} margin={{ top: 10, right: 30, left: 20, bottom: 60 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
        <XAxis
          dataKey={dimensionKey}
          stroke="var(--color-text-muted)"
          fontSize={12}
          angle={-45}
          textAnchor="end"
          height={80}
        />
        <YAxis
          stroke="var(--color-text-muted)"
          fontSize={12}
          tickFormatter={formatAxisTick}
        />
        <Tooltip content={<CustomTooltip metrics={metrics} currency={currency} />} />
        <Legend wrapperStyle={{ paddingTop: 20 }} />
        {metrics.map((metric, idx) => (
          <Bar
            key={metric.field}
            dataKey={metric.field}
            name={metric.label}
            fill={CHART_COLORS[idx % CHART_COLORS.length]}
            radius={[4, 4, 0, 0]}
            onClick={handleClick}
            cursor={onClick ? 'pointer' : undefined}
          />
        ))}
      </BarChart>
    </ResponsiveContainer>
  );
}

// ============================================
// Line Chart
// ============================================

interface LineChartRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function LineChartRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: LineChartRendererProps) {
  const dimensionKey = dimensions[0]?.field || 'name';

  const handleClick = useCallback(
    (data: { payload?: Record<string, unknown> } | undefined) => {
      if (onClick && data?.payload) {
        onClick(data.payload);
      }
    },
    [onClick]
  );

  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data} margin={{ top: 10, right: 30, left: 20, bottom: 60 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
        <XAxis
          dataKey={dimensionKey}
          stroke="var(--color-text-muted)"
          fontSize={12}
          angle={-45}
          textAnchor="end"
          height={80}
        />
        <YAxis
          stroke="var(--color-text-muted)"
          fontSize={12}
          tickFormatter={formatAxisTick}
        />
        <Tooltip content={<CustomTooltip metrics={metrics} currency={currency} />} />
        <Legend wrapperStyle={{ paddingTop: 20 }} />
        {metrics.map((metric, idx) => (
          <Line
            key={metric.field}
            type="monotone"
            dataKey={metric.field}
            name={metric.label}
            stroke={CHART_COLORS[idx % CHART_COLORS.length]}
            strokeWidth={2}
            dot={{ fill: CHART_COLORS[idx % CHART_COLORS.length], strokeWidth: 2 }}
            activeDot={{
              r: 6,
              onClick: handleClick as any,
              cursor: onClick ? 'pointer' : undefined,
            }}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}

// ============================================
// Pie Chart
// ============================================

interface PieChartRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function PieChartRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: PieChartRendererProps) {
  const dimensionKey = dimensions[0]?.field || 'name';
  const metricKey = metrics[0]?.field || 'value';
  const metricFormat = metrics[0]?.format;

  const handleClick = useCallback(
    (data: Record<string, unknown> | undefined) => {
      if (onClick && data) {
        onClick(data);
      }
    },
    [onClick]
  );

  const renderLabel = useCallback(
    ({
      name,
      percent,
    }: {
      name: string;
      percent: number;
    }) => `${name} (${(percent * 100).toFixed(0)}%)`,
    []
  );

  return (
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          data={data}
          dataKey={metricKey}
          nameKey={dimensionKey}
          cx="50%"
          cy="50%"
          outerRadius={100}
          label={renderLabel as any}
          labelLine
          onClick={handleClick as any}
          cursor={onClick ? 'pointer' : undefined}
        >
          {data.map((_, index) => (
            <Cell
              key={`cell-${index}`}
              fill={CHART_COLORS[index % CHART_COLORS.length]}
            />
          ))}
        </Pie>
        <Tooltip
          formatter={(value: number) => formatValue(value, metricFormat, currency)}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}

// ============================================
// Funnel Chart
// ============================================

interface FunnelChartRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function FunnelChartRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: FunnelChartRendererProps) {
  const dimensionKey = dimensions[0]?.field || 'name';
  const metricKey = metrics[0]?.field || 'value';
  const metricFormat = metrics[0]?.format;

  // Prepare funnel data with fill colors
  const funnelData = useMemo(
    () =>
      data.map((item, index) => ({
        ...item,
        fill: FUNNEL_COLORS[index % FUNNEL_COLORS.length],
        name: String(item[dimensionKey]),
        value: Number(item[metricKey]) || 0,
      })),
    [data, dimensionKey, metricKey]
  );

  const handleClick = useCallback(
    (data: Record<string, unknown> | undefined) => {
      if (onClick && data) {
        onClick(data);
      }
    },
    [onClick]
  );

  return (
    <ResponsiveContainer width="100%" height="100%">
      <FunnelChart>
        <Tooltip
          formatter={(value: number) => formatValue(value, metricFormat, currency)}
        />
        <Funnel
          dataKey="value"
          data={funnelData}
          isAnimationActive
          onClick={handleClick as any}
        >
          <LabelList
            position="center"
            fill="#fff"
            stroke="none"
            dataKey="name"
          />
        </Funnel>
      </FunnelChart>
    </ResponsiveContainer>
  );
}

// ============================================
// Table Renderer
// ============================================

interface TableRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function TableRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: TableRendererProps) {
  const columns = [...dimensions, ...metrics];

  return (
    <div className="report-table-wrapper">
      <table className="report-table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.field} className="report-table__header">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, rowIdx) => (
            <tr
              key={rowIdx}
              className={`report-table__row ${onClick ? 'report-table__row--clickable' : ''}`}
              onClick={onClick ? () => onClick(row) : undefined}
            >
              {columns.map((col) => (
                <td key={col.field} className="report-table__cell">
                  {'format' in col
                    ? formatValue(row[col.field], col.format, currency)
                    : String(row[col.field] ?? '-')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ============================================
// Metric Display
// ============================================

interface MetricDisplayProps {
  data: Record<string, unknown>[];
  metrics: ReportMetric[];
  currency: string;
}

function MetricDisplay({ data, metrics, currency }: MetricDisplayProps) {
  // For metric display, aggregate all values
  const aggregatedValues = useMemo(() => {
    return metrics.map((metric) => {
      const values = data.map((row) => Number(row[metric.field]) || 0);
      let aggregated: number;

      switch (metric.aggregation) {
        case 'sum':
          aggregated = values.reduce((a, b) => a + b, 0);
          break;
        case 'avg':
          aggregated = values.length > 0 ? values.reduce((a, b) => a + b, 0) / values.length : 0;
          break;
        case 'count':
          aggregated = values.length;
          break;
        case 'min':
          aggregated = Math.min(...values);
          break;
        case 'max':
          aggregated = Math.max(...values);
          break;
        default:
          aggregated = values.reduce((a, b) => a + b, 0);
      }

      return {
        label: metric.label,
        value: aggregated,
        format: metric.format,
      };
    });
  }, [data, metrics]);

  return (
    <div className="report-metrics-grid">
      {aggregatedValues.map((metric, idx) => (
        <div key={idx} className="report-metric-card">
          <span className="report-metric-card__label">{metric.label}</span>
          <span className="report-metric-card__value">
            {formatValue(metric.value, metric.format, currency)}
          </span>
        </div>
      ))}
    </div>
  );
}

// ============================================
// Heatmap Renderer
// ============================================

interface HeatmapRendererProps {
  data: Record<string, unknown>[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  currency: string;
  onClick?: (data: Record<string, unknown>) => void;
}

function HeatmapRenderer({
  data,
  dimensions,
  metrics,
  currency,
  onClick,
}: HeatmapRendererProps) {
  const rowDimension = dimensions[0]?.field || 'row';
  const colDimension = dimensions[1]?.field || null;
  const metricKey = metrics[0]?.field || 'value';
  const metricFormat = metrics[0]?.format;

  // Build heatmap structure
  const heatmapData = useMemo(() => {
    // Get unique row and column values
    const rows = [...new Set(data.map((item) => String(item[rowDimension] ?? '')))];

    // If we have a second dimension, use it for columns
    // Otherwise, use metric keys as columns
    let columns: string[];
    let getValueFn: (row: string, col: string) => number;

    if (colDimension) {
      columns = [...new Set(data.map((item) => String(item[colDimension] ?? '')))];
      getValueFn = (row: string, col: string) => {
        const item = data.find(
          (d) => String(d[rowDimension]) === row && String(d[colDimension]) === col
        );
        return item ? Number(item[metricKey]) || 0 : 0;
      };
    } else {
      // Use metrics as columns if only one dimension
      columns = metrics.map((m) => m.label);
      getValueFn = (row: string, colLabel: string) => {
        const metric = metrics.find((m) => m.label === colLabel);
        if (!metric) return 0;
        const item = data.find((d) => String(d[rowDimension]) === row);
        return item ? Number(item[metric.field]) || 0 : 0;
      };
    }

    // Calculate min/max for intensity
    let minVal = Infinity;
    let maxVal = -Infinity;

    rows.forEach((row) => {
      columns.forEach((col) => {
        const val = getValueFn(row, col);
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      });
    });

    if (minVal === Infinity) minVal = 0;
    if (maxVal === -Infinity) maxVal = 0;

    return { rows, columns, getValueFn, minVal, maxVal };
  }, [data, rowDimension, colDimension, metricKey, metrics]);

  const getIntensity = useCallback(
    (value: number): number => {
      if (heatmapData.maxVal === heatmapData.minVal) return 3;
      const range = heatmapData.maxVal - heatmapData.minVal;
      const normalized = (value - heatmapData.minVal) / range;
      return Math.min(5, Math.max(0, Math.round(normalized * 5)));
    },
    [heatmapData.maxVal, heatmapData.minVal]
  );

  const handleCellClick = useCallback(
    (row: string, col: string, value: number) => {
      if (onClick) {
        onClick({
          [rowDimension]: row,
          ...(colDimension ? { [colDimension]: col } : {}),
          [metricKey]: value,
        });
      }
    },
    [onClick, rowDimension, colDimension, metricKey]
  );

  return (
    <div className="report-heatmap">
      <div className="report-heatmap__grid">
        {/* Column headers */}
        <div className="report-heatmap__header">
          {heatmapData.columns.map((col) => (
            <div key={col} className="report-heatmap__header-cell">
              {col}
            </div>
          ))}
        </div>

        {/* Rows */}
        {heatmapData.rows.map((row) => (
          <div key={row} className="report-heatmap__row">
            <div className="report-heatmap__row-label">{row}</div>
            {heatmapData.columns.map((col) => {
              const value = heatmapData.getValueFn(row, col);
              const intensity = getIntensity(value);
              return (
                <div
                  key={`${row}-${col}`}
                  className={`report-heatmap__cell report-heatmap__cell--intensity-${intensity}`}
                  onClick={() => handleCellClick(row, col, value)}
                  title={`${row} - ${col}: ${formatValue(value, metricFormat, currency)}`}
                >
                  {formatValue(value, metricFormat, currency)}
                </div>
              );
            })}
          </div>
        ))}
      </div>

      {/* Legend */}
      <div className="report-heatmap__legend">
        <span className="report-heatmap__legend-label">Intensity:</span>
        <div className="report-heatmap__legend-scale">
          {[0, 1, 2, 3, 4, 5].map((level) => (
            <div
              key={level}
              className={`report-heatmap__legend-swatch report-heatmap__cell--intensity-${level}`}
            >
              {level === 0 ? 'Low' : level === 5 ? 'High' : ''}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ============================================
// Main Component
// ============================================

/**
 * ChartRenderer - Unified chart rendering component
 *
 * Supports bar, line, pie, funnel, table, metric, and heatmap chart types.
 * Automatically formats values based on metric configuration.
 *
 * @example
 * ```tsx
 * <ChartRenderer
 *   type="bar"
 *   data={reportResult.rows}
 *   dimensions={report.dimensions}
 *   metrics={report.metrics}
 *   title="Deals by Stage"
 *   currency="USD"
 *   onClick={(row) => console.log('Clicked:', row)}
 * />
 * ```
 */
export function ChartRenderer({
  type,
  data,
  dimensions,
  metrics,
  title,
  subtitle,
  height = 300,
  currency = 'USD',
  isLoading = false,
  onClick,
}: ChartRendererProps) {
  const isEmpty = data.length === 0;

  const renderChart = useCallback(() => {
    switch (type) {
      case 'bar':
        return (
          <BarChartRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      case 'line':
        return (
          <LineChartRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      case 'pie':
        return (
          <PieChartRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      case 'funnel':
        return (
          <FunnelChartRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      case 'table':
        return (
          <TableRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      case 'metric':
        return (
          <MetricDisplay
            data={data}
            metrics={metrics}
            currency={currency}
          />
        );

      case 'heatmap':
        return (
          <HeatmapRenderer
            data={data}
            dimensions={dimensions}
            metrics={metrics}
            currency={currency}
            onClick={onClick}
          />
        );

      default:
        return (
          <div className="chart-unsupported">
            <p>Unsupported chart type: {type}</p>
          </div>
        );
    }
  }, [type, data, dimensions, metrics, currency, onClick]);

  return (
    <ChartContainer
      title={title || 'Report'}
      subtitle={subtitle}
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height}
      emptyMessage="No data available for this report"
    >
      {renderChart()}
    </ChartContainer>
  );
}

export default ChartRenderer;
