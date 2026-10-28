/**
 * SequenceAnalytics Tests
 * Phase 5 Implementation - Analytics & Reporting
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { SequenceAnalytics } from '../SequenceAnalytics';
import type { SequenceMetrics } from '../../../services/sequence-analytics-service';
import type { Sequence } from '../../../types/sequences';

// Mock metrics data
const mockMetrics: SequenceMetrics = {
  sequenceId: 'seq-1',
  sequenceName: 'Sales Outreach',
  dateRange: {
    start: new Date('2024-01-01'),
    end: new Date('2024-12-31'),
  },
  totalEnrolled: 500,
  activeEnrollments: 125,
  completedCount: 200,
  exitedCount: 175,
  completionRate: 53.3,
  avgTimeToComplete: 7.5,
  avgTimeToReply: 2.3,
  emailsSent: 1500,
  emailsDelivered: 1450,
  emailsOpened: 725,
  emailsClicked: 290,
  emailsReplied: 145,
  emailsBounced: 50,
  deliveryRate: 96.7,
  openRate: 50.0,
  clickRate: 20.0,
  replyRate: 10.0,
  bounceRate: 3.3,
  tasksCreated: 75,
  tasksCompleted: 50,
  taskCompletionRate: 66.7,
  meetingsBooked: 35,
  meetingBookingRate: 7.0,
  dealsCreated: 15,
  dealConversionRate: 3.0,
  avgTimeToExit: 4.2,
  revenueInfluenced: 250000,
  exitReasons: {
    replied: 50,
    unsubscribed: 30,
    bounced: 50,
    manual: 45,
  },
  calculatedAt: new Date(),
};

const mockSequence: Sequence = {
  id: 'seq-1',
  name: 'Sales Outreach',
  description: 'Outbound sales sequence',
  status: 'active',
  steps: [
    {
      id: 'step-1',
      order: 0,
      type: 'email',
      delayDays: 0,
      delayHours: 0,
      emailConfig: {
        subject: 'Hello',
        body: 'Test email',
      },
      isActive: true,
    },
  ],
  settings: {
    sendingSchedule: {
      timezone: 'America/New_York',
      businessHoursOnly: true,
      startHour: 9,
      endHour: 17,
      excludeDays: [0, 6],
    },
    dailyEmailLimit: 50,
    maxEnrollmentsPerDay: 100,
    pauseOnReply: true,
    pauseOnOpen: false,
    trackOpens: true,
    trackClicks: true,
    pauseOnMeetingBooked: true,
    removeOnUnsubscribe: true,
    threadEmails: true,
  },
  exitCriteria: {
    onReply: true,
    onMeetingBooked: true,
    onDealWon: false,
    onDealLost: false,
    onLeadConverted: false,
    onManualRemoval: true,
  },
  stats: {
    totalEnrolled: 0,
    activeEnrollments: 0,
    completedCount: 0,
    exitedCount: 0,
  },
  ownerId: 'user-1',
  ownerName: 'Test User',
  visibility: 'team',
  teamIds: ['team-1'],
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-06-01'),
};

// Mock hooks and services
const mockNavigate = vi.fn();
let mockCalculateSequenceMetrics = vi.fn();
let mockSequenceRepoGetById = vi.fn();

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Test User',
      role: 'admin',
      teamIds: ['team-1'],
      managedTeamIds: [],
    },
    businessId: 'biz-1',
  }),
}));

vi.mock('../../../services/sequence-analytics-service', () => ({
  getSequenceAnalyticsService: () => ({
    calculateSequenceMetrics: mockCalculateSequenceMetrics,
    getEnrollmentFunnel: vi.fn().mockResolvedValue({
      sequenceId: 'seq-1',
      sequenceName: 'Sales Outreach',
      totalEnrolled: 100,
      overallConversionRate: 50,
      steps: [],
    }),
    getEnrollmentTrends: vi.fn().mockResolvedValue([]),
    getOptimalSendTimes: vi.fn().mockResolvedValue({
      bestDays: [],
      bestHours: [],
      recommendation: 'Test recommendation',
    }),
  }),
}));

vi.mock('../../../data/repositories/sequence-repository', () => ({
  getSequenceRepository: () => ({
    getById: mockSequenceRepoGetById,
  }),
}));

// Mock child components to simplify testing
vi.mock('../StepPerformanceTable', () => ({
  StepPerformanceTable: () => <div data-testid="step-performance-table">Step Performance Table</div>,
}));

vi.mock('../EnrollmentFunnel', () => ({
  EnrollmentFunnel: () => <div data-testid="enrollment-funnel">Enrollment Funnel</div>,
}));

vi.mock('../SendTimeHeatmap', () => ({
  SendTimeHeatmap: () => <div data-testid="send-time-heatmap">Send Time Heatmap</div>,
}));

vi.mock('../SequenceTrendChart', () => ({
  SequenceTrendChart: () => <div data-testid="trend-chart">Trend Chart</div>,
}));

function renderWithRouter(sequenceId = 'seq-1') {
  return render(
    <MemoryRouter initialEntries={[`/sequences/${sequenceId}/analytics`]}>
      <Routes>
        <Route path="/sequences/:sequenceId/analytics" element={<SequenceAnalytics />} />
        <Route path="/sequences" element={<div>Sequences List</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('SequenceAnalytics', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockCalculateSequenceMetrics = vi.fn().mockResolvedValue(mockMetrics);
    mockSequenceRepoGetById = vi.fn().mockResolvedValue({
      success: true,
      data: mockSequence,
    });
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it('renders loading state initially', () => {
    mockCalculateSequenceMetrics.mockImplementation(() => new Promise(() => {}));
    mockSequenceRepoGetById.mockImplementation(() => new Promise(() => {}));
    renderWithRouter();
    expect(screen.getByText('Loading analytics...')).toBeInTheDocument();
  });

  it('renders analytics after loading', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Sales Outreach')).toBeInTheDocument();
    });
  });

  it('displays sequence status badge', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('active')).toBeInTheDocument();
    });
  });

  it('renders all tabs', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Overview')).toBeInTheDocument();
    });

    expect(screen.getByText('Funnel')).toBeInTheDocument();
    expect(screen.getByText('Step Performance')).toBeInTheDocument();
    expect(screen.getByText('Timing')).toBeInTheDocument();
    expect(screen.getByText('Trends')).toBeInTheDocument();
  });

  it('shows overview tab by default', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Total Enrolled')).toBeInTheDocument();
    });

    expect(screen.getByText('Completion Rate')).toBeInTheDocument();
    expect(screen.getByText('Reply Rate')).toBeInTheDocument();
  });

  it('displays correct metrics on overview', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('500')).toBeInTheDocument(); // total enrolled
    });

    expect(screen.getByText('53.3%')).toBeInTheDocument(); // completion rate
    expect(screen.getByText('10.0%')).toBeInTheDocument(); // reply rate
  });

  it('switches to funnel tab when clicked', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Funnel')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText('Funnel'));

    await waitFor(() => {
      expect(screen.getByTestId('enrollment-funnel')).toBeInTheDocument();
    });
  });

  it('switches to step performance tab when clicked', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Step Performance')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText('Step Performance'));

    await waitFor(() => {
      expect(screen.getByTestId('step-performance-table')).toBeInTheDocument();
    });
  });

  it('switches to timing tab when clicked', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Timing')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText('Timing'));

    await waitFor(() => {
      expect(screen.getByTestId('send-time-heatmap')).toBeInTheDocument();
    });
  });

  it('switches to trends tab when clicked', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Trends')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText('Trends'));

    await waitFor(() => {
      expect(screen.getByTestId('trend-chart')).toBeInTheDocument();
    });
  });

  it('renders date range selector', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByDisplayValue('Last 30 days')).toBeInTheDocument();
    });
  });

  it('changes date range when selected', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByDisplayValue('Last 30 days')).toBeInTheDocument();
    });

    const select = screen.getByDisplayValue('Last 30 days');
    fireEvent.change(select, { target: { value: '7d' } });

    await waitFor(() => {
      expect(screen.getByDisplayValue('Last 7 days')).toBeInTheDocument();
    });
  });

  it('renders export button', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Export CSV')).toBeInTheDocument();
    });
  });

  it('renders error state when sequence not found', async () => {
    mockSequenceRepoGetById.mockResolvedValue({
      success: false,
      data: null,
    });

    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Error: Sequence not found')).toBeInTheDocument();
    });
  });

  it('renders error state when service fails', async () => {
    mockCalculateSequenceMetrics.mockRejectedValue(new Error('Service error'));

    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Error: Service error')).toBeInTheDocument();
    });
  });

  it('shows back button that navigates to sequences list', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByLabelText('Back to sequences')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByLabelText('Back to sequences'));
    expect(mockNavigate).toHaveBeenCalledWith('/sequences');
  });

  it('displays email performance section', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Email Performance')).toBeInTheDocument();
    });

    expect(screen.getByText('Emails Sent')).toBeInTheDocument();
    expect(screen.getByText('Delivered')).toBeInTheDocument();
    expect(screen.getByText('Opened')).toBeInTheDocument();
    expect(screen.getByText('Clicked')).toBeInTheDocument();
    expect(screen.getByText('Replied')).toBeInTheDocument();
    expect(screen.getByText('Bounced')).toBeInTheDocument();
  });

  it('displays exit reasons section', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Exit Reasons')).toBeInTheDocument();
    });
  });

  it('displays conversion metrics section', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Conversion Metrics')).toBeInTheDocument();
    });

    expect(screen.getByText('Meetings Booked')).toBeInTheDocument();
    expect(screen.getByText('Deals Created')).toBeInTheDocument();
    expect(screen.getByText('Tasks Created')).toBeInTheDocument();
  });

  it('displays sequence details section', async () => {
    renderWithRouter();

    await waitFor(() => {
      expect(screen.getByText('Sequence Details')).toBeInTheDocument();
    });

    expect(screen.getByText('Steps')).toBeInTheDocument();
    expect(screen.getByText('Owner')).toBeInTheDocument();
    expect(screen.getByText('Created')).toBeInTheDocument();
    expect(screen.getByText('Last Updated')).toBeInTheDocument();
  });

  it('applies success color class for high completion rate', async () => {
    renderWithRouter();

    await waitFor(() => {
      const completionElement = screen.getByText('53.3%');
      expect(completionElement).toHaveClass('sequence-analytics__metric-value--success');
    });
  });

  it('applies success color class for high reply rate', async () => {
    renderWithRouter();

    await waitFor(() => {
      const replyElement = screen.getByText('10.0%');
      expect(replyElement).toHaveClass('sequence-analytics__metric-value--success');
    });
  });
});
