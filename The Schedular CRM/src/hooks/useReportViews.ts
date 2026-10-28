/**
 * useReportViews Hook
 * Manages saved report views with owner/team RBAC
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getReportViewRepository } from '../data/repositories/report-view-repository';
import type { CRMUser, ReportView, ReportViewFilters, Visibility } from '../types/models';
import {
  canDeleteShareableEntity,
  createSecurityContextFromParams,
  getUserManagedTeamIds,
  getUserTeamIds,
  sanitizeTeamIds,
} from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

export interface UseReportViewsResult {
  views: ReportView[];
  isLoading: boolean;
  error: Error | null;
  createView: (data: { name: string; description?: string; filters: ReportViewFilters; teamIds?: string[]; visibility?: Visibility }) => Promise<ReportView>;
  updateView: (id: string, data: Partial<ReportView>) => Promise<ReportView>;
  deleteView: (id: string) => Promise<void>;
  refresh: () => void;
  canManage: (view: ReportView) => boolean;
}

export function filterViewsForClient(
  views: ReportView[],
  crmUser: CRMUser | null
): ReportView[] {
  if (!crmUser) return [];
  const isPrivileged = crmUser.role === 'owner' || crmUser.role === 'admin';
  const allowedTeams = sanitizeTeamIds([
    ...getUserTeamIds(crmUser),
    ...getUserManagedTeamIds(crmUser),
  ]);

  if (isPrivileged) {
    return views;
  }

  return views.filter((view) => {
    if (view.ownerId === crmUser.id) return true;
    const viewTeams = sanitizeTeamIds(view.teamIds || []);
    if (allowedTeams.length === 0 && viewTeams.length === 0) {
      return false;
    }
    return viewTeams.some((teamId) => allowedTeams.includes(teamId));
  });
}

export function useReportViews(enabled = true): UseReportViewsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [views, setViews] = useState<ReportView[]>([]);
  const [isLoading, setIsLoading] = useState(enabled);
  const [error, setError] = useState<Error | null>(null);

  const repo = useMemo(() => getReportViewRepository(), []);

  const getContext = useCallback(() => {
    if (!crmUser || !businessId) {
      throw new Error('User not authenticated');
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

  const fetchViews = useCallback(async () => {
    if (!enabled) {
      setViews([]);
      setIsLoading(false);
      setError(null);
      return;
    }
    if (!crmUser || !businessId) {
      setViews([]);
      setIsLoading(false);
      return;
    }
    setIsLoading(true);
    setError(null);
    try {
      const context = getContext();
      const teamIds = sanitizeTeamIds([
        ...getUserTeamIds(crmUser),
        ...getUserManagedTeamIds(crmUser),
      ]);
      const result = await repo.getAccessible(context, teamIds);
      if (!result.success) {
        throw new Error(result.error.message);
      }
      const scopedViews = filterViewsForClient(result.data, crmUser);
      setViews(scopedViews);
    } catch (err) {
      setError(err as Error);
      setViews([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, enabled, getContext, repo]);

  useEffect(() => {
    fetchViews();
  }, [fetchViews]);

  const createView = useCallback(
    async (data: { name: string; description?: string; filters: ReportViewFilters; teamIds?: string[]; visibility?: Visibility }) => {
      const context = getContext();
      const sanitizedTeamIds = sanitizeTeamIds(data.teamIds);
      const result = await repo.create(context, {
        ...data,
        teamIds: sanitizedTeamIds,
        visibility: data.visibility ?? 'team',
      });
      if (!result.success) {
        throw new Error(result.error.message);
      }
      await fetchViews();
      return result.data;
    },
    [fetchViews, getContext, repo]
  );

  const updateView = useCallback(
    async (id: string, data: Partial<ReportView>) => {
      const context = getContext();
      const result = await repo.update(context, id, {
        ...data,
        teamIds: data.teamIds ? sanitizeTeamIds(data.teamIds) : data.teamIds,
        visibility: data.visibility,
      });
      if (!result.success) {
        throw new Error(result.error.message);
      }
      await fetchViews();
      return result.data;
    },
    [fetchViews, getContext, repo]
  );

  const deleteView = useCallback(
    async (id: string) => {
      const context = getContext();
      const result = await repo.delete(context, id);
      if (!result.success) {
        throw new Error(result.error.message);
      }
      await fetchViews();
    },
    [fetchViews, getContext, repo]
  );

  const canManage = useCallback(
    (view: ReportView) => {
      if (!crmUser || !businessId) return false;
      const context = getContext();
      return canDeleteShareableEntity(context, view);
    },
    [businessId, crmUser, getContext]
  );

  return {
    views,
    isLoading,
    error,
    createView: guardMutation(createView, { action: 'report-view-create' }),
    updateView: guardMutation(updateView, { action: 'report-view-update' }),
    deleteView: guardMutation(deleteView, { action: 'report-view-delete' }),
    refresh: fetchViews,
    canManage,
  };
}

export default useReportViews;
