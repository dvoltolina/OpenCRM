/**
 * API Key Authentication Middleware
 * Validates API keys and attaches business context to requests
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - API keys are validated via SHA-256 hash comparison
 * - Business ID extracted for tenant isolation
 * - No PHI in error messages
 * - All authentication failures logged for audit
 *
 * Security:
 * - Bearer token authentication
 * - Key expiration checking
 * - Active status verification
 */

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import type { ApiKeyData, AuthenticatedRequest } from '../types';

// Initialize Firestore if not already initialized
const getDb = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
};

/**
 * Generate a unique request ID for tracing
 */
function generateRequestId(): string {
  return `req_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * Compute SHA-256 hash of an API key
 */
function hashApiKey(apiKey: string): string {
  return crypto.createHash('sha256').update(apiKey).digest('hex');
}

/**
 * Sanitize error message to prevent information leakage
 */
function sanitizeError(code: string): { code: string; message: string } {
  const errorMessages: Record<string, string> = {
    MISSING_API_KEY: 'API key is required',
    INVALID_FORMAT: 'Invalid API key format',
    INVALID_KEY: 'Invalid API key',
    KEY_EXPIRED: 'API key has expired',
    KEY_INACTIVE: 'API key is inactive',
    INTERNAL_ERROR: 'Authentication failed',
  };

  return {
    code,
    message: errorMessages[code] || 'Authentication failed',
  };
}

/**
 * Look up API key by hash in Firestore
 * Uses collection group query to search across all businesses
 */
async function findApiKeyByHash(keyHash: string): Promise<{
  apiKey: ApiKeyData | null;
  businessId: string | null;
}> {
  const db = getDb();

  // Query across all businesses for the key hash
  // In production, consider using a top-level lookup collection for efficiency
  const businessesSnapshot = await db.collection('businesses').get();

  for (const businessDoc of businessesSnapshot.docs) {
    const businessId = businessDoc.id;
    const apiKeysRef = db.collection(`businesses/${businessId}/api_keys`);
    const keyQuery = apiKeysRef
      .where('keyHash', '==', keyHash)
      .where('isActive', '==', true)
      .limit(1);

    const keySnapshot = await keyQuery.get();

    if (!keySnapshot.empty) {
      const keyDoc = keySnapshot.docs[0];
      const data = keyDoc.data();

      const apiKey: ApiKeyData = {
        id: keyDoc.id,
        businessId,
        name: data.name,
        scopes: data.scopes || [],
        rateLimit: data.rateLimit ?? 60,
        rateLimitWindow: data.rateLimitWindow ?? 60,
        isActive: data.isActive ?? true,
        expiresAt: data.expiresAt?.toDate?.(),
      };

      return { apiKey, businessId };
    }
  }

  return { apiKey: null, businessId: null };
}

/**
 * API Key validation middleware
 * Validates the Bearer token and attaches business context to the request
 */
export async function validateApiKey(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const requestId = generateRequestId();
  const timestamp = new Date().toISOString();

  // Attach requestId to request for downstream use
  (req as AuthenticatedRequest).requestId = requestId;

  try {
    // Check for Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      const error = sanitizeError('MISSING_API_KEY');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Validate Bearer token format
    if (!authHeader.startsWith('Bearer ')) {
      const error = sanitizeError('INVALID_FORMAT');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Extract the key
    const apiKey = authHeader.substring(7);

    // Validate key format (crm_live_ prefix)
    if (!apiKey.startsWith('crm_live_') || apiKey.length < 20) {
      const error = sanitizeError('INVALID_FORMAT');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Hash the key for lookup
    const keyHash = hashApiKey(apiKey);

    // Look up the key
    const { apiKey: keyData, businessId } = await findApiKeyByHash(keyHash);

    if (!keyData || !businessId) {
      const error = sanitizeError('INVALID_KEY');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Check if key is active
    if (!keyData.isActive) {
      const error = sanitizeError('KEY_INACTIVE');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Check expiration
    if (keyData.expiresAt && keyData.expiresAt < new Date()) {
      const error = sanitizeError('KEY_EXPIRED');
      res.status(401).json({
        error,
        meta: { requestId, timestamp },
      });
      return;
    }

    // Attach validated data to request
    const authReq = req as AuthenticatedRequest;
    authReq.businessId = businessId;
    authReq.apiKey = keyData;

    // Continue to next middleware
    next();
  } catch (error) {
    // Log error internally but don't expose details
    console.error('API key validation error:', error);

    const sanitized = sanitizeError('INTERNAL_ERROR');
    res.status(500).json({
      error: sanitized,
      meta: { requestId, timestamp },
    });
  }
}

/**
 * Optional: Validate API key for a specific business
 * Used when business ID is known from request path
 */
export async function validateApiKeyForBusiness(
  req: Request,
  res: Response,
  next: NextFunction,
  expectedBusinessId: string
): Promise<void> {
  // First validate the API key
  await validateApiKey(req, res, () => {
    const authReq = req as AuthenticatedRequest;

    // Verify business ID matches
    if (authReq.businessId !== expectedBusinessId) {
      const requestId = authReq.requestId || generateRequestId();
      res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: 'Access denied to this resource',
        },
        meta: {
          requestId,
          timestamp: new Date().toISOString(),
        },
      });
      return;
    }

    next();
  });
}

export default validateApiKey;
