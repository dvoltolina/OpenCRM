/**
 * usePipelines Hook Tests
 *
 * Agent CRM-07 Implementation
 *
 * Test Scenarios:
 * 1. Returns all active pipelines
 * 2. Identifies default pipeline
 * 3. createPipeline adds new pipeline
 * 4. setDefaultPipeline updates default
 * 5. archivePipeline removes from list
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { usePipelines } from '../usePipelines';
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

const mockPipelines: Pipeline[] = [
  {
    id: 'pipeline-1',
    name: 'Sales Pipeline',
    isDefault: true,
    isActive: true,
    ownerId: 'user-123',
    ownerName: 'Test User',
    teamIds: [],
    createdAt: new Date(),
  },
  {
    id: 'pipeline-2',
    name: 'Marketing Pipeline',
    isDefault: false,
    isActive: true,
    ownerId: 'user-123',
    ownerName: 'Test User',
    teamIds: [],
    createdAt: new Date(),
  },
];

const mockGetActive = vi.fn();
const mockCreate = vi.fn();
const mockSetDefault = vi.fn();
const mockArchive = vi.fn();
const mockRestore = vi.fn();
const mockUpdate = vi.fn();
const mockDelete = vi.fn();

vi.mock('../../data/repositories/pipeline-repository', () => ({
  getPipelineRepository: vi.fn(() => ({
    getActive: mockGetActive,
    create: mockCreate,
    setDefault: mockSetDefault,
    archive: mockArchive,
    restore: mockRestore,
    update: mockUpdate,
    delete: mockDelete,
  })),
}));

// ============================================
// Tests
// ============================================

describe('usePipelines', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock responses
    mockGetActive.mockResolvedValue({
      success: true,
      data: { data: mockPipelines, hasMore: false, lastDoc: null },
      error: null,
    });
  });

  // ============================================
  // Test 1: Returns all active pipelines
  // ============================================
  it('returns all active pipelines', async () => {
    const { result } = renderHook(() => usePipelines());

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipelines).toHaveLength(2);
    expect(result.current.pipelines[0].name).toBe('Sales Pipeline');
    expect(result.current.pipelines[1].name).toBe('Marketing Pipeline');
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: Identifies default pipeline
  // ============================================
  it('identifies default pipeline', async () => {
    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.defaultPipeline).not.toBeNull();
    expect(result.current.defaultPipeline?.id).toBe('pipeline-1');
    expect(result.current.defaultPipeline?.isDefault).toBe(true);
  });

  // ============================================
  // Test 3: createPipeline adds new pipeline
  // ============================================
  it('createPipeline adds new pipeline', async () => {
    const newPipeline: Pipeline = {
      id: 'pipeline-3',
      name: 'New Pipeline',
      isDefault: false,
      isActive: true,
      ownerId: 'user-123',
      ownerName: 'Test User',
      teamIds: [],
      createdAt: new Date(),
    };

    mockCreate.mockResolvedValue({
      success: true,
      data: newPipeline,
      error: null,
    });

    // After create, return updated list
    mockGetActive.mockResolvedValueOnce({
      success: true,
      data: { data: mockPipelines, hasMore: false, lastDoc: null },
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: { data: [...mockPipelines, newPipeline], hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    let createdPipeline: Pipeline | undefined;
    await act(async () => {
      createdPipeline = await result.current.createPipeline({ name: 'New Pipeline' });
    });

    expect(createdPipeline?.name).toBe('New Pipeline');
    expect(mockCreate).toHaveBeenCalled();
  });

  // ============================================
  // Test 4: setDefaultPipeline updates default
  // ============================================
  it('setDefaultPipeline updates default', async () => {
    mockSetDefault.mockResolvedValue({
      success: true,
      data: { ...mockPipelines[1], isDefault: true },
      error: null,
    });

    const updatedPipelines = [
      { ...mockPipelines[0], isDefault: false },
      { ...mockPipelines[1], isDefault: true },
    ];

    mockGetActive.mockResolvedValueOnce({
      success: true,
      data: { data: mockPipelines, hasMore: false, lastDoc: null },
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: { data: updatedPipelines, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      await result.current.setDefaultPipeline('pipeline-2');
    });

    expect(mockSetDefault).toHaveBeenCalledWith(
      expect.any(Object),
      'pipeline-2'
    );
  });

  // ============================================
  // Test 5: archivePipeline removes from list
  // ============================================
  it('archivePipeline removes from list', async () => {
    mockArchive.mockResolvedValue({
      success: true,
      data: { ...mockPipelines[1], isActive: false },
      error: null,
    });

    const updatedPipelines = [mockPipelines[0]];

    mockGetActive.mockResolvedValueOnce({
      success: true,
      data: { data: mockPipelines, hasMore: false, lastDoc: null },
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: { data: updatedPipelines, hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipelines).toHaveLength(2);

    await act(async () => {
      await result.current.archivePipeline('pipeline-2');
    });

    expect(mockArchive).toHaveBeenCalledWith(
      expect.any(Object),
      'pipeline-2'
    );
  });

  it('handles error when fetching pipelines', async () => {
    mockGetActive.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch' },
    });

    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.pipelines).toHaveLength(0);
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Failed to fetch');
  });

  it('refresh triggers new fetch', async () => {
    const { result } = renderHook(() => usePipelines());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetActive).toHaveBeenCalledTimes(1);

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockGetActive).toHaveBeenCalledTimes(2);
    });
  });
});
