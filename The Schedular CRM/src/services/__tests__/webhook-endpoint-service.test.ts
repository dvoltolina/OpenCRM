/**
 * Webhook Endpoint Service Tests
 *
 * Test coverage:
 * - Endpoint CRUD operations with RBAC
 * - Secret generation and regeneration
 * - Endpoint testing
 * - Event triggering to subscribed endpoints
 * - Delivery tracking and retry
 * - HIPAA payload sanitization
 * - Rate limiting
 * - HTTPS enforcement
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { WebhookEndpointService } from '../webhook-endpoint-service';
import type { RateLimitService } from '../RateLimitService';
import type { AuditLogService } from '../AuditLogService';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { WebhookEndpoint } from '../../types/integrations';

// ============================================
// Mock Setup
// ============================================

const adminContext: SecurityContext = {
  businessId: 'biz-123',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: ['team-1'],
};

const staffContext: SecurityContext = {
  businessId: 'biz-123',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: ['team-1'],
};

const mockRateLimit = (): RateLimitService =>
  ({
    checkLimit: vi.fn().mockResolvedValue({
      allowed: true,
      remaining: 10,
      resetAt: new Date(Date.now() + 60000),
    }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  }) as unknown as RateLimitService;

const mockAudit = (): AuditLogService =>
  ({
    logAction: vi.fn().mockResolvedValue({ success: true, data: undefined }),
  }) as unknown as AuditLogService;

const createMockHttpClient = (
  responses: Array<{ ok: boolean; status: number; body?: string }>
) => {
  let callIndex = 0;
  return vi.fn().mockImplementation(async () => {
    const response = responses[callIndex] || responses[responses.length - 1];
    callIndex++;
    return {
      ...response,
      responseTimeMs: 50,
    };
  });
};

// Mock repositories
const createMockEndpointRepo = () => {
  const endpoints = new Map<string, WebhookEndpoint>();
  let idCounter = 0;
  let secretCounter = 0;

  return {
    create: vi.fn().mockImplementation(async (context, input) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const id = `webhook-${++idCounter}`;
      const secret = `whsec_test_${++secretCounter}_${Date.now()}`;
      const endpoint: WebhookEndpoint = {
        id,
        businessId: context.businessId,
        name: input.name,
        description: input.description,
        url: input.url,
        secret,
        events: input.events,
        isActive: true,
        failureCount: 0,
        retryEnabled: input.retryEnabled ?? true,
        maxRetries: input.maxRetries ?? 3,
        customHeaders: input.customHeaders,
        createdById: context.userId,
        createdAt: new Date(),
      };
      endpoints.set(id, endpoint);
      return { success: true, data: { ...endpoint, secret }, error: null };
    }),
    getById: vi.fn().mockImplementation(async (context, id) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const endpoint = endpoints.get(id);
      if (!endpoint) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Webhook endpoint not found' },
        };
      }
      return { success: true, data: { ...endpoint, secret: '[REDACTED]' }, error: null };
    }),
    getByIdWithSecret: vi.fn().mockImplementation(async (context, id) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const endpoint = endpoints.get(id);
      if (!endpoint) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Webhook endpoint not found' },
        };
      }
      return { success: true, data: endpoint, error: null };
    }),
    getAll: vi.fn().mockImplementation(async (context) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const data = Array.from(endpoints.values()).map((e) => ({
        ...e,
        secret: '[REDACTED]',
      }));
      return {
        success: true,
        data: { data, lastDoc: null, hasMore: false },
        error: null,
      };
    }),
    getByEvent: vi.fn().mockImplementation(async (_businessId, event) => {
      return Array.from(endpoints.values()).filter(
        (e) => e.businessId === _businessId && e.isActive && e.events.includes(event)
      );
    }),
    update: vi.fn().mockImplementation(async (context, id, updates) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const endpoint = endpoints.get(id);
      if (!endpoint) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Webhook endpoint not found' },
        };
      }
      const updated = { ...endpoint, ...updates, updatedAt: new Date() };
      endpoints.set(id, updated);
      return { success: true, data: { ...updated, secret: '[REDACTED]' }, error: null };
    }),
    delete: vi.fn().mockImplementation(async (context, id) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      if (!endpoints.has(id)) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Webhook endpoint not found' },
        };
      }
      endpoints.delete(id);
      return { success: true, data: undefined, error: null };
    }),
    regenerateSecret: vi.fn().mockImplementation(async (context, id) => {
      if (context.userRole !== 'admin' && context.userRole !== 'owner') {
        return {
          success: false,
          data: null,
          error: { code: 'PERMISSION_DENIED', message: 'Unauthorized' },
        };
      }
      const endpoint = endpoints.get(id);
      if (!endpoint) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Webhook endpoint not found' },
        };
      }
      const newSecret = `whsec_regenerated_${Date.now()}`;
      endpoint.secret = newSecret;
      return { success: true, data: newSecret, error: null };
    }),
    recordTrigger: vi.fn().mockResolvedValue(undefined),
    incrementFailure: vi.fn().mockResolvedValue(undefined),
    resetFailure: vi.fn().mockResolvedValue(undefined),
  };
};

const createMockDeliveryRepo = () => {
  const deliveries = new Map<string, any>();
  let idCounter = 0;

  return {
    create: vi.fn().mockImplementation(async (_businessId, input) => {
      const id = `delivery-${++idCounter}`;
      deliveries.set(id, {
        id,
        businessId: _businessId,
        webhookId: input.webhookId,
        event: input.event,
        payload: input.payload,
        status: 'pending',
        attemptCount: 0,
        createdAt: new Date(),
      });
      return id;
    }),
    getById: vi.fn().mockImplementation(async (_context, id) => {
      const delivery = deliveries.get(id);
      if (!delivery) {
        return {
          success: false,
          data: null,
          error: { code: 'NOT_FOUND', message: 'Delivery not found' },
        };
      }
      return { success: true, data: delivery, error: null };
    }),
    getByWebhookId: vi.fn().mockImplementation(async (_context, webhookId) => {
      const data = Array.from(deliveries.values()).filter(
        (d) => d.webhookId === webhookId
      );
      return {
        success: true,
        data: { data, lastDoc: null, hasMore: false },
        error: null,
      };
    }),
    updateStatus: vi.fn().mockImplementation(async (_businessId, deliveryId, status) => {
      const delivery = deliveries.get(deliveryId);
      if (delivery) {
        Object.assign(delivery, status, { attemptCount: delivery.attemptCount + 1 });
      }
    }),
    resetForRetry: vi.fn().mockImplementation(async (_context, deliveryId) => {
      const delivery = deliveries.get(deliveryId);
      if (delivery) {
        delivery.status = 'pending';
        delivery.nextRetryAt = null;
      }
      return { success: true, data: undefined, error: null };
    }),
    getPendingRetries: vi.fn().mockResolvedValue([]),
    getFailedDeliveries: vi.fn().mockImplementation(async () => ({
      success: true,
      data: { data: [], lastDoc: null, hasMore: false },
      error: null,
    })),
  };
};

// ============================================
// Tests
// ============================================

describe('WebhookEndpointService', () => {
  let service: WebhookEndpointService;
  let rateLimit: ReturnType<typeof mockRateLimit>;
  let audit: ReturnType<typeof mockAudit>;
  let httpClient: ReturnType<typeof createMockHttpClient>;
  let endpointRepo: ReturnType<typeof createMockEndpointRepo>;
  let deliveryRepo: ReturnType<typeof createMockDeliveryRepo>;

  beforeEach(() => {
    rateLimit = mockRateLimit();
    audit = mockAudit();
    httpClient = createMockHttpClient([{ ok: true, status: 200 }]);
    endpointRepo = createMockEndpointRepo();
    deliveryRepo = createMockDeliveryRepo();

    // Create service with mocked dependencies
    service = new WebhookEndpointService(rateLimit, audit, httpClient);

    // Inject mock repositories via prototype override
    (service as any).endpointRepo = endpointRepo;
    (service as any).deliveryRepo = deliveryRepo;
  });

  // ============================================
  // Endpoint CRUD Tests
  // ============================================

  describe('Endpoint CRUD', () => {
    it('creates endpoint with valid input', async () => {
      const result = await service.createEndpoint(adminContext, {
        name: 'Test Webhook',
        url: 'https://example.com/webhook',
        events: ['lead.created', 'deal.won'],
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(result.data?.name).toBe('Test Webhook');
      expect(result.data?.secret).toContain('whsec_');
      expect(result.data?.events).toHaveLength(2);
      expect(audit.logAction).toHaveBeenCalled();
    });

    it('denies endpoint creation for non-admin users', async () => {
      const result = await service.createEndpoint(staffContext, {
        name: 'Test Webhook',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('PERMISSION_DENIED');
    });

    it('gets all endpoints for business', async () => {
      // Create two endpoints
      await service.createEndpoint(adminContext, {
        name: 'Webhook 1',
        url: 'https://example.com/hook1',
        events: ['lead.created'],
      });
      await service.createEndpoint(adminContext, {
        name: 'Webhook 2',
        url: 'https://example.com/hook2',
        events: ['deal.won'],
      });

      const result = await service.getEndpoints(adminContext);

      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(2);
      // Secrets should be redacted in list view
      result.data?.forEach((endpoint) => {
        expect(endpoint.secret).toBe('[REDACTED]');
      });
    });

    it('updates endpoint successfully', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Original Name',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      const updateResult = await service.updateEndpoint(
        adminContext,
        createResult.data!.id,
        { name: 'Updated Name', isActive: false }
      );

      expect(updateResult.success).toBe(true);
      expect(updateResult.data?.name).toBe('Updated Name');
      expect(updateResult.data?.isActive).toBe(false);
    });

    it('deletes endpoint successfully', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'To Delete',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      const deleteResult = await service.deleteEndpoint(
        adminContext,
        createResult.data!.id
      );

      expect(deleteResult.success).toBe(true);

      // Verify it's gone
      const getResult = await service.getEndpoint(
        adminContext,
        createResult.data!.id
      );
      expect(getResult.success).toBe(false);
    });
  });

  // ============================================
  // Secret Management Tests
  // ============================================

  describe('Secret Management', () => {
    it('generates unique secret on creation', async () => {
      const result1 = await service.createEndpoint(adminContext, {
        name: 'Webhook 1',
        url: 'https://example.com/hook1',
        events: ['lead.created'],
      });

      const result2 = await service.createEndpoint(adminContext, {
        name: 'Webhook 2',
        url: 'https://example.com/hook2',
        events: ['deal.won'],
      });

      expect(result1.data?.secret).not.toBe(result2.data?.secret);
    });

    it('regenerates secret successfully', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Test Webhook',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      const originalSecret = createResult.data!.secret;

      const regenerateResult = await service.regenerateSecret(
        adminContext,
        createResult.data!.id
      );

      expect(regenerateResult.success).toBe(true);
      expect(regenerateResult.data).toContain('whsec_regenerated_');
      expect(regenerateResult.data).not.toBe(originalSecret);
    });
  });

  // ============================================
  // Endpoint Testing Tests
  // ============================================

  describe('Endpoint Testing', () => {
    it('tests endpoint and returns success response', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Test Webhook',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      const testResult = await service.testEndpoint(
        adminContext,
        createResult.data!.id
      );

      expect(testResult.success).toBe(true);
      expect(testResult.data?.success).toBe(true);
      expect(testResult.data?.statusCode).toBe(200);
      expect(testResult.data?.responseTimeMs).toBeGreaterThan(0);
      expect(httpClient).toHaveBeenCalled();
    });

    it('tests endpoint and returns failure response', async () => {
      httpClient = createMockHttpClient([{ ok: false, status: 500 }]);
      (service as any).httpClient = httpClient;

      const createResult = await service.createEndpoint(adminContext, {
        name: 'Failing Webhook',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
      });

      const testResult = await service.testEndpoint(
        adminContext,
        createResult.data!.id
      );

      expect(testResult.success).toBe(true);
      expect(testResult.data?.success).toBe(false);
      expect(testResult.data?.statusCode).toBe(500);
      expect(testResult.data?.error).toContain('500');
    });

    it('includes custom headers in test request', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'With Headers',
        url: 'https://example.com/webhook',
        events: ['lead.created'],
        customHeaders: { 'X-Custom-Header': 'custom-value' },
      });

      await service.testEndpoint(adminContext, createResult.data!.id);

      const callArgs = httpClient.mock.calls[0];
      expect(callArgs[2]).toMatchObject({
        'X-Custom-Header': 'custom-value',
      });
    });
  });

  // ============================================
  // Event Triggering Tests
  // ============================================

  describe('Event Triggering', () => {
    it('triggers event to subscribed endpoints', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Lead Webhook',
        url: 'https://example.com/leads',
        events: ['lead.created'],
      });

      await service.triggerEvent(adminContext, 'lead.created', {
        id: 'lead-123',
        status: 'new',
      });

      // Wait for async delivery
      await new Promise((resolve) => setTimeout(resolve, 100));

      expect(deliveryRepo.create).toHaveBeenCalled();
      expect(httpClient).toHaveBeenCalled();
    });

    it('does not trigger event if no endpoints subscribed', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Deal Webhook',
        url: 'https://example.com/deals',
        events: ['deal.won'],
      });

      await service.triggerEvent(adminContext, 'lead.created', {
        id: 'lead-123',
      });

      // Wait for async operations
      await new Promise((resolve) => setTimeout(resolve, 100));

      expect(httpClient).not.toHaveBeenCalled();
    });

    it('respects rate limiting on event triggers', async () => {
      rateLimit.checkLimit = vi.fn().mockResolvedValue({
        allowed: false,
        remaining: 0,
        resetAt: new Date(),
      });

      await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.triggerEvent(adminContext, 'lead.created', {
        id: 'lead-123',
      });

      await new Promise((resolve) => setTimeout(resolve, 100));

      // Should not make HTTP call when rate limited
      expect(httpClient).not.toHaveBeenCalled();
    });
  });

  // ============================================
  // Payload Sanitization Tests (HIPAA)
  // ============================================

  describe('Payload Sanitization (HIPAA)', () => {
    it('redacts sensitive fields from webhook payloads', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.triggerEvent(adminContext, 'lead.created', {
        id: 'lead-123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '555-1234',
        status: 'new',
        ssn: '123-45-6789',
      });

      await new Promise((resolve) => setTimeout(resolve, 100));

      const deliveryPayload = deliveryRepo.create.mock.calls[0][1].payload;
      expect(deliveryPayload.firstName).toBe('[REDACTED]');
      expect(deliveryPayload.lastName).toBe('[REDACTED]');
      expect(deliveryPayload.email).toBe('[REDACTED]');
      expect(deliveryPayload.phone).toBe('[REDACTED]');
      expect(deliveryPayload.ssn).toBe('[REDACTED]');
      expect(deliveryPayload.id).toBe('lead-123');
      expect(deliveryPayload.status).toBe('new');
    });

    it('sanitizes nested objects', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['contact.created'],
      });

      await service.triggerEvent(adminContext, 'contact.created', {
        id: 'contact-1',
        details: {
          firstName: 'Jane',
          companyName: 'Acme Corp',
        },
      });

      await new Promise((resolve) => setTimeout(resolve, 100));

      const deliveryPayload = deliveryRepo.create.mock.calls[0][1].payload;
      expect(deliveryPayload.details.firstName).toBe('[REDACTED]');
      expect(deliveryPayload.details.companyName).toBe('Acme Corp');
    });
  });

  // ============================================
  // Delivery Tracking Tests
  // ============================================

  describe('Delivery Tracking', () => {
    it('gets delivery history for endpoint', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      // Trigger some events
      await service.triggerEvent(adminContext, 'lead.created', { id: 'lead-1' });
      await service.triggerEvent(adminContext, 'lead.created', { id: 'lead-2' });

      await new Promise((resolve) => setTimeout(resolve, 100));

      const deliveries = await service.getDeliveries(
        adminContext,
        createResult.data!.id
      );

      expect(deliveries.success).toBe(true);
    });

    it('retries failed delivery', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      // First delivery - fails
      httpClient = createMockHttpClient([
        { ok: false, status: 500 },
        { ok: true, status: 200 },
      ]);
      (service as any).httpClient = httpClient;

      await service.triggerEvent(adminContext, 'lead.created', { id: 'lead-1' });
      await new Promise((resolve) => setTimeout(resolve, 100));

      // Get the delivery ID
      const deliveryId = deliveryRepo.create.mock.results[0]?.value;

      // Mock a failed delivery
      deliveryRepo.getById = vi.fn().mockResolvedValue({
        success: true,
        data: {
          id: deliveryId,
          webhookId: createResult.data!.id,
          event: 'lead.created',
          payload: { id: 'lead-1' },
          status: 'failed',
          attemptCount: 1,
        },
        error: null,
      });

      // Retry
      const retryResult = await service.retryDelivery(adminContext, deliveryId);

      expect(retryResult.success).toBe(true);
      expect(deliveryRepo.resetForRetry).toHaveBeenCalled();
    });
  });

  // ============================================
  // Webhook Signature Tests
  // ============================================

  describe('Webhook Signatures', () => {
    it('includes signature header in requests', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.testEndpoint(adminContext, 'webhook-1');

      const headers = httpClient.mock.calls[0][2];
      expect(headers).toHaveProperty('X-Webhook-Signature');
      expect(headers).toHaveProperty('X-Webhook-Event', 'test');
      expect(headers).toHaveProperty('X-Webhook-Timestamp');
    });
  });

  // ============================================
  // Error Handling Tests
  // ============================================

  describe('Error Handling', () => {
    it('handles endpoint not found', async () => {
      const result = await service.getEndpoint(adminContext, 'nonexistent-id');

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('NOT_FOUND');
    });

    it('records delivery failure and increments endpoint failure count', async () => {
      httpClient = createMockHttpClient([{ ok: false, status: 500 }]);
      (service as any).httpClient = httpClient;

      await service.createEndpoint(adminContext, {
        name: 'Failing Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
        retryEnabled: false,
      });

      await service.triggerEvent(adminContext, 'lead.created', { id: 'lead-1' });
      await new Promise((resolve) => setTimeout(resolve, 100));

      expect(deliveryRepo.updateStatus).toHaveBeenCalledWith(
        adminContext.businessId,
        expect.any(String),
        expect.objectContaining({ status: 'failed' })
      );
      expect(endpointRepo.incrementFailure).toHaveBeenCalled();
    });

    it('resets failure count on successful delivery', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Webhook',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.triggerEvent(adminContext, 'lead.created', { id: 'lead-1' });
      await new Promise((resolve) => setTimeout(resolve, 100));

      expect(endpointRepo.resetFailure).toHaveBeenCalled();
      expect(endpointRepo.recordTrigger).toHaveBeenCalled();
    });
  });

  // ============================================
  // Audit Logging Tests
  // ============================================

  describe('Audit Logging', () => {
    it('logs endpoint creation', async () => {
      await service.createEndpoint(adminContext, {
        name: 'Audit Test',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_endpoint_created',
          entityType: 'webhook_endpoint',
        })
      );
    });

    it('logs endpoint update', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Original',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.updateEndpoint(adminContext, createResult.data!.id, {
        name: 'Updated',
      });

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_endpoint_updated',
        })
      );
    });

    it('logs endpoint deletion', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'To Delete',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.deleteEndpoint(adminContext, createResult.data!.id);

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_endpoint_deleted',
        })
      );
    });

    it('logs secret regeneration', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Secret Test',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.regenerateSecret(adminContext, createResult.data!.id);

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_secret_regenerated',
        })
      );
    });

    it('logs endpoint test', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Test Endpoint',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      await service.testEndpoint(adminContext, createResult.data!.id);

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_endpoint_tested',
        })
      );
    });

    it('logs delivery retry', async () => {
      const createResult = await service.createEndpoint(adminContext, {
        name: 'Retry Test',
        url: 'https://example.com/hook',
        events: ['lead.created'],
      });

      deliveryRepo.getById = vi.fn().mockResolvedValue({
        success: true,
        data: {
          id: 'delivery-1',
          webhookId: createResult.data!.id,
          event: 'lead.created',
          payload: { id: 'lead-1' },
          status: 'failed',
        },
        error: null,
      });

      await service.retryDelivery(adminContext, 'delivery-1');

      expect(audit.logAction).toHaveBeenCalledWith(
        adminContext,
        expect.objectContaining({
          action: 'webhook_delivery_retried',
        })
      );
    });
  });
});
