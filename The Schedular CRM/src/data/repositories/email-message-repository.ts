/**
 * Email Message Repository
 * Stores synced inbox messages and tracking metadata.
 *
 * HIPAA: Do not log or expose full bodies; snippets only in queries.
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import { failedResult, AuthorizationError, successResult } from '../errors/repository-errors';
import type { EmailMessage } from '../../types/email-integration';
import { getEmailAccountRepository } from './email-account-repository';

// ============================================
// Repository
// ============================================

export class EmailMessageRepository extends BaseRepository<EmailMessage> {
  private accountRepo = getEmailAccountRepository();
  private accountAccessCache = new Map<string, boolean>();

  constructor() {
    super({
      collectionName: 'email_messages',
      softDelete: false,
    });
  }

  private async ensureAccountAccess(context: SecurityContext, accountId: string): Promise<void> {
    const accountResult = await this.accountRepo.getById(context, accountId);
    if (!accountResult.success || !accountResult.data) {
      throw new AuthorizationError('Inbox account not found or not accessible');
    }
  }

  private accountCacheKey(context: SecurityContext, accountId: string): string {
    return `${context.businessId}:${context.userId}:${context.userRole}:${accountId}`;
  }

  private async canAccessAccount(context: SecurityContext, accountId: string): Promise<boolean> {
    const cacheKey = this.accountCacheKey(context, accountId);
    if (this.accountAccessCache.has(cacheKey)) {
      return this.accountAccessCache.get(cacheKey) as boolean;
    }

    const isPrivileged = context.userRole === 'owner' || context.userRole === 'admin';
    if (isPrivileged) {
      this.accountAccessCache.set(cacheKey, true);
      return true;
    }

    try {
      await this.ensureAccountAccess(context, accountId);
      this.accountAccessCache.set(cacheKey, true);
      return true;
    } catch {
      this.accountAccessCache.set(cacheKey, false);
      return false;
    }
  }

  private async filterAccessibleMessages(
    context: SecurityContext,
    messages: EmailMessage[]
  ): Promise<EmailMessage[]> {
    const filtered: EmailMessage[] = [];
    for (const message of messages) {
      if (await this.canAccessAccount(context, message.accountId)) {
        filtered.push(message);
      }
    }
    return filtered;
  }

  private applyFilters(
    options: QueryOptions = {},
    filters?: { accountId?: string; direction?: EmailMessage['direction'] }
  ): QueryOptions {
    const where = [...(options.where || [])];
    if (filters?.accountId) {
      where.push({ field: 'accountId', operator: '==', value: filters.accountId });
    }
    if (filters?.direction) {
      where.push({ field: 'direction', operator: '==', value: filters.direction });
    }
    return {
      ...options,
      where,
    };
  }

  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<EmailMessage>> {
    const result = await super.getById(context, id);
    if (!result.success || !result.data) {
      return result;
    }

    try {
      await this.ensureAccountAccess(context, result.data.accountId);
      return result;
    } catch (error) {
      return failedResult(error, 'Unauthorized email message access');
    }
  }

  async getByEntity(
    context: SecurityContext,
    entityType: EmailMessage['associatedEntityType'],
    entityId: string
  ): Promise<RepositoryResult<PaginatedResult<EmailMessage>>> {
    const options: QueryOptions = {
      where: [
        { field: 'associatedEntityType', operator: '==', value: entityType },
        { field: 'associatedEntityId', operator: '==', value: entityId },
      ],
      orderBy: { field: 'sentAt', direction: 'desc' },
    };
    const result = await super.getAll(context, options);
    if (!result.success) return result;

    const accessible = await this.filterAccessibleMessages(context, result.data.data);
    return successResult({
      data: accessible,
      lastDoc: result.data.lastDoc,
      hasMore: result.data.hasMore,
    });
  }

  async getByThread(
    context: SecurityContext,
    threadId: string
  ): Promise<RepositoryResult<PaginatedResult<EmailMessage>>> {
    const options: QueryOptions = {
      where: [{ field: 'threadId', operator: '==', value: threadId }],
      orderBy: { field: 'sentAt', direction: 'asc' },
    };
    const result = await super.getAll(context, options);
    if (!result.success) return result;

    const accessible = await this.filterAccessibleMessages(context, result.data.data);
    return successResult({
      data: accessible,
      lastDoc: result.data.lastDoc,
      hasMore: result.data.hasMore,
    });
  }

  async getByTrackingId(
    context: SecurityContext,
    trackingId: string
  ): Promise<RepositoryResult<EmailMessage | null>> {
    const result = await super.getAll(context, {
      where: [{ field: 'trackingId', operator: '==', value: trackingId }],
      limit: 1,
    });

    if (!result.success) {
      return result;
    }

    const message = result.data.data[0] || null;
    if (!message) {
      return successResult(null);
    }

    try {
      await this.ensureAccountAccess(context, message.accountId);
      return successResult(message);
    } catch (error) {
      return failedResult(error, 'Unauthorized email message access');
    }
  }

  /**
   * Simple search by subject/snippet; filters by account/direction if provided.
   * Full-text search should be delegated to a backend service when available.
   */
  async search(
    context: SecurityContext,
    query: string,
    filters?: { accountId?: string; direction?: EmailMessage['direction'] }
  ): Promise<RepositoryResult<PaginatedResult<EmailMessage>>> {
    const normalizedQuery = query.trim().toLowerCase();
    const baseResult = await super.getAll(
      context,
      this.applyFilters(
        {
          orderBy: { field: 'sentAt', direction: 'desc' },
          limit: 50,
        },
        filters
      )
    );

    if (!baseResult.success) {
      return baseResult;
    }

    const accessible = await this.filterAccessibleMessages(context, baseResult.data.data);
    const filtered = accessible.filter((message) => {
      const haystack = `${message.subject} ${message.snippet}`.toLowerCase();
      return haystack.includes(normalizedQuery);
    });

    return successResult({
      data: filtered,
      lastDoc: baseResult.data.lastDoc,
      hasMore: baseResult.data.hasMore,
    });
  }

  /**
   * Messages without associations, scoped by account if provided.
   */
  async getUnassociated(
    context: SecurityContext,
    accountId?: string
  ): Promise<RepositoryResult<EmailMessage[]>> {
    const options: QueryOptions = {
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: 100,
    };
    const result = await super.getAll(context, this.applyFilters(options, { accountId }));

    if (!result.success) {
      return failedResult(result.error || new Error('Failed to load messages'));
    }

    const accessible = await this.filterAccessibleMessages(context, result.data.data);
    const unlinked = accessible.filter(
      (msg) => !msg.associatedEntityId && !msg.associatedEntityType
    );
    return successResult(unlinked);
  }

  /**
   * Enforce account ownership on create/update operations.
   */
  async create(
    context: SecurityContext,
    data: Omit<EmailMessage, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<EmailMessage>> {
    await this.ensureAccountAccess(context, data.accountId);
    return super.create(context, data, customId);
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<EmailMessage, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<EmailMessage>> {
    const existing = await this.getById(context, id);
    if (!existing.success || !existing.data) {
      return existing;
    }
    await this.ensureAccountAccess(context, existing.data.accountId);
    return super.update(context, id, data);
  }

  /**
   * Filter list responses to only accounts the user can access.
   */
  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<EmailMessage>>> {
    const result = await super.getAll(context, options);
    if (!result.success) return result;

    const accessible = await this.filterAccessibleMessages(context, result.data.data);
    return successResult({
      data: accessible,
      lastDoc: result.data.lastDoc,
      hasMore: result.data.hasMore,
    });
  }
}

// ============================================
// Singleton
// ============================================

let emailMessageRepository: EmailMessageRepository | null = null;

export function getEmailMessageRepository(): EmailMessageRepository {
  if (!emailMessageRepository) {
    emailMessageRepository = new EmailMessageRepository();
  }
  return emailMessageRepository;
}
