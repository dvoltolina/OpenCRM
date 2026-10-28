import { useCallback, useEffect, useMemo, useState } from 'react';

import { useBusinessContext } from './useBusinessContext';
import {
  fetchReports,
  type ReportExportResult,
  type ReportType,
  type ReportsRequest,
  requestReportExport,
  type ReportsResponse,
} from '../data/reports';

const DATE_FORMATTER = new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' });
const msPerDay = 1000 * 60 * 60 * 24;

export type ReportsPreset = '7d' | '30d' | '90d' | 'custom';

export type ReportsFilters = {
  preset: ReportsPreset;
  startDate: string;
  endDate: string;
};

type ExportState = {
  csv: boolean;
  pdf: boolean;
};

type UseReportsOptions = {
  enabled?: boolean;
};

export function useReports(options: UseReportsOptions = {}) {
  const enabled = options.enabled ?? true;
  const { businessId, userId } = useBusinessContext({ requireBusinessId: true, minRole: 'admin' });
  const [filters, setFilters] = useState<ReportsFilters>(() => ({
    preset: '30d',
    ...deriveRange('30d'),
  }));
  const [reportType, setReportType] = useState<ReportType>('appointments');
  const [data, setData] = useState<ReportsResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<number | null>(null);
  const [exporting, setExporting] = useState<ExportState>({ csv: false, pdf: false });

  const reportsRequest: ReportsRequest = useMemo(
    () => ({
      startDate: filters.startDate,
      endDate: filters.endDate,
      granularity: getGranularity(filters.startDate, filters.endDate),
    }),
    [filters.endDate, filters.startDate],
  );

  const refresh = useCallback(async () => {
    if (!enabled) {
      setData(null);
      setLoading(false);
      return;
    }
    if (!businessId) {
      return;
    }
    setLoading(true);
    setError(null);

    try {
      const response = await fetchReports(businessId, reportsRequest, userId);
      setData(response);
      setLastUpdatedAt(Date.now());
    } catch (err) {
      console.error('Failed to load reports', err);
      setError(err instanceof Error ? err.message : 'Failed to load reports');
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [businessId, enabled, reportsRequest, userId]);

  useEffect(() => {
    if (!enabled) {
      setData(null);
      setLoading(false);
      return;
    }
    refresh();
  }, [enabled, refresh]);

  const setPresetRange = useCallback((preset: ReportsPreset) => {
    setFilters((prev) => {
      if (preset === 'custom') {
        return { ...prev, preset };
      }
      return {
        preset,
        ...deriveRange(preset),
      };
    });
  }, []);

  const setCustomRange = useCallback((partial: Partial<Pick<ReportsFilters, 'startDate' | 'endDate'>>) => {
    setFilters((prev) => ({
      ...prev,
      preset: 'custom',
      ...partial,
    }));
  }, []);

  const exportCsv = useCallback(async () => {
    if (!businessId || !enabled) {
      return;
    }
    setExporting((prev) => ({ ...prev, csv: true }));
    try {
      const result = await requestReportExport(businessId, 'csv', reportType, reportsRequest, userId);
      downloadExport(result);
    } catch (error) {
      console.error('CSV export failed', error);
      setError(error instanceof Error ? error.message : 'CSV export failed');
      throw error;
    } finally {
      setExporting((prev) => ({ ...prev, csv: false }));
    }
  }, [businessId, enabled, reportType, reportsRequest, userId]);

  const exportPdf = useCallback(async () => {
    if (!businessId || !enabled) {
      return;
    }
    setExporting((prev) => ({ ...prev, pdf: true }));
    try {
      const result = await requestReportExport(businessId, 'pdf', reportType, reportsRequest, userId);
      downloadExport(result);
    } catch (error) {
      console.error('PDF export failed', error);
      setError(error instanceof Error ? error.message : 'PDF export failed');
      throw error;
    } finally {
      setExporting((prev) => ({ ...prev, pdf: false }));
    }
  }, [businessId, enabled, reportType, reportsRequest, userId]);

  return {
    filters,
    reportType,
    setReportType,
    data,
    loading,
    error,
    lastUpdatedAt,
    exporting,
    setPresetRange,
    setCustomRange,
    refresh,
    exportCsv,
    exportPdf,
  };
}

function deriveRange(preset: Exclude<ReportsPreset, 'custom'>): Pick<ReportsFilters, 'startDate' | 'endDate'> {
  const today = new Date();
  const endDate = formatDate(today);
  let startDate = endDate;

  if (preset === '7d') {
    startDate = formatDate(new Date(today.getTime() - msPerDay * 6));
  } else if (preset === '30d') {
    startDate = formatDate(new Date(today.getTime() - msPerDay * 29));
  } else if (preset === '90d') {
    startDate = formatDate(new Date(today.getTime() - msPerDay * 89));
  }

  return { startDate, endDate };
}

function getGranularity(start: string, end: string): ReportsRequest['granularity'] {
  const startDate = new Date(`${start}T00:00:00`);
  const endDate = new Date(`${end}T00:00:00`);
  const diff = Math.abs(endDate.getTime() - startDate.getTime()) / msPerDay;
  return diff > 60 ? 'week' : 'day';
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function downloadExport(result: ReportExportResult): void {
  if (typeof window === 'undefined') {
    return;
  }

  const blob = typeof result.content === 'string' ? new Blob([result.content], { type: result.mimeType }) : result.content;
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = result.fileName;
  anchor.rel = 'noopener noreferrer';
  anchor.click();
  URL.revokeObjectURL(url);
}

export function formatUpdatedTimestamp(timestamp: number | null): string | null {
  if (!timestamp) {
    return null;
  }
  return DATE_FORMATTER.format(timestamp);
}
