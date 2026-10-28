import { useEffect, useMemo, useState } from 'react';
import { getFeatureFlags } from '../config/features';
import { Button, Card, EmptyState, PageHeader, PageLayout } from '../components/ui';
import type { Document } from '../types/documents';
import { DocumentUploader } from '../components/documents/DocumentUploader';
import { DocumentList } from '../components/documents/DocumentList';
import { DocumentPreview } from '../components/documents/DocumentPreview';
import { DocumentFolderTree } from '../components/documents/DocumentFolder';
import { SignatureRequestForm } from '../components/documents/SignatureRequestForm';
import { SignatureStatus } from '../components/documents/SignatureStatus';
import { PublicLinkManager } from '../components/documents/PublicLinkManager';
import { useDocuments } from '../hooks';
import './styles/documents-page.css';

export function DocumentsPage() {
  const features = getFeatureFlags();
  const [preview, setPreview] = useState<Document | null>(null);
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const [activeFolderId, setActiveFolderId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isSendingSignature, setIsSendingSignature] = useState(false);
  const {
    documents,
    folders,
    isLoading,
    isUploading,
    error,
    uploadDocument,
    createFolder,
    refreshDocuments,
    generatePublicLink,
    revokePublicLink,
    sendForSignature,
  } = useDocuments({
    folderId: activeFolderId,
  });

  const canUseDocuments = useMemo(() => features.enableDocuments, [features.enableDocuments]);
  const canUseESignature = useMemo(
    () => features.enableDocuments && features.enableESignature,
    [features.enableDocuments, features.enableESignature]
  );
  const activeFolder = useMemo(
    () => folders.find((folder) => folder.id === activeFolderId) ?? null,
    [activeFolderId, folders]
  );
  const signatureQueueCount = useMemo(
    () =>
      documents.filter(
        (document) =>
          document.status === 'pending_signature' ||
          (document.requiresSignature && document.status !== 'signed')
      ).length,
    [documents]
  );

  useEffect(() => {
    if (!documents.length) {
      setSelectedDocument(null);
      return;
    }
    if (selectedDocument) {
      const updated = documents.find((doc) => doc.id === selectedDocument.id);
      if (updated) {
        setSelectedDocument(updated);
        return;
      }
    }
    setSelectedDocument(documents[0]);
  }, [documents, selectedDocument]);

  if (!canUseDocuments) {
    return (
      <PageLayout width="wide" className="documents-page">
        <PageHeader
          eyebrow="Document Hub"
          title="Documents"
          subtitle="Store document metadata, links, and signature operations for this workspace."
        />
        <Card padding="lg">
          <EmptyState
            eyebrow="Disabled"
            title="Documents are disabled for this workspace"
            description="Enable the documents feature flag before using uploads, folders, sharing, or e-signature flows."
          />
        </Card>
      </PageLayout>
    );
  }

  const handleUpload = async (file: File) => {
    await uploadDocument(file, {
      name: file.name,
      documentType: 'attachment',
      folderId: activeFolderId,
    });
  };

  const handleCreateFolder = async (parentId?: string) => {
    const name = window.prompt('Folder name');
    if (!name) return;
    await createFolder(name.trim(), parentId);
  };

  const handleSendForSignature = async (
    signers: Parameters<typeof sendForSignature>[1]
  ): Promise<void> => {
    if (!selectedDocument) {
      setActionError('Select a document before sending for signature.');
      return;
    }
    setActionError(null);
    setIsSendingSignature(true);
    try {
      await sendForSignature(selectedDocument.id, signers);
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to send for signature');
    } finally {
      setIsSendingSignature(false);
    }
  };

  const handlePublicLinkGenerate = async (days?: number) => {
    if (!selectedDocument) {
      setActionError('Select a document to generate a public link.');
      return;
    }
    setActionError(null);
    await generatePublicLink(selectedDocument.id, days);
  };

  const handlePublicLinkRevoke = async () => {
    if (!selectedDocument) {
      setActionError('Select a document to revoke its public link.');
      return;
    }
    setActionError(null);
    await revokePublicLink(selectedDocument.id);
  };

  return (
    <PageLayout width="wide" className="documents-page">
      <PageHeader
        eyebrow="Document Hub"
        title="Documents"
        subtitle="Upload files, organize them into folders, and manage sharing or signature workflows from one workspace."
        actions={(
          <Button variant="secondary" onClick={refreshDocuments} disabled={isLoading || isUploading}>
            Refresh
          </Button>
        )}
      />

      <Card className="documents-page__hero" padding="lg" tone="accent">
        <div className="documents-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current Focus</p>
          <h2>{activeFolder ? activeFolder.name : 'All documents'}</h2>
          <p>
            Keep proposals, contracts, and signed files organized by folder while tracking link
            access and signature progress in the same workspace.
          </p>
        </div>
        <div className="documents-page__hero-stats">
          <div>
            <span>Documents</span>
            <strong>{documents.length}</strong>
          </div>
          <div>
            <span>Folders</span>
            <strong>{folders.length}</strong>
          </div>
          <div>
            <span>Signature queue</span>
            <strong>{signatureQueueCount}</strong>
          </div>
        </div>
      </Card>

      {(actionError || error) ? (
        <Card className="documents-page__error" padding="md">
          <span>{actionError || error?.message}</span>
        </Card>
      ) : null}

      <section className="documents-page__layout">
        <Card className="documents-page__sidebar" padding="lg" tone="subtle">
          <DocumentFolderTree
            folders={folders}
            activeFolderId={activeFolderId}
            onSelect={(folderId) => setActiveFolderId(folderId)}
            onCreateFolder={handleCreateFolder}
          />
        </Card>

        <div className="documents-page__main-column">
          <Card className="documents-page__uploader-card" padding="lg" tone="subtle">
            <div className="documents-page__section-copy">
              <p className="ui-empty-state__eyebrow">Upload</p>
              <h3>Add a new file</h3>
              <p>Drag in a file or browse locally to attach it to the current folder context.</p>
            </div>
            <DocumentUploader onUpload={handleUpload} folderId={activeFolderId ?? undefined} />
          </Card>

          <Card className="documents-page__list-card" padding="lg">
            <DocumentList
              documents={documents}
              isLoading={isLoading || isUploading}
              onSelect={(doc) => {
                setSelectedDocument(doc);
                setActionError(null);
              }}
              onPreview={(doc) => {
                setSelectedDocument(doc);
                setPreview(doc);
              }}
              onRefresh={refreshDocuments}
            />
          </Card>
        </div>

        <Card className="documents-page__actions" padding="lg">
          {!selectedDocument ? (
            <EmptyState
              eyebrow="Inspector"
              title="Select a document"
              description="Choose a file from the list to review ownership, preview it, manage public links, and handle signature requests."
            />
          ) : (
            <div className="documents-page__inspector">
              <div className="document-actions-card">
                <div className="document-actions-header">
                  <p className="ui-empty-state__eyebrow">{selectedDocument.documentType}</p>
                  <h4>{selectedDocument.name}</h4>
                  {selectedDocument.description ? (
                    <p className="muted">{selectedDocument.description}</p>
                  ) : null}
                </div>
                <div className="document-actions-meta">
                  <p>Owner: {selectedDocument.ownerName}</p>
                  <p>Version: v{selectedDocument.version}</p>
                  <p>Status: {selectedDocument.status}</p>
                </div>
                <div className="document-actions-buttons">
                  <Button variant="secondary" size="sm" onClick={() => setPreview(selectedDocument)}>
                    Preview
                  </Button>
                </div>
              </div>

              <PublicLinkManager
                onGenerate={handlePublicLinkGenerate}
                onRevoke={handlePublicLinkRevoke}
                isLoading={isLoading || isUploading}
                publicLinkToken={selectedDocument.publicLinkToken}
                expiresAt={
                  selectedDocument.publicLinkExpiresAt
                    ? new Date(selectedDocument.publicLinkExpiresAt)
                    : undefined
                }
              />

              {canUseESignature ? (
                <>
                  <SignatureStatus document={selectedDocument} onRefresh={refreshDocuments} />
                  <SignatureRequestForm
                    onSend={handleSendForSignature}
                    isSubmitting={isSendingSignature}
                    defaultMessage="Please review and sign this document."
                  />
                </>
              ) : (
                <div className="signature-status muted">
                  E-signature is disabled in this environment. Enable it to send documents for signature.
                </div>
              )}
            </div>
          )}
        </Card>
      </section>

      {preview ? <DocumentPreview document={preview} onClose={() => setPreview(null)} /> : null}
    </PageLayout>
  );
}
