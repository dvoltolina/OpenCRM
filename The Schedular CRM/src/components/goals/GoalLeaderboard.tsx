/**
 * GoalLeaderboard Component
 * Displays team goal progress rankings
 */

import { useMemo } from 'react';
import type { Goal, GoalMetric } from '../../types/goals';
import { formatCurrency } from '../../hooks/useForecasting';

// ============================================
// Types
// ============================================

export interface GoalLeaderboardProps {
  /** Goals to display in leaderboard */
  goals: Goal[];
  /** Filter by specific metric (optional) */
  metric?: GoalMetric;
  /** Maximum number of entries to show */
  limit?: number;
  /** Title for the leaderboard */
  title?: string;
}

interface LeaderboardEntry {
  rank: number;
  userId: string;
  userName: string;
  progressPercent: number;
  currentValue: number;
  targetValue: number;
  metric: GoalMetric;
  goalsCount: number;
  achievedCount: number;
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

// ============================================
// Helper Functions
// ============================================

function formatValue(value: number, metric: GoalMetric): string {
  if (metric === 'revenue') {
    return formatCurrency(value);
  }
  return value.toLocaleString();
}

function aggregateByUser(goals: Goal[], metricFilter?: GoalMetric): LeaderboardEntry[] {
  const userMap = new Map<
    string,
    {
      userId: string;
      userName: string;
      totalProgress: number;
      totalCurrent: number;
      totalTarget: number;
      goalCount: number;
      achievedCount: number;
      metrics: Set<GoalMetric>;
    }
  >();

  // Filter to user-assigned active or achieved goals
  const relevantGoals = goals.filter(
    (g) =>
      g.assigneeType === 'user' &&
      (g.status === 'active' || g.status === 'achieved') &&
      (!metricFilter || g.metric === metricFilter)
  );

  for (const goal of relevantGoals) {
    const existing = userMap.get(goal.assigneeId);

    if (existing) {
      existing.totalProgress += goal.progressPercent;
      existing.totalCurrent += goal.currentValue;
      existing.totalTarget += goal.targetValue;
      existing.goalCount += 1;
      existing.achievedCount += goal.status === 'achieved' ? 1 : 0;
      existing.metrics.add(goal.metric);
    } else {
      userMap.set(goal.assigneeId, {
        userId: goal.assigneeId,
        userName: goal.assigneeName,
        totalProgress: goal.progressPercent,
        totalCurrent: goal.currentValue,
        totalTarget: goal.targetValue,
        goalCount: 1,
        achievedCount: goal.status === 'achieved' ? 1 : 0,
        metrics: new Set([goal.metric]),
      });
    }
  }

  // Convert to leaderboard entries and sort by progress
  const entries: LeaderboardEntry[] = Array.from(userMap.values())
    .map((user) => ({
      rank: 0,
      userId: user.userId,
      userName: user.userName,
      progressPercent: Math.round(user.totalProgress / user.goalCount),
      currentValue: user.totalCurrent,
      targetValue: user.totalTarget,
      metric: metricFilter || (user.metrics.size === 1 ? Array.from(user.metrics)[0] : 'revenue'),
      goalsCount: user.goalCount,
      achievedCount: user.achievedCount,
    }))
    .sort((a, b) => b.progressPercent - a.progressPercent);

  // Assign ranks
  entries.forEach((entry, index) => {
    entry.rank = index + 1;
  });

  return entries;
}

// ============================================
// Sub-components
// ============================================

function LeaderboardRow({ entry, showMetric }: { entry: LeaderboardEntry; showMetric: boolean }) {
  const progressColor =
    entry.progressPercent >= 100
      ? 'goal-leaderboard__progress--success'
      : entry.progressPercent >= 75
        ? 'goal-leaderboard__progress--on-track'
        : entry.progressPercent >= 50
          ? 'goal-leaderboard__progress--warning'
          : 'goal-leaderboard__progress--danger';

  const medalEmoji =
    entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : entry.rank === 3 ? '🥉' : '';

  return (
    <tr className="goal-leaderboard__row" data-testid={`leaderboard-row-${entry.userId}`}>
      <td className="goal-leaderboard__cell goal-leaderboard__cell--rank">
        {medalEmoji || entry.rank}
      </td>
      <td className="goal-leaderboard__cell goal-leaderboard__cell--name">
        <span className="goal-leaderboard__user-name">{entry.userName}</span>
        <span className="goal-leaderboard__goals-count">
          {entry.goalsCount} goal{entry.goalsCount !== 1 ? 's' : ''}
          {entry.achievedCount > 0 && ` (${entry.achievedCount} achieved)`}
        </span>
      </td>
      {showMetric && (
        <td className="goal-leaderboard__cell goal-leaderboard__cell--metric">
          {METRIC_LABELS[entry.metric]}
        </td>
      )}
      <td className="goal-leaderboard__cell goal-leaderboard__cell--value">
        {formatValue(entry.currentValue, entry.metric)} / {formatValue(entry.targetValue, entry.metric)}
      </td>
      <td className="goal-leaderboard__cell goal-leaderboard__cell--progress">
        <div className="goal-leaderboard__progress-container">
          <div className="goal-leaderboard__progress-bar">
            <div
              className={`goal-leaderboard__progress-fill ${progressColor}`}
              style={{ width: `${Math.min(100, entry.progressPercent)}%` }}
            />
          </div>
          <span className="goal-leaderboard__progress-text">{entry.progressPercent}%</span>
        </div>
      </td>
    </tr>
  );
}

// ============================================
// Main Component
// ============================================

export function GoalLeaderboard({
  goals,
  metric,
  limit = 10,
  title = 'Goal Leaderboard',
}: GoalLeaderboardProps) {
  const entries = useMemo(() => {
    const aggregated = aggregateByUser(goals, metric);
    return aggregated.slice(0, limit);
  }, [goals, metric, limit]);

  if (entries.length === 0) {
    return (
      <div className="goal-leaderboard goal-leaderboard--empty" data-testid="goal-leaderboard">
        <h3 className="goal-leaderboard__title">{title}</h3>
        <p className="goal-leaderboard__empty-message">
          No goals to display. Create goals to see the leaderboard.
        </p>
      </div>
    );
  }

  return (
    <div className="goal-leaderboard" data-testid="goal-leaderboard">
      <h3 className="goal-leaderboard__title">{title}</h3>
      <table className="goal-leaderboard__table">
        <thead>
          <tr>
            <th className="goal-leaderboard__header">#</th>
            <th className="goal-leaderboard__header">Name</th>
            {!metric && <th className="goal-leaderboard__header">Metric</th>}
            <th className="goal-leaderboard__header">Progress</th>
            <th className="goal-leaderboard__header">%</th>
          </tr>
        </thead>
        <tbody>
          {entries.map((entry) => (
            <LeaderboardRow key={entry.userId} entry={entry} showMetric={!metric} />
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default GoalLeaderboard;
