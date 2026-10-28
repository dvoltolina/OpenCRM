import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {db, FieldValue, Timestamp} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

export const processSequenceSteps = onSchedule("every 5 minutes", async () => {
  const now = Timestamp.now();
  const snapshot = await db.collectionGroup("sequence_enrollments")
    .where("status", "==", "active")
    .where("nextStepScheduledAt", "<=", now)
    .limit(50)
    .get();

  for (const doc of snapshot.docs) {
    const businessId = doc.ref.parent.parent?.id;
    if (!businessId) continue;
    const data = doc.data();
    const executionRef = db.collection("businesses").doc(businessId)
      .collection("sequence_executions").doc();
    await executionRef.set({
      businessId,
      enrollmentId: doc.id,
      sequenceId: data.sequenceId ?? null,
      stepIndex: data.currentStepIndex ?? 0,
      stepType: data.steps?.[data.currentStepIndex ?? 0]?.type ?? "unknown",
      status: "completed",
      scheduledAt: data.nextStepScheduledAt ?? now,
      executedAt: FieldValue.serverTimestamp(),
      result: {success: true},
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await doc.ref.set({
      currentStepIndex: (data.currentStepIndex ?? 0) + 1,
      stepsCompleted: FieldValue.increment(1),
      status: (data.currentStepIndex ?? 0) + 1 >= (data.totalSteps ?? 1) ? "completed" : data.status,
      nextStepScheduledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
});

export const handleEmailWebhook = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const events = Array.isArray(req.body) ? req.body : [req.body];
    for (const event of events) {
      const trackingId = event?.trackingId ?? event?.sg_message_id;
      const status = event?.event ?? event?.status ?? "unknown";
      const businessId = event?.businessId ?? event?.category?.find((c: string) => c?.startsWith?.("business:"))?.split(":")?.[1];
      if (!businessId || !trackingId) continue;
      await db.collection("businesses").doc(String(businessId))
        .collection("sequence_executions")
        .where("trackingId", "==", String(trackingId))
        .limit(1)
        .get()
        .then(async (snap) => {
          if (!snap.empty) {
            await snap.docs[0].ref.set({
              status,
              updatedAt: FieldValue.serverTimestamp(),
            }, {merge: true});
          }
        });
    }
    res.json({success: true});
  } catch (error) {
    logger.error("handleEmailWebhook error", {error: getErrorMessage(error)});
    res.status(500).json({error: "Failed"});
  }
});

export const onAppointmentCreated = onDocumentCreated("businesses/{businessId}/appointments/{appointmentId}", async (event) => {
  const {businessId} = event.params;
  const data = event.data?.data();
  if (!data?.clientId) return;
  const enrollments = await db.collection("businesses").doc(businessId)
    .collection("sequence_enrollments")
    .where("entityId", "==", data.clientId)
    .where("status", "==", "active")
    .limit(20)
    .get();
  for (const doc of enrollments.docs) {
    await doc.ref.set({
      status: "exited",
      exitReason: "meetingBooked",
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
});

export const onDealUpdated = onDocumentUpdated("businesses/{businessId}/deals/{dealId}", async (event) => {
  const {businessId} = event.params;
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === after.status) return;
  const enrollments = await db.collection("businesses").doc(businessId)
    .collection("sequence_enrollments")
    .where("entityId", "==", event.params.dealId)
    .where("status", "==", "active")
    .limit(20)
    .get();
  for (const doc of enrollments.docs) {
    await doc.ref.set({
      status: "exited",
      exitReason: `deal:${after.status}`,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
});

export const onLeadConverted = onDocumentUpdated("businesses/{businessId}/leads/{leadId}", async (event) => {
  const {businessId, leadId} = event.params;
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.convertedAt || !after.convertedAt) return;
  const enrollments = await db.collection("businesses").doc(businessId)
    .collection("sequence_enrollments")
    .where("entityId", "==", leadId)
    .where("status", "==", "active")
    .limit(20)
    .get();
  for (const doc of enrollments.docs) {
    await doc.ref.set({
      status: "exited",
      exitReason: "leadConverted",
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
});
