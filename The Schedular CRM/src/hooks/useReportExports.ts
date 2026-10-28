import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getReportExportService, type RunReportExportInput, type RunReportExportResult, type ScheduleReportExportInput } from '../services/report-export-service';
import type { ReportExport } from '../types/reporting';
import { createSecurityContextFromParams, getUserManagedTeamIds, getUserTeamIds } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

export interface UseReportExportsResult {
  exports: ReportExport[];
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
  schedule: (input: ScheduleReportExportInput) => Promise<ReportExport>;
  runNow: (input: RunReportExportInput) => Promise<RunReportExportResult>;
}

export function useReportExports(): UseReportExportsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [exports, setExports] = useState<ReportExport[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const service = useMemo(() => getReportExportService(), []);

  const getContext = useCallback(() => {
    if (!crmUser || !businessId) {
      throw new Error('Not authenticated');
    }
    const teamIds = getUserTeamIds(crmUser);
    const managedTeamIds = getUserManagedTeamIds(crmUser);
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      teamIds,
      managedTeamIds,
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  const refresh = useCallback(async () => {
    if (!crmUser || !businessId) {
      setExports([]);
      return;
    }
    setIsLoading(true);
    setError(null);
    try {
      const context = getContext();
      const data = await service.listScheduled(context);
      setExports(data);
    } catch (err) {
      setError(err as Error);
      setExports([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, service]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const schedule = useCallback(
    async (input: ScheduleReportExportInput) => {
      const context = getContext();
      const record = await service.scheduleExport(context, input);
      await refresh();
      return record;
    },
    [getContext, refresh, service]
  );

  const runNow = useCallback(
    async (input: RunReportExportInput) => {
      const context = getContext();
      const result = await service.runExportNow(context, input);
      await refresh();
      return result;
    },
    [getContext, refresh, service]
  );

  return {
    exports,
    isLoading,
    error,
    refresh,
    schedule: guardMutation(schedule, { action: 'report-export-schedule' }),
    runNow: guardMutation(runNow, { action: 'report-export-run' }),
  };
}

export default useReportExports;
