/**
 * Deal Stage Service Tests
 *
 * Agent CRM-12 Implementation
 *
 * Test Scenarios (14 total):
 * 1. canMoveToStage returns true for valid transition
 * 2. canMoveToStage returns false for closed deal
 * 3. canMoveToStage returns false for inactive stage
 * 4. canMoveToStage returns false for different pipeline
 * 5. moveToStage updates deal stageId
 * 6. moveToStage logs activity with from/to names
 * 7. moveToStage includes reason in activity
 * 8. markWon sets status and logs activity
 * 9. markLost requires reason
 * 10. markLost logs activity with reason
 * 11. reopenDeal changes status to open
 * 12. reopenDeal logs previous status in activity
 * 13. getStageHistory returns transition history
 * 14. Operations scoped by businessId
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { DealStageService } from '../deal-stage-service';
import type { Deal, Stage, SalesActivity } from '../../types/models';
import type { SecurityContext, PaginatedResult } from '../../data/repositories/repository-types';

// ============================================
// Mock Data
// ============================================

const mockSecurityContext: SecurityContext = {
  businessId: 'business-123',
  userId: 'user-123',
  userName: 'Test User',
  userRole: 'admin',
};

const mockDeal: Deal = {
  id: 'deal-123',
  pipelineId: 'pipeline-1',
  stageId: 'stage-lead',
  title: 'Test Deal',
  valueCents: 100000,
  currency: 'USD',
  probability: 25,
  status: 'open',
  clientId: 'client-123',
  clientName: 'John Doe',
  tags: [],
  createdAt: new Date(),
};

const mockWonDeal: Deal = {
  ...mockDeal,
  status: 'won',
  closedAt: new Date(),
};

const mockLostDeal: Deal = {
  ...mockDeal,
  status: 'lost',
  closedAt: new Date(),
  wonLostReason: 'Budget constraints',
};

const mockStageFrom: Stage = {
  id: 'stage-lead',
  pipelineId: 'pipeline-1',
  name: 'Lead',
  order: 0,
  colorHex: '#ccc',
  probability: 25,
  isActive: true,
  createdAt: new Date(),
};

const mockStageTo: Stage = {
  id: 'stage-qualified',
  pipelineId: 'pipeline-1',
  name: 'Qualified',
  order: 1,
  colorHex: '#4CAF50',
  probability: 50,
  isActive: true,
  createdAt: new Date(),
};

const mockInactiveStage: Stage = {
  id: 'stage-archived',
  pipelineId: 'pipeline-1',
  name: 'Archived Stage',
  order: 99,
  colorHex: '#999',
  probability: 0,
  isActive: false,
  createdAt: new Date(),
};

const mockOtherPipelineStage: Stage = {
  id: 'stage-other',
  pipelineId: 'pipeline-2',
  name: 'Other Pipeline Stage',
  order: 0,
  colorHex: '#FF5722',
  probability: 50,
  isActive: true,
  createdAt: new Date(),
};

// ============================================
// Mock Repositories
// ============================================

const mockDealGetById = vi.fn();
const mockDealMoveToStage = vi.fn();
const mockDealMarkWon = vi.fn();
const mockDealMarkLost = vi.fn();
const mockDealReopen = vi.fn();
const mockDealUpdate = vi.fn();

const mockStageGetById = vi.fn();

const mockActivityCreate = vi.fn();
const mockActivityGetByDeal = vi.fn();

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: vi.fn(() => ({
    getById: mockDealGetById,
    moveToStage: mockDealMoveToStage,
    markWon: mockDealMarkWon,
    markLost: mockDealMarkLost,
    reopen: mockDealReopen,
    update: mockDealUpdate,
  })),
}));

vi.mock('../../data/repositories/stage-repository', () => ({
  getStageRepository: vi.fn(() => ({
    getById: mockStageGetById,
  })),
}));

vi.mock('../../data/repositories/activity-repository', () => ({
  getActivityRepository: vi.fn(() => ({
    create: mockActivityCreate,
    getByDeal: mockActivityGetByDeal,
  })),
}));

// ============================================
// Tests
// ============================================

describe('DealStageService', () => {
  let service: DealStageService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new DealStageService();

    // Default mock responses
    mockDealGetById.mockResolvedValue({
      success: true,
      data: mockDeal,
      error: null,
    });

    mockStageGetById.mockImplementation(async (_ctx: SecurityContext, stageId: string) => {
      if (stageId === 'stage-lead') {
        return { success: true, data: mockStageFrom, error: null };
      }
      if (stageId === 'stage-qualified') {
        return { success: true, data: mockStageTo, error: null };
      }
      if (stageId === 'stage-archived') {
        return { success: true, data: mockInactiveStage, error: null };
      }
      if (stageId === 'stage-other') {
        return { success: true, data: mockOtherPipelineStage, error: null };
      }
      return {
        success: false,
        data: null,
        error: { code: 'NOT_FOUND', message: 'Stage not found' },
      };
    });

    mockDealMoveToStage.mockResolvedValue({
      success: true,
      data: { ...mockDeal, stageId: 'stage-qualified', probability: 50 },
      error: null,
    });

    mockDealMarkWon.mockResolvedValue({
      success: true,
      data: mockWonDeal,
      error: null,
    });

    mockDealMarkLost.mockResolvedValue({
      success: true,
      data: mockLostDeal,
      error: null,
    });

    mockDealReopen.mockResolvedValue({
      success: true,
      data: { ...mockDeal, status: 'open' },
      error: null,
    });

    mockActivityCreate.mockResolvedValue({
      success: true,
      data: { id: 'activity-123' },
      error: null,
    });

    mockActivityGetByDeal.mockResolvedValue({
      success: true,
      data: { data: [], lastDoc: null, hasMore: false } as PaginatedResult<SalesActivity>,
      error: null,
    });
  });

  // ============================================
  // Test 1: canMoveToStage returns true for valid transition
  // ============================================
  describe('canMoveToStage', () => {
    it('returns true for valid transition', async () => {
      const result = await service.canMoveToStage(
        mockSecurityContext,
        'deal-123',
        'stage-qualified'
      );

      expect(result.canMove).toBe(true);
      expect(result.reason).toBeUndefined();
    });

    // ============================================
    // Test 2: canMoveToStage returns false for closed deal
    // ============================================
    it('returns false for closed deal', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockWonDeal,
        error: null,
      });

      const result = await service.canMoveToStage(
        mockSecurityContext,
        'deal-123',
        'stage-qualified'
      );

      expect(result.canMove).toBe(false);
      expect(result.reason).toContain('won');
      expect(result.reason).toContain('Reopen');
    });

    // ============================================
    // Test 3: canMoveToStage returns false for inactive stage
    // ============================================
    it('returns false for inactive stage', async () => {
      const result = await service.canMoveToStage(
        mockSecurityContext,
        'deal-123',
        'stage-archived'
      );

      expect(result.canMove).toBe(false);
      expect(result.reason).toContain('inactive');
    });

    // ============================================
    // Test 4: canMoveToStage returns false for different pipeline
    // ============================================
    it('returns false for different pipeline stage', async () => {
      const result = await service.canMoveToStage(
        mockSecurityContext,
        'deal-123',
        'stage-other'
      );

      expect(result.canMove).toBe(false);
      expect(result.reason).toContain('different pipeline');
    });

    it('returns false when deal is already in target stage', async () => {
      const result = await service.canMoveToStage(
        mockSecurityContext,
        'deal-123',
        'stage-lead' // Same as current stageId
      );

      expect(result.canMove).toBe(false);
      expect(result.reason).toContain('already in this stage');
    });
  });

  // ============================================
  // Test 5: moveToStage updates deal stageId
  // ============================================
  describe('moveToStage', () => {
    it('updates deal stageId', async () => {
      const result = await service.moveToStage(mockSecurityContext, {
        dealId: 'deal-123',
        fromStageId: 'stage-lead',
        toStageId: 'stage-qualified',
      });

      expect(result.success).toBe(true);
      expect(result.deal?.stageId).toBe('stage-qualified');
      expect(mockDealMoveToStage).toHaveBeenCalledWith(
        mockSecurityContext,
        'deal-123',
        'stage-qualified',
        50 // probability from target stage
      );
    });

    // ============================================
    // Test 6: moveToStage logs activity with from/to names
    // ============================================
    it('logs activity with from/to stage names', async () => {
      await service.moveToStage(mockSecurityContext, {
        dealId: 'deal-123',
        fromStageId: 'stage-lead',
        toStageId: 'stage-qualified',
      });

      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          type: 'note',
          title: 'Stage Changed',
          description: expect.stringContaining('Lead'),
        })
      );
      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          description: expect.stringContaining('Qualified'),
        })
      );
    });

    // ============================================
    // Test 7: moveToStage includes reason in activity
    // ============================================
    it('includes reason in activity description', async () => {
      await service.moveToStage(mockSecurityContext, {
        dealId: 'deal-123',
        fromStageId: 'stage-lead',
        toStageId: 'stage-qualified',
        reason: 'Customer requested proposal',
      });

      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          description: expect.stringContaining('Customer requested proposal'),
        })
      );
    });

    it('returns error for invalid transition', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockWonDeal,
        error: null,
      });

      const result = await service.moveToStage(mockSecurityContext, {
        dealId: 'deal-123',
        fromStageId: 'stage-lead',
        toStageId: 'stage-qualified',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('won');
    });
  });

  // ============================================
  // Test 8: markWon sets status and logs activity
  // ============================================
  describe('markWon', () => {
    it('sets status and logs activity', async () => {
      const result = await service.markWon(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'won',
        reason: 'Great negotiation',
      });

      expect(result.success).toBe(true);
      expect(result.deal?.status).toBe('won');
      expect(mockDealMarkWon).toHaveBeenCalledWith(
        mockSecurityContext,
        'deal-123',
        'Great negotiation'
      );
      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          title: 'Deal Won',
          description: expect.stringContaining('Great negotiation'),
        })
      );
    });

    it('rejects invalid outcome', async () => {
      const result = await service.markWon(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'lost',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('markLost');
    });

    it('rejects marking already won deal', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockWonDeal,
        error: null,
      });

      const result = await service.markWon(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'won',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('already marked as won');
    });
  });

  // ============================================
  // Test 9: markLost requires reason
  // ============================================
  describe('markLost', () => {
    it('requires reason', async () => {
      const result = await service.markLost(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'lost',
        reason: '', // Empty reason
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('Reason is required');
    });

    // ============================================
    // Test 10: markLost logs activity with reason
    // ============================================
    it('logs activity with reason', async () => {
      const result = await service.markLost(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'lost',
        reason: 'Budget constraints',
      });

      expect(result.success).toBe(true);
      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          title: 'Deal Lost',
          description: expect.stringContaining('Budget constraints'),
        })
      );
    });

    it('rejects invalid outcome', async () => {
      const result = await service.markLost(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'won',
        reason: 'Some reason',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('markWon');
    });

    it('rejects marking already lost deal', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockLostDeal,
        error: null,
      });

      const result = await service.markLost(mockSecurityContext, {
        dealId: 'deal-123',
        outcome: 'lost',
        reason: 'Some reason',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('already marked as lost');
    });
  });

  // ============================================
  // Test 11: reopenDeal changes status to open
  // ============================================
  describe('reopenDeal', () => {
    it('changes status to open', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockLostDeal,
        error: null,
      });

      const result = await service.reopenDeal(mockSecurityContext, 'deal-123');

      expect(result.success).toBe(true);
      expect(mockDealReopen).toHaveBeenCalledWith(mockSecurityContext, 'deal-123');
    });

    // ============================================
    // Test 12: reopenDeal logs previous status in activity
    // ============================================
    it('logs previous status in activity', async () => {
      mockDealGetById.mockResolvedValue({
        success: true,
        data: mockLostDeal,
        error: null,
      });

      await service.reopenDeal(mockSecurityContext, 'deal-123');

      expect(mockActivityCreate).toHaveBeenCalledWith(
        mockSecurityContext,
        expect.objectContaining({
          title: 'Deal Reopened',
          description: expect.stringContaining('lost'),
        })
      );
    });

    it('rejects reopening already open deal', async () => {
      // mockDeal has status 'open' by default
      const result = await service.reopenDeal(mockSecurityContext, 'deal-123');

      expect(result.success).toBe(false);
      expect(result.error).toContain('already open');
    });
  });

  // ============================================
  // Test 13: getStageHistory returns transition history
  // ============================================
  describe('getStageHistory', () => {
    it('returns transition history from activities', async () => {
      const mockActivities: SalesActivity[] = [
        {
          id: 'activity-1',
          type: 'note',
          title: 'Stage Changed',
          description: 'Moved from "Lead" to "Qualified"',
          dealId: 'deal-123',
          isCompleted: true,
          createdById: 'user-123',
          createdByName: 'Test User',
          createdAt: new Date(),
        },
        {
          id: 'activity-2',
          type: 'note',
          title: 'Stage Changed',
          description: 'Moved from "Qualified" to "Proposal". Reason: Customer interested',
          dealId: 'deal-123',
          isCompleted: true,
          createdById: 'user-456',
          createdByName: 'Other User',
          createdAt: new Date(Date.now() + 1000),
        },
      ];

      mockActivityGetByDeal.mockResolvedValue({
        success: true,
        data: { data: mockActivities, lastDoc: null, hasMore: false },
        error: null,
      });

      const history = await service.getStageHistory(mockSecurityContext, 'deal-123');

      expect(history.length).toBe(2);
      expect(history[0].fromStageName).toBe('Qualified');
      expect(history[0].toStageName).toBe('Proposal');
      expect(history[0].reason).toBe('Customer interested');
      expect(history[1].fromStageName).toBe('Lead');
      expect(history[1].toStageName).toBe('Qualified');
    });

    it('returns empty array when no stage change activities', async () => {
      mockActivityGetByDeal.mockResolvedValue({
        success: true,
        data: { data: [], lastDoc: null, hasMore: false },
        error: null,
      });

      const history = await service.getStageHistory(mockSecurityContext, 'deal-123');

      expect(history).toEqual([]);
    });
  });

  // ============================================
  // Test 14: Operations scoped by businessId
  // ============================================
  describe('businessId scoping', () => {
    it('all operations receive security context with businessId', async () => {
      await service.moveToStage(mockSecurityContext, {
        dealId: 'deal-123',
        fromStageId: 'stage-lead',
        toStageId: 'stage-qualified',
      });

      expect(mockDealGetById).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'deal-123'
      );

      expect(mockStageGetById).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(String)
      );

      expect(mockDealMoveToStage).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(String),
        expect.any(String),
        expect.any(Number)
      );

      expect(mockActivityCreate).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(Object)
      );
    });
  });

  // ============================================
  // Additional Tests: validateAndMove
  // ============================================
  describe('validateAndMove', () => {
    it('convenience method that gets current stage and moves', async () => {
      const result = await service.validateAndMove(
        mockSecurityContext,
        'deal-123',
        'stage-qualified',
        'Customer qualified'
      );

      expect(result.success).toBe(true);
      expect(result.deal?.stageId).toBe('stage-qualified');
    });

    it('returns error when deal not found', async () => {
      mockDealGetById.mockResolvedValue({
        success: false,
        data: null,
        error: { code: 'NOT_FOUND', message: 'Deal not found' },
      });

      const result = await service.validateAndMove(
        mockSecurityContext,
        'deal-999',
        'stage-qualified'
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('Deal not found');
    });
  });
});
