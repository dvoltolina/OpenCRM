/**
 * Integration Types
 * Shared types for email/calendar sync, webhook delivery, API keys, and dead-letter logging.
 *
 * HIPAA Compliance:
 * - Only IDs and hashes are represented here. Do not place PHI in any field.
 * - API responses must never include PHI in error messages
 * - Webhook payloads must be sanitized, don't send full records
 * - API logging must exclude sensitive data
 * - Integration tokens must be encrypted at rest
 * - Data minimization: API responses should only include necessary fields
 *
 * Security Considerations:
 * - API keys hashed with SHA-256, never stored plain
 * - Webhook secrets for HMAC signature verification
 * - Rate limiting per API key
 * - Scope-based access control
 * - OAuth tokens encrypted at rest
 * - Webhook delivery retries with exponential backoff
 * - API request logging for audit
 */

// ============================================
// Integration Core Types
// ============================================

/**
 * Type of integration connection
 * - zapier: Zapier platform integration
 * - webhook: Custom webhook endpoints
 * - native: Built-in integrations (Slack, Google, etc.)
 * - api_key: External API access
 */
export type IntegrationType = 'zapier' | 'webhook' | 'native' | 'api_key';

/**
 * Status of an integration connection
 * - active: Integration is working normally
 * - inactive: Integration is disabled
 * - error: Integration encountered an error
 * - pending_auth: Awaiting OAuth completion
 */
export type IntegrationStatus = 'active' | 'inactive' | 'error' | 'pending_auth';

/**
 * Events that can trigger webhooks
 * Used for both outbound webhooks and Zapier triggers
 */
export type WebhookEvent =
  | 'lead.created'
  | 'lead.updated'
  | 'lead.converted'
  | 'deal.created'
  | 'deal.updated'
  | 'deal.stage_changed'
  | 'deal.won'
  | 'deal.lost'
  | 'contact.created'
  | 'contact.updated'
  | 'task.created'
  | 'task.completed'
  | 'email.sent'
  | 'email.opened'
  | 'sequence.enrolled'
  | 'sequence.completed'
  | 'form.submitted';

/**
 * Third-party integration record
 * Path: businesses/{businessId}/integrations/{integrationId}
 *
 * HIPAA: accessToken and refreshToken must be encrypted at rest
 */
export interface Integration {
  id: string;
  businessId: string;
  name: string;
  description?: string;

  type: IntegrationType;
  /** Provider identifier e.g., 'salesforce', 'hubspot', 'slack' */
  provider?: string;

  // Status
  status: IntegrationStatus;
  lastSyncAt?: Date;
  lastErrorAt?: Date;
  /** Sanitized error message - never include PHI */
  lastErrorMessage?: string;

  /** Configuration (encrypted for sensitive data) */
  config: Record<string, unknown>;

  // OAuth (if applicable) - MUST be encrypted at rest
  accessToken?: string;
  refreshToken?: string;
  tokenExpiresAt?: Date;
  scopes?: string[];

  // Metadata
  createdById: string;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Webhook Types
// ============================================

/**
 * Outbound webhook endpoint configuration
 * Path: businesses/{businessId}/webhook_endpoints/{webhookId}
 *
 * HIPAA: secret is used for HMAC signature verification
 */
export interface WebhookEndpoint {
  id: string;
  businessId: string;
  name: string;
  description?: string;

  // Endpoint config - MUST be HTTPS in production
  url: string;
  /** Secret for HMAC-SHA256 signature verification */
  secret: string;
  /** Events this endpoint subscribes to */
  events: WebhookEvent[];

  // Status
  isActive: boolean;
  lastTriggeredAt?: Date;
  failureCount: number;
  lastFailureAt?: Date;
  /** Sanitized failure reason - never include PHI */
  lastFailureReason?: string;

  /** Optional custom headers for endpoint authentication */
  customHeaders?: Record<string, string>;

  // Retry config
  retryEnabled: boolean;
  /** Maximum retry attempts (default: 3) */
  maxRetries: number;

  createdById: string;
  createdAt: Date;
  updatedAt?: Date;
}

/**
 * Webhook delivery attempt record
 * Path: businesses/{businessId}/webhook_deliveries/{deliveryId}
 *
 * HIPAA: payload must be sanitized, responseBody must not contain PHI
 */
export interface WebhookDelivery {
  id: string;
  businessId: string;
  webhookId: string;

  // Event info
  event: WebhookEvent;
  /** Sanitized payload - no PHI */
  payload: Record<string, unknown>;

  // Delivery status
  status: 'pending' | 'success' | 'failed' | 'retrying';
  attemptCount: number;
  lastAttemptAt?: Date;
  nextRetryAt?: Date;

  // Response - sanitized, no PHI
  responseStatus?: number;
  responseBody?: string;
  responseTimeMs?: number;

  createdAt: Date;
}

// ============================================
// API Key Types
// ============================================

/**
 * API access scopes for fine-grained permissions
 */
export type ApiScope =
  | 'leads:read'
  | 'leads:write'
  | 'deals:read'
  | 'deals:write'
  | 'contacts:read'
  | 'contacts:write'
  | 'tasks:read'
  | 'tasks:write'
  | 'activities:read'
  | 'sequences:read'
  | 'sequences:write'
  | 'webhooks:manage';

/**
 * API key for external API access
 * Path: businesses/{businessId}/api_keys/{keyId}
 *
 * Security: Full key is shown only once on creation.
 * Only keyPrefix and keyHash are stored. keyHash is SHA-256.
 */
export interface ApiKey {
  id: string;
  businessId: string;
  name: string;
  description?: string;

  /** First 8 characters for identification (e.g., "sk_live_") */
  keyPrefix: string;
  /** SHA-256 hash of the full key - never store plain key */
  keyHash: string;

  // Permissions
  scopes: ApiScope[];

  // Rate limits
  /** Requests per rate limit window (default: 60) */
  rateLimit: number;
  /** Rate limit window in seconds (default: 60) */
  rateLimitWindow: number;

  // Status
  isActive: boolean;
  lastUsedAt?: Date;
  usageCount: number;

  // Optional expiration
  expiresAt?: Date;

  createdById: string;
  createdAt: Date;
  updatedAt?: Date;
}

/**
 * API request log for audit trail
 * Path: businesses/{businessId}/api_requests/{requestId}
 *
 * HIPAA: Do not log request/response bodies. Only log metadata for audit.
 */
export interface ApiRequest {
  id: string;
  businessId: string;
  apiKeyId: string;

  // Request info
  method: string;
  path: string;
  /** Query parameters (sanitized, no PHI) */
  queryParams?: Record<string, string>;

  // Response
  statusCode: number;
  responseTimeMs: number;

  // Metadata for audit
  ipAddress: string;
  userAgent?: string;

  createdAt: Date;
}

// ============================================
// API Validation Result Types
// ============================================

/**
 * Result of API key validation
 */
export interface ApiKeyValidationResult {
  valid: boolean;
  apiKey?: ApiKey;
  businessId?: string;
  /** Sanitized error message */
  error?: string;
}

/**
 * Rate limit check result
 */
export interface RateLimitCheckResult {
  allowed: boolean;
  remaining: number;
  resetAt: Date;
}

/**
 * API usage statistics
 */
export interface ApiUsageStats {
  requests: number;
  byEndpoint: Record<string, number>;
}

// ============================================
// Webhook Test Result Types
// ============================================

/**
 * Result of testing a webhook endpoint
 */
export interface WebhookTestResult {
  success: boolean;
  statusCode?: number;
  responseTimeMs?: number;
  /** Sanitized error message */
  error?: string;
}

// ============================================
// Legacy Types (preserved for compatibility)
// ============================================

/**
 * Integration provider for email/calendar sync
 * @deprecated Use IntegrationType and Integration.provider instead
 */
export type IntegrationProvider =
  | 'google_calendar'
  | 'outlook_calendar'
  | 'gmail'
  | 'outlook_mail'
  | 'zapier';

/**
 * Integration credential for OAuth flows
 * Used by email/calendar sync services
 */
export interface IntegrationCredential {
  businessId: string;
  provider: IntegrationProvider;
  integrationId?: string;
  accessToken: string;
  refreshToken?: string;
  expiresAt: Date;
  tokenType?: 'oauth' | 'service';
  signatureSecret?: string;
  tenantScoped?: boolean;
  staffId?: string;
}

export interface SyncRecord {
  id: string;
  updatedAt: Date;
  hash?: string;
  remoteChecksum?: string;
}

export interface SyncBatch<T extends SyncRecord> {
  items: T[];
  cursor?: string;
}

export interface SyncConflict {
  itemId: string;
  localUpdatedAt: Date;
  remoteUpdatedAt: Date;
  resolution: 'local' | 'remote' | 'manual';
  reason?: string;
}

export interface SyncResult {
  success: boolean;
  created: number;
  updated: number;
  skipped: number;
  conflicts: SyncConflict[];
  retried: number;
  backoffMs?: number;
  resumeCursor?: string;
  errors?: string[];
}

/**
 * Dead letter event for failed webhook deliveries
 * Path: businesses/{businessId}/webhook_dead_letters/{deadLetterId}
 */
export interface DeadLetterEvent {
  id: string;
  businessId: string;
  /** HTTPS destination URL only */
  destination: string;
  /** Sanitized reason - no PHI */
  reason: string;
  attempts: number;
  lastAttemptAt: Date;
  /** Hash of payload - never store actual payload */
  payloadHash: string;
  status: 'pending' | 'retrying' | 'failed' | 'deleted';
  nextRetryAt?: Date;
  lastHttpStatus?: number;
  errorCode?: string;
  replayCursor?: string;
}

/**
 * Webhook event envelope for inbound/outbound webhooks
 */
export interface WebhookEventEnvelope {
  id: string;
  type: string;
  businessId: string;
  occurredAt: Date;
  /** HMAC-SHA256 signature for verification */
  signature: string;
  /** Sanitized payload - no PHI */
  payload: unknown;
}
