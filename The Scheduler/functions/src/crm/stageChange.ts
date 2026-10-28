import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "../firebaseAdmin";

interface DealDoc {
  stageId?: string;
  clientId?: string;
  companyId?: string;
  leadId?: string;
  assigneeId?: string;
  assigneeName?: string;
}

export const buildStageChangeActivityPayload = (
  before: DealDoc,
  after: DealDoc,
  dealId: string
): Record<string, unknown> => {
  const fromStage = before.stageId ?? null;
  const toStage = after.stageId ?? null;

  return {
    type: "note",
    title: "Deal stage changed",
    description: null,
    dealId,
    clientId: after.clientId ?? null,
    companyId: after.companyId ?? null,
    leadId: after.leadId ?? null,
    assigneeId: after.assigneeId ?? null,
    assigneeName: after.assigneeName ?? null,
    isCompleted: true,
    createdById: after.assigneeId ?? "system",
    createdByName: after.assigneeName ?? "system",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    metadata: {
      fromStage,
      toStage,
    },
  };
};

export const dealsStageChange = onDocumentUpdated(
  "businesses/{businessId}/deals/{dealId}",
  async (event) => {
    const beforeData = event.data?.before.data() as DealDoc | undefined;
    const afterData = event.data?.after.data() as DealDoc | undefined;

    if (!beforeData || !afterData) return;

    const fromStage = beforeData.stageId;
    const toStage = afterData.stageId;

    if (!toStage || fromStage === toStage) return;

    const businessId = event.params.businessId as string;
    const dealId = event.params.dealId as string;
    const activityId = `stage-${event.id}`;

    const activityRef = db
      .collection("businesses")
      .doc(businessId)
      .collection("sales_activities")
      .doc(activityId);

    await db.runTransaction(async (tx) => {
      const existing = await tx.get(activityRef);
      if (existing.exists) return;

      tx.set(
        activityRef,
        buildStageChangeActivityPayload(beforeData, afterData, dealId),
        {
          merge: true,
        }
      );
    });

    logger.info("Stage change activity created", {
      businessId,
      dealId,
      fromStage,
      toStage,
    });
  }
);
