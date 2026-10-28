import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { TaskReminderCard } from '../TaskReminderCard';
import type { TaskReminder } from '../../../services/task-reminder-service';

const markReadMock = vi.fn();
const dismissReminderMock = vi.fn();
const snoozeReminderMock = vi.fn();

vi.mock('../../../contexts/NotificationContext', () => ({
  useNotifications: () => ({
    markRead: markReadMock,
    dismissReminder: dismissReminderMock,
  }),
}));

vi.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Test User',
      role: 'admin',
    },
    businessId: 'business-1',
  }),
}));

vi.mock('../../../services/activity-service', () => ({
  getActivityService: () => ({
    completeTask: vi.fn().mockResolvedValue({ success: true }),
  }),
}));

vi.mock('../../../hooks/usePipeline', () => ({
  createSecurityContext: (
    businessId: string,
    userId: string,
    userName?: string,
    userRole?: string
  ) => ({
    businessId,
    userId,
    userName,
    userRole,
  }),
}));

vi.mock('../../../services/task-reminder-service', () => ({
  getTaskReminderService: () => ({
    snoozeReminder: snoozeReminderMock.mockResolvedValue({
      success: true,
    }),
  }),
}));

vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

describe('TaskReminderCard', () => {
  beforeEach(() => {
    markReadMock.mockClear();
    dismissReminderMock.mockClear();
    snoozeReminderMock.mockClear();
  });

  it('snoozes a reminder by 24 hours and dismisses it', async () => {
    const reminder: TaskReminder = {
      id: 'rem-1',
      taskId: 'task-1',
      taskTitle: 'Follow up with client',
      entityType: 'deal',
      entityId: 'deal-1',
      entityName: 'Deal 1',
      dueDate: new Date('2025-12-02T12:00:00Z'),
      reminderAt: new Date('2025-12-02T11:00:00Z'),
      slaAt: new Date('2025-12-02T10:00:00Z'),
      reminderType: 'upcoming',
      daysUntilDue: 1,
      isRead: false,
      createdAt: new Date('2025-12-01T11:00:00Z'),
    };

    render(<TaskReminderCard reminder={reminder} />);

    fireEvent.click(screen.getByText('Snooze'));

    await waitFor(() => expect(snoozeReminderMock).toHaveBeenCalledTimes(1), { timeout: 1000 });

    expect(snoozeReminderMock).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'business-1', userId: 'user-1' }),
      expect.objectContaining({ id: 'rem-1', taskId: 'task-1' })
    );

    expect(markReadMock).toHaveBeenCalledWith('rem-1');
    expect(dismissReminderMock).toHaveBeenCalledWith('rem-1');
  });
});
