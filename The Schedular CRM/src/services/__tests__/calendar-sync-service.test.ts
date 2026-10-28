import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('firebase/auth', () => ({
  getAuth: () => ({
    currentUser: {
      getIdToken: vi.fn().mockResolvedValue('id-token'),
    },
  }),
}));

vi.mock('../calendar-functions-client', () => {
  const syncCalendar = vi.fn();
  return {
    isCalendarFunctionsConfigured: () => false,
    syncCalendar,
  };
});

import { CalendarSyncService } from '../calendar-sync-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  CalendarConnection,
  CalendarSyncMapping,
  CalendarEvent,
} from '../../types/calendar-sync';
import type { SalesActivity } from '../../types/models';

vi.mock('../../config/features', async () => {
  const actual = await vi.importActual<typeof import('../../config/features')>(
    '../../config/features'
  );
  return {
    ...actual,
    getFeatureFlags: () => ({ ...actual.defaultFeatures, enableCalendarSync: true }),
  };
});

const context: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: [],
};

const baseConnection: CalendarConnection = {
  id: 'conn-1',
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  provider: 'google',
  accessToken: 'token',
  refreshToken: 'refresh',
  tokenExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
  settings: {
    syncDirection: 'bidirectional',
    defaultCalendarId: 'primary',
    syncMeetings: true,
    syncCalls: true,
    syncTasks: false,
    lookbackDays: 7,
    lookforwardDays: 30,
  },
  lastSyncStatus: 'success',
  status: 'active',
  createdAt: new Date(),
};

const baseActivity: SalesActivity = {
  id: 'act-1',
  type: 'meeting',
  title: 'CRM Meeting',
  description: 'metadata only',
  dealId: 'deal-1',
  isCompleted: false,
  createdById: 'user-1',
  createdByName: 'Test User',
  createdAt: new Date('2024-01-01T08:00:00Z'),
  updatedAt: new Date('2024-01-01T08:00:00Z'),
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: [],
  visibility: 'team',
};

const baseMapping: CalendarSyncMapping = {
  id: 'map-1',
  businessId: 'biz-1',
  userId: 'user-1',
  provider: 'google',
  externalEventId: 'ext-1',
  activityId: 'act-1',
  lastSyncedAt: new Date('2024-01-01T09:00:00Z'),
  status: 'synced',
  syncDirection: 'crm_to_calendar',
  createdAt: new Date('2024-01-01T09:00:00Z'),
};

const baseEvent: CalendarEvent = {
  id: 'evt-1',
  externalId: 'ext-1',
  provider: 'google',
  calendarId: 'primary',
  title: 'External meeting',
  startTime: new Date('2024-01-02T10:00:00Z'),
  endTime: new Date('2024-01-02T10:30:00Z'),
  isAllDay: false,
  attendeeCount: 0,
  syncStatus: 'pending',
  lastSyncAt: new Date('2024-01-01T09:00:00Z'),
  updatedAt: new Date('2024-01-02T09:00:00Z'),
  createdAt: new Date('2024-01-01T08:00:00Z'),
};

describe('CalendarSyncService', () => {
  let connectionRepo: any;
  let mappingRepo: any;
  let activityRepo: any;
  let rateLimit: any;
  let auditLog: any;
  let googleAdapter: any;
  let outlookAdapter: any;

  beforeEach(() => {
    Object.assign((import.meta as any).env, { VITE_FUNCTIONS_BASE_URL: '' });
    connectionRepo = {
      getById: vi.fn().mockResolvedValue({ success: true, data: baseConnection }),
      updateSyncStatus: vi.fn().mockResolvedValue({ success: true, data: baseConnection }),
      getByUser: vi.fn().mockResolvedValue({ success: true, data: { data: [baseConnection] } }),
    };
    mappingRepo = {
      getByExternalEvent: vi.fn(),
      getByActivity: vi.fn().mockResolvedValue({ success: true, data: null }),
      getById: vi.fn(),
      update: vi.fn().mockResolvedValue({ success: true }),
      create: vi.fn().mockResolvedValue({ success: true, data: baseMapping }),
    };
    activityRepo = {
      getById: vi.fn(),
      update: vi.fn().mockResolvedValue({ success: true }),
      getAll: vi.fn().mockResolvedValue({ success: true, data: { data: [], lastDoc: null, hasMore: false } }),
    };
    rateLimit = {
      checkLimit: vi.fn().mockResolvedValue({ allowed: true, resetAt: new Date() }),
      recordAction: vi.fn().mockResolvedValue(undefined),
    };
    auditLog = {
      logAction: vi.fn().mockResolvedValue(undefined),
    };
    googleAdapter = {
      listEvents: vi.fn(),
      createEvent: vi.fn(),
      updateEvent: vi.fn(),
      deleteEvent: vi.fn(),
      setupWebhook: vi.fn(),
    };
    outlookAdapter = {
      listEvents: vi.fn(),
      createEvent: vi.fn(),
      updateEvent: vi.fn(),
      deleteEvent: vi.fn(),
      setupSubscription: vi.fn(),
    };
  });

  it('updates mapped events and marks mapping synced', async () => {
    const mappedActivity = { ...baseActivity, updatedAt: new Date('2024-01-01T08:30:00Z') };
    mappingRepo.getByExternalEvent.mockResolvedValue({ success: true, data: baseMapping });
    activityRepo.getById.mockResolvedValue({ success: true, data: mappedActivity });
    googleAdapter.listEvents.mockResolvedValue([baseEvent]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.updated).toBe(1);
    expect(result.conflicts).toHaveLength(0);
    expect(mappingRepo.update).toHaveBeenCalledWith(
      context,
      baseMapping.id,
      expect.objectContaining({ status: 'synced' })
    );
    expect(connectionRepo.updateSyncStatus).toHaveBeenCalledWith(
      context,
      'conn-1',
      'success',
      undefined
    );
  });

  it('marks conflict when both sides changed after last sync', async () => {
    const conflictedActivity = { ...baseActivity, updatedAt: new Date('2024-01-03T10:00:00Z') };
    const conflictedEvent = {
      ...baseEvent,
      updatedAt: new Date('2024-01-03T09:00:00Z'),
    };
    mappingRepo.getByExternalEvent.mockResolvedValue({ success: true, data: baseMapping });
    activityRepo.getById.mockResolvedValue({ success: true, data: conflictedActivity });
    googleAdapter.listEvents.mockResolvedValue([conflictedEvent]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.conflicts).toHaveLength(1);
    expect(result.skipped).toBe(1);
    expect(mappingRepo.update).toHaveBeenCalledWith(
      context,
      baseMapping.id,
      expect.objectContaining({ status: 'conflict' })
    );
    expect(connectionRepo.updateSyncStatus).toHaveBeenCalledWith(
      context,
      'conn-1',
      'partial',
      'Calendar conflicts detected'
    );
  });

  it('creates a new mapping when event references an activity id', async () => {
    const eventWithActivity: CalendarEvent = { ...baseEvent, externalId: 'ext-2', activityId: 'act-1' };
    mappingRepo.getByExternalEvent.mockResolvedValue({ success: true, data: null });
    activityRepo.getById.mockResolvedValue({ success: true, data: baseActivity });
    googleAdapter.listEvents.mockResolvedValue([eventWithActivity]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.created).toBe(1);
    expect(mappingRepo.create).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        activityId: 'act-1',
        externalEventId: 'ext-2',
        syncDirection: 'calendar_to_crm',
      })
    );
  });

  it('pushes CRM activities to calendar when direction allows it', async () => {
    const activityWithDueDate = { ...baseActivity, dueDate: new Date('2024-01-02T10:00:00Z') };
    activityRepo.getAll.mockResolvedValue({
      success: true,
      data: { data: [activityWithDueDate], lastDoc: null, hasMore: false },
    });
    mappingRepo.getByActivity.mockResolvedValue({ success: true, data: null });
    googleAdapter.listEvents.mockResolvedValue([]);
    googleAdapter.createEvent.mockResolvedValue('ext-new');

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.created).toBe(1);
    expect(mappingRepo.create).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        activityId: activityWithDueDate.id,
        provider: 'google',
        syncDirection: 'crm_to_calendar',
      })
    );
    expect(googleAdapter.createEvent).toHaveBeenCalled();
  });

  it('enforces rate limit before syncing calendar when not using Functions', async () => {
    rateLimit.checkLimit.mockResolvedValueOnce({
      allowed: false,
      resetAt: new Date(Date.now() + 120000),
      message: 'Rate limit hit',
    });

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.success).toBe(false);
    expect(result.backoffMs).toBeGreaterThan(0);
    expect(googleAdapter.listEvents).not.toHaveBeenCalled();
  });

  it('marks unmapped events as dead-letter audits', async () => {
    const unmappedEvent: CalendarEvent = {
      ...baseEvent,
      externalId: 'ext-unmapped',
      activityId: undefined,
    };
    mappingRepo.getByExternalEvent.mockResolvedValue({ success: true, data: null });
    googleAdapter.listEvents.mockResolvedValue([unmappedEvent]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    await service.syncCalendar(context, 'conn-1');

    expect(auditLog.logAction).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        entityType: 'calendar_event',
        metadata: expect.objectContaining({ deadLetter: true, reason: 'unmapped_event' }),
      })
    );
  });

  it('skips CRM push when syncDirection is calendar_to_crm', async () => {
    const calendarOnlyConnection = {
      ...baseConnection,
      settings: { ...baseConnection.settings, syncDirection: 'calendar_to_crm' as const },
    };
    connectionRepo.getById.mockResolvedValue({ success: true, data: calendarOnlyConnection });
    googleAdapter.listEvents.mockResolvedValue([]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(activityRepo.getAll).not.toHaveBeenCalled();
    expect(result.created).toBe(0);
    expect(result.updated).toBe(0);
  });

  it('throws when syncing a single activity if CRM push is disabled', async () => {
    const calendarOnlyConnection = {
      ...baseConnection,
      settings: { ...baseConnection.settings, syncDirection: 'calendar_to_crm' as const },
    };
    connectionRepo.getByUser.mockResolvedValue({
      success: true,
      data: { data: [calendarOnlyConnection] },
    });
    activityRepo.getById.mockResolvedValue({ success: true, data: { ...baseActivity, dueDate: new Date() } });

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    await expect(service.syncActivityToCalendar(context, baseActivity.id)).rejects.toThrow(
      'CRM to calendar sync is disabled for this connection'
    );
  });

  it('updates mapped activity when calendar event changed after last sync', async () => {
    const mapping = { ...baseMapping, lastSyncedAt: new Date('2024-01-01T09:00:00Z') };
    const changedEvent: CalendarEvent = {
      ...baseEvent,
      startTime: new Date('2024-01-02T15:00:00Z'),
      updatedAt: new Date('2024-01-02T16:00:00Z'),
    };
    const unchangedActivity = { ...baseActivity, updatedAt: new Date('2024-01-01T08:00:00Z') };
    mappingRepo.getByExternalEvent.mockResolvedValue({ success: true, data: mapping });
    activityRepo.getById.mockResolvedValue({ success: true, data: unchangedActivity });
    googleAdapter.listEvents.mockResolvedValue([changedEvent]);

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.updated).toBe(1);
    expect(activityRepo.update).toHaveBeenCalledWith(
      context,
      mapping.activityId,
      expect.objectContaining({ dueDate: changedEvent.startTime })
    );
    expect(mappingRepo.update).toHaveBeenCalledWith(
      context,
      mapping.id,
      expect.objectContaining({ status: 'synced' })
    );
  });

  it('returns rate limit response when sync is throttled', async () => {
    const resetAt = new Date(Date.now() + 60000);
    rateLimit.checkLimit.mockResolvedValueOnce({
      allowed: false,
      resetAt,
      message: 'rate limited',
    });

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    const result = await service.syncCalendar(context, 'conn-1');

    expect(result.success).toBe(false);
    expect(result.backoffMs).toBeGreaterThan(0);
    expect(googleAdapter.listEvents).not.toHaveBeenCalled();
  });

  it('resolves conflicts by marking mapping synced in chosen direction', async () => {
    mappingRepo.getById.mockResolvedValue({ success: true, data: baseMapping });

    const service = new CalendarSyncService(
      connectionRepo,
      mappingRepo,
      activityRepo,
      rateLimit,
      auditLog,
      googleAdapter,
      outlookAdapter
    );

    await service.resolveConflict(context, baseMapping.id, 'use_calendar');

    expect(mappingRepo.update).toHaveBeenCalledWith(
      context,
      baseMapping.id,
      expect.objectContaining({
        status: 'synced',
        syncDirection: 'calendar_to_crm',
      })
    );
    expect(auditLog.logAction).toHaveBeenCalled();
  });
});
