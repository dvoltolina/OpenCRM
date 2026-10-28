/**
 * Integration Settings Cloud Functions
 * 
 * Handles:
 * - Updating telehealth settings
 * - Saving staff integration preferences
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "./firebaseAdmin";
import {isAdminRole, normalizeUserRole} from "./roleUtils";

// Helper to verify auth and business access
const requireBusinessAccess = async (request: CallableRequest, businessId?: string) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  
  const uid = request.auth.uid;
  const requestedBusinessId = businessId || request.data.businessId;

  if (!requestedBusinessId) {
    throw new HttpsError("invalid-argument", "Business ID is required");
  }

  // Check custom claim
  if (request.auth.token.businessId === requestedBusinessId) {
    return { uid, businessId: requestedBusinessId };
  }

  // Fallback to user doc check
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data();

  if (!userData || userData.businessId !== requestedBusinessId) {
    throw new HttpsError("permission-denied", "Access denied to this business");
  }

  return {
    uid,
    businessId: requestedBusinessId,
    role: normalizeUserRole(request.auth.token.role) ?? normalizeUserRole(userData.role),
  };
};

export const updateTelehealthSettings = onCall(async (request: CallableRequest) => {
  const { updates, businessId } = request.data;
  
  const { role } = await requireBusinessAccess(request, businessId);
  
  if (!isAdminRole(role)) {
    throw new HttpsError("permission-denied", "Only admins can update telehealth settings");
  }

  try {
    await db.doc(`businesses/${businessId}/settings/telehealth`).set(updates, { merge: true });
    return { success: true };
  } catch (error) {
    logger.error("Failed to update telehealth settings", error);
    throw new HttpsError("internal", "Failed to update settings");
  }
});

export const saveStaffIntegrationPreference = onCall(async (request: CallableRequest) => {
  const { preference, businessId } = request.data;
  const { uid, role } = await requireBusinessAccess(request, businessId);

  // Staff can update their own prefs, admins can update anyone's
  if (preference.staffId !== uid && !isAdminRole(role)) {
    throw new HttpsError("permission-denied", "Cannot update other staff preferences");
  }

  try {
    await db.doc(`businesses/${businessId}/staff_integrations/${preference.staffId}`).set(preference, { merge: true });
    return { success: true };
  } catch (error) {
    logger.error("Failed to save staff preference", error);
    throw new HttpsError("internal", "Failed to save preference");
  }
});
