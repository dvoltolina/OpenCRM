import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom';
import { SequenceEnrollmentDetailPage } from '../SequenceEnrollmentDetailPage';

const refreshMock = vi.fn();

const mockEnrollment = {
  id: 'enrollment-1',
  sequenceId: 'sequence-1',
  sequenceName: 'Outbound Follow-up',
  entityType: 'client' as const,
  entityId: 'contact-1',
  entityName: 'Contact Record',
  entityEmail: 'contact@example.com',
  status: 'active' as const,
  currentStepIndex: 1,
  stepsCompleted: 1,
  totalSteps: 4,
  emailsSent: 2,
  emailsOpened: 1,
  emailsClicked: 0,
  tasksCreated: 1,
  repliesReceived: 0,
  enrolledById: 'user-1',
  enrolledByName: 'Owner User',
  ownerId: 'user-1',
  ownerName: 'Owner User',
  teamIds: ['team-1'],
  visibility: 'team' as const,
  createdAt: new Date('2026-03-01T00:00:00.000Z'),
};

vi.mock('../../hooks/useSequenceEnrollments', () => ({
  useEnrollment: () => ({
    enrollment: mockEnrollment,
    isLoading: false,
    error: null,
    refresh: refreshMock,
  }),
}));

vi.mock('../../components/sequences/EnrollmentDetail', () => ({
  EnrollmentDetail: ({
    enrollment,
    onBack,
    onEntityClick,
  }: {
    enrollment: typeof mockEnrollment;
    onBack?: () => void;
    onEntityClick?: (entityType: 'lead' | 'client' | 'deal', entityId: string) => void;
  }) => (
    <div>
      <div>{enrollment.sequenceName}</div>
      <button type="button" onClick={onBack}>Back to Sequence</button>
      <button type="button" onClick={() => onEntityClick?.(enrollment.entityType, enrollment.entityId)}>
        Open Entity
      </button>
    </div>
  ),
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location">{location.pathname}</div>;
}

describe('SequenceEnrollmentDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the enrollment detail for the nested sequence route', () => {
    render(
      <MemoryRouter initialEntries={['/sequences/sequence-1/enrollments/enrollment-1']}>
        <Routes>
          <Route path="/sequences/:sequenceId/enrollments/:enrollmentId" element={<SequenceEnrollmentDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Outbound Follow-up')).toBeInTheDocument();
  });

  it('navigates back to the parent sequence and maps client entities to contacts', async () => {
    render(
      <MemoryRouter initialEntries={['/sequences/sequence-1/enrollments/enrollment-1']}>
        <Routes>
          <Route
            path="/sequences/:sequenceId/enrollments/:enrollmentId"
            element={(
              <>
                <LocationDisplay />
                <SequenceEnrollmentDetailPage />
              </>
            )}
          />
          <Route
            path="/sequences/:sequenceId"
            element={(
              <>
                <LocationDisplay />
                <div>Sequence Home</div>
              </>
            )}
          />
          <Route
            path="/contacts/:contactId"
            element={(
              <>
                <LocationDisplay />
                <div>Contact Detail</div>
              </>
            )}
          />
        </Routes>
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Open Entity' }));

    await waitFor(() => {
      expect(screen.getByText('Contact Detail')).toBeInTheDocument();
    });
    expect(screen.getByTestId('location')).toHaveTextContent('/contacts/contact-1');
  });
});
