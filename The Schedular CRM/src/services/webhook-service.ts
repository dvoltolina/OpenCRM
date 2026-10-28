/**
 * Webhook/Zapier Service
 * Validates inbound webhook signatures, throttles requests, audits activity,
 * and delivers outbound webhooks with retry/backoff + dead-letter logging.
 *
 * HIPAA: Never persist or log payload content; only store hashes/IDs.
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService } from './AuditLogService';
import type { DeadLetterEvent, WebhookEventEnvelope } from '../types/integrations';
import { withExponentialBackoff } from '../utils/backoff';
import type { WebhookPersistence } from '../data/repositories/webhook-repository';
import { getWebhookPersistence } from '../data/repositories/webhook-repository';

const WEBHOOK_MAX_SKEW_MS = 5 * 60 * 1000; // 5 minutes
const MAX_WEBHOOK_PAYLOAD_BYTES = 128 * 1024; // 128KB ceiling to avoid PHI/DoS

export interface InboundWebhookResult {
  accepted: boolean;
  reason?: string;
}

export interface OutboundWebhookRequest {
  destination: string;
  event: WebhookEventEnvelope;
  headers?: Record<string, string>;
  maxAttempts?: number;
}

type HttpClient = (destination: string, payload: unknown, headers?: Record<string, string>) => Promise<{
  status: number;
  ok: boolean;
}>;

export class WebhookService {
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private httpClient: HttpClient;
  private store: WebhookPersistence;

  constructor(
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService,
    httpClient?: HttpClient,
    store?: WebhookPersistence
  ) {
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
    this.store = store || getWebhookPersistence();
    this.httpClient =
      httpClient ||
      (async (destination: string, payload: unknown, headers?: Record<string, string>) => {
        const response = await fetch(destination, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(headers || {}),
          },
          body: JSON.stringify(payload),
        });
        return { status: response.status, ok: response.ok };
      });
  }

  /**
   * Validate and throttle inbound webhook (lead intake, etc.).
   */
  async handleInboundWebhook(
    context: SecurityContext,
    envelope: WebhookEventEnvelope,
    rawBody: string,
    signature: string | undefined,
    secret: string
  ): Promise<InboundWebhookResult> {
    if (!signature || !(await this.validateSignature(rawBody, signature, secret))) {
      return { accepted: false, reason: 'Invalid signature' };
    }

    if (envelope.businessId !== context.businessId) {
      return { accepted: false, reason: 'Tenant mismatch' };
    }

    const occurredAtMs = new Date(envelope.occurredAt).getTime();
    const now = Date.now();
    if (!Number.isFinite(occurredAtMs) || Math.abs(now - occurredAtMs) > WEBHOOK_MAX_SKEW_MS) {
      return { accepted: false, reason: 'Stale or invalid timestamp' };
    }

    const payloadSize = this.getPayloadSize(rawBody);
    if (payloadSize > MAX_WEBHOOK_PAYLOAD_BYTES) {
      await this.audit.logAction(context, {
        action: 'webhook',
        entityType: 'webhook',
        entityId: envelope.id,
        entityName: envelope.type,
        metadata: {
          payloadHash: this.hashPayload(rawBody),
          reason: 'payload_too_large',
          payloadSize,
        },
      });
      return { accepted: false, reason: 'Payload too large' };
    }

    if (await this.store.hasInbound(context.businessId, envelope.id)) {
      await this.audit.logAction(context, {
        action: 'webhook',
        entityType: 'webhook',
        entityId: envelope.id,
        entityName: envelope.type,
        metadata: {
          payloadHash: this.hashPayload(rawBody),
          reason: 'duplicate_event',
        },
      });
      return { accepted: false, reason: 'Duplicate webhook event' };
    }

    const limit = await this.rateLimit.checkLimit('webhook', context.userId, context.businessId);
    if (!limit.allowed) {
      return { accepted: false, reason: 'Webhook throttled' };
    }

    await this.rateLimit.recordAction('webhook', context.userId, context.businessId);
    await this.audit.logAction(context, {
      action: 'webhook',
      entityType: 'webhook',
      entityId: envelope.id,
      entityName: envelope.type,
      metadata: {
        payloadHash: this.hashPayload(rawBody),
        receivedAt: envelope.occurredAt,
      },
    });

    try {
      await this.store.recordInbound(context.businessId, {
        id: envelope.id,
        type: envelope.type,
        payloadHash: this.hashPayload(rawBody),
        occurredAt: new Date(envelope.occurredAt),
        receivedAt: new Date(),
      });
    } catch {
      // Persistence is best-effort; do not leak failures to caller.
    }

    return { accepted: true };
  }

  /**
   * Deliver an outbound webhook with retry/backoff and dead-letter logging.
   */
  async sendOutboundWebhook(
    context: SecurityContext,
    request: OutboundWebhookRequest
  ): Promise<{ success: boolean; attempts: number; deadLetterId?: string }> {
    if (!this.isHttpsDestination(request.destination)) {
      await this.audit.logAction(context, {
        action: 'webhook',
        entityType: 'webhook',
        entityId: request.event.id,
        entityName: request.event.type,
        metadata: {
          destination: request.destination,
          reason: 'non_https_destination',
        },
      });
      return { success: false, attempts: 0 };
    }

    const limit = await this.rateLimit.checkLimit('webhook', context.userId, context.businessId);
    if (!limit.allowed) {
      return { success: false, attempts: 0 };
    }

    const payload = this.sanitizePayload(request.event.payload);
    let attempts = 0;
    let deadLetterId: string | undefined;

    const result = await withExponentialBackoff({
      operation: async () => {
        attempts += 1;
        const response = await this.httpClient(request.destination, payload, request.headers);
        if (!response.ok) {
          throw new Error(`Webhook delivery failed with status ${response.status}`);
        }
      },
      maxAttempts: request.maxAttempts || 3,
      shouldRetry: () => true,
    });

    if (result.error) {
      try {
        deadLetterId = await this.store.recordDeadLetter(context.businessId, {
          businessId: context.businessId,
          destination: request.destination,
          reason: result.error instanceof Error ? result.error.message : 'delivery_failed',
          attempts,
          payloadHash: this.hashPayload(JSON.stringify(payload)),
          status: 'failed',
        });
      } catch {
        deadLetterId = undefined;
      }
    }

    await this.rateLimit.recordAction('webhook', context.userId, context.businessId);
    await this.audit.logAction(context, {
      action: 'webhook',
      entityType: 'webhook',
      entityId: request.event.id,
      entityName: request.event.type,
      metadata: {
        destination: request.destination,
        attempts,
        deadLetterId,
        payloadHash: this.hashPayload(JSON.stringify(payload)),
      },
    });

    return { success: !result.error, attempts, deadLetterId };
  }

  /**
   * Accessor for dead-letter queue (sanitized, no PHI).
   */
  async getDeadLetters(businessId: string): Promise<DeadLetterEvent[]> {
    try {
      return await this.store.listDeadLetters(businessId);
    } catch {
      return [];
    }
  }

  private getPayloadSize(raw: string): number {
    if (!raw) {
      return 0;
    }

    if (typeof TextEncoder !== 'undefined') {
      return new TextEncoder().encode(raw).length;
    }

    try {
      // Node/browserify fallback
      return Buffer.byteLength(raw, 'utf8');
    } catch {
      return raw.length;
    }
  }

  private isHttpsDestination(destination: string): boolean {
    try {
      const url = new URL(destination);
      return url.protocol === 'https:';
    } catch {
      return false;
    }
  }

  private async validateSignature(payload: string, signature: string, secret: string): Promise<boolean> {
    if (!payload || !signature || !secret) {
      return false;
    }

    const expected = await this.computeHmac(payload, secret);
    return this.timingSafeCompare(expected, signature);
  }

  private async computeHmac(payload: string, secret: string): Promise<string> {
    // Browser/web crypto path
    try {
      if (typeof crypto !== 'undefined' && 'subtle' in crypto) {
        const encoder = new TextEncoder();
        const keyData = encoder.encode(secret);
        const key = await crypto.subtle.importKey('raw', keyData, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
        const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
        const bytes = new Uint8Array(signatureBuffer);
        return Array.from(bytes)
          .map((b) => b.toString(16).padStart(2, '0'))
          .join('');
      }
    } catch {
      // Fallback below
    }

    // Node runtime path
    try {
      const { createHmac } = await import('crypto');
      return createHmac('sha256', secret).update(payload).digest('hex');
    } catch {
      // Fallback below
    }

    // Simple hash fallback if crypto unavailable
    return this.hashPayload(`${payload}:${secret}`);
  }

  private timingSafeCompare(a: string, b: string): boolean {
    if (a.length !== b.length) {
      return false;
    }
    let mismatch = 0;
    for (let i = 0; i < a.length; i++) {
      mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return mismatch === 0;
  }

  private sanitizePayload(payload: unknown): Record<string, unknown> {
    if (!payload || typeof payload !== 'object') {
      return {};
    }

    const sanitized: Record<string, unknown> = {};
    Object.entries(payload as Record<string, unknown>).forEach(([key, value]) => {
      if (['name', 'email', 'phone', 'notes', 'message', 'body'].includes(key)) {
        return; // skip potential PHI
      }
      sanitized[key] = value;
    });
    return sanitized;
  }

  private hashPayload(raw: string): string {
    let hash = 0;
    for (let i = 0; i < raw.length; i++) {
      hash = (hash << 5) - hash + raw.charCodeAt(i);
      hash |= 0; // Convert to 32bit integer
    }
    return `h${Math.abs(hash)}`;
  }
}

let webhookService: WebhookService | null = null;

export function getWebhookService(): WebhookService {
  if (!webhookService) {
    webhookService = new WebhookService();
  }
  return webhookService;
}
