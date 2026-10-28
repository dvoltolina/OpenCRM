/**
 * SequenceMetrics Component
 * Metrics panel displaying sequence performance data
 *
 * Phase 3 Implementation
 */

import { useMemo } from 'react';
import { useSequenceEnrollments } from '../../hooks/useSequenceEnrollments';
import type { Sequence } from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface SequenceMetricsProps {
  /** Sequence to show metrics for */
  sequence: Sequence;
  /** Show compact view */
  compact?: boolean;
}

interface MetricCardProps {
  label: string;
  value: number | string;
  subValue?: string;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
}

// ============================================
// Component
// ============================================

export function SequenceMetrics({ sequence, compact = false }: SequenceMetricsProps) {
  const { enrollments, isLoading, countByStatus } = useSequenceEnrollments(sequence.id);

  // Calculate metrics
  const metrics = useMemo(() => {
    const totalEnrolled = sequence.stats.totalEnrolled || enrollments.length;
    const active = countByStatus.active;
    const completed = sequence.stats.completedCount || countByStatus.completed;
    const exited = sequence.stats.exitedCount || countByStatus.exited;
    const bounced = countByStatus.bounced;
    const unsubscribed = countByStatus.unsubscribed;

    // Rates
    const completionRate = totalEnrolled > 0 ? (completed / totalEnrolled) * 100 : 0;
    const exitRate = totalEnrolled > 0 ? (exited / totalEnrolled) * 100 : 0;

    // Aggregate email stats
    const emailStats = enrollments.reduce(
      (acc, e) => ({
        sent: acc.sent + e.emailsSent,
        opened: acc.opened + e.emailsOpened,
        clicked: acc.clicked + e.emailsClicked,
        replied: acc.replied + e.repliesReceived,
      }),
      { sent: 0, opened: 0, clicked: 0, replied: 0 }
    );

    const openRate = emailStats.sent > 0 ? (emailStats.opened / emailStats.sent) * 100 : 0;
    const clickRate = emailStats.opened > 0 ? (emailStats.clicked / emailStats.opened) * 100 : 0;
    const replyRate = emailStats.sent > 0 ? (emailStats.replied / emailStats.sent) * 100 : 0;

    // Exit reasons breakdown
    const exitReasons = enrollments
      .filter((e) => e.exitReason)
      .reduce<Record<string, number>>((acc, e) => {
        const reason = e.exitReason!;
        acc[reason] = (acc[reason] || 0) + 1;
        return acc;
      }, {});

    return {
      totalEnrolled,
      active,
      completed,
      exited,
      bounced,
      unsubscribed,
      completionRate,
      exitRate,
      emailStats,
      openRate,
      clickRate,
      replyRate,
      exitReasons,
    };
  }, [sequence, enrollments, countByStatus]);

  if (isLoading) {
    return (
      <div className="sequence-metrics sequence-metrics--loading">
        <div className="sequence-metrics__spinner" />
        <span>Loading metrics...</span>
      </div>
    );
  }

  if (compact) {
    return <CompactMetrics metrics={metrics} />;
  }

  return (
    <div className="sequence-metrics" data-testid="sequence-metrics">
      {/* Enrollment Stats */}
      <div className="sequence-metrics__section">
        <h4 className="sequence-metrics__section-title">Enrollments</h4>
        <div className="sequence-metrics__cards">
          <MetricCard
            label="Total Enrolled"
            value={metrics.totalEnrolled}
          />
          <MetricCard
            label="Active"
            value={metrics.active}
            variant="success"
          />
          <MetricCard
            label="Completed"
            value={metrics.completed}
            variant="info"
          />
          <MetricCard
            label="Exited"
            value={metrics.exited}
            subValue={metrics.bounced > 0 ? `(${metrics.bounced} bounced)` : undefined}
          />
        </div>
      </div>

      {/* Rates */}
      <div className="sequence-metrics__section">
        <h4 className="sequence-metrics__section-title">Performance Rates</h4>
        <div className="sequence-metrics__cards">
          <MetricCard
            label="Completion Rate"
            value={`${metrics.completionRate.toFixed(1)}%`}
            variant={metrics.completionRate > 50 ? 'success' : 'default'}
          />
          <MetricCard
            label="Exit Rate"
            value={`${metrics.exitRate.toFixed(1)}%`}
            variant={metrics.exitRate > 30 ? 'warning' : 'default'}
          />
          <MetricCard
            label="Reply Rate"
            value={`${metrics.replyRate.toFixed(1)}%`}
            variant={metrics.replyRate > 10 ? 'success' : 'default'}
          />
          <MetricCard
            label="Open Rate"
            value={`${metrics.openRate.toFixed(1)}%`}
            variant={metrics.openRate > 30 ? 'success' : 'default'}
          />
        </div>
      </div>

      {/* Email Stats */}
      <div className="sequence-metrics__section">
        <h4 className="sequence-metrics__section-title">Email Engagement</h4>
        <div className="sequence-metrics__cards">
          <MetricCard label="Emails Sent" value={metrics.emailStats.sent} />
          <MetricCard label="Opened" value={metrics.emailStats.opened} />
          <MetricCard label="Clicked" value={metrics.emailStats.clicked} />
          <MetricCard label="Replies" value={metrics.emailStats.replied} />
        </div>
      </div>

      {/* Exit Reasons Chart */}
      {Object.keys(metrics.exitReasons).length > 0 && (
        <div className="sequence-metrics__section">
          <h4 className="sequence-metrics__section-title">Exit Reasons</h4>
          <ExitReasonsChart reasons={metrics.exitReasons} total={metrics.exited} />
        </div>
      )}

      {/* Status Distribution */}
      <div className="sequence-metrics__section">
        <h4 className="sequence-metrics__section-title">Status Distribution</h4>
        <StatusDistribution
          active={metrics.active}
          completed={metrics.completed}
          exited={metrics.exited}
          bounced={metrics.bounced}
          unsubscribed={metrics.unsubscribed}
          total={metrics.totalEnrolled}
        />
      </div>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

function MetricCard({ label, value, subValue, variant = 'default' }: MetricCardProps) {
  return (
    <div className={`sequence-metrics__card sequence-metrics__card--${variant}`}>
      <div className="sequence-metrics__card-value">{value}</div>
      <div className="sequence-metrics__card-label">{label}</div>
      {subValue && <div className="sequence-metrics__card-sub">{subValue}</div>}
    </div>
  );
}

interface CompactMetricsProps {
  metrics: {
    totalEnrolled: number;
    active: number;
    completed: number;
    completionRate: number;
    replyRate: number;
  };
}

function CompactMetrics({ metrics }: CompactMetricsProps) {
  return (
    <div className="sequence-metrics sequence-metrics--compact" data-testid="sequence-metrics-compact">
      <div className="sequence-metrics__compact-row">
        <span className="sequence-metrics__compact-label">Enrolled:</span>
        <span className="sequence-metrics__compact-value">{metrics.totalEnrolled}</span>
      </div>
      <div className="sequence-metrics__compact-row">
        <span className="sequence-metrics__compact-label">Active:</span>
        <span className="sequence-metrics__compact-value">{metrics.active}</span>
      </div>
      <div className="sequence-metrics__compact-row">
        <span className="sequence-metrics__compact-label">Completion:</span>
        <span className="sequence-metrics__compact-value">{metrics.completionRate.toFixed(0)}%</span>
      </div>
      <div className="sequence-metrics__compact-row">
        <span className="sequence-metrics__compact-label">Replies:</span>
        <span className="sequence-metrics__compact-value">{metrics.replyRate.toFixed(0)}%</span>
      </div>
    </div>
  );
}

interface ExitReasonsChartProps {
  reasons: Record<string, number>;
  total: number;
}

function ExitReasonsChart({ reasons, total }: ExitReasonsChartProps) {
  const reasonLabels: Record<string, string> = {
    manual: 'Manual removal',
    replied: 'Replied',
    unsubscribed: 'Unsubscribed',
    bounced: 'Bounced',
    meeting_booked: 'Meeting booked',
    deal_won: 'Deal won',
    deal_lost: 'Deal lost',
    converted: 'Converted',
  };

  const sortedReasons = Object.entries(reasons)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  return (
    <div className="sequence-metrics__exit-chart">
      {sortedReasons.map(([reason, count]) => {
        const percent = total > 0 ? (count / total) * 100 : 0;
        return (
          <div key={reason} className="sequence-metrics__exit-row">
            <div className="sequence-metrics__exit-label">
              {reasonLabels[reason] || reason}
            </div>
            <div className="sequence-metrics__exit-bar-container">
              <div
                className="sequence-metrics__exit-bar"
                style={{ width: `${percent}%` }}
              />
            </div>
            <div className="sequence-metrics__exit-count">{count}</div>
          </div>
        );
      })}
    </div>
  );
}

interface StatusDistributionProps {
  active: number;
  completed: number;
  exited: number;
  bounced: number;
  unsubscribed: number;
  total: number;
}

function StatusDistribution({
  active,
  completed,
  exited,
  bounced,
  unsubscribed,
  total,
}: StatusDistributionProps) {
  if (total === 0) {
    return <div className="sequence-metrics__empty">No enrollments yet</div>;
  }

  const segments = [
    { label: 'Active', value: active, color: '#22c55e' },
    { label: 'Completed', value: completed, color: '#3b82f6' },
    { label: 'Exited', value: exited, color: '#94a3b8' },
    { label: 'Bounced', value: bounced, color: '#f97316' },
    { label: 'Unsubscribed', value: unsubscribed, color: '#ef4444' },
  ].filter((s) => s.value > 0);

  return (
    <div className="sequence-metrics__distribution">
      <div className="sequence-metrics__distribution-bar">
        {segments.map((segment) => (
          <div
            key={segment.label}
            className="sequence-metrics__distribution-segment"
            style={{
              width: `${(segment.value / total) * 100}%`,
              backgroundColor: segment.color,
            }}
            title={`${segment.label}: ${segment.value} (${((segment.value / total) * 100).toFixed(1)}%)`}
          />
        ))}
      </div>
      <div className="sequence-metrics__distribution-legend">
        {segments.map((segment) => (
          <div key={segment.label} className="sequence-metrics__distribution-legend-item">
            <span
              className="sequence-metrics__distribution-dot"
              style={{ backgroundColor: segment.color }}
            />
            <span className="sequence-metrics__distribution-legend-label">
              {segment.label}: {segment.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default SequenceMetrics;
