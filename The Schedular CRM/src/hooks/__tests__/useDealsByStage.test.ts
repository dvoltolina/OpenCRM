/**
 * useDealsByStage Hook Tests
 *
 * Agent CRM-09 Implementation
 *
 * Test Scenarios:
 * 1. Groups deals by stage
 * 2. Orders stages correctly
 * 3. Calculates stage totals
 * 4. Updates when deal moves
 * 5. Handles empty stages
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useDealsByStage } from '../useDealsByStage';
import type { Deal, Stage } from '../../types/models';

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
// Mock Data
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

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    pipelineId: 'pipeline-123',
    stageId: 'stage-1',
    title: 'Deal A',
    valueCents: 100000,
    currency: 'USD',
    probability: 10,
    status: 'open',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-2',
    pipelineId: 'pipeline-123',
    stageId: 'stage-1',
    title: 'Deal B',
    valueCents: 200000,
    currency: 'USD',
    probability: 10,
    status: 'open',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-3',
    pipelineId: 'pipeline-123',
    stageId: 'stage-2',
    title: 'Deal C',
    valueCents: 300000,
    currency: 'USD',
    probability: 25,
    status: 'open',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'deal-4',
    pipelineId: 'pipeline-123',
    stageId: 'stage-1',
    title: 'Closed Deal',
    valueCents: 500000,
    currency: 'USD',
    probability: 100,
    status: 'won', // Closed deals should not appear in kanban
    tags: [],
    createdAt: new Date(),
  },
];

const mockGetByPipeline = vi.fn();
const mockGetActiveByPipeline = vi.fn();

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getByPipeline: mockGetByPipeline,
  })),
}));

vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: vi.fn(() => ({
    getActiveByPipeline: mockGetActiveByPipeline,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useDealsByStage', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock responses
    mockGetByPipeline.mockResolvedValue({
      success: true,
      data: mockDeals,
      error: null,
    });

    mockGetActiveByPipeline.mockResolvedValue({
      success: true,
      data: mockStages,
      error: null,
    });
  });

  // ============================================
  // Test 1: Groups deals by stage
  // ============================================
  it('groups deals by stage', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const { dealsByStage } = result.current;

    // Stage 1 should have 2 open deals (not the closed one)
    expect(dealsByStage['stage-1'].count).toBe(2);
    expect(dealsByStage['stage-1'].deals.map((d) => d.id)).toContain('deal-1');
    expect(dealsByStage['stage-1'].deals.map((d) => d.id)).toContain('deal-2');

    // Stage 2 should have 1 deal
    expect(dealsByStage['stage-2'].count).toBe(1);
    expect(dealsByStage['stage-2'].deals[0].id).toBe('deal-3');

    // Stage 3 should be empty
    expect(dealsByStage['stage-3'].count).toBe(0);
    expect(dealsByStage['stage-3'].deals).toHaveLength(0);
  });

  // ============================================
  // Test 2: Orders stages correctly
  // ============================================
  it('orders stages correctly', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const { stages } = result.current;

    expect(stages).toHaveLength(3);
    expect(stages[0].name).toBe('Lead');
    expect(stages[0].order).toBe(0);
    expect(stages[1].name).toBe('Qualified');
    expect(stages[1].order).toBe(1);
    expect(stages[2].name).toBe('Proposal');
    expect(stages[2].order).toBe(2);
  });

  // ============================================
  // Test 3: Calculates stage totals
  // ============================================
  it('calculates stage totals', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const { dealsByStage } = result.current;

    // Stage 1: 100000 + 200000 = 300000 (closed deal excluded)
    expect(dealsByStage['stage-1'].totalValue).toBe(300000);

    // Stage 2: 300000
    expect(dealsByStage['stage-2'].totalValue).toBe(300000);

    // Stage 3: 0
    expect(dealsByStage['stage-3'].totalValue).toBe(0);
  });

  // ============================================
  // Test 4: Updates when data refreshed
  // ============================================
  it('updates when refresh is called', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockGetByPipeline).toHaveBeenCalledTimes(1);
    expect(mockGetActiveByPipeline).toHaveBeenCalledTimes(1);

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockGetByPipeline).toHaveBeenCalledTimes(2);
      expect(mockGetActiveByPipeline).toHaveBeenCalledTimes(2);
    });
  });

  // ============================================
  // Test 5: Handles empty stages
  // ============================================
  it('handles empty stages', async () => {
    // Return only deals for stage-1
    mockGetByPipeline.mockResolvedValue({
      success: true,
      data: mockDeals.filter((d) => d.stageId === 'stage-1' && d.status === 'open'),
      error: null,
    });

    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const { dealsByStage } = result.current;

    // Stage 2 and 3 should exist but be empty
    expect(dealsByStage['stage-2']).toBeDefined();
    expect(dealsByStage['stage-2'].count).toBe(0);
    expect(dealsByStage['stage-2'].deals).toHaveLength(0);

    expect(dealsByStage['stage-3']).toBeDefined();
    expect(dealsByStage['stage-3'].count).toBe(0);
    expect(dealsByStage['stage-3'].deals).toHaveLength(0);
  });

  // ============================================
  // Additional Tests
  // ============================================
  it('calculates pipeline totals', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    // 100000 + 200000 + 300000 = 600000 (closed deal excluded)
    expect(result.current.pipelineValue).toBe(600000);
    expect(result.current.pipelineCount).toBe(3);
  });

  it('returns empty when pipelineId is undefined', async () => {
    const { result } = renderHook(() => useDealsByStage(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.stages).toHaveLength(0);
    expect(Object.keys(result.current.dealsByStage)).toHaveLength(0);
    expect(result.current.error).toBeNull();
  });

  it('handles fetch error', async () => {
    mockGetByPipeline.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NETWORK_ERROR', message: 'Failed to fetch' },
    });

    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe(
      'Pipeline pipeline-123: Unable to load deals for pipeline pipeline-123: Failed to fetch'
    );
  });

  it('includes stage info in dealsByStage', async () => {
    const { result } = renderHook(() => useDealsByStage('pipeline-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const { dealsByStage } = result.current;

    // Each stage entry should include the stage object
    expect(dealsByStage['stage-1'].stage.name).toBe('Lead');
    expect(dealsByStage['stage-1'].stage.colorHex).toBe('#6B7280');
    expect(dealsByStage['stage-2'].stage.name).toBe('Qualified');
    expect(dealsByStage['stage-3'].stage.name).toBe('Proposal');
  });
});
