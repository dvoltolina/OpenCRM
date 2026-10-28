import { Timestamp } from 'firebase/firestore';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { CalendarConnection, CalendarProvider } from '../types/calendar-sync';
import type { SalesActivity } from '../types/models';
import type { CalendarSyncMappingRepository } from '../data/repositories/calendar-sync-mapping-repository';
import type { ActivityRepository } from '../data/repositories/activity-repository';
import type { RateLimitService } from './RateLimitService';
import type { AuditLogService } from './AuditLogService';
import { GoogleCalendarAdapter } from './calendar-providers/google-calendar-adapter';
import { OutlookCalendarAdapter } from './calendar-providers/outlook-calendar-adapter';

export interface SyncWindow {
  start: Date;
  end: Date;
}

export class CalendarSyncWorker {
  private mappings: CalendarSyncMappingRepository;
  private activities: ActivityRepository;
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private googleAdapter: GoogleCalendarAdapter;
  private outlookAdapter: OutlookCalendarAdapter;

  constructor(
    mappings: CalendarSyncMappingRepository,
    activities: ActivityRepository,
    rateLimit: RateLimitService,
    audit: AuditLogService,
    googleAdapter: GoogleCalendarAdapter,
    outlookAdapter: OutlookCalendarAdapter
  ) {
    this.mappings = mappings;
    this.activities = activities;
    this.rateLimit = rateLimit;
    this.audit = audit;
    this.googleAdapter = googleAdapter;
    this.outlookAdapter = outlookAdapter;
  }

  allowsCalendarToCrm(connection: CalendarConnection): boolean {
    return connection.settings.syncDirection !== 'crm_to_calendar';
  }

  allowsCrmToCalendar(connection: CalendarConnection): boolean {
    return connection.settings.syncDirection !== 'calendar_to_crm';
  }

  getAdapter(provider: CalendarProvider) {
    return provider === 'outlook' ? this.outlookAdapter : this.googleAdapter;
  }

  async getActivitiesForConnection(
    context: SecurityContext,
    connection: CalendarConnection,
    window: SyncWindow
  ): Promise<SalesActivity[]> {
    const allowedTypes = this.getAllowedActivityTypes(connection);
    if (!allowedTypes.length) {
      return [];
    }

    const activities = await this.activities.getAll(context, {
      where: [
        { field: 'assigneeId', operator: '==', value: connection.userId },
        { field: 'type', operator: 'in', value: allowedTypes },
        { field: 'dueDate', operator: '>=', value: Timestamp.fromDate(window.start) },
        { field: 'dueDate', operator: '<=', value: Timestamp.fromDate(window.end) },
      ],
    });

    if (!activities.success) {
      return [];
    }

    return activities.data.data.filter((activity) =>
      this.isActivitySyncable(activity, connection)
    );
  }

  async syncActivitiesToCalendar(
    context: SecurityContext,
    connection: CalendarConnection,
    window: SyncWindow
  ): Promise<{ created: number; updated: number; skipped: number; errors: string[] }> {
    const activities = await this.getActivitiesForConnection(context, connection, window);
    if (!activities.length) {
      return { created: 0, updated: 0, skipped: 0, errors: [] };
    }

    const results = { created: 0, updated: 0, skipped: 0, errors: [] as string[] };
    for (const activity of activities) {
      try {
        const outcome = await this.syncActivityWithConnection(context, connection, activity);
        if (outcome === 'created') {
          results.created += 1;
        } else if (outcome === 'updated') {
          results.updated += 1;
        } else {
          results.skipped += 1;
        }
      } catch (error) {
        results.errors.push(error instanceof Error ? error.message : 'Failed to sync activity');
        results.skipped += 1;
      }
    }

    return results;
  }

  async syncActivityWithConnection(
    context: SecurityContext,
    connection: CalendarConnection,
    activity: SalesActivity
  ): Promise<'created' | 'updated' | 'skipped'> {
    if (!this.isActivitySyncable(activity, connection)) {
      return 'skipped';
    }

    const rate = await this.rateLimit.checkLimit(
      'integration_sync',
      context.userId,
      context.businessId
    );
    if (!rate.allowed) {
      throw new Error(rate.message || 'Calendar sync rate limit exceeded');
    }

    const adapter = this.getAdapter(connection.provider);
    const mapping = await this.mappings.getByActivity(context, activity.id);

    if (!mapping.success) {
      throw new Error(mapping.error?.message || 'Unable to load calendar mapping');
    }

    const payload = this.activityToEvent(activity);

    if (mapping.data) {
      await adapter.updateEvent(
        connection.accessToken,
        connection.settings.defaultCalendarId,
        mapping.data.externalEventId,
        payload
      );
      await this.mappings.update(context, mapping.data.id, {
        status: 'synced',
        lastSyncedAt: new Date(),
        updatedAt: new Date(),
      });
      await this.audit.logAction(context, {
        action: 'integration',
        entityType: 'integration',
        entityId: mapping.data.id,
        entityName: mapping.data.provider,
        metadata: { direction: 'crm_to_calendar', operation: 'update' },
      });
      return 'updated';
    }

    const externalId = await adapter.createEvent(
      connection.accessToken,
      connection.settings.defaultCalendarId,
      payload
    );
    const createResult = await this.mappings.create(context, {
      activityId: activity.id,
      provider: connection.provider,
      externalEventId: externalId,
      lastSyncedAt: new Date(),
      syncDirection: 'crm_to_calendar',
      status: 'synced',
      businessId: context.businessId,
      userId: connection.userId,
    });

    if (!createResult.success) {
      throw new Error(createResult.error?.message || 'Failed to store calendar mapping');
    }

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: createResult.data.id,
      entityName: connection.provider,
      metadata: { direction: 'crm_to_calendar', operation: 'create' },
    });
    return 'created';
  }

  private getAllowedActivityTypes(connection: CalendarConnection): Array<SalesActivity['type']> {
    const types: Array<SalesActivity['type']> = [];
    if (connection.settings.syncMeetings) types.push('meeting');
    if (connection.settings.syncCalls) types.push('call');
    if (connection.settings.syncTasks) types.push('task');
    return types;
  }

  private isActivitySyncable(activity: SalesActivity, connection: CalendarConnection): boolean {
    if (!this.allowsCrmToCalendar(connection)) {
      return false;
    }
    const allowedTypes = this.getAllowedActivityTypes(connection);
    if (!allowedTypes.includes(activity.type)) {
      return false;
    }
    if (!activity.dueDate) {
      return false;
    }
    if (activity.type === 'task' && activity.isCompleted) {
      return false;
    }
    return true;
  }

  private activityToEvent(activity: SalesActivity) {
    const start = activity.dueDate || new Date();
    const end = new Date(start.getTime() + 30 * 60 * 1000);
    return {
      title: this.sanitizeTitle(activity),
      description: `CRM activity ${activity.id} (metadata only)`,
      startTime: start,
      endTime: end,
      isAllDay: false,
      location: undefined,
      activityId: activity.id,
    };
  }

  private sanitizeTitle(activity: SalesActivity): string {
    const typeLabel = activity.type === 'call' ? 'Call' : activity.type === 'task' ? 'Task' : 'Meeting';
    if (!activity.title) {
      return `CRM ${typeLabel}`;
    }
    const trimmed = activity.title.replace(/<[^>]+>/g, '').trim();
    return trimmed.length > 0 ? trimmed : `CRM ${typeLabel}`;
  }
}
