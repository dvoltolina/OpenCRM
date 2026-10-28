import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { NotificationsPage } from '../NotificationsPage';

const { state, refreshMock, markAsReadMock, markAllAsReadMock, archiveMock, loadMoreMock } = vi.hoisted(() => ({
  state: { error: null as string | null },
  refreshMock: vi.fn(),
  markAsReadMock: vi.fn(),
  markAllAsReadMock: vi.fn(),
  archiveMock: vi.fn(),
  loadMoreMock: vi.fn(),
}));

vi.mock('../../hooks/useNotifications', () => ({
  useNotifications: () => ({
    notifications: [{ id: 'note-1' }, { id: 'note-2' }],
    unreadCount: 1,
    isLoading: false,
    error: state.error,
    markAsRead: markAsReadMock,
    markAllAsRead: markAllAsReadMock,
    archive: archiveMock,
    refresh: refreshMock,
    loadMore: loadMoreMock,
    hasMore: false,
  }),
}));

vi.mock('../../components/notifications/NotificationList', () => ({
  NotificationList: ({ notifications }: { notifications: Array<{ id: string }> }) => (
    <div>Notification List {notifications.length}</div>
  ),
}));

describe('NotificationsPage', () => {
  beforeEach(() => {
    state.error = null;
    refreshMock.mockReset();
    markAsReadMock.mockReset();
    markAllAsReadMock.mockReset();
    archiveMock.mockReset();
    loadMoreMock.mockReset();
  });

  it('renders the notifications shell and actions', () => {
    render(
      <MemoryRouter>
        <NotificationsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Notifications')).toBeInTheDocument();
    expect(screen.getByText('Notification List 2')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Settings' })).toHaveAttribute(
      'href',
      '/settings?tab=notifications'
    );

    fireEvent.click(screen.getByRole('button', { name: 'Refresh' }));
    expect(refreshMock).toHaveBeenCalled();
  });

  it('renders the route-level error banner when the hook returns an error', () => {
    state.error = 'Unable to load notifications';

    render(
      <MemoryRouter>
        <NotificationsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Unable to load notifications')).toBeInTheDocument();
  });
});
