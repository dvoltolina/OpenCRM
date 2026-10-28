import { describe, it, expect, vi } from 'vitest';
import { AutomationRuleRepository } from '../automation-repository';
import type { SecurityContext } from '../repository-types';
import type { AutomationRule } from '../../../types/automation';

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(),
  onSnapshot: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  writeBatch: vi.fn().mockReturnValue({
    set: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    commit: vi.fn(),
  }),
  Timestamp: {
    now: vi.fn(),
    fromDate: vi.fn(),
  },
}));

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('../../../lib/collections', () => ({
  businessPath: vi.fn((businessId: string) => `businesses/${businessId}`),
}));

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-2',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: [],
  managedTeamIds: [],
};

const managerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-3',
  userName: 'Manager User',
  userRole: 'manager',
  teamIds: ['team-1'],
  managedTeamIds: ['team-1'],
};

const validRuleInput: Omit<AutomationRule, 'id' | 'createdAt' | 'updatedAt'> = {
  name: 'New Lead Task',
  description: 'Follow up when a lead is created',
  trigger: { type: 'leadCreated' },
  action: {
    type: 'createTask',
    target: 'lead',
    taskTemplate: { title: 'Follow up', dueInDays: 1, activityType: 'task' },
  },
  status: 'enabled',
  businessId: 'biz-1',
  createdById: 'user-1',
  createdByName: 'Admin User',
  ownerId: 'user-1',
  ownerName: 'Admin User',
  teamIds: [],
  visibility: 'team',
};

describe('AutomationRuleRepository RBAC and validation', () => {
  const repo = new AutomationRuleRepository();

  it('rejects automation rule creation for non-privileged roles', async () => {
    const result = await repo.create(staffContext, validRuleInput);
    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('validates required trigger/action fields on create', async () => {
    const result = await repo.create(adminContext, {
      ...validRuleInput,
      name: '',
      trigger: undefined as any,
      action: undefined as any,
    });
    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('VALIDATION_ERROR');
  });

  it('blocks status updates for unauthorized roles', async () => {
    const result = await repo.setStatus(staffContext, 'rule-1', 'enabled');
    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('validates reminder type for task reminder triggers', async () => {
    const result = await repo.create(adminContext, {
      ...validRuleInput,
      trigger: {
        type: 'taskReminder',
        reminderType: 'not-real' as any,
      },
    });
    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('VALIDATION_ERROR');
  });

  it('blocks manager deletes so rule removal stays owner or admin only', async () => {
    const result = await repo.delete(managerContext, 'rule-1');
    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });
});
