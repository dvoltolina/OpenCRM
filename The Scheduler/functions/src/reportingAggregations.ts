// @ts-nocheck
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {auth, db, Timestamp} from "./firebaseAdmin";
import type {Query} from "firebase-admin/firestore";
import {applyCors} from "./httpUtils";
import {isAdminRole, normalizeUserRole} from "./roleUtils";

type ReportingTimeBucket = "daily" | "weekly" | "monthly";

interface ReportingKpis {
  openCount: number;
  wonCount: number;
  lostCount: number;
  openValueCents: number;
  wonValueCents: number;
  lostValueCents: number;
  averageCycleDays: number;
}

interface VelocityMetrics {
  averageCycleDays: number;
  averageOpenDays: number;
  throughputPerDay: number;
  winRate: number;
}

interface StageSummary {
  stageId: string;
  count: number;
  valueCents: number;
}

interface StageConversion {
  stageId: string;
  entered: number;
  won: number;
  lost: number;
  conversionRate: number;
}

interface LostReasonBreakdown {
  reason: string;
  count: number;
  valueCents: number;
  pipelineId?: string;
}

interface TimeBucketAggregation {
  bucket: ReportingTimeBucket;
  periodStart: string;
  periodEnd: string;
  metrics: ReportingKpis;
  pipelineId?: string;
}

interface PerformanceMetrics {
  ownerOrTeamId: string;
  ownerOrTeamName?: string;
  pipelineIds: string[];
  metrics: ReportingKpis;
  winRate: number;
  averageCycleDays: number;
}

interface SourceCohort {
  source: string;
  periodStart: string;
  periodEnd: string;
  leadCount: number;
  convertedCount: number;
  conversionRate: number;
  wonValueCents: number;
}

interface PipelineAggregation {
  pipelineId: string;
  ownerId: string;
  teamIds: string[];
  metrics: ReportingKpis;
  stageBreakdown: StageSummary[];
  stageConversions: StageConversion[];
  lostReasons: LostReasonBreakdown[];
  velocity: VelocityMetrics;
}

interface ReportingAggregationFilters {
  startDate?: string;
  endDate?: string;
  pipelineIds?: string[];
  ownerIds?: string[];
  teamIds?: string[];
  stageIds?: string[];
  sources?: string[];
  bucket?: ReportingTimeBucket;
  includeStageBreakdown?: boolean;
  preferCache?: boolean;
}

interface ReportingAggregationResult {
  generatedAt: string;
  filters: ReportingAggregationFilters;
  summary: ReportingKpis;
  pipelines: PipelineAggregation[];
  timeBuckets: TimeBucketAggregation[];
  stageConversions: StageConversion[];
  velocity: VelocityMetrics;
  ownerPerformance: PerformanceMetrics[];
  teamPerformance: PerformanceMetrics[];
  lostReasons: LostReasonBreakdown[];
  cohorts: SourceCohort[];
}

const emptyKpis: ReportingKpis = {
  openCount: 0,
  wonCount: 0,
  lostCount: 0,
  openValueCents: 0,
  wonValueCents: 0,
  lostValueCents: 0,
  averageCycleDays: 0,
};

const emptyVelocity: VelocityMetrics = {
  averageCycleDays: 0,
  averageOpenDays: 0,
  throughputPerDay: 0,
  winRate: 0,
};

const toStringArray = (value: unknown): string[] =>
  Array.isArray(value)
    ? value.filter((v) => typeof v === "string").map((v) => v.trim()).filter(Boolean)
    : [];

const parseDateString = (value: unknown): string | undefined => {
  if (typeof value !== "string" || !value.trim()) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date.toISOString();
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const toDate = (value?: string): Date | undefined => {
  if (!value) return undefined;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? undefined : parsed;
};

const toTimestamp = (value?: Date): Timestamp | undefined =>
  value ? Timestamp.fromDate(value) : undefined;

const sanitizeTeams = (teams?: unknown): string[] => toStringArray(teams);

const isPrivileged = (role?: string): boolean =>
  isAdminRole(role);

const now = () => new Date();

const buildCacheId = (
  pipelineId: string,
  bucket: ReportingTimeBucket,
  startDate?: Date,
  endDate?: Date
): string => {
  const startKey = startDate ? startDate.toISOString().split("T")[0] : "any";
  const endKey = endDate ? endDate.toISOString().split("T")[0] : "any";
  return `${pipelineId}-${bucket}-${startKey}-${endKey}`;
};

const readCachedAggregates = async (
  businessId: string,
  pipelineIds: string[],
  bucket: ReportingTimeBucket,
  startDate?: Date,
  endDate?: Date
): Promise<PipelineAggregation[]> => {
  const results: PipelineAggregation[] = [];
  for (const pipelineId of pipelineIds) {
    const cacheId = buildCacheId(pipelineId, bucket, startDate, endDate);
    const docRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("reporting_aggregates")
      .doc(cacheId);
    const snap = await docRef.get();
    if (!snap.exists) {
      return [];
    }
    const data = snap.data() || {};
    results.push({
      pipelineId,
      ownerId: typeof data.ownerId === "string" ? data.ownerId : "unknown-owner",
      teamIds: sanitizeTeams(data.teamIds),
      metrics: data.metrics ?? {...emptyKpis},
      stageBreakdown: Array.isArray(data.stageBreakdown) ? data.stageBreakdown : [],
      stageConversions: Array.isArray(data.stageConversions) ? data.stageConversions : [],
      lostReasons: Array.isArray(data.lostReasons) ? data.lostReasons : [],
      velocity:
        data.velocity ??
        {
          ...emptyVelocity,
          winRate: data.metrics ? calcWinRate(data.metrics.wonCount, data.metrics.lostCount) : 0,
        },
    });
  }
  return results;
};

const writeCachedAggregates = async (
  businessId: string,
  pipelines: PipelineAggregation[],
  bucket: ReportingTimeBucket,
  startDate?: Date,
  endDate?: Date
): Promise<void> => {
  const batch = db.batch();
  pipelines.forEach((aggregate) => {
    const cacheId = buildCacheId(aggregate.pipelineId, bucket, startDate, endDate);
    const docRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("reporting_aggregates")
      .doc(cacheId);
    batch.set(docRef, {
      pipelineId: aggregate.pipelineId,
      ownerId: aggregate.ownerId,
      teamIds: aggregate.teamIds,
      bucket,
      startDate: startDate ? Timestamp.fromDate(startDate) : null,
      endDate: endDate ? Timestamp.fromDate(endDate) : null,
      metrics: aggregate.metrics,
      stageBreakdown: aggregate.stageBreakdown,
      stageConversions: aggregate.stageConversions,
      lostReasons: aggregate.lostReasons,
      velocity: aggregate.velocity,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
  await batch.commit();
};

const calcWinRate = (won: number, lost: number): number => {
  const closed = won + lost;
  return closed ? (won / closed) * 100 : 0;
};

const calcKpis = (deals: DealDoc[]): ReportingKpis => {
  if (!deals.length) return {...emptyKpis};

  let openCount = 0;
  let wonCount = 0;
  let lostCount = 0;
  let openValueCents = 0;
  let wonValueCents = 0;
  let lostValueCents = 0;
  let totalCycleDays = 0;
  let closedWithDates = 0;

  deals.forEach((deal) => {
    const value = deal.valueCents ?? 0;
    const status = deal.status ?? "open";
    if (status === "won") {
      wonCount += 1;
      wonValueCents += value;
    } else if (status === "lost") {
      lostCount += 1;
      lostValueCents += value;
    } else {
      openCount += 1;
      openValueCents += value;
    }

    if (deal.closedAt && deal.createdAt) {
      const cycleDays = Math.max(
        0,
        Math.round(
          (deal.closedAt.getTime() - deal.createdAt.getTime()) / (1000 * 60 * 60 * 24)
        )
      );
      totalCycleDays += cycleDays;
      closedWithDates += 1;
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
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const mergeKpis = (list: ReportingKpis[]): ReportingKpis => {
  if (!list.length) return {...emptyKpis};
  let closedSamples = 0;
  let cycleDaysSum = 0;
  const total = list.reduce<ReportingKpis>(
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
    {...emptyKpis}
  );

  return {
    ...total,
    averageCycleDays: closedSamples ? cycleDaysSum / closedSamples : 0,
  };
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildStageBreakdown = (_deals: DealDoc[]): StageSummary[] => {
  const map = new Map<string, StageSummary>();
  deals.forEach((deal) => {
    if (!deal.stageId) return;
    const current = map.get(deal.stageId) || {stageId: deal.stageId, count: 0, valueCents: 0};
    current.count += 1;
    current.valueCents += deal.valueCents ?? 0;
    map.set(deal.stageId, current);
  });
  return Array.from(map.values());
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildStageConversions = (_deals: DealDoc[]): StageConversion[] => {
  const map = new Map<string, {entered: number; won: number; lost: number}>();
  deals.forEach((deal) => {
    if (!deal.stageId) return;
    const entry = map.get(deal.stageId) || {entered: 0, won: 0, lost: 0};
    entry.entered += 1;
    if (deal.status === "won") entry.won += 1;
    if (deal.status === "lost") entry.lost += 1;
    map.set(deal.stageId, entry);
  });

  return Array.from(map.entries()).map(([stageId, data]) => ({
    stageId,
    entered: data.entered,
    won: data.won,
    lost: data.lost,
    conversionRate: data.entered ? (data.won / data.entered) * 100 : 0,
  }));
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildLostReasons = (_deals: DealDoc[], _pipelineId?: string): LostReasonBreakdown[] => {
  const map = new Map<string, LostReasonBreakdown>();
  deals.forEach((deal) => {
    if (deal.status !== "lost" || !deal.wonLostReason) return;
    const key = deal.wonLostReason;
    const current = map.get(key) || {reason: key, count: 0, valueCents: 0, pipelineId};
    current.count += 1;
    current.valueCents += deal.valueCents ?? 0;
    map.set(key, current);
  });
  return Array.from(map.values());
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const calcVelocity = (_deals: DealDoc[]): VelocityMetrics => {
  const kpis = calcKpis(deals);
  const nowDate = now();
  let openDaysSum = 0;
  let openSamples = 0;
  let earliest: Date | undefined;
  let latest: Date | undefined;

  deals.forEach((deal) => {
    if (deal.createdAt) {
      if (!earliest || deal.createdAt < earliest) earliest = deal.createdAt;
      if (!latest || deal.createdAt > latest) latest = deal.createdAt;
    }
    if (deal.status === "open" && deal.createdAt) {
      openDaysSum += Math.max(
        0,
        Math.round((nowDate.getTime() - deal.createdAt.getTime()) / (1000 * 60 * 60 * 24))
      );
      openSamples += 1;
    }
  });

  const closedCount = kpis.wonCount + kpis.lostCount;
  const windowDays = earliest && latest ?
    Math.max(1, Math.ceil((latest.getTime() - earliest.getTime()) / (1000 * 60 * 60 * 24))) :
    0;

  return {
    averageCycleDays: kpis.averageCycleDays,
    averageOpenDays: openSamples ? openDaysSum / openSamples : 0,
    throughputPerDay: windowDays ? closedCount / windowDays : 0,
    winRate: calcWinRate(kpis.wonCount, kpis.lostCount),
  };
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildTimeBuckets = (
  _deals: DealDoc[],
  bucket: ReportingTimeBucket,
  _startDate?: Date,
  _endDate?: Date
): TimeBucketAggregation[] => {
  if (!deals.length) return [];

  const bucketMap = new Map<string, DealDoc[]>();
  deals.forEach((deal) => {
    const eventDate =
      (deal.status === "won" || deal.status === "lost") && deal.closedAt
        ? deal.closedAt
        : deal.createdAt;
    if (!eventDate) return;

    const periodStart = truncateDate(eventDate, bucket);
    const periodEnd = getPeriodEnd(periodStart, bucket);
    if (startDate && periodEnd < startDate) return;
    if (endDate && periodStart > endDate) return;

    const key = `${bucket}-${periodStart.toISOString()}`;
    const existing = bucketMap.get(key) ?? [];
    existing.push(deal);
    bucketMap.set(key, existing);
  });

  return Array.from(bucketMap.entries())
    .map(([key, bucketDeals]) => {
      const [, iso] = key.split(`${bucket}-`);
      const start = iso ? new Date(iso) : truncateDate(new Date(), bucket);
      return {
        bucket,
        periodStart: start.toISOString(),
        periodEnd: getPeriodEnd(start, bucket).toISOString(),
        metrics: calcKpis(bucketDeals),
      };
    })
    .sort((a, b) => new Date(a.periodStart).getTime() - new Date(b.periodStart).getTime());
};

const truncateDate = (date: Date, bucket: ReportingTimeBucket): Date => {
  const d = new Date(date);
  if (bucket === "daily") {
    d.setHours(0, 0, 0, 0);
    return d;
  }
  if (bucket === "weekly") {
    const day = d.getDay();
    const diff = d.getDate() - day;
    d.setDate(diff);
    d.setHours(0, 0, 0, 0);
    return d;
  }
  d.setDate(1);
  d.setHours(0, 0, 0, 0);
  return d;
};

const getPeriodEnd = (start: Date, bucket: ReportingTimeBucket): Date => {
  const end = new Date(start);
  if (bucket === "daily") {
    end.setHours(23, 59, 59, 999);
  } else if (bucket === "weekly") {
    end.setDate(end.getDate() + 6);
    end.setHours(23, 59, 59, 999);
  } else {
    end.setMonth(end.getMonth() + 1);
    end.setDate(0);
    end.setHours(23, 59, 59, 999);
  }
  return end;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildOwnerPerformance = (_deals: DealDoc[]): PerformanceMetrics[] => {
  const map = new Map<string, DealDoc[]>();
  deals.forEach((deal) => {
    const ownerId = deal.ownerId || "unknown-owner";
    const arr = map.get(ownerId) ?? [];
    arr.push(deal);
    map.set(ownerId, arr);
  });
  return Array.from(map.entries()).map(([ownerId, ownerDeals]) => {
    const metrics = calcKpis(ownerDeals);
    return {
      ownerOrTeamId: ownerId,
      ownerOrTeamName: ownerDeals[0]?.ownerName,
      pipelineIds: Array.from(new Set(ownerDeals.map((d) => d.pipelineId))),
      metrics,
      winRate: calcWinRate(metrics.wonCount, metrics.lostCount),
      averageCycleDays: metrics.averageCycleDays,
    };
  });
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildTeamPerformance = (_deals: DealDoc[]): PerformanceMetrics[] => {
  const map = new Map<string, DealDoc[]>();
  deals.forEach((deal) => {
    const teams = sanitizeTeams(deal.teamIds);
    teams.forEach((teamId) => {
      const arr = map.get(teamId) ?? [];
      arr.push(deal);
      map.set(teamId, arr);
    });
  });

  return Array.from(map.entries()).map(([teamId, teamDeals]) => {
    const metrics = calcKpis(teamDeals);
    return {
      ownerOrTeamId: teamId,
      pipelineIds: Array.from(new Set(teamDeals.map((d) => d.pipelineId))),
      metrics,
      winRate: calcWinRate(metrics.wonCount, metrics.lostCount),
      averageCycleDays: metrics.averageCycleDays,
    };
  });
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const buildSourceCohorts = (
  _leads: LeadDoc[],
  _deals: DealDoc[],
  _bucket: ReportingTimeBucket,
  _startDate?: Date,
  _endDate?: Date
): SourceCohort[] => {
  if (!leads.length) return [];

  const dealMap = new Map(deals.map((deal) => [deal.id, deal]));
  const buckets = new Map<string, SourceCohort>();

  leads.forEach((lead) => {
    const createdAt = lead.createdAt;
    if (!createdAt) return;
    if (startDate && createdAt < startDate) return;
    if (endDate && createdAt > endDate) return;
    const periodStart = truncateDate(createdAt, bucket);
    const periodEnd = getPeriodEnd(periodStart, bucket);
    const key = `${lead.source || "other"}-${periodStart.toISOString()}`;

    const current =
      buckets.get(key) ??
      {
        source: lead.source || "other",
        periodStart: periodStart.toISOString(),
        periodEnd: periodEnd.toISOString(),
        leadCount: 0,
        convertedCount: 0,
        conversionRate: 0,
        wonValueCents: 0,
      };

    current.leadCount += 1;
    if (lead.status === "converted" || lead.convertedToDealId) {
      current.convertedCount += 1;
      const convertedDeal = lead.convertedToDealId ? dealMap.get(lead.convertedToDealId) : undefined;
      if (convertedDeal?.status === "won") {
        current.wonValueCents += convertedDeal.valueCents ?? 0;
      }
    }

    current.conversionRate = current.leadCount
      ? (current.convertedCount / current.leadCount) * 100
      : 0;
    buckets.set(key, current);
  });

  return Array.from(buckets.values()).sort(
    (a, b) => new Date(a.periodStart).getTime() - new Date(b.periodStart).getTime()
  );
};

const loadPipelines = async (
  businessId: string,
  filters: ReportingAggregationFilters,
  userId: string,
  role: string,
  userTeams: string[]
): Promise<PipelineDoc[]> => {
  const pipelinesSnap = await db
    .collection("businesses")
    .doc(businessId)
    .collection("pipelines")
    .where("isActive", "==", true)
    .get();

  const pipelines: PipelineDoc[] = pipelinesSnap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      ownerId: typeof data.ownerId === "string" ? data.ownerId : undefined,
      ownerName: typeof data.ownerName === "string" ? data.ownerName : undefined,
      teamIds: sanitizeTeams(data.teamIds),
      isActive: data.isActive !== false,
    };
  });

  const pipelineFilter = new Set(filters.pipelineIds ?? []);
  const ownerFilter = new Set(filters.ownerIds ?? []);
  const teamFilter = new Set(filters.teamIds ?? []);

  return pipelines.filter((pipeline) => {
    if (!pipeline.isActive) return false;
    if (pipelineFilter.size && !pipelineFilter.has(pipeline.id)) return false;
    if (ownerFilter.size && pipeline.ownerId && !ownerFilter.has(pipeline.ownerId)) return false;
    if (teamFilter.size && !pipeline.teamIds?.some((id) => teamFilter.has(id))) return false;
    if (isPrivileged(role)) return true;
    if (pipeline.ownerId === userId) return true;
    return pipeline.teamIds?.some((id) => userTeams.includes(id));
  });
};

const loadDealsForPipeline = async (
  businessId: string,
  pipelineId: string,
  filters: ReportingAggregationFilters
): Promise<DealDoc[]> => {
  let query = db
    .collection("businesses")
    .doc(businessId)
    .collection("deals")
    .where("pipelineId", "==", pipelineId);

  const startDate = toDate(filters.startDate);
  const endDate = toDate(filters.endDate);
  if (startDate) {
    const ts = toTimestamp(startDate);
    if (ts) query = query.where("createdAt", ">=", ts);
  }
  if (endDate) {
    const ts = toTimestamp(endDate);
    if (ts) query = query.where("createdAt", "<=", ts);
  }

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      pipelineId,
      stageId: typeof data.stageId === "string" ? data.stageId : undefined,
      status: typeof data.status === "string" ? data.status : "open",
      valueCents: typeof data.valueCents === "number" ? data.valueCents : 0,
      createdAt:
        data.createdAt instanceof Timestamp ? data.createdAt.toDate() : undefined,
      closedAt:
        data.closedAt instanceof Timestamp ? data.closedAt.toDate() : undefined,
      ownerId: typeof data.ownerId === "string" ? data.ownerId : undefined,
      ownerName: typeof data.ownerName === "string" ? data.ownerName : undefined,
      teamIds: sanitizeTeams(data.teamIds),
      wonLostReason: typeof data.wonLostReason === "string" ? data.wonLostReason : undefined,
      leadSource: typeof data.leadSource === "string" ? data.leadSource : undefined,
    };
  });
};

const loadLeads = async (
  businessId: string,
  filters: ReportingAggregationFilters
): Promise<LeadDoc[]> => {
  let query: Query = db
    .collection("businesses")
    .doc(businessId)
    .collection("leads");

  const startDate = toDate(filters.startDate);
  const endDate = toDate(filters.endDate);
  if (startDate) {
    const ts = toTimestamp(startDate);
    if (ts) query = query.where("createdAt", ">=", ts);
  }
  if (endDate) {
    const ts = toTimestamp(endDate);
    if (ts) query = query.where("createdAt", "<=", ts);
  }

  const snapshot = await query.get();
  const sourceFilter = new Set(filters.sources ?? []);

  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        source: typeof data.source === "string" ? data.source : "other",
        status: typeof data.status === "string" ? data.status : undefined,
        createdAt:
          data.createdAt instanceof Timestamp ? data.createdAt.toDate() : undefined,
        convertedToDealId:
          typeof data.convertedToDealId === "string" ? data.convertedToDealId : undefined,
      };
    })
    .filter((lead) => {
      if (!sourceFilter.size) return true;
      return lead.source ? sourceFilter.has(lead.source) : false;
    });
};

const filterDealsByAccessAndFilters = (
  deals: DealDoc[],
  filters: ReportingAggregationFilters,
  userTeams: string[],
  role: string,
  userId: string
): DealDoc[] => {
  const stageFilter = new Set(filters.stageIds ?? []);
  const ownerFilter = new Set(filters.ownerIds ?? []);
  const teamFilter = new Set(filters.teamIds ?? []);
  const sourceFilter = new Set(filters.sources ?? []);

  return deals.filter((deal) => {
    if (stageFilter.size && deal.stageId && !stageFilter.has(deal.stageId)) return false;
    if (ownerFilter.size && deal.ownerId && !ownerFilter.has(deal.ownerId)) return false;
    if (teamFilter.size && !sanitizeTeams(deal.teamIds).some((id) => teamFilter.has(id))) {
      return false;
    }
    if (sourceFilter.size && deal.leadSource && !sourceFilter.has(deal.leadSource)) {
      return false;
    }
    if (isPrivileged(role)) return true;
    if (deal.ownerId === userId) return true;
    return sanitizeTeams(deal.teamIds).some((id) => userTeams.includes(id));
  });
};

type PipelineDoc = {
  id: string;
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  isActive?: boolean;
};

type DealDoc = {
  id: string;
  pipelineId: string;
  stageId?: string;
  status?: string;
  valueCents?: number;
  createdAt?: Date;
  closedAt?: Date;
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  wonLostReason?: string;
  leadSource?: string;
};

type LeadDoc = {
  id: string;
  source?: string;
  status?: string;
  createdAt?: Date;
  convertedToDealId?: string;
};

export const reportingAggregations = onRequest(async (req, res) => {
  if (applyCors(req, res, {methods: "POST,OPTIONS"})) return;

  if (req.method !== "POST") {
    res.status(405).json({error: "Method not allowed"});
    return;
  }

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Missing Authorization header"});
      return;
    }

    const tokenString = authHeader.split(" ")[1];
    const decoded = await auth.verifyIdToken(tokenString);

    const headerBusinessId = typeof req.headers["x-business-id"] === "string"
      ? (req.headers["x-business-id"] as string).trim()
      : undefined;

    const tokenBusinessId =
      typeof decoded.businessId === "string" ? decoded.businessId : undefined;

    const businessId = headerBusinessId || tokenBusinessId;

    if (!businessId) {
      res.status(400).json({error: "businessId is required"});
      return;
    }

    if (tokenBusinessId && tokenBusinessId !== businessId) {
      res.status(403).json({error: "Forbidden"});
      return;
    }

    const userDoc = await db.collection("users").doc(decoded.uid).get();
    if (!userDoc.exists) {
      res.status(403).json({error: "User profile not found"});
      return;
    }

    const profile = userDoc.data() || {};
    const profileBusinessId =
      typeof profile.businessId === "string" ? profile.businessId : undefined;
    if (profileBusinessId && profileBusinessId !== businessId) {
      res.status(403).json({error: "Forbidden"});
      return;
    }

    const role = normalizeUserRole(decoded.role) ?? normalizeUserRole(profile.role);

    if (!role || role === "client") {
      res.status(403).json({error: "Forbidden"});
      return;
    }

    const flagsSnap = await db
      .doc(`businesses/${businessId}/settings/feature_flags`)
      .get();
    const flags = flagsSnap.data() || {};
    if (flags.enableAdvancedReporting === false || !flags.enableAdvancedReporting) {
      res.status(403).json({error: "Advanced reporting disabled"});
      return;
    }

    const rawFilters = (req.body && req.body.filters) || {};
    const bucket: ReportingTimeBucket =
      rawFilters.bucket === "daily" ||
      rawFilters.bucket === "weekly" ||
      rawFilters.bucket === "monthly"
        ? rawFilters.bucket
        : "monthly";

    const filters: ReportingAggregationFilters = {
      startDate: parseDateString(rawFilters.startDate),
      endDate: parseDateString(rawFilters.endDate),
      pipelineIds: toStringArray(rawFilters.pipelineIds),
      ownerIds: toStringArray(rawFilters.ownerIds),
      teamIds: toStringArray(rawFilters.teamIds),
      stageIds: toStringArray(rawFilters.stageIds),
      sources: toStringArray(rawFilters.sources),
      bucket,
      includeStageBreakdown: Boolean(
        rawFilters.includeStageBreakdown ?? true
      ),
      preferCache: Boolean(rawFilters.preferCache),
    };

    logger.info("reportingAggregations access", {
      businessId,
      uid: decoded.uid,
      role,
      pipelineIds: filters.pipelineIds?.length,
      teamIds: filters.teamIds?.length,
      ownerIds: filters.ownerIds?.length,
      bucket,
    });

    const userTeams = Array.from(
      new Set([
        ...sanitizeTeams(profile.teamIds ?? decoded.teamIds),
        ...sanitizeTeams(profile.managedTeamIds ?? decoded.managedTeamIds),
      ])
    );
    const accessiblePipelines = await loadPipelines(
      businessId,
      filters,
      decoded.uid,
      role,
      userTeams
    );

    if (!accessiblePipelines.length) {
      res.status(200).json({
        generatedAt: new Date().toISOString(),
        filters,
        summary: {...emptyKpis},
        pipelines: [],
        timeBuckets: [],
        stageConversions: [],
        velocity: {...emptyVelocity},
        ownerPerformance: [],
        teamPerformance: [],
        lostReasons: [],
        cohorts: [],
      });
      return;
    }

    const allDeals: DealDoc[] = [];
    const pipelineAggregations: PipelineAggregation[] = [];
    const startDateObj = toDate(filters.startDate);
    const endDateObj = toDate(filters.endDate);

    for (const pipeline of accessiblePipelines) {
      const deals = await loadDealsForPipeline(businessId, pipeline.id, filters);
      const filteredDeals = filterDealsByAccessAndFilters(
        deals,
        filters,
        userTeams,
        role,
        decoded.uid
      );
      allDeals.push(...filteredDeals);
      const metrics = calcKpis(filteredDeals);
      const stageBreakdown = filters.includeStageBreakdown
        ? buildStageBreakdown(filteredDeals)
        : [];
      const stageConversions = filters.includeStageBreakdown
        ? buildStageConversions(filteredDeals)
        : [];
      const lostReasons = buildLostReasons(filteredDeals, pipeline.id);
      const velocity = calcVelocity(filteredDeals);

      pipelineAggregations.push({
        pipelineId: pipeline.id,
        ownerId: pipeline.ownerId || "unknown-owner",
        teamIds: sanitizeTeams(pipeline.teamIds),
        metrics,
        stageBreakdown,
        stageConversions,
        lostReasons,
        velocity,
      });
    }

    const summary = mergeKpis(pipelineAggregations.map((p) => p.metrics));
    const timeBuckets = buildTimeBuckets(allDeals, bucket, startDateObj, endDateObj);
    const stageConversions = buildStageConversions(allDeals);
    const lostReasons = buildLostReasons(allDeals);
    const velocity = calcVelocity(allDeals);
    const ownerPerformance = buildOwnerPerformance(allDeals);
    const teamPerformance = buildTeamPerformance(allDeals);

    const leads = await loadLeads(businessId, filters);
    const cohorts = buildSourceCohorts(leads, allDeals, bucket, startDateObj, endDateObj);

    const result: ReportingAggregationResult = {
      generatedAt: new Date().toISOString(),
      filters,
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

    res.status(200).json(result);
  } catch (error) {
    logger.error("reportingAggregations error", {error});
    res.status(500).json({error: "Internal server error"});
  }
});
