import type {
  AutomationActionType,
  AutomationTarget,
  AutomationTriggerType,
} from '../../types/automation';

export interface AutomationOption<T extends string> {
  value: T;
  label: string;
}

const taskTriggerTypes: AutomationTriggerType[] = ['taskOverdue', 'taskSnoozed', 'taskReminder'];

const leadDealTargets: AutomationOption<AutomationTarget>[] = [
  { value: 'lead', label: 'Lead' },
  { value: 'deal', label: 'Opportunity' },
];

const leadDealContactTargets: AutomationOption<AutomationTarget>[] = [
  { value: 'lead', label: 'Lead' },
  { value: 'deal', label: 'Opportunity' },
  { value: 'contact', label: 'Contact' },
];

const taskTriggerTargets: AutomationOption<AutomationTarget>[] = [
  { value: 'lead', label: 'Lead' },
  { value: 'deal', label: 'Opportunity' },
  { value: 'contact', label: 'Contact' },
  { value: 'company', label: 'Company' },
];

export const triggerOptions: AutomationOption<AutomationTriggerType>[] = [
  { value: 'leadCreated', label: 'Lead Created' },
  { value: 'leadStatusChanged', label: 'Lead Status Changed' },
  { value: 'dealStageChanged', label: 'Opportunity Stage Changed' },
  { value: 'taskOverdue', label: 'Task Overdue' },
  { value: 'taskSnoozed', label: 'Task Snoozed' },
  { value: 'taskReminder', label: 'Task Reminder Fired' },
];

export const actionOptions: AutomationOption<AutomationActionType>[] = [
  { value: 'createTask', label: 'Create Task' },
  { value: 'sendEmailTemplate', label: 'Send Email Template' },
  { value: 'addTag', label: 'Add Tag' },
  { value: 'updateField', label: 'Update Field' },
];

export function entityTypeForTrigger(triggerType: AutomationTriggerType): 'lead' | 'deal' | 'activity' {
  switch (triggerType) {
    case 'dealStageChanged':
      return 'deal';
    case 'taskOverdue':
    case 'taskSnoozed':
    case 'taskReminder':
      return 'activity';
    default:
      return 'lead';
  }
}

export function isTaskTriggerType(triggerType: AutomationTriggerType): boolean {
  return taskTriggerTypes.includes(triggerType);
}

export function getAvailableActionOptions(
  triggerType: AutomationTriggerType
): AutomationOption<AutomationActionType>[] {
  return isTaskTriggerType(triggerType)
    ? actionOptions.filter((option) => option.value !== 'sendEmailTemplate')
    : actionOptions;
}

export function getTargetOptions(
  triggerType: AutomationTriggerType,
  actionType: AutomationActionType
): AutomationOption<AutomationTarget>[] {
  if (isTaskTriggerType(triggerType)) {
    if (actionType === 'updateField') {
      return leadDealTargets;
    }

    if (actionType === 'addTag' || actionType === 'createTask') {
      return taskTriggerTargets;
    }
  }

  switch (actionType) {
    case 'addTag':
    case 'updateField':
      return leadDealTargets;
    case 'sendEmailTemplate':
      return leadDealContactTargets;
    case 'createTask':
    default:
      return leadDealContactTargets;
  }
}

export const leadStatuses = ['new', 'contacted', 'qualified', 'unqualified', 'converted'] as const;
