/**
 * IntegrationsPage Component
 * Main integration hub for managing API keys, webhooks, and third-party connections.
 *
 * HIPAA Compliance:
 * - All integration access is logged via audit service
 * - Access restricted to admin/owner roles only (RBAC)
 * - No PHI in error messages
 * - API keys and secrets never displayed after creation
 *
 * Security:
 * - RBAC enforced: Only admin/owner can access
 * - Full keys/secrets shown only once on creation
 * - All changes logged for audit trail
 *
 * Agent CRM - API Integrations Task 10 Implementation
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../hooks/usePipeline';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import { IntegrationCard } from '../components/integrations/IntegrationCard';
import { WebhookManager } from '../components/integrations/WebhookManager';
import { WebhookDeliveryLog } from '../components/integrations/WebhookDeliveryLog';
import { ApiKeyManager } from '../components/integrations/ApiKeyManager';
import { ApiUsageChart } from '../components/integrations/ApiUsageChart';
import { DemoIntegrationsPanels } from '../components/integrations/DemoIntegrationsPanels';
import { OAuthConnector } from '../components/integrations/OAuthConnector';
import { CalendarSyncPanel } from '../components/calendar-sync/CalendarSyncPanel';
import { getFeatureFlags } from '../config/features';
import { isDemoMode } from '../config/demo';
import type { Integration, WebhookEndpoint, ApiKey } from '../types/integrations';
import type { SecurityContext } from '../data/repositories/repository-types';
import { getIntegrationRepository } from '../data/repositories/integration-repository';
import { getWebhookEndpointRepository } from '../data/repositories/webhook-endpoint-repository';
import { getApiKeyRepository } from '../data/repositories/api-key-repository';
import '../components/integrations/integrations.css';

// ============================================
// Types
// ============================================

type TabType = 'connected' | 'available' | 'api_keys' | 'webhooks';

const TAB_META: Record<TabType, { label: string; description: string }> = {
  connected: {
    label: 'Connected',
    description: 'Active and failing integrations currently attached to the workspace.',
  },
  available: {
    label: 'Available',
    description: 'OAuth and provider integrations that can be connected next.',
  },
  api_keys: {
    label: 'API Keys',
    description: 'External API credentials and current usage footprint.',
  },
  webhooks: {
    label: 'Webhooks',
    description: 'Outbound delivery endpoints and recent webhook activity.',
  },
};

// ============================================
// Main Component
// ============================================

/**
 * IntegrationsPage - Integration hub and dashboard
 *
 * Features:
 * - View all connected integrations with status
 * - Connect new integrations via OAuth
 * - Manage API keys for external access
 * - Configure webhook endpoints
 * - View delivery logs and usage analytics
 *
 * Security:
 * - Access restricted to admin/owner roles only
 * - All operations logged for audit trail
 * - Secrets never displayed after creation
 *
 * @example
 * ```tsx
 * // Used as a route component
 * <Route path="/integrations" element={<IntegrationsPage />} />
 * ```
 */
export function IntegrationsPage() {
  const { businessId, crmUser } = useAuth();
  const userId = crmUser?.id ?? null;
  const userName = crmUser?.displayName ?? null;
  const userRole = crmUser?.role ?? null;
  const integrationRepo = useMemo(() => getIntegrationRepository(), []);
  const webhookRepo = useMemo(() => getWebhookEndpointRepository(), []);
  const apiKeyRepo = useMemo(() => getApiKeyRepository(), []);
  const features = useMemo(() => getFeatureFlags(), []);

  // Create security context from auth state
  const securityContext = useMemo<SecurityContext | null>(() => {
    if (!businessId || !userId || !userName || !userRole) return null;
    return createSecurityContext(
      businessId,
      userId,
      userName,
      userRole
    );
  }, [businessId, userId, userName, userRole]);

  // State
  const [activeTab, setActiveTab] = useState<TabType>('connected');
  const [integrations, setIntegrations] = useState<Integration[]>([]);
  const [webhookEndpoints, setWebhookEndpoints] = useState<WebhookEndpoint[]>([]);
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const availableTabs = useMemo<TabType[]>(
    () => [
      'connected',
      'available',
      ...(features.enableApi ? (['api_keys'] as const) : []),
      ...(features.enableWebhooks ? (['webhooks'] as const) : []),
    ],
    [features.enableApi, features.enableWebhooks]
  );

  // Check RBAC - only admin/owner can access
  const canAccess = useMemo(() => {
    if (!userRole) return false;
    return userRole === 'admin' || userRole === 'owner';
  }, [userRole]);

  useEffect(() => {
    if (!availableTabs.includes(activeTab)) {
      setActiveTab(availableTabs[0] ?? 'connected');
    }
  }, [activeTab, availableTabs]);

  // Load data on mount
  useEffect(() => {
    async function loadData() {
      if (!securityContext || !canAccess) {
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        // Load all data in parallel
        const [integrationsResult, webhooksResult, keysResult] = await Promise.all([
          integrationRepo.getAll(securityContext),
          webhookRepo.getAll(securityContext),
          apiKeyRepo.getAll(securityContext),
        ]);

        if (integrationsResult.success) {
          setIntegrations(integrationsResult.data.data);
        }
        if (webhooksResult.success) {
          setWebhookEndpoints(webhooksResult.data.data);
        }
        if (keysResult.success) {
          setApiKeys(keysResult.data.data);
        }
      } catch {
        setError('Failed to load integration data');
      } finally {
        setIsLoading(false);
      }
    }

    loadData();
  }, [securityContext, canAccess, integrationRepo, webhookRepo, apiKeyRepo]);

  // Handlers
  const handleRefresh = useCallback(async () => {
    if (!securityContext || !canAccess) return;

    setIsLoading(true);
    setError(null);

    try {
      const [integrationsResult, webhooksResult, keysResult] = await Promise.all([
        integrationRepo.getAll(securityContext),
        webhookRepo.getAll(securityContext),
        apiKeyRepo.getAll(securityContext),
      ]);

      if (integrationsResult.success) setIntegrations(integrationsResult.data.data);
      if (webhooksResult.success) setWebhookEndpoints(webhooksResult.data.data);
      if (keysResult.success) setApiKeys(keysResult.data.data);
    } catch {
      setError('Failed to refresh data');
    } finally {
      setIsLoading(false);
    }
  }, [securityContext, canAccess, integrationRepo, webhookRepo, apiKeyRepo]);

  // Filter integrations by status
  const connectedIntegrations = useMemo(
    () => integrations.filter((i) => i.status === 'active'),
    [integrations]
  );

  const errorIntegrations = useMemo(
    () => integrations.filter((i) => i.status === 'error'),
    [integrations]
  );
  const activeApiKeys = useMemo(
    () => apiKeys.filter((key) => key.isActive),
    [apiKeys]
  );
  const activeWebhooks = useMemo(
    () => webhookEndpoints.filter((endpoint) => endpoint.isActive),
    [webhookEndpoints]
  );

  // Available integrations (hardcoded for now)
  const availableIntegrations = useMemo(
    () => [
      {
        id: 'zapier',
        name: 'Zapier',
        description: 'Connect with 5000+ apps',
        provider: 'zapier',
        icon: '⚡',
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Get notifications in Slack',
        provider: 'slack',
        icon: '💬',
      },
      {
        id: 'salesforce',
        name: 'Salesforce',
        description: 'Sync with Salesforce CRM',
        provider: 'salesforce',
        icon: '☁️',
      },
      {
        id: 'hubspot',
        name: 'HubSpot',
        description: 'Sync with HubSpot CRM',
        provider: 'hubspot',
        icon: '🧡',
      },
    ],
    []
  );
  const activeTabMeta = TAB_META[activeTab];

  const renderTabButton = (tab: TabType, count?: number) => {
    if (!availableTabs.includes(tab)) {
      return null;
    }

    return (
      <button
        key={tab}
        type="button"
        className={`integrations-page__tab ${activeTab === tab ? 'integrations-page__tab--active' : ''}`}
        onClick={() => setActiveTab(tab)}
      >
        {TAB_META[tab].label}
        {count && count > 0 ? (
          <span className="integrations-page__tab-badge">{count}</span>
        ) : null}
      </button>
    );
  };

  // Access denied UI
  if (!canAccess) {
    return (
      <PageLayout width="wide" className="integrations-page integrations-page--access-denied">
        <PageHeader
          eyebrow="Connections"
          title="Integrations"
          subtitle="Only owners and admins can manage external integrations, API keys, and webhooks."
        />
        <Card padding="lg">
          <EmptyState
            eyebrow="Restricted"
            title="Access denied"
            description="Only administrators and owners can access this workspace surface."
          />
        </Card>
      </PageLayout>
    );
  }

  // Loading state
  if (isLoading && integrations.length === 0) {
    return (
      <PageLayout width="wide" className="integrations-page integrations-page--loading">
        <PageHeader
          eyebrow="Connections"
          title="Integrations"
          subtitle="Loading workspace integration state, API access, and webhook metadata."
        />
        <Card className="integrations-page__status-card" padding="lg">
          <p>Loading integrations...</p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="integrations-page">
      <PageHeader
        eyebrow="Connections"
        title="Integrations"
        subtitle="Manage provider connections, external API access, and outbound delivery endpoints from one audited workspace surface."
        actions={(
          <Button variant="secondary" onClick={handleRefresh} disabled={isLoading}>
            Refresh
          </Button>
        )}
      />

      <Card className="integrations-page__overview" padding="lg" tone="accent">
        <div className="integrations-page__overview-copy">
          <p className="ui-empty-state__eyebrow">Workspace Health</p>
          <h2>{activeTabMeta.label}</h2>
          <p>{activeTabMeta.description}</p>
        </div>
        <div className="integrations-page__overview-stats">
          <div>
            <span>Connected</span>
            <strong>{connectedIntegrations.length}</strong>
          </div>
          <div>
            <span>Errors</span>
            <strong>{errorIntegrations.length}</strong>
          </div>
          <div>
            <span>API keys</span>
            <strong>{activeApiKeys.length}</strong>
          </div>
          <div>
            <span>Webhooks</span>
            <strong>{activeWebhooks.length}</strong>
          </div>
        </div>
      </Card>

      {/* Error Banner */}
      {error && (
        <Card className="integrations-page__error-banner" padding="md">
          <span>{error}</span>
          <button
            type="button"
            className="integrations-page__error-close"
            onClick={() => setError(null)}
          >
            Close
          </button>
        </Card>
      )}

      <Card className="integrations-page__tabs-card" padding="md">
        <Toolbar
          start={(
            <div className="integrations-page__tabs">
              {renderTabButton('connected', connectedIntegrations.length)}
              {renderTabButton('available')}
              {renderTabButton('api_keys', activeApiKeys.length)}
              {renderTabButton('webhooks', activeWebhooks.length)}
            </div>
          )}
          end={<span className="ui-results-count">{availableTabs.length} sections available</span>}
        />
      </Card>

      {/* Tab Content */}
      <main className="integrations-page__content">
        {isDemoMode ? (
          <DemoIntegrationsPanels
            activeTab={activeTab}
            apiKeys={apiKeys}
            availableIntegrations={availableIntegrations}
            connectedIntegrations={connectedIntegrations}
            errorIntegrations={errorIntegrations}
            onBrowseAvailable={() => setActiveTab('available')}
            webhookEndpoints={webhookEndpoints}
          />
        ) : (
          <>
            {activeTab === 'connected' && (
              <div className="integrations-page__section">
                {features.enableCalendarSync && (
                  <Card className="integrations-page__subsection" padding="lg" tone="subtle">
                    <div className="integrations-page__subsection-header">
                      <div>
                        <p className="ui-empty-state__eyebrow">Calendar Sync</p>
                        <h2 className="integrations-page__subsection-title">Scheduling connections</h2>
                        <p className="integrations-page__subsection-copy">
                          Sync CRM activities with Google or Outlook calendars. OAuth tokens stay
                          encrypted in Cloud Functions; attendee emails and event bodies are not stored.
                        </p>
                      </div>
                    </div>
                    <CalendarSyncPanel />
                  </Card>
                )}

                {errorIntegrations.length > 0 && (
                  <section className="integrations-page__subsection">
                    <div className="integrations-page__subsection-header">
                      <div>
                        <p className="ui-empty-state__eyebrow">Attention</p>
                        <h2 className="integrations-page__subsection-title">Action required</h2>
                        <p className="integrations-page__subsection-copy">
                          These integrations have fallen out of a healthy state and need review.
                        </p>
                      </div>
                    </div>
                    <div className="integrations-page__grid">
                      {errorIntegrations.map((integration) => (
                        <IntegrationCard
                          key={integration.id}
                          integration={integration}
                          onRefresh={handleRefresh}
                        />
                      ))}
                    </div>
                  </section>
                )}

                {connectedIntegrations.length > 0 ? (
                  <section className="integrations-page__subsection">
                    <div className="integrations-page__subsection-header">
                      <div>
                        <p className="ui-empty-state__eyebrow">Connected</p>
                        <h2 className="integrations-page__subsection-title">Active integrations</h2>
                        <p className="integrations-page__subsection-copy">
                          Providers currently connected to this CRM workspace.
                        </p>
                      </div>
                    </div>
                    <div className="integrations-page__grid">
                      {connectedIntegrations.map((integration) => (
                        <IntegrationCard
                          key={integration.id}
                          integration={integration}
                          onRefresh={handleRefresh}
                        />
                      ))}
                    </div>
                  </section>
                ) : (
                  <Card padding="lg">
                    <EmptyState
                      eyebrow="Connected"
                      title="No integrations connected yet"
                      description="Connect a provider to start syncing external systems into this workspace."
                      actions={(
                        <Button onClick={() => setActiveTab('available')}>
                          Browse available integrations
                        </Button>
                      )}
                    />
                  </Card>
                )}
              </div>
            )}

            {activeTab === 'available' && (
              <section className="integrations-page__section">
                <div className="integrations-page__subsection-header">
                  <div>
                    <p className="ui-empty-state__eyebrow">Catalog</p>
                    <h2 className="integrations-page__section-title">Available integrations</h2>
                    <p className="integrations-page__subsection-copy">
                      OAuth-backed providers and connectors available to this workspace.
                    </p>
                  </div>
                </div>
                <div className="integrations-page__grid">
                  {availableIntegrations.map((provider) => (
                    <OAuthConnector
                      key={provider.id}
                      provider={provider.provider}
                      name={provider.name}
                      description={provider.description}
                      icon={provider.icon}
                      onConnect={handleRefresh}
                    />
                  ))}
                </div>
              </section>
            )}

            {activeTab === 'api_keys' && (
              <div className="integrations-page__section">
                <ApiKeyManager
                  securityContext={securityContext!}
                  onUpdate={handleRefresh}
                />
                {apiKeys.length > 0 && (
                  <Card className="integrations-page__subsection" padding="lg" tone="subtle">
                    <div className="integrations-page__subsection-header">
                      <div>
                        <p className="ui-empty-state__eyebrow">Usage</p>
                        <h3 className="integrations-page__subsection-title">API usage</h3>
                        <p className="integrations-page__subsection-copy">
                          Observe current request activity across active API keys.
                        </p>
                      </div>
                    </div>
                    <ApiUsageChart
                      securityContext={securityContext!}
                      apiKeys={apiKeys}
                    />
                  </Card>
                )}
              </div>
            )}

            {activeTab === 'webhooks' && (
              <div className="integrations-page__section">
                <WebhookManager
                  securityContext={securityContext!}
                  onUpdate={handleRefresh}
                />
                {webhookEndpoints.length > 0 && (
                  <Card className="integrations-page__subsection" padding="lg" tone="subtle">
                    <div className="integrations-page__subsection-header">
                      <div>
                        <p className="ui-empty-state__eyebrow">Delivery</p>
                        <h3 className="integrations-page__subsection-title">Recent deliveries</h3>
                        <p className="integrations-page__subsection-copy">
                          Review recent webhook attempts and delivery outcomes.
                        </p>
                      </div>
                    </div>
                    <WebhookDeliveryLog
                      securityContext={securityContext!}
                      webhookEndpoints={webhookEndpoints}
                    />
                  </Card>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </PageLayout>
  );
}

export default IntegrationsPage;
