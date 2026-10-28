import type { StaffIntegrationRow } from '../../hooks/useIntegrationsPanel';
import {
  CALENDAR_SELECT_OPTIONS,
  TELEHEALTH_SELECT_OPTIONS,
} from './providerConfig';

type StaffUpdateHandler<T> = (staffId: string, value: T) => Promise<void>;

type StaffIntegrationsPanelProps = {
  rows: StaffIntegrationRow[];
  loading: boolean;
  mutationKey: string | null;
  onUpdateCalendar: StaffUpdateHandler<StaffIntegrationRow['calendarProvider']>;
  onUpdateTelehealth: StaffUpdateHandler<StaffIntegrationRow['telehealthProvider']>;
};

export function StaffIntegrationsPanel({
  rows,
  loading,
  mutationKey,
  onUpdateCalendar,
  onUpdateTelehealth,
}: StaffIntegrationsPanelProps) {
  return (
    <section className="panel">
      <header className="panel__header">
        <div>
          <p className="eyebrow">Assignments</p>
          <h2>Staff Provider Mapping</h2>
          <p className="muted">
            Choose which calendar and telehealth provider each staff member uses by default.
          </p>
        </div>
      </header>

      {rows.length === 0 ? (
        <p className="muted">No staff members found. Invite staff to configure integrations.</p>
      ) : (
        <div className="table">
          <div className="table__head">
            <span>Staff</span>
            <span>Calendar</span>
            <span>Telehealth</span>
          </div>
          {rows.map((row) => {
            const busy = loading || mutationKey === `staff:${row.id}`;
            return (
              <div className="table__row" key={row.id}>
                <div>
                  <div className="panel__title">{row.name}</div>
                  <span className="badge badge--neutral">{row.role}</span>
                </div>
                <select
                  value={row.calendarProvider}
                  onChange={(event) =>
                    onUpdateCalendar(row.id, event.target.value as StaffIntegrationRow['calendarProvider'])
                  }
                  disabled={busy}
                  aria-label={`Calendar provider for ${row.name}`}
                >
                  {CALENDAR_SELECT_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <select
                  value={row.telehealthProvider}
                  onChange={(event) =>
                    onUpdateTelehealth(
                      row.id,
                      event.target.value as StaffIntegrationRow['telehealthProvider'],
                    )
                  }
                  disabled={busy}
                  aria-label={`Telehealth provider for ${row.name}`}
                >
                  {TELEHEALTH_SELECT_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}

