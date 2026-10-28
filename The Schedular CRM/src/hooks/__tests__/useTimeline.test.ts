import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useRecentActivities } from '../useTimeline';

const mockGetRecentActivities = vi.fn();

vi.mock('../../services/activity-service', () => ({
  getActivityService: () => ({
    getRecentActivities: mockGetRecentActivities,
  }),
}));

const crmUser = {
  id: 'user-456',
  businessId: 'biz-789',
  displayName: '',
  email: 'agent@example.com',
  role: 'manager' as const,
  teamIds: ['team-1'],
  managedTeamIds: ['team-2'],
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser,
    businessId: 'biz-789',
  }),
}));

describe('useTimeline', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockGetRecentActivities.mockResolvedValue({ success: true, data: [] });
  });

  it('builds a team-aware SecurityContext when fetching recent activities', async () => {
    renderHook(() => useRecentActivities(7, 5));

    await waitFor(() => {
      expect(mockGetRecentActivities).toHaveBeenCalled();
    });

    const [contextArg, daysArg, limitArg] = mockGetRecentActivities.mock.calls[0];

    expect(contextArg.businessId).toBe('biz-789');
    expect(contextArg.teamIds).toEqual(['team-1']);
    expect(contextArg.managedTeamIds).toEqual(['team-2']);
    expect(contextArg.userName).toBe('agent@example.com');
    expect(daysArg).toBe(7);
    expect(limitArg).toBe(5);
  });
});
