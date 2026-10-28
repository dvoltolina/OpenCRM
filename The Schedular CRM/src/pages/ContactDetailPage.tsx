import { useNavigate, useParams } from 'react-router-dom';
import { ContactDetail } from '../components/details';
import { Card, EmptyState, PageLayout } from '../components/ui';

export function ContactDetailPage() {
  const { contactId } = useParams<{ contactId: string }>();
  const navigate = useNavigate();

  if (!contactId) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            title="Contact not found"
            description="The requested contact record is unavailable or the route is incomplete."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide">
      <ContactDetail
        contactId={contactId}
        onBack={() => navigate('/contacts')}
        onDealClick={(dealId) => navigate(`/deals/${dealId}`)}
      />
    </PageLayout>
  );
}
