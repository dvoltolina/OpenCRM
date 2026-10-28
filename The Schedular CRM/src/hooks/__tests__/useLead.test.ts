/**
 * useLead Hook Tests
 *
 * Agent CRM-08 Implementation
 *
 * Test Scenarios:
 * 1. Returns lead data
 * 2. Returns lead activities
 * 3. Returns null when lead not found
 * 4. Handles fetch error
 * 5. Refresh reloads data
 * 6. Returns null when leadId is undefined
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import { useLead } from '../useLead';
import type { Lead } from '../../types/models';

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
// Mock Lead Repository
// ============================================

const mockLead: Lead = {
  id: 'lead-123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '+1234567890',
  companyName: 'Acme Corp',
  status: 'qualified',
  source: 'website',
  score: 75,
  tags: ['enterprise', 'high-value'],
  notes: 'Interested in enterprise plan',
  assigneeId: 'user-456',
  assigneeName: 'Sales Rep',
  createdAt: new Date(),
};

const mockGetById = vi.fn();

vi.mock('../../data/repositories/lead-repository', () => ({
  getLeadRepository: vi.fn(() => ({
    getById: mockGetById,
  })),
}));

// ============================================
// Tests
// ============================================

describe('useLead', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock response
    mockGetById.mockResolvedValue({
      success: true,
      data: mockLead,
      error: null,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Test 1: Returns lead data
  // ============================================
  it('returns lead data', async () => {
    const { result } = renderHook(() => useLead('lead-123'));

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead).not.toBeNull();
    expect(result.current.lead?.id).toBe('lead-123');
    expect(result.current.lead?.firstName).toBe('John');
    expect(result.current.lead?.lastName).toBe('Doe');
    expect(result.current.lead?.email).toBe('john@example.com');
    expect(result.current.error).toBeNull();
  });

  // ============================================
  // Test 2: Returns lead activities (empty for now)
  // ============================================
  it('returns lead activities', async () => {
    const { result } = renderHook(() => useLead('lead-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    // Activities are currently empty as ActivityRepository is not yet implemented
    expect(result.current.activities).toBeDefined();
    expect(Array.isArray(result.current.activities)).toBe(true);
  });

  // ============================================
  // Test 3: Returns null when lead not found
  // ============================================
  it('returns null and error when lead not found', async () => {
    mockGetById.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NOT_FOUND', message: 'Lead not found' },
    });

    const { result } = renderHook(() => useLead('non-existent'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead).toBeNull();
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Lead not found');
  });

  // ============================================
  // Test 4: Handles fetch error
  // ============================================
  it('handles fetch error', async () => {
    mockGetById.mockRejectedValue(new Error('Network error'));

    const { result } = renderHook(() => useLead('lead-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead).toBeNull();
    expect(result.current.error).not.toBeNull();
    expect(result.current.error?.message).toBe('Network error');
  });

  // ============================================
  // Test 5: Refresh reloads data
  // ============================================
  it('refresh reloads data', async () => {
    const updatedLead = { ...mockLead, firstName: 'Johnny' };

    mockGetById
      .mockResolvedValueOnce({
        success: true,
        data: mockLead,
        error: null,
      })
      .mockResolvedValueOnce({
        success: true,
        data: updatedLead,
        error: null,
      });

    const { result } = renderHook(() => useLead('lead-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead?.firstName).toBe('John');

    // Refresh
    await act(async () => {
      result.current.refresh();
    });

    await waitFor(() => {
      expect(result.current.lead?.firstName).toBe('Johnny');
    });
  });

  // ============================================
  // Test 6: Returns null when leadId is undefined
  // ============================================
  it('returns null when leadId is undefined', async () => {
    const { result } = renderHook(() => useLead(undefined));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead).toBeNull();
    expect(result.current.error).toBeNull();
    expect(mockGetById).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 7: Fetches new lead when leadId changes
  // ============================================
  it('fetches new lead when leadId changes', async () => {
    const anotherLead = { ...mockLead, id: 'lead-456', firstName: 'Jane' };

    mockGetById
      .mockResolvedValueOnce({
        success: true,
        data: mockLead,
        error: null,
      })
      .mockResolvedValueOnce({
        success: true,
        data: anotherLead,
        error: null,
      });

    const { result, rerender } = renderHook(
      ({ leadId }) => useLead(leadId),
      { initialProps: { leadId: 'lead-123' } }
    );

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead?.id).toBe('lead-123');
    expect(result.current.lead?.firstName).toBe('John');

    // Change leadId
    rerender({ leadId: 'lead-456' });

    await waitFor(() => {
      expect(result.current.lead?.id).toBe('lead-456');
    });

    expect(result.current.lead?.firstName).toBe('Jane');
  });

  // ============================================
  // Test 8: Returns all lead fields
  // ============================================
  it('returns all lead fields', async () => {
    const { result } = renderHook(() => useLead('lead-123'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.lead).toEqual(mockLead);
    expect(result.current.lead?.companyName).toBe('Acme Corp');
    expect(result.current.lead?.status).toBe('qualified');
    expect(result.current.lead?.source).toBe('website');
    expect(result.current.lead?.score).toBe(75);
    expect(result.current.lead?.tags).toContain('enterprise');
    expect(result.current.lead?.assigneeId).toBe('user-456');
  });
});
