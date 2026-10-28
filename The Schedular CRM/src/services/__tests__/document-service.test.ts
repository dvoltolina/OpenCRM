import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DocumentService } from '../document-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Document, DocumentFolder } from '../../types/documents';
import * as firestoreUtils from '../../data/repositories/firestore-utils';

const sendForSignatureMock = vi.fn();
const requestUploadMock = vi.fn();
const uploadFileMock = vi.fn();
const generateFromTemplateMock = vi.fn();
const getDownloadUrlMock = vi.fn();

const mockDocumentRepo = {
  getDocument: vi.fn(),
  getDocuments: vi.fn(),
  deleteDocument: vi.fn(),
  update: vi.fn(),
  moveToFolder: vi.fn(),
};

const mockActivityRepo = {
  recordActivity: vi.fn(),
  getByDocument: vi.fn(),
};

const mockFolderRepo = {
  createFolder: vi.fn(),
  getByParent: vi.fn(),
};

const mockTemplateRepo = {
  incrementUsage: vi.fn(),
};

vi.mock('../../config/features', () => ({
  getFeatureFlags: vi.fn(() => ({
    enableDocuments: true,
    enableESignature: true,
  })),
}));

vi.mock('../document-functions-client', () => ({
  DocumentFunctionsClient: vi.fn().mockImplementation(() => ({
    requestUpload: requestUploadMock,
    uploadFile: uploadFileMock,
    generateFromTemplate: generateFromTemplateMock,
    getDownloadUrl: getDownloadUrlMock,
    sendForSignature: sendForSignatureMock,
  })),
}));

vi.mock('../../data/repositories/document-repository', () => ({
  getDocumentRepository: () => mockDocumentRepo,
}));

vi.mock('../../data/repositories/document-folder-repository', () => ({
  getDocumentFolderRepository: () => mockFolderRepo,
}));

vi.mock('../../data/repositories/document-template-repository', () => ({
  getDocumentTemplateRepository: () => mockTemplateRepo,
}));

vi.mock('../../data/repositories/document-activity-repository', () => ({
  getDocumentActivityRepository: () => mockActivityRepo,
}));

describe('DocumentService', () => {
  let service: DocumentService;
  let context: SecurityContext;
  let baseDocument: Document;

  beforeEach(() => {
    vi.clearAllMocks();

    context = {
      businessId: 'biz-1',
      userId: 'user-1',
      userName: 'User One',
      userRole: 'admin',
      teamIds: [],
      managedTeamIds: [],
    };

    baseDocument = {
      id: 'doc-1',
      businessId: context.businessId,
      name: 'Contract',
      documentType: 'contract',
      status: 'draft',
      fileName: 'contract.pdf',
      fileType: 'application/pdf',
      fileSize: 1024,
      storageUrl: 'businesses/biz-1/documents/doc-1/original/contract.pdf',
      version: 1,
      isLatestVersion: true,
      requiresSignature: false,
      uploadedById: context.userId,
      uploadedByName: context.userName,
      ownerId: context.userId,
      ownerName: context.userName,
      isPublic: false,
      accessUserIds: [context.userId],
      createdAt: new Date(),
    };

    mockDocumentRepo.getDocument.mockResolvedValue({ success: true, data: baseDocument });
    mockDocumentRepo.getDocuments.mockResolvedValue({ success: true, data: [baseDocument] });
    mockDocumentRepo.deleteDocument.mockResolvedValue({ success: true, data: undefined, error: null });
    mockDocumentRepo.update.mockImplementation(async (_ctx, _id, data) => ({
      success: true,
      data: { ...baseDocument, ...data },
    }));
    mockDocumentRepo.moveToFolder.mockResolvedValue({ success: true, data: { ...baseDocument } });
    mockActivityRepo.recordActivity.mockResolvedValue({ success: true });
    mockFolderRepo.createFolder.mockResolvedValue({
      success: true,
      data: {
        id: 'folder-1',
        businessId: context.businessId,
        name: 'Contracts',
        ownerId: context.userId,
        isShared: false,
        createdAt: new Date(),
      } satisfies DocumentFolder,
    });
    mockTemplateRepo.incrementUsage.mockResolvedValue({ success: true, data: undefined, error: null });
    requestUploadMock.mockResolvedValue({
      documentId: baseDocument.id,
      uploadUrl: 'https://upload.example.com',
      uploadHeaders: { 'Content-Type': 'application/pdf' },
      storagePath: baseDocument.storageUrl,
      expiresAt: new Date().toISOString(),
    });
    uploadFileMock.mockResolvedValue(undefined);
    generateFromTemplateMock.mockResolvedValue({
      documentId: baseDocument.id,
      storagePath: baseDocument.storageUrl,
    });
    getDownloadUrlMock.mockResolvedValue('https://download.example.com/doc.pdf');
    sendForSignatureMock.mockResolvedValue({ signatureRequestId: 'req-123' });

    service = new DocumentService();
  });

  it('uploads document via signed URL and fetches created metadata', async () => {
    const file = {
      name: 'contract.pdf',
      size: 2048,
      type: 'application/pdf',
    } as File;

    const result = await service.uploadDocument(context, file, {
      name: 'New Contract',
      documentType: 'contract',
      description: 'Initial draft',
      associatedEntity: { type: 'deal', id: 'deal-42' },
      folderId: 'folder-1',
      tags: ['vip'],
    });

    expect(requestUploadMock).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        name: 'New Contract',
        description: 'Initial draft',
        documentType: 'contract',
        fileName: 'contract.pdf',
        fileType: 'application/pdf',
        fileSize: 2048,
        folderId: 'folder-1',
        tags: ['vip'],
        associatedEntityType: 'deal',
        associatedEntityId: 'deal-42',
        version: 1,
        requiresSignature: false,
      })
    );
    expect(uploadFileMock).toHaveBeenCalledWith(
      'https://upload.example.com',
      file,
      expect.objectContaining({ 'Content-Type': 'application/pdf' })
    );
    expect(mockDocumentRepo.getDocument).toHaveBeenCalledWith(context, baseDocument.id);
    expect(result.id).toBe(baseDocument.id);
  });

  it('creates a new version when updating a document', async () => {
    const updatedDoc = { ...baseDocument, id: 'doc-2', version: 2, previousVersionId: baseDocument.id };
    mockDocumentRepo.getDocument
      .mockResolvedValueOnce({ success: true, data: baseDocument })
      .mockResolvedValueOnce({ success: true, data: updatedDoc });
    requestUploadMock.mockResolvedValueOnce({
      documentId: updatedDoc.id,
      uploadUrl: 'https://upload.example.com/v2',
      uploadHeaders: {},
      storagePath: updatedDoc.storageUrl,
      expiresAt: new Date().toISOString(),
    });

    const file = {
      name: 'contract-v2.pdf',
      size: 4096,
      type: 'application/pdf',
    } as File;

    const result = await service.updateDocument(context, baseDocument.id, file, { description: 'Revision' });

    expect(requestUploadMock).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        previousVersionId: baseDocument.id,
        version: 2,
        description: 'Revision',
      })
    );
    expect(uploadFileMock).toHaveBeenCalledWith('https://upload.example.com/v2', file, expect.any(Object));
    expect(result.version).toBe(2);
    expect(result.previousVersionId).toBe(baseDocument.id);
  });

  it('generates public link tokens and stores expiration with activity log', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2025-01-01T00:00:00.000Z'));
    const idSpy = vi
      .spyOn(firestoreUtils, 'generateId')
      .mockReturnValueOnce('token-a')
      .mockReturnValueOnce('token-b');

    const link = await service.generatePublicLink(context, baseDocument.id, 3);

    const updatePayload = mockDocumentRepo.update.mock.calls[0]?.[2];
    expect(updatePayload).toMatchObject({
      isPublic: true,
      publicLinkToken: 'token-a-token-b',
    });
    expect(updatePayload.publicLinkExpiresAt?.getTime()).toBe(
      new Date('2025-01-04T00:00:00.000Z').getTime()
    );
    expect(link.url).toBe('token-a-token-b');
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        documentId: baseDocument.id,
        activityType: 'updated',
        details: expect.objectContaining({ publicLinkExpiresAt: expect.any(Date) }),
      })
    );
    vi.useRealTimers();
    idSpy.mockRestore();
  });

  it('creates documents from template with merge data and increments usage', async () => {
    const result = await service.createFromTemplate(context, 'tpl-1', {
      name: 'Proposal',
      mergeData: { client_name: 'Acme' },
      associatedEntity: { type: 'deal', id: 'deal-99' },
      signers: [{ name: 'Signer', email: 'signer@example.com', role: 'client', order: 1 }],
    });

    expect(generateFromTemplateMock).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        templateId: 'tpl-1',
        name: 'Proposal',
        mergeData: { client_name: 'Acme' },
      })
    );
    expect(mockTemplateRepo.incrementUsage).toHaveBeenCalledWith(context, 'tpl-1');
    expect(result.id).toBe(baseDocument.id);
  });

  it('records activity when deleting documents', async () => {
    await service.deleteDocument(context, baseDocument.id);

    expect(mockDocumentRepo.deleteDocument).toHaveBeenCalledWith(context, baseDocument.id);
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        documentId: baseDocument.id,
        activityType: 'updated',
        details: { action: 'deleted' },
      })
    );
  });

  it('creates folders with parent association and owner defaults', async () => {
    const folder = await service.createFolder(context, 'Contracts', 'parent-1');

    expect(mockFolderRepo.createFolder).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        name: 'Contracts',
        parentFolderId: 'parent-1',
        ownerId: context.userId,
        businessId: context.businessId,
        isShared: false,
      })
    );
    expect(folder.name).toBe('Contracts');
  });

  it('delegates sendForSignature to Cloud Functions and refreshes the document', async () => {
    const result = await service.sendForSignature(
      context,
      baseDocument.id,
      [{ name: 'Signer', email: 'signer@example.com', role: 'client', order: 1 }],
      { message: 'Please sign', expiresInDays: 5 }
    );

    expect(sendForSignatureMock).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: context.businessId }),
      expect.objectContaining({
        documentId: baseDocument.id,
        message: 'Please sign',
        expiresInDays: 5,
      })
    );
    expect(mockDocumentRepo.getDocument).toHaveBeenCalledWith(context, baseDocument.id);
    expect(result.id).toBe(baseDocument.id);
  });

  it('throws when no signers are provided', async () => {
    await expect(
      service.sendForSignature(context, baseDocument.id, [], { message: 'missing signers' })
    ).rejects.toThrow('At least one signer is required');
    expect(sendForSignatureMock).not.toHaveBeenCalled();
  });
});
