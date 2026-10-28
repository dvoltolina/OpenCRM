/**
 * Payment Service
 * Wrapper around Scheduler payments collection and Cloud Function
 * Handles payment processing, history retrieval, and card management
 *
 * Agent Payment Migration Implementation
 * Date: 2025-11-27
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 * PCI Compliance: NEVER stores raw card details - only tokenized data
 * Financial Compliance: All payment operations are audit logged via repositories
 *
 * Migration Notes:
 * - Migrated from direct Firestore access to repository pattern
 * - All operations now use PaymentRepository and PaymentMethodRepository
 * - SecurityContext validation enforced at repository layer
 * - Audit logging automatic via repositories
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { Payment, PaymentMethodCard } from '../types/models';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getPaymentRepository } from '../data/repositories/payment-repository';
import { getPaymentMethodRepository } from '../data/repositories/payment-method-repository';

// ============================================
// Types
// ============================================

/**
 * Data required to charge a client
 */
export interface ChargeClientRequest {
  /** Amount in cents */
  amountCents: number;
  /** Currency code (e.g., 'USD') */
  currency: string;
  /** Client being charged */
  clientId: string;
  clientName: string;
  /** Optional deal to associate with payment */
  dealId?: string;
  dealTitle?: string;
  /** Payment method - 'card' or 'new_card' or 'cash', etc. */
  method: 'card' | 'new_card' | 'cash' | 'check' | 'bank_transfer' | 'other';
  /** For saved cards - the payment method ID */
  paymentMethodId?: string;
  /** For new cards - tokenized card data from payment provider */
  newCardToken?: string;
  /** Optional description */
  description?: string;
  /** Optional notes */
  notes?: string;
  /** Whether to save the card for future use */
  saveCard?: boolean;
}

/**
 * Result of a charge operation
 */
export interface ChargeResult {
  success: boolean;
  payment?: Payment;
  error?: string;
}

/**
 * Payment history query options
 */
export interface PaymentHistoryOptions {
  /** Filter by client */
  clientId?: string;
  /** Filter by deal */
  dealId?: string;
  /** Maximum number of payments to return */
  limit?: number;
}

// ============================================
// Payment Service
// ============================================

/**
 * PaymentService
 * Manages payment processing and history using repository pattern
 *
 * TODO: Production Implementation
 * In production, payment processing would be handled by a Stripe Cloud Function:
 * 1. Frontend calls Cloud Function endpoint with payment intent
 * 2. Cloud Function processes payment via Stripe API
 * 3. Cloud Function creates payment record via PaymentRepository
 * 4. Stripe webhooks update payment status via PaymentRepository.updateStatus()
 *
 * For now, this simulates the payment flow for development/testing.
 */
export class PaymentService {
  private paymentRepo = getPaymentRepository();
  private paymentMethodRepo = getPaymentMethodRepository();

  /**
   * Charge a client
   *
   * TODO: Replace simulation with Cloud Function call in production
   * Production flow: POST /api/processPayment -> Stripe -> Webhook -> Repository
   */
  async chargeClient(
    context: SecurityContext,
    request: ChargeClientRequest
  ): Promise<ChargeResult> {
    // Validate request
    const validationError = this.validateChargeRequest(request);
    if (validationError) {
      return {
        success: false,
        error: validationError,
      };
    }

    try {
      // TODO: Production - Call Cloud Function instead of simulation
      // const response = await callCloudFunction('processPayment', {
      //   ...request,
      //   businessId: context.businessId,
      // });

      // Simulate payment processing
      const paymentResult = await this.simulatePaymentProcessing(context, request);

      if (!paymentResult.success) {
        return paymentResult;
      }

      // If payment succeeded and deal is linked, optionally update deal status
      if (request.dealId) {
        await this.updateDealAfterPayment(context, request.dealId);
      }

      return paymentResult;
    } catch (error) {
      // HIPAA: Don't log error details to console - use audit logging instead
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to process payment',
      };
    }
  }

  /**
   * Get payment history
   * Retrieves payments filtered by client or deal
   */
  async getPaymentHistory(
    context: SecurityContext,
    options: PaymentHistoryOptions = {}
  ): Promise<Payment[]> {
    try {
      // Use repository for all queries
      const result = await this.paymentRepo.getHistory(context, {
        clientId: options.clientId,
        dealId: options.dealId,
        limit: options.limit || 50,
      });

      if (!result.success) {
        // HIPAA: Don't log error details
        return [];
      }

      return result.data.data;
    } catch (error) {
      // HIPAA: Don't log error details to console
      return [];
    }
  }

  /**
   * Get a single payment by ID
   */
  async getPaymentById(
    context: SecurityContext,
    paymentId: string
  ): Promise<Payment | null> {
    try {
      const result = await this.paymentRepo.getById(context, paymentId);

      if (!result.success) {
        // HIPAA: Don't log error details
        return null;
      }

      return result.data;
    } catch (error) {
      // HIPAA: Don't log error details to console
      return null;
    }
  }

  /**
   * Get saved payment methods for a client
   */
  async getPaymentMethods(
    context: SecurityContext,
    clientId: string
  ): Promise<PaymentMethodCard[]> {
    try {
      const result = await this.paymentMethodRepo.getByClient(context, clientId);

      if (!result.success) {
        // HIPAA: Don't log error details
        return [];
      }

      return result.data;
    } catch (error) {
      // HIPAA: Don't log error details to console
      return [];
    }
  }

  // ============================================
  // Private Helper Methods
  // ============================================

  /**
   * Validate charge request
   */
  private validateChargeRequest(request: ChargeClientRequest): string | null {
    if (request.amountCents <= 0) {
      return 'Amount must be greater than 0';
    }

    if (!request.currency) {
      return 'Currency is required';
    }

    if (!request.clientId) {
      return 'Client ID is required';
    }

    if (!request.clientName) {
      return 'Client name is required';
    }

    if (!request.method) {
      return 'Payment method is required';
    }

    // For card payments, require either saved card or new card token
    if (request.method === 'card' && !request.paymentMethodId) {
      return 'Payment method ID is required for card payments';
    }

    if (request.method === 'new_card' && !request.newCardToken) {
      return 'Card token is required for new card payments';
    }

    return null;
  }

  /**
   * Simulate payment processing (mock for Cloud Function)
   *
   * TODO: Production Implementation
   * In production, this would be handled by a Stripe Cloud Function:
   * - Validate payment intent
   * - Process via Stripe API
   * - Create payment via PaymentRepository
   * - Return success/failure
   */
  private async simulatePaymentProcessing(
    context: SecurityContext,
    request: ChargeClientRequest
  ): Promise<ChargeResult> {
    try {
      // Simulate Stripe charge creation
      const providerId = `ch_mock_${Date.now()}`;

      // Extract data from request
      const {
        amountCents,
        currency,
        description,
        clientId,
        clientName,
        dealId,
        dealTitle,
      } = request;

      // Create payment record via repository
      const paymentData: Omit<Payment, 'id' | 'createdAt' | 'updatedAt'> = {
        amountCents,
        currency,
        status: 'completed',
        method: request.method === 'cash' ? 'cash' : request.method === 'check' ? 'check' : 'card',
        type: 'full', // Default type aligned with shared contract
        description,
        clientId,
        clientName,
        dealId,
        dealTitle,
        providerId,
        receiptUrl: `https://receipts.example.com/${providerId}`, // Mock receipt URL
        last4: '4242', // Mock last4
        cardBrand: 'visa', // Mock brand
        processedById: context.userId,
        processedByName: context.userName,
        processedAt: new Date(),
      };

      const result = await this.paymentRepo.create(context, paymentData);

      if (!result.success) {
        return {
          success: false,
          error: result.error?.message || 'Failed to create payment',
        };
      }

      // If saveCard is true and this is a new card, save the payment method
      if (request.saveCard && request.method === 'new_card' && request.newCardToken) {
        await this.savePaymentMethod(context, request.clientId, request.newCardToken);
      }

      return {
        success: true,
        payment: result.data,
      };
    } catch (error) {
      // HIPAA: Don't log error details to console
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create payment',
      };
    }
  }

  /**
   * Save a payment method for future use
   *
   * TODO: Production Implementation
   * In production, this would be handled by a Stripe Cloud Function:
   * - Attach payment method to Stripe customer
   * - Store payment method reference via PaymentMethodRepository
   */
  private async savePaymentMethod(
    context: SecurityContext,
    clientId: string,
    _cardToken: string
  ): Promise<void> {
    try {
      // TODO: Production - Call Stripe to attach payment method
      // const stripeMethod = await stripe.paymentMethods.attach(cardToken, {
      //   customer: stripeCustomerId,
      // });

      const methodData: Omit<PaymentMethodCard, 'id' | 'createdAt' | 'updatedAt'> = {
        providerId: `pm_mock_${Date.now()}`,
        last4: '4242',
        brand: 'visa',
        expMonth: 12,
        expYear: new Date().getFullYear() + 2,
        isDefault: false,
      };

      await this.paymentMethodRepo.createForClient(context, clientId, methodData);
    } catch (error) {
      // HIPAA: Don't log error details to console
      // Error is non-critical - payment succeeded even if card save failed
    }
  }

  /**
   * Update deal after successful payment
   * Optionally marks deal as won if full amount is paid
   */
  private async updateDealAfterPayment(
    context: SecurityContext,
    dealId: string
  ): Promise<void> {
    try {
      const dealRepo = getDealRepository();
      const dealResult = await dealRepo.getById(context, dealId);

      if (dealResult.success) {
        // TODO: Production Enhancement
        // If deal is still open, optionally:
        // - Update a "amountPaid" field
        // - Mark as won if fully paid
        // - Add a note about the payment
        // Payment recorded successfully - audit logged automatically by repository
      }
    } catch (error) {
      // HIPAA: Don't log error details to console
      // Error is non-critical - payment succeeded even if deal update failed
    }
  }
}

// ============================================
// Singleton Export
// ============================================

let paymentServiceInstance: PaymentService | null = null;

export function getPaymentService(): PaymentService {
  if (!paymentServiceInstance) {
    paymentServiceInstance = new PaymentService();
  }
  return paymentServiceInstance;
}
