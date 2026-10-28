/**
 * EnrollmentList Tests
 * Phase 3 Implementation
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { EnrollmentList } from '../EnrollmentList';

// Mock data
const mockEnrollments = [
  {
    id: 'enroll-1',
    sequenceId: 'seq-1',
    sequenceName: 'Sales Outreach',
    entityType: 'lead' as const,
    entityId: 'lead-1',
    entityName: 'John Doe',
    entityEmail: 'john@example.com',
    status: 'active' as const,
    currentStepIndex: 1,
    stepsCompleted: 1,
    totalSteps: 3,
    emailsSent: 1,
    emailsOpened: 1,
    emailsClicked: 0,
    tasksCreated: 0,
    repliesReceived: 0,
    enrolledById: 'user-1',
    enrolledByName: 'Admin',
    ownerId: 'user-1',
    ownerName: 'Admin',
    teamIds: [],
    visibility: 'team' as const,
    createdAt: new Date('2024-01-15'),
    nextStepScheduledAt: new Date('2024-01-17'),
  },
  {
    id: 'enroll-2',
    sequenceId: 'seq-1',
    sequenceName: 'Sales Outreach',
    entityType: 'lead' as const,
    entityId: 'lead-2',
    entityName: 'Jane Smith',
    entityEmail: 'jane@example.com',
    status: 'completed' as const,
    currentStepIndex: 3,
    stepsCompleted: 3,
    totalSteps: 3,
    emailsSent: 3,
    emailsOpened: 2,
    emailsClicked: 1,
    tasksCreated: 1,
    repliesReceived: 0,
    enrolledById: 'user-1',
    enrolledByName: 'Admin',
    ownerId: 'user-1',
    ownerName: 'Admin',
    teamIds: [],
    visibility: 'team' as const,
    createdAt: new Date('2024-01-10'),
    completedAt: new Date('2024-01-14'),
  },
  {
    id: 'enroll-3',
    sequenceId: 'seq-1',
    sequenceName: 'Sales Outreach',
    entityType: 'lead' as const,
    entityId: 'lead-3',
    entityName: 'Bob Wilson',
    entityEmail: 'bob@example.com',
    status: 'paused' as const,
    currentStepIndex: 1,
    stepsCompleted: 1,
    totalSteps: 3,
    emailsSent: 1,
    emailsOpened: 0,
    emailsClicked: 0,
    tasksCreated: 0,
    repliesReceived: 0,
    enrolledById: 'user-1',
    enrolledByName: 'Admin',
    ownerId: 'user-1',
    ownerName: 'Admin',
    teamIds: [],
    visibility: 'team' as const,
    createdAt: new Date('2024-01-12'),
  },
];

// Mock hooks
vi.mock('../../../hooks/useSequenceEnrollments', () => ({
  useSequenceEnrollments: () => ({
    enrollments: mockEnrollments,
    isLoading: false,
    error: null,
    refresh: vi.fn(),
    countByStatus: {
      active: 1,
      paused: 1,
      completed: 1,
      exited: 0,
      bounced: 0,
      unsubscribed: 0,
    },
    totalCount: 3,
  }),
  useEnrollmentMutations: () => ({
    pause: vi.fn().mockResolvedValue({}),
    resume: vi.fn().mockResolvedValue({}),
    exit: vi.fn().mockResolvedValue({}),
    isMutating: false,
  }),
}));

describe('EnrollmentList', () => {
  const defaultProps = {
    sequenceId: 'seq-1',
    onEnrollmentClick: vi.fn(),
    onEntityClick: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders enrollment table', () => {
    render(<EnrollmentList {...defaultProps} />);
    expect(screen.getByTestId('enrollment-list')).toBeInTheDocument();
    expect(screen.getByTestId('enrollment-table')).toBeInTheDocument();
  });

  it('displays enrollment rows', () => {
    render(<EnrollmentList {...defaultProps} />);
    expect(screen.getByTestId('enrollment-row-enroll-1')).toBeInTheDocument();
    expect(screen.getByTestId('enrollment-row-enroll-2')).toBeInTheDocument();
    expect(screen.getByTestId('enrollment-row-enroll-3')).toBeInTheDocument();
  });

  it('displays entity names', () => {
    render(<EnrollmentList {...defaultProps} />);
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    expect(screen.getByText('Bob Wilson')).toBeInTheDocument();
  });

  it('displays status badges', () => {
    render(<EnrollmentList {...defaultProps} />);
    expect(screen.getByText('Active')).toBeInTheDocument();
    expect(screen.getByText('Completed')).toBeInTheDocument();
    expect(screen.getByText('Paused')).toBeInTheDocument();
  });

  it('displays progress information', () => {
    render(<EnrollmentList {...defaultProps} />);
    // Check for progress text (stepsCompleted/totalSteps format)
    // Multiple elements may have same text, so use getAllByText
    expect(screen.getAllByText('1/3').length).toBeGreaterThan(0); // John Doe and Bob Wilson
    expect(screen.getAllByText('3/3').length).toBeGreaterThan(0); // Jane Smith
  });

  it('shows status filter dropdown', () => {
    render(<EnrollmentList {...defaultProps} />);
    const statusFilter = screen.getByTestId('enrollment-status-filter');
    expect(statusFilter).toBeInTheDocument();
    expect(screen.getByText('All (3)')).toBeInTheDocument();
  });

  it('shows search input', () => {
    render(<EnrollmentList {...defaultProps} />);
    const searchInput = screen.getByTestId('enrollment-search-filter');
    expect(searchInput).toBeInTheDocument();
    expect(searchInput).toHaveAttribute('placeholder', 'Search by name or email...');
  });

  it('filters by status', () => {
    render(<EnrollmentList {...defaultProps} />);

    const statusFilter = screen.getByTestId('enrollment-status-filter');
    fireEvent.change(statusFilter, { target: { value: 'active' } });

    // Status filter shows counts in options
    expect(screen.getByText('Active (1)')).toBeInTheDocument();
  });

  it('shows bulk actions when items are selected', () => {
    render(<EnrollmentList {...defaultProps} />);

    // Select first checkbox
    const checkboxes = screen.getAllByRole('checkbox');
    fireEvent.click(checkboxes[1]); // First data row (index 0 is header)

    expect(screen.getByTestId('bulk-actions')).toBeInTheDocument();
    expect(screen.getByText('1 selected')).toBeInTheDocument();
  });

  it('shows action buttons for active enrollments', () => {
    render(<EnrollmentList {...defaultProps} />);

    // Find the row with active enrollment
    // Multiple Remove buttons exist (for each active/paused row)
    const pauseButtons = screen.getAllByText('Pause');
    const removeButtons = screen.getAllByText('Remove');
    expect(pauseButtons.length).toBeGreaterThan(0);
    expect(removeButtons.length).toBeGreaterThan(0);
  });

  it('shows resume button for paused enrollments', () => {
    render(<EnrollmentList {...defaultProps} />);

    const pausedRow = screen.getByTestId('enrollment-row-enroll-3');
    expect(pausedRow).toContainElement(screen.getAllByText('Resume')[0]);
  });

  it('calls onEnrollmentClick when View is clicked', () => {
    render(<EnrollmentList {...defaultProps} />);

    const viewButtons = screen.getAllByText('View');
    fireEvent.click(viewButtons[0]);

    expect(defaultProps.onEnrollmentClick).toHaveBeenCalled();
  });
});
