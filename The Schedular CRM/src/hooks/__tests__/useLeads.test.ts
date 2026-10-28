/**
 * useLeads Hook Tests
 *
 * Agent CRM-08 Implementation
 *
 * Test Scenarios:
 * 1. Returns lead list
 * 2. Filters by status
 * 3. Filters by source
 * 4. Filters by assignee
 * 5. Search by name/email
 * 6. Pagination loads more results
 * 7. Combined filters work correctly
 * 8. Real-time updates when lead added (via refresh)
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useLeads } from '../useLeads';
import type { Lead } from '../../types/models';

// ============================================
// Mock Auth Context
// ============================================

const mockCrmUser = {
  id: 'user-123',
  displayName: 'Test User',
  role: 'admin' as const, // Changed to as const
  businessId: 'business-123',
  email: 'test@example.com',
  createdAt: new Date(),
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(() => ({
    crmUser: mockCrmUser,
    businessId: 'business-123',
    user: { uid: 'user-123' },
    isLoading: false,
    error: null,
  })),
}));

// ============================================
// Mock Lead Repository
// ============================================

const mockLeads: Lead[] = [
  {
    id: 'lead-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    phone: '+1234567890',
    companyName: 'Acme Corp',
    status: 'new',
    source: 'website',
    tags: ['enterprise'],
    createdAt: new Date(),
  },
  {
    id: 'lead-2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    status: 'qualified',
    source: 'referral',
    assigneeId: 'user-456',
    assigneeName: 'Sales Rep',
    tags: ['startup'],
    createdAt: new Date(),
  },
  {
    id: 'lead-3',
    firstName: 'Bob',
    lastName: 'Johnson',
    email: 'bob@example.com',
    status: 'new',
    source: 'website',
    tags: [],
    createdAt: new Date(),
  },
];

const mockGetFiltered = vi.fn();
const mockSearch = vi.fn();

vi.mock('../../data/repositories/lead-repository', () => ({
  getLeadRepository: vi.fn(() => ({
    getFiltered: mockGetFiltered,
    search: mockSearch,
    getAll: mockGetFiltered,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useLeads', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock response
    mockGetFiltered.mockResolvedValue({
      success: true,
      data: { data: mockLeads, hasMore: false, lastDoc: null },
      error: null,
    });

    mockSearch.mockResolvedValue({
      success: true,
      data: { data: mockLeads, hasMore: false, lastDoc: null },
      error: null,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Returns lead list
  // ============================================
  it('returns lead list', async () => {
    const { result } = renderHook(() => useLeads());

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.leads).toHaveLength(3);
    expect(result.current.leads[0].firstName).toBe('John');
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: Filters by status
  // ============================================
  it('filters by status', async () => {
    const newLeads = mockLeads.filter((l) => l.status === 'new');
    mockGetFiltered.mockResolvedValue({
      success: true,
      data: { data: newLeads, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => useLeads({ status: 'new' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetFiltered).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({ status: 'new' }),
      expect.any(Object)
    );
  });

  // ============================================
  // Test 3: Filters by source
  // ============================================
  it('filters by source', async () => {
    const websiteLeads = mockLeads.filter((l) => l.source === 'website');
    mockGetFiltered.mockResolvedValue({
      success: true,
      data: { data: websiteLeads, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => useLeads({ source: 'website' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetFiltered).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({ source: 'website' }),
      expect.any(Object)
    );
  });

  // ============================================
  // Test 4: Filters by assignee
  // ============================================
  it('filters by assignee', async () => {
    const assignedLeads = mockLeads.filter((l) => l.assigneeId === 'user-456');
    mockGetFiltered.mockResolvedValue({
      success: true,
      data: { data: assignedLeads, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => useLeads({ assigneeId: 'user-456' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetFiltered).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({ assigneeId: 'user-456' }),
      expect.any(Object)
    );
  });

  // ============================================
  // Test 5: Search by name/email (debounce test simplified)
  // ============================================
  it('searches by name/email', async () => {
    const searchResults = [mockLeads[0]]; // John Doe
    mockSearch.mockResolvedValue({
      success: true,
      data: { data: searchResults, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => useLeads({ search: 'john' }));

    // Wait for debounce and data load
    await waitFor(
      () => {
        expect(mockSearch).toHaveBeenCalled();
      },
      { timeout: 500 }
    );

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockSearch).toHaveBeenCalledWith(
      expect.any(Object),
      'john',
      expect.any(Object)
    );
  });

  // ============================================
  // Test 6: Pagination loads more results
  // ============================================
  it('pagination loads more results', async () => {
    const firstPage = mockLeads.slice(0, 2);
    const secondPage = [mockLeads[2]];

    mockGetFiltered
      .mockResolvedValueOnce({
        success: true,
        data: { data: firstPage, hasMore: true, lastDoc: 'doc-2' },
        error: null,
      })
      .mockResolvedValueOnce({
        success: true,
        data: { data: secondPage, hasMore: false, lastDoc: null },
        error: null,
      });

    const { result } = renderHook(() => useLeads(undefined, 2));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.leads).toHaveLength(2);
    expect(result.current.hasMore).toBe(true);

    // Load more
    await act(async () => {
      result.current.loadMore();
    });

    await waitFor(() => {
      expect(result.current.isLoadingMore).toBe(false);
    });

    expect(result.current.leads).toHaveLength(3);
    expect(result.current.hasMore).toBe(false);
  });

  // ============================================
  // Test 7: Combined filters work correctly
  // ============================================
  it('combined filters work correctly', async () => {
    const filteredLeads = [mockLeads[0]];
    mockGetFiltered.mockResolvedValue({
      success: true,
      data: { data: filteredLeads, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() =>
      useLeads({
        status: 'new',
        source: 'website',
      })
    );

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetFiltered).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({
        status: 'new',
        source: 'website',
      }),
      expect.any(Object)
    );
  });

  // ============================================
  // Test 8: Refresh reloads data
  // ============================================
  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useLeads());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetFiltered).toHaveBeenCalledTimes(1);

    // Refresh
    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockGetFiltered).toHaveBeenCalledTimes(2);
    });
  });

  // ============================================
  // Test 9: Handles fetch error
  // ============================================
  it('handles fetch error', async () => {
    mockGetFiltered.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch leads' },
    });

    const { result } = renderHook(() => useLeads());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Failed to fetch leads');
    expect(result.current.leads).toHaveLength(0);
  });

  // ============================================
  // Test 10: Returns empty list when no auth
  // ============================================
  it('returns empty list when no businessId', async () => {
    // Clear the mock and set up a new return value for this test
    const authModule = await import('../../context/AuthContext');
    vi.mocked(authModule.useAuth).mockReturnValue({
      crmUser: null,
      businessId: null,
      user: null,
      isLoading: false,
      error: null,
      status: 'unauthenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    const { result } = renderHook(() => useLeads());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.leads).toHaveLength(0);

    // Restore the mock for other tests
    vi.mocked(authModule.useAuth).mockReturnValue({
      crmUser: mockCrmUser,
      businessId: 'business-123',
      user: { uid: 'user-123' } as never,
      isLoading: false,
      error: null,
      status: 'authenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });
  });
});
