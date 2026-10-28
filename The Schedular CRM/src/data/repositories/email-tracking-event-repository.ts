/**
 * Email Tracking Event Repository
 * Persists open/click events for auditing and analytics.
 */

import { BaseRepository } from './base-repository';
import type { SecurityContext, RepositoryResult, PaginatedResult, QueryOptions } from './repository-types';
import type { EmailTrackingEvent } from '../../types/email-integration';

export class EmailTrackingEventRepository extends BaseRepository<EmailTrackingEvent> {
  constructor() {
    super({
      collectionName: 'email_tracking_events',
      softDelete: false,
    });
  }

  async getByTrackingId(
    context: SecurityContext,
    trackingId: string
  ): Promise<RepositoryResult<PaginatedResult<EmailTrackingEvent>>> {
    const options: QueryOptions = {
      where: [{ field: 'trackingId', operator: '==', value: trackingId }],
      orderBy: { field: 'occurredAt', direction: 'desc' },
    };
    return this.getAll(context, options);
  }
}

let emailTrackingEventRepository: EmailTrackingEventRepository | null = null;

export function getEmailTrackingEventRepository(): EmailTrackingEventRepository {
  if (!emailTrackingEventRepository) {
    emailTrackingEventRepository = new EmailTrackingEventRepository();
  }
  return emailTrackingEventRepository;
}
