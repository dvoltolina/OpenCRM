import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { GoalDetailPage } from '../GoalDetailPage';

const refreshMock = vi.fn();
const recalculateProgressMock = vi.fn();
const updateGoalMock = vi.fn();
const cancelGoalMock = vi.fn();

const mockGoal = {
  id: 'goal-1',
  metric: 'revenue',
  targetValue: 250000,
  period: 'monthly',
  startDate: new Date('2026-03-01T00:00:00.000Z'),
  endDate: new Date('2026-03-31T00:00:00.000Z'),
  assigneeType: 'user',
  assigneeId: 'user-1',
  assigneeName: 'Alex Seller',
  currentValue: 125000,
  progressPercent: 50,
  lastCalculatedAt: new Date('2026-03-05T12:00:00.000Z'),
  status: 'active',
  ownerId: 'user-1',
  ownerName: 'Alex Seller',
  teamIds: ['team-1'],
  visibility: 'team',
  createdById: 'user-2',
  createdByName: 'Manager User',
  createdAt: new Date('2026-03-01T00:00:00.000Z'),
};

vi.mock('../../hooks/useGoals', () => ({
  useGoal: () => ({
    goal: mockGoal,
    isLoading: false,
    error: null,
    refresh: refreshMock,
  }),
  useGoalMutations: () => ({
    updateGoal: updateGoalMock,
    cancelGoal: cancelGoalMock,
    recalculateProgress: recalculateProgressMock,
    isMutating: false,
  }),
}));

describe('GoalDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    recalculateProgressMock.mockResolvedValue(mockGoal);
  });

  it('renders goal details for the routed goal id', () => {
    render(
      <MemoryRouter initialEntries={['/goals/goal-1']}>
        <Routes>
          <Route path="/goals/:goalId" element={<GoalDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByTestId('goal-detail-page')).toBeInTheDocument();
    expect(screen.getByText('Revenue')).toBeInTheDocument();
    expect(screen.getByText('Alex Seller')).toBeInTheDocument();
    expect(screen.getByText('Created by Manager User')).toBeInTheDocument();
  });

  it('recalculates progress from the detail page', async () => {
    render(
      <MemoryRouter initialEntries={['/goals/goal-1']}>
        <Routes>
          <Route path="/goals/:goalId" element={<GoalDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Recalculate' }));

    await waitFor(() => {
      expect(recalculateProgressMock).toHaveBeenCalledWith('goal-1');
    });
    expect(refreshMock).toHaveBeenCalled();
  });
});
