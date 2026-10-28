import type { IntegrationAccount } from '../../types/models';
import { PROVIDER_STATUS_META, type ProviderMeta } from './providerConfig';

type IntegrationProviderCardProps<T extends string> = {
  meta: ProviderMeta<T>;
  integration?: IntegrationAccount;
  mutationKey: string | null;
  loading: boolean;
  onConnect: (provider: T) => Promise<void>;
  onDisconnect: (provider: T) => Promise<void>;
  onRefresh: (provider: T) => Promise<void>;
  emptyState?: string;
};

export function IntegrationProviderCard<T extends string>({
  meta,
  integration,
  mutationKey,
  loading,
  onConnect,
  onDisconnect,
  onRefresh,
  emptyState,
}: IntegrationProviderCardProps<T>) {
  const status = integration?.status ?? 'disconnected';
  const statusMeta = PROVIDER_STATUS_META[status];
  const busy = loading || mutationKey === `provider:${meta.id}`;

  const primaryLabel =
    status === 'connected' ? 'Disconnect' : status === 'error' ? 'Reconnect' : 'Connect';
  const primaryAction =
    status === 'connected'
      ? () => onDisconnect(meta.id)
      : () => onConnect(meta.id);

  return (
    <div className="integration-card">
      <div>
        <div className="panel__title">{meta.name}</div>
        <p className="muted">{meta.description}</p>
      </div>

      <div className="integration-card__status">
        <span className={`badge ${statusMeta.tone}`}>{statusMeta.label}</span>
        <span className="muted">
          Last sync:{' '}
          {integration?.lastSyncAt ? formatTimestamp(integration.lastSyncAt) : 'Not synced yet'}
        </span>
      </div>

      {integration?.connectedEmail ? (
        <p className="muted">Connected as {integration.connectedEmail}</p>
      ) : (
        <p className="muted">
          {emptyState ?? 'Nothing connected yet. Use the button below to start.'}
        </p>
      )}

      <div className="integration-card__actions">
        <button
          className={`button ${
            status === 'connected' ? 'button--ghost' : 'button--primary'
          }`}
          type="button"
          onClick={primaryAction}
          disabled={busy}
          aria-label={`${primaryLabel} ${meta.name}`}
        >
          {primaryLabel}
        </button>

        {status === 'connected' && (
          <button
            className="button button--primary"
            type="button"
            onClick={() => onRefresh(meta.id)}
            disabled={busy}
            aria-label={`Refresh ${meta.name} token`}
          >
            Refresh token
          </button>
        )}
      </div>
    </div>
  );
}

function formatTimestamp(isoDate: string) {
  const parsed = new Date(isoDate);
  if (Number.isNaN(parsed.getTime())) {
    return 'Unknown';
  }
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(parsed);
}

