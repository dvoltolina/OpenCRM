/**
 * Document Folder Repository
 * Handles folder CRUD, RBAC, and breadcrumb lookup.
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  ValidationResult,
  Validator,
  WhereClause,
} from './repository-types';
import {
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type { DocumentFolder } from '../../types/documents';
import { hasTeamAccess, isOrgPrivileged } from './access-control';
import { sanitizeTeamIds } from '../../lib/security-context';

export function validateDocumentFolder(data: Partial<DocumentFolder>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.name?.trim()) {
    errors.push({ field: 'name', message: 'Folder name is required', code: 'REQUIRED' });
  }

  if (!data.ownerId?.trim()) {
    errors.push({ field: 'ownerId', message: 'Owner is required', code: 'REQUIRED' });
  }

  return { isValid: errors.length === 0, errors };
}

export class DocumentFolderRepository extends BaseRepository<DocumentFolder> {
  constructor() {
    super({
      collectionName: 'document_folders',
      softDelete: true,
    });
    this.setValidator(validateDocumentFolder as Validator<DocumentFolder>);
  }

  private canAccessFolder(context: SecurityContext, folder: DocumentFolder | null): boolean {
    if (!folder) return false;
    if (isOrgPrivileged(context)) return true;
    if (folder.ownerId === context.userId) return true;
    if (folder.isShared) {
      if (sanitizeTeamIds(folder.sharedWithTeamIds).length) {
        if (hasTeamAccess(context, folder.sharedWithTeamIds)) return true;
      }
      if (folder.sharedWithUserIds?.includes(context.userId)) return true;
    }
    return false;
  }

  async createFolder(
    context: SecurityContext,
    data: Omit<DocumentFolder, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<DocumentFolder>> {
    const payload: Omit<DocumentFolder, 'id' | 'createdAt' | 'updatedAt'> = {
      ...data,
      businessId: context.businessId,
      ownerId: data.ownerId || context.userId,
      isShared: data.isShared ?? false,
      sharedWithTeamIds: sanitizeTeamIds(data.sharedWithTeamIds),
      sharedWithUserIds: data.sharedWithUserIds || [],
    };

    const result = await this.create(context, payload);
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, { entity: 'document_folder' });
    }
    return result;
  }

  async getByParent(
    context: SecurityContext,
    parentId?: string
  ): Promise<RepositoryResult<DocumentFolder[]>> {
    const where: WhereClause[] = parentId
      ? [{ field: 'parentFolderId', operator: '==', value: parentId } as WhereClause]
      : [{ field: 'parentFolderId', operator: '==', value: null } as WhereClause];

    const result = await this.getAll(context, { where, orderBy: { field: 'name', direction: 'asc' } });
    if (!result.success) return failedResult(result.error);

    const folders = result.data.data.filter((folder) => this.canAccessFolder(context, folder));
    return successResult(folders);
  }

  async getPath(context: SecurityContext, folderId: string): Promise<RepositoryResult<DocumentFolder[]>> {
    const path: DocumentFolder[] = [];
    let currentId: string | undefined = folderId;

    while (currentId) {
      const folderResult = await this.getById(context, currentId);
      if (!folderResult.success || !folderResult.data) {
        break;
      }

      const folder = folderResult.data;
      if (!this.canAccessFolder(context, folder)) {
        return failedResult(new AuthorizationError('Not authorized to access folder path'));
      }

      path.unshift(folder);
      currentId = folder.parentFolderId || undefined;
    }

    return successResult(path);
  }

  async deleteFolder(context: SecurityContext, folderId: string): Promise<RepositoryResult<void>> {
    const existing = await this.getById(context, folderId);
    if (!existing.success || !existing.data) {
      return failedResult(existing.error);
    }

    if (!this.canAccessFolder(context, existing.data)) {
      return failedResult(new AuthorizationError('Not authorized to delete folder'));
    }

    const result = await this.delete(context, folderId);
    if (result.success) {
      await this.logAudit(context, 'delete', folderId, { action: 'delete_folder' });
    }
    return result;
  }
}

let documentFolderRepositoryInstance: DocumentFolderRepository | null = null;

export function getDocumentFolderRepository(): DocumentFolderRepository {
  if (!documentFolderRepositoryInstance) {
    documentFolderRepositoryInstance = new DocumentFolderRepository();
  }
  return documentFolderRepositoryInstance;
}
