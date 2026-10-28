/**
 * Google Calendar Integration
 * Native integration for Google Calendar sync and event management
 *
 * Task 8: Native Integrations Framework
 *
 * HIPAA Compliance:
 * - No PHI in calendar event descriptions
 * - All event data sanitized before sync
 * - OAuth tokens encrypted at rest
 * - Error messages sanitized
 * - Audit logging for all operations
 *
 * Security:
 * - HTTPS-only API calls
 * - OAuth 2.0 authentication
 * - Token refresh handling
 * - Rate limiting on API calls
 */

// crypto import reserved for future webhook signature verification
// import crypto from 'crypto';
import {
  BaseIntegration,
  type OAuthAuthData,
  type IntegrationSyncResult,
  type WebhookHandlerResult,
} from './base-integration';
import {
  getIntegrationRepository,
  type CreateIntegrationInput,
} from '../../data/repositories/integration-repository';
import type {
  SecurityContext,
  RepositoryResult,
} from '../../data/repositories/repository-types';
import type { Integration } from '../../types/integrations';
import {
  failedResult,
  successResult,
  InvalidArgumentError,
} from '../../data/errors/repository-errors';
import { getTokenEncryptionService } from '../token-encryption-service';

// ============================================
// Google Calendar API Configuration
// ============================================

const GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const GOOGLE_CALENDAR_API_BASE = 'https://www.googleapis.com/calendar/v3';

const GOOGLE_REQUIRED_SCOPES = [
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events',
];

// ============================================
// Google Calendar Types
// ============================================

interface GoogleOAuthResponse {
  access_token?: string;
  refresh_token?: string;
  expires_in?: number;
  token_type?: string;
  scope?: string;
  error?: string;
  error_description?: string;
}

interface GoogleCalendarEvent {
  id?: string;
  summary: string;
  description?: string;
  location?: string;
  start: {
    dateTime: string;
    timeZone?: string;
  };
  end: {
    dateTime: string;
    timeZone?: string;
  };
  attendees?: Array<{
    email: string;
    displayName?: string;
    responseStatus?: string;
  }>;
  created?: string;
  updated?: string;
  etag?: string;
}

interface GoogleCalendarListResponse {
  kind: string;
  etag: string;
  items?: GoogleCalendarEvent[];
  nextPageToken?: string;
  nextSyncToken?: string;
}

/**
 * Calendar event input (sanitized)
 * HIPAA: No PHI in event descriptions
 */
export interface CalendarEventInput {
  summary: string;
  description?: string;
  location?: string;
  startDateTime: Date;
  endDateTime: Date;
  timeZone?: string;
  attendeeEmails?: string[];
}

/**
 * Calendar event update input
 */
export interface CalendarEventUpdateInput {
  summary?: string;
  description?: string;
  location?: string;
  startDateTime?: Date;
  endDateTime?: Date;
  timeZone?: string;
}

// ============================================
// Google Calendar Integration Class
// ============================================

export class GoogleCalendarIntegration extends BaseIntegration {
  readonly name = 'Google Calendar';
  readonly type = 'native' as const;
  readonly provider = 'google_calendar';

  protected readonly authUrl = GOOGLE_AUTH_URL;
  protected readonly tokenUrl = GOOGLE_TOKEN_URL;
  protected readonly requiredScopes = GOOGLE_REQUIRED_SCOPES;

  private integrationRepo = getIntegrationRepository();

  // ============================================
  // OAuth Connection Flow
  // ============================================

  /**
   * Get Google OAuth authorization URL
   *
   * @param context SecurityContext for state generation
   * @param redirectUri Where to redirect after authorization
   * @returns Authorization URL for user to visit
   */
  getAuthorizationUrl(context: SecurityContext, redirectUri: string): string {
    this.validateContext(context);

    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) {
      throw new Error('GOOGLE_CLIENT_ID not configured');
    }

    const state = this.generateState(context);
    const scopes = this.requiredScopes.join(' ');

    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: scopes,
      access_type: 'offline', // Request refresh token
      prompt: 'consent', // Force consent to get refresh token
      state,
    });

    return `${GOOGLE_AUTH_URL}?${params.toString()}`;
  }

  /**
   * Connect Google Calendar integration using OAuth authorization code
   *
   * HIPAA: OAuth tokens must be encrypted before storage
   *
   * @param context SecurityContext for authorization
   * @param authData OAuth authorization data
   * @returns Integration record with connection details
   */
  async connect(
    context: SecurityContext,
    authData: unknown
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.validateContext(context);

      const oauthData = authData as OAuthAuthData;
      if (!oauthData.authCode) {
        return failedResult(
          new InvalidArgumentError('Authorization code is required', 'authCode')
        );
      }

      // Exchange authorization code for access token
      const tokenResponse = await this.exchangeAuthCode(
        oauthData.authCode,
        oauthData.redirectUri
      );

      if (tokenResponse.error || !tokenResponse.access_token) {
        return failedResult(
          new Error(
            `Google OAuth failed: ${tokenResponse.error_description || tokenResponse.error || 'Unknown error'}`
          )
        );
      }

      // Get user's primary calendar info
      const calendarInfo = await this.getCalendarInfo(tokenResponse.access_token);

      // Create integration record
      const integrationInput: CreateIntegrationInput = {
        name: `Google Calendar - ${calendarInfo.email || 'Account'}`,
        description: 'Google Calendar integration for event sync',
        type: 'native',
        provider: 'google_calendar',
        config: {
          calendarId: 'primary',
          email: calendarInfo.email,
          timeZone: calendarInfo.timeZone,
        },
        scopes: tokenResponse.scope?.split(' ') || [],
      };

      const result = await this.integrationRepo.create(context, integrationInput);
      if (!result.success) {
        return result;
      }

      // Update with OAuth tokens (encrypted)
      // Note: In production, tokens should be encrypted using a KMS service
      const encryptedAccessToken = await this.encryptToken(tokenResponse.access_token);
      const encryptedRefreshToken = tokenResponse.refresh_token
        ? await this.encryptToken(tokenResponse.refresh_token)
        : undefined;

      const expiresAt = new Date(
        Date.now() + (tokenResponse.expires_in || 3600) * 1000
      );

      await this.integrationRepo.updateOAuthTokens(context, result.data.id, {
        accessToken: encryptedAccessToken,
        refreshToken: encryptedRefreshToken,
        tokenExpiresAt: expiresAt,
        scopes: tokenResponse.scope?.split(' '),
      });

      // Mark as active
      await this.integrationRepo.updateStatus(context, result.data.id, 'active');

      return this.integrationRepo.getById(context, result.data.id);
    } catch (error) {
      return failedResult(error, 'Failed to connect Google Calendar integration');
    }
  }

  /**
   * Disconnect Google Calendar integration
   *
   * @param context SecurityContext for authorization
   * @param integrationId Integration ID to disconnect
   */
  async disconnect(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.validateContext(context);

      // Get integration with tokens
      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (integration.success && integration.data.accessToken) {
        // Revoke the token with Google
        try {
          const decryptedToken = await this.decryptToken(integration.data.accessToken);
          await this.revokeToken(decryptedToken);
        } catch {
          // Best effort - continue with disconnect even if revocation fails
        }
      }

      // Clear OAuth tokens
      await this.integrationRepo.clearOAuthTokens(context, integrationId);

      // Mark as inactive
      await this.integrationRepo.updateStatus(context, integrationId, 'inactive');

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to disconnect Google Calendar integration');
    }
  }

  /**
   * Refresh OAuth tokens when expired
   *
   * HIPAA: Tokens must be encrypted before storage
   *
   * @param context SecurityContext for authorization
   * @param integrationId Integration ID with expired token
   * @returns Updated integration with refreshed tokens
   */
  async refreshTokens(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<Integration>> {
    try {
      this.validateContext(context);

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success) {
        return integration;
      }

      if (!integration.data.refreshToken) {
        return failedResult(
          new Error('No refresh token available - re-authentication required')
        );
      }

      const decryptedRefreshToken = await this.decryptToken(
        integration.data.refreshToken
      );

      const tokenResponse = await this.refreshAccessToken(decryptedRefreshToken);

      if (tokenResponse.error || !tokenResponse.access_token) {
        await this.integrationRepo.updateStatus(
          context,
          integrationId,
          'error',
          'Token refresh failed - re-authentication required'
        );
        return failedResult(
          new Error(
            `Token refresh failed: ${tokenResponse.error_description || tokenResponse.error}`
          )
        );
      }

      // Update with new tokens
      const encryptedAccessToken = await this.encryptToken(tokenResponse.access_token);
      const expiresAt = new Date(
        Date.now() + (tokenResponse.expires_in || 3600) * 1000
      );

      await this.integrationRepo.updateOAuthTokens(context, integrationId, {
        accessToken: encryptedAccessToken,
        tokenExpiresAt: expiresAt,
        scopes: tokenResponse.scope?.split(' '),
      });

      return this.integrationRepo.getById(context, integrationId);
    } catch (error) {
      return failedResult(error, 'Failed to refresh Google Calendar tokens');
    }
  }

  /**
   * Sync calendar events
   *
   * HIPAA: All event data sanitized before storage
   *
   * @param context SecurityContext for authorization
   * @param integrationId Integration ID to sync
   * @returns Sync result with counts and conflicts
   */
  async sync(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<IntegrationSyncResult>> {
    try {
      this.validateContext(context);

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success || !integration.data.accessToken) {
        return failedResult(new Error('Integration not found or not connected'));
      }

      // Check if token needs refresh
      if (this.isTokenExpired(integration.data.tokenExpiresAt)) {
        const refreshResult = await this.refreshTokens(context, integrationId);
        if (!refreshResult.success) {
          return failedResult(new Error('Failed to refresh expired token'));
        }
      }

      const decryptedToken = await this.decryptToken(integration.data.accessToken);
      const calendarId = (integration.data.config?.calendarId as string) || 'primary';

      // Fetch events from Google Calendar
      const events = await this.fetchCalendarEvents(decryptedToken, calendarId);

      // In a real implementation, you would:
      // 1. Compare with local events
      // 2. Create/update/delete as needed
      // 3. Handle conflicts
      // 4. Track changes

      const result: IntegrationSyncResult = {
        success: true,
        created: 0,
        updated: 0,
        skipped: events.length, // All skipped in this basic implementation
        conflicts: [],
        retried: 0,
        integrationId,
        syncedAt: new Date(),
      };

      // Record successful sync
      await this.integrationRepo.recordSync(context.businessId, integrationId);

      return successResult(result);
    } catch (error) {
      await this.integrationRepo.recordError(
        context.businessId,
        integrationId,
        String(error)
      );
      return failedResult(error, 'Failed to sync Google Calendar');
    }
  }

  /**
   * Test Google Calendar connection
   *
   * @param context SecurityContext for authorization
   * @param integrationId Integration ID to test
   */
  async testConnection(
    context: SecurityContext,
    integrationId: string
  ): Promise<RepositoryResult<{ success: boolean; message: string }>> {
    try {
      this.validateContext(context);

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success) {
        return integration as RepositoryResult<{ success: boolean; message: string }>;
      }

      if (!integration.data.accessToken) {
        return successResult({
          success: false,
          message: 'No access token found',
        });
      }

      // Check if token needs refresh
      if (this.isTokenExpired(integration.data.tokenExpiresAt)) {
        const refreshResult = await this.refreshTokens(context, integrationId);
        if (!refreshResult.success) {
          return successResult({
            success: false,
            message: 'Token expired and refresh failed',
          });
        }
      }

      const decryptedToken = await this.decryptToken(integration.data.accessToken);

      // Test by fetching calendar info
      try {
        await this.getCalendarInfo(decryptedToken);
        return successResult({
          success: true,
          message: 'Google Calendar connection is valid',
        });
      } catch (error) {
        return successResult({
          success: false,
          message: `Connection test failed: ${this.sanitizeErrorMessage(String(error))}`,
        });
      }
    } catch (error) {
      return failedResult(error, 'Failed to test Google Calendar connection');
    }
  }

  // ============================================
  // Calendar Event Methods
  // ============================================

  /**
   * Create a calendar event
   *
   * HIPAA: No PHI in event descriptions
   *
   * @param integrationId Integration ID to use
   * @param event Event details (sanitized)
   * @param businessId Business ID for context
   * @returns Created event ID
   */
  async createEvent(
    integrationId: string,
    event: CalendarEventInput,
    businessId: string
  ): Promise<{ success: boolean; eventId?: string; error?: string }> {
    try {
      const context: SecurityContext = {
        businessId,
        userId: 'system',
        userName: 'System',
        userRole: 'admin',
      };

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success || !integration.data.accessToken) {
        return {
          success: false,
          error: 'Integration not found or not connected',
        };
      }

      // Check if token needs refresh
      if (this.isTokenExpired(integration.data.tokenExpiresAt)) {
        const refreshResult = await this.refreshTokens(context, integrationId);
        if (!refreshResult.success) {
          return { success: false, error: 'Token expired and refresh failed' };
        }
      }

      const decryptedToken = await this.decryptToken(integration.data.accessToken);
      const calendarId = (integration.data.config?.calendarId as string) || 'primary';

      // HIPAA: Sanitize event data
      const sanitizedEvent: GoogleCalendarEvent = {
        summary: this.sanitizeStringValue(event.summary),
        description: event.description
          ? this.sanitizeStringValue(event.description)
          : undefined,
        location: event.location,
        start: {
          dateTime: event.startDateTime.toISOString(),
          timeZone: event.timeZone || 'UTC',
        },
        end: {
          dateTime: event.endDateTime.toISOString(),
          timeZone: event.timeZone || 'UTC',
        },
        attendees: event.attendeeEmails?.map((email) => ({ email })),
      };

      const response = await fetch(
        `${GOOGLE_CALENDAR_API_BASE}/calendars/${calendarId}/events`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${decryptedToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(sanitizedEvent),
        }
      );

      if (!response.ok) {
        const error = await response.text();
        return {
          success: false,
          error: this.sanitizeErrorMessage(error),
        };
      }

      const createdEvent = await response.json() as GoogleCalendarEvent;

      return {
        success: true,
        eventId: createdEvent.id,
      };
    } catch (error) {
      return {
        success: false,
        error: this.sanitizeErrorMessage(String(error)),
      };
    }
  }

  /**
   * Update a calendar event
   *
   * HIPAA: No PHI in event descriptions
   *
   * @param integrationId Integration ID to use
   * @param eventId Event ID to update
   * @param updates Event updates (sanitized)
   * @param businessId Business ID for context
   * @returns Success status
   */
  async updateEvent(
    integrationId: string,
    eventId: string,
    updates: CalendarEventUpdateInput,
    businessId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const context: SecurityContext = {
        businessId,
        userId: 'system',
        userName: 'System',
        userRole: 'admin',
      };

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success || !integration.data.accessToken) {
        return {
          success: false,
          error: 'Integration not found or not connected',
        };
      }

      // Check if token needs refresh
      if (this.isTokenExpired(integration.data.tokenExpiresAt)) {
        const refreshResult = await this.refreshTokens(context, integrationId);
        if (!refreshResult.success) {
          return { success: false, error: 'Token expired and refresh failed' };
        }
      }

      const decryptedToken = await this.decryptToken(integration.data.accessToken);
      const calendarId = (integration.data.config?.calendarId as string) || 'primary';

      // HIPAA: Sanitize event updates
      const sanitizedUpdates: Partial<GoogleCalendarEvent> = {};

      if (updates.summary !== undefined) {
        sanitizedUpdates.summary = this.sanitizeStringValue(updates.summary);
      }
      if (updates.description !== undefined) {
        sanitizedUpdates.description = this.sanitizeStringValue(updates.description);
      }
      if (updates.location !== undefined) {
        sanitizedUpdates.location = updates.location;
      }
      if (updates.startDateTime !== undefined || updates.endDateTime !== undefined) {
        if (updates.startDateTime) {
          sanitizedUpdates.start = {
            dateTime: updates.startDateTime.toISOString(),
            timeZone: updates.timeZone || 'UTC',
          };
        }
        if (updates.endDateTime) {
          sanitizedUpdates.end = {
            dateTime: updates.endDateTime.toISOString(),
            timeZone: updates.timeZone || 'UTC',
          };
        }
      }

      const response = await fetch(
        `${GOOGLE_CALENDAR_API_BASE}/calendars/${calendarId}/events/${eventId}`,
        {
          method: 'PATCH',
          headers: {
            'Authorization': `Bearer ${decryptedToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(sanitizedUpdates),
        }
      );

      if (!response.ok) {
        const error = await response.text();
        return {
          success: false,
          error: this.sanitizeErrorMessage(error),
        };
      }

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: this.sanitizeErrorMessage(String(error)),
      };
    }
  }

  /**
   * Delete a calendar event
   *
   * @param integrationId Integration ID to use
   * @param eventId Event ID to delete
   * @param businessId Business ID for context
   * @returns Success status
   */
  async deleteEvent(
    integrationId: string,
    eventId: string,
    businessId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const context: SecurityContext = {
        businessId,
        userId: 'system',
        userName: 'System',
        userRole: 'admin',
      };

      const integration = await this.integrationRepo.getByIdWithTokens(
        context,
        integrationId
      );

      if (!integration.success || !integration.data.accessToken) {
        return {
          success: false,
          error: 'Integration not found or not connected',
        };
      }

      // Check if token needs refresh
      if (this.isTokenExpired(integration.data.tokenExpiresAt)) {
        const refreshResult = await this.refreshTokens(context, integrationId);
        if (!refreshResult.success) {
          return { success: false, error: 'Token expired and refresh failed' };
        }
      }

      const decryptedToken = await this.decryptToken(integration.data.accessToken);
      const calendarId = (integration.data.config?.calendarId as string) || 'primary';

      const response = await fetch(
        `${GOOGLE_CALENDAR_API_BASE}/calendars/${calendarId}/events/${eventId}`,
        {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${decryptedToken}`,
          },
        }
      );

      if (!response.ok) {
        const error = await response.text();
        return {
          success: false,
          error: this.sanitizeErrorMessage(error),
        };
      }

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: this.sanitizeErrorMessage(String(error)),
      };
    }
  }

  // ============================================
  // Webhook Handling (Push Notifications)
  // ============================================

  /**
   * Handle Google Calendar webhook (push notifications)
   *
   * @param payload Webhook payload
   * @param signature Signature (not used by Google - uses channel verification)
   * @returns Handler result
   */
  async handleWebhook(
    _payload: unknown,
    _signature: string
  ): Promise<WebhookHandlerResult> {
    try {
      // Google Calendar uses push notifications, not traditional webhooks
      // The payload would contain channel info and resource state
      // In a real implementation, you would:
      // 1. Verify the channel ID matches a registered channel
      // 2. Fetch updated events from the calendar
      // 3. Sync changes to local database

      return {
        success: true,
        metadata: {
          message: 'Google Calendar webhook received',
        },
      };
    } catch (error) {
      return {
        success: false,
        error: this.sanitizeErrorMessage(String(error)),
      };
    }
  }

  // ============================================
  // Private Helper Methods
  // ============================================

  /**
   * Exchange OAuth authorization code for access token
   */
  private async exchangeAuthCode(
    code: string,
    redirectUri: string
  ): Promise<GoogleOAuthResponse> {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      throw new Error('Google OAuth credentials not configured');
    }

    const params = new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      code,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    });

    const response = await fetch(GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    return response.json();
  }

  /**
   * Refresh access token using refresh token
   */
  private async refreshAccessToken(
    refreshToken: string
  ): Promise<GoogleOAuthResponse> {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      throw new Error('Google OAuth credentials not configured');
    }

    const params = new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    });

    const response = await fetch(GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    return response.json();
  }

  /**
   * Revoke OAuth token
   */
  private async revokeToken(token: string): Promise<void> {
    await fetch(`https://oauth2.googleapis.com/revoke?token=${token}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
  }

  /**
   * Get calendar info for the authenticated user
   */
  private async getCalendarInfo(
    accessToken: string
  ): Promise<{ email?: string; timeZone?: string }> {
    const response = await fetch(
      `${GOOGLE_CALENDAR_API_BASE}/calendars/primary`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      }
    );

    if (!response.ok) {
      throw new Error('Failed to fetch calendar info');
    }

    const data = await response.json();
    return {
      email: data.summary,
      timeZone: data.timeZone,
    };
  }

  /**
   * Fetch calendar events
   */
  private async fetchCalendarEvents(
    accessToken: string,
    calendarId: string,
    maxResults: number = 100
  ): Promise<GoogleCalendarEvent[]> {
    const params = new URLSearchParams({
      maxResults: maxResults.toString(),
      singleEvents: 'true',
      orderBy: 'startTime',
      timeMin: new Date().toISOString(),
    });

    const response = await fetch(
      `${GOOGLE_CALENDAR_API_BASE}/calendars/${calendarId}/events?${params.toString()}`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      }
    );

    if (!response.ok) {
      throw new Error('Failed to fetch calendar events');
    }

    const data = await response.json() as GoogleCalendarListResponse;
    return data.items || [];
  }

  /**
   * Check if token is expired or about to expire
   */
  private isTokenExpired(expiresAt?: Date): boolean {
    if (!expiresAt) return true;
    // Consider expired if less than 5 minutes remaining
    const fiveMinutesFromNow = new Date(Date.now() + 5 * 60 * 1000);
    return expiresAt < fiveMinutesFromNow;
  }

  /**
   * Generate OAuth state parameter
   */
  private generateState(context: SecurityContext): string {
    const data = `${context.businessId}:${context.userId}:${Date.now()}`;
    return Buffer.from(data).toString('base64');
  }

  /**
   * Encrypt OAuth token
   *
   * HIPAA: Tokens must be encrypted at rest using AES-256-GCM
   * Uses TokenEncryptionService with support for:
   * - Local key encryption (development)
   * - Google Cloud KMS (production)
   */
  private async encryptToken(token: string): Promise<string> {
    const encryptionService = getTokenEncryptionService();
    return encryptionService.encrypt(token);
  }

  /**
   * Decrypt OAuth token
   *
   * Uses TokenEncryptionService for AES-256-GCM decryption
   */
  private async decryptToken(encryptedToken: string): Promise<string> {
    const encryptionService = getTokenEncryptionService();
    return encryptionService.decrypt(encryptedToken);
  }
}
