import { useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../lib/security-context';
import { SequenceComparisonChart } from '../components/sequences/SequenceComparisonChart';
import { Card, EmptyState, PageHeader, PageLayout } from '../components/ui';

export function SequenceComparisonPage() {
  const { crmUser } = useAuth();
  const securityContext = useMemo(() => {
    try {
      return createSecurityContext(crmUser);
    } catch {
      return null;
    }
  }, [crmUser]);

  if (!securityContext) {
    return (
      <PageLayout width="wide">
        <PageHeader
          eyebrow="Sequences"
          title="Compare Sequences"
          subtitle="Review completion, reply, meeting, and enrollment metrics side by side."
        />
        <Card padding="lg">
          <EmptyState
            tone="warning"
            title="Sequence comparison unavailable"
            description="An authenticated business context is required before cross-sequence analytics can be loaded."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide">
      <PageHeader
        eyebrow="Sequences"
        title="Compare Sequences"
        subtitle="Review completion, reply, meeting, and enrollment metrics side by side."
      />
      <SequenceComparisonChart securityContext={securityContext} />
    </PageLayout>
  );
}
