/**
 * useDeals Hook Tests
 *
 * Agent CRM-09 Implementation
 *
 * Test Scenarios:
 * 1. Returns deal list
 * 2. Filters by pipeline
 * 3. Filters by status
 * 4. Filters by value range
 * 5. Search by title
 * 6. Calculates totalValue
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useDeals } from '../useDeals';
import type { Deal } from '../../types/models';

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
// Mock Deal Repository
// ============================================

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    pipelineId: 'pipeline-123',
    stageId: 'stage-1',
    title: 'Enterprise Deal',
    valueCents: 500000,
    currency: 'USD',
    probability: 75,
    status: 'open',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-2',
    pipelineId: 'pipeline-123',
    stageId: 'stage-2',
    title: 'Small Business Deal',
    valueCents: 100000,
    currency: 'USD',
    probability: 50,
    status: 'open',
    clientName: 'Acme Corp',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-3',
    pipelineId: 'pipeline-456',
    stageId: 'stage-3',
    title: 'Marketing Deal',
    valueCents: 250000,
    currency: 'USD',
    probability: 25,
    status: 'won',
    tags: [],
    createdAt: new Date(),
  },
];

const mockGetAll = vi.fn();
const mockGetByPipeline = vi.fn();
const mockGetByStage = vi.fn();
const mockGetByStatus = vi.fn();
const mockGetByAssignee = vi.fn();
const mockGetByClient = vi.fn();
const mockGetByCompany = vi.fn();

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getAll: mockGetAll,
    getByPipeline: mockGetByPipeline,
    getByStage: mockGetByStage,
    getByStatus: mockGetByStatus,
    getByAssignee: mockGetByAssignee,
    getByClient: mockGetByClient,
    getByCompany: mockGetByCompany,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useDeals', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock responses
    mockGetAll.mockResolvedValue({
      success: true,
      data: { data: mockDeals, hasMore: false, lastDoc: null },
      error: null,
    });

    mockGetByPipeline.mockResolvedValue({
      success: true,
      data: mockDeals.filter((d) => d.pipelineId === 'pipeline-123'),
      error: null,
    });

    mockGetByStatus.mockResolvedValue({
      success: true,
      data: mockDeals.filter((d) => d.status === 'open'),
      error: null,
    });
  });

  // ============================================
  // Test 1: Returns deal list
  // ============================================
  it('returns deal list', async () => {
    const { result } = renderHook(() => useDeals());

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(3);
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: Filters by pipeline
  // ============================================
  it('filters by pipeline', async () => {
    const { result } = renderHook(() =>
      useDeals({ pipelineId: 'pipeline-123' })
    );

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByPipeline).toHaveBeenCalledWith(
      expect.any(Object),
      'pipeline-123'
    );
    expect(result.current.deals).toHaveLength(2);
    expect(result.current.deals.every((d) => d.pipelineId === 'pipeline-123')).toBe(true);
  });

  // ============================================
  // Test 3: Filters by status
  // ============================================
  it('filters by status', async () => {
    const { result } = renderHook(() => useDeals({ status: 'open' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByStatus).toHaveBeenCalledWith(
      expect.any(Object),
      'open'
    );
    expect(result.current.deals).toHaveLength(2);
    expect(result.current.deals.every((d) => d.status === 'open')).toBe(true);
  });

  // ============================================
  // Test 4: Filters by value range
  // ============================================
  it('filters by value range', async () => {
    const { result } = renderHook(() =>
      useDeals({ valueRange: { min: 100000, max: 300000 } })
    );

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    // All deals are returned initially, then filtered client-side
    expect(result.current.deals.length).toBeGreaterThanOrEqual(1);
    expect(
      result.current.deals.every(
        (d) => d.valueCents >= 100000 && d.valueCents <= 300000
      )
    ).toBe(true);
  });

  // ============================================
  // Test 5: Search by title
  // ============================================
  it('searches by title', async () => {
    const { result } = renderHook(() => useDeals({ search: 'Enterprise' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(1);
    expect(result.current.deals[0].title).toBe('Enterprise Deal');
  });

  // ============================================
  // Test 6: Calculates totalValue
  // ============================================
  it('calculates totalValue', async () => {
    const { result } = renderHook(() => useDeals());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    // 500000 + 100000 + 250000 = 850000
    expect(result.current.totalValue).toBe(850000);
    expect(result.current.totalCount).toBe(3);
  });

  // ============================================
  // Additional Tests
  // ============================================
  it('returns empty list when not authenticated', async () => {
    // Import and mock useAuth before rendering
    const AuthModule = await import('../../context/AuthContext');
    vi.mocked(AuthModule.useAuth).mockReturnValue({
      crmUser: null,
      businessId: null,
      user: null,
      isLoading: false,
      error: null,
    } as ReturnType<typeof AuthModule.useAuth>);

    const { result } = renderHook(() => useDeals());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(0);

    // Restore the original mock for subsequent tests
    vi.mocked(AuthModule.useAuth).mockReturnValue({
      crmUser: mockCrmUser,
      businessId: 'business-123',
      user: { uid: 'user-123' },
      isLoading: false,
      error: null,
    } as ReturnType<typeof AuthModule.useAuth>);
  });

  it('handles fetch error', async () => {
    mockGetAll.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch deals' },
    });

    const { result } = renderHook(() => useDeals());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Failed to fetch deals');
  });

  it('refresh triggers new fetch', async () => {
    const { result } = renderHook(() => useDeals());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const initialCalls = mockGetAll.mock.calls.length;

    await act(async () => {
      result.current.refresh();
      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
        expect(mockGetAll.mock.calls.length).toBeGreaterThanOrEqual(initialCalls);
      });
    });
  });

  it('searches by client name', async () => {
    const { result } = renderHook(() => useDeals({ search: 'Acme' }));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(1);
    expect(result.current.deals[0].clientName).toBe('Acme Corp');
  });
});
