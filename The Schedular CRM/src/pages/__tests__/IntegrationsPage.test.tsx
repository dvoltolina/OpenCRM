import { render, screen, waitFor, waitForElementToBeRemoved, fireEvent } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { IntegrationsPage } from '../IntegrationsPage';

let mockRole = 'owner';
let mockIntegrations: Array<Record<string, unknown>> = [];
let mockWebhookEndpoints: Array<Record<string, unknown>> = [];
let mockApiKeys: Array<Record<string, unknown>> = [];

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    businessId: 'business-1',
    crmUser: {
      id: 'user-1',
      displayName: 'Owner User',
      role: mockRole,
      teamIds: [],
      managedTeamIds: [],
    },
  }),
}));

vi.mock('../../hooks/usePipeline', () => ({
  createSecurityContext: () => ({
    businessId: 'business-1',
    userId: 'user-1',
    userName: 'Owner User',
    userRole: mockRole,
    teamIds: [],
    managedTeamIds: [],
  }),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => ({
    enableApi: true,
    enableWebhooks: true,
    enableCalendarSync: false,
  }),
}));

vi.mock('../../config/demo', () => ({
  isDemoMode: false,
}));

vi.mock('../../components/integrations/IntegrationCard', () => ({
  IntegrationCard: ({ integration }: { integration: { name: string } }) => <div>{integration.name}</div>,
}));

vi.mock('../../components/integrations/WebhookManager', () => ({
  WebhookManager: () => <div>Webhook Manager</div>,
}));

vi.mock('../../components/integrations/WebhookDeliveryLog', () => ({
  WebhookDeliveryLog: () => <div>Webhook Delivery Log</div>,
}));

vi.mock('../../components/integrations/ApiKeyManager', () => ({
  ApiKeyManager: () => <div>API Key Manager</div>,
}));

vi.mock('../../components/integrations/ApiUsageChart', () => ({
  ApiUsageChart: () => <div>API Usage Chart</div>,
}));

vi.mock('../../components/integrations/DemoIntegrationsPanels', () => ({
  DemoIntegrationsPanels: () => <div>Demo Integrations Panels</div>,
}));

vi.mock('../../components/integrations/OAuthConnector', () => ({
  OAuthConnector: ({ name }: { name: string }) => <div>{name}</div>,
}));

vi.mock('../../components/calendar-sync/CalendarSyncPanel', () => ({
  CalendarSyncPanel: () => <div>Calendar Sync Panel</div>,
}));

vi.mock('../../data/repositories/integration-repository', () => ({
  getIntegrationRepository: () => ({
    getAll: vi.fn(async () => ({ success: true, data: { data: mockIntegrations } })),
  }),
}));

vi.mock('../../data/repositories/webhook-endpoint-repository', () => ({
  getWebhookEndpointRepository: () => ({
    getAll: vi.fn(async () => ({ success: true, data: { data: mockWebhookEndpoints } })),
  }),
}));

vi.mock('../../data/repositories/api-key-repository', () => ({
  getApiKeyRepository: () => ({
    getAll: vi.fn(async () => ({ success: true, data: { data: mockApiKeys } })),
  }),
}));

describe('IntegrationsPage', () => {
  beforeEach(() => {
    mockRole = 'owner';
    mockIntegrations = [];
    mockWebhookEndpoints = [];
    mockApiKeys = [];
  });

  it('blocks non-admin roles from the integrations surface', () => {
    mockRole = 'staff';

    render(<IntegrationsPage />);

    expect(screen.getByText('Access denied')).toBeInTheDocument();
  });

  it('renders the available integrations tab with provider options', async () => {
    render(<IntegrationsPage />);

    await waitForElementToBeRemoved(() => screen.getByText('Loading integrations...'));

    await waitFor(() => {
      expect(screen.getByRole('button', { name: 'Available' })).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole('button', { name: 'Available' }));

    expect(screen.getByText('Zapier')).toBeInTheDocument();
    expect(screen.getByText('Slack')).toBeInTheDocument();
    expect(screen.getByText('Salesforce')).toBeInTheDocument();
    expect(screen.getByText('HubSpot')).toBeInTheDocument();
  });
});
