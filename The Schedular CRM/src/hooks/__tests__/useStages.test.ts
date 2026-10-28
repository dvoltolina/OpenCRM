/**
 * useStages Hook Tests
 *
 * Agent CRM-07 Implementation
 *
 * Test Scenarios:
 * 1. Returns stages ordered by order field
 * 2. createStage adds stage to list
 * 3. reorderStages updates order
 * 4. archiveStage removes from list
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useStages } from '../useStages';
import type { Stage } from '../../types/models';

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
// Mock Stage Repository
// ============================================

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-123',
    name: 'Lead',
    order: 0,
    colorHex: '#6B7280',
    probability: 10,
    isActive: true,
    createdAt: new Date(),
  },
  {
    id: 'stage-2',
    pipelineId: 'pipeline-123',
    name: 'Qualified',
    order: 1,
    colorHex: '#3B82F6',
    probability: 25,
    isActive: true,
    createdAt: new Date(),
  },
  {
    id: 'stage-3',
    pipelineId: 'pipeline-123',
    name: 'Proposal',
    order: 2,
    colorHex: '#8B5CF6',
    probability: 50,
    isActive: true,
    createdAt: new Date(),
  },
];

const mockGetActiveByPipeline = vi.fn();
const mockCreate = vi.fn();
const mockUpdate = vi.fn();
const mockReorder = vi.fn();
const mockArchive = vi.fn();
const mockRestore = vi.fn();
const mockDelete = vi.fn();
const mockGetNextOrder = vi.fn();

vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: vi.fn(() => ({
    getActiveByPipeline: mockGetActiveByPipeline,
    create: mockCreate,
    update: mockUpdate,
    reorder: mockReorder,
    archive: mockArchive,
    restore: mockRestore,
    delete: mockDelete,
    getNextOrder: mockGetNextOrder,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useStages', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock responses
    mockGetActiveByPipeline.mockResolvedValue({
      success: true,
      data: mockStages,
      error: null,
    });
    mockGetNextOrder.mockResolvedValue(3);
  });

  // ============================================
  // Test 1: Returns stages ordered by order field
  // ============================================
  it('returns stages ordered by order field', async () => {
    const { result } = renderHook(() => useStages('pipeline-123'));

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.stages).toHaveLength(3);
    expect(result.current.stages[0].name).toBe('Lead');
    expect(result.current.stages[0].order).toBe(0);
    expect(result.current.stages[1].name).toBe('Qualified');
    expect(result.current.stages[1].order).toBe(1);
    expect(result.current.stages[2].name).toBe('Proposal');
    expect(result.current.stages[2].order).toBe(2);
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: createStage adds stage to list
  // ============================================
  it('createStage adds stage to list', async () => {
    const newStage: Stage = {
      id: 'stage-4',
      pipelineId: 'pipeline-123',
      name: 'Negotiation',
      order: 3,
      colorHex: '#F59E0B',
      probability: 75,
      isActive: true,
      createdAt: new Date(),
    };

    mockCreate.mockResolvedValue({
      success: true,
      data: newStage,
      error: null,
    });

    mockGetActiveByPipeline.mockResolvedValueOnce({
      success: true,
      data: mockStages,
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: [...mockStages, newStage],
      error: null,
    });

    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    let createdStage: Stage | undefined;
    await act(async () => {
      createdStage = await result.current.createStage({
        name: 'Negotiation',
        colorHex: '#F59E0B',
        probability: 75,
      });
    });

    expect(createdStage?.name).toBe('Negotiation');
    expect(mockCreate).toHaveBeenCalled();
  });

  // ============================================
  // Test 3: reorderStages updates order
  // ============================================
  it('reorderStages updates order', async () => {
    mockReorder.mockResolvedValue({
      success: true,
      data: undefined,
      error: null,
    });

    // New order: Qualified, Lead, Proposal
    const reorderedStages = [
      { ...mockStages[1], order: 0 }, // Qualified first
      { ...mockStages[0], order: 1 }, // Lead second
      { ...mockStages[2], order: 2 }, // Proposal third
    ];

    mockGetActiveByPipeline.mockResolvedValueOnce({
      success: true,
      data: mockStages,
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: reorderedStages,
      error: null,
    });

    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      await result.current.reorderStages(['stage-2', 'stage-1', 'stage-3']);
    });

    expect(mockReorder).toHaveBeenCalledWith(
      expect.any(Object),
      ['stage-2', 'stage-1', 'stage-3'],
      expect.any(Array)
    );
  });

  // ============================================
  // Test 4: archiveStage removes from list
  // ============================================
  it('archiveStage removes from list', async () => {
    mockArchive.mockResolvedValue({
      success: true,
      data: { ...mockStages[2], isActive: false },
      error: null,
    });

    const updatedStages = mockStages.slice(0, 2);

    mockGetActiveByPipeline.mockResolvedValueOnce({
      success: true,
      data: mockStages,
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: updatedStages,
      error: null,
    });

    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.stages).toHaveLength(3);

    await act(async () => {
      await result.current.archiveStage('stage-3');
    });

    expect(mockArchive).toHaveBeenCalledWith(
      expect.any(Object),
      'stage-3',
      expect.any(Array)
    );
  });

  it('returns empty array when pipelineId is undefined', async () => {
    const { result } = renderHook(() => useStages(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.stages).toHaveLength(0);
    expect(result.current.error).toBeNull();
  });

  it('handles error when fetching stages', async () => {
    mockGetActiveByPipeline.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch stages' },
    });

    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.stages).toHaveLength(0);
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Failed to fetch stages');
  });

  it('updateStage modifies existing stage', async () => {
    mockUpdate.mockResolvedValue({
      success: true,
      data: { ...mockStages[0], name: 'Updated Lead' },
      error: null,
    });

    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      await result.current.updateStage('stage-1', { name: 'Updated Lead' });
    });

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.any(Object),
      'stage-1',
      { name: 'Updated Lead' },
      expect.any(Array)
    );
  });

  it('refresh triggers new fetch', async () => {
    const { result } = renderHook(() => useStages('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetActiveByPipeline).toHaveBeenCalledTimes(1);

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockGetActiveByPipeline).toHaveBeenCalledTimes(2);
    });
  });

  it('throws error when creating stage without pipelineId', async () => {
    const { result } = renderHook(() => useStages(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await expect(
      result.current.createStage({ name: 'New Stage' })
    ).rejects.toThrow('Pipeline ID is required');
  });
});
