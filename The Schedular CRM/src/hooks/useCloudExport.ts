import { useState, useCallback } from 'react';
import { runExport, type ExportDataResponse } from '../services/cloud-functions-integration';
import type { ExportRequest } from '../services/import-export-service';
import { useAuth } from '../context/AuthContext';

export interface UseCloudExportResult {
  isLoading: boolean;
  error: string | null;
  lastExportId: string | null;
  exportData: (request: ExportRequest & { filename?: string }) => Promise<void>;
}

export function useCloudExport(): UseCloudExportResult {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastExportId, setLastExportId] = useState<string | null>(null);
  const { businessId } = useAuth();

  const download = (content: string, contentType: ExportDataResponse['contentType'], filename?: string) => {
    const blob = new Blob([content], { type: contentType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename || `export-${new Date().toISOString().split('T')[0]}.${contentType.includes('pdf') ? 'pdf' : 'csv'}`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const exportData = useCallback(
    async (request: ExportRequest & { filename?: string }) => {
      setIsLoading(true);
      setError(null);
      setLastExportId(null);

      try {
        const response = await runExport({ ...request, businessId: businessId ?? undefined });
        if (!response.success) {
          setError(response.errors?.[0] || 'Export failed');
          return;
        }
        setLastExportId(response.exportId);
        download(response.content, response.contentType, request.filename);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Export failed');
      } finally {
        setIsLoading(false);
      }
    },
    [businessId]
  );

  return {
    isLoading,
    error,
    lastExportId,
    exportData,
  };
}

export default useCloudExport;
