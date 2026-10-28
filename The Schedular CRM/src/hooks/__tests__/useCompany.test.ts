/**
 * useCompany Hook Tests
 *
 * Agent CRM-10 Implementation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useCompany } from '../useCompany';
import type { Company, Client, Deal } from '../../types/models';

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
// Mock Repositories
// ============================================

const mockCompany: Company = {
  id: 'company-123',
  name: 'Acme Corp',
  industry: 'Technology',
  size: 'enterprise',
  tags: ['partner'],
  createdAt: new Date(),
};

const mockContacts: Client[] = [
  {
    id: 'contact-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    companyId: 'company-123',
    tags: [],
    createdAt: new Date(),
  },
  {
    id: 'contact-2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    companyId: 'company-123',
    tags: [],
    createdAt: new Date(),
  },
];

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    title: 'Enterprise Plan',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    status: 'open',
    valueCents: 5000000,
    currency: 'USD', // Added
    probability: 50, // Added
    tags: [], // Added
    companyId: 'company-123',
    createdAt: new Date(),
  },
  {
    id: 'deal-2',
    title: 'Support Contract',
    pipelineId: 'pipeline-1',
    stageId: 'stage-2',
    status: 'won',
    valueCents: 1000000,
    currency: 'USD', // Added
    probability: 100, // Added
    tags: [], // Added
    companyId: 'company-123',
    createdAt: new Date(),
  },
];

const mockCompanyGetById = vi.fn();
const mockContactGetByCompany = vi.fn();
const mockDealGetByCompany = vi.fn();

vi.mock('../../data/repositories/company-repository', () => ({
  getCompanyRepository: vi.fn(() => ({
    getById: mockCompanyGetById,
  })),
}));

vi.mock('../../data/repositories/contact-repository', () => ({
  getContactRepository: vi.fn(() => ({
    getByCompany: mockContactGetByCompany,
  })),
}));

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getByCompany: mockDealGetByCompany,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useCompany', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockCompanyGetById.mockResolvedValue({
      success: true,
      data: mockCompany,
    });

    mockContactGetByCompany.mockResolvedValue({
      success: true,
      data: mockContacts,
    });

    mockDealGetByCompany.mockResolvedValue({
      success: true,
      data: mockDeals,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('returns company with contacts', async () => {
    const { result } = renderHook(() => useCompany('company-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.company?.name).toBe('Acme Corp');
    expect(result.current.contacts).toHaveLength(2);
    expect(result.current.contactCount).toBe(2);
  });

  it('returns company deals', async () => {
    const { result } = renderHook(() => useCompany('company-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(2);
    expect(result.current.dealCount).toBe(2);
  });

  it('calculates total deal value', async () => {
    const { result } = renderHook(() => useCompany('company-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.totalDealValue).toBe(6000000);
  });

  it('returns null when company not found', async () => {
    mockCompanyGetById.mockResolvedValue({
      success: false,
      error: { code: 'NOT_FOUND', message: 'Company not found' },
    });

    const { result } = renderHook(() => useCompany('non-existent'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.company).toBeNull();
    expect(result.current.error?.message).toBe('Company not found');
  });

  it('returns null when companyId is undefined', async () => {
    const { result } = renderHook(() => useCompany(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.company).toBeNull();
    expect(mockCompanyGetById).not.toHaveBeenCalled();
  });

  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useCompany('company-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockCompanyGetById).toHaveBeenCalledTimes(2);
    });
  });
});
