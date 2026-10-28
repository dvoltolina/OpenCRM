/**
 * ActivitiesPage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state with retry
 * 3. Renders activity data
 * 4. Renders empty state
 * 5. Filter tabs work
 */

import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ActivitiesPage } from '../ActivitiesPage';
import type { SalesActivity } from '../../types/models';

// Mock hooks
const logActivityMock = vi.fn();
const createTaskMock = vi.fn();
const completeTaskMock = vi.fn();
const uncompleteTaskMock = vi.fn();
const updateActivityMock = vi.fn();
const deleteActivityMock = vi.fn();
const getStageByIdMock = vi.fn();

vi.mock('../../hooks', () => ({
  useRecentActivities: vi.fn(),
  useDeals: vi.fn(() => ({ deals: [] })),
  useLeads: vi.fn(() => ({ leads: [] })),
  useContacts: vi.fn(() => ({ contacts: [] })),
  useModal: vi.fn(() => ({
    isOpen: false,
    open: vi.fn(),
    close: vi.fn(),
    data: null,
  })),
}));

vi.mock('../../hooks/useActivityLog', () => ({
  useActivityLog: () => ({
    logActivity: logActivityMock,
    isLoading: false,
    clearError: vi.fn(),
    logCall: vi.fn(),
    logEmail: vi.fn(),
    logMeeting: vi.fn(),
    logNote: vi.fn(),
    createTask: createTaskMock,
    completeTask: completeTaskMock,
    uncompleteTask: uncompleteTaskMock,
    updateActivity: updateActivityMock,
    deleteActivity: deleteActivityMock,
    error: null,
  }),
}));

vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: () => ({
    getById: getStageByIdMock,
  }),
}));

vi.mock('../../components/modals', () => ({
  Modal: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  ConfirmDialog: ({ onConfirm, message }: { onConfirm: () => void; message: string }) => (
    <div>
      <span>{message}</span>
      <button onClick={onConfirm}>confirm-delete</button>
    </div>
  ),
}));

vi.mock('../../components/forms/ActivityForm', () => ({
  ActivityForm: ({ onSubmit }: { onSubmit: () => void }) => (
    <button onClick={onSubmit}>submit-activity</button>
  ),
}));

const authState = {
  crmUser: {
    id: 'user-1',
    businessId: 'business-1',
    displayName: 'Test User',
    role: 'admin' as 'admin' | 'staff',
    email: 'test@example.com',
    teamIds: ['team-a'],
    managedTeamIds: [] as string[],
  },
  businessId: 'business-1',
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => authState,
}));

import { useRecentActivities, useDeals, useContacts, useLeads } from '../../hooks';

const mockActivities: SalesActivity[] = [
  {
    id: 'activity-1',
    type: 'call',
    title: 'Sales Call with John',
    description: 'Discussed pricing options',
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date('2025-01-15T10:00:00'),
    updatedAt: new Date('2025-01-15T10:00:00'),
    isCompleted: false,
  },
  {
    id: 'activity-2',
    type: 'email',
    title: 'Follow-up Email',
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date('2025-01-15T14:00:00'),
    updatedAt: new Date('2025-01-15T14:00:00'),
    isCompleted: false,
  },
  {
    id: 'activity-3',
    type: 'meeting',
    title: 'Product Demo',
    description: 'Showed new features',
    createdById: 'user-2',
    createdByName: 'Account Exec',
    createdAt: new Date('2025-01-16T09:00:00'),
    updatedAt: new Date('2025-01-16T09:00:00'),
    isCompleted: false,
  },
  {
    id: 'task-1',
    type: 'task',
    title: 'Follow up with client',
    dueDate: new Date('2025-01-20T10:00:00'),
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date('2025-01-17T09:00:00'),
    updatedAt: new Date('2025-01-17T09:00:00'),
    isCompleted: false,
  },
  {
    id: 'task-2',
    type: 'task',
    title: 'Completed task',
    dueDate: new Date('2025-01-18T10:00:00'),
    createdById: 'user-1',
    createdByName: 'Sales Rep',
    createdAt: new Date('2025-01-17T09:00:00'),
    updatedAt: new Date('2025-01-18T11:00:00'),
    isCompleted: true,
    completedAt: new Date('2025-01-18T11:00:00'),
  },
];

describe('ActivitiesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(useDeals).mockReturnValue({ deals: [] } as any);
    vi.mocked(useLeads).mockReturnValue({ leads: [] } as any);
    vi.mocked(useContacts).mockReturnValue({ contacts: [] } as any);
    logActivityMock.mockResolvedValue(null as any);
    createTaskMock.mockResolvedValue(null as any);
    completeTaskMock.mockResolvedValue(null as any);
    uncompleteTaskMock.mockResolvedValue(null as any);
    updateActivityMock.mockResolvedValue(null as any);
    deleteActivityMock.mockResolvedValue(true as any);
    getStageByIdMock.mockReset();
    getStageByIdMock.mockResolvedValue({
      success: false,
      error: { code: 'NOT_FOUND', message: 'not found' },
    });
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: true,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    expect(screen.getByText('Loading activities...')).toBeInTheDocument();
    expect(screen.getByText('Activities')).toBeInTheDocument();
  });

  // Test 2: Error state
  it('renders error state with retry button', () => {
    const mockRefresh = vi.fn();
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: false,
      error: { code: 'FETCH_ERROR', message: 'Failed to fetch activities' },
      refresh: mockRefresh,
    });

    render(<ActivitiesPage />);

    expect(screen.getByText(/Error loading activities/)).toBeInTheDocument();

    const retryButton = screen.getByText('Retry');
    fireEvent.click(retryButton);
    expect(mockRefresh).toHaveBeenCalled();
  });

  // Test 3: Renders activity data
  it('renders activity data correctly', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    expect(screen.getByText('Sales Call with John')).toBeInTheDocument();
    expect(screen.getByText('Discussed pricing options')).toBeInTheDocument();
    expect(screen.getByText('Follow-up Email')).toBeInTheDocument();
    expect(screen.getByText('Product Demo')).toBeInTheDocument();
  });

  // Test 4: Empty state
  it('renders empty state when no activities', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    expect(screen.getByText('No activities found')).toBeInTheDocument();
    expect(screen.getByText('Log your first activity')).toBeInTheDocument();
  });

  // Test 5: Filter tabs render
  it('renders filter tabs', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    expect(screen.getByText('All Activities')).toBeInTheDocument();
    expect(screen.getByText('Calls')).toBeInTheDocument();
    expect(screen.getByText('Emails')).toBeInTheDocument();
    expect(screen.getByText('Meetings')).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();
    expect(screen.getByText('Tasks')).toBeInTheDocument();
  });

  // Test 6: Filter tabs filter activities
  it('filters activities by type when tab clicked', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Initially shows all activities
    expect(screen.getByText('Sales Call with John')).toBeInTheDocument();
    expect(screen.getByText('Follow-up Email')).toBeInTheDocument();
    expect(screen.getByText('Product Demo')).toBeInTheDocument();

    // Click on Calls filter
    fireEvent.click(screen.getByText('Calls'));

    // Should only show call activities
    expect(screen.getByText('Sales Call with John')).toBeInTheDocument();
    expect(screen.queryByText('Follow-up Email')).not.toBeInTheDocument();
    expect(screen.queryByText('Product Demo')).not.toBeInTheDocument();
  });

  // Test 7: Shows author name
  it('shows activity author name', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Two activities have "by Sales Rep", one has "by Account Exec"
    expect(screen.getAllByText('by Sales Rep').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('by Account Exec')).toBeInTheDocument();
  });

  // Test 8: Pagination - Load more button
  it('shows load more button when activities exceed limit', () => {
    // Create 25 activities (more than default limit of 20)
    const manyActivities: SalesActivity[] = Array.from({ length: 25 }, (_, i) => ({
      id: `activity-${i}`,
      type: 'note',
      title: `Activity ${i}`,
      createdById: 'user-1',
      createdByName: 'Sales Rep',
      createdAt: new Date(),
      updatedAt: new Date(),
      isCompleted: false,
    }));

    vi.mocked(useRecentActivities).mockReturnValue({
      activities: manyActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Should show load more button
    expect(screen.getByText(/Load More/)).toBeInTheDocument();
    expect(screen.getByText(/5 remaining/)).toBeInTheDocument();
  });

  // Test 9: Pagination - Load more expands list
  it('loads more activities when load more is clicked', () => {
    const manyActivities: SalesActivity[] = Array.from({ length: 25 }, (_, i) => ({
      id: `activity-${i}`,
      type: 'note',
      title: `Activity ${i}`,
      createdById: 'user-1',
      createdByName: 'Sales Rep',
      createdAt: new Date(),
      updatedAt: new Date(),
      isCompleted: false,
    }));

    vi.mocked(useRecentActivities).mockReturnValue({
      activities: manyActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Click load more
    const loadMoreButton = screen.getByText(/Load More/);
    fireEvent.click(loadMoreButton);

    // After clicking, should display all activities or more of them
    // No more "5 remaining" since we loaded more
    expect(screen.queryByText(/5 remaining/)).not.toBeInTheDocument();
  });

  // Test 10: Task completion toggle
  it('shows complete button for pending tasks', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Should show completion buttons for tasks
    const checkButtons = screen.getAllByTitle(/Mark as/);
    expect(checkButtons.length).toBeGreaterThan(0);
  });

  // Test 11: Filter completed tasks
  it('filters out completed tasks when checkbox is unchecked', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Initially shows both pending and completed tasks
    expect(screen.getByText('Follow up with client')).toBeInTheDocument();
    expect(screen.getByText('Completed task')).toBeInTheDocument();

    // Uncheck "Show completed tasks"
    const checkbox = screen.getByLabelText('Show completed tasks');
    fireEvent.click(checkbox);

    // Should still show pending task
    expect(screen.getByText('Follow up with client')).toBeInTheDocument();
    // Should hide completed task
    expect(screen.queryByText('Completed task')).not.toBeInTheDocument();
  });

  // Test 12: Edit button shows for own activities
  it('shows edit button for activities created by current user or admin', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Should have edit buttons (user-1 is admin and creator of some activities)
    const editButtons = screen.getAllByTitle('Edit activity');
    expect(editButtons.length).toBeGreaterThan(0);
  });

  // Test 13: Delete button shows only for admins
  it('shows delete button for admin users', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities,
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Should have delete buttons (user is admin)
    const deleteButtons = screen.getAllByTitle('Delete activity');
    expect(deleteButtons.length).toBeGreaterThan(0);
  });

  it('shows read-only tooltip when activity is not shared to user', () => {
    authState.crmUser.role = 'staff';
    authState.crmUser.teamIds = ['team-a'];
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [
        {
          ...mockActivities[0],
          teamIds: ['team-other'],
          visibility: 'team',
          createdById: 'other-user',
          createdByName: 'Other User',
        },
      ],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    const readOnlyButtons = screen.getAllByTitle(/Read-only/);
    expect(readOnlyButtons.length).toBeGreaterThan(0);
    readOnlyButtons.forEach((button) => expect(button).toBeDisabled());

    authState.crmUser.role = 'admin';
    authState.crmUser.teamIds = ['team-a'];
  });

  // Test 14: Empty state when filtered
  it('shows empty state when filter results in no activities', () => {
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: mockActivities.filter(a => a.type !== 'note'),
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    // Click on Notes filter
    fireEvent.click(screen.getByText('Notes'));

    // Should show empty message but not the "log first activity" button
    expect(screen.getByText('No activities found')).toBeInTheDocument();
    expect(screen.queryByText('Log your first activity')).not.toBeInTheDocument();
  });

  it('submits quick note inline when entities are available', async () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [{ id: 'deal-1', title: 'Enterprise Deal' }],
    } as any);
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    logActivityMock.mockResolvedValue({ id: 'activity-quick-note' } as any);

    render(<ActivitiesPage />);

    fireEvent.change(screen.getByTestId('quick-title'), { target: { value: 'Pipeline note' } });
    fireEvent.change(screen.getByTestId('quick-note'), { target: { value: 'Call scheduled' } });
    fireEvent.click(screen.getByTestId('quick-submit'));

    expect(logActivityMock).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'note',
        title: 'Pipeline note',
        description: 'Call scheduled',
        dealId: 'deal-1',
      })
    );
  });

  it('applies template defaults for quick tasks', async () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [{ id: 'deal-2', title: 'Renewal' }],
    } as any);
    vi.mocked(useContacts).mockReturnValue({ contacts: [] } as any);
    vi.mocked(useLeads).mockReturnValue({ leads: [] } as any);
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    createTaskMock.mockResolvedValue({ id: 'task-quick' } as any);

    render(<ActivitiesPage />);

    fireEvent.click(screen.getByText('Add Task'));

    await waitFor(() =>
      expect((screen.getByTestId('quick-due') as HTMLInputElement).value).not.toBe('')
    );

    fireEvent.change(screen.getByTestId('quick-title'), {
      target: { value: 'Prep contract' },
    });
    fireEvent.click(screen.getByTestId('quick-submit'));

    expect(createTaskMock).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Prep contract',
        dealId: 'deal-2',
        assigneeId: authState.crmUser.id,
        assigneeName: authState.crmUser.displayName,
        templateId: expect.any(String),
        slaMinutes: expect.any(Number),
        slaAt: expect.any(Date),
        reminderAt: expect.any(Date),
        dueDate: expect.any(Date),
      })
    );
  });

  it('applies stage-aware templates when logging a quick task for a deal', async () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [
        {
          id: 'deal-3',
          title: 'Enterprise Renewal',
          pipelineId: 'pipe-1',
          stageId: 'stage-negotiation',
        },
      ],
    } as any);
    vi.mocked(useContacts).mockReturnValue({ contacts: [] } as any);
    vi.mocked(useLeads).mockReturnValue({ leads: [] } as any);
    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });
    getStageByIdMock.mockResolvedValue({
      success: true,
      data: {
        id: 'stage-negotiation',
        name: 'Negotiation',
        pipelineId: 'pipe-1',
      },
    });
    createTaskMock.mockResolvedValue({ id: 'task-stage-aware' } as any);

    render(<ActivitiesPage />);

    fireEvent.click(screen.getByText('Add Task'));

    await waitFor(() =>
      expect((screen.getByTestId('quick-template') as HTMLSelectElement).value).toBe('contract-follow-up')
    );

    fireEvent.change(screen.getByTestId('quick-title'), {
      target: { value: 'Close the renewal' },
    });
    fireEvent.click(screen.getByTestId('quick-submit'));

    expect(createTaskMock).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Close the renewal',
        dealId: 'deal-3',
        templateId: 'contract-follow-up',
        slaMinutes: expect.any(Number),
        slaAt: expect.any(Date),
        reminderAt: expect.any(Date),
        dueDate: expect.any(Date),
      })
    );
  });

  it('shows SLA badge for overdue tasks', () => {
    const overdueTask: SalesActivity = {
      id: 'overdue-1',
      type: 'task',
      title: 'Overdue follow-up',
      createdById: 'user-1',
      createdByName: 'Sales Rep',
      createdAt: new Date(),
      dueDate: new Date(Date.now() - 3 * 60 * 60 * 1000),
      isCompleted: false,
    };

    vi.mocked(useRecentActivities).mockReturnValue({
      activities: [overdueTask],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
    });

    render(<ActivitiesPage />);

    expect(screen.getByText(/SLA breached/)).toBeInTheDocument();
  });
});
