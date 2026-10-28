/**
 * EnrollmentFunnel Tests
 * Phase 5 Implementation - Analytics & Reporting
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { EnrollmentFunnel } from '../EnrollmentFunnel';
import type { SecurityContext } from '../../../data/repositories/repository-types';
import type { FunnelData } from '../../../services/sequence-analytics-service';

// Mock funnel data
const mockFunnelData: FunnelData = {
  sequenceId: 'seq-1',
  sequenceName: 'Sales Outreach',
  totalEnrolled: 100,
  overallConversionRate: 45.0,
  steps: [
    {
      stepId: 'step-1',
      stepIndex: 0,
      stepName: 'Initial Email',
      stepType: 'email',
      enteredCount: 100,
      completedCount: 85,
      exitedCount: 15,
      conversionRate: 85.0,
      dropoffRate: 15.0,
    },
    {
      stepId: 'step-2',
      stepIndex: 1,
      stepName: 'Wait 3 Days',
      stepType: 'wait',
      enteredCount: 85,
      completedCount: 80,
      exitedCount: 5,
      conversionRate: 94.1,
      dropoffRate: 5.9,
    },
    {
      stepId: 'step-3',
      stepIndex: 2,
      stepName: 'Follow-up Email',
      stepType: 'email',
      enteredCount: 80,
      completedCount: 45,
      exitedCount: 35,
      conversionRate: 56.3,
      dropoffRate: 43.7,
    },
  ],
};

const mockEmptyFunnelData: FunnelData = {
  sequenceId: 'seq-1',
  sequenceName: 'Empty Sequence',
  totalEnrolled: 0,
  overallConversionRate: 0,
  steps: [],
};

// Mock analytics service
let mockGetEnrollmentFunnel = vi.fn();

vi.mock('../../../services/sequence-analytics-service', () => ({
  getSequenceAnalyticsService: () => ({
    getEnrollmentFunnel: mockGetEnrollmentFunnel,
  }),
}));

describe('EnrollmentFunnel', () => {
  const mockSecurityContext: SecurityContext = {
    businessId: 'biz-1',
    userId: 'user-1',
    userName: 'Test User',
    userRole: 'admin',
    teamIds: ['team-1'],
    managedTeamIds: [],
  };

  const defaultProps = {
    sequenceId: 'seq-1',
    securityContext: mockSecurityContext,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockGetEnrollmentFunnel = vi.fn().mockResolvedValue(mockFunnelData);
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it('renders loading state initially', () => {
    mockGetEnrollmentFunnel.mockImplementation(
      () => new Promise(() => {}) // Never resolves
    );
    render(<EnrollmentFunnel {...defaultProps} />);
    expect(screen.getByText('Loading funnel data...')).toBeInTheDocument();
  });

  it('renders funnel with data after loading', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Enrollment Funnel')).toBeInTheDocument();
    });

    // Check overall conversion rate
    expect(screen.getByText('45.0%')).toBeInTheDocument();
    expect(screen.getByText('Overall Conversion')).toBeInTheDocument();
  });

  it('renders all funnel steps', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Initial Email')).toBeInTheDocument();
    });

    expect(screen.getByText('Wait 3 Days')).toBeInTheDocument();
    expect(screen.getByText('Follow-up Email')).toBeInTheDocument();
  });

  it('displays step type labels correctly', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getAllByText('Email').length).toBeGreaterThanOrEqual(2);
    });

    expect(screen.getByText('Wait')).toBeInTheDocument();
  });

  it('displays step metrics', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      // Multiple elements may have the same text, use getAllByText
      const enteredCounts = screen.getAllByText('100');
      expect(enteredCounts.length).toBeGreaterThanOrEqual(1);
    });

    // Check for completed counts - using getAllByText for repeated values
    expect(screen.getAllByText('85').length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('45').length).toBeGreaterThanOrEqual(1);
  });

  it('shows conversion rates for steps', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('85.0% converted')).toBeInTheDocument();
    });

    expect(screen.getByText('94.1% converted')).toBeInTheDocument();
    expect(screen.getByText('56.3% converted')).toBeInTheDocument();
  });

  it('shows dropout rates when > 0', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('15.0% dropped')).toBeInTheDocument();
    });

    expect(screen.getByText('43.7% dropped')).toBeInTheDocument();
  });

  it('renders empty state when no data', async () => {
    mockGetEnrollmentFunnel.mockResolvedValue(mockEmptyFunnelData);
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('No enrollment data available for this period')).toBeInTheDocument();
    });
  });

  it('renders error state when service fails', async () => {
    mockGetEnrollmentFunnel.mockRejectedValue(new Error('Network error'));
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
    });
  });

  it('calls onStepClick when step is clicked', async () => {
    const onStepClick = vi.fn();
    render(<EnrollmentFunnel {...defaultProps} onStepClick={onStepClick} />);

    await waitFor(() => {
      expect(screen.getByText('Initial Email')).toBeInTheDocument();
    });

    // Find the step and click it
    const step = screen.getByText('Initial Email').closest('.enrollment-funnel__step');
    if (step) {
      fireEvent.click(step);
      expect(onStepClick).toHaveBeenCalledWith('step-1');
    }
  });

  it('shows tooltip on step hover', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Initial Email')).toBeInTheDocument();
    });

    // Find a step and hover
    const step = screen.getByText('Initial Email').closest('.enrollment-funnel__step');
    if (step) {
      fireEvent.mouseEnter(step);
      await waitFor(() => {
        expect(screen.getByText(/Step 1: Initial Email/)).toBeInTheDocument();
      });

      fireEvent.mouseLeave(step);
    }
  });

  it('renders summary section', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Started')).toBeInTheDocument();
    });

    expect(screen.getByText('Completed')).toBeInTheDocument();
    expect(screen.getByText('Total Dropped')).toBeInTheDocument();
  });

  it('renders legend', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Progressed to next step')).toBeInTheDocument();
    });

    expect(screen.getByText('Dropped at this step')).toBeInTheDocument();
  });

  it('shows high dropout warning insight', async () => {
    render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Insights')).toBeInTheDocument();
    });

    // Step 3 has 43.7% dropout (> 20%)
    expect(screen.getByText(/Follow-up Email.*has a high dropout rate/)).toBeInTheDocument();
  });

  it('passes date range to service', async () => {
    const dateRange = {
      start: new Date('2024-01-01'),
      end: new Date('2024-01-31'),
    };

    render(<EnrollmentFunnel {...defaultProps} dateRange={dateRange} />);

    await waitFor(() => {
      expect(mockGetEnrollmentFunnel).toHaveBeenCalledWith(
        mockSecurityContext,
        'seq-1',
        dateRange
      );
    });
  });

  it('reloads data when sequenceId changes', async () => {
    const { rerender } = render(<EnrollmentFunnel {...defaultProps} />);

    await waitFor(() => {
      expect(mockGetEnrollmentFunnel).toHaveBeenCalledTimes(1);
    });

    rerender(<EnrollmentFunnel {...defaultProps} sequenceId="seq-2" />);

    await waitFor(() => {
      expect(mockGetEnrollmentFunnel).toHaveBeenCalledTimes(2);
      expect(mockGetEnrollmentFunnel).toHaveBeenLastCalledWith(
        mockSecurityContext,
        'seq-2',
        undefined
      );
    });
  });
});
