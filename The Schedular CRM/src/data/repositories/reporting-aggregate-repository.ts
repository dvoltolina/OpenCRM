/**
 * Reporting Aggregate Repository
 * Stores precomputed KPI snapshots for reporting endpoints
 */

import { BaseRepository } from './base-repository';
import type {
  RepositoryResult,
  SecurityContext,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  AuthorizationError,
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type {
  ReportingAggregate,
  ReportingAggregationFilters,
} from '../../types/reporting';
import { resolveTeamIds, sanitizeTeamIds } from '../../lib/security-context';
import { isValidDocumentId } from './firestore-utils';

const aggregateValidator: Validator<ReportingAggregate> = (
  data: Partial<ReportingAggregate>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.startDate && data.endDate && data.startDate > data.endDate) {
    errors.push({
      field: 'startDate',
      message: 'startDate must be before endDate',
      code: 'INVALID_RANGE',
    });
  }

  if (data.metrics) {
    const { openCount, wonCount, lostCount, openValueCents, wonValueCents, lostValueCents } =
      data.metrics;
    const counts = [openCount, wonCount, lostCount].filter((value) => value !== undefined);
    if (counts.some((value) => value !== undefined && (value as number) < 0)) {
      errors.push({
        field: 'metrics',
        message: 'Counts must be non-negative',
        code: 'INVALID_VALUE',
      });
    }
    const values = [openValueCents, wonValueCents, lostValueCents].filter(
      (value) => value !== undefined
    );
    if (values.some((value) => value !== undefined && (value as number) < 0)) {
      errors.push({
        field: 'metrics',
        message: 'Value cents must be non-negative',
        code: 'INVALID_VALUE',
      });
    }
  }

  if (Array.isArray(data.stageConversions)) {
    data.stageConversions.forEach((conversion, index) => {
      if (conversion.entered < 0 || conversion.won < 0 || conversion.lost < 0) {
        errors.push({
          field: `stageConversions[${index}]`,
          message: 'Stage conversion counts must be non-negative',
          code: 'INVALID_VALUE',
        });
      }
    });
  }

  if (Array.isArray(data.lostReasons)) {
    data.lostReasons.forEach((reason, index) => {
      if (reason.count < 0 || reason.valueCents < 0) {
        errors.push({
          field: `lostReasons[${index}]`,
          message: 'Lost reason counts and values must be non-negative',
          code: 'INVALID_VALUE',
        });
      }
    });
  }

  return { isValid: errors.length === 0, errors };
};

export class ReportingAggregateRepository extends BaseRepository<ReportingAggregate> {
  constructor() {
    super({ collectionName: 'reporting_aggregates' });
    this.setValidator(aggregateValidator);
  }

  private normalize(aggregate: ReportingAggregate): ReportingAggregate {
    return {
      ...aggregate,
      pipelineId: aggregate.pipelineId ?? null,
      ownerId: aggregate.ownerId ?? null,
      teamIds: sanitizeTeamIds(aggregate.teamIds),
      bucket: aggregate.bucket || 'monthly',
      startDate: aggregate.startDate instanceof Date ? aggregate.startDate : new Date(aggregate.startDate),
      endDate: aggregate.endDate instanceof Date ? aggregate.endDate : new Date(aggregate.endDate),
      createdAt: aggregate.createdAt instanceof Date ? aggregate.createdAt : new Date(aggregate.createdAt),
      updatedAt: aggregate.updatedAt ? (aggregate.updatedAt instanceof Date ? aggregate.updatedAt : new Date(aggregate.updatedAt)) : undefined,
      stageBreakdown: Array.isArray(aggregate.stageBreakdown) ? aggregate.stageBreakdown : [],
      stageConversions: Array.isArray(aggregate.stageConversions) ? aggregate.stageConversions : [],
      lostReasons: Array.isArray(aggregate.lostReasons) ? aggregate.lostReasons : [],
      velocity: aggregate.velocity
        ? {
            ...aggregate.velocity,
            averageCycleDays: Number(aggregate.velocity.averageCycleDays || 0),
            averageOpenDays: Number(aggregate.velocity.averageOpenDays || 0),
            throughputPerDay: Number(aggregate.velocity.throughputPerDay || 0),
            winRate: Number(aggregate.velocity.winRate || 0),
          }
        : undefined,
      metrics: {
        ...aggregate.metrics,
        averageCycleDays: Number.isFinite(aggregate.metrics.averageCycleDays)
          ? Number(aggregate.metrics.averageCycleDays)
          : 0,
      },
    };
  }

  private getUserTeams(context: SecurityContext, teamIds?: string[]): string[] {
    return resolveTeamIds(teamIds, context.teamIds || []);
  }

  private canAccess(context: SecurityContext, aggregate: ReportingAggregate, teamIds?: string[]): boolean {
    if (this.isAdminOrOwner(context)) return true;

    const memberships = this.getUserTeams(context, teamIds);
    if (aggregate.ownerId && aggregate.ownerId === context.userId) {
      return true;
    }
    if (aggregate.teamIds?.some((teamId) => memberships.includes(teamId))) {
      return true;
    }

    // If the aggregate is tied to a pipeline, allow team members to access it
    return Boolean(aggregate.pipelineId);
  }

  private matchesFilters(
    aggregate: ReportingAggregate,
    filters: ReportingAggregationFilters,
    resolvedTeams: string[]
  ): boolean {
    if (filters.pipelineIds?.length && aggregate.pipelineId) {
      if (!filters.pipelineIds.includes(aggregate.pipelineId)) {
        return false;
      }
    }

    if (filters.ownerIds?.length && aggregate.ownerId) {
      if (!filters.ownerIds.includes(aggregate.ownerId)) {
        return false;
      }
    }

    if (filters.teamIds?.length && aggregate.teamIds?.length) {
      const requestedTeams = sanitizeTeamIds(filters.teamIds);
      const overlap = aggregate.teamIds.some(
        (teamId) => requestedTeams.includes(teamId) || resolvedTeams.includes(teamId)
      );
      if (!overlap) {
        return false;
      }
    }

    if (filters.bucket && aggregate.bucket !== filters.bucket) {
      return false;
    }

    if (filters.startDate && aggregate.startDate < filters.startDate) {
      return false;
    }

    if (filters.endDate && aggregate.endDate > filters.endDate) {
      return false;
    }

    return true;
  }

  async getById(
    context: SecurityContext,
    id: string,
    teamIds?: string[]
  ): Promise<RepositoryResult<ReportingAggregate>> {
    if (!isValidDocumentId(id)) {
      return failedResult(new InvalidArgumentError('Invalid reporting aggregate ID', 'id'));
    }

    const result = await super.getById(context, id);
    if (!result.success) {
      return result;
    }

    const normalized = this.normalize(result.data);
    if (!this.canAccess(context, normalized, teamIds)) {
      return failedResult(new AuthorizationError('Not authorized to access this report aggregate'));
    }

    return successResult(normalized);
  }

  async getByFilters(
    context: SecurityContext,
    filters: ReportingAggregationFilters = {},
    teamIds?: string[]
  ): Promise<RepositoryResult<ReportingAggregate[]>> {
    const resolvedTeams = this.getUserTeams(context, teamIds);

    const where = [];
    if (filters.pipelineIds?.length === 1) {
      where.push({ field: 'pipelineId', operator: '==', value: filters.pipelineIds[0] });
    }
    if (filters.ownerIds?.length === 1) {
      where.push({ field: 'ownerId', operator: '==', value: filters.ownerIds[0] });
    }
    if (filters.bucket) {
      where.push({ field: 'bucket', operator: '==', value: filters.bucket });
    }
    if (filters.startDate) {
      where.push({ field: 'startDate', operator: '>=', value: filters.startDate });
    }
    if (filters.endDate) {
      where.push({ field: 'endDate', operator: '<=', value: filters.endDate });
    }

    const baseResult = await this.getAll(context, {
      where,
      orderBy: { field: 'startDate', direction: 'desc' },
    });

    if (!baseResult.success) {
      return failedResult(baseResult.error);
    }

    const normalized = baseResult.data.data.map((aggregate) => this.normalize(aggregate));
    const filtered = normalized.filter(
      (aggregate) =>
        this.canAccess(context, aggregate, resolvedTeams) &&
        this.matchesFilters(aggregate, filters, resolvedTeams)
    );

    return successResult(filtered);
  }

  async createAggregate(
    context: SecurityContext,
    data: Omit<ReportingAggregate, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<ReportingAggregate>> {
    if (!this.isAdminOrOwner(context)) {
      return failedResult(
        new AuthorizationError('Only admins or owners can create reporting aggregates')
      );
    }

    const payload: Omit<ReportingAggregate, 'id' | 'createdAt' | 'updatedAt'> = {
      ...data,
      pipelineId: data.pipelineId ?? null,
      ownerId: data.ownerId ?? null,
      teamIds: sanitizeTeamIds(data.teamIds),
      bucket: data.bucket || 'monthly',
      stageBreakdown: data.stageBreakdown || [],
      stageConversions: data.stageConversions || [],
      lostReasons: data.lostReasons || [],
      velocity: data.velocity,
    };

    const result = await super.create(context, payload as ReportingAggregate, customId);
    if (!result.success) {
      return result;
    }

    return successResult(this.normalize(result.data));
  }
}

let reportingAggregateRepository: ReportingAggregateRepository | null = null;

export function getReportingAggregateRepository(): ReportingAggregateRepository {
  if (!reportingAggregateRepository) {
    reportingAggregateRepository = new ReportingAggregateRepository();
  }
  return reportingAggregateRepository;
}
