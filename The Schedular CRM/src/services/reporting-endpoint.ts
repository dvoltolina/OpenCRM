/**
 * Reporting Endpoint Facade
 * Secured entrypoint for reporting aggregations (designed for Cloud Function/endpoint use).
 * Enforces feature flag + RBAC, sanitizes filters, and defers to ReportingAggregationService.
 */

import { getFeatureFlags } from '../config/features';
import { ReportingAggregationService } from './reporting-aggregation-service';
import type { ReportingAggregationFilters, ReportingAggregationResult } from '../types/reporting';
import type { SecurityContext } from '../data/repositories/repository-types';
import { AuthorizationError } from '../data/errors/repository-errors';
import { sanitizeTeamIds } from '../lib/security-context';
import { getFirebaseAuth } from '../lib/firebase';

const reportingService = new ReportingAggregationService();

function getReportingEndpointUrl(): string {
  const env = (import.meta as ImportMeta)?.env as Record<string, string | undefined>;
  return env?.VITE_REPORTING_ENDPOINT_URL || '';
}

function serializeFilters(filters: ReportingAggregationFilters): ReportingAggregationFilters {
  return {
    ...filters,
    startDate: filters.startDate ? new Date(filters.startDate) : undefined,
    endDate: filters.endDate ? new Date(filters.endDate) : undefined,
  };
}

export async function fetchReportingSnapshot(
  context: SecurityContext,
  filters: ReportingAggregationFilters = {},
  service: ReportingAggregationService = reportingService,
  options: { endpointUrl?: string } = {}
): Promise<ReportingAggregationResult> {
  const { enableReports, enableAdvancedReporting } = getFeatureFlags();
  if (!enableReports || enableAdvancedReporting === false) {
    throw new AuthorizationError('Reporting is disabled by feature flag');
  }

  const normalizedFilters: ReportingAggregationFilters = {
    ...filters,
    startDate: filters.startDate,
    endDate: filters.endDate,
    pipelineIds: sanitizeTeamIds(filters.pipelineIds),
    ownerIds: sanitizeTeamIds(filters.ownerIds),
    teamIds: sanitizeTeamIds(filters.teamIds),
    stageIds: sanitizeTeamIds(filters.stageIds),
    sources: sanitizeTeamIds(filters.sources),
    bucket: filters.bucket ?? 'monthly',
    includeStageBreakdown: filters.includeStageBreakdown ?? true,
  };

  // If an HTTPS endpoint is configured, prefer server execution with ID token auth.
  const endpointUrl = options.endpointUrl ?? getReportingEndpointUrl();
  const isExplicitEndpoint = Boolean(options.endpointUrl);
  const shouldUseRemote =
    Boolean(endpointUrl) && (isExplicitEndpoint || process.env.NODE_ENV !== 'test');
  if (shouldUseRemote && endpointUrl) {
    try {
      const auth = getFirebaseAuth();
      const token = await auth?.currentUser?.getIdToken?.();

      const response = await fetch(endpointUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          'X-Business-Id': context.businessId,
        },
        body: JSON.stringify({
          filters: {
            ...serializeFilters(normalizedFilters),
            startDate: normalizedFilters.startDate?.toISOString(),
            endDate: normalizedFilters.endDate?.toISOString(),
          },
        }),
      });

      if (!response.ok) {
        throw new Error(`Reporting endpoint error: ${response.status} ${response.statusText}`);
      }

      return (await response.json()) as ReportingAggregationResult;
    } catch {
      // Fall back to local aggregation when remote endpoint is unreachable (dev/test).
    }
  }

  // Fallback: run locally (useful in dev or when endpoint not configured)
  return service.getAggregatedKpis(context, normalizedFilters);
}
