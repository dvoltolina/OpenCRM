/**
 * Report View Repository
 * Manages saved report definitions with ownership + team sharing RBAC
 */

import { BaseRepository } from './base-repository';
import type { SecurityContext, RepositoryResult } from './repository-types';
import {
  AuthorizationError,
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { isValidDocumentId } from './firestore-utils';
import type { ReportView, ReportViewFilters } from '../../types/models';
import { resolveTeamIds, sanitizeTeamIds } from '../../lib/security-context';

export class ReportViewRepository extends BaseRepository<ReportView> {
  constructor() {
    super({ collectionName: 'report_views' });
  }

  private normalize(view: ReportView): ReportView {
    const filters = view.filters || {};
    return {
      ...view,
      teamIds: sanitizeTeamIds(view.teamIds),
      ownerId: view.ownerId || 'unknown-owner',
      ownerName: view.ownerName || 'Unknown Owner',
      filters: {
        ...filters,
        pipelineId: filters?.pipelineId || null,
        stageIds: sanitizeTeamIds(filters?.stageIds),
        assigneeIds: sanitizeTeamIds(filters?.assigneeIds),
        leadSources: sanitizeTeamIds(filters?.leadSources),
        ownerIds: sanitizeTeamIds(filters?.ownerIds),
        teamIds: sanitizeTeamIds(filters?.teamIds),
        statuses: filters?.statuses || [],
      },
    };
  }

  private getUserTeams(context: SecurityContext, teamIds?: string[]): string[] {
    const fallbackTeams = [...(context.teamIds || []), ...(context.managedTeamIds || [])];
    return resolveTeamIds(teamIds, fallbackTeams);
  }

  private withOwnership(
    context: SecurityContext,
    data: Partial<ReportView>,
    allowOverride: boolean
  ): Pick<ReportView, 'ownerId' | 'ownerName' | 'teamIds'> {
    const canOverride = allowOverride && this.isAdminOrOwner(context);
    const ownerId = canOverride && data.ownerId ? data.ownerId : context.userId;
    const ownerName = canOverride && data.ownerName ? data.ownerName : context.userName;
    const teamIds = sanitizeTeamIds(data.teamIds);
    return { ownerId, ownerName, teamIds };
  }

  private canAccess(context: SecurityContext, view: ReportView, teamIds?: string[]): boolean {
    if (this.isAdminOrOwner(context)) return true;
    const memberships = this.getUserTeams(context, teamIds);
    return view.ownerId === context.userId || (view.teamIds || []).some((id) => memberships.includes(id));
  }

  private canModify(context: SecurityContext, view: ReportView, _teamIds?: string[]): boolean {
    if (this.isAdminOrOwner(context)) return true;
    return view.ownerId === context.userId;
  }

  async getById(
    context: SecurityContext,
    id: string,
    teamIds?: string[]
  ): Promise<RepositoryResult<ReportView>> {
    const result = await super.getById(context, id);
    if (!result.success) {
      return result;
    }
    const normalized = this.normalize(result.data);
    if (!this.canAccess(context, normalized, teamIds)) {
      return failedResult(new AuthorizationError('Not authorized to access this report view'));
    }
    return successResult(normalized);
  }

  async getAccessible(
    context: SecurityContext,
    teamIds?: string[]
  ): Promise<RepositoryResult<ReportView[]>> {
    const baseResult = await this.getAll(context, {
      orderBy: { field: 'name', direction: 'asc' },
    });

    if (!baseResult.success) {
      return failedResult(baseResult.error);
    }

    const normalized = baseResult.data.data.map((view) => this.normalize(view));
    const filtered = normalized.filter((view) => this.canAccess(context, view, teamIds));

    return successResult(filtered);
  }

  async create(
    context: SecurityContext,
    data: {
      name: string;
      description?: string;
      filters?: ReportViewFilters;
      teamIds?: string[];
      visibility?: 'private' | 'team' | 'org';
    }
  ): Promise<RepositoryResult<ReportView>> {
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return failedResult(new AuthorizationError('Not authorized to create report views'));
    }

    const ownership = this.withOwnership(context, { teamIds: data.teamIds }, true);
    const payload: Omit<ReportView, 'id' | 'createdAt' | 'updatedAt'> = {
      name: data.name.trim() || 'New Report View',
      description: data.description?.trim(),
      filters: data.filters || {},
      ...ownership,
      visibility: data.visibility ?? 'team',
    };

    const result = await super.create(context, payload as ReportView);
    if (!result.success) return result;
    return successResult(this.normalize(result.data));
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<ReportView>
  ): Promise<RepositoryResult<ReportView>> {
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return failedResult(new AuthorizationError('Not authorized to update report views'));
    }

    if (!this.isAdminOrOwner(context) && (data.ownerId || data.ownerName)) {
      return failedResult(
        new AuthorizationError('Only admins or owners can reassign saved view ownership')
      );
    }

    const existingResult = await this.getById(context, id);
    if (!existingResult.success) {
      return existingResult;
    }

    if (!this.canModify(context, existingResult.data)) {
      return failedResult(new AuthorizationError('Not authorized to update this saved view'));
    }

    const ownership = this.withOwnership(context, { ...existingResult.data, ...data }, true);
    const payload: Partial<ReportView> = {
      ...data,
      ownerId: ownership.ownerId,
      ownerName: ownership.ownerName,
      teamIds: ownership.teamIds,
    };

    const result = await super.update(context, id, payload);
    if (!result.success) return result;
    return successResult(this.normalize(result.data));
  }

  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    if (!isValidDocumentId(id)) {
      return failedResult(new InvalidArgumentError('Invalid report view ID', 'id'));
    }

    const existing = await this.getById(context, id);
    if (!existing.success) {
      return failedResult(existing.error);
    }

    if (!this.canModify(context, existing.data)) {
      return failedResult(new AuthorizationError('Not authorized to delete this saved view'));
    }

    return super.delete(context, id);
  }
}

let reportViewRepository: ReportViewRepository | null = null;

export function getReportViewRepository(): ReportViewRepository {
  if (!reportViewRepository) {
    reportViewRepository = new ReportViewRepository();
  }
  return reportViewRepository;
}
