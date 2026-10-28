import type { SalesActivity } from '../types/models';

export type TaskSlaStatus = 'none' | 'ok' | 'atRisk' | 'breached' | 'met';

export interface TaskSlaState {
  status: TaskSlaStatus;
  target?: Date;
  minutesRemaining?: number;
}

/**
  * Compute SLA status for a task.
  * Prioritises slaAt, then dueDate. Completed tasks return "met".
  */
export function evaluateTaskSla(task: SalesActivity, now: Date = new Date()): TaskSlaState {
  if (task.type !== 'task') {
    return { status: 'none' };
  }

  if (task.isCompleted) {
    return { status: 'met', target: task.slaAt || task.dueDate };
  }

  const target = task.slaAt || task.dueDate;
  if (!target) {
    return { status: 'none' };
  }

  const targetMs = target.getTime();
  const diffMinutes = Math.floor((targetMs - now.getTime()) / 60000);

  if (diffMinutes < 0) {
    return { status: 'breached', target, minutesRemaining: diffMinutes };
  }

  // Consider tasks at-risk inside the last 2 hours or inside the last 20% of the SLA window.
  const slaWindowMinutes = task.slaMinutes || Math.ceil((targetMs - (task.createdAt?.getTime?.() ?? now.getTime())) / 60000);
  const atRiskThreshold = Math.max(30, Math.min(120, Math.floor(slaWindowMinutes * 0.2)));

  if (diffMinutes <= atRiskThreshold) {
    return { status: 'atRisk', target, minutesRemaining: diffMinutes };
  }

  return { status: 'ok', target, minutesRemaining: diffMinutes };
}
