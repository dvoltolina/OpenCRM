import type { AuditEntry } from '../types/audit';
import type { Deal, Lead, SalesActivity, Stage } from '../types/models';
import { sanitizeTeamIds } from '../lib/security-context';

export interface ManagerDashboardFilters {
  selectedTeams: string[];
  pipelineId?: string;
  assigneeId?: string;
  dateRange?: { start?: Date; end?: Date };
  enforceTeamScope?: boolean;
}

export interface StageSummary {
  stageId: string;
  stageName: string;
  count: number;
  valueCents: number;
}

export interface ConversionSummary {
  totalLeads: number;
  convertedLeads: number;
  conversionRate: number;
}

export interface OverdueSlaRow {
  assigneeId: string;
  assigneeName: string;
  overdueCount: number;
  oldestDueDate?: Date;
}

export type ApprovalStatus = 'pending' | 'approved' | 'denied' | 'escalated' | 'unknown';

export interface ApprovalRequest {
  id: string;
  requestType: string;
  status: ApprovalStatus;
  teamIds: string[];
  entry: AuditEntry;
}

export interface WinLossSummary {
  wonCount: number;
  lostCount: number;
  winRate: number;
  wonValueCents: number;
  lostValueCents: number;
}

export interface WinRateTrendPoint {
  bucketLabel: string;
  won: number;
  lost: number;
  winRate: number;
}

function isWithinRange(date: Date | undefined, range?: { start?: Date; end?: Date }) {
  if (!date) return false;
  if (!range?.start && !range?.end) return true;
  const time = date.getTime();
  const afterStart = range?.start ? time >= range.start.getTime() : true;
  const beforeEnd = range?.end ? time <= range.end.getTime() : true;
  return afterStart && beforeEnd;
}

function matchesTeamScope(
  entityTeams: string[] | undefined,
  filters: ManagerDashboardFilters
): boolean {
  const selected = sanitizeTeamIds(filters.selectedTeams);
  const enforce = Boolean(filters.enforceTeamScope);
  if (selected.length === 0) {
    return !enforce;
  }
  const teams = sanitizeTeamIds(entityTeams);
  return teams.some((team) => selected.includes(team));
}

export function filterDealsForManager(
  deals: Deal[],
  filters: ManagerDashboardFilters
): Deal[] {
  return deals.filter((deal) => {
    if (!matchesTeamScope(deal.teamIds, filters)) return false;
    if (filters.pipelineId && deal.pipelineId !== filters.pipelineId) return false;
    if (filters.assigneeId && deal.assigneeId !== filters.assigneeId) return false;
    if (filters.dateRange && !isWithinRange(deal.createdAt, filters.dateRange)) return false;
    return true;
  });
}

export function filterLeadsForManager(
  leads: Lead[],
  filters: ManagerDashboardFilters
): Lead[] {
  return leads.filter((lead) => {
    if (!matchesTeamScope(lead.teamIds, filters)) return false;
    if (filters.assigneeId && lead.assigneeId !== filters.assigneeId) return false;
    if (filters.dateRange && !isWithinRange(lead.createdAt, filters.dateRange)) return false;
    return true;
  });
}

export function filterActivitiesForManager(
  activities: SalesActivity[],
  filters: ManagerDashboardFilters
): SalesActivity[] {
  return activities.filter((activity) => {
    if (!matchesTeamScope(activity.teamIds, filters)) return false;
    if (filters.assigneeId && activity.assigneeId !== filters.assigneeId) return false;
    if (filters.dateRange && !isWithinRange(activity.createdAt, filters.dateRange)) return false;
    return true;
  });
}

export function summarizeStages(deals: Deal[], stages: Stage[]): StageSummary[] {
  const stageMap = new Map<string, StageSummary>();
  stages.forEach((stage) => {
    stageMap.set(stage.id, {
      stageId: stage.id,
      stageName: stage.name,
      count: 0,
      valueCents: 0,
    });
  });

  deals
    .filter((deal) => deal.status === 'open')
    .forEach((deal) => {
      const current = stageMap.get(deal.stageId) || {
        stageId: deal.stageId,
        stageName: 'Unknown Stage',
        count: 0,
        valueCents: 0,
      };
      current.count += 1;
      current.valueCents += deal.valueCents;
      stageMap.set(deal.stageId, current);
    });

  return Array.from(stageMap.values());
}

export function calculateConversionSummary(
  leads: Lead[],
  range?: { start?: Date; end?: Date }
): ConversionSummary {
  const leadsInRange = range ? leads.filter((lead) => isWithinRange(lead.createdAt, range)) : leads;
  const convertedLeads = leadsInRange.filter(
    (lead) => lead.status === 'converted' && (!range || isWithinRange(lead.convertedAt, range))
  );
  const totalLeads = leadsInRange.length;
  const conversionRate = totalLeads > 0 ? (convertedLeads.length / totalLeads) * 100 : 0;

  return {
    totalLeads,
    convertedLeads: convertedLeads.length,
    conversionRate,
  };
}

export function buildOverdueSla(
  tasks: SalesActivity[],
  filters: ManagerDashboardFilters
): OverdueSlaRow[] {
  const now = Date.now();
  const overdue = tasks.filter(
    (task) =>
      !task.isCompleted &&
      task.dueDate &&
      task.dueDate.getTime() < now &&
      matchesTeamScope(task.teamIds, filters) &&
      (!filters.assigneeId || task.assigneeId === filters.assigneeId)
  );

  const grouped = new Map<string, OverdueSlaRow>();
  overdue.forEach((task) => {
    const key = task.assigneeId || 'unassigned';
    const existing = grouped.get(key) || {
      assigneeId: key,
      assigneeName: task.assigneeName || 'Unassigned',
      overdueCount: 0,
      oldestDueDate: task.dueDate || undefined,
    };
    existing.overdueCount += 1;
    if (task.dueDate && (!existing.oldestDueDate || task.dueDate < existing.oldestDueDate)) {
      existing.oldestDueDate = task.dueDate;
    }
    grouped.set(key, existing);
  });

  return Array.from(grouped.values()).sort((a, b) => b.overdueCount - a.overdueCount);
}

export function filterApprovals(
  entries: AuditEntry[],
  filters: ManagerDashboardFilters
): AuditEntry[] {
  return entries.filter((entry) => {
    const meta = entry.metadata || {};
    const category = String(meta.category || meta.type || '').toLowerCase();
    const approvalType = String(meta.approvalType || meta.approval || '').toLowerCase();
    const requestType = String(meta.requestType || '').toLowerCase();
    const status = String(meta.status || '').toLowerCase();
    const decision = String(meta.decision || '').toLowerCase();

    const isApprovalLike =
      category.includes('approval') ||
      category.includes('escalation') ||
      approvalType.length > 0 ||
      requestType.includes('approval') ||
      requestType.includes('escalation') ||
      status.includes('approval') ||
      status.includes('escalated') ||
      decision.includes('approve') ||
      decision.includes('deny');

    if (!isApprovalLike) return false;

    const entryTeams = sanitizeTeamIds(
      Array.isArray(meta.teamIds) ? meta.teamIds : Array.isArray(meta.managedTeamIds) ? meta.managedTeamIds : []
    );

    if (entryTeams.length === 0 && filters.enforceTeamScope) {
      return false;
    }

    return matchesTeamScope(entryTeams, filters);
  });
}

function deriveApprovalStatus(meta: Record<string, any>): ApprovalStatus {
  const status = String(meta.status || meta.state || meta.resolution || '').toLowerCase();
  const decision = String(meta.decision || '').toLowerCase();
  const approved = meta.approved === true;
  const denied = meta.denied === true;

  if (approved || status.includes('approved') || decision.includes('approve')) {
    return 'approved';
  }
  if (denied || status.includes('denied') || status.includes('rejected') || decision.includes('deny')) {
    return 'denied';
  }
  if (status.includes('escalated') || decision.includes('escalat')) {
    return 'escalated';
  }
  if (status.includes('pending') || !status) {
    return 'pending';
  }
  return 'unknown';
}

function deriveApprovalRequestType(entry: AuditEntry): string {
  const meta = entry.metadata || {};
  const candidates = [
    meta.approvalType,
    meta.requestType,
    meta.category,
    meta.type,
    meta.reason,
  ]
    .map((value) => (value ? String(value).trim() : ''))
    .filter(Boolean);

  if (candidates.length > 0) {
    return candidates[0];
  }

  return 'approval';
}

export function buildApprovalRequests(
  entries: AuditEntry[],
  filters: ManagerDashboardFilters
): ApprovalRequest[] {
  return filterApprovals(entries, filters).map((entry) => {
    const meta = entry.metadata || {};
    const teamIds = sanitizeTeamIds(
      Array.isArray(meta.teamIds)
        ? meta.teamIds
        : Array.isArray(meta.managedTeamIds)
          ? meta.managedTeamIds
          : []
    );

    return {
      id: entry.id,
      requestType: deriveApprovalRequestType(entry),
      status: deriveApprovalStatus(meta),
      teamIds,
      entry,
    };
  });
}

function pickClosedDate(deal: Deal): Date | undefined {
  return deal.closedAt || deal.updatedAt || deal.createdAt;
}

export function computeWinLossSummary(
  deals: Deal[],
  range?: { start?: Date; end?: Date }
): WinLossSummary {
  const closed = deals.filter((deal) => deal.status !== 'open');

  let wonCount = 0;
  let lostCount = 0;
  let wonValueCents = 0;
  let lostValueCents = 0;

  closed.forEach((deal) => {
    const closedAt = pickClosedDate(deal);
    if (range && !isWithinRange(closedAt || deal.createdAt, range)) {
      return;
    }
    if (deal.status === 'won') {
      wonCount += 1;
      wonValueCents += deal.valueCents || 0;
    } else if (deal.status === 'lost') {
      lostCount += 1;
      lostValueCents += deal.valueCents || 0;
    }
  });

  const total = wonCount + lostCount;
  const winRate = total > 0 ? (wonCount / total) * 100 : 0;

  return {
    wonCount,
    lostCount,
    winRate,
    wonValueCents,
    lostValueCents,
  };
}

export function computeWeightedForecast(deals: Deal[]): number {
  return deals
    .filter((deal) => deal.status === 'open')
    .reduce((sum, deal) => sum + (deal.valueCents || 0) * (deal.probability / 100), 0);
}

function formatBucketLabel(date: Date, granularity: 'month' | 'week'): string {
  if (granularity === 'week') {
    const week = Math.ceil(date.getDate() / 7);
    return `${date.getFullYear()}-W${week}`;
  }
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  return `${date.getFullYear()}-${month}`;
}

export function computeWinRateTrend(
  deals: Deal[],
  range?: { start?: Date; end?: Date },
  granularity: 'month' | 'week' = 'month'
): WinRateTrendPoint[] {
  const buckets = new Map<string, { won: number; lost: number }>();

  deals
    .filter((deal) => deal.status !== 'open')
    .forEach((deal) => {
      const closedAt = pickClosedDate(deal);
      if (range && !isWithinRange(closedAt || deal.createdAt, range)) {
        return;
      }
      const date = closedAt || deal.createdAt || new Date();
      const label = formatBucketLabel(date, granularity);
      const bucket = buckets.get(label) || { won: 0, lost: 0 };
      if (deal.status === 'won') bucket.won += 1;
      if (deal.status === 'lost') bucket.lost += 1;
      buckets.set(label, bucket);
    });

  return Array.from(buckets.entries())
    .sort(([a], [b]) => (a < b ? -1 : 1))
    .map(([bucketLabel, bucket]) => {
      const total = bucket.won + bucket.lost;
      const winRate = total > 0 ? (bucket.won / total) * 100 : 0;
      return { bucketLabel, won: bucket.won, lost: bucket.lost, winRate };
    });
}
