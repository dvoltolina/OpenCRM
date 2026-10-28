import type { CalendarSyncMapping } from '../../types/calendar-sync';

interface ConflictResolverProps {
  conflicts: CalendarSyncMapping[];
  onResolve: (mappingId: string, resolution: 'use_crm' | 'use_calendar') => Promise<void>;
}

export function ConflictResolver({ conflicts, onResolve }: ConflictResolverProps) {
  if (!conflicts.length) {
    return null;
  }

  return (
    <div className="conflict-resolver">
      <div className="conflict-resolver__header">
        <h4>Calendar Conflicts</h4>
        <p className="text-muted">Choose which version to keep for each event.</p>
      </div>
      <ul className="conflict-resolver__list">
        {conflicts.map((conflict) => (
          <li key={conflict.id} className="conflict-resolver__item">
            <div>
              <div className="conflict-resolver__title">Activity {conflict.activityId}</div>
              <div className="text-muted">Provider: {conflict.provider}</div>
            </div>
            <div className="conflict-resolver__actions">
              <button
                type="button"
                className="btn btn--secondary btn--sm"
                onClick={() => onResolve(conflict.id, 'use_crm')}
              >
                Use CRM
              </button>
              <button
                type="button"
                className="btn btn--ghost btn--sm"
                onClick={() => onResolve(conflict.id, 'use_calendar')}
              >
                Use calendar
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default ConflictResolver;
