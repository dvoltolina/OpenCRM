/**
 * GoalCard Component
 * Displays a goal with progress bar and action buttons
 */

import type { Goal, GoalMetric } from '../../types/goals';
import { formatCurrency } from '../../hooks/useForecasting';

// ============================================
// Types
// ============================================

export interface GoalCardProps {
  goal: Goal;
  onEdit?: (goal: Goal) => void;
  onCancel?: (goal: Goal) => void;
  onRecalculate?: (goal: Goal) => void;
  showActions?: boolean;
}

// ============================================
// Sub-components
// ============================================

function ProgressBar({ percent }: { percent: number }) {
  const clampedPercent = Math.min(100, Math.max(0, percent));
  const colorClass =
    clampedPercent >= 100
      ? 'goal-card__progress-fill--success'
      : clampedPercent >= 75
        ? 'goal-card__progress-fill--on-track'
        : clampedPercent >= 50
          ? 'goal-card__progress-fill--warning'
          : 'goal-card__progress-fill--danger';

  return (
    <div className="goal-card__progress-bar" data-testid="goal-progress-bar">
      <div
        className={`goal-card__progress-fill ${colorClass}`}
        style={{ width: `${clampedPercent}%` }}
      />
      <span className="goal-card__progress-text">{clampedPercent}%</span>
    </div>
  );
}

// ============================================
// Constants
// ============================================

const METRIC_LABELS: Record<GoalMetric, string> = {
  revenue: 'Revenue',
  deals_won: 'Opportunities Won',
  deals_created: 'Opportunities Created',
  activities_completed: 'Activities',
  calls_made: 'Calls',
  emails_sent: 'Emails',
};

const STATUS_COLORS: Record<string, string> = {
  active: 'goal-card__status--active',
  achieved: 'goal-card__status--success',
  missed: 'goal-card__status--danger',
  cancelled: 'goal-card__status--muted',
};

// ============================================
// Helper Functions
// ============================================

function formatValue(value: number, metric: GoalMetric): string {
  if (metric === 'revenue') {
    return formatCurrency(value);
  }
  return value.toLocaleString();
}

function formatDateRange(startDate: Date, endDate: Date): string {
  const start = new Date(startDate);
  const end = new Date(endDate);
  return `${start.toLocaleDateString()} - ${end.toLocaleDateString()}`;
}

// ============================================
// Main Component
// ============================================

export function GoalCard({
  goal,
  onEdit,
  onCancel,
  onRecalculate,
  showActions = true,
}: GoalCardProps) {
  const statusColor = STATUS_COLORS[goal.status] || 'goal-card__status--muted';

  return (
    <div className="goal-card" data-testid={`goal-card-${goal.id}`}>
      <div className="goal-card__header">
        <div className="goal-card__info">
          <h3 className="goal-card__title">{METRIC_LABELS[goal.metric]}</h3>
          <span className="goal-card__assignee">{goal.assigneeName}</span>
        </div>
        <span className={`goal-card__status ${statusColor}`}>{goal.status}</span>
      </div>

      <div className="goal-card__values">
        <div className="goal-card__current">
          <span className="goal-card__current-value">
            {formatValue(goal.currentValue, goal.metric)}
          </span>
          <span className="goal-card__target">
            / {formatValue(goal.targetValue, goal.metric)}
          </span>
        </div>
      </div>

      <ProgressBar percent={goal.progressPercent} />

      <div className="goal-card__meta">
        <span className="goal-card__period">{goal.period}</span>
        <span className="goal-card__dates">
          {formatDateRange(goal.startDate, goal.endDate)}
        </span>
      </div>

      {showActions && goal.status === 'active' && (
        <div className="goal-card__actions">
          {onRecalculate && (
            <button
              className="goal-card__action-btn"
              onClick={() => onRecalculate(goal)}
              title="Recalculate Progress"
            >
              Refresh
            </button>
          )}
          {onEdit && (
            <button
              className="goal-card__action-btn"
              onClick={() => onEdit(goal)}
              title="Edit Goal"
            >
              Edit
            </button>
          )}
          {onCancel && (
            <button
              className="goal-card__action-btn goal-card__action-btn--danger"
              onClick={() => onCancel(goal)}
              title="Cancel Goal"
            >
              Cancel
            </button>
          )}
        </div>
      )}
    </div>
  );
}

export default GoalCard;
