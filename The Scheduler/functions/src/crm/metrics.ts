import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import type {Request, Response} from "express";
import {db} from "../firebaseAdmin";
import {applyCors} from "../httpUtils";
import {CRM_ALLOWED_ROLES} from "../roleUtils";
import {requireAuthContext, verifyAppCheck} from "./auth";
import {
  HttpError,
  clampLimit,
  isStaffLikeRole,
  parseOptionalNumber,
  requireBusinessId,
  startOfMonthTimestamp,
} from "./utils";

interface MetricsRequest {
  businessId: string;
  rangeDays: number;
  activityLimit: number;
}

interface ActivitySummary {
  id: string;
  type?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  assigneeId?: string;
  createdById?: string;
  createdAt: string | null;
  isCompleted?: boolean;
}

export const parseMetricsRequest = (body: unknown): MetricsRequest => {
  if (!body || typeof body !== "object") {
    throw new HttpError(400, "Request body must be an object");
  }
  const payload = body as Record<string, unknown>;
  const businessId = requireBusinessId(payload.businessId);
  const rangeDays = clampLimit(
    parseOptionalNumber(payload.rangeDays, "rangeDays", {
      min: 1,
      max: 365,
    }) ?? 30,
    1,
    365
  );
  const activityLimit = clampLimit(
    parseOptionalNumber(payload.activityLimit, "activityLimit", {
      min: 1,
      max: 50,
      integer: true,
    }) ?? 10,
    1,
    50
  );

  return {businessId, rangeDays, activityLimit};
};

const toIso = (value: unknown): string | null => {
  if (!value || typeof value !== "object") return null;
  if ("toDate" in (value as Record<string, unknown>)) {
    const date = (value as FirebaseFirestore.Timestamp).toDate();
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
  }
  return null;
};

const fetchMetrics = async (
  request: MetricsRequest
): Promise<Record<string, unknown>> => {
  const businessRef = db.collection("businesses").doc(request.businessId);
  const dealsRef = businessRef.collection("deals");
  const leadsRef = businessRef.collection("leads");
  const activitiesRef = businessRef.collection("sales_activities");

  const now = new Date();
  const rangeStart = new Date(now.getTime() - request.rangeDays * 24 * 60 * 60 * 1000);
  const startTimestamp = startOfMonthTimestamp(now);

  const [
    openDealsSnap,
    wonDealsAgg,
    newLeadsAgg,
    convertedLeadsAgg,
    recentActivitiesSnap,
  ] = await Promise.all([
    dealsRef.where("status", "==", "open").limit(500).get(),
    dealsRef
      .where("status", "==", "won")
      .where("closedAt", ">=", startTimestamp)
      .count()
      .get(),
    leadsRef.where("createdAt", ">=", startTimestamp).count().get(),
    leadsRef
      .where("status", "==", "converted")
      .where("convertedAt", ">=", startTimestamp)
      .count()
      .get(),
    activitiesRef.orderBy("createdAt", "desc").limit(request.activityLimit).get(),
  ]);

  let totalPipelineValueCents = 0;
  openDealsSnap.docs.forEach((doc) => {
    const value = doc.get("valueCents");
    if (typeof value === "number") totalPipelineValueCents += value;
  });

  const openDealsSampled = openDealsSnap.size >= 500;
  const wonDealsThisMonth = wonDealsAgg.data().count ?? 0;
  const newLeadsThisMonth = newLeadsAgg.data().count ?? 0;
  const convertedThisMonth = convertedLeadsAgg.data().count ?? 0;
  const conversionRate =
    newLeadsThisMonth > 0 ?
      Number(((convertedThisMonth / newLeadsThisMonth) * 100).toFixed(2)) :
      0;

  const recentActivities: ActivitySummary[] = recentActivitiesSnap.docs.map((doc) => {
    const data = doc.data() ?? {};
    return {
      id: doc.id,
      type: typeof data.type === "string" ? data.type : undefined,
      dealId: typeof data.dealId === "string" ? data.dealId : undefined,
      clientId: typeof data.clientId === "string" ? data.clientId : undefined,
      leadId: typeof data.leadId === "string" ? data.leadId : undefined,
      companyId: typeof data.companyId === "string" ? data.companyId : undefined,
      assigneeId: typeof data.assigneeId === "string" ? data.assigneeId : undefined,
      createdById:
        typeof data.createdById === "string" ? data.createdById : undefined,
      createdAt: toIso(data.createdAt),
      isCompleted: typeof data.isCompleted === "boolean" ? data.isCompleted : undefined,
    };
  });

  return {
    totalPipelineValueCents,
    wonDealsThisMonth,
    newLeadsThisMonth,
    convertedThisMonth,
    conversionRate,
    openDealsSampled,
    rangeStart: rangeStart.toISOString(),
    startOfMonth: startTimestamp.toDate().toISOString(),
    recentActivities,
  };
};

export const createCrmMetricsHandler =
  () =>
    async (req: Request, res: Response): Promise<void> => {
      if (applyCors(req, res)) return;
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      try {
        await verifyAppCheck(req);
        const payload = parseMetricsRequest(req.body);
        const authContext = await requireAuthContext(
          req,
          payload.businessId,
          CRM_ALLOWED_ROLES
        );

        if (!isStaffLikeRole(authContext.role)) {
          throw new HttpError(403, "Insufficient permissions");
        }

        const metrics = await fetchMetrics(payload);
        res.status(200).json(metrics);
      } catch (error) {
        if (error instanceof HttpError) {
          res.status(error.status).json({error: error.message});
          return;
        }
        const message =
          error instanceof Error ? error.message : "Internal server error";
        logger.error("crm-metrics failed", {error: message});
        res.status(500).json({error: "Internal server error"});
      }
    };

export const crmMetrics = onRequest(createCrmMetricsHandler());
