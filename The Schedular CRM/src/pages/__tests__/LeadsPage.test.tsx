/**
 * LeadsPage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state with retry
 * 3. Renders lead data
 * 4. Renders empty state
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LeadsPage } from '../LeadsPage';
import type { Lead } from '../../types/models';

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(() => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Test User',
      email: 'user@example.com',
      role: 'owner',
      businessId: 'biz-1',
      teamIds: ['team-a'],
      managedTeamIds: [],
    },
    businessId: 'biz-1',
  })),
}));

// Mock hooks
vi.mock('../../hooks', () => ({
  useLeads: vi.fn(),
  useLeadMutations: vi.fn(() => ({ isLoading: false })),
  usePipelines: vi.fn(() => ({ pipelines: [] })),
  useStages: vi.fn(() => ({ stages: [] })),
  useModal: vi.fn(() => ({
    isOpen: false,
    open: vi.fn(),
    close: vi.fn(),
    data: null,
  })),
}));

// Mock components
vi.mock('../../components/leads', () => ({
  LeadActions: ({ lead }: { lead: Lead }) => <div data-testid="lead-actions">{lead.id}</div>,
  LeadStatusBadge: ({ status }: { status: string }) => <span>{status}</span>,
}));

vi.mock('../../components/modals', () => ({
  ConvertLeadModal: () => null,
  ConfirmDialog: () => null,
  CreateLeadModal: () => null,
}));

vi.mock('../../components/details', () => ({
  LeadDetail: () => <div data-testid="lead-detail" />,
}));

vi.mock('../../components/import', () => ({
  CSVImportModal: () => null,
}));

vi.mock('../../components/payments/PayNowButton', () => ({
  __esModule: true,
  default: () => <button>pay-now</button>,
}));

import { useLeads } from '../../hooks';

const mockLeads: Lead[] = [
  {
    id: 'lead-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    status: 'new',
    source: 'website',
    tags: [], // Added
    createdAt: new Date('2025-01-01'),
    updatedAt: new Date('2025-01-01'),
  },
  {
    id: 'lead-2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    status: 'qualified',
    source: 'referral',
    companyName: 'Acme Corp',
    tags: [], // Added
    createdAt: new Date('2025-01-02'),
    updatedAt: new Date('2025-01-02'),
  },
];

describe('LeadsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(useLeads).mockReturnValue({
      leads: [],
      isLoading: true,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Loading leads...')).toBeInTheDocument();
    expect(screen.getByText('Leads')).toBeInTheDocument();
  });

  // Test 2: Error state with retry
  it('renders error state with retry button', () => {
    const mockRefresh = vi.fn();
    vi.mocked(useLeads).mockReturnValue({
      leads: [],
      isLoading: false,
      error: new Error('Failed to fetch leads'),
      hasMore: false,
      loadMore: vi.fn(),
      refresh: mockRefresh,
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    expect(screen.getByText(/Error loading leads/)).toBeInTheDocument();

    const retryButton = screen.getByText('Retry');
    fireEvent.click(retryButton);
    expect(mockRefresh).toHaveBeenCalled();
  });

  // Test 3: Renders lead data
  it('renders lead data correctly', () => {
    vi.mocked(useLeads).mockReturnValue({
      leads: mockLeads,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    expect(screen.getByText('Acme Corp')).toBeInTheDocument();
  });

  // Test 4: Empty state
  it('renders empty state when no leads', () => {
    vi.mocked(useLeads).mockReturnValue({
      leads: [],
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 0,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Pipeline starts here')).toBeInTheDocument();
    expect(screen.getByText('No leads yet')).toBeInTheDocument();
    expect(
      screen.getByText('Import your pipeline or create the first lead manually to start qualification and assignment.')
    ).toBeInTheDocument();
    expect(screen.getAllByText('Import CSV')[0]).toBeInTheDocument();
  });

  // Test 5: Load more button
  it('shows load more button when hasMore is true', () => {
    const mockLoadMore = vi.fn();
    vi.mocked(useLeads).mockReturnValue({
      leads: mockLeads,
      isLoading: false,
      error: null,
      hasMore: true,
      loadMore: mockLoadMore,
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    const loadMoreButton = screen.getByText('Load More');
    expect(loadMoreButton).toBeInTheDocument();

    fireEvent.click(loadMoreButton);
    expect(mockLoadMore).toHaveBeenCalled();
  });

  // Test 6: Filter functionality
  it('renders filter controls', () => {
    vi.mocked(useLeads).mockReturnValue({
      leads: mockLeads,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
      getAccessSummary: vi.fn(),
    });

    render(
      <MemoryRouter>
        <LeadsPage />
      </MemoryRouter>
    );

    expect(screen.getByPlaceholderText('Search leads...')).toBeInTheDocument();
    expect(screen.getAllByRole('combobox')).toHaveLength(2);
  });
});
