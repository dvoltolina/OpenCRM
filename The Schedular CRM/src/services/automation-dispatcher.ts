/**
 * Lightweight dispatcher for automation triggers.
 * Fire-and-forget to avoid blocking user actions; guarded by feature flag.
 */
import { getFeatureFlags } from '../config/features';
import { triggerAutomationEvent } from './cloud-functions-integration';
import type {
  AutomationRelatedEntityType,
  AutomationReminderType,
  AutomationTriggerType,
} from '../types/automation';
import type { LeadStatus } from '../types/models';

interface DispatchPayload {
  triggerType: AutomationTriggerType;
  entityId: string;
  entityType: 'lead' | 'deal' | 'contact' | 'company' | 'activity';
  businessId: string;
  correlationId?: string;
  fromStatus?: LeadStatus;
  toStatus?: LeadStatus;
  fromStageId?: string;
  toStageId?: string;
  overdueDays?: number;
  reminderType?: AutomationReminderType;
  relatedEntityId?: string;
  relatedEntityType?: AutomationRelatedEntityType;
}

function makeCorrelationId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return `auto-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
}

export async function dispatchAutomationEvent(payload: DispatchPayload): Promise<void> {
  if (!getFeatureFlags().enableAutomation) return;

  try {
    await triggerAutomationEvent({
      ...payload,
      correlationId: payload.correlationId || makeCorrelationId(),
      dryRun: false,
      businessId: payload.businessId,
    });
  } catch {
    // Soft-fail; avoid leaking PHI in logs
    console.warn('Automation dispatch failed');
  }
}
