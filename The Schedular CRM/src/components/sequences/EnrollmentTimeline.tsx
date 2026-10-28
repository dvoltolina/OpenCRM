/**
 * EnrollmentTimeline Component
 * Visual timeline showing step progress for an enrollment
 *
 * Phase 3 Implementation
 */

import type { ReactNode } from 'react';
import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '../../context/AuthContext';
import { getSequenceExecutionRepository } from '../../data/repositories/sequence-execution-repository';
import { createSecurityContext } from '../../hooks/usePipeline';
import type {
  SequenceEnrollment,
  SequenceExecution,
  SequenceStepType,
  ExecutionStatus,
} from '../../types/sequences';

// ============================================
// Types
// ============================================

export interface EnrollmentTimelineProps {
  /** Enrollment to show timeline for */
  enrollment: SequenceEnrollment;
  /** Whether to show expanded details by default */
  expandedByDefault?: boolean;
}

interface TimelineEvent {
  id: string;
  type: 'enrollment' | 'step' | 'pause' | 'resume' | 'exit' | 'complete';
  timestamp: Date;
  title: string;
  description?: string;
  status?: ExecutionStatus;
  stepType?: SequenceStepType;
  stepIndex?: number;
  metadata?: Record<string, unknown>;
}

// ============================================
// Component
// ============================================

export function EnrollmentTimeline({
  enrollment,
  expandedByDefault = false,
}: EnrollmentTimelineProps) {
  const { crmUser, businessId } = useAuth();
  const [executions, setExecutions] = useState<SequenceExecution[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  // Fetch executions
  useEffect(() => {
    async function fetchExecutions() {
      if (!businessId || !crmUser) {
        setIsLoading(false);
        return;
      }

      try {
        const context = createSecurityContext(
          businessId,
          crmUser.id,
          crmUser.displayName,
          crmUser.role
        );

        const repo = getSequenceExecutionRepository();
        const result = await repo.getByEnrollment(context, enrollment.id);

        if (result.success) {
          setExecutions(result.data);
        }
      } catch {
        // Error handled silently
      } finally {
        setIsLoading(false);
      }
    }

    fetchExecutions();
  }, [businessId, crmUser, enrollment.id]);

  // Build timeline events
  const events = useMemo((): TimelineEvent[] => {
    const timelineEvents: TimelineEvent[] = [];

    // Enrollment event
    timelineEvents.push({
      id: 'enrollment',
      type: 'enrollment',
      timestamp: enrollment.createdAt,
      title: 'Enrolled in sequence',
      description: `Added to ${enrollment.sequenceName} by ${enrollment.enrolledByName}`,
    });

    // Step executions
    executions.forEach((execution) => {
      timelineEvents.push({
        id: execution.id,
        type: 'step',
        timestamp: execution.executedAt || execution.scheduledAt,
        title: getStepTitle(execution.stepType, execution.stepIndex),
        description: getStepDescription(execution),
        status: execution.status,
        stepType: execution.stepType,
        stepIndex: execution.stepIndex,
        metadata: {
          emailMetrics: execution.emailMetrics,
          result: execution.result,
        },
      });
    });

    // Exit/complete event
    if (enrollment.exitedAt) {
      timelineEvents.push({
        id: 'exit',
        type: 'exit',
        timestamp: enrollment.exitedAt,
        title: 'Exited sequence',
        description: enrollment.exitReason
          ? `Reason: ${formatExitReason(enrollment.exitReason)}`
          : undefined,
      });
    } else if (enrollment.completedAt) {
      timelineEvents.push({
        id: 'complete',
        type: 'complete',
        timestamp: enrollment.completedAt,
        title: 'Completed sequence',
        description: `Finished all ${enrollment.totalSteps} steps`,
      });
    }

    // Sort by timestamp descending (most recent first)
    return timelineEvents.sort(
      (a, b) => b.timestamp.getTime() - a.timestamp.getTime()
    );
  }, [enrollment, executions]);

  // Toggle expanded
  const handleToggle = (id: string) => {
    setExpandedId(expandedId === id ? null : id);
  };

  if (isLoading) {
    return (
      <div className="enrollment-timeline enrollment-timeline--loading">
        <div className="enrollment-timeline__spinner" />
        <span>Loading timeline...</span>
      </div>
    );
  }

  return (
    <div className="enrollment-timeline" data-testid="enrollment-timeline">
      {events.length === 0 ? (
        <div className="enrollment-timeline__empty">No activity yet</div>
      ) : (
        <div className="enrollment-timeline__list">
          {events.map((event, index) => (
            <TimelineEventItem
              key={event.id}
              event={event}
              isExpanded={expandedByDefault || expandedId === event.id}
              isFirst={index === 0}
              isLast={index === events.length - 1}
              onToggle={() => handleToggle(event.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface TimelineEventItemProps {
  event: TimelineEvent;
  isExpanded: boolean;
  isFirst: boolean;
  isLast: boolean;
  onToggle: () => void;
}

function TimelineEventItem({
  event,
  isExpanded,
  isFirst,
  isLast,
  onToggle,
}: TimelineEventItemProps) {
  const icon = getEventIcon(event);
  const statusClass = getStatusClass(event);

  return (
    <div
      className={`enrollment-timeline__item ${statusClass} ${isFirst ? 'enrollment-timeline__item--first' : ''} ${isLast ? 'enrollment-timeline__item--last' : ''}`}
      data-testid={`timeline-event-${event.id}`}
    >
      <div className="enrollment-timeline__line" />
      <div className={`enrollment-timeline__icon ${statusClass}`}>{icon}</div>
      <div className="enrollment-timeline__content">
        <button
          type="button"
          className="enrollment-timeline__header"
          onClick={onToggle}
          aria-expanded={isExpanded}
        >
          <span className="enrollment-timeline__title">{event.title}</span>
          <span className="enrollment-timeline__time">
            {formatTime(event.timestamp)}
          </span>
        </button>
        {event.description && (
          <p className="enrollment-timeline__description">{event.description}</p>
        )}
        {isExpanded && event.metadata && (
          <TimelineEventDetails event={event} />
        )}
      </div>
    </div>
  );
}

interface TimelineEventDetailsProps {
  event: TimelineEvent;
}

function TimelineEventDetails({ event }: TimelineEventDetailsProps) {
  const emailMetrics = event.metadata?.emailMetrics as
    | { opened?: boolean; clicked?: boolean; replied?: boolean; bounced?: boolean }
    | undefined;
  const result = event.metadata?.result as
    | { success?: boolean; errorMessage?: string }
    | undefined;

  if (!emailMetrics && !result) {
    return null;
  }

  return (
    <div className="enrollment-timeline__details">
      {emailMetrics && (
        <div className="enrollment-timeline__metrics">
          <MetricItem label="Opened" value={emailMetrics.opened} />
          <MetricItem label="Clicked" value={emailMetrics.clicked} />
          <MetricItem label="Replied" value={emailMetrics.replied} />
          <MetricItem label="Bounced" value={emailMetrics.bounced} isNegative />
        </div>
      )}
      {result && !result.success && result.errorMessage && (
        <div className="enrollment-timeline__error">
          <strong>Error:</strong> {result.errorMessage}
        </div>
      )}
    </div>
  );
}

interface MetricItemProps {
  label: string;
  value?: boolean;
  isNegative?: boolean;
}

function MetricItem({ label, value, isNegative }: MetricItemProps) {
  if (value === undefined) return null;

  const iconClass = value
    ? isNegative
      ? 'enrollment-timeline__metric--negative'
      : 'enrollment-timeline__metric--positive'
    : 'enrollment-timeline__metric--neutral';

  return (
    <span className={`enrollment-timeline__metric ${iconClass}`}>
      {value ? (isNegative ? '✗' : '✓') : '—'} {label}
    </span>
  );
}

// ============================================
// Helpers
// ============================================

function getEventIcon(event: TimelineEvent): ReactNode {
  switch (event.type) {
    case 'enrollment':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
          <circle cx="8.5" cy="7" r="4" />
          <line x1="20" y1="8" x2="20" y2="14" />
          <line x1="23" y1="11" x2="17" y2="11" />
        </svg>
      );
    case 'step':
      return getStepIcon(event.stepType);
    case 'pause':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="6" y="4" width="4" height="16" />
          <rect x="14" y="4" width="4" height="16" />
        </svg>
      );
    case 'resume':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polygon points="5 3 19 12 5 21 5 3" />
        </svg>
      );
    case 'exit':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
          <polyline points="16 17 21 12 16 7" />
          <line x1="21" y1="12" x2="9" y2="12" />
        </svg>
      );
    case 'complete':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
          <polyline points="22 4 12 14.01 9 11.01" />
        </svg>
      );
    default:
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
        </svg>
      );
  }
}

function getStepIcon(stepType?: SequenceStepType): ReactNode {
  switch (stepType) {
    case 'email':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
          <polyline points="22,6 12,13 2,6" />
        </svg>
      );
    case 'task':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M9 11l3 3L22 4" />
          <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
        </svg>
      );
    case 'wait':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <polyline points="12 6 12 12 16 14" />
        </svg>
      );
    case 'call_reminder':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
        </svg>
      );
    case 'sms':
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      );
    default:
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
        </svg>
      );
  }
}

function getStatusClass(event: TimelineEvent): string {
  if (event.type === 'complete') return 'enrollment-timeline__item--completed';
  if (event.type === 'exit') return 'enrollment-timeline__item--exited';
  if (event.type === 'enrollment') return 'enrollment-timeline__item--enrolled';

  if (event.status) {
    switch (event.status) {
      case 'completed':
        return 'enrollment-timeline__item--completed';
      case 'failed':
        return 'enrollment-timeline__item--failed';
      case 'skipped':
        return 'enrollment-timeline__item--skipped';
      case 'executing':
      case 'scheduled':
        return 'enrollment-timeline__item--pending';
      default:
        return '';
    }
  }

  return '';
}

function getStepTitle(stepType: SequenceStepType, stepIndex: number): string {
  const typeLabels: Record<SequenceStepType, string> = {
    email: 'Email sent',
    task: 'Task created',
    wait: 'Wait period',
    call_reminder: 'Call reminder',
    sms: 'SMS sent',
  };
  return `Step ${stepIndex + 1}: ${typeLabels[stepType] || stepType}`;
}

function getStepDescription(execution: SequenceExecution): string {
  switch (execution.status) {
    case 'completed':
      return 'Successfully completed';
    case 'failed':
      return `Failed: ${execution.result?.errorMessage || 'Unknown error'}`;
    case 'skipped':
      return 'Skipped';
    case 'scheduled':
      return `Scheduled for ${formatTime(execution.scheduledAt)}`;
    case 'executing':
      return 'In progress...';
    default:
      return '';
  }
}

function formatTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}

function formatExitReason(reason: string): string {
  const labels: Record<string, string> = {
    manual: 'Manually removed',
    replied: 'Contact replied',
    unsubscribed: 'Unsubscribed',
    bounced: 'Email bounced',
    meeting_booked: 'Meeting booked',
    deal_won: 'Deal won',
    deal_lost: 'Deal lost',
    converted: 'Lead converted',
  };
  return labels[reason] || reason;
}

export default EnrollmentTimeline;
