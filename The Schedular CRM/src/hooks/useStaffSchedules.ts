/**
 * Staff Schedule Hooks
 * Provides hooks for staff schedule management
 *
 * HIPAA Compliance: All operations require authentication
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getStaffScheduleRepository,
  isStaffWorkingOnDate,
  createDefaultWeeklyPatterns,
} from '../data/repositories/staff-schedule-repository';
import { createSecurityContext } from './usePipeline';
import type {
  StaffSchedule,
  ScheduleException,
  WeeklySchedulePattern,
  ScheduleTimeSlot,
  DayOfWeek,
} from '../types/models';

// ============================================
// useStaffSchedules Hook - List all schedules
// ============================================

export interface UseStaffSchedulesResult {
  schedules: StaffSchedule[];
  isLoading: boolean;
  error: Error | null;
  getScheduleForStaff: (staffId: string) => StaffSchedule | undefined;
  getWorkingStaffForDate: (date: Date) => StaffSchedule[];
  refresh: () => void;
}

export function useStaffSchedules(): UseStaffSchedulesResult {
  const { crmUser, businessId } = useAuth();
  const [schedules, setSchedules] = useState<StaffSchedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const abortControllerRef = useRef<AbortController | null>(null);

  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  const fetchSchedules = useCallback(async () => {
    if (!businessId || !crmUser) {
      setSchedules([]);
      setIsLoading(false);
      return;
    }

    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    abortControllerRef.current = new AbortController();
    const currentAbortController = abortControllerRef.current;

    setIsLoading(true);
    setError(null);

    try {
      if (currentAbortController.signal.aborted) return;

      const context = getContext();
      const repo = getStaffScheduleRepository();
      const result = await repo.getAllSchedules(context);

      if (currentAbortController.signal.aborted) return;

      if (result.success) {
        setSchedules(result.data);
      } else {
        setError(new Error(result.error.message));
        setSchedules([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch schedules'));
      setSchedules([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext]);

  useEffect(() => {
    fetchSchedules();
  }, [fetchSchedules]);

  const refresh = useCallback(() => {
    fetchSchedules();
  }, [fetchSchedules]);

  const getScheduleForStaff = useCallback(
    (staffId: string): StaffSchedule | undefined => {
      return schedules.find((s) => s.staffId === staffId);
    },
    [schedules]
  );

  const getWorkingStaffForDate = useCallback(
    (date: Date): StaffSchedule[] => {
      return schedules.filter((s) => isStaffWorkingOnDate(s, date));
    },
    [schedules]
  );

  return {
    schedules,
    isLoading,
    error,
    getScheduleForStaff,
    getWorkingStaffForDate,
    refresh,
  };
}

// ============================================
// useStaffSchedule Hook - Single schedule
// ============================================

export interface UseStaffScheduleResult {
  schedule: StaffSchedule | null;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

export function useStaffSchedule(staffId: string | null): UseStaffScheduleResult {
  const { crmUser, businessId } = useAuth();
  const [schedule, setSchedule] = useState<StaffSchedule | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  const fetchSchedule = useCallback(async () => {
    if (!businessId || !crmUser || !staffId) {
      setSchedule(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getStaffScheduleRepository();
      const result = await repo.getByStaffId(context, staffId);

      if (result.success) {
        setSchedule(result.data);
      } else {
        setError(new Error(result.error.message));
        setSchedule(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch schedule'));
      setSchedule(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, staffId, getContext]);

  useEffect(() => {
    fetchSchedule();
  }, [fetchSchedule]);

  const refresh = useCallback(() => {
    fetchSchedule();
  }, [fetchSchedule]);

  return { schedule, isLoading, error, refresh };
}

// ============================================
// useStaffScheduleMutations Hook - CRUD ops
// ============================================

export interface UseStaffScheduleMutationsResult {
  createSchedule: (data: Partial<StaffSchedule>) => Promise<StaffSchedule>;
  updateSchedule: (id: string, data: Partial<StaffSchedule>) => Promise<StaffSchedule>;
  deleteSchedule: (id: string) => Promise<void>;
  updateWeeklyPatterns: (
    scheduleId: string,
    patterns: WeeklySchedulePattern[]
  ) => Promise<StaffSchedule>;
  addException: (
    scheduleId: string,
    exception: Omit<ScheduleException, 'id'>
  ) => Promise<StaffSchedule>;
  removeException: (scheduleId: string, exceptionId: string) => Promise<StaffSchedule>;
  isLoading: boolean;
  error: Error | null;
  clearError: () => void;
}

export function useStaffScheduleMutations(): UseStaffScheduleMutationsResult {
  const { crmUser, businessId } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const createSchedule = useCallback(
    async (data: Partial<StaffSchedule>): Promise<StaffSchedule> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();

        const scheduleData = {
          staffId: data.staffId ?? '',
          staffName: data.staffName ?? '',
          staffEmail: data.staffEmail,
          weeklyPatterns: data.weeklyPatterns ?? createDefaultWeeklyPatterns(),
          exceptions: data.exceptions ?? [],
          timezone: data.timezone ?? Intl.DateTimeFormat().resolvedOptions().timeZone,
          maxStopsPerDay: data.maxStopsPerDay,
          maxDrivingMinutesPerDay: data.maxDrivingMinutesPerDay,
          homeBaseAddress: data.homeBaseAddress,
          homeBaseLatitude: data.homeBaseLatitude,
          homeBaseLongitude: data.homeBaseLongitude,
          calendarConnectionId: data.calendarConnectionId,
          syncExceptionsFromCalendar: data.syncExceptionsFromCalendar ?? false,
          businessId: context.businessId,
          createdBy: context.userId,
          createdByName: context.userName,
        } as Omit<StaffSchedule, 'id' | 'createdAt' | 'updatedAt'>;

        const result = await repo.create(context, scheduleData);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create schedule');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateSchedule = useCallback(
    async (id: string, data: Partial<StaffSchedule>): Promise<StaffSchedule> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();
        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update schedule');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const deleteSchedule = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();
        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete schedule');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateWeeklyPatterns = useCallback(
    async (
      scheduleId: string,
      patterns: WeeklySchedulePattern[]
    ): Promise<StaffSchedule> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();
        const result = await repo.updateWeeklyPatterns(context, scheduleId, patterns);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error =
          err instanceof Error ? err : new Error('Failed to update weekly patterns');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const addException = useCallback(
    async (
      scheduleId: string,
      exception: Omit<ScheduleException, 'id'>
    ): Promise<StaffSchedule> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();
        const result = await repo.addException(context, scheduleId, exception);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add exception');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const removeException = useCallback(
    async (scheduleId: string, exceptionId: string): Promise<StaffSchedule> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getStaffScheduleRepository();
        const result = await repo.removeException(context, scheduleId, exceptionId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to remove exception');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createSchedule,
    updateSchedule,
    deleteSchedule,
    updateWeeklyPatterns,
    addException,
    removeException,
    isLoading,
    error,
    clearError,
  };
}

// ============================================
// Helper exports
// ============================================

export { isStaffWorkingOnDate, createDefaultWeeklyPatterns };

/**
 * Get working hours for a specific date from a schedule
 */
export function getWorkingHoursForDate(
  schedule: StaffSchedule,
  date: Date
): ScheduleTimeSlot[] | null {
  // Check for exception first
  const dateStr = date.toISOString().split('T')[0];
  const exception = schedule.exceptions.find((exc) => {
    const excDate =
      exc.date instanceof Date ? exc.date : new Date(exc.date as unknown as string);
    return excDate.toISOString().split('T')[0] === dateStr;
  });

  if (exception) {
    if (exception.allDay && exception.type === 'time_off') {
      return null; // Day off
    }
    if (exception.type === 'modified_hours' && exception.shifts) {
      return exception.shifts;
    }
    if (exception.type === 'holiday') {
      return null; // Holiday
    }
  }

  // Check weekly pattern
  const days: DayOfWeek[] = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];
  const dayOfWeek = days[date.getDay()];
  const pattern = schedule.weeklyPatterns.find((p) => p.dayOfWeek === dayOfWeek);

  if (!pattern || !pattern.isWorkingDay) {
    return null;
  }

  return pattern.shifts;
}
