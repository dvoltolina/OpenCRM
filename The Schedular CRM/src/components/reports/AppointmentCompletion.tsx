/**
 * AppointmentCompletion Component
 * Chart showing missed vs completed appointment rates over time
 *
 * Agent CRM-31 Implementation
 */

import { useState } from 'react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { ChartContainer } from '../charts/ChartContainer';
import type { AppointmentCompletionData } from '../../hooks/useAdvancedAnalytics';
import './reports.css';

// ============================================
// Types
// ============================================

export interface AppointmentCompletionProps {
  /** Completion data over time */
  data: AppointmentCompletionData[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Available staff for filtering */
  staffList?: { id: string; name: string }[];
  /** Current staff filter */
  selectedStaffId?: string;
  /** Staff selection callback */
  onStaffChange?: (staffId: string | undefined) => void;
  /** Current granularity */
  granularity?: 'daily' | 'weekly' | 'monthly';
  /** Granularity change callback */
  onGranularityChange?: (granularity: 'daily' | 'weekly' | 'monthly') => void;
}

// ============================================
// Helper Functions
// ============================================

function formatPercentage(value: number): string {
  return `${value.toFixed(1)}%`;
}

// ============================================
// Component
// ============================================

/**
 * AppointmentCompletion - Shows appointment completion rates over time
 *
 * @example
 * ```tsx
 * const completionData = analytics.getAppointmentCompletion(
 *   dateRange,
 *   'daily',
 *   selectedStaffId
 * );
 *
 * <AppointmentCompletion
 *   data={completionData}
 *   staffList={staffMembers}
 *   selectedStaffId={selectedStaffId}
 *   onStaffChange={setSelectedStaffId}
 *   granularity="daily"
 *   onGranularityChange={setGranularity}
 * />
 * ```
 */
export function AppointmentCompletion({
  data,
  isLoading = false,
  staffList = [],
  selectedStaffId,
  onStaffChange,
  granularity = 'daily',
  onGranularityChange,
}: AppointmentCompletionProps) {
  const [chartType, setChartType] = useState<'line' | 'bar'>('line');
  const [metric, setMetric] = useState<'count' | 'rate'>('count');

  // Calculate overall stats
  const totalScheduled = data.reduce((sum, d) => sum + d.scheduled, 0);
  const totalCompleted = data.reduce((sum, d) => sum + d.completed, 0);
  const totalMissed = data.reduce((sum, d) => sum + d.missed, 0);
  const totalCancelled = data.reduce((sum, d) => sum + d.cancelled, 0);
  const overallCompletionRate = totalScheduled > 0
    ? (totalCompleted / totalScheduled) * 100
    : 0;

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (!active || !payload || !payload.length) return null;

    const dataPoint = payload[0]?.payload;
    if (!dataPoint) return null;

    return (
      <div className="recharts-default-tooltip">
        <p className="recharts-tooltip-label">{label}</p>
        <p className="recharts-tooltip-item">
          Scheduled: {dataPoint.scheduled}
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-success)' }}>
          Completed: {dataPoint.completed} ({formatPercentage(dataPoint.completionRate)})
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-danger)' }}>
          Missed: {dataPoint.missed}
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-warning)' }}>
          Cancelled: {dataPoint.cancelled}
        </p>
      </div>
    );
  };

  const renderChart = () => {
    const chartData = metric === 'rate'
      ? data.map(d => ({
          ...d,
          completionRate: d.completionRate,
          missedRate: d.scheduled > 0 ? (d.missed / d.scheduled) * 100 : 0,
        }))
      : data;

    if (chartType === 'line') {
      return (
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
            <XAxis
              dataKey="date"
              stroke="var(--color-text-muted)"
              fontSize={12}
              tickLine={false}
            />
            <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
            <Tooltip content={<CustomTooltip />} />
            <Legend />
            {metric === 'count' ? (
              <>
                <Line
                  type="monotone"
                  dataKey="completed"
                  name="Completed"
                  stroke="var(--color-success)"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="missed"
                  name="Missed"
                  stroke="var(--color-danger)"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="cancelled"
                  name="Cancelled"
                  stroke="var(--color-warning)"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                />
              </>
            ) : (
              <>
                <Line
                  type="monotone"
                  dataKey="completionRate"
                  name="Completion Rate"
                  stroke="var(--color-success)"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="missedRate"
                  name="Missed Rate"
                  stroke="var(--color-danger)"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                />
              </>
            )}
          </LineChart>
        </ResponsiveContainer>
      );
    }

    // Bar chart
    return (
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
          <XAxis
            dataKey="date"
            stroke="var(--color-text-muted)"
            fontSize={12}
            tickLine={false}
          />
          <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          {metric === 'count' ? (
            <>
              <Bar dataKey="completed" name="Completed" fill="var(--color-success)" />
              <Bar dataKey="missed" name="Missed" fill="var(--color-danger)" />
              <Bar dataKey="cancelled" name="Cancelled" fill="var(--color-warning)" />
            </>
          ) : (
            <>
              <Bar dataKey="completionRate" name="Completion Rate" fill="var(--color-success)" />
              <Bar dataKey="missedRate" name="Missed Rate" fill="var(--color-danger)" />
            </>
          )}
        </BarChart>
      </ResponsiveContainer>
    );
  };

  return (
    <div className="appointment-completion">
      <div className="appointment-completion__header">
        <h2 className="appointment-completion__title">Appointment Completion Rates</h2>
      </div>

      <div className="appointment-completion__stats">
        <div className="appointment-completion__stat">
          <span className="appointment-completion__stat-label">Total Scheduled</span>
          <span className="appointment-completion__stat-value">{totalScheduled}</span>
        </div>
        <div className="appointment-completion__stat appointment-completion__stat--success">
          <span className="appointment-completion__stat-label">Completed</span>
          <span className="appointment-completion__stat-value">{totalCompleted}</span>
        </div>
        <div className="appointment-completion__stat appointment-completion__stat--danger">
          <span className="appointment-completion__stat-label">Missed</span>
          <span className="appointment-completion__stat-value">{totalMissed}</span>
        </div>
        <div className="appointment-completion__stat appointment-completion__stat--warning">
          <span className="appointment-completion__stat-label">Cancelled</span>
          <span className="appointment-completion__stat-value">{totalCancelled}</span>
        </div>
        <div className="appointment-completion__stat appointment-completion__stat--primary">
          <span className="appointment-completion__stat-label">Completion Rate</span>
          <span className="appointment-completion__stat-value">
            {formatPercentage(overallCompletionRate)}
          </span>
        </div>
      </div>

      <div className="appointment-completion__controls">
        <div className="appointment-completion__control-group">
          <label>Staff Member:</label>
          <select
            value={selectedStaffId || ''}
            onChange={(e) => onStaffChange?.(e.target.value || undefined)}
            className="appointment-completion__select"
          >
            <option value="">All Staff</option>
            {staffList.map((staff) => (
              <option key={staff.id} value={staff.id}>
                {staff.name}
              </option>
            ))}
          </select>
        </div>

        {onGranularityChange && (
          <div className="appointment-completion__control-group">
            <label>Time Period:</label>
            <div className="appointment-completion__button-group">
              <button
                className={`appointment-completion__btn ${granularity === 'daily' ? 'appointment-completion__btn--active' : ''}`}
                onClick={() => onGranularityChange('daily')}
              >
                Daily
              </button>
              <button
                className={`appointment-completion__btn ${granularity === 'weekly' ? 'appointment-completion__btn--active' : ''}`}
                onClick={() => onGranularityChange('weekly')}
              >
                Weekly
              </button>
              <button
                className={`appointment-completion__btn ${granularity === 'monthly' ? 'appointment-completion__btn--active' : ''}`}
                onClick={() => onGranularityChange('monthly')}
              >
                Monthly
              </button>
            </div>
          </div>
        )}

        <div className="appointment-completion__control-group">
          <label>Chart Type:</label>
          <div className="appointment-completion__button-group">
            <button
              className={`appointment-completion__btn ${chartType === 'line' ? 'appointment-completion__btn--active' : ''}`}
              onClick={() => setChartType('line')}
            >
              Line
            </button>
            <button
              className={`appointment-completion__btn ${chartType === 'bar' ? 'appointment-completion__btn--active' : ''}`}
              onClick={() => setChartType('bar')}
            >
              Bar
            </button>
          </div>
        </div>

        <div className="appointment-completion__control-group">
          <label>Metric:</label>
          <div className="appointment-completion__button-group">
            <button
              className={`appointment-completion__btn ${metric === 'count' ? 'appointment-completion__btn--active' : ''}`}
              onClick={() => setMetric('count')}
            >
              Count
            </button>
            <button
              className={`appointment-completion__btn ${metric === 'rate' ? 'appointment-completion__btn--active' : ''}`}
              onClick={() => setMetric('rate')}
            >
              Rate %
            </button>
          </div>
        </div>
      </div>

      <ChartContainer
        title={`Appointment ${metric === 'count' ? 'Counts' : 'Rates'} Over Time`}
        subtitle={selectedStaffId ? `Filtered by staff member` : 'All staff members'}
        isLoading={isLoading}
        isEmpty={data.length === 0}
        height={400}
        emptyMessage="No appointment data available for this period"
      >
        {renderChart()}
      </ChartContainer>
    </div>
  );
}

export default AppointmentCompletion;
