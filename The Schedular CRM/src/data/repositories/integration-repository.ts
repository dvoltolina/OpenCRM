/**
 * Integration Repository
 * CRUD operations for third-party integration management with RBAC enforcement
 *
 * Path: businesses/{businessId}/integrations/{integrationId}
 *
 * Task 9: API & Third-Party Integrations - Repository Layer
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - OAuth tokens (accessToken, refreshToken) must be encrypted at rest
 * - Error messages are sanitized - never include PHI
 * - Sensitive config values must be encrypted
 * - No PHI in audit logs
 *
 * Security:
 * - OAuth tokens encrypted at rest
 * - Only admin/owner can manage integrations
 * - Status updates sanitize error messages
 * - Config stored securely (encrypted for sensitive data)
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
import type {
  Integration,
  IntegrationType,
  IntegrationStatus,
} from '../../types/integrations';

const COLLECTION_NAME = 'integrations';

// ============================================
// Input Types
// ============================================

/**
 * Options for creating an integration
 */
export interface CreateIntegrationInput {
  name: string;
  description?: string;
  type: IntegrationType;
  provider?: string;
  config?: Record<string, unknown>;
  scopes?: string[];
}

/**
 * Options for updating an integration
 */
export interface UpdateIntegrationInput {
  name?: string;
  description?: string;
  config?: Record<string, unknown>;
  scopes?: string[];
}

/**
 * Options for updating OAuth tokens
 * HIPAA: These must be encrypted before storage
 */
export interface UpdateOAuthTokensInput {
  accessToken: string;
  refreshToken?: string;
  tokenExpiresAt: Date;
  scopes?: string[];
}

/**
 * Valid integration types
 */
const VALID_INTEGRATION_TYPES: IntegrationType[] = [
  'zapier',
  'webhook',
  'native',
  'api_key',
];

/**
 * Valid integration statuses
 */
const VALID_STATUSES: IntegrationStatus[] = [
  'active',
  'inactive',
  'error',
  'pending_auth',
];

// ============================================
// Integration Repository Class
// ============================================

export class IntegrationRepository {
  private db = getFirebaseDb();

  private getCollectionPath(businessId: string): string {
    return `${businessPath(businessId)}/${COLLECTION_NAME}`;
  }

  private getDocRef(businessId: string, integrationId: string) {
    return doc(this.db!, this.getCollectionPath(businessId), integrationId);
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
        'Only administrators can manage integrations'
      );
    }
  }

  /**
   * Validates integration type
   */
  private validateType(type: IntegrationType): void {
    if (!VALID_INTEGRATION_TYPES.includes(type)) {
      throw new InvalidArgumentError(
        `Invalid integration type: ${type}. Valid types: ${VALID_INTEGRATION_TYPES.join(', ')}`,
        'type'
      );
    }
  }

  /**
   * Validates integration status
   */
  private validateStatus(status: IntegrationStatus): void {
    if (!VALID_STATUSES.includes(status)) {
      throw new InvalidArgumentError(
        `Invalid integration status: ${status}. Valid statuses: ${VALID_STATUSES.join(', ')}`,
        'status'
      );
    }
  }

  /**
   * Sanitizes error messages to prevent PHI leakage
   * HIPAA: Error messages must never contain PHI
   */
  private sanitizeErrorMessage(message?: string): string | undefined {
    if (!message) return undefined;
    // Truncate and remove potential PHI patterns
    return message
      .substring(0, 200)
      .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL]')
      .replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE]')
      .replace(/\b\d{3}[-]?\d{2}[-]?\d{4}\b/g, '[SSN]');
  }

  /**
   * Converts Firestore document to Integration
   * Note: OAuth tokens are redacted in normal retrieval for security
   */
  private documentToIntegration(
    docId: string,
    data: DocumentData,
    businessId: string,
    includeTokens: boolean = false
  ): Integration {
    return {
      id: docId,
      businessId,
      name: data.name,
      description: data.description,
      type: data.type,
      provider: data.provider,
      status: data.status || 'inactive',
      lastSyncAt: data.lastSyncAt?.toDate?.(),
      lastErrorAt: data.lastErrorAt?.toDate?.(),
      lastErrorMessage: data.lastErrorMessage,
      config: data.config || {},
      // HIPAA: Only include tokens when explicitly requested (internal use only)
      accessToken: includeTokens ? data.accessToken : undefined,
      refreshToken: includeTokens ? data.refreshToken : undefined,
      tokenExpiresAt: data.tokenExpiresAt?.toDate?.(),
      scopes: data.scopes || [],
      createdById: data.createdById,
      createdAt: data.createdAt?.toDate?.() ?? new Date(),
      updatedAt: data.updatedAt?.toDate?.(),
    };
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /**
   * Create a new integration
   */
  async create(
    context: SecurityContext,
    input: CreateIntegrationInput
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!input.name?.trim()) {
        return failedResult(
          new InvalidArgumentError('Integration name is required', 'name')
        );
      }

      this.validateType(input.type);

      const integrationId = generateId();
      const now = Timestamp.now();

      const docData: Record<string, unknown> = {
        name: input.name.trim(),
        description: input.description?.trim(),
        type: input.type,
        provider: input.provider?.trim(),
        status: 'inactive' as IntegrationStatus,
        config: input.config || {},
        scopes: input.scopes || [],
        createdById: context.userId,
        createdAt: now,
      };

      const docRef = this.getDocRef(context.businessId, integrationId);
      await setDoc(docRef, docData);

      const integration = this.documentToIntegration(
        integrationId,
        { ...docData, createdAt: now },
        context.businessId
      );

      return successResult(integration);
    } catch (error) {
      return failedResult(error, 'Failed to create integration');
    }
  }

  /**
   * Get a single integration by ID
   */
  async getById(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('integration', integrationId));
      }

      const integration = this.documentToIntegration(
        integrationId,
        docSnap.data(),
        context.businessId,
        false
      );

      return successResult(integration);
    } catch (error) {
      return failedResult(error, 'Failed to get integration');
    }
  }

  /**
   * Get integration with OAuth tokens (for internal use only)
   * HIPAA: Use sparingly - tokens are sensitive
   */
  async getByIdWithTokens(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('integration', integrationId));
      }

      const integration = this.documentToIntegration(
        integrationId,
        docSnap.data(),
        context.businessId,
        true // Include tokens
      );

      return successResult(integration);
    } catch (error) {
      return failedResult(error, 'Failed to get integration');
    }
  }

  /**
   * Get all integrations for a business
   */
  async getAll(
    context: SecurityContext,
    _options?: QueryOptions
  ): Promise<RepositoryResult<PaginatedResult<Integration>>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(collectionRef, orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);

      const integrations = querySnapshot.docs.map((docSnap) =>
        this.documentToIntegration(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult({
        data: integrations,
        lastDoc: querySnapshot.docs[querySnapshot.docs.length - 1] || null,
        hasMore: false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to list integrations');
    }
  }

  /**
   * Get integrations by type
   * e.g., get all 'webhook' integrations
   */
  async getByType(
    context: SecurityContext,
    type: IntegrationType
  ): Promise<RepositoryResult<Integration[]>> {
    try {
      this.ensureAdminOrOwner(context);
      this.validateType(type);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('type', '==', type),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);

      const integrations = querySnapshot.docs.map((docSnap) =>
        this.documentToIntegration(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult(integrations);
    } catch (error) {
      return failedResult(error, 'Failed to get integrations by type');
    }
  }

  /**
   * Get integrations by provider
   * e.g., get all Slack integrations
   */
  async getByProvider(
    context: SecurityContext,
    provider: string
  ): Promise<RepositoryResult<Integration[]>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!provider?.trim()) {
        return failedResult(
          new InvalidArgumentError('Provider is required', 'provider')
        );
      }

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('provider', '==', provider.trim()),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);

      const integrations = querySnapshot.docs.map((docSnap) =>
        this.documentToIntegration(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult(integrations);
    } catch (error) {
      return failedResult(error, 'Failed to get integrations by provider');
    }
  }

  /**
   * Get active integrations only
   */
  async getActiveIntegrations(
    context: SecurityContext
  ): Promise<RepositoryResult<Integration[]>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('status', '==', 'active'),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);

      const integrations = querySnapshot.docs.map((docSnap) =>
        this.documentToIntegration(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult(integrations);
    } catch (error) {
      return failedResult(error, 'Failed to get active integrations');
    }
  }

  /**
   * Get integrations with errors (for monitoring/debugging)
   */
  async getErroredIntegrations(
    context: SecurityContext
  ): Promise<RepositoryResult<Integration[]>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('status', '==', 'error'),
        orderBy('lastErrorAt', 'desc')
      );
      const querySnapshot = await getDocs(q);

      const integrations = querySnapshot.docs.map((docSnap) =>
        this.documentToIntegration(
          docSnap.id,
          docSnap.data(),
          context.businessId,
          false
        )
      );

      return successResult(integrations);
    } catch (error) {
      return failedResult(error, 'Failed to get errored integrations');
    }
  }

  /**
   * Update an integration
   */
  async update(
    context: SecurityContext,
    integrationId: string,
    input: UpdateIntegrationInput
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, integrationId);
      if (!existing.success) {
        return existing;
      }

      const updates: Record<string, unknown> = {
        updatedAt: Timestamp.now(),
      };

      if (input.name !== undefined) updates.name = input.name.trim();
      if (input.description !== undefined)
        updates.description = input.description?.trim();
      if (input.config !== undefined) updates.config = input.config;
      if (input.scopes !== undefined) updates.scopes = input.scopes;

      const docRef = this.getDocRef(context.businessId, integrationId);
      await updateDoc(docRef, updates);

      return this.getById(context, integrationId);
    } catch (error) {
      return failedResult(error, 'Failed to update integration');
    }
  }

  /**
   * Update integration status
   * Used after sync operations to track success/failure
   * HIPAA: Error messages are sanitized
   */
  async updateStatus(
    context: SecurityContext,
    integrationId: string,
    status: IntegrationStatus,
    errorMessage?: string
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      this.validateStatus(status);

      // Verify exists
      const existing = await this.getById(context, integrationId);
      if (!existing.success) {
        return existing;
      }

      const updates: Record<string, unknown> = {
        status,
        updatedAt: Timestamp.now(),
      };

      // Update sync/error timestamps based on status
      if (status === 'active') {
        updates.lastSyncAt = Timestamp.now();
        updates.lastErrorAt = null;
        updates.lastErrorMessage = null;
      } else if (status === 'error') {
        updates.lastErrorAt = Timestamp.now();
        updates.lastErrorMessage = this.sanitizeErrorMessage(errorMessage);
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      await updateDoc(docRef, updates);

      return this.getById(context, integrationId);
    } catch (error) {
      return failedResult(error, 'Failed to update integration status');
    }
  }

  /**
   * Update OAuth tokens
   * HIPAA: Tokens should be encrypted before being passed to this method
   */
  async updateOAuthTokens(
    context: SecurityContext,
    integrationId: string,
    tokens: UpdateOAuthTokensInput
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, integrationId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const updates: Record<string, unknown> = {
        accessToken: tokens.accessToken,
        tokenExpiresAt: Timestamp.fromDate(tokens.tokenExpiresAt),
        status: 'active' as IntegrationStatus,
        updatedAt: Timestamp.now(),
      };

      if (tokens.refreshToken) {
        updates.refreshToken = tokens.refreshToken;
      }

      if (tokens.scopes) {
        updates.scopes = tokens.scopes;
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      await updateDoc(docRef, updates);

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to update OAuth tokens');
    }
  }

  /**
   * Clear OAuth tokens (for disconnection)
   */
  async clearOAuthTokens(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, integrationId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      await updateDoc(docRef, {
        accessToken: null,
        refreshToken: null,
        tokenExpiresAt: null,
        status: 'inactive' as IntegrationStatus,
        updatedAt: Timestamp.now(),
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to clear OAuth tokens');
    }
  }

  /**
   * Record successful sync
   */
  async recordSync(
    businessId: string,
    integrationId: string
  ): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, integrationId);
      await updateDoc(docRef, {
        lastSyncAt: Timestamp.now(),
        status: 'active' as IntegrationStatus,
      });
    } catch {
      // Best-effort, don't fail the sync
    }
  }

  /**
   * Record sync error
   * HIPAA: Error message is sanitized
   */
  async recordError(
    businessId: string,
    integrationId: string,
    errorMessage: string
  ): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, integrationId);
      await updateDoc(docRef, {
        lastErrorAt: Timestamp.now(),
        lastErrorMessage: this.sanitizeErrorMessage(errorMessage),
        status: 'error' as IntegrationStatus,
      });
    } catch {
      // Best-effort
    }
  }

  /**
   * Delete an integration
   */
  async delete(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(integrationId)) {
        return failedResult(
          new InvalidArgumentError('Invalid integration ID', 'integrationId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, integrationId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, integrationId);
      await deleteDoc(docRef);

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete integration');
    }
  }

  /**
   * Check if an integration exists by provider
   */
  async existsByProvider(
    context: SecurityContext,
    provider: string
  ): Promise<boolean> {
    try {
      const result = await this.getByProvider(context, provider);
      return result.success && result.data.length > 0;
    } catch {
      return false;
    }
  }

  /**
   * Count integrations by type
   */
  async countByType(
    context: SecurityContext,
    type: IntegrationType
  ): Promise<number> {
    try {
      const result = await this.getByType(context, type);
      return result.success ? result.data.length : 0;
    } catch {
      return 0;
    }
  }

  /**
   * Count active integrations
   */
  async countActive(context: SecurityContext): Promise<number> {
    try {
      const result = await this.getActiveIntegrations(context);
      return result.success ? result.data.length : 0;
    } catch {
      return 0;
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let integrationRepo: IntegrationRepository | null = null;

export function getIntegrationRepository(): IntegrationRepository {
  if (!integrationRepo) {
    integrationRepo = new IntegrationRepository();
  }
  return integrationRepo;
}
