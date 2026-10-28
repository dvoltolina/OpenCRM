/**
 * IntegrationSyncService Tests
 */

import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';
import { IntegrationSyncService, type IntegrationSyncAdapter } from '../integration-sync-service';
import type { SyncRecord } from '../../types/integrations';
import type { RateLimitService } from '../RateLimitService';
import type { AuditLogService } from '../AuditLogService';
import type { SyncStateStore } from '../../data/repositories/integration-sync-state-repository';

const buildJwt = (payload: Record<string, unknown>): string => {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.sig`;
};

const context = {
  businessId: 'biz-123',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
};

const mockRateLimit = (): RateLimitService =>
  ({
    checkLimit: vi.fn().mockResolvedValue({
      allowed: true,
      remaining: 10,
      resetAt: new Date(Date.now() + 1_000),
    }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  } as unknown as RateLimitService);

const mockAudit = (): AuditLogService =>
  ({
    logAction: vi.fn().mockResolvedValue({ success: true, data: undefined }),
  } as unknown as AuditLogService);

const freshAdapter = (): IntegrationSyncAdapter<SyncRecord> => ({
  type: 'calendar',
  credential: {
    businessId: 'biz-123',
    provider: 'google_calendar',
    accessToken: 'token.part.payload',
    expiresAt: new Date(Date.now() + 60_000),
  },
  fetchRemoteChanges: vi.fn().mockResolvedValue({
    items: [{ id: '1', updatedAt: new Date('2024-01-01') }],
  }),
  fetchLocalChanges: vi.fn().mockResolvedValue({
    items: [{ id: '1', updatedAt: new Date('2024-01-02') }],
  }),
  applyRemoteChanges: vi.fn().mockResolvedValue(undefined),
  pushLocalChanges: vi.fn().mockResolvedValue({ created: 0, updated: 1 }),
});

describe('IntegrationSyncService', () => {
  let rateLimit: RateLimitService;
  let audit: AuditLogService;
  let service: IntegrationSyncService;
  let syncStore: SyncStateStore;

  beforeEach(() => {
    rateLimit = mockRateLimit();
    audit = mockAudit();
    syncStore = {
      load: vi.fn().mockResolvedValue(null),
      save: vi.fn().mockResolvedValue(undefined),
    };
    service = new IntegrationSyncService(rateLimit, audit, syncStore);
  });

  it('retries transient failures and reports retry count', async () => {
    const adapter = freshAdapter();
    (adapter.fetchRemoteChanges as unknown as Mock)
      .mockRejectedValueOnce(new Error('timeout'))
      .mockResolvedValueOnce({
        items: [{ id: '1', updatedAt: new Date('2024-01-03') }],
        cursor: 'next',
      });

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(true);
    expect(result.retried).toBe(1);
    expect((audit.logAction as unknown as Mock)).toHaveBeenCalled();
    const auditPayload = (audit.logAction as unknown as Mock).mock.calls[0]?.[1];
    expect(auditPayload?.action).toBe('integration');
  });

  it('detects conflicts and marks resolution direction', async () => {
    const adapter = freshAdapter();

    const result = await service.sync(context, adapter, {
      direction: 'bidirectional',
      allowConflicts: false,
    });

    expect(result.success).toBe(true);
    expect(result.conflicts).toHaveLength(1);
    expect(result.conflicts[0]?.resolution).toBe('local');
    expect(result.skipped).toBe(1);
  });

  it('flags checksum mismatches when timestamps match', async () => {
    const adapter = freshAdapter();
    (adapter.fetchRemoteChanges as unknown as Mock).mockResolvedValue({
      items: [{ id: '1', updatedAt: new Date('2024-01-01'), hash: 'a1' }],
    });
    (adapter.fetchLocalChanges as unknown as Mock).mockResolvedValue({
      items: [{ id: '1', updatedAt: new Date('2024-01-01'), hash: 'b2' }],
    });

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: false,
    });

    expect(result.success).toBe(true);
    expect(result.conflicts[0]?.reason).toBe('Checksum mismatch');
    expect(result.conflicts[0]?.resolution).toBe('manual');
    expect(result.skipped).toBe(1);
  });

  it('rejects mismatched tenant credentials', async () => {
    const adapter = freshAdapter();
    adapter.credential.businessId = 'other';

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(false);
    expect(result.errors?.[0]).toContain('Credential business mismatch');
  });

  it('rejects expired credentials', async () => {
    const adapter = freshAdapter();
    adapter.credential.expiresAt = new Date(Date.now() - 1000);

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(false);
    expect(result.errors?.[0]).toContain('Integration token expired');
  });

  it('rejects JWT credentials when exp claim is expired', async () => {
    const adapter = freshAdapter();
    adapter.credential.expiresAt = new Date(Date.now() + 60_000);
    adapter.credential.accessToken = buildJwt({
      exp: Math.floor(Date.now() / 1000) - 60,
      aud: 'scheduler-crm',
      businessId: context.businessId,
    });

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(false);
    expect(result.errors?.some((err) => err.includes('exp claim'))).toBe(true);
  });

  it('rejects staff-scoped credential when user mismatches', async () => {
    const adapter = freshAdapter();
    adapter.credential.staffId = 'other-staff';

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(false);
    expect(result.errors?.[0]).toContain('staff member');
  });

  it('surfaces timeout failures with backoff metadata', async () => {
    const adapter = freshAdapter();
    (adapter.fetchRemoteChanges as unknown as Mock).mockImplementation(
      () =>
        new Promise(() => {
          /* never resolves */
        })
    );

    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
      timeoutMs: 5,
    });

    expect(result.success).toBe(false);
    expect(result.errors?.[0]).toContain('timed out');
    expect(result.backoffMs).toBeGreaterThanOrEqual(0);
    expect(result.retried).toBeGreaterThan(0);
  });

  it('surfaces rate limit backoff data when throttled', async () => {
    (rateLimit.checkLimit as unknown as Mock).mockResolvedValueOnce({
      allowed: false,
      remaining: 0,
      resetAt: new Date(Date.now() + 5_000),
      message: 'Too many syncs',
    });

    const adapter = freshAdapter();
    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.success).toBe(false);
    expect(result.backoffMs).toBeGreaterThan(0);
    expect(result.errors?.[0]).toContain('Too many syncs');
  });

  it('persists sync cursor and backoff state', async () => {
    const adapter = freshAdapter();
    (adapter.fetchRemoteChanges as unknown as Mock).mockResolvedValue({
      items: [],
      cursor: 'c123',
    });
    const result = await service.sync(context, adapter, {
      direction: 'pull',
      allowConflicts: true,
    });

    expect(result.resumeCursor).toBe('c123');
    expect((syncStore.save as unknown as Mock)).toHaveBeenCalledWith(
      context.businessId,
      expect.objectContaining({
        cursor: 'c123',
        lastStatus: 'success',
      })
    );
  });
});
