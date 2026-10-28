/**
 * Dashboard Components Index
 * Barrel export for all dashboard components
 *
 * Agent CRM-18 Implementation
 */

// KPI Components
export { KPICard } from './KPICard';
export type { KPICardProps } from './KPICard';

export { KPIGrid } from './KPIGrid';
export type { KPIGridProps } from './KPIGrid';

// Widget Components
export { PipelineFunnel } from './PipelineFunnel';
export type { PipelineFunnelProps } from './PipelineFunnel';

export { RecentDeals } from './RecentDeals';
export type { RecentDealsProps } from './RecentDeals';

export { UpcomingTasks } from './UpcomingTasks';
export type { UpcomingTasksProps } from './UpcomingTasks';

export { ActivityFeed } from './ActivityFeed';
export type { ActivityFeedProps } from './ActivityFeed';

// Action Components
export { QuickActions } from './QuickActions';
export type { QuickActionsProps } from './QuickActions';

// Task 7 - Dashboard Editor
export { DashboardEditor } from './DashboardEditor';
export type { DashboardEditorProps, AvailableWidget } from './DashboardEditor';

// Task 7 - Dashboard Widgets
export {
  MetricWidget,
  ChartWidget,
  LeaderboardWidget,
  ActivityFeedWidget,
} from './widgets';
export type {
  MetricWidgetProps,
  ChartWidgetProps,
  LeaderboardWidgetProps,
  LeaderboardEntry,
  ActivityFeedWidgetProps,
  ActivityFeedItem,
} from './widgets';

// Role-Based Dashboard Components (Empire/Team/Hunter Views)
export { QuotaProgress } from './QuotaProgress';
export type { QuotaProgressProps } from './QuotaProgress';

export { TeamLeaderboard } from './TeamLeaderboard';
export type { TeamLeaderboardProps, LeaderboardEntry as TeamLeaderboardEntry } from './TeamLeaderboard';

export { TodaysTasks } from './TodaysTasks';
export type { TodaysTasksProps } from './TodaysTasks';

export { TeamActivitySummary } from './TeamActivitySummary';
export type { TeamActivitySummaryProps } from './TeamActivitySummary';

export { ForecastVsGoal } from './ForecastVsGoal';
export type { ForecastVsGoalProps } from './ForecastVsGoal';
