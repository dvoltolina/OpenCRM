/**
 * Document Service
 * Orchestrates document CRUD, versioning, and public link management.
 *
 * Storage upload is handled via Cloud Functions signed URLs; this service
 * records metadata and RBAC-enforced access paths only.
 */

import { getFeatureFlags } from '../config/features';
import type { SecurityContext } from '../data/repositories/repository-types';
import { getDocumentRepository } from '../data/repositories/document-repository';
import { getDocumentFolderRepository } from '../data/repositories/document-folder-repository';
import { getDocumentTemplateRepository } from '../data/repositories/document-template-repository';
import { getDocumentActivityRepository } from '../data/repositories/document-activity-repository';
import type {
  Document,
  DocumentActivity,
  DocumentFolder,
  DocumentSigner,
  DocumentTemplate,
  DocumentStatus,
  DocumentType,
} from '../types/documents';
import { generateId } from '../data/repositories/firestore-utils';
import { DocumentFunctionsClient } from './document-functions-client';

function assertFeatureEnabled(): void {
  const { enableDocuments } = getFeatureFlags();
  if (!enableDocuments) {
    throw new Error('Document management is disabled for this environment');
  }
}

function assertSignatureEnabled(): void {
  const { enableESignature } = getFeatureFlags();
  if (!enableESignature) {
    throw new Error('E-signature is disabled for this environment');
  }
}

/** Build storage path for document files - kept for potential direct storage access */
// @ts-expect-error - Kept for potential direct storage access
function _buildStoragePath(
  businessId: string,
  documentId: string,
  fileName: string,
  version?: number
): string {
  if (version && version > 1) {
    return `businesses/${businessId}/documents/${documentId}/versions/v${version}/${fileName}`;
  }
  return `businesses/${businessId}/documents/${documentId}/original/${fileName}`;
}

export class DocumentService {
  private documentRepo = getDocumentRepository();
  private folderRepo = getDocumentFolderRepository();
  private templateRepo = getDocumentTemplateRepository();
  private activityRepo = getDocumentActivityRepository();
  private functionsClient = new DocumentFunctionsClient();

  // Upload document
  async uploadDocument(
    context: SecurityContext,
    file: File,
    options: {
      name: string;
      documentType: DocumentType;
      description?: string;
      associatedEntity?: { type: string; id: string };
      folderId?: string;
      tags?: string[];
    }
  ): Promise<Document> {
    assertFeatureEnabled();
    const uploadPlan = await this.functionsClient.requestUpload(context, {
      name: options.name,
      description: options.description,
      documentType: options.documentType,
      fileName: file.name,
      fileType: file.type || 'application/octet-stream',
      fileSize: file.size,
      folderId: options.folderId,
      tags: options.tags,
      associatedEntityType: options.associatedEntity?.type as 'lead' | 'client' | 'deal' | undefined,
      associatedEntityId: options.associatedEntity?.id,
      version: 1,
      requiresSignature: false,
    });

    await this.functionsClient.uploadFile(uploadPlan.uploadUrl, file, uploadPlan.uploadHeaders);

    const created = await this.documentRepo.getDocument(context, uploadPlan.documentId);
    if (!created.success) {
      throw new Error(created.error?.message || 'Document uploaded but metadata unavailable');
    }
    return created.data;
  }

  // Create from template
  async createFromTemplate(
    context: SecurityContext,
    templateId: string,
    options: {
      name: string;
      mergeData: Record<string, string>;
      associatedEntity?: { type: string; id: string };
      signers?: Omit<DocumentSigner, 'id' | 'status'>[];
    }
  ): Promise<Document> {
    assertFeatureEnabled();
    const generation = await this.functionsClient.generateFromTemplate(context, {
      templateId,
      name: options.name,
      mergeData: options.mergeData,
      associatedEntity: options.associatedEntity,
      signers: options.signers,
    });

    const created = await this.documentRepo.getDocument(context, generation.documentId);
    if (!created.success) {
      throw new Error(created.error?.message || 'Document generation failed');
    }
    await this.templateRepo.incrementUsage(context, templateId);
    return created.data;
  }

  // Update document (new version)
  async updateDocument(
    context: SecurityContext,
    documentId: string,
    file: File,
    options?: { description?: string }
  ): Promise<Document> {
    assertFeatureEnabled();
    const existingResult = await this.documentRepo.getDocument(context, documentId);
    if (!existingResult.success) {
      throw new Error(existingResult.error?.message || 'Document not found');
    }

    const existing = existingResult.data;
    const nextVersion = (existing.version || 1) + 1;

    const uploadPlan = await this.functionsClient.requestUpload(context, {
      name: existing.name,
      description: options?.description ?? existing.description,
      documentType: existing.documentType,
      fileName: file.name,
      fileType: file.type || 'application/octet-stream',
      fileSize: file.size,
      folderId: existing.folderId,
      tags: existing.tags,
      associatedEntityType: existing.associatedEntityType,
      associatedEntityId: existing.associatedEntityId,
      previousVersionId: existing.id,
      version: nextVersion,
      requiresSignature: existing.requiresSignature,
    });

    await this.functionsClient.uploadFile(uploadPlan.uploadUrl, file, uploadPlan.uploadHeaders);

    const created = await this.documentRepo.getDocument(context, uploadPlan.documentId);
    if (!created.success) {
      throw new Error(created.error?.message || 'Document version upload failed');
    }
    return created.data;
  }

  async getDocument(context: SecurityContext, documentId: string): Promise<Document> {
    assertFeatureEnabled();
    const result = await this.documentRepo.getDocument(context, documentId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Document not found');
    }
    return result.data;
  }

  async getDocuments(
    context: SecurityContext,
    options?: {
      folderId?: string;
      entityType?: string;
      entityId?: string;
      documentType?: DocumentType;
      status?: DocumentStatus;
    }
  ): Promise<Document[]> {
    assertFeatureEnabled();
    const result = await this.documentRepo.getDocuments(context, {
      folderId: options?.folderId,
      entityType: options?.entityType,
      entityId: options?.entityId,
      documentType: options?.documentType,
      status: options?.status,
      isLatest: true,
    });
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to list documents');
    }
    return result.data;
  }

  async getDocumentVersions(context: SecurityContext, documentId: string): Promise<Document[]> {
    assertFeatureEnabled();
    const result = await this.documentRepo.getVersions(context, documentId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to load versions');
    }
    return result.data;
  }

  // Download
  async getDownloadUrl(context: SecurityContext, documentId: string): Promise<string> {
    assertFeatureEnabled();
    return this.functionsClient.getDownloadUrl(context, documentId);
  }

  // Delete
  async deleteDocument(context: SecurityContext, documentId: string): Promise<void> {
    assertFeatureEnabled();
    const result = await this.documentRepo.deleteDocument(context, documentId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to delete document');
    }
    await this.activityRepo.recordActivity(context, {
      businessId: context.businessId,
      documentId,
      activityType: 'updated',
      actorId: context.userId,
      actorName: context.userName,
      occurredAt: new Date(),
      details: { action: 'deleted' },
    });
  }

  // Folders
  async createFolder(context: SecurityContext, name: string, parentId?: string): Promise<DocumentFolder> {
    assertFeatureEnabled();
    const result = await this.folderRepo.createFolder(context, {
      businessId: context.businessId,
      name,
      parentFolderId: parentId,
      color: undefined,
      ownerId: context.userId,
      isShared: false,
      sharedWithUserIds: [],
      sharedWithTeamIds: [],
    });

    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to create folder');
    }
    return result.data;
  }

  async moveToFolder(
    context: SecurityContext,
    documentId: string,
    folderId: string | null
  ): Promise<void> {
    assertFeatureEnabled();
    const result = await this.documentRepo.moveToFolder(context, documentId, folderId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to move document');
    }
  }

  async getFolders(context: SecurityContext, parentId?: string): Promise<DocumentFolder[]> {
    assertFeatureEnabled();
    const result = await this.folderRepo.getByParent(context, parentId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to load folders');
    }
    return result.data;
  }

  // Public links
  async generatePublicLink(
    context: SecurityContext,
    documentId: string,
    expiresInDays = 7
  ): Promise<{ url: string; expiresAt: Date }> {
    assertFeatureEnabled();
    const doc = await this.getDocument(context, documentId);
    const token = `${generateId()}-${generateId()}`;
    const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000);

    const updateResult = await this.documentRepo.update(context, doc.id, {
      isPublic: true,
      publicLinkToken: token,
      publicLinkExpiresAt: expiresAt,
    });

    if (!updateResult.success) {
      throw new Error(updateResult.error?.message || 'Failed to enable public link');
    }

    await this.activityRepo.recordActivity(context, {
      businessId: context.businessId,
      documentId: doc.id,
      activityType: 'updated',
      actorId: context.userId,
      actorName: context.userName,
      occurredAt: new Date(),
      details: { publicLinkExpiresAt: expiresAt },
    });

    return {
      url: token,
      expiresAt,
    };
  }

  async revokePublicLink(context: SecurityContext, documentId: string): Promise<void> {
    assertFeatureEnabled();
    const updateResult = await this.documentRepo.update(context, documentId, {
      isPublic: false,
      publicLinkToken: undefined,
      publicLinkExpiresAt: undefined,
    });

    if (!updateResult.success) {
      throw new Error(updateResult.error?.message || 'Failed to revoke public link');
    }
  }

  // E-signature
  async sendForSignature(
    context: SecurityContext,
    documentId: string,
    signers: Array<Omit<DocumentSigner, 'id' | 'status'>>,
    options?: { message?: string; expiresInDays?: number }
  ): Promise<Document> {
    assertFeatureEnabled();
    assertSignatureEnabled();

    if (!signers.length) {
      throw new Error('At least one signer is required');
    }

    await this.functionsClient.sendForSignature(context, {
      documentId,
      signers,
      message: options?.message,
      expiresInDays: options?.expiresInDays,
    });

    const updated = await this.documentRepo.getDocument(context, documentId);
    if (!updated.success) {
      throw new Error(updated.error?.message || 'Signature request sent but document not available');
    }
    return updated.data;
  }

  // Templates
  async createTemplate(
    context: SecurityContext,
    template: Omit<DocumentTemplate, 'id' | 'businessId' | 'createdAt'>
  ): Promise<DocumentTemplate> {
    assertFeatureEnabled();
    const result = await this.templateRepo.createTemplate(context, {
      ...template,
      businessId: context.businessId,
      createdById: template.createdById || context.userId,
      usageCount: template.usageCount ?? 0,
    });

    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to create template');
    }

    return result.data;
  }

  async getTemplates(context: SecurityContext, category?: string): Promise<DocumentTemplate[]> {
    assertFeatureEnabled();
    const result = await this.templateRepo.getActive(context, category);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to load templates');
    }
    return result.data;
  }

  // Activity
  async getDocumentActivity(context: SecurityContext, documentId: string): Promise<DocumentActivity[]> {
    assertFeatureEnabled();
    const result = await this.activityRepo.getByDocument(context, documentId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Failed to load activity');
    }
    return result.data;
  }
}
