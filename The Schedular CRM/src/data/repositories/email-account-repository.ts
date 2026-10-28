/**
 * Email Account Repository
 * Stores OAuth-connected inbox accounts with tenant/user RBAC.
 *
 * HIPAA: Tokens must be encrypted at rest; no PHI in logs.
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
  successResult,
  failedResult,
} from '../errors/repository-errors';
import type { EmailAccount, EmailSyncStatus } from '../../types/email-integration';

// ============================================
// Helpers
// ============================================

const OWNERSHIP_ROLES = ['owner', 'admin', 'system'];

// ============================================
// Repository
// ============================================

export class EmailAccountRepository extends BaseRepository<EmailAccount> {
  constructor() {
    super({
      collectionName: 'email_accounts',
      softDelete: false,
    });
  }

  private ensureAccountAccess(context: SecurityContext, account: EmailAccount): void {
    const isOwner = account.userId === context.userId;
    const isPrivileged = OWNERSHIP_ROLES.includes(context.userRole);
    if (!isOwner && !isPrivileged) {
      throw new AuthorizationError('You do not have access to this inbox account');
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

  /**
   * Ensure account is accessible before returning it.
   */
  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<EmailAccount>> {
    const result = await super.getById(context, id);
    if (!result.success || !result.data) {
      return result;
    }
    try {
      this.ensureAccountAccess(context, result.data);
      return result;
    } catch (error) {
      return failedResult(error, 'Unauthorized email account access');
    }
  }

  /**
   * Get accounts for the current user (default) or a specific user (admin/owner).
   */
  async getByUserId(
    context: SecurityContext,
    userId?: string
  ): Promise<RepositoryResult<PaginatedResult<EmailAccount>>> {
    const targetUserId = userId || context.userId;
    const isPrivilegedLookup = Boolean(userId && userId !== context.userId);

    if (isPrivilegedLookup && !OWNERSHIP_ROLES.includes(context.userRole)) {
      return failedResult(
        new AuthorizationError('Only owners/admins can view other users inbox accounts')
      );
    }

    return this.getAll(context, this.scopedQuery({}, targetUserId));
  }

  /**
   * Find account by email address (case-insensitive).
   */
  async getByEmail(
    context: SecurityContext,
    email: string
  ): Promise<RepositoryResult<EmailAccount | null>> {
    const normalized = email.trim().toLowerCase();
    const result = await this.getAll(context, {
      where: [{ field: 'email', operator: '==', value: normalized }],
      limit: 1,
    });

    if (!result.success) {
      return result;
    }

    const account = result.data.data[0] || null;
    if (account) {
      try {
        this.ensureAccountAccess(context, account);
      } catch (error) {
        return failedResult(error, 'Unauthorized email account access');
      }
    }

    return successResult(account);
  }

  /**
   * Create an account scoped to the requester unless privileged.
   */
  async create(
    context: SecurityContext,
    data: Omit<EmailAccount, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<EmailAccount>> {
    const targetUserId = data.userId || context.userId;
    const isPrivileged = OWNERSHIP_ROLES.includes(context.userRole);

    if (targetUserId !== context.userId && !isPrivileged) {
      return failedResult(new AuthorizationError('You cannot create accounts for other users'));
    }

    return super.create(
      context,
      { ...data, userId: targetUserId, businessId: context.businessId },
      customId
    );
  }

  /**
   * Update sync status and cursor after a sync run.
   */
  async updateSyncStatus(
    context: SecurityContext,
    accountId: string,
    status: EmailSyncStatus,
    cursor?: string
  ): Promise<RepositoryResult<EmailAccount>> {
    const accountResult = await this.getById(context, accountId);
    if (!accountResult.success || !accountResult.data) {
      return accountResult;
    }

    const updateResult = await this.update(context, accountId, {
      syncStatus: status,
      syncCursor: cursor,
      lastSyncAt: new Date(),
    });

    return updateResult;
  }

  /**
   * Prevent ownership changes while allowing admins to update settings.
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<EmailAccount, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<EmailAccount>> {
    const existing = await this.getById(context, id);
    if (!existing.success || !existing.data) {
      return existing;
    }

    if (data.userId && data.userId !== existing.data.userId) {
      return failedResult(
        ValidationError.fromErrors([
          { field: 'userId', message: 'Email account owner cannot be changed' },
        ])
      );
    }

    this.ensureAccountAccess(context, existing.data);
    return super.update(context, id, data);
  }

  /**
   * List accounts for the current user only.
   */
  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<EmailAccount>>> {
    const scopedOptions = this.hasUserScope(options)
      ? options
      : this.scopedQuery(options, context.userId);
    return super.getAll(context, scopedOptions);
  }
}

// ============================================
// Singleton
// ============================================

let emailAccountRepository: EmailAccountRepository | null = null;

export function getEmailAccountRepository(): EmailAccountRepository {
  if (!emailAccountRepository) {
    emailAccountRepository = new EmailAccountRepository();
  }
  return emailAccountRepository;
}
