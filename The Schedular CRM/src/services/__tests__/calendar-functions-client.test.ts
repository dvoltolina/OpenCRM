import { describe, it, expect, beforeEach, vi } from 'vitest';

vi.mock('firebase/auth', () => ({
  getAuth: () => ({
    currentUser: {
      getIdToken: vi.fn().mockResolvedValue('id-token'),
    },
  }),
}));

import {
  connectCalendar,
  isCalendarFunctionsConfigured,
} from '../calendar-functions-client';

describe('calendar-functions-client', () => {
  beforeEach(() => {
    Object.assign((import.meta as any).env, {
      VITE_FUNCTIONS_BASE_URL: 'https://functions.test',
      VITE_FIREBASE_PROJECT_ID: 'crm-project',
    });
    vi.resetAllMocks();
  });

  it('detects configuration when base URL is present', () => {
    expect(isCalendarFunctionsConfigured()).toBe(true);
  });

  it('posts to connectCalendar with auth headers and business scope', async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, connectionId: 'conn-123' }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      })
    );
    global.fetch = fetchMock as any;

    const result = await connectCalendar({
      provider: 'google',
      authCode: 'code-123',
      businessId: 'biz-1',
    });

    expect(result.success).toBe(true);
    expect(result.connectionId).toBe('conn-123');
    const call = fetchMock.mock.calls[0];
    expect(call[0]).toContain('/connectCalendar');
    expect(call[1]).toMatchObject({
      method: 'POST',
      headers: expect.objectContaining({
        Authorization: 'Bearer id-token',
        'X-Business-Id': 'biz-1',
      }),
    });
  });

  it('returns sanitized error on failure', async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ error: 'provider error' }), {
        status: 400,
        headers: { 'content-type': 'application/json' },
      })
    );
    global.fetch = fetchMock as any;

    const result = await connectCalendar({
      provider: 'google',
      authCode: 'bad-code',
      businessId: 'biz-1',
    });

    expect(result.success).toBe(false);
    expect(result.error).toBe('provider error');
  });

  it('falls back to the Firebase project functions host when the env override is absent', async () => {
    Object.assign((import.meta as any).env, {
      VITE_FUNCTIONS_BASE_URL: '',
      VITE_FIREBASE_PROJECT_ID: 'crm-project',
    });
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, connectionId: 'conn-456' }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      })
    );
    global.fetch = fetchMock as any;

    const result = await connectCalendar({
      provider: 'outlook',
      authCode: 'code-456',
      businessId: 'biz-2',
    });

    expect(result.success).toBe(true);
    expect(fetchMock.mock.calls[0]?.[0]).toMatch(
      /^https:\/\/us-central1-.*\.cloudfunctions\.net\/connectCalendar$/
    );
  });
});
