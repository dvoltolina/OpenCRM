/**
 * Calendar Sync Mapping Repository
 * Tracks mapping between CRM activities and provider event IDs.
 *
 * HIPAA: Only stores IDs/timestamps; no event bodies or attendee details.
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
  WhereClause,
} from './repository-types';
import {
  AuthorizationError,
  ValidationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type { CalendarProvider, CalendarSyncMapping } from '../../types/calendar-sync';

const PRIVILEGED_ROLES = ['owner', 'admin', 'system'];

export class CalendarSyncMappingRepository extends BaseRepository<CalendarSyncMapping> {
  constructor() {
    super({
      collectionName: 'calendar_sync_mappings',
      softDelete: false,
    });
  }

  private ensureAccess(context: SecurityContext, mapping: CalendarSyncMapping): void {
    const isOwner = mapping.userId === context.userId;
    const isPrivileged = PRIVILEGED_ROLES.includes(context.userRole);
    if (!isOwner && !isPrivileged) {
      throw new AuthorizationError('You do not have access to this calendar sync mapping');
    }
  }

  private scopedQuery(options: QueryOptions = {}, userId: string) {
    const where: WhereClause[] = [
      ...(options.where || []),
      { field: 'userId', operator: '==', value: userId } as WhereClause,
    ];
    return { ...options, where };
  }

  private hasUserScope(options: QueryOptions = {}): boolean {
    return (options.where || []).some((clause) => clause.field === 'userId');
  }

  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<CalendarSyncMapping>> {
    const result = await super.getById(context, id);
    if (!result.success || !result.data) {
      return result;
    }

    try {
      this.ensureAccess(context, result.data);
      return result;
    } catch (error) {
      return failedResult(error, 'Unauthorized calendar mapping access');
    }
  }

  async getByActivity(
    context: SecurityContext,
    activityId: string
  ): Promise<RepositoryResult<CalendarSyncMapping | null>> {
    const result = await this.getAll(context, {
      where: [{ field: 'activityId', operator: '==', value: activityId }],
      limit: 1,
    });

    if (!result.success) {
      return result;
    }

    const mapping = result.data.data[0] || null;
    if (mapping) {
      try {
        this.ensureAccess(context, mapping);
      } catch (error) {
        return failedResult(error, 'Unauthorized calendar mapping access');
      }
    }

    return successResult(mapping);
  }

  async getByExternalEvent(
    context: SecurityContext,
    provider: CalendarProvider,
    externalEventId: string
  ): Promise<RepositoryResult<CalendarSyncMapping | null>> {
    const result = await this.getAll(context, {
      where: [
        { field: 'provider', operator: '==', value: provider },
        { field: 'externalEventId', operator: '==', value: externalEventId },
      ],
      limit: 1,
    });

    if (!result.success) {
      return result;
    }

    const mapping = result.data.data[0] || null;
    if (mapping) {
      try {
        this.ensureAccess(context, mapping);
      } catch (error) {
        return failedResult(error, 'Unauthorized calendar mapping access');
      }
    }

    return successResult(mapping);
  }

  async getConflicts(
    context: SecurityContext,
    userId?: string
  ): Promise<RepositoryResult<PaginatedResult<CalendarSyncMapping>>> {
    const targetUserId = userId || context.userId;
    const isPrivilegedLookup = Boolean(userId && userId !== context.userId);

    if (isPrivilegedLookup && !PRIVILEGED_ROLES.includes(context.userRole)) {
      return failedResult(
        new AuthorizationError('Only owners/admins can view conflicts for other users')
      );
    }

    return this.getAll(context, {
      where: [
        { field: 'userId', operator: '==', value: targetUserId },
        { field: 'status', operator: '==', value: 'conflict' },
      ],
    });
  }

  async create(
    context: SecurityContext,
    data: Omit<CalendarSyncMapping, 'id' | 'createdAt' | 'updatedAt'> &
      Partial<Pick<CalendarSyncMapping, 'createdAt' | 'updatedAt'>>,
    customId?: string
  ): Promise<RepositoryResult<CalendarSyncMapping>> {
    const targetUserId = data.userId || context.userId;
    const isPrivileged = PRIVILEGED_ROLES.includes(context.userRole);

    if (targetUserId !== context.userId && !isPrivileged) {
      return failedResult(new AuthorizationError('You cannot create mappings for other users'));
    }

    return super.create(
      context,
      {
        ...data,
        userId: targetUserId,
        businessId: context.businessId,
        status: data.status || 'synced',
        lastSyncedAt: data.lastSyncedAt || new Date(),
        createdAt: data.createdAt || new Date(),
        updatedAt: data.updatedAt,
      },
      customId
    );
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<CalendarSyncMapping, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<CalendarSyncMapping>> {
    const existing = await this.getById(context, id);
    if (!existing.success || !existing.data) {
      return existing;
    }

    if (data.userId && data.userId !== existing.data.userId) {
      return failedResult(
        ValidationError.fromErrors([
          { field: 'userId', message: 'Calendar mapping owner cannot be changed' },
        ])
      );
    }

    this.ensureAccess(context, existing.data);
    return super.update(context, id, data);
  }

  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<CalendarSyncMapping>>> {
    const scopedOptions = this.hasUserScope(options)
      ? options
      : this.scopedQuery(options, context.userId);
    return super.getAll(context, scopedOptions);
  }
}

let calendarSyncMappingRepository: CalendarSyncMappingRepository | null = null;

export function getCalendarSyncMappingRepository(): CalendarSyncMappingRepository {
  if (!calendarSyncMappingRepository) {
    calendarSyncMappingRepository = new CalendarSyncMappingRepository();
  }
  return calendarSyncMappingRepository;
}
