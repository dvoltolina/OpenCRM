import { useParams, useNavigate } from 'react-router-dom';
import { DealDetail } from '../components/details';
import { useDealMutations } from '../hooks';
import { Card, EmptyState, PageLayout } from '../components/ui';

export function DealDetailPage() {
  const { dealId } = useParams<{ dealId: string }>();
  const navigate = useNavigate();
  const { markWon, markLost } = useDealMutations();

  if (!dealId) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            title="Deal not found"
            description="The requested deal record is unavailable or the route is incomplete."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide">
      <DealDetail
        dealId={dealId}
        onBack={() => navigate('/deals')}
        onClientClick={(clientId) => navigate(`/contacts/${clientId}`)}
        onMarkWon={async () => {
          await markWon(dealId, 'Marked won from detail view');
          navigate('/deals');
        }}
        onMarkLost={async () => {
          await markLost(dealId, 'Marked lost (no PHI captured)');
          navigate('/deals');
        }}
      />
    </PageLayout>
  );
}
