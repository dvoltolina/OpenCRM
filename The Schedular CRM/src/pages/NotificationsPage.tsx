/**
 * NotificationsPage
 * Full-page notifications view with all notification management features
 *
 * HIPAA Compliance: No PHI displayed - only entity references
 */

import { Link } from 'react-router-dom';
import { useNotifications } from '../hooks/useNotifications';
import { Button, Card, PageHeader, PageLayout } from '../components/ui';
import { NotificationList } from '../components/notifications/NotificationList';
import '../components/notifications/notifications.css';
import './styles/notifications-page.css';

// ============================================
// Component
// ============================================

export function NotificationsPage() {
  const {
    notifications,
    unreadCount,
    isLoading,
    error,
    markAsRead,
    markAllAsRead,
    archive,
    refresh,
    loadMore,
    hasMore,
  } = useNotifications({
    limit: 50,
    realtime: true,
  });

  return (
    <PageLayout className="notifications-page">
      <PageHeader
        eyebrow="Inbox"
        title="Notifications"
        subtitle="Review reminders, sequence events, goal alerts, and system activity in one workspace feed."
        actions={(
          <div className="notifications-page__actions">
            <Button variant="secondary" onClick={() => void refresh()} disabled={isLoading}>
              Refresh
            </Button>
            <Link to="/settings?tab=notifications" className="ui-button ui-button--secondary ui-button--md">
              Settings
            </Link>
          </div>
        )}
      />

      <Card className="notifications-page__hero" padding="lg" tone="accent">
        <div className="notifications-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current Feed</p>
          <h2>Notification operations</h2>
          <p>
            Keep up with work that needs action, clear the unread queue, and route into personal
            notification preferences when delivery needs adjusting.
          </p>
        </div>
        <div className="notifications-page__hero-stats">
          <div>
            <span>Total loaded</span>
            <strong>{notifications.length}</strong>
          </div>
          <div>
            <span>Unread</span>
            <strong>{unreadCount}</strong>
          </div>
          <div>
            <span>More available</span>
            <strong>{hasMore ? 'Yes' : 'No'}</strong>
          </div>
        </div>
      </Card>

      {error ? (
        <Card className="notifications-page__error" padding="md">
          <span>{error}</span>
        </Card>
      ) : null}

      <Card className="notifications-page__content-card" padding="md">
        <div className="notifications-page-content">
          <NotificationList
            notifications={notifications}
            isLoading={isLoading}
            onMarkRead={markAsRead}
            onMarkAllRead={markAllAsRead}
            onArchive={archive}
            onLoadMore={loadMore}
            hasMore={hasMore}
          />
        </div>
      </Card>
    </PageLayout>
  );
}
