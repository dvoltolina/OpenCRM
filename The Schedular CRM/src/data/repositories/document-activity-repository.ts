/**
 * Document Activity Repository
 * Append-only log for document events (viewed, downloaded, signed, etc.).
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import type { DocumentActivity } from '../../types/documents';
import { failedResult, successResult } from '../errors/repository-errors';

export function validateDocumentActivity(data: Partial<DocumentActivity>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.documentId?.trim()) {
    errors.push({ field: 'documentId', message: 'documentId is required', code: 'REQUIRED' });
  }

  if (!data.activityType?.trim()) {
    errors.push({ field: 'activityType', message: 'activityType is required', code: 'REQUIRED' });
  }

  if (!data.occurredAt) {
    errors.push({ field: 'occurredAt', message: 'occurredAt is required', code: 'REQUIRED' });
  }

  return { isValid: errors.length === 0, errors };
}

export class DocumentActivityRepository extends BaseRepository<DocumentActivity> {
  constructor() {
    super({
      collectionName: 'document_activities',
      softDelete: false,
    });
    this.setValidator(validateDocumentActivity as Validator<DocumentActivity>);
  }

  async recordActivity(
    context: SecurityContext,
    activity: Omit<DocumentActivity, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<DocumentActivity>> {
    const payload = {
      ...activity,
      businessId: context.businessId,
      occurredAt: activity.occurredAt || new Date(),
    };
    const result = await this.create(context, payload);
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, { entity: 'document_activity' });
    }
    return result;
  }

  async getByDocument(
    context: SecurityContext,
    documentId: string
  ): Promise<RepositoryResult<DocumentActivity[]>> {
    const result = await this.getAll(context, {
      where: [{ field: 'documentId', operator: '==', value: documentId }],
      orderBy: { field: 'occurredAt', direction: 'desc' },
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(result.data.data);
  }
}

let documentActivityRepositoryInstance: DocumentActivityRepository | null = null;

export function getDocumentActivityRepository(): DocumentActivityRepository {
  if (!documentActivityRepositoryInstance) {
    documentActivityRepositoryInstance = new DocumentActivityRepository();
  }
  return documentActivityRepositoryInstance;
}
