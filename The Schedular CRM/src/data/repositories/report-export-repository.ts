/**
 * Report Export Repository
 * Persists scheduled report export definitions with shareable RBAC defaults.
 */

import { ShareableRepository, type VisibilityLevel } from './access-control';
import type { SecurityContext, RepositoryResult } from './repository-types';
import {
  AuthorizationError,
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type {
  ReportExport,
  ReportExportDelivery,
  ReportExportFrequency,
  ReportExportFormat,
  ReportExportStatus,
  ReportingAggregationFilters,
} from '../../types/reporting';
import { sanitizeTeamIds } from '../../lib/security-context';

type CreateReportExportInput = {
  name: string;
  description?: string;
  format: ReportExportFormat;
  cadence: ReportExportFrequency;
  nextRunAt: Date;
  filters: ReportingAggregationFilters;
  delivery: ReportExportDelivery;
  teamIds?: string[];
  visibility?: ReportExport['visibility'];
};

type UpdateRunMetadataInput = {
  status?: ReportExportStatus;
  nextRunAt?: Date;
  lastRunAt?: Date;
  lastRunStatus?: ReportExportStatus;
  delivery?: Partial<ReportExportDelivery>;
};

export class ReportExportRepository extends ShareableRepository<ReportExport> {
  protected entityName = 'report export';
  protected defaultVisibility: VisibilityLevel = 'team';

  constructor() {
    super({ collectionName: 'report_exports' });
  }

  private normalizeFilters(filters: ReportingAggregationFilters = {}): ReportingAggregationFilters {
    return {
      ...filters,
      startDate: filters.startDate ? new Date(filters.startDate) : undefined,
      endDate: filters.endDate ? new Date(filters.endDate) : undefined,
      pipelineIds: sanitizeTeamIds(filters.pipelineIds),
      ownerIds: sanitizeTeamIds(filters.ownerIds),
      teamIds: sanitizeTeamIds(filters.teamIds),
      stageIds: sanitizeTeamIds(filters.stageIds),
      sources: sanitizeTeamIds(filters.sources),
      bucket: filters.bucket ?? 'monthly',
      includeStageBreakdown: filters.includeStageBreakdown ?? true,
    };
  }

  private normalizeDelivery(delivery: ReportExportDelivery): ReportExportDelivery {
    return {
      ...delivery,
      expiresAt: delivery.expiresAt ? new Date(delivery.expiresAt) : undefined,
    };
  }

  private normalize(exportDef: ReportExport): ReportExport {
    return {
      ...exportDef,
      teamIds: sanitizeTeamIds(exportDef.teamIds),
      filters: this.normalizeFilters(exportDef.filters),
      delivery: this.normalizeDelivery(exportDef.delivery),
      nextRunAt: new Date(exportDef.nextRunAt),
      lastRunAt: exportDef.lastRunAt ? new Date(exportDef.lastRunAt) : undefined,
      createdAt: exportDef.createdAt instanceof Date ? exportDef.createdAt : new Date(exportDef.createdAt),
      updatedAt: exportDef.updatedAt ? (exportDef.updatedAt instanceof Date ? exportDef.updatedAt : new Date(exportDef.updatedAt)) : undefined,
    };
  }

  async getAccessible(
    context: SecurityContext,
    teamIds?: string[]
  ): Promise<RepositoryResult<ReportExport[]>> {
    const result = await super.getAll(context, {
      orderBy: { field: 'nextRunAt', direction: 'asc' },
    });

    if (!result.success) {
      return failedResult(result.error);
    }

    const normalized = result.data.data.map((record) => this.normalize(record));
    const memberships = sanitizeTeamIds(teamIds);
    const filtered = normalized.filter((record) => {
      if (this.isAdminOrOwner(context)) return true;
      if (record.ownerId === context.userId) return true;
      const teams = sanitizeTeamIds(record.teamIds);
      return teams.some((id) => memberships.includes(id));
    });

    return successResult(filtered);
  }

  async schedule(
    context: SecurityContext,
    data: CreateReportExportInput
  ): Promise<RepositoryResult<ReportExport>> {
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return failedResult(new AuthorizationError('Not authorized to schedule exports'));
    }

    if (!data.nextRunAt) {
      return failedResult(new InvalidArgumentError('nextRunAt is required', 'nextRunAt'));
    }

    const payload: Omit<ReportExport, 'id' | 'createdAt' | 'updatedAt'> = {
      name: data.name.trim() || 'Report Export',
      description: data.description?.trim(),
      format: data.format,
      cadence: data.cadence,
      status: 'scheduled',
      nextRunAt: new Date(data.nextRunAt),
      filters: this.normalizeFilters(data.filters),
      delivery: this.normalizeDelivery(data.delivery),
      lastRunStatus: undefined,
      lastRunAt: undefined,
      ownerId: context.userId,
      ownerName: context.userName,
      teamIds: sanitizeTeamIds(data.teamIds),
      visibility: data.visibility ?? this.defaultVisibility,
    };

    const created = await super.create(context, payload as ReportExport);
    if (!created.success) {
      return created;
    }

    return successResult(this.normalize(created.data));
  }

  async updateRunMetadata(
    context: SecurityContext,
    id: string,
    updates: UpdateRunMetadataInput
  ): Promise<RepositoryResult<ReportExport>> {
    const existing = await super.getById(context, id);
    if (!existing.success) {
      return existing;
    }

    const sanitizedUpdates: Partial<ReportExport> = {
      status: updates.status,
      nextRunAt: updates.nextRunAt ? new Date(updates.nextRunAt) : undefined,
      lastRunAt: updates.lastRunAt ? new Date(updates.lastRunAt) : undefined,
      lastRunStatus: updates.lastRunStatus,
      delivery: updates.delivery
        ? this.normalizeDelivery({
            ...existing.data.delivery,
            ...updates.delivery,
          })
        : undefined,
    };

    const result = await super.update(context, id, sanitizedUpdates);
    if (!result.success) {
      return result;
    }

    return successResult(this.normalize(result.data));
  }
}

let reportExportRepository: ReportExportRepository | null = null;

export function getReportExportRepository(): ReportExportRepository {
  if (!reportExportRepository) {
    reportExportRepository = new ReportExportRepository();
  }
  return reportExportRepository;
}
