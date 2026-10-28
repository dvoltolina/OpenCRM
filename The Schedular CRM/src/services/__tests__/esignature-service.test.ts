import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ESignatureService } from '../esignature-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Document } from '../../types/documents';
import * as features from '../../config/features';

const mockDocumentRepo = {
  getDocument: vi.fn(),
  update: vi.fn(),
  getBySignatureRequestId: vi.fn(),
};

const mockActivityRepo = {
  recordActivity: vi.fn(),
};

const mockStoreSignedDocument = vi.fn();

const mockProvider = {
  name: 'MockESign',
  sendForSignature: vi.fn(),
  getSignatureStatus: vi.fn(),
  voidSignatureRequest: vi.fn(),
  downloadSignedDocument: vi.fn(),
};

vi.mock('../../data/repositories/document-repository', () => ({
  getDocumentRepository: () => mockDocumentRepo,
}));

vi.mock('../../data/repositories/document-activity-repository', () => ({
  getDocumentActivityRepository: () => mockActivityRepo,
}));

vi.mock('../cloud-functions-integration', () => ({
  storeSignedDocument: (...args: unknown[]) => mockStoreSignedDocument(...args),
}));

describe('ESignatureService', () => {
  let service: ESignatureService;
  let context: SecurityContext;
  let baseDocument: Document;

  beforeEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();

    service = new ESignatureService(mockProvider as any);
    (mockProvider as any).validateWebhookSignature = undefined;
    context = {
      businessId: 'biz-123',
      userId: 'user-1',
      userName: 'Test User',
      userRole: 'admin',
      teamIds: ['team-1'],
    };

    baseDocument = {
      id: 'doc-1',
      businessId: context.businessId,
      name: 'Contract',
      documentType: 'contract',
      status: 'draft',
      description: 'Test',
      fileName: 'contract.pdf',
      fileType: 'application/pdf',
      fileSize: 1024,
      storageUrl: 'businesses/biz-123/documents/doc-1/contract.pdf',
      version: 1,
      isLatestVersion: true,
      requiresSignature: true,
      signers: [
        {
          id: 'signer-1',
          name: 'Signer One',
          email: 'one@example.com',
          role: 'client',
          order: 1,
          status: 'pending',
        },
      ],
      uploadedById: context.userId,
      uploadedByName: context.userName,
      ownerId: context.userId,
      ownerName: context.userName,
      isPublic: false,
      accessUserIds: [context.userId],
      createdAt: new Date('2025-01-01'),
    };

    vi.spyOn(features, 'getFeatureFlags').mockReturnValue({ enableESignature: true } as any);

    mockDocumentRepo.getDocument.mockResolvedValue({ success: true, data: { ...baseDocument } });
    mockDocumentRepo.getBySignatureRequestId.mockResolvedValue({
      success: true,
      data: { ...baseDocument, signatureRequestId: 'req-123', status: 'pending_signature' },
    });
    mockDocumentRepo.update.mockImplementation(async (_ctx, _id, data) => ({
      success: true,
      data: { ...baseDocument, ...data },
    }));
    mockActivityRepo.recordActivity.mockResolvedValue({ success: true, data: undefined });

    mockProvider.sendForSignature.mockResolvedValue('req-123');
    mockProvider.getSignatureStatus.mockResolvedValue({
      status: 'pending',
      signerStatuses: [],
    });
    mockProvider.voidSignatureRequest.mockResolvedValue(undefined);
    mockStoreSignedDocument.mockResolvedValue({ success: true });
  });

  it('sends a document for signature and updates metadata', async () => {
    const result = await service.sendForSignature(
      context,
      baseDocument.id,
      [
        {
          name: 'Signer One',
          email: 'one@example.com',
          role: 'client',
          order: 1,
        },
      ],
      { expiresInDays: 3 }
    );

    expect(mockProvider.sendForSignature).toHaveBeenCalledWith(
      expect.objectContaining({ id: baseDocument.id }),
      expect.any(Array)
    );
    expect(mockDocumentRepo.update).toHaveBeenCalledWith(
      context,
      baseDocument.id,
      expect.objectContaining({
        status: 'pending_signature',
        signatureRequestId: 'req-123',
        requiresSignature: true,
      })
    );
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        businessId: context.businessId,
        documentId: baseDocument.id,
        activityType: 'sent_for_signature',
      })
    );
    expect(result.status).toBe('pending_signature');
  });

  it('marks document as signed when provider reports success', async () => {
    mockDocumentRepo.getDocument.mockResolvedValue({
      success: true,
      data: { ...baseDocument, status: 'pending_signature', signatureRequestId: 'req-123' },
    });
    mockProvider.getSignatureStatus.mockResolvedValue({
      status: 'signed',
      signedDocumentUrl: 'https://signed.example.com/doc.pdf',
      signerStatuses: [
        { email: 'one@example.com', status: 'signed', signedAt: new Date('2025-01-02') },
      ],
    });

    const status = await service.checkSignatureStatus(context, baseDocument.id);

    expect(status).toBe('signed');
    expect(mockDocumentRepo.update).toHaveBeenCalledWith(
      context,
      baseDocument.id,
      expect.objectContaining({
        status: 'signed',
        signedDocumentUrl: 'https://signed.example.com/doc.pdf',
      })
    );
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      context,
      expect.objectContaining({ activityType: 'signed' })
    );
  });

  it('resends to a signer and updates request metadata', async () => {
    mockDocumentRepo.getDocument.mockResolvedValueOnce({
      success: true,
      data: {
        ...baseDocument,
        status: 'pending_signature',
        signatureRequestId: 'req-old',
        signedDocumentUrl: 'https://existing.example/signed.pdf',
      },
    });
    mockProvider.sendForSignature.mockResolvedValueOnce('req-new');

    await service.resendToSigner(context, baseDocument.id, 'one@example.com');

    expect(mockProvider.sendForSignature).toHaveBeenCalledWith(
      expect.objectContaining({ id: baseDocument.id }),
      expect.arrayContaining([
        expect.objectContaining({
          email: 'one@example.com',
          status: 'pending',
          signedAt: undefined,
          declinedReason: undefined,
        }),
      ])
    );
    expect(mockDocumentRepo.update).toHaveBeenCalledWith(
      context,
      baseDocument.id,
      expect.objectContaining({
        status: 'pending_signature',
        signatureRequestId: 'req-new',
        signedDocumentUrl: undefined,
        requiresSignature: true,
      })
    );
    const updatePayload = mockDocumentRepo.update.mock.calls[0][2];
    const refreshedSigner = (updatePayload.signers || []).find(
      (signer: any) => signer.email === 'one@example.com'
    );
    expect(refreshedSigner.status).toBe('pending');
    expect(refreshedSigner.signedAt).toBeUndefined();
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        details: expect.objectContaining({ requestId: 'req-new', resendTo: 'one@example.com' }),
      })
    );
  });

  it('persists signed document via Cloud Function on webhook', async () => {
    const payload = {
      businessId: context.businessId,
      signatureRequestId: 'req-123',
      status: 'signed',
      signedDocumentUrl: 'https://provider.example/signed.pdf',
      signerStatuses: [{ email: 'one@example.com', status: 'signed' as const }],
    };

    await service.handleWebhook(payload);

    expect(mockStoreSignedDocument).toHaveBeenCalledWith(
      expect.objectContaining({
        businessId: context.businessId,
        documentId: baseDocument.id,
        signatureRequestId: 'req-123',
        status: 'signed',
        signedDocumentUrl: 'https://provider.example/signed.pdf',
      })
    );
  });

  it('rejects webhook when signature validation fails', async () => {
    (mockProvider as any).validateWebhookSignature = vi.fn().mockResolvedValue(false);

    await expect(
      service.handleWebhook({ businessId: context.businessId, signatureRequestId: 'req-123' })
    ).rejects.toThrow('Invalid webhook signature');

    expect(mockStoreSignedDocument).not.toHaveBeenCalled();
  });

  it('handles webhook payload and updates document via signatureRequestId', async () => {
    const payload = {
      businessId: context.businessId,
      signatureRequestId: 'req-123',
      status: 'declined',
      signerStatuses: [{ email: 'one@example.com', status: 'declined' as const }],
      actorEmail: 'signer@example.com',
    };

    await service.handleWebhook(payload);

    expect(mockProvider.getSignatureStatus).not.toHaveBeenCalled();
    expect(mockDocumentRepo.getBySignatureRequestId).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: context.businessId }),
      'req-123'
    );
    expect(mockDocumentRepo.update).toHaveBeenCalledWith(
      expect.objectContaining({ userRole: 'owner' }),
      baseDocument.id,
      expect.objectContaining({ status: 'voided' })
    );
    expect(mockActivityRepo.recordActivity).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: context.businessId }),
      expect.objectContaining({ activityType: 'declined' })
    );
    expect(mockStoreSignedDocument).not.toHaveBeenCalled();
  });
});
