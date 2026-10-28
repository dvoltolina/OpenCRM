/**
 * Email Log Repository
 * Audit trail for all email operations
 *
 * HIPAA Compliance:
 * - NO PHI in log entries (IDs only, no email addresses or names)
 * - Immutable logs (no updates or deletes)
 * - Tenant isolation via businessId
 *
 * Storage Path: businesses/{businessId}/email_logs/{logId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { EmailLog, EmailStatus, EmailTemplateType } from '../../types/email';
import { successResult, failedResult, InvalidArgumentError } from '../errors/repository-errors';

// ============================================
// Repository Implementation
// ============================================

export class EmailLogRepository extends BaseRepository<EmailLog> {
  constructor() {
    super({
      collectionName: 'email_logs',
      softDelete: false, // Logs are permanent
    });
  }

  /**
   * Create an email log entry
   * Enhanced with audit logging
   */
  async create(
    context: SecurityContext,
    data: Omit<EmailLog, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<EmailLog>> {
    // Ensure no PHI in failure reason
    const sanitizedData = {
      ...data,
      failureReason: data.failureReason
        ? this.sanitizeErrorMessage(data.failureReason)
        : undefined,
    };

    const result = await super.create(context, sanitizedData, customId);

    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, {
        templateType: data.templateType,
        category: data.category,
        status: data.status,
      });
    }

    return result;
  }

  /**
   * Update is restricted - only status updates allowed for webhook processing
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<EmailLog, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<EmailLog>> {
    // Only allow status-related updates
    const allowedFields = [
      'status',
      'deliveredAt',
      'openedAt',
      'clickedAt',
      'bouncedAt',
      'failureReason',
      'providerMessageId',
    ];

    const updateKeys = Object.keys(data);
    const invalidFields = updateKeys.filter((key) => !allowedFields.includes(key));

    if (invalidFields.length > 0) {
      return failedResult(
        new InvalidArgumentError(
          `Cannot update fields: ${invalidFields.join(', ')}. Email logs are immutable except for status updates.`
        )
      );
    }

    // Sanitize failure reason
    const sanitizedData = {
      ...data,
      failureReason: data.failureReason
        ? this.sanitizeErrorMessage(data.failureReason)
        : data.failureReason,
    };

    return super.update(context, id, sanitizedData);
  }

  /**
   * Delete is blocked - email logs are permanent for audit compliance
   */
  async delete(context: SecurityContext, _id: string): Promise<RepositoryResult<void>> {
    this.ensureSecurityContext(context);
    return failedResult(
      new InvalidArgumentError('Email logs cannot be deleted (audit compliance requirement)')
    );
  }

  /**
   * Update email status (for webhook processing)
   */
  async updateStatus(
    context: SecurityContext,
    id: string,
    status: EmailStatus,
    timestamp?: Date
  ): Promise<RepositoryResult<EmailLog>> {
    const updateData: Partial<EmailLog> = { status };

    // Set appropriate timestamp based on status
    const now = timestamp || new Date();
    switch (status) {
      case 'delivered':
        updateData.deliveredAt = now;
        break;
      case 'opened':
        updateData.openedAt = now;
        break;
      case 'clicked':
        updateData.clickedAt = now;
        break;
      case 'bounced':
      case 'failed':
        updateData.bouncedAt = now;
        break;
    }

    return this.update(context, id, updateData);
  }

  /**
   * Get logs by recipient
   */
  async getByRecipient(
    context: SecurityContext,
    recipientId: string,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      where: [{ field: 'recipientId', operator: '==', value: recipientId }],
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get logs by template type
   */
  async getByTemplateType(
    context: SecurityContext,
    templateType: EmailTemplateType,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      where: [{ field: 'templateType', operator: '==', value: templateType }],
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 100,
    };

    return this.getAll(context, options);
  }

  /**
   * Get logs by status
   */
  async getByStatus(
    context: SecurityContext,
    status: EmailStatus,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: status }],
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 100,
    };

    return this.getAll(context, options);
  }

  /**
   * Get failed emails for retry
   */
  async getFailedEmails(
    context: SecurityContext,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: 'failed' }],
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get bounced emails
   */
  async getBouncedEmails(
    context: SecurityContext,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: 'bounced' }],
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get email by provider message ID (for webhook processing)
   */
  async getByProviderMessageId(
    context: SecurityContext,
    providerMessageId: string
  ): Promise<RepositoryResult<EmailLog | null>> {
    const options: QueryOptions = {
      where: [{ field: 'providerMessageId', operator: '==', value: providerMessageId }],
      limit: 1,
    };

    const result = await this.getAll(context, options);

    if (!result.success) {
      return { success: false, data: null, error: result.error };
    }

    const log = result.data.data[0] || null;
    return successResult(log);
  }

  /**
   * Get recent logs (for dashboard)
   */
  async getRecentLogs(
    context: SecurityContext,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<EmailLog>>> {
    const options: QueryOptions = {
      orderBy: { field: 'sentAt', direction: 'desc' },
      limit: limit || 25,
    };

    return this.getAll(context, options);
  }

  /**
   * Get email statistics for a time period
   */
  async getStatistics(
    context: SecurityContext,
    startDate: Date,
    endDate: Date
  ): Promise<
    RepositoryResult<{
      total: number;
      sent: number;
      delivered: number;
      opened: number;
      clicked: number;
      bounced: number;
      failed: number;
    }>
  > {
    try {
      this.ensureSecurityContext(context);

      // Get all logs in the date range
      const options: QueryOptions = {
        where: [
          { field: 'sentAt', operator: '>=', value: startDate },
          { field: 'sentAt', operator: '<=', value: endDate },
        ],
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      const logs = result.data.data;
      const stats = {
        total: logs.length,
        sent: logs.filter((l) => l.status === 'sent').length,
        delivered: logs.filter((l) => l.status === 'delivered').length,
        opened: logs.filter((l) => l.status === 'opened' || l.openedAt).length,
        clicked: logs.filter((l) => l.status === 'clicked' || l.clickedAt).length,
        bounced: logs.filter((l) => l.status === 'bounced').length,
        failed: logs.filter((l) => l.status === 'failed').length,
      };

      return successResult(stats);
    } catch (error) {
      return failedResult(error, 'Failed to get email statistics');
    }
  }

  /**
   * Sanitize error messages to remove potential PHI
   */
  private sanitizeErrorMessage(message: string): string {
    // Remove potential email addresses
    let sanitized = message.replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[EMAIL]');
    // Remove potential phone numbers
    sanitized = sanitized.replace(/\d{3}[-.\s]?\d{3}[-.\s]?\d{4}/g, '[PHONE]');
    // Remove potential names (common patterns)
    sanitized = sanitized.replace(/for\s+[A-Z][a-z]+\s+[A-Z][a-z]+/g, 'for [RECIPIENT]');
    return sanitized;
  }
}

// ============================================
// Singleton Instance
// ============================================

let emailLogRepositoryInstance: EmailLogRepository | null = null;

export function getEmailLogRepository(): EmailLogRepository {
  if (!emailLogRepositoryInstance) {
    emailLogRepositoryInstance = new EmailLogRepository();
  }
  return emailLogRepositoryInstance;
}
