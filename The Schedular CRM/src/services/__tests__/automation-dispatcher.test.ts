import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest';

const triggerAutomationEvent = vi.fn();
const getFeatureFlags = vi.fn();

vi.mock('../cloud-functions-integration', () => ({
  triggerAutomationEvent: (...args: any[]) => triggerAutomationEvent(...args),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => getFeatureFlags(),
}));

import { dispatchAutomationEvent } from '../automation-dispatcher';

describe('dispatchAutomationEvent', () => {
  beforeEach(() => {
    triggerAutomationEvent.mockResolvedValue({ success: true, runs: [] });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('does nothing when automation feature flag is disabled', async () => {
    getFeatureFlags.mockReturnValue({ enableAutomation: false } as any);

    await dispatchAutomationEvent({
      triggerType: 'leadCreated',
      entityId: 'lead-1',
      entityType: 'lead',
      businessId: 'biz-1',
    });

    expect(triggerAutomationEvent).not.toHaveBeenCalled();
  });

  it('calls triggerAutomationEvent when enabled', async () => {
    getFeatureFlags.mockReturnValue({ enableAutomation: true } as any);

    await dispatchAutomationEvent({
      triggerType: 'dealStageChanged',
      entityId: 'deal-1',
      entityType: 'deal',
      businessId: 'biz-1',
      fromStageId: 'stage-1',
      toStageId: 'stage-2',
    });

    expect(triggerAutomationEvent).toHaveBeenCalledTimes(1);
    const call = triggerAutomationEvent.mock.calls[0][0];
    expect(call.triggerType).toBe('dealStageChanged');
    expect(call.entityId).toBe('deal-1');
    expect(call.businessId).toBe('biz-1');
    expect(call.correlationId).toBeTruthy();
  });

  it('passes reminder metadata through for task-trigger dispatches', async () => {
    getFeatureFlags.mockReturnValue({ enableAutomation: true } as any);

    await dispatchAutomationEvent({
      triggerType: 'taskReminder',
      entityId: 'task-1',
      entityType: 'activity',
      businessId: 'biz-1',
      reminderType: 'due_today',
      relatedEntityId: 'contact-1',
      relatedEntityType: 'contact',
    });

    const call = triggerAutomationEvent.mock.calls[0][0];
    expect(call.reminderType).toBe('due_today');
    expect(call.relatedEntityId).toBe('contact-1');
    expect(call.relatedEntityType).toBe('contact');
  });
});
