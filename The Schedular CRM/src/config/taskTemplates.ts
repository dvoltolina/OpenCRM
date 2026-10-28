/**
 * Task Templates
 * Lightweight, client-side templates for repeatable task logging.
 *
 * These stay config-driven so tenants can adjust quickly without code changes.
 * Templates avoid PHI and only include metadata (titles + time expectations).
 */

export type TaskTemplateId = 'first-touch' | 'demo-prep' | 'contract-follow-up';

export interface TaskTemplate {
  id: TaskTemplateId | string;
  /** User-facing label shown in pickers */
  label: string;
  /** Helper text to describe when to use the template */
  summary: string;
  /** Default task title */
  title: string;
  /** Hours from now until due */
  dueInHours: number;
  /** SLA window in minutes (breach after this many minutes if incomplete) */
  slaMinutes: number;
  /** Minutes before the SLA target to trigger reminder hooks */
  reminderMinutesBefore?: number;
  /** Stage-name matches that should favor this template */
  stageMatches?: string[];
}

const BASE_TEMPLATES: TaskTemplate[] = [
  {
    id: 'first-touch',
    label: 'First Touch (8h SLA)',
    summary: 'Initial response on new leads or early-stage deals',
    title: 'First touch follow-up',
    dueInHours: 24,
    slaMinutes: 8 * 60,
    reminderMinutesBefore: 60,
    stageMatches: ['lead', 'new', 'prospecting', 'qualified'],
  },
  {
    id: 'demo-prep',
    label: 'Demo Prep (24h SLA)',
    summary: 'Prep assets and agenda before a scheduled demo',
    title: 'Prep for demo',
    dueInHours: 48,
    slaMinutes: 24 * 60,
    reminderMinutesBefore: 120,
    stageMatches: ['demo', 'proposal', 'presentation'],
  },
  {
    id: 'contract-follow-up',
    label: 'Contract Follow-up (12h SLA)',
    summary: 'Chase signatures or revisions in negotiation/contract',
    title: 'Follow up on contract',
    dueInHours: 24,
    slaMinutes: 12 * 60,
    reminderMinutesBefore: 90,
    stageMatches: ['negotiation', 'contract', 'closing'],
  },
];

const STAGE_DEFAULTS: Record<string, TaskTemplateId> = {
  qualified: 'first-touch',
  prospecting: 'first-touch',
  proposal: 'demo-prep',
  demo: 'demo-prep',
  negotiation: 'contract-follow-up',
  contracting: 'contract-follow-up',
};

type PipelineTemplateConfig = {
  defaultTemplateId?: TaskTemplateId;
  stageDefaults?: Record<string, TaskTemplateId>;
};

// Per-pipeline overrides (customizable by tenants via config deployment)
const PIPELINE_TEMPLATES: Record<string, PipelineTemplateConfig> = {
  // Example: 'pipeline-enterprise': { defaultTemplateId: 'contract-follow-up' }
};

function normalizeStageName(stageName?: string): string {
  return (stageName || '').trim().toLowerCase();
}

/**
 * Return all templates, sorted with the stage-matched default first.
 */
export function getTaskTemplates(stageName?: string, pipelineId?: string): TaskTemplate[] {
  const defaultTemplate = getDefaultTaskTemplate(stageName, pipelineId);

  const unique = new Map<string, TaskTemplate>();
  BASE_TEMPLATES.forEach((template) => unique.set(template.id, template));

  const templates = Array.from(unique.values());

  if (!defaultTemplate) return templates;

  const sorted = templates.filter((t) => t.id !== defaultTemplate.id);
  return [defaultTemplate, ...sorted];
}

/**
 * Get the best-fit template for a stage name.
 */
export function getDefaultTaskTemplate(stageName?: string, pipelineId?: string): TaskTemplate | undefined {
  const normalized = normalizeStageName(stageName);
  if (!normalized && !pipelineId) return BASE_TEMPLATES[0];

  if (pipelineId) {
    const pipelineConfig = PIPELINE_TEMPLATES[pipelineId];
    const stageOverrideId = pipelineConfig?.stageDefaults?.[normalized];
    if (stageOverrideId) {
      const stageOverride = BASE_TEMPLATES.find((t) => t.id === stageOverrideId);
      if (stageOverride) return stageOverride;
    }
    if (pipelineConfig?.defaultTemplateId) {
      const pipelineDefault = BASE_TEMPLATES.find((t) => t.id === pipelineConfig.defaultTemplateId);
      if (pipelineDefault) return pipelineDefault;
    }
  }

  const byStageMapId = STAGE_DEFAULTS[normalized];
  if (byStageMapId) {
    const match = BASE_TEMPLATES.find((t) => t.id === byStageMapId);
    if (match) return match;
  }

  const matched = BASE_TEMPLATES.find((template) =>
    template.stageMatches?.some((match) => normalized.includes(match))
  );

  return matched || BASE_TEMPLATES[0];
}

export interface AppliedTaskTemplate {
  title: string;
  dueDate: Date;
  slaAt: Date;
  reminderAt: Date;
  slaMinutes: number;
  templateId: TaskTemplate['id'];
}

/**
 * Apply a template to generate due/SLA/reminder timestamps.
 * Falls back to sane defaults if dates would be in the past.
 */
export function applyTaskTemplate(
  template: TaskTemplate,
  now: Date = new Date()
): AppliedTaskTemplate {
  const dueDate = new Date(now.getTime() + template.dueInHours * 60 * 60 * 1000);
  const slaAt = new Date(now.getTime() + template.slaMinutes * 60 * 1000);

  const reminderMinutes = template.reminderMinutesBefore ?? Math.min(template.slaMinutes, 90);
  const reminderAtCandidate = new Date(slaAt.getTime() - reminderMinutes * 60 * 1000);
  const reminderAt =
    reminderAtCandidate.getTime() <= now.getTime()
      ? new Date(now.getTime() + 30 * 60 * 1000)
      : reminderAtCandidate;

  return {
    title: template.title,
    dueDate,
    slaAt,
    reminderAt,
    slaMinutes: template.slaMinutes,
    templateId: template.id,
  };
}
