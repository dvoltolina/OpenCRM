import { render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DocumentsPage } from '../DocumentsPage';

const { featureFlags, useDocumentsMock } = vi.hoisted(() => ({
  featureFlags: {
    enableDocuments: true,
    enableESignature: true,
  },
  useDocumentsMock: vi.fn(),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => featureFlags,
}));

vi.mock('../../hooks', () => ({
  useDocuments: () => useDocumentsMock(),
}));

vi.mock('../../components/documents/DocumentUploader', () => ({
  DocumentUploader: () => <div>Document Uploader</div>,
}));

vi.mock('../../components/documents/DocumentList', () => ({
  DocumentList: ({ documents }: { documents: Array<{ id: string }> }) => (
    <div>Document List {documents.length}</div>
  ),
}));

vi.mock('../../components/documents/DocumentPreview', () => ({
  DocumentPreview: () => <div>Document Preview</div>,
}));

vi.mock('../../components/documents/DocumentFolder', () => ({
  DocumentFolderTree: () => <div>Document Folder Tree</div>,
}));

vi.mock('../../components/documents/PublicLinkManager', () => ({
  PublicLinkManager: () => <div>Public Link Manager</div>,
}));

vi.mock('../../components/documents/SignatureStatus', () => ({
  SignatureStatus: () => <div>Signature Status</div>,
}));

vi.mock('../../components/documents/SignatureRequestForm', () => ({
  SignatureRequestForm: () => <div>Signature Request Form</div>,
}));

describe('DocumentsPage', () => {
  beforeEach(() => {
    featureFlags.enableDocuments = true;
    featureFlags.enableESignature = true;
    useDocumentsMock.mockReturnValue({
      documents: [
        {
          id: 'doc-1',
          businessId: 'business-1',
          name: 'Master Services Agreement',
          documentType: 'contract',
          status: 'pending_signature',
          fileName: 'msa.pdf',
          fileType: 'application/pdf',
          fileSize: 2048,
          storageUrl: '/docs/msa.pdf',
          version: 3,
          isLatestVersion: true,
          requiresSignature: true,
          uploadedById: 'user-1',
          uploadedByName: 'Owner User',
          ownerId: 'user-1',
          ownerName: 'Owner User',
          isPublic: false,
          createdAt: new Date('2026-03-20T09:00:00Z'),
          updatedAt: new Date('2026-03-20T09:00:00Z'),
        },
      ],
      folders: [
        {
          id: 'folder-1',
          businessId: 'business-1',
          name: 'Contracts',
          ownerId: 'user-1',
          isShared: false,
          createdAt: new Date('2026-03-20T09:00:00Z'),
        },
      ],
      isLoading: false,
      isUploading: false,
      error: null,
      uploadDocument: vi.fn(),
      createFolder: vi.fn(),
      refreshDocuments: vi.fn(),
      generatePublicLink: vi.fn(),
      revokePublicLink: vi.fn(),
      sendForSignature: vi.fn(),
    });
  });

  it('renders the disabled state when document features are off', () => {
    featureFlags.enableDocuments = false;

    render(<DocumentsPage />);

    expect(screen.getByText('Documents are disabled for this workspace')).toBeInTheDocument();
  });

  it('renders the document workspace and inspector panels', async () => {
    render(<DocumentsPage />);

    expect(screen.getByText('Document Uploader')).toBeInTheDocument();
    expect(screen.getByText('Document List 1')).toBeInTheDocument();
    expect(screen.getByText('Document Folder Tree')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Master Services Agreement')).toBeInTheDocument();
    });

    expect(screen.getByText('Public Link Manager')).toBeInTheDocument();
    expect(screen.getByText('Signature Status')).toBeInTheDocument();
    expect(screen.getByText('Signature Request Form')).toBeInTheDocument();
  });
});
