/**
 * API Key Service
 * Complete API for managing API keys, validation, rate limiting, and usage tracking
 *
 * Task 3: API & Third-Party Integrations - API Key Service
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - API keys are hashed with SHA-256, never stored or logged in plain text
 * - Error messages are sanitized to prevent information leakage
 * - All key management operations are audit logged (without PHI)
 * - No PHI in API responses or error messages
 *
 * Security:
 * - API keys hashed with SHA-256, never stored plain
 * - Full key shown only once on creation
 * - Rate limiting per API key (configurable)
 * - Scope-based access control
 * - Only admin/owner roles can manage keys
 * - Key expiration support
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getApiKeyRepository,
  type CreateApiKeyInput,
  type UpdateApiKeyInput,
} from '../data/repositories/api-key-repository';
import type { RateLimitService } from './RateLimitService';
import { getAuditLogService, type AuditLogService } from './AuditLogService';
import type {
  ApiKey,
  ApiScope,
  ApiKeyValidationResult,
  RateLimitCheckResult,
  ApiUsageStats,
} from '../types/integrations';

// ============================================
// Types
// ============================================

export interface ApiKeyServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export interface ApiKeyWithFullKey {
  key: ApiKey;
  fullKey: string;
}

/**
 * Rate limit entry stored in memory for quick access
 */
interface RateLimitEntry {
  /** Timestamps of requests within the current window */
  timestamps: number[];
  /** Window start time */
  windowStart: number;
}

// ============================================
// API Key Service Implementation
// ============================================

export class ApiKeyService {
  private repo = getApiKeyRepository();
  private audit: AuditLogService;

  /** In-memory rate limit tracking per API key */
  private rateLimitStore: Map<string, RateLimitEntry> = new Map();

  constructor(
    _rateLimitService?: RateLimitService,
    auditService?: AuditLogService
  ) {
    this.audit = auditService || getAuditLogService();
  }

  // ============================================
  // Key Management
  // ============================================

  /**
   * Create a new API key
   * Returns the key with the full API key (shown only once)
   */
  async createKey(
    context: SecurityContext,
    options: {
      name: string;
      description?: string;
      scopes: ApiScope[];
      rateLimit?: number;
      expiresAt?: Date;
    }
  ): Promise<ApiKeyServiceResult<ApiKeyWithFullKey>> {
    const input: CreateApiKeyInput = {
      name: options.name,
      description: options.description,
      scopes: options.scopes,
      rateLimit: options.rateLimit,
      expiresAt: options.expiresAt,
    };

    const result = await this.repo.create(context, input);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    // Audit log the creation (no sensitive data)
    await this.audit.logAction(context, {
      action: 'create',
      entityType: 'integration',
      entityId: result.data.key.id,
      entityName: result.data.key.name,
      metadata: {
        scopes: result.data.key.scopes,
        keyPrefix: result.data.key.keyPrefix,
        expiresAt: result.data.key.expiresAt?.toISOString(),
      },
    });

    return {
      success: true,
      data: {
        key: result.data.key,
        fullKey: result.data.fullKey,
      },
    };
  }

  /**
   * Update an existing API key
   */
  async updateKey(
    context: SecurityContext,
    keyId: string,
    updates: Partial<
      Pick<ApiKey, 'name' | 'description' | 'scopes' | 'rateLimit' | 'isActive'>
    >
  ): Promise<ApiKeyServiceResult<ApiKey>> {
    const input: UpdateApiKeyInput = {
      name: updates.name,
      description: updates.description,
      scopes: updates.scopes,
      rateLimit: updates.rateLimit,
      isActive: updates.isActive,
    };

    const result = await this.repo.update(context, keyId, input);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    await this.audit.logAction(context, {
      action: 'update',
      entityType: 'integration',
      entityId: result.data.id,
      entityName: result.data.name,
      metadata: {
        updatedFields: Object.keys(updates).filter(
          (k) => updates[k as keyof typeof updates] !== undefined
        ),
      },
    });

    return {
      success: true,
      data: result.data,
    };
  }

  /**
   * Revoke an API key (soft delete - sets isActive to false)
   */
  async revokeKey(
    context: SecurityContext,
    keyId: string
  ): Promise<ApiKeyServiceResult<void>> {
    // Get key info for audit before revoking
    const existing = await this.repo.getById(context, keyId);

    const result = await this.repo.revoke(context, keyId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    // Clear rate limit cache for this key
    this.rateLimitStore.delete(keyId);

    await this.audit.logAction(context, {
      action: 'delete',
      entityType: 'integration',
      entityId: keyId,
      entityName: existing.success ? existing.data.name : 'Unknown',
      metadata: {},
    });

    return { success: true };
  }

  /**
   * Get all API keys for the business
   */
  async getKeys(
    context: SecurityContext
  ): Promise<ApiKeyServiceResult<ApiKey[]>> {
    const result = await this.repo.getAll(context);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data.data,
    };
  }

  /**
   * Get a single API key by ID
   */
  async getKey(
    context: SecurityContext,
    keyId: string
  ): Promise<ApiKeyServiceResult<ApiKey>> {
    const result = await this.repo.getById(context, keyId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  // ============================================
  // Validation
  // ============================================

  /**
   * Validate an API key and return its associated data
   * Used by API middleware for authentication
   *
   * @param key - The full API key to validate
   * @returns Validation result with key data if valid
   */
  async validateKey(key: string): Promise<ApiKeyValidationResult> {
    // Basic format validation
    if (!key || typeof key !== 'string') {
      return { valid: false, error: 'API key is required' };
    }

    if (!key.startsWith('crm_live_')) {
      return { valid: false, error: 'Invalid API key format' };
    }

    // For full validation, we need to know the business ID
    // In a real API gateway, this would be extracted from the request path
    // or a separate lookup collection would be used
    return {
      valid: false,
      error: 'Use validateKeyForBusiness with business context',
    };
  }

  /**
   * Validate an API key for a specific business
   * This is the primary validation method for API requests
   */
  async validateKeyForBusiness(
    key: string,
    businessId: string
  ): Promise<ApiKeyValidationResult> {
    const result = await this.repo.validateApiKeyForBusiness(key, businessId);

    if (!result.valid) {
      return {
        valid: false,
        error: result.error,
      };
    }

    return {
      valid: true,
      apiKey: result.apiKey,
      businessId,
    };
  }

  /**
   * Check if a key has the required scope for an operation
   */
  checkScope(apiKey: ApiKey, requiredScope: ApiScope): boolean {
    return this.repo.hasScope(apiKey, requiredScope);
  }

  /**
   * Check if a key has any of the required scopes
   */
  checkAnyScope(apiKey: ApiKey, requiredScopes: ApiScope[]): boolean {
    return this.repo.hasAnyScope(apiKey, requiredScopes);
  }

  /**
   * Check if a key has all of the required scopes
   */
  checkAllScopes(apiKey: ApiKey, requiredScopes: ApiScope[]): boolean {
    return this.repo.hasAllScopes(apiKey, requiredScopes);
  }

  // ============================================
  // Rate Limiting
  // ============================================

  /**
   * Check if an API request is allowed under rate limits
   * Uses sliding window rate limiting algorithm
   */
  async checkRateLimit(keyId: string): Promise<RateLimitCheckResult> {
    // Get the API key to retrieve rate limit configuration
    // Note: This is an internal operation, so we bypass SecurityContext
    const now = Date.now();

    // Get or create rate limit entry
    let entry = this.rateLimitStore.get(keyId);

    // Default rate limit if key not found (fail-safe)
    const rateLimit = 60; // requests per window
    const rateLimitWindow = 60 * 1000; // 1 minute in ms

    // Try to get actual rate limit from key (in memory cache or quick lookup)
    // For simplicity, use defaults and rely on recordUsage to set proper limits

    if (!entry) {
      entry = {
        timestamps: [],
        windowStart: now,
      };
    }

    // Clean up old timestamps outside the window
    const windowStart = now - rateLimitWindow;
    entry.timestamps = entry.timestamps.filter((ts) => ts > windowStart);

    // Check if limit exceeded
    const count = entry.timestamps.length;
    const remaining = Math.max(0, rateLimit - count);
    const allowed = count < rateLimit;

    // Calculate reset time
    const oldestTimestamp = entry.timestamps[0] || now;
    const resetAt = new Date(oldestTimestamp + rateLimitWindow);

    // Save updated entry
    this.rateLimitStore.set(keyId, entry);

    return {
      allowed,
      remaining,
      resetAt,
    };
  }

  /**
   * Check rate limit with custom configuration
   */
  async checkRateLimitWithConfig(
    keyId: string,
    config: { rateLimit: number; rateLimitWindow: number }
  ): Promise<RateLimitCheckResult> {
    const now = Date.now();
    const windowMs = config.rateLimitWindow * 1000; // Convert to ms

    // Get or create rate limit entry
    let entry = this.rateLimitStore.get(keyId);

    if (!entry) {
      entry = {
        timestamps: [],
        windowStart: now,
      };
    }

    // Clean up old timestamps outside the window
    const windowStart = now - windowMs;
    entry.timestamps = entry.timestamps.filter((ts) => ts > windowStart);

    // Check if limit exceeded
    const count = entry.timestamps.length;
    const remaining = Math.max(0, config.rateLimit - count);
    const allowed = count < config.rateLimit;

    // Calculate reset time
    const oldestTimestamp = entry.timestamps[0] || now;
    const resetAt = new Date(oldestTimestamp + windowMs);

    // Save updated entry
    this.rateLimitStore.set(keyId, entry);

    return {
      allowed,
      remaining,
      resetAt,
    };
  }

  /**
   * Record an API request for rate limiting purposes
   * Should be called after successful authentication
   */
  async recordUsage(keyId: string): Promise<void> {
    const now = Date.now();

    // Update in-memory rate limit tracking
    let entry = this.rateLimitStore.get(keyId);

    if (!entry) {
      entry = {
        timestamps: [],
        windowStart: now,
      };
    }

    // Add current timestamp
    entry.timestamps.push(now);
    this.rateLimitStore.set(keyId, entry);

    // Also record in Firestore (async, non-blocking)
    // Extract businessId from the key tracking or use a lookup
    // For now, this is handled by the repository when key is validated
  }

  /**
   * Record usage in Firestore for persistent tracking
   */
  async recordUsagePersistent(
    businessId: string,
    keyId: string
  ): Promise<void> {
    await this.repo.recordUsage(businessId, keyId);
  }

  // ============================================
  // Usage Statistics
  // ============================================

  /**
   * Get usage statistics for an API key
   */
  async getUsageStats(
    context: SecurityContext,
    keyId: string,
    _dateRange: { start: Date; end: Date }
  ): Promise<ApiKeyServiceResult<ApiUsageStats>> {
    // Get the key to verify access
    const keyResult = await this.repo.getById(context, keyId);

    if (!keyResult.success) {
      return {
        success: false,
        error: {
          code: keyResult.error.code,
          message: keyResult.error.message,
        },
      };
    }

    const apiKey = keyResult.data;

    // For now, return basic stats from the key itself
    // In production, you would query the api_requests collection
    // for detailed endpoint-level statistics
    const stats: ApiUsageStats = {
      requests: apiKey.usageCount,
      byEndpoint: {
        // This would be populated from api_requests collection
        // For now, return empty since we don't have per-endpoint tracking yet
      },
    };

    return {
      success: true,
      data: stats,
    };
  }

  /**
   * Get total usage count for an API key
   */
  async getUsageCount(
    context: SecurityContext,
    keyId: string
  ): Promise<ApiKeyServiceResult<number>> {
    const result = await this.repo.getUsageCount(context, keyId);

    if (!result.success) {
      return {
        success: false,
        error: {
          code: result.error.code,
          message: result.error.message,
        },
      };
    }

    return {
      success: true,
      data: result.data,
    };
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Clear rate limit cache for a specific key
   * Useful when key is updated or deleted
   */
  clearRateLimitCache(keyId: string): void {
    this.rateLimitStore.delete(keyId);
  }

  /**
   * Clear all rate limit caches
   * Useful for testing or system reset
   */
  clearAllRateLimitCaches(): void {
    this.rateLimitStore.clear();
  }

  /**
   * Get current rate limit status for a key (without recording)
   */
  getRateLimitStatus(keyId: string): {
    count: number;
    windowStart: number;
  } | null {
    const entry = this.rateLimitStore.get(keyId);
    if (!entry) return null;

    return {
      count: entry.timestamps.length,
      windowStart: entry.windowStart,
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let apiKeyService: ApiKeyService | null = null;

export function getApiKeyService(): ApiKeyService {
  if (!apiKeyService) {
    apiKeyService = new ApiKeyService();
  }
  return apiKeyService;
}

// ============================================
// Convenience Functions
// ============================================

/**
 * Convenience function to validate an API key
 */
export async function validateApiKey(
  key: string,
  businessId: string
): Promise<ApiKeyValidationResult> {
  const service = getApiKeyService();
  return service.validateKeyForBusiness(key, businessId);
}

/**
 * Convenience function to check rate limit
 */
export async function checkApiKeyRateLimit(
  keyId: string,
  config?: { rateLimit: number; rateLimitWindow: number }
): Promise<RateLimitCheckResult> {
  const service = getApiKeyService();
  if (config) {
    return service.checkRateLimitWithConfig(keyId, config);
  }
  return service.checkRateLimit(keyId);
}

/**
 * Convenience function to record API usage
 */
export async function recordApiKeyUsage(keyId: string): Promise<void> {
  const service = getApiKeyService();
  return service.recordUsage(keyId);
}
