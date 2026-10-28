/**
 * usePipeline Hook Tests
 *
 * Agent CRM-07 Implementation
 *
 * Test Scenarios:
 * 1. Returns pipeline data when exists
 * 2. Returns null and error when not found
 * 3. Updates when pipeline changes (refresh)
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { usePipeline, createSecurityContext } from '../usePipeline';
import type { Pipeline } from '../../types/models';

// ============================================
// Mock Auth Context
// ============================================

const mockCrmUser = {
  id: 'user-123',
  displayName: 'Test User',
  role: 'admin',
  businessId: 'business-123',
  email: 'test@example.com',
  teamIds: [],
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
// Mock Pipeline Repository
// ============================================

const mockPipeline: Pipeline = {
  id: 'pipeline-123',
  name: 'Sales Pipeline',
  isDefault: true,
  isActive: true,
  ownerId: 'user-123',
  ownerName: 'Test User',
  teamIds: [],
  createdAt: new Date(),
};

const mockGetById = vi.fn();

vi.mock('../../data/repositories/pipeline-repository', () => ({
  getPipelineRepository: vi.fn(() => ({
    getById: mockGetById,
  })),
}));

// ============================================
// Tests
// ============================================

describe('usePipeline', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Returns pipeline data when exists
  // ============================================
  it('returns pipeline data when exists', async () => {
    mockGetById.mockResolvedValue({
      success: true,
      data: mockPipeline,
      error: null,
    });

    const { result } = renderHook(() => usePipeline('pipeline-123'));

    // Initially loading
    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipeline).toEqual(mockPipeline);
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: Returns null and error when not found
  // ============================================
  it('returns null and error when not found', async () => {
    mockGetById.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NOT_FOUND', message: 'Pipeline not found' },
    });

    const { result } = renderHook(() => usePipeline('non-existent'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipeline).toBeNull();
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Pipeline not found');
  });

  // ============================================
  // Test 3: Updates when refresh is called
  // ============================================
  it('updates when refresh is called', async () => {
    const updatedPipeline = { ...mockPipeline, name: 'Updated Pipeline' };

    mockGetById
      .mockResolvedValueOnce({
        success: true,
        data: mockPipeline,
        error: null,
      })
      .mockResolvedValueOnce({
        success: true,
        data: updatedPipeline,
        error: null,
      });

    const { result } = renderHook(() => usePipeline('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipeline?.name).toBe('Sales Pipeline');

    // Call refresh
    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(result.current.pipeline?.name).toBe('Updated Pipeline');
    });
  });

  it('returns null when pipelineId is undefined', async () => {
    const { result } = renderHook(() => usePipeline(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipeline).toBeNull();
    expect(result.current.error).toBeNull();
  });
});

describe('createSecurityContext', () => {
  it('creates a valid security context', () => {
    const context = createSecurityContext(
      'business-123',
      'user-456',
      'John Doe',
      'admin'
    );

    expect(context).toEqual({
      businessId: 'business-123',
      userId: 'user-456',
      userName: 'John Doe',
      userRole: 'admin',
      teamIds: [],
      managedTeamIds: [],
      managerId: undefined,
      requiresHipaaCompliance: false,
      auditLoggingEnabled: false,
    });
  });
});
