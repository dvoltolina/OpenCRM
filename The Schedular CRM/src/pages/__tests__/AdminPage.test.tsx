import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { AdminPage } from '../AdminPage';

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      role: 'admin',
    },
  }),
}));

vi.mock('../../components/admin', () => ({
  AdminTeamsPanel: () => <div>Admin Teams Panel</div>,
  AdminUsersPanel: () => <div>Admin Users Panel</div>,
  AdminOrgTreePanel: () => <div>Admin Org Tree Panel</div>,
  UserDetailDrawer: () => null,
}));

vi.mock('../../components/audit/AuditLogViewer', () => ({
  AuditLogViewer: () => <div>Audit Log Viewer</div>,
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location-search">{location.search}</div>;
}

describe('AdminPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('opens the audit tab from the URL query string', () => {
    render(
      <MemoryRouter initialEntries={['/admin?tab=audit']}>
        <LocationDisplay />
        <AdminPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Audit Log Viewer')).toBeInTheDocument();
    expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=audit');
  });

  it('falls back to teams for unknown admin tabs and normalizes the URL', async () => {
    render(
      <MemoryRouter initialEntries={['/admin?tab=invalid']}>
        <LocationDisplay />
        <AdminPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Admin Teams Panel')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=teams');
    });
  });

  it('updates the query string when switching admin tabs', async () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <LocationDisplay />
        <AdminPage />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Audit Log' }));

    expect(screen.getByText('Audit Log Viewer')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=audit');
    });
  });
});
