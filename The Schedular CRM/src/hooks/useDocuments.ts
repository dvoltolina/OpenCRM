import { useCallback, useEffect, useMemo, useState } from 'react';
import { getFeatureFlags } from '../config/features';
import { useAuth } from '../context/AuthContext';
import { DocumentService } from '../services/document-service';
import type {
  Document,
  DocumentFolder,
  DocumentSigner,
  DocumentStatus,
  DocumentType,
} from '../types/documents';
import { createSecurityContext } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

export interface UseDocumentsOptions {
  folderId?: string | null;
  entityType?: 'deal' | 'lead' | 'client';
  entityId?: string;
  documentType?: DocumentType;
  status?: DocumentStatus;
  autoLoad?: boolean;
}

export interface UseDocumentsResult {
  documents: Document[];
  folders: DocumentFolder[];
  isLoading: boolean;
  isUploading: boolean;
  error: Error | null;
  refreshDocuments: () => void;
  refreshFolders: () => void;
  uploadDocument: (
    file: File,
    options: {
      name: string;
      documentType: DocumentType;
      description?: string;
      associatedEntity?: { type: 'deal' | 'lead' | 'client'; id: string };
      folderId?: string | null;
      tags?: string[];
    }
  ) => Promise<Document | null>;
  createFolder: (name: string, parentId?: string) => Promise<DocumentFolder | null>;
  moveToFolder: (documentId: string, folderId: string | null) => Promise<void>;
  generatePublicLink: (documentId: string, expiresInDays?: number) => Promise<void>;
  revokePublicLink: (documentId: string) => Promise<void>;
  sendForSignature: (
    documentId: string,
    signers: Array<Omit<DocumentSigner, 'id' | 'status'>>,
    options?: { message?: string; expiresInDays?: number }
  ) => Promise<Document | null>;
}

export function useDocuments(options?: UseDocumentsOptions): UseDocumentsResult {
  const { crmUser } = useAuth();
  const { guardMutation } = useDemoGuard();
  const features = getFeatureFlags();
  const [documents, setDocuments] = useState<Document[]>([]);
  const [folders, setFolders] = useState<DocumentFolder[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const documentService = useMemo(() => new DocumentService(), []);

  const featureEnabled = features.enableDocuments;
  const autoLoad = options?.autoLoad ?? true;

  const getContext = useCallback(() => {
    if (!crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(crmUser);
  }, [crmUser]);

  const refreshDocuments = useCallback(() => setRefreshKey((prev) => prev + 1), []);
  const refreshFolders = useCallback(() => setRefreshKey((prev) => prev + 1), []);

  useEffect(() => {
    if (!featureEnabled || !autoLoad) {
      setDocuments([]);
      setIsLoading(false);
      return;
    }
    let isActive = true;

    const fetchDocuments = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const context = getContext();
        const docs = await documentService.getDocuments(context, {
          folderId: options?.folderId ?? undefined,
          entityType: options?.entityType,
          entityId: options?.entityId,
          documentType: options?.documentType,
          status: options?.status,
        });
        if (isActive) {
          setDocuments(docs);
        }
      } catch (err) {
        if (isActive) {
          setError(err instanceof Error ? err : new Error('Failed to load documents'));
          setDocuments([]);
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    };

    void fetchDocuments();
    return () => {
      isActive = false;
    };
  }, [
    autoLoad,
    documentService,
    featureEnabled,
    getContext,
    options?.documentType,
    options?.entityId,
    options?.entityType,
    options?.folderId,
    options?.status,
    refreshKey,
  ]);

  useEffect(() => {
    if (!featureEnabled || !autoLoad) {
      setFolders([]);
      return;
    }
    let isActive = true;

    const fetchFolders = async () => {
      try {
        const context = getContext();
        const folderResults = await documentService.getFolders(context, undefined);
        if (isActive) {
          setFolders(folderResults);
        }
      } catch (err) {
        if (isActive) {
          setError(err instanceof Error ? err : new Error('Failed to load folders'));
          setFolders([]);
        }
      }
    };

    void fetchFolders();
    return () => {
      isActive = false;
    };
  }, [autoLoad, documentService, featureEnabled, getContext, refreshKey]);

  const uploadDocument: UseDocumentsResult['uploadDocument'] = useCallback(
    async (file, uploadOptions) => {
      if (!featureEnabled) return null;
      setIsUploading(true);
      setError(null);
      try {
        const context = getContext();
        const document = await documentService.uploadDocument(context, file, {
          name: uploadOptions.name,
          documentType: uploadOptions.documentType,
          description: uploadOptions.description,
          associatedEntity: uploadOptions.associatedEntity,
          folderId: uploadOptions.folderId ?? undefined,
          tags: uploadOptions.tags,
        });
        refreshDocuments();
        return document;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Upload failed');
        setError(error);
        return null;
      } finally {
        setIsUploading(false);
      }
    },
    [documentService, featureEnabled, getContext, refreshDocuments]
  );

  const createFolder: UseDocumentsResult['createFolder'] = useCallback(
    async (name, parentId) => {
      if (!featureEnabled) return null;
      try {
        const context = getContext();
        const folder = await documentService.createFolder(context, name, parentId);
        refreshFolders();
        return folder;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to create folder'));
        return null;
      }
    },
    [documentService, featureEnabled, getContext, refreshFolders]
  );

  const moveToFolder: UseDocumentsResult['moveToFolder'] = useCallback(
    async (documentId, folderId) => {
      if (!featureEnabled) return;
      try {
        const context = getContext();
        await documentService.moveToFolder(context, documentId, folderId);
        refreshDocuments();
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to move document'));
      }
    },
    [documentService, featureEnabled, getContext, refreshDocuments]
  );

  const generatePublicLink: UseDocumentsResult['generatePublicLink'] = useCallback(
    async (documentId, expiresInDays) => {
      if (!featureEnabled) return;
      try {
        const context = getContext();
        await documentService.generatePublicLink(context, documentId, expiresInDays);
        refreshDocuments();
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to generate public link'));
      }
    },
    [documentService, featureEnabled, getContext, refreshDocuments]
  );

  const revokePublicLink: UseDocumentsResult['revokePublicLink'] = useCallback(
    async (documentId) => {
      if (!featureEnabled) return;
      try {
        const context = getContext();
        await documentService.revokePublicLink(context, documentId);
        refreshDocuments();
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to revoke public link'));
      }
    },
    [documentService, featureEnabled, getContext, refreshDocuments]
  );

  const sendForSignature: UseDocumentsResult['sendForSignature'] = useCallback(
    async (documentId, signers, options) => {
      if (!featureEnabled || !features.enableESignature) return null;
      try {
        const context = getContext();
        const doc = await documentService.sendForSignature(context, documentId, signers, options);
        refreshDocuments();
        return doc;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to send for signature'));
        return null;
      }
    },
    [documentService, featureEnabled, features.enableESignature, getContext, refreshDocuments]
  );

  return {
    documents,
    folders,
    isLoading,
    isUploading,
    error,
    refreshDocuments,
    refreshFolders,
    uploadDocument: guardMutation(uploadDocument, { action: 'document-upload' }),
    createFolder: guardMutation(createFolder, { action: 'document-folder-create' }),
    moveToFolder: guardMutation(moveToFolder, { action: 'document-move' }),
    generatePublicLink: guardMutation(generatePublicLink, { action: 'document-link-create' }),
    revokePublicLink: guardMutation(revokePublicLink, { action: 'document-link-revoke' }),
    sendForSignature: guardMutation(sendForSignature, { action: 'document-signature-send' }),
  };
}
