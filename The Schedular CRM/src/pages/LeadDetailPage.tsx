import { useParams, useNavigate } from 'react-router-dom';
import { LeadDetail } from '../components/details';
import { useLeadMutations } from '../hooks';
import { Card, EmptyState, PageLayout } from '../components/ui';

export function LeadDetailPage() {
  const { leadId } = useParams<{ leadId: string }>();
  const navigate = useNavigate();
  const { deleteLead } = useLeadMutations();

  if (!leadId) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            title="Lead not found"
            description="The requested lead record is unavailable or the route is incomplete."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide">
      <LeadDetail
        leadId={leadId}
        onBack={() => navigate('/leads')}
        onDelete={async () => {
          await deleteLead(leadId);
          navigate('/leads');
        }}
      />
    </PageLayout>
  );
}
