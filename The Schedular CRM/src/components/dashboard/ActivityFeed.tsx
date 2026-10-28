/**
 * ActivityFeed Component
 * Recent activity feed widget
 *
 * Agent CRM-18 Implementation
 */

import type { SalesActivity } from '../../types/models';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface ActivityFeedProps {
  /** List of activities to display */
  activities: SalesActivity[];
  /** Maximum number of activities to show */
  limit?: number;
  /** Callback when activity is clicked */
  onActivityClick?: (activityId: string) => void;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Get activity type icon
 */
function getActivityIcon(type: SalesActivity['type']): string {
  switch (type) {
    case 'call':
      return '📞';
    case 'email':
      return '✉️';
    case 'meeting':
      return '🤝';
    case 'note':
      return '📝';
    case 'task':
      return '✅';
    default:
      return '📋';
  }
}

/**
 * Format relative time
 */
function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

/**
 * Get activity description
 */
function getActivityDescription(activity: SalesActivity): string {
  const parts: string[] = [];

  // Add type-specific prefix
  switch (activity.type) {
    case 'call':
      parts.push('Made a call');
      break;
    case 'email':
      parts.push('Sent an email');
      break;
    case 'meeting':
      parts.push('Had a meeting');
      break;
    case 'note':
      parts.push('Added a note');
      break;
    case 'task':
      parts.push(activity.isCompleted ? 'Completed task' : 'Created task');
      break;
  }

  // Add description if available
  if (activity.description) {
    parts.push(`- ${activity.description}`);
  }

  return parts.join(' ');
}

/**
 * Get entity reference
 */
function getEntityReference(activity: SalesActivity): string | null {
  if (activity.dealId) return 'Deal';
  if (activity.leadId) return 'Lead';
  if (activity.clientId) return 'Contact';
  if (activity.companyId) return 'Company';
  return null;
}

// ============================================
// Component
// ============================================

/**
 * ActivityFeed - Recent activity feed
 *
 * @example
 * ```tsx
 * const { recentActivities } = useDashboardData();
 *
 * return (
 *   <ActivityFeed
 *     activities={recentActivities}
 *     limit={10}
 *     onActivityClick={(id) => navigate(`/activities/${id}`)}
 *   />
 * );
 * ```
 */
export function ActivityFeed({
  activities,
  limit = 10,
  onActivityClick,
  className = '',
}: ActivityFeedProps) {
  // Limit activities
  const displayedActivities = activities.slice(0, limit);

  return (
    <div className={`activity-feed ${className}`}>
      <div className="activity-feed__header">
        <h2>Recent Activities</h2>
        <p className="activity-feed__subtitle">Last 7 days</p>
      </div>

      <div className="activity-feed__list">
        {displayedActivities.map((activity) => {
          const icon = getActivityIcon(activity.type);
          const description = getActivityDescription(activity);
          const entityRef = getEntityReference(activity);

          return (
            <div
              key={activity.id}
              className="activity-feed-item"
              onClick={() => onActivityClick?.(activity.id)}
              role={onActivityClick ? 'button' : undefined}
              tabIndex={onActivityClick ? 0 : undefined}
            >
              <div className="activity-feed-item__icon">{icon}</div>

              <div className="activity-feed-item__content">
                <div className="activity-feed-item__header">
                  <h3 className="activity-feed-item__title">{activity.title}</h3>
                  <span className="activity-feed-item__time">
                    {formatRelativeTime(activity.createdAt)}
                  </span>
                </div>

                <p className="activity-feed-item__description">{description}</p>

                <div className="activity-feed-item__meta">
                  <span className="activity-feed-item__user">
                    {activity.createdByName}
                  </span>
                  {entityRef && (
                    <span className="activity-feed-item__entity">{entityRef}</span>
                  )}
                  {activity.type === 'task' && activity.isCompleted && (
                    <span className="activity-feed-item__badge activity-feed-item__badge--completed">
                      Completed
                    </span>
                  )}
                  {activity.type === 'task' &&
                    !activity.isCompleted &&
                    activity.dueDate && (
                      <span className="activity-feed-item__badge">
                        Due {formatRelativeTime(activity.dueDate)}
                      </span>
                    )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {displayedActivities.length === 0 && (
        <div className="activity-feed__empty">
          <p>No recent activities</p>
        </div>
      )}
    </div>
  );
}

export default ActivityFeed;
