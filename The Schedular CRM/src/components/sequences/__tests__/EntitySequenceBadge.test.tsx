/**
 * EntitySequenceBadge Tests
 * Phase 3 Implementation
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { EntitySequenceBadge, EntitySequenceBadgeSimple } from '../EntitySequenceBadge';
import type { SequenceEnrollment } from '../../../types/sequences';

// Mock enrollment data
const mockActiveEnrollment: SequenceEnrollment = {
  id: 'enroll-1',
  sequenceId: 'seq-1',
  sequenceName: 'Sales Outreach',
  entityType: 'lead',
  entityId: 'lead-1',
  entityName: 'John Doe',
  entityEmail: 'john@example.com',
  status: 'active',
  currentStepIndex: 1,
  stepsCompleted: 2,
  totalSteps: 5,
  emailsSent: 2,
  emailsOpened: 1,
  emailsClicked: 0,
  tasksCreated: 0,
  repliesReceived: 0,
  enrolledById: 'user-1',
  enrolledByName: 'Admin',
  ownerId: 'user-1',
  ownerName: 'Admin',
  teamIds: [],
  visibility: 'team',
  createdAt: new Date(),
};

// Mock hook with controllable state
let mockIsEnrolled = true;
let mockActiveEnrollmentData: SequenceEnrollment = mockActiveEnrollment;
let mockIsLoading = false;

vi.mock('../../../hooks/useSequenceEnrollments', () => ({
  useEntityEnrollment: () => ({
    isEnrolled: mockIsEnrolled,
    activeEnrollment: mockIsEnrolled ? mockActiveEnrollmentData : null,
    isLoading: mockIsLoading,
  }),
}));

describe('EntitySequenceBadge', () => {
  const defaultProps = {
    entityType: 'lead' as const,
    entityId: 'lead-1',
    entityEmail: 'john@example.com',
    onClick: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockIsEnrolled = true;
    mockActiveEnrollmentData = mockActiveEnrollment;
    mockIsLoading = false;
  });

  it('renders badge when enrolled', () => {
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.getByTestId('entity-sequence-badge')).toBeInTheDocument();
  });

  it('does not render when not enrolled', () => {
    mockIsEnrolled = false;
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.queryByTestId('entity-sequence-badge')).not.toBeInTheDocument();
  });

  it('does not render when loading', () => {
    mockIsLoading = true;
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.queryByTestId('entity-sequence-badge')).not.toBeInTheDocument();
  });

  it('displays sequence name (truncated)', () => {
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.getByText('Sales Outreach')).toBeInTheDocument();
  });

  it('displays progress', () => {
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.getByText('2/5')).toBeInTheDocument();
  });

  it('renders icon-only variant', () => {
    render(<EntitySequenceBadge {...defaultProps} iconOnly />);
    const badge = screen.getByTestId('entity-sequence-badge');
    expect(badge).toBeInTheDocument();
    // Icon-only doesn't show the name
    expect(screen.queryByText('Sales Outreach')).not.toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    render(<EntitySequenceBadge {...defaultProps} />);
    const badge = screen.getByTestId('entity-sequence-badge');
    fireEvent.click(badge);
    expect(defaultProps.onClick).toHaveBeenCalled();
  });

  it('shows paused status when enrollment is paused', () => {
    mockActiveEnrollmentData = { ...mockActiveEnrollment, status: 'paused' as const };
    render(<EntitySequenceBadge {...defaultProps} />);
    expect(screen.getByText('Paused')).toBeInTheDocument();
  });
});

describe('EntitySequenceBadgeSimple', () => {
  const defaultProps = {
    sequenceName: 'Follow-up Sequence',
    stepsCompleted: 3,
    totalSteps: 6,
    onClick: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders with provided data', () => {
    render(<EntitySequenceBadgeSimple {...defaultProps} />);
    expect(screen.getByTestId('entity-sequence-badge-simple')).toBeInTheDocument();
    // Truncated at 15 chars = "Follow-up Sequ…"
    expect(screen.getByText('Follow-up Sequ…')).toBeInTheDocument();
    expect(screen.getByText('3/6')).toBeInTheDocument();
  });

  it('shows paused indicator when isPaused is true', () => {
    render(<EntitySequenceBadgeSimple {...defaultProps} isPaused />);
    expect(screen.getByText('Paused')).toBeInTheDocument();
  });

  it('renders icon-only variant', () => {
    render(<EntitySequenceBadgeSimple {...defaultProps} iconOnly />);
    const badge = screen.getByTestId('entity-sequence-badge-simple');
    expect(badge).toBeInTheDocument();
    // Icon-only doesn't show the progress
    expect(screen.queryByText('3/6')).not.toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    render(<EntitySequenceBadgeSimple {...defaultProps} />);
    const badge = screen.getByTestId('entity-sequence-badge-simple');
    fireEvent.click(badge);
    expect(defaultProps.onClick).toHaveBeenCalled();
  });

  it('shows correct tooltip in icon-only mode', () => {
    render(<EntitySequenceBadgeSimple {...defaultProps} iconOnly />);
    const badge = screen.getByTestId('entity-sequence-badge-simple');
    expect(badge).toHaveAttribute(
      'title',
      'In sequence: Follow-up Sequence (50%)'
    );
  });
});
