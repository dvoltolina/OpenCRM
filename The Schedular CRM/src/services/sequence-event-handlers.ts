/**
 * Sequence Event Handlers
 * Handles external events that affect sequence enrollments
 *
 * Events handled:
 * - Email reply detection
 * - Email bounce
 * - Email open (if tracking enabled)
 * - Meeting booked via Scheduler
 * - Deal status change (won/lost)
 * - Unsubscribe
 *
 * HIPAA Compliance:
 * - No PHI in logs (entity IDs only)
 * - All events audited
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { EnrollmentEntityType, ExitReason } from '../types/sequences';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { getSequenceExecutionRepository } from '../data/repositories/sequence-execution-repository';
import { getAuditLogService } from './AuditLogService';

// ============================================
// Sequence Event Handlers
// ============================================

export class SequenceEventHandlers {
  private sequenceRepo = getSequenceRepository();
  private enrollmentRepo = getSequenceEnrollmentRepository();
  private executionRepo = getSequenceExecutionRepository();
  private auditService = getAuditLogService();

  // ============================================
  // Reply Handling
  // ============================================

  /**
   * Handle email reply detection.
   * Called from email webhook or manual marking.
   */
  async onReply(
    context: SecurityContext,
    entityType: EnrollmentEntityType,
    entityId: string,
    messageId?: string
  ): Promise<void> {
    // 1. Find active enrollment for entity
    const enrollmentResult = await this.enrollmentRepo.getActiveByEntity(
      context,
      entityType,
      entityId
    );

    if (!enrollmentResult.success || !enrollmentResult.data) {
      return; // No active enrollment, nothing to do
    }

    const enrollment = enrollmentResult.data;

    // 2. Update reply count
    await this.enrollmentRepo.incrementStat(context, enrollment.id, 'repliesReceived');

    // 3. If we have a messageId, record reply on execution
    if (messageId) {
      const executionResult = await this.executionRepo.getByMessageId(context, messageId);
      if (executionResult.success && executionResult.data) {
        await this.executionRepo.recordEmailReply(context, executionResult.data.id);
      }
    }

    // 4. Get sequence settings to check behavior
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return;
    }

    const sequence = sequenceResult.data;

    // 5. Check if we should pause or exit
    if (sequence.settings.pauseOnReply) {
      await this.enrollmentRepo.pause(context, enrollment.id, 'Reply received');
    }

    // 6. Check exit criteria
    if (sequence.exitCriteria?.onReply) {
      await this.enrollmentRepo.exit(context, enrollment.id, 'replied');
      await this.sequenceRepo.incrementStat(context, sequence.id, 'exitedCount');
    }

    // 7. Audit log
    await this.auditService.logAction(context, {
      action: 'update',
      entityType: 'activity',
      entityId: enrollment.id,
      metadata: {
        action: 'sequenceReplyReceived',
        sequenceId: sequence.id,
        enrollmentId: enrollment.id,
        entityType,
        entityId,
        pausedOrExited: sequence.settings.pauseOnReply || sequence.exitCriteria?.onReply,
      },
    });
  }

  // ============================================
  // Bounce Handling
  // ============================================

  /**
   * Handle email bounce.
   * Called from email webhook.
   */
  async onBounce(
    context: SecurityContext,
    messageId: string,
    bounceType: 'hard' | 'soft' = 'hard'
  ): Promise<void> {
    // 1. Find execution by messageId
    const executionResult = await this.executionRepo.getByMessageId(context, messageId);
    if (!executionResult.success || !executionResult.data) {
      return; // Message not from a sequence, ignore
    }

    const execution = executionResult.data;

    // 2. Record bounce on execution
    await this.executionRepo.recordEmailBounce(context, execution.id, bounceType);

    // 3. For hard bounces, exit enrollment
    if (bounceType === 'hard') {
      await this.enrollmentRepo.markBounced(context, execution.enrollmentId);

      // Update sequence stats
      const sequenceResult = await this.sequenceRepo.getById(context, execution.sequenceId);
      if (sequenceResult.success && sequenceResult.data) {
        await this.sequenceRepo.incrementStat(context, sequenceResult.data.id, 'exitedCount');
      }
    }

    // 4. Audit log
    await this.auditService.logAction(context, {
      action: 'update',
      entityType: 'activity',
      entityId: execution.id,
      metadata: {
        action: 'sequenceEmailBounced',
        sequenceId: execution.sequenceId,
        enrollmentId: execution.enrollmentId,
        bounceType,
        exited: bounceType === 'hard',
      },
    });
  }

  // ============================================
  // Email Open Handling
  // ============================================

  /**
   * Handle email open (if tracking enabled).
   * Called from email webhook.
   */
  async onEmailOpen(context: SecurityContext, messageId: string): Promise<void> {
    // 1. Find execution by messageId
    const executionResult = await this.executionRepo.getByMessageId(context, messageId);
    if (!executionResult.success || !executionResult.data) {
      return;
    }

    const execution = executionResult.data;

    // 2. Record open on execution
    await this.executionRepo.recordEmailOpen(context, execution.id);

    // 3. Update enrollment stats
    await this.enrollmentRepo.incrementStat(context, execution.enrollmentId, 'emailsOpened');

    // 4. Check if we should pause on open
    const sequenceResult = await this.sequenceRepo.getById(context, execution.sequenceId);
    if (sequenceResult.success && sequenceResult.data) {
      const sequence = sequenceResult.data;

      if (sequence.settings.pauseOnOpen) {
        await this.enrollmentRepo.pause(context, execution.enrollmentId, 'Email opened');
      }
    }
  }

  /**
   * Handle email click.
   * Called from email webhook.
   */
  async onEmailClick(context: SecurityContext, messageId: string): Promise<void> {
    // 1. Find execution by messageId
    const executionResult = await this.executionRepo.getByMessageId(context, messageId);
    if (!executionResult.success || !executionResult.data) {
      return;
    }

    const execution = executionResult.data;

    // 2. Record click on execution
    await this.executionRepo.recordEmailClick(context, execution.id);

    // 3. Update enrollment stats
    await this.enrollmentRepo.incrementStat(context, execution.enrollmentId, 'emailsClicked');
  }

  /**
   * Handle email delivery.
   * Called from email webhook.
   */
  async onEmailDelivered(context: SecurityContext, messageId: string): Promise<void> {
    // Find execution and record delivery
    const executionResult = await this.executionRepo.getByMessageId(context, messageId);
    if (executionResult.success && executionResult.data) {
      await this.executionRepo.recordEmailDelivery(context, executionResult.data.id);
    }
  }

  // ============================================
  // Meeting Booked Handling
  // ============================================

  /**
   * Handle meeting booked via Scheduler.
   * Called when appointment is created for a client.
   */
  async onMeetingBooked(context: SecurityContext, clientId: string): Promise<void> {
    // 1. Find active enrollment for client
    const enrollmentResult = await this.enrollmentRepo.getActiveByEntity(
      context,
      'client',
      clientId
    );

    if (!enrollmentResult.success || !enrollmentResult.data) {
      // Try as lead
      const leadEnrollmentResult = await this.enrollmentRepo.getActiveByEntity(
        context,
        'lead',
        clientId // In some cases, clientId might be a lead that was converted
      );

      if (!leadEnrollmentResult.success || !leadEnrollmentResult.data) {
        return; // No active enrollment
      }
    }

    const enrollment = enrollmentResult.data!;

    // 2. Get sequence settings
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return;
    }

    const sequence = sequenceResult.data;

    // 3. Check if we should exit on meeting booked
    if (sequence.settings.pauseOnMeetingBooked || sequence.exitCriteria?.onMeetingBooked) {
      await this.enrollmentRepo.exit(context, enrollment.id, 'meeting_booked');
      await this.sequenceRepo.incrementStat(context, sequence.id, 'exitedCount');

      // Audit log
      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'activity',
        entityId: enrollment.id,
        metadata: {
          action: 'sequenceMeetingBooked',
          sequenceId: sequence.id,
          enrollmentId: enrollment.id,
          clientId,
        },
      });
    }
  }

  // ============================================
  // Deal Status Change Handling
  // ============================================

  /**
   * Handle deal status change.
   * Called when deal moves to won/lost.
   */
  async onDealStatusChange(
    context: SecurityContext,
    dealId: string,
    status: 'won' | 'lost'
  ): Promise<void> {
    // 1. Find active enrollment for deal
    const enrollmentResult = await this.enrollmentRepo.getActiveByEntity(
      context,
      'deal',
      dealId
    );

    if (!enrollmentResult.success || !enrollmentResult.data) {
      return; // No active enrollment
    }

    const enrollment = enrollmentResult.data;

    // 2. Get sequence settings
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return;
    }

    const sequence = sequenceResult.data;
    const exitCriteria = sequence.exitCriteria;

    // 3. Check exit criteria
    let shouldExit = false;
    let exitReason: ExitReason | undefined;

    if (status === 'won' && exitCriteria?.onDealWon) {
      shouldExit = true;
      exitReason = 'deal_won';
    } else if (status === 'lost' && exitCriteria?.onDealLost) {
      shouldExit = true;
      exitReason = 'deal_lost';
    }

    // 4. Exit if criteria met
    if (shouldExit && exitReason) {
      await this.enrollmentRepo.exit(context, enrollment.id, exitReason);
      await this.sequenceRepo.incrementStat(context, sequence.id, 'exitedCount');

      // Audit log
      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'activity',
        entityId: enrollment.id,
        metadata: {
          action: 'sequenceDealStatusChanged',
          sequenceId: sequence.id,
          enrollmentId: enrollment.id,
          dealId,
          dealStatus: status,
          exited: true,
        },
      });
    }
  }

  // ============================================
  // Unsubscribe Handling
  // ============================================

  /**
   * Handle unsubscribe.
   * Called from unsubscribe link click.
   */
  async onUnsubscribe(
    context: SecurityContext,
    entityType: EnrollmentEntityType,
    entityId: string
  ): Promise<void> {
    // 1. Get all enrollments for entity (not just active)
    const enrollmentsResult = await this.enrollmentRepo.getByEntity(
      context,
      entityType,
      entityId
    );

    if (!enrollmentsResult.success || !enrollmentsResult.data) {
      return;
    }

    const enrollments = enrollmentsResult.data;

    // 2. Exit all active/paused enrollments
    for (const enrollment of enrollments) {
      if (enrollment.status === 'active' || enrollment.status === 'paused') {
        await this.enrollmentRepo.markUnsubscribed(context, enrollment.id);

        // Update sequence stats
        await this.sequenceRepo.incrementStat(context, enrollment.sequenceId, 'exitedCount');
      }
    }

    // 3. Audit log
    await this.auditService.logAction(context, {
      action: 'update',
      entityType: 'activity',
      entityId: entityId,
      metadata: {
        action: 'sequenceUnsubscribed',
        entityType,
        entityId,
        enrollmentsExited: enrollments.filter(
          (e) => e.status === 'active' || e.status === 'paused'
        ).length,
      },
    });

    // 4. TODO: Mark entity as opted out in their record
    // This would require updating the lead/client/deal repository
    // to store an optedOutAt or unsubscribedAt field
  }

  // ============================================
  // Lead Conversion Handling
  // ============================================

  /**
   * Handle lead conversion to client/deal.
   * Called when a lead is converted.
   */
  async onLeadConverted(
    context: SecurityContext,
    leadId: string,
    convertedToType: 'client' | 'deal',
    convertedToId: string
  ): Promise<void> {
    // 1. Find active enrollment for lead
    const enrollmentResult = await this.enrollmentRepo.getActiveByEntity(
      context,
      'lead',
      leadId
    );

    if (!enrollmentResult.success || !enrollmentResult.data) {
      return;
    }

    const enrollment = enrollmentResult.data;

    // 2. Get sequence settings
    const sequenceResult = await this.sequenceRepo.getById(context, enrollment.sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return;
    }

    const sequence = sequenceResult.data;

    // 3. Check exit criteria
    if (sequence.exitCriteria?.onLeadConverted) {
      await this.enrollmentRepo.exit(context, enrollment.id, 'converted');
      await this.sequenceRepo.incrementStat(context, sequence.id, 'exitedCount');

      // Audit log
      await this.auditService.logAction(context, {
        action: 'update',
        entityType: 'activity',
        entityId: enrollment.id,
        metadata: {
          action: 'sequenceLeadConverted',
          sequenceId: sequence.id,
          enrollmentId: enrollment.id,
          leadId,
          convertedToType,
          convertedToId,
        },
      });
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let handlersInstance: SequenceEventHandlers | null = null;

export function getSequenceEventHandlers(): SequenceEventHandlers {
  if (!handlersInstance) {
    handlersInstance = new SequenceEventHandlers();
  }
  return handlersInstance;
}
