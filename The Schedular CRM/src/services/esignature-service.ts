/**
 * E-Signature Service
 * Provider-agnostic wrapper for sending documents for signature and tracking status.
 */

import { getFeatureFlags } from '../config/features';
import type { SecurityContext } from '../data/repositories/repository-types';
import type {
  Document,
  DocumentActivity,
  DocumentSigner,
  DocumentStatus,
  SignatureStatus,
} from '../types/documents';
import { getDocumentRepository } from '../data/repositories/document-repository';
import { getDocumentActivityRepository } from '../data/repositories/document-activity-repository';
import { generateId } from '../data/repositories/firestore-utils';
import { storeSignedDocument } from './cloud-functions-integration';

export interface SignatureRequestStatus {
  status: SignatureStatus;
  signedDocumentUrl?: string;
  signerStatuses?: Array<{
    email: string;
    status: SignatureStatus;
    signedAt?: Date;
    declinedReason?: string;
  }>;
}

type WebhookPayload = {
  businessId?: string;
  documentId?: string;
  signatureRequestId?: string;
  requestId?: string;
  status?: SignatureStatus;
  signedDocumentUrl?: string;
  signerStatuses?: SignatureRequestStatus['signerStatuses'];
  actorEmail?: string;
  actorName?: string;
};

// Abstraction layer for e-signature providers (DocuSign, HelloSign, etc.)
export interface ESignatureProvider {
  name: string;
  sendForSignature(document: Document, signers: DocumentSigner[]): Promise<string>; // Returns request ID
  getSignatureStatus(requestId: string): Promise<SignatureRequestStatus>;
  voidSignatureRequest(requestId: string): Promise<void>;
  downloadSignedDocument(requestId: string): Promise<Buffer>;
  validateWebhookSignature?(
    payload: unknown,
    headers?: Record<string, string | undefined>
  ): Promise<boolean>;
}

function ensureEnabled(): void {
  const { enableESignature } = getFeatureFlags();
  if (!enableESignature) {
    throw new Error('E-signature feature is disabled');
  }
}

function toDocumentSigners(signers: Array<Omit<DocumentSigner, 'id' | 'status'>>): DocumentSigner[] {
  return signers.map((signer, idx) => ({
    ...signer,
    id: generateId(),
    status: 'pending',
    order: signer.order ?? idx + 1,
  }));
}

function normalizeSignerStatuses(
  statuses?: SignatureRequestStatus['signerStatuses']
): SignatureRequestStatus['signerStatuses'] {
  if (!statuses) return undefined;
  return statuses.map((signer) => ({
    ...signer,
    signedAt: signer.signedAt ? new Date(signer.signedAt) : undefined,
  }));
}

function mapSignatureStatusToDocumentStatus(
  currentStatus: DocumentStatus,
  signatureStatus: SignatureStatus
): DocumentStatus {
  switch (signatureStatus) {
    case 'signed':
      return 'signed';
    case 'declined':
      return 'voided';
    case 'expired':
      return 'expired';
    case 'pending':
      return currentStatus === 'draft' ? 'pending_signature' : currentStatus;
    default:
      return currentStatus;
  }
}

function signatureStatusToActivity(signatureStatus: SignatureStatus): DocumentActivity['activityType'] | null {
  if (signatureStatus === 'signed') return 'signed';
  if (signatureStatus === 'declined') return 'declined';
  if (signatureStatus === 'expired') return 'expired';
  return null;
}

export class ESignatureService {
  private provider: ESignatureProvider | null;
  private documentRepo = getDocumentRepository();
  private activityRepo = getDocumentActivityRepository();

  constructor(provider?: ESignatureProvider) {
    this.provider = provider || null;
  }

  setProvider(provider: ESignatureProvider): void {
    this.provider = provider;
  }

  private requireProvider(): ESignatureProvider {
    if (!this.provider) {
      throw new Error('E-signature provider not configured');
    }
    return this.provider;
  }

  private buildSystemContext(businessId: string): SecurityContext {
    return {
      businessId,
      userId: 'system-esign',
      userName: 'ESignature Webhook',
      userRole: 'owner',
      teamIds: [],
      managedTeamIds: [],
    };
  }

  private mergeSignerStatuses(
    existing: DocumentSigner[] | undefined,
    updates?: SignatureRequestStatus['signerStatuses']
  ): DocumentSigner[] {
    if (!updates || updates.length === 0) {
      return existing || [];
    }

    if (!existing || existing.length === 0) {
      return updates.map((signer, idx) => ({
        id: generateId(),
        name: signer.email,
        email: signer.email,
        role: 'signer',
        order: idx + 1,
        status: signer.status,
        signedAt: signer.signedAt,
        declinedReason: signer.declinedReason,
      }));
    }

    return existing.map((signer) => {
      const match = updates.find((update) => update.email === signer.email);
      if (!match) return signer;
      return {
        ...signer,
        status: match.status,
        signedAt: match.signedAt ?? signer.signedAt,
        declinedReason: match.declinedReason ?? signer.declinedReason,
      };
    });
  }

  private async applySignatureStatus(
    context: SecurityContext,
    document: Document,
    status: SignatureRequestStatus,
    actor?: { actorEmail?: string; actorName?: string }
  ): Promise<Document> {
    const mergedSigners = this.mergeSignerStatuses(document.signers, status.signerStatuses);
    const nextStatus = mapSignatureStatusToDocumentStatus(document.status, status.status);
    const updateResult = await this.documentRepo.update(context, document.id, {
      status: nextStatus,
      signers: mergedSigners,
      requiresSignature: true,
      signedDocumentUrl: status.signedDocumentUrl ?? document.signedDocumentUrl,
      signedAt: status.status === 'signed' ? document.signedAt ?? new Date() : document.signedAt,
    });

    if (!updateResult.success) {
      throw new Error(updateResult.error?.message || 'Failed to update document signature status');
    }

    const activityType = signatureStatusToActivity(status.status);
    if (activityType) {
      await this.activityRepo.recordActivity(context, {
        businessId: context.businessId,
        documentId: document.id,
        activityType,
        occurredAt: new Date(),
        actorId: context.userId,
        actorEmail: actor?.actorEmail,
        actorName: actor?.actorName ?? context.userName,
      });
    }

    return updateResult.data;
  }

  private normalizeWebhookPayload(payload: unknown): WebhookPayload {
    if (!payload || typeof payload !== 'object') {
      throw new Error('Invalid webhook payload');
    }

    const data = payload as Record<string, unknown>;
    const allowedStatuses: SignatureStatus[] = ['pending', 'signed', 'declined', 'expired'];
    const statusValue =
      typeof data.status === 'string' && allowedStatuses.includes(data.status as SignatureStatus)
        ? (data.status as SignatureStatus)
        : undefined;

    const signerStatuses = Array.isArray(data.signerStatuses)
      ? normalizeSignerStatuses(data.signerStatuses as SignatureRequestStatus['signerStatuses'])
      : undefined;

    return {
      businessId: typeof data.businessId === 'string' ? data.businessId : undefined,
      documentId: typeof data.documentId === 'string' ? data.documentId : undefined,
      signatureRequestId:
        typeof data.signatureRequestId === 'string'
          ? data.signatureRequestId
          : typeof data.requestId === 'string'
          ? data.requestId
          : undefined,
      requestId: typeof data.requestId === 'string' ? data.requestId : undefined,
      status: statusValue,
      signedDocumentUrl:
        typeof data.signedDocumentUrl === 'string' ? (data.signedDocumentUrl as string) : undefined,
      actorEmail: typeof data.actorEmail === 'string' ? (data.actorEmail as string) : undefined,
      actorName: typeof data.actorName === 'string' ? (data.actorName as string) : undefined,
      signerStatuses,
    };
  }

  private async resolveDocumentForWebhook(
    context: SecurityContext,
    payload: WebhookPayload
  ): Promise<Document> {
    if (payload.documentId) {
      const docResult = await this.documentRepo.getDocument(context, payload.documentId);
      if (!docResult.success) {
        throw new Error(docResult.error?.message || 'Document not found for webhook');
      }
      return docResult.data;
    }

    const signatureRequestId = payload.signatureRequestId || payload.requestId;
    if (!signatureRequestId) {
      throw new Error('Webhook payload missing signatureRequestId');
    }

    const result = await this.documentRepo.getBySignatureRequestId(context, signatureRequestId);
    if (!result.success) {
      throw new Error(result.error?.message || 'Document not found for signature request');
    }
    return result.data;
  }

  // Send for signature
  async sendForSignature(
    context: SecurityContext,
    documentId: string,
    signers: Omit<DocumentSigner, 'id' | 'status'>[],
    options?: {
      message?: string;
      expiresInDays?: number;
    }
  ): Promise<Document> {
    ensureEnabled();
    const provider = this.requireProvider();

    if (!signers.length) {
      throw new Error('At least one signer is required to send for signature');
    }

    const docResult = await this.documentRepo.getDocument(context, documentId);
    if (!docResult.success) {
      throw new Error(docResult.error?.message || 'Document not found');
    }

    const document = docResult.data;
    if (['signed', 'voided', 'expired', 'final'].includes(document.status)) {
      throw new Error('Document is not eligible for signature');
    }

    const signerList = toDocumentSigners(signers);
    const requestId = await provider.sendForSignature(document, signerList);

    const updateResult = await this.documentRepo.update(context, documentId, {
      status: 'pending_signature',
      requiresSignature: true,
      signatureRequestId: requestId,
      signers: signerList,
      ...(options?.expiresInDays
        ? { expiresAt: new Date(Date.now() + options.expiresInDays * 24 * 60 * 60 * 1000) }
        : {}),
    });

    if (!updateResult.success) {
      throw new Error(updateResult.error?.message || 'Failed to update signature metadata');
    }

    await this.activityRepo.recordActivity(context, {
      businessId: context.businessId,
      documentId,
      activityType: 'sent_for_signature',
      actorId: context.userId,
      actorName: context.userName,
      occurredAt: new Date(),
      details: { provider: provider.name, message: options?.message },
    });

    return updateResult.data;
  }

  // Check status (called by webhook or polling)
  async checkSignatureStatus(context: SecurityContext, documentId: string): Promise<SignatureStatus> {
    ensureEnabled();
    const provider = this.requireProvider();

    const docResult = await this.documentRepo.getDocument(context, documentId);
    if (!docResult.success || !docResult.data.signatureRequestId) {
      throw new Error('Document is not under signature');
    }

    const status = await provider.getSignatureStatus(docResult.data.signatureRequestId);
    const normalizedStatus: SignatureRequestStatus = {
      ...status,
      signerStatuses: normalizeSignerStatuses(status.signerStatuses),
    };

    await this.applySignatureStatus(context, docResult.data, normalizedStatus);
    return normalizedStatus.status;
  }

  // Void signature request
  async voidSignatureRequest(context: SecurityContext, documentId: string): Promise<void> {
    ensureEnabled();
    const provider = this.requireProvider();

    const docResult = await this.documentRepo.getDocument(context, documentId);
    if (!docResult.success || !docResult.data.signatureRequestId) {
      throw new Error('Document is not under signature');
    }

    await provider.voidSignatureRequest(docResult.data.signatureRequestId);
    await this.documentRepo.update(context, documentId, { status: 'voided' });
    await this.activityRepo.recordActivity(context, {
      businessId: context.businessId,
      documentId,
      activityType: 'voided',
      occurredAt: new Date(),
      actorId: context.userId,
      actorName: context.userName,
    });
  }

  // Resend to signer
  async resendToSigner(context: SecurityContext, documentId: string, signerEmail: string): Promise<void> {
    ensureEnabled();
    const provider = this.requireProvider();

    const docResult = await this.documentRepo.getDocument(context, documentId);
    if (!docResult.success || !docResult.data.signatureRequestId) {
      throw new Error('Document is not under signature');
    }

    const existingSigners = docResult.data.signers || [];
    if (!existingSigners.some((signer) => signer.email === signerEmail)) {
      throw new Error('Signer is not associated with this document');
    }

    if (docResult.data.status !== 'pending_signature') {
      throw new Error('Only pending signature requests can be resent');
    }

    const refreshedSigners: DocumentSigner[] = existingSigners.map((signer) =>
      signer.email === signerEmail
        ? { ...signer, status: 'pending' as const, signedAt: undefined, declinedReason: undefined }
        : signer
    );

    const requestId = await provider.sendForSignature(docResult.data, refreshedSigners);
    const updateResult = await this.documentRepo.update(context, documentId, {
      status: 'pending_signature',
      requiresSignature: true,
      signers: refreshedSigners as DocumentSigner[],
      ...(requestId && requestId !== docResult.data.signatureRequestId
        ? {
            signatureRequestId: requestId,
            signedDocumentUrl: undefined,
            signedAt: undefined,
          }
        : {}),
    });

    if (!updateResult.success) {
      throw new Error(updateResult.error?.message || 'Failed to update document after resend');
    }

    await this.activityRepo.recordActivity(context, {
      businessId: context.businessId,
      documentId,
      activityType: 'sent_for_signature',
      occurredAt: new Date(),
      actorId: context.userId,
      actorName: context.userName,
      details: { resendTo: signerEmail, requestId: requestId || docResult.data.signatureRequestId },
    });
  }

  // Handle webhook from e-sign provider
  async handleWebhook(payload: unknown, headers?: Record<string, string | undefined>): Promise<void> {
    ensureEnabled();
    const provider = this.requireProvider();
    const normalizedPayload = this.normalizeWebhookPayload(payload);

    if (provider.validateWebhookSignature) {
      const isValid = await provider.validateWebhookSignature(payload, headers);
      if (!isValid) {
        throw new Error('Invalid webhook signature');
      }
    }

    if (!normalizedPayload.businessId) {
      throw new Error('Webhook payload missing businessId');
    }

    const context = this.buildSystemContext(normalizedPayload.businessId);
    const document = await this.resolveDocumentForWebhook(context, normalizedPayload);
    const signatureRequestId =
      document.signatureRequestId ||
      normalizedPayload.signatureRequestId ||
      normalizedPayload.requestId;

    let providerStatus: SignatureRequestStatus | null = null;
    if (!normalizedPayload.status || normalizedPayload.status === 'pending') {
      if (!signatureRequestId) {
        throw new Error('Missing signature request ID for webhook status lookup');
      }
      providerStatus = await provider.getSignatureStatus(signatureRequestId);
    }

    const combinedStatus: SignatureRequestStatus = {
      status: normalizedPayload.status || providerStatus?.status || 'pending',
      signedDocumentUrl:
        normalizedPayload.signedDocumentUrl ?? providerStatus?.signedDocumentUrl,
      signerStatuses: normalizeSignerStatuses(
        normalizedPayload.signerStatuses || providerStatus?.signerStatuses
      ),
    };

    const updatedDoc = await this.applySignatureStatus(context, document, combinedStatus, {
      actorEmail: normalizedPayload.actorEmail,
      actorName: normalizedPayload.actorName,
    });

    if (combinedStatus.status === 'signed') {
      const signatureRequestId =
        updatedDoc.signatureRequestId ||
        normalizedPayload.signatureRequestId ||
        normalizedPayload.requestId;

      if (!signatureRequestId) {
        throw new Error('Missing signature request ID for signed document persistence');
      }

      const persistResult = await storeSignedDocument({
        businessId: context.businessId,
        documentId: updatedDoc.id,
        signatureRequestId,
        status: combinedStatus.status,
        signedDocumentUrl: combinedStatus.signedDocumentUrl,
      });

      if (!persistResult.success) {
        throw new Error(persistResult.error || 'Failed to persist signed document');
      }
    }
  }
}
