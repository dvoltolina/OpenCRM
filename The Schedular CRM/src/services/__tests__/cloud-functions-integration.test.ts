import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  runIntegrationSync,
  startImportJob,
  runExport,
} from '../cloud-functions-integration';

vi.mock('firebase/auth', () => ({
  getAuth: () => ({
    currentUser: {
      getIdToken: vi.fn().mockResolvedValue('id-token'),
    },
  }),
}));

describe('cloud-functions-integration', () => {
  const fetchSpy = vi.fn();

  beforeEach(() => {
    Object.assign((import.meta as any).env, {
      VITE_FUNCTIONS_BASE_URL: '',
      VITE_FIREBASE_PROJECT_ID: 'crm-project',
    });
    fetchSpy.mockReset();
    vi.stubGlobal('fetch', fetchSpy);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('includes business header on integration sync', async () => {
    fetchSpy.mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: () =>
        Promise.resolve({
          success: true,
          created: 0,
          updated: 0,
          skipped: 0,
          conflicts: [],
          retried: 0,
        }),
    });

    await runIntegrationSync({
      integrationId: 'int-1',
      direction: 'pull',
      businessId: 'biz-123',
    });

    const headers = fetchSpy.mock.calls[0]?.[1]?.headers as Record<string, string>;
    expect(headers['X-Business-Id']).toBe('biz-123');
  });

  it('propagates export id header on success', async () => {
    const headers = new Headers({
      'X-Export-Id': 'exp-123',
      'content-type': 'text/csv',
    });
    fetchSpy.mockResolvedValue({
      ok: true,
      status: 200,
      headers,
      text: () => Promise.resolve('data'),
    });

    const response = await runExport({
      entity: 'deal',
      format: 'csv',
      businessId: 'biz-123',
    } as any);

    expect(response.success).toBe(true);
    expect(response.exportId).toBe('exp-123');
    const requestHeaders = fetchSpy.mock.calls[0]?.[1]?.headers as Record<string, string>;
    expect(requestHeaders['X-Business-Id']).toBe('biz-123');
  });

  it('sends business header on import', async () => {
    fetchSpy.mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: () =>
        Promise.resolve({
          success: true,
          sessionId: 'sess-1',
          processedRows: 1,
          totalRows: 1,
          validationErrors: [],
        }),
    });

    await startImportJob({
      businessId: 'biz-xyz',
      entityType: 'multi',
      primaryEntityType: 'deal',
      rows: [['a@example.com']],
      headers: ['email'],
      fieldMapping: { email: 'email' },
      existingIdentifiers: { emails: ['a@example.com'], phones: ['+1-222-333-4444'] },
    });

    const headers = fetchSpy.mock.calls[0]?.[1]?.headers as Record<string, string>;
    expect(headers['X-Business-Id']).toBe('biz-xyz');
    const body = JSON.parse(fetchSpy.mock.calls[0]?.[1]?.body as string);
    expect(body.existingIdentifiers).toEqual({
      emails: ['a@example.com'],
      phones: ['+1-222-333-4444'],
    });
    expect(body.primaryEntityType).toBe('deal');
  });
});
