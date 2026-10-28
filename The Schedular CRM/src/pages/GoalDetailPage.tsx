import { useCallback, useEffect, useMemo, useState } from 'react';
import type { FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Button, Card, EmptyState, PageHeader, PageLayout } from '../components/ui';
import { useGoal, useGoalMutations } from '../hooks/useGoals';
import type { Goal, GoalAssigneeType, GoalMetric, GoalPeriod, GoalStatus } from '../types/goals';
import './styles/goals.css';

function getGoalMetricLabel(metric: GoalMetric) {
  switch (metric) {
    case 'revenue':
      return 'Revenue';
    case 'deals_won':
      return 'Deals Won';
    case 'deals_created':
      return 'Deals Created';
    case 'activities_completed':
      return 'Activities Completed';
    case 'calls_made':
      return 'Calls Made';
    case 'emails_sent':
      return 'Emails Sent';
    default:
      return metric;
  }
}

function getPeriodRange(period: GoalPeriod) {
  const now = new Date();
  const startDate = new Date(now);
  const endDate = new Date(now);

  switch (period) {
    case 'weekly':
      startDate.setDate(startDate.getDate() - startDate.getDay());
      endDate.setDate(startDate.getDate() + 6);
      break;
    case 'monthly':
      startDate.setDate(1);
      endDate.setMonth(endDate.getMonth() + 1);
      endDate.setDate(0);
      break;
    case 'quarterly': {
      const quarter = Math.floor(startDate.getMonth() / 3);
      startDate.setMonth(quarter * 3);
      startDate.setDate(1);
      endDate.setMonth(quarter * 3 + 3);
      endDate.setDate(0);
      break;
    }
    case 'yearly':
      startDate.setMonth(0);
      startDate.setDate(1);
      endDate.setMonth(11);
      endDate.setDate(31);
      break;
  }

  return { startDate, endDate };
}

function formatGoalValue(metric: GoalMetric, value: number) {
  if (metric === 'revenue') {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value / 100);
  }

  return value.toLocaleString();
}

function formatGoalDate(date: Date) {
  return date.toLocaleDateString();
}

function GoalEditModal({
  goal,
  isOpen,
  isSaving,
  onClose,
  onSave,
}: {
  goal: Goal;
  isOpen: boolean;
  isSaving: boolean;
  onClose: () => void;
  onSave: (updates: {
    metric: GoalMetric;
    targetValue: number;
    period: GoalPeriod;
    assigneeType: GoalAssigneeType;
    status: GoalStatus;
  }) => Promise<void>;
}) {
  const [metric, setMetric] = useState<GoalMetric>(goal.metric);
  const [targetValue, setTargetValue] = useState(
    goal.metric === 'revenue' ? String(goal.targetValue / 100) : String(goal.targetValue)
  );
  const [period, setPeriod] = useState<GoalPeriod>(goal.period);
  const [assigneeType, setAssigneeType] = useState<GoalAssigneeType>(goal.assigneeType);
  const [status, setStatus] = useState<GoalStatus>(goal.status);

  useEffect(() => {
    setMetric(goal.metric);
    setTargetValue(goal.metric === 'revenue' ? String(goal.targetValue / 100) : String(goal.targetValue));
    setPeriod(goal.period);
    setAssigneeType(goal.assigneeType);
    setStatus(goal.status);
  }, [goal]);

  if (!isOpen) return null;

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();

    const parsedValue = metric === 'revenue'
      ? Math.round(Number.parseFloat(targetValue || '0') * 100)
      : Number.parseInt(targetValue || '0', 10);

    await onSave({
      metric,
      targetValue: Number.isFinite(parsedValue) ? parsedValue : goal.targetValue,
      period,
      assigneeType,
      status,
    });
  };

  return (
    <div className="goals-page__modal-overlay" onClick={onClose}>
      <div className="goals-page__modal" onClick={(event) => event.stopPropagation()}>
        <h2 className="goals-page__modal-title">Edit Goal</h2>
        <form onSubmit={handleSubmit}>
          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Metric</label>
            <select
              className="goals-page__form-select"
              value={metric}
              onChange={(event) => setMetric(event.target.value as GoalMetric)}
            >
              <option value="revenue">Revenue</option>
              <option value="deals_won">Deals Won</option>
              <option value="deals_created">Deals Created</option>
              <option value="activities_completed">Activities Completed</option>
              <option value="calls_made">Calls Made</option>
              <option value="emails_sent">Emails Sent</option>
            </select>
          </div>

          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Target</label>
            <input
              type="number"
              className="goals-page__form-input"
              value={targetValue}
              onChange={(event) => setTargetValue(event.target.value)}
              min="1"
              required
            />
          </div>

          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Period</label>
            <select
              className="goals-page__form-select"
              value={period}
              onChange={(event) => setPeriod(event.target.value as GoalPeriod)}
            >
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
              <option value="quarterly">Quarterly</option>
              <option value="yearly">Yearly</option>
            </select>
          </div>

          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Assign To</label>
            <select
              className="goals-page__form-select"
              value={assigneeType}
              onChange={(event) => setAssigneeType(event.target.value as GoalAssigneeType)}
            >
              <option value="user">User</option>
              <option value="team">Team</option>
              <option value="business">Business</option>
            </select>
          </div>

          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Status</label>
            <select
              className="goals-page__form-select"
              value={status}
              onChange={(event) => setStatus(event.target.value as GoalStatus)}
            >
              <option value="active">Active</option>
              <option value="achieved">Achieved</option>
              <option value="missed">Missed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>

          <div className="goals-page__modal-actions">
            <Button
              type="button"
              variant="secondary"
              onClick={onClose}
              disabled={isSaving}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSaving}>
              {isSaving ? 'Saving...' : 'Save Goal'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function GoalDetailPage() {
  const { goalId } = useParams<{ goalId: string }>();
  const navigate = useNavigate();
  const { goal, isLoading, error, refresh } = useGoal(goalId);
  const { updateGoal, cancelGoal, recalculateProgress, isMutating } = useGoalMutations();
  const [showEditModal, setShowEditModal] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const progressStatus = useMemo(() => {
    if (!goal) return '';
    if (goal.progressPercent >= 100) return 'On or above target';
    if (goal.progressPercent >= 75) return 'Tracking well';
    if (goal.progressPercent >= 50) return 'Needs attention';
    return 'At risk';
  }, [goal]);

  const handleSave = useCallback(
    async (updates: {
      metric: GoalMetric;
      targetValue: number;
      period: GoalPeriod;
      assigneeType: GoalAssigneeType;
      status: GoalStatus;
    }) => {
      if (!goal) return;

      setActionError(null);

      try {
        const { startDate, endDate } = getPeriodRange(updates.period);
        await updateGoal(goal.id, {
          metric: updates.metric,
          targetValue: updates.targetValue,
          period: updates.period,
          assigneeType: updates.assigneeType,
          status: updates.status,
          startDate,
          endDate,
        });
        setShowEditModal(false);
        refresh();
      } catch (err) {
        setActionError(err instanceof Error ? err.message : 'Failed to update goal');
      }
    },
    [goal, refresh, updateGoal]
  );

  const handleCancelGoal = useCallback(async () => {
    if (!goal || !window.confirm('Are you sure you want to cancel this goal?')) return;

    setActionError(null);

    try {
      await cancelGoal(goal.id);
      refresh();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to cancel goal');
    }
  }, [cancelGoal, goal, refresh]);

  const handleRecalculate = useCallback(async () => {
    if (!goal) return;

    setActionError(null);

    try {
      await recalculateProgress(goal.id);
      refresh();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to recalculate goal');
    }
  }, [goal, recalculateProgress, refresh]);

  if (!goalId) {
    return (
      <PageLayout width="wide" className="goals-page goal-detail-page">
        <PageHeader
          eyebrow="Goals"
          title="Goal details"
          subtitle="Review and manage an individual goal target."
        />
        <Card padding="lg">
          <EmptyState
            title="Goal not found"
            description="The requested goal route is incomplete or does not point to an available record."
          />
        </Card>
      </PageLayout>
    );
  }

  if (isLoading) {
    return (
      <PageLayout width="wide" className="goals-page goal-detail-page">
        <PageHeader
          eyebrow="Goals"
          title="Goal details"
          subtitle="Review and manage an individual goal target."
        />
        <Card padding="lg">
          <p className="goals-page__loading">Loading goal...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error || !goal) {
    return (
      <PageLayout width="wide" className="goals-page goal-detail-page">
        <PageHeader
          eyebrow="Goals"
          title="Goal details"
          subtitle="Review and manage an individual goal target."
        />
        <Card padding="lg">
          <EmptyState
            tone="danger"
            title="Goal unavailable"
            description={error?.message || 'Goal not found.'}
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="goals-page goal-detail-page" data-testid="goal-detail-page">
      <PageHeader
        eyebrow="Goals"
        title={getGoalMetricLabel(goal.metric)}
        subtitle={`${goal.assigneeName} · ${goal.period} · ${goal.status}`}
        actions={(
          <div className="goal-detail-page__header-actions">
            <Button variant="secondary" onClick={() => navigate('/goals')}>
              Back to Goals
            </Button>
            <Button variant="ghost" onClick={handleRecalculate} disabled={isMutating}>
              Recalculate
            </Button>
            <Button onClick={() => setShowEditModal(true)} disabled={isMutating}>
              Edit Goal
            </Button>
          </div>
        )}
      />

      <Card tone="accent" className="goal-detail-page__hero">
        <div className="goal-detail-page__hero-copy">
          <h2>{progressStatus}</h2>
          <p>
            Track this target against its current pace, adjust the definition when plans change,
            and recalculate progress without leaving the detail surface.
          </p>
        </div>
        <div className="goal-detail-page__hero-stats" aria-label="Goal detail summary">
          <div>
            <span>Current</span>
            <strong>{formatGoalValue(goal.metric, goal.currentValue)}</strong>
          </div>
          <div>
            <span>Target</span>
            <strong>{formatGoalValue(goal.metric, goal.targetValue)}</strong>
          </div>
          <div>
            <span>Progress</span>
            <strong>{Math.round(goal.progressPercent)}%</strong>
          </div>
        </div>
      </Card>

      <div className="goals-page__stats-grid">
        <div className="goals-page__stat-card">
          <div className="goals-page__stat-value">{formatGoalValue(goal.metric, goal.currentValue)}</div>
          <div className="goals-page__stat-label">Current</div>
        </div>
        <div className="goals-page__stat-card">
          <div className="goals-page__stat-value">{formatGoalValue(goal.metric, goal.targetValue)}</div>
          <div className="goals-page__stat-label">Target</div>
        </div>
        <div className="goals-page__stat-card">
          <div className="goals-page__stat-value">{Math.round(goal.progressPercent)}%</div>
          <div className="goals-page__stat-label">Progress</div>
        </div>
        <div className="goals-page__stat-card">
          <div className="goals-page__stat-value">{progressStatus}</div>
          <div className="goals-page__stat-label">Pace</div>
        </div>
      </div>

      <div className="goals-page__goals-grid">
        <div className="goals-page__goal-card">
          <div className="goals-page__goal-header">
            <div className="goals-page__goal-info">
              <h2 className="goals-page__goal-title">Goal Details</h2>
              <span className="goals-page__goal-assignee">{goal.assigneeName}</span>
            </div>
            <span className={`goals-page__status goals-page__status--${
              goal.status === 'achieved'
                ? 'success'
                : goal.status === 'missed'
                  ? 'danger'
                  : goal.status === 'cancelled'
                    ? 'muted'
                    : 'active'
            }`}
            >
              {goal.status}
            </span>
          </div>

          <div className="goals-page__goal-values">
            <div className="goals-page__goal-current">
              <span className="goals-page__goal-current-value">
                {formatGoalValue(goal.metric, goal.currentValue)}
              </span>
              <span className="goals-page__goal-target">
                / {formatGoalValue(goal.metric, goal.targetValue)}
              </span>
            </div>
          </div>

          <div className="goals-page__progress-bar" data-testid="goal-detail-progress">
            <div
              className={`goals-page__progress-fill ${
                goal.progressPercent >= 100
                  ? 'goals-page__progress-fill--success'
                  : goal.progressPercent >= 75
                    ? 'goals-page__progress-fill--on-track'
                    : goal.progressPercent >= 50
                      ? 'goals-page__progress-fill--warning'
                      : 'goals-page__progress-fill--danger'
              }`}
              style={{ width: `${Math.min(100, Math.max(0, goal.progressPercent))}%` }}
            />
            <span className="goals-page__progress-text">{Math.round(goal.progressPercent)}%</span>
          </div>

          <div className="goals-page__goal-meta">
            <span className="goals-page__goal-period">
              {formatGoalDate(goal.startDate)} - {formatGoalDate(goal.endDate)}
            </span>
            <span className="goals-page__goal-period">Assigned to {goal.assigneeType}</span>
          </div>

          <div className="goals-page__goal-meta">
            <span className="goals-page__goal-period">Created by {goal.createdByName}</span>
            <span className="goals-page__goal-period">
              Last calculated {formatGoalDate(goal.lastCalculatedAt)}
            </span>
          </div>

          <div className="goals-page__goal-actions">
            <button
              type="button"
              className="goals-page__action-btn"
              onClick={() => setShowEditModal(true)}
              disabled={isMutating}
            >
              Edit
            </button>
            <button
              type="button"
              className="goals-page__action-btn"
              onClick={handleRecalculate}
              disabled={isMutating}
            >
              Refresh
            </button>
            {goal.status !== 'cancelled' && (
              <button
                type="button"
                className="goals-page__action-btn goals-page__action-btn--danger"
                onClick={handleCancelGoal}
                disabled={isMutating}
              >
                Cancel Goal
              </button>
            )}
          </div>

          {actionError && (
            <div className="goals-page__error" role="alert">
              {actionError}
            </div>
          )}
        </div>
      </div>

      <GoalEditModal
        goal={goal}
        isOpen={showEditModal}
        isSaving={isMutating}
        onClose={() => setShowEditModal(false)}
        onSave={handleSave}
      />
    </PageLayout>
  );
}
