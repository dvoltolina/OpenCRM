/**
 * Reporting aggregation types
 * Defines KPI payloads for backend reporting endpoints and caches.
 *
 * HIPAA Compliance Notes:
 * - Reports aggregate data, not expose individual PHI
 * - Export files may contain PHI; track downloads in audit log
 * - Scheduled reports use secure links, not attachments with PHI
 * - Access logging tracks who runs what reports
 */

import type { BaseEntity } from '../data/repositories/repository-types';

// ============================================
// Report Definition Types
// ============================================

export type ReportType =
  | 'leads'
  | 'deals'
  | 'activities'
  | 'sequences'
  | 'pipeline'
  | 'revenue'
  | 'conversion'
  | 'team';

export type ChartType =
  | 'bar'
  | 'line'
  | 'pie'
  | 'funnel'
  | 'table'
  | 'metric'
  | 'heatmap';

export type AggregationType = 'count' | 'sum' | 'avg' | 'min' | 'max';

export type DateRange =
  | 'today'
  | 'yesterday'
  | 'this_week'
  | 'last_week'
  | 'this_month'
  | 'last_month'
  | 'this_quarter'
  | 'last_quarter'
  | 'this_year'
  | 'last_year'
  | 'custom';

export type ReportDataSource =
  | 'leads'
  | 'deals'
  | 'activities'
  | 'sequence_enrollments'
  | 'email_messages';

export interface ReportDimension {
  field: string;
  label: string;
  type: 'string' | 'date' | 'boolean';
  dateGranularity?: 'day' | 'week' | 'month' | 'quarter' | 'year';
}

export interface ReportMetric {
  field: string;
  label: string;
  aggregation: AggregationType;
  format?: 'number' | 'currency' | 'percent';
}

export type ReportFilterOperator =
  | 'eq'
  | 'neq'
  | 'gt'
  | 'gte'
  | 'lt'
  | 'lte'
  | 'in'
  | 'contains';

export interface ReportFilter {
  field: string;
  operator: ReportFilterOperator;
  value: unknown;
}

export interface ReportDefinition extends BaseEntity {
  businessId: string;
  name: string;
  description?: string;

  // Report configuration
  reportType: ReportType;
  chartType: ChartType;

  // Data source
  dataSource: ReportDataSource;

  // Dimensions (group by)
  dimensions: ReportDimension[];

  // Metrics (aggregate)
  metrics: ReportMetric[];

  // Filters
  filters: ReportFilter[];

  // Default date range
  defaultDateRange: DateRange;
  dateField: string;

  // Display options
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  limit?: number;

  // Sharing
  isSystemReport: boolean;
  isPublic: boolean;
  ownerId: string;
  ownerName?: string;
  sharedWithUserIds?: string[];
  sharedWithTeamIds?: string[];
  teamIds?: string[];
  visibility?: 'private' | 'team' | 'org';
  [key: string]: unknown;
}

export interface ReportResult {
  reportId: string;
  generatedAt: Date;
  dateRange: { start: Date; end: Date };

  // Data
  rows: Record<string, unknown>[];
  totals?: Record<string, number>;

  // Metadata
  rowCount: number;
  queryTimeMs: number;
}

// ============================================
// Scheduled Report Types
// ============================================

export type ScheduledReportFrequency = 'daily' | 'weekly' | 'monthly';
export type ScheduledReportFormat = 'pdf' | 'csv' | 'xlsx';

export interface ScheduledReport extends BaseEntity {
  businessId: string;
  reportId: string;
  reportName: string;

  // Schedule
  frequency: ScheduledReportFrequency;
  dayOfWeek?: number; // 0-6 for weekly
  dayOfMonth?: number; // 1-31 for monthly
  timeOfDay: string; // HH:MM in business timezone

  // Recipients
  recipientUserIds: string[];
  recipientEmails?: string[]; // External recipients

  // Delivery options
  format: ScheduledReportFormat;
  includeChart: boolean;

  // Status
  isActive: boolean;
  lastSentAt?: Date;
  nextSendAt: Date;
  lastError?: string;
  lastErrorAt?: Date;

  createdById: string;
  createdByName?: string;
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
}

// ============================================
// Dashboard Types
// ============================================

export type DashboardLayout = 'grid' | 'freeform';
export type WidgetType = 'report' | 'metric' | 'leaderboard' | 'activity_feed' | 'tasks';

export interface MetricWidgetConfig {
  metric: string; // e.g., 'deals_won_count', 'revenue_this_month'
  comparison?: 'previous_period' | 'same_period_last_year';
  format: 'number' | 'currency' | 'percent';
  thresholds?: { warning: number; danger: number };
  showSparkline?: boolean;
  subtitle?: string;
}

export interface LeaderboardConfig {
  metric: string;
  entityType: 'user' | 'team';
  limit: number;
  dateRange: DateRange;
}

export interface DashboardWidget {
  id: string;
  type: WidgetType;

  // Position
  x: number;
  y: number;
  width: number;
  height: number;

  // Configuration
  title: string;
  reportId?: string; // For report widgets
  metricConfig?: MetricWidgetConfig;
  leaderboardConfig?: LeaderboardConfig;

  // Refresh
  refreshIntervalMinutes?: number;
}

export interface Dashboard extends BaseEntity {
  businessId: string;
  name: string;
  description?: string;

  // Layout
  widgets: DashboardWidget[];
  layout: DashboardLayout;

  // Access
  isDefault: boolean;
  defaultForRoles?: string[];
  ownerId: string;
  ownerName?: string;
  isPublic: boolean;
  teamIds?: string[];
  visibility?: 'private' | 'team' | 'org';
  [key: string]: unknown;
}

// ============================================
// Quick Stats Types
// ============================================

export interface QuickStats {
  leadsThisMonth: number;
  dealsWonThisMonth: number;
  revenueThisMonth: number;
  activitiesThisWeek: number;
  openTasks: number;
  sequenceEnrollments: number;
}

export interface MetricValue {
  value: number;
  previousValue?: number;
  changePercent?: number;
}

// ============================================
// Report Cache Types
// ============================================

export interface ReportCache extends BaseEntity {
  reportId: string;
  dateRangeKey: string;
  result: ReportResult;
  generatedAt: Date;
  expiresAt: Date;
}

export type ReportingTimeBucket = 'daily' | 'weekly' | 'monthly';

export interface ReportingKpis {
  openCount: number;
  wonCount: number;
  lostCount: number;
  openValueCents: number;
  wonValueCents: number;
  lostValueCents: number;
  averageCycleDays: number;
}

export interface StageSummary {
  stageId: string;
  count: number;
  valueCents: number;
}

export interface StageConversion {
  stageId: string;
  stageName?: string;
  entered: number;
  won: number;
  lost: number;
  conversionRate: number;
}

export interface VelocityMetrics {
  averageCycleDays: number;
  averageOpenDays: number;
  throughputPerDay: number;
  winRate: number;
}

export interface PerformanceMetrics {
  ownerOrTeamId: string;
  ownerOrTeamName?: string;
  pipelineIds: string[];
  metrics: ReportingKpis;
  winRate: number;
  averageCycleDays: number;
}

export interface LostReasonBreakdown {
  reason: string;
  count: number;
  valueCents: number;
  pipelineId?: string;
}

export interface SourceCohort {
  source: string;
  periodStart: Date;
  periodEnd: Date;
  leadCount: number;
  convertedCount: number;
  conversionRate: number;
  wonValueCents: number;
}

export interface PipelineAggregation {
  pipelineId: string;
  ownerId: string;
  teamIds: string[];
  metrics: ReportingKpis;
  stageBreakdown: StageSummary[];
  stageConversions: StageConversion[];
  lostReasons: LostReasonBreakdown[];
  velocity: VelocityMetrics;
}

export interface TimeBucketAggregation {
  bucket: ReportingTimeBucket;
  periodStart: Date;
  periodEnd: Date;
  metrics: ReportingKpis;
  pipelineId?: string;
}

export interface ReportingAggregationResult {
  generatedAt: Date;
  filters: ReportingAggregationFilters;
  summary: ReportingKpis;
  pipelines: PipelineAggregation[];
  timeBuckets: TimeBucketAggregation[];
  stageConversions: StageConversion[];
  velocity: VelocityMetrics;
  ownerPerformance: PerformanceMetrics[];
  teamPerformance: PerformanceMetrics[];
  lostReasons: LostReasonBreakdown[];
  cohorts: SourceCohort[];
}

export interface ReportingAggregationFilters {
  startDate?: Date;
  endDate?: Date;
  pipelineIds?: string[];
  ownerIds?: string[];
  teamIds?: string[];
  stageIds?: string[];
  sources?: string[];
  bucket?: ReportingTimeBucket;
  includeStageBreakdown?: boolean;
  cacheResults?: boolean;
  preferCache?: boolean;
}

export interface ReportingAggregate extends BaseEntity {
  pipelineId: string | null;
  ownerId: string | null;
  teamIds: string[];
  bucket: ReportingTimeBucket;
  startDate: Date;
  endDate: Date;
  metrics: ReportingKpis;
  stageBreakdown: StageSummary[];
  stageConversions?: StageConversion[];
  lostReasons?: LostReasonBreakdown[];
  velocity?: VelocityMetrics;
}

export type ReportExportFormat = 'csv' | 'pdf';
export type ReportExportFrequency = 'once' | 'daily' | 'weekly';
export type ReportExportStatus = 'scheduled' | 'running' | 'completed' | 'failed' | 'paused';

export interface ReportExportDelivery {
  method: 'email' | 'link';
  targetEmail?: string;
  expiresAt?: Date;
  downloadUrl?: string;
}

export interface ReportExport extends BaseEntity {
  name: string;
  description?: string;
  format: ReportExportFormat;
  cadence: ReportExportFrequency;
  status: ReportExportStatus;
  nextRunAt: Date;
  lastRunAt?: Date;
  lastRunStatus?: ReportExportStatus;
  filters: ReportingAggregationFilters;
  delivery: ReportExportDelivery;
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  visibility?: 'private' | 'team' | 'org';
  [key: string]: unknown;
}
