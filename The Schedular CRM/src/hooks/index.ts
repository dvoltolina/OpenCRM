/**
 * Hooks Index
 * Barrel export for all CRM hooks
 */

// Pipeline & Stage Hooks (Agent CRM-07)
export { usePipeline, createSecurityContext } from './usePipeline';
export type { UsePipelineResult } from './usePipeline';

export { usePipelines } from './usePipelines';
export type { UsePipelinesResult } from './usePipelines';

export { useStages } from './useStages';
export type { UseStagesResult } from './useStages';

export { usePipelineWithStages } from './usePipelineWithStages';
export type { UsePipelineWithStagesResult } from './usePipelineWithStages';

// Lead Hooks (Agent CRM-08)
export { useLeads } from './useLeads';
export type { UseLeadsResult, LeadFilters } from './useLeads';

export { useLead } from './useLead';
export type { UseLeadResult } from './useLead';

export { useLeadMutations } from './useLeadMutations';
export type { UseLeadMutationsResult } from './useLeadMutations';

// Deal Hooks (Agent CRM-09)
export { useDeals } from './useDeals';
export type { UseDealsResult, DealFilters } from './useDeals';

export { useDeal } from './useDeal';
export type { UseDealResult } from './useDeal';

export { useDealsByStage } from './useDealsByStage';
export type { UseDealsByStageResult, DealsByStage, StageWithDeals } from './useDealsByStage';

export { useDealMutations } from './useDealMutations';
export type { UseDealMutationsResult, CreateDealInput } from './useDealMutations';

// Contact & Company Hooks (Agent CRM-10)
export { useContacts } from './useContacts';
export type { UseContactsResult, ContactFilters } from './useContacts';

export { useContact } from './useContact';
export type { UseContactResult } from './useContact';

export { useContactMutations } from './useContactMutations';
export type { UseContactMutationsResult, ContactMutationOptions } from './useContactMutations';

export { useCompanies } from './useCompanies';
export type { UseCompaniesResult, CompanyFilters } from './useCompanies';

export { useCompany } from './useCompany';
export type { UseCompanyResult } from './useCompany';

export { useCompanyMutations } from './useCompanyMutations';
export type { UseCompanyMutationsResult } from './useCompanyMutations';

// Lead Conversion Hook (Agent CRM-11)
export { useLeadConversion } from './useLeadConversion';
export type { UseLeadConversionResult } from './useLeadConversion';

// Deal Stage Transition Hook (Agent CRM-12)
export { useDealStageTransition } from './useDealStageTransition';
export type { UseDealStageTransitionResult } from './useDealStageTransition';

// Activity Logging Hooks (Agent CRM-13)
export { useActivityLog } from './useActivityLog';
export type { UseActivityLogResult } from './useActivityLog';

export {
  useTimeline,
  useUnifiedTimeline,
  usePendingTasks,
  useOverdueTasks,
  useUpcomingTasks,
  useRecentActivities,
} from './useTimeline';
export type {
  UseTimelineResult,
  UseTimelineOptions,
  UseUnifiedTimelineOptions,
  UseTasksResult,
} from './useTimeline';

// Modal Hook (Agent CRM-15)
export { useModal } from './useModal';
export type { UseModalResult } from './useModal';

// Kanban Drag-Drop Hook (Agent CRM-16)
export { useKanbanDragDrop } from './useKanbanDragDrop';
export type {
  UseKanbanDragDropResult,
  UseKanbanDragDropOptions,
  DragState,
} from './useKanbanDragDrop';

// Dashboard Hooks (Agent CRM-18)
export { useDashboardKPIs } from './useDashboardKPIs';
export type { DashboardKPIs, UseDashboardKPIsOptions } from './useDashboardKPIs';

export { useDashboardData } from './useDashboardData';
export type { UseDashboardDataResult } from './useDashboardData';

// Chart Data Hooks (Agent CRM-19)
export { usePipelineChartData } from './usePipelineChartData';
export type {
  UsePipelineChartDataResult,
  PipelineChartDataPoint,
} from './usePipelineChartData';

export { useSalesChartData } from './useSalesChartData';
export type {
  UseSalesChartDataResult,
  UseSalesChartDataOptions,
  SalesDataPoint,
  TimeGranularity,
} from './useSalesChartData';

// Settings Hooks (Agent CRM-20)
export { useSettings } from './useSettings';
export type { UseSettingsResult } from './useSettings';

export { useTeamMembers } from './useTeamMembers';
export type { UseTeamMembersResult, TeamMember } from './useTeamMembers';

export { useTeams } from './useTeams';
export type { UseTeamsResult, UseTeamsOptions } from './useTeams';

// Advanced Analytics Hooks (Agent CRM-31)
export { useAdvancedAnalytics } from './useAdvancedAnalytics';
export type {
  UseAdvancedAnalyticsResult,
  UseAdvancedAnalyticsOptions,
  LeadSourceROIData,
  AppointmentCompletionData,
  StaffUtilizationData,
  PayoutData,
  DisputeData,
  DateRange,
} from './useAdvancedAnalytics';
export { useReportViews } from './useReportViews';
export { useReportingAggregations } from './useReportingAggregations';
export type { UseReportingAggregationsResult } from './useReportingAggregations';
export { useReportExports } from './useReportExports';

// Network Status Hook (Agent CRM-34)
export { useNetworkStatus } from './useNetworkStatus';
export type {
  UseNetworkStatusResult,
  UseNetworkStatusOptions,
} from './useNetworkStatus';

// Custom Fields Hook (Agent CRM-39)
export { useCustomFields } from './useCustomFields';
export type { UseCustomFieldsResult } from './useCustomFields';

// Lead Scoring Hook (Agent CRM-40)
export { useLeadScoring } from './useLeadScoring';
export type { UseLeadScoringResult } from './useLeadScoring';

// Deal Rotting Hook (Agent CRM-41)
export { useDealRotting } from './useDealRotting';
export type { UseDealRottingResult } from './useDealRotting';

// Scheduler Integration Hooks (Agent CRM-43)
export {
  useClientAppointments,
  useClientAIInsights,
  useClientCommunications,
} from './useSchedulerData';
export type {
  UseClientAppointmentsResult,
  UseClientAIInsightsResult,
  UseClientCommunicationsResult,
  Appointment,
  AIInsights,
  CommunicationRecord,
} from './useSchedulerData';

// Task Reminder Hook (Agent CRM-44)
export { useTaskReminders } from './useTaskReminders';
export type { UseTaskRemindersResult } from './useTaskReminders';

// CSV Import Hook (Agent CRM-42)
export { useCSVImport } from './useCSVImport';
export type { UseCSVImportReturn } from './useCSVImport';

// Automation (Trigger -> Action)
export { useAutomationRules } from './useAutomationRules';
export type { CreateAutomationInput, UseAutomationRulesResult } from './useAutomationRules';

// Workspace Hook (Agent CRM-Security)
export { useWorkspace } from './useWorkspace';

// Cloud Functions helpers
export { useCloudExport } from './useCloudExport';
export { useIntegrationSync } from './useIntegrationSync';

// Email Integration
export { useEmailIntegration } from './useEmailIntegration';
// Calendar Sync
export { useCalendarSync } from './useCalendarSync';

// Documents
export { useDocuments } from './useDocuments';
export type { UseDocumentsResult, UseDocumentsOptions } from './useDocuments';
export type { UseEmailIntegrationResult } from './useEmailIntegration';
export { useDocumentTemplates } from './useDocumentTemplates';
export type { UseDocumentTemplatesOptions, UseDocumentTemplatesResult } from './useDocumentTemplates';

// Route Planning Hooks
export { useRoutes, useRouteMutations, useGeocoding, haversineDistance, optimizeRouteOrder } from './useRoutes';
export type { UseRoutesResult, UseRouteMutationsResult, UseGeocodingResult } from './useRoutes';

// Time Entry / Timesheet Hooks
export {
  useTimeEntries,
  useTimeEntryMutations,
  usePendingApprovals,
  useTimesheetData,
  calculateOvertimeMinutes,
  buildTimesheetSummary,
  formatMinutesAsTime,
  formatMinutesAsDecimal,
  generatePayrollCSV,
  generateWeeklySummaryCSV,
  downloadCSV,
} from './useTimeEntries';
export type {
  UseTimeEntriesResult,
  UseTimeEntryMutationsResult,
  UsePendingApprovalsResult,
  UseTimesheetDataOptions,
  UseTimesheetDataResult,
  PayrollExportRow,
} from './useTimeEntries';

// Staff Schedule Hooks (Team Route Planning)
export {
  useStaffSchedules,
  useStaffSchedule,
  useStaffScheduleMutations,
  isStaffWorkingOnDate,
  createDefaultWeeklyPatterns,
  getWorkingHoursForDate,
} from './useStaffSchedules';
export type {
  UseStaffSchedulesResult,
  UseStaffScheduleResult,
  UseStaffScheduleMutationsResult,
} from './useStaffSchedules';

// Territory Hooks (Team Route Planning)
export {
  useTerritories,
  useTerritory,
  useTerritoryMutations,
  suggestStaffForContact,
  isLocationInTerritory,
  isZipCodeInTerritory,
} from './useTerritories';
export type {
  UseTerritoriesResult,
  UseTerritoryResult,
  UseTerritoryMutationsResult,
} from './useTerritories';

// Team Route Builder Hook (Multi-Staff Route Planning)
export { useTeamRouteBuilder } from './useTeamRouteBuilder';
export type {
  UseTeamRouteBuilderResult,
  WorkingStaffMember,
  TeamRoutePlan,
} from './useTeamRouteBuilder';

// Calendar Conflicts Hook (Route Planning)
export { useCalendarConflicts } from './useCalendarConflicts';
export type { UseCalendarConflictsOptions, UseCalendarConflictsResult } from './useCalendarConflicts';

// Client Notes Hooks (CRM-A Task 4)
export {
  useClientNotes,
  useFilteredClientNotes,
  useRecentClientNotes,
  useClientNoteMutations,
  useJobNotes,
  useAppointmentJobNotes,
  useFilteredJobNotes,
  useAllClientNotes,
} from './useClientNotes';
export type {
  ClientNote,
  JobNote,
  ClientNoteType,
  CreateNoteInput,
  UpdateNoteInput,
} from './useClientNotes';
