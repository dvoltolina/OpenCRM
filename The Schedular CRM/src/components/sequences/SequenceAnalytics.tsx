/**
 * SequenceAnalytics Component
 * Deep dive analytics for a single sequence with tabbed interface:
 * - Overview: Key metrics and comparisons
 * - Funnel: Visual enrollment funnel
 * - Step Performance: Detailed step-by-step breakdown
 * - Timing: Send time analysis
 * - Trends: Time-series charts
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import {
  getSequenceAnalyticsService,
  type SequenceMetrics,
  type DateRange,
} from '../../services/sequence-analytics-service';
import { getSequenceRepository } from '../../data/repositories/sequence-repository';
import type { Sequence } from '../../types/sequences';
import { StepPerformanceTable } from './StepPerformanceTable';
import { EnrollmentFunnel } from './EnrollmentFunnel';
import { SendTimeHeatmap } from './SendTimeHeatmap';
import { SequenceTrendChart } from './SequenceTrendChart';
import './sequences.css';

// ============================================
// Types
// ============================================

type AnalyticsTab = 'overview' | 'funnel' | 'steps' | 'timing' | 'trends';

interface DateRangeOption {
  label: string;
  value: string;
  getRange: () => DateRange;
}

// ============================================
// Constants
// ============================================

const DATE_RANGE_OPTIONS: DateRangeOption[] = [
  {
    label: 'Last 7 days',
    value: '7d',
    getRange: () => ({
      start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      end: new Date(),
    }),
  },
  {
    label: 'Last 30 days',
    value: '30d',
    getRange: () => ({
      start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      end: new Date(),
    }),
  },
  {
    label: 'Last 90 days',
    value: '90d',
    getRange: () => ({
      start: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
      end: new Date(),
    }),
  },
  {
    label: 'All time',
    value: 'all',
    getRange: () => ({
      start: new Date(0),
      end: new Date(),
    }),
  },
];

const TABS: { id: AnalyticsTab; label: string }[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'funnel', label: 'Funnel' },
  { id: 'steps', label: 'Step Performance' },
  { id: 'timing', label: 'Timing' },
  { id: 'trends', label: 'Trends' },
];

// ============================================
// Helper Functions
// ============================================

function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}

function formatNumber(value: number): string {
  if (value >= 1000000) {
    return `${(value / 1000000).toFixed(1)}M`;
  }
  if (value >= 1000) {
    return `${(value / 1000).toFixed(1)}K`;
  }
  return value.toString();
}

function formatDays(days: number): string {
  if (days < 1) {
    const hours = Math.round(days * 24);
    return `${hours}h`;
  }
  return `${days.toFixed(1)}d`;
}

// ============================================
// Component
// ============================================

export function SequenceAnalytics() {
  const { sequenceId } = useParams<{ sequenceId: string }>();
  const navigate = useNavigate();
  const { crmUser, businessId } = useAuth();

  const [activeTab, setActiveTab] = useState<AnalyticsTab>('overview');
  const [selectedRange, setSelectedRange] = useState<string>('30d');
  const [sequence, setSequence] = useState<Sequence | null>(null);
  const [metrics, setMetrics] = useState<SequenceMetrics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const securityContext = useMemo(() => {
    if (!crmUser || !businessId) return null;
    const teamIds = sanitizeTeamIds(crmUser.teamIds || []);
    const managedTeamIds = sanitizeTeamIds(crmUser.managedTeamIds || []);
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      teamIds,
      managedTeamIds,
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  const dateRange = useMemo(() => {
    const option = DATE_RANGE_OPTIONS.find((o) => o.value === selectedRange);
    return option ? option.getRange() : DATE_RANGE_OPTIONS[1].getRange();
  }, [selectedRange]);

  const loadAnalytics = useCallback(async () => {
    if (!securityContext || !sequenceId) return;

    setIsLoading(true);
    setError(null);

    try {
      const analyticsService = getSequenceAnalyticsService();
      const sequenceRepo = getSequenceRepository();

      // Load sequence
      const sequenceResult = await sequenceRepo.getById(securityContext, sequenceId);
      if (!sequenceResult.success || !sequenceResult.data) {
        setError('Sequence not found');
        return;
      }
      setSequence(sequenceResult.data);

      // Load metrics
      const metricsData = await analyticsService.calculateSequenceMetrics(
        securityContext,
        sequenceId,
        dateRange
      );
      setMetrics(metricsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load analytics');
    } finally {
      setIsLoading(false);
    }
  }, [securityContext, sequenceId, dateRange]);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  const handleExport = async () => {
    if (!metrics) return;

    // Create CSV content
    const rows = [
      ['Metric', 'Value'],
      ['Sequence Name', metrics.sequenceName],
      ['Total Enrolled', metrics.totalEnrolled.toString()],
      ['Active Enrollments', metrics.activeEnrollments.toString()],
      ['Completed', metrics.completedCount.toString()],
      ['Exited', metrics.exitedCount.toString()],
      ['Completion Rate', formatPercent(metrics.completionRate)],
      ['Emails Sent', metrics.emailsSent.toString()],
      ['Open Rate', formatPercent(metrics.openRate)],
      ['Click Rate', formatPercent(metrics.clickRate)],
      ['Reply Rate', formatPercent(metrics.replyRate)],
      ['Bounce Rate', formatPercent(metrics.bounceRate)],
      ['Avg Time to Complete', formatDays(metrics.avgTimeToComplete)],
      ['Avg Time to Reply', formatDays(metrics.avgTimeToReply)],
      ['Meetings Booked', metrics.meetingsBooked.toString()],
      ['Meeting Rate', formatPercent(metrics.meetingBookingRate)],
    ];

    const csv = rows.map((row) => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${metrics.sequenceName.replace(/\s+/g, '_')}_analytics.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (isLoading) {
    return (
      <div className="sequence-analytics">
        <div className="sequence-analytics__loading">
          <div className="sequence-analytics__spinner" />
          <p>Loading analytics...</p>
        </div>
      </div>
    );
  }

  if (error || !sequence || !metrics) {
    return (
      <div className="sequence-analytics">
        <div className="sequence-analytics__error">
          <p>Error: {error || 'Failed to load analytics'}</p>
          <button className="btn btn-primary" onClick={() => navigate('/sequences')}>
            Back to Sequences
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="sequence-analytics">
      <header className="sequence-analytics__header">
        <div className="sequence-analytics__header-left">
          <button
            className="sequence-analytics__back-btn"
            onClick={() => navigate('/sequences')}
            aria-label="Back to sequences"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
              <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" />
            </svg>
          </button>
          <div className="sequence-analytics__title-group">
            <h1>{sequence.name}</h1>
            <span
              className={`sequence-analytics__status sequence-analytics__status--${sequence.status}`}
            >
              {sequence.status}
            </span>
          </div>
        </div>
        <div className="sequence-analytics__header-right">
          <select
            className="sequence-analytics__date-select"
            value={selectedRange}
            onChange={(e) => setSelectedRange(e.target.value)}
          >
            {DATE_RANGE_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <button className="btn btn-secondary" onClick={handleExport}>
            Export CSV
          </button>
        </div>
      </header>

      {/* Tabs */}
      <nav className="sequence-analytics__tabs">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            className={`sequence-analytics__tab ${
              activeTab === tab.id ? 'sequence-analytics__tab--active' : ''
            }`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </nav>

      {/* Tab Content */}
      <div className="sequence-analytics__content">
        {activeTab === 'overview' && (
          <OverviewTab metrics={metrics} sequence={sequence} />
        )}
        {activeTab === 'funnel' && sequenceId && securityContext && (
          <EnrollmentFunnel
            sequenceId={sequenceId}
            securityContext={securityContext}
            dateRange={dateRange}
          />
        )}
        {activeTab === 'steps' && sequenceId && securityContext && (
          <StepPerformanceTable
            sequenceId={sequenceId}
            securityContext={securityContext}
            dateRange={dateRange}
          />
        )}
        {activeTab === 'timing' && sequenceId && securityContext && (
          <SendTimeHeatmap
            sequenceId={sequenceId}
            securityContext={securityContext}
          />
        )}
        {activeTab === 'trends' && sequenceId && securityContext && (
          <SequenceTrendChart
            sequenceId={sequenceId}
            securityContext={securityContext}
            dateRange={dateRange}
          />
        )}
      </div>
    </div>
  );
}

// ============================================
// Overview Tab Component
// ============================================

interface OverviewTabProps {
  metrics: SequenceMetrics;
  sequence: Sequence;
}

function OverviewTab({ metrics, sequence }: OverviewTabProps) {
  return (
    <div className="sequence-analytics__overview">
      {/* Key Metrics */}
      <section className="sequence-analytics__metrics-grid">
        <div className="sequence-analytics__metric-card">
          <span className="sequence-analytics__metric-label">Total Enrolled</span>
          <span className="sequence-analytics__metric-value">
            {formatNumber(metrics.totalEnrolled)}
          </span>
          <span className="sequence-analytics__metric-sublabel">
            {metrics.activeEnrollments} active
          </span>
        </div>

        <div className="sequence-analytics__metric-card">
          <span className="sequence-analytics__metric-label">Completion Rate</span>
          <span
            className={`sequence-analytics__metric-value ${
              metrics.completionRate >= 50
                ? 'sequence-analytics__metric-value--success'
                : metrics.completionRate >= 25
                ? 'sequence-analytics__metric-value--warning'
                : 'sequence-analytics__metric-value--danger'
            }`}
          >
            {formatPercent(metrics.completionRate)}
          </span>
          <span className="sequence-analytics__metric-sublabel">
            {metrics.completedCount} completed, {metrics.exitedCount} exited
          </span>
        </div>

        <div className="sequence-analytics__metric-card">
          <span className="sequence-analytics__metric-label">Reply Rate</span>
          <span
            className={`sequence-analytics__metric-value ${
              metrics.replyRate >= 10
                ? 'sequence-analytics__metric-value--success'
                : metrics.replyRate >= 5
                ? 'sequence-analytics__metric-value--warning'
                : ''
            }`}
          >
            {formatPercent(metrics.replyRate)}
          </span>
          <span className="sequence-analytics__metric-sublabel">
            {metrics.emailsReplied} replies from {metrics.emailsDelivered} delivered
          </span>
        </div>

        <div className="sequence-analytics__metric-card">
          <span className="sequence-analytics__metric-label">Avg Time to Complete</span>
          <span className="sequence-analytics__metric-value">
            {formatDays(metrics.avgTimeToComplete)}
          </span>
          <span className="sequence-analytics__metric-sublabel">
            {metrics.avgTimeToReply > 0 ? `${formatDays(metrics.avgTimeToReply)} to first reply` : 'No replies yet'}
          </span>
        </div>
      </section>

      {/* Email Performance */}
      <section className="sequence-analytics__section">
        <h2>Email Performance</h2>
        <div className="sequence-analytics__email-stats">
          <div className="sequence-analytics__stat-row">
            <span className="sequence-analytics__stat-label">Emails Sent</span>
            <span className="sequence-analytics__stat-value">{formatNumber(metrics.emailsSent)}</span>
          </div>
          <div className="sequence-analytics__stat-row">
            <span className="sequence-analytics__stat-label">Delivered</span>
            <span className="sequence-analytics__stat-value">
              {formatNumber(metrics.emailsDelivered)} ({formatPercent(metrics.deliveryRate)})
            </span>
          </div>
          <div className="sequence-analytics__stat-row">
            <span className="sequence-analytics__stat-label">Opened</span>
            <span className="sequence-analytics__stat-value">
              {formatNumber(metrics.emailsOpened)} ({formatPercent(metrics.openRate)})
            </span>
          </div>
          <div className="sequence-analytics__stat-row">
            <span className="sequence-analytics__stat-label">Clicked</span>
            <span className="sequence-analytics__stat-value">
              {formatNumber(metrics.emailsClicked)} ({formatPercent(metrics.clickRate)})
            </span>
          </div>
          <div className="sequence-analytics__stat-row">
            <span className="sequence-analytics__stat-label">Replied</span>
            <span className="sequence-analytics__stat-value">
              {formatNumber(metrics.emailsReplied)} ({formatPercent(metrics.replyRate)})
            </span>
          </div>
          <div className="sequence-analytics__stat-row sequence-analytics__stat-row--danger">
            <span className="sequence-analytics__stat-label">Bounced</span>
            <span className="sequence-analytics__stat-value">
              {formatNumber(metrics.emailsBounced)} ({formatPercent(metrics.bounceRate)})
            </span>
          </div>
        </div>
      </section>

      {/* Exit Reasons */}
      {Object.keys(metrics.exitReasons).length > 0 && (
        <section className="sequence-analytics__section">
          <h2>Exit Reasons</h2>
          <div className="sequence-analytics__exit-reasons">
            {Object.entries(metrics.exitReasons)
              .sort((a, b) => b[1] - a[1])
              .map(([reason, count]) => (
                <div key={reason} className="sequence-analytics__exit-reason">
                  <span className="sequence-analytics__exit-reason-label">
                    {reason.replace(/_/g, ' ')}
                  </span>
                  <span className="sequence-analytics__exit-reason-value">{count}</span>
                  <div
                    className="sequence-analytics__exit-reason-bar"
                    style={{
                      width: `${(count / metrics.exitedCount) * 100}%`,
                    }}
                  />
                </div>
              ))}
          </div>
        </section>
      )}

      {/* Conversion Metrics */}
      <section className="sequence-analytics__section">
        <h2>Conversion Metrics</h2>
        <div className="sequence-analytics__conversions">
          <div className="sequence-analytics__conversion-card">
            <span className="sequence-analytics__conversion-value">{metrics.meetingsBooked}</span>
            <span className="sequence-analytics__conversion-label">Meetings Booked</span>
            <span className="sequence-analytics__conversion-rate">
              {formatPercent(metrics.meetingBookingRate)}
            </span>
          </div>
          <div className="sequence-analytics__conversion-card">
            <span className="sequence-analytics__conversion-value">{metrics.dealsCreated}</span>
            <span className="sequence-analytics__conversion-label">Deals Created</span>
            <span className="sequence-analytics__conversion-rate">
              {formatPercent(metrics.dealConversionRate)}
            </span>
          </div>
          <div className="sequence-analytics__conversion-card">
            <span className="sequence-analytics__conversion-value">{metrics.tasksCreated}</span>
            <span className="sequence-analytics__conversion-label">Tasks Created</span>
            <span className="sequence-analytics__conversion-rate">
              {metrics.taskCompletionRate > 0 ? formatPercent(metrics.taskCompletionRate) : 'N/A'}
            </span>
          </div>
        </div>
      </section>

      {/* Sequence Info */}
      <section className="sequence-analytics__section sequence-analytics__section--info">
        <h2>Sequence Details</h2>
        <div className="sequence-analytics__info-grid">
          <div className="sequence-analytics__info-item">
            <span className="sequence-analytics__info-label">Steps</span>
            <span className="sequence-analytics__info-value">{sequence.steps.length}</span>
          </div>
          <div className="sequence-analytics__info-item">
            <span className="sequence-analytics__info-label">Owner</span>
            <span className="sequence-analytics__info-value">{sequence.ownerName}</span>
          </div>
          <div className="sequence-analytics__info-item">
            <span className="sequence-analytics__info-label">Created</span>
            <span className="sequence-analytics__info-value">
              {sequence.createdAt.toLocaleDateString()}
            </span>
          </div>
          <div className="sequence-analytics__info-item">
            <span className="sequence-analytics__info-label">Last Updated</span>
            <span className="sequence-analytics__info-value">
              {sequence.updatedAt?.toLocaleDateString() || 'Never'}
            </span>
          </div>
        </div>
      </section>
    </div>
  );
}

export default SequenceAnalytics;
