/**
 * Document Template Repository
 * CRUD with RBAC for reusable document templates.
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  ValidationResult,
  Validator,
  QueryOptions,
} from './repository-types';
import { AuthorizationError, failedResult, successResult } from '../errors/repository-errors';
import type { DocumentTemplate } from '../../types/documents';
import { isOrgPrivileged } from './access-control';

export function validateDocumentTemplate(data: Partial<DocumentTemplate>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.name?.trim()) {
    errors.push({ field: 'name', message: 'Template name is required', code: 'REQUIRED' });
  }

  if (!data.documentType?.trim()) {
    errors.push({ field: 'documentType', message: 'documentType is required', code: 'REQUIRED' });
  }

  if (!data.templateUrl?.trim()) {
    errors.push({ field: 'templateUrl', message: 'templateUrl is required', code: 'REQUIRED' });
  }

  if (!data.fileType?.trim()) {
    errors.push({ field: 'fileType', message: 'fileType is required', code: 'REQUIRED' });
  }

  if (!data.createdById?.trim()) {
    errors.push({ field: 'createdById', message: 'createdById is required', code: 'REQUIRED' });
  }

  return { isValid: errors.length === 0, errors };
}

export class DocumentTemplateRepository extends BaseRepository<DocumentTemplate> {
  constructor() {
    super({
      collectionName: 'document_templates',
      softDelete: true,
    });
    this.setValidator(validateDocumentTemplate as Validator<DocumentTemplate>);
  }

  async createTemplate(
    context: SecurityContext,
    template: Omit<DocumentTemplate, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<DocumentTemplate>> {
    const payload: Omit<DocumentTemplate, 'id' | 'createdAt' | 'updatedAt'> = {
      ...template,
      businessId: context.businessId,
      isActive: template.isActive ?? true,
      usageCount: template.usageCount ?? 0,
    };

    const result = await this.create(context, payload);
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, { entity: 'document_template' });
    }
    return result;
  }

  async getActive(
    context: SecurityContext,
    category?: string
  ): Promise<RepositoryResult<DocumentTemplate[]>> {
    const where: QueryOptions['where'] = [
      { field: 'isActive', operator: '==', value: true },
    ];

    if (category) {
      where.push({ field: 'category', operator: '==', value: category });
    }

    const result = await this.getAll(context, { where, orderBy: { field: 'usageCount', direction: 'desc' } });
    if (!result.success) {
      return failedResult(result.error);
    }

    return successResult(result.data.data);
  }

  async incrementUsage(context: SecurityContext, templateId: string): Promise<RepositoryResult<void>> {
    const existing = await this.getById(context, templateId);
    if (!existing.success || !existing.data) {
      return failedResult(existing.error);
    }

    if (!isOrgPrivileged(context) && existing.data.createdById !== context.userId) {
      // Usage increments are allowed for the business but not without template access
      return failedResult(new AuthorizationError('Not authorized to update template usage'));
    }

    const nextUsage = (existing.data.usageCount || 0) + 1;
    const result = await this.update(context, templateId, { usageCount: nextUsage });

    if (result.success) {
      await this.logAudit(context, 'update', templateId, { action: 'increment_usage' });
    }

    if (!result.success) {
      return result;
    }

    return successResult(undefined);
  }
}

let documentTemplateRepositoryInstance: DocumentTemplateRepository | null = null;

export function getDocumentTemplateRepository(): DocumentTemplateRepository {
  if (!documentTemplateRepositoryInstance) {
    documentTemplateRepositoryInstance = new DocumentTemplateRepository();
  }
  return documentTemplateRepositoryInstance;
}
