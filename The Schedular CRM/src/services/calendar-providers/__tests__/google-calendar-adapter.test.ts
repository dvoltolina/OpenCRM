import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { GoogleCalendarAdapter } from '../google-calendar-adapter';
import { DEFAULT_CALENDAR_TITLE } from '../provider-sanitizers';

describe('GoogleCalendarAdapter', () => {
  const adapter = new GoogleCalendarAdapter();

  beforeEach(() => {
    vi.resetAllMocks();
  });

  afterEach(() => {
    globalThis.fetch = undefined as unknown as typeof global.fetch;
  });

  it('maps provider events with sanitized fields and activity metadata', async () => {
    const sampleEvent = {
      id: 'evt-1',
      summary: 'Consult with John Doe john@example.com',
      description: 'Discuss +1 555-123-4567 details',
      start: { dateTime: '2024-01-01T10:00:00Z' },
      end: { dateTime: '2024-01-01T11:00:00Z' },
      updated: '2024-01-01T09:00:00Z',
      created: '2024-01-01T08:00:00Z',
      attendees: [{ email: 'john@example.com' }],
      extendedProperties: { private: { activityId: 'act-123' } },
    };

    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ items: [sampleEvent] }),
      text: async () => JSON.stringify({ items: [sampleEvent] }),
      headers: { get: () => 'application/json' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const events = await adapter.listEvents(
      'token',
      'primary',
      new Date('2024-01-01T00:00:00Z'),
      new Date('2024-01-02T00:00:00Z')
    );

    expect(events).toHaveLength(1);
    expect(events[0]!.title).toBe(DEFAULT_CALENDAR_TITLE);
    expect(events[0]!.description).toContain('[redacted]');
    expect(events[0]!.attendeeCount).toBe(1);
    expect(events[0]!.activityId).toBe('act-123');
    expect(events[0]!.updatedAt!.toISOString()).toBe('2024-01-01T09:00:00.000Z');
  });

  it('creates events with sanitized payload', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ id: 'evt-new' }),
      text: async () => 'ok',
      headers: { get: () => 'application/json' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const newId = await adapter.createEvent('token', 'primary', {
      title: 'Call Jane Smith jane@example.com',
      description: 'Dial +1 (777) 555-1212',
      startTime: new Date('2024-01-02T12:00:00Z'),
      endTime: new Date('2024-01-02T12:30:00Z'),
      activityId: 'act-999',
      attendeeEmails: ['team-member@example.com'],
    });

    expect(newId).toBe('evt-new');
    const [, requestInit] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(requestInit.body as string);
    expect(body.summary).toBe(DEFAULT_CALENDAR_TITLE);
    expect(body.description).toContain('[redacted]');
    expect(body.extendedProperties.private.activityId).toBe('act-999');
    expect(body.attendees[0].email).toBe('team-member@example.com');
  });

  it('sanitizes provider errors to avoid leaking identifiers', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: false,
      text: async () => 'Unauthorized john@example.com secret-long-token-12345678901234567890',
      statusText: 'Unauthorized',
      headers: { get: () => 'text/plain' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    try {
      await adapter.deleteEvent('token', 'primary', 'evt-bad');
      throw new Error('Expected to throw');
    } catch (error) {
      const message = (error as Error).message;
      expect(message).toContain('Unauthorized');
      expect(message).not.toContain('john@example.com');
      expect(message).not.toContain('secret-long-token-12345678901234567890');
    }
  });
});
