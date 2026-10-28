import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import type { SecurityContext, QueryOptions } from '../repository-types';
import { CalendarConnectionRepository } from '../calendar-connection-repository';
import { CalendarSyncMappingRepository } from '../calendar-sync-mapping-repository';
import { BaseRepository } from '../base-repository';
import type { CalendarConnection, CalendarSyncMapping } from '../../../types/calendar-sync';
import { successResult } from '../../errors/repository-errors';

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(() => ({ docs: [], empty: true })),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  onSnapshot: vi.fn(),
  writeBatch: vi.fn(),
  Timestamp: {
    now: vi.fn(() => ({ toDate: () => new Date() })),
    fromDate: vi.fn((value: Date) => ({ toDate: () => value })),
  },
}));

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('../../../lib/collections', () => ({
  businessPath: vi.fn((businessId: string) => `businesses/${businessId}`),
}));

vi.mock('../firestore-utils', () => ({
  buildQuery: vi.fn(),
  documentsToEntities: vi.fn(() => []),
  documentToEntity: vi.fn(),
  generateId: vi.fn(() => 'generated-id'),
  isValidDocumentId: vi.fn(() => true),
  prepareForCreate: vi.fn((data) => data),
  prepareForUpdate: vi.fn((data) => data),
  MAX_BATCH_SIZE: 500,
}));

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'admin',
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
};

describe('CalendarConnectionRepository', () => {
  let repo: CalendarConnectionRepository;

  beforeEach(() => {
    repo = new CalendarConnectionRepository();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('blocks non-privileged access when listing active connections', async () => {
    const result = await repo.getActiveConnections(staffContext);

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('allows privileged users to list active connections', async () => {
    const superGetAll = vi
      .spyOn(
        BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll },
        'getAll'
      )
      .mockResolvedValue(successResult({ data: [], lastDoc: null, hasMore: false }));

    const result = await repo.getActiveConnections(adminContext);

    expect(result.success).toBe(true);
    expect(superGetAll).toHaveBeenCalledTimes(1);
    expect(superGetAll).toHaveBeenCalledWith(adminContext, {
      where: [{ field: 'status', operator: '==', value: 'active' }],
    });
  });

  it('prevents non-owner from querying another user connections', async () => {
    const result = await repo.getByUser(staffContext, 'other-user');

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('scopes privileged getByUser to the requested user without double filters', async () => {
    const superGetAll = vi
      .spyOn(
        BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll },
        'getAll'
      )
      .mockResolvedValue(successResult({ data: [], lastDoc: null, hasMore: false }));

    await repo.getByUser(adminContext, 'other-user');

    const optionsArg = superGetAll.mock.calls[0]?.[1] as QueryOptions;
    expect(optionsArg?.where).toEqual([{ field: 'userId', operator: '==', value: 'other-user' }]);
  });

  it('updates sync status and stamps lastSyncAt', async () => {
    const connection: CalendarConnection = {
      id: 'conn-1',
      businessId: adminContext.businessId,
      userId: adminContext.userId,
      userName: 'Admin User',
      provider: 'google',
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenExpiresAt: new Date(),
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

    vi.spyOn(repo, 'getById').mockResolvedValue(successResult(connection));
    const superUpdate = vi
      .spyOn(
        BaseRepository.prototype as unknown as { update: typeof BaseRepository.prototype.update },
        'update'
      )
      .mockResolvedValue(successResult(connection));

    const result = await repo.updateSyncStatus(adminContext, 'conn-1', 'failed', 'timeout');

    expect(result.success).toBe(true);
    expect(superUpdate).toHaveBeenCalledTimes(1);
    const [, , updatePayload] = superUpdate.mock.calls[0];
    expect(updatePayload).toMatchObject({ lastSyncStatus: 'failed', lastSyncError: 'timeout' });
    expect(updatePayload.lastSyncAt).toBeInstanceOf(Date);
  });

  it('prevents creating connections for other users without privilege', async () => {
    const superCreate = vi
      .spyOn(
        BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create },
        'create'
      )
      .mockResolvedValue(successResult({} as CalendarConnection));

    const result = await repo.create(staffContext, {
      businessId: staffContext.businessId,
      userId: 'other-user',
      userName: 'Other User',
      provider: 'google',
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenExpiresAt: new Date(),
      settings: {
        syncDirection: 'bidirectional',
        defaultCalendarId: 'primary',
        syncMeetings: true,
        syncCalls: true,
        syncTasks: true,
        lookbackDays: 7,
        lookforwardDays: 30,
      },
      lastSyncStatus: 'success',
      status: 'active',
    });

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
    expect(superCreate).not.toHaveBeenCalled();
  });
});

describe('CalendarSyncMappingRepository', () => {
  let repo: CalendarSyncMappingRepository;

  beforeEach(() => {
    repo = new CalendarSyncMappingRepository();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('blocks viewing conflicts for another user when not privileged', async () => {
    const result = await repo.getConflicts(staffContext, 'other-user');

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('scopes conflict lookup to requested user for privileged roles', async () => {
    const superGetAll = vi
      .spyOn(
        BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll },
        'getAll'
      )
      .mockResolvedValue(successResult({ data: [], lastDoc: null, hasMore: false }));

    await repo.getConflicts(adminContext, 'user-2');

    expect(superGetAll).toHaveBeenCalledTimes(1);
    const optionsArg = superGetAll.mock.calls[0]?.[1] as QueryOptions;
    expect(optionsArg?.where).toEqual([
      { field: 'userId', operator: '==', value: 'user-2' },
      { field: 'status', operator: '==', value: 'conflict' },
    ]);
  });

  it('prevents non-owners from reading mappings tied to other users', async () => {
    const mapping: CalendarSyncMapping = {
      id: 'map-1',
      businessId: staffContext.businessId,
      userId: 'other-user',
      provider: 'google',
      externalEventId: 'ext-1',
      activityId: 'act-1',
      lastSyncedAt: new Date(),
      status: 'conflict',
      syncDirection: 'crm_to_calendar',
      createdAt: new Date(),
    };

    vi.spyOn(
      BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll },
      'getAll'
    ).mockResolvedValue(successResult({ data: [mapping], lastDoc: null, hasMore: false }));

    const result = await repo.getByActivity(staffContext, 'act-1');

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('returns mappings for owner with correct filter applied', async () => {
    const mapping: CalendarSyncMapping = {
      id: 'map-1',
      businessId: adminContext.businessId,
      userId: adminContext.userId,
      provider: 'google',
      externalEventId: 'ext-1',
      activityId: 'act-1',
      lastSyncedAt: new Date(),
      status: 'synced',
      syncDirection: 'crm_to_calendar',
      createdAt: new Date(),
    };

    const superGetAll = vi
      .spyOn(
        BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll },
        'getAll'
      )
      .mockResolvedValue(successResult({ data: [mapping], lastDoc: null, hasMore: false }));

    const result = await repo.getByActivity(adminContext, 'act-1');

    expect(result.success).toBe(true);
    expect(result.data?.id).toBe('map-1');
    const optionsArg = superGetAll.mock.calls[0]?.[1] as QueryOptions;
    expect(optionsArg?.where).toContainEqual({
      field: 'activityId',
      operator: '==',
      value: 'act-1',
    });
  });

  it('prevents creating mappings for another user without privilege', async () => {
    const superCreate = vi
      .spyOn(
        BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create },
        'create'
      )
      .mockResolvedValue(successResult({} as CalendarSyncMapping));

    const result = await repo.create(staffContext, {
      userId: 'other-user',
      businessId: staffContext.businessId,
      provider: 'google',
      externalEventId: 'ext-1',
      activityId: 'act-1',
      lastSyncedAt: new Date(),
      syncDirection: 'crm_to_calendar',
      status: 'pending',
    });

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
    expect(superCreate).not.toHaveBeenCalled();
  });

  it('sets defaults when privileged users create mappings', async () => {
    const superCreate = vi
      .spyOn(
        BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create },
        'create'
      )
      .mockResolvedValue(
        successResult({
          id: 'map-1',
          businessId: adminContext.businessId,
          userId: adminContext.userId,
          provider: 'google',
          externalEventId: 'ext-1',
          activityId: 'act-1',
          lastSyncedAt: new Date(),
          status: 'synced',
          syncDirection: 'crm_to_calendar',
          createdAt: new Date(),
        } as CalendarSyncMapping)
      );

    const result = await repo.create(adminContext, {
      businessId: adminContext.businessId,
      userId: adminContext.userId,
      provider: 'google',
      externalEventId: 'ext-1',
      activityId: 'act-1',
      lastSyncedAt: new Date(),
      syncDirection: 'crm_to_calendar',
    });

    expect(result.success).toBe(true);
    expect(superCreate).toHaveBeenCalledTimes(1);
    const [, createPayload] = superCreate.mock.calls[0];
    expect(createPayload.status).toBe('synced');
    expect(createPayload.lastSyncedAt).toBeInstanceOf(Date);
  });
});
