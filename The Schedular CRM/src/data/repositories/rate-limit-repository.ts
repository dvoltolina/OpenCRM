/**
 * Rate Limit Repository
 * Handles persistence of rate limit entries to Firestore
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for tenant isolation
 * - Rate limit data is NOT PHI but still needs tenant isolation
 * - No logging of user actions (could reveal patterns)
 *
 * Security Migration Agent - 2025-11-27
 */

import { BaseRepository } from './base-repository';
import type { SecurityContext, RepositoryResult, BaseEntity } from './repository-types';
import { successResult } from '../errors/repository-errors';

// ============================================
// Types
// ============================================

/**
 * Rate limit entry entity stored in Firestore
 */
export interface RateLimitEntity extends BaseEntity {
  /** Composite key: businessId:userId:action */
  key: string;
  /** Action timestamps within the current window */
  timestamps: number[];
  /** Last reset time */
  lastReset: number;
}

/**
 * Data for creating a rate limit entry
 */
export type RateLimitCreateData = Omit<
  RateLimitEntity,
  'id' | 'createdAt' | 'updatedAt' | 'isDeleted' | 'deletedAt'
>;

/**
 * Data for updating a rate limit entry
 */
export type RateLimitUpdateData = Partial<Omit<RateLimitEntity, 'id' | 'createdAt' | 'key'>>;

// ============================================
// Rate Limit Repository
// ============================================

/**
 * Repository for managing rate limit entries in Firestore
 *
 * NOTE: This repository handles ONLY the persistence layer.
 * The RateLimitService maintains an in-memory store for performance
 * and uses this repository for optional persistence and recovery.
 */
export class RateLimitRepository extends BaseRepository<RateLimitEntity> {
  constructor() {
    super({
      collectionName: 'rateLimits',
      softDelete: false, // Rate limits don't need soft delete
    });
  }

  /**
   * Save or update a rate limit entry
   * Uses the composite key as the document ID for deterministic storage
   *
   * @param context - Security context with businessId
   * @param data - Rate limit data to persist
   * @returns Result with saved entity
   */
  async save(
    context: SecurityContext,
    data: RateLimitCreateData
  ): Promise<RepositoryResult<RateLimitEntity>> {
    // Use the key as the document ID for deterministic storage
    // This allows updates to overwrite previous entries
    const docId = this.sanitizeDocumentId(data.key);

    // Check if it exists
    const existing = await this.getById(context, docId);

    if (existing.success) {
      // Update existing entry
      return this.update(context, docId, {
        timestamps: data.timestamps,
        lastReset: data.lastReset,
      });
    } else {
      // Create new entry
      return this.create(context, data, docId);
    }
  }

  /**
   * Get rate limit entry by composite key
   *
   * @param context - Security context with businessId
   * @param key - Composite key (businessId:userId:action)
   * @returns Result with rate limit entry or error
   */
  async getByKey(
    context: SecurityContext,
    key: string
  ): Promise<RepositoryResult<RateLimitEntity>> {
    const docId = this.sanitizeDocumentId(key);
    return this.getById(context, docId);
  }

  /**
   * Reset rate limit entry (clear timestamps)
   *
   * @param context - Security context with businessId
   * @param key - Composite key (businessId:userId:action)
   * @returns Result indicating success or failure
   */
  async resetByKey(context: SecurityContext, key: string): Promise<RepositoryResult<void>> {
    const docId = this.sanitizeDocumentId(key);
    const now = Date.now();

    // Update to empty timestamps
    const result = await this.update(context, docId, {
      timestamps: [],
      lastReset: now,
    });

    // Convert to void result
    if (result.success) {
      return successResult(undefined);
    }
    return { success: false, data: null, error: result.error };
  }

  /**
   * Sanitize key to be a valid Firestore document ID
   * Replace colons with underscores to avoid path issues
   */
  private sanitizeDocumentId(key: string): string {
    return key.replace(/:/g, '_');
  }
}

/**
 * Singleton instance
 */
let rateLimitRepositoryInstance: RateLimitRepository | null = null;

export function getRateLimitRepository(): RateLimitRepository {
  if (!rateLimitRepositoryInstance) {
    rateLimitRepositoryInstance = new RateLimitRepository();
  }
  return rateLimitRepositoryInstance;
}
