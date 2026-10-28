import type { ReportDefinition, ReportType } from '../types/reporting';

export interface ReportCategory {
  type: ReportType;
  label: string;
  description: string;
}

export const REPORT_CATEGORIES: ReportCategory[] = [
  { type: 'deals', label: 'Deals', description: 'Pipeline movement and value tracking.' },
  { type: 'revenue', label: 'Revenue', description: 'Closed-won totals and forecasting.' },
  { type: 'leads', label: 'Leads', description: 'Acquisition and conversion reporting.' },
  { type: 'activities', label: 'Activities', description: 'Rep execution and task output.' },
  { type: 'pipeline', label: 'Pipeline', description: 'Stage health and throughput.' },
  { type: 'team', label: 'Team', description: 'Rep and team-level performance.' },
  { type: 'sequences', label: 'Sequences', description: 'Enrollment and engagement metrics.' },
  { type: 'conversion', label: 'Conversion', description: 'Funnel progression and loss rates.' },
];

export function getReportCategory(type: ReportType) {
  return REPORT_CATEGORIES.find((category) => category.type === type);
}

export function buildBuilderInitialData(report: ReportDefinition | null) {
  if (!report) {
    return undefined;
  }

  return {
    name: report.name,
    description: report.description,
    reportType: report.reportType,
    chartType: report.chartType,
    dataSource: report.dataSource,
    dimensions: report.dimensions,
    metrics: report.metrics,
    filters: report.filters,
    defaultDateRange: report.defaultDateRange,
    dateField: report.dateField || 'createdAt',
    sortBy: report.sortBy,
    sortOrder: report.sortOrder,
    limit: report.limit,
    isPublic: report.isPublic || false,
  };
}
