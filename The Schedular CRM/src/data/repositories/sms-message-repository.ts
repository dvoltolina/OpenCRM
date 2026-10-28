/**
 * SMS Message Repository
 * Manages SMS messages in Firestore
 *
 * HIPAA Compliance:
 * - Phone numbers masked in logs (last 4 digits only)
 * - Message content stored for delivery purposes only
 * - Audit logging for all operations
 * - Tenant isolation via businessId
 *
 * Storage Path: businesses/{businessId}/sms_messages/{messageId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { SmsMessage, SmsStatus } from '../../types/sms';
import { successResult, failedResult, ValidationError } from '../errors/repository-errors';

// ============================================
// Repository Implementation
// ============================================

export class SmsMessageRepository extends BaseRepository<SmsMessage> {
  constructor() {
    super({
      collectionName: 'sms_messages',
      softDelete: false, // SMS messages are kept for audit purposes
    });
  }

  /**
   * Validate SMS message data
   * Ensures no PHI in message content
   */
  private validateMessage(data: Partial<SmsMessage>): {
    isValid: boolean;
    errors: Array<{ field: string; message: string }>;
  } {
    const errors: Array<{ field: string; message: string }> = [];

    // Check for potential PHI patterns in body
    if (data.body) {
      const phiPatterns = [
        /\b\d{3}-\d{2}-\d{4}\b/, // SSN pattern
        /\b\d{9}\b/, // SSN without dashes
        /dob|date of birth|born on/i,
        /diagnosis|treatment|medication|prescription/i,
        /medical record|patient id|mrn/i,
      ];

      for (const pattern of phiPatterns) {
        if (pattern.test(data.body)) {
          errors.push({
            field: 'body',
            message: 'Message body may contain PHI - use secure portal links instead',
          });
          break;
        }
      }

      // Check body length
      if (data.body.length > 1600) {
        errors.push({
          field: 'body',
          message: 'Message exceeds maximum length of 1600 characters',
        });
      }
    }

    // Validate phone format
    if (data.recipientPhone) {
      const normalized = data.recipientPhone.replace(/\D/g, '');
      if (normalized.length < 10) {
        errors.push({
          field: 'recipientPhone',
          message: 'Invalid phone number format',
        });
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Create a new SMS message record
   */
  async create(
    context: SecurityContext,
    data: Omit<SmsMessage, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<SmsMessage>> {
    // Validate for PHI
    const validation = this.validateMessage(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Ensure businessId is set
    const messageData = {
      ...data,
      businessId: context.businessId,
    };

    return super.create(context, messageData, customId);
  }

  /**
   * Update SMS message status
   */
  async updateStatus(
    context: SecurityContext,
    id: string,
    status: SmsStatus,
    details?: {
      deliveredAt?: Date;
      failedAt?: Date;
      errorCode?: string;
      errorMessage?: string;
    }
  ): Promise<RepositoryResult<SmsMessage>> {
    const updateData: Partial<SmsMessage> = {
      status,
      ...details,
    };

    return super.update(context, id, updateData);
  }

  /**
   * Get messages by recipient ID
   */
  async getByRecipient(
    context: SecurityContext,
    recipientId: string,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<SmsMessage>>> {
    const options: QueryOptions = {
      where: [{ field: 'recipientId', operator: '==', value: recipientId }],
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get message by provider message ID (Twilio SID)
   */
  async getByProviderMessageId(
    context: SecurityContext,
    providerMessageId: string
  ): Promise<RepositoryResult<SmsMessage | null>> {
    const options: QueryOptions = {
      where: [{ field: 'providerMessageId', operator: '==', value: providerMessageId }],
      limit: 1,
    };

    const result = await this.getAll(context, options);
    if (!result.success) {
      return { success: false, data: null, error: result.error };
    }

    const message = result.data.data[0] || null;
    return successResult(message);
  }

  /**
   * Get messages by related entity
   */
  async getByRelatedEntity(
    context: SecurityContext,
    entityType: string,
    entityId: string,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<SmsMessage>>> {
    const options: QueryOptions = {
      where: [
        { field: 'relatedEntityType', operator: '==', value: entityType },
        { field: 'relatedEntityId', operator: '==', value: entityId },
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get messages by status
   */
  async getByStatus(
    context: SecurityContext,
    status: SmsStatus,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<SmsMessage>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: status }],
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: limit || 100,
    };

    return this.getAll(context, options);
  }

  /**
   * Get recent messages
   */
  async getRecent(
    context: SecurityContext,
    limit?: number
  ): Promise<RepositoryResult<PaginatedResult<SmsMessage>>> {
    const options: QueryOptions = {
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: limit || 50,
    };

    return this.getAll(context, options);
  }

  /**
   * Get message statistics for a date range
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
      failed: number;
      segmentCount: number;
    }>
  > {
    try {
      // Get all messages in date range
      const options: QueryOptions = {
        where: [
          { field: 'createdAt', operator: '>=', value: startDate },
          { field: 'createdAt', operator: '<=', value: endDate },
        ],
        orderBy: { field: 'createdAt', direction: 'desc' },
      };

      const result = await this.getAll(context, options);
      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      const messages = result.data.data;

      // Calculate statistics
      const stats = {
        total: messages.length,
        sent: messages.filter((m) => m.status === 'sent').length,
        delivered: messages.filter((m) => m.status === 'delivered').length,
        failed: messages.filter((m) => m.status === 'failed' || m.status === 'undelivered').length,
        segmentCount: messages.reduce((sum, m) => sum + (m.segmentCount || 1), 0),
      };

      return successResult(stats);
    } catch (error) {
      return failedResult(error, 'Failed to get SMS statistics');
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let smsMessageRepositoryInstance: SmsMessageRepository | null = null;

export function getSmsMessageRepository(): SmsMessageRepository {
  if (!smsMessageRepositoryInstance) {
    smsMessageRepositoryInstance = new SmsMessageRepository();
  }
  return smsMessageRepositoryInstance;
}
