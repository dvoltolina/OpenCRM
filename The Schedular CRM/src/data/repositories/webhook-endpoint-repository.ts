/**
 * Webhook Endpoint Repository
 * CRUD operations for webhook endpoint configurations with RBAC enforcement
 *
 * Path: businesses/{businessId}/webhook_endpoints/{webhookId}
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - Secrets are stored for signature verification but never returned in list operations
 * - Error messages are sanitized to prevent information leakage
 *
 * Security:
 * - Webhook secrets for HMAC-SHA256 signature verification
 * - URLs must be HTTPS in production
 * - Only admin/owner can manage webhook endpoints
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  Timestamp,
} from 'firebase/firestore';
import type { DocumentData } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import {
  NotFoundError,
  AuthorizationError,
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { isValidDocumentId, generateId } from './firestore-utils';
import type { WebhookEndpoint, WebhookEvent } from '../../types/integrations';

const COLLECTION_NAME = 'webhook_endpoints';

/**
 * Options for creating a webhook endpoint
 */
export interface CreateWebhookEndpointInput {
  name: string;
  description?: string;
  url: string;
  events: WebhookEvent[];
  customHeaders?: Record<string, string>;
  retryEnabled?: boolean;
  maxRetries?: number;
}

/**
 * Options for updating a webhook endpoint
 */
export interface UpdateWebhookEndpointInput {
  name?: string;
  description?: string;
  url?: string;
  events?: WebhookEvent[];
  isActive?: boolean;
  customHeaders?: Record<string, string>;
  retryEnabled?: boolean;
  maxRetries?: number;
}

/**
 * Webhook Endpoint Repository Class
 * Implements CRUD with RBAC enforcement (admin/owner only)
 */
export class WebhookEndpointRepository {
  private db = getFirebaseDb();

  private getCollectionPath(businessId: string): string {
    return `${businessPath(businessId)}/${COLLECTION_NAME}`;
  }

  private getDocRef(businessId: string, endpointId: string) {
    return doc(this.db!, this.getCollectionPath(businessId), endpointId);
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
        'Only administrators can manage webhook endpoints'
      );
    }
  }

  /**
   * Validates that a URL is HTTPS (required for production)
   */
  private validateUrl(url: string): void {
    try {
      const parsed = new URL(url);
      if (parsed.protocol !== 'https:') {
        throw new InvalidArgumentError(
          'Webhook URLs must use HTTPS for security',
          'url'
        );
      }
    } catch (error) {
      if (error instanceof InvalidArgumentError) throw error;
      throw new InvalidArgumentError('Invalid webhook URL format', 'url');
    }
  }

  /**
   * Generates a cryptographically secure secret for HMAC signature verification
   */
  private async generateSecret(): Promise<string> {
    if (typeof crypto === 'undefined' || !('getRandomValues' in crypto)) {
      throw new InvalidArgumentError('Secure browser crypto is required to create webhook secrets');
    }

    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * Converts Firestore document to WebhookEndpoint
   */
  private documentToEndpoint(
    docId: string,
    data: DocumentData,
    businessId: string,
    includeSecret: boolean = false
  ): WebhookEndpoint {
    return {
      id: docId,
      businessId,
      name: data.name,
      description: data.description,
      url: data.url,
      secret: includeSecret ? data.secret : '[REDACTED]',
      events: data.events || [],
      isActive: data.isActive ?? true,
      lastTriggeredAt: data.lastTriggeredAt?.toDate?.(),
      failureCount: data.failureCount ?? 0,
      lastFailureAt: data.lastFailureAt?.toDate?.(),
      lastFailureReason: data.lastFailureReason,
      customHeaders: data.customHeaders,
      retryEnabled: data.retryEnabled ?? true,
      maxRetries: data.maxRetries ?? 3,
      createdById: data.createdById,
      createdAt: data.createdAt?.toDate?.() ?? new Date(),
      updatedAt: data.updatedAt?.toDate?.(),
    };
  }

  /**
   * Create a new webhook endpoint
   * Returns the endpoint with the secret (shown only once)
   */
  async create(
    context: SecurityContext,
    input: CreateWebhookEndpointInput
  ): Promise<RepositoryResult<WebhookEndpoint & { secret: string }>> {
    try {
      this.ensureAdminOrOwner(context);
      this.validateUrl(input.url);

      if (!input.name?.trim()) {
        return failedResult(
          new InvalidArgumentError('Endpoint name is required', 'name')
        );
      }

      if (!input.events || input.events.length === 0) {
        return failedResult(
          new InvalidArgumentError(
            'At least one event type must be selected',
            'events'
          )
        );
      }

      const endpointId = generateId();
      const secret = await this.generateSecret();
      const now = Timestamp.now();

      const docData = {
        name: input.name.trim(),
        description: input.description?.trim(),
        url: input.url,
        secret,
        events: input.events,
        isActive: true,
        failureCount: 0,
        customHeaders: input.customHeaders,
        retryEnabled: input.retryEnabled ?? true,
        maxRetries: input.maxRetries ?? 3,
        createdById: context.userId,
        createdAt: now,
      };

      const docRef = this.getDocRef(context.businessId, endpointId);
      await setDoc(docRef, docData);

      const endpoint = this.documentToEndpoint(
        endpointId,
        { ...docData, createdAt: now },
        context.businessId,
        true
      );

      return successResult(endpoint as WebhookEndpoint & { secret: string });
    } catch (error) {
      return failedResult(error, 'Failed to create webhook endpoint');
    }
  }

  /**
   * Get a single webhook endpoint by ID
   */
  async getById(
    context: SecurityContext,
    endpointId: string
  ): Promise<RepositoryResult<WebhookEndpoint>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(endpointId)) {
        return failedResult(
          new InvalidArgumentError('Invalid endpoint ID', 'endpointId')
        );
      }

      const docRef = this.getDocRef(context.businessId, endpointId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('webhook_endpoint', endpointId));
      }

      const endpoint = this.documentToEndpoint(
        endpointId,
        docSnap.data(),
        context.businessId,
        false
      );

      return successResult(endpoint);
    } catch (error) {
      return failedResult(error, 'Failed to get webhook endpoint');
    }
  }

  /**
   * Get endpoint with secret (for internal use during delivery)
   */
  async getByIdWithSecret(
    context: SecurityContext,
    endpointId: string
  ): Promise<RepositoryResult<WebhookEndpoint>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(endpointId)) {
        return failedResult(
          new InvalidArgumentError('Invalid endpoint ID', 'endpointId')
        );
      }

      const docRef = this.getDocRef(context.businessId, endpointId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('webhook_endpoint', endpointId));
      }

      const endpoint = this.documentToEndpoint(
        endpointId,
        docSnap.data(),
        context.businessId,
        true
      );

      return successResult(endpoint);
    } catch (error) {
      return failedResult(error, 'Failed to get webhook endpoint');
    }
  }

  /**
   * Get all webhook endpoints for a business
   */
  async getAll(
    context: SecurityContext,
    _options?: QueryOptions
  ): Promise<RepositoryResult<PaginatedResult<WebhookEndpoint>>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(collectionRef, orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);

      const endpoints = querySnapshot.docs.map((docSnap) =>
        this.documentToEndpoint(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult({
        data: endpoints,
        lastDoc: querySnapshot.docs[querySnapshot.docs.length - 1] || null,
        hasMore: false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to list webhook endpoints');
    }
  }

  /**
   * Get endpoints subscribed to a specific event
   * For internal use when triggering events
   */
  async getByEvent(
    businessId: string,
    event: WebhookEvent
  ): Promise<WebhookEndpoint[]> {
    try {
      const collectionRef = this.getCollectionRef(businessId);
      const q = query(
        collectionRef,
        where('isActive', '==', true),
        where('events', 'array-contains', event)
      );
      const querySnapshot = await getDocs(q);

      return querySnapshot.docs.map((docSnap) =>
        this.documentToEndpoint(docSnap.id, docSnap.data(), businessId, true)
      );
    } catch {
      return [];
    }
  }

  /**
   * Update a webhook endpoint
   */
  async update(
    context: SecurityContext,
    endpointId: string,
    input: UpdateWebhookEndpointInput
  ): Promise<RepositoryResult<WebhookEndpoint>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(endpointId)) {
        return failedResult(
          new InvalidArgumentError('Invalid endpoint ID', 'endpointId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, endpointId);
      if (!existing.success) {
        return existing;
      }

      // Validate URL if being updated
      if (input.url) {
        this.validateUrl(input.url);
      }

      // Validate events if being updated
      if (input.events !== undefined && input.events.length === 0) {
        return failedResult(
          new InvalidArgumentError(
            'At least one event type must be selected',
            'events'
          )
        );
      }

      const updates: Record<string, unknown> = {
        updatedAt: Timestamp.now(),
      };

      if (input.name !== undefined) updates.name = input.name.trim();
      if (input.description !== undefined)
        updates.description = input.description?.trim();
      if (input.url !== undefined) updates.url = input.url;
      if (input.events !== undefined) updates.events = input.events;
      if (input.isActive !== undefined) updates.isActive = input.isActive;
      if (input.customHeaders !== undefined)
        updates.customHeaders = input.customHeaders;
      if (input.retryEnabled !== undefined)
        updates.retryEnabled = input.retryEnabled;
      if (input.maxRetries !== undefined) updates.maxRetries = input.maxRetries;

      const docRef = this.getDocRef(context.businessId, endpointId);
      await updateDoc(docRef, updates);

      return this.getById(context, endpointId);
    } catch (error) {
      return failedResult(error, 'Failed to update webhook endpoint');
    }
  }

  /**
   * Delete a webhook endpoint
   */
  async delete(
    context: SecurityContext,
    endpointId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(endpointId)) {
        return failedResult(
          new InvalidArgumentError('Invalid endpoint ID', 'endpointId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, endpointId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, endpointId);
      await deleteDoc(docRef);

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete webhook endpoint');
    }
  }

  /**
   * Regenerate the secret for an endpoint
   * Returns the new secret (shown only once)
   */
  async regenerateSecret(
    context: SecurityContext,
    endpointId: string
  ): Promise<RepositoryResult<string>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(endpointId)) {
        return failedResult(
          new InvalidArgumentError('Invalid endpoint ID', 'endpointId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, endpointId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const newSecret = await this.generateSecret();

      const docRef = this.getDocRef(context.businessId, endpointId);
      await updateDoc(docRef, {
        secret: newSecret,
        updatedAt: Timestamp.now(),
      });

      return successResult(newSecret);
    } catch (error) {
      return failedResult(error, 'Failed to regenerate webhook secret');
    }
  }

  /**
   * Record a successful trigger
   */
  async recordTrigger(businessId: string, endpointId: string): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, endpointId);
      await updateDoc(docRef, {
        lastTriggeredAt: Timestamp.now(),
      });
    } catch {
      // Best-effort, don't fail the delivery
    }
  }

  /**
   * Increment failure count and record failure reason
   */
  async incrementFailure(
    businessId: string,
    endpointId: string,
    reason: string
  ): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, endpointId);
      const docSnap = await getDoc(docRef);
      if (!docSnap.exists()) return;

      const currentCount = docSnap.data().failureCount ?? 0;

      await updateDoc(docRef, {
        failureCount: currentCount + 1,
        lastFailureAt: Timestamp.now(),
        // Sanitize reason - never include PHI
        lastFailureReason: reason.substring(0, 200),
      });
    } catch {
      // Best-effort
    }
  }

  /**
   * Reset failure count after successful delivery
   */
  async resetFailure(businessId: string, endpointId: string): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, endpointId);
      await updateDoc(docRef, {
        failureCount: 0,
        lastFailureReason: null,
      });
    } catch {
      // Best-effort
    }
  }
}

// Singleton instance
let webhookEndpointRepo: WebhookEndpointRepository | null = null;

export function getWebhookEndpointRepository(): WebhookEndpointRepository {
  if (!webhookEndpointRepo) {
    webhookEndpointRepo = new WebhookEndpointRepository();
  }
  return webhookEndpointRepo;
}
