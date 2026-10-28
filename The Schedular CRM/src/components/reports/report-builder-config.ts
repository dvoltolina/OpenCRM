import type {
  AggregationType,
  ChartType,
  DateRange,
  ReportDataSource,
  ReportFilterOperator,
  ReportType,
} from '../../types/reporting';

export interface DataSourceField {
  field: string;
  label: string;
  type: 'string' | 'number' | 'date' | 'boolean';
  aggregatable?: boolean;
  filterable?: boolean;
}

export interface ReportBuilderStepDefinition {
  label: string;
  title: string;
  description: string;
}

export const REPORT_BUILDER_STEPS: ReportBuilderStepDefinition[] = [
  {
    label: 'Foundations',
    title: 'Name the report and choose its source',
    description: 'Set the report identity, business intent, and the dataset it should query.',
  },
  {
    label: 'Metrics',
    title: 'Choose groupings and measurements',
    description: 'Define the dimensions and KPIs that shape the output of the report.',
  },
  {
    label: 'Filters',
    title: 'Set time scope and filters',
    description: 'Constrain the result set without exposing raw records or individual PHI.',
  },
  {
    label: 'Display',
    title: 'Shape the final presentation',
    description: 'Choose the chart, sorting, row limits, and workspace visibility defaults.',
  },
];

export const REPORT_TYPES: Array<{
  value: ReportType;
  label: string;
  description: string;
}> = [
  { value: 'deals', label: 'Deals', description: 'Pipeline movement, value, and stage reporting.' },
  { value: 'revenue', label: 'Revenue', description: 'Closed value, velocity, and forecasting views.' },
  { value: 'leads', label: 'Leads', description: 'Acquisition, qualification, and conversion insights.' },
  { value: 'activities', label: 'Activities', description: 'Tasks, meetings, and rep execution trends.' },
  { value: 'pipeline', label: 'Pipeline', description: 'Stage health, throughput, and flow analysis.' },
  { value: 'team', label: 'Team', description: 'Rep and team performance snapshots.' },
  { value: 'sequences', label: 'Sequences', description: 'Enrollment and campaign engagement metrics.' },
  { value: 'conversion', label: 'Conversion', description: 'Source-to-stage and funnel completion rates.' },
];

export const CHART_TYPES: Array<{
  value: ChartType;
  label: string;
  description: string;
}> = [
  { value: 'bar', label: 'Bar', description: 'Compare groups side by side.' },
  { value: 'line', label: 'Line', description: 'Track trends over time.' },
  { value: 'pie', label: 'Pie', description: 'Show proportional breakdowns.' },
  { value: 'funnel', label: 'Funnel', description: 'Visualize stage drop-off.' },
  { value: 'table', label: 'Table', description: 'Keep the report row-driven.' },
  { value: 'metric', label: 'Metric', description: 'Highlight one headline KPI.' },
  { value: 'heatmap', label: 'Heatmap', description: 'Surface density and utilization patterns.' },
];

export const DATA_SOURCES: Array<{
  value: ReportDataSource;
  label: string;
  description: string;
}> = [
  { value: 'deals', label: 'Deals', description: 'Open, won, and lost deal data.' },
  { value: 'leads', label: 'Leads', description: 'Lead intake and qualification records.' },
  { value: 'activities', label: 'Activities', description: 'Calls, tasks, meetings, and notes.' },
  {
    value: 'sequence_enrollments',
    label: 'Sequence Enrollments',
    description: 'Sequence participation and response metrics.',
  },
  {
    value: 'email_messages',
    label: 'Email Messages',
    description: 'Message delivery and engagement summaries.',
  },
];

export const DATE_RANGES: Array<{ value: DateRange; label: string }> = [
  { value: 'today', label: 'Today' },
  { value: 'yesterday', label: 'Yesterday' },
  { value: 'this_week', label: 'This week' },
  { value: 'last_week', label: 'Last week' },
  { value: 'this_month', label: 'This month' },
  { value: 'last_month', label: 'Last month' },
  { value: 'this_quarter', label: 'This quarter' },
  { value: 'last_quarter', label: 'Last quarter' },
  { value: 'this_year', label: 'This year' },
  { value: 'last_year', label: 'Last year' },
  { value: 'custom', label: 'Custom range' },
];

export const AGGREGATION_TYPES: Array<{ value: AggregationType; label: string }> = [
  { value: 'count', label: 'Count' },
  { value: 'sum', label: 'Sum' },
  { value: 'avg', label: 'Average' },
  { value: 'min', label: 'Minimum' },
  { value: 'max', label: 'Maximum' },
];

export const FILTER_OPERATORS: Array<{ value: ReportFilterOperator; label: string }> = [
  { value: 'eq', label: 'Equals' },
  { value: 'neq', label: 'Not equal' },
  { value: 'gt', label: 'Greater than' },
  { value: 'gte', label: 'Greater than or equal' },
  { value: 'lt', label: 'Less than' },
  { value: 'lte', label: 'Less than or equal' },
  { value: 'in', label: 'In list' },
  { value: 'contains', label: 'Contains' },
];

export const FORMAT_OPTIONS: Array<{
  value: 'number' | 'currency' | 'percent';
  label: string;
}> = [
  { value: 'number', label: 'Number' },
  { value: 'currency', label: 'Currency' },
  { value: 'percent', label: 'Percent' },
];

export const DATE_GRANULARITIES: Array<{
  value: 'day' | 'week' | 'month' | 'quarter' | 'year';
  label: string;
}> = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
  { value: 'quarter', label: 'Quarter' },
  { value: 'year', label: 'Year' },
];

export const DEFAULT_FIELDS: Record<ReportDataSource, DataSourceField[]> = {
  leads: [
    { field: 'id', label: 'Lead ID', type: 'string', aggregatable: false, filterable: false },
    { field: 'firstName', label: 'First name', type: 'string' },
    { field: 'lastName', label: 'Last name', type: 'string' },
    { field: 'email', label: 'Email', type: 'string' },
    { field: 'status', label: 'Status', type: 'string', filterable: true },
    { field: 'source', label: 'Source', type: 'string', filterable: true },
    { field: 'score', label: 'Score', type: 'number', aggregatable: true },
    { field: 'assigneeName', label: 'Assignee', type: 'string', filterable: true },
    { field: 'createdAt', label: 'Created date', type: 'date' },
    { field: 'updatedAt', label: 'Updated date', type: 'date' },
  ],
  deals: [
    { field: 'id', label: 'Deal ID', type: 'string', aggregatable: false, filterable: false },
    { field: 'title', label: 'Title', type: 'string' },
    { field: 'valueCents', label: 'Value', type: 'number', aggregatable: true },
    { field: 'status', label: 'Status', type: 'string', filterable: true },
    { field: 'stage', label: 'Stage', type: 'string', filterable: true },
    { field: 'probability', label: 'Probability', type: 'number', aggregatable: true },
    { field: 'assigneeName', label: 'Assignee', type: 'string', filterable: true },
    { field: 'clientName', label: 'Client', type: 'string' },
    { field: 'companyName', label: 'Company', type: 'string' },
    { field: 'createdAt', label: 'Created date', type: 'date' },
    { field: 'closedAt', label: 'Closed date', type: 'date' },
  ],
  activities: [
    { field: 'id', label: 'Activity ID', type: 'string', aggregatable: false, filterable: false },
    { field: 'type', label: 'Type', type: 'string', filterable: true },
    { field: 'title', label: 'Title', type: 'string' },
    { field: 'isCompleted', label: 'Completed', type: 'boolean', filterable: true },
    { field: 'assigneeName', label: 'Assignee', type: 'string', filterable: true },
    { field: 'createdByName', label: 'Created by', type: 'string' },
    { field: 'dueDate', label: 'Due date', type: 'date' },
    { field: 'createdAt', label: 'Created date', type: 'date' },
    { field: 'completedAt', label: 'Completed date', type: 'date' },
  ],
  sequence_enrollments: [
    { field: 'id', label: 'Enrollment ID', type: 'string', aggregatable: false, filterable: false },
    { field: 'sequenceName', label: 'Sequence', type: 'string', filterable: true },
    { field: 'entityName', label: 'Entity', type: 'string' },
    { field: 'status', label: 'Status', type: 'string', filterable: true },
    { field: 'emailsSent', label: 'Emails sent', type: 'number', aggregatable: true },
    { field: 'emailsOpened', label: 'Emails opened', type: 'number', aggregatable: true },
    { field: 'repliesReceived', label: 'Replies', type: 'number', aggregatable: true },
    { field: 'createdAt', label: 'Enrolled date', type: 'date' },
  ],
  email_messages: [
    { field: 'id', label: 'Message ID', type: 'string', aggregatable: false, filterable: false },
    { field: 'subject', label: 'Subject', type: 'string' },
    { field: 'direction', label: 'Direction', type: 'string', filterable: true },
    { field: 'opens', label: 'Opens', type: 'number', aggregatable: true },
    { field: 'clicks', label: 'Clicks', type: 'number', aggregatable: true },
    { field: 'sentAt', label: 'Sent date', type: 'date' },
    { field: 'receivedAt', label: 'Received date', type: 'date' },
  ],
};
