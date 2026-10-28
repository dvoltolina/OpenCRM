import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getFeatureFlags } from '../config/features';
import { DocumentService } from '../services/document-service';
import type { DocumentTemplate, DocumentType } from '../types/documents';
import { createSecurityContext } from '../lib/security-context';

export interface UseDocumentTemplatesOptions {
  category?: string;
  documentTypes?: DocumentType[];
  autoLoad?: boolean;
}

export interface UseDocumentTemplatesResult {
  templates: DocumentTemplate[];
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

/**
 * Load active document templates with optional category/type filtering.
 * Feature-flagged by enableDocuments.
 */
export function useDocumentTemplates(options?: UseDocumentTemplatesOptions): UseDocumentTemplatesResult {
  const { crmUser } = useAuth();
  const features = getFeatureFlags();
  const [templates, setTemplates] = useState<DocumentTemplate[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const documentService = useMemo(() => new DocumentService(), []);
  const autoLoad = options?.autoLoad ?? true;

  const refresh = useCallback(() => setRefreshKey((prev) => prev + 1), []);

  useEffect(() => {
    if (!features.enableDocuments || !autoLoad) {
      setTemplates([]);
      setIsLoading(false);
      return;
    }
    if (!crmUser) {
      setTemplates([]);
      setIsLoading(false);
      return;
    }

    let isActive = true;
    const loadTemplates = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const context = createSecurityContext(crmUser);
        const data = await documentService.getTemplates(context, options?.category);
        const filtered =
          options?.documentTypes && options.documentTypes.length
            ? data.filter((tpl) => options.documentTypes?.includes(tpl.documentType))
            : data;
        if (isActive) {
          setTemplates(filtered);
        }
      } catch (err) {
        if (isActive) {
          const message = err instanceof Error ? err.message : 'Unable to load document templates';
          setTemplates([]);
          setError(new Error(message));
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    };

    void loadTemplates();
    return () => {
      isActive = false;
    };
  }, [
    autoLoad,
    crmUser,
    documentService,
    features.enableDocuments,
    options?.category,
    options?.documentTypes,
    refreshKey,
  ]);

  return {
    templates,
    isLoading,
    error,
    refresh,
  };
}
