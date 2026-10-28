import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AutomationEngine } from '../automation-engine';
import type { AutomationRule } from '../../types/automation';
import type { SecurityContext } from '../../data/repositories/repository-types';

const rateLimitCheckMock = vi.fn();
const rateLimitRecordMock = vi.fn();
const logRunMock = vi.fn();
const getByCorrelationMock = vi.fn();
const getByTriggerMock = vi.fn();
const auditLogMock = vi.fn();
const logActivityMock = vi.fn();
const sendEmailMock = vi.fn();
const leadUpdateMock = vi.fn();
const dealUpdateMock = vi.fn();
const contactUpdateMock = vi.fn();
const companyUpdateMock = vi.fn();

vi.mock('../RateLimitService', () => ({
  getRateLimitService: () => ({
    checkLimit: rateLimitCheckMock,
    recordAction: rateLimitRecordMock,
  }),
}));

vi.mock('../activity-service', () => ({
  ActivityService: vi.fn().mockImplementation(() => ({
    logActivity: logActivityMock,
  })),
}));

vi.mock('../email-service', () => ({
  EmailService: vi.fn().mockImplementation(() => ({
    sendEmail: sendEmailMock,
  })),
}));

vi.mock('../../data/repositories/lead-repository', () => ({
  LeadRepository: vi.fn().mockImplementation(() => ({
    update: leadUpdateMock,
    getById: vi.fn().mockResolvedValue({ success: true, data: { id: 'lead1', tags: [] } }),
  })),
}));

vi.mock('../../data/repositories/deal-repository', () => ({
  DealRepository: vi.fn().mockImplementation(() => ({
    update: dealUpdateMock,
    getById: vi.fn().mockResolvedValue({ success: true, data: { id: 'deal1', tags: [] } }),
  })),
}));

vi.mock('../../data/repositories/contact-repository', () => ({
  ContactRepository: vi.fn().mockImplementation(() => ({
    update: contactUpdateMock,
    getById: vi.fn().mockResolvedValue({ success: true, data: { id: 'contact1', tags: [] } }),
  })),
}));

vi.mock('../../data/repositories/company-repository', () => ({
  CompanyRepository: vi.fn().mockImplementation(() => ({
    update: companyUpdateMock,
    getById: vi.fn().mockResolvedValue({ success: true, data: { id: 'company1', tags: [] } }),
  })),
}));

vi.mock('../AuditLogService', () => ({
  AuditLogService: vi.fn().mockImplementation(() => ({
    logAction: auditLogMock,
  })),
}));

vi.mock('../../data/repositories/automation-repository', () => ({
  getAutomationRuleRepository: () => ({
    getByTriggerType: getByTriggerMock,
  }),
  getAutomationRunRepository: () => ({
    logRun: logRunMock,
    getByCorrelationId: getByCorrelationMock,
  }),
}));

const baseContext: SecurityContext = {
  businessId: 'biz',
  userId: 'user',
  userName: 'User',
  userRole: 'owner',
  teamIds: [],
  managedTeamIds: [],
};

const baseRule: AutomationRule = {
  id: 'rule1',
  name: 'Test Rule',
  trigger: { type: 'leadCreated' },
  action: {
    type: 'createTask',
    target: 'lead',
    taskTemplate: { title: 'Follow up', dueInDays: 1, activityType: 'task' },
  },
  status: 'enabled',
  businessId: 'biz',
  createdById: 'user',
  createdByName: 'User',
  createdAt: new Date(),
  ownerId: 'user',
  ownerName: 'User',
  teamIds: [],
};

describe('AutomationEngine', () => {
  const runStore = new Set<string>();

  beforeEach(() => {
    rateLimitCheckMock.mockReset();
    rateLimitRecordMock.mockReset();
    logRunMock.mockReset();
    getByCorrelationMock.mockReset();
    getByTriggerMock.mockReset();
    auditLogMock.mockReset();
    logActivityMock.mockReset();
    sendEmailMock.mockReset();
    leadUpdateMock.mockReset();
    dealUpdateMock.mockReset();
    contactUpdateMock.mockReset();
    companyUpdateMock.mockReset();
    leadUpdateMock.mockResolvedValue({ success: true, data: {} });
    dealUpdateMock.mockResolvedValue({ success: true, data: {} });
    contactUpdateMock.mockResolvedValue({ success: true, data: {} });
    companyUpdateMock.mockResolvedValue({ success: true, data: {} });
    sendEmailMock.mockResolvedValue({ success: true });

    runStore.clear();

    getByCorrelationMock.mockImplementation(async (_ctx, correlationId: string, ruleId?: string) => {
      const key = `${ruleId || 'any'}:${correlationId}`;
      return { success: true, data: runStore.has(key) ? { id: key } : null };
    });
    logRunMock.mockImplementation(async (_ctx, payload) => {
      const key = `${(payload as any).ruleId}:${(payload as any).correlationId}`;
      if ((payload as any).ruleId && (payload as any).correlationId) {
        runStore.add(key);
      }
      return { success: true, data: payload };
    });
  });

  it('skips execution when correlation already exists', async () => {
    const engine = new AutomationEngine();
    runStore.add('rule1:corr-1');

    const result = await engine.executeRule(baseContext, baseRule, {
      triggerType: 'leadCreated',
      entityId: 'lead1',
      entityType: 'lead',
      correlationId: 'corr-1',
    });

    expect(result.allowed).toBe(false);
    expect(logRunMock).not.toHaveBeenCalled();
  });

  it('returns rate_limited when rate limit denied', async () => {
    const engine = new AutomationEngine();
    getByCorrelationMock.mockResolvedValue({ success: true, data: null });
    rateLimitCheckMock.mockResolvedValue({ allowed: false, message: 'Rate limited', remaining: 0, resetAt: new Date() });

    const result = await engine.executeRule(baseContext, baseRule, {
      triggerType: 'leadCreated',
      entityId: 'lead1',
      entityType: 'lead',
      correlationId: 'corr-2',
    });

    expect(result.allowed).toBe(false);
    expect(logRunMock).toHaveBeenCalled();
  });

  it('logs success when action succeeds', async () => {
    const engine = new AutomationEngine();
    getByCorrelationMock.mockResolvedValue({ success: true, data: null });
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 10, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });

    const result = await engine.executeRule(baseContext, baseRule, {
      triggerType: 'leadCreated',
      entityId: 'lead1',
      entityType: 'lead',
      correlationId: 'corr-3',
    });

    expect(result.allowed).toBe(true);
    expect(logRunMock).toHaveBeenCalled();
    expect(auditLogMock).toHaveBeenCalled();
  });

  it('updates fields on lead targets for updateField actions', async () => {
    const engine = new AutomationEngine();
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 10, resetAt: new Date() });

    const fieldRule: AutomationRule = {
      ...baseRule,
      id: 'rule-field',
      action: { type: 'updateField', target: 'lead', fieldUpdate: { field: 'status', value: 'qualified' } },
    };

    const result = await engine.executeRule(baseContext, fieldRule, {
      triggerType: 'leadStatusChanged',
      entityId: 'lead1',
      entityType: 'lead',
      correlationId: 'corr-field',
    });

    expect(result.allowed).toBe(true);
    expect(leadUpdateMock).toHaveBeenCalledWith(baseContext, 'lead1', { status: 'qualified' });
    expect(logRunMock).toHaveBeenCalled();
  });

  it('returns failure when email action fails to send', async () => {
    const engine = new AutomationEngine();
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 5, resetAt: new Date() });
    sendEmailMock.mockResolvedValue({ success: false, error: 'template_missing' });

    const emailRule: AutomationRule = {
      ...baseRule,
      id: 'rule-email',
      action: { type: 'sendEmailTemplate', target: 'lead', emailTemplate: { templateId: 'tmpl-1', recipient: 'lead' } },
    };

    const result = await engine.executeRule(baseContext, emailRule, {
      triggerType: 'leadCreated',
      entityId: 'lead1',
      entityType: 'lead',
      correlationId: 'corr-email',
    });

    expect(result.allowed).toBe(false);
    expect(logRunMock).toHaveBeenCalled();
  });

  it('filters rules by trigger match when handling events', async () => {
    const engine = new AutomationEngine();
    getByCorrelationMock.mockResolvedValue({ success: true, data: null });
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 5, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });

    getByTriggerMock.mockResolvedValue({
      success: true,
      data: {
        data: [
          baseRule,
          {
            ...baseRule,
            id: 'rule-2',
            trigger: { type: 'leadStatusChanged', fromStatus: 'new', toStatus: 'qualified' },
          },
        ],
        lastDoc: null,
        hasMore: false,
      },
      error: null,
    });

    const results = await engine.handleEvent(baseContext, {
      triggerType: 'leadStatusChanged',
      entityId: 'lead-123',
      entityType: 'lead',
      correlationId: 'corr-4',
      fromStatus: 'new',
      toStatus: 'qualified',
    });

    expect(results).toHaveLength(1);
    expect(logActivityMock).toHaveBeenCalledTimes(1);
    expect(logRunMock).toHaveBeenCalledTimes(1);
  });

  it('matches task reminder rules by reminder type', async () => {
    const engine = new AutomationEngine();
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 5, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });

    getByTriggerMock.mockResolvedValue({
      success: true,
      data: {
        data: [
          {
            ...baseRule,
            id: 'rule-reminder-any',
            trigger: { type: 'taskReminder' },
            action: { type: 'createTask', target: 'lead', taskTemplate: { title: 'Follow up reminder' } },
          },
          {
            ...baseRule,
            id: 'rule-reminder-match',
            trigger: { type: 'taskReminder', reminderType: 'due_today' },
            action: { type: 'createTask', target: 'lead', taskTemplate: { title: 'Same-day follow up' } },
          },
          {
            ...baseRule,
            id: 'rule-reminder-skip',
            trigger: { type: 'taskReminder', reminderType: 'upcoming' },
            action: { type: 'createTask', target: 'lead', taskTemplate: { title: 'Skip me' } },
          },
        ],
        lastDoc: null,
        hasMore: false,
      },
      error: null,
    });

    const results = await engine.handleEvent(baseContext, {
      triggerType: 'taskReminder',
      entityId: 'task-123',
      entityType: 'activity',
      relatedEntityId: 'lead-123',
      relatedEntityType: 'lead',
      correlationId: 'corr-reminder',
      reminderType: 'due_today',
    });

    expect(results).toHaveLength(2);
    expect(logActivityMock).toHaveBeenCalledTimes(2);
  });

  it('uses the related entity for task-based task creation', async () => {
    const engine = new AutomationEngine();
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 10, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });

    const reminderRule: AutomationRule = {
      ...baseRule,
      id: 'rule-task-reminder',
      trigger: { type: 'taskReminder', reminderType: 'due_today' },
      action: {
        type: 'createTask',
        target: 'contact',
        taskTemplate: { title: 'Call the contact', dueInDays: 1, activityType: 'task' },
      },
    };

    const result = await engine.executeRule(baseContext, reminderRule, {
      triggerType: 'taskReminder',
      entityId: 'task-1',
      entityType: 'activity',
      relatedEntityId: 'contact-42',
      relatedEntityType: 'contact',
      reminderType: 'due_today',
      correlationId: 'corr-task-reminder',
    });

    expect(result.allowed).toBe(true);
    expect(logActivityMock).toHaveBeenCalledWith(
      baseContext,
      expect.objectContaining({
        clientId: 'contact-42',
      })
    );
  });

  it('executes multiple matching rules even when sharing a correlation id', async () => {
    const engine = new AutomationEngine();
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 5, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });
    getByTriggerMock.mockResolvedValue({
      success: true,
      data: {
        data: [
          baseRule,
          {
            ...baseRule,
            id: 'rule-2',
            trigger: { type: 'leadCreated' },
            action: { type: 'addTag', target: 'lead', tag: 'vip' },
          },
        ],
        lastDoc: null,
        hasMore: false,
      },
      error: null,
    });

    const results = await engine.handleEvent(baseContext, {
      triggerType: 'leadCreated',
      entityId: 'lead-abc',
      entityType: 'lead',
      correlationId: 'corr-shared',
    });

    expect(results).toHaveLength(2);
    expect(logRunMock).toHaveBeenCalledTimes(2);
  });

  it('creates audit entry for dry-run simulations without persisting runs', async () => {
    const engine = new AutomationEngine();
    getByCorrelationMock.mockResolvedValue({ success: true, data: null });
    rateLimitCheckMock.mockResolvedValue({ allowed: true, remaining: 5, resetAt: new Date() });
    logActivityMock.mockResolvedValue({ success: true, data: {} });

    const result = await engine.executeRule(baseContext, baseRule, {
      triggerType: 'leadCreated',
      entityId: 'lead-xyz',
      entityType: 'lead',
      correlationId: 'corr-dry',
      dryRun: true,
    });

    expect(result.allowed).toBe(true);
    expect(auditLogMock).toHaveBeenCalled();
    expect(logRunMock).not.toHaveBeenCalled();
  });
});
