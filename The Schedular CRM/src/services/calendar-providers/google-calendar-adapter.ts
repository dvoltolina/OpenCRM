/**
 * Google Calendar Adapter
 * Wraps direct Google Calendar REST calls with HIPAA-aware sanitization.
 *
 * NOTE: Cloud Functions should be preferred in production. This adapter is a safe
 * fallback for dev/local flows and keeps responses metadata-only (no attendee emails).
 */

import { generateId } from '../../data/repositories/firestore-utils';
import type { CalendarEvent, CalendarEventInput } from '../../types/calendar-sync';
import {
  DEFAULT_CALENDAR_TITLE,
  isoDateOnly,
  sanitizeDescription,
  sanitizeErrorMessage,
  sanitizeTitle,
} from './provider-sanitizers';

export interface ProviderCalendar {
  id: string;
  name: string;
  primary?: boolean;
  accessRole?: string;
}

interface GoogleCalendarListResponse {
  items?: Array<{
    id: string;
    summary?: string;
    primary?: boolean;
    accessRole?: string;
  }>;
  nextPageToken?: string;
}

interface GoogleEvent {
  id: string;
  summary?: string;
  description?: string;
  location?: string;
  status?: string;
  start?: { dateTime?: string; date?: string; timeZone?: string };
  end?: { dateTime?: string; date?: string; timeZone?: string };
  updated?: string;
  created?: string;
  organizer?: { email?: string };
  attendees?: Array<{ email?: string }>;
  extendedProperties?: { private?: Record<string, string>; shared?: Record<string, string> };
}

interface GoogleEventListResponse {
  items?: GoogleEvent[];
  nextPageToken?: string;
}

const GOOGLE_CALENDAR_API_BASE = 'https://www.googleapis.com/calendar/v3';

export class GoogleCalendarAdapter {
  private async request<T>(
    accessToken: string,
    path: string,
    init: RequestInit,
    errorContext: string
  ): Promise<T> {
    const headers = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
      ...(init.headers || {}),
    };

    const response = await fetch(`${GOOGLE_CALENDAR_API_BASE}${path}`, { ...init, headers });
    if (!response.ok) {
      const errorBody = (await response.text()) || response.statusText;
      throw new Error(`${errorContext}: ${sanitizeErrorMessage(errorBody)}`);
    }

    const contentType = response.headers?.get?.('content-type') || '';
    if (!contentType.includes('application/json')) {
      return undefined as T;
    }
    return (await response.json()) as T;
  }

  async listCalendars(accessToken: string): Promise<ProviderCalendar[]> {
    let pageToken: string | undefined;
    const calendars: ProviderCalendar[] = [];

    do {
      const query = pageToken ? `?pageToken=${encodeURIComponent(pageToken)}` : '';
      const payload = await this.request<GoogleCalendarListResponse>(
        accessToken,
        `/users/me/calendarList${query}`,
        { method: 'GET' },
        'Failed to list Google calendars'
      );

      (payload.items || []).forEach((calendar) => {
        // Only include calendars the user can modify
        if (calendar.accessRole === 'owner' || calendar.accessRole === 'writer') {
          calendars.push({
            id: calendar.id,
            name: sanitizeTitle(calendar.summary || calendar.id, DEFAULT_CALENDAR_TITLE),
            primary: calendar.primary,
            accessRole: calendar.accessRole,
          });
        }
      });

      pageToken = payload.nextPageToken;
    } while (pageToken);

    return calendars.length ? calendars : [{ id: 'primary', name: 'Primary', primary: true }];
  }

  async listEvents(
    accessToken: string,
    calendarId: string,
    timeMin: Date,
    timeMax: Date
  ): Promise<CalendarEvent[]> {
    const events: CalendarEvent[] = [];
    let pageToken: string | undefined;

    do {
      const params = new URLSearchParams({
        singleEvents: 'true',
        showDeleted: 'false',
        timeMin: timeMin.toISOString(),
        timeMax: timeMax.toISOString(),
        orderBy: 'updated',
      });
      if (pageToken) {
        params.set('pageToken', pageToken);
      }

      const payload = await this.request<GoogleEventListResponse>(
        accessToken,
        `/calendars/${encodeURIComponent(calendarId)}/events?${params.toString()}`,
        { method: 'GET' },
        'Failed to list Google calendar events'
      );

      (payload.items || []).forEach((event) => {
        if (event.status === 'cancelled') return;
        const mapped = this.mapEvent(calendarId, event);
        if (mapped) {
          events.push(mapped);
        }
      });

      pageToken = payload.nextPageToken;
    } while (pageToken);

    return events;
  }

  async createEvent(
    accessToken: string,
    calendarId: string,
    event: CalendarEventInput
  ): Promise<string> {
    const body = this.buildEventBody(event);
    const payload = await this.request<{ id: string }>(
      accessToken,
      `/calendars/${encodeURIComponent(calendarId)}/events`,
      { method: 'POST', body: JSON.stringify(body) },
      'Failed to create Google calendar event'
    );
    return payload.id;
  }

  async updateEvent(
    accessToken: string,
    calendarId: string,
    eventId: string,
    event: CalendarEventInput
  ): Promise<void> {
    const body = this.buildEventBody(event);
    await this.request<void>(
      accessToken,
      `/calendars/${encodeURIComponent(calendarId)}/events/${encodeURIComponent(eventId)}`,
      { method: 'PATCH', body: JSON.stringify(body) },
      'Failed to update Google calendar event'
    );
  }

  async deleteEvent(accessToken: string, calendarId: string, eventId: string): Promise<void> {
    await this.request<void>(
      accessToken,
      `/calendars/${encodeURIComponent(calendarId)}/events/${encodeURIComponent(eventId)}`,
      { method: 'DELETE' },
      'Failed to delete Google calendar event'
    );
  }

  async setupWebhook(accessToken: string, calendarId: string, webhookUrl: string): Promise<string> {
    const channelId = `gcal_${generateId()}`;
    const body = {
      id: channelId,
      type: 'web_hook',
      address: webhookUrl,
      token: generateId(),
    };

    await this.request<void>(
      accessToken,
      `/calendars/${encodeURIComponent(calendarId)}/events/watch`,
      { method: 'POST', body: JSON.stringify(body) },
      'Failed to create Google calendar webhook'
    );

    return channelId;
  }

  private mapEvent(calendarId: string, event: GoogleEvent): CalendarEvent | null {
    const start = event.start?.dateTime || event.start?.date;
    const end = event.end?.dateTime || event.end?.date;

    if (!start || !end) {
      return null;
    }

    const isAllDay = Boolean(event.start?.date);
    const startTime = isAllDay ? new Date(`${event.start?.date}T00:00:00.000Z`) : new Date(start);
    const endTime = isAllDay ? new Date(`${event.end?.date}T00:00:00.000Z`) : new Date(end);

    const updatedAt = event.updated ? new Date(event.updated) : new Date();

    return {
      id: event.id,
      externalId: event.id,
      provider: 'google',
      calendarId,
      title: sanitizeTitle(event.summary, DEFAULT_CALENDAR_TITLE),
      description: sanitizeDescription(event.description),
      startTime,
      endTime,
      isAllDay,
      location: event.location,
      attendeeCount: event.attendees?.length || 0,
      organizerEmail: undefined, // avoid storing emails for HIPAA safety
      activityId:
        event.extendedProperties?.private?.activityId ||
        event.extendedProperties?.shared?.activityId,
      syncStatus: 'pending',
      lastSyncAt: updatedAt,
      createdAt: event.created ? new Date(event.created) : new Date(),
      updatedAt,
    };
  }

  private buildEventBody(event: CalendarEventInput) {
    const isAllDay = Boolean(event.isAllDay);
    const body: Record<string, unknown> = {
      summary: sanitizeTitle(event.title, DEFAULT_CALENDAR_TITLE),
      description: sanitizeDescription(event.description),
      location: event.location,
      start: isAllDay
        ? { date: isoDateOnly(event.startTime) }
        : { dateTime: event.startTime.toISOString() },
      end: isAllDay
        ? { date: isoDateOnly(event.endTime || event.startTime) }
        : { dateTime: (event.endTime || event.startTime).toISOString() },
      attendees: event.attendeeEmails
        ? event.attendeeEmails.filter(Boolean).map((email) => ({ email }))
        : undefined,
    };

    if (event.activityId) {
      body.extendedProperties = { private: { activityId: event.activityId } };
    }

    // Remove undefined fields to keep payload minimal
    Object.keys(body).forEach((key) => {
      if (body[key] === undefined) {
        delete body[key];
      }
    });

    return body;
  }
}
