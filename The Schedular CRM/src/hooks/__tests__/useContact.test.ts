/**
 * useContact Hook Tests
 *
 * Agent CRM-10 Implementation
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useContact } from '../useContact';
import type { Client, Company, Deal } from '../../types/models';

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

const mockContact: Client = {
  id: 'contact-123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  companyId: 'company-123',
  companyName: 'Acme Corp',
  lifecycle: 'active', // Changed from 'customer'
  tags: [], // Added
  createdAt: new Date(),
};

const mockCompany: Company = {
  id: 'company-123',
  name: 'Acme Corp',
  industry: 'Technology',
  tags: [],
  createdAt: new Date(),
};

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
    clientId: 'contact-123',
    createdAt: new Date(),
  },
];

const mockContactGetById = vi.fn();
const mockCompanyGetById = vi.fn();
const mockDealGetByClient = vi.fn();

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

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getByClient: mockDealGetByClient,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useContact', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockContactGetById.mockResolvedValue({
      success: true,
      data: mockContact,
    });

    mockCompanyGetById.mockResolvedValue({
      success: true,
      data: mockCompany,
    });

    mockDealGetByClient.mockResolvedValue({
      success: true,
      data: mockDeals,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('returns contact with company', async () => {
    const { result } = renderHook(() => useContact('contact-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.contact?.firstName).toBe('John');
    expect(result.current.company?.name).toBe('Acme Corp');
  });

  it('returns contact deals', async () => {
    const { result } = renderHook(() => useContact('contact-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.deals).toHaveLength(1);
    expect(result.current.totalDealValue).toBe(5000000);
  });

  it('returns null when contact not found', async () => {
    mockContactGetById.mockResolvedValue({
      success: false,
      error: { code: 'NOT_FOUND', message: 'Contact not found' },
    });

    const { result } = renderHook(() => useContact('non-existent'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.contact).toBeNull();
    expect(result.current.error?.message).toBe('Contact not found');
  });

  it('returns null when contactId is undefined', async () => {
    const { result } = renderHook(() => useContact(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.contact).toBeNull();
    expect(mockContactGetById).not.toHaveBeenCalled();
  });

  it('handles contact without company', async () => {
    mockContactGetById.mockResolvedValue({
      success: true,
      data: { ...mockContact, companyId: undefined },
    });

    const { result } = renderHook(() => useContact('contact-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.contact).not.toBeNull();
    expect(result.current.company).toBeNull();
  });

  it('refresh reloads data', async () => {
    const { result } = renderHook(() => useContact('contact-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(mockContactGetById).toHaveBeenCalledTimes(2);
    });
  });
});
