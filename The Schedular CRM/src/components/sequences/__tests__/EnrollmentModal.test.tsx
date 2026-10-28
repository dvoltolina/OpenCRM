/**
 * EnrollmentModal Tests
 * Phase 3 Implementation
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { EnrollmentModal } from '../EnrollmentModal';
import type { EntityInfo } from '../EnrollmentModal';

// Mock hooks
vi.mock('../../../hooks/useSequences', () => ({
  useSequences: () => ({
    sequences: [
      {
        id: 'seq-1',
        name: 'Sales Outreach',
        description: 'Initial sales sequence',
        status: 'active',
        steps: [
          { id: 's1', type: 'email', order: 0 },
          { id: 's2', type: 'wait', order: 1 },
          { id: 's3', type: 'email', order: 2 },
        ],
        stats: {
          totalEnrolled: 50,
          activeEnrollments: 10,
          completedCount: 30,
          exitedCount: 10,
        },
      },
      {
        id: 'seq-2',
        name: 'Follow-up Sequence',
        status: 'active',
        steps: [{ id: 's1', type: 'email', order: 0 }],
        stats: {
          totalEnrolled: 20,
          activeEnrollments: 5,
          completedCount: 10,
          exitedCount: 5,
        },
      },
    ],
    isLoading: false,
  }),
}));

vi.mock('../../../hooks/useSequenceEnrollments', () => ({
  useEntityEnrollment: (
    _entityType: string,
    _entityId: string,
    entityEmail?: string
  ) => ({
    isEnrolled: false,
    activeEnrollment: null,
    canEnroll: !!entityEmail,
    enrollmentBlockReason: !entityEmail ? 'No email address' : undefined,
    isLoading: false,
  }),
  useEnrollmentMutations: () => ({
    enroll: vi.fn().mockResolvedValue({
      id: 'enrollment-1',
      entityName: 'Test Lead',
      sequenceName: 'Sales Outreach',
    }),
    isMutating: false,
    mutationError: null,
  }),
}));

describe('EnrollmentModal', () => {
  const mockEntity: EntityInfo = {
    type: 'lead',
    id: 'lead-123',
    name: 'John Doe',
    email: 'john@example.com',
  };

  const defaultProps = {
    isOpen: true,
    onClose: vi.fn(),
    entity: mockEntity,
    onSuccess: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders when open', () => {
    render(<EnrollmentModal {...defaultProps} />);
    expect(screen.getByTestId('enrollment-modal')).toBeInTheDocument();
    expect(screen.getByText('Add to Sequence')).toBeInTheDocument();
  });

  it('does not render when closed', () => {
    render(<EnrollmentModal {...defaultProps} isOpen={false} />);
    expect(screen.queryByTestId('enrollment-modal')).not.toBeInTheDocument();
  });

  it('displays entity info', () => {
    render(<EnrollmentModal {...defaultProps} />);
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
    expect(screen.getByText('lead')).toBeInTheDocument();
  });

  it('displays sequence options', () => {
    render(<EnrollmentModal {...defaultProps} />);
    expect(screen.getByTestId('sequence-select')).toBeInTheDocument();
    expect(screen.getByText('Sales Outreach')).toBeInTheDocument();
    expect(screen.getByText('Follow-up Sequence')).toBeInTheDocument();
  });

  it('disables enroll button when no sequence selected', () => {
    render(<EnrollmentModal {...defaultProps} />);
    const enrollButton = screen.getByTestId('enroll-button');
    expect(enrollButton).toBeDisabled();
  });

  it('enables enroll button when sequence is selected', async () => {
    render(<EnrollmentModal {...defaultProps} />);

    const select = screen.getByTestId('sequence-select');
    fireEvent.change(select, { target: { value: 'seq-1' } });

    await waitFor(() => {
      const enrollButton = screen.getByTestId('enroll-button');
      expect(enrollButton).not.toBeDisabled();
    });
  });

  it('shows sequence preview when selected', async () => {
    render(<EnrollmentModal {...defaultProps} />);

    const select = screen.getByTestId('sequence-select');
    fireEvent.change(select, { target: { value: 'seq-1' } });

    await waitFor(() => {
      expect(screen.getByText('Sequence Details')).toBeInTheDocument();
      expect(screen.getByText('3')).toBeInTheDocument(); // 3 steps
    });
  });

  it('shows warning when entity has no email', () => {
    const noEmailEntity: EntityInfo = {
      ...mockEntity,
      email: '',
    };

    render(<EnrollmentModal {...defaultProps} entity={noEmailEntity} />);
    expect(
      screen.getByText('This entity does not have an email address')
    ).toBeInTheDocument();
  });

  it('shows warning when entity has opted out', () => {
    const optedOutEntity: EntityInfo = {
      ...mockEntity,
      hasOptedOut: true,
    };

    render(<EnrollmentModal {...defaultProps} entity={optedOutEntity} />);
    expect(
      screen.getByText('This entity has opted out of emails')
    ).toBeInTheDocument();
  });

  it('calls onClose when close button is clicked', () => {
    render(<EnrollmentModal {...defaultProps} />);

    const closeButton = screen.getByLabelText('Close modal');
    fireEvent.click(closeButton);

    expect(defaultProps.onClose).toHaveBeenCalled();
  });

  it('calls onClose when cancel button is clicked', () => {
    render(<EnrollmentModal {...defaultProps} />);

    const cancelButton = screen.getByText('Cancel');
    fireEvent.click(cancelButton);

    expect(defaultProps.onClose).toHaveBeenCalled();
  });
});
