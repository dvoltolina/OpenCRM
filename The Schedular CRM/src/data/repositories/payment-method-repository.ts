/**
 * Payment Method Repository
 * Manages saved payment methods (cards) per client
 *
 * PCI Compliance: NEVER stores raw card data - only tokens/references from payment provider
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 *
 * Agent Payment Migration Implementation
 * Date: 2025-11-27
 */

import { collection, query, where, orderBy, getDocs } from 'firebase/firestore';
import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
} from './repository-types';
import type { PaymentMethodCard } from '../../types/models';
import { successResult, failedResult, InvalidArgumentError } from '../errors/repository-errors';
import { documentsToEntities } from './firestore-utils';

/**
 * PaymentMethodRepository
 * Manages saved payment methods per client
 *
 * CRITICAL PCI Compliance Notes:
 * - NEVER store raw card numbers
 * - NEVER store CVV/CVC codes
 * - ONLY store tokenized references from payment provider (e.g., Stripe pm_xxx)
 * - Store only last4, brand, expiration for display purposes
 *
 * Data Path: businesses/{businessId}/clients/{clientId}/paymentMethods/{methodId}
 *
 * Security Notes:
 * - All operations validated via SecurityContext
 * - Payment methods are scoped per client (sub-collection)
 * - Audit logging for create/delete operations (financial compliance)
 */
export class PaymentMethodRepository extends BaseRepository<PaymentMethodCard> {
  constructor() {
    super({
      collectionName: 'paymentMethods',
      softDelete: false, // Payment methods are hard deleted when removed
    });
  }

  /**
   * Override getCollectionPath to use client sub-collection
   * Path: businesses/{businessId}/clients/{clientId}/paymentMethods
   */
  protected getCollectionPath(context: SecurityContext, clientId?: string): string {
    this.ensureSecurityContext(context);

    if (!clientId) {
      throw new InvalidArgumentError('clientId is required for payment methods');
    }

    return `businesses/${context.businessId}/clients/${clientId}/paymentMethods`;
  }

  /**
   * Get collection reference for client's payment methods
   */
  protected getClientCollectionRef(context: SecurityContext, clientId: string) {
    const path = this.getCollectionPath(context, clientId);
    return collection(this.db, path);
  }

  /**
   * Get all payment methods for a client
   * Returns methods ordered by most recently created first
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @returns Array of payment methods
   */
  async getByClient(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<PaymentMethodCard[]>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      const collectionRef = this.getClientCollectionRef(context, clientId);
      const q = query(collectionRef, orderBy('createdAt', 'desc'));

      const snapshot = await getDocs(q);
      const methods = documentsToEntities<PaymentMethodCard>(snapshot.docs);

      // HIPAA: Log access (financial compliance)
      await this.logAudit(context, 'list', null, {
        queryType: 'getByClient',
        clientId, // ID only - not PHI
        count: methods.length,
      });

      return successResult(methods);
    } catch (error) {
      return failedResult(error, 'Failed to get payment methods');
    }
  }

  /**
   * Get default payment method for a client
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @returns Default payment method or null
   */
  async getDefault(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<PaymentMethodCard | null>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      const collectionRef = this.getClientCollectionRef(context, clientId);
      const q = query(
        collectionRef,
        where('isDefault', '==', true),
        orderBy('createdAt', 'desc')
      );

      const snapshot = await getDocs(q);
      const methods = documentsToEntities<PaymentMethodCard>(snapshot.docs);
      const defaultMethod = methods[0] || null;

      // HIPAA: Log access
      await this.logAudit(context, 'read', defaultMethod?.id || null, {
        queryType: 'getDefault',
        clientId, // ID only - not PHI
        found: !!defaultMethod,
      });

      return successResult(defaultMethod);
    } catch (error) {
      return failedResult(error, 'Failed to get default payment method');
    }
  }

  /**
   * Get payment method by provider ID (e.g., Stripe pm_xxx)
   * Used for webhook processing and provider syncing
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @param providerId - Payment provider's method ID
   * @returns Payment method or null
   */
  async getByProviderId(
    context: SecurityContext,
    clientId: string,
    providerId: string
  ): Promise<RepositoryResult<PaymentMethodCard | null>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      if (!providerId?.trim()) {
        return failedResult(new InvalidArgumentError('providerId is required'));
      }

      const collectionRef = this.getClientCollectionRef(context, clientId);
      const q = query(collectionRef, where('providerId', '==', providerId));

      const snapshot = await getDocs(q);
      const methods = documentsToEntities<PaymentMethodCard>(snapshot.docs);
      const method = methods[0] || null;

      // HIPAA: Log lookup
      await this.logAudit(context, 'read', method?.id || null, {
        queryType: 'getByProviderId',
        clientId, // ID only
        found: !!method,
      });

      return successResult(method);
    } catch (error) {
      return failedResult(error, 'Failed to get payment method by provider ID');
    }
  }

  /**
   * Create a payment method for a client
   * PCI Compliance: Only accepts tokenized data from payment provider
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @param data - Payment method data (tokenized only)
   * @returns Created payment method
   */
  async createForClient(
    context: SecurityContext,
    clientId: string,
    data: Omit<PaymentMethodCard, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<RepositoryResult<PaymentMethodCard>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      // PCI CRITICAL: Verify we're not storing raw card data
      if ('cardNumber' in data || 'cvv' in data || 'cvc' in data) {
        return failedResult(
          new InvalidArgumentError('Raw card data cannot be stored. Use tokenized data only.')
        );
      }

      // Verify required tokenized fields
      if (!data.providerId || !data.last4 || !data.brand) {
        return failedResult(
          new InvalidArgumentError('providerId, last4, and brand are required')
        );
      }

      // Use custom collection path for sub-collection
      const collectionRef = this.getClientCollectionRef(context, clientId);
      const docRef = await import('firebase/firestore').then(({ addDoc }) =>
        addDoc(collectionRef, {
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
        })
      );

      // Fetch created document
      const snapshot = await import('firebase/firestore').then(({ getDoc }) =>
        getDoc(docRef)
      );

      const method = {
        id: snapshot.id,
        ...snapshot.data(),
        createdAt: snapshot.data()?.createdAt?.toDate?.() || snapshot.data()?.createdAt,
        updatedAt: snapshot.data()?.updatedAt?.toDate?.() || snapshot.data()?.updatedAt,
      } as PaymentMethodCard;

      // CRITICAL: Audit payment method creation (financial compliance)
      await this.logAudit(context, 'create', method.id, {
        clientId, // ID only - not PHI
        providerId: data.providerId,
        brand: data.brand,
        last4: data.last4,
      });

      return successResult(method);
    } catch (error) {
      return failedResult(error, 'Failed to create payment method');
    }
  }

  /**
   * Set a payment method as default
   * Unsets any existing default methods for the client
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @param methodId - Payment method ID to set as default
   * @returns Updated payment method
   */
  async setDefault(
    context: SecurityContext,
    clientId: string,
    methodId: string
  ): Promise<RepositoryResult<PaymentMethodCard>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      // Get all methods for client
      const methodsResult = await this.getByClient(context, clientId);
      if (!methodsResult.success) {
        return methodsResult as RepositoryResult<PaymentMethodCard>;
      }

      // Use batch to update all methods atomically
      const { writeBatch } = await import('firebase/firestore');
      const batch = writeBatch(this.db);

      const collectionRef = this.getClientCollectionRef(context, clientId);

      // Unset default on all methods
      for (const method of methodsResult.data) {
        const docRef = await import('firebase/firestore').then(({ doc }) =>
          doc(collectionRef, method.id)
        );
        batch.update(docRef, { isDefault: false, updatedAt: new Date() });
      }

      // Set new default
      const newDefaultRef = await import('firebase/firestore').then(({ doc }) =>
        doc(collectionRef, methodId)
      );
      batch.update(newDefaultRef, { isDefault: true, updatedAt: new Date() });

      await batch.commit();

      // Fetch updated method
      const snapshot = await import('firebase/firestore').then(({ getDoc }) =>
        getDoc(newDefaultRef)
      );

      const method = {
        id: snapshot.id,
        ...snapshot.data(),
        createdAt: snapshot.data()?.createdAt?.toDate?.() || snapshot.data()?.createdAt,
        updatedAt: snapshot.data()?.updatedAt?.toDate?.() || snapshot.data()?.updatedAt,
      } as PaymentMethodCard;

      // Audit the change
      await this.logAudit(context, 'update', methodId, {
        action: 'setDefault',
        clientId, // ID only
      });

      return successResult(method);
    } catch (error) {
      return failedResult(error, 'Failed to set default payment method');
    }
  }

  /**
   * Delete a payment method
   * NOTE: This is a hard delete (PCI compliance - remove card references when no longer needed)
   *
   * @param context - Security context
   * @param clientId - Client ID
   * @param methodId - Payment method ID
   * @returns Result indicating success or failure
   */
  async deleteForClient(
    context: SecurityContext,
    clientId: string,
    methodId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('clientId is required'));
      }

      const collectionRef = this.getClientCollectionRef(context, clientId);
      const docRef = await import('firebase/firestore').then(({ doc }) =>
        doc(collectionRef, methodId)
      );

      // Verify exists before deleting
      const snapshot = await import('firebase/firestore').then(({ getDoc }) =>
        getDoc(docRef)
      );

      if (!snapshot.exists()) {
        return failedResult(new Error('Payment method not found'));
      }

      // Hard delete
      await import('firebase/firestore').then(({ deleteDoc }) =>
        deleteDoc(docRef)
      );

      // CRITICAL: Audit deletion (financial compliance)
      await this.logAudit(context, 'delete', methodId, {
        clientId, // ID only
        hardDelete: true,
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete payment method');
    }
  }
}

// ============================================
// Singleton Export
// ============================================

let paymentMethodRepositoryInstance: PaymentMethodRepository | null = null;

export function getPaymentMethodRepository(): PaymentMethodRepository {
  if (!paymentMethodRepositoryInstance) {
    paymentMethodRepositoryInstance = new PaymentMethodRepository();
  }
  return paymentMethodRepositoryInstance;
}
