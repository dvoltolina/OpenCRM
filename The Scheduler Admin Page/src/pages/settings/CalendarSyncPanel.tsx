import type { IntegrationAccount, CalendarIntegrationProvider } from '../../types/models';
import { IntegrationProviderCard } from './IntegrationProviderCard';
import { CALENDAR_PROVIDER_META } from './providerConfig';

type CalendarSyncPanelProps = {
  lookup: Record<string, IntegrationAccount | undefined>;
  loading: boolean;
  mutationKey: string | null;
  error: string | null;
  onRefreshAll: () => Promise<void>;
  onConnect: (provider: CalendarIntegrationProvider) => Promise<void>;
  onDisconnect: (provider: CalendarIntegrationProvider) => Promise<void>;
  onRefresh: (provider: CalendarIntegrationProvider) => Promise<void>;
};

export function CalendarSyncPanel({
  lookup,
  loading,
  mutationKey,
  error,
  onRefreshAll,
  onConnect,
  onDisconnect,
  onRefresh,
}: CalendarSyncPanelProps) {
  return (
    <section className="panel">
      <header className="panel__header" style={{ display: 'flex', justifyContent: 'space-between', gap: 16 }}>
        <div>
          <p className="eyebrow">Integrations</p>
          <h2>Calendar Sync</h2>
          <p className="muted">
            Connect Google or Microsoft calendars for each staff member. Status reflects the most
            recent sync attempt.
          </p>
        </div>
        <button
          className="button button--ghost"
          type="button"
          onClick={() => onRefreshAll()}
          disabled={loading}
          aria-label="Refresh all calendar integration status"
        >
          Refresh status
        </button>
      </header>

      {error && (
        <div className="note-box" role="status">
          <strong>Heads up:</strong> {error}
        </div>
      )}

      <div className="integration-grid">
        {CALENDAR_PROVIDER_META.map((meta) => (
          <IntegrationProviderCard
            key={meta.id}
            meta={meta}
            integration={lookup[meta.id]}
            loading={loading}
            mutationKey={mutationKey}
            onConnect={onConnect}
            onDisconnect={onDisconnect}
            onRefresh={onRefresh}
            emptyState="No staff calendars connected yet."
          />
        ))}
      </div>
    </section>
  );
}


