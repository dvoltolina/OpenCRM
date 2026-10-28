/**
 * StepPerformanceTable Component
 * Detailed step-by-step breakdown of sequence performance metrics.
 * Sortable table showing execution stats, email metrics, and dropout rates.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import type { ReactNode } from 'react';
import { useState, useEffect, useMemo } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import {
  getSequenceAnalyticsService,
  type StepMetrics,
  type DateRange,
} from '../../services/sequence-analytics-service';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface StepPerformanceTableProps {
  sequenceId: string;
  securityContext: SecurityContext;
  dateRange?: DateRange;
}

type SortField =
  | 'stepIndex'
  | 'executed'
  | 'successRate'
  | 'openRate'
  | 'clickRate'
  | 'replyRate'
  | 'dropoutRate';

type SortDirection = 'asc' | 'desc';

// ============================================
// Helper Functions
// ============================================

function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}

function getStepTypeIcon(stepType: string): ReactNode {
  switch (stepType) {
    case 'email':
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
        </svg>
      );
    case 'task':
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M19 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
        </svg>
      );
    case 'wait':
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" />
          <path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" />
        </svg>
      );
    case 'call_reminder':
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" />
        </svg>
      );
    case 'sms':
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM9 11H7V9h2v2zm4 0h-2V9h2v2zm4 0h-2V9h2v2z" />
        </svg>
      );
    default:
      return (
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
        </svg>
      );
  }
}

function getMetricClass(value: number, thresholds: { good: number; warning: number }): string {
  if (value >= thresholds.good) return 'step-performance__value--success';
  if (value >= thresholds.warning) return 'step-performance__value--warning';
  return 'step-performance__value--danger';
}

// ============================================
// Component
// ============================================

export function StepPerformanceTable({
  sequenceId,
  securityContext,
  dateRange,
}: StepPerformanceTableProps) {
  const [stepMetrics, setStepMetrics] = useState<StepMetrics[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sortField, setSortField] = useState<SortField>('stepIndex');
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc');

  useEffect(() => {
    const loadMetrics = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const metrics = await analyticsService.calculateAllStepMetrics(
          securityContext,
          sequenceId,
          dateRange
        );
        setStepMetrics(metrics);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load step metrics');
      } finally {
        setIsLoading(false);
      }
    };

    loadMetrics();
  }, [securityContext, sequenceId, dateRange]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  const sortedMetrics = useMemo(() => {
    return [...stepMetrics].sort((a, b) => {
      const aValue = a[sortField];
      const bValue = b[sortField];
      const direction = sortDirection === 'asc' ? 1 : -1;
      return (aValue - bValue) * direction;
    });
  }, [stepMetrics, sortField, sortDirection]);

  const getSortIndicator = (field: SortField) => {
    if (sortField !== field) return null;
    return sortDirection === 'asc' ? ' ↑' : ' ↓';
  };

  // Find best/worst performers for highlighting
  const bestOpenRate = Math.max(...stepMetrics.filter((s) => s.stepType === 'email').map((s) => s.openRate));
  const worstOpenRate = Math.min(
    ...stepMetrics.filter((s) => s.stepType === 'email' && s.openRate > 0).map((s) => s.openRate)
  );
  const bestReplyRate = Math.max(...stepMetrics.filter((s) => s.stepType === 'email').map((s) => s.replyRate));

  if (isLoading) {
    return (
      <div className="step-performance">
        <div className="step-performance__loading">
          <div className="step-performance__spinner" />
          <p>Loading step metrics...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="step-performance">
        <div className="step-performance__error">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  if (stepMetrics.length === 0) {
    return (
      <div className="step-performance">
        <div className="step-performance__empty">
          <p>No step data available for this period</p>
        </div>
      </div>
    );
  }

  return (
    <div className="step-performance">
      <div className="step-performance__header">
        <h2>Step Performance</h2>
        <p className="step-performance__subtitle">
          Click column headers to sort. Green = best performer, red = needs improvement.
        </p>
      </div>

      <div className="step-performance__table-container">
        <table className="step-performance__table">
          <thead>
            <tr>
              <th
                className="step-performance__th step-performance__th--sortable"
                onClick={() => handleSort('stepIndex')}
              >
                Step{getSortIndicator('stepIndex')}
              </th>
              <th className="step-performance__th">Type</th>
              <th className="step-performance__th">Name</th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('executed')}
              >
                Executed{getSortIndicator('executed')}
              </th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('successRate')}
              >
                Success{getSortIndicator('successRate')}
              </th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('openRate')}
              >
                Open Rate{getSortIndicator('openRate')}
              </th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('clickRate')}
              >
                Click Rate{getSortIndicator('clickRate')}
              </th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('replyRate')}
              >
                Reply Rate{getSortIndicator('replyRate')}
              </th>
              <th
                className="step-performance__th step-performance__th--sortable step-performance__th--number"
                onClick={() => handleSort('dropoutRate')}
              >
                Dropout{getSortIndicator('dropoutRate')}
              </th>
              <th className="step-performance__th step-performance__th--number">Avg Delay</th>
            </tr>
          </thead>
          <tbody>
            {sortedMetrics.map((step) => {
              const isEmailStep = step.stepType === 'email';
              const isBestOpen = isEmailStep && step.openRate === bestOpenRate && bestOpenRate > 0;
              const isWorstOpen = isEmailStep && step.openRate === worstOpenRate && step.openRate > 0;
              const isBestReply = isEmailStep && step.replyRate === bestReplyRate && bestReplyRate > 0;

              return (
                <tr
                  key={step.stepId}
                  className={`step-performance__row ${
                    isBestReply ? 'step-performance__row--best' : ''
                  }`}
                >
                  <td className="step-performance__cell step-performance__cell--index">
                    {step.stepIndex + 1}
                  </td>
                  <td className="step-performance__cell step-performance__cell--type">
                    <span className={`step-performance__type-icon step-performance__type-icon--${step.stepType}`}>
                      {getStepTypeIcon(step.stepType)}
                    </span>
                    {step.stepType}
                  </td>
                  <td className="step-performance__cell step-performance__cell--name" title={step.stepName}>
                    {step.stepName}
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    {step.executed}
                    {step.failed > 0 && (
                      <span className="step-performance__failed" title={`${step.failed} failed`}>
                        ({step.failed} failed)
                      </span>
                    )}
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    <span className={getMetricClass(step.successRate, { good: 90, warning: 70 })}>
                      {formatPercent(step.successRate)}
                    </span>
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    {isEmailStep ? (
                      <span
                        className={`${getMetricClass(step.openRate, { good: 30, warning: 15 })} ${
                          isBestOpen ? 'step-performance__value--highlight' : ''
                        } ${isWorstOpen ? 'step-performance__value--lowlight' : ''}`}
                      >
                        {formatPercent(step.openRate)}
                      </span>
                    ) : (
                      <span className="step-performance__na">—</span>
                    )}
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    {isEmailStep ? (
                      <span className={getMetricClass(step.clickRate, { good: 5, warning: 2 })}>
                        {formatPercent(step.clickRate)}
                      </span>
                    ) : (
                      <span className="step-performance__na">—</span>
                    )}
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    {isEmailStep ? (
                      <span
                        className={`${getMetricClass(step.replyRate, { good: 10, warning: 5 })} ${
                          isBestReply ? 'step-performance__value--highlight' : ''
                        }`}
                      >
                        {formatPercent(step.replyRate)}
                      </span>
                    ) : (
                      <span className="step-performance__na">—</span>
                    )}
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    <span
                      className={
                        step.dropoutRate > 20
                          ? 'step-performance__value--danger'
                          : step.dropoutRate > 10
                          ? 'step-performance__value--warning'
                          : ''
                      }
                    >
                      {formatPercent(step.dropoutRate)}
                    </span>
                  </td>
                  <td className="step-performance__cell step-performance__cell--number">
                    {step.avgExecutionDelay < 60
                      ? `${Math.round(step.avgExecutionDelay)}m`
                      : `${(step.avgExecutionDelay / 60).toFixed(1)}h`}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Legend */}
      <div className="step-performance__legend">
        <span className="step-performance__legend-item">
          <span className="step-performance__legend-color step-performance__legend-color--success" />
          Good performance
        </span>
        <span className="step-performance__legend-item">
          <span className="step-performance__legend-color step-performance__legend-color--warning" />
          Needs attention
        </span>
        <span className="step-performance__legend-item">
          <span className="step-performance__legend-color step-performance__legend-color--danger" />
          Needs improvement
        </span>
      </div>

      {/* Summary Stats */}
      <div className="step-performance__summary">
        <div className="step-performance__summary-item">
          <span className="step-performance__summary-label">Total Steps</span>
          <span className="step-performance__summary-value">{stepMetrics.length}</span>
        </div>
        <div className="step-performance__summary-item">
          <span className="step-performance__summary-label">Email Steps</span>
          <span className="step-performance__summary-value">
            {stepMetrics.filter((s) => s.stepType === 'email').length}
          </span>
        </div>
        <div className="step-performance__summary-item">
          <span className="step-performance__summary-label">Avg Open Rate</span>
          <span className="step-performance__summary-value">
            {formatPercent(
              stepMetrics.filter((s) => s.stepType === 'email').length > 0
                ? stepMetrics
                    .filter((s) => s.stepType === 'email')
                    .reduce((sum, s) => sum + s.openRate, 0) /
                    stepMetrics.filter((s) => s.stepType === 'email').length
                : 0
            )}
          </span>
        </div>
        <div className="step-performance__summary-item">
          <span className="step-performance__summary-label">Avg Reply Rate</span>
          <span className="step-performance__summary-value">
            {formatPercent(
              stepMetrics.filter((s) => s.stepType === 'email').length > 0
                ? stepMetrics
                    .filter((s) => s.stepType === 'email')
                    .reduce((sum, s) => sum + s.replyRate, 0) /
                    stepMetrics.filter((s) => s.stepType === 'email').length
                : 0
            )}
          </span>
        </div>
      </div>
    </div>
  );
}

export default StepPerformanceTable;
