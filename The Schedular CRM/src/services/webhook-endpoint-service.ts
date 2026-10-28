/**
 * Webhook Endpoint Service
 * Complete API for managing webhook endpoints, triggering events, and tracking deliveries
 *
 * Task 2: API & Third-Party Integrations - Webhook Service
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - Payloads are sanitized before delivery - no PHI transmitted
 * - Webhook secrets use HMAC-SHA256 for signature verification
 * - All deliveries are logged for audit trail (without PHI)
 *
 * Security:
 * - Only admin/owner roles can manage endpoints
 * - URLs must be HTTPS
 * - Secrets shown only once on creation/regeneration
 * - Rate limiting on outbound deliveries
 * - Exponential backoff with configurable retries
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getWebhookEndpointRepository,
  type CreateWebhookEndpointInput,
  type UpdateWebhookEndpointInput,
} from '../data/repositories/webhook-endpoint-repository';
import {
  getWebhookDeliveryRepository,
  type ListDeliveriesOptions,
} from '../data/repositories/webhook-delivery-repository';
import { getRateLimitService, type RateLimitService } from './RateLimitService';
import { getAuditLogService, type AuditLogService } from './AuditLogService';
import { withExponentialBackoff } from '../utils/backoff';
import type {
  WebhookEndpoint,
  WebhookDelivery,
  WebhookEvent,
  WebhookTestResult,
} from '../types/integrations';
import type { PaginatedResult } from '../data/repositories/repository-types';

// ============================================
// Types
// ============================================

export interface WebhookServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export interface TriggerEventPayload {
  event: WebhookEvent;
  timestamp: string;
  data: Record<string, unknown>;
  changes?: string[];
  previousValue?: unknown;
  newValue?: unknown;
}

type HttpClient = (
  url: string,
  payload: unknown,
  headers?: Record<string, string>
) => Promise<{
  status: number;
  ok: boolean;
  body?: string;
  responseTimeMs: number;
}>;

// ============================================
// Service Implementation
// ============================================

export class WebhookEndpointService {
  private endpointRepo = getWebhookEndpointRepository();
  private deliveryRepo = getWebhookDeliveryRepository();
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private httpClient: HttpClient;

  constructor(
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService,
    httpClient?: HttpClient
  ) {
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
    this.httpClient =
      httpClient ||
      (async (
        url: string,
        payload: unknown,
        headers?: Record<string, string>
      ) => {
        const startTime = Date.now();
        try {
          const response = await fetch(url, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              ...headers,
            },
            body: JSON.stringify(payload),
          });
          const body = await response.text().catch(() => '');
          return {
            status: response.status,
            ok: response.ok,
            body,
            responseTimeMs: Date.now() - startTime,
          };
        } catch (error) {
          return {
            status: 0,
            ok: false,
            body: error instanceof Error ? error.message : 'Network error',
            responseTimeMs: Date.now() - startTime,
          };
        }
      });
  }

  // ============================================
  // Endpoint Management
  // ============================================

  /**
   * Create a new webhook endpoint
   * Returns the endpoint with the secret (shown only once)
   */
  async createEndpoint(
    context: SecurityContext,
    input: CreateWebhookEndpointInput
  ): Promise<WebhookServiceResult<WebhookEndpoint & { secret: string }>> {
    const result = await this.endpointRepo.create(context, input);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    await this.audit.logAction(context, {
      action: 'webhook_endpoint_created',
      entityType: 'webhook_endpoint',
      entityId: result.data.id,
      entityName: result.data.name,
      metadata: {
        events: result.data.events,
        url: result.data.url,
      },
    });

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Update an existing webhook endpoint
   */
  async updateEndpoint(
    context: SecurityContext,
    endpointId: string,
    updates: UpdateWebhookEndpointInput
  ): Promise<WebhookServiceResult<WebhookEndpoint>> {
    const result = await this.endpointRepo.update(context, endpointId, updates);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    await this.audit.logAction(context, {
      action: 'webhook_endpoint_updated',
      entityType: 'webhook_endpoint',
      entityId: result.data.id,
      entityName: result.data.name,
      metadata: {
        updatedFields: Object.keys(updates),
      },
    });

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Delete a webhook endpoint
   */
  async deleteEndpoint(
    context: SecurityContext,
    endpointId: string
  ): Promise<WebhookServiceResult<void>> {
    // Get endpoint info for audit before deleting
    const existing = await this.endpointRepo.getById(context, endpointId);

    const result = await this.endpointRepo.delete(context, endpointId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    await this.audit.logAction(context, {
      action: 'webhook_endpoint_deleted',
      entityType: 'webhook_endpoint',
      entityId: endpointId,
      entityName: existing.success ? existing.data.name : 'Unknown',
      metadata: {},
    });

    return { success: true };
  }

  /**
   * Get all webhook endpoints for the business
   */
  async getEndpoints(
    context: SecurityContext
  ): Promise<WebhookServiceResult<WebhookEndpoint[]>> {
    const result = await this.endpointRepo.getAll(context);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get a single endpoint by ID
   */
  async getEndpoint(
    context: SecurityContext,
    endpointId: string
  ): Promise<WebhookServiceResult<WebhookEndpoint>> {
    const result = await this.endpointRepo.getById(context, endpointId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Regenerate the secret for an endpoint
   * Returns the new secret (shown only once)
   */
  async regenerateSecret(
    context: SecurityContext,
    endpointId: string
  ): Promise<WebhookServiceResult<string>> {
    const result = await this.endpointRepo.regenerateSecret(
      context,
      endpointId
    );

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    await this.audit.logAction(context, {
      action: 'webhook_secret_regenerated',
      entityType: 'webhook_endpoint',
      entityId: endpointId,
      entityName: 'Secret',
      metadata: {},
    });

    return {
      success: true,
      data: result.data,
    };
  }

  // ============================================
  // Endpoint Testing
  // ============================================

  /**
   * Test a webhook endpoint with a sample payload
   */
  async testEndpoint(
    context: SecurityContext,
    endpointId: string
  ): Promise<WebhookServiceResult<WebhookTestResult>> {
    const endpointResult = await this.endpointRepo.getByIdWithSecret(
      context,
      endpointId
    );

    if (!endpointResult.success) {
      return {
        success: false,
        error: {
          code: endpointResult.error.code,
          message: endpointResult.error.message,
        },
      };
    }

    const endpoint = endpointResult.data;

    // Create test payload
    const testPayload = {
      event: 'test' as const,
      timestamp: new Date().toISOString(),
      data: {
        message: 'This is a test webhook delivery',
        endpointId: endpoint.id,
        businessId: context.businessId,
      },
    };

    // Compute signature
    const signature = await this.computeSignature(
      JSON.stringify(testPayload),
      endpoint.secret
    );

    // Prepare headers
    const headers: Record<string, string> = {
      'X-Webhook-Signature': signature,
      'X-Webhook-Event': 'test',
      'X-Webhook-Timestamp': testPayload.timestamp,
      ...endpoint.customHeaders,
    };

    // Make the test request
    const response = await this.httpClient(
      endpoint.url,
      testPayload,
      headers
    );

    const testResult: WebhookTestResult = {
      success: response.ok,
      statusCode: response.status,
      responseTimeMs: response.responseTimeMs,
      error: response.ok ? undefined : `HTTP ${response.status}`,
    };

    await this.audit.logAction(context, {
      action: 'webhook_endpoint_tested',
      entityType: 'webhook_endpoint',
      entityId: endpointId,
      entityName: endpoint.name,
      metadata: {
        success: testResult.success,
        statusCode: testResult.statusCode,
        responseTimeMs: testResult.responseTimeMs,
      },
    });

    return {
      success: true,
      data: testResult,
    };
  }

  // ============================================
  // Event Triggering
  // ============================================

  /**
   * Trigger webhooks for a specific event
   * Sends to all active endpoints subscribed to the event
   */
  async triggerEvent(
    context: SecurityContext,
    event: WebhookEvent,
    payload: Record<string, unknown>
  ): Promise<void> {
    // Check rate limit
    const limit = await this.rateLimit.checkLimit(
      'webhook_trigger',
      context.userId,
      context.businessId
    );
    if (!limit.allowed) {
      return; // Silently skip if rate limited
    }

    // Get all endpoints subscribed to this event
    const endpoints = await this.endpointRepo.getByEvent(
      context.businessId,
      event
    );

    if (endpoints.length === 0) {
      return; // No endpoints to trigger
    }

    // Sanitize payload - remove PHI
    const sanitizedPayload = this.sanitizePayload(payload);

    // Build event envelope
    const envelope: TriggerEventPayload = {
      event,
      timestamp: new Date().toISOString(),
      data: sanitizedPayload,
    };

    // Trigger each endpoint asynchronously
    const deliveryPromises = endpoints.map((endpoint) =>
      this.deliverToEndpoint(context, endpoint, envelope)
    );

    // Don't await - fire and forget for performance
    // Errors are logged in deliverToEndpoint
    Promise.allSettled(deliveryPromises).catch(() => {
      // Ignore collective errors
    });

    await this.rateLimit.recordAction(
      'webhook_trigger',
      context.userId,
      context.businessId
    );
  }

  /**
   * Deliver a webhook to a specific endpoint with retry logic
   */
  private async deliverToEndpoint(
    context: SecurityContext,
    endpoint: WebhookEndpoint,
    payload: TriggerEventPayload
  ): Promise<void> {
    // Create delivery record
    const deliveryId = await this.deliveryRepo.create(context.businessId, {
      webhookId: endpoint.id,
      event: payload.event,
      payload: payload.data,
    });

    // Compute signature
    const signature = await this.computeSignature(
      JSON.stringify(payload),
      endpoint.secret
    );

    // Prepare headers
    const headers: Record<string, string> = {
      'X-Webhook-Signature': signature,
      'X-Webhook-Event': payload.event,
      'X-Webhook-Timestamp': payload.timestamp,
      'X-Webhook-Delivery': deliveryId,
      ...endpoint.customHeaders,
    };

    const maxAttempts = endpoint.retryEnabled ? endpoint.maxRetries : 1;
    let lastResponse: {
      status: number;
      ok: boolean;
      body?: string;
      responseTimeMs: number;
    } = { status: 0, ok: false, body: '', responseTimeMs: 0 };

    const result = await withExponentialBackoff({
      operation: async () => {
        const response = await this.httpClient(endpoint.url, payload, headers);
        lastResponse = response;

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        return response;
      },
      maxAttempts,
      baseDelayMs: 1000,
      shouldRetry: (_error) => {
        // Retry on network errors and 5xx errors
        if (lastResponse && lastResponse.status >= 400 && lastResponse.status < 500) {
          return false; // Don't retry 4xx errors
        }
        return true;
      },
    });

    if (result.error) {
      // Delivery failed after all retries
      await this.deliveryRepo.updateStatus(context.businessId, deliveryId, {
        status: 'failed',
        responseStatus: lastResponse.status,
        responseBody: lastResponse.body,
        responseTimeMs: lastResponse.responseTimeMs,
      });

      await this.endpointRepo.incrementFailure(
        context.businessId,
        endpoint.id,
        result.error instanceof Error ? result.error.message : 'Delivery failed'
      );
    } else {
      // Delivery successful
      await this.deliveryRepo.updateStatus(context.businessId, deliveryId, {
        status: 'success',
        responseStatus: lastResponse.status,
        responseBody: lastResponse.body,
        responseTimeMs: lastResponse.responseTimeMs,
      });

      await this.endpointRepo.resetFailure(context.businessId, endpoint.id);
      await this.endpointRepo.recordTrigger(context.businessId, endpoint.id);
    }
  }

  // ============================================
  // Delivery Management
  // ============================================

  /**
   * Get delivery history for a webhook endpoint
   */
  async getDeliveries(
    context: SecurityContext,
    endpointId: string,
    options?: ListDeliveriesOptions
  ): Promise<WebhookServiceResult<PaginatedResult<WebhookDelivery>>> {
    const result = await this.deliveryRepo.getByWebhookId(
      context,
      endpointId,
      options
    );

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Retry a failed delivery manually
   */
  async retryDelivery(
    context: SecurityContext,
    deliveryId: string
  ): Promise<WebhookServiceResult<void>> {
    const deliveryResult = await this.deliveryRepo.getById(context, deliveryId);

    if (!deliveryResult.success) {
      return {
        success: false,
        error: {
          code: deliveryResult.error.code,
          message: deliveryResult.error.message,
        },
      };
    }

    const delivery = deliveryResult.data;

    // Get the endpoint
    const endpointResult = await this.endpointRepo.getByIdWithSecret(
      context,
      delivery.webhookId
    );

    if (!endpointResult.success) {
      return {
        success: false,
        error: {
          code: endpointResult.error.code,
          message: endpointResult.error.message,
        },
      };
    }

    const endpoint = endpointResult.data;

    // Reset delivery for retry
    await this.deliveryRepo.resetForRetry(context, deliveryId);

    // Rebuild payload envelope
    const payload: TriggerEventPayload = {
      event: delivery.event,
      timestamp: new Date().toISOString(),
      data: delivery.payload,
    };

    // Re-trigger delivery
    await this.deliverToEndpoint(context, endpoint, payload);

    await this.audit.logAction(context, {
      action: 'webhook_delivery_retried',
      entityType: 'webhook_delivery',
      entityId: deliveryId,
      entityName: delivery.event,
      metadata: {
        webhookId: delivery.webhookId,
      },
    });

    return { success: true };
  }

  // ============================================
  // Private Helpers
  // ============================================

  /**
   * Compute HMAC-SHA256 signature for payload verification
   */
  private async computeSignature(
    payload: string,
    secret: string
  ): Promise<string> {
    const webCrypto = globalThis.crypto;
    if (!webCrypto?.subtle) {
      throw new Error('Web Crypto API is required for webhook signature generation');
    }

    const encoder = new TextEncoder();
    const key = await webCrypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    const signatureBuffer = await webCrypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(payload)
    );
    const bytes = new Uint8Array(signatureBuffer);
    return Array.from(bytes)
      .map((byte) => byte.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * Sanitize payload to remove potential PHI fields
   * HIPAA: Never send PHI in webhook payloads
   */
  private sanitizePayload(
    payload: Record<string, unknown>
  ): Record<string, unknown> {
    // Exact field names that should always be redacted
    const exactSensitiveFields = new Set([
      'name',
      'email',
      'phone',
      'address',
      'street',
      'city',
      'state',
      'zip',
      'notes',
      'message',
      'body',
      'ssn',
      'dob',
      'password',
      'secret',
      'token',
    ]);

    // Field name patterns that indicate PHI (match at end of camelCase)
    const sensitivePatterns = [
      /firstName$/i,
      /lastName$/i,
      /fullName$/i,
      /emailAddress$/i,
      /phoneNumber$/i,
      /mobilePhone$/i,
      /homePhone$/i,
      /workPhone$/i,
      /streetAddress$/i,
      /zipCode$/i,
      /postalCode$/i,
      /birthDate$/i,
      /dateOfBirth$/i,
      /medicalRecord$/i,
      /healthInfo$/i,
      /insuranceNumber$/i,
      /socialSecurity$/i,
      /diagnosis$/i,
      /treatment$/i,
      /medication$/i,
      /accessToken$/i,
      /refreshToken$/i,
      /apiKey$/i,
      /apiSecret$/i,
    ];

    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(payload)) {
      const lowerKey = key.toLowerCase();

      // Check exact matches
      const isExactMatch = exactSensitiveFields.has(lowerKey);

      // Check pattern matches
      const isPatternMatch = sensitivePatterns.some((pattern) => pattern.test(key));

      if (isExactMatch || isPatternMatch) {
        // Include field but redact value
        sanitized[key] = '[REDACTED]';
      } else if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        // Recursively sanitize nested objects
        sanitized[key] = this.sanitizePayload(value as Record<string, unknown>);
      } else if (Array.isArray(value)) {
        // Sanitize array items if they are objects
        sanitized[key] = value.map((item) =>
          typeof item === 'object' && item !== null
            ? this.sanitizePayload(item as Record<string, unknown>)
            : item
        );
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }
}

// ============================================
// Singleton Instance
// ============================================

let webhookEndpointService: WebhookEndpointService | null = null;

export function getWebhookEndpointService(): WebhookEndpointService {
  if (!webhookEndpointService) {
    webhookEndpointService = new WebhookEndpointService();
  }
  return webhookEndpointService;
}
