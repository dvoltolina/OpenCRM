/**
 * ActivityChart Component
 * Stacked bar chart showing activity volume over time
 *
 * Agent CRM-19 Implementation
 */

import { useCallback } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { ChartContainer } from './ChartContainer';
import type { SalesActivity, SalesActivityType } from '../../types/models';
import './charts.css';

interface ActivityChartDataPoint {
  date: string;
  label: string;
  call: number;
  email: number;
  meeting: number;
  note: number;
  task: number;
  total: number;
}

// ============================================
// Types
// ============================================

export interface ActivityChartProps {
  /** Activities to chart */
  activities: SalesActivity[];
  /** Number of days to show */
  days?: number;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
}

// ============================================
// Colors
// ============================================

const ACTIVITY_COLORS: Record<SalesActivityType, string> = {
  call: '#6366f1',
  email: '#8b5cf6',
  meeting: '#a855f7',
  note: '#f59e0b',
  task: '#22c55e',
};

// ============================================
// Helper Functions
// ============================================

function getDateKey(date: Date): string {
  return date.toISOString().split('T')[0];
}

function formatDateLabel(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function generateDateRange(days: number): string[] {
  const dates: string[] = [];
  const now = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    dates.push(getDateKey(date));
  }

  return dates;
}

// ============================================
// Component
// ============================================

/**
 * ActivityChart - Activity volume over time
 *
 * @example
 * ```tsx
 * const { activities } = useRecentActivities(30);
 *
 * <ActivityChart
 *   activities={activities}
 *   days={30}
 * />
 * ```
 */
export function ActivityChart({
  activities,
  days = 14,
  isLoading = false,
  height = 300,
}: ActivityChartProps) {
  const isEmpty = activities.length === 0;

  // Generate date range
  const dateRange = generateDateRange(days);

  // Initialize data
  const dataMap: Record<string, Record<SalesActivityType, number>> = {};
  for (const date of dateRange) {
    dataMap[date] = { call: 0, email: 0, meeting: 0, note: 0, task: 0 };
  }

  // Aggregate activities by date and type
  for (const activity of activities) {
    const dateKey = getDateKey(new Date(activity.createdAt));
    if (dataMap[dateKey]) {
      dataMap[dateKey][activity.type] += 1;
    }
  }

  // Convert to chart data
  const chartData = dateRange.map((date) => ({
    date,
    label: formatDateLabel(date),
    ...dataMap[date],
    total: Object.values(dataMap[date]).reduce((a, b) => a + b, 0),
  }));

  const renderTooltip = useCallback(
    ({
      active,
      payload,
      label,
    }: {
      active?: boolean;
      payload?: { payload: ActivityChartDataPoint }[];
      label?: string;
    }) => {
      if (!active || !payload || payload.length === 0) return null;

      const data = payload[0]?.payload;
      if (!data) return null;

      return (
        <div className="recharts-default-tooltip">
          <p className="recharts-tooltip-label">{label}</p>
          {data.call > 0 && (
            <p className="recharts-tooltip-item" style={{ color: ACTIVITY_COLORS.call }}>
              Calls: {data.call}
            </p>
          )}
          {data.email > 0 && (
            <p className="recharts-tooltip-item" style={{ color: ACTIVITY_COLORS.email }}>
              Emails: {data.email}
            </p>
          )}
          {data.meeting > 0 && (
            <p className="recharts-tooltip-item" style={{ color: ACTIVITY_COLORS.meeting }}>
              Meetings: {data.meeting}
            </p>
          )}
          {data.note > 0 && (
            <p className="recharts-tooltip-item" style={{ color: ACTIVITY_COLORS.note }}>
              Notes: {data.note}
            </p>
          )}
          {data.task > 0 && (
            <p className="recharts-tooltip-item" style={{ color: ACTIVITY_COLORS.task }}>
              Tasks: {data.task}
            </p>
          )}
          <p className="recharts-tooltip-item" style={{ marginTop: 4, fontWeight: 500 }}>
            Total: {data.total}
          </p>
        </div>
      );
    },
    []
  );

  return (
    <ChartContainer
      title="Activity Volume"
      subtitle={`Last ${days} days`}
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height}
      emptyMessage="No activities recorded"
    >
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={chartData} margin={{ top: 10, right: 30, left: 0, bottom: 10 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
          <XAxis
            dataKey="label"
            stroke="var(--color-text-muted)"
            fontSize={11}
            tickLine={false}
            interval={days > 14 ? 2 : 0}
          />
          <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
          <Tooltip content={renderTooltip as any} />
          <Legend />
          <Bar dataKey="call" name="Calls" stackId="a" fill={ACTIVITY_COLORS.call} />
          <Bar dataKey="email" name="Emails" stackId="a" fill={ACTIVITY_COLORS.email} />
          <Bar dataKey="meeting" name="Meetings" stackId="a" fill={ACTIVITY_COLORS.meeting} />
          <Bar dataKey="note" name="Notes" stackId="a" fill={ACTIVITY_COLORS.note} />
          <Bar dataKey="task" name="Tasks" stackId="a" fill={ACTIVITY_COLORS.task} radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
}

export default ActivityChart;
