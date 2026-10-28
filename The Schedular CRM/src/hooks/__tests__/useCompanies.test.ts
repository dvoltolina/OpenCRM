/**
 * useCompanies Hook Tests
 *
 * Agent CRM-10 Implementation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useCompanies } from '../useCompanies';
import type { Company } from '../../types/models';

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
// Mock Company Repository
// ============================================

const mockCompanies: Company[] = [
  {
    id: 'company-1',
    name: 'Acme Corp',
    industry: 'Technology',
    size: 'enterprise',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'company-2',
    name: 'Beta Industries',
    industry: 'Manufacturing',
    size: 'large',
    tags: [],
    createdAt: new Date(),
  },
];

const mockGetFiltered = vi.fn();
const mockGetByIndustry = vi.fn();
const mockGetBySize = vi.fn();
const mockSearch = vi.fn();
const mockGetUniqueIndustries = vi.fn();

vi.mock('../../data/repositories/company-repository', () => ({
  getCompanyRepository: vi.fn(() => ({
    getFiltered: mockGetFiltered,
    getByIndustry: mockGetByIndustry,
    getBySize: mockGetBySize,
    search: mockSearch,
    getUniqueIndustries: mockGetUniqueIndustries,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useCompanies', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockGetFiltered.mockResolvedValue({
      success: true,
      data: mockCompanies,
    });

    mockSearch.mockResolvedValue({
      success: true,
      data: mockCompanies,
    });

    mockGetUniqueIndustries.mockResolvedValue({
      success: true,
      data: ['Technology', 'Manufacturing'],
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('returns company list', async () => {
    const { result } = renderHook(() => useCompanies());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.companies).toHaveLength(2);
    expect(result.current.companies[0].name).toBe('Acme Corp');
  });

  it('filters by industry', async () => {
    mockGetByIndustry.mockResolvedValue({
      success: true,
      data: { data: [mockCompanies[0]], hasMore: false, lastDoc: null },
    });

    const { result } = renderHook(() => useCompanies({ industry: 'Technology' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByIndustry).toHaveBeenCalledWith(
      expect.any(Object),
      'Technology'
    );
  });

  it('filters by size', async () => {
    mockGetBySize.mockResolvedValue({
      success: true,
      data: { data: [mockCompanies[0]], hasMore: false, lastDoc: null },
    });

    const { result } = renderHook(() => useCompanies({ size: 'enterprise' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetBySize).toHaveBeenCalledWith(
      expect.any(Object),
      'enterprise'
    );
  });

  it('searches by name', async () => {
    mockSearch.mockResolvedValue({
      success: true,
      data: { data: [mockCompanies[0]], hasMore: false, lastDoc: null },
    });

    renderHook(() => useCompanies({ search: 'acme' }));

    await waitFor(() => {
      expect(mockSearch).toHaveBeenCalled();
    }, { timeout: 500 });

    expect(mockSearch).toHaveBeenCalledWith(
      expect.any(Object),
      'acme'
    );
  });

  it('returns unique industries', async () => {
    const { result } = renderHook(() => useCompanies());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.industries).toContain('Technology');
    expect(result.current.industries).toContain('Manufacturing');
  });

  it('handles fetch error', async () => {
    mockGetFiltered.mockResolvedValue({
      success: false,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch' },
    });

    const { result } = renderHook(() => useCompanies());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
  });

  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useCompanies());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      result.current.refresh();
    });

    expect(mockGetFiltered).toHaveBeenCalledTimes(2);
  });
});
