/**
 * Base Integration Tests
 * Tests for the abstract BaseIntegration class
 *
 * Task 8: Native Integrations Framework
 */

import { BaseIntegration } from '../base-integration';
import type {
  SecurityContext,
  RepositoryResult,
} from '../../../data/repositories/repository-types';
import type { Integration } from '../../../types/integrations';
import { successResult } from '../../../data/errors/repository-errors';

// ============================================
// Mock Implementation
// ============================================

class MockIntegration extends BaseIntegration {
  readonly name = 'Mock Integration';
  readonly type = 'native' as const;
  readonly provider = 'mock';
  protected readonly authUrl = 'https://mock.example.com/oauth/authorize';
  protected readonly tokenUrl = 'https://mock.example.com/oauth/token';
  protected readonly requiredScopes = ['read', 'write'];

  async connect(
    _context: SecurityContext,
    _authData: unknown
  ): Promise<RepositoryResult<Integration>> {
    return successResult({
      id: 'mock-integration-id',
      businessId: 'test-business',
      name: this.name,
      type: this.type,
      provider: this.provider,
      status: 'active',
      config: {},
      scopes: this.requiredScopes,
      createdById: 'test-user',
      createdAt: new Date(),
    });
  }

  async disconnect(
    _context: SecurityContext,
    _integrationId: string
  ): Promise<RepositoryResult<void>> {
    return successResult(undefined);
  }

  async sync(
    _context: SecurityContext,
    _integrationId: string
  ): Promise<any> {
    return successResult({
      success: true,
      created: 0,
      updated: 0,
      skipped: 0,
      conflicts: [],
      retried: 0,
      integrationId: 'mock-id',
      syncedAt: new Date(),
    });
  }

  getAuthorizationUrl(_context: SecurityContext, _redirectUri: string): string {
    return 'https://mock.example.com/oauth/authorize?client_id=test';
  }
}

// ============================================
// Test Setup
// ============================================

describe('BaseIntegration', () => {
  let integration: MockIntegration;
  let mockContext: SecurityContext;

  beforeEach(() => {
    integration = new MockIntegration();
    mockContext = {
      businessId: 'test-business-id',
      userId: 'test-user-id',
      userName: 'Test User',
      userRole: 'admin',
    };
  });

  // ============================================
  // Core Properties Tests
  // ============================================

  describe('Core Properties', () => {
    it('should have required properties', () => {
      expect(integration.name).toBe('Mock Integration');
      expect(integration.type).toBe('native');
      expect(integration.provider).toBe('mock');
    });

    it('should have OAuth URLs', () => {
      expect(integration['authUrl']).toBe('https://mock.example.com/oauth/authorize');
      expect(integration['tokenUrl']).toBe('https://mock.example.com/oauth/token');
    });

    it('should have required scopes', () => {
      expect(integration['requiredScopes']).toEqual(['read', 'write']);
    });
  });

  // ============================================
  // PHI Field Detection Tests
  // ============================================

  describe('isPHIField', () => {
    it('should identify firstName as PHI', () => {
      expect(integration['isPHIField']('firstName')).toBe(true);
    });

    it('should identify lastName as PHI', () => {
      expect(integration['isPHIField']('lastName')).toBe(true);
    });

    it('should identify email as PHI', () => {
      expect(integration['isPHIField']('email')).toBe(true);
    });

    it('should identify phone as PHI', () => {
      expect(integration['isPHIField']('phone')).toBe(true);
    });

    it('should identify address as PHI', () => {
      expect(integration['isPHIField']('address')).toBe(true);
    });

    it('should identify notes as PHI', () => {
      expect(integration['isPHIField']('notes')).toBe(true);
    });

    it('should identify customFields as PHI', () => {
      expect(integration['isPHIField']('customFields')).toBe(true);
    });

    it('should NOT identify non-PHI fields', () => {
      expect(integration['isPHIField']('id')).toBe(false);
      expect(integration['isPHIField']('createdAt')).toBe(false);
      expect(integration['isPHIField']('status')).toBe(false);
    });

    it('should be case-insensitive', () => {
      expect(integration['isPHIField']('FirstName')).toBe(true);
      expect(integration['isPHIField']('LASTNAME')).toBe(true);
    });
  });

  // ============================================
  // String Sanitization Tests
  // ============================================

  describe('sanitizeStringValue', () => {
    it('should sanitize email addresses', () => {
      const input = 'Contact john.doe@example.com for details';
      const output = integration['sanitizeStringValue'](input);
      expect(output).toBe('Contact [EMAIL] for details');
    });

    it('should sanitize phone numbers', () => {
      const input = 'Call 123-456-7890 or 987.654.3210';
      const output = integration['sanitizeStringValue'](input);
      expect(output).toBe('Call [PHONE] or [PHONE]');
    });

    it('should sanitize SSN', () => {
      const input = 'SSN: 123-45-6789';
      const output = integration['sanitizeStringValue'](input);
      expect(output).toBe('SSN: [SSN]');
    });

    it('should sanitize multiple patterns', () => {
      const input = 'Email: test@example.com, Phone: 555-123-4567, SSN: 123-45-6789';
      const output = integration['sanitizeStringValue'](input);
      expect(output).not.toContain('test@example.com');
      expect(output).not.toContain('555-123-4567');
      expect(output).not.toContain('123-45-6789');
    });

    it('should leave clean strings unchanged', () => {
      const input = 'This is a clean string with no PHI';
      const output = integration['sanitizeStringValue'](input);
      expect(output).toBe(input);
    });
  });

  // ============================================
  // Error Message Sanitization Tests
  // ============================================

  describe('sanitizeErrorMessage', () => {
    it('should sanitize email in error messages', () => {
      const input = 'Error: Invalid email john@example.com';
      const output = integration['sanitizeErrorMessage'](input);
      expect(output).toBe('Error: Invalid email [EMAIL]');
    });

    it('should sanitize phone in error messages', () => {
      const input = 'Failed to call 555-123-4567';
      const output = integration['sanitizeErrorMessage'](input);
      expect(output).toBe('Failed to call [PHONE]');
    });

    it('should sanitize names in error messages', () => {
      const input = 'User John Doe not found';
      const output = integration['sanitizeErrorMessage'](input);
      expect(output).toContain('[NAME]');
      expect(output).not.toContain('John Doe');
    });

    it('should truncate long error messages', () => {
      const input = 'A'.repeat(300);
      const output = integration['sanitizeErrorMessage'](input);
      expect(output.length).toBe(200);
    });

    it('should handle multiple PHI patterns', () => {
      const input =
        'Error for John Doe at john@example.com phone 555-123-4567 SSN 123-45-6789';
      const output = integration['sanitizeErrorMessage'](input);
      expect(output).not.toContain('john@example.com');
      expect(output).not.toContain('555-123-4567');
      expect(output).not.toContain('123-45-6789');
      expect(output).not.toContain('John Doe');
    });
  });

  // ============================================
  // Outbound Data Sanitization Tests
  // ============================================

  describe('sanitizeOutboundData', () => {
    it('should remove PHI fields', () => {
      const data = {
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        status: 'active',
      };

      const sanitized = integration['sanitizeOutboundData'](data);

      expect(sanitized.id).toBe('123');
      expect(sanitized.status).toBe('active');
      expect(sanitized.firstName).toBeUndefined();
      expect(sanitized.lastName).toBeUndefined();
      expect(sanitized.email).toBeUndefined();
    });

    it('should sanitize nested objects', () => {
      const data = {
        user: {
          id: '123',
          firstName: 'John',
          email: 'john@example.com',
        },
        status: 'active',
      };

      const sanitized = integration['sanitizeOutboundData'](data);

      expect(sanitized.status).toBe('active');
      expect((sanitized.user as any)?.id).toBe('123');
      expect((sanitized.user as any)?.firstName).toBeUndefined();
      expect((sanitized.user as any)?.email).toBeUndefined();
    });

    it('should sanitize arrays of objects', () => {
      const data = {
        users: [
          { id: '1', firstName: 'John', email: 'john@example.com' },
          { id: '2', firstName: 'Jane', email: 'jane@example.com' },
        ],
      };

      const sanitized = integration['sanitizeOutboundData'](data);

      expect((sanitized.users as any)?.[0]?.id).toBe('1');
      expect((sanitized.users as any)?.[0]?.firstName).toBeUndefined();
      expect((sanitized.users as any)?.[1]?.id).toBe('2');
      expect((sanitized.users as any)?.[1]?.firstName).toBeUndefined();
    });

    it('should sanitize string values', () => {
      const data = {
        id: '123',
        title: 'Contact john@example.com or call 555-123-4567',
      };

      const sanitized = integration['sanitizeOutboundData'](data);

      expect(sanitized.id).toBe('123');
      expect(typeof sanitized.title).toBe('string');
      if (typeof sanitized.title === 'string') {
        expect(sanitized.title).not.toContain('john@example.com');
        expect(sanitized.title).not.toContain('555-123-4567');
      }
    });
  });

  // ============================================
  // Security Context Validation Tests
  // ============================================

  describe('validateContext', () => {
    it('should accept valid admin context', () => {
      const context: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'admin',
      };

      expect(() => integration['validateContext'](context)).not.toThrow();
    });

    it('should accept valid owner context', () => {
      const context: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'owner',
      };

      expect(() => integration['validateContext'](context)).not.toThrow();
    });

    it('should reject missing businessId', () => {
      const context: SecurityContext = {
        businessId: '',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'admin',
      };

      expect(() => integration['validateContext'](context)).toThrow(
        'SecurityContext missing businessId'
      );
    });

    it('should reject missing userId', () => {
      const context: SecurityContext = {
        businessId: 'test-business',
        userId: '',
        userName: 'Test User',
        userRole: 'admin',
      };

      expect(() => integration['validateContext'](context)).toThrow(
        'SecurityContext missing userId'
      );
    });

    it('should reject non-admin/owner roles', () => {
      const context: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'staff',
      };

      expect(() => integration['validateContext'](context)).toThrow(
        'Only administrators can manage integrations'
      );
    });

    it('should reject client role', () => {
      const context: SecurityContext = {
        businessId: 'test-business',
        userId: 'test-user',
        userName: 'Test User',
        userRole: 'client',
      };

      expect(() => integration['validateContext'](context)).toThrow(
        'Only administrators can manage integrations'
      );
    });
  });

  // ============================================
  // HTTPS Enforcement Tests
  // ============================================

  describe('ensureHttps', () => {
    it('should accept HTTPS URLs', () => {
      expect(() =>
        integration['ensureHttps']('https://example.com/api')
      ).not.toThrow();
    });

    it('should reject HTTP URLs', () => {
      expect(() => integration['ensureHttps']('http://example.com/api')).toThrow(
        'All integration API calls must use HTTPS'
      );
    });

    it('should reject non-HTTP URLs', () => {
      expect(() => integration['ensureHttps']('ftp://example.com/api')).toThrow(
        'All integration API calls must use HTTPS'
      );
    });

    it('should accept HTTPS with ports', () => {
      expect(() =>
        integration['ensureHttps']('https://example.com:8443/api')
      ).not.toThrow();
    });

    it('should accept HTTPS with query params', () => {
      expect(() =>
        integration['ensureHttps']('https://example.com/api?key=value')
      ).not.toThrow();
    });
  });

  // ============================================
  // Abstract Method Tests
  // ============================================

  describe('Abstract Methods', () => {
    it('should implement connect method', async () => {
      const result = await integration.connect(mockContext, {});
      expect(result.success).toBe(true);
      expect(result.data?.provider).toBe('mock');
    });

    it('should implement disconnect method', async () => {
      const result = await integration.disconnect(mockContext, 'test-id');
      expect(result.success).toBe(true);
    });

    it('should implement sync method', async () => {
      const result = await integration.sync(mockContext, 'test-id');
      expect(result.success).toBe(true);
      expect(result.data?.integrationId).toBe('mock-id');
    });

    it('should implement getAuthorizationUrl method', () => {
      const url = integration.getAuthorizationUrl(mockContext, 'https://redirect.com');
      expect(url).toContain('https://mock.example.com');
    });
  });
});
