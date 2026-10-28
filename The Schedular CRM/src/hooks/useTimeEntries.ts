/**
 * Time Entry Hooks
 * Provides hooks for viewing and managing time entries (punch clock data)
 *
 * HIPAA Compliance: All operations require authentication
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getTimeEntryRepository } from '../data/repositories/time-entry-repository';
import type { TimeEntryFilters } from '../data/repositories/time-entry-repository';
import { createSecurityContext } from './usePipeline';
import type { TimeEntry, TimesheetSummary } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseTimeEntriesResult {
  entries: TimeEntry[];
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

export interface UseTimeEntryMutationsResult {
  approve: (id: string, managerNotes?: string) => Promise<void>;
  reject: (id: string, reason: string, managerNotes?: string) => Promise<void>;
  bulkApprove: (ids: string[]) => Promise<{ approved: number; failed: number }>;
  isLoading: boolean;
  error: Error | null;
}

export interface UsePendingApprovalsResult {
  entries: TimeEntry[];
  count: number;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

// ============================================
// Overtime Calculation (8h/day, 40h/week, 1.5x)
// ============================================

const DAILY_REGULAR_MINUTES = 8 * 60;  // 480 minutes
const WEEKLY_REGULAR_MINUTES = 40 * 60; // 2400 minutes

export function calculateOvertimeMinutes(
  entries: TimeEntry[],
  periodType: 'daily' | 'weekly' = 'weekly'
): { regularMinutes: number; overtimeMinutes: number } {
  const totalWorked = entries.reduce((sum, e) => sum + (e.workedMinutes || 0), 0);
  const threshold = periodType === 'daily' ? DAILY_REGULAR_MINUTES : WEEKLY_REGULAR_MINUTES;

  if (totalWorked <= threshold) {
    return { regularMinutes: totalWorked, overtimeMinutes: 0 };
  }

  return {
    regularMinutes: threshold,
    overtimeMinutes: totalWorked - threshold,
  };
}

/**
 * Build timesheet summary from entries
 */
export function buildTimesheetSummary(
  entries: TimeEntry[],
  staffId: string,
  staffName: string,
  periodStart: Date,
  periodEnd: Date
): TimesheetSummary {
  const totalWorkedMinutes = entries.reduce((sum, e) => sum + (e.workedMinutes || 0), 0);
  const totalBreakMinutes = entries.reduce((sum, e) => sum + (e.breakMinutes || 0), 0);

  const { regularMinutes, overtimeMinutes } = calculateOvertimeMinutes(entries, 'weekly');

  return {
    staffId,
    staffName,
    periodStart,
    periodEnd,
    totalWorkedMinutes,
    totalBreakMinutes,
    regularMinutes,
    overtimeMinutes,
    totalEntries: entries.length,
    pendingEntries: entries.filter((e) => e.status === 'pending').length,
    approvedEntries: entries.filter((e) => e.status === 'approved').length,
    rejectedEntries: entries.filter((e) => e.status === 'rejected').length,
    entries,
  };
}

// ============================================
// useTimeEntries Hook
// ============================================

export function useTimeEntries(filters?: TimeEntryFilters): UseTimeEntriesResult {
  const { user, crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<TimeEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshTrigger, setRefreshTrigger] = useState(0);
  const listFilters = useMemo<TimeEntryFilters | undefined>(
    () => ({
      staffId: filters?.staffId,
      status: filters?.status,
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
    }),
    [filters?.dateFrom, filters?.dateTo, filters?.staffId, filters?.status]
  );

  const getContext = useCallback(() => {
    if (!user || !crmUser || !businessId) {
      throw new Error('Not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      crmUser.teamIds || [],
      crmUser.managedTeamIds || [],
      crmUser.managerId
    );
  }, [user, crmUser, businessId]);

  useEffect(() => {
    if (!user || !crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    const fetchEntries = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.list(context, listFilters);

        if (result.success) {
          setEntries(result.data);
        } else {
          setError(new Error(result.error?.message || 'Failed to fetch time entries'));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch time entries'));
      } finally {
        setIsLoading(false);
      }
    };

    fetchEntries();
  }, [user, crmUser, businessId, listFilters, refreshTrigger, getContext]);

  const refresh = useCallback(() => {
    setRefreshTrigger((prev) => prev + 1);
  }, []);

  return { entries, isLoading, error, refresh };
}

// ============================================
// useTimeEntryMutations Hook
// ============================================

export function useTimeEntryMutations(): UseTimeEntryMutationsResult {
  const { user, crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback(() => {
    if (!user || !crmUser || !businessId) {
      throw new Error('Not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      crmUser.teamIds || [],
      crmUser.managedTeamIds || [],
      crmUser.managerId
    );
  }, [user, crmUser, businessId]);

  const approve = useCallback(
    async (id: string, managerNotes?: string) => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.approve(context, id, managerNotes);

        if (!result.success) {
          throw result.error;
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to approve entry');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const reject = useCallback(
    async (id: string, reason: string, managerNotes?: string) => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.reject(context, id, reason, managerNotes);

        if (!result.success) {
          throw result.error;
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to reject entry');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const bulkApprove = useCallback(
    async (ids: string[]): Promise<{ approved: number; failed: number }> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.bulkApprove(context, ids);

        if (!result.success) {
          throw result.error;
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to bulk approve');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    approve: guardMutation(approve, { action: 'time-entry-approve' }),
    reject: guardMutation(reject, { action: 'time-entry-reject' }),
    bulkApprove: guardMutation(bulkApprove, { action: 'time-entry-bulk-approve' }),
    isLoading,
    error,
  };
}

// ============================================
// usePendingApprovals Hook
// ============================================

export function usePendingApprovals(): UsePendingApprovalsResult {
  const { user, crmUser, businessId } = useAuth();
  const [entries, setEntries] = useState<TimeEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  const getContext = useCallback(() => {
    if (!user || !crmUser || !businessId) {
      throw new Error('Not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      crmUser.teamIds || [],
      crmUser.managedTeamIds || [],
      crmUser.managerId
    );
  }, [user, crmUser, businessId]);

  useEffect(() => {
    if (!user || !crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    // Only admins can view pending approvals
    if (crmUser.role !== 'owner' && crmUser.role !== 'admin') {
      setIsLoading(false);
      return;
    }

    const fetchPending = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.getPendingApprovals(context);

        if (result.success) {
          setEntries(result.data);
        } else {
          setError(new Error(result.error?.message || 'Failed to fetch pending approvals'));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch pending approvals'));
      } finally {
        setIsLoading(false);
      }
    };

    fetchPending();
  }, [user, crmUser, businessId, refreshTrigger, getContext]);

  const refresh = useCallback(() => {
    setRefreshTrigger((prev) => prev + 1);
  }, []);

  return {
    entries,
    count: entries.length,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useTimesheetData Hook
// ============================================

export interface UseTimesheetDataOptions {
  staffId?: string;
  weekOf: Date; // Any date in the week
}

export interface UseTimesheetDataResult {
  summary: TimesheetSummary | null;
  weekStart: Date;
  weekEnd: Date;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

export function useTimesheetData(options: UseTimesheetDataOptions): UseTimesheetDataResult {
  const { user, crmUser, businessId } = useAuth();
  const [summary, setSummary] = useState<TimesheetSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // Calculate week start (Sunday) and end (Saturday)
  const { weekStart, weekEnd } = useMemo(() => {
    const date = new Date(options.weekOf);
    const day = date.getDay();

    const start = new Date(date);
    start.setDate(date.getDate() - day);
    start.setHours(0, 0, 0, 0);

    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);

    return { weekStart: start, weekEnd: end };
  }, [options.weekOf]);

  const getContext = useCallback(() => {
    if (!user || !crmUser || !businessId) {
      throw new Error('Not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      crmUser.teamIds || [],
      crmUser.managedTeamIds || [],
      crmUser.managerId
    );
  }, [user, crmUser, businessId]);

  useEffect(() => {
    if (!user || !crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    const fetchTimesheet = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getTimeEntryRepository();
        const result = await repo.getForDateRange(
          context,
          weekStart,
          weekEnd,
          options.staffId
        );

        if (result.success) {
          const staffId = options.staffId || context.userId;
          const staffName = options.staffId ? 'Staff Member' : (crmUser.displayName || 'You');

          const timesheetSummary = buildTimesheetSummary(
            result.data,
            staffId,
            staffName,
            weekStart,
            weekEnd
          );

          setSummary(timesheetSummary);
        } else {
          setError(new Error(result.error?.message || 'Failed to fetch timesheet data'));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch timesheet data'));
      } finally {
        setIsLoading(false);
      }
    };

    fetchTimesheet();
  }, [user, crmUser, businessId, weekStart, weekEnd, options.staffId, refreshTrigger, getContext]);

  const refresh = useCallback(() => {
    setRefreshTrigger((prev) => prev + 1);
  }, []);

  return { summary, weekStart, weekEnd, isLoading, error, refresh };
}

// ============================================
// Utility: Format minutes as hours:minutes
// ============================================

export function formatMinutesAsTime(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${hours}h ${mins}m`;
}

export function formatMinutesAsDecimal(minutes: number): string {
  return (minutes / 60).toFixed(2);
}

// ============================================
// Payroll Export Utilities
// ============================================

export interface PayrollExportRow {
  staffId: string;
  staffName: string;
  date: string;
  clockIn: string;
  clockOut: string;
  totalHours: string;
  breakHours: string;
  workedHours: string;
  regularHours: string;
  overtimeHours: string;
  status: string;
}

/**
 * Generate CSV content for payroll export
 */
export function generatePayrollCSV(entries: TimeEntry[], staffNames?: Map<string, string>): string {
  const headers = [
    'Staff ID',
    'Staff Name',
    'Date',
    'Clock In',
    'Clock Out',
    'Total Hours',
    'Break Hours',
    'Worked Hours',
    'Status',
  ];

  const rows = entries
    .filter((e) => e.status === 'approved')
    .map((entry) => {
      const staffName = staffNames?.get(entry.staffId) || entry.staffId;
      return [
        entry.staffId,
        staffName,
        entry.clockInTime.toLocaleDateString(),
        entry.clockInTime.toLocaleTimeString(),
        entry.clockOutTime?.toLocaleTimeString() || '',
        formatMinutesAsDecimal(entry.totalMinutes || 0),
        formatMinutesAsDecimal(entry.breakMinutes || 0),
        formatMinutesAsDecimal(entry.workedMinutes || 0),
        entry.status,
      ];
    });

  const csvContent = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n');

  return csvContent;
}

/**
 * Generate weekly summary CSV for payroll
 */
export function generateWeeklySummaryCSV(
  summaries: TimesheetSummary[]
): string {
  const headers = [
    'Staff ID',
    'Staff Name',
    'Week Start',
    'Week End',
    'Total Worked (hrs)',
    'Regular (hrs)',
    'Overtime (hrs)',
    'Break (hrs)',
    'Approved Entries',
    'Pending Entries',
  ];

  const rows = summaries.map((summary) => [
    summary.staffId,
    summary.staffName,
    summary.periodStart.toLocaleDateString(),
    summary.periodEnd.toLocaleDateString(),
    formatMinutesAsDecimal(summary.totalWorkedMinutes),
    formatMinutesAsDecimal(summary.regularMinutes),
    formatMinutesAsDecimal(summary.overtimeMinutes),
    formatMinutesAsDecimal(summary.totalBreakMinutes),
    summary.approvedEntries.toString(),
    summary.pendingEntries.toString(),
  ]);

  const csvContent = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n');

  return csvContent;
}

/**
 * Download CSV as file
 */
export function downloadCSV(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  URL.revokeObjectURL(url);
}
