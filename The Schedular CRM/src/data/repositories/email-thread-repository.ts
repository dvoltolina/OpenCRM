/**
 * Email Thread Repository
 * Stores normalized thread metadata for connected inboxes.
 */

import { BaseRepository } from './base-repository';
import type { SecurityContext, RepositoryResult, PaginatedResult, QueryOptions } from './repository-types';
import type { EmailThread } from '../../types/email-integration';

export class EmailThreadRepository extends BaseRepository<EmailThread> {
  constructor() {
    super({
      collectionName: 'email_threads',
      softDelete: false,
    });
  }

  async getByProviderThreadId(
    context: SecurityContext,
    accountId: string,
    providerThreadId: string
  ): Promise<RepositoryResult<EmailThread | null>> {
    const result = await this.getAll(context, {
      where: [
        { field: 'accountId', operator: '==', value: accountId },
        { field: 'providerThreadId', operator: '==', value: providerThreadId },
      ],
      limit: 1,
    });

    if (!result.success) {
      return result;
    }

    return {
      success: true,
      data: result.data.data[0] || null,
      error: null,
    };
  }

  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<EmailThread>>> {
    return super.getAll(context, {
      ...options,
      orderBy: options.orderBy || { field: 'lastMessageAt', direction: 'desc' },
    });
  }
}

let emailThreadRepository: EmailThreadRepository | null = null;

export function getEmailThreadRepository(): EmailThreadRepository {
  if (!emailThreadRepository) {
    emailThreadRepository = new EmailThreadRepository();
  }
  return emailThreadRepository;
}
