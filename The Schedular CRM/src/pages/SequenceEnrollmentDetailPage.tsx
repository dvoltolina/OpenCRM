import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { EnrollmentDetail } from '../components/sequences/EnrollmentDetail';
import { Card, EmptyState, PageLayout } from '../components/ui';
import { useEnrollment } from '../hooks/useSequenceEnrollments';
import type { SequenceEnrollment } from '../types/sequences';

function getEntityPath(entityType: SequenceEnrollment['entityType'], entityId: string): string {
  switch (entityType) {
    case 'lead':
      return `/leads/${entityId}`;
    case 'client':
      return `/contacts/${entityId}`;
    case 'deal':
      return `/deals/${entityId}`;
    default:
      return '/sequences';
  }
}

export function SequenceEnrollmentDetailPage() {
  const { sequenceId, enrollmentId } = useParams<{
    sequenceId: string;
    enrollmentId: string;
  }>();
  const navigate = useNavigate();
  const { enrollment, isLoading, error, refresh } = useEnrollment(enrollmentId);
  const [currentEnrollment, setCurrentEnrollment] = useState<SequenceEnrollment | null>(null);

  useEffect(() => {
    setCurrentEnrollment(enrollment);
  }, [enrollment]);

  const sequencePath = useMemo(
    () => (sequenceId ? `/sequences/${sequenceId}` : '/sequences'),
    [sequenceId]
  );

  if (!enrollmentId) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            title="Enrollment not found"
            description="The requested enrollment route is incomplete or no longer points to a valid record."
          />
        </Card>
      </PageLayout>
    );
  }

  if (isLoading) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <p>Loading enrollment...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error || !currentEnrollment) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            tone="danger"
            title="Enrollment unavailable"
            description={error?.message || 'Enrollment not found.'}
          />
        </Card>
      </PageLayout>
    );
  }

  if (sequenceId && currentEnrollment.sequenceId !== sequenceId) {
    return (
      <PageLayout width="wide">
        <Card padding="lg">
          <EmptyState
            tone="warning"
            title="Sequence mismatch"
            description="This enrollment does not belong to the requested sequence."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide">
      <EnrollmentDetail
        enrollment={currentEnrollment}
        onBack={() => navigate(sequencePath)}
        onUpdate={(updatedEnrollment) => {
          setCurrentEnrollment(updatedEnrollment);
          refresh();
        }}
        onEntityClick={(entityType, entityId) => navigate(getEntityPath(entityType, entityId))}
      />
    </PageLayout>
  );
}
