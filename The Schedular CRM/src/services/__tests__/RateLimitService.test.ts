/**
 * RateLimitService Tests
 *
 * Agent CRM-28 Implementation
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { RateLimitService, getRateLimitService, DEFAULT_RATE_LIMITS } from '../RateLimitService';

// Mock persistence to avoid Firestore network calls in tests
const mockResetByKey = vi.fn().mockResolvedValue({ success: true, data: undefined, error: null });
const mockSave = vi.fn().mockResolvedValue({
  success: true,
  data: {
    id: 'mock',
    key: 'mock',
    timestamps: [],
    lastReset: Date.now(),
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  error: null,
});

vi.mock('../../data/repositories/rate-limit-repository', () => ({
  getRateLimitRepository: () => ({
    resetByKey: mockResetByKey,
    save: mockSave,
  }),
}));

// ============================================
// Test Data
// ============================================

const mockUserId = 'user-123';
const mockBusinessId = 'business-123';

// ============================================
// Tests
// ============================================

describe('RateLimitService', () => {
  let service: RateLimitService;

  beforeEach(() => {
    service = new RateLimitService();
    service.clearAll(); // Clear any previous data
  });

  afterEach(() => {
    service.clearAll();
  });

  // ============================================
  // Initialization Tests
  // ============================================

  describe('initialization', () => {
    it('initializes with default limits', () => {
      const limits = service.getLimits();
      expect(limits.email).toEqual(DEFAULT_RATE_LIMITS.email);
      expect(limits.api_call).toEqual(DEFAULT_RATE_LIMITS.api_call);
    });

    it('includes webhook and integration sync limits', () => {
      const limits = service.getLimits();
      expect(limits.webhook).toBeDefined();
      expect(limits.integration_sync).toBeDefined();
    });

    it('accepts custom limits', () => {
      const customService = new RateLimitService({
        email: {
          maxActions: 50,
          windowMs: 30 * 60 * 1000,
          description: '50 emails per 30 minutes',
        },
      });

      const limits = customService.getLimits();
      expect(limits.email.maxActions).toBe(50);
      expect(limits.email.windowMs).toBe(30 * 60 * 1000);
    });
  });

  // ============================================
  // checkLimit Tests
  // ============================================

  describe('checkLimit', () => {
    it('allows action under limit', async () => {
      const result = await service.checkLimit('email', mockUserId, mockBusinessId);

      expect(result.allowed).toBe(true);
      expect(result.remaining).toBe(DEFAULT_RATE_LIMITS.email.maxActions);
    });

    it('denies action over limit', async () => {
      // Record actions up to the limit
      const limit = DEFAULT_RATE_LIMITS.email.maxActions;
      for (let i = 0; i < limit; i++) {
        await service.recordAction('email', mockUserId, mockBusinessId);
      }

      // Next check should be denied
      const result = await service.checkLimit('email', mockUserId, mockBusinessId);

      expect(result.allowed).toBe(false);
      expect(result.remaining).toBe(0);
      expect(result.message).toContain('Rate limit exceeded');
    });

    it('allows action when disabled', async () => {
      service.disable();

      // Record many actions
      for (let i = 0; i < 200; i++) {
        await service.recordAction('email', mockUserId, mockBusinessId);
      }

      const result = await service.checkLimit('email', mockUserId, mockBusinessId);

      expect(result.allowed).toBe(true);
      expect(result.remaining).toBe(Infinity);
    });

    it('allows unknown action types', async () => {
      const result = await service.checkLimit('unknown_action' as any, mockUserId, mockBusinessId);

      expect(result.allowed).toBe(true);
      expect(result.remaining).toBe(Infinity);
    });
  });

  // ============================================
  // recordAction Tests
  // ============================================

  describe('recordAction', () => {
    it('increments action count', async () => {
      await service.recordAction('email', mockUserId, mockBusinessId);

      const usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(1);
      expect(usage.remaining).toBe(DEFAULT_RATE_LIMITS.email.maxActions - 1);
    });

    it('does not increment when disabled', async () => {
      service.disable();

      await service.recordAction('email', mockUserId, mockBusinessId);

      service.enable();
      const usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(0);
    });
  });

  // ============================================
  // Sliding Window Tests
  // ============================================

  describe('sliding window', () => {
    it('removes old timestamps outside window', async () => {
      // Create a service with a very short window for testing
      const testService = new RateLimitService({
        email: {
          maxActions: 3,
          windowMs: 100, // 100ms window
          description: 'Test limit',
        },
      });

      // Record 3 actions
      await testService.recordAction('email', mockUserId, mockBusinessId);
      await testService.recordAction('email', mockUserId, mockBusinessId);
      await testService.recordAction('email', mockUserId, mockBusinessId);

      // Check that limit is reached
      let result = await testService.checkLimit('email', mockUserId, mockBusinessId);
      expect(result.allowed).toBe(false);

      // Wait for window to expire
      await new Promise((resolve) => setTimeout(resolve, 150));

      // Check that limit is reset
      result = await testService.checkLimit('email', mockUserId, mockBusinessId);
      expect(result.allowed).toBe(true);
    });
  });

  // ============================================
  // Per-User Tracking Tests
  // ============================================

  describe('per-user tracking', () => {
    it('tracks limits separately per user', async () => {
      const user1 = 'user-1';
      const user2 = 'user-2';

      // Record actions for user1
      await service.recordAction('email', user1, mockBusinessId);
      await service.recordAction('email', user1, mockBusinessId);

      // Record actions for user2
      await service.recordAction('email', user2, mockBusinessId);

      // Check usage for each user
      const usage1 = await service.getUsage('email', user1, mockBusinessId);
      const usage2 = await service.getUsage('email', user2, mockBusinessId);

      expect(usage1.count).toBe(2);
      expect(usage2.count).toBe(1);
    });

    it('tracks limits separately per business', async () => {
      const business1 = 'business-1';
      const business2 = 'business-2';

      // Record actions for business1
      await service.recordAction('email', mockUserId, business1);
      await service.recordAction('email', mockUserId, business1);

      // Record actions for business2
      await service.recordAction('email', mockUserId, business2);

      // Check usage for each business
      const usage1 = await service.getUsage('email', mockUserId, business1);
      const usage2 = await service.getUsage('email', mockUserId, business2);

      expect(usage1.count).toBe(2);
      expect(usage2.count).toBe(1);
    });
  });

  // ============================================
  // checkAndRecord Tests
  // ============================================

  describe('checkAndRecord', () => {
    it('records action if allowed', async () => {
      const result = await service.checkAndRecord('email', mockUserId, mockBusinessId);

      expect(result.allowed).toBe(true);

      const usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(1);
    });

    it('does not record action if denied', async () => {
      // Fill up to limit
      const limit = DEFAULT_RATE_LIMITS.email.maxActions;
      for (let i = 0; i < limit; i++) {
        await service.recordAction('email', mockUserId, mockBusinessId);
      }

      const result = await service.checkAndRecord('email', mockUserId, mockBusinessId);

      expect(result.allowed).toBe(false);

      const usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(limit); // Should not increment
    });
  });

  // ============================================
  // reset Tests
  // ============================================

  describe('reset', () => {
    it('clears rate limit for user/action', async () => {
      // Record some actions
      await service.recordAction('email', mockUserId, mockBusinessId);
      await service.recordAction('email', mockUserId, mockBusinessId);

      // Verify count
      let usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(2);

      // Reset
      await service.reset('email', mockUserId, mockBusinessId);

      // Verify reset
      usage = await service.getUsage('email', mockUserId, mockBusinessId);
      expect(usage.count).toBe(0);
    });
  });

  // ============================================
  // getUsage Tests
  // ============================================

  describe('getUsage', () => {
    it('returns current usage stats', async () => {
      await service.recordAction('api_call', mockUserId, mockBusinessId);
      await service.recordAction('api_call', mockUserId, mockBusinessId);
      await service.recordAction('api_call', mockUserId, mockBusinessId);

      const usage = await service.getUsage('api_call', mockUserId, mockBusinessId);

      expect(usage.count).toBe(3);
      expect(usage.limit).toBe(DEFAULT_RATE_LIMITS.api_call.maxActions);
      expect(usage.remaining).toBe(DEFAULT_RATE_LIMITS.api_call.maxActions - 3);
      expect(usage.resetAt).toBeInstanceOf(Date);
    });

    it('returns zero usage for new user', async () => {
      const usage = await service.getUsage('email', 'new-user', mockBusinessId);

      expect(usage.count).toBe(0);
      expect(usage.remaining).toBe(DEFAULT_RATE_LIMITS.email.maxActions);
    });
  });

  // ============================================
  // updateLimit Tests
  // ============================================

  describe('updateLimit', () => {
    it('updates rate limit configuration', () => {
      const newConfig = {
        maxActions: 25,
        windowMs: 15 * 60 * 1000,
        description: 'Updated limit',
      };

      service.updateLimit('email', newConfig);

      const limits = service.getLimits();
      expect(limits.email).toEqual(newConfig);
    });
  });

  // ============================================
  // Integration Tests
  // ============================================

  describe('integration', () => {
    it('handles multiple action types simultaneously', async () => {
      await service.recordAction('email', mockUserId, mockBusinessId);
      await service.recordAction('sms', mockUserId, mockBusinessId);
      await service.recordAction('api_call', mockUserId, mockBusinessId);

      const emailUsage = await service.getUsage('email', mockUserId, mockBusinessId);
      const smsUsage = await service.getUsage('sms', mockUserId, mockBusinessId);
      const apiUsage = await service.getUsage('api_call', mockUserId, mockBusinessId);

      expect(emailUsage.count).toBe(1);
      expect(smsUsage.count).toBe(1);
      expect(apiUsage.count).toBe(1);
    });

    it('enforces different limits for different actions', async () => {
      const testService = new RateLimitService({
        email: {
          maxActions: 2,
          windowMs: 60 * 1000,
          description: 'Test email limit',
        },
        sms: {
          maxActions: 5,
          windowMs: 60 * 1000,
          description: 'Test SMS limit',
        },
      });

      // Fill email limit
      await testService.recordAction('email', mockUserId, mockBusinessId);
      await testService.recordAction('email', mockUserId, mockBusinessId);

      // Fill SMS limit
      for (let i = 0; i < 5; i++) {
        await testService.recordAction('sms', mockUserId, mockBusinessId);
      }

      const emailResult = await testService.checkLimit('email', mockUserId, mockBusinessId);
      const smsResult = await testService.checkLimit('sms', mockUserId, mockBusinessId);

      expect(emailResult.allowed).toBe(false);
      expect(smsResult.allowed).toBe(false);

      // SMS had higher limit, so different counts
      const emailUsage = await testService.getUsage('email', mockUserId, mockBusinessId);
      const smsUsage = await testService.getUsage('sms', mockUserId, mockBusinessId);

      expect(emailUsage.count).toBe(2);
      expect(smsUsage.count).toBe(5);
    });
  });
});

// ============================================
// Singleton Tests
// ============================================

describe('getRateLimitService', () => {
  it('returns singleton instance', () => {
    const instance1 = getRateLimitService();
    const instance2 = getRateLimitService();
    expect(instance1).toBe(instance2);
  });
});
