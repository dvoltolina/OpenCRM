/**
 * SequenceTrendChart Component
 * Time-series chart showing enrollment, completion, and reply trends.
 * Uses Recharts for line chart visualization with multiple series.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect, useMemo } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import {
  getSequenceAnalyticsService,
  type TrendData,
  type DateRange,
} from '../../services/sequence-analytics-service';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceTrendChartProps {
  sequenceId: string;
  securityContext: SecurityContext;
  dateRange?: DateRange;
}

type TimeBucket = 'daily' | 'weekly' | 'monthly';
type MetricSeries = 'enrolled' | 'completed' | 'exited' | 'emailsSent' | 'replies';

interface SeriesConfig {
  key: MetricSeries;
  label: string;
  color: string;
  visible: boolean;
}

// ============================================
// Constants
// ============================================

const DEFAULT_SERIES: SeriesConfig[] = [
  { key: 'enrolled', label: 'Enrolled', color: 'var(--color-primary)', visible: true },
  { key: 'completed', label: 'Completed', color: 'var(--color-success)', visible: true },
  { key: 'exited', label: 'Exited', color: 'var(--color-danger)', visible: true },
  { key: 'emailsSent', label: 'Emails Sent', color: 'var(--color-info)', visible: false },
  { key: 'replies', label: 'Replies', color: 'var(--color-warning)', visible: true },
];

// ============================================
// Helper Functions
// ============================================

function formatDateLabel(dateStr: string, bucket: TimeBucket): string {
  if (bucket === 'weekly') {
    // Format: "2025-W01" -> "Week 1"
    const match = dateStr.match(/(\d{4})-W(\d{2})/);
    if (match) {
      return `W${parseInt(match[2], 10)}`;
    }
    return dateStr;
  }

  if (bucket === 'monthly') {
    // Format: "2025-01" -> "Jan '25"
    const match = dateStr.match(/(\d{4})-(\d{2})/);
    if (match) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const monthIndex = parseInt(match[2], 10) - 1;
      const year = match[1].slice(2);
      return `${months[monthIndex]} '${year}`;
    }
    return dateStr;
  }

  // Daily: "2025-01-15" -> "Jan 15"
  const match = dateStr.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (match) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthIndex = parseInt(match[2], 10) - 1;
    const day = parseInt(match[3], 10);
    return `${months[monthIndex]} ${day}`;
  }
  return dateStr;
}

// ============================================
// Simple Chart Component (No external dependency)
// ============================================

interface SimpleLineChartProps {
  data: TrendData[];
  series: SeriesConfig[];
  bucket: TimeBucket;
  width: number;
  height: number;
}

function SimpleLineChart({ data, series, bucket, width, height }: SimpleLineChartProps) {
  if (data.length === 0) return null;

  const padding = { top: 20, right: 20, bottom: 40, left: 50 };
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  // Calculate max value across all visible series
  const visibleSeries = series.filter((s) => s.visible);
  const maxValue = Math.max(
    ...data.flatMap((d) => visibleSeries.map((s) => d[s.key])),
    1
  );

  // Generate points for each series
  const getPoints = (seriesKey: MetricSeries): string => {
    return data
      .map((d, i) => {
        const x = padding.left + (i / (data.length - 1 || 1)) * chartWidth;
        const y = padding.top + chartHeight - (d[seriesKey] / maxValue) * chartHeight;
        return `${x},${y}`;
      })
      .join(' ');
  };

  // Generate Y-axis labels
  const yLabels = [0, Math.round(maxValue / 2), Math.round(maxValue)];

  // Generate X-axis labels (show every nth based on data size)
  const xLabelStep = Math.max(1, Math.floor(data.length / 6));
  const xLabels = data.filter((_, i) => i % xLabelStep === 0 || i === data.length - 1);

  return (
    <svg
      className="trend-chart__svg"
      viewBox={`0 0 ${width} ${height}`}
      preserveAspectRatio="xMidYMid meet"
    >
      {/* Grid lines */}
      {yLabels.map((label, i) => {
        const y = padding.top + chartHeight - (label / maxValue) * chartHeight;
        return (
          <g key={i}>
            <line
              x1={padding.left}
              y1={y}
              x2={padding.left + chartWidth}
              y2={y}
              stroke="var(--color-border)"
              strokeDasharray="4,4"
            />
            <text
              x={padding.left - 8}
              y={y + 4}
              textAnchor="end"
              className="trend-chart__axis-label"
            >
              {label}
            </text>
          </g>
        );
      })}

      {/* X-axis labels */}
      {xLabels.map((d) => {
        const dataIndex = data.indexOf(d);
        const x = padding.left + (dataIndex / (data.length - 1 || 1)) * chartWidth;
        return (
          <text
            key={d.date}
            x={x}
            y={height - 10}
            textAnchor="middle"
            className="trend-chart__axis-label"
          >
            {formatDateLabel(d.date, bucket)}
          </text>
        );
      })}

      {/* Lines */}
      {visibleSeries.map((s) => (
        <polyline
          key={s.key}
          points={getPoints(s.key)}
          fill="none"
          stroke={s.color}
          strokeWidth="2"
          className="trend-chart__line"
        />
      ))}

      {/* Data points */}
      {visibleSeries.map((s) =>
        data.map((d, i) => {
          const x = padding.left + (i / (data.length - 1 || 1)) * chartWidth;
          const y = padding.top + chartHeight - (d[s.key] / maxValue) * chartHeight;
          return (
            <circle
              key={`${s.key}-${i}`}
              cx={x}
              cy={y}
              r="4"
              fill={s.color}
              className="trend-chart__point"
            >
              <title>{`${s.label}: ${d[s.key]} (${formatDateLabel(d.date, bucket)})`}</title>
            </circle>
          );
        })
      )}
    </svg>
  );
}

// ============================================
// Component
// ============================================

export function SequenceTrendChart({
  sequenceId,
  securityContext,
  dateRange,
}: SequenceTrendChartProps) {
  const [trendData, setTrendData] = useState<TrendData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [bucket, setBucket] = useState<TimeBucket>('daily');
  const [series, setSeries] = useState<SeriesConfig[]>(DEFAULT_SERIES);

  useEffect(() => {
    const loadTrends = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const data = await analyticsService.getEnrollmentTrends(
          securityContext,
          sequenceId,
          bucket,
          dateRange
        );
        setTrendData(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load trend data');
      } finally {
        setIsLoading(false);
      }
    };

    loadTrends();
  }, [securityContext, sequenceId, bucket, dateRange]);

  const toggleSeries = (key: MetricSeries) => {
    setSeries((prev) =>
      prev.map((s) => (s.key === key ? { ...s, visible: !s.visible } : s))
    );
  };

  // Calculate totals for the period
  const totals = useMemo(() => {
    return {
      enrolled: trendData.reduce((sum, d) => sum + d.enrolled, 0),
      completed: trendData.reduce((sum, d) => sum + d.completed, 0),
      exited: trendData.reduce((sum, d) => sum + d.exited, 0),
      emailsSent: trendData.reduce((sum, d) => sum + d.emailsSent, 0),
      replies: trendData.reduce((sum, d) => sum + d.replies, 0),
    };
  }, [trendData]);

  if (isLoading) {
    return (
      <div className="sequence-trend">
        <div className="sequence-trend__loading">
          <div className="sequence-trend__spinner" />
          <p>Loading trend data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="sequence-trend">
        <div className="sequence-trend__error">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="sequence-trend">
      <div className="sequence-trend__header">
        <h2>Enrollment Trends</h2>
        <div className="sequence-trend__controls">
          <div className="sequence-trend__bucket-selector">
            <button
              className={`sequence-trend__bucket-btn ${bucket === 'daily' ? 'sequence-trend__bucket-btn--active' : ''}`}
              onClick={() => setBucket('daily')}
            >
              Daily
            </button>
            <button
              className={`sequence-trend__bucket-btn ${bucket === 'weekly' ? 'sequence-trend__bucket-btn--active' : ''}`}
              onClick={() => setBucket('weekly')}
            >
              Weekly
            </button>
            <button
              className={`sequence-trend__bucket-btn ${bucket === 'monthly' ? 'sequence-trend__bucket-btn--active' : ''}`}
              onClick={() => setBucket('monthly')}
            >
              Monthly
            </button>
          </div>
        </div>
      </div>

      {/* Series toggles */}
      <div className="sequence-trend__legend">
        {series.map((s) => (
          <label
            key={s.key}
            className={`sequence-trend__legend-item ${s.visible ? 'sequence-trend__legend-item--active' : ''}`}
          >
            <input
              type="checkbox"
              checked={s.visible}
              onChange={() => toggleSeries(s.key)}
            />
            <span
              className="sequence-trend__legend-color"
              style={{ backgroundColor: s.color }}
            />
            <span className="sequence-trend__legend-label">{s.label}</span>
            <span className="sequence-trend__legend-total">({totals[s.key]})</span>
          </label>
        ))}
      </div>

      {/* Chart */}
      {trendData.length === 0 ? (
        <div className="sequence-trend__empty">
          <svg viewBox="0 0 24 24" width="48" height="48" fill="currentColor">
            <path d="M3.5 18.49l6-6.01 4 4L22 6.92l-1.41-1.41-7.09 7.97-4-4L2 16.99z" />
          </svg>
          <p>No trend data available for this period</p>
          <p className="sequence-trend__empty-hint">
            Data will appear here once enrollments start occurring.
          </p>
        </div>
      ) : (
        <div className="sequence-trend__chart-container">
          <SimpleLineChart
            data={trendData}
            series={series}
            bucket={bucket}
            width={600}
            height={300}
          />
        </div>
      )}

      {/* Summary Stats */}
      {trendData.length > 0 && (
        <div className="sequence-trend__summary">
          <div className="sequence-trend__summary-item">
            <span className="sequence-trend__summary-value sequence-trend__summary-value--enrolled">
              {totals.enrolled}
            </span>
            <span className="sequence-trend__summary-label">Total Enrolled</span>
          </div>
          <div className="sequence-trend__summary-item">
            <span className="sequence-trend__summary-value sequence-trend__summary-value--completed">
              {totals.completed}
            </span>
            <span className="sequence-trend__summary-label">Completed</span>
          </div>
          <div className="sequence-trend__summary-item">
            <span className="sequence-trend__summary-value sequence-trend__summary-value--exited">
              {totals.exited}
            </span>
            <span className="sequence-trend__summary-label">Exited</span>
          </div>
          <div className="sequence-trend__summary-item">
            <span className="sequence-trend__summary-value sequence-trend__summary-value--replies">
              {totals.replies}
            </span>
            <span className="sequence-trend__summary-label">Replies</span>
          </div>
        </div>
      )}

      {/* Data Table */}
      {trendData.length > 0 && (
        <div className="sequence-trend__table-container">
          <h3>Data Table</h3>
          <table className="sequence-trend__table">
            <thead>
              <tr>
                <th>Period</th>
                <th>Enrolled</th>
                <th>Completed</th>
                <th>Exited</th>
                <th>Emails</th>
                <th>Replies</th>
              </tr>
            </thead>
            <tbody>
              {trendData.map((d) => (
                <tr key={d.date}>
                  <td>{formatDateLabel(d.date, bucket)}</td>
                  <td>{d.enrolled}</td>
                  <td>{d.completed}</td>
                  <td>{d.exited}</td>
                  <td>{d.emailsSent}</td>
                  <td>{d.replies}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td><strong>Total</strong></td>
                <td><strong>{totals.enrolled}</strong></td>
                <td><strong>{totals.completed}</strong></td>
                <td><strong>{totals.exited}</strong></td>
                <td><strong>{totals.emailsSent}</strong></td>
                <td><strong>{totals.replies}</strong></td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}

      {/* Export Button */}
      {trendData.length > 0 && (
        <div className="sequence-trend__actions">
          <button
            className="btn btn-secondary"
            onClick={() => {
              const headers = ['Period', 'Enrolled', 'Completed', 'Exited', 'Emails Sent', 'Replies'];
              const rows = trendData.map((d) => [
                formatDateLabel(d.date, bucket),
                d.enrolled,
                d.completed,
                d.exited,
                d.emailsSent,
                d.replies,
              ]);
              const csv = [headers, ...rows].map((row) => row.join(',')).join('\n');
              const blob = new Blob([csv], { type: 'text/csv' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = `sequence_trends_${bucket}.csv`;
              a.click();
              URL.revokeObjectURL(url);
            }}
          >
            Export Data
          </button>
        </div>
      )}
    </div>
  );
}

export default SequenceTrendChart;
