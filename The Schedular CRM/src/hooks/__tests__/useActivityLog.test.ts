import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useActivityLog } from '../useActivityLog';

const mockCreateTask = vi.fn();

vi.mock('../../services/activity-service', () => ({
  getActivityService: () => ({
    createTask: mockCreateTask,
  }),
}));

const crmUser = {
  id: 'user-123',
  businessId: 'business-123',
  displayName: 'Agent One',
  email: 'agent@example.com',
  role: 'admin' as const,
  teamIds: ['team-a'],
  managedTeamIds: ['team-b'],
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser,
    businessId: 'business-123',
  }),
}));

describe('useActivityLog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockCreateTask.mockResolvedValue({ success: true, data: { id: 'task-1' } });
  });

  it('passes full SecurityContext with team scope to createTask', async () => {
    const { result } = renderHook(() => useActivityLog());

    await act(async () => {
      await result.current.createTask({
        title: 'Follow up',
        description: 'Call the client',
        dueDate: new Date('2025-01-01T10:00:00Z'),
        dealId: 'deal-1',
      });
    });

    expect(mockCreateTask).toHaveBeenCalledTimes(1);
    const [contextArg, payloadArg] = mockCreateTask.mock.calls[0];

    expect(contextArg.businessId).toBe('business-123');
    expect(contextArg.teamIds).toEqual(['team-a']);
    expect(contextArg.managedTeamIds).toEqual(['team-b']);
    expect(contextArg.userName).toBe('Agent One');
    expect(payloadArg.type).toBe('task');
  });
});
