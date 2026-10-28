/**
 * Email Step Executor
 * Handles execution of email steps in sequences
 *
 * HIPAA Compliance:
 * - No PHI in logs
 * - Email content processed via secure email service
 * - Rate limits enforced
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  SequenceEnrollment,
} from '../../types/sequences';
import type { StepExecutionResult, ExecutorContext } from './types';
import { getEmailService } from '../email-service';
import { getRateLimitService } from '../RateLimitService';
import {
  getMergeFieldProcessor,
  type MergeFieldContext,
} from '../sequence-merge-fields';
import { getEmailTrackingService } from '../email-tracking-service';

// ============================================
// Email Step Executor
// ============================================

export class EmailStepExecutor {
  private emailService = getEmailService();
  private rateLimitService = getRateLimitService();
  private mergeFieldProcessor = getMergeFieldProcessor();
  private emailTrackingService = getEmailTrackingService();

  /**
   * Execute an email step.
   */
  async execute(context: ExecutorContext): Promise<StepExecutionResult> {
    const { securityContext, enrollment, step } = context;

    // 1. Validate email configuration
    if (!step.emailConfig) {
      return {
        success: false,
        errorCode: 'MISSING_CONFIG',
        errorMessage: 'Email step is missing email configuration',
      };
    }

    // 2. Check rate limits (business level)
    const businessRateCheck = await this.rateLimitService.checkLimit(
      'email',
      'system',
      securityContext.businessId
    );

    if (!businessRateCheck.allowed) {
      return {
        success: false,
        errorCode: 'RATE_LIMITED',
        errorMessage: `Business email rate limit exceeded. Retry after ${businessRateCheck.resetAt.toISOString()}`,
      };
    }

    // 3. Check per-contact rate limit (max 3 emails/day per contact)
    const contactRateCheck = await this.rateLimitService.checkLimit(
      'email',
      enrollment.entityId,
      securityContext.businessId
    );

    if (!contactRateCheck.allowed) {
      return {
        success: false,
        errorCode: 'CONTACT_RATE_LIMITED',
        errorMessage: 'Contact has reached daily email limit',
      };
    }

    // 4. Resolve email content (template or inline)
    let subject = step.emailConfig.subject || '';
    let body = step.emailConfig.body || '';

    if (step.emailConfig.templateId) {
      const templateResult = await this.emailService.getTemplateById(
        securityContext,
        step.emailConfig.templateId
      );

      if (templateResult.success && templateResult.data) {
        subject = templateResult.data.subject;
        body = templateResult.data.textBody;
      } else {
        // Fall back to inline content if template not found
        if (!subject || !body) {
          return {
            success: false,
            errorCode: 'TEMPLATE_NOT_FOUND',
            errorMessage: 'Email template not found and no inline content provided',
          };
        }
      }
    }

    // 5. Validate we have content
    if (!subject || !body) {
      return {
        success: false,
        errorCode: 'MISSING_CONTENT',
        errorMessage: 'Email step has no subject or body content',
      };
    }

    // 6. Apply merge fields
    try {
      const mergeContext = await this.buildMergeContext(securityContext, enrollment);
      subject = await this.mergeFieldProcessor.process(subject, mergeContext);
      body = await this.mergeFieldProcessor.process(body, mergeContext);
    } catch (error) {
      return {
        success: false,
        errorCode: 'MERGE_FIELD_ERROR',
        errorMessage: 'Failed to process merge fields',
      };
    }

    // 7.1 Inject tracking pixel/link wrappers for downstream analytics
    body = await this.emailTrackingService.prepareEmailForTracking(
      securityContext,
      enrollment.id,
      body,
      { trackOpens: true, trackClicks: true }
    );

    // 7. Send email via EmailService
    const sendResult = await this.emailService.sendEmail(securityContext, {
      recipientId: enrollment.entityId,
      templateType: 'follow_up',
      templateData: {
        subject,
        message: body,
        businessName: '', // Will be filled by email service
      },
      relatedEntity: {
        // Use 'lead' as default entity type for sequence-related emails
        type: 'lead',
        id: enrollment.entityId,
      },
    });

    // 8. Record rate limit usage
    if (sendResult.success) {
      await this.rateLimitService.recordAction(
        'email',
        enrollment.entityId,
        securityContext.businessId
      );
    }

    // 9. Return result
    return {
      success: sendResult.success,
      messageId: sendResult.providerMessageId,
      errorCode: sendResult.success ? undefined : 'SEND_FAILED',
      errorMessage: sendResult.error,
    };
  }

  /**
   * Build merge field context from enrollment data.
   */
  private async buildMergeContext(
    _context: SecurityContext,
    enrollment: SequenceEnrollment
  ): Promise<MergeFieldContext> {
    // In a full implementation, we would fetch the actual entity data
    // For now, we use the denormalized data from enrollment
    return {
      contact: {
        firstName: this.extractFirstName(enrollment.entityName),
        lastName: this.extractLastName(enrollment.entityName),
        email: enrollment.entityEmail,
      },
      company: {},
      sender: {
        name: enrollment.enrolledByName || 'System',
        email: '', // Would be fetched from user/business settings
      },
      business: {
        name: '', // Would be fetched from business settings
      },
      custom: {},
    };
  }

  /**
   * Extract first name from full name.
   */
  private extractFirstName(fullName: string): string {
    const parts = fullName.trim().split(/\s+/);
    return parts[0] || '';
  }

  /**
   * Extract last name from full name.
   */
  private extractLastName(fullName: string): string {
    const parts = fullName.trim().split(/\s+/);
    return parts.slice(1).join(' ') || '';
  }
}

// ============================================
// Singleton Instance
// ============================================

let executorInstance: EmailStepExecutor | null = null;

export function getEmailStepExecutor(): EmailStepExecutor {
  if (!executorInstance) {
    executorInstance = new EmailStepExecutor();
  }
  return executorInstance;
}
