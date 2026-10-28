import type { WaitlistEntryStatus, WaitlistPriority } from '../../types/models';

export function StatusBadge({ status }: { status: WaitlistEntryStatus }) {
  const tone =
    status === 'active'
      ? 'badge--info'
      : status === 'notified'
        ? 'badge--neutral'
        : status === 'converted'
          ? 'badge--success'
          : 'badge--warn';

  return <span className={`badge ${tone}`}>{status}</span>;
}

export function PriorityBadge({ priority }: { priority: WaitlistPriority }) {
  const tone = priority === 'vip' ? 'badge--warn' : 'badge--neutral';
  return <span className={`badge ${tone}`}>{priority.toUpperCase()}</span>;
}


