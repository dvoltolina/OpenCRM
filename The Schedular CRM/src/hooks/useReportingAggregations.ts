import { useCallback, useEffect, useMemo, useState } from 'react';
import type { ReportingAggregationFilters, ReportingAggregationResult } from '../types/reporting';
import { fetchReportingSnapshot } from '../services/reporting-endpoint';
import { useAuth } from '../context/AuthContext';
import {
  createSecurityContextFromParams,
  getUserManagedTeamIds,
  getUserTeamIds,
} from '../lib/security-context';
import { AuthorizationError } from '../data/errors/repository-errors';

export interface UseReportingAggregationsResult {
  data: ReportingAggregationResult | null;
  isLoading: boolean;
  error: Error | null;
  isUnauthorized: boolean;
  refresh: () => void;
}

function normalizeAggregationResult(result: ReportingAggregationResult): ReportingAggregationResult {
  return {
    ...result,
    generatedAt:
      result.generatedAt instanceof Date ? result.generatedAt : new Date(result.generatedAt),
    timeBuckets: (result.timeBuckets || []).map((bucket) => ({
      ...bucket,
      periodStart:
        bucket.periodStart instanceof Date ? bucket.periodStart : new Date(bucket.periodStart),
      periodEnd: bucket.periodEnd instanceof Date ? bucket.periodEnd : new Date(bucket.periodEnd),
    })),
    cohorts: (result.cohorts || []).map((cohort) => ({
      ...cohort,
      periodStart:
        cohort.periodStart instanceof Date ? cohort.periodStart : new Date(cohort.periodStart),
      periodEnd: cohort.periodEnd instanceof Date ? cohort.periodEnd : new Date(cohort.periodEnd),
    })),
  };
}

export function useReportingAggregations(
  filters: ReportingAggregationFilters
): UseReportingAggregationsResult {
  const { crmUser, businessId } = useAuth();
  const [data, setData] = useState<ReportingAggregationResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [isUnauthorized, setIsUnauthorized] = useState(false);

  const normalizedFilters = useMemo(() => {
    const startDate = filters.startDate ? new Date(filters.startDate) : undefined;
    const endDate = filters.endDate ? new Date(filters.endDate) : undefined;
    return {
      ...filters,
      startDate,
      endDate,
    };
  }, [filters]);

  const filterKey = useMemo(() => {
    const { startDate, endDate, ...rest } = normalizedFilters;
    return JSON.stringify({
      ...rest,
      startDate: startDate ? startDate.toISOString() : undefined,
      endDate: endDate ? endDate.toISOString() : undefined,
    });
  }, [normalizedFilters]);

  const fetchData = useCallback(async () => {
    if (!crmUser || !businessId) {
      setData(null);
      setError(new Error('Not authenticated'));
      setIsUnauthorized(false);
      return;
    }
    setIsLoading(true);
    setError(null);
    setIsUnauthorized(false);
    try {
      const teamIds = getUserTeamIds(crmUser);
      const managedTeamIds = getUserManagedTeamIds(crmUser);
      const context = createSecurityContextFromParams(
        businessId,
        crmUser.id,
        crmUser.displayName,
        crmUser.role,
        teamIds,
        managedTeamIds,
        crmUser.managerId
      );
      const result = await fetchReportingSnapshot(context, normalizedFilters);
      setData(normalizeAggregationResult(result));
    } catch (err) {
      setError(err as Error);
      setIsUnauthorized(err instanceof AuthorizationError);
      setData(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, normalizedFilters]);

  useEffect(() => {
    fetchData();
  }, [fetchData, filterKey]);

  return {
    data,
    isLoading,
    error,
    isUnauthorized,
    refresh: fetchData,
  };
}

export default useReportingAggregations;
