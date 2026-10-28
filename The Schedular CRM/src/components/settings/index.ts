/**
 * Settings Components Barrel Export
 * Agent CRM-20 Implementation
 */

// Main Settings Page
export { CRMSettings, type CRMSettingsProps } from './CRMSettings';

// Pipeline Settings
export { PipelineSettings, type PipelineSettingsProps } from './PipelineSettings';
export { StageList, type StageListProps } from './StageList';
export { StageEditor, type StageEditorProps, type StageFormData } from './StageEditor';

// Team Settings
export { TeamSettings, type TeamSettingsProps } from './TeamSettings';
export { TeamMemberRow, type TeamMemberRowProps } from './TeamMemberRow';

// Custom Fields
export { CustomFieldsSettings, type CustomFieldsSettingsProps } from './CustomFieldsSettings';
export { WorkspaceSettings } from './WorkspaceSettings';

// Lead Scoring (Agent CRM-40)
export { LeadScoringSettings, type LeadScoringSettingsProps } from './LeadScoringSettings';

// Deal Rotting (Agent CRM-41)
export { DealRottingSettings, type DealRottingSettingsProps } from './DealRottingSettings';

// Automation (Agent Automation MVP)
export { AutomationSettings } from './AutomationSettings';
