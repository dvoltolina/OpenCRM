import { useDemoGuard } from '../../hooks/useDemoGuard';
import type { ApiKey, Integration, WebhookEndpoint } from '../../types/integrations';

type TabType = 'connected' | 'available' | 'api_keys' | 'webhooks';

interface AvailableIntegration {
  id: string;
  name: string;
  description: string;
  provider: string;
  icon: string;
}

interface DemoIntegrationsPanelsProps {
  activeTab: TabType;
  apiKeys: ApiKey[];
  availableIntegrations: AvailableIntegration[];
  connectedIntegrations: Integration[];
  errorIntegrations: Integration[];
  onBrowseAvailable: () => void;
  webhookEndpoints: WebhookEndpoint[];
}

function IntegrationSummaryCard({
  description,
  label,
  value,
}: {
  description: string;
  label: string;
  value: string;
}) {
  return (
    <div className="card soft">
      <div className="card-body">
        <div className="text-muted">{label}</div>
        <div style={{ fontSize: '20px', fontWeight: 700 }}>{value}</div>
        <p className="text-muted">{description}</p>
      </div>
    </div>
  );
}

export function DemoIntegrationsPanels({
  activeTab,
  apiKeys,
  availableIntegrations,
  connectedIntegrations,
  errorIntegrations,
  onBrowseAvailable,
  webhookEndpoints,
}: DemoIntegrationsPanelsProps) {
  const { notifyBlocked } = useDemoGuard();

  if (activeTab === 'connected') {
    if (connectedIntegrations.length === 0 && errorIntegrations.length === 0) {
      return (
        <div className="integrations-page__empty">
          <p>No live integrations are connected in this demo tenant.</p>
          <button type="button" className="btn btn-primary" onClick={onBrowseAvailable}>
            Browse Available Integrations
          </button>
        </div>
      );
    }

    return (
      <div className="integrations-page__section">
        <div className="integrations-page__grid">
          {[...errorIntegrations, ...connectedIntegrations].map((integration) => (
            <div key={integration.id} className="card soft">
              <div className="card-body">
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px' }}>
                  <div>
                    <h3>{integration.name}</h3>
                    <p className="text-muted">{integration.description || integration.provider}</p>
                  </div>
                  <span className="badge">
                    {integration.status === 'active' ? 'Active' : integration.status}
                  </span>
                </div>
                <p className="text-muted" style={{ marginTop: '12px' }}>
                  Last sync:{' '}
                  {integration.lastSyncAt
                    ? new Date(integration.lastSyncAt).toLocaleDateString()
                    : 'Not yet synced'}
                </p>
                {integration.lastErrorMessage && (
                  <p className="text-muted" style={{ marginTop: '8px' }}>
                    {integration.lastErrorMessage}
                  </p>
                )}
                <button
                  type="button"
                  className="btn btn-secondary"
                  style={{ marginTop: '12px' }}
                  onClick={() =>
                    notifyBlocked({ action: 'integration-manage', message: 'Integration changes are disabled in demo mode.' })
                  }
                >
                  Manage Connection
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (activeTab === 'available') {
    return (
      <div className="integrations-page__section">
        <div className="integrations-page__grid">
          {availableIntegrations.map((provider) => (
            <div key={provider.id} className="card soft">
              <div className="card-body">
                <div style={{ fontSize: '28px' }}>{provider.icon}</div>
                <h3 style={{ marginTop: '8px' }}>{provider.name}</h3>
                <p className="text-muted">{provider.description}</p>
                <button
                  type="button"
                  className="btn btn-primary"
                  style={{ marginTop: '12px' }}
                  onClick={() =>
                    notifyBlocked({ action: 'oauth-connect', message: 'OAuth connections are disabled in demo mode.' })
                  }
                >
                  Preview Connection Flow
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (activeTab === 'api_keys') {
    return (
      <div className="integrations-page__section">
        <div className="integrations-page__grid">
          <IntegrationSummaryCard
            label="Active keys"
            value={String(apiKeys.filter((key) => key.isActive).length)}
            description="Keys are seeded for exploration only. Creation and revocation are disabled."
          />
          <IntegrationSummaryCard
            label="Scopes shown"
            value={String(apiKeys.reduce((count, key) => count + key.scopes.length, 0))}
            description="Permissions are visible so buyers can review API surface area."
          />
        </div>
        <div className="card soft" style={{ marginTop: '16px' }}>
          <div className="card-body">
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
              <h3>API Keys</h3>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() =>
                  notifyBlocked({ action: 'api-key-create', message: 'API key creation is disabled in demo mode.' })
                }
              >
                Create API Key
              </button>
            </div>
            {apiKeys.length === 0 ? (
              <p className="text-muted" style={{ marginTop: '12px' }}>
                No demo API keys are seeded.
              </p>
            ) : (
              <div style={{ marginTop: '12px', display: 'grid', gap: '12px' }}>
                {apiKeys.map((key) => (
                  <div key={key.id} className="card">
                    <div className="card-body">
                      <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
                        <div>
                          <strong>{key.name}</strong>
                          <div className="text-muted">{key.keyPrefix}...</div>
                        </div>
                        <span className="badge">{key.isActive ? 'Active' : 'Inactive'}</span>
                      </div>
                      <p className="text-muted" style={{ marginTop: '8px' }}>
                        {key.scopes.join(', ')}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="integrations-page__section">
      <div className="integrations-page__grid">
        <IntegrationSummaryCard
          label="Configured endpoints"
          value={String(webhookEndpoints.length)}
          description="Endpoint metadata is visible. Secret rotation, testing, and deletes are disabled."
        />
        <IntegrationSummaryCard
          label="Active endpoints"
          value={String(webhookEndpoints.filter((endpoint) => endpoint.isActive).length)}
          description="Webhook delivery actions are blocked to keep the demo tenant read-only."
        />
      </div>
      <div className="card soft" style={{ marginTop: '16px' }}>
        <div className="card-body">
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
            <h3>Webhook Endpoints</h3>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() =>
                notifyBlocked({ action: 'webhook-create', message: 'Webhook management is disabled in demo mode.' })
              }
            >
              Add Webhook
            </button>
          </div>
          {webhookEndpoints.length === 0 ? (
            <p className="text-muted" style={{ marginTop: '12px' }}>
              No demo webhooks are seeded.
            </p>
          ) : (
            <div style={{ marginTop: '12px', display: 'grid', gap: '12px' }}>
              {webhookEndpoints.map((endpoint) => (
                <div key={endpoint.id} className="card">
                  <div className="card-body">
                    <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
                      <div>
                        <strong>{endpoint.name}</strong>
                        <p className="text-muted">{endpoint.url}</p>
                      </div>
                      <span className="badge">{endpoint.isActive ? 'Active' : 'Inactive'}</span>
                    </div>
                    <p className="text-muted" style={{ marginTop: '8px' }}>
                      {endpoint.events.join(', ')}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
