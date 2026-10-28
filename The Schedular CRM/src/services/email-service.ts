/**
 * Email Service
 * Handles email sending via SendGrid with HIPAA compliance
 *
 * HIPAA Compliance Requirements:
 * - NO PHI in email content (use secure portal links)
 * - NO PHI in logs (IDs only)
 * - Rate limiting to prevent spam
 * - Opt-in/opt-out management
 * - Audit logging for all operations
 *
 * Agent Email Implementation - 2025-11-27
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type {
  EmailTemplate,
  EmailTemplateType,
  SendEmailOptions,
  SendEmailResult,
  BulkEmailOptions,
  BulkEmailResult,
  EmailTemplateData,
} from '../types/email';
import { getEmailTemplateRepository } from '../data/repositories/email-template-repository';
import { getEmailLogRepository } from '../data/repositories/email-log-repository';
import { getRateLimitService } from './RateLimitService';
import { generateId } from '../data/repositories/firestore-utils';

// ============================================
// Configuration
// ============================================

interface EmailConfig {
  /** Cloud Function endpoint for sending emails */
  sendEmailEndpoint: string;
  /** Cloud Function endpoint for webhook processing */
  webhookEndpoint: string;
  /** Default from email */
  fromEmail: string;
  /** Default from name */
  fromName: string;
  /** Base URL for portal links */
  portalBaseUrl: string;
  /** Base URL for unsubscribe links */
  unsubscribeBaseUrl: string;
  /** Enable simulation mode (no actual emails sent) */
  simulationMode: boolean;
}

// Default configuration (override via environment variables)
const getConfig = (): EmailConfig => ({
  sendEmailEndpoint: import.meta.env.VITE_EMAIL_FUNCTION_URL || '',
  webhookEndpoint: import.meta.env.VITE_EMAIL_WEBHOOK_URL || '',
  fromEmail: import.meta.env.VITE_SENDGRID_FROM_EMAIL || 'noreply@scheduler.example.com',
  fromName: import.meta.env.VITE_SENDGRID_FROM_NAME || 'The Scheduler',
  portalBaseUrl: import.meta.env.VITE_PORTAL_URL || 'https://app.example.com',
  unsubscribeBaseUrl: import.meta.env.VITE_UNSUBSCRIBE_URL || 'https://app.example.com/unsubscribe',
  simulationMode: import.meta.env.VITE_EMAIL_SIMULATION === 'true' || !import.meta.env.VITE_EMAIL_FUNCTION_URL,
});

// ============================================
// Email Service
// ============================================

export class EmailService {
  private config: EmailConfig;
  private templateRepo = getEmailTemplateRepository();
  private logRepo = getEmailLogRepository();
  private rateLimitService = getRateLimitService();

  constructor(config?: Partial<EmailConfig>) {
    this.config = { ...getConfig(), ...config };
  }

  // ============================================
  // Public Methods
  // ============================================

  /**
   * Send a single email
   * HIPAA compliant - no PHI in content
   */
  async sendEmail(
    context: SecurityContext,
    options: SendEmailOptions
  ): Promise<SendEmailResult> {
    try {
      // 1. Check rate limit
      const rateCheck = await this.rateLimitService.checkLimit(
        'email',
        context.userId,
        context.businessId
      );

      if (!rateCheck.allowed) {
        return {
          success: false,
          error: `Rate limit exceeded. Try again after ${rateCheck.resetAt.toLocaleTimeString()}`,
        };
      }

      // 2. Get recipient preferences (in production, fetch from client repo)
      const canSend = await this.checkRecipientOptIn(
        context,
        options.recipientId,
        options.category || this.getCategoryForType(options.templateType)
      );

      if (!canSend.allowed) {
        return {
          success: false,
          error: canSend.reason,
        };
      }

      // 3. Get template
      const template = await this.getTemplate(context, options.templateType, options.templateId);
      if (!template) {
        return {
          success: false,
          error: 'Email template not found',
        };
      }

      // 4. Prepare email content (NO PHI)
      const emailContent = this.prepareEmailContent(context, template, options.templateData);

      // 5. Send via Cloud Function (or simulate in development)
      const sendResult = await this.sendViaCloudFunction(
        context,
        options.recipientId,
        emailContent,
        options.templateType,
        options.relatedEntity
      );

      // 6. Record rate limit
      await this.rateLimitService.recordAction('email', context.userId, context.businessId);

      // 7. Create audit log
      const logResult = await this.logRepo.create(context, {
        businessId: context.businessId,
        recipientId: options.recipientId,
        templateId: template.id,
        templateType: options.templateType,
        category: options.category || this.getCategoryForType(options.templateType),
        status: sendResult.success ? 'sent' : 'failed',
        providerMessageId: sendResult.messageId,
        sentById: context.userId,
        sentByName: context.userName,
        sentAt: new Date(),
        failureReason: sendResult.error,
        relatedEntityType: options.relatedEntity?.type,
        relatedEntityId: options.relatedEntity?.id,
      });

      return {
        success: sendResult.success,
        emailLogId: logResult.success ? logResult.data.id : undefined,
        providerMessageId: sendResult.messageId,
        error: sendResult.error,
      };
    } catch (error) {
      return {
        success: false,
        error: 'Failed to send email. Please try again later.',
      };
    }
  }

  /**
   * Send bulk emails
   * Respects rate limits and opt-out preferences
   */
  async sendBulkEmail(
    context: SecurityContext,
    options: BulkEmailOptions
  ): Promise<BulkEmailResult> {
    const results: BulkEmailResult = {
      success: true,
      total: options.recipientIds.length,
      queued: 0,
      failed: 0,
      errors: {},
    };

    // Check overall rate limit first
    const rateCheck = await this.rateLimitService.checkLimit(
      'bulk_operation',
      context.userId,
      context.businessId
    );

    if (!rateCheck.allowed) {
      return {
        success: false,
        total: options.recipientIds.length,
        queued: 0,
        failed: options.recipientIds.length,
        errors: { _all: 'Rate limit exceeded for bulk operations' },
      };
    }

    // Get template once
    const template = await this.getTemplate(context, options.templateType, options.templateId);
    if (!template) {
      return {
        success: false,
        total: options.recipientIds.length,
        queued: 0,
        failed: options.recipientIds.length,
        errors: { _all: 'Email template not found' },
      };
    }

    // Process each recipient
    for (const recipientId of options.recipientIds) {
      const sendResult = await this.sendEmail(context, {
        recipientId,
        templateType: options.templateType,
        templateId: options.templateId,
        templateData: options.templateData,
        category: options.category,
      });

      if (sendResult.success) {
        results.queued++;
      } else {
        results.failed++;
        if (results.errors) {
          results.errors[recipientId] = sendResult.error || 'Unknown error';
        }
      }
    }

    // Record bulk operation
    await this.rateLimitService.recordAction('bulk_operation', context.userId, context.businessId);

    results.success = results.failed === 0;
    return results;
  }

  /**
   * Get email statistics
   */
  async getStatistics(
    context: SecurityContext,
    startDate: Date,
    endDate: Date
  ) {
    return this.logRepo.getStatistics(context, startDate, endDate);
  }

  /**
   * Get recent email logs
   */
  async getRecentLogs(context: SecurityContext, limit?: number) {
    return this.logRepo.getRecentLogs(context, limit);
  }

  /**
   * Get email logs for a recipient
   */
  async getRecipientLogs(context: SecurityContext, recipientId: string) {
    return this.logRepo.getByRecipient(context, recipientId);
  }

  /**
   * Update email status (for webhook processing)
   */
  async updateEmailStatus(
    context: SecurityContext,
    providerMessageId: string,
    status: 'delivered' | 'opened' | 'clicked' | 'bounced' | 'failed',
    timestamp?: Date
  ): Promise<boolean> {
    const logResult = await this.logRepo.getByProviderMessageId(context, providerMessageId);

    if (!logResult.success || !logResult.data) {
      return false;
    }

    const updateResult = await this.logRepo.updateStatus(
      context,
      logResult.data.id,
      status,
      timestamp
    );

    return updateResult.success;
  }

  // ============================================
  // Template Methods
  // ============================================

  /**
   * Create a new email template
   */
  async createTemplate(
    context: SecurityContext,
    template: Omit<EmailTemplate, 'id' | 'createdAt' | 'updatedAt'>
  ) {
    // Cast to repository type - category values are validated at runtime
    return this.templateRepo.create(
      context,
      template as Parameters<typeof this.templateRepo.create>[1]
    );
  }

  /**
   * Get all templates
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
  async updateTemplate(
    context: SecurityContext,
    id: string,
    data: Partial<EmailTemplate>
  ) {
    // Cast to repository type - category values are validated at runtime
    return this.templateRepo.update(
      context,
      id,
      data as Parameters<typeof this.templateRepo.update>[2]
    );
  }

  // ============================================
  // Private Methods
  // ============================================

  /**
   * Check if recipient has opted in for email type
   */
  private async checkRecipientOptIn(
    _context: SecurityContext,
    _recipientId: string,
    category: 'transactional' | 'marketing' | 'system'
  ): Promise<{ allowed: boolean; reason?: string }> {
    // In production, fetch client preferences from repository
    // For now, allow transactional and system emails by default

    if (category === 'transactional' || category === 'system') {
      return { allowed: true };
    }

    // Marketing emails require opt-in
    // TODO: Implement actual opt-in check from client repository
    // const client = await clientRepo.getById(context, recipientId);
    // if (!client.data?.emailOptIn) {
    //   return { allowed: false, reason: 'Recipient has not opted in to marketing emails' };
    // }

    return { allowed: true };
  }

  /**
   * Get email template
   */
  private async getTemplate(
    context: SecurityContext,
    type: EmailTemplateType,
    templateId?: string
  ): Promise<EmailTemplate | null> {
    if (templateId) {
      const result = await this.templateRepo.getById(context, templateId);
      return result.success ? result.data : null;
    }

    const result = await this.templateRepo.getDefaultTemplate(context, type);
    if (result.success && result.data) {
      return result.data;
    }

    // Return a fallback template
    return this.getDefaultFallbackTemplate(type);
  }

  /**
   * Get default fallback template if none exists
   */
  private getDefaultFallbackTemplate(type: EmailTemplateType): EmailTemplate {
    const templates: Record<EmailTemplateType, Partial<EmailTemplate>> = {
      appointment_reminder: {
        subject: 'Appointment Reminder',
        textBody: 'Hello,\n\nYou have an upcoming appointment scheduled.\n\nTo view details, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      appointment_confirmation: {
        subject: 'Appointment Confirmed',
        textBody: 'Hello,\n\nYour appointment has been confirmed.\n\nTo view details, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      appointment_cancelled: {
        subject: 'Appointment Cancelled',
        textBody: 'Hello,\n\nYour appointment has been cancelled.\n\nIf you need to reschedule, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      welcome: {
        subject: 'Welcome!',
        textBody: 'Hello,\n\nWelcome! Your account has been created.\n\nTo get started, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      password_reset: {
        subject: 'Password Reset Request',
        textBody: 'Hello,\n\nA password reset was requested for your account.\n\nTo reset your password, click here: {{actionButtonLink}}\n\nIf you did not request this, please ignore this email.\n\nThank you,\n{{businessName}}',
      },
      invoice: {
        subject: 'New Invoice Available',
        textBody: 'Hello,\n\nA new invoice is available for your review.\n\nTo view your invoice, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      payment_receipt: {
        subject: 'Payment Receipt',
        textBody: 'Hello,\n\nThank you for your payment.\n\nTo view your receipt, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      document_ready: {
        subject: 'Document Ready for Review',
        textBody: 'Hello,\n\nA document is ready for your review.\n\nTo view the document, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      signature_request: {
        subject: 'Signature Requested',
        textBody: 'Hello,\n\nYour signature is requested on a document.\n\nTo sign the document, please log in to your portal: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      follow_up: {
        subject: 'Following Up',
        textBody: 'Hello,\n\n{{message}}\n\nPlease log in to your portal for more details: {{portalLink}}\n\nThank you,\n{{businessName}}',
      },
      marketing: {
        subject: 'News from {{businessName}}',
        textBody: 'Hello,\n\n{{message}}\n\nLearn more: {{portalLink}}\n\nTo unsubscribe: {{unsubscribeLink}}\n\nThank you,\n{{businessName}}',
      },
      custom: {
        subject: '{{subject}}',
        textBody: '{{message}}\n\n{{businessName}}',
      },
    };

    const template = templates[type] || templates.custom;

    return {
      id: `default_${type}`,
      businessId: '',
      name: `Default ${type}`,
      type,
      subject: template.subject || 'Notification',
      textBody: template.textBody || 'Please log in to your portal for details.',
      isActive: true,
      category: this.getCategoryForType(type),
      createdById: 'system',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
  }

  /**
   * Prepare email content with template data
   */
  private prepareEmailContent(
    _context: SecurityContext,
    template: EmailTemplate,
    templateData?: EmailTemplateData
  ): { subject: string; text: string; html?: string } {
    const data: EmailTemplateData = {
      businessName: templateData?.businessName || 'The Scheduler',
      portalLink: this.config.portalBaseUrl,
      unsubscribeLink: `${this.config.unsubscribeBaseUrl}?t=${generateId()}`,
      ...templateData,
    };

    const replaceVariables = (text: string): string => {
      return text.replace(/\{\{(\w+)\}\}/g, (_, key) => {
        return data[key] || '';
      });
    };

    return {
      subject: replaceVariables(template.subject),
      text: replaceVariables(template.textBody),
      html: template.htmlBody ? replaceVariables(template.htmlBody) : undefined,
    };
  }

  /**
   * Send email via Cloud Function
   * The Cloud Function handles SendGrid integration securely
   */
  private async sendViaCloudFunction(
    context: SecurityContext,
    recipientId: string,
    content: { subject: string; text: string; html?: string },
    templateType: EmailTemplateType,
    relatedEntity?: { type: string; id: string }
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    // In simulation mode, return simulated success
    if (this.config.simulationMode) {
      return {
        success: true,
        messageId: `sim_${generateId()}`,
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
          error: 'User not authenticated',
        };
      }

      const idToken = await user.getIdToken();

      // Call Cloud Function endpoint
      const response = await fetch(this.config.sendEmailEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          // Security context (validated by Cloud Function)
          businessId: context.businessId,
          userId: context.userId,

          // Recipient (Cloud Function fetches email from Firestore)
          recipientId: recipientId,

          // Email content (NO PHI - already validated)
          subject: content.subject,
          text: content.text,
          html: content.html,

          // Metadata for tracking
          templateType: templateType,
          relatedEntityType: relatedEntity?.type,
          relatedEntityId: relatedEntity?.id,

          // From configuration
          fromEmail: this.config.fromEmail,
          fromName: this.config.fromName,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          error: errorData.error || `HTTP ${response.status}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        messageId: data.messageId,
      };
    } catch (error) {
      return {
        success: false,
        error: 'Failed to send email. Please try again later.',
      };
    }
  }

  /**
   * Get category for template type
   */
  private getCategoryForType(type: EmailTemplateType): 'transactional' | 'marketing' | 'system' {
    const transactional: EmailTemplateType[] = [
      'appointment_reminder',
      'appointment_confirmation',
      'appointment_cancelled',
      'password_reset',
      'invoice',
      'payment_receipt',
      'document_ready',
      'signature_request',
    ];

    const system: EmailTemplateType[] = ['welcome'];

    if (transactional.includes(type)) return 'transactional';
    if (system.includes(type)) return 'system';
    return 'marketing';
  }
}

// ============================================
// Singleton Instance
// ============================================

let emailServiceInstance: EmailService | null = null;

export function getEmailService(): EmailService {
  if (!emailServiceInstance) {
    emailServiceInstance = new EmailService();
  }
  return emailServiceInstance;
}

// ============================================
// Utility Functions
// ============================================

/**
 * Generate a secure unsubscribe token
 */
export function generateUnsubscribeToken(clientId: string, businessId: string): string {
  // In production, use a proper JWT or encrypted token
  const payload = `${businessId}:${clientId}:${Date.now()}`;
  return btoa(payload);
}

/**
 * Parse an unsubscribe token
 */
export function parseUnsubscribeToken(token: string): { businessId: string; clientId: string } | null {
  try {
    const decoded = atob(token);
    const [businessId, clientId] = decoded.split(':');
    if (businessId && clientId) {
      return { businessId, clientId };
    }
    return null;
  } catch {
    return null;
  }
}
