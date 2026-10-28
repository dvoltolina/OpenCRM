import * as logger from "firebase-functions/logger";
import {db, FieldValue} from "../firebaseAdmin";
import {sanitizeMetadataMap} from "../httpUtils";

type AuditActionType =
  | "loginSuccess"
  | "loginFailure"
  | "phiRead"
  | "phiReadList"
  | "phiWrite"
  | "dataExport"
  | "securityEvent";

interface AuditParams {
  businessId: string;
  userId: string;
  actionType: AuditActionType;
  entityType: string;
  entityId: string;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
}

export const writeAuditLogSafe = async (params: AuditParams): Promise<void> => {
  try {
    const metadata = sanitizeMetadataMap(params.metadata ?? {}, 200);
    const data: Record<string, unknown> = {
      businessId: params.businessId,
      userId: params.userId,
      actionType: params.actionType,
      entityType: params.entityType,
      entityId: params.entityId,
      metadata,
      timestamp: FieldValue.serverTimestamp(),
    };
    if (params.ipAddress) {
      data.ipAddress = params.ipAddress;
    }

    await db
      .collection("businesses")
      .doc(params.businessId)
      .collection("audit_logs")
      .add(data);
  } catch (error) {
    logger.error("Failed to write audit log", {
      error: error instanceof Error ? error.message : error,
    });
  }
};
