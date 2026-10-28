/**
 * NotificationList Component
 * Displays a list of notifications with filters
 *
 * HIPAA Compliance: No PHI displayed - only entity references
 */

import { useState, useMemo } from 'react';
import type { Notification, NotificationType } from '../../types/notifications';
import { NotificationItem } from './NotificationItem';
import './notifications.css';

// ============================================
// Types
// ============================================

interface NotificationListProps {
  notifications: Notification[];
  isLoading: boolean;
  onMarkRead: (id: string) => void;
  onMarkAllRead: () => void;
  onArchive: (id: string) => void;
  onLoadMore?: () => void;
  hasMore?: boolean;
}

type FilterType = 'all' | 'unread' | NotificationType;

// ============================================
// Filter Configuration
// ============================================

const TYPE_LABELS: Record<string, string> = {
  all: 'All',
  unread: 'Unread',
  task_due: 'Tasks Due',
  task_assigned: 'Tasks Assigned',
  task_completed: 'Completed Tasks',
  deal_stage_changed: 'Deal Updates',
  deal_won: 'Deals Won',
  deal_lost: 'Deals Lost',
  lead_assigned: 'Leads',
  lead_converted: 'Conversions',
  sequence_reply: 'Replies',
  sequence_completed: 'Sequences',
  email_opened: 'Opens',
  email_clicked: 'Clicks',
  meeting_scheduled: 'Meetings',
  mention: 'Mentions',
  comment: 'Comments',
  goal_achieved: 'Goals',
  goal_at_risk: 'At Risk',
  system_announcement: 'System',
};

// ============================================
// Component
// ============================================

export function NotificationList({
  notifications,
  isLoading,
  onMarkRead,
  onMarkAllRead,
  onArchive,
  onLoadMore,
  hasMore,
}: NotificationListProps) {
  const [filter, setFilter] = useState<FilterType>('all');

  // Count unread
  const unreadCount = useMemo(
    () => notifications.filter((n) => !n.isRead).length,
    [notifications]
  );

  // Filter notifications
  const filteredNotifications = useMemo(() => {
    if (filter === 'all') return notifications;
    if (filter === 'unread') return notifications.filter((n) => !n.isRead);
    return notifications.filter((n) => n.type === filter);
  }, [notifications, filter]);

  // Group by date
  const groupedNotifications = useMemo(() => {
    const groups: Map<string, Notification[]> = new Map();

    for (const notification of filteredNotifications) {
      const date = new Date(notification.createdAt);
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      let label: string;
      if (date.toDateString() === today.toDateString()) {
        label = 'Today';
      } else if (date.toDateString() === yesterday.toDateString()) {
        label = 'Yesterday';
      } else {
        label = date.toLocaleDateString('en-US', {
          weekday: 'long',
          month: 'short',
          day: 'numeric',
        });
      }

      const existing = groups.get(label) || [];
      existing.push(notification);
      groups.set(label, existing);
    }

    return groups;
  }, [filteredNotifications]);

  // Get available type filters (only show types that have notifications)
  const availableTypes = useMemo(() => {
    const types = new Set<NotificationType>();
    for (const notification of notifications) {
      types.add(notification.type);
    }
    return Array.from(types);
  }, [notifications]);

  return (
    <div className="notification-list-container">
      {/* Header */}
      <div className="notification-list-header">
        <div className="notification-list-title-row">
          <h2 className="notification-list-title">
            Notifications
            {unreadCount > 0 && (
              <span className="notification-list-badge">{unreadCount}</span>
            )}
          </h2>
          {unreadCount > 0 && (
            <button
              className="notification-list-action-btn"
              onClick={onMarkAllRead}
            >
              Mark all as read
            </button>
          )}
        </div>

        {/* Filters */}
        <div className="notification-list-filters">
          <button
            className={`notification-filter-btn ${filter === 'all' ? 'active' : ''}`}
            onClick={() => setFilter('all')}
          >
            All
          </button>
          <button
            className={`notification-filter-btn ${filter === 'unread' ? 'active' : ''}`}
            onClick={() => setFilter('unread')}
          >
            Unread ({unreadCount})
          </button>
          {availableTypes.slice(0, 5).map((type) => (
            <button
              key={type}
              className={`notification-filter-btn ${filter === type ? 'active' : ''}`}
              onClick={() => setFilter(type)}
            >
              {TYPE_LABELS[type] || type}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="notification-list-content">
        {isLoading ? (
          <div className="notification-list-loading">
            <div className="notification-spinner" />
            <p>Loading notifications...</p>
          </div>
        ) : filteredNotifications.length === 0 ? (
          <div className="notification-list-empty">
            <svg
              className="notification-empty-icon"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
              />
            </svg>
            <p className="notification-empty-text">
              {filter === 'unread'
                ? 'No unread notifications'
                : filter !== 'all'
                  ? `No ${TYPE_LABELS[filter] || filter} notifications`
                  : 'No notifications yet'}
            </p>
            <p className="notification-empty-subtext">
              {filter === 'all'
                ? "You'll see notifications here as activities happen"
                : 'Try changing your filter'}
            </p>
          </div>
        ) : (
          <>
            {Array.from(groupedNotifications.entries()).map(([date, group]) => (
              <div key={date} className="notification-list-group">
                <h3 className="notification-list-group-title">{date}</h3>
                {group.map((notification) => (
                  <NotificationItem
                    key={notification.id}
                    notification={notification}
                    onMarkRead={onMarkRead}
                    onArchive={onArchive}
                  />
                ))}
              </div>
            ))}

            {hasMore && (
              <div className="notification-list-load-more">
                <button
                  className="notification-load-more-btn"
                  onClick={onLoadMore}
                >
                  Load more
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
