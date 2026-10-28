/**
 * useActivityLog Hook
 * React hook for logging sales activities
 *
 * Agent CRM-13 Implementation
 * Dependencies: ActivityService, AuthContext
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getActivityService,
  type LogActivityOptions,
  type TaskOptions,
  type EntityType,
} from '../services/activity-service';
import type { SalesActivity } from '../types/models';
import { createSecurityContext, sanitizeTeamIds } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseActivityLogResult {
  // Quick log methods
  logCall: (entityId: string, entityType: EntityType, notes: string) => Promise<SalesActivity | null>;
  logEmail: (entityId: string, entityType: EntityType, subject: string, notes?: string) => Promise<SalesActivity | null>;
  logMeeting: (entityId: string, entityType: EntityType, notes: string) => Promise<SalesActivity | null>;
  logNote: (entityId: string, entityType: EntityType, note: string) => Promise<SalesActivity | null>;

  // General logging
  logActivity: (options: LogActivityOptions) => Promise<SalesActivity | null>;

  // Task methods
  createTask: (options: Omit<TaskOptions, 'type'>) => Promise<SalesActivity | null>;
  completeTask: (activityId: string) => Promise<SalesActivity | null>;
  uncompleteTask: (activityId: string) => Promise<SalesActivity | null>;

  // Update/delete
  updateActivity: (
    activityId: string,
    updates: Partial<
      Pick<SalesActivity, 'title' | 'description' | 'dueDate' | 'assigneeId' | 'assigneeName' | 'teamIds' | 'templateId' | 'slaMinutes' | 'slaAt' | 'reminderAt'>
    >
  ) => Promise<SalesActivity | null>;
  deleteActivity: (activityId: string) => Promise<boolean>;

  // State
  isLoading: boolean;
  error: { code: string; message: string } | null;
  clearError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

export function useActivityLog(): UseActivityLogResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<{ code: string; message: string } | null>(null);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  /**
   * Log a generic activity
   */
  const logActivity = useCallback(
    async (options: LogActivityOptions): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.logActivity(context, options);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to log activity' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to log activity' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Quick log a call
   */
  const logCall = useCallback(
    async (entityId: string, entityType: EntityType, notes: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.logCall(context, entityId, entityType, notes);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to log call' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to log call' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Quick log an email
   */
  const logEmail = useCallback(
    async (entityId: string, entityType: EntityType, subject: string, notes?: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.logEmail(context, entityId, entityType, subject, notes);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to log email' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to log email' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Quick log a meeting
   */
  const logMeeting = useCallback(
    async (entityId: string, entityType: EntityType, notes: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.logMeeting(context, entityId, entityType, notes);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to log meeting' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to log meeting' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Quick log a note
   */
  const logNote = useCallback(
    async (entityId: string, entityType: EntityType, note: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.logNote(context, entityId, entityType, note);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to log note' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to log note' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Create a task
   */
  const createTask = useCallback(
    async (options: Omit<TaskOptions, 'type'>): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.createTask(context, { ...options, type: 'task' });

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to create task' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to create task' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Complete a task
   */
  const completeTask = useCallback(
    async (activityId: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.completeTask(context, activityId);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to complete task' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to complete task' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Uncomplete a task
   */
  const uncompleteTask = useCallback(
    async (activityId: string): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.uncompleteTask(context, activityId);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to uncomplete task' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to uncomplete task' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Update an activity
   */
  const updateActivity = useCallback(
    async (
      activityId: string,
      updates: Partial<
        Pick<SalesActivity, 'title' | 'description' | 'dueDate' | 'assigneeId' | 'assigneeName' | 'teamIds' | 'templateId' | 'slaMinutes' | 'slaAt' | 'reminderAt'>
      >
    ): Promise<SalesActivity | null> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return null;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.updateActivity(context, activityId, {
          ...updates,
          teamIds: updates.teamIds ? sanitizeTeamIds(updates.teamIds) : updates.teamIds,
        });

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to update activity' });
          return null;
        }

        return result.data || null;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to update activity' });
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  /**
   * Delete an activity
   */
  const deleteActivity = useCallback(
    async (activityId: string): Promise<boolean> => {
      if (!crmUser || !businessId) {
        setError({ code: 'AUTH_ERROR', message: 'Not authenticated' });
        return false;
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = createSecurityContext(crmUser);
        const service = getActivityService();
        const result = await service.deleteActivity(context, activityId);

        if (!result.success) {
          setError(result.error || { code: 'UNKNOWN', message: 'Failed to delete activity' });
          return false;
        }

        return true;
      } catch (err) {
        setError({ code: 'NETWORK_ERROR', message: 'Failed to delete activity' });
        return false;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, businessId]
  );

  return {
    logActivity: guardMutation(logActivity, { action: 'activity-log' }),
    logCall: guardMutation(logCall, { action: 'activity-call-log' }),
    logEmail: guardMutation(logEmail, { action: 'activity-email-log' }),
    logMeeting: guardMutation(logMeeting, { action: 'activity-meeting-log' }),
    logNote: guardMutation(logNote, { action: 'activity-note-log' }),
    createTask: guardMutation(createTask, { action: 'activity-task-create' }),
    completeTask: guardMutation(completeTask, { action: 'activity-task-complete' }),
    uncompleteTask: guardMutation(uncompleteTask, { action: 'activity-task-uncomplete' }),
    updateActivity: guardMutation(updateActivity, { action: 'activity-update' }),
    deleteActivity: guardMutation(deleteActivity, { action: 'activity-delete' }),
    isLoading,
    error,
    clearError,
  };
}
