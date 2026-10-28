import { doc, updateDoc, serverTimestamp } from 'firebase/firestore';

import { assertDemoMutationAllowed } from '../config/demo';
import { getDb } from '../lib/firebase';
import { logAuditEvent } from './auditLog';
import { callTenantFunction } from './firestoreBase';

export interface HipaaToggleInput {
  businessId: string;
  enabled: boolean;
  userId: string;
}

/**
 * Toggles HIPAA compliance mode for a business.
 *
 * SECURITY:
 * - Only callable by owners (enforced at hook/component level)
 * - businessId must be from authenticated user context
 * - All changes are audit logged
 * - NO PHI in any logs
 *
 * When HIPAA is enabled:
 * - Audit logging enabled for all PHI access
 * - MFA required for all owner/admin accounts
 * - Session timeout set to 15 minutes
 * - Analytics that may contain PHI are disabled
 *
 * @param input - HIPAA toggle configuration
 * @throws Error if businessId is missing or update fails
 */
export async function toggleHipaaMode(input: HipaaToggleInput): Promise<void> {
  assertDemoMutationAllowed('toggle HIPAA mode');
  const { businessId, enabled, userId } = input;

  if (!businessId) {
    throw new Error('businessId is required to toggle HIPAA mode');
  }

  if (!userId) {
    throw new Error('userId is required to toggle HIPAA mode');
  }

  const db = getDb();
  const businessRef = doc(db, 'businesses', businessId);

  // Update business document with HIPAA settings
  await updateDoc(businessRef, {
    requiresHipaaCompliance: enabled,
    hipaaEnabled: enabled,
    mfaEnabled: enabled, // MFA required when HIPAA is enabled
    'settings.sessionTimeoutMinutes': enabled ? 15 : 60,
    'settings.requireMfaForStaff': enabled,
    updatedAt: serverTimestamp(),
  });

  // Log audit event - NO PHI, only IDs and action type
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'securityEvent',
    entityType: 'business_settings',
    entityId: businessId,
    metadata: {
      action: enabled ? 'hipaa_enabled' : 'hipaa_disabled',
      previousState: !enabled,
      newState: enabled,
    },
  });
}

/**
 * Requests a data export for GDPR/CCPA compliance.
 * This is a placeholder that will trigger a Cloud Function to generate the export.
 *
 * SECURITY:
 * - Only callable by owners (enforced at hook/component level)
 * - businessId must be from authenticated user context
 * - Request is audit logged
 *
 * @param businessId - The business ID requesting the export
 * @param userId - The user ID requesting the export
 * @throws Error if businessId or userId is missing
 */
export async function requestDataExport(businessId: string, userId: string): Promise<void> {
  assertDemoMutationAllowed('request data export');
  if (!businessId) {
    throw new Error('businessId is required to request data export');
  }

  if (!userId) {
    throw new Error('userId is required to request data export');
  }

  await callTenantFunction('requestDataExport', businessId, {
    format: 'csv',
    scope: 'full',
  });
}

/**
 * Initiates business deletion process.
 * This is a placeholder that will trigger a Cloud Function to handle deletion.
 *
 * SECURITY:
 * - Only callable by owners (enforced at hook/component level)
 * - Requires password re-authentication
 * - Requires exact text confirmation
 * - Irreversible action
 *
 * @param businessId - The business ID to delete
 * @param userId - The user ID initiating deletion
 * @throws Error if businessId or userId is missing
 */
export async function initiatBusinessDeletion(businessId: string, userId: string): Promise<void> {
  assertDemoMutationAllowed('delete workspace');
  if (!businessId) {
    throw new Error('businessId is required to delete business');
  }

  if (!userId) {
    throw new Error('userId is required to delete business');
  }

  await callTenantFunction('initiateBusinessDeletion', businessId, {
    reason: 'owner_requested_from_admin',
  });
}
