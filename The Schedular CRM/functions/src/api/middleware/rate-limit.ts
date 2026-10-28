/**
 * Rate Limiting Middleware
 * Enforces per-API-key rate limits using sliding window algorithm
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - Rate limiting prevents abuse and data exfiltration
 * - No PHI in rate limit responses
 *
 * Security:
 * - Sliding window algorithm for accurate rate limiting
 * - Per-key configurable limits
 * - Rate limit headers in all responses
 */

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import type { AuthenticatedRequest } from '../types';

// In-memory rate limit store (for single-instance functions)
// For production with multiple instances, use Redis or Firestore
interface RateLimitEntry {
  timestamps: number[];
  windowStart: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();

// Initialize Firestore if not already initialized
const getDb = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
};

/**
 * Clean up old timestamps outside the rate limit window
 */
function cleanupTimestamps(entry: RateLimitEntry, windowMs: number): number[] {
  const now = Date.now();
  const windowStart = now - windowMs;
  return entry.timestamps.filter((ts) => ts > windowStart);
}

/**
 * Rate limiting middleware
 * Uses the rate limit configuration from the authenticated API key
 */
export async function checkRateLimit(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const requestId = authReq.requestId || 'unknown';
  const timestamp = new Date().toISOString();

  // Ensure authentication was performed
  if (!authReq.apiKey) {
    res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      },
      meta: { requestId, timestamp },
    });
    return;
  }

  const { id: keyId, rateLimit, rateLimitWindow } = authReq.apiKey;
  const windowMs = rateLimitWindow * 1000;
  const now = Date.now();

  // Get or create rate limit entry
  let entry = rateLimitStore.get(keyId);

  if (!entry) {
    entry = {
      timestamps: [],
      windowStart: now,
    };
  }

  // Clean up old timestamps
  entry.timestamps = cleanupTimestamps(entry, windowMs);

  // Calculate current usage
  const currentCount = entry.timestamps.length;
  const remaining = Math.max(0, rateLimit - currentCount);
  const allowed = currentCount < rateLimit;

  // Calculate reset time
  const oldestTimestamp = entry.timestamps[0] || now;
  const resetAt = new Date(oldestTimestamp + windowMs);

  // Set rate limit headers
  res.setHeader('X-RateLimit-Limit', rateLimit.toString());
  res.setHeader('X-RateLimit-Remaining', remaining.toString());
  res.setHeader('X-RateLimit-Reset', resetAt.toISOString());

  if (!allowed) {
    res.status(429).json({
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: `Rate limit exceeded. Try again at ${resetAt.toISOString()}`,
      },
      meta: { requestId, timestamp },
    });
    return;
  }

  // Record this request
  entry.timestamps.push(now);
  rateLimitStore.set(keyId, entry);

  next();
}

/**
 * Record API usage in Firestore for persistent tracking
 * Called after successful request processing
 */
export async function recordApiUsage(
  businessId: string,
  keyId: string,
  method: string,
  path: string,
  statusCode: number,
  responseTimeMs: number,
  ipAddress: string,
  userAgent?: string
): Promise<void> {
  try {
    const db = getDb();

    // Update API key usage count
    const keyRef = db.doc(`businesses/${businessId}/api_keys/${keyId}`);
    await keyRef.update({
      usageCount: admin.firestore.FieldValue.increment(1),
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log API request for audit (no PHI)
    const requestRef = db.collection(`businesses/${businessId}/api_requests`).doc();
    await requestRef.set({
      apiKeyId: keyId,
      method,
      path,
      statusCode,
      responseTimeMs,
      ipAddress,
      userAgent: userAgent || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    // Log error but don't fail the request
    console.error('Failed to record API usage:', error);
  }
}

/**
 * Middleware to record API usage after response
 */
export function recordUsageMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authReq = req as AuthenticatedRequest;
  const startTime = Date.now();

  // Hook into response finish event
  res.on('finish', () => {
    if (authReq.apiKey && authReq.businessId) {
      const responseTimeMs = Date.now() - startTime;
      const ipAddress = req.ip || req.socket.remoteAddress || 'unknown';
      const userAgent = req.headers['user-agent'];

      // Record usage asynchronously (don't block response)
      recordApiUsage(
        authReq.businessId,
        authReq.apiKey.id,
        req.method,
        req.path,
        res.statusCode,
        responseTimeMs,
        ipAddress,
        userAgent
      ).catch((err) => console.error('Usage recording failed:', err));
    }
  });

  next();
}

/**
 * Clear rate limit cache for a specific key
 * Useful for testing or when key is revoked
 */
export function clearRateLimitCache(keyId: string): void {
  rateLimitStore.delete(keyId);
}

/**
 * Clear all rate limit caches
 * Useful for testing
 */
export function clearAllRateLimitCaches(): void {
  rateLimitStore.clear();
}

export default checkRateLimit;
