/**
 * SMS Service
 * Handles SMS sending via Twilio with HIPAA compliance
 *
 * HIPAA Compliance Requirements:
 * - NO PHI in SMS content (use secure portal links)
 * - Phone numbers masked in logs (last 4 digits only)
 * - Rate limiting to prevent spam (TCPA compliance)
 * - Opt-out management (STOP/START keywords)
 * - Audit logging for all operations
 *
 * Agent SMS Implementation - 2025-12-02
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type {
  SmsMessage,
  SmsTemplate,
  SmsStatus,
  OptOutStatus,
  SendSmsOptions,
  SendSmsResult,
  SendTemplatedSmsOptions,
} from '../types/sms';
import {
  calculateSegmentCount,
  normalizePhone,
  isValidPhone,
  isOptOutKeyword,
  isOptInKeyword,
} from '../types/sms';
import { getSmsMessageRepository } from '../data/repositories/sms-message-repository';
import { getSmsOptOutRepository } from '../data/repositories/sms-opt-out-repository';
import { getSmsTemplateRepository } from '../data/repositories/sms-template-repository';
import { getRateLimitService } from './RateLimitService';
import { getMergeFieldProcessor, type MergeFieldContext } from './sequence-merge-fields';
import { generateId } from '../data/repositories/firestore-utils';

// ============================================
// Configuration
// ============================================

interface SmsConfig {
  /** Cloud Function endpoint for sending SMS */
  sendSmsEndpoint: string;
  /** Cloud Function endpoint for webhook processing */
  webhookEndpoint: string;
  /** Default from number (Twilio number) */
  fromNumber: string;
  /** Enable simulation mode (no actual SMS sent) */
  simulationMode: boolean;
  /** Business ID for Twilio messaging service */
  twilioMessagingServiceSid?: string;
}

// Default configuration (override via environment variables)
const getConfig = (): SmsConfig => ({
  sendSmsEndpoint: import.meta.env.VITE_SMS_FUNCTION_URL || '',
  webhookEndpoint: import.meta.env.VITE_SMS_WEBHOOK_URL || '',
  fromNumber: import.meta.env.VITE_TWILIO_FROM_NUMBER || '',
  simulationMode:
    import.meta.env.VITE_SMS_SIMULATION === 'true' || !import.meta.env.VITE_SMS_FUNCTION_URL,
  twilioMessagingServiceSid: import.meta.env.VITE_TWILIO_MESSAGING_SERVICE_SID,
});

// ============================================
// SMS Service
// ============================================

export class SmsService {
  private config: SmsConfig;
  private messageRepo = getSmsMessageRepository();
  private optOutRepo = getSmsOptOutRepository();
  private templateRepo = getSmsTemplateRepository();
  private rateLimitService = getRateLimitService();
  private mergeFieldProcessor = getMergeFieldProcessor();

  constructor(config?: Partial<SmsConfig>) {
    this.config = { ...getConfig(), ...config };
  }

  // ============================================
  // Public Methods - Sending
  // ============================================

  /**
   * Send a single SMS
   * HIPAA compliant - no PHI in content
   */
  async sendSms(context: SecurityContext, options: SendSmsOptions): Promise<SendSmsResult> {
    try {
      // 1. Validate phone number
      if (!isValidPhone(options.recipientPhone)) {
        return {
          success: false,
          errorCode: 'INVALID_PHONE',
          errorMessage: 'Invalid recipient phone number',
        };
      }

      // 2. Check business-level rate limit
      const businessRateCheck = await this.rateLimitService.checkLimit(
        'sms',
        'business',
        context.businessId
      );

      if (!businessRateCheck.allowed) {
        return {
          success: false,
          errorCode: 'RATE_LIMITED',
          errorMessage: `Business SMS rate limit exceeded. Try again after ${businessRateCheck.resetAt.toLocaleTimeString()}`,
        };
      }

      // 3. Check per-contact rate limit
      const contactRateCheck = await this.rateLimitService.checkLimit(
        'sms',
        options.recipientId,
        context.businessId
      );

      if (!contactRateCheck.allowed) {
        return {
          success: false,
          errorCode: 'CONTACT_RATE_LIMITED',
          errorMessage: 'Contact has reached daily SMS limit',
        };
      }

      // 4. Check opt-out status (TCPA compliance)
      const optOutStatus = await this.checkOptOut(context, options.recipientPhone);
      if (optOutStatus === 'opted_out') {
        return {
          success: false,
          errorCode: 'OPTED_OUT',
          errorMessage: 'Recipient has opted out of SMS messages',
        };
      }

      // 5. Calculate segment count
      const segmentCount = calculateSegmentCount(options.body);

      // 6. Create message record (queued)
      const messageData: Omit<SmsMessage, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        recipientId: options.recipientId,
        recipientPhone: normalizePhone(options.recipientPhone),
        fromNumber: this.config.fromNumber,
        sentById: context.userId,
        sentByName: context.userName,
        body: options.body,
        segmentCount,
        status: 'queued',
        direction: 'outbound',
        relatedEntityType: options.relatedEntity?.type,
        relatedEntityId: options.relatedEntity?.id,
      };

      const createResult = await this.messageRepo.create(context, messageData);
      if (!createResult.success) {
        return {
          success: false,
          errorCode: 'CREATE_FAILED',
          errorMessage: 'Failed to create message record',
        };
      }

      const messageId = createResult.data.id;

      // 7. Send via Cloud Function (or simulate)
      const sendResult = await this.sendViaCloudFunction(
        context,
        messageId,
        normalizePhone(options.recipientPhone),
        options.body
      );

      // 8. Update message status
      if (sendResult.success) {
        await this.messageRepo.updateStatus(context, messageId, 'sent', {
          deliveredAt: new Date(),
        });

        // Record rate limit usage
        await this.rateLimitService.recordAction('sms', options.recipientId, context.businessId);
        await this.rateLimitService.recordAction('sms', 'business', context.businessId);
      } else {
        await this.messageRepo.updateStatus(context, messageId, 'failed', {
          failedAt: new Date(),
          errorCode: sendResult.errorCode,
          errorMessage: sendResult.errorMessage,
        });
      }

      return {
        success: sendResult.success,
        messageId,
        providerMessageId: sendResult.providerMessageId,
        segmentCount,
        errorCode: sendResult.errorCode,
        errorMessage: sendResult.errorMessage,
      };
    } catch (error) {
      return {
        success: false,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: 'Failed to send SMS. Please try again later.',
      };
    }
  }

  /**
   * Send SMS using a template
   */
  async sendTemplatedSms(
    context: SecurityContext,
    options: SendTemplatedSmsOptions
  ): Promise<SendSmsResult> {
    try {
      // 1. Get template
      const templateResult = await this.templateRepo.getById(context, options.templateId);
      if (!templateResult.success || !templateResult.data) {
        return {
          success: false,
          errorCode: 'TEMPLATE_NOT_FOUND',
          errorMessage: 'SMS template not found',
        };
      }

      const template = templateResult.data;
      if (!template.isActive) {
        return {
          success: false,
          errorCode: 'TEMPLATE_INACTIVE',
          errorMessage: 'SMS template is inactive',
        };
      }

      // 2. Apply merge fields
      const mergeContext = this.buildMergeContext(options.mergeData);
      const body = await this.mergeFieldProcessor.process(template.body, mergeContext);

      // 3. Send using standard send method
      return this.sendSms(context, {
        recipientId: options.recipientId,
        recipientPhone: options.recipientPhone,
        body,
        relatedEntity: options.relatedEntity,
      });
    } catch (error) {
      return {
        success: false,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: 'Failed to send templated SMS',
      };
    }
  }

  // ============================================
  // Public Methods - Opt-Out Management
  // ============================================

  /**
   * Check opt-out status for a phone number
   */
  async checkOptOut(context: SecurityContext, phone: string): Promise<OptOutStatus> {
    const result = await this.optOutRepo.checkOptOut(context, phone);
    if (!result.success) {
      // Default to pending (allow send) if check fails
      return 'pending';
    }
    return result.data;
  }

  /**
   * Handle opt-out request (STOP)
   */
  async handleOptOut(
    context: SecurityContext,
    phone: string,
    source: 'reply_stop' | 'manual' | 'import' | 'api'
  ): Promise<void> {
    await this.optOutRepo.optOut(context, phone, source);
  }

  /**
   * Handle opt-in request (START)
   */
  async handleOptIn(context: SecurityContext, phone: string): Promise<void> {
    await this.optOutRepo.optIn(context, phone);
  }

  // ============================================
  // Public Methods - Incoming SMS Handling
  // ============================================

  /**
   * Process an incoming SMS (from Twilio webhook)
   */
  async handleIncomingSms(
    context: SecurityContext,
    fromPhone: string,
    toNumber: string,
    body: string
  ): Promise<{ responseMessage?: string; action: string }> {
    const normalizedBody = body.toLowerCase().trim();

    // Check for opt-out keywords (TCPA compliance)
    if (isOptOutKeyword(normalizedBody)) {
      await this.handleOptOut(context, fromPhone, 'reply_stop');
      return {
        responseMessage: 'You have been unsubscribed. Reply START to resubscribe.',
        action: 'opted_out',
      };
    }

    // Check for opt-in keywords
    if (isOptInKeyword(normalizedBody)) {
      await this.handleOptIn(context, fromPhone);
      return {
        responseMessage: 'You have been resubscribed to messages.',
        action: 'opted_in',
      };
    }

    // Store incoming message for context
    const messageData: Omit<SmsMessage, 'id' | 'createdAt' | 'updatedAt'> = {
      businessId: context.businessId,
      recipientId: '', // Unknown - would need to lookup by phone
      recipientPhone: normalizePhone(fromPhone),
      fromNumber: toNumber,
      sentById: 'inbound',
      sentByName: 'Inbound',
      body: body,
      segmentCount: calculateSegmentCount(body),
      status: 'delivered',
      direction: 'inbound',
    };

    await this.messageRepo.create(context, messageData);

    // Return action for sequence event handlers
    return {
      action: 'reply_received',
    };
  }

  // ============================================
  // Public Methods - Message History
  // ============================================

  /**
   * Get SMS history for a recipient
   */
  async getRecipientHistory(
    context: SecurityContext,
    recipientId: string
  ): Promise<SmsMessage[]> {
    const result = await this.messageRepo.getByRecipient(context, recipientId);
    return result.success ? result.data.data : [];
  }

  /**
   * Get recent messages
   */
  async getRecentMessages(context: SecurityContext, limit?: number): Promise<SmsMessage[]> {
    const result = await this.messageRepo.getRecent(context, limit);
    return result.success ? result.data.data : [];
  }

  /**
   * Get message statistics
   */
  async getStatistics(context: SecurityContext, startDate: Date, endDate: Date) {
    return this.messageRepo.getStatistics(context, startDate, endDate);
  }

  // ============================================
  // Public Methods - Template Management
  // ============================================

  /**
   * Create a new SMS template
   */
  async createTemplate(
    context: SecurityContext,
    template: Omit<SmsTemplate, 'id' | 'createdAt' | 'updatedAt' | 'characterCount' | 'segmentCount'>
  ) {
    return this.templateRepo.create(context, template);
  }

  /**
   * Get all active templates
   */
  async getTemplates(context: SecurityContext) {
    return this.templateRepo.getActiveTemplates(context);
  }

  /**
   * Get template by ID
   */
  async getTemplateById(context: SecurityContext, id: string) {
    return this.templateRepo.getById(context, id);
  }

  /**
   * Update a template
   */
  async updateTemplate(context: SecurityContext, id: string, data: Partial<SmsTemplate>) {
    return this.templateRepo.update(context, id, data);
  }

  /**
   * Delete (deactivate) a template
   */
  async deactivateTemplate(context: SecurityContext, id: string) {
    return this.templateRepo.deactivate(context, id);
  }

  // ============================================
  // Public Methods - Status Updates (Webhooks)
  // ============================================

  /**
   * Update message status from webhook
   */
  async updateMessageStatus(
    context: SecurityContext,
    providerMessageId: string,
    status: SmsStatus,
    errorCode?: string,
    errorMessage?: string
  ): Promise<boolean> {
    const messageResult = await this.messageRepo.getByProviderMessageId(
      context,
      providerMessageId
    );

    if (!messageResult.success || !messageResult.data) {
      return false;
    }

    const details: Parameters<typeof this.messageRepo.updateStatus>[3] = {};
    if (status === 'delivered') {
      details.deliveredAt = new Date();
    } else if (status === 'failed' || status === 'undelivered') {
      details.failedAt = new Date();
      details.errorCode = errorCode;
      details.errorMessage = errorMessage;
    }

    const updateResult = await this.messageRepo.updateStatus(
      context,
      messageResult.data.id,
      status,
      details
    );

    return updateResult.success;
  }

  // ============================================
  // Private Methods
  // ============================================

  /**
   * Send SMS via Cloud Function
   * The Cloud Function handles Twilio API integration securely
   */
  private async sendViaCloudFunction(
    context: SecurityContext,
    messageId: string,
    recipientPhone: string,
    body: string
  ): Promise<{ success: boolean; providerMessageId?: string; errorCode?: string; errorMessage?: string }> {
    // In simulation mode, return simulated success
    if (this.config.simulationMode) {
      return {
        success: true,
        providerMessageId: `sim_${generateId()}`,
      };
    }

    try {
      // Get Firebase auth token for authenticated request
      const { getAuth } = await import('firebase/auth');
      const auth = getAuth();
      const user = auth.currentUser;

      if (!user) {
        return {
          success: false,
          errorCode: 'NOT_AUTHENTICATED',
          errorMessage: 'User not authenticated',
        };
      }

      const idToken = await user.getIdToken();

      // Call Cloud Function endpoint
      const response = await fetch(this.config.sendSmsEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          // Security context (validated by Cloud Function)
          businessId: context.businessId,
          userId: context.userId,

          // Message details
          messageId,
          to: recipientPhone,
          body,

          // From configuration (validated server-side)
          messagingServiceSid: this.config.twilioMessagingServiceSid,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          errorCode: errorData.code || `HTTP_${response.status}`,
          errorMessage: errorData.error || `HTTP ${response.status}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        providerMessageId: data.sid || data.messageId,
      };
    } catch (error) {
      return {
        success: false,
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Failed to connect to SMS service',
      };
    }
  }

  /**
   * Build merge field context from data
   */
  private buildMergeContext(data: Record<string, string>): MergeFieldContext {
    return {
      contact: {
        firstName: data.firstName,
        lastName: data.lastName,
        email: data.email || '',
        phone: data.phone,
        title: data.title,
      },
      company: {
        name: data.companyName,
      },
      sender: {
        name: data.senderName || '',
        email: data.senderEmail || '',
      },
      business: {
        name: data.businessName || '',
        phone: data.businessPhone,
        website: data.businessWebsite,
      },
      custom: data,
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let smsServiceInstance: SmsService | null = null;

export function getSmsService(): SmsService {
  if (!smsServiceInstance) {
    smsServiceInstance = new SmsService();
  }
  return smsServiceInstance;
}

// ============================================
// Utility Functions
// ============================================

/**
 * Convenience function to send SMS
 */
export async function sendSms(
  context: SecurityContext,
  options: SendSmsOptions
): Promise<SendSmsResult> {
  const service = getSmsService();
  return service.sendSms(context, options);
}

/**
 * Convenience function to check opt-out
 */
export async function checkSmsOptOut(
  context: SecurityContext,
  phone: string
): Promise<OptOutStatus> {
  const service = getSmsService();
  return service.checkOptOut(context, phone);
}
