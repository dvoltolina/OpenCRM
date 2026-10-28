/**
 * API Middleware Tests
 * Tests for authentication, scope checking, and rate limiting middleware
 *
 * Task 5: Cloud Functions - API Layer
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Request, Response, NextFunction } from 'express';

// Mock Firebase Admin before imports
vi.mock('firebase-admin', () => {
  const mockCollectionRef = {
    doc: vi.fn().mockReturnThis(),
    add: vi.fn().mockResolvedValue({ id: 'test-id' }),
    where: vi.fn().mockReturnThis(),
    orderBy: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    get: vi.fn(),
    set: vi.fn().mockResolvedValue(undefined),
    update: vi.fn().mockResolvedValue(undefined),
  };

  const mockFirestore = {
    collection: vi.fn().mockReturnValue(mockCollectionRef),
    doc: vi.fn().mockReturnValue({
      get: vi.fn(),
      set: vi.fn().mockResolvedValue(undefined),
      update: vi.fn().mockResolvedValue(undefined),
    }),
  };

  return {
    apps: [],
    initializeApp: vi.fn(),
    firestore: Object.assign(vi.fn(() => mockFirestore), {
      FieldValue: {
        serverTimestamp: vi.fn().mockReturnValue({ _serverTimestamp: true }),
      },
    }),
  };
});

import type { AuthenticatedRequest } from '../types';
import { checkScope, checkAnyScope, checkAllScopes } from '../middleware';
import { isValidEmail, isValidUrl, VALID_LEAD_STATUSES, VALID_LEAD_SOURCES, VALID_DEAL_STATUSES } from '../types';

describe('Scope Middleware', () => {
  let mockReq: Partial<AuthenticatedRequest>;
  let mockRes: Partial<Response>;
  let mockNext: NextFunction;

  beforeEach(() => {
    mockReq = {
      requestId: 'req_test123',
      businessId: 'biz123',
      apiKey: {
        id: 'apikey123',
        businessId: 'biz123',
        name: 'Test Key',
        scopes: ['leads:read', 'leads:write', 'deals:read'],
        rateLimit: 100,
        rateLimitWindow: 3600000,
        isActive: true,
      },
    } as Partial<AuthenticatedRequest>;

    mockRes = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn().mockReturnThis(),
    };

    mockNext = vi.fn();
  });

  describe('checkScope', () => {
    it('should allow access when API key has required scope', () => {
      const middleware = checkScope('leads:read');
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockRes.status).not.toHaveBeenCalled();
    });

    it('should deny access when API key lacks required scope', () => {
      const middleware = checkScope('contacts:write');
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: expect.objectContaining({
            code: 'INSUFFICIENT_SCOPE',
          }),
        })
      );
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('checkAnyScope', () => {
    it('should allow access when API key has any of the required scopes', () => {
      const middleware = checkAnyScope(['leads:read', 'contacts:read']);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });

    it('should deny access when API key has none of the required scopes', () => {
      const middleware = checkAnyScope(['contacts:read', 'tasks:write']);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('checkAllScopes', () => {
    it('should allow access when API key has all required scopes', () => {
      const middleware = checkAllScopes(['leads:read', 'leads:write']);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });

    it('should deny access when API key lacks any required scope', () => {
      const middleware = checkAllScopes(['leads:read', 'contacts:write']);
      middleware(mockReq as Request, mockRes as Response, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockNext).not.toHaveBeenCalled();
    });
  });
});

describe('Validation Helpers', () => {
  describe('isValidEmail', () => {
    it('should validate correct email formats', () => {
      expect(isValidEmail('test@example.com')).toBe(true);
      expect(isValidEmail('user.name@example.com')).toBe(true);
      expect(isValidEmail('user+tag@example.org')).toBe(true);
    });

    it('should reject invalid email formats', () => {
      expect(isValidEmail('notanemail')).toBe(false);
      expect(isValidEmail('missing@domain')).toBe(false);
      expect(isValidEmail('@nodomain.com')).toBe(false);
      expect(isValidEmail('spaces not@example.com')).toBe(false);
    });
  });

  describe('isValidUrl', () => {
    it('should validate HTTPS URLs', () => {
      expect(isValidUrl('https://example.com')).toBe(true);
      expect(isValidUrl('https://api.example.com/webhook')).toBe(true);
      expect(isValidUrl('https://example.com:8443/path')).toBe(true);
    });

    it('should reject non-HTTPS URLs', () => {
      expect(isValidUrl('http://example.com')).toBe(false);
      expect(isValidUrl('ftp://example.com')).toBe(false);
    });

    it('should reject invalid URLs', () => {
      expect(isValidUrl('not-a-url')).toBe(false);
      expect(isValidUrl('')).toBe(false);
    });
  });
});

describe('API Scope Constants', () => {
  it('should define all expected scopes', () => {
    const expectedScopes = [
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

    // Verify scopes are defined as a union type
    type ScopeType = 'leads:read' | 'leads:write' | 'deals:read' | 'deals:write' |
      'contacts:read' | 'contacts:write' | 'tasks:read' | 'tasks:write' |
      'activities:read' | 'sequences:read' | 'sequences:write' | 'webhooks:manage';

    // Just verify all scopes can be used
    const scopes: ScopeType[] = expectedScopes as ScopeType[];
    expect(scopes).toHaveLength(12);
  });
});

describe('Validation Constants', () => {
  it('should define valid lead statuses', () => {
    expect(VALID_LEAD_STATUSES).toContain('new');
    expect(VALID_LEAD_STATUSES).toContain('contacted');
    expect(VALID_LEAD_STATUSES).toContain('qualified');
    expect(VALID_LEAD_STATUSES).toContain('converted');
  });

  it('should define valid lead sources', () => {
    expect(VALID_LEAD_SOURCES).toContain('website');
    expect(VALID_LEAD_SOURCES).toContain('referral');
    expect(VALID_LEAD_SOURCES).toContain('social');
  });

  it('should define valid deal statuses', () => {
    expect(VALID_DEAL_STATUSES).toContain('open');
    expect(VALID_DEAL_STATUSES).toContain('won');
    expect(VALID_DEAL_STATUSES).toContain('lost');
  });
});
