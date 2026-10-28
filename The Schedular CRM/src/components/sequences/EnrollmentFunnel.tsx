/**
 * EnrollmentFunnel Component
 * Visual funnel chart showing step-by-step progression of enrollments.
 * Width proportional to count, color indicates conversion vs dropout.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import {
  getSequenceAnalyticsService,
  type FunnelData,
  type DateRange,
} from '../../services/sequence-analytics-service';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface EnrollmentFunnelProps {
  sequenceId: string;
  securityContext: SecurityContext;
  dateRange?: DateRange;
  onStepClick?: (stepId: string) => void;
}

// ============================================
// Helper Functions
// ============================================

function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}

function getStepTypeLabel(stepType: string): string {
  switch (stepType) {
    case 'email':
      return 'Email';
    case 'task':
      return 'Task';
    case 'wait':
      return 'Wait';
    case 'call_reminder':
      return 'Call';
    case 'sms':
      return 'SMS';
    default:
      return stepType;
  }
}

// ============================================
// Component
// ============================================

export function EnrollmentFunnel({
  sequenceId,
  securityContext,
  dateRange,
  onStepClick,
}: EnrollmentFunnelProps) {
  const [funnelData, setFunnelData] = useState<FunnelData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hoveredStep, setHoveredStep] = useState<string | null>(null);

  useEffect(() => {
    const loadFunnel = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const data = await analyticsService.getEnrollmentFunnel(
          securityContext,
          sequenceId,
          dateRange
        );
        setFunnelData(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load funnel data');
      } finally {
        setIsLoading(false);
      }
    };

    loadFunnel();
  }, [securityContext, sequenceId, dateRange]);

  if (isLoading) {
    return (
      <div className="enrollment-funnel">
        <div className="enrollment-funnel__loading">
          <div className="enrollment-funnel__spinner" />
          <p>Loading funnel data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="enrollment-funnel">
        <div className="enrollment-funnel__error">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  if (!funnelData || funnelData.steps.length === 0) {
    return (
      <div className="enrollment-funnel">
        <div className="enrollment-funnel__empty">
          <svg viewBox="0 0 24 24" width="48" height="48" fill="currentColor">
            <path d="M22 5v14H3V5h19m0-2H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h19c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14l-6-5.27L5 17v-2.5l6-5.27 6 5.27V17z" />
          </svg>
          <p>No enrollment data available for this period</p>
          <p className="enrollment-funnel__empty-hint">
            Enrollments will appear here once contacts start progressing through the sequence.
          </p>
        </div>
      </div>
    );
  }

  const maxEntered = Math.max(...funnelData.steps.map((s) => s.enteredCount), 1);

  return (
    <div className="enrollment-funnel">
      <div className="enrollment-funnel__header">
        <h2>Enrollment Funnel</h2>
        <div className="enrollment-funnel__overall">
          <span className="enrollment-funnel__overall-label">Overall Conversion</span>
          <span
            className={`enrollment-funnel__overall-value ${
              funnelData.overallConversionRate >= 50
                ? 'enrollment-funnel__overall-value--success'
                : funnelData.overallConversionRate >= 25
                ? 'enrollment-funnel__overall-value--warning'
                : 'enrollment-funnel__overall-value--danger'
            }`}
          >
            {formatPercent(funnelData.overallConversionRate)}
          </span>
        </div>
      </div>

      <div className="enrollment-funnel__chart">
        {funnelData.steps.map((step, index) => {
          const widthPercent = Math.max((step.enteredCount / maxEntered) * 100, 10);
          const isHovered = hoveredStep === step.stepId;
          const hasDropoff = step.exitedCount > 0;

          return (
            <div
              key={step.stepId}
              className={`enrollment-funnel__step ${isHovered ? 'enrollment-funnel__step--hovered' : ''}`}
              onMouseEnter={() => setHoveredStep(step.stepId)}
              onMouseLeave={() => setHoveredStep(null)}
              onClick={() => onStepClick?.(step.stepId)}
            >
              {/* Step bar */}
              <div
                className="enrollment-funnel__bar-container"
                style={{ '--funnel-width': `${widthPercent}%` } as React.CSSProperties}
              >
                <div className="enrollment-funnel__bar">
                  <div className="enrollment-funnel__bar-fill" />
                  {hasDropoff && (
                    <div
                      className="enrollment-funnel__bar-dropout"
                      style={{
                        width: `${(step.exitedCount / step.enteredCount) * 100}%`,
                      }}
                    />
                  )}
                </div>

                {/* Connector to next step */}
                {index < funnelData.steps.length - 1 && (
                  <div className="enrollment-funnel__connector">
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                      <path d="M7 10l5 5 5-5z" />
                    </svg>
                  </div>
                )}
              </div>

              {/* Step info */}
              <div className="enrollment-funnel__info">
                <div className="enrollment-funnel__step-header">
                  <span className="enrollment-funnel__step-number">{step.stepIndex + 1}</span>
                  <span className="enrollment-funnel__step-type">
                    {getStepTypeLabel(step.stepType)}
                  </span>
                </div>
                <span className="enrollment-funnel__step-name" title={step.stepName}>
                  {step.stepName}
                </span>
              </div>

              {/* Metrics */}
              <div className="enrollment-funnel__metrics">
                <div className="enrollment-funnel__metric">
                  <span className="enrollment-funnel__metric-value">{step.enteredCount}</span>
                  <span className="enrollment-funnel__metric-label">entered</span>
                </div>
                <div className="enrollment-funnel__metric">
                  <span className="enrollment-funnel__metric-value enrollment-funnel__metric-value--success">
                    {step.completedCount}
                  </span>
                  <span className="enrollment-funnel__metric-label">completed</span>
                </div>
                {step.exitedCount > 0 && (
                  <div className="enrollment-funnel__metric">
                    <span className="enrollment-funnel__metric-value enrollment-funnel__metric-value--danger">
                      {step.exitedCount}
                    </span>
                    <span className="enrollment-funnel__metric-label">dropped</span>
                  </div>
                )}
              </div>

              {/* Rates */}
              <div className="enrollment-funnel__rates">
                <span
                  className={`enrollment-funnel__rate enrollment-funnel__rate--conversion ${
                    step.conversionRate >= 80
                      ? 'enrollment-funnel__rate--good'
                      : step.conversionRate >= 50
                      ? 'enrollment-funnel__rate--ok'
                      : 'enrollment-funnel__rate--poor'
                  }`}
                >
                  {formatPercent(step.conversionRate)} converted
                </span>
                {step.dropoffRate > 0 && (
                  <span className="enrollment-funnel__rate enrollment-funnel__rate--dropout">
                    {formatPercent(step.dropoffRate)} dropped
                  </span>
                )}
              </div>

              {/* Tooltip */}
              {isHovered && (
                <div className="enrollment-funnel__tooltip">
                  <div className="enrollment-funnel__tooltip-header">
                    <strong>Step {step.stepIndex + 1}: {step.stepName}</strong>
                  </div>
                  <div className="enrollment-funnel__tooltip-content">
                    <div className="enrollment-funnel__tooltip-row">
                      <span>Entered:</span>
                      <span>{step.enteredCount}</span>
                    </div>
                    <div className="enrollment-funnel__tooltip-row">
                      <span>Completed:</span>
                      <span>{step.completedCount}</span>
                    </div>
                    <div className="enrollment-funnel__tooltip-row">
                      <span>Dropped:</span>
                      <span>{step.exitedCount}</span>
                    </div>
                    <div className="enrollment-funnel__tooltip-row enrollment-funnel__tooltip-row--highlight">
                      <span>Conversion Rate:</span>
                      <span>{formatPercent(step.conversionRate)}</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Summary */}
      <div className="enrollment-funnel__summary">
        <div className="enrollment-funnel__summary-item">
          <span className="enrollment-funnel__summary-value">
            {funnelData.steps[0]?.enteredCount || 0}
          </span>
          <span className="enrollment-funnel__summary-label">Started</span>
        </div>
        <div className="enrollment-funnel__summary-arrow">
          <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
            <path d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z" />
          </svg>
        </div>
        <div className="enrollment-funnel__summary-item">
          <span className="enrollment-funnel__summary-value enrollment-funnel__summary-value--success">
            {funnelData.steps[funnelData.steps.length - 1]?.completedCount || 0}
          </span>
          <span className="enrollment-funnel__summary-label">Completed</span>
        </div>
        <div className="enrollment-funnel__summary-item">
          <span className="enrollment-funnel__summary-value enrollment-funnel__summary-value--danger">
            {funnelData.steps.reduce((sum, s) => sum + s.exitedCount, 0)}
          </span>
          <span className="enrollment-funnel__summary-label">Total Dropped</span>
        </div>
      </div>

      {/* Legend */}
      <div className="enrollment-funnel__legend">
        <div className="enrollment-funnel__legend-item">
          <span className="enrollment-funnel__legend-color enrollment-funnel__legend-color--fill" />
          <span>Progressed to next step</span>
        </div>
        <div className="enrollment-funnel__legend-item">
          <span className="enrollment-funnel__legend-color enrollment-funnel__legend-color--dropout" />
          <span>Dropped at this step</span>
        </div>
      </div>

      {/* Insights */}
      <div className="enrollment-funnel__insights">
        <h3>Insights</h3>
        <ul className="enrollment-funnel__insights-list">
          {funnelData.steps
            .filter((s) => s.dropoffRate > 20)
            .map((step) => (
              <li key={step.stepId} className="enrollment-funnel__insight enrollment-funnel__insight--warning">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                  <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z" />
                </svg>
                Step {step.stepIndex + 1} "{step.stepName}" has a high dropout rate ({formatPercent(step.dropoffRate)})
              </li>
            ))}
          {funnelData.overallConversionRate >= 50 && (
            <li className="enrollment-funnel__insight enrollment-funnel__insight--success">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
              </svg>
              Great overall conversion rate! Above 50% of enrollees complete the sequence.
            </li>
          )}
          {funnelData.steps.length > 0 && funnelData.overallConversionRate < 30 && (
            <li className="enrollment-funnel__insight enrollment-funnel__insight--danger">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
              </svg>
              Low overall conversion rate. Consider reviewing and optimizing high-dropout steps.
            </li>
          )}
        </ul>
      </div>
    </div>
  );
}

export default EnrollmentFunnel;
