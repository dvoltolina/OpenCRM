/**
 * useContacts Hook Tests
 *
 * Agent CRM-10 Implementation
 *
 * Test Scenarios:
 * 1. Returns contact list
 * 2. Filters by company
 * 3. Filters by lifecycle
 * 4. Search by name/email
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useContacts } from '../useContacts';
import type { Client } from '../../types/models';

// ============================================
// Mock Auth Context
// ============================================

const mockCrmUser = {
  id: 'user-123',
  displayName: 'Test User',
  role: 'admin',
  businessId: 'business-123',
  email: 'test@example.com',
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
// Mock Contact Repository
// ============================================

const mockContacts: Client[] = [
  {
    id: 'contact-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    phone: '+1234567890',
    companyId: 'company-1',
    companyName: 'Acme Corp',
    lifecycle: 'active',
    leadSource: 'website',
    tags: ['vip'],
    createdAt: new Date(),
  },
  {
    id: 'contact-2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    lifecycle: 'prospect',
    leadSource: 'referral',
    tags: ['lead'],
    createdAt: new Date(),
  },
  {
    id: 'contact-3',
    firstName: 'Bob',
    lastName: 'Johnson',
    email: 'bob@example.com',
    companyId: 'company-1',
    companyName: 'Acme Corp',
    lifecycle: 'active',
    leadSource: 'website',
    tags: [],
    createdAt: new Date(),
  },
];

const mockGetFiltered = vi.fn();
const mockGetByCompany = vi.fn();
const mockGetByLifecycle = vi.fn();
const mockSearch = vi.fn();

vi.mock('../../data/repositories/contact-repository', () => ({
  getContactRepository: vi.fn(() => ({
    getFiltered: mockGetFiltered,
    getByCompany: mockGetByCompany,
    getByLifecycle: mockGetByLifecycle,
    search: mockSearch,
    getStaleContacts: vi.fn(),
  })),
}));

// ============================================
// Tests
// ============================================

describe('useContacts', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockGetFiltered.mockResolvedValue({
      success: true,
      data: mockContacts,
    });

    mockSearch.mockResolvedValue({
      success: true,
      data: mockContacts,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('returns contact list', async () => {
    const { result } = renderHook(() => useContacts());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.contacts).toHaveLength(3);
    expect(result.current.contacts[0].firstName).toBe('John');
  });

  it('filters by company', async () => {
    mockGetByCompany.mockResolvedValue({
      success: true,
      data: { data: [mockContacts[0], mockContacts[2]], hasMore: false, lastDoc: null },
    });

    const { result } = renderHook(() => useContacts({ companyId: 'company-1' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByCompany).toHaveBeenCalled();
  });

  it('filters by lifecycle', async () => {
    mockGetByLifecycle.mockResolvedValue({
      success: true,
      data: { data: [mockContacts[0], mockContacts[2]], hasMore: false, lastDoc: null },
    });

    const { result } = renderHook(() => useContacts({ lifecycle: 'active' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByLifecycle).toHaveBeenCalledWith(
      expect.any(Object),
      'active'
    );
  });

  it('searches by name/email', async () => {
    mockSearch.mockResolvedValue({
      success: true,
      data: { data: [mockContacts[0]], hasMore: false, lastDoc: null },
    });

    renderHook(() => useContacts({ search: 'john' }));

    await waitFor(() => {
      expect(mockSearch).toHaveBeenCalled();
    }, { timeout: 500 });

    expect(mockSearch).toHaveBeenCalledWith(
      expect.any(Object),
      'john'
    );
  });

  it('handles fetch error', async () => {
    mockGetFiltered.mockResolvedValue({
      success: false,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch' },
    });

    const { result } = renderHook(() => useContacts());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
  });

  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useContacts());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      result.current.refresh();
    });

    expect(mockGetFiltered).toHaveBeenCalledTimes(2);
  });
});
