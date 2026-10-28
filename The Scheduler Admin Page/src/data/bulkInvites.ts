import { assertDemoMutationAllowed } from '../config/demo';
import { callTenantFunction } from './firestoreBase';
import type { UserRole } from '../types/auth';
import { logAuditEvent } from './auditLog';

export interface BulkInviteInput {
  invites: Array<{
    email: string;
    role: UserRole;
    name?: string;
  }>;
}

export interface BulkInviteResult {
  success: boolean;
  sent: number;
  failed: number;
  errors?: Array<{ email: string; error: string }>;
}

/**
 * Sends bulk invites via Cloud Function.
 * HIPAA Note: Audit log records count only - never email addresses or names.
 */
export async function sendBulkInvites(
  businessId: string,
  userId: string,
  input: BulkInviteInput,
): Promise<BulkInviteResult> {
  assertDemoMutationAllowed('send bulk invites');
  if (!businessId) {
    throw new Error('businessId is required');
  }

  if (!input.invites || input.invites.length === 0) {
    throw new Error('No invites provided');
  }

  try {
    // Call Cloud Function for bulk invite processing
    // The CF will:
    // - Generate invite codes for each
    // - Store invite records in businesses/{businessId}/invites/{inviteId}
    // - Send invite emails
    // - Return results
    const result = await callTenantFunction<Record<string, unknown>, BulkInviteResult>(
      'staffBulkInvite',
      businessId,
      input as Record<string, unknown>,
      {
        // Fallback for development/stub mode
        fallbackValue: {
          success: true,
          sent: input.invites.length,
          failed: 0,
        },
      },
    );

    // Log audit event (HIPAA compliant - count only, no PII)
    await logAuditEvent({
      businessId,
      userId,
      actionType: 'bulk_invite_sent',
      entityType: 'StaffInvite',
      entityId: businessId,
      metadata: {
        source: 'sendBulkInvites',
        totalAttempted: input.invites.length,
        successCount: result.sent,
        failedCount: result.failed,
      },
    });

    return result;
  } catch (error) {
    console.error('[bulkInvites] Failed to send bulk invites');

    // Log failure audit event (HIPAA compliant - no PII)
    await logAuditEvent({
      businessId,
      userId,
      actionType: 'bulk_invite_sent',
      entityType: 'StaffInvite',
      entityId: businessId,
      metadata: {
        source: 'sendBulkInvites',
        totalAttempted: input.invites.length,
        successCount: 0,
        failedCount: input.invites.length,
        error: 'Cloud function call failed',
      },
    });

    // Return error result
    return {
      success: false,
      sent: 0,
      failed: input.invites.length,
      errors: [{ email: '(all)', error: 'Failed to process bulk invites' }],
    };
  }
}
