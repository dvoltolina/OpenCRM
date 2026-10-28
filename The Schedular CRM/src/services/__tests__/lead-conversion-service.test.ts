/**
 * Lead Conversion Service Tests
 *
 * Agent CRM-11 Implementation
 *
 * Test Scenarios:
 * 1. Convert lead creates new client
 * 2. Convert lead links to existing client
 * 3. Convert lead creates deal when requested
 * 4. Convert lead updates lead status
 * 5. Convert lead sets conversion metadata
 * 6. Convert logs activity
 * 7. Cannot convert already-converted lead
 * 8. Duplicate detection finds email match
 * 9. Duplicate detection finds phone match
 * 10. Duplicate detection returns confidence scores
 * 11. Operations scoped by businessId
 * 12. Atomic operation (rollback on failure)
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { LeadConversionService } from '../lead-conversion-service';
import type { Lead, Client, Deal } from '../../types/models';
import type { SecurityContext } from '../../data/repositories/repository-types';

// ============================================
// Mock Data
// ============================================

const mockSecurityContext: SecurityContext = {
  businessId: 'business-123',
  userId: 'user-123',
  userName: 'Test User',
  userRole: 'admin',
};

const mockLead: Lead = {
  id: 'lead-123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '555-123-4567',
  companyName: 'Acme Corp',
  title: 'CEO',
  status: 'qualified',
  source: 'website',
  tags: ['vip'],
  createdAt: new Date(),
};

const mockConvertedLead: Lead = {
  ...mockLead,
  status: 'converted',
  convertedToClientId: 'client-new',
  convertedAt: new Date(),
};

const mockClient: Client = {
  id: 'client-new',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '555-123-4567',
  companyName: 'Acme Corp',
  title: 'CEO',
  lifecycle: 'prospect',
  tags: ['vip'],
  createdAt: new Date(),
};

const mockExistingClient: Client = {
  id: 'client-existing',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '555-123-4567',
  tags: [],
  createdAt: new Date(),
};

const mockDeal: Deal = {
  id: 'deal-new',
  pipelineId: 'pipeline-123',
  stageId: 'stage-1',
  title: 'New Deal',
  valueCents: 50000,
  currency: 'USD',
  probability: 25,
  status: 'open',
  clientId: 'client-new',
  clientName: 'John Doe',
  tags: [],
  createdAt: new Date(),
};

// ============================================
// Mock Repositories
// ============================================

const mockLeadGetById = vi.fn();
const mockLeadMarkConverted = vi.fn();

const mockContactGetById = vi.fn();
const mockContactCreate = vi.fn();
const mockContactUpdate = vi.fn();
const mockContactSearch = vi.fn();
const mockContactDelete = vi.fn();

const mockDealCreate = vi.fn();
const mockDealDelete = vi.fn();

const mockActivityCreate = vi.fn();

vi.mock('../../data/repositories/lead-repository', () => ({
  getLeadRepository: vi.fn(() => ({
    getById: mockLeadGetById,
    markConverted: mockLeadMarkConverted,
  })),
}));

vi.mock('../../data/repositories/contact-repository', () => ({
  getContactRepository: vi.fn(() => ({
    getById: mockContactGetById,
    create: mockContactCreate,
    update: mockContactUpdate,
    search: mockContactSearch,
    delete: mockContactDelete,
  })),
}));

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    create: mockDealCreate,
    delete: mockDealDelete,
  })),
}));

vi.mock('../../data/repositories/activity-repository', () => ({
  getActivityRepository: vi.fn(() => ({
    create: mockActivityCreate,
  })),
}));

// ============================================
// Tests
// ============================================

describe('LeadConversionService', () => {
  let service: LeadConversionService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new LeadConversionService();

    // Default mock responses
    mockLeadGetById.mockResolvedValue({
      success: true,
      data: mockLead,
      error: null,
    });

    mockLeadMarkConverted.mockResolvedValue({
      success: true,
      data: mockConvertedLead,
      error: null,
    });

    mockContactCreate.mockResolvedValue({
      success: true,
      data: mockClient,
      error: null,
    });

    mockContactGetById.mockResolvedValue({
      success: true,
      data: mockExistingClient,
      error: null,
    });

    mockContactUpdate.mockResolvedValue({
      success: true,
      data: mockExistingClient,
      error: null,
    });

    mockContactSearch.mockResolvedValue({
      success: true,
      data: [],
      error: null,
    });

    mockDealCreate.mockResolvedValue({
      success: true,
      data: mockDeal,
      error: null,
    });

    mockActivityCreate.mockResolvedValue({
      success: true,
      data: { id: 'activity-1' },
      error: null,
    });
  });

  // ============================================
  // Test 1: Convert lead creates new client
  // ============================================
  it('convert lead creates new client', async () => {
    const result = await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
    });

    expect(mockContactCreate).toHaveBeenCalled();
    expect(result.client).toBeDefined();
    expect(result.client.firstName).toBe('John');
    expect(result.client.lastName).toBe('Doe');
    expect(result.client.email).toBe('john@example.com');
  });

  // ============================================
  // Test 2: Convert lead links to existing client
  // ============================================
  it('convert lead links to existing client', async () => {
    const result = await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
      existingClientId: 'client-existing',
    });

    expect(mockContactCreate).not.toHaveBeenCalled();
    expect(mockContactGetById).toHaveBeenCalledWith(
      mockSecurityContext,
      'client-existing'
    );
    expect(result.client.id).toBe('client-existing');
  });

  // ============================================
  // Test 3: Convert lead creates deal when requested
  // ============================================
  it('convert lead creates deal when requested', async () => {
    const result = await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: true,
      dealData: {
        title: 'New Deal',
        valueCents: 50000,
        pipelineId: 'pipeline-123',
        stageId: 'stage-1',
      },
    });

    expect(mockDealCreate).toHaveBeenCalled();
    expect(result.deal).toBeDefined();
    expect(result.deal?.title).toBe('New Deal');
    expect(result.deal?.valueCents).toBe(50000);
  });

  // ============================================
  // Test 4: Convert lead updates lead status
  // ============================================
  it('convert lead updates lead status', async () => {
    const result = await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
    });

    expect(mockLeadMarkConverted).toHaveBeenCalledWith(
      mockSecurityContext,
      'lead-123',
      expect.any(String),
      undefined
    );
    expect(result.lead.status).toBe('converted');
  });

  // ============================================
  // Test 5: Convert lead sets conversion metadata
  // ============================================
  it('convert lead sets conversion metadata', async () => {
    mockLeadMarkConverted.mockResolvedValue({
      success: true,
      data: {
        ...mockConvertedLead,
        convertedToClientId: 'client-new',
        convertedToDealId: 'deal-new',
        convertedAt: new Date(),
      },
      error: null,
    });

    const result = await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: true,
      dealData: {
        title: 'New Deal',
        valueCents: 50000,
        pipelineId: 'pipeline-123',
        stageId: 'stage-1',
      },
    });

    expect(result.lead.convertedToClientId).toBeDefined();
    expect(result.lead.convertedAt).toBeDefined();
  });

  // ============================================
  // Test 6: Convert logs activity
  // ============================================
  it('convert logs activity', async () => {
    await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
    });

    expect(mockActivityCreate).toHaveBeenCalledWith(
      mockSecurityContext,
      expect.objectContaining({
        type: 'note',
        title: 'Lead Converted',
        clientId: expect.any(String),
        createdById: 'user-123',
        createdByName: 'Test User',
      })
    );
  });

  // ============================================
  // Test 7: Cannot convert already-converted lead
  // ============================================
  it('cannot convert already-converted lead', async () => {
    mockLeadGetById.mockResolvedValue({
      success: true,
      data: { ...mockLead, status: 'converted' },
      error: null,
    });

    const canConvertResult = await service.canConvert(mockSecurityContext, 'lead-123');

    expect(canConvertResult.canConvert).toBe(false);
    expect(canConvertResult.reason).toContain('already been converted');
  });

  // ============================================
  // Test 8: Duplicate detection finds email match
  // ============================================
  it('duplicate detection finds email match', async () => {
    mockContactSearch.mockResolvedValue({
      success: true,
      data: [mockExistingClient],
      error: null,
    });

    const duplicates = await service.suggestExistingClient(mockSecurityContext, mockLead);

    expect(duplicates.length).toBeGreaterThan(0);
    expect(duplicates[0].matchType).toBe('email');
    expect(duplicates[0].confidence).toBe(100);
  });

  // ============================================
  // Test 9: Duplicate detection finds phone match
  // ============================================
  it('duplicate detection finds phone match', async () => {
    const clientWithPhone = {
      ...mockExistingClient,
      email: 'different@example.com',
      phone: '5551234567', // Same phone, different format
    };

    mockContactSearch.mockResolvedValueOnce({
      success: true,
      data: [], // No email match
      error: null,
    }).mockResolvedValueOnce({
      success: true,
      data: [clientWithPhone], // Phone match
      error: null,
    });

    const duplicates = await service.suggestExistingClient(mockSecurityContext, mockLead);

    expect(duplicates.some((d) => d.matchType === 'phone')).toBe(true);
    expect(duplicates.find((d) => d.matchType === 'phone')?.confidence).toBe(90);
  });

  // ============================================
  // Test 10: Duplicate detection returns confidence scores
  // ============================================
  it('duplicate detection returns confidence scores', async () => {
    mockContactSearch.mockResolvedValue({
      success: true,
      data: [mockExistingClient],
      error: null,
    });

    const duplicates = await service.suggestExistingClient(mockSecurityContext, mockLead);

    expect(duplicates.length).toBeGreaterThan(0);
    for (const match of duplicates) {
      expect(match.confidence).toBeGreaterThanOrEqual(0);
      expect(match.confidence).toBeLessThanOrEqual(100);
    }

    // Should be sorted by confidence (highest first)
    for (let i = 1; i < duplicates.length; i++) {
      expect(duplicates[i - 1].confidence).toBeGreaterThanOrEqual(duplicates[i].confidence);
    }
  });

  // ============================================
  // Test 11: Operations scoped by businessId
  // ============================================
  it('operations scoped by businessId', async () => {
    await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
    });

    // All repository calls should receive the security context with businessId
    expect(mockLeadGetById).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'business-123' }),
      'lead-123'
    );

    expect(mockContactCreate).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'business-123' }),
      expect.any(Object)
    );

    expect(mockLeadMarkConverted).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'business-123' }),
      expect.any(String),
      expect.any(String),
      undefined
    );
  });

  // ============================================
  // Test 12: Atomic operation (rollback on failure)
  // ============================================
  it('rolls back on deal creation failure', async () => {
    mockDealCreate.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'ERROR', message: 'Deal creation failed' },
    });

    await expect(
      service.convert(mockSecurityContext, {
        leadId: 'lead-123',
        createDeal: true,
        dealData: {
          title: 'New Deal',
          valueCents: 50000,
          pipelineId: 'pipeline-123',
          stageId: 'stage-1',
        },
      })
    ).rejects.toThrow('Failed to create deal');

    // Should have attempted to delete the created client (rollback)
    expect(mockContactDelete).toHaveBeenCalledWith(
      mockSecurityContext,
      'client-new'
    );
  });

  it('rolls back deal and client on mark converted failure', async () => {
    mockLeadMarkConverted.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'ERROR', message: 'Mark converted failed' },
    });

    await expect(
      service.convert(mockSecurityContext, {
        leadId: 'lead-123',
        createDeal: true,
        dealData: {
          title: 'New Deal',
          valueCents: 50000,
          pipelineId: 'pipeline-123',
          stageId: 'stage-1',
        },
      })
    ).rejects.toThrow('Failed to mark lead as converted');

    // Should have attempted to delete both deal and client (rollback)
    expect(mockDealDelete).toHaveBeenCalled();
    expect(mockContactDelete).toHaveBeenCalled();
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('canConvert returns false for lead without email', async () => {
    mockLeadGetById.mockResolvedValue({
      success: true,
      data: { ...mockLead, email: '' },
      error: null,
    });

    const result = await service.canConvert(mockSecurityContext, 'lead-123');

    expect(result.canConvert).toBe(false);
    expect(result.reason).toContain('email');
  });

  it('convert without deal does not call dealRepository', async () => {
    await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
    });

    expect(mockDealCreate).not.toHaveBeenCalled();
  });

  it('updates existing client with clientData when linking', async () => {
    await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: false,
      existingClientId: 'client-existing',
      clientData: {
        title: 'Updated Title',
      },
    });

    expect(mockContactUpdate).toHaveBeenCalledWith(
      mockSecurityContext,
      'client-existing',
      { title: 'Updated Title' }
    );
  });

  it('deal includes client info when created', async () => {
    await service.convert(mockSecurityContext, {
      leadId: 'lead-123',
      createDeal: true,
      dealData: {
        title: 'New Deal',
        valueCents: 50000,
        pipelineId: 'pipeline-123',
        stageId: 'stage-1',
      },
    });

    expect(mockDealCreate).toHaveBeenCalledWith(
      mockSecurityContext,
      expect.objectContaining({
        clientId: 'client-new',
        clientName: 'John Doe',
      })
    );
  });
});
