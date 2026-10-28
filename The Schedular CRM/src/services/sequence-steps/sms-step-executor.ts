/**
 * SMS Step Executor
 * Handles execution of SMS steps in sequences
 *
 * HIPAA Compliance:
 * - No PHI in logs
 * - SMS content processed via secure SMS service
 * - Rate limits enforced
 * - Opt-out status checked before every send
 *
 * Phase 5 Implementation - SMS Sequences
 */

import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  SequenceEnrollment,
} from '../../types/sequences';
import type { StepExecutionResult, ExecutorContext } from './types';
import { getSmsService } from '../sms-service';
import { getRateLimitService } from '../RateLimitService';
import {
  getMergeFieldProcessor,
  type MergeFieldContext,
} from '../sequence-merge-fields';

// ============================================
// SMS Step Executor
// ============================================

export class SmsStepExecutor {
  private smsService = getSmsService();
  private rateLimitService = getRateLimitService();
  private mergeFieldProcessor = getMergeFieldProcessor();

  /**
   * Execute an SMS step.
   */
  async execute(context: ExecutorContext): Promise<StepExecutionResult> {
    const { securityContext, enrollment, step } = context;

    // 1. Validate SMS configuration
    if (!step.smsConfig) {
      return {
        success: false,
        errorCode: 'MISSING_CONFIG',
        errorMessage: 'SMS step is missing SMS configuration',
      };
    }

    // 2. Validate enrollment has phone number
    if (!enrollment.entityPhone) {
      return {
        success: false,
        skipped: true,
        skipReason: 'Contact does not have a phone number',
      };
    }

    // 3. Check business-level rate limit
    const businessRateCheck = await this.rateLimitService.checkLimit(
      'sms',
      'business',
      securityContext.businessId
    );

    if (!businessRateCheck.allowed) {
      return {
        success: false,
        errorCode: 'RATE_LIMITED',
        errorMessage: `Business SMS rate limit exceeded. Retry after ${businessRateCheck.resetAt.toISOString()}`,
      };
    }

    // 4. Check per-contact rate limit (2 SMS/day per contact)
    const contactRateCheck = await this.rateLimitService.checkLimit(
      'sms',
      enrollment.entityId,
      securityContext.businessId
    );

    if (!contactRateCheck.allowed) {
      return {
        success: false,
        errorCode: 'CONTACT_RATE_LIMITED',
        errorMessage: 'Contact has reached daily SMS limit',
      };
    }

    // 5. Check opt-out status (TCPA compliance)
    const optOutStatus = await this.smsService.checkOptOut(
      securityContext,
      enrollment.entityPhone
    );

    if (optOutStatus === 'opted_out') {
      return {
        success: true,
        skipped: true,
        skipReason: 'Contact has opted out of SMS',
      };
    }

    // 6. Resolve SMS body
    let body = step.smsConfig.body || '';

    if (step.smsConfig.templateId) {
      const templateResult = await this.smsService.getTemplateById(
        securityContext,
        step.smsConfig.templateId
      );

      if (templateResult.success && templateResult.data) {
        body = templateResult.data.body;
      } else {
        // Fall back to inline content if template not found
        if (!body) {
          return {
            success: false,
            errorCode: 'TEMPLATE_NOT_FOUND',
            errorMessage: 'SMS template not found and no inline content provided',
          };
        }
      }
    }

    if (!body) {
      return {
        success: false,
        errorCode: 'MISSING_BODY',
        errorMessage: 'SMS step has no message content',
      };
    }

    // 7. Apply merge fields
    try {
      const mergeContext = await this.buildMergeContext(securityContext, enrollment);
      body = await this.mergeFieldProcessor.process(body, mergeContext);
    } catch (error) {
      return {
        success: false,
        errorCode: 'MERGE_FIELD_ERROR',
        errorMessage: 'Failed to process merge fields',
      };
    }

    // 8. Send SMS via SMS Service
    const sendResult = await this.smsService.sendSms(securityContext, {
      recipientId: enrollment.entityId,
      recipientPhone: enrollment.entityPhone,
      body,
      relatedEntity: {
        type: 'sequence_enrollment',
        id: enrollment.id,
      },
    });

    // 9. Record rate limit usage if successful
    if (sendResult.success) {
      await this.rateLimitService.recordAction(
        'sms',
        enrollment.entityId,
        securityContext.businessId
      );
      await this.rateLimitService.recordAction(
        'sms',
        'business',
        securityContext.businessId
      );
    }

    // 10. Return result
    return {
      success: sendResult.success,
      messageId: sendResult.providerMessageId || sendResult.messageId,
      errorCode: sendResult.errorCode,
      errorMessage: sendResult.errorMessage,
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
        phone: enrollment.entityPhone,
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

let executorInstance: SmsStepExecutor | null = null;

export function getSmsStepExecutor(): SmsStepExecutor {
  if (!executorInstance) {
    executorInstance = new SmsStepExecutor();
  }
  return executorInstance;
}
