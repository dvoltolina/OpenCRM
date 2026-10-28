/**
 * Rate Limit Service
 * Prevents runaway automations and API abuse
 *
 * Agent CRM-28 Implementation
 * Safety controls for automation triggers and actions
 *
 * Implementation:
 * - Sliding window rate limiting
 * - Configurable limits per action type
 * - Per-user and per-business tracking
 * - In-memory storage with optional persistence
 *
 * Security Migration Agent - 2025-11-27
 * - Migrated to repository pattern for Firestore persistence
 * - Removed direct Firestore imports
 * - Removed console.error statements per HIPAA guidelines
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getRateLimitRepository } from '../data/repositories/rate-limit-repository';
import type { RateLimitCreateData } from '../data/repositories/rate-limit-repository';

// ============================================
// Types
// ============================================

export type RateLimitAction =
  | 'email'
  | 'sms'
  | 'api_call'
  | 'automation'
  | 'bulk_operation'
  | 'export'
  | 'import'
  | 'webhook'
  | 'integration_sync'
  | 'report'
  | 'webhook_trigger';

export interface RateLimitConfig {
  /** Maximum number of actions allowed */
  maxActions: number;
  /** Time window in milliseconds */
  windowMs: number;
  /** Human-readable description */
  description: string;
}

export interface RateLimitEntry {
  /** Action timestamps within the current window */
  timestamps: number[];
  /** Last reset time */
  lastReset: number;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: Date;
  message?: string;
}

export interface RateLimitSettings {
  enabled: boolean;
  limits: Record<RateLimitAction, RateLimitConfig>;
}

// ============================================
// Default Rate Limits
// ============================================

export const DEFAULT_RATE_LIMITS: Record<RateLimitAction, RateLimitConfig> = {
  email: {
    maxActions: 100,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '100 emails per hour',
  },
  sms: {
    maxActions: 50,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '50 SMS per hour',
  },
  api_call: {
    maxActions: 1000,
    windowMs: 24 * 60 * 60 * 1000, // 1 day
    description: '1000 API calls per day',
  },
  automation: {
    maxActions: 500,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '500 automation triggers per hour',
  },
  bulk_operation: {
    maxActions: 10,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '10 bulk operations per hour',
  },
  export: {
    maxActions: 20,
    windowMs: 24 * 60 * 60 * 1000, // 1 day
    description: '20 exports per day',
  },
  import: {
    maxActions: 10,
    windowMs: 24 * 60 * 60 * 1000, // 1 day
    description: '10 imports per day',
  },
  webhook: {
    maxActions: 100,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '100 webhook events per hour',
  },
  integration_sync: {
    maxActions: 20,
    windowMs: 5 * 60 * 1000, // 5 minutes
    description: '20 sync batches per 5 minutes',
  },
  report: {
    maxActions: 50,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '50 report executions per hour',
  },
  webhook_trigger: {
    maxActions: 200,
    windowMs: 60 * 60 * 1000, // 1 hour
    description: '200 webhook triggers per hour',
  },
};

const UNKNOWN_ACTION_FALLBACK: RateLimitConfig = {
  maxActions: Infinity,
  windowMs: 60 * 60 * 1000,
  description: 'Unknown action type — unbounded until configured',
};

// ============================================
// Rate Limit Service
// ============================================

export class RateLimitService {
  private inMemoryStore: Map<string, RateLimitEntry>;
  private limits: Record<RateLimitAction, RateLimitConfig>;
  private enabled: boolean;

  constructor(customLimits?: Partial<Record<RateLimitAction, RateLimitConfig>>) {
    this.inMemoryStore = new Map();
    this.limits = { ...DEFAULT_RATE_LIMITS, ...customLimits };
    this.enabled = true;
  }

  /**
   * Enable rate limiting
   */
  enable(): void {
    this.enabled = true;
  }

  /**
   * Disable rate limiting (for testing or emergency situations)
   */
  disable(): void {
    this.enabled = false;
  }

  /**
   * Check if an action is allowed under rate limits
   */
  async checkLimit(
    action: RateLimitAction,
    userId: string,
    businessId?: string
  ): Promise<RateLimitResult> {
    if (!this.enabled) {
      return {
        allowed: true,
        remaining: Infinity,
        resetAt: new Date(Date.now() + 86400000),
      };
    }

    const config = this.limits[action];
    const activeConfig = config ?? UNKNOWN_ACTION_FALLBACK;

    const key = this.getKey(action, userId, businessId);
    const now = Date.now();
    const windowStart = now - activeConfig.windowMs;

    // Get or create entry
    let entry = this.inMemoryStore.get(key);
    if (!entry) {
      entry = {
        timestamps: [],
        lastReset: now,
      };
    }

    // Remove timestamps outside the window (sliding window)
    entry.timestamps = entry.timestamps.filter((ts) => ts > windowStart);

    // Check if limit exceeded
    const count = entry.timestamps.length;
    const remaining = Math.max(0, activeConfig.maxActions - count);
    const allowed = count < activeConfig.maxActions;

    // Calculate reset time (oldest timestamp + window duration)
    const oldestTimestamp = entry.timestamps[0] || now;
    const resetAt = new Date(oldestTimestamp + activeConfig.windowMs);

    if (!allowed) {
      return {
        allowed: false,
        remaining: 0,
        resetAt,
        message: `Rate limit exceeded: ${activeConfig.description}. Try again after ${resetAt.toLocaleTimeString()}.`,
      };
    }

    return {
      allowed: true,
      remaining,
      resetAt,
    };
  }

  /**
   * Record an action (increment counter)
   */
  async recordAction(
    action: RateLimitAction,
    userId: string,
    businessId?: string
  ): Promise<void> {
    if (!this.enabled) {
      return;
    }

    const config = this.limits[action] ?? UNKNOWN_ACTION_FALLBACK;
    const key = this.getKey(action, userId, businessId);
    const now = Date.now();

    // Enforce cleanup even when recording directly to avoid unbounded growth
    const windowStart = now - config.windowMs;

    // Get or create entry
    let entry = this.inMemoryStore.get(key);
    if (!entry) {
      entry = {
        timestamps: [],
        lastReset: now,
      };
    }

    entry.timestamps = entry.timestamps.filter((ts) => ts > windowStart);

    // Add current timestamp
    entry.timestamps.push(now);

    // Save to in-memory store
    this.inMemoryStore.set(key, entry);

    // Optionally persist to Firestore (async, don't wait)
    this.persistToFirestore(key, entry, businessId).catch(() => {
      // Persistence failures are non-blocking
      // Error handling per HIPAA guidelines - no logging of user actions
    });
  }

  /**
   * Check and record in one operation
   */
  async checkAndRecord(
    action: RateLimitAction,
    userId: string,
    businessId?: string
  ): Promise<RateLimitResult> {
    const result = await this.checkLimit(action, userId, businessId);

    if (result.allowed) {
      await this.recordAction(action, userId, businessId);
    }

    return result;
  }

  /**
   * Reset rate limit for a specific action/user
   */
  async reset(
    action: RateLimitAction,
    userId: string,
    businessId?: string
  ): Promise<void> {
    const key = this.getKey(action, userId, businessId);
    this.inMemoryStore.delete(key);

    // Also reset in Firestore if businessId is provided
    if (businessId) {
      try {
        const context: SecurityContext = {
          businessId,
          userId,
          userName: 'System',
          userRole: 'system',
        };

        const repository = getRateLimitRepository();
        await repository.resetByKey(context, key);
      } catch {
        // Persistence failures are non-blocking
        // Error handling per HIPAA guidelines - no logging of user actions
      }
    }
  }

  /**
   * Get current usage for an action
   */
  async getUsage(
    action: RateLimitAction,
    userId: string,
    businessId?: string
  ): Promise<{
    count: number;
    limit: number;
    remaining: number;
    resetAt: Date;
  }> {
    const config = this.limits[action];
    const activeConfig = config ?? UNKNOWN_ACTION_FALLBACK;

    const key = this.getKey(action, userId, businessId);
    const now = Date.now();
    const windowStart = now - activeConfig.windowMs;

    const entry = this.inMemoryStore.get(key);
    if (!entry) {
      return {
        count: 0,
        limit: activeConfig.maxActions,
        remaining: activeConfig.maxActions,
        resetAt: new Date(now + activeConfig.windowMs),
      };
    }

    // Filter to current window
    const validTimestamps = entry.timestamps.filter((ts) => ts > windowStart);
    const count = validTimestamps.length;
    const remaining = Math.max(0, activeConfig.maxActions - count);

    // Calculate reset time
    const oldestTimestamp = validTimestamps[0] || now;
    const resetAt = new Date(oldestTimestamp + activeConfig.windowMs);

    return {
      count,
      limit: activeConfig.maxActions,
      remaining,
      resetAt,
    };
  }

  /**
   * Update rate limit configuration
   */
  updateLimit(action: RateLimitAction, config: RateLimitConfig): void {
    this.limits[action] = config;
  }

  /**
   * Get all rate limit configurations
   */
  getLimits(): Record<RateLimitAction, RateLimitConfig> {
    return { ...this.limits };
  }

  /**
   * Clear all rate limit data (for testing)
   */
  clearAll(): void {
    this.inMemoryStore.clear();
  }

  // ============================================
  // Private Helpers
  // ============================================

  /**
   * Generate unique key for action/user/business combination
   */
  private getKey(action: RateLimitAction, userId: string, businessId?: string): string {
    if (businessId) {
      return `${businessId}:${userId}:${action}`;
    }
    return `${userId}:${action}`;
  }

  /**
   * Persist rate limit data to Firestore using repository pattern
   */
  private async persistToFirestore(
    key: string,
    entry: RateLimitEntry,
    businessId?: string
  ): Promise<void> {
    if (!businessId) {
      return; // Can't persist without businessId
    }

    try {
      // Extract userId from key (format: businessId:userId:action or userId:action)
      const keyParts = key.split(':');
      const userId = keyParts.length === 3 ? keyParts[1] : keyParts[0];

      const context: SecurityContext = {
        businessId,
        userId,
        userName: 'System',
        userRole: 'system',
      };

      const data: RateLimitCreateData = {
        key,
        timestamps: entry.timestamps,
        lastReset: entry.lastReset,
      };

      const repository = getRateLimitRepository();
      await repository.save(context, data);
    } catch {
      // Fail silently - persistence is optional
      // Error handling per HIPAA guidelines - no logging of user actions
    }
  }



  /**
   * Hydrate in-memory store from Firestore
   * Note: This would require querying all documents in the rateLimits collection
   * For now, we rely on in-memory store and lazy loading
   * Full implementation would use repository.getAll() here
   */
  async hydrateFromFirestore(_businessId: string): Promise<void> {
    // Not implemented - in-memory store is primary source of truth
    // Firestore persistence is used for recovery/audit purposes only
  }
}

// ============================================
// Singleton Instance
// ============================================

let rateLimitServiceInstance: RateLimitService | null = null;

export function getRateLimitService(): RateLimitService {
  if (!rateLimitServiceInstance) {
    rateLimitServiceInstance = new RateLimitService();
  }
  return rateLimitServiceInstance;
}

// ============================================
// Utility Functions
// ============================================

/**
 * Convenience function to check rate limit
 */
export async function checkRateLimit(
  action: RateLimitAction,
  context: SecurityContext
): Promise<RateLimitResult> {
  const service = getRateLimitService();
  return service.checkLimit(action, context.userId, context.businessId);
}

/**
 * Convenience function to check and record
 */
export async function checkAndRecordRateLimit(
  action: RateLimitAction,
  context: SecurityContext
): Promise<RateLimitResult> {
  const service = getRateLimitService();
  return service.checkAndRecord(action, context.userId, context.businessId);
}
