import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TaskReminderService } from '../task-reminder-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { SalesActivity } from '../../types/models';

const getPendingTasksMock = vi.hoisted(() => vi.fn());
const getOverdueTasksMock = vi.hoisted(() => vi.fn());
const dispatchAutomationEventMock = vi.hoisted(() => vi.fn());
const checkRateLimitMock = vi.hoisted(() => vi.fn(async () => ({
  allowed: true,
  remaining: 100,
  resetAt: new Date(),
})));
const checkAndRecordRateLimitMock = vi.hoisted(() => vi.fn(async () => ({
  allowed: true,
  remaining: 99,
  resetAt: new Date(),
})));

const featureFlags = vi.hoisted(() => ({
  enableAutomation: true,
}));

vi.mock('../activity-service', () => ({
  getActivityService: () => ({
    getPendingTasks: getPendingTasksMock,
    getUpcomingTasks: vi.fn(),
    getOverdueTasks: getOverdueTasksMock,
  }),
}));

vi.mock('../automation-dispatcher', () => ({
  dispatchAutomationEvent: dispatchAutomationEventMock,
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => featureFlags,
}));

vi.mock('../RateLimitService', () => ({
  checkRateLimit: checkRateLimitMock,
  checkAndRecordRateLimit: checkAndRecordRateLimitMock,
}));

const context: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'owner',
  teamIds: [],
  managedTeamIds: [],
};

function buildOverdueActivity(): SalesActivity {
  const dueDate = new Date();
  dueDate.setDate(dueDate.getDate() - 2); // two days overdue

  return {
    id: 'task-1',
    type: 'task',
    title: 'Follow up',
    isCompleted: false,
    createdById: 'user-1',
    createdByName: 'Test User',
    createdAt: new Date(),
    dueDate,
    leadId: 'lead-1',
  };
}

describe('TaskReminderService automation dispatch', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2025-12-05T12:00:00Z'));
    const storage: Record<string, string> = {};
    (globalThis as any).localStorage = {
      getItem: (key: string) => (key in storage ? storage[key] : null),
      setItem: (key: string, value: string) => {
        storage[key] = value;
      },
      removeItem: (key: string) => {
        delete storage[key];
      },
    };
    getPendingTasksMock.mockReset();
    getOverdueTasksMock.mockReset();
    dispatchAutomationEventMock.mockReset();
    checkRateLimitMock.mockClear();
    checkAndRecordRateLimitMock.mockClear();
    checkRateLimitMock.mockResolvedValue({
      allowed: true,
      remaining: 100,
      resetAt: new Date(),
    });
    checkAndRecordRateLimitMock.mockResolvedValue({
      allowed: true,
      remaining: 99,
      resetAt: new Date(),
    });
    featureFlags.enableAutomation = true;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('dispatches taskOverdue automation once per task correlation', async () => {
    getPendingTasksMock.mockResolvedValue({ success: true, data: [buildOverdueActivity()] });

    const service = new TaskReminderService();
    await service.getReminders(context);
    await Promise.resolve();

    expect(dispatchAutomationEventMock).toHaveBeenCalledTimes(1);
    const payload = dispatchAutomationEventMock.mock.calls[0][0];
    expect(payload.triggerType).toBe('taskOverdue');
    expect(payload.entityId).toBe('task-1');
    expect(payload.entityType).toBe('activity');
    expect(payload.correlationId).toContain('task-1');
    expect(payload.overdueDays).toBeGreaterThanOrEqual(1);
    expect(payload.relatedEntityId).toBe('lead-1');
    expect(payload.relatedEntityType).toBe('lead');
  });

  it('does not re-dispatch for the same overdue task correlation', async () => {
    getPendingTasksMock.mockResolvedValue({ success: true, data: [buildOverdueActivity()] });

    const service = new TaskReminderService();
    await service.getReminders(context);
    await Promise.resolve();

    dispatchAutomationEventMock.mockClear();

    await service.getReminders(context);
    await Promise.resolve();

    expect(dispatchAutomationEventMock).not.toHaveBeenCalled();
  });

  it('skips automation dispatch when feature flag is disabled', async () => {
    featureFlags.enableAutomation = false;
    getPendingTasksMock.mockResolvedValue({ success: true, data: [buildOverdueActivity()] });

    const service = new TaskReminderService();
    await service.getReminders(context);
    await Promise.resolve();

    expect(dispatchAutomationEventMock).not.toHaveBeenCalled();
  });

  it('dispatches reminder hooks when reminderAt is elapsed', async () => {
    const upcoming: SalesActivity = {
      id: 'task-2',
      type: 'task',
      title: 'Prep deck',
    isCompleted: false,
    createdById: 'user-1',
    createdByName: 'Test User',
    createdAt: new Date('2025-12-05T10:00:00Z'),
    dueDate: new Date('2025-12-05T18:00:00Z'),
    reminderAt: new Date('2025-12-05T11:00:00Z'),
    leadId: 'lead-123',
  };

    getPendingTasksMock.mockResolvedValue({ success: true, data: [upcoming] });

    const service = new TaskReminderService();
    const result = await service.getReminders(context);
    expect(result.data?.[0]?.reminderAt).toBeDefined();
    expect(checkAndRecordRateLimitMock).toHaveBeenCalled();

    expect(dispatchAutomationEventMock).toHaveBeenCalledTimes(1);
    const payload = dispatchAutomationEventMock.mock.calls[0][0];
    expect(payload.triggerType).toBe('taskReminder');
    expect(payload.relatedEntityId).toBe('lead-123');
    expect(payload.relatedEntityType).toBe('lead');
    expect(payload.reminderType).toBe('due_today');
  });

  it('computes reminderAt from template defaults when missing', async () => {
    const slaAt = new Date('2025-12-05T16:00:00Z');
    const noReminder: SalesActivity = {
      id: 'task-template',
      type: 'task',
      title: 'Contract follow-up',
      templateId: 'contract-follow-up',
      slaAt,
      dueDate: new Date('2025-12-05T18:00:00Z'),
      isCompleted: false,
      createdById: 'user-1',
      createdByName: 'Test User',
      createdAt: new Date('2025-12-05T10:00:00Z'),
      leadId: 'lead-123',
    };

    getPendingTasksMock.mockResolvedValue({ success: true, data: [noReminder] });

    const service = new TaskReminderService();
    const result = await service.getReminders(context);

    expect(result.data?.[0]?.reminderAt).toBeInstanceOf(Date);
    expect(result.data?.[0]?.reminderAt?.getTime()).toBe(
      new Date('2025-12-05T14:30:00Z').getTime()
    );
    expect(dispatchAutomationEventMock).not.toHaveBeenCalled();
  });
});
