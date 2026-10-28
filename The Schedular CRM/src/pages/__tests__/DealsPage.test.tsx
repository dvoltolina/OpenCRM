/**
 * DealsPage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state with retry
 * 3. Renders deal data
 * 4. Renders empty state
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { DealsPage } from '../DealsPage';
import type { Deal } from '../../types/models';

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      businessId: 'biz-1',
      displayName: 'Test User',
      role: 'admin',
      teamIds: [],
      managedTeamIds: [],
    },
    businessId: 'biz-1',
  }),
}));

// Mock hooks
vi.mock('../../hooks', () => ({
  useDeals: vi.fn(),
  useDealMutations: vi.fn(() => ({ isLoading: false })),
  usePipelines: vi.fn(() => ({ pipelines: [] })),
  useStages: vi.fn(() => ({ stages: [] })),
  useModal: vi.fn(() => ({
    isOpen: false,
    open: vi.fn(),
    close: vi.fn(),
    data: null,
  })),
}));

vi.mock('../../components/modals', () => ({
  CreateDealModal: () => null,
  ConfirmDialog: () => null,
}));

vi.mock('../../components/payments/PayNowButton', () => ({
  __esModule: true,
  default: () => <div data-testid="pay-now-button" />,
}));

vi.mock('../../components/import', () => ({
  CSVImportModal: () => null,
}));

vi.mock('../../components/details', () => ({
  DealDetail: () => <div data-testid="deal-detail" />,
}));

// Mock utils
vi.mock('../../utils/formatting', () => ({
  formatCurrency: (cents: number) => `$${(cents / 100).toFixed(2)}`,
}));

import { useDeals } from '../../hooks';

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    title: 'Enterprise Contract',
    valueCents: 1000000,
    currency: 'USD',
    probability: 50, // Added
    status: 'open',
    stageId: 'stage-1',
    pipelineId: 'pipeline-1',
    clientName: 'John Doe',
    tags: [], // Added
    expectedCloseDate: new Date('2025-03-01'),
    createdAt: new Date('2025-01-01'),
    updatedAt: new Date('2025-01-01'),
  },
  {
    id: 'deal-2',
    title: 'Small Business Deal',
    valueCents: 50000,
    currency: 'USD',
    probability: 100, // Added
    status: 'won',
    stageId: 'stage-3',
    pipelineId: 'pipeline-1',
    tags: [], // Added
    createdAt: new Date('2025-01-02'),
    updatedAt: new Date('2025-01-15'),
  },
];

describe('DealsPage', () => {
  const renderWithRouter = () =>
    render(
      <MemoryRouter initialEntries={['/deals']}>
        <Routes>
          <Route path="/deals" element={<DealsPage />} />
        </Routes>
      </MemoryRouter>
    );

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [],
      isLoading: true,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalValue: 0,
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    expect(screen.getByText('Loading opportunities...')).toBeInTheDocument();
    expect(screen.getByText('Opportunities')).toBeInTheDocument();
  });

  // Test 2: Error state
  it('renders error state with retry button', () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [],
      isLoading: false,
      error: new Error('Failed to fetch deals'),
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalValue: 0,
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    expect(screen.getByText(/Error loading opportunities/)).toBeInTheDocument();
  });

  // Test 3: Renders deal data
  it('renders deal data correctly', () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: mockDeals,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalValue: 1050000,
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    expect(screen.getByText('Enterprise Contract')).toBeInTheDocument();
    expect(screen.getByText('$10000.00')).toBeInTheDocument();
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Small Business Deal')).toBeInTheDocument();
  });

  // Test 4: Empty state
  it('renders empty state when no deals', () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: [],
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalValue: 0,
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    expect(screen.getByText('Revenue tracking')).toBeInTheDocument();
    expect(screen.getByText('No opportunities yet')).toBeInTheDocument();
    expect(
      screen.getByText('Import existing pipeline data or create the first opportunity manually to start stage-based tracking.')
    ).toBeInTheDocument();
    expect(screen.getAllByText('Import CSV')[0]).toBeInTheDocument();
  });

  // Test 5: Load more button
  it('shows load more button when hasMore is true', () => {
    const mockLoadMore = vi.fn();
    vi.mocked(useDeals).mockReturnValue({
      deals: mockDeals,
      isLoading: false,
      error: null,
      hasMore: true,
      loadMore: mockLoadMore,
      refresh: vi.fn(),
      totalValue: 1050000,
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    const loadMoreButton = screen.getByText('Load More');
    expect(loadMoreButton).toBeInTheDocument();

    fireEvent.click(loadMoreButton);
    expect(mockLoadMore).toHaveBeenCalled();
  });

  // Test 6: Status filter
  it('renders status filter with options', () => {
    vi.mocked(useDeals).mockReturnValue({
      deals: mockDeals,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalValue: 1050000,
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    renderWithRouter();

    const select = screen.getByRole('combobox');
    expect(select).toBeInTheDocument();

    // Check options exist
    expect(screen.getByRole('option', { name: 'All Opportunities' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Open' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Won' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Lost' })).toBeInTheDocument();
  });
});
