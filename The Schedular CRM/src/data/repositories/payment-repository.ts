/**
 * Payment Repository
 * Manages payment records in Firestore
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 * PCI Compliance: NEVER stores raw card data - only tokenized references
 * Financial Compliance: ALL payment operations are audit logged
 *
 * Agent Payment Migration Implementation
 * Date: 2025-11-27
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { Payment } from '../../types/models';
import { successResult, failedResult } from '../errors/repository-errors';

/**
 * Payment-specific query options
 */
export interface PaymentQueryOptions extends QueryOptions {
  /** Filter by client ID */
  clientId?: string;
  /** Filter by deal ID */
  dealId?: string;
  /** Filter by status */
  status?: Payment['status'];
  /** Filter by payment method */
  method?: Payment['method'];
}

/**
 * PaymentRepository
 * Manages payment records with HIPAA and PCI compliance
 *
 * Security Notes:
 * - All operations validated via SecurityContext
 * - ALL payment operations are audit logged (financial compliance)
 * - NO PHI (clientName) in logs - only IDs
 * - Payments are generally immutable after creation (status updates only)
 */
export class PaymentRepository extends BaseRepository<Payment> {
  constructor() {
    super({
      collectionName: 'payments',
      softDelete: false, // Payments are immutable - never deleted
    });
  }

  /**
   * Get payment history for a client
   * Returns payments ordered by most recent first
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @param limit - Maximum number of payments to return (default: 50)
   * @returns Paginated payments
   */
  async getByClient(
    context: SecurityContext,
    clientId: string,
    limit = 50
  ): Promise<RepositoryResult<PaginatedResult<Payment>>> {
    try {
      this.ensureSecurityContext(context);

      // HIPAA: Log only the action and IDs, NOT clientName
      await this.logAudit(context, 'list', null, {
        queryType: 'getByClient',
        clientId, // ID only - not PHI
        limit,
      });

      return await this.getAll(context, {
        where: [{ field: 'clientId', operator: '==', value: clientId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit,
      });
    } catch (error) {
      return failedResult(error, 'Failed to get payments for client');
    }
  }

  /**
   * Get payment history for a deal
   * Returns payments ordered by most recent first
   *
   * @param context - Security context
   * @param dealId - Deal ID
   * @param limit - Maximum number of payments to return (default: 50)
   * @returns Paginated payments
   */
  async getByDeal(
    context: SecurityContext,
    dealId: string,
    limit = 50
  ): Promise<RepositoryResult<PaginatedResult<Payment>>> {
    try {
      this.ensureSecurityContext(context);

      // HIPAA: Log only the action and IDs
      await this.logAudit(context, 'list', null, {
        queryType: 'getByDeal',
        dealId, // ID only
        limit,
      });

      return await this.getAll(context, {
        where: [{ field: 'dealId', operator: '==', value: dealId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit,
      });
    } catch (error) {
      return failedResult(error, 'Failed to get payments for deal');
    }
  }

  /**
   * Get payment history with flexible filtering
   *
   * @param context - Security context
   * @param options - Query options
   * @returns Paginated payments
   */
  async getHistory(
    context: SecurityContext,
    options: PaymentQueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Payment>>> {
    try {
      this.ensureSecurityContext(context);

      const queryOptions: QueryOptions = {
        ...options,
        where: [...(options.where || [])],
      };

      // Add client filter
      if (options.clientId) {
        queryOptions.where!.push({
          field: 'clientId',
          operator: '==',
          value: options.clientId,
        });
      }

      // Add deal filter
      if (options.dealId) {
        queryOptions.where!.push({
          field: 'dealId',
          operator: '==',
          value: options.dealId,
        });
      }

      // Add status filter
      if (options.status) {
        queryOptions.where!.push({
          field: 'status',
          operator: '==',
          value: options.status,
        });
      }

      // Add method filter
      if (options.method) {
        queryOptions.where!.push({
          field: 'method',
          operator: '==',
          value: options.method,
        });
      }

      // Default ordering by most recent
      if (!queryOptions.orderBy) {
        queryOptions.orderBy = { field: 'createdAt', direction: 'desc' };
      }

      // HIPAA: Log query without PHI
      await this.logAudit(context, 'list', null, {
        queryType: 'getHistory',
        filters: {
          hasClientFilter: !!options.clientId,
          hasDealFilter: !!options.dealId,
          status: options.status,
          method: options.method,
        },
      });

      return await this.getAll(context, queryOptions);
    } catch (error) {
      return failedResult(error, 'Failed to get payment history');
    }
  }

  /**
   * Get payment by provider ID (e.g., Stripe charge ID)
   * Used for webhook processing to find existing payment records
   *
   * @param context - Security context
   * @param providerId - Payment provider ID (e.g., ch_xxx from Stripe)
   * @returns Payment or null if not found
   */
  async getByProviderId(
    context: SecurityContext,
    providerId: string
  ): Promise<RepositoryResult<Payment | null>> {
    try {
      this.ensureSecurityContext(context);

      const result = await this.getAll(context, {
        where: [{ field: 'providerId', operator: '==', value: providerId }],
        limit: 1,
      });

      if (!result.success) {
        return result as RepositoryResult<Payment | null>;
      }

      const payment = result.data.data[0] || null;

      // HIPAA: Log lookup by providerId (not PHI)
      await this.logAudit(context, 'read', payment?.id || null, {
        queryType: 'getByProviderId',
        found: !!payment,
      });

      return successResult(payment);
    } catch (error) {
      return failedResult(error, 'Failed to get payment by provider ID');
    }
  }

  /**
   * Update payment status
   * Used for webhook processing when payment status changes
   *
   * NOTE: Payments are generally immutable - only status updates allowed
   *
   * @param context - Security context
   * @param id - Payment ID
   * @param status - New payment status
   * @returns Updated payment
   */
  async updateStatus(
    context: SecurityContext,
    id: string,
    status: Payment['status']
  ): Promise<RepositoryResult<Payment>> {
    try {
      this.ensureSecurityContext(context);

      // HIPAA: Audit the status change (critical for financial compliance)
      await this.logAudit(context, 'update', id, {
        field: 'status',
        newStatus: status,
      });

      return await this.update(context, id, { status });
    } catch (error) {
      return failedResult(error, 'Failed to update payment status');
    }
  }

  /**
   * Override create to enforce audit logging for ALL payment creations
   * Financial compliance: ALL payment operations MUST be audited
   */
  async create(
    context: SecurityContext,
    data: Omit<Payment, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Payment>> {
    try {
      this.ensureSecurityContext(context);

      // Create the payment
      const result = await super.create(context, data, customId);

      if (result.success) {
        // CRITICAL: Audit payment creation (financial compliance)
        // Log only metadata - NO PHI (clientName, dealTitle)
        await this.logAudit(context, 'create', result.data.id, {
          amountCents: data.amountCents,
          currency: data.currency,
          status: data.status,
          method: data.method,
          clientId: data.clientId, // ID only - not PHI
          dealId: data.dealId, // ID only - not PHI
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to create payment');
    }
  }

  /**
   * Override delete to prevent payment deletion
   * Payments are immutable - cannot be deleted (financial compliance)
   */
  async delete(_context: SecurityContext, _id: string): Promise<RepositoryResult<void>> {
    return failedResult(
      new Error('Payments cannot be deleted. Use status updates or refunds instead.'),
      'Payment deletion not allowed'
    );
  }
}

// ============================================
// Singleton Export
// ============================================

let paymentRepositoryInstance: PaymentRepository | null = null;

export function getPaymentRepository(): PaymentRepository {
  if (!paymentRepositoryInstance) {
    paymentRepositoryInstance = new PaymentRepository();
  }
  return paymentRepositoryInstance;
}
