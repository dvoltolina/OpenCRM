/**
 * Outlook Calendar Adapter
 * Safe Graph API wrapper with HIPAA-aware sanitization. Prefer Cloud Functions in production.
 */

import { generateId } from '../../data/repositories/firestore-utils';
import type { CalendarEvent, CalendarEventInput } from '../../types/calendar-sync';
import type { ProviderCalendar } from './google-calendar-adapter';
import {
  DEFAULT_CALENDAR_TITLE,
  sanitizeDescription,
  sanitizeErrorMessage,
  sanitizeTitle,
} from './provider-sanitizers';

interface GraphCalendar {
  id: string;
  name?: string;
  isDefaultCalendar?: boolean;
  canEdit?: boolean;
}

interface GraphListResponse<T> {
  value?: T[];
  '@odata.nextLink'?: string;
}

interface GraphEvent {
  id: string;
  subject?: string;
  bodyPreview?: string;
  body?: { contentType?: string; content?: string };
  start?: { dateTime?: string; timeZone?: string };
  end?: { dateTime?: string; timeZone?: string };
  isAllDay?: boolean;
  lastModifiedDateTime?: string;
  createdDateTime?: string;
  organizer?: { emailAddress?: { address?: string } };
  attendees?: Array<{ emailAddress?: { address?: string } }>;
  singleValueExtendedProperties?: Array<{ id?: string; value?: string }>;
  location?: { displayName?: string };
}

const GRAPH_API_BASE = 'https://graph.microsoft.com/v1.0';
export const OUTLOOK_ACTIVITY_ID_PROPERTY_ID =
  'String {00020329-0000-0000-C000-000000000046} Name activityId';

export class OutlookCalendarAdapter {
  private async request<T>(
    accessToken: string,
    path: string,
    init: RequestInit,
    errorContext: string
  ): Promise<T> {
    const headers = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
      Prefer: 'outlook.timezone="UTC"',
      ...(init.headers || {}),
    };

    const response = await fetch(`${GRAPH_API_BASE}${path}`, { ...init, headers });
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
    let nextLink: string | undefined = `/me/calendars?$select=id,name,isDefaultCalendar,canEdit`;
    const calendars: ProviderCalendar[] = [];

    while (nextLink) {
      const payload: GraphListResponse<GraphCalendar> = await this.request<GraphListResponse<GraphCalendar>>(
        accessToken,
        nextLink,
        { method: 'GET' },
        'Failed to list Outlook calendars'
      );

      (payload.value || []).forEach((calendar: GraphCalendar) => {
        if (calendar.canEdit || calendar.isDefaultCalendar) {
          calendars.push({
            id: calendar.id,
            name: sanitizeTitle(calendar.name || calendar.id, DEFAULT_CALENDAR_TITLE),
            primary: calendar.isDefaultCalendar,
            accessRole: calendar.canEdit ? 'owner' : 'reader',
          });
        }
      });

      nextLink = payload['@odata.nextLink']?.replace(GRAPH_API_BASE, '');
    }

    return calendars.length ? calendars : [{ id: 'primary', name: 'Default Calendar', primary: true }];
  }

  async listEvents(
    accessToken: string,
    calendarId: string,
    startDateTime: Date,
    endDateTime: Date
  ): Promise<CalendarEvent[]> {
    const events: CalendarEvent[] = [];
    const baseParams = new URLSearchParams({
      startDateTime: startDateTime.toISOString(),
      endDateTime: endDateTime.toISOString(),
      $select:
        'id,subject,bodyPreview,start,end,isAllDay,lastModifiedDateTime,createdDateTime,organizer,attendees,location',
      $expand: `singleValueExtendedProperties($filter=id eq '${OUTLOOK_ACTIVITY_ID_PROPERTY_ID}')`,
      $orderby: 'lastModifiedDateTime desc',
    });

    let nextLink: string | undefined = `/me/calendars/${encodeURIComponent(calendarId)}/calendarView?${baseParams.toString()}`;

    while (nextLink) {
      const payload: GraphListResponse<GraphEvent> = await this.request<GraphListResponse<GraphEvent>>(
        accessToken,
        nextLink,
        { method: 'GET' },
        'Failed to list Outlook calendar events'
      );

      (payload.value || []).forEach((event: GraphEvent) => {
        const mapped = this.mapEvent(calendarId, event);
        if (mapped) {
          events.push(mapped);
        }
      });

      nextLink = payload['@odata.nextLink']?.replace(GRAPH_API_BASE, '');
    }

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
      `/me/calendars/${encodeURIComponent(calendarId)}/events`,
      { method: 'POST', body: JSON.stringify(body) },
      'Failed to create Outlook calendar event'
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
      `/me/calendars/${encodeURIComponent(calendarId)}/events/${encodeURIComponent(eventId)}`,
      { method: 'PATCH', body: JSON.stringify(body) },
      'Failed to update Outlook calendar event'
    );
  }

  async deleteEvent(accessToken: string, calendarId: string, eventId: string): Promise<void> {
    await this.request<void>(
      accessToken,
      `/me/calendars/${encodeURIComponent(calendarId)}/events/${encodeURIComponent(eventId)}`,
      { method: 'DELETE' },
      'Failed to delete Outlook calendar event'
    );
  }

  async setupSubscription(accessToken: string, webhookUrl: string): Promise<string> {
    const clientState = generateId();
    const expirationDateTime = new Date(Date.now() + 55 * 60 * 1000); // ~55 minutes (Graph limit)
    const body = {
      changeType: 'created,updated,deleted',
      notificationUrl: webhookUrl,
      resource: '/me/events',
      clientState,
      expirationDateTime: expirationDateTime.toISOString(),
    };

    const payload = await this.request<{ id: string }>(
      accessToken,
      '/subscriptions',
      { method: 'POST', body: JSON.stringify(body) },
      'Failed to create Outlook calendar subscription'
    );

    return payload.id || clientState;
  }

  private mapEvent(calendarId: string, event: GraphEvent): CalendarEvent | null {
    const start = event.start?.dateTime;
    const end = event.end?.dateTime;
    if (!start || !end) {
      return null;
    }

    const updatedAt = event.lastModifiedDateTime
      ? new Date(event.lastModifiedDateTime)
      : new Date();

    return {
      id: event.id,
      externalId: event.id,
      provider: 'outlook',
      calendarId,
      title: sanitizeTitle(event.subject, DEFAULT_CALENDAR_TITLE),
      description: sanitizeDescription(event.bodyPreview || event.body?.content),
      startTime: new Date(start),
      endTime: new Date(end),
      isAllDay: Boolean(event.isAllDay),
      location: event.location?.displayName,
      attendeeCount: event.attendees?.length || 0,
      organizerEmail: undefined,
      activityId: this.extractActivityId(event.singleValueExtendedProperties),
      syncStatus: 'pending',
      lastSyncAt: updatedAt,
      createdAt: event.createdDateTime ? new Date(event.createdDateTime) : updatedAt,
      updatedAt,
    };
  }

  private buildEventBody(event: CalendarEventInput) {
    const isAllDay = Boolean(event.isAllDay);
    const body: Record<string, unknown> = {
      subject: sanitizeTitle(event.title, DEFAULT_CALENDAR_TITLE),
      body: event.description
        ? {
            contentType: 'Text',
            content: sanitizeDescription(event.description) || '',
          }
        : undefined,
      start: {
        dateTime: event.startTime.toISOString(),
        timeZone: 'UTC',
      },
      end: {
        dateTime: event.endTime.toISOString(),
        timeZone: 'UTC',
      },
      isAllDay,
      location: event.location ? { displayName: event.location } : undefined,
      attendees: event.attendeeEmails
        ? event.attendeeEmails.filter(Boolean).map((email) => ({ emailAddress: { address: email } }))
        : undefined,
      singleValueExtendedProperties: event.activityId
        ? [{ id: OUTLOOK_ACTIVITY_ID_PROPERTY_ID, value: event.activityId }]
        : undefined,
    };

    Object.keys(body).forEach((key) => {
      if (body[key] === undefined) {
        delete body[key];
      }
    });

    return body;
  }

  private extractActivityId(properties?: Array<{ id?: string; value?: string }>): string | undefined {
    if (!properties || !properties.length) return undefined;
    const match = properties.find((prop) => prop.id === OUTLOOK_ACTIVITY_ID_PROPERTY_ID);
    return match?.value;
  }
}
