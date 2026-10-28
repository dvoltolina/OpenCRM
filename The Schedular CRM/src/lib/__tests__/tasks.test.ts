import { describe, it, expect, vi } from 'vitest';
import { applyTaskTemplate, getDefaultTaskTemplate } from '../../config/taskTemplates';
import { evaluateTaskSla } from '../tasks';
import type { SalesActivity } from '../../types/models';

describe('task template helpers', () => {
  it('applies template with due, sla, and reminder times', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2025-12-01T10:00:00Z'));

    const template = getDefaultTaskTemplate('qualified');
    expect(template).toBeDefined();
    const applied = applyTaskTemplate(template!);

    expect(applied.dueDate.getTime()).toBeGreaterThan(Date.now());
    expect(applied.slaAt.getTime()).toBeGreaterThan(Date.now());
    expect(applied.reminderAt.getTime()).toBeLessThan(applied.slaAt.getTime());

    vi.useRealTimers();
  });

  it('flags tasks as at-risk near SLA target', () => {
    const task: SalesActivity = {
      id: 'task-123',
      type: 'task',
      title: 'At risk task',
      isCompleted: false,
      createdById: 'user-1',
      createdByName: 'Test User',
      createdAt: new Date(),
      dueDate: new Date(Date.now() + 30 * 60 * 1000),
      slaMinutes: 60,
    };

    const evaluationTime = new Date(Date.now() + 10 * 60 * 1000);
    const state = evaluateTaskSla(task, evaluationTime);
    expect(state.status).toBe('atRisk');
  });
});
