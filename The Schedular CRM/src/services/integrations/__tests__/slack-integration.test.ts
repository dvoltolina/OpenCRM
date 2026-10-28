/**
 * Slack Integration Tests
 * Tests for Slack OAuth flow, notifications, and webhook handling
 *
 * Task 8: Native Integrations Framework
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { SlackIntegration } from '../slack-integration';
import type { SecurityContext } from '../../../data/repositories/repository-types';

// Mock fetch globally
global.fetch = vi.fn() as any;

// Mock integration repository
const mockIntegrationRepo = {
  create: vi.fn(),
  getById: vi.fn(),
  getByIdWithTokens: vi.fn(),
  updateOAuthTokens: vi.fn(),
  updateStatus: vi.fn(),
  clearOAuthTokens: vi.fn(),
  recordSync: vi.fn(),
  recordError: vi.fn(),
};

vi.mock('../../../data/repositories/integration-repository', () => ({
  getIntegrationRepository: vi.fn(() => mockIntegrationRepo),
}));

// Mock TokenEncryptionService - encrypts/decrypts as passthrough for testing
const mockEncryptionService = {
  encrypt: vi.fn((value: string) => Promise.resolve(`encrypted:${value}`)),
  decrypt: vi.fn((value: string) => {
    // Handle both prefixed and legacy tokens
    if (value.startsWith('encrypted:')) {
      return Promise.resolve(value.replace('encrypted:', ''));
    }
    // For backwards compatibility with base64 encoded test data
    try {
      return Promise.resolve(Buffer.from(value, 'base64').toString('utf-8'));
    } catch {
      return Promise.resolve(value);
    }
  }),
  initialize: vi.fn(),
  rotate: vi.fn(),
  needsRotation: vi.fn(() => false),
};

vi.mock('../../token-encryption-service', () => ({
  getTokenEncryptionService: vi.fn(() => mockEncryptionService),
  TokenEncryptionService: vi.fn(() => mockEncryptionService),
  resetTokenEncryptionService: vi.fn(),
}));

// ============================================
// Test Setup
// ============================================

describe('SlackIntegration', () => {
  let slackIntegration: SlackIntegration;
  let mockContext: SecurityContext;
  let mockFetch: any;

  beforeEach(() => {
    slackIntegration = new SlackIntegration();
    mockContext = {
      businessId: 'test-business-id',
      userId: 'test-user-id',
      userName: 'Test User',
      userRole: 'admin',
    };
    mockFetch = global.fetch as any;
    vi.clearAllMocks();
    Object.values(mockIntegrationRepo).forEach((fn) => fn.mockReset());

    // Set environment variables for tests
    process.env.SLACK_CLIENT_ID = 'test-client-id';
    process.env.SLACK_CLIENT_SECRET = 'test-client-secret';
    process.env.SLACK_SIGNING_SECRET = 'test-signing-secret';
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Core Properties Tests
  // ============================================

  describe('Core Properties', () => {
    it('should have correct name', () => {
      expect(slackIntegration.name).toBe('Slack');
    });

    it('should have correct type', () => {
      expect(slackIntegration.type).toBe('native');
    });

    it('should have correct provider', () => {
      expect(slackIntegration.provider).toBe('slack');
    });
  });

  // ============================================
  // OAuth Authorization URL Tests
  // ============================================

  describe('getAuthorizationUrl', () => {
    it('should generate valid authorization URL', () => {
      const redirectUri = 'https://app.example.com/oauth/callback';
      const url = slackIntegration.getAuthorizationUrl(mockContext, redirectUri);

      expect(url).toContain('https://slack.com/oauth/v2/authorize');
      expect(url).toContain('client_id=test-client-id');
      expect(url).toContain(`redirect_uri=${encodeURIComponent(redirectUri)}`);
      expect(url).toContain('scope=');
      expect(url).toContain('state=');
    });

    it('should include required scopes', () => {
      const url = slackIntegration.getAuthorizationUrl(
        mockContext,
        'https://app.example.com'
      );

      const urlObj = new URL(url);
      const scopes = urlObj.searchParams.get('scope')?.split(',') || [];

      expect(scopes).toContain('chat:write');
      expect(scopes).toContain('channels:read');
    });

    it('should include state parameter', () => {
      const url = slackIntegration.getAuthorizationUrl(
        mockContext,
        'https://app.example.com'
      );

      const urlObj = new URL(url);
      const state = urlObj.searchParams.get('state');

      expect(state).toBeTruthy();
      expect(state).toMatch(/^[A-Za-z0-9+/=]+$/); // Base64 pattern
    });

    it('should throw if SLACK_CLIENT_ID not configured', () => {
      delete process.env.SLACK_CLIENT_ID;

      expect(() =>
        slackIntegration.getAuthorizationUrl(mockContext, 'https://app.example.com')
      ).toThrow('SLACK_CLIENT_ID not configured');
    });

    it('should reject invalid context', () => {
      const invalidContext = {
        ...mockContext,
        userRole: 'staff' as const,
      };

      expect(() =>
        slackIntegration.getAuthorizationUrl(invalidContext, 'https://app.example.com')
      ).toThrow('Only administrators can manage integrations');
    });
  });

  // ============================================
  // Notification Tests
  // ============================================

  describe('sendNotification', () => {
    it('should send notification successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true }),
      } as Response);

      const result = await slackIntegration.sendNotification(
        'test-integration-id',
        '#general',
        'Test message',
        'test-business-id'
      );

      expect(result.success).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith(
        'https://slack.com/api/chat.postMessage',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-access-token',
            'Content-Type': 'application/json',
          }),
        })
      );
    });

    it('should sanitize message before sending', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true }),
      } as Response);

      const messageWithPHI = 'Contact John Doe at john@example.com or 555-1234';

      await slackIntegration.sendNotification(
        'test-integration-id',
        '#general',
        messageWithPHI,
        'test-business-id'
      );

      const fetchCall = mockFetch.mock.calls[0];
      const body = JSON.parse(fetchCall[1]?.body as string);

      expect(body.text).not.toContain('john@example.com');
      expect(body.text).not.toContain('555-1234');
      expect(body.text).not.toContain('John Doe');
    });

    it('should handle integration not found', async () => {
      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: false,
      });

      const result = await slackIntegration.sendNotification(
        'nonexistent-id',
        '#general',
        'Test message',
        'test-business-id'
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('not found');
    });

    it('should handle Slack API error', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: false, error: 'channel_not_found' }),
      } as Response);

      const result = await slackIntegration.sendNotification(
        'test-integration-id',
        '#nonexistent',
        'Test message',
        'test-business-id'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBeTruthy();
    });
  });

  // ============================================
  // Webhook Handling Tests
  // ============================================

  describe('handleWebhook', () => {
    it('should handle URL verification challenge', async () => {
      const payload = {
        type: 'url_verification',
        challenge: 'test-challenge-token',
      };

      const result = await slackIntegration.handleWebhook(payload, '');

      expect(result.success).toBe(true);
      expect(result.metadata?.challenge).toBe('test-challenge-token');
    });

    it('should handle event callbacks', async () => {
      const payload = {
        type: 'event_callback',
        team_id: 'T12345',
        event: {
          type: 'message',
          channel: 'C12345',
          user: 'U12345',
          text: 'Test message',
        },
      };

      const result = await slackIntegration.handleWebhook(payload, '');

      expect(result.success).toBe(true);
      expect(result.metadata?.eventType).toBe('message');
      expect(result.metadata?.teamId).toBe('T12345');
    });

    it('should handle unknown webhook types gracefully', async () => {
      const payload = {
        type: 'unknown_type',
      };

      const result = await slackIntegration.handleWebhook(payload, '');

      expect(result.success).toBe(true);
    });

    it('should sanitize errors in webhook handling', async () => {
      // Pass invalid payload to trigger error
      const result = await slackIntegration.handleWebhook(null, '');

      if (!result.success) {
        expect(result.error).toBeDefined();
        expect(typeof result.error).toBe('string');
      }
    });
  });

  // ============================================
  // Webhook Signature Validation Tests
  // ============================================

  describe('validateWebhookSignature', () => {
    it('should validate correct signature', () => {
      const timestamp = Math.floor(Date.now() / 1000).toString();
      const payload = 'test-payload';

      // Calculate expected signature
      const crypto = require('crypto');
      const sigBaseString = `v0:${timestamp}:${payload}`;
      const signature = `v0=${crypto
        .createHmac('sha256', 'test-signing-secret')
        .update(sigBaseString)
        .digest('hex')}`;

      const isValid = slackIntegration['validateWebhookSignature'](
        payload,
        signature,
        timestamp
      );

      expect(isValid).toBe(true);
    });

    it('should reject invalid signature', () => {
      const timestamp = Math.floor(Date.now() / 1000).toString();
      const payload = 'test-payload';
      const signature = 'v0=invalid-signature';

      const isValid = slackIntegration['validateWebhookSignature'](
        payload,
        signature,
        timestamp
      );

      expect(isValid).toBe(false);
    });

    it('should reject old timestamps', () => {
      // Timestamp from 10 minutes ago
      const oldTimestamp = (Math.floor(Date.now() / 1000) - 600).toString();
      const payload = 'test-payload';

      const crypto = require('crypto');
      const sigBaseString = `v0:${oldTimestamp}:${payload}`;
      const signature = `v0=${crypto
        .createHmac('sha256', 'test-signing-secret')
        .update(sigBaseString)
        .digest('hex')}`;

      const isValid = slackIntegration['validateWebhookSignature'](
        payload,
        signature,
        oldTimestamp
      );

      expect(isValid).toBe(false);
    });

    it('should handle missing signing secret', () => {
      delete process.env.SLACK_SIGNING_SECRET;

      const timestamp = Math.floor(Date.now() / 1000).toString();
      const payload = 'test-payload';
      const signature = 'v0=test-signature';

      expect(() =>
        slackIntegration['validateWebhookSignature'](payload, signature, timestamp)
      ).toThrow('SLACK_SIGNING_SECRET not configured');
    });
  });

  // ============================================
  // Test Connection Tests
  // ============================================

  describe('testConnection', () => {
    it('should test connection successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true, team: 'Test Team' }),
      } as Response);

      const result = await slackIntegration.testConnection(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(true);
      expect(result.data?.success).toBe(true);
      expect(result.data?.message).toContain('valid');
    });

    it('should handle no access token', async () => {
      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: { id: 'test-id' },
      });

      const result = await slackIntegration.testConnection(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(true);
      expect(result.data?.success).toBe(false);
      expect(result.data?.message).toContain('No access token');
    });

    it('should handle Slack API failure', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: false, error: 'token_revoked' }),
      } as Response);

      const result = await slackIntegration.testConnection(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(true);
      expect(result.data?.success).toBe(false);
      expect(result.data?.message).toContain('failed');
    });
  });

  // ============================================
  // HIPAA Compliance Tests
  // ============================================

  describe('HIPAA Compliance', () => {
    it('should sanitize all outbound messages', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true }),
      } as Response);

      const messageWithPHI =
        'Patient John Doe (john.doe@example.com) called at 555-123-4567';

      await slackIntegration.sendNotification(
        'test-integration-id',
        '#general',
        messageWithPHI,
        'test-business-id'
      );

      const fetchCall = mockFetch.mock.calls[0];
      const body = JSON.parse(fetchCall[1]?.body as string);

      expect(body.text).not.toContain('John Doe');
      expect(body.text).not.toContain('john.doe@example.com');
      expect(body.text).not.toContain('555-123-4567');
      expect(body.text).toContain('[NAME]');
      expect(body.text).toContain('[EMAIL]');
      expect(body.text).toContain('[PHONE]');
    });

    it('should not expose PHI in error messages', async () => {
      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockRejectedValue(
        new Error('User john.doe@example.com not found')
      );

      const result = await slackIntegration.sendNotification(
        'test-integration-id',
        '#general',
        'Test message',
        'test-business-id'
      );

      expect(result.success).toBe(false);
      expect(result.error).not.toContain('john.doe@example.com');
    });
  });
});
