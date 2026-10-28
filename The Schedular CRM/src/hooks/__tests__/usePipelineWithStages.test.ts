/**
 * usePipelineWithStages Hook Tests
 *
 * Validates access-filtered pipeline retrieval and empty-state handling.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import type { Pipeline, Stage } from '../../types/models';

// ============================================
// Mocks
// ============================================

const authMocks = vi.hoisted(() => ({
  mockAuthUser: {
    id: 'user-1',
    displayName: 'Test User',
    role: 'staff',
    businessId: 'biz-1',
    email: 'test@example.com',
    teamIds: ['team-1'],
  },
  mockUseAuth: vi.fn(),
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: authMocks.mockUseAuth,
}));

const mockGetDefault = vi.fn();
const mockGetActive = vi.fn();
const mockGetById = vi.fn();
vi.mock('../../data/repositories/pipeline-repository', () => ({
  getPipelineRepository: vi.fn(() => ({
    getDefault: mockGetDefault,
    getActive: mockGetActive,
    getById: mockGetById,
    create: vi.fn(),
    setDefault: vi.fn(),
  })),
  DEFAULT_STAGES: [],
}));

const mockGetActiveByPipeline = vi.fn();
const mockCreateMany = vi.fn();
vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: vi.fn(() => ({
    getActiveByPipeline: mockGetActiveByPipeline,
    createMany: mockCreateMany,
  })),
}));

import { usePipelineWithStages } from '../usePipelineWithStages';

// ============================================
// Fixtures
// ============================================

const pipeline: Pipeline = {
  id: 'pipe-1',
  name: 'Sales',
  isDefault: true,
  isActive: true,
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: ['team-1'],
  createdAt: new Date(),
};

const stages: Stage[] = [
  {
    id: 'stage-1',
    name: 'Lead',
    order: 0,
    pipelineId: 'pipe-1',
    probability: 10,
    colorHex: '#6B7280',
    isActive: true,
    createdAt: new Date(),
  },
];

// ============================================
// Tests
// ============================================

describe('usePipelineWithStages', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    authMocks.mockUseAuth.mockReturnValue({
      crmUser: authMocks.mockAuthUser,
      businessId: authMocks.mockAuthUser.businessId,
    });
  });

  it('returns pipeline and stages when default is accessible', async () => {
    mockGetDefault.mockResolvedValue({ success: true, data: pipeline, error: null });
    mockGetActiveByPipeline.mockResolvedValue({ success: true, data: stages, error: null });

    const { result } = renderHook(() => usePipelineWithStages());

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.pipeline?.id).toBe('pipe-1');
    expect(result.current.stages).toHaveLength(1);
    expect(result.current.canCreatePipeline).toBe(false);
    expect(mockGetDefault).toHaveBeenCalled();
    expect(mockGetActiveByPipeline).toHaveBeenCalledWith(
      expect.any(Object),
      'pipe-1',
      authMocks.mockAuthUser.teamIds
    );
  });

  it('sets creation path when no accessible pipeline exists', async () => {
    mockGetDefault.mockResolvedValue({ success: true, data: null, error: null });
    mockGetActive.mockResolvedValue({
      success: true,
      data: { data: [], hasMore: false, lastDoc: null },
      error: null,
    });
    mockGetActiveByPipeline.mockResolvedValue({ success: true, data: [], error: null });

    const { result } = renderHook(() => usePipelineWithStages());

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.pipeline).toBeNull();
    expect(result.current.canCreatePipeline).toBe(true);
  });

  it('blocks creation path for front desk users when no pipeline is accessible', async () => {
    const frontDeskUser = { ...authMocks.mockAuthUser, role: 'frontDesk' };
    authMocks.mockUseAuth.mockReturnValue({
      crmUser: frontDeskUser,
      businessId: frontDeskUser.businessId,
    });

    mockGetDefault.mockResolvedValue({ success: true, data: null, error: null });
    mockGetActive.mockResolvedValue({
      success: true,
      data: { data: [], hasMore: false, lastDoc: null },
      error: null,
    });

    const { result } = renderHook(() => usePipelineWithStages());

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.pipeline).toBeNull();
    expect(result.current.canCreatePipeline).toBe(false);
  });
});
