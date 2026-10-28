/**
 * Notification Context
 * Global state management for task reminders and notifications
 *
 * CRM-44 Implementation
 */

import {
  createContext,
  useContext,
  type ReactNode,
} from 'react';
import {
  useTaskReminders,
  type UseTaskRemindersResult,
} from '../hooks/useTaskReminders';

// ============================================
// Context
// ============================================

type NotificationContextValue = UseTaskRemindersResult;

const NotificationContext = createContext<NotificationContextValue | null>(null);

// ============================================
// Provider
// ============================================

interface NotificationProviderProps {
  children: ReactNode;
}

export function NotificationProvider({ children }: NotificationProviderProps) {
  const taskReminders = useTaskReminders();

  const value: NotificationContextValue = {
    ...taskReminders,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
}

// ============================================
// Hook
// ============================================

export function useNotifications(): NotificationContextValue {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
}
