import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { GoalsPage } from '../GoalsPage';

const { featureFlags, roleState, goalsHookMock, goalDashboardMock, forecastSummaryMock } = vi.hoisted(() => ({
  featureFlags: {
    enableGoals: true,
    enableForecasting: true,
  },
  roleState: { role: 'owner' },
  goalsHookMock: vi.fn(),
  goalDashboardMock: vi.fn(),
  forecastSummaryMock: vi.fn(),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => featureFlags,
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Owner User',
      role: roleState.role,
    },
  }),
}));

vi.mock('../../hooks/useGoals', () => ({
  useGoals: (...args: unknown[]) => goalsHookMock(...args),
  useGoalDashboard: () => goalDashboardMock(),
  useGoalMutations: () => ({
    createGoal: vi.fn(),
    cancelGoal: vi.fn(),
    recalculateProgress: vi.fn(),
    isMutating: false,
  }),
}));

vi.mock('../../hooks/useForecasting', () => ({
  useForecastSummary: (...args: unknown[]) => forecastSummaryMock(...args),
  formatCurrency: (value: number) => `$${(value / 100).toLocaleString()}`,
}));

describe('GoalsPage', () => {
  beforeEach(() => {
    featureFlags.enableGoals = true;
    featureFlags.enableForecasting = true;
    goalsHookMock.mockReturnValue({
      goals: [
        {
          id: 'goal-1',
          metric: 'revenue',
          assigneeName: 'Owner User',
          assigneeType: 'user',
          currentValue: 500000,
          targetValue: 1000000,
          progressPercent: 50,
          status: 'active',
          period: 'monthly',
          startDate: new Date('2026-03-01T00:00:00Z'),
          endDate: new Date('2026-03-31T00:00:00Z'),
        },
      ],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      isEnabled: true,
    });
    goalDashboardMock.mockReturnValue({
      stats: {
        totalGoals: 1,
        activeGoals: 1,
        achievedGoals: 0,
        missedGoals: 0,
        averageProgress: 50,
      },
    });
    forecastSummaryMock.mockReturnValue({
      summary: {
        forecast: {
          projectedRevenue: 1200000,
          committed: 800000,
          closed: 250000,
          bestCase: 1450000,
        },
        commitmentRatio: 67,
        confidenceLevel: 'medium',
      },
      isLoading: false,
      error: null,
    });
  });

  it('renders the feature-locked prompt when goals are disabled', () => {
    featureFlags.enableGoals = false;

    render(
      <MemoryRouter>
        <GoalsPage />
      </MemoryRouter>
    );

    expect(screen.getByTestId('goals-upgrade-prompt')).toBeInTheDocument();
  });

  it('renders the goals workspace and allows filters to be changed', () => {
    render(
      <MemoryRouter>
        <GoalsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Goals & Forecasting')).toBeInTheDocument();
    expect(screen.getByTestId('stat-active-goals')).toHaveTextContent('1');
    expect(screen.getByTestId('forecast-widget')).toBeInTheDocument();

    fireEvent.change(screen.getByDisplayValue('All Statuses'), { target: { value: 'active' } });
    expect(screen.getByRole('button', { name: 'Clear Filters' })).toBeInTheDocument();
  });
});
