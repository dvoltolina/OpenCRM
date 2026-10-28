/**
 * ActivityFeedWidget Component
 * Displays a real-time feed of recent activities.
 *
 * HIPAA Compliance:
 * - Activity descriptions are sanitized of PHI
 * - Entity names shown but no sensitive details
 * - All access logged via parent components
 *
 * Agent CRM - Task 7 Implementation
 */

import { useMemo } from 'react';

// ============================================
// Types
// ============================================

export interface ActivityFeedItem {
  id: string;
  type: string;
  title: string;
  description?: string;
  entityType?: 'lead' | 'deal' | 'contact' | 'company' | 'task';
  entityId?: string;
  entityName?: string;
  createdAt: Date;
  createdByName?: string;
  createdByAvatarUrl?: string;
}

export interface ActivityFeedWidgetProps {
  /** Widget title */
  title?: string;
  /** Activity items */
  activities: ActivityFeedItem[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Maximum items to show */
  limit?: number;
  /** Show relative time instead of absolute */
  useRelativeTime?: boolean;
  /** Click handler for activity */
  onActivityClick?: (activity: ActivityFeedItem) => void;
  /** Click handler for view all */
  onViewAll?: () => void;
}

// ============================================
// Helper Functions
// ============================================

function getActivityIcon(type: string): string {
  const icons: Record<string, string> = {
    call: '📞',
    email: '📧',
    meeting: '📅',
    note: '📝',
    task: '✅',
    deal_created: '💼',
    deal_won: '🎉',
    deal_lost: '❌',
    deal_moved: '➡️',
    lead_created: '🎯',
    lead_converted: '✨',
    contact_created: '👤',
    company_created: '🏢',
    default: '📌',
  };

  return icons[type] || icons.default;
}

function getEntityIcon(entityType?: string): string {
  const icons: Record<string, string> = {
    lead: '🎯',
    deal: '💼',
    contact: '👤',
    company: '🏢',
    task: '✅',
  };

  return entityType ? icons[entityType] || '' : '';
}

function getRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .substring(0, 2);
}

// ============================================
// Avatar Component
// ============================================

interface AvatarProps {
  name?: string;
  avatarUrl?: string;
}

function Avatar({ name, avatarUrl }: AvatarProps) {
  const colors = [
    '#3b82f6', // blue
    '#10b981', // emerald
    '#f59e0b', // amber
    '#ef4444', // red
    '#8b5cf6', // violet
    '#ec4899', // pink
  ];

  const colorIndex = name ? name.charCodeAt(0) % colors.length : 0;
  const bgColor = colors[colorIndex];

  if (avatarUrl) {
    return (
      <div className="activity-feed__avatar">
        <img src={avatarUrl} alt={name || 'User'} className="activity-feed__avatar-img" />
      </div>
    );
  }

  if (name) {
    return (
      <div
        className="activity-feed__avatar activity-feed__avatar--initials"
        style={{ backgroundColor: bgColor }}
      >
        {getInitials(name)}
      </div>
    );
  }

  return (
    <div className="activity-feed__avatar activity-feed__avatar--system">
      🤖
    </div>
  );
}

// ============================================
// Main Component
// ============================================

/**
 * ActivityFeedWidget - Real-time activity stream
 *
 * Features:
 * - Chronological activity list
 * - Type-specific icons
 * - Relative or absolute timestamps
 * - Entity links
 * - User avatars
 *
 * @example
 * ```tsx
 * <ActivityFeedWidget
 *   title="Recent Activity"
 *   activities={recentActivities}
 *   limit={10}
 *   useRelativeTime={true}
 *   onActivityClick={(activity) => navigate(`/activity/${activity.id}`)}
 *   onViewAll={() => navigate('/activity')}
 * />
 * ```
 */
export function ActivityFeedWidget({
  title = 'Recent Activity',
  activities,
  isLoading = false,
  error = null,
  limit = 10,
  useRelativeTime = true,
  onActivityClick,
  onViewAll,
}: ActivityFeedWidgetProps) {
  // Limit and sort activities
  const displayActivities = useMemo(() => {
    return [...activities]
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, limit);
  }, [activities, limit]);

  // Group by date for visual separation
  const groupedActivities = useMemo(() => {
    const groups: Map<string, ActivityFeedItem[]> = new Map();
    const now = new Date();
    const todayStr = now.toDateString();
    const yesterdayDate = new Date(now);
    yesterdayDate.setDate(yesterdayDate.getDate() - 1);
    const yesterdayStr = yesterdayDate.toDateString();

    for (const activity of displayActivities) {
      const dateStr = new Date(activity.createdAt).toDateString();
      let groupKey: string;

      if (dateStr === todayStr) {
        groupKey = 'Today';
      } else if (dateStr === yesterdayStr) {
        groupKey = 'Yesterday';
      } else {
        groupKey = new Date(activity.createdAt).toLocaleDateString('en-US', {
          weekday: 'long',
          month: 'short',
          day: 'numeric',
        });
      }

      if (!groups.has(groupKey)) {
        groups.set(groupKey, []);
      }
      groups.get(groupKey)!.push(activity);
    }

    return groups;
  }, [displayActivities]);

  // Loading state
  if (isLoading) {
    return (
      <div className="activity-feed activity-feed--loading">
        <div className="activity-feed__header">
          <h3 className="activity-feed__title">{title}</h3>
        </div>
        <div className="activity-feed__content">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="activity-feed__item-skeleton" />
          ))}
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="activity-feed activity-feed--error">
        <div className="activity-feed__header">
          <h3 className="activity-feed__title">{title}</h3>
        </div>
        <div className="activity-feed__content">
          <p className="activity-feed__error">{error}</p>
        </div>
      </div>
    );
  }

  // Empty state
  if (displayActivities.length === 0) {
    return (
      <div className="activity-feed activity-feed--empty">
        <div className="activity-feed__header">
          <h3 className="activity-feed__title">{title}</h3>
        </div>
        <div className="activity-feed__content">
          <div className="activity-feed__empty-state">
            <span className="activity-feed__empty-icon">📭</span>
            <p>No recent activity</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="activity-feed">
      <div className="activity-feed__header">
        <h3 className="activity-feed__title">{title}</h3>
        {onViewAll && (
          <button
            type="button"
            className="activity-feed__view-all"
            onClick={onViewAll}
          >
            View All
          </button>
        )}
      </div>

      <div className="activity-feed__content">
        {Array.from(groupedActivities.entries()).map(([groupKey, items]) => (
          <div key={groupKey} className="activity-feed__group">
            <div className="activity-feed__group-header">
              <span className="activity-feed__group-title">{groupKey}</span>
            </div>

            <ul className="activity-feed__list">
              {items.map((activity) => (
                <li
                  key={activity.id}
                  className={`activity-feed__item ${
                    onActivityClick ? 'activity-feed__item--clickable' : ''
                  }`}
                  onClick={onActivityClick ? () => onActivityClick(activity) : undefined}
                >
                  <div className="activity-feed__item-icon">
                    {getActivityIcon(activity.type)}
                  </div>

                  <div className="activity-feed__item-content">
                    <div className="activity-feed__item-header">
                      <span className="activity-feed__item-title">
                        {activity.title}
                      </span>
                      <span className="activity-feed__item-time">
                        {useRelativeTime
                          ? getRelativeTime(new Date(activity.createdAt))
                          : formatTime(new Date(activity.createdAt))}
                      </span>
                    </div>

                    {activity.description && (
                      <p className="activity-feed__item-description">
                        {activity.description}
                      </p>
                    )}

                    {activity.entityName && (
                      <div className="activity-feed__item-entity">
                        <span className="activity-feed__entity-icon">
                          {getEntityIcon(activity.entityType)}
                        </span>
                        <span className="activity-feed__entity-name">
                          {activity.entityName}
                        </span>
                      </div>
                    )}

                    {activity.createdByName && (
                      <div className="activity-feed__item-author">
                        <Avatar
                          name={activity.createdByName}
                          avatarUrl={activity.createdByAvatarUrl}
                        />
                        <span className="activity-feed__author-name">
                          {activity.createdByName}
                        </span>
                      </div>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      {activities.length > limit && (
        <div className="activity-feed__footer">
          <span className="activity-feed__more">
            +{activities.length - limit} more activities
          </span>
        </div>
      )}
    </div>
  );
}

export default ActivityFeedWidget;
