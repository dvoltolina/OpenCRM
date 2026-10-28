import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { SettingsPage } from '../SettingsPage';

vi.mock('../../components/settings', () => ({
  WorkspaceSettings: () => <div>Workspace Settings Content</div>,
  PipelineSettings: () => <div>Pipeline Settings Content</div>,
  TeamSettings: () => <div>Team Settings Content</div>,
  CustomFieldsSettings: () => <div>Custom Fields Settings Content</div>,
  CRMSettings: () => <div>CRM Settings Content</div>,
  AutomationSettings: () => <div>Automation Settings Content</div>,
}));

vi.mock('../../components/notifications', () => ({
  NotificationPreferences: () => <div>Notification Preferences Content</div>,
}));

vi.mock('../../components/calendar-sync/CalendarSyncPanel', () => ({
  CalendarSyncPanel: () => <div>Calendar Sync Panel</div>,
}));

vi.mock('../../hooks/useIntegrationSync', () => ({
  useIntegrationSync: () => ({
    isLoading: false,
    error: null,
    lastResult: null,
    runSync: vi.fn(),
  }),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => ({
    enableAutomation: true,
    enableCalendarSync: false,
  }),
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      role: 'owner',
    },
    hasRole: () => true,
  }),
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location-search">{location.search}</div>;
}

describe('SettingsPage', () => {
  const originalScrollTo = window.scrollTo;

  beforeEach(() => {
    window.scrollTo = vi.fn();
  });

  afterEach(() => {
    window.scrollTo = originalScrollTo;
  });

  it('normalizes legacy pipeline tab aliases from the URL', async () => {
    render(
      <MemoryRouter initialEntries={['/settings?tab=pipelines']}>
        <LocationDisplay />
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Pipeline Settings Content')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=pipeline');
    });
  });

  it('updates the query string when a settings tab is clicked', async () => {
    render(
      <MemoryRouter initialEntries={['/settings']}>
        <LocationDisplay />
        <SettingsPage />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Team' }));

    expect(screen.getByText('Team Settings Content')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=team');
    });
  });

  it('opens notification preferences from the URL query string', () => {
    render(
      <MemoryRouter initialEntries={['/settings?tab=notifications']}>
        <LocationDisplay />
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Notification Preferences Content')).toBeInTheDocument();
    expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=notifications');
  });
});
