/**
 * Base Integration Class
 * Abstract base class for all native integrations
 *
 * Task 8: Native Integrations Framework
 *
 * HIPAA Compliance:
 * - All OAuth tokens must be encrypted at rest
 * - PHI must be sanitized before sending to external services
 * - All operations require SecurityContext for audit trails
 * - Error messages must be sanitized
 *
 * Security:
 * - RBAC enforcement via SecurityContext (admin/owner only)
 * - OAuth token encryption required
 * - All API calls over HTTPS only
 * - Webhook signature verification
 * - Rate limiting on API calls
 */

import type {
  SecurityContext,
  RepositoryResult,
} from '../../data/repositories/repository-types';
import type {
  Integration,
  IntegrationType,
  SyncResult,
} from '../../types/integrations';

// ============================================
// Base Integration Types
// ============================================

/**
 * OAuth authorization data for connecting an integration
 */
export interface OAuthAuthData {
  /** Authorization code from OAuth flow */
  authCode: string;
  /** Redirect URI used in OAuth flow */
  redirectUri: string;
  /** Optional state parameter for CSRF protection */
  state?: string;
}

/**
 * Result of a sync operation
 */
export interface IntegrationSyncResult extends SyncResult {
  /** Integration ID that was synced */
  integrationId: string;
  /** Timestamp when sync completed */
  syncedAt: Date;
}

/**
 * Webhook payload handler result
 */
export interface WebhookHandlerResult {
  success: boolean;
  /** Sanitized error message if failed */
  error?: string;
  /** Optional metadata about what was processed */
  metadata?: Record<string, unknown>;
}

// ============================================
// Abstract Base Integration Class
// ============================================

/**
 * Abstract base class for all native integrations
 *
 * All integrations must:
 * 1. Implement connect/disconnect lifecycle
 * 2. Support OAuth token refresh
 * 3. Provide sync capabilities
 * 4. Sanitize all outbound data per HIPAA
 * 5. Enforce SecurityContext for all operations
 * 6. Handle errors gracefully with sanitized messages
 */
export abstract class BaseIntegration {
  /**
   * Human-readable name of the integration
   */
  abstract readonly name: string;

  /**
   * Integration type identifier
   */
  abstract readonly type: IntegrationType;

  /**
   * Provider identifier (e.g., 'slack', 'google_calendar')
   */
  abstract readonly provider: string;

  /**
   * OAuth authorization URL template (if OAuth is supported)
   */
  protected abstract readonly authUrl?: string;

  /**
   * OAuth token URL (if OAuth is supported)
   */
  protected abstract readonly tokenUrl?: string;

  /**
   * Required OAuth scopes
   */
  protected abstract readonly requiredScopes?: string[];

  /**
   * Connect to the integration using OAuth or other auth method
   *
   * HIPAA: OAuth tokens must be encrypted before storage
   * Security: Only admin/owner can connect integrations
   *
   * @param context SecurityContext for authorization and audit trail
   * @param authData Authorization data (OAuth code, API key, etc.)
   * @returns Integration record with connection details
   */
  abstract connect(
    context: SecurityContext,
    authData: unknown
  ): Promise<RepositoryResult<Integration>>;

  /**
   * Disconnect from the integration
   *
   * Security: Only admin/owner can disconnect integrations
   *
   * @param context SecurityContext for authorization and audit trail
   * @param integrationId Integration ID to disconnect
   */
  abstract disconnect(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<void>>;

  /**
   * Sync data with the integration
   *
   * HIPAA: All outbound data must be sanitized (no PHI)
   *
   * @param context SecurityContext for authorization and audit trail
   * @param integrationId Integration ID to sync
   * @returns Sync result with counts and errors
   */
  abstract sync(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<IntegrationSyncResult>>;

  /**
   * Refresh OAuth tokens (if applicable)
   *
   * HIPAA: Tokens must be encrypted before storage
   *
   * @param context SecurityContext for authorization
   * @param integrationId Integration ID with expired token
   * @returns Updated integration with refreshed tokens
   */
  /**
   * Refresh OAuth tokens (if applicable)
   * Override in subclasses that support token refresh.
   */
  async refreshTokens?(
    _context: SecurityContext,
    _integrationId: string
  ): Promise<RepositoryResult<Integration>> {
    return { success: false, data: null, error: { code: 'VALIDATION_ERROR', message: 'Token refresh not supported by this integration' } };
  }

  /**
   * Handle incoming webhook from the integration (if applicable)
   * Override in subclasses that support webhooks.
   */
  async handleWebhook?(
    _payload: unknown,
    _signature: string
  ): Promise<WebhookHandlerResult> {
    return { success: false, error: 'Webhooks not supported by this integration' };
  }

  /**
   * Validate webhook signature
   * Override in subclasses that support webhooks.
   */
  protected validateWebhookSignature?(
    _payload: string,
    _signature: string,
    _secret: string
  ): boolean {
    return false;
  }

  /**
   * Get OAuth authorization URL for user to visit
   * Override in subclasses that support OAuth.
   */
  getAuthorizationUrl?(
    _context: SecurityContext,
    _redirectUri: string
  ): string {
    return '';
  }

  /**
   * Test integration connection
   * Override in subclasses that support connection testing.
   */
  async testConnection?(
    _context: SecurityContext,
    _integrationId: string
  ): Promise<RepositoryResult<{ success: boolean; message: string }>> {
    return { success: true, data: { success: true, message: 'Connection test not implemented' } } as RepositoryResult<{ success: boolean; message: string }>;
  }

  // ============================================
  // Protected Helper Methods
  // ============================================

  /**
   * Sanitize error message to prevent PHI leakage
   *
   * HIPAA: Error messages must never contain PHI
   *
   * @param message Raw error message
   * @returns Sanitized error message
   */
  protected sanitizeErrorMessage(message: string): string {
    return message
      .substring(0, 200)
      .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL]')
      .replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE]')
      .replace(/\b\d{3}[-.]?\d{4}\b/g, '[PHONE]')
      .replace(/\b\d{3}[-]?\d{2}[-]?\d{4}\b/g, '[SSN]')
      .replace(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b/g, '[NAME]');
  }

  /**
   * Sanitize data before sending to external service
   *
   * HIPAA: Remove all PHI from outbound data
   *
   * @param data Data to sanitize
   * @returns Sanitized data
   */
  protected sanitizeOutboundData(data: Record<string, unknown>): Record<string, unknown> {
    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(data)) {
      // Skip known PHI fields
      if (this.isPHIField(key)) {
        continue;
      }

      // Recursively sanitize nested objects
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        sanitized[key] = this.sanitizeOutboundData(value as Record<string, unknown>);
      } else if (Array.isArray(value)) {
        sanitized[key] = value.map((item) =>
          typeof item === 'object' ? this.sanitizeOutboundData(item) : item
        );
      } else if (typeof value === 'string') {
        // Sanitize string values
        sanitized[key] = this.sanitizeStringValue(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * Check if a field name indicates PHI
   *
   * @param fieldName Field name to check
   * @returns True if field likely contains PHI
   */
  protected isPHIField(fieldName: string): boolean {
    const phiFields = [
      'firstName',
      'lastName',
      'fullName',
      'name',
      'email',
      'phone',
      'phoneNumber',
      'address',
      'ssn',
      'notes',
      'description',
      'customFields',
      'crmNotes',
      'clientName',
      'contactName',
    ];

    return phiFields.some((phi) =>
      fieldName.toLowerCase().includes(phi.toLowerCase())
    );
  }

  /**
   * Sanitize a string value
   *
   * @param value String to sanitize
   * @returns Sanitized string
   */
  protected sanitizeStringValue(value: string): string {
    return value
      .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL]')
      .replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE]')
      .replace(/\b\d{3}[-.]?\d{4}\b/g, '[PHONE]')
      .replace(/\b\d{3}[-]?\d{2}[-]?\d{4}\b/g, '[SSN]')
      .replace(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b/g, '[NAME]');
  }

  /**
   * Validate SecurityContext
   *
   * @param context SecurityContext to validate
   * @throws Error if context is invalid
   */
  protected validateContext(context: SecurityContext): void {
    if (!context.businessId?.trim()) {
      throw new Error('SecurityContext missing businessId');
    }
    if (!context.userId?.trim()) {
      throw new Error('SecurityContext missing userId');
    }
    if (!['admin', 'owner'].includes(context.userRole)) {
      throw new Error('Only administrators can manage integrations');
    }
  }

  /**
   * Ensure HTTPS-only connections
   *
   * Security: All external API calls must use HTTPS
   *
   * @param url URL to validate
   * @throws Error if URL is not HTTPS
   */
  protected ensureHttps(url: string): void {
    if (!url.startsWith('https://')) {
      throw new Error('All integration API calls must use HTTPS');
    }
  }
}
