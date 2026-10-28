import { assertDemoMutationAllowed } from '../config/demo';
import { postTenantEndpoint } from './firestoreBase';

const MS_PER_DAY = 1000 * 60 * 60 * 24;

export type ReportsGranularity = 'day' | 'week';

export type ReportsRequest = {
  startDate: string;
  endDate: string;
  granularity: ReportsGranularity;
};

export type ReportType = 'appointments' | 'payments' | 'clients';

export type ReportsResponse = {
  totalAppointments: number;
  completedAppointments: number;
  cancelledAppointments: number;
  totalRevenue: number;
  newClients: number;
  averageRevenuePerAppointment: number;
  completionRate: number;
};

export type ReportExportResult = {
  content: string | Blob;
  mimeType: 'text/csv' | 'application/pdf';
  fileName: string;
};

type ReportMetricsEndpointResponse = {
  success?: boolean;
  metrics?: Partial<ReportsResponse>;
  error?: string;
};

export async function fetchReports(
  businessId: string,
  request: ReportsRequest,
  userId?: string,
): Promise<ReportsResponse> {
  void userId;
  if (!businessId) {
    throw new Error('Cannot fetch reports without a businessId.');
  }

  const response = await postTenantEndpoint<ReportsRequest, ReportMetricsEndpointResponse>(
    '/getReportMetrics',
    businessId,
    request,
  );

  return normalizeMetrics(response?.metrics);
}

export async function requestReportExport(
  businessId: string,
  format: 'csv' | 'pdf',
  reportType: ReportType,
  request: ReportsRequest,
  userId?: string,
): Promise<ReportExportResult> {
  assertDemoMutationAllowed(`export reports (${format.toUpperCase()})`);
  void userId;
  if (!businessId) {
    throw new Error('Cannot export reports without a businessId.');
  }

  const endpoint = format === 'csv' ? '/exportReportCsv' : '/exportReportPdf';
  const payload = {
    reportType,
    startDate: request.startDate,
    endDate: request.endDate,
  };

  const content = await postTenantEndpoint<typeof payload, string | Blob>(endpoint, businessId, payload);

  return {
    content,
    mimeType: format === 'csv' ? 'text/csv' : 'application/pdf',
    fileName: buildFileName(request, reportType, format),
  };
}

function normalizeMetrics(metrics: Partial<ReportsResponse> | undefined): ReportsResponse {
  return {
    totalAppointments: Number(metrics?.totalAppointments ?? 0),
    completedAppointments: Number(metrics?.completedAppointments ?? 0),
    cancelledAppointments: Number(metrics?.cancelledAppointments ?? 0),
    totalRevenue: Number(metrics?.totalRevenue ?? 0),
    newClients: Number(metrics?.newClients ?? 0),
    averageRevenuePerAppointment: Number(metrics?.averageRevenuePerAppointment ?? 0),
    completionRate: Number(metrics?.completionRate ?? 0),
  };
}

function buildFileName(filters: ReportsRequest, reportType: ReportType, extension: 'csv' | 'pdf'): string {
  return `reports-${reportType}-${filters.startDate}-${filters.endDate}.${extension}`;
}

export function getReportWindowLengthDays(request: ReportsRequest): number {
  return Math.max(1, differenceInDays(request.startDate, request.endDate));
}

function differenceInDays(startDate: string, endDate: string): number {
  const start = new Date(`${startDate}T00:00:00`);
  const end = new Date(`${endDate}T00:00:00`);
  return Math.abs(end.getTime() - start.getTime()) / MS_PER_DAY;
}
