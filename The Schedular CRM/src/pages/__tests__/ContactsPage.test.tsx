/**
 * ContactsPage Smoke Tests
 *
 * Agent CRM-23 Implementation
 *
 * Test Scenarios:
 * 1. Renders loading state
 * 2. Renders error state with retry
 * 3. Renders contact data
 * 4. Renders empty state
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ContactsPage } from '../ContactsPage';
import type { Client, CRMUser } from '../../types/models';

// Mock hooks
vi.mock('../../hooks', async () => {
  const actual = await vi.importActual<typeof import('../../hooks')>('../../hooks');
  return {
    ...actual,
    useContacts: vi.fn(),
    useContactMutations: vi.fn(() => ({ isLoading: false })),
    useModal: vi.fn(() => ({
      isOpen: false,
      open: vi.fn(),
      close: vi.fn(),
      data: null,
    })),
  };
});

vi.mock('../../components/modals', async () => {
  const actual = await vi.importActual<typeof import('../../components/modals')>('../../components/modals');
  return {
    ...actual,
    CreateContactModal: () => null,
    ContactDetailModal: () => null,
    ConfirmDialog: () => null,
  };
});

const mockCrmUser: CRMUser = {
  id: 'user-1',
  email: 'admin@example.com',
  displayName: 'Admin User',
  role: 'admin',
  businessId: 'business-123',
  createdAt: new Date(),
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    user: null,
    crmUser: mockCrmUser,
    businessId: mockCrmUser.businessId,
    isLoading: false,
    error: null,
    status: 'authenticated',
    requiresMfa: false,
    mfaResolver: null,
    mfaEnrollmentRequired: false,
    signIn: vi.fn(),
    signOut: vi.fn(),
    refreshAuthState: vi.fn(),
    hasRole: () => true,
  }),
}));

import { useContacts } from '../../hooks';

const mockContacts: Client[] = [
  {
    id: 'contact-1',
    firstName: 'Alice',
    lastName: 'Johnson',
    email: 'alice@example.com',
    phone: '555-1234',
    companyName: 'Tech Corp',
    title: 'CEO',
    lifecycle: 'active', // Changed from 'customer'
    tags: [], // Added
    lastContactedAt: new Date('2025-01-15'),
    createdAt: new Date('2025-01-01'),
    updatedAt: new Date('2025-01-15'),
  },
  {
    id: 'contact-2',
    firstName: 'Bob',
    lastName: 'Williams',
    email: 'bob@example.com',
    lifecycle: 'prospect',
    tags: [], // Added
    createdAt: new Date('2025-01-02'),
    updatedAt: new Date('2025-01-02'),
  },
];

describe('ContactsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // Test 1: Loading state
  it('renders loading state', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: [],
      isLoading: true,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 0,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(screen.getByText('Loading contacts...')).toBeInTheDocument();
    expect(screen.getByText('Contacts')).toBeInTheDocument();
  });

  // Test 2: Error state
  it('renders error state with retry button', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: [],
      isLoading: false,
      error: new Error('Failed to fetch contacts'),
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 0,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(
      screen.getByText(/Unable to load contacts/i)
    ).toBeInTheDocument();
  });

  // Test 3: Renders contact data
  it('renders contact data correctly', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: mockContacts,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(screen.getByText('Alice Johnson')).toBeInTheDocument();
    expect(screen.getByText('alice@example.com')).toBeInTheDocument();
    expect(screen.getByText('555-1234')).toBeInTheDocument();
    expect(screen.getByText('Tech Corp')).toBeInTheDocument();
    expect(screen.getByText('CEO')).toBeInTheDocument();
    expect(screen.getByText('Bob Williams')).toBeInTheDocument();
  });

  // Test 4: Empty state
  it('renders empty state when no contacts', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: [],
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 0,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(screen.getByText('Directory')).toBeInTheDocument();
    expect(screen.getByText('No contacts yet')).toBeInTheDocument();
    expect(
      screen.getByText('Import your existing contact list or create the first person record manually to centralize outreach.')
    ).toBeInTheDocument();
    expect(screen.getAllByText('Import CSV')[0]).toBeInTheDocument();
  });

  // Test 5: Load more button
  it('shows load more button when hasMore is true', () => {
    const mockLoadMore = vi.fn();
    vi.mocked(useContacts).mockReturnValue({
      contacts: mockContacts,
      isLoading: false,
      error: null,
      hasMore: true,
      loadMore: mockLoadMore,
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    const loadMoreButton = screen.getByText('Load More');
    expect(loadMoreButton).toBeInTheDocument();

    fireEvent.click(loadMoreButton);
    expect(mockLoadMore).toHaveBeenCalled();
  });

  // Test 6: Search input
  it('renders search input', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: mockContacts,
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 2,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(screen.getByPlaceholderText('Search contacts...')).toBeInTheDocument();
  });

  // Test 7: Shows "Never" for contacts without lastContactedAt
  it('shows Never for contacts without lastContactedAt', () => {
    vi.mocked(useContacts).mockReturnValue({
      contacts: [mockContacts[1]], // Bob has no lastContactedAt
      isLoading: false,
      error: null,
      hasMore: false,
      loadMore: vi.fn(),
      refresh: vi.fn(),
      totalCount: 1,
      isLoadingMore: false,
    });

    render(<ContactsPage />);

    expect(screen.getByText('Never')).toBeInTheDocument();
  });
});
