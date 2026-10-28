import React from 'react';
import { act, renderHook, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { useDocuments } from '../useDocuments';
import { AuthProvider } from '../../context/AuthContext';
import * as featureFlags from '../../config/features';
import type { Document, DocumentFolder } from '../../types/documents';

const mockDocumentService = {
  getDocuments: vi.fn(),
  getFolders: vi.fn(),
  uploadDocument: vi.fn(),
  createFolder: vi.fn(),
  moveToFolder: vi.fn(),
  generatePublicLink: vi.fn(),
  revokePublicLink: vi.fn(),
  sendForSignature: vi.fn(),
};

vi.mock('../../services/document-service', () => ({
  DocumentService: vi.fn().mockImplementation(() => mockDocumentService),
}));

vi.mock('../../context/AuthContext', () => {
  const crmUser = {
    id: 'user-1',
    uid: 'user-1',
    businessId: 'biz-1',
    displayName: 'Test User',
    role: 'admin',
    email: 'test@example.com',
    teamIds: [],
    managedTeamIds: [],
  };
  return {
    useAuth: () => ({ crmUser }),
    AuthProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
  };
});

describe('useDocuments hook', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <AuthProvider>{children}</AuthProvider>
  );

  const baseDocument: Document = {
    id: 'doc-1',
    businessId: 'biz-1',
    name: 'Contract',
    documentType: 'contract',
    status: 'draft',
    fileName: 'contract.pdf',
    fileType: 'application/pdf',
    fileSize: 1000,
    storageUrl: 'businesses/biz-1/documents/doc-1/original/contract.pdf',
    version: 1,
    isLatestVersion: true,
    requiresSignature: false,
    uploadedById: 'user-1',
    uploadedByName: 'Test User',
    ownerId: 'user-1',
    ownerName: 'Test User',
    isPublic: false,
    accessUserIds: ['user-1'],
    createdAt: new Date(),
  };

  const baseFolder: DocumentFolder = {
    id: 'folder-1',
    businessId: 'biz-1',
    name: 'Root',
    ownerId: 'user-1',
    isShared: false,
    createdAt: new Date(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(featureFlags, 'getFeatureFlags').mockReturnValue({
      enableDocuments: true,
      enableESignature: true,
    } as ReturnType<typeof featureFlags.getFeatureFlags>);

    mockDocumentService.getDocuments.mockResolvedValue([baseDocument]);
    mockDocumentService.getFolders.mockResolvedValue([baseFolder]);
    mockDocumentService.uploadDocument.mockResolvedValue(baseDocument);
    mockDocumentService.createFolder.mockResolvedValue(baseFolder);
    mockDocumentService.generatePublicLink.mockResolvedValue(undefined);
    mockDocumentService.revokePublicLink.mockResolvedValue(undefined);
    mockDocumentService.sendForSignature.mockResolvedValue({ ...baseDocument, status: 'pending_signature' });
  });

  it('loads documents and folders on mount when enabled', async () => {
    const { result, unmount } = renderHook(() => useDocuments(), { wrapper });

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(mockDocumentService.getDocuments).toHaveBeenCalled();
    expect(mockDocumentService.getFolders).toHaveBeenCalled();
    expect(result.current.documents[0].id).toBe(baseDocument.id);
    expect(result.current.folders[0].id).toBe(baseFolder.id);
    unmount();
  });

  it('sends for signature calls service correctly', async () => {
    const { result, unmount } = renderHook(() => useDocuments(), { wrapper });

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    // Verify sendForSignature mock is callable and returns expected result
    const signers = [{ name: 'Signer', email: 'signer@example.com', role: 'client' as const, order: 1 }];

    await act(async () => {
      const doc = await result.current.sendForSignature(baseDocument.id, signers);
      expect(doc?.status).toBe('pending_signature');
    });

    expect(mockDocumentService.sendForSignature).toHaveBeenCalledWith(
      expect.any(Object),
      baseDocument.id,
      signers,
      undefined
    );
    unmount();
  });
});
