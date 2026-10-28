import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  OutlookCalendarAdapter,
  OUTLOOK_ACTIVITY_ID_PROPERTY_ID,
} from '../outlook-calendar-adapter';
import { DEFAULT_CALENDAR_TITLE } from '../provider-sanitizers';

describe('OutlookCalendarAdapter', () => {
  const adapter = new OutlookCalendarAdapter();

  beforeEach(() => {
    vi.resetAllMocks();
  });

  afterEach(() => {
    globalThis.fetch = undefined as unknown as typeof global.fetch;
  });

  it('maps events with sanitized metadata', async () => {
    const sampleEvent = {
      id: 'evt-2',
      subject: 'Planning with Jane Roe',
      bodyPreview: 'Follow up with +1 999-888-7777',
      start: { dateTime: '2024-02-01T09:00:00Z' },
      end: { dateTime: '2024-02-01T09:30:00Z' },
      isAllDay: false,
      lastModifiedDateTime: '2024-02-01T08:00:00Z',
      createdDateTime: '2024-02-01T07:00:00Z',
      attendees: [{ emailAddress: { address: 'staff@example.com' } }],
      singleValueExtendedProperties: [{ id: OUTLOOK_ACTIVITY_ID_PROPERTY_ID, value: 'act-555' }],
      location: { displayName: 'HQ Conference' },
    };

    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ value: [sampleEvent] }),
      text: async () => JSON.stringify({ value: [sampleEvent] }),
      headers: { get: () => 'application/json' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const events = await adapter.listEvents(
      'token',
      'primary',
      new Date('2024-02-01T00:00:00Z'),
      new Date('2024-02-02T00:00:00Z')
    );

    expect(events).toHaveLength(1);
    expect(events[0].title).toBe(DEFAULT_CALENDAR_TITLE);
    expect(events[0].description).toContain('[redacted]');
    expect(events[0].attendeeCount).toBe(1);
    expect(events[0].activityId).toBe('act-555');
    expect(events[0].location).toBe('HQ Conference');
  });

  it('creates events with sanitized payload and activity link', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ id: 'evt-new' }),
      text: async () => 'ok',
      headers: { get: () => 'application/json' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const newId = await adapter.createEvent('token', 'primary', {
      title: 'Demo with Client X',
      description: 'Send deck to client@example.com',
      startTime: new Date('2024-03-01T14:00:00Z'),
      endTime: new Date('2024-03-01T14:30:00Z'),
      activityId: 'act-777',
      attendeeEmails: ['team@example.com'],
    });

    expect(newId).toBe('evt-new');
    const [, requestInit] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(requestInit.body as string);
    expect(body.subject).toBe(DEFAULT_CALENDAR_TITLE);
    expect(body.body.content).toContain('[redacted]');
    expect(body.singleValueExtendedProperties[0].id).toBe(OUTLOOK_ACTIVITY_ID_PROPERTY_ID);
    expect(body.singleValueExtendedProperties[0].value).toBe('act-777');
    expect(body.attendees[0].emailAddress.address).toBe('team@example.com');
  });

  it('sanitizes provider errors', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: false,
      text: async () => 'Forbidden jane@example.com super-secret-token-1234567890123456',
      statusText: 'Forbidden',
      headers: { get: () => 'text/plain' },
    });
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    await expect(
      adapter.deleteEvent('token', 'primary', 'evt-fail')
    ).rejects.toThrow(/Forbidden/);

    try {
      await adapter.deleteEvent('token', 'primary', 'evt-fail');
    } catch (error) {
      const message = (error as Error).message;
      expect(message).not.toContain('jane@example.com');
      expect(message).not.toContain('super-secret-token-1234567890123456');
    }
  });
});
