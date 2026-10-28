/**
 * Webhook Event Triggers Service
 * Provides typed methods for triggering webhooks when CRM entities change.
 *
 * Task 6: API & Third-Party Integrations - Webhook Event Triggers
 *
 * HIPAA Compliance:
 * - All payloads are sanitized before triggering webhooks - no PHI transmitted
 * - Entity-specific sanitization removes notes, customFields, and sensitive data
 * - Follows data minimization principles
 *
 * Security:
 * - All operations require SecurityContext for multi-tenant isolation
 * - Sanitization prevents accidental PHI exposure
 * - Timestamps are ISO8601 strings for consistency
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { Lead } from '../types/leads';
import type { Deal } from '../types/deals';
import type { Client, SalesActivity } from '../types/models';
import type { SequenceEnrollment } from '../types/sequences';
import type { EmailMessage, EmailTrackingEvent } from '../types/email-integration';
import { getWebhookEndpointService } from './webhook-endpoint-service';

// ============================================
// Types
// ============================================

/**
 * Change tracking for update events
 */
export interface EntityChange {
  field: string;
  previousValue?: unknown;
  newValue?: unknown;
}

/**
 * Form submission data (generic structure)
 */
export interface FormSubmission {
  formId: string;
  formName?: string;
  submittedAt: Date;
  submitterEmail?: string;
  submitterName?: string;
  fields: Record<string, unknown>;
}

// ============================================
// Service Implementation
// ============================================

export class WebhookEventTriggers {
  private webhookService = getWebhookEndpointService();

  // ============================================
  // Lead Events
  // ============================================

  /**
   * Trigger webhook when a lead is created
   */
  async onLeadCreated(context: SecurityContext, lead: Lead): Promise<void> {
    await this.webhookService.triggerEvent(context, 'lead.created', {
      event: 'lead.created',
      timestamp: new Date().toISOString(),
      data: this.sanitizeLead(lead),
    });
  }

  /**
   * Trigger webhook when a lead is updated
   */
  async onLeadUpdated(
    context: SecurityContext,
    lead: Lead,
    changes: EntityChange[]
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'lead.updated', {
      event: 'lead.updated',
      timestamp: new Date().toISOString(),
      data: this.sanitizeLead(lead),
      changes: changes.map((c) => c.field), // Only send field names, not values
    });
  }

  /**
   * Trigger webhook when a lead is converted to a client
   */
  async onLeadConverted(
    context: SecurityContext,
    lead: Lead,
    clientId: string,
    dealId?: string
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'lead.converted', {
      event: 'lead.converted',
      timestamp: new Date().toISOString(),
      data: this.sanitizeLead(lead),
      convertedToClientId: clientId,
      convertedToDealId: dealId,
    });
  }

  // ============================================
  // Deal Events
  // ============================================

  /**
   * Trigger webhook when a deal is created
   */
  async onDealCreated(context: SecurityContext, deal: Deal): Promise<void> {
    await this.webhookService.triggerEvent(context, 'deal.created', {
      event: 'deal.created',
      timestamp: new Date().toISOString(),
      data: this.sanitizeDeal(deal),
    });
  }

  /**
   * Trigger webhook when a deal is updated
   */
  async onDealUpdated(
    context: SecurityContext,
    deal: Deal,
    changes: EntityChange[]
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'deal.updated', {
      event: 'deal.updated',
      timestamp: new Date().toISOString(),
      data: this.sanitizeDeal(deal),
      changes: changes.map((c) => c.field),
    });
  }

  /**
   * Trigger webhook when a deal stage changes
   */
  async onDealStageChanged(
    context: SecurityContext,
    deal: Deal,
    previousStage: string
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'deal.stage_changed', {
      event: 'deal.stage_changed',
      timestamp: new Date().toISOString(),
      data: this.sanitizeDeal(deal),
      previousStage,
      newStage: deal.stageId,
    });

    // Also trigger won/lost events if applicable
    if (deal.status === 'won') {
      await this.onDealWon(context, deal);
    } else if (deal.status === 'lost') {
      await this.onDealLost(context, deal);
    }
  }

  /**
   * Trigger webhook when a deal is won
   */
  async onDealWon(context: SecurityContext, deal: Deal): Promise<void> {
    await this.webhookService.triggerEvent(context, 'deal.won', {
      event: 'deal.won',
      timestamp: new Date().toISOString(),
      data: this.sanitizeDeal(deal),
    });
  }

  /**
   * Trigger webhook when a deal is lost
   */
  async onDealLost(context: SecurityContext, deal: Deal): Promise<void> {
    await this.webhookService.triggerEvent(context, 'deal.lost', {
      event: 'deal.lost',
      timestamp: new Date().toISOString(),
      data: this.sanitizeDeal(deal),
    });
  }

  // ============================================
  // Contact Events
  // ============================================

  /**
   * Trigger webhook when a contact is created
   */
  async onContactCreated(
    context: SecurityContext,
    contact: Client
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'contact.created', {
      event: 'contact.created',
      timestamp: new Date().toISOString(),
      data: this.sanitizeContact(contact),
    });
  }

  /**
   * Trigger webhook when a contact is updated
   */
  async onContactUpdated(
    context: SecurityContext,
    contact: Client,
    changes: EntityChange[]
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'contact.updated', {
      event: 'contact.updated',
      timestamp: new Date().toISOString(),
      data: this.sanitizeContact(contact),
      changes: changes.map((c) => c.field),
    });
  }

  // ============================================
  // Task Events
  // ============================================

  /**
   * Trigger webhook when a task is created
   */
  async onTaskCreated(
    context: SecurityContext,
    task: SalesActivity
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'task.created', {
      event: 'task.created',
      timestamp: new Date().toISOString(),
      data: this.sanitizeTask(task),
    });
  }

  /**
   * Trigger webhook when a task is completed
   */
  async onTaskCompleted(
    context: SecurityContext,
    task: SalesActivity
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'task.completed', {
      event: 'task.completed',
      timestamp: new Date().toISOString(),
      data: this.sanitizeTask(task),
    });
  }

  // ============================================
  // Email Events
  // ============================================

  /**
   * Trigger webhook when an email is sent
   */
  async onEmailSent(
    context: SecurityContext,
    email: EmailMessage
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'email.sent', {
      event: 'email.sent',
      timestamp: new Date().toISOString(),
      data: this.sanitizeEmail(email),
    });
  }

  /**
   * Trigger webhook when an email is opened
   */
  async onEmailOpened(
    context: SecurityContext,
    trackingEvent: EmailTrackingEvent
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'email.opened', {
      event: 'email.opened',
      timestamp: new Date().toISOString(),
      data: {
        messageId: trackingEvent.messageId,
        trackingId: trackingEvent.trackingId,
        occurredAt: trackingEvent.occurredAt.toISOString(),
      },
    });
  }

  // ============================================
  // Sequence Events
  // ============================================

  /**
   * Trigger webhook when a contact is enrolled in a sequence
   */
  async onSequenceEnrolled(
    context: SecurityContext,
    enrollment: SequenceEnrollment
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'sequence.enrolled', {
      event: 'sequence.enrolled',
      timestamp: new Date().toISOString(),
      data: this.sanitizeEnrollment(enrollment),
    });
  }

  /**
   * Trigger webhook when a sequence enrollment is completed
   */
  async onSequenceCompleted(
    context: SecurityContext,
    enrollment: SequenceEnrollment
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'sequence.completed', {
      event: 'sequence.completed',
      timestamp: new Date().toISOString(),
      data: this.sanitizeEnrollment(enrollment),
    });
  }

  // ============================================
  // Form Events
  // ============================================

  /**
   * Trigger webhook when a web form is submitted
   */
  async onFormSubmitted(
    context: SecurityContext,
    formId: string,
    submission: FormSubmission
  ): Promise<void> {
    await this.webhookService.triggerEvent(context, 'form.submitted', {
      event: 'form.submitted',
      timestamp: new Date().toISOString(),
      data: {
        formId,
        formName: submission.formName,
        submittedAt: submission.submittedAt.toISOString(),
        // Do not include field data - may contain PHI
        fieldCount: Object.keys(submission.fields).length,
      },
    });
  }

  // ============================================
  // HIPAA Sanitization Methods
  // ============================================

  /**
   * Sanitize lead data - remove PHI fields
   * HIPAA: Remove notes, customFields which may contain PHI
   */
  private sanitizeLead(lead: Lead): Record<string, unknown> {
    const {
      notes,
      customFields,
      phone: _phone,
      email: _email,
      firstName: _firstName,
      lastName: _lastName,
      ...sanitized
    } = lead;

    return {
      ...sanitized,
      // Redact PII but keep structure for API consumers
      firstName: '[REDACTED]',
      lastName: '[REDACTED]',
      email: '[REDACTED]',
      phone: '[REDACTED]',
      hasNotes: !!notes,
      customFieldCount: customFields ? Object.keys(customFields).length : 0,
    };
  }

  /**
   * Sanitize deal data - remove sensitive details
   * HIPAA: Remove notes, wonLostReason which may contain PHI
   */
  private sanitizeDeal(deal: Deal): Record<string, unknown> {
    const {
      notes,
      customFields,
      wonLostReason,
      clientName: _clientName,
      clientEmail: _clientEmail,
      companyName: _companyName,
      ...sanitized
    } = deal;

    return {
      ...sanitized,
      // Redact identifying info (HIPAA: emails and names are PHI)
      clientName: deal.clientId ? '[REDACTED]' : undefined,
      clientEmail: deal.clientId ? '[REDACTED]' : undefined,
      companyName: deal.companyId ? '[REDACTED]' : undefined,
      hasNotes: !!notes,
      customFieldCount: customFields ? Object.keys(customFields).length : 0,
      hasWonLostReason: !!wonLostReason,
    };
  }

  /**
   * Sanitize contact data - remove PHI
   * HIPAA: Remove crmNotes, address, and other sensitive fields
   */
  private sanitizeContact(contact: Client): Record<string, unknown> {
    const {
      crmNotes,
      customFields,
      address,
      phone: _phone,
      email: _email,
      firstName: _firstName,
      lastName: _lastName,
      userId,
      ...sanitized
    } = contact;

    return {
      ...sanitized,
      // Redact PII
      firstName: '[REDACTED]',
      lastName: '[REDACTED]',
      email: '[REDACTED]',
      phone: '[REDACTED]',
      hasAddress: !!address,
      hasCrmNotes: !!crmNotes,
      customFieldCount: customFields ? Object.keys(customFields).length : 0,
      hasUserId: !!userId,
    };
  }

  /**
   * Sanitize task/activity data - remove descriptions
   * HIPAA: Remove description which may contain PHI
   */
  private sanitizeTask(task: SalesActivity): Record<string, unknown> {
    const { description, ...sanitized } = task;

    return {
      ...sanitized,
      hasDescription: !!description,
    };
  }

  /**
   * Sanitize email message - remove content
   * HIPAA: Remove message body and participant details
   */
  private sanitizeEmail(email: EmailMessage): Record<string, unknown> {
    const {
      bodyText,
      bodyHtml,
      snippet: _snippet,
      fromEmail: _fromEmail,
      fromName: _fromName,
      toEmails,
      ccEmails,
      bccEmails,
      ...sanitized
    } = email;

    return {
      ...sanitized,
      // Redact content and participants
      fromEmail: '[REDACTED]',
      fromName: '[REDACTED]',
      recipientCount: toEmails.length,
      ccCount: ccEmails?.length || 0,
      bccCount: bccEmails?.length || 0,
      hasBody: !!(bodyText || bodyHtml),
    };
  }

  /**
   * Sanitize sequence enrollment - remove entity details
   * HIPAA: Remove entityName, entityEmail
   */
  private sanitizeEnrollment(
    enrollment: SequenceEnrollment
  ): Record<string, unknown> {
    const {
      entityName,
      entityEmail,
      entityPhone,
      ...sanitized
    } = enrollment;

    return {
      ...sanitized,
      // Redact entity PII
      hasEntityName: !!entityName,
      hasEntityEmail: !!entityEmail,
      hasEntityPhone: !!entityPhone,
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let webhookEventTriggers: WebhookEventTriggers | null = null;

export function getWebhookEventTriggers(): WebhookEventTriggers {
  if (!webhookEventTriggers) {
    webhookEventTriggers = new WebhookEventTriggers();
  }
  return webhookEventTriggers;
}
