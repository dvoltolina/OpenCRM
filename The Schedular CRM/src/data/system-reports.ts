/**
 * Pre-built System Reports
 * Default report definitions that are automatically available to all users.
 *
 * HIPAA Compliance Notes:
 * - System reports aggregate data, never expose individual PHI
 * - Reports are scoped by businessId and respect RBAC
 * - All report access is logged via audit service
 *
 * These reports are seeded into Firestore when a business is created
 * or when the application initializes if they don't exist.
 */

import type {
  ReportDefinition,
  ReportType,
  ReportDataSource,
} from '../types/reporting';

// ============================================
// System Report Definitions
// ============================================

/**
 * Partial report definition used for system reports.
 * businessId, id, createdAt, and owner fields are populated during seeding.
 */
export type SystemReportDefinition = Pick<
  ReportDefinition,
  | 'name'
  | 'description'
  | 'reportType'
  | 'chartType'
  | 'dataSource'
  | 'dimensions'
  | 'metrics'
  | 'filters'
  | 'defaultDateRange'
  | 'dateField'
  | 'sortBy'
  | 'sortOrder'
  | 'limit'
  | 'isSystemReport'
  | 'isPublic'
>;

/**
 * Pre-built system reports available to all businesses.
 * These are automatically seeded on business initialization.
 */
export const SYSTEM_REPORTS: SystemReportDefinition[] = [
  // ============================================
  // Pipeline Reports
  // ============================================
  {
    name: 'Pipeline by Stage',
    description: 'View deal distribution across pipeline stages with count and total value.',
    reportType: 'pipeline',
    chartType: 'funnel',
    dataSource: 'deals',
    dimensions: [
      { field: 'stageId', label: 'Stage', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Deal Count', aggregation: 'count', format: 'number' },
      { field: 'valueCents', label: 'Total Value', aggregation: 'sum', format: 'currency' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    sortBy: 'stageId',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Deals Won vs Lost',
    description: 'Compare won and lost deals over time to analyze performance trends.',
    reportType: 'deals',
    chartType: 'bar',
    dataSource: 'deals',
    dimensions: [
      { field: 'closedAt', label: 'Month', type: 'date', dateGranularity: 'month' },
    ],
    metrics: [
      { field: 'id', label: 'Deal Count', aggregation: 'count', format: 'number' },
      { field: 'valueCents', label: 'Total Value', aggregation: 'sum', format: 'currency' },
    ],
    filters: [
      { field: 'status', operator: 'in', value: ['won', 'lost'] },
    ],
    defaultDateRange: 'this_quarter',
    dateField: 'closedAt',
    sortBy: 'closedAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Deal Pipeline Velocity',
    description: 'Analyze how quickly deals move through your pipeline stages.',
    reportType: 'pipeline',
    chartType: 'table',
    dataSource: 'deals',
    dimensions: [
      { field: 'stageId', label: 'Stage', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Deal Count', aggregation: 'count', format: 'number' },
      { field: 'valueCents', label: 'Total Value', aggregation: 'sum', format: 'currency' },
      { field: 'valueCents', label: 'Average Value', aggregation: 'avg', format: 'currency' },
    ],
    filters: [
      { field: 'status', operator: 'eq', value: 'open' },
    ],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Lead Reports
  // ============================================
  {
    name: 'Lead Sources',
    description: 'Breakdown of leads by acquisition source to measure marketing effectiveness.',
    reportType: 'leads',
    chartType: 'pie',
    dataSource: 'leads',
    dimensions: [
      { field: 'source', label: 'Source', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Lead Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Lead Conversion Funnel',
    description: 'Track leads through each status stage to identify conversion bottlenecks.',
    reportType: 'conversion',
    chartType: 'funnel',
    dataSource: 'leads',
    dimensions: [
      { field: 'status', label: 'Status', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_quarter',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Lead Status by Source',
    description: 'Analyze lead status distribution by acquisition source.',
    reportType: 'leads',
    chartType: 'bar',
    dataSource: 'leads',
    dimensions: [
      { field: 'source', label: 'Source', type: 'string' },
      { field: 'status', label: 'Status', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Lead Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Leads Over Time',
    description: 'Track new lead acquisition over time to identify trends.',
    reportType: 'leads',
    chartType: 'line',
    dataSource: 'leads',
    dimensions: [
      { field: 'createdAt', label: 'Week', type: 'date', dateGranularity: 'week' },
    ],
    metrics: [
      { field: 'id', label: 'New Leads', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_quarter',
    dateField: 'createdAt',
    sortBy: 'createdAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Activity Reports
  // ============================================
  {
    name: 'Activities by Type',
    description: 'Breakdown of sales activities by type (calls, emails, meetings, etc.).',
    reportType: 'activities',
    chartType: 'bar',
    dataSource: 'activities',
    dimensions: [
      { field: 'type', label: 'Activity Type', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_week',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Activities by Rep',
    description: 'Compare activity levels across team members.',
    reportType: 'team',
    chartType: 'bar',
    dataSource: 'activities',
    dimensions: [
      { field: 'assigneeName', label: 'Rep', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Activities', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_week',
    dateField: 'createdAt',
    sortBy: 'id',
    sortOrder: 'desc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Completed Tasks',
    description: 'Track task completion rates over time.',
    reportType: 'activities',
    chartType: 'line',
    dataSource: 'activities',
    dimensions: [
      { field: 'completedAt', label: 'Day', type: 'date', dateGranularity: 'day' },
    ],
    metrics: [
      { field: 'id', label: 'Completed', aggregation: 'count', format: 'number' },
    ],
    filters: [
      { field: 'isCompleted', operator: 'eq', value: true },
      { field: 'type', operator: 'eq', value: 'task' },
    ],
    defaultDateRange: 'this_week',
    dateField: 'completedAt',
    sortBy: 'completedAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Activity Heatmap',
    description: 'Visualize team activity patterns across days and times.',
    reportType: 'activities',
    chartType: 'heatmap',
    dataSource: 'activities',
    dimensions: [
      { field: 'createdAt', label: 'Day', type: 'date', dateGranularity: 'day' },
    ],
    metrics: [
      { field: 'id', label: 'Activity Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Sequence Reports
  // ============================================
  {
    name: 'Sequence Performance',
    description: 'Analyze sequence effectiveness with enrollment, open, and reply metrics.',
    reportType: 'sequences',
    chartType: 'table',
    dataSource: 'sequence_enrollments',
    dimensions: [
      { field: 'sequenceName', label: 'Sequence', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Enrollments', aggregation: 'count', format: 'number' },
      { field: 'emailsOpened', label: 'Open Rate', aggregation: 'avg', format: 'percent' },
      { field: 'repliesReceived', label: 'Reply Rate', aggregation: 'avg', format: 'percent' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    sortBy: 'id',
    sortOrder: 'desc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Sequence Enrollment Trend',
    description: 'Track sequence enrollment volume over time.',
    reportType: 'sequences',
    chartType: 'line',
    dataSource: 'sequence_enrollments',
    dimensions: [
      { field: 'createdAt', label: 'Week', type: 'date', dateGranularity: 'week' },
    ],
    metrics: [
      { field: 'id', label: 'Enrollments', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_quarter',
    dateField: 'createdAt',
    sortBy: 'createdAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Sequence Status Breakdown',
    description: 'View distribution of sequence enrollments by status.',
    reportType: 'sequences',
    chartType: 'pie',
    dataSource: 'sequence_enrollments',
    dimensions: [
      { field: 'status', label: 'Status', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Count', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_month',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Revenue Reports
  // ============================================
  {
    name: 'Revenue by Month',
    description: 'Track closed-won revenue over time.',
    reportType: 'revenue',
    chartType: 'line',
    dataSource: 'deals',
    dimensions: [
      { field: 'closedAt', label: 'Month', type: 'date', dateGranularity: 'month' },
    ],
    metrics: [
      { field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' },
    ],
    filters: [
      { field: 'status', operator: 'eq', value: 'won' },
    ],
    defaultDateRange: 'this_year',
    dateField: 'closedAt',
    sortBy: 'closedAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Average Deal Size',
    description: 'Track average deal value trends over time.',
    reportType: 'deals',
    chartType: 'line',
    dataSource: 'deals',
    dimensions: [
      { field: 'closedAt', label: 'Month', type: 'date', dateGranularity: 'month' },
    ],
    metrics: [
      { field: 'valueCents', label: 'Avg Deal Size', aggregation: 'avg', format: 'currency' },
    ],
    filters: [
      { field: 'status', operator: 'eq', value: 'won' },
    ],
    defaultDateRange: 'this_year',
    dateField: 'closedAt',
    sortBy: 'closedAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Revenue by Rep',
    description: 'Compare closed-won revenue across team members.',
    reportType: 'revenue',
    chartType: 'bar',
    dataSource: 'deals',
    dimensions: [
      { field: 'assigneeName', label: 'Rep', type: 'string' },
    ],
    metrics: [
      { field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' },
      { field: 'id', label: 'Deals Won', aggregation: 'count', format: 'number' },
    ],
    filters: [
      { field: 'status', operator: 'eq', value: 'won' },
    ],
    defaultDateRange: 'this_quarter',
    dateField: 'closedAt',
    sortBy: 'valueCents',
    sortOrder: 'desc',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Team Performance Reports
  // ============================================
  {
    name: 'Team Leaderboard',
    description: 'Rank team members by closed-won deals.',
    reportType: 'team',
    chartType: 'table',
    dataSource: 'deals',
    dimensions: [
      { field: 'assigneeName', label: 'Rep', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Deals Won', aggregation: 'count', format: 'number' },
      { field: 'valueCents', label: 'Revenue', aggregation: 'sum', format: 'currency' },
      { field: 'valueCents', label: 'Avg Deal Size', aggregation: 'avg', format: 'currency' },
    ],
    filters: [
      { field: 'status', operator: 'eq', value: 'won' },
    ],
    defaultDateRange: 'this_month',
    dateField: 'closedAt',
    sortBy: 'valueCents',
    sortOrder: 'desc',
    limit: 10,
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Win Rate by Rep',
    description: 'Compare win rates across team members.',
    reportType: 'team',
    chartType: 'bar',
    dataSource: 'deals',
    dimensions: [
      { field: 'assigneeName', label: 'Rep', type: 'string' },
      { field: 'status', label: 'Status', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Deal Count', aggregation: 'count', format: 'number' },
    ],
    filters: [
      { field: 'status', operator: 'in', value: ['won', 'lost'] },
    ],
    defaultDateRange: 'this_quarter',
    dateField: 'closedAt',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Email Performance Reports
  // ============================================
  {
    name: 'Email Open Rates',
    description: 'Track email open rates over time.',
    reportType: 'sequences',
    chartType: 'line',
    dataSource: 'email_messages',
    dimensions: [
      { field: 'sentAt', label: 'Week', type: 'date', dateGranularity: 'week' },
    ],
    metrics: [
      { field: 'id', label: 'Emails Sent', aggregation: 'count', format: 'number' },
      { field: 'opens', label: 'Opens', aggregation: 'sum', format: 'number' },
    ],
    filters: [
      { field: 'direction', operator: 'eq', value: 'outbound' },
    ],
    defaultDateRange: 'this_month',
    dateField: 'sentAt',
    sortBy: 'sentAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },

  // ============================================
  // Conversion Reports
  // ============================================
  {
    name: 'Source to Deal Conversion',
    description: 'Track conversion rates from lead source to closed deal.',
    reportType: 'conversion',
    chartType: 'funnel',
    dataSource: 'leads',
    dimensions: [
      { field: 'source', label: 'Lead Source', type: 'string' },
    ],
    metrics: [
      { field: 'id', label: 'Leads', aggregation: 'count', format: 'number' },
    ],
    filters: [],
    defaultDateRange: 'this_quarter',
    dateField: 'createdAt',
    isSystemReport: true,
    isPublic: true,
  },

  {
    name: 'Monthly Conversion Trend',
    description: 'Track lead-to-deal conversion rates month over month.',
    reportType: 'conversion',
    chartType: 'line',
    dataSource: 'leads',
    dimensions: [
      { field: 'convertedAt', label: 'Month', type: 'date', dateGranularity: 'month' },
    ],
    metrics: [
      { field: 'id', label: 'Conversions', aggregation: 'count', format: 'number' },
    ],
    filters: [
      { field: 'convertedToClientId', operator: 'neq', value: null },
    ],
    defaultDateRange: 'this_year',
    dateField: 'convertedAt',
    sortBy: 'convertedAt',
    sortOrder: 'asc',
    isSystemReport: true,
    isPublic: true,
  },
];

// ============================================
// Helper Functions
// ============================================

/**
 * Get a system report definition by name.
 */
export function getSystemReportByName(name: string): SystemReportDefinition | undefined {
  return SYSTEM_REPORTS.find((report) => report.name === name);
}

/**
 * Get all system reports of a specific type.
 */
export function getSystemReportsByType(reportType: ReportType): SystemReportDefinition[] {
  return SYSTEM_REPORTS.filter((report) => report.reportType === reportType);
}

/**
 * Get all system reports for a specific data source.
 */
export function getSystemReportsByDataSource(dataSource: ReportDataSource): SystemReportDefinition[] {
  return SYSTEM_REPORTS.filter((report) => report.dataSource === dataSource);
}

/**
 * Convert a system report definition to a full ReportDefinition for storage.
 */
export function createReportDefinitionFromSystem(
  systemReport: SystemReportDefinition,
  businessId: string,
  ownerId: string,
  ownerName?: string
): Omit<ReportDefinition, 'id' | 'createdAt'> {
  return {
    ...systemReport,
    businessId,
    ownerId,
    ownerName,
    teamIds: [],
    visibility: 'org',
  };
}

/**
 * Get IDs of system reports that should be seeded for a new business.
 * Returns report names for identification during seeding.
 */
export function getDefaultSystemReportNames(): string[] {
  return SYSTEM_REPORTS.map((report) => report.name);
}

/**
 * Validate a system report definition has all required fields.
 */
export function validateSystemReport(report: SystemReportDefinition): string | null {
  if (!report.name?.trim()) {
    return 'Report name is required';
  }
  if (!report.reportType) {
    return 'Report type is required';
  }
  if (!report.chartType) {
    return 'Chart type is required';
  }
  if (!report.dataSource) {
    return 'Data source is required';
  }
  if (!report.dimensions?.length && !report.metrics?.length) {
    return 'At least one dimension or metric is required';
  }
  if (!report.defaultDateRange) {
    return 'Default date range is required';
  }
  if (!report.dateField) {
    return 'Date field is required';
  }
  return null;
}

// Validate all system reports at module load time
for (const report of SYSTEM_REPORTS) {
  const error = validateSystemReport(report);
  if (error) {
    console.error(`Invalid system report "${report.name}": ${error}`);
  }
}
