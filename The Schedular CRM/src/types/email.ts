/**
 * Email Types
 * Type definitions for email service operations
 *
 * HIPAA Compliance:
 * - NO PHI in email content (use secure portal links)
 * - NO PHI in logs (IDs only)
 * - Audit all email operations
 */

import type { BaseEntity } from '../data/repositories/repository-types';

// ============================================
// Email Template Types
// ============================================

/**
 * Email template types for different scenarios
 */
export type EmailTemplateType =
  | 'appointment_reminder'
  | 'appointment_confirmation'
  | 'appointment_cancelled'
  | 'welcome'
  | 'password_reset'
  | 'invoice'
  | 'payment_receipt'
  | 'document_ready'
  | 'signature_request'
  | 'follow_up'
  | 'marketing'
  | 'custom';

/**
 * Email template stored in Firestore
 */
export interface EmailTemplate extends BaseEntity {
  /** Business this template belongs to */
  businessId: string;
  /** Template name (internal identifier) */
  name: string;
  /** Template type */
  type: EmailTemplateType;
  /** Email subject line (NO PHI allowed) */
  subject: string;
  /** Plain text body (NO PHI allowed) */
  textBody: string;
  /** HTML body (NO PHI allowed) */
  htmlBody?: string;
  /** Optional HTML body alias for integration templates */
  bodyHtml?: string;
  /** Optional plain text alias for integration templates */
  bodyText?: string;
  /** SendGrid template ID (if using SendGrid templates) */
  sendGridTemplateId?: string;
  /** Whether this template is active */
  isActive: boolean;
  /** Template category for organization */
  category?: 'transactional' | 'marketing' | 'system' | 'outreach' | 'followup' | 'nurture';
  /** Created by user ID */
  createdById: string;
  /** Last updated by user ID */
  updatedById?: string;
  /** Merge fields available for this template */
  availableMergeFields?: string[];
  /** Usage counter for analytics */
  usageCount?: number;
}

// ============================================
// Email Log Types (Audit)
// ============================================

/**
 * Email delivery status
 */
export type EmailStatus =
  | 'queued'
  | 'sent'
  | 'delivered'
  | 'opened'
  | 'clicked'
  | 'bounced'
  | 'failed'
  | 'blocked'
  | 'spam';

/**
 * Email log entry for audit trail
 * CRITICAL: NO PHI in this record
 */
export interface EmailLog extends BaseEntity {
  /** Business this email belongs to */
  businessId: string;
  /** Recipient client ID (NOT email address) */
  recipientId: string;
  /** Template ID used */
  templateId?: string;
  /** Template type */
  templateType: EmailTemplateType;
  /** Email category */
  category: 'transactional' | 'marketing' | 'system';
  /** Current status */
  status: EmailStatus;
  /** SendGrid message ID for tracking */
  providerMessageId?: string;
  /** Sent by user ID */
  sentById: string;
  /** Sent by user name */
  sentByName: string;
  /** Sent timestamp */
  sentAt: Date;
  /** Delivered timestamp */
  deliveredAt?: Date;
  /** Opened timestamp */
  openedAt?: Date;
  /** Clicked timestamp */
  clickedAt?: Date;
  /** Bounced timestamp */
  bouncedAt?: Date;
  /** Failure reason (sanitized, no PHI) */
  failureReason?: string;
  /** Associated entity type */
  relatedEntityType?: 'deal' | 'lead' | 'appointment' | 'invoice';
  /** Associated entity ID */
  relatedEntityId?: string;
}

// ============================================
// Email Opt-In Types
// ============================================

/**
 * Email preferences for a client
 */
export interface EmailPreferences {
  /** Marketing emails opt-in */
  marketingOptIn: boolean;
  /** Marketing opt-in date */
  marketingOptInDate?: Date;
  /** Marketing opt-out date */
  marketingOptOutDate?: Date;
  /** Transactional emails (always allowed) */
  transactionalAllowed: boolean;
  /** Preferred email frequency */
  preferredFrequency?: 'immediate' | 'daily_digest' | 'weekly_digest';
  /** Unsubscribed from all (emergency stop) */
  unsubscribedAll: boolean;
  /** Unsubscribe date */
  unsubscribedAt?: Date;
}

// ============================================
// Email Service Types
// ============================================

/**
 * Options for sending an email
 */
export interface SendEmailOptions {
  /** Recipient client ID */
  recipientId: string;
  /** Template type to use */
  templateType: EmailTemplateType;
  /** Custom template ID (optional, uses default if not provided) */
  templateId?: string;
  /** Dynamic template data (NO PHI allowed) */
  templateData?: EmailTemplateData;
  /** Override category (defaults based on template type) */
  category?: 'transactional' | 'marketing';
  /** Related entity for tracking */
  relatedEntity?: {
    type: 'deal' | 'lead' | 'appointment' | 'invoice';
    id: string;
  };
  /** Schedule for later (ISO date string) */
  scheduledFor?: string;
}

/**
 * Template data for dynamic content (NO PHI allowed)
 */
export interface EmailTemplateData {
  /** Business name */
  businessName?: string;
  /** Business phone */
  businessPhone?: string;
  /** Business address */
  businessAddress?: string;
  /** Secure portal link */
  portalLink?: string;
  /** Unsubscribe link */
  unsubscribeLink?: string;
  /** Generic message (NO PHI) */
  message?: string;
  /** Action button text */
  actionButtonText?: string;
  /** Action button link */
  actionButtonLink?: string;
  /** Custom fields (NO PHI) */
  [key: string]: string | undefined;
}

/**
 * Result of sending an email
 */
export interface SendEmailResult {
  success: boolean;
  /** Email log ID for tracking */
  emailLogId?: string;
  /** SendGrid message ID */
  providerMessageId?: string;
  /** Error message (sanitized) */
  error?: string;
}

/**
 * Bulk email options
 */
export interface BulkEmailOptions {
  /** Recipient client IDs */
  recipientIds: string[];
  /** Template type */
  templateType: EmailTemplateType;
  /** Template ID */
  templateId?: string;
  /** Shared template data */
  templateData?: EmailTemplateData;
  /** Category */
  category: 'transactional' | 'marketing';
}

/**
 * Bulk email result
 */
export interface BulkEmailResult {
  success: boolean;
  /** Total recipients */
  total: number;
  /** Successfully queued */
  queued: number;
  /** Failed (rate limited, opted out, etc.) */
  failed: number;
  /** Errors by recipient ID */
  errors?: Record<string, string>;
}
