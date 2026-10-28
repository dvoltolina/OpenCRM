/**
 * useTaskReminders Hook
 * React hook for managing task reminders
 *
 * CRM-44 Implementation
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getTaskReminderService,
  type TaskReminder,
} from '../services/task-reminder-service';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseTaskRemindersResult {
  reminders: TaskReminder[];
  unreadCount: number;
  isLoading: boolean;
  error: string | null;
  markRead: (reminderId: string) => void;
  markAllRead: () => void;
  dismissReminder: (reminderId: string) => void;
  refresh: () => Promise<void>;
}

// ============================================
// Hook
// ============================================

const REFRESH_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

export function useTaskReminders(): UseTaskRemindersResult {
  const { crmUser, businessId } = useAuth();
  const { guardAction } = useDemoGuard();
  const [reminders, setReminders] = useState<TaskReminder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const refreshIntervalRef = useRef<NodeJS.Timeout | null>(null);

  /**
   * Fetch reminders from service
   */
  const fetchReminders = useCallback(async () => {
    if (!crmUser || !businessId) {
      setReminders([]);
      setIsLoading(false);
      return;
    }

    try {
      setError(null);
      const service = getTaskReminderService();

      const result = await service.getReminders({
        userId: crmUser.id,
        businessId,
        userName: crmUser.displayName,
        userRole: crmUser.role,
      });

      if (result.success && result.data) {
        setReminders(result.data);
      } else {
        setError(result.error?.message || 'Failed to fetch reminders');
        setReminders([]);
      }
    } catch (err) {
      console.error('Error fetching reminders:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch reminders');
      setReminders([]);
    } finally {
      setIsLoading(false);
    }
  }, [crmUser, businessId]);

  /**
   * Mark a reminder as read
   */
  const markRead = useCallback(
    (reminderId: string) => {
      if (!crmUser || !businessId) return;

      const service = getTaskReminderService();
      const result = service.markAsRead(crmUser.id, businessId, reminderId);

      if (result.success) {
        setReminders(prev =>
          prev.map(reminder =>
            reminder.id === reminderId
              ? { ...reminder, isRead: true }
              : reminder
          )
        );
      } else {
        console.error('Failed to mark reminder as read:', result.error);
      }
    },
    [businessId, crmUser]
  );

  /**
   * Mark all reminders as read
   */
  const markAllRead = useCallback(() => {
    if (!crmUser || !businessId) return;

    const service = getTaskReminderService();
    const unreadIds = reminders
      .filter(r => !r.isRead)
      .map(r => r.id);

    const result = service.markMultipleAsRead(crmUser.id, businessId, unreadIds);

    if (result.success) {
      setReminders(prev =>
        prev.map(reminder => ({ ...reminder, isRead: true }))
      );
    } else {
      console.error('Failed to mark all reminders as read:', result.error);
    }
  }, [businessId, crmUser, reminders]);

  /**
   * Dismiss a reminder
   */
  const dismissReminder = useCallback(
    (reminderId: string) => {
      if (!crmUser || !businessId) return;

      const service = getTaskReminderService();
      const result = service.dismissReminder(crmUser.id, businessId, reminderId);

      if (result.success) {
        setReminders(prev => prev.filter(r => r.id !== reminderId));
      } else {
        console.error('Failed to dismiss reminder:', result.error);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Refresh reminders
   */
  const refresh = useCallback(async () => {
    setIsLoading(true);
    await fetchReminders();
  }, [fetchReminders]);

  /**
   * Calculate unread count
   */
  const unreadCount = reminders.filter(r => !r.isRead).length;

  /**
   * Initial fetch and periodic refresh
   */
  useEffect(() => {
    fetchReminders();

    // Set up periodic refresh
    refreshIntervalRef.current = setInterval(
      fetchReminders,
      REFRESH_INTERVAL_MS
    );

    return () => {
      if (refreshIntervalRef.current) {
        clearInterval(refreshIntervalRef.current);
      }
    };
  }, [fetchReminders]);

  return {
    reminders,
    unreadCount,
    isLoading,
    error,
    markRead: guardAction(markRead, { action: 'task-reminder-read' }),
    markAllRead: guardAction(markAllRead, { action: 'task-reminder-read-all' }),
    dismissReminder: guardAction(dismissReminder, { action: 'task-reminder-dismiss' }),
    refresh,
  };
}
