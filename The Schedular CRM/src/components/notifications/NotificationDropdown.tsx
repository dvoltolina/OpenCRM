/**
 * NotificationDropdown Component
 * Dropdown panel showing all task reminders
 *
 * CRM-44 Implementation
 */

import { useNavigate } from 'react-router-dom';
import { useNotifications } from '../../contexts/NotificationContext';
import { TaskReminderCard } from './TaskReminderCard';
import type { TaskReminder } from '../../services/task-reminder-service';
import './notifications.css';

// ============================================
// Types
// ============================================

interface NotificationDropdownProps {
  onClose: () => void;
}

interface GroupedReminders {
  overdue: TaskReminder[];
  dueToday: TaskReminder[];
  upcoming: TaskReminder[];
}

// ============================================
// Helper Functions
// ============================================

/**
 * Group reminders by type
 */
function groupReminders(reminders: TaskReminder[]): GroupedReminders {
  return reminders.reduce(
    (acc, reminder) => {
      switch (reminder.reminderType) {
        case 'overdue':
          acc.overdue.push(reminder);
          break;
        case 'due_today':
          acc.dueToday.push(reminder);
          break;
        case 'upcoming':
          acc.upcoming.push(reminder);
          break;
      }
      return acc;
    },
    { overdue: [], dueToday: [], upcoming: [] } as GroupedReminders
  );
}

// ============================================
// Component
// ============================================

export function NotificationDropdown({ onClose }: NotificationDropdownProps) {
  const navigate = useNavigate();
  const { reminders, unreadCount, isLoading, markAllRead } = useNotifications();

  const grouped = groupReminders(reminders);
  const hasReminders = reminders.length > 0;

  const handleMarkAllRead = () => {
    markAllRead();
  };

  const handleViewAllTasks = () => {
    onClose();
    navigate('/activities?type=task');
  };

  return (
    <div className="notification-dropdown">
      <div className="notification-dropdown-header">
        <h3 className="notification-dropdown-title">
          Notifications
          {unreadCount > 0 && (
            <span className="notification-dropdown-count">({unreadCount})</span>
          )}
        </h3>

        {hasReminders && unreadCount > 0 && (
          <button
            className="notification-dropdown-action"
            onClick={handleMarkAllRead}
          >
            Mark all read
          </button>
        )}
      </div>

      <div className="notification-dropdown-content">
        {isLoading ? (
          <div className="notification-dropdown-loading">
            <div className="notification-spinner" />
            <p>Loading notifications...</p>
          </div>
        ) : !hasReminders ? (
          <div className="notification-dropdown-empty">
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
            <p className="notification-empty-text">No reminders</p>
            <p className="notification-empty-subtext">
              You're all caught up!
            </p>
          </div>
        ) : (
          <>
            {grouped.overdue.length > 0 && (
              <div className="notification-group">
                <h4 className="notification-group-title notification-group-overdue">
                  Overdue ({grouped.overdue.length})
                </h4>
                {grouped.overdue.map(reminder => (
                  <TaskReminderCard key={reminder.id} reminder={reminder} />
                ))}
              </div>
            )}

            {grouped.dueToday.length > 0 && (
              <div className="notification-group">
                <h4 className="notification-group-title notification-group-today">
                  Due Today ({grouped.dueToday.length})
                </h4>
                {grouped.dueToday.map(reminder => (
                  <TaskReminderCard key={reminder.id} reminder={reminder} />
                ))}
              </div>
            )}

            {grouped.upcoming.length > 0 && (
              <div className="notification-group">
                <h4 className="notification-group-title notification-group-upcoming">
                  Upcoming ({grouped.upcoming.length})
                </h4>
                {grouped.upcoming.map(reminder => (
                  <TaskReminderCard key={reminder.id} reminder={reminder} />
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {hasReminders && (
        <div className="notification-dropdown-footer">
          <button
            className="notification-view-all-btn"
            onClick={handleViewAllTasks}
          >
            View all tasks
          </button>
        </div>
      )}
    </div>
  );
}
