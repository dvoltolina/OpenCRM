import {
  type AutomationRule,
  type MessageHistory,
  type MessageTemplate,
} from '../types/models';
import { assertDemoMutationAllowed } from '../config/demo';
import { logAuditEvent } from './auditLog';
import {
  callTenantFunction,
  fetchCollection,
  postTenantEndpoint,
  scopedCollection,
} from './firestoreBase';

export type SendTestMessageResult = {
  success?: boolean;
  messageId?: string;
  renderedPreview?: string;
  variables?: Record<string, string>;
  error?: string;
};

// Message Templates
export async function listTemplates(businessId: string, userId?: string): Promise<MessageTemplate[]> {
  const scoped = scopedCollection<MessageTemplate>(businessId, ['message_templates']);
  const results = await fetchCollection(scoped);
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'MessageTemplate',
    entityId: businessId,
    metadata: { source: 'listTemplates', count: results.length },
  });
  return results;
}

export async function saveTemplate(
  businessId: string,
  template: Partial<MessageTemplate>,
  userId?: string,
): Promise<void> {
  assertDemoMutationAllowed('save message template');
  if (!businessId) throw new Error('businessId is required to save a template');
  await callTenantFunction('communications-saveTemplate', businessId, { template });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'MessageTemplate',
    entityId: template.id ?? 'new',
    metadata: { source: 'saveTemplate' },
  });
}

export async function deleteTemplate(businessId: string, templateId: string, userId?: string): Promise<void> {
  assertDemoMutationAllowed('delete message template');
  if (!businessId) throw new Error('businessId is required to delete a template');
  await callTenantFunction('communications-deleteTemplate', businessId, { templateId });
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'MessageTemplate',
    entityId: templateId,
    metadata: { source: 'deleteTemplate' },
  });
}

// Automation Rules
export async function listAutomationRules(businessId: string): Promise<AutomationRule[]> {
  const scoped = scopedCollection<AutomationRule>(businessId, ['automation_rules']);
  return fetchCollection(scoped);
}

export async function updateAutomationRule(
  businessId: string,
  ruleId: string,
  updates: Partial<AutomationRule>,
): Promise<void> {
  assertDemoMutationAllowed('update automation rule');
  if (!businessId) throw new Error('businessId is required to update an automation rule');
  await callTenantFunction('communications-updateAutomationRule', businessId, {
    ruleId,
    updates,
  });
}

// Message History
export async function listMessageHistory(
  businessId: string,
  limit: number = 50
): Promise<MessageHistory[]> {
  const scoped = scopedCollection<MessageHistory>(businessId, ['message_history']);
  // In real implementation, would add orderBy and limit constraints
  const results = await fetchCollection(scoped);
  await logAuditEvent({
    businessId,
    actionType: 'phiReadList',
    entityType: 'MessageHistory',
    entityId: businessId,
    metadata: { source: 'listMessageHistory', count: results.length, limit },
  });
  return results;
}

// Test Send
export async function sendTestMessage(
  businessId: string,
  templateId: string,
  recipient: string,
  channel: 'email' | 'sms',
): Promise<SendTestMessageResult> {
  assertDemoMutationAllowed('send test message');
  if (!businessId) throw new Error('businessId is required to send a test message');
  return postTenantEndpoint('/sendTestMessage', businessId, {
    templateId,
    recipient,
    channel,
  });
}
