/**
 * Web Form Submission Service
 * Handles public form submissions with spam protection, validation, and lead creation
 *
 * Agent Web Forms Implementation
 *
 * HIPAA Compliance:
 * - Public endpoints must NOT log PHI
 * - IP addresses used for rate limiting only, NOT stored with lead
 * - Audit logs use formId/leadId only, no field values
 * - Notification emails use secure portal links, not inline PHI
 */

import { getWebFormRepository } from '../data/repositories/web-form-repository';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { getDuplicateDetectionService } from './DuplicateDetectionService';
import { getRateLimitService, type RateLimitAction } from './RateLimitService';
import { getAuditLogService } from './AuditLogService';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Lead, LeadSource } from '../types/models';
import type {
  WebForm,
  WebFormSubmissionData,
  WebFormSubmissionResult,
  WebFormSubmissionErrorCode,
  WebFormDuplicateWarning,
  WebFormFieldError,
  WebFormValidationResult,
} from '../types/web-forms';

// ============================================
// Rate Limit Configuration
// ============================================

/**
 * Rate limit bucket for web form submissions
 * Uses IP-based limiting via RateLimitService
 */
const WEB_FORM_RATE_LIMIT_ACTION: RateLimitAction = 'automation';

// ============================================
// Validation
// ============================================

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

/**
 * Normalize phone number for storage
 */
function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, '');
}

/**
 * Validate form field values against field configuration
 */
function validateSubmission(
  form: WebForm,
  fieldValues: Record<string, string | boolean>
): WebFormValidationResult {
  const errors: WebFormFieldError[] = [];

  for (const field of form.fields) {
    const value = fieldValues[field.id];

    // Check required fields
    if (field.required) {
      const isEmpty =
        value === undefined ||
        value === null ||
        value === '' ||
        (typeof value === 'string' && !value.trim());

      if (isEmpty) {
        errors.push({
          fieldId: field.id,
          message: `${field.label} is required`,
          code: 'REQUIRED',
        });
        continue;
      }
    }

    // Skip further validation if value is empty and not required
    if (value === undefined || value === null || value === '') {
      continue;
    }

    const stringValue = typeof value === 'string' ? value : String(value);

    // Type-specific validation
    switch (field.type) {
      case 'email':
        if (!EMAIL_REGEX.test(stringValue)) {
          errors.push({
            fieldId: field.id,
            message: 'Please enter a valid email address',
            code: 'INVALID_FORMAT',
          });
        }
        break;

      case 'phone':
        if (!PHONE_REGEX.test(stringValue)) {
          errors.push({
            fieldId: field.id,
            message: 'Please enter a valid phone number',
            code: 'INVALID_FORMAT',
          });
        } else {
          const normalized = normalizePhone(stringValue);
          if (normalized.length < MIN_PHONE_DIGITS) {
            errors.push({
              fieldId: field.id,
              message: `Phone number must have at least ${MIN_PHONE_DIGITS} digits`,
              code: 'INVALID_FORMAT',
            });
          }
        }
        break;

      case 'select':
        if (field.options && !field.options.includes(stringValue)) {
          errors.push({
            fieldId: field.id,
            message: 'Please select a valid option',
            code: 'INVALID_FORMAT',
          });
        }
        break;
    }

    // Custom validation rules
    if (field.validation) {
      if (field.validation.minLength && stringValue.length < field.validation.minLength) {
        errors.push({
          fieldId: field.id,
          message: `${field.label} must be at least ${field.validation.minLength} characters`,
          code: 'TOO_SHORT',
        });
      }

      if (field.validation.maxLength && stringValue.length > field.validation.maxLength) {
        errors.push({
          fieldId: field.id,
          message: `${field.label} must be less than ${field.validation.maxLength} characters`,
          code: 'TOO_LONG',
        });
      }

      if (field.validation.pattern) {
        try {
          const regex = new RegExp(field.validation.pattern);
          if (!regex.test(stringValue)) {
            errors.push({
              fieldId: field.id,
              message: `${field.label} format is invalid`,
              code: 'PATTERN_MISMATCH',
            });
          }
        } catch {
          // Invalid regex pattern - skip validation
        }
      }
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Lead Data Mapping
// ============================================

/**
 * Map form field values to lead data
 */
function mapToLeadData(
  form: WebForm,
  fieldValues: Record<string, string | boolean>,
  metadata: WebFormSubmissionData['metadata']
): Partial<Lead> {
  const leadData: Partial<Lead> = {
    tags: form.settings.defaultTags || [],
    source: (form.settings.defaultLeadSource as LeadSource) || 'website',
  };

  const customFields: Record<string, unknown> = {};

  // Map field values
  for (const field of form.fields) {
    const value = fieldValues[field.id];
    if (value === undefined || value === null || value === '') {
      continue;
    }

    const stringValue = typeof value === 'string' ? value.trim() : String(value);

    switch (field.mapToField) {
      case 'firstName':
        leadData.firstName = stringValue;
        break;
      case 'lastName':
        leadData.lastName = stringValue;
        break;
      case 'email':
        leadData.email = stringValue.toLowerCase();
        break;
      case 'phone':
        leadData.phone = normalizePhone(stringValue);
        break;
      case 'companyName':
        leadData.companyName = stringValue;
        break;
      case 'title':
        leadData.title = stringValue;
        break;
      case 'source':
        leadData.source = stringValue as LeadSource;
        break;
      case 'notes':
        leadData.notes = stringValue;
        break;
      default:
        // Custom field mapping
        if (field.mapToField && field.mapToField.startsWith('customField_')) {
          const customFieldName = field.mapToField.replace('customField_', '');
          customFields[customFieldName] = value;
        }
    }
  }

  // Add custom fields if any
  if (Object.keys(customFields).length > 0) {
    leadData.customFields = customFields;
  }

  // Add UTM parameters to notes or custom fields
  const utmParams: string[] = [];
  if (metadata.utmSource) utmParams.push(`Source: ${metadata.utmSource}`);
  if (metadata.utmMedium) utmParams.push(`Medium: ${metadata.utmMedium}`);
  if (metadata.utmCampaign) utmParams.push(`Campaign: ${metadata.utmCampaign}`);

  if (utmParams.length > 0) {
    const utmNote = `UTM: ${utmParams.join(', ')}`;
    leadData.notes = leadData.notes
      ? `${leadData.notes}\n\n${utmNote}`
      : utmNote;
  }

  // Add referrer to notes
  if (metadata.referrerUrl) {
    const referrerNote = `Referrer: ${metadata.referrerUrl}`;
    leadData.notes = leadData.notes
      ? `${leadData.notes}\n${referrerNote}`
      : referrerNote;
  }

  return leadData;
}

// ============================================
// Web Form Submission Service
// ============================================

export class WebFormSubmissionService {
  private formRepo = getWebFormRepository();
  private leadRepo = getLeadRepository();
  private duplicateService = getDuplicateDetectionService();
  private rateLimitService = getRateLimitService();
  private auditService = getAuditLogService();

  /**
   * Process a public form submission
   *
   * HIPAA Note: This is a public endpoint. Do NOT log field values or PHI.
   *
   * @param businessId - Business ID (from form embed config)
   * @param submission - Form submission data
   * @param ipAddress - Client IP for rate limiting (NOT stored)
   */
  async submitForm(
    businessId: string,
    submission: WebFormSubmissionData,
    ipAddress: string
  ): Promise<WebFormSubmissionResult> {
    try {
      // 1. Validate form exists and is active
      const formResult = await this.formRepo.getPublicForm(
        businessId,
        submission.formId
      );

      if (!formResult.success) {
        return {
          success: false,
          error: 'Form not found or inactive',
          errorCode: 'FORM_NOT_FOUND',
        };
      }

      // Get full form for processing (need internal settings)
      const systemContext: SecurityContext = {
        businessId,
        userId: 'system',
        userName: 'System',
        userRole: 'system',
      };

      // Re-fetch with system context for full data
      const fullFormResult = await this.formRepo.getById(
        systemContext,
        submission.formId
      );

      if (!fullFormResult.success || fullFormResult.data.status !== 'active') {
        return {
          success: false,
          error: 'Form not found or inactive',
          errorCode: 'FORM_INACTIVE',
        };
      }

      const form = fullFormResult.data;

      // 2. Apply spam protection checks
      const spamCheck = await this.checkSpamProtection(
        form,
        submission,
        ipAddress,
        businessId
      );

      if (!spamCheck.passed) {
        return {
          success: false,
          error: spamCheck.message,
          errorCode: spamCheck.errorCode,
        };
      }

      // 3. Validate required fields and formats
      const validation = validateSubmission(form, submission.fieldValues);
      if (!validation.isValid) {
        const errorMessages = validation.errors.map((e) => e.message).join(', ');
        return {
          success: false,
          error: errorMessages,
          errorCode: 'VALIDATION_ERROR',
        };
      }

      // 4. Map to lead data
      const leadData = mapToLeadData(form, submission.fieldValues, submission.metadata);

      // Ensure required lead fields
      if (!leadData.firstName) leadData.firstName = 'Unknown';
      if (!leadData.lastName) leadData.lastName = 'Lead';
      if (!leadData.email) {
        return {
          success: false,
          error: 'Email is required',
          errorCode: 'VALIDATION_ERROR',
        };
      }

      // 5. Check for duplicates (warn but don't block)
      const duplicateWarnings: WebFormDuplicateWarning[] = [];
      try {
        const duplicates = await this.duplicateService.findDuplicates(
          systemContext,
          leadData as Lead,
          { entityType: 'lead', minConfidence: 80, limit: 3 }
        );

        for (const dup of duplicates) {
          if (dup.matchDetails.email) {
            duplicateWarnings.push({
              matchType: 'email',
              existingLeadId: dup.entity.id,
            });
          }
          if (dup.matchDetails.phone) {
            duplicateWarnings.push({
              matchType: 'phone',
              existingLeadId: dup.entity.id,
            });
          }
        }
      } catch {
        // Duplicate detection failure should not block submission
      }

      // 6. Create lead
      const createData: Omit<Lead, 'id' | 'createdAt' | 'updatedAt'> = {
        ...leadData,
        firstName: leadData.firstName!,
        lastName: leadData.lastName!,
        email: leadData.email!,
        status: 'new',
        source: leadData.source || 'website',
        tags: leadData.tags || [],
        ownerId: form.settings.assignToUserId || form.ownerId,
        ownerName: form.settings.assignToUserName || form.ownerName,
        teamIds: form.teamIds,
        visibility: 'team',
        assigneeId: form.settings.assignToUserId,
        assigneeName: form.settings.assignToUserName,
        // Allow duplicate override for web form submissions
        allowDuplicate: true,
      } as Omit<Lead, 'id' | 'createdAt' | 'updatedAt'> & { allowDuplicate: boolean };

      const leadResult = await this.leadRepo.create(systemContext, createData);

      if (!leadResult.success) {
        return {
          success: false,
          error: 'Failed to create lead',
          errorCode: 'INTERNAL_ERROR',
        };
      }

      const lead = leadResult.data;

      // 7. Increment form submission count
      await this.formRepo.incrementSubmissionCount(systemContext, form.id);

      // 8. Trigger automation event (leadCreated)
      try {
        await this.triggerAutomation(systemContext, lead, form.id);
      } catch {
        // Automation failure should not block submission
      }

      // 9. Auto-enroll in sequence if configured
      if (form.settings.sequenceId) {
        try {
          await this.enrollInSequence(
            systemContext,
            lead,
            form.settings.sequenceId
          );
        } catch {
          // Sequence enrollment failure should not block submission
        }
      }

      // 10. Send notification emails if configured
      if (form.settings.notifyEmails && form.settings.notifyEmails.length > 0) {
        try {
          await this.sendNotifications(
            systemContext,
            form,
            lead
          );
        } catch {
          // Notification failure should not block submission
        }
      }

      // 11. Audit log (formId and leadId only - no PHI)
      try {
        await this.auditService.logAction(systemContext, {
          action: 'create',
          entityType: 'lead',
          entityId: lead.id,
          metadata: {
            source: 'web_form',
            formId: form.id,
            hasDuplicates: duplicateWarnings.length > 0,
          },
        });
      } catch {
        // Audit failure should not block submission
      }

      return {
        success: true,
        leadId: lead.id,
        duplicateWarnings:
          duplicateWarnings.length > 0 ? duplicateWarnings : undefined,
      };
    } catch (error) {
      // Generic error handling - do not expose internal details
      return {
        success: false,
        error: 'An error occurred processing your submission',
        errorCode: 'INTERNAL_ERROR',
      };
    }
  }

  /**
   * Check spam protection rules
   */
  private async checkSpamProtection(
    form: WebForm,
    submission: WebFormSubmissionData,
    ipAddress: string,
    businessId: string
  ): Promise<{
    passed: boolean;
    message?: string;
    errorCode?: WebFormSubmissionErrorCode;
  }> {
    // Honeypot check
    if (form.spamProtection.honeypot && submission.honeypotValue) {
      return {
        passed: false,
        message: 'Spam detected',
        errorCode: 'SPAM_DETECTED',
      };
    }

    // Rate limiting (per IP)
    const rateLimit = await this.rateLimitService.checkLimit(
      WEB_FORM_RATE_LIMIT_ACTION,
      ipAddress, // Use IP as the "user" for rate limiting
      businessId
    );

    if (rateLimit && rateLimit.allowed === false) {
      return {
        passed: false,
        message: `Too many submissions. Please try again later.`,
        errorCode: 'RATE_LIMITED',
      };
    }

    // Record the action for rate limiting
    await this.rateLimitService.recordAction(
      WEB_FORM_RATE_LIMIT_ACTION,
      ipAddress,
      businessId
    );

    // reCAPTCHA validation would be done in the Cloud Function
    // as it requires the secret key which should not be in client code
    if (form.spamProtection.recaptchaEnabled && !submission.recaptchaToken) {
      return {
        passed: false,
        message: 'Please complete the captcha',
        errorCode: 'RECAPTCHA_FAILED',
      };
    }

    return { passed: true };
  }

  /**
   * Trigger automation event for lead creation
   */
  private async triggerAutomation(
    context: SecurityContext,
    lead: Lead,
    _formId: string
  ): Promise<void> {
    // Import dynamically to avoid circular dependencies
    try {
      const { dispatchAutomationEvent } = await import('./automation-dispatcher');
      await dispatchAutomationEvent({
        triggerType: 'leadCreated',
        entityType: 'lead',
        entityId: lead.id,
        businessId: context.businessId,
      });
    } catch {
      // Automation not available or failed - continue
    }
  }

  /**
   * Enroll lead in sequence
   */
  private async enrollInSequence(
    _context: SecurityContext,
    lead: Lead,
    sequenceId: string
  ): Promise<void> {
    try {
      const { getSequenceExecutionService } = await import('./sequence-execution-service');
      const service = getSequenceExecutionService();
      // Note: Sequence enrollment through web forms requires custom integration
      // For now, log the intent - actual enrollment would use sequence-enrollment-repository directly
      console.log(`[WebForm] Would enroll lead ${lead.id} in sequence ${sequenceId}`);
      void service; // Service available for future use
    } catch {
      // Sequence service not available or failed - continue
    }
  }

  /**
   * Send notification emails to configured recipients
   *
   * HIPAA Note: Use secure portal links instead of inline PHI
   */
  private async sendNotifications(
    _context: SecurityContext,
    form: WebForm,
    lead: Lead
  ): Promise<void> {
    if (!form.settings.notifyEmails || form.settings.notifyEmails.length === 0) {
      return;
    }

    // Build secure portal link (no PHI in email)
    const portalLink = `/leads/${lead.id}`;

    // TODO: Implement via Cloud Functions for raw email sending to staff addresses
    // The email service is designed for CRM contact-based emails with templates
    // Staff notifications require a different mechanism (e.g., SendGrid direct API via Cloud Function)
    console.log(`[WebForm] Would notify ${form.settings.notifyEmails.length} recipients about lead via ${portalLink}`);
  }
}

// ============================================
// Singleton Export
// ============================================

let webFormSubmissionServiceInstance: WebFormSubmissionService | null = null;

export function getWebFormSubmissionService(): WebFormSubmissionService {
  if (!webFormSubmissionServiceInstance) {
    webFormSubmissionServiceInstance = new WebFormSubmissionService();
  }
  return webFormSubmissionServiceInstance;
}
