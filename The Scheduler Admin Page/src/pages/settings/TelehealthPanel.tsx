import type {
  IntegrationAccount,
  TelehealthFallbackOption,
  TelehealthProvider,
  TelehealthSettings,
} from '../../types/models';
import type { ServiceTelehealthPreference } from '../../hooks/useIntegrationsPanel';
import { IntegrationProviderCard } from './IntegrationProviderCard';
import {
  TELEHEALTH_PROVIDER_META,
  TELEHEALTH_SELECT_OPTIONS,
} from './providerConfig';

type TelehealthPanelProps = {
  lookup: Record<string, IntegrationAccount | undefined>;
  loading: boolean;
  mutationKey: string | null;
  settings: TelehealthSettings | null;
  services: ServiceTelehealthPreference[];
  onConnect: (provider: TelehealthProvider) => Promise<void>;
  onDisconnect: (provider: TelehealthProvider) => Promise<void>;
  onRefresh: (provider: TelehealthProvider) => Promise<void>;
  onSetDefault: (provider: TelehealthProvider) => Promise<void>;
  onSetFallback: (provider: TelehealthFallbackOption) => Promise<void>;
  onRequireLink: (enabled: boolean) => Promise<void>;
  onServiceProviderChange: (
    serviceId: string,
    provider: TelehealthProvider | 'default',
  ) => Promise<void>;
};

export function TelehealthPanel({
  lookup,
  loading,
  mutationKey,
  settings,
  services,
  onConnect,
  onDisconnect,
  onRefresh,
  onSetDefault,
  onSetFallback,
  onRequireLink,
  onServiceProviderChange,
}: TelehealthPanelProps) {
  const telehealthBusy = mutationKey === 'telehealth' || loading;

  return (
    <section className="panel">
      <header className="panel__header" style={{ display: 'flex', justifyContent: 'space-between', gap: 16 }}>
        <div>
          <p className="eyebrow">Telehealth</p>
          <h2>Zoom &amp; Google Meet</h2>
          <p className="muted">
            Control which providers generate meeting links plus fallback rules for when video is
            disabled.
          </p>
        </div>
      </header>

      <div className="integration-grid">
        {TELEHEALTH_PROVIDER_META.map((meta) => (
          <IntegrationProviderCard
            key={meta.id}
            meta={meta}
            integration={lookup[meta.id]}
            loading={loading}
            mutationKey={mutationKey}
            onConnect={onConnect}
            onDisconnect={onDisconnect}
            onRefresh={onRefresh}
            emptyState="Connect to auto-generate telehealth links for booked sessions."
          />
        ))}
      </div>

      <div className="telehealth-defaults">
        <div className="grid grid--2">
          <div className="field">
            <label htmlFor="default-telehealth-provider">Default meeting provider</label>
            <select
              id="default-telehealth-provider"
              value={settings?.defaultProvider ?? 'zoom'}
              onChange={(event) => onSetDefault(event.target.value as TelehealthProvider)}
              disabled={telehealthBusy}
              aria-describedby="default-provider-description"
            >
              <option value="zoom">Zoom</option>
              <option value="googleMeet">Google Meet</option>
            </select>
            <p id="default-provider-description">Used for services and staff who defer to the default.</p>
          </div>

          <div className="field">
            <label htmlFor="telehealth-fallback">Fallback option</label>
            <select
              id="telehealth-fallback"
              value={settings?.fallbackProvider ?? 'phone'}
              onChange={(event) =>
                onSetFallback(event.target.value as TelehealthFallbackOption)
              }
              disabled={telehealthBusy}
              aria-describedby="fallback-description"
            >
              <option value="phone">Phone call</option>
              <option value="in_person">In person</option>
            </select>
            <p id="fallback-description">Shown when a telehealth link is unavailable or video is disabled.</p>
          </div>
        </div>

        <label className="field" style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <input
            type="checkbox"
            checked={settings?.requireLink ?? true}
            onChange={(event) => onRequireLink(event.target.checked)}
            disabled={telehealthBusy}
            aria-label="Require telehealth link on video appointments"
          />
          Require telehealth link on video appointments
        </label>
      </div>

      <div>
        <div className="panel__subheader">
          <div className="panel__title">Per-service defaults</div>
          <p className="muted">Override the default provider for specific services.</p>
        </div>

        {services.length === 0 ? (
          <p className="muted">No services found yet. Add services to customize telehealth rules.</p>
        ) : (
          <div className="table">
            <div className="table__head">
              <span>Service</span>
              <span>Telehealth provider</span>
            </div>
            {services.map((service) => {
              const busy = mutationKey === `service:${service.id}` || loading;
              return (
                <div className="table__row" key={service.id}>
                  <span>{service.name}</span>
                  <select
                    value={service.provider}
                    onChange={(event) =>
                      onServiceProviderChange(
                        service.id,
                        event.target.value as TelehealthProvider | 'default',
                      )
                    }
                    disabled={busy}
                    aria-label={`Telehealth provider for ${service.name}`}
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
      </div>
    </section>
  );
}


