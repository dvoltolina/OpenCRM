import type { SalesActivity } from '../../types/models';
import { evaluateTaskSla } from '../../lib/tasks';

export function getActivityIcon(type: SalesActivity['type']): string {
  const icons = {
    call: '📞',
    email: '📧',
    meeting: '📅',
    note: '📝',
    task: '✓',
  };
  return icons[type] || '•';
}

export function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString();
}

export function formatDateTimeLocal(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours()
  )}:${pad(date.getMinutes())}`;
}

export function formatSlaLabel(activity: SalesActivity): { label: string; tone: string } | null {
  if (activity.type !== 'task') return null;
  const { status, target, minutesRemaining } = evaluateTaskSla(activity);
  const dueLabel = target ? target.toLocaleDateString() : '';

  switch (status) {
    case 'met':
      return { label: 'SLA met', tone: 'success' };
    case 'breached':
      return { label: `SLA breached${dueLabel ? ` (${dueLabel})` : ''}`, tone: 'danger' };
    case 'atRisk':
      return {
        label: `SLA at risk${minutesRemaining !== undefined ? ` (${minutesRemaining}m)` : ''}`,
        tone: 'warning',
      };
    case 'ok':
      return { label: 'On track', tone: 'default' };
    default:
      return null;
  }
}
