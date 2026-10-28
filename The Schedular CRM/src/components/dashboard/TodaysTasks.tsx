/**
 * TodaysTasks Component
 * "Who do I call today?" widget for sales reps (Hunter View)
 */

import type { SalesActivity } from '../../types/models';

export interface TodaysTasksProps {
  /** Tasks for today */
  tasks: SalesActivity[];
  /** Called when a task is clicked */
  onTaskClick?: (task: SalesActivity) => void;
  /** Called when complete is clicked */
  onTaskComplete?: (taskId: string) => void;
  /** Check if user can complete task */
  canCompleteTask?: (task: SalesActivity) => boolean;
  /** Whether mutations are in progress */
  isLoading?: boolean;
}

function formatTime(date?: Date) {
  if (!date) return '';
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

export function TodaysTasks({
  tasks,
  onTaskClick,
  onTaskComplete,
  canCompleteTask,
  isLoading = false,
}: TodaysTasksProps) {
  // Sort by due time, overdue first
  const sortedTasks = [...tasks].sort((a, b) => {
    const aTime = a.dueDate?.getTime() || 0;
    const bTime = b.dueDate?.getTime() || 0;
    return aTime - bTime;
  });

  const overdueTasks = sortedTasks.filter(
    (t) => t.dueDate && t.dueDate < new Date() && !t.isCompleted
  );
  const upcomingTasks = sortedTasks.filter(
    (t) => !t.isCompleted && (!t.dueDate || t.dueDate >= new Date())
  );
  const completedTasks = sortedTasks.filter((t) => t.isCompleted);

  const getTaskIcon = (task: SalesActivity) => {
    switch (task.type) {
      case 'call':
        return '📞';
      case 'email':
        return '📧';
      case 'meeting':
        return '📅';
      default:
        return '✅';
    }
  };

  const renderTask = (task: SalesActivity, isOverdue: boolean = false) => {
    const canComplete = canCompleteTask ? canCompleteTask(task) : true;

    return (
      <div
        key={task.id}
        className={`todays-task ${isOverdue ? 'todays-task--overdue' : ''} ${task.isCompleted ? 'todays-task--completed' : ''}`}
      >
        <button
          type="button"
          className="todays-task__checkbox"
          onClick={() => onTaskComplete?.(task.id)}
          disabled={isLoading || !canComplete}
          title={task.isCompleted ? 'Mark incomplete' : 'Mark complete'}
        >
          {task.isCompleted ? '✓' : '○'}
        </button>
        <button
          type="button"
          className="todays-task__content"
          onClick={() => onTaskClick?.(task)}
        >
          <span className="todays-task__icon">{getTaskIcon(task)}</span>
          <div className="todays-task__info">
            <span className="todays-task__title">{task.title}</span>
            {task.dueDate && (
              <span className="todays-task__time">
                {isOverdue ? 'Overdue • ' : ''}
                {formatTime(task.dueDate)}
              </span>
            )}
          </div>
        </button>
      </div>
    );
  };

  if (tasks.length === 0) {
    return (
      <div className="todays-tasks todays-tasks--empty">
        <div className="todays-tasks__header">
          <h3>Today's Tasks</h3>
        </div>
        <div className="todays-tasks__empty-state">
          <span className="todays-tasks__empty-icon">🎯</span>
          <p>No tasks scheduled for today</p>
          <p className="todays-tasks__empty-hint">Time to prospect!</p>
        </div>
      </div>
    );
  }

  return (
    <div className="todays-tasks">
      <div className="todays-tasks__header">
        <h3>Who do I call today?</h3>
        <span className="todays-tasks__count">
          {upcomingTasks.length + overdueTasks.length} pending
        </span>
      </div>

      {overdueTasks.length > 0 && (
        <div className="todays-tasks__section todays-tasks__section--overdue">
          <span className="todays-tasks__section-label">⚠️ Overdue</span>
          {overdueTasks.map((task) => renderTask(task, true))}
        </div>
      )}

      {upcomingTasks.length > 0 && (
        <div className="todays-tasks__section">
          <span className="todays-tasks__section-label">📋 Today</span>
          {upcomingTasks.slice(0, 5).map((task) => renderTask(task))}
          {upcomingTasks.length > 5 && (
            <p className="todays-tasks__more">
              +{upcomingTasks.length - 5} more tasks
            </p>
          )}
        </div>
      )}

      {completedTasks.length > 0 && (
        <div className="todays-tasks__section todays-tasks__section--completed">
          <span className="todays-tasks__section-label">
            ✅ Completed ({completedTasks.length})
          </span>
        </div>
      )}
    </div>
  );
}

export default TodaysTasks;
