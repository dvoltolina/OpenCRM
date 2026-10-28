import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom';
import { RequireFeature } from '../RequireFeature';
import { RequireRole } from '../RequireRole';
import { RequireSettingsAccess } from '../RequireSettingsAccess';

const authState = {
  crmUser: {
    id: 'user-1',
    role: 'owner',
  },
};

const featureFlags = {
  enableReports: true,
  enableAdvancedReporting: true,
  enableWebForms: true,
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => authState,
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => featureFlags,
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location">{`${location.pathname}${location.search}`}</div>;
}

describe('Route guards', () => {
  beforeEach(() => {
    authState.crmUser.role = 'owner';
    featureFlags.enableReports = true;
    featureFlags.enableAdvancedReporting = true;
    featureFlags.enableWebForms = true;
  });

  it('redirects disabled feature routes to the dashboard', async () => {
    featureFlags.enableWebForms = false;

    render(
      <MemoryRouter initialEntries={['/web-forms']}>
        <Routes>
          <Route path="/dashboard" element={<div>Dashboard fallback</div>} />
          <Route
            path="/web-forms"
            element={(
              <RequireFeature flag="enableWebForms">
                <div>Web Forms</div>
              </RequireFeature>
            )}
          />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Dashboard fallback')).toBeInTheDocument();
    });
  });

  it('redirects unauthorized roles to the dashboard', async () => {
    authState.crmUser.role = 'staff';

    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route path="/dashboard" element={<div>Dashboard fallback</div>} />
          <Route
            path="/admin"
            element={(
              <RequireRole roles={['admin', 'owner']}>
                <div>Admin content</div>
              </RequireRole>
            )}
          />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Dashboard fallback')).toBeInTheDocument();
    });
  });

  it('normalizes staff settings access to the notifications tab', async () => {
    authState.crmUser.role = 'staff';

    render(
      <MemoryRouter initialEntries={['/settings?tab=team']}>
        <Routes>
          <Route
            path="/settings"
            element={(
              <RequireSettingsAccess>
                <>
                  <LocationDisplay />
                  <div>Settings content</div>
                </>
              </RequireSettingsAccess>
            )}
          />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('location')).toHaveTextContent('/settings?tab=notifications');
    });

    expect(screen.getByText('Settings content')).toBeInTheDocument();
  });
});
