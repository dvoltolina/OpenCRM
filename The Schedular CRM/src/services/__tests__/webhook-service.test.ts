/**
 * WebhookService Tests
 */

import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';
import { WebhookService } from '../webhook-service';
import type { RateLimitService } from '../RateLimitService';
import type { AuditLogService } from '../AuditLogService';
import crypto from 'crypto';

const context = {
  businessId: 'biz-123',
  userId: 'user-1',
  userName: 'Tester',
  userRole: 'admin',
};

const mockRateLimit = (): RateLimitService =>
  ({
    checkLimit: vi.fn().mockResolvedValue({
      allowed: true,
      remaining: 5,
      resetAt: new Date(Date.now() + 1_000),
    }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  } as unknown as RateLimitService);

const mockAudit = (): AuditLogService =>
  ({
    logAction: vi.fn().mockResolvedValue({ success: true, data: undefined }),
  } as unknown as AuditLogService);

describe('WebhookService', () => {
  let service: WebhookService;
  let rateLimit: RateLimitService;
  let audit: AuditLogService;
  let store: any;

  beforeEach(() => {
    rateLimit = mockRateLimit();
    audit = mockAudit();
    const deadLetterStore: any[] = [];
    const inboundStore = new Set<string>();
    store = {
      hasInbound: vi.fn().mockImplementation(async (biz: string, id: string) =>
        inboundStore.has(`${biz}:${id}`)
      ),
      recordInbound: vi.fn().mockImplementation(async (biz: string, record: { id: string }) => {
        inboundStore.add(`${biz}:${record.id}`);
      }),
      recordDeadLetter: vi.fn().mockImplementation((_biz, entry) => {
        const id = `dead-${deadLetterStore.length + 1}`;
        deadLetterStore.push({ id, ...entry, lastAttemptAt: new Date() });
        return Promise.resolve(id);
      }),
      listDeadLetters: vi.fn().mockImplementation(async () => deadLetterStore),
    };
    service = new WebhookService(rateLimit, audit, vi.fn(), store);
  });

  it('validates webhook signatures', async () => {
    const payload = JSON.stringify({ id: 'evt-1', data: 'x' });
    const secret = 'top-secret';
    const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');

    const result = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-1',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature,
        payload: {},
      },
      payload,
      signature,
      secret
    );

    expect(result.accepted).toBe(true);
    expect(store.recordInbound).toHaveBeenCalled();
  });

  it('rejects webhook with bad signature', async () => {
    const result = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-2',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature: 'bad',
        payload: {},
      },
      '{"id":"evt-2"}',
      'bad',
      'secret'
    );

    expect(result.accepted).toBe(false);
    expect(result.reason).toContain('Invalid signature');
  });

  it('rejects duplicate inbound webhook ids', async () => {
    const payload = JSON.stringify({ id: 'evt-dup' });
    const secret = 'top-secret';
    const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');

    const first = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-dup',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature,
        payload: {},
      },
      payload,
      signature,
      secret
    );

    expect(first.accepted).toBe(true);

    const second = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-dup',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature,
        payload: {},
      },
      payload,
      signature,
      secret
    );

    expect(second.accepted).toBe(false);
    expect(second.reason).toContain('Duplicate');
  });

  it('rejects webhook when payload is too large', async () => {
    const payload = 'x'.repeat(140_000);
    const secret = 'top-secret';
    const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');

    const result = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-oversize',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature,
        payload: {},
      },
      payload,
      signature,
      secret
    );

    expect(result.accepted).toBe(false);
    expect(result.reason).toContain('Payload too large');
  });

  it('creates dead-letter entry after outbound failures', async () => {
    const failingClient = vi.fn().mockResolvedValue({ ok: false, status: 500 });
    service = new WebhookService(rateLimit, audit, failingClient as any, store);

    const result = await service.sendOutboundWebhook(context, {
      destination: 'https://example.com/webhook',
      event: {
        id: 'evt-3',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature: '',
        payload: { id: 'lead-1', email: 'hidden@example.com' },
      },
      maxAttempts: 1,
    });

    expect(result.success).toBe(false);
    const deadLetters = await service.getDeadLetters(context.businessId);
    expect(deadLetters.length).toBeGreaterThan(0);
    expect(deadLetters[0]?.payloadHash).toBeDefined();
    expect(store.recordDeadLetter).toHaveBeenCalled();
  });

  it('blocks outbound webhooks to non-https destinations', async () => {
    const result = await service.sendOutboundWebhook(context, {
      destination: 'http://example.com/webhook',
      event: {
        id: 'evt-plain',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(),
        signature: '',
        payload: { id: 'lead-1' },
      },
    });

    expect(result.success).toBe(false);
    expect(result.attempts).toBe(0);
    const auditPayload = (audit.logAction as unknown as Mock).mock.calls.at(-1)?.[1];
    expect(auditPayload?.metadata?.reason).toBe('non_https_destination');
  });

  it('rejects webhook with stale timestamp to prevent replay', async () => {
    const payload = JSON.stringify({ id: 'evt-stale' });
    const secret = 'top-secret';
    const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');

    const result = await service.handleInboundWebhook(
      context,
      {
        id: 'evt-stale',
        type: 'lead.created',
        businessId: context.businessId,
        occurredAt: new Date(Date.now() - 10 * 60 * 1000),
        signature,
        payload: {},
      },
      payload,
      signature,
      secret
    );

    expect(result.accepted).toBe(false);
    expect(result.reason).toContain('Stale');
  });
});
