/**
 * Calendar Connection Repository
 * Stores OAuth-connected calendar accounts with tenant/user RBAC.
 *
 * HIPAA: Tokens must be encrypted at rest; do not log titles/notes.
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
} from '../errors/repository-errors';
import type { CalendarConnection } from '../../types/calendar-sync';

const PRIVILEGED_ROLES = ['owner', 'admin', 'system'];

export class CalendarConnectionRepository extends BaseRepository<CalendarConnection> {
  constructor() {
    super({
      collectionName: 'calendar_connections',
      softDelete: false,
    });
  }

  private ensureAccess(context: SecurityContext, connection: CalendarConnection): void {
    const isOwner = connection.userId === context.userId;
    const isPrivileged = PRIVILEGED_ROLES.includes(context.userRole);
    if (!isOwner && !isPrivileged) {
      throw new AuthorizationError('You do not have access to this calendar connection');
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
  ): Promise<RepositoryResult<CalendarConnection>> {
    const result = await super.getById(context, id);
    if (!result.success || !result.data) {
      return result;
    }

    try {
      this.ensureAccess(context, result.data);
      return result;
    } catch (error) {
      return failedResult(error, 'Unauthorized calendar connection access');
    }
  }

  async getByUser(
    context: SecurityContext,
    userId?: string
  ): Promise<RepositoryResult<PaginatedResult<CalendarConnection>>> {
    const targetUserId = userId || context.userId;
    const isPrivilegedLookup = Boolean(userId && userId !== context.userId);

    if (isPrivilegedLookup && !PRIVILEGED_ROLES.includes(context.userRole)) {
      return failedResult(
        new AuthorizationError('Only owners/admins can view other users calendar connections')
      );
    }

    return this.getAll(context, this.scopedQuery({}, targetUserId));
  }

  async create(
    context: SecurityContext,
    data: Omit<CalendarConnection, 'id' | 'createdAt' | 'updatedAt'> &
      Partial<Pick<CalendarConnection, 'createdAt' | 'updatedAt'>>,
    customId?: string
  ): Promise<RepositoryResult<CalendarConnection>> {
    const targetUserId = data.userId || context.userId;
    const isPrivileged = PRIVILEGED_ROLES.includes(context.userRole);

    if (targetUserId !== context.userId && !isPrivileged) {
      return failedResult(new AuthorizationError('You cannot create connections for other users'));
    }

    return super.create(
      context,
      {
        ...data,
        userId: targetUserId,
        businessId: context.businessId,
        lastSyncStatus: data.lastSyncStatus || 'success',
        createdAt: data.createdAt || new Date(),
      },
      customId
    );
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<CalendarConnection, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<CalendarConnection>> {
    const existing = await this.getById(context, id);
    if (!existing.success || !existing.data) {
      return existing;
    }

    if (data.userId && data.userId !== existing.data.userId) {
      return failedResult(
        ValidationError.fromErrors([
          { field: 'userId', message: 'Calendar connection owner cannot be changed' },
        ])
      );
    }

    this.ensureAccess(context, existing.data);
    return super.update(context, id, data);
  }

  async updateSyncStatus(
    context: SecurityContext,
    connectionId: string,
    status: CalendarConnection['lastSyncStatus'],
    error?: string
  ): Promise<RepositoryResult<CalendarConnection>> {
    const connection = await this.getById(context, connectionId);
    if (!connection.success || !connection.data) {
      return connection;
    }

    const updateResult = await this.update(context, connectionId, {
      lastSyncStatus: status,
      lastSyncError: error,
      lastSyncAt: new Date(),
    });

    return updateResult;
  }

  async getActiveConnections(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<CalendarConnection>>> {
    const isPrivileged = PRIVILEGED_ROLES.includes(context.userRole);
    if (!isPrivileged) {
      return failedResult(
        new AuthorizationError('Only privileged roles can list all active calendar connections')
      );
    }

    return super.getAll(context, {
      where: [{ field: 'status', operator: '==', value: 'active' }],
    });
  }

  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<CalendarConnection>>> {
    const scopedOptions = this.hasUserScope(options)
      ? options
      : this.scopedQuery(options, context.userId);
    return super.getAll(context, scopedOptions);
  }
}

let calendarConnectionRepository: CalendarConnectionRepository | null = null;

export function getCalendarConnectionRepository(): CalendarConnectionRepository {
  if (!calendarConnectionRepository) {
    calendarConnectionRepository = new CalendarConnectionRepository();
  }
  return calendarConnectionRepository;
}
