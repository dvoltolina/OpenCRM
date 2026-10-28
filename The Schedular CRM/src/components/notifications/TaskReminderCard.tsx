/**
 * TaskReminderCard Component
 * Individual reminder card in the notification dropdown
 *
 * CRM-44 Implementation
 */

import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useNotifications } from '../../contexts/NotificationContext';
import { getActivityService } from '../../services/activity-service';
import { getTaskReminderService } from '../../services/task-reminder-service';
import { createSecurityContextFromParams } from '../../lib/security-context';
import type { TaskReminder } from '../../services/task-reminder-service';
import './notifications.css';

// ============================================
// Types
// ============================================

interface TaskReminderCardProps {
  reminder: TaskReminder;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format relative time string
 */
function formatRelativeTime(daysUntilDue: number): string {
  if (daysUntilDue < 0) {
    const daysOverdue = Math.abs(daysUntilDue);
    if (daysOverdue === 1) return '1 day overdue';
    return `${daysOverdue} days overdue`;
  } else if (daysUntilDue === 0) {
    return 'Due today';
  } else if (daysUntilDue === 1) {
    return 'Due tomorrow';
  } else {
    return `Due in ${daysUntilDue} days`;
  }
}

/**
 * Get color class based on reminder type
 */
function getReminderColorClass(reminderType: TaskReminder['reminderType']): string {
  switch (reminderType) {
    case 'overdue':
      return 'reminder-overdue';
    case 'due_today':
      return 'reminder-due-today';
    case 'upcoming':
      return 'reminder-upcoming';
    default:
      return '';
  }
}

// ============================================
// Component
// ============================================

export function TaskReminderCard({ reminder }: TaskReminderCardProps) {
  const navigate = useNavigate();
  const { crmUser, businessId } = useAuth();
  const { markRead, dismissReminder } = useNotifications();

  const handleViewTask = () => {
    // Mark as read
    markRead(reminder.id);

    // Navigate to entity detail page
    const basePath = getEntityPath(reminder.entityType);
    if (basePath) {
      navigate(`${basePath}/${reminder.entityId}`);
    }
  };

  const handleMarkComplete = async (e: React.MouseEvent) => {
    e.stopPropagation();

    if (!crmUser || !businessId) return;

    try {
      const activityService = getActivityService();
      const context = createSecurityContextFromParams(
        businessId,
        crmUser.id,
        crmUser.displayName || crmUser.email || 'Unknown User',
        crmUser.role || 'staff',
        crmUser.teamIds,
        crmUser.managedTeamIds,
        crmUser.managerId
      );
      const result = await activityService.completeTask(context, reminder.taskId);

      if (result.success) {
        // Dismiss the reminder after marking complete
        dismissReminder(reminder.id);
      } else {
        console.error('Failed to mark task complete:', result.error);
      }
    } catch (error) {
      console.error('Error marking task complete:', error);
    }
  };

  const handleDismiss = (e: React.MouseEvent) => {
    e.stopPropagation();
    dismissReminder(reminder.id);
  };

  const handleSnooze = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!crmUser || !businessId) return;

    try {
      const context = createSecurityContextFromParams(
        businessId,
        crmUser.id,
        crmUser.displayName || crmUser.email || 'Unknown User',
        crmUser.role || 'staff',
        crmUser.teamIds,
        crmUser.managedTeamIds,
        crmUser.managerId
      );
      const reminderService = getTaskReminderService();
      const result = await reminderService.snoozeReminder(context, reminder);

      if (result.success) {
        markRead(reminder.id);
        dismissReminder(reminder.id);
      }
    } catch (error) {
      console.error('Error snoozing task:', error);
    }
  };

  const colorClass = getReminderColorClass(reminder.reminderType);
  const relativeTime = formatRelativeTime(reminder.daysUntilDue);

  return (
    <div
      className={`task-reminder-card ${colorClass} ${!reminder.isRead ? 'task-reminder-unread' : ''}`}
      onClick={handleViewTask}
    >
      {!reminder.isRead && <span className="unread-indicator" />}

      <div className="task-reminder-content">
        <div className="task-reminder-header">
          <h4 className="task-reminder-title">{reminder.taskTitle}</h4>
          <span className={`task-reminder-badge ${colorClass}`}>
            {relativeTime}
          </span>
        </div>

        <p className="task-reminder-entity">
          {reminder.entityType.charAt(0).toUpperCase() + reminder.entityType.slice(1)}: {reminder.entityName}
        </p>

        <div className="task-reminder-actions">
          <button
            className="task-reminder-action-btn task-reminder-complete-btn"
            onClick={handleMarkComplete}
            title="Mark complete"
            type="button"
          >
            <svg
              className="task-reminder-action-icon"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 13l4 4L19 7"
              />
            </svg>
            Complete
          </button>

          <button
            className="task-reminder-action-btn task-reminder-dismiss-btn"
            onClick={handleDismiss}
            title="Dismiss"
            type="button"
          >
            <svg
              className="task-reminder-action-icon"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
            Dismiss
          </button>
          <button
            className="task-reminder-action-btn"
            onClick={handleSnooze}
            title="Snooze 24 hours"
            type="button"
          >
            <svg
              className="task-reminder-action-icon"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            Snooze
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================
// Helper Functions
// ============================================

function getEntityPath(entityType: string): string | null {
  switch (entityType) {
    case 'deal':
      return '/deals';
    case 'contact':
      return '/contacts';
    case 'lead':
      return '/leads';
    case 'company':
      return '/companies';
    default:
      return null;
  }
}
