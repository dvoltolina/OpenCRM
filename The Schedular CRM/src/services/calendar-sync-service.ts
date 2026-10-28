/**
 * Calendar Sync Service
 * Bidirectional sync scaffolding between CRM activities and Google/Outlook calendars.
 *
 * HIPAA: Event payloads must avoid PHI. Titles/descriptions are sanitized to generic values.
 * Provider API calls are expected to run through Cloud Functions; this client persists metadata only.
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getCalendarConnectionRepository,
  type CalendarConnectionRepository,
} from '../data/repositories/calendar-connection-repository';
import {
  getCalendarSyncMappingRepository,
  type CalendarSyncMappingRepository,
} from '../data/repositories/calendar-sync-mapping-repository';
import { getActivityRepository, type ActivityRepository } from '../data/repositories/activity-repository';
import type {
  CalendarConnection,
  CalendarEvent,
  CalendarProvider,
  CalendarSyncMapping,
  SyncStatus,
} from '../types/calendar-sync';
import type { SyncConflict, SyncResult } from '../types/integrations';
import { getFeatureFlags } from '../config/features';
import { GoogleCalendarAdapter } from './calendar-providers/google-calendar-adapter';
import { OutlookCalendarAdapter } from './calendar-providers/outlook-calendar-adapter';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService } from './AuditLogService';
import type { SalesActivity } from '../types/models';
import {
  isCalendarFunctionsConfigured,
  syncCalendar as syncCalendarViaFunctions,
} from './calendar-functions-client';
import { CalendarSyncWorker } from './calendar-sync-worker';

interface TimeWindow {
  start: Date;
  end: Date;
}

interface EventSyncResult {
  status: SyncStatus;
  conflict?: SyncConflict;
  createdMapping?: boolean;
}

export class CalendarSyncService {
  private connections: CalendarConnectionRepository;
  private mappings: CalendarSyncMappingRepository;
  private activities: ActivityRepository;
  private googleAdapter: GoogleCalendarAdapter;
  private outlookAdapter: OutlookCalendarAdapter;
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private worker: CalendarSyncWorker;

  constructor(
    connectionRepo?: CalendarConnectionRepository,
    mappingRepo?: CalendarSyncMappingRepository,
    activityRepo?: ActivityRepository,
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService,
    googleAdapter?: GoogleCalendarAdapter,
    outlookAdapter?: OutlookCalendarAdapter
  ) {
    this.connections = connectionRepo || getCalendarConnectionRepository();
    this.mappings = mappingRepo || getCalendarSyncMappingRepository();
    this.activities = activityRepo || getActivityRepository();
    this.googleAdapter = googleAdapter || new GoogleCalendarAdapter();
    this.outlookAdapter = outlookAdapter || new OutlookCalendarAdapter();
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
    this.worker = new CalendarSyncWorker(
      this.mappings,
      this.activities,
      this.rateLimit,
      this.audit,
      this.googleAdapter,
      this.outlookAdapter
    );
  }

  /**
   * Full sync for a single calendar connection.
   * Returns counts only; provider deltas are handled server-side.
  */
  async syncCalendar(context: SecurityContext, connectionId: string): Promise<SyncResult> {
    this.assertEnabled();
    const connection = await this.requireConnection(context, connectionId);
    const allowCalendarToCrm = this.worker.allowsCalendarToCrm(connection);
    const allowCrmToCalendar = this.worker.allowsCrmToCalendar(connection);

    if (!allowCalendarToCrm && !allowCrmToCalendar) {
      return {
        success: true,
        created: 0,
        updated: 0,
        skipped: 0,
        conflicts: [],
        retried: 0,
      };
    }

    if (isCalendarFunctionsConfigured()) {
      const result = await syncCalendarViaFunctions({
        connectionId,
        businessId: context.businessId,
        provider: connection.provider,
      });
      // Update local status for UI responsiveness; Functions should also update server-side
      const syncStatus: CalendarConnection['lastSyncStatus'] =
        result.conflicts.length > 0 || (result.errors && result.errors.length > 0) ? 'partial' : 'success';
      await this.connections.updateSyncStatus(
        context,
        connectionId,
        syncStatus,
        result.errors?.[0]
      );
      return result;
    }

    const limit = await this.rateLimit.checkLimit(
      'integration_sync',
      context.userId,
      context.businessId
    );
    if (!limit.allowed) {
      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        conflicts: [],
        retried: 0,
        backoffMs: limit.resetAt.getTime() - Date.now(),
        errors: [limit.message || 'Calendar sync rate limit exceeded'],
      };
    }

    const adapter = this.worker.getAdapter(connection.provider);
    const window = this.buildTimeWindow(connection);
    const events = allowCalendarToCrm
      ? await adapter.listEvents(
          connection.accessToken,
          connection.settings.defaultCalendarId,
          window.start,
          window.end
        )
      : [];

    let created = 0;
    let updated = 0;
    let skipped = 0;
    const conflicts: SyncConflict[] = [];
    const errors: string[] = [];

    if (allowCalendarToCrm) {
      for (const event of events) {
        try {
          const result = await this.syncEventToCRM(context, event);
          if (result.status === 'synced') {
            updated += 1;
            if (result.createdMapping) {
              created += 1;
            }
          } else if (result.status === 'conflict' && result.conflict) {
            conflicts.push(result.conflict);
            skipped += 1;
          } else {
            skipped += 1;
          }
        } catch (error) {
          errors.push(error instanceof Error ? error.message : 'Calendar sync failed for event');
          skipped += 1;
        }
      }
    }

    if (allowCrmToCalendar) {
      const crmSync = await this.worker.syncActivitiesToCalendar(context, connection, window);
      created += crmSync.created;
      updated += crmSync.updated;
      skipped += crmSync.skipped;
      if (crmSync.errors.length) {
        errors.push(...crmSync.errors);
      }
    }

    const syncStatus: CalendarConnection['lastSyncStatus'] =
      conflicts.length > 0 || errors.length > 0 ? 'partial' : 'success';
    const syncError = errors[0] || (conflicts.length ? 'Calendar conflicts detected' : undefined);
    await this.connections.updateSyncStatus(
      context,
      connectionId,
      syncStatus,
      syncError
    );
    await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);
    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'calendar_connection',
      entityId: connectionId,
      entityName: connection.provider,
      metadata: {
        created,
        updated,
        skipped,
        window,
        conflicts: conflicts.length,
        direction: connection.settings.syncDirection,
      },
    });

    return {
      success: errors.length === 0,
      created,
      updated,
      skipped,
      conflicts,
      retried: 0,
      errors:
        errors.length > 0
          ? errors
          : conflicts.length
            ? ['Calendar conflicts detected']
            : undefined,
    };
  }

  /**
   * Sync a single CRM activity to the connected calendar.
   */
  async syncActivityToCalendar(context: SecurityContext, activityId: string): Promise<void> {
    this.assertEnabled();
    const connection = await this.findActiveConnection(context);
    if (!connection) {
      throw new Error('No active calendar connection found for this user');
    }
    if (!this.worker.allowsCrmToCalendar(connection)) {
      throw new Error('CRM to calendar sync is disabled for this connection');
    }

    const activityResult = await this.activities.getById(context, activityId);
    if (!activityResult.success || !activityResult.data) {
      throw new Error(activityResult.error?.message || 'Activity not found');
    }

    const limit = await this.rateLimit.checkLimit(
      'integration_sync',
      context.userId,
      context.businessId
    );
    if (!limit.allowed) {
      throw new Error(limit.message || 'Calendar sync rate limit exceeded');
    }

    await this.worker.syncActivityWithConnection(context, connection, activityResult.data);
  }

  /**
   * Sync a provider event into CRM if mapped; skips creation when entity context is missing.
   */
  async syncEventToCRM(context: SecurityContext, event: CalendarEvent): Promise<EventSyncResult> {
    this.assertEnabled();
    const mapping = await this.mappings.getByExternalEvent(
      context,
      event.provider,
      event.externalId
    );

    if (mapping.success && mapping.data) {
      const activityResult = await this.activities.getById(context, mapping.data.activityId);
      if (!activityResult.success || !activityResult.data) {
        await this.mappings.update(context, mapping.data.id, {
          status: 'failed',
          updatedAt: new Date(),
        });
        return { status: 'failed' };
      }

      const conflict = this.detectConflict(mapping.data, activityResult.data, event);
      if (conflict) {
        await this.mappings.update(context, mapping.data.id, {
          status: 'conflict',
          updatedAt: new Date(),
        });
        await this.audit.logAction(context, {
          action: 'integration',
          entityType: 'calendar_mapping',
          entityId: mapping.data.id,
          entityName: mapping.data.provider,
          metadata: { conflict: true, eventId: event.externalId },
        });
        return { status: 'conflict', conflict };
      }

      const updates: Partial<SalesActivity> = {
        dueDate: event.startTime,
        updatedAt: new Date(),
      };
      const sanitizedTitle = this.sanitizeEventTitle(event.title, activityResult.data.title);
      if (sanitizedTitle && sanitizedTitle !== activityResult.data.title) {
        updates.title = sanitizedTitle;
      }

      await this.activities.update(context, mapping.data.activityId, updates);
      await this.mappings.update(context, mapping.data.id, {
        lastSyncedAt: new Date(),
        status: 'synced',
        updatedAt: new Date(),
      });
      return { status: 'synced' };
    }

    if (event.activityId) {
      const activityResult = await this.activities.getById(context, event.activityId);
      if (activityResult.success && activityResult.data) {
        const updates: Partial<SalesActivity> = {
          dueDate: event.startTime,
          updatedAt: new Date(),
        };
        const sanitizedTitle = this.sanitizeEventTitle(event.title, activityResult.data.title);
        if (sanitizedTitle && sanitizedTitle !== activityResult.data.title) {
          updates.title = sanitizedTitle;
        }

        await this.activities.update(context, event.activityId, updates);
        await this.mappings.create(context, {
          activityId: event.activityId,
          provider: event.provider,
          externalEventId: event.externalId,
          lastSyncedAt: event.updatedAt || event.lastSyncAt || new Date(),
          syncDirection: 'calendar_to_crm',
          status: 'synced',
          businessId: context.businessId,
          userId: context.userId,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
        return { status: 'synced', createdMapping: true };
      }
    }

    // No mapping and no entity context: skip to avoid creating orphaned activities
    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'calendar_event',
      entityId: event.id,
      entityName: event.provider,
      metadata: {
        skipped: true,
        reason: 'unmapped_event',
        deadLetter: true,
        payloadKeys: Object.keys(event || {}).slice(0, 10),
      },
    });
    return { status: 'pending' };
  }

  /**
   * Handle webhook payloads; delegates to sync for known connections.
   */
  async handleWebhook(_provider: CalendarProvider, _payload: unknown): Promise<void> {
    throw new Error('Calendar webhooks must be handled server-side via Functions');
  }

  /**
   * Resolve a conflict by marking mapping as synced according to chosen side.
   */
  async resolveConflict(
    context: SecurityContext,
    mappingId: string,
    resolution: 'use_crm' | 'use_calendar'
  ): Promise<void> {
    this.assertEnabled();
    const mapping = await this.mappings.getById(context, mappingId);
    if (!mapping.success || !mapping.data) {
      throw new Error(mapping.error?.message || 'Mapping not found');
    }

    await this.mappings.update(context, mappingId, {
      status: 'synced',
      lastSyncedAt: new Date(),
      updatedAt: new Date(),
      syncDirection: resolution === 'use_crm' ? 'crm_to_calendar' : 'calendar_to_crm',
    });

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'calendar_mapping',
      entityId: mappingId,
      entityName: mapping.data.provider,
      metadata: { resolution },
    });
  }

  private detectConflict(
    mapping: CalendarSyncMapping,
    activity: SalesActivity,
    event: CalendarEvent
  ): SyncConflict | null {
    const lastSyncedAt = mapping.lastSyncedAt ? new Date(mapping.lastSyncedAt) : null;
    const activityUpdatedAt = activity.updatedAt ? new Date(activity.updatedAt) : null;
    const eventUpdatedAt = event.updatedAt || event.lastSyncAt;

    if (!lastSyncedAt || !activityUpdatedAt || !eventUpdatedAt) {
      return null;
    }

    if (activityUpdatedAt > lastSyncedAt && eventUpdatedAt > lastSyncedAt) {
      return {
        itemId: event.externalId,
        localUpdatedAt: activityUpdatedAt,
        remoteUpdatedAt: eventUpdatedAt,
        resolution: 'manual',
        reason: 'crm_and_calendar_changed_after_last_sync',
      };
    }

    return null;
  }

  private assertEnabled() {
    if (!getFeatureFlags().enableCalendarSync) {
      throw new Error('Calendar sync is disabled');
    }
  }

  private buildTimeWindow(connection: CalendarConnection): TimeWindow {
    const now = new Date();
    const start = new Date(now);
    start.setDate(start.getDate() - (connection.settings.lookbackDays || 7));
    const end = new Date(now);
    end.setDate(end.getDate() + (connection.settings.lookforwardDays || 30));
    return { start, end };
  }

  private async requireConnection(
    context: SecurityContext,
    connectionId: string
  ): Promise<CalendarConnection> {
    const result = await this.connections.getById(context, connectionId);
    if (!result.success || !result.data) {
      throw new Error(result.error?.message || 'Calendar connection not found');
    }
    if (result.data.status === 'disconnected') {
      throw new Error('Calendar connection is disconnected');
    }
    return result.data;
  }

  private async findActiveConnection(
    context: SecurityContext
  ): Promise<CalendarConnection | null> {
    const result = await this.connections.getByUser(context, context.userId);
    if (!result.success) {
      return null;
    }

    return result.data.data.find((conn) => conn.status === 'active') || null;
  }

  private sanitizeEventTitle(title?: string, fallback?: string): string {
    if (fallback) {
      return fallback;
    }
    const cleaned = title?.replace(/<[^>]+>/g, '').trim() || '';
    return cleaned.length > 0 ? cleaned.slice(0, 80) : 'Calendar Event';
  }
}

let calendarSyncService: CalendarSyncService | null = null;

export function getCalendarSyncService(): CalendarSyncService {
  if (!calendarSyncService) {
    calendarSyncService = new CalendarSyncService();
  }
  return calendarSyncService;
}
