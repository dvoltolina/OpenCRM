/**
 * API Key Repository
 * CRUD operations for API key management with RBAC enforcement
 *
 * Path: businesses/{businessId}/api_keys/{keyId}
 *
 * Task 3: API & Third-Party Integrations - API Key Service
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - API keys are hashed with SHA-256, never stored in plain text
 * - Only keyPrefix (first 8 chars) stored for identification
 * - Error messages are sanitized to prevent information leakage
 * - No PHI in audit logs
 *
 * Security:
 * - API keys hashed with SHA-256
 * - Full key shown only once on creation
 * - Rate limiting per API key
 * - Scope-based access control
 * - Only admin/owner can manage API keys
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
import type { DocumentData, Firestore } from 'firebase/firestore';

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
import type { ApiKey, ApiScope } from '../../types/integrations';

const COLLECTION_NAME = 'api_keys';

/** Default rate limit: 60 requests per minute */
const DEFAULT_RATE_LIMIT = 60;
/** Default rate limit window: 60 seconds */
const DEFAULT_RATE_LIMIT_WINDOW = 60;
/** Key prefix length for identification */
const KEY_PREFIX_LENGTH = 8;

// ============================================
// Input Types
// ============================================

/**
 * Options for creating an API key
 */
export interface CreateApiKeyInput {
  name: string;
  description?: string;
  scopes: ApiScope[];
  rateLimit?: number;
  rateLimitWindow?: number;
  expiresAt?: Date;
}

/**
 * Options for updating an API key
 */
export interface UpdateApiKeyInput {
  name?: string;
  description?: string;
  scopes?: ApiScope[];
  rateLimit?: number;
  rateLimitWindow?: number;
  isActive?: boolean;
}

/**
 * Result of API key creation including the full key (shown once)
 */
export interface ApiKeyCreationResult {
  key: ApiKey;
  fullKey: string;
}

// ============================================
// Valid Scopes
// ============================================

const VALID_SCOPES: ApiScope[] = [
  'leads:read',
  'leads:write',
  'deals:read',
  'deals:write',
  'contacts:read',
  'contacts:write',
  'tasks:read',
  'tasks:write',
  'activities:read',
  'sequences:read',
  'sequences:write',
  'webhooks:manage',
];

// ============================================
// API Key Repository Class
// ============================================

export class ApiKeyRepository {
  private getDb(): Firestore {
    const db = getFirebaseDb();
    if (!db) {
      throw new InvalidArgumentError('Firestore not initialized');
    }
    return db;
  }

  private getCollectionPath(businessId: string): string {
    return `${businessPath(businessId)}/${COLLECTION_NAME}`;
  }

  private getDocRef(businessId: string, keyId: string) {
    const db = this.getDb();
    return doc(db, this.getCollectionPath(businessId), keyId);
  }

  private getCollectionRef(businessId: string) {
    const db = this.getDb();
    return collection(db, this.getCollectionPath(businessId));
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
      throw new AuthorizationError('Only administrators can manage API keys');
    }
  }

  /**
   * Validates scopes array
   */
  private validateScopes(scopes: ApiScope[]): void {
    if (!scopes || scopes.length === 0) {
      throw new InvalidArgumentError(
        'At least one scope must be specified',
        'scopes'
      );
    }

    for (const scope of scopes) {
      if (!VALID_SCOPES.includes(scope)) {
        throw new InvalidArgumentError(`Invalid scope: ${scope}`, 'scopes');
      }
    }
  }

  /**
   * Generates a cryptographically secure API key
   * Format: crm_live_<32 random hex chars>
   */
  private async generateApiKey(): Promise<string> {
    if (typeof crypto === 'undefined' || !('getRandomValues' in crypto)) {
      throw new InvalidArgumentError('Secure browser crypto is required to create API keys');
    }

    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    const randomPart = Array.from(array)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
    return `crm_live_${randomPart}`;
  }

  /**
   * Computes SHA-256 hash of an API key
   */
  private async hashApiKey(apiKey: string): Promise<string> {
    if (typeof crypto === 'undefined' || !('subtle' in crypto)) {
      throw new InvalidArgumentError('Secure browser crypto is required to hash API keys');
    }

    const encoder = new TextEncoder();
    const data = encoder.encode(apiKey);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const bytes = new Uint8Array(hashBuffer);
    return Array.from(bytes)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * Extracts the prefix from a full API key for identification
   */
  private getKeyPrefix(fullKey: string): string {
    return fullKey.substring(0, KEY_PREFIX_LENGTH);
  }

  /**
   * Converts Firestore document to ApiKey
   */
  private documentToApiKey(
    docId: string,
    data: DocumentData,
    businessId: string
  ): ApiKey {
    return {
      id: docId,
      businessId,
      name: data.name,
      description: data.description,
      keyPrefix: data.keyPrefix,
      keyHash: data.keyHash,
      scopes: data.scopes || [],
      rateLimit: data.rateLimit ?? DEFAULT_RATE_LIMIT,
      rateLimitWindow: data.rateLimitWindow ?? DEFAULT_RATE_LIMIT_WINDOW,
      isActive: data.isActive ?? true,
      lastUsedAt: data.lastUsedAt?.toDate?.(),
      usageCount: data.usageCount ?? 0,
      expiresAt: data.expiresAt?.toDate?.(),
      createdById: data.createdById,
      createdAt: data.createdAt?.toDate?.() ?? new Date(),
      updatedAt: data.updatedAt?.toDate?.(),
    };
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /**
   * Create a new API key
   * Returns the key with the full API key (shown only once)
   */
  async create(
    context: SecurityContext,
    input: CreateApiKeyInput
  ): Promise<RepositoryResult<ApiKeyCreationResult>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!input.name?.trim()) {
        return failedResult(
          new InvalidArgumentError('API key name is required', 'name')
        );
      }

      this.validateScopes(input.scopes);

      // Generate the full API key
      const fullKey = await this.generateApiKey();
      const keyHash = await this.hashApiKey(fullKey);
      const keyPrefix = this.getKeyPrefix(fullKey);

      const keyId = generateId();
      const now = Timestamp.now();

      const docData: Record<string, unknown> = {
        name: input.name.trim(),
        description: input.description?.trim(),
        keyPrefix,
        keyHash,
        scopes: input.scopes,
        rateLimit: input.rateLimit ?? DEFAULT_RATE_LIMIT,
        rateLimitWindow: input.rateLimitWindow ?? DEFAULT_RATE_LIMIT_WINDOW,
        isActive: true,
        usageCount: 0,
        createdById: context.userId,
        createdAt: now,
      };

      // Add expiration if provided
      if (input.expiresAt) {
        docData.expiresAt = Timestamp.fromDate(input.expiresAt);
      }

      const docRef = this.getDocRef(context.businessId, keyId);
      await setDoc(docRef, docData);

      const apiKey = this.documentToApiKey(
        keyId,
        { ...docData, createdAt: now },
        context.businessId
      );

      return successResult({
        key: apiKey,
        fullKey,
      });
    } catch (error) {
      return failedResult(error, 'Failed to create API key');
    }
  }

  /**
   * Get a single API key by ID
   */
  async getById(
    context: SecurityContext,
    keyId: string
  ): Promise<RepositoryResult<ApiKey>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(keyId)) {
        return failedResult(
          new InvalidArgumentError('Invalid API key ID', 'keyId')
        );
      }

      const docRef = this.getDocRef(context.businessId, keyId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError('api_key', keyId));
      }

      const apiKey = this.documentToApiKey(
        keyId,
        docSnap.data(),
        context.businessId
      );

      return successResult(apiKey);
    } catch (error) {
      return failedResult(error, 'Failed to get API key');
    }
  }

  /**
   * Get API key by its hash (for validation during API requests)
   * This does not require SecurityContext as it's used for API authentication
   */
  async getByKeyHash(
    businessId: string,
    keyHash: string
  ): Promise<ApiKey | null> {
    try {
      if (!businessId?.trim() || !keyHash?.trim()) {
        return null;
      }

      const collectionRef = this.getCollectionRef(businessId);
      const q = query(
        collectionRef,
        where('keyHash', '==', keyHash),
        where('isActive', '==', true)
      );
      const querySnapshot = await getDocs(q);

      if (querySnapshot.empty) {
        return null;
      }

      const docSnap = querySnapshot.docs[0];
      return this.documentToApiKey(docSnap.id, docSnap.data(), businessId);
    } catch {
      return null;
    }
  }

  /**
   * Validate an API key and return the associated key data
   * Used by API middleware for authentication
   */
  async validateApiKey(fullKey: string): Promise<{
    valid: boolean;
    apiKey?: ApiKey;
    businessId?: string;
    error?: string;
  }> {
    try {
      // Basic format validation
      if (!fullKey || typeof fullKey !== 'string') {
        return { valid: false, error: 'API key is required' };
      }

      if (!fullKey.startsWith('crm_live_')) {
        return { valid: false, error: 'Invalid API key format' };
      }

      // We need to search across all businesses - this requires a collection group query
      // For now, we'll extract business ID from the key if encoded, or use a global lookup
      // In production, consider using a top-level api_key_lookup collection
      // For this implementation, we'll scan all businesses (should be optimized in production)

      // Note: This is a simplified implementation. In production, you should:
      // 1. Use a collection group query with the keyHash
      // 2. Or maintain a top-level lookup collection
      // For now, we require the business ID to be passed separately or use lookup collection

      return {
        valid: false,
        error: 'API key validation requires business context. Use validateApiKeyForBusiness instead.',
      };
    } catch {
      return { valid: false, error: 'Key validation failed' };
    }
  }

  /**
   * Validate an API key for a specific business
   */
  async validateApiKeyForBusiness(
    fullKey: string,
    businessId: string
  ): Promise<{
    valid: boolean;
    apiKey?: ApiKey;
    error?: string;
  }> {
    try {
      // Basic format validation
      if (!fullKey || typeof fullKey !== 'string') {
        return { valid: false, error: 'API key is required' };
      }

      if (!fullKey.startsWith('crm_live_')) {
        return { valid: false, error: 'Invalid API key format' };
      }

      // Hash the key for lookup
      const keyHash = await this.hashApiKey(fullKey);

      // Look up by hash
      const apiKey = await this.getByKeyHash(businessId, keyHash);

      if (!apiKey) {
        return { valid: false, error: 'Invalid API key' };
      }

      // Check if key is active
      if (!apiKey.isActive) {
        return { valid: false, error: 'API key is inactive' };
      }

      // Check expiration
      if (apiKey.expiresAt && apiKey.expiresAt < new Date()) {
        return { valid: false, error: 'API key has expired' };
      }

      return {
        valid: true,
        apiKey,
      };
    } catch {
      return { valid: false, error: 'Key validation failed' };
    }
  }

  /**
   * Get all API keys for a business
   */
  async getAll(
    context: SecurityContext,
    _options?: QueryOptions
  ): Promise<RepositoryResult<PaginatedResult<ApiKey>>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(collectionRef, orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);

      const apiKeys = querySnapshot.docs.map((docSnap) =>
        this.documentToApiKey(docSnap.id, docSnap.data(), context.businessId)
      );

      return successResult({
        data: apiKeys,
        lastDoc: querySnapshot.docs[querySnapshot.docs.length - 1] || null,
        hasMore: false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to list API keys');
    }
  }

  /**
   * Get active API keys only
   */
  async getActiveKeys(
    context: SecurityContext
  ): Promise<RepositoryResult<ApiKey[]>> {
    try {
      this.ensureAdminOrOwner(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('isActive', '==', true),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);

      const apiKeys = querySnapshot.docs.map((docSnap) =>
        this.documentToApiKey(docSnap.id, docSnap.data(), context.businessId)
      );

      return successResult(apiKeys);
    } catch (error) {
      return failedResult(error, 'Failed to list active API keys');
    }
  }

  /**
   * Update an API key
   */
  async update(
    context: SecurityContext,
    keyId: string,
    input: UpdateApiKeyInput
  ): Promise<RepositoryResult<ApiKey>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(keyId)) {
        return failedResult(
          new InvalidArgumentError('Invalid API key ID', 'keyId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, keyId);
      if (!existing.success) {
        return existing;
      }

      // Validate scopes if being updated
      if (input.scopes !== undefined) {
        if (input.scopes.length === 0) {
          return failedResult(
            new InvalidArgumentError(
              'At least one scope must be specified',
              'scopes'
            )
          );
        }
        this.validateScopes(input.scopes);
      }

      const updates: Record<string, unknown> = {
        updatedAt: Timestamp.now(),
      };

      if (input.name !== undefined) updates.name = input.name.trim();
      if (input.description !== undefined)
        updates.description = input.description?.trim();
      if (input.scopes !== undefined) updates.scopes = input.scopes;
      if (input.rateLimit !== undefined) updates.rateLimit = input.rateLimit;
      if (input.rateLimitWindow !== undefined)
        updates.rateLimitWindow = input.rateLimitWindow;
      if (input.isActive !== undefined) updates.isActive = input.isActive;

      const docRef = this.getDocRef(context.businessId, keyId);
      await updateDoc(docRef, updates);

      return this.getById(context, keyId);
    } catch (error) {
      return failedResult(error, 'Failed to update API key');
    }
  }

  /**
   * Revoke (soft delete) an API key by setting isActive to false
   */
  async revoke(
    context: SecurityContext,
    keyId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(keyId)) {
        return failedResult(
          new InvalidArgumentError('Invalid API key ID', 'keyId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, keyId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, keyId);
      await updateDoc(docRef, {
        isActive: false,
        updatedAt: Timestamp.now(),
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to revoke API key');
    }
  }

  /**
   * Permanently delete an API key
   */
  async delete(
    context: SecurityContext,
    keyId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureAdminOrOwner(context);

      if (!isValidDocumentId(keyId)) {
        return failedResult(
          new InvalidArgumentError('Invalid API key ID', 'keyId')
        );
      }

      // Verify exists
      const existing = await this.getById(context, keyId);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, keyId);
      await deleteDoc(docRef);

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete API key');
    }
  }

  // ============================================
  // Usage Tracking
  // ============================================

  /**
   * Record API key usage (increment count and update lastUsedAt)
   * Called by API middleware on each request
   */
  async recordUsage(businessId: string, keyId: string): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, keyId);
      const docSnap = await getDoc(docRef);
      if (!docSnap.exists()) return;

      const currentCount = docSnap.data().usageCount ?? 0;

      await updateDoc(docRef, {
        usageCount: currentCount + 1,
        lastUsedAt: Timestamp.now(),
      });
    } catch {
      // Best-effort, don't fail the API request
    }
  }

  /**
   * Increment usage count by a specific amount (batch recording)
   */
  async incrementUsage(
    businessId: string,
    keyId: string,
    count: number = 1
  ): Promise<void> {
    try {
      const docRef = this.getDocRef(businessId, keyId);
      const docSnap = await getDoc(docRef);
      if (!docSnap.exists()) return;

      const currentCount = docSnap.data().usageCount ?? 0;

      await updateDoc(docRef, {
        usageCount: currentCount + count,
        lastUsedAt: Timestamp.now(),
      });
    } catch {
      // Best-effort
    }
  }

  /**
   * Get usage count for a specific API key
   */
  async getUsageCount(
    context: SecurityContext,
    keyId: string
  ): Promise<RepositoryResult<number>> {
    try {
      const result = await this.getById(context, keyId);
      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      return successResult(result.data.usageCount);
    } catch (error) {
      return failedResult(error, 'Failed to get usage count');
    }
  }

  // ============================================
  // Helpers
  // ============================================

  /**
   * Check if a key has a specific scope
   */
  hasScope(apiKey: ApiKey, requiredScope: ApiScope): boolean {
    return apiKey.scopes.includes(requiredScope);
  }

  /**
   * Check if a key has any of the specified scopes
   */
  hasAnyScope(apiKey: ApiKey, requiredScopes: ApiScope[]): boolean {
    return requiredScopes.some((scope) => apiKey.scopes.includes(scope));
  }

  /**
   * Check if a key has all of the specified scopes
   */
  hasAllScopes(apiKey: ApiKey, requiredScopes: ApiScope[]): boolean {
    return requiredScopes.every((scope) => apiKey.scopes.includes(scope));
  }

  /**
   * Compute hash for a given API key (exposed for validation service)
   */
  async computeKeyHash(fullKey: string): Promise<string> {
    return this.hashApiKey(fullKey);
  }
}

// ============================================
// Singleton Instance
// ============================================

let apiKeyRepo: ApiKeyRepository | null = null;

export function getApiKeyRepository(): ApiKeyRepository {
  if (!apiKeyRepo) {
    apiKeyRepo = new ApiKeyRepository();
  }
  return apiKeyRepo;
}
