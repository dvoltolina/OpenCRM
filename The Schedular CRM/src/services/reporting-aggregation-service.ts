/**
 * ReportingAggregationService
 * Computes secure KPI snapshots for reporting endpoints with RBAC-aware filters.
 */

import {
  sanitizeTeamIds,
  resolveTeamIds,
  validateSecurityContext,
  getHierarchyScopeFromContext,
} from '../lib/security-context';
import type { Deal, Pipeline, Lead } from '../types/models';
import type {
  PipelineAggregation,
  PerformanceMetrics,
  ReportingAggregate,
  ReportingAggregationFilters,
  ReportingAggregationResult,
  ReportingKpis,
  SourceCohort,
  LostReasonBreakdown,
  ReportingTimeBucket,
  StageConversion,
  StageSummary,
  TimeBucketAggregation,
  VelocityMetrics,
} from '../types/reporting';
import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getDealRepository,
  getLeadRepository,
  getPipelineRepository,
  getReportingAggregateRepository,
} from '../data/repositories';
import type { DealRepository, LeadRepository, PipelineRepository } from '../data/repositories';
import type { ReportingAggregateRepository } from '../data/repositories/reporting-aggregate-repository';
import { AuthorizationError } from '../data/errors/repository-errors';
import { AuditLogService } from './AuditLogService';

type AggregationSourceData = {
  deals?: Deal[];
  leads?: Lead[];
};

type AggregationDependencies = {
  dealRepository?: DealRepository;
  leadRepository?: LeadRepository;
  pipelineRepository?: PipelineRepository;
  aggregateRepository?: ReportingAggregateRepository;
  auditLogService?: AuditLogService;
};

const EMPTY_KPIS: ReportingKpis = {
  openCount: 0,
  wonCount: 0,
  lostCount: 0,
  openValueCents: 0,
  wonValueCents: 0,
  lostValueCents: 0,
  averageCycleDays: 0,
};

/** Cache TTL in milliseconds - aggregates older than this are considered stale */
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

export class ReportingAggregationService {
  private readonly dealsRepo: DealRepository;
  private readonly leadsRepo: LeadRepository;
  private readonly pipelineRepo: PipelineRepository;
  private readonly aggregateRepo: ReportingAggregateRepository;
  private readonly auditService: AuditLogService;

  constructor(dependencies: AggregationDependencies = {}) {
    this.dealsRepo = dependencies.dealRepository ?? getDealRepository();
    this.leadsRepo = dependencies.leadRepository ?? getLeadRepository();
    this.pipelineRepo = dependencies.pipelineRepository ?? getPipelineRepository();
    this.aggregateRepo = dependencies.aggregateRepository ?? getReportingAggregateRepository();
    this.auditService = dependencies.auditLogService ?? new AuditLogService();
  }

  /**
   * Fetch KPI snapshot for the given filters. Prefers cached aggregates when requested,
   * otherwise derives metrics from deal/lead data scoped to accessible pipelines.
   */
  async getAggregatedKpis(
    context: SecurityContext,
    filters: ReportingAggregationFilters = {},
    sourceData: AggregationSourceData = {}
  ): Promise<ReportingAggregationResult> {
    validateSecurityContext(context);

    if (context.userRole === 'frontDesk') {
      throw new AuthorizationError('Front desk users cannot access reporting aggregates');
    }

    const resolvedTeams = resolveTeamIds(filters.teamIds, context.teamIds || []);
    const bucket = filters.bucket ?? 'monthly';
    const accessiblePipelines = await this.loadAccessiblePipelines(
      context,
      filters,
      resolvedTeams
    );
    this.assertFilterAccess(context, filters, accessiblePipelines);

    if (!accessiblePipelines.length) {
      await this.auditAccess(context, filters, [], false, { dealCount: 0, leadCount: 0 });
      return this.emptyResult(filters, bucket);
    }

    // Always try cache first unless explicitly disabled
    if (filters.preferCache !== false) {
      const cached = await this.tryReadCache(context, filters, resolvedTeams);
      if (cached && !this.isCacheStale(cached.generatedAt)) {
        const cachedDealCount = cached.pipelines.reduce(
          (sum, pipeline) =>
            sum + pipeline.metrics.openCount + pipeline.metrics.wonCount + pipeline.metrics.lostCount,
          0
        );
        await this.auditAccess(context, filters, accessiblePipelines.map((p) => p.id), true, {
          dealCount: cachedDealCount,
          leadCount: 0,
        });
        return cached;
      }
    }

    const [deals, leads] = await Promise.all([
      this.loadDeals(context, accessiblePipelines, sourceData.deals),
      this.loadLeads(context, filters, sourceData.leads),
    ]);

    const filteredDeals = this.applyDealFilters(
      this.applyDateFilter(deals, filters.startDate, filters.endDate),
      filters,
      resolvedTeams
    );

    const filteredLeads = this.applyLeadFilters(
      leads,
      filters.startDate,
      filters.endDate,
      filters.sources
    );

    const pipelineAggregations = this.buildPipelineAggregations(
      accessiblePipelines,
      filteredDeals,
      filters.includeStageBreakdown
    );

    const summary = this.calculateKpis(filteredDeals);
    const timeBuckets = this.buildTimeBuckets(filteredDeals, bucket, filters.startDate, filters.endDate);
    const stageConversions = this.aggregateStageConversions(pipelineAggregations);
    const lostReasons = this.aggregateLostReasons(pipelineAggregations);
    const velocity = this.combineVelocity(pipelineAggregations, filteredDeals, filters.startDate, filters.endDate);
    const ownerPerformance = this.buildOwnerPerformance(filteredDeals);
    const teamPerformance = this.buildTeamPerformance(filteredDeals);
    const cohorts = this.buildSourceCohorts(
      filteredLeads,
      filteredDeals,
      bucket,
      filters.startDate,
      filters.endDate
    );

    // Auto-persist aggregates for privileged users (unless explicitly disabled)
    if (filters.cacheResults !== false && this.isPrivileged(context)) {
      await this.persistAggregates(context, pipelineAggregations, filters, bucket);
    }

    await this.auditAccess(context, filters, accessiblePipelines.map((p) => p.id), false, {
      dealCount: filteredDeals.length,
      leadCount: filteredLeads.length,
    });

    return {
      generatedAt: new Date(),
      filters: { ...filters, bucket },
      summary,
      pipelines: pipelineAggregations,
      timeBuckets,
      stageConversions,
      velocity,
      ownerPerformance,
      teamPerformance,
      lostReasons,
      cohorts,
    };
  }

  private async loadAccessiblePipelines(
    context: SecurityContext,
    filters: ReportingAggregationFilters,
    teamIds: string[]
  ): Promise<Pipeline[]> {
    const pipelinesResult = await this.pipelineRepo.getActive(context, teamIds);
    if (!pipelinesResult.success) {
      throw pipelinesResult.error;
    }

    const ownerFilters = sanitizeTeamIds(filters.ownerIds);
    const pipelineFilters = sanitizeTeamIds(filters.pipelineIds);
    const requestedTeams = sanitizeTeamIds(filters.teamIds);

    return pipelinesResult.data.data.filter((pipeline) => {
      if (pipelineFilters.length && !pipelineFilters.includes(pipeline.id)) {
        return false;
      }
      if (ownerFilters.length && !ownerFilters.includes(pipeline.ownerId)) {
        return false;
      }
      if (requestedTeams.length) {
        return pipeline.teamIds?.some((teamId) => requestedTeams.includes(teamId));
      }
      return true;
    });
  }

  private async loadDeals(
    context: SecurityContext,
    pipelines: Pipeline[],
    seedDeals?: Deal[]
  ): Promise<Deal[]> {
    if (seedDeals && seedDeals.length) {
      return seedDeals;
    }

    const deals: Deal[] = [];
    for (const pipeline of pipelines) {
      const result = await this.dealsRepo.getByPipeline(context, pipeline.id);
      if (result.success) {
        deals.push(...result.data);
      }
    }
    return deals;
  }

  private async loadLeads(
    context: SecurityContext,
    filters: ReportingAggregationFilters,
    seedLeads?: Lead[]
  ): Promise<Lead[]> {
    if (seedLeads && seedLeads.length) {
      return seedLeads;
    }

    const dateRange =
      filters.startDate && filters.endDate
        ? { start: filters.startDate, end: filters.endDate }
        : undefined;

    const result = await this.leadsRepo.getFiltered(
      context,
      {
        source:
          filters.sources && filters.sources.length === 1
            ? (filters.sources[0] as Lead['source'])
            : undefined,
        dateRange,
      },
      { limit: undefined }
    );

    if (!result.success) {
      return [];
    }

    return result.data.data;
  }

  private applyDateFilter(deals: Deal[], start?: Date, end?: Date): Deal[] {
    if (!start && !end) return deals;
    return deals.filter((deal) => {
      const eventDate =
        (deal.status === 'won' || deal.status === 'lost') && deal.closedAt
          ? (deal.closedAt as Date)
          : (deal.createdAt as Date);

      if (start && eventDate < start) return false;
      if (end && eventDate > end) return false;
      return true;
    });
  }

  private applyDealFilters(
    deals: Deal[],
    filters: ReportingAggregationFilters,
    resolvedTeams: string[]
  ): Deal[] {
    const stageFilters = sanitizeTeamIds(filters.stageIds);
    const ownerFilters = sanitizeTeamIds(filters.ownerIds);
    const pipelineFilters = sanitizeTeamIds(filters.pipelineIds);
    const sourceFilters = sanitizeTeamIds(filters.sources);

    return deals.filter((deal) => {
      if (pipelineFilters.length && !pipelineFilters.includes(deal.pipelineId)) {
        return false;
      }
      if (ownerFilters.length && deal.ownerId && !ownerFilters.includes(deal.ownerId)) {
        return false;
      }
      if (stageFilters.length && deal.stageId && !stageFilters.includes(deal.stageId)) {
        return false;
      }
      if (sourceFilters.length && (deal as unknown as { leadSource?: string }).leadSource) {
        const leadSource = (deal as unknown as { leadSource?: string }).leadSource;
        if (leadSource && !sourceFilters.includes(leadSource)) return false;
      }
      if (filters.teamIds?.length) {
        const teamIds = sanitizeTeamIds((deal as unknown as { teamIds?: string[] }).teamIds || []);
        if (!teamIds.some((id) => resolvedTeams.includes(id))) {
          return false;
        }
      }
      return true;
    });
  }

  private applyLeadFilters(
    leads: Lead[],
    start?: Date,
    end?: Date,
    sources?: string[]
  ): Lead[] {
    const sourceFilters = sanitizeTeamIds(sources);
    return leads.filter((lead) => {
      const createdAt = lead.createdAt as Date;
      if (start && createdAt < start) return false;
      if (end && createdAt > end) return false;
      if (sourceFilters.length && !sourceFilters.includes(lead.source)) return false;
      return true;
    });
  }

  private buildPipelineAggregations(
    pipelines: Pipeline[],
    deals: Deal[],
    includeStages?: boolean
  ): PipelineAggregation[] {
    return pipelines.map((pipeline) => {
      const pipelineDeals = deals.filter((deal) => deal.pipelineId === pipeline.id);
      const metrics = this.calculateKpis(pipelineDeals);
      const stageBreakdown = includeStages ? this.buildStageBreakdown(pipelineDeals) : [];
      const stageConversions = includeStages ? this.buildStageConversions(pipelineDeals) : [];
      const lostReasons = this.buildLostReasons(pipelineDeals, pipeline.id);
      const velocity = this.calculateVelocity(pipelineDeals);

      return {
        pipelineId: pipeline.id,
        ownerId: pipeline.ownerId,
        teamIds: sanitizeTeamIds(pipeline.teamIds),
        metrics,
        stageBreakdown,
        stageConversions,
        lostReasons,
        velocity,
      };
    });
  }

  private buildStageBreakdown(deals: Deal[]): StageSummary[] {
    const map = new Map<string, StageSummary>();
    deals.forEach((deal) => {
      if (!deal.stageId) return;
      const current = map.get(deal.stageId) || {
        stageId: deal.stageId,
        count: 0,
        valueCents: 0,
      };
      current.count += 1;
      current.valueCents += deal.valueCents || 0;
      map.set(deal.stageId, current);
    });
    return Array.from(map.values());
  }

  private buildStageConversions(deals: Deal[]): StageConversion[] {
    const stageMap = new Map<string, { entered: number; won: number; lost: number }>();
    deals.forEach((deal) => {
      if (!deal.stageId) return;
      const entry = stageMap.get(deal.stageId) || { entered: 0, won: 0, lost: 0 };
      entry.entered += 1;
      if (deal.status === 'won') {
        entry.won += 1;
      } else if (deal.status === 'lost') {
        entry.lost += 1;
      }
      stageMap.set(deal.stageId, entry);
    });

    return Array.from(stageMap.entries()).map(([stageId, data]) => ({
      stageId,
      entered: data.entered,
      won: data.won,
      lost: data.lost,
      conversionRate: data.entered ? (data.won / data.entered) * 100 : 0,
    }));
  }

  private buildLostReasons(deals: Deal[], pipelineId?: string): LostReasonBreakdown[] {
    const map = new Map<string, LostReasonBreakdown>();
    deals.forEach((deal) => {
      if (deal.status !== 'lost' || !deal.wonLostReason) return;
      const key = deal.wonLostReason;
      const current = map.get(key) || {
        reason: key,
        count: 0,
        valueCents: 0,
        pipelineId,
      };
      current.count += 1;
      current.valueCents += deal.valueCents || 0;
      map.set(key, current);
    });
    return Array.from(map.values());
  }

  private calculateKpis(deals: Deal[]): ReportingKpis {
    if (!deals.length) return { ...EMPTY_KPIS };

    let openCount = 0;
    let wonCount = 0;
    let lostCount = 0;
    let openValueCents = 0;
    let wonValueCents = 0;
    let lostValueCents = 0;
    let totalCycleDays = 0;
    let closedWithDates = 0;

    deals.forEach((deal) => {
      const value = deal.valueCents || 0;
      if (deal.status === 'won') {
        wonCount += 1;
        wonValueCents += value;
      } else if (deal.status === 'lost') {
        lostCount += 1;
        lostValueCents += value;
      } else {
        openCount += 1;
        openValueCents += value;
      }

      if (deal.closedAt) {
        const createdAt = deal.createdAt ? new Date(deal.createdAt) : null;
        const closedAt = new Date(deal.closedAt as Date);
        if (createdAt) {
          const cycleDays = Math.max(
            0,
            Math.round((closedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24))
          );
          totalCycleDays += cycleDays;
          closedWithDates += 1;
        }
      }
    });

    return {
      openCount,
      wonCount,
      lostCount,
      openValueCents,
      wonValueCents,
      lostValueCents,
      averageCycleDays: closedWithDates ? totalCycleDays / closedWithDates : 0,
    };
  }

  private mergeMetrics(metricList: ReportingKpis[]): ReportingKpis {
    if (!metricList.length) return { ...EMPTY_KPIS };
    let closedSamples = 0;
    let cycleDaysSum = 0;
    const totals = metricList.reduce<ReportingKpis>(
      (acc, metrics) => {
        acc.openCount += metrics.openCount;
        acc.wonCount += metrics.wonCount;
        acc.lostCount += metrics.lostCount;
        acc.openValueCents += metrics.openValueCents;
        acc.wonValueCents += metrics.wonValueCents;
        acc.lostValueCents += metrics.lostValueCents;
        const closed = metrics.wonCount + metrics.lostCount;
        if (closed > 0) {
          closedSamples += closed;
          cycleDaysSum += metrics.averageCycleDays * closed;
        }
        return acc;
      },
      { ...EMPTY_KPIS }
    );

    return {
      ...totals,
      averageCycleDays: closedSamples ? cycleDaysSum / closedSamples : 0,
    };
  }

  private buildTimeBuckets(
    deals: Deal[],
    bucket: ReportingTimeBucket,
    startDate?: Date,
    endDate?: Date
  ): TimeBucketAggregation[] {
    if (!deals.length) return [];

    const bucketMap = new Map<string, Deal[]>();
    deals.forEach((deal) => {
      const eventDate =
        (deal.status === 'won' || deal.status === 'lost') && deal.closedAt
          ? (deal.closedAt as Date)
          : (deal.createdAt as Date);

      const periodStart = this.truncateDate(eventDate, bucket);
      const periodEnd = this.getPeriodEnd(periodStart, bucket);
      if (startDate && periodEnd < startDate) return;
      if (endDate && periodStart > endDate) return;

      const bucketKey = `${bucket}-${periodStart.toISOString()}`;
      const existing = bucketMap.get(bucketKey) ?? [];
      existing.push(deal);
      bucketMap.set(bucketKey, existing);
    });

    const aggregations: TimeBucketAggregation[] = [];
    bucketMap.forEach((bucketDeals, key) => {
      const [, isoStart] = key.split(`${bucket}-`);
      const periodStart = isoStart ? new Date(isoStart) : this.truncateDate(new Date(), bucket);
      aggregations.push({
        bucket,
        periodStart,
        periodEnd: this.getPeriodEnd(periodStart, bucket),
        metrics: this.calculateKpis(bucketDeals),
      });
    });

    return aggregations.sort((a, b) => a.periodStart.getTime() - b.periodStart.getTime());
  }

  private truncateDate(date: Date, bucket: ReportingTimeBucket): Date {
    const base = new Date(date);
    if (bucket === 'daily') {
      base.setHours(0, 0, 0, 0);
      return base;
    }
    if (bucket === 'weekly') {
      const day = base.getDay();
      const diff = base.getDate() - day;
      base.setDate(diff);
      base.setHours(0, 0, 0, 0);
      return base;
    }
    // monthly
    base.setDate(1);
    base.setHours(0, 0, 0, 0);
    return base;
  }

  private getPeriodEnd(start: Date, bucket: ReportingTimeBucket): Date {
    const end = new Date(start);
    if (bucket === 'daily') {
      end.setHours(23, 59, 59, 999);
    } else if (bucket === 'weekly') {
      end.setDate(end.getDate() + 6);
      end.setHours(23, 59, 59, 999);
    } else {
      end.setMonth(end.getMonth() + 1);
      end.setDate(0); // last day of previous month
      end.setHours(23, 59, 59, 999);
    }
    return end;
  }

  private calculateVelocity(deals: Deal[]): VelocityMetrics {
    const kpis = this.calculateKpis(deals);
    const now = new Date();
    let openDaysSum = 0;
    let openSamples = 0;
    let earliestDate: Date | null = null;
    let latestDate: Date | null = null;

    deals.forEach((deal) => {
      const createdAt = deal.createdAt ? new Date(deal.createdAt) : null;
      if (!createdAt) return;
      if (!earliestDate || createdAt < earliestDate) earliestDate = createdAt;
      if (!latestDate || createdAt > latestDate) latestDate = createdAt;
      if (deal.status === 'open') {
        openDaysSum += Math.max(
          0,
          Math.round((now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24))
        );
        openSamples += 1;
      }
    });

    const closedCount = kpis.wonCount + kpis.lostCount;
    const windowDays = this.calculateWindowDays(earliestDate, latestDate);
    return {
      averageCycleDays: kpis.averageCycleDays,
      averageOpenDays: openSamples ? openDaysSum / openSamples : 0,
      throughputPerDay: windowDays ? closedCount / windowDays : 0,
      winRate: this.calculateWinRate(kpis.wonCount, kpis.lostCount),
    };
  }

  private calculateWindowDays(start?: Date | null, end?: Date | null): number {
    if (!start || !end) return 0;
    const diffMs = Math.max(1, end.getTime() - start.getTime());
    return Math.max(1, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
  }

  private calculateWinRate(won: number, lost: number): number {
    const closed = won + lost;
    return closed ? (won / closed) * 100 : 0;
  }

  private aggregateStageConversions(pipelines: PipelineAggregation[]): StageConversion[] {
    const map = new Map<string, { entered: number; won: number; lost: number }>();
    pipelines.forEach((pipeline) => {
      pipeline.stageConversions.forEach((conversion) => {
        const current = map.get(conversion.stageId) || { entered: 0, won: 0, lost: 0 };
        current.entered += conversion.entered;
        current.won += conversion.won;
        current.lost += conversion.lost;
        map.set(conversion.stageId, current);
      });
    });

    return Array.from(map.entries()).map(([stageId, data]) => ({
      stageId,
      entered: data.entered,
      won: data.won,
      lost: data.lost,
      conversionRate: data.entered ? (data.won / data.entered) * 100 : 0,
    }));
  }

  private aggregateLostReasons(pipelines: PipelineAggregation[]): LostReasonBreakdown[] {
    const map = new Map<string, LostReasonBreakdown>();
    pipelines.forEach((pipeline) => {
      pipeline.lostReasons.forEach((reason) => {
        const current = map.get(reason.reason) || {
          reason: reason.reason,
          count: 0,
          valueCents: 0,
          pipelineId: reason.pipelineId,
        };
        current.count += reason.count;
        current.valueCents += reason.valueCents;
        map.set(reason.reason, current);
      });
    });
    return Array.from(map.values());
  }

  private combineVelocity(
    pipelines: PipelineAggregation[],
    deals: Deal[],
    startDate?: Date,
    endDate?: Date
  ): VelocityMetrics {
    if (pipelines.length === 0) {
      return {
        averageCycleDays: 0,
        averageOpenDays: 0,
        throughputPerDay: 0,
        winRate: 0,
      };
    }

    // Prefer recalculating from deals for accuracy
    if (deals.length) {
      return this.calculateVelocity(deals);
    }

    let weightedCycleDays = 0;
    let cycleSamples = 0;
    let weightedOpenDays = 0;
    let openSamples = 0;
    let closedCount = 0;

    pipelines.forEach((pipeline) => {
      const metrics = pipeline.metrics;
      const closed = metrics.wonCount + metrics.lostCount;
      closedCount += closed;
      cycleSamples += closed;
      weightedCycleDays += metrics.averageCycleDays * closed;
      weightedOpenDays += pipeline.velocity.averageOpenDays * metrics.openCount;
      openSamples += metrics.openCount;
    });

    const windowDays = startDate && endDate ? this.calculateWindowDays(startDate, endDate) : 0;

    return {
      averageCycleDays: cycleSamples ? weightedCycleDays / cycleSamples : 0,
      averageOpenDays: openSamples ? weightedOpenDays / openSamples : 0,
      throughputPerDay: windowDays ? closedCount / windowDays : 0,
      winRate: this.calculateWinRate(
        pipelines.reduce((acc, p) => acc + p.metrics.wonCount, 0),
        pipelines.reduce((acc, p) => acc + p.metrics.lostCount, 0)
      ),
    };
  }

  private buildOwnerPerformance(deals: Deal[]): PerformanceMetrics[] {
    const map = new Map<string, Deal[]>();
    deals.forEach((deal) => {
      const ownerId = deal.ownerId || 'unknown-owner';
      const arr = map.get(ownerId) ?? [];
      arr.push(deal);
      map.set(ownerId, arr);
    });
    return Array.from(map.entries()).map(([ownerId, ownerDeals]) => {
      const metrics = this.calculateKpis(ownerDeals);
      return {
        ownerOrTeamId: ownerId,
        ownerOrTeamName: ownerDeals[0]?.ownerName,
        pipelineIds: Array.from(new Set(ownerDeals.map((d) => d.pipelineId))),
        metrics,
        winRate: this.calculateWinRate(metrics.wonCount, metrics.lostCount),
        averageCycleDays: metrics.averageCycleDays,
      };
    });
  }

  private buildTeamPerformance(deals: Deal[]): PerformanceMetrics[] {
    const map = new Map<string, Deal[]>();
    deals.forEach((deal) => {
      const teams = sanitizeTeamIds((deal as unknown as { teamIds?: string[] }).teamIds || []);
      teams.forEach((teamId) => {
        const arr = map.get(teamId) ?? [];
        arr.push(deal);
        map.set(teamId, arr);
      });
    });

    return Array.from(map.entries()).map(([teamId, teamDeals]) => {
      const metrics = this.calculateKpis(teamDeals);
      return {
        ownerOrTeamId: teamId,
        pipelineIds: Array.from(new Set(teamDeals.map((d) => d.pipelineId))),
        metrics,
        winRate: this.calculateWinRate(metrics.wonCount, metrics.lostCount),
        averageCycleDays: metrics.averageCycleDays,
      };
    });
  }

  private buildOwnerPerformanceFromPipelines(pipelines: PipelineAggregation[]): PerformanceMetrics[] {
    const map = new Map<string, PipelineAggregation[]>();
    pipelines.forEach((p) => {
      const arr = map.get(p.ownerId) ?? [];
      arr.push(p);
      map.set(p.ownerId, arr);
    });

    return Array.from(map.entries()).map(([ownerId, ownerPipelines]) => {
      const metrics = this.mergeMetrics(ownerPipelines.map((p) => p.metrics));
      return {
        ownerOrTeamId: ownerId,
        pipelineIds: ownerPipelines.map((p) => p.pipelineId),
        metrics,
        winRate: this.calculateWinRate(metrics.wonCount, metrics.lostCount),
        averageCycleDays: metrics.averageCycleDays,
      };
    });
  }

  private buildTeamPerformanceFromPipelines(pipelines: PipelineAggregation[]): PerformanceMetrics[] {
    const map = new Map<string, PipelineAggregation[]>();
    pipelines.forEach((p) => {
      const teams = sanitizeTeamIds(p.teamIds);
      teams.forEach((teamId) => {
        const arr = map.get(teamId) ?? [];
        arr.push(p);
        map.set(teamId, arr);
      });
    });

    return Array.from(map.entries()).map(([teamId, teamPipelines]) => {
      const metrics = this.mergeMetrics(teamPipelines.map((p) => p.metrics));
      return {
        ownerOrTeamId: teamId,
        pipelineIds: teamPipelines.map((p) => p.pipelineId),
        metrics,
        winRate: this.calculateWinRate(metrics.wonCount, metrics.lostCount),
        averageCycleDays: metrics.averageCycleDays,
      };
    });
  }

  private buildSourceCohorts(
    leads: Lead[],
    deals: Deal[],
    bucket: ReportingTimeBucket,
    startDate?: Date,
    endDate?: Date
  ): SourceCohort[] {
    if (!leads.length) return [];

    const bucketMap = new Map<string, SourceCohort>();
    const dealById = new Map(deals.map((deal) => [deal.id, deal]));

    leads.forEach((lead) => {
      const createdAt = lead.createdAt ? new Date(lead.createdAt) : null;
      if (!createdAt) return;
      if (startDate && createdAt < startDate) return;
      if (endDate && createdAt > endDate) return;

      const periodStart = this.truncateDate(createdAt, bucket);
      const periodEnd = this.getPeriodEnd(periodStart, bucket);
      const bucketKey = `${lead.source}-${periodStart.toISOString()}`;

      const current = bucketMap.get(bucketKey) ?? {
        source: lead.source,
        periodStart,
        periodEnd,
        leadCount: 0,
        convertedCount: 0,
        conversionRate: 0,
        wonValueCents: 0,
      };

      current.leadCount += 1;

      if (lead.status === 'converted' || lead.convertedToDealId) {
        current.convertedCount += 1;
        const convertedDeal = lead.convertedToDealId ? dealById.get(lead.convertedToDealId) : undefined;
        if (convertedDeal?.status === 'won') {
          current.wonValueCents += convertedDeal.valueCents || 0;
        }
      }

      current.conversionRate = current.leadCount
        ? (current.convertedCount / current.leadCount) * 100
        : 0;
      bucketMap.set(bucketKey, current);
    });

    return Array.from(bucketMap.values()).sort(
      (a, b) => a.periodStart.getTime() - b.periodStart.getTime()
    );
  }

  private async persistAggregates(
    context: SecurityContext,
    aggregates: PipelineAggregation[],
    filters: ReportingAggregationFilters,
    bucket: ReportingTimeBucket
  ): Promise<void> {
    await Promise.all(
      aggregates.map(async (aggregate) => {
        const payload: Omit<ReportingAggregate, 'id' | 'createdAt' | 'updatedAt'> = {
          pipelineId: aggregate.pipelineId,
          ownerId: aggregate.ownerId,
          teamIds: aggregate.teamIds,
          bucket,
          startDate: filters.startDate ?? this.truncateDate(new Date(), bucket),
          endDate: filters.endDate ?? new Date(),
          metrics: aggregate.metrics,
          stageBreakdown: aggregate.stageBreakdown,
          stageConversions: aggregate.stageConversions,
          lostReasons: aggregate.lostReasons,
          velocity: aggregate.velocity,
        };

        const customId = this.buildCacheId(aggregate.pipelineId, bucket, filters);
        await this.aggregateRepo.createAggregate(context, payload, customId);
      })
    );
  }

  private buildCacheId(
    pipelineId: string,
    bucket: ReportingTimeBucket,
    filters: ReportingAggregationFilters
  ): string | undefined {
    const startKey = filters.startDate ? filters.startDate.toISOString().split('T')[0] : 'any';
    const endKey = filters.endDate ? filters.endDate.toISOString().split('T')[0] : 'any';
    return `${pipelineId}-${bucket}-${startKey}-${endKey}`;
  }

  private async tryReadCache(
    context: SecurityContext,
    filters: ReportingAggregationFilters,
    teamIds: string[]
  ): Promise<ReportingAggregationResult | null> {
    const cacheResult = await this.aggregateRepo.getByFilters(
      context,
      { ...filters, teamIds },
      teamIds
    );
    if (!cacheResult.success || !cacheResult.data.length) {
      return null;
    }

    const pipelines = cacheResult.data.map<PipelineAggregation>((aggregate) => ({
      pipelineId: aggregate.pipelineId ?? 'unknown',
      ownerId: aggregate.ownerId ?? 'unknown',
      teamIds: aggregate.teamIds,
      metrics: aggregate.metrics,
      stageBreakdown: aggregate.stageBreakdown,
      stageConversions: aggregate.stageConversions ?? [],
      lostReasons: aggregate.lostReasons ?? [],
      velocity:
        aggregate.velocity ?? {
          averageCycleDays: aggregate.metrics.averageCycleDays,
          averageOpenDays: 0,
          throughputPerDay: 0,
          winRate: this.calculateWinRate(aggregate.metrics.wonCount, aggregate.metrics.lostCount),
        },
    }));

    const summary = this.mergeMetrics(pipelines.map((p) => p.metrics));
    const stageConversions = this.aggregateStageConversions(pipelines);
    const lostReasons = this.aggregateLostReasons(pipelines);
    const velocity = this.combineVelocity(pipelines, [], filters.startDate, filters.endDate);
    const ownerPerformance = this.buildOwnerPerformanceFromPipelines(pipelines);
    const teamPerformance = this.buildTeamPerformanceFromPipelines(pipelines);

    // Use the oldest cache timestamp to determine staleness
    const oldestCacheTime = cacheResult.data.reduce(
      (oldest, agg) => {
        const createdAt = agg.createdAt ? new Date(agg.createdAt) : new Date();
        return createdAt < oldest ? createdAt : oldest;
      },
      new Date()
    );

    return {
      generatedAt: oldestCacheTime,
      filters: { ...filters, bucket: filters.bucket ?? 'monthly' },
      summary,
      pipelines,
      timeBuckets: [],
      stageConversions,
      velocity,
      ownerPerformance,
      teamPerformance,
      lostReasons,
      cohorts: [],
    };
  }

  private assertFilterAccess(
    context: SecurityContext,
    filters: ReportingAggregationFilters,
    pipelines: Pipeline[]
  ): void {
    const requestedPipelines = sanitizeTeamIds(filters.pipelineIds);
    const accessiblePipelineIds = new Set(pipelines.map((p) => p.id));
    const inaccessiblePipelines = requestedPipelines.filter((id) => !accessiblePipelineIds.has(id));
    if (inaccessiblePipelines.length) {
      throw new AuthorizationError('Requested pipelines are not accessible for this user');
    }

    const hierarchy = getHierarchyScopeFromContext(context);
    const requestedTeams = sanitizeTeamIds(filters.teamIds);
    if (!hierarchy.isOrgPrivileged && requestedTeams.length) {
      const allowedTeams = new Set([...hierarchy.teamIds, ...hierarchy.managedTeamIds]);
      const unauthorizedTeams = requestedTeams.filter((id) => !allowedTeams.has(id));
      if (unauthorizedTeams.length) {
        throw new AuthorizationError('Requested team filters are not accessible for this user');
      }
    }
  }

  private async auditAccess(
    context: SecurityContext,
    filters: ReportingAggregationFilters,
    pipelineIds: string[],
    fromCache: boolean,
    resultSizes?: { dealCount?: number; leadCount?: number }
  ): Promise<void> {
    try {
      await this.auditService.logAction(context, {
        action: 'read',
        entityType: 'reportingAggregate',
        entityId: pipelineIds.join(',') || 'all',
        metadata: {
          bucket: filters.bucket ?? 'monthly',
          startDate: filters.startDate?.toISOString(),
          endDate: filters.endDate?.toISOString(),
          pipelineCount: pipelineIds.length,
          stageFilterCount: filters.stageIds?.length ?? 0,
          sourceFilterCount: filters.sources?.length ?? 0,
          fromCache,
          dealCount: resultSizes?.dealCount ?? 0,
          leadCount: resultSizes?.leadCount ?? 0,
        },
      });
    } catch (error) {
      // Audit failures must not block reporting reads
      console.warn('Reporting audit logging failed', error);
    }
  }

  private isPrivileged(context: SecurityContext): boolean {
    return context.userRole === 'owner' || context.userRole === 'admin';
  }

  private isCacheStale(generatedAt: Date): boolean {
    const age = Date.now() - new Date(generatedAt).getTime();
    return age > CACHE_TTL_MS;
  }

  private emptyResult(filters: ReportingAggregationFilters, bucket: ReportingTimeBucket) {
    return {
      generatedAt: new Date(),
      filters: { ...filters, bucket },
      summary: { ...EMPTY_KPIS },
      pipelines: [],
      timeBuckets: [],
      stageConversions: [],
      velocity: {
        averageCycleDays: 0,
        averageOpenDays: 0,
        throughputPerDay: 0,
        winRate: 0,
      },
      ownerPerformance: [],
      teamPerformance: [],
      lostReasons: [],
      cohorts: [],
    };
  }
}
