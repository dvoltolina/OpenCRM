/**
 * GoalsPage Component
 * Manage sales goals, quotas, and view forecasts
 *
 * Feature: Goals & Forecasting
 */

import { useState, useMemo, useCallback } from 'react';
import type { FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useGoals, useGoalMutations, useGoalDashboard } from '../hooks/useGoals';
import { useForecastSummary, formatCurrency } from '../hooks/useForecasting';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import { getFeatureFlags } from '../config/features';
import type { Goal, GoalStatus, GoalPeriod, GoalMetric, GoalAssigneeType } from '../types/goals';
import './styles/goals.css';

// ============================================
// Types
// ============================================

interface StatsCardProps {
  label: string;
  value: number | string;
  testId?: string;
  color?: 'default' | 'success' | 'warning' | 'danger';
}

interface GoalCardProps {
  goal: Goal;
  onEdit: (goal: Goal) => void;
  onCancel: (goal: Goal) => void;
  onRecalculate: (goal: Goal) => void;
}

// ============================================
// Sub-components
// ============================================

function StatsCard({ label, value, testId, color = 'default' }: StatsCardProps) {
  return (
    <div className={`goals-page__stat-card goals-page__stat-card--${color}`} data-testid={testId}>
      <div className="goals-page__stat-value">{value}</div>
      <div className="goals-page__stat-label">{label}</div>
    </div>
  );
}

function ProgressBar({ percent }: { percent: number }) {
  const clampedPercent = Math.min(100, Math.max(0, percent));
  const colorClass = clampedPercent >= 100
    ? 'goals-page__progress-fill--success'
    : clampedPercent >= 75
      ? 'goals-page__progress-fill--on-track'
      : clampedPercent >= 50
        ? 'goals-page__progress-fill--warning'
        : 'goals-page__progress-fill--danger';

  return (
    <div className="goals-page__progress-bar" data-testid="goal-progress-bar">
      <div
        className={`goals-page__progress-fill ${colorClass}`}
        style={{ width: `${clampedPercent}%` }}
      />
      <span className="goals-page__progress-text">{clampedPercent}%</span>
    </div>
  );
}

function GoalCard({ goal, onEdit, onCancel, onRecalculate }: GoalCardProps) {
  const statusColor = {
    active: 'goals-page__status--active',
    achieved: 'goals-page__status--success',
    missed: 'goals-page__status--danger',
    cancelled: 'goals-page__status--muted',
  }[goal.status];

  const metricLabels: Record<GoalMetric, string> = {
    revenue: 'Revenue',
    deals_won: 'Deals Won',
    deals_created: 'Deals Created',
    activities_completed: 'Activities',
    calls_made: 'Calls',
    emails_sent: 'Emails',
  };

  const formatValue = (value: number, metric: GoalMetric) => {
    if (metric === 'revenue') {
      return formatCurrency(value);
    }
    return value.toLocaleString();
  };

  return (
    <div className="goals-page__goal-card" data-testid={`goal-card-${goal.id}`}>
      <div className="goals-page__goal-header">
        <div className="goals-page__goal-info">
          <h3 className="goals-page__goal-title">{metricLabels[goal.metric]}</h3>
          <span className="goals-page__goal-assignee">{goal.assigneeName}</span>
        </div>
        <span className={`goals-page__status ${statusColor}`}>{goal.status}</span>
      </div>

      <div className="goals-page__goal-values">
        <div className="goals-page__goal-current">
          <span className="goals-page__goal-current-value">
            {formatValue(goal.currentValue, goal.metric)}
          </span>
          <span className="goals-page__goal-target">
            / {formatValue(goal.targetValue, goal.metric)}
          </span>
        </div>
      </div>

      <ProgressBar percent={goal.progressPercent} />

      <div className="goals-page__goal-meta">
        <span className="goals-page__goal-period">{goal.period}</span>
        <span className="goals-page__goal-dates">
          {new Date(goal.startDate).toLocaleDateString()} - {new Date(goal.endDate).toLocaleDateString()}
        </span>
      </div>

      {goal.status === 'active' && (
        <div className="goals-page__goal-actions">
          <button
            className="goals-page__action-btn"
            onClick={() => onRecalculate(goal)}
            title="Recalculate Progress"
          >
            Refresh
          </button>
          <button
            className="goals-page__action-btn"
            onClick={() => onEdit(goal)}
            title="Edit Goal"
          >
            Edit
          </button>
          <button
            className="goals-page__action-btn goals-page__action-btn--danger"
            onClick={() => onCancel(goal)}
            title="Cancel Goal"
          >
            Cancel
          </button>
        </div>
      )}
    </div>
  );
}

function ForecastWidget() {
  const [period, setPeriod] = useState<GoalPeriod>('monthly');
  const { summary, isLoading, error } = useForecastSummary({ period });

  if (isLoading) {
    return (
      <div className="goals-page__forecast-widget goals-page__forecast-widget--loading">
        Loading forecast...
      </div>
    );
  }

  if (error || !summary) {
    return (
      <div className="goals-page__forecast-widget goals-page__forecast-widget--error">
        Unable to load forecast data
      </div>
    );
  }

  const { forecast, commitmentRatio, confidenceLevel } = summary;

  const confidenceColors = {
    high: 'goals-page__confidence--high',
    medium: 'goals-page__confidence--medium',
    low: 'goals-page__confidence--low',
  };

  return (
    <div className="goals-page__forecast-widget" data-testid="forecast-widget">
      <div className="goals-page__forecast-header">
        <h3 className="goals-page__forecast-title">Revenue Forecast</h3>
        <select
          className="goals-page__period-select"
          value={period}
          onChange={(e) => setPeriod(e.target.value as GoalPeriod)}
        >
          <option value="weekly">Weekly</option>
          <option value="monthly">Monthly</option>
          <option value="quarterly">Quarterly</option>
          <option value="yearly">Yearly</option>
        </select>
      </div>

      <div className="goals-page__forecast-body">
        <div className="goals-page__forecast-metric">
          <span className="goals-page__forecast-label">Projected</span>
          <span className="goals-page__forecast-value">
            {formatCurrency(forecast.projectedRevenue)}
          </span>
        </div>

        <div className="goals-page__forecast-metric">
          <span className="goals-page__forecast-label">Committed</span>
          <span className="goals-page__forecast-value">
            {formatCurrency(forecast.committed)}
          </span>
        </div>

        <div className="goals-page__forecast-metric">
          <span className="goals-page__forecast-label">Closed</span>
          <span className="goals-page__forecast-value">
            {formatCurrency(forecast.closed)}
          </span>
        </div>

        <div className="goals-page__forecast-metric">
          <span className="goals-page__forecast-label">Best Case</span>
          <span className="goals-page__forecast-value">
            {formatCurrency(forecast.bestCase)}
          </span>
        </div>
      </div>

      <div className="goals-page__forecast-footer">
        <span className={`goals-page__confidence ${confidenceColors[confidenceLevel]}`}>
          {confidenceLevel.charAt(0).toUpperCase() + confidenceLevel.slice(1)} Confidence
        </span>
        <span className="goals-page__commitment-ratio">
          {Math.round(commitmentRatio)}% committed
        </span>
      </div>
    </div>
  );
}

function UpgradePrompt() {
  return (
    <Card className="goals-page__upgrade" padding="lg" data-testid="goals-upgrade-prompt">
      <EmptyState
        eyebrow="Feature Locked"
        title="Goals & Forecasting"
        description="Set sales goals, track progress, and forecast revenue with weighted pipeline analysis so the team can plan against real pipeline conditions."
        actions={<p className="goals-page__upgrade-cta">Contact your administrator to enable this feature.</p>}
      />
    </Card>
  );
}

function CreateGoalModal({
  isOpen,
  initialGoal,
  submitLabel = 'Create Goal',
  onClose,
  onSubmit,
}: {
  isOpen: boolean;
  initialGoal?: Goal | null;
  submitLabel?: string;
  onClose: () => void;
  onSubmit: (data: {
    metric: GoalMetric;
    targetValue: number;
    period: GoalPeriod;
    assigneeType: GoalAssigneeType;
    assigneeId: string;
    assigneeName: string;
  }) => void | Promise<void>;
}) {
  const { crmUser } = useAuth();
  const [metric, setMetric] = useState<GoalMetric>(initialGoal?.metric ?? 'revenue');
  const [targetValue, setTargetValue] = useState(
    initialGoal
      ? initialGoal.metric === 'revenue'
        ? String(initialGoal.targetValue / 100)
        : String(initialGoal.targetValue)
      : ''
  );
  const [period, setPeriod] = useState<GoalPeriod>(initialGoal?.period ?? 'monthly');
  const [assigneeType, setAssigneeType] = useState<GoalAssigneeType>(initialGoal?.assigneeType ?? 'user');

  if (!isOpen || !crmUser) return null;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    const numericValue = metric === 'revenue'
      ? Math.round(parseFloat(targetValue) * 100) // Convert to cents
      : parseInt(targetValue, 10);

    await onSubmit({
      metric,
      targetValue: numericValue,
      period,
      assigneeType,
      assigneeId: crmUser.id,
      assigneeName: crmUser.displayName,
    });

    onClose();
  };

  return (
    <div className="goals-page__modal-overlay" onClick={onClose}>
      <div className="goals-page__modal" onClick={(e) => e.stopPropagation()}>
        <h2 className="goals-page__modal-title">Create Goal</h2>
        <form onSubmit={handleSubmit}>
          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Metric</label>
            <select
              className="goals-page__form-select"
              value={metric}
              onChange={(e) => setMetric(e.target.value as GoalMetric)}
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
            <label className="goals-page__form-label">
              Target {metric === 'revenue' ? '($)' : '(count)'}
            </label>
            <input
              type="number"
              className="goals-page__form-input"
              value={targetValue}
              onChange={(e) => setTargetValue(e.target.value)}
              placeholder={metric === 'revenue' ? '10000' : '20'}
              required
              min="1"
            />
          </div>

          <div className="goals-page__form-group">
            <label className="goals-page__form-label">Period</label>
            <select
              className="goals-page__form-select"
              value={period}
              onChange={(e) => setPeriod(e.target.value as GoalPeriod)}
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
              onChange={(e) => setAssigneeType(e.target.value as GoalAssigneeType)}
            >
              <option value="user">Myself</option>
              <option value="team">Team</option>
              <option value="business">Company</option>
            </select>
          </div>

          <div className="goals-page__modal-actions">
            <button type="button" className="goals-page__btn--secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="goals-page__btn--primary">
              {submitLabel}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ============================================
// Main Component
// ============================================

export function GoalsPage() {
  const { crmUser } = useAuth();
  const features = getFeatureFlags();
  const navigate = useNavigate();

  // Filter state
  const [statusFilter, setStatusFilter] = useState<GoalStatus | ''>('');
  const [periodFilter, setPeriodFilter] = useState<GoalPeriod | ''>('');
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Build filters
  const filters = useMemo(() => ({
    status: statusFilter || undefined,
    period: periodFilter || undefined,
  }), [statusFilter, periodFilter]);

  // Fetch goals
  const { goals, isLoading, error, refresh, isEnabled } = useGoals(filters);
  const { stats } = useGoalDashboard();
  const { createGoal, cancelGoal, recalculateProgress, isMutating } = useGoalMutations();
  const hasFilters = Boolean(statusFilter || periodFilter);

  // Calculate stats
  const displayStats = useMemo(() => {
    if (stats) return stats;

    return {
      totalGoals: goals.length,
      activeGoals: goals.filter((g) => g.status === 'active').length,
      achievedGoals: goals.filter((g) => g.status === 'achieved').length,
      missedGoals: goals.filter((g) => g.status === 'missed').length,
      averageProgress: goals.length > 0
        ? Math.round(goals.reduce((sum, g) => sum + g.progressPercent, 0) / goals.length)
        : 0,
    };
  }, [goals, stats]);

  // Handlers
  const handleCreateGoal = useCallback(async (data: {
    metric: GoalMetric;
    targetValue: number;
    period: GoalPeriod;
    assigneeType: GoalAssigneeType;
    assigneeId: string;
    assigneeName: string;
  }) => {
    const now = new Date();
    const startDate = new Date(now);
    const endDate = new Date(now);

    // Calculate period dates
    switch (data.period) {
      case 'weekly':
        startDate.setDate(startDate.getDate() - startDate.getDay());
        endDate.setDate(startDate.getDate() + 6);
        break;
      case 'monthly':
        startDate.setDate(1);
        endDate.setMonth(endDate.getMonth() + 1);
        endDate.setDate(0);
        break;
      case 'quarterly':
        const quarter = Math.floor(startDate.getMonth() / 3);
        startDate.setMonth(quarter * 3);
        startDate.setDate(1);
        endDate.setMonth(quarter * 3 + 3);
        endDate.setDate(0);
        break;
      case 'yearly':
        startDate.setMonth(0);
        startDate.setDate(1);
        endDate.setMonth(11);
        endDate.setDate(31);
        break;
    }

    try {
      await createGoal({
        ...data,
        startDate,
        endDate,
        ownerId: crmUser!.id,
        ownerName: crmUser!.displayName,
        teamIds: [],
        visibility: 'team',
        createdById: crmUser!.id,
        createdByName: crmUser!.displayName,
      });
      refresh();
    } catch {
      // Error handled by hook
    }
  }, [createGoal, refresh, crmUser]);

  const handleEditGoal = useCallback((goal: Goal) => {
    navigate(`/goals/${goal.id}`);
  }, [navigate]);

  const handleCancelGoal = useCallback(async (goal: Goal) => {
    if (!confirm('Are you sure you want to cancel this goal?')) return;
    try {
      await cancelGoal(goal.id);
      refresh();
    } catch {
      // Error handled by hook
    }
  }, [cancelGoal, refresh]);

  const handleRecalculate = useCallback(async (goal: Goal) => {
    try {
      await recalculateProgress(goal.id);
      refresh();
    } catch {
      // Error handled by hook
    }
  }, [recalculateProgress, refresh]);

  // Check feature flag
  if (!features.enableGoals || !isEnabled) {
    return (
      <PageLayout width="wide" className="goals-page" data-testid="goals-page">
        <PageHeader
          eyebrow="Performance"
          title="Goals & Forecasting"
          subtitle="Track quota progress and forecast revenue for the current workspace."
        />
        <UpgradePrompt />
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="goals-page" data-testid="goals-page">
      <PageHeader
        eyebrow="Performance"
        title="Goals & Forecasting"
        subtitle="Track progress, watch attainment trends, and review revenue forecast confidence from one workspace."
        actions={(
          <Button
            onClick={() => setShowCreateModal(true)}
            disabled={isMutating}
          >
            New Goal
          </Button>
        )}
      />

      <Card className="goals-page__hero" padding="lg" tone="accent">
        <div className="goals-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current Snapshot</p>
          <h2>{hasFilters ? 'Filtered goal view' : 'Goal health overview'}</h2>
          <p>
            Review active quotas, achieved targets, and forecast confidence without leaving the
            goals workspace.
          </p>
        </div>
        <div className="goals-page__hero-stats">
          <div>
            <span>Total goals</span>
            <strong>{displayStats.totalGoals}</strong>
          </div>
          <div>
            <span>Active</span>
            <strong>{displayStats.activeGoals}</strong>
          </div>
          <div>
            <span>Avg progress</span>
            <strong>{displayStats.averageProgress}%</strong>
          </div>
        </div>
      </Card>

      {/* Stats */}
      <div className="goals-page__stats-grid">
        <StatsCard
          label="Active Goals"
          value={displayStats.activeGoals}
          testId="stat-active-goals"
        />
        <StatsCard
          label="Achieved"
          value={displayStats.achievedGoals}
          testId="stat-achieved-goals"
          color="success"
        />
        <StatsCard
          label="Missed"
          value={displayStats.missedGoals}
          testId="stat-missed-goals"
          color="danger"
        />
        <StatsCard
          label="Avg Progress"
          value={`${displayStats.averageProgress}%`}
          testId="stat-avg-progress"
        />
      </div>

      {/* Forecast Widget */}
      {features.enableForecasting ? (
        <Card className="goals-page__forecast-shell" padding="lg" tone="subtle">
          <ForecastWidget />
        </Card>
      ) : null}

      {/* Filters */}
      <Card className="goals-page__filters-card" padding="md">
        <Toolbar
          start={(
            <div className="goals-page__filters">
              <select
                className="goals-page__filter-select"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as GoalStatus | '')}
              >
                <option value="">All Statuses</option>
                <option value="active">Active</option>
                <option value="achieved">Achieved</option>
                <option value="missed">Missed</option>
                <option value="cancelled">Cancelled</option>
              </select>

              <select
                className="goals-page__filter-select"
                value={periodFilter}
                onChange={(e) => setPeriodFilter(e.target.value as GoalPeriod | '')}
              >
                <option value="">All Periods</option>
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
                <option value="quarterly">Quarterly</option>
                <option value="yearly">Yearly</option>
              </select>

              {hasFilters ? (
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={() => {
                    setStatusFilter('');
                    setPeriodFilter('');
                  }}
                >
                  Clear Filters
                </Button>
              ) : null}
            </div>
          )}
          end={(
            <div className="goals-page__filter-actions">
              <Button variant="secondary" size="sm" onClick={refresh}>
                Refresh
              </Button>
              <span className="ui-results-count">{goals.length} goals</span>
            </div>
          )}
        />
      </Card>

      {/* Goal List */}
      {isLoading ? (
        <Card className="goals-page__loading" padding="lg">Loading goals...</Card>
      ) : error ? (
        <Card padding="lg">
          <EmptyState
            eyebrow="Load Error"
            title="Goals could not be loaded"
            description={`Error loading goals: ${error.message}`}
            actions={<Button onClick={refresh}>Retry</Button>}
          />
        </Card>
      ) : goals.length === 0 ? (
        <Card className="goals-page__empty" padding="lg">
          <EmptyState
            eyebrow="Goals"
            title={hasFilters ? 'No goals match the current filters' : 'No goals found'}
            description={
              hasFilters
                ? 'Adjust the current filters to review more goal records.'
                : 'Create your first goal to start tracking quota progress and forecast performance.'
            }
            actions={
              !hasFilters ? (
                <Button onClick={() => setShowCreateModal(true)}>
                  Create Goal
                </Button>
              ) : undefined
            }
          />
        </Card>
      ) : (
        <div className="goals-page__goals-grid">
          {goals.map((goal) => (
            <GoalCard
              key={goal.id}
              goal={goal}
              onEdit={handleEditGoal}
              onCancel={handleCancelGoal}
              onRecalculate={handleRecalculate}
            />
          ))}
        </div>
      )}

      {/* Create Modal */}
      <CreateGoalModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSubmit={handleCreateGoal}
      />
    </PageLayout>
  );
}

export default GoalsPage;
