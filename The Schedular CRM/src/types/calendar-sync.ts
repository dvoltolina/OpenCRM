/**
 * Calendar Sync Types
 * Shared types for Google/Outlook calendar connections and event mapping.
 *
 * HIPAA: Do not store external attendee emails or free-text notes containing PHI.
 * Only persist metadata needed for sync/audit.
 */

export type CalendarProvider = 'google' | 'outlook';
export type SyncDirection = 'crm_to_calendar' | 'calendar_to_crm' | 'bidirectional';
export type SyncStatus = 'pending' | 'synced' | 'failed' | 'conflict';

export interface CalendarConnection {
  id: string;
  businessId: string;
  userId: string;
  userName: string;
  provider: CalendarProvider;

  // OAuth tokens (encrypted at rest)
  accessToken: string; // Encrypted
  refreshToken: string; // Encrypted
  tokenExpiresAt: Date;

  // Sync settings
  settings: {
    syncDirection: SyncDirection;
    defaultCalendarId: string; // Which calendar to sync to
    syncMeetings: boolean;
    syncCalls: boolean;
    syncTasks: boolean; // As calendar events with reminders
    lookbackDays: number; // How far back to sync (default: 7)
    lookforwardDays: number; // How far forward (default: 30)
  };

  // Sync state
  lastSyncAt?: Date;
  lastSyncStatus: 'success' | 'partial' | 'failed';
  lastSyncError?: string;

  // Connection status
  status: 'active' | 'disconnected' | 'error';

  createdAt: Date;
  updatedAt?: Date;
}

export interface CalendarEvent {
  id: string;
  externalId: string; // Google/Outlook event ID
  provider: CalendarProvider;
  calendarId: string;

  // Event details
  title: string;
  description?: string;
  startTime: Date;
  endTime: Date;
  isAllDay: boolean;
  location?: string;

  // Attendees (no PHI stored - just count or internal user refs)
  attendeeCount: number;
  organizerEmail?: string; // Only if internal user

  // Link to CRM
  activityId?: string; // Linked CRM activity
  syncStatus: SyncStatus;
  lastSyncAt: Date;

  // Metadata
  createdAt: Date;
  updatedAt?: Date;
}

// For tracking sync mapping
export interface CalendarSyncMapping {
  id: string;
  businessId: string;
  userId: string;
  provider: CalendarProvider;
  externalEventId: string;
  activityId: string;
  lastSyncedAt: Date;
  status?: SyncStatus;
  syncDirection: 'crm_to_calendar' | 'calendar_to_crm';
  createdAt: Date;
  updatedAt?: Date;
}

/**
 * Input shape for provider adapters when creating/updating events.
 * Mirrors CalendarEvent but keeps only provider-required fields.
 */
export interface CalendarEventInput {
  title: string;
  description?: string;
  startTime: Date;
  endTime: Date;
  isAllDay?: boolean;
  location?: string;
  attendeeEmails?: string[]; // Internal attendees only; avoid external PHI
  /** Optional CRM activity id to help providers store extended properties for round-tripping */
  activityId?: string;
}
