/**
 * Document Repository
 * Scoped CRUD with RBAC for business documents.
 *
 * HIPAA: Enforces business isolation and access lists (owner/user/team/public).
 * No direct Firestore access outside repositories.
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  QueryOptions,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  AuthorizationError,
  NotFoundError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type { Document, DocumentStatus, DocumentType } from '../../types/documents';
import { hasTeamAccess, isOrgPrivileged } from './access-control';
import { sanitizeTeamIds } from '../../lib/security-context';

export interface DocumentFilterOptions {
  folderId?: string | null;
  entityType?: string;
  entityId?: string;
  documentType?: DocumentType;
  status?: DocumentStatus;
  isLatest?: boolean;
}

function normalizeArray(value?: string[]): string[] {
  return Array.isArray(value) ? value.filter(Boolean) : [];
}

export function validateDocument(data: Partial<Document>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];
  const allowedTypes: DocumentType[] = [
    'proposal',
    'contract',
    'quote',
    'invoice',
    'agreement',
    'attachment',
    'other',
  ];
  const allowedStatus: DocumentStatus[] = [
    'draft',
    'pending_signature',
    'signed',
    'expired',
    'voided',
    'final',
  ];

  if (!data.name?.trim()) {
    errors.push({ field: 'name', message: 'Name is required', code: 'REQUIRED' });
  }

  if (!data.documentType || !allowedTypes.includes(data.documentType)) {
    errors.push({
      field: 'documentType',
      message: 'Valid documentType is required',
      code: 'INVALID_VALUE',
    });
  }

  if (!data.status || !allowedStatus.includes(data.status)) {
    errors.push({
      field: 'status',
      message: 'Valid status is required',
      code: 'INVALID_VALUE',
    });
  }

  if (!data.fileName?.trim()) {
    errors.push({ field: 'fileName', message: 'fileName is required', code: 'REQUIRED' });
  }

  if (!data.fileType?.trim()) {
    errors.push({ field: 'fileType', message: 'fileType is required', code: 'REQUIRED' });
  }

  if (data.fileSize !== undefined && data.fileSize <= 0) {
    errors.push({ field: 'fileSize', message: 'fileSize must be greater than zero', code: 'INVALID' });
  }

  if (!data.storageUrl?.trim()) {
    errors.push({ field: 'storageUrl', message: 'storageUrl is required', code: 'REQUIRED' });
  }

  if (data.version !== undefined && data.version < 1) {
    errors.push({ field: 'version', message: 'version must be at least 1', code: 'INVALID' });
  }

  if (!data.uploadedById?.trim()) {
    errors.push({ field: 'uploadedById', message: 'uploadedById is required', code: 'REQUIRED' });
  }

  if (!data.ownerId?.trim()) {
    errors.push({ field: 'ownerId', message: 'ownerId is required', code: 'REQUIRED' });
  }

  return { isValid: errors.length === 0, errors };
}

export class DocumentRepository extends BaseRepository<Document> {
  constructor() {
    super({
      collectionName: 'documents',
      softDelete: true,
    });
    this.setValidator(validateDocument as Validator<Document>);
  }

  private canAccessDocument(context: SecurityContext, document: Document | null): boolean {
    if (!document) return false;
    if (isOrgPrivileged(context)) return true;
    if (document.ownerId === context.userId || document.uploadedById === context.userId) {
      return true;
    }
    if (normalizeArray(document.accessUserIds).includes(context.userId)) {
      return true;
    }
    const teamIds = sanitizeTeamIds(document.accessTeamIds);
    if (teamIds.length && hasTeamAccess(context, teamIds)) {
      return true;
    }
    return document.isPublic === true;
  }

  async createDocument(
    context: SecurityContext,
    data: Omit<Document, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<Document>> {
    const payload: Omit<Document, 'id' | 'createdAt' | 'updatedAt'> = {
      ...data,
      businessId: context.businessId,
      ownerId: data.ownerId || context.userId,
      ownerName: data.ownerName || context.userName,
      uploadedById: data.uploadedById || context.userId,
      uploadedByName: data.uploadedByName || context.userName,
      accessUserIds: normalizeArray(data.accessUserIds).length
        ? normalizeArray(data.accessUserIds)
        : [context.userId],
      accessTeamIds: sanitizeTeamIds(data.accessTeamIds),
      isLatestVersion: data.isLatestVersion ?? true,
    };

    const result = await this.create(context, payload);
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, { entity: 'document' });
    }
    return result;
  }

  async getDocument(context: SecurityContext, documentId: string): Promise<RepositoryResult<Document>> {
    const result = await this.getById(context, documentId);
    if (!result.success) return result;

    if (!this.canAccessDocument(context, result.data)) {
      return failedResult(new AuthorizationError('Not authorized to access document'));
    }

    return result;
  }

  async getDocuments(
    context: SecurityContext,
    filters: DocumentFilterOptions = {}
  ): Promise<RepositoryResult<Document[]>> {
    const where: NonNullable<QueryOptions['where']> = [];

    if (filters.folderId !== undefined) {
      where.push({ field: 'folderId', operator: '==', value: filters.folderId });
    }

    if (filters.entityType) {
      where.push({ field: 'associatedEntityType', operator: '==', value: filters.entityType });
    }

    if (filters.entityId) {
      where.push({ field: 'associatedEntityId', operator: '==', value: filters.entityId });
    }

    if (filters.documentType) {
      where.push({ field: 'documentType', operator: '==', value: filters.documentType });
    }

    if (filters.status) {
      where.push({ field: 'status', operator: '==', value: filters.status });
    }

    if (filters.isLatest !== undefined) {
      where.push({ field: 'isLatestVersion', operator: '==', value: filters.isLatest });
    }

    const result = await this.getAll(context, {
      where: where.length ? where : undefined,
      orderBy: { field: 'createdAt', direction: 'desc' },
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    const accessible = this.filterAccessibleDocuments(context, result.data.data);
    return successResult(accessible);
  }

  async getBySignatureRequestId(
    context: SecurityContext,
    signatureRequestId: string
  ): Promise<RepositoryResult<Document>> {
    const result = await this.getAll(context, {
      where: [{ field: 'signatureRequestId', operator: '==', value: signatureRequestId }],
      limit: 1,
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    const document = result.data.data[0];
    if (!document) {
      return failedResult(new NotFoundError('document', signatureRequestId));
    }

    if (!this.canAccessDocument(context, document)) {
      return failedResult(new AuthorizationError('Not authorized to access document'));
    }

    return successResult(document);
  }

  async getByEntity(
    context: SecurityContext,
    entityType: string,
    entityId: string
  ): Promise<RepositoryResult<Document[]>> {
    return this.getDocuments(context, { entityType, entityId });
  }

  async getByFolder(
    context: SecurityContext,
    folderId: string | null
  ): Promise<RepositoryResult<Document[]>> {
    return this.getDocuments(context, { folderId });
  }

  async getVersions(context: SecurityContext, documentId: string): Promise<RepositoryResult<Document[]>> {
    const visited = new Set<string>();
    const stack: string[] = [documentId];
    const versions: Document[] = [];

    while (stack.length) {
      const currentId = stack.pop();
      if (!currentId || visited.has(currentId)) {
        continue;
      }
      visited.add(currentId);

      const docResult = await this.getById(context, currentId);
      if (!docResult.success || !docResult.data) {
        continue;
      }

      const doc = docResult.data;
      if (this.canAccessDocument(context, doc)) {
        versions.push(doc);
        if (doc.previousVersionId) {
          stack.push(doc.previousVersionId);
        }
        const children = await this.getAll(context, {
          where: [{ field: 'previousVersionId', operator: '==', value: doc.id }],
        });
        if (children.success) {
          children.data.data.forEach((child) => stack.push(child.id));
        }
      }
    }

    versions.sort((a, b) => (b.version || 0) - (a.version || 0));
    return successResult(versions);
  }

  async search(
    context: SecurityContext,
    queryText: string,
    filters: DocumentFilterOptions = {}
  ): Promise<RepositoryResult<Document[]>> {
    const baseResult = await this.getDocuments(context, filters);
    if (!baseResult.success) return baseResult;

    const needle = queryText.trim().toLowerCase();
    if (!needle) {
      return successResult(baseResult.data);
    }

    const filtered = baseResult.data.filter((doc) => {
      const haystacks = [
        doc.name?.toLowerCase() || '',
        doc.description?.toLowerCase() || '',
        ...(doc.tags || []).map((tag) => tag.toLowerCase()),
      ];
      return haystacks.some((value) => value.includes(needle));
    });

    return successResult(filtered);
  }

  async moveToFolder(
    context: SecurityContext,
    documentId: string,
    folderId: string | null
  ): Promise<RepositoryResult<Document>> {
    const existing = await this.getDocument(context, documentId);
    if (!existing.success) return existing;

    const updateResult = await this.update(context, documentId, {
      folderId: folderId ?? undefined,
    });

    if (updateResult.success) {
      await this.logAudit(context, 'update', documentId, { action: 'move_to_folder', folderId });
    }

    return updateResult;
  }

  async deleteDocument(context: SecurityContext, documentId: string): Promise<RepositoryResult<void>> {
    const existing = await this.getDocument(context, documentId);
    if (!existing.success) {
      return failedResult(existing.error);
    }

    if (!this.canAccessDocument(context, existing.data)) {
      return failedResult(new AuthorizationError('Not authorized to delete document'));
    }

    const result = await this.delete(context, documentId);
    if (result.success) {
      await this.logAudit(context, 'delete', documentId, { action: 'delete_document' });
    }
    return result;
  }

  private filterAccessibleDocuments(context: SecurityContext, docs: Document[]): Document[] {
    return docs.filter((doc) => this.canAccessDocument(context, doc));
  }
}

let documentRepositoryInstance: DocumentRepository | null = null;

export function getDocumentRepository(): DocumentRepository {
  if (!documentRepositoryInstance) {
    documentRepositoryInstance = new DocumentRepository();
  }
  return documentRepositoryInstance;
}
