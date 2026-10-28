/**
 * ImportExportService Tests
 */

import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';
import { ImportExportService, type ImportSessionStore, type ImportSessionState } from '../import-export-service';
import type { RateLimitService } from '../RateLimitService';
import type { AuditLogService } from '../AuditLogService';

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

describe('ImportExportService', () => {
  let service: ImportExportService;
  let rateLimit: RateLimitService;
  let audit: AuditLogService;

  beforeEach(() => {
    rateLimit = mockRateLimit();
    audit = mockAudit();
    service = new ImportExportService(rateLimit, audit);
    // Ensure mocks are used even if constructor fallback changes
    (service as any).rateLimit = rateLimit;
    (service as any).audit = audit;
  });

  it('allows import for staff because import RBAC matches backend security rules', async () => {
    const result = await service.startImport(
      { ...context, userRole: 'staff' },
      {
        entityType: 'lead',
        rows: [['John', 'Doe', 'john@example.com']],
        headers: ['firstName', 'lastName', 'email'],
        fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
      }
    );

    expect(result.success).toBe(true);
    expect(result.errors).toBeUndefined();
  });

  it('returns validation errors without leaking row data', async () => {
    const result = await service.startImport(context, {
      entityType: 'lead',
      rows: [['John', 'Doe', 'not-an-email']],
      headers: ['firstName', 'lastName', 'email'],
      fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
    });

    expect(result.success).toBe(false);
    expect(result.validationErrors[0]?.field).toBe('email');
    expect((result.validationErrors[0] as any).value).toBeUndefined();
  });

  it('blocks import when identifiers collide with existing records', async () => {
    const result = await service.startImport(context, {
      entityType: 'contact',
      rows: [['Jane', 'Smith', 'collision@example.com', '+1 (555) 000-0000']],
      headers: ['firstName', 'lastName', 'email', 'phone'],
      fieldMapping: {
        firstName: 'firstName',
        lastName: 'lastName',
        email: 'email',
        phone: 'phone',
      },
      existingIdentifiers: {
        emails: ['collision@example.com'],
        phones: ['+1-555-000-0000'],
      },
    });

    expect(result.success).toBe(false);
    expect(result.validationErrors.some((err) => err.field === 'email')).toBe(true);
    expect(result.validationErrors.some((err) => err.field === 'phone')).toBe(true);
  });

  it('exports CSV with audit logging', async () => {
    const exportResult = await service.exportData(context, {
      entity: 'deal',
      format: 'csv',
      filters: { status: 'open' },
    });

    expect(exportResult.success).toBe(true);
    expect(exportResult.contentType).toBe('text/csv');
    expect(exportResult.content).toContain('deal_1');
    expect(exportResult.exportId).toMatch(/export_/);
    expect((audit.logAction as unknown as Mock)).toHaveBeenCalled();
  });

  it('returns backoff metadata when rate limited', async () => {
    (rateLimit.checkLimit as unknown as Mock).mockResolvedValueOnce({
      allowed: false,
      remaining: 0,
      resetAt: new Date(Date.now() + 2_000),
      message: 'Too many imports',
    });

    const result = await service.startImport(context, {
      entityType: 'lead',
      rows: [['John', 'Doe', 'john@example.com']],
      headers: ['firstName', 'lastName', 'email'],
      fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
    });

    expect(result.success).toBe(false);
    expect(result.backoffMs).toBeGreaterThan(0);
    expect(result.errors?.[0]).toContain('Too many imports');
  });

  it('persists and reloads session state via provided store', async () => {
    const storeData = new Map<string, ImportSessionState>();
    const store: ImportSessionStore = {
      load: async (biz, id) => storeData.get(`${biz}:${id}`) || null,
      save: async (biz, id, state) => {
        storeData.set(`${biz}:${id}`, state);
      },
      delete: async (biz, id) => {
        storeData.delete(`${biz}:${id}`);
      },
    };

    const serviceWithStore = new ImportExportService(rateLimit, audit, store);
    const started = await serviceWithStore.startImport(context, {
      entityType: 'lead',
      rows: [['John', 'Doe', 'john@example.com']],
      headers: ['firstName', 'lastName', 'email'],
      fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
      sessionId: 'sess-store',
    });

    expect(storeData.has(`${context.businessId}:${started.sessionId}`)).toBe(true);

    // Simulate paused state persisted externally without validation errors
    const stored = storeData.get(`${context.businessId}:${started.sessionId}`)!;
    storeData.set(`${context.businessId}:${started.sessionId}`, {
      ...stored,
      status: 'paused',
      errors: [],
    });

    const reloadedService = new ImportExportService(rateLimit, audit, store);
    const resumed = await reloadedService.resumeImport(context, {
      sessionId: started.sessionId,
      resumeToken: started.resumeToken || '',
    });

    expect(resumed.success).toBe(true);
    expect(resumed.processedRows).toBe(resumed.totalRows);
  });

  it('rejects resume with invalid token', async () => {
    const resume = await service.resumeImport(context, {
      sessionId: 'missing',
      resumeToken: 'bad',
    });

    expect(resume.success).toBe(false);
    expect(resume.errors?.[0]).toContain('Invalid resume token');
  });

  it('rejects resume when validation errors remain', async () => {
    const started = await service.startImport(context, {
      entityType: 'lead',
      rows: [['John', 'Doe', 'bad-email']],
      headers: ['firstName', 'lastName', 'email'],
      fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
      sessionId: 'sess-1',
    });

    const resume = await service.resumeImport(context, {
      sessionId: started.sessionId,
      resumeToken: started.resumeToken || '',
    });

    expect(resume.success).toBe(false);
    expect(resume.errors?.[0]).toContain('Validation errors');
  });

  it('rejects resume when session businessId mismatches context', async () => {
    const mismatchedSession: ImportSessionState = {
      businessId: 'other-biz',
      createdBy: 'user-x',
      createdByRole: 'admin',
      entityType: 'lead',
      startedAt: new Date(),
      expiresAt: new Date(Date.now() + 10_000),
      processedRows: 1,
      totalRows: 1,
      errors: [],
      resumeToken: 'resume-token',
      status: 'paused',
    };

    const store: ImportSessionStore = {
      load: async () => mismatchedSession,
      save: async () => {},
      delete: async () => {},
    };

    const scopedService = new ImportExportService(rateLimit, audit, store);
    const resume = await scopedService.resumeImport(context, {
      sessionId: 'sess-mismatch',
      resumeToken: mismatchedSession.resumeToken,
    });

    expect(resume.success).toBe(false);
    expect(resume.errors?.[0]).toContain('does not belong');
  });

  it('rejects resume when session is expired', async () => {
    const expiredSession: ImportSessionState = {
      businessId: context.businessId,
      createdBy: context.userId,
      createdByRole: context.userRole,
      entityType: 'lead',
      startedAt: new Date(Date.now() - 50_000),
      expiresAt: new Date(Date.now() - 1_000),
      processedRows: 0,
      totalRows: 1,
      errors: [],
      resumeToken: 'expired-token',
      status: 'paused',
    };

    const store: ImportSessionStore = {
      load: async () => expiredSession,
      save: async () => {},
      delete: async () => {},
    };

    const scopedService = new ImportExportService(rateLimit, audit, store);
    const resume = await scopedService.resumeImport(context, {
      sessionId: 'sess-expired',
      resumeToken: expiredSession.resumeToken,
    });

    expect(resume.success).toBe(false);
    expect(resume.errors?.[0]).toContain('expired');
  });

  it('allows resume for staff because import RBAC matches backend security rules', async () => {
    const started = await service.startImport(context, {
      entityType: 'lead',
      rows: [['John', 'Doe', 'john@example.com']],
      headers: ['firstName', 'lastName', 'email'],
      fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
      sessionId: 'sess-2',
    });

    const session = service.getSession(context.businessId, started.sessionId);
    expect(session).toBeDefined();
    if (session) {
      session.status = 'paused';
      session.errors = [];
    }

    const resume = await service.resumeImport(
      { ...context, userRole: 'staff' },
      {
        sessionId: started.sessionId,
        resumeToken: started.resumeToken || '',
      }
    );

    expect(resume.success).toBe(true);
    expect(resume.errors).toBeUndefined();
  });

  it('still blocks export for staff', async () => {
    const result = await service.exportData(
      { ...context, userRole: 'staff' },
      {
        entity: 'deal',
        format: 'csv',
      }
    );

    expect(result.success).toBe(false);
    expect(result.errors?.[0]).toContain('Insufficient permissions for export');
  });
});
