import { getAuth } from 'firebase/auth';
import type { SecurityContext } from '../data/repositories/repository-types';
import { getFunctionsBaseUrl } from './functions-base-url';

interface UploadRequestPayload {
  name: string;
  description?: string;
  documentType: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  folderId?: string | null;
  tags?: string[];
  associatedEntityType?: 'deal' | 'lead' | 'client';
  associatedEntityId?: string;
  previousVersionId?: string;
  version?: number;
  requiresSignature?: boolean;
}

export interface UploadPlan {
  documentId: string;
  uploadUrl: string;
  uploadHeaders: Record<string, string>;
  storagePath: string;
  expiresAt: string;
}

interface SendForSignatureRequest {
  documentId: string;
  signers: Array<Record<string, unknown>>;
  message?: string;
  expiresInDays?: number;
}

interface SendForSignatureResponse {
  success?: boolean;
  signatureRequestId?: string;
  requestId?: string;
  envelopeId?: string;
}

export class DocumentFunctionsClient {
  private async getIdToken(): Promise<string> {
    const auth = getAuth();
    const user = auth.currentUser;
    if (!user) {
      throw new Error('User not authenticated');
    }
    return user.getIdToken();
  }

  private ensureBaseUrl(): string {
    const baseUrl = getFunctionsBaseUrl();
    if (!baseUrl) {
      throw new Error('Functions base URL is not configured');
    }
    return baseUrl;
  }

  async requestUpload(context: SecurityContext, payload: UploadRequestPayload): Promise<UploadPlan> {
    const baseUrl = this.ensureBaseUrl();
    const idToken = await this.getIdToken();

    const response = await fetch(`${baseUrl}/getDocumentUploadUrl`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
        'X-Business-Id': context.businessId,
      },
      body: JSON.stringify({ ...payload, businessId: context.businessId }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = data?.error?.message || 'Failed to prepare upload';
      throw new Error(message);
    }

    const { documentId, uploadUrl, uploadHeaders, storagePath, expiresAt } = data as UploadPlan;
    if (!documentId || !uploadUrl || !uploadHeaders || !storagePath) {
      throw new Error('Upload response missing fields');
    }

    return { documentId, uploadUrl, uploadHeaders, storagePath, expiresAt };
  }

  async uploadFile(uploadUrl: string, file: File | Blob, headers: Record<string, string>): Promise<void> {
    const response = await fetch(uploadUrl, {
      method: 'PUT',
      headers,
      body: file as Blob,
    });

    if (!response.ok) {
      throw new Error('Upload failed');
    }
  }

  async getDownloadUrl(context: SecurityContext, documentId: string): Promise<string> {
    const baseUrl = this.ensureBaseUrl();
    const idToken = await this.getIdToken();

    const response = await fetch(`${baseUrl}/getDocumentDownloadUrl`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
        'X-Business-Id': context.businessId,
      },
      body: JSON.stringify({ documentId, businessId: context.businessId }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = data?.error?.message || 'Failed to generate download URL';
      throw new Error(message);
    }

    if (!data.url) {
      throw new Error('Download URL missing in response');
    }

    return data.url as string;
  }

  async sendForSignature(
    context: SecurityContext,
    payload: SendForSignatureRequest
  ): Promise<{ signatureRequestId?: string }> {
    const baseUrl = this.ensureBaseUrl();
    const idToken = await this.getIdToken();

    const response = await fetch(`${baseUrl}/sendDocumentForSignature`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
        'X-Business-Id': context.businessId,
      },
      body: JSON.stringify({ ...payload, businessId: context.businessId }),
    });

    const data: SendForSignatureResponse = await response.json().catch(() => ({}));

    if (!response.ok) {
      const message = (data as any)?.error?.message || 'Failed to send for signature';
      throw new Error(message);
    }

    const signatureRequestId = data.signatureRequestId || data.requestId || data.envelopeId;
    return { signatureRequestId };
  }

  async generateFromTemplate(
    context: SecurityContext,
    payload: {
      templateId: string;
      name: string;
      mergeData: Record<string, string>;
      associatedEntity?: { type: string; id: string };
      signers?: Array<Record<string, unknown>>;
    }
  ): Promise<{ documentId: string; storagePath: string }> {
    const baseUrl = this.ensureBaseUrl();
    const idToken = await this.getIdToken();

    const response = await fetch(`${baseUrl}/generateDocumentFromTemplate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
        'X-Business-Id': context.businessId,
      },
      body: JSON.stringify({ ...payload, businessId: context.businessId }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = data?.error?.message || 'Failed to generate document';
      throw new Error(message);
    }

    if (!data.documentId) {
      throw new Error('Template generation response missing documentId');
    }

    return {
      documentId: data.documentId as string,
      storagePath: data.storagePath as string,
    };
  }
}
