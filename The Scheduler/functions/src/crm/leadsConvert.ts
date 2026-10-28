import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import type {Request, Response} from "express";
import {db, FieldValue} from "../firebaseAdmin";
import {applyCors} from "../httpUtils";
import {CRM_ALLOWED_ROLES} from "../roleUtils";
import {writeAuditLogSafe} from "./audit";
import {requireAuthContext, type AuthContext, verifyAppCheck} from "./auth";
import {
  HttpError,
  clampLimit,
  isAdminRole,
  isStaffLikeRole,
  normalizeCurrency,
  optionalDateTimestamp,
  optionalString,
  parseOptionalNumber,
  requireBusinessId,
  requireId,
  requireString,
} from "./utils";

interface LeadDoc {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  companyName?: string;
  title?: string;
  status?: string;
  source?: string;
  score?: number;
  assigneeId?: string;
  assigneeName?: string;
  tags?: string[];
  notes?: string;
  convertedToClientId?: string;
  convertedToDealId?: string;
  convertedAt?: FirebaseFirestore.Timestamp;
  createdById?: string;
  createdAt?: FirebaseFirestore.Timestamp;
}

interface StageDoc {
  pipelineId?: string;
  name?: string;
  probability?: number;
}

interface DealInput {
  pipelineId: string;
  stageId: string;
  title?: string;
  valueCents?: number;
  currency?: string;
  expectedCloseDate?: FirebaseFirestore.Timestamp;
  assigneeId?: string;
  probability?: number;
}

export interface LeadConversionRequest {
  businessId: string;
  leadId: string;
  createDeal: boolean;
  deal?: DealInput;
}

export interface LeadConversionResult {
  clientId: string;
  dealId: string | null;
  alreadyConverted: boolean;
}

export const parseLeadConversionRequest = (
  body: unknown
): LeadConversionRequest => {
  if (!body || typeof body !== "object") {
    throw new HttpError(400, "Request body must be an object");
  }

  const payload = body as Record<string, unknown>;
  const businessId = requireBusinessId(payload.businessId);
  const leadId = requireId(payload.leadId, "leadId");
  const createDeal = Boolean(payload.createDeal ?? payload.deal);
  const dealPayload = payload.deal as Record<string, unknown> | undefined;

  let deal: DealInput | undefined;
  if (createDeal) {
    const pipelineId = requireId(
      payload.pipelineId ?? dealPayload?.pipelineId,
      "pipelineId"
    );
    const stageId = requireId(
      payload.stageId ?? dealPayload?.stageId,
      "stageId"
    );
    const valueCents = parseOptionalNumber(
      payload.valueCents ?? dealPayload?.valueCents,
      "valueCents",
      {min: 0, max: 50_000_000, integer: true}
    );
    const probability = parseOptionalNumber(
      payload.probability ?? dealPayload?.probability,
      "probability",
      {min: 0, max: 100}
    );
    const currency = normalizeCurrency(payload.currency ?? dealPayload?.currency);
    const title = optionalString(payload.title ?? dealPayload?.title);
    const expectedCloseDate = optionalDateTimestamp(
      payload.expectedCloseDate ?? dealPayload?.expectedCloseDate,
      "expectedCloseDate"
    );
    const assigneeId = optionalString(
      payload.assigneeId ?? dealPayload?.assigneeId
    );

    deal = {
      pipelineId,
      stageId,
      valueCents,
      currency,
      title,
      expectedCloseDate,
      assigneeId: assigneeId ?? undefined,
      probability,
    };
  }

  return {
    businessId,
    leadId,
    createDeal,
    deal,
  };
};

const getClientIp = (req: Request): string => {
  const forwarded = (req.headers["x-forwarded-for"] as string | undefined)
    ?.split(",")[0]
    ?.trim();
  return forwarded || req.ip || "unknown";
};

const buildClientPayload = (
  lead: LeadDoc
): Record<string, unknown> => {
  const email = requireString(lead.email, "lead.email");
  const firstName = requireString(lead.firstName, "lead.firstName");
  const lastName = requireString(lead.lastName, "lead.lastName");
  const tags =
    Array.isArray(lead.tags) ?
      lead.tags
        .filter((tag) => typeof tag === "string")
        .map((tag) => tag.trim())
        .filter(Boolean)
        .slice(0, 25) :
      [];

  const payload: Record<string, unknown> = {
    firstName,
    lastName,
    email,
    phone: optionalString(lead.phone) ?? null,
    companyName: optionalString(lead.companyName) ?? null,
    title: optionalString(lead.title) ?? null,
    leadSource: optionalString(lead.source) ?? null,
    crmNotes: optionalString(lead.notes) ?? null,
    tags,
    lifecycle: "active",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  return payload;
};

const ensureStaffCanModifyLead = (
  authContext: AuthContext,
  lead: LeadDoc
): void => {
  if (isAdminRole(authContext.role)) return;
  const assignee = lead.assigneeId ?? lead.createdById;
  if (assignee && assignee !== authContext.uid) {
    throw new HttpError(403, "Only assignee can convert this lead");
  }
};

const createDealPayload = (
  lead: LeadDoc,
  clientId: string,
  dealInput: DealInput,
  stage: StageDoc
): Record<string, unknown> => {
  const baseTitle =
    dealInput.title ??
    `${requireString(lead.firstName ?? "", "lead.firstName")} ${optionalString(
      lead.lastName ?? ""
    ) ?? ""}`.trim();

  const valueCents = dealInput.valueCents ?? 0;
  const probFromStage =
    typeof stage.probability === "number" && stage.probability >= 0 ?
      stage.probability :
      undefined;
  const probability = clampLimit(
    dealInput.probability ?? probFromStage ?? 0,
    0,
    100
  );

  const payload: Record<string, unknown> = {
    pipelineId: dealInput.pipelineId,
    stageId: dealInput.stageId,
    title: baseTitle,
    valueCents,
    currency: normalizeCurrency(dealInput.currency),
    probability,
    status: "open",
    expectedCloseDate: dealInput.expectedCloseDate ?? null,
    clientId,
    clientName: `${lead.firstName ?? ""} ${lead.lastName ?? ""}`.trim(),
    companyName: optionalString(lead.companyName) ?? null,
    assigneeId: optionalString(dealInput.assigneeId) ?? lead.assigneeId ?? null,
    assigneeName: optionalString(lead.assigneeName) ?? null,
    tags:
      Array.isArray(lead.tags) ?
        lead.tags
          .filter((tag) => typeof tag === "string")
          .map((tag) => tag.trim())
          .filter(Boolean)
          .slice(0, 25) :
        [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  return payload;
};

const convertLead = async (
  authContext: AuthContext,
  payload: LeadConversionRequest,
  requestIp?: string
): Promise<LeadConversionResult> => {
  const businessRef = db.collection("businesses").doc(payload.businessId);
  const leadRef = businessRef.collection("leads").doc(payload.leadId);
  const clientId = businessRef.collection("clients").doc().id;

  const result = await db.runTransaction(async (tx) => {
    const leadSnap = await tx.get(leadRef);
    if (!leadSnap.exists) {
      throw new HttpError(404, "Lead not found");
    }

    const lead = leadSnap.data() as LeadDoc;
    ensureStaffCanModifyLead(authContext, lead);

    if (lead.status === "converted" || lead.convertedToClientId) {
      return {
        clientId: lead.convertedToClientId ?? "",
        dealId: lead.convertedToDealId ?? null,
        alreadyConverted: true,
      };
    }

    const clientRef = businessRef.collection("clients").doc(clientId);
    tx.set(clientRef, buildClientPayload(lead), {merge: true});

    let dealId: string | null = null;
    if (payload.createDeal && payload.deal) {
      const pipelineRef = businessRef
        .collection("pipelines")
        .doc(payload.deal.pipelineId);
      const stageRef = businessRef.collection("stages").doc(payload.deal.stageId);

      const [pipelineSnap, stageSnap] = await Promise.all([
        tx.get(pipelineRef),
        tx.get(stageRef),
      ]);

      if (!pipelineSnap.exists) {
        throw new HttpError(400, "Pipeline not found");
      }
      if (!stageSnap.exists) {
        throw new HttpError(400, "Stage not found");
      }

      const stage = stageSnap.data() as StageDoc;
      if (
        stage.pipelineId &&
        stage.pipelineId !== payload.deal.pipelineId
      ) {
        throw new HttpError(400, "Stage does not belong to pipeline");
      }

      const dealRef = businessRef.collection("deals").doc();
      tx.set(
        dealRef,
        createDealPayload(lead, clientId, payload.deal, stage),
        {merge: true}
      );
      dealId = dealRef.id;
    }

    tx.set(
      leadRef,
      {
        status: "converted",
        convertedToClientId: clientId,
        convertedToDealId: dealId,
        convertedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    return {clientId, dealId, alreadyConverted: false};
  });

  await writeAuditLogSafe({
    businessId: payload.businessId,
    userId: authContext.uid,
    actionType: "phiWrite",
    entityType: "lead",
    entityId: payload.leadId,
    metadata: {
      converted: true,
      clientId: result.clientId,
      createdDeal: Boolean(result.dealId),
    },
    ipAddress: requestIp,
  });

  return result;
};

export const createLeadsConvertHandler =
  () =>
    async (req: Request, res: Response): Promise<void> => {
      if (applyCors(req, res)) return;
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      try {
        await verifyAppCheck(req);
        const payload = parseLeadConversionRequest(req.body);
        const authContext = await requireAuthContext(
          req,
          payload.businessId,
          CRM_ALLOWED_ROLES
        );

        if (!isStaffLikeRole(authContext.role)) {
          throw new HttpError(403, "Insufficient permissions");
        }

        const result = await convertLead(
          authContext,
          payload,
          getClientIp(req)
        );

        res.status(200).json({
          clientId: result.clientId,
          dealId: result.dealId,
          status: "converted",
          alreadyConverted: result.alreadyConverted,
        });
      } catch (error) {
        if (error instanceof HttpError) {
          res.status(error.status).json({error: error.message});
          return;
        }
        const message =
          error instanceof Error ? error.message : "Internal server error";
        logger.error("leads-convert failed", {error: message});
        res.status(500).json({error: "Internal server error"});
      }
    };

export const leadsConvert = onRequest(
  createLeadsConvertHandler()
);
