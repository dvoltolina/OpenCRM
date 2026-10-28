/**
 * Webhook Delivery Repository
 * Tracks webhook delivery attempts with retry logic and status management
 *
 * Path: businesses/{businessId}/webhook_deliveries/{deliveryId}
 *
 * HIPAA Compliance:
 * - Payloads must be sanitized - no PHI stored
 * - Response bodies must be sanitized
 * - All operations scoped by businessId
 *
 * Security:
 * - Delivery retries with exponential backoff
 * - Maximum retry attempts enforced
 * - Audit trail for all delivery attempts
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  query,
  where,
  orderBy,
  limit as firestoreLimit,
  Timestamp,
} from 'firebase/firestore';
import type { DocumentData } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
} from './repository-types';
import {
  NotFoundError,
  AuthorizationError,
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { isValidDocumentId } from './firestore-utils';
import type { WebhookDelivery, WebhookEvent } from '../../types/integrations';

const COLLECTION_NAME = 'webhook_deliveries';

/**
 * Input for creating a delivery record
 */
export interface CreateDeliveryInput {
  webhookId: string;
  event: WebhookEvent;
  payload: Record<string, unknown>;
}

/**
 * Input for updating delivery status after attempt
 */
export interface UpdateDeliveryStatusInput {
  status: WebhookDelivery['status'];
  responseStatus?: number;
  responseBody?: string;
  responseTimeMs?: number;
  nextRetryAt?: Date;
}

/**
 * Options for listing deliveries
 */
export interface ListDeliveriesOptions {
  limit?: number;
  status?: WebhookDelivery['status'];
}

/**
 * Webhook Delivery Repository Class
 */
export class WebhookDeliveryRepository {
  private db = getFirebaseDb();

  private getCollectionPath(businessId: string): string {
    return `${businessPath(businessId)}/${COLLECTION_NAME}`;
  }

  private getDocRef(businessId: string, deliveryId: string) {
    return doc(this.db!, this.getCollectionPath(businessId), deliveryId);
  }

  private getCollectionRef(businessId: string) {
    return collection(this.db!, this.getCollectionPath(businessId));
  }

  /**
   * Validates security context and enforces admin/owner role requirement
   */
  private ensureAdminOrOwner(context: SecurityContext): void {
    if (!context.businessId?.trim()) {
      throw new InvalidArgumentError('SecurityContext missing businessId');
    }
    if (!context.userId?.trim()) {
      throw new InvalidArgumentError('SecurityContext missing userId');
    }
    if (context.userRole !== 'admin' && context.userRole !== 'owner') {
      throw new AuthorizationError(
        'Only administrators can manage webhook deliveries'
      );
    }
  }

  /**
   * Sanitizes payload to remove potential PHI fields
   * HIPAA: Never store PHI in webhook delivery logs
   */
  private sanitizePayload(
    payload: Record<string, unknown>
  ): Record<string, unknown> {
    const sensitiveFields = [
      'name',
      'firstName',
      'lastName',
      'email',
      'phone',
      'address',
      'notes',
      'message',
      'body',
      'ssn',
      'dob',
      'birthDate',
      'medicalRecord',
      'healthInfo',
      'insurance',
    ];

    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(payload)) {
      if (sensitiveFields.some((f) => key.toLowerCase().includes(f.toLowerCase()))) {
        sanitized[key] = '[REDACTED]';
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = this.sanitizePayload(value as Record<string, unknown>);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * Sanitizes response body - truncate and remove potential PHI
   */
  private sanitizeResponseBody(body?: string): string | undefined {
    if (!body) return undefined;
    // Truncate to 500 chars and remove any obvious PHI patterns
    return body.substring(0, 500).replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL]');
  }

  /**
   * Converts Firestore document to WebhookDelivery
   */
  private documentToDelivery(
    docId: string,
    data: DocumentData,
    businessId: string
  ): WebhookDelivery {
    return {
      id: docId,
      businessId,
      webhookId: data.webhookId,
      event: data.event,
      payload: data.payload || {},
      status: data.status || 'pending',
      attemptCount: data.attemptCount ?? 0,
      lastAttemptAt: data.lastAttemptAt?.toDate?.(),
      nextRetryAt: data.nextRetryAt?.toDate?.(),
      responseStatus: data.responseStatus,
      responseBody: data.responseBody,
      responseTimeMs: data.responseTimeMs,
      createdAt: data.createdAt?.toDate?.() ?? new Date(),
    };
  }

  /**
   * Create a new delivery record
   */
  async create(
    businessId: string,
    input: CreateDeliveryInput
  ): Promise<string> {
    const now = Timestamp.now();
    const sanitizedPayload = this.sanitizePayload(input.payload);

    const docRef = await addDoc(this.getCollectionRef(businessId), {
      webhookId: input.webhookId,
      event: input.event,
      payload: sanitizedPayload,
      status: 'pending',
      attemptCount: 0,
      createdAt: now,
    });

    return docRef.id;
  }

  /**
   * Get a single delivery by ID
   */
  async getById(
    context: SecurityContext,
    deliveryId: string
  ): Promise<RepositoryResult<WebhookDelivery>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(deliveryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid delivery ID', 'deliveryId')
        );
      }

      const docRef = this.getDocRef(context.businessId, deliveryId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('webhook_delivery', deliveryId));
      }

      const delivery = this.documentToDelivery(
        deliveryId,
        docSnap.data(),
        context.businessId
      );

      return successResult(delivery);
    } catch (error) {
      return failedResult(error, 'Failed to get webhook delivery');
    }
  }

  /**
   * Get deliveries for a specific webhook endpoint
   */
  async getByWebhookId(
    context: SecurityContext,
    webhookId: string,
    options?: ListDeliveriesOptions
  ): Promise<RepositoryResult<PaginatedResult<WebhookDelivery>>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(webhookId)) {
        return failedResult(
          new InvalidArgumentError('Invalid webhook ID', 'webhookId')
        );
      }

      const collectionRef = this.getCollectionRef(context.businessId);
      let q = query(
        collectionRef,
        where('webhookId', '==', webhookId),
        orderBy('createdAt', 'desc')
      );

      if (options?.status) {
        q = query(
          collectionRef,
          where('webhookId', '==', webhookId),
          where('status', '==', options.status),
          orderBy('createdAt', 'desc')
        );
      }

      if (options?.limit) {
        q = query(q, firestoreLimit(options.limit));
      }

      const querySnapshot = await getDocs(q);

      const deliveries = querySnapshot.docs.map((docSnap) =>
        this.documentToDelivery(
          docSnap.id,
          docSnap.data(),
          context.businessId
        )
      );

      return successResult({
        data: deliveries,
        lastDoc: querySnapshot.docs[querySnapshot.docs.length - 1] || null,
        hasMore: options?.limit ? querySnapshot.docs.length >= options.limit : false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to list webhook deliveries');
    }
  }

  /**
   * Get pending retries that are due
   * For internal use by retry processor
   */
  async getPendingRetries(businessId: string): Promise<WebhookDelivery[]> {
    try {
      const now = Timestamp.now();
      const collectionRef = this.getCollectionRef(businessId);
      const q = query(
        collectionRef,
        where('status', '==', 'retrying'),
        where('nextRetryAt', '<=', now),
        firestoreLimit(50)
      );

      const querySnapshot = await getDocs(q);

      return querySnapshot.docs.map((docSnap) =>
        this.documentToDelivery(docSnap.id, docSnap.data(), businessId)
      );
    } catch {
      return [];
    }
  }

  /**
   * Update delivery status after an attempt
   */
  async updateStatus(
    businessId: string,
    deliveryId: string,
    input: UpdateDeliveryStatusInput
  ): Promise<void> {
    const docRef = this.getDocRef(businessId, deliveryId);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) return;

    const currentAttempts = docSnap.data().attemptCount ?? 0;

    const updates: Record<string, unknown> = {
      status: input.status,
      attemptCount: currentAttempts + 1,
      lastAttemptAt: Timestamp.now(),
    };

    if (input.responseStatus !== undefined) {
      updates.responseStatus = input.responseStatus;
    }

    if (input.responseBody !== undefined) {
      updates.responseBody = this.sanitizeResponseBody(input.responseBody);
    }

    if (input.responseTimeMs !== undefined) {
      updates.responseTimeMs = input.responseTimeMs;
    }

    if (input.nextRetryAt) {
      updates.nextRetryAt = Timestamp.fromDate(input.nextRetryAt);
    } else {
      updates.nextRetryAt = null;
    }

    await updateDoc(docRef, updates);
  }

  /**
   * Mark delivery for retry with next attempt time
   */
  async scheduleRetry(
    businessId: string,
    deliveryId: string,
    nextRetryAt: Date
  ): Promise<void> {
    const docRef = this.getDocRef(businessId, deliveryId);
    await updateDoc(docRef, {
      status: 'retrying',
      nextRetryAt: Timestamp.fromDate(nextRetryAt),
    });
  }

  /**
   * Get failed deliveries for manual retry
   */
  async getFailedDeliveries(
    context: SecurityContext,
    options?: { limit?: number }
  ): Promise<RepositoryResult<PaginatedResult<WebhookDelivery>>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      let q = query(
        collectionRef,
        where('status', '==', 'failed'),
        orderBy('createdAt', 'desc')
      );

      if (options?.limit) {
        q = query(q, firestoreLimit(options.limit));
      }

      const querySnapshot = await getDocs(q);

      const deliveries = querySnapshot.docs.map((docSnap) =>
        this.documentToDelivery(
          docSnap.id,
          docSnap.data(),
          context.businessId
        )
      );

      return successResult({
        data: deliveries,
        lastDoc: querySnapshot.docs[querySnapshot.docs.length - 1] || null,
        hasMore: options?.limit ? querySnapshot.docs.length >= options.limit : false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to list failed deliveries');
    }
  }

  /**
   * Reset delivery for manual retry
   */
  async resetForRetry(
    context: SecurityContext,
    deliveryId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(deliveryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid delivery ID', 'deliveryId')
        );
      }

      const existing = await this.getById(context, deliveryId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, deliveryId);
      await updateDoc(docRef, {
        status: 'pending',
        nextRetryAt: null,
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to reset delivery for retry');
    }
  }
}

// Singleton instance
let webhookDeliveryRepo: WebhookDeliveryRepository | null = null;

export function getWebhookDeliveryRepository(): WebhookDeliveryRepository {
  if (!webhookDeliveryRepo) {
    webhookDeliveryRepo = new WebhookDeliveryRepository();
  }
  return webhookDeliveryRepo;
}
