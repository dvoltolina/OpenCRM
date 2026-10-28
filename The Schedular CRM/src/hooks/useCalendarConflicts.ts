/**
 * Calendar Conflicts Hook
 * Check for calendar conflicts for staff members
 *
 * HIPAA Compliance: Only fetches time blocks, not event details
 */

import { useState, useCallback, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import {
  getCalendarConflictService,
  type StaffConflict,
} from '../services/calendar-conflict-service';
import { getFeatureFlags } from '../config/features';

// ============================================
// Types
// ============================================

export interface UseCalendarConflictsOptions {
  date: Date;
  staffIds: string[];
  workStartTime?: string; // HH:mm format
  workEndTime?: string; // HH:mm format
  enabled?: boolean;
}

export interface UseCalendarConflictsResult {
  conflicts: Map<string, StaffConflict[]>;
  isLoading: boolean;
  error: Error | null;
  hasConflicts: (staffId: string) => boolean;
  getConflicts: (staffId: string) => StaffConflict[];
  refresh: () => void;
}

// ============================================
// Hook
// ============================================

export function useCalendarConflicts(
  options: UseCalendarConflictsOptions
): UseCalendarConflictsResult {
  const { crmUser, businessId } = useAuth();
  const [conflicts, setConflicts] = useState<Map<string, StaffConflict[]>>(new Map());
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const abortControllerRef = useRef<AbortController | null>(null);

  const {
    date,
    staffIds,
    workStartTime,
    workEndTime,
    enabled = true,
  } = options;

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

  const checkConflicts = useCallback(async () => {
    const flags = getFeatureFlags();
    if (!flags.enableCalendarSync || !enabled) {
      setConflicts(new Map());
      setIsLoading(false);
      return;
    }

    if (!businessId || !crmUser || staffIds.length === 0) {
      setConflicts(new Map());
      setIsLoading(false);
      return;
    }

    // Cancel any in-progress check
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    abortControllerRef.current = new AbortController();

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getCalendarConflictService();

      const results = await service.checkConflicts(context, {
        date,
        staffIds,
        startTime: workStartTime,
        endTime: workEndTime,
      });

      // Build conflicts map
      const conflictsMap = new Map<string, StaffConflict[]>();
      for (const result of results) {
        if (result.conflicts.length > 0) {
          conflictsMap.set(result.staffId, result.conflicts);
        }
      }

      setConflicts(conflictsMap);
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        return; // Ignore abort errors
      }
      setError(err instanceof Error ? err : new Error('Failed to check conflicts'));
      setConflicts(new Map());
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, date, staffIds, workStartTime, workEndTime, enabled, getContext]);

  // Check conflicts when dependencies change
  useEffect(() => {
    checkConflicts();

    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, [checkConflicts]);

  const hasConflicts = useCallback(
    (staffId: string): boolean => {
      const staffConflicts = conflicts.get(staffId);
      return staffConflicts !== undefined && staffConflicts.length > 0;
    },
    [conflicts]
  );

  const getConflicts = useCallback(
    (staffId: string): StaffConflict[] => {
      return conflicts.get(staffId) ?? [];
    },
    [conflicts]
  );

  const refresh = useCallback(() => {
    checkConflicts();
  }, [checkConflicts]);

  return {
    conflicts,
    isLoading,
    error,
    hasConflicts,
    getConflicts,
    refresh,
  };
}

export default useCalendarConflicts;
