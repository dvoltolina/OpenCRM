import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Card, EmptyState, PageHeader, PageLayout } from '../components/ui';

export function NotFoundPage() {
  const { user, businessId } = useAuth();
  const homePath = user
    ? businessId
      ? '/dashboard'
      : '/business-required'
    : '/login';
  const homeLabel = user ? 'Return to dashboard' : 'Go to login';

  return (
    <PageLayout width="wide">
      <PageHeader
        eyebrow="Routing"
        title="Page not found"
        subtitle="The route you requested does not exist or is no longer available."
      />
      <Card padding="lg">
        <EmptyState
          title="Nothing lives here anymore"
          description="Use the primary navigation or return to a valid entry point for your workspace."
          actions={(
            <Link className="ui-button ui-button--primary ui-button--md" to={homePath}>
              {homeLabel}
            </Link>
          )}
        />
      </Card>
    </PageLayout>
  );
}
