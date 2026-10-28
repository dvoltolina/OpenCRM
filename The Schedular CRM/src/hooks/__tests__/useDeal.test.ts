/**
 * useDeal Hook Tests
 *
 * Agent CRM-09 Implementation
 *
 * Test Scenarios:
 * 1. Returns deal with stage
 * 2. Returns linked client
 * 3. Returns linked company
 * 4. Returns deal activities
 * 5. moveToStage updates deal (via useDealMutations)
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useDeal } from '../useDeal';
import type { Deal, Stage, Client, Company, SalesActivity } from '../../types/models';

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

const mockDeal: Deal = {
  id: 'deal-123',
  pipelineId: 'pipeline-123',
  stageId: 'stage-1',
  title: 'Enterprise Deal',
  valueCents: 500000,
  currency: 'USD',
  probability: 75,
  status: 'open',
  clientId: 'client-123',
  clientName: 'John Smith',
  companyId: 'company-123',
  companyName: 'Acme Corp',
  tags: [],
  createdAt: new Date(),
};

const mockStage: Stage = {
  id: 'stage-1',
  pipelineId: 'pipeline-123',
  name: 'Qualified',
  order: 1,
  colorHex: '#3B82F6',
  probability: 25,
  isActive: true,
  createdAt: new Date(),
};

const mockClient: Client = {
  id: 'client-123',
  firstName: 'John',
  lastName: 'Smith',
  email: 'john@example.com',
  phone: '555-1234',
  tags: [],
  createdAt: new Date(),
};

const mockCompany: Company = {
  id: 'company-123',
  name: 'Acme Corp',
  industry: 'Technology',
  size: 'medium',
  tags: [],
  createdAt: new Date(),
};

const mockActivities: SalesActivity[] = [
  {
    id: 'activity-1',
    type: 'call',
    title: 'Discovery Call',
    dealId: 'deal-123',
    isCompleted: true,
    completedAt: new Date(),
    createdById: 'user-123',
    createdByName: 'Test User',
    createdAt: new Date(),
  },
  {
    id: 'activity-2',
    type: 'email',
    title: 'Follow-up Email',
    dealId: 'deal-123',
    isCompleted: false,
    createdById: 'user-123',
    createdByName: 'Test User',
    createdAt: new Date(),
  },
];

// ============================================
// Mock Repositories
// ============================================

const mockDealGetById = vi.fn();
const mockStageGetById = vi.fn();
const mockContactGetById = vi.fn();
const mockCompanyGetById = vi.fn();
const mockActivityGetByDeal = vi.fn();

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getById: mockDealGetById,
  })),
}));

vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: vi.fn(() => ({
    getById: mockStageGetById,
  })),
}));

vi.mock('../../data/repositories/contact-repository', () => ({
  getContactRepository: vi.fn(() => ({
    getById: mockContactGetById,
  })),
}));

vi.mock('../../data/repositories/company-repository', () => ({
  getCompanyRepository: vi.fn(() => ({
    getById: mockCompanyGetById,
  })),
}));

vi.mock('../../data/repositories/activity-repository', () => ({
  getActivityRepository: vi.fn(() => ({
    getByDeal: mockActivityGetByDeal,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useDeal', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock responses
    mockDealGetById.mockResolvedValue({
      success: true,
      data: mockDeal,
      error: null,
    });

    mockStageGetById.mockResolvedValue({
      success: true,
      data: mockStage,
      error: null,
    });

    mockContactGetById.mockResolvedValue({
      success: true,
      data: mockClient,
      error: null,
    });

    mockCompanyGetById.mockResolvedValue({
      success: true,
      data: mockCompany,
      error: null,
    });

    mockActivityGetByDeal.mockResolvedValue({
      success: true,
      data: { data: mockActivities, hasMore: false, lastDoc: null },
      error: null,
    });
  });

  // ============================================
  // Test 1: Returns deal with stage
  // ============================================
  it('returns deal with stage', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deal).not.toBeNull();
    expect(result.current.deal?.id).toBe('deal-123');
    expect(result.current.deal?.title).toBe('Enterprise Deal');

    expect(result.current.stage).not.toBeNull();
    expect(result.current.stage?.id).toBe('stage-1');
    expect(result.current.stage?.name).toBe('Qualified');
  });

  // ============================================
  // Test 2: Returns linked client
  // ============================================
  it('returns linked client', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.client).not.toBeNull();
    expect(result.current.client?.id).toBe('client-123');
    expect(result.current.client?.firstName).toBe('John');
    expect(result.current.client?.lastName).toBe('Smith');
    expect(result.current.client?.email).toBe('john@example.com');
  });

  // ============================================
  // Test 3: Returns linked company
  // ============================================
  it('returns linked company', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.company).not.toBeNull();
    expect(result.current.company?.id).toBe('company-123');
    expect(result.current.company?.name).toBe('Acme Corp');
    expect(result.current.company?.industry).toBe('Technology');
  });

  // ============================================
  // Test 4: Returns deal activities
  // ============================================
  it('returns deal activities', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.activities).toHaveLength(2);
    expect(result.current.activities[0].type).toBe('call');
    expect(result.current.activities[0].title).toBe('Discovery Call');
    expect(result.current.activities[1].type).toBe('email');
    expect(result.current.activities[1].title).toBe('Follow-up Email');
  });

  // ============================================
  // Test 5: Returns null when deal not found
  // ============================================
  it('returns null and error when deal not found', async () => {
    mockDealGetById.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NOT_FOUND', message: 'Deal not found' },
    });

    const { result } = renderHook(() => useDeal('non-existent'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deal).toBeNull();
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Deal not found');
  });

  // ============================================
  // Additional Tests
  // ============================================
  it('returns null when dealId is undefined', async () => {
    const { result } = renderHook(() => useDeal(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deal).toBeNull();
    expect(result.current.stage).toBeNull();
    expect(result.current.client).toBeNull();
    expect(result.current.company).toBeNull();
    expect(result.current.activities).toHaveLength(0);
    expect(result.current.error).toBeNull();
  });

  it('handles deal without client', async () => {
    const dealWithoutClient = { ...mockDeal, clientId: undefined };
    mockDealGetById.mockResolvedValue({
      success: true,
      data: dealWithoutClient,
      error: null,
    });

    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deal).not.toBeNull();
    expect(result.current.client).toBeNull();
    expect(mockContactGetById).not.toHaveBeenCalled();
  });

  it('handles deal without company', async () => {
    const dealWithoutCompany = { ...mockDeal, companyId: undefined };
    mockDealGetById.mockResolvedValue({
      success: true,
      data: dealWithoutCompany,
      error: null,
    });

    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deal).not.toBeNull();
    expect(result.current.company).toBeNull();
    expect(mockCompanyGetById).not.toHaveBeenCalled();
  });

  it('refresh triggers new fetch', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(mockDealGetById).toHaveBeenCalledTimes(1);

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockDealGetById).toHaveBeenCalledTimes(2);
    });
  });

  it('fetches all related data in parallel', async () => {
    const { result } = renderHook(() => useDeal('deal-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    // All related repositories should have been called
    expect(mockDealGetById).toHaveBeenCalledTimes(1);
    expect(mockStageGetById).toHaveBeenCalledTimes(1);
    expect(mockContactGetById).toHaveBeenCalledTimes(1);
    expect(mockCompanyGetById).toHaveBeenCalledTimes(1);
    expect(mockActivityGetByDeal).toHaveBeenCalledTimes(1);
  });
});
