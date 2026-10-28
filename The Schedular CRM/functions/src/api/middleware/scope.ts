/**
 * Scope Checking Middleware
 * Validates that API key has required scope for the requested operation
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - Enforces principle of least privilege
 * - Scope checks occur after authentication
 * - No PHI in error messages
 *
 * Security:
 * - Fine-grained permission checking
 * - Multiple scope validation options
 */

import { Request, Response, NextFunction } from 'express';
import type { ApiScope, AuthenticatedRequest } from '../types';

/**
 * Check if the authenticated API key has the required scope
 */
export function checkScope(requiredScope: ApiScope) {
  return (req: Request, res: Response, next: NextFunction): void => {
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

    // Check if key has the required scope
    const hasScope = authReq.apiKey.scopes.includes(requiredScope);

    if (!hasScope) {
      res.status(403).json({
        error: {
          code: 'INSUFFICIENT_SCOPE',
          message: `This operation requires the '${requiredScope}' scope`,
        },
        meta: { requestId, timestamp },
      });
      return;
    }

    next();
  };
}

/**
 * Check if the authenticated API key has any of the required scopes
 */
export function checkAnyScope(requiredScopes: ApiScope[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
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

    // Check if key has any of the required scopes
    const hasAnyScope = requiredScopes.some((scope) =>
      authReq.apiKey.scopes.includes(scope)
    );

    if (!hasAnyScope) {
      res.status(403).json({
        error: {
          code: 'INSUFFICIENT_SCOPE',
          message: `This operation requires one of: ${requiredScopes.join(', ')}`,
        },
        meta: { requestId, timestamp },
      });
      return;
    }

    next();
  };
}

/**
 * Check if the authenticated API key has all of the required scopes
 */
export function checkAllScopes(requiredScopes: ApiScope[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
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

    // Check if key has all of the required scopes
    const missingScopes = requiredScopes.filter(
      (scope) => !authReq.apiKey.scopes.includes(scope)
    );

    if (missingScopes.length > 0) {
      res.status(403).json({
        error: {
          code: 'INSUFFICIENT_SCOPE',
          message: `Missing required scopes: ${missingScopes.join(', ')}`,
        },
        meta: { requestId, timestamp },
      });
      return;
    }

    next();
  };
}

export default checkScope;
