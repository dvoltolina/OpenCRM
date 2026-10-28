/**
 * Calendar OAuth Service
 * Generates provider auth URLs, exchanges auth codes via Cloud Functions, and stores connections.
 *
 * HIPAA: Tokens must be encrypted at rest server-side. Client never logs tokens or event content.
 */

import { getAuth } from 'firebase/auth';
import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getCalendarConnectionRepository,
  type CalendarConnectionRepository,
} from '../data/repositories/calendar-connection-repository';
import type { CalendarProvider, CalendarConnection } from '../types/calendar-sync';
import { getFeatureFlags } from '../config/features';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService } from './AuditLogService';
import { generateId } from '../data/repositories/firestore-utils';
import { getFunctionsBaseUrl, hasFunctionsBaseUrl } from './functions-base-url';
import {
  connectCalendar as connectCalendarViaFunctions,
  disconnectCalendar as disconnectCalendarViaFunctions,
  isCalendarFunctionsConfigured,
  refreshCalendarTokens as refreshCalendarTokensViaFunctions,
} from './calendar-functions-client';

interface TokenExchangeResult {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
  email?: string;
  displayName?: string;
}

interface OAuthStatePayload {
  userId: string;
  businessId: string;
  nonce: string;
  redirectUri?: string;
  issuedAt?: number;
}

const GOOGLE_SCOPES = [
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/calendar.events',
];

const OUTLOOK_SCOPES = ['Calendars.ReadWrite', 'offline_access'];

const defaultLookbackDays = 7;
const defaultLookforwardDays = 30;
const STATE_STORAGE_KEY = 'calendar_oauth_state';
const STATE_MAX_AGE_MS = 10 * 60 * 1000; // 10 minutes

type StoredState = OAuthStatePayload & {
  provider: CalendarProvider;
  encoded: string;
};

export class CalendarOAuthService {
  private connections: CalendarConnectionRepository;
  private rateLimit: RateLimitService;
  private audit: AuditLogService;

  constructor(
    repository?: CalendarConnectionRepository,
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService
  ) {
    this.connections = repository || getCalendarConnectionRepository();
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
  }

  isConfigured(): boolean {
    return hasFunctionsBaseUrl() || isCalendarFunctionsConfigured();
  }

  private isTestEnv(): boolean {
    return Boolean(
      (typeof process !== 'undefined' && process.env?.VITEST) ||
        (typeof import.meta !== 'undefined' && (import.meta as any)?.env?.MODE === 'test') ||
        (globalThis as any)?.vitest
    );
  }

  /**
   * Build provider OAuth URL with state payload.
   */
  async getAuthUrl(
    provider: CalendarProvider,
    userId: string,
    businessId: string
  ): Promise<string> {
    this.assertEnabled();
    if (!this.isConfigured() && !this.isTestEnv()) {
      throw new Error('Calendar Functions are not configured; enable server-side calendar connect');
    }
    const statePayload: OAuthStatePayload = {
      userId,
      businessId,
      nonce: generateId(),
      issuedAt: Date.now(),
    };
    const state = this.encodeState(statePayload);

    this.persistState(provider, state, statePayload);

    if (provider === 'google') {
      const clientId =
        import.meta.env.VITE_GOOGLE_CALENDAR_CLIENT_ID ||
        import.meta.env.GOOGLE_CALENDAR_CLIENT_ID ||
        'google-client-id-not-set';
      const redirectUri =
        import.meta.env.VITE_GOOGLE_CALENDAR_REDIRECT_URI ||
        import.meta.env.GOOGLE_CALENDAR_REDIRECT_URI ||
        'https://your-domain.com/api/calendar/google/callback';

      const params = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: 'code',
        access_type: 'offline',
        scope: GOOGLE_SCOPES.join(' '),
        include_granted_scopes: 'true',
        prompt: 'consent',
        state,
      });

      return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
    }

    const clientId =
      import.meta.env.VITE_OUTLOOK_CLIENT_ID ||
      import.meta.env.OUTLOOK_CLIENT_ID ||
      'outlook-client-id-not-set';
    const redirectUri =
      import.meta.env.VITE_OUTLOOK_REDIRECT_URI ||
      import.meta.env.OUTLOOK_REDIRECT_URI ||
      'https://your-domain.com/api/calendar/outlook/callback';
    const params = new URLSearchParams({
      client_id: clientId,
      response_type: 'code',
      redirect_uri: redirectUri,
      response_mode: 'query',
      scope: OUTLOOK_SCOPES.join(' '),
      state,
    });

    return `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?${params.toString()}`;
  }

  /**
   * Exchange auth code for tokens via Cloud Function (or stub in dev) and persist the connection.
   */
  async handleCallback(
    context: SecurityContext,
    provider: CalendarProvider,
    code: string,
    state: string
  ): Promise<CalendarConnection> {
    this.assertEnabled();
    if (!this.isConfigured() && !this.isTestEnv()) {
      throw new Error('Calendar Functions are not configured; enable server-side calendar connect');
    }
    const resolvedState = state || this.getStoredState(provider);
    if (!resolvedState) {
      throw new Error('Missing OAuth state');
    }

    const statePayload = this.decodeState(resolvedState);
    this.validateState(context, provider, statePayload, resolvedState);
    this.clearStoredState(provider, statePayload.nonce);

    const rate = await this.rateLimit.checkLimit('integration_sync', context.userId, context.businessId);
    if (!rate.allowed) {
      throw new Error(rate.message || 'Calendar OAuth rate limit exceeded');
    }

    if (this.isConfigured() && isCalendarFunctionsConfigured()) {
      const connectResult = await connectCalendarViaFunctions({
        provider,
        authCode: code,
        businessId: context.businessId,
        state,
      });

      if (!connectResult.success && !connectResult.connectionId) {
        throw new Error(connectResult.error || 'Calendar connection failed');
      }

      // Fetch latest connection created server-side
      const latest = await this.connections.getByUser(context, context.userId);
      if (latest.success) {
        const connection = latest.data.data.find((c) => c.provider === provider && c.status === 'active');
        if (connection) {
          await this.audit.logAction(context, {
            action: 'integration',
            entityType: 'calendar_connection',
            entityId: connection.id,
            entityName: provider,
            metadata: { provider, operation: 'connect_functions' },
          });
          await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);
          return connection;
        }
      }
      throw new Error('Calendar connection created server-side but not yet available in client scope');
    }

    const exchange = await this.exchangeCode(provider, code, statePayload);

    const createResult = await this.connections.create(context, {
      businessId: context.businessId,
      userId: context.userId,
      userName: context.userName,
      provider,
      accessToken: exchange.accessToken,
      refreshToken: exchange.refreshToken,
      tokenExpiresAt: exchange.expiresAt,
      settings: {
        syncDirection: 'bidirectional',
        defaultCalendarId: 'primary',
        syncMeetings: true,
        syncCalls: true,
        syncTasks: false,
        lookbackDays: defaultLookbackDays,
        lookforwardDays: defaultLookforwardDays,
      },
      lastSyncStatus: 'success',
      status: 'active',
      lastSyncAt: undefined,
      lastSyncError: undefined,
    });

    if (!createResult.success || !createResult.data) {
      throw new Error(createResult.error?.message || 'Failed to store calendar connection');
    }

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: createResult.data.id,
      entityName: provider,
      metadata: { provider, operation: 'connect' },
    });

    await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);
    return createResult.data;
  }

  /**
   * Refresh tokens for an existing connection.
   */
  async refreshTokens(context: SecurityContext, connectionId: string): Promise<CalendarConnection> {
    this.assertEnabled();
    if (!this.isConfigured() && !this.isTestEnv()) {
      throw new Error('Calendar Functions are not configured; cannot refresh tokens client-side');
    }
    const connection = await this.connections.getById(context, connectionId);
    if (!connection.success || !connection.data) {
      throw new Error(connection.error?.message || 'Calendar connection not found');
    }

    if (this.isConfigured() && isCalendarFunctionsConfigured()) {
      const response = await refreshCalendarTokensViaFunctions({
        connectionId,
        businessId: context.businessId,
      });
      if (!response.success) {
        throw new Error(response.error || 'Failed to refresh calendar tokens');
      }
      const refreshed = await this.connections.getById(context, connectionId);
      if (refreshed.success && refreshed.data) {
        await this.audit.logAction(context, {
          action: 'integration',
          entityType: 'integration',
          entityId: connectionId,
          entityName: refreshed.data.provider,
          metadata: { provider: refreshed.data.provider, operation: 'refresh_functions' },
        });
        return refreshed.data;
      }
      throw new Error('Calendar connection refresh succeeded but data not available locally');
    }

    const exchange = await this.refresh(providerFrom(connection.data.provider), connection.data.refreshToken);
    const updateResult = await this.connections.update(context, connectionId, {
      accessToken: exchange.accessToken,
      refreshToken: exchange.refreshToken,
      tokenExpiresAt: exchange.expiresAt,
      updatedAt: new Date(),
      status: 'active',
    });

    if (!updateResult.success || !updateResult.data) {
      throw new Error(updateResult.error?.message || 'Failed to refresh calendar tokens');
    }

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: connectionId,
      entityName: connection.data.provider,
      metadata: { provider: connection.data.provider, operation: 'refresh' },
    });

    return updateResult.data;
  }

  /**
   * Disconnect an account by revoking tokens server-side and marking status locally.
   */
  async disconnect(context: SecurityContext, connectionId: string): Promise<void> {
    this.assertEnabled();
    const connection = await this.connections.getById(context, connectionId);
    if (!connection.success || !connection.data) {
      throw new Error(connection.error?.message || 'Calendar connection not found');
    }

    try {
      if (this.isConfigured() && isCalendarFunctionsConfigured()) {
        await disconnectCalendarViaFunctions({
          connectionId,
          businessId: context.businessId,
        });
      } else if (this.isConfigured()) {
        await this.postToFunction(`/disconnectCalendar`, {
          connectionId,
          provider: connection.data.provider,
          businessId: context.businessId,
        });
      }
    } catch {
      // Best-effort revoke; proceed to mark disconnected regardless.
    }

    await this.connections.update(context, connectionId, {
      status: 'disconnected',
      accessToken: '',
      refreshToken: '',
      updatedAt: new Date(),
    });

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: connectionId,
      entityName: connection.data.provider,
      metadata: { provider: connection.data.provider, operation: 'disconnect' },
    });
  }

  private assertEnabled() {
    if (!getFeatureFlags().enableCalendarSync) {
      throw new Error('Calendar sync is disabled');
    }
  }

  private persistState(provider: CalendarProvider, encoded: string, payload: OAuthStatePayload) {
    if (typeof sessionStorage === 'undefined') return;
    const states = this.getStoredStates().filter((entry) => entry.provider !== provider);
    const stored: StoredState = {
      provider,
      encoded,
      userId: payload.userId,
      businessId: payload.businessId,
      nonce: payload.nonce,
      redirectUri: payload.redirectUri,
      issuedAt: payload.issuedAt ?? Date.now(),
    };
    try {
      states.push(stored);
      const trimmed = states.slice(-5); // keep most recent few entries
      sessionStorage.setItem(STATE_STORAGE_KEY, JSON.stringify(trimmed));
    } catch {
      // Swallow storage errors (Safari private mode, etc.)
    }
  }

  private getStoredStates(): StoredState[] {
    if (typeof sessionStorage === 'undefined') return [];
    try {
      const raw = sessionStorage.getItem(STATE_STORAGE_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) return [];
      return parsed as StoredState[];
    } catch {
      return [];
    }
  }

  private getStoredState(provider: CalendarProvider): string | null {
    const match = this.getStoredStates()
      .filter((entry) => entry.provider === provider)
      .pop();
    return match?.encoded || null;
  }

  private clearStoredState(provider: CalendarProvider, nonce?: string) {
    if (typeof sessionStorage === 'undefined') return;
    const remaining = this.getStoredStates().filter((entry) => {
      if (entry.provider !== provider) return true;
      if (nonce && entry.nonce !== nonce) return true;
      return false;
    });
    try {
      if (remaining.length === 0) {
        sessionStorage.removeItem(STATE_STORAGE_KEY);
      } else {
        sessionStorage.setItem(STATE_STORAGE_KEY, JSON.stringify(remaining));
      }
    } catch {
      // Ignore storage errors
    }
  }

  private validateState(
    context: SecurityContext,
    provider: CalendarProvider,
    payload: OAuthStatePayload,
    encoded: string
  ) {
    const stored = this.getStoredStates().find(
      (entry) => entry.provider === provider && entry.encoded === encoded
    );
    if (!payload.businessId || !payload.userId || !payload.nonce) {
      throw new Error('Invalid OAuth state payload');
    }

    if (payload.businessId !== context.businessId || payload.userId !== context.userId) {
      throw new Error('OAuth state mismatch');
    }

    if (stored && stored.nonce !== payload.nonce) {
      throw new Error('OAuth state mismatch');
    }

    const issuedAt = stored?.issuedAt ?? payload.issuedAt;
    if (issuedAt && Date.now() - issuedAt > STATE_MAX_AGE_MS) {
      throw new Error('OAuth state expired');
    }
  }

  private encodeState(payload: OAuthStatePayload): string {
    const json = JSON.stringify(payload);
    if (typeof btoa === 'function') {
      return btoa(json);
    }
    return Buffer.from(json, 'utf-8').toString('base64');
  }

  private decodeState(state: string): OAuthStatePayload {
    if (!state) {
      return { userId: '', businessId: '', nonce: '' };
    }
    try {
      const decode =
        typeof atob === 'function'
          ? atob
          : (value: string) => Buffer.from(value, 'base64').toString('utf-8');
      const json = decode(state);
      return JSON.parse(json) as OAuthStatePayload;
    } catch {
      return { userId: '', businessId: '', nonce: '' };
    }
  }

  private async exchangeCode(
    provider: CalendarProvider,
    code: string,
    state: OAuthStatePayload
  ): Promise<TokenExchangeResult> {
    if (!this.isConfigured()) {
      // Dev stub: do not exchange tokens without Functions backend
      const expiresAt = new Date(Date.now() + 55 * 60 * 1000);
      return {
        accessToken: `dev-${provider}-access-${code}`,
        refreshToken: `dev-${provider}-refresh-${code}`,
        expiresAt,
      };
    }

    const response = await this.postToFunction<TokenExchangeResult>(
      `/calendar/${provider}/callback`,
      {
        code,
        state,
        provider,
      }
    );

    if (!response?.accessToken || !response.refreshToken) {
      throw new Error('Calendar provider token exchange failed');
    }

    return {
      ...response,
      expiresAt: new Date(response.expiresAt),
    };
  }

  private async refresh(provider: CalendarProvider, refreshToken: string): Promise<TokenExchangeResult> {
    if (!refreshToken) {
      throw new Error('Missing refresh token');
    }

    if (!this.isConfigured()) {
      return {
        accessToken: `dev-${provider}-access-${generateId()}`,
        refreshToken,
        expiresAt: new Date(Date.now() + 55 * 60 * 1000),
      };
    }

    const response = await this.postToFunction<TokenExchangeResult>(
      `/refreshCalendarTokens`,
      {
        provider,
        refreshToken,
      }
    );

    if (!response?.accessToken || !response.refreshToken) {
      throw new Error('Calendar token refresh failed');
    }

    return {
      ...response,
      expiresAt: new Date(response.expiresAt),
    };
  }

  private async postToFunction<TResponse = unknown>(
    path: string,
    body: Record<string, unknown>
  ): Promise<TResponse> {
    const baseUrl = getFunctionsBaseUrl();
    if (!baseUrl) {
      throw new Error('Functions base URL is not configured');
    }

    const auth = getAuth();
    const idToken = await auth.currentUser?.getIdToken();
    if (!idToken) {
      throw new Error('User not authenticated');
    }

    const response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify(body),
    });

    const isJson = response.headers.get('content-type')?.includes('application/json');
    const payload = isJson ? await response.json() : await response.text();

    if (!response.ok) {
      const message =
        typeof payload === 'string'
          ? payload
          : (payload as { error?: string })?.error || 'Calendar function call failed';
      throw new Error(message);
    }

    return payload as TResponse;
  }
}

function providerFrom(value: CalendarProvider): CalendarProvider {
  return value === 'outlook' ? 'outlook' : 'google';
}

let calendarOAuthService: CalendarOAuthService | null = null;

export function getCalendarOAuthService(): CalendarOAuthService {
  if (!calendarOAuthService) {
    calendarOAuthService = new CalendarOAuthService();
  }
  return calendarOAuthService;
}
