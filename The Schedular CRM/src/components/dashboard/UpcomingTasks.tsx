/**
 * UpcomingTasks Component
 * Tasks due in next 7 days with quick complete checkbox
 *
 * Agent CRM-18 Implementation
 */

import type { SalesActivity } from '../../types/models';
import { evaluateTaskSla } from '../../lib/tasks';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface UpcomingTasksProps {
  /** List of tasks to display */
  tasks: SalesActivity[];
  /** Callback when task is completed */
  onTaskComplete?: (taskId: string) => void;
  /** Determines if the user can complete the task */
  canCompleteTask?: (task: SalesActivity) => boolean;
  /** Optional read-only message when task is not writable */
  getReadOnlyReason?: (task: SalesActivity) => string | undefined;
  /** Callback when task is clicked */
  onTaskClick?: (taskId: string) => void;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format date (e.g., "Today", "Tomorrow", "Mon, Jan 15")
 */
function formatDueDate(date: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const dueDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

  if (dueDate.getTime() === today.getTime()) {
    return 'Today';
  }
  if (dueDate.getTime() === tomorrow.getTime()) {
    return 'Tomorrow';
  }

  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });
}

/**
 * Check if task is overdue
 */
function isOverdue(date: Date): boolean {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dueDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

  return dueDate < today;
}

/**
 * Get entity link text
 */
function getEntityLink(task: SalesActivity): string | null {
  if (task.dealId) return 'Deal';
  if (task.leadId) return 'Lead';
  if (task.clientId) return 'Contact';
  if (task.companyId) return 'Company';
  return null;
}

function getSlaLabel(task: SalesActivity): { label: string; tone: 'ok' | 'warning' | 'danger' } | null {
  const { status, minutesRemaining } = evaluateTaskSla(task);
  switch (status) {
    case 'breached':
      return { label: 'SLA breached', tone: 'danger' };
    case 'atRisk':
      return {
        label:
          minutesRemaining !== undefined && minutesRemaining >= 0
            ? `SLA at risk (${minutesRemaining}m)`
            : 'SLA at risk',
        tone: 'warning',
      };
    case 'ok':
      return { label: 'On track', tone: 'ok' };
    default:
      return null;
  }
}

// ============================================
// Component
// ============================================

/**
 * UpcomingTasks - Tasks due in next 7 days
 *
 * @example
 * ```tsx
 * const { upcomingTasks } = useDashboardData();
 *
 * return (
 *   <UpcomingTasks
 *     tasks={upcomingTasks}
 *     onTaskComplete={(id) => completeTaskMutation(id)}
 *     onTaskClick={(id) => navigate(`/activities/${id}`)}
 *   />
 * );
 * ```
 */
export function UpcomingTasks({
  tasks,
  onTaskComplete,
  canCompleteTask,
  getReadOnlyReason,
  onTaskClick,
  className = '',
}: UpcomingTasksProps) {
  // Sort by due date (soonest first)
  const sortedTasks = [...tasks].sort((a, b) => {
    if (!a.dueDate) return 1;
    if (!b.dueDate) return -1;
    return a.dueDate.getTime() - b.dueDate.getTime();
  });

  return (
    <div className={`upcoming-tasks ${className}`}>
      <div className="upcoming-tasks__header">
        <h2>Upcoming Tasks</h2>
        <p className="upcoming-tasks__subtitle">Next 7 days</p>
      </div>

      <div className="upcoming-tasks__list">
        {sortedTasks.map((task) => {
          const overdue = task.dueDate ? isOverdue(task.dueDate) : false;
          const entityLink = getEntityLink(task);
          const slaLabel = getSlaLabel(task);
          const writable = canCompleteTask ? canCompleteTask(task) : true;
          const readOnlyMessage = writable ? undefined : getReadOnlyReason?.(task);

          return (
            <div
              key={task.id}
              className={`upcoming-task-item ${overdue ? 'upcoming-task-item--overdue' : ''}`}
            >
              <div className="upcoming-task-item__checkbox">
                <input
                  type="checkbox"
                  checked={task.isCompleted}
                  onChange={() => writable && onTaskComplete?.(task.id)}
                  aria-label={`Complete task: ${task.title}`}
                  disabled={!writable}
                  title={readOnlyMessage}
                />
              </div>

              <div
                className="upcoming-task-item__content"
                onClick={() => onTaskClick?.(task.id)}
                role={onTaskClick ? 'button' : undefined}
                tabIndex={onTaskClick ? 0 : undefined}
              >
                <div className="upcoming-task-item__header">
                  <h3 className="upcoming-task-item__title">{task.title}</h3>
                  {task.dueDate && (
                    <span
                      className={`upcoming-task-item__due ${
                        overdue ? 'upcoming-task-item__due--overdue' : ''
                      }`}
                    >
                      {formatDueDate(task.dueDate)}
                    </span>
                  )}
                </div>

                {task.description && (
                  <p className="upcoming-task-item__description">
                    {task.description}
                  </p>
                )}

                <div className="upcoming-task-item__meta">
                  {entityLink && (
                    <span className="upcoming-task-item__entity">{entityLink}</span>
                  )}
                  {task.assigneeName && (
                    <span className="upcoming-task-item__assignee">
                      {task.assigneeName}
                    </span>
                  )}
                  {slaLabel && (
                    <span
                      className={`upcoming-task-item__sla upcoming-task-item__sla--${slaLabel.tone}`}
                    >
                      {slaLabel.label}
                    </span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {sortedTasks.length === 0 && (
        <div className="upcoming-tasks__empty">
          <p>No upcoming tasks</p>
        </div>
      )}
    </div>
  );
}

export default UpcomingTasks;
