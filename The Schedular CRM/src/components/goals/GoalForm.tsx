/**
 * GoalForm Component
 * Create and edit goals with metric, target, and period selection
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import { usePipelines } from '../../hooks/usePipelines';
import type { Goal, GoalMetric, GoalPeriod, GoalAssigneeType, CreateGoalData } from '../../types/goals';

// ============================================
// Types
// ============================================

export interface GoalFormProps {
  /** Existing goal for editing (null for create mode) */
  goal?: Goal | null;
  /** Called when form is submitted */
  onSubmit: (data: CreateGoalData) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** True while submitting */
  isSubmitting?: boolean;
}

export interface GoalFormData {
  metric: GoalMetric;
  targetValue: string;
  period: GoalPeriod;
  assigneeType: GoalAssigneeType;
  assigneeId: string;
  assigneeName: string;
  pipelineId?: string;
}

// ============================================
// Constants
// ============================================

const METRIC_OPTIONS: { value: GoalMetric; label: string; hint: string }[] = [
  { value: 'revenue', label: 'Revenue', hint: 'Total opportunity value (closed won)' },
  { value: 'deals_won', label: 'Opportunities Won', hint: 'Number of opportunities closed' },
  { value: 'deals_created', label: 'Opportunities Created', hint: 'New opportunities added' },
  { value: 'activities_completed', label: 'Activities', hint: 'Tasks/activities completed' },
  { value: 'calls_made', label: 'Calls Made', hint: 'Call activities logged' },
  { value: 'emails_sent', label: 'Emails Sent', hint: 'Email activities logged' },
];

const PERIOD_OPTIONS: { value: GoalPeriod; label: string }[] = [
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'yearly', label: 'Yearly' },
];

const ASSIGNEE_TYPE_OPTIONS: { value: GoalAssigneeType; label: string }[] = [
  { value: 'user', label: 'Individual' },
  { value: 'team', label: 'Team' },
  { value: 'business', label: 'Company-wide' },
];

// ============================================
// Helper Functions
// ============================================

function calculatePeriodDates(period: GoalPeriod): { startDate: Date; endDate: Date } {
  const now = new Date();
  const startDate = new Date(now);
  const endDate = new Date(now);

  switch (period) {
    case 'weekly':
      // Start on Sunday of current week
      startDate.setDate(startDate.getDate() - startDate.getDay());
      startDate.setHours(0, 0, 0, 0);
      endDate.setDate(startDate.getDate() + 6);
      endDate.setHours(23, 59, 59, 999);
      break;
    case 'monthly':
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      endDate.setMonth(endDate.getMonth() + 1);
      endDate.setDate(0);
      endDate.setHours(23, 59, 59, 999);
      break;
    case 'quarterly':
      const quarter = Math.floor(startDate.getMonth() / 3);
      startDate.setMonth(quarter * 3);
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      endDate.setMonth(quarter * 3 + 3);
      endDate.setDate(0);
      endDate.setHours(23, 59, 59, 999);
      break;
    case 'yearly':
      startDate.setMonth(0);
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      endDate.setMonth(11);
      endDate.setDate(31);
      endDate.setHours(23, 59, 59, 999);
      break;
  }

  return { startDate, endDate };
}

// ============================================
// Main Component
// ============================================

export function GoalForm({ goal, onSubmit, onCancel, isSubmitting = false }: GoalFormProps) {
  const { crmUser, businessId } = useAuth();
  const { pipelines } = usePipelines();

  // Form state
  const [metric, setMetric] = useState<GoalMetric>(goal?.metric || 'revenue');
  const [targetValue, setTargetValue] = useState(
    goal ? (goal.metric === 'revenue' ? (goal.targetValue / 100).toString() : goal.targetValue.toString()) : ''
  );
  const [period, setPeriod] = useState<GoalPeriod>(goal?.period || 'monthly');
  const [assigneeType, setAssigneeType] = useState<GoalAssigneeType>(goal?.assigneeType || 'user');
  const [pipelineId, setPipelineId] = useState<string>(goal?.pipelineId || '');
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Validation
  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (!targetValue || parseFloat(targetValue) <= 0) {
      newErrors.targetValue = 'Target value must be greater than 0';
    }

    if (metric === 'revenue' && isNaN(parseFloat(targetValue))) {
      newErrors.targetValue = 'Please enter a valid dollar amount';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [targetValue, metric]);

  // Handle submit
  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();

      if (!validate() || !crmUser || !businessId) return;

      const { startDate, endDate } = calculatePeriodDates(period);

      // Convert target value (dollars to cents for revenue)
      const numericValue =
        metric === 'revenue'
          ? Math.round(parseFloat(targetValue) * 100)
          : parseInt(targetValue, 10);

      const data: CreateGoalData = {
        metric,
        targetValue: numericValue,
        period,
        startDate,
        endDate,
        assigneeType,
        assigneeId: crmUser.id,
        assigneeName: crmUser.displayName,
        pipelineId: pipelineId || undefined,
        ownerId: crmUser.id,
        ownerName: crmUser.displayName,
        teamIds: [],
        visibility: assigneeType === 'user' ? 'private' : 'team',
        createdById: crmUser.id,
        createdByName: crmUser.displayName,
      };

      await onSubmit(data);
    },
    [
      validate,
      crmUser,
      businessId,
      metric,
      targetValue,
      period,
      assigneeType,
      pipelineId,
      onSubmit,
    ]
  );

  const isEditMode = !!goal;
  const title = isEditMode ? 'Edit Goal' : 'Create Goal';

  return (
    <form className="goal-form" onSubmit={handleSubmit} data-testid="goal-form">
      <h2 className="goal-form__title">{title}</h2>

      {/* Metric Selection */}
      <div className="goal-form__field">
        <label className="goal-form__label" htmlFor="goal-metric">
          Metric
        </label>
        <select
          id="goal-metric"
          className="goal-form__select"
          value={metric}
          onChange={(e) => setMetric(e.target.value as GoalMetric)}
          disabled={isEditMode}
        >
          {METRIC_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        <span className="goal-form__hint">
          {METRIC_OPTIONS.find((m) => m.value === metric)?.hint}
        </span>
      </div>

      {/* Target Value */}
      <div className="goal-form__field">
        <label className="goal-form__label" htmlFor="goal-target">
          Target {metric === 'revenue' ? '($)' : '(count)'}
        </label>
        <input
          id="goal-target"
          type="number"
          className={`goal-form__input ${errors.targetValue ? 'goal-form__input--error' : ''}`}
          value={targetValue}
          onChange={(e) => setTargetValue(e.target.value)}
          placeholder={metric === 'revenue' ? '10000' : '20'}
          min="1"
          step={metric === 'revenue' ? '0.01' : '1'}
        />
        {errors.targetValue && (
          <span className="goal-form__error">{errors.targetValue}</span>
        )}
      </div>

      {/* Period Selection */}
      <div className="goal-form__field">
        <label className="goal-form__label" htmlFor="goal-period">
          Period
        </label>
        <select
          id="goal-period"
          className="goal-form__select"
          value={period}
          onChange={(e) => setPeriod(e.target.value as GoalPeriod)}
          disabled={isEditMode}
        >
          {PERIOD_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {/* Assignee Type */}
      <div className="goal-form__field">
        <label className="goal-form__label" htmlFor="goal-assignee-type">
          Assign To
        </label>
        <select
          id="goal-assignee-type"
          className="goal-form__select"
          value={assigneeType}
          onChange={(e) => setAssigneeType(e.target.value as GoalAssigneeType)}
          disabled={isEditMode}
        >
          {ASSIGNEE_TYPE_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {/* Pipeline Filter (optional, for revenue/deals metrics) */}
      {(metric === 'revenue' || metric === 'deals_won' || metric === 'deals_created') &&
        pipelines.length > 0 && (
          <div className="goal-form__field">
            <label className="goal-form__label" htmlFor="goal-pipeline">
              Pipeline (optional)
            </label>
            <select
              id="goal-pipeline"
              className="goal-form__select"
              value={pipelineId}
              onChange={(e) => setPipelineId(e.target.value)}
            >
              <option value="">All Pipelines</option>
              {pipelines.map((p: { id: string; name: string }) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
            <span className="goal-form__hint">
              Only count opportunities from this pipeline
            </span>
          </div>
        )}

      {/* Actions */}
      <div className="goal-form__actions">
        <button
          type="button"
          className="goal-form__btn goal-form__btn--secondary"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          Cancel
        </button>
        <button
          type="submit"
          className="goal-form__btn goal-form__btn--primary"
          disabled={isSubmitting}
        >
          {isSubmitting ? 'Saving...' : isEditMode ? 'Update Goal' : 'Create Goal'}
        </button>
      </div>
    </form>
  );
}

export default GoalForm;
