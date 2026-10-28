import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CalendarOAuthService } from '../calendar-oauth-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { CalendarConnection } from '../../types/calendar-sync';

vi.mock('firebase/auth', () => ({
  getAuth: () => ({
    currentUser: null,
  }),
}));

vi.mock('../calendar-functions-client', () => ({
  isCalendarFunctionsConfigured: () => false,
  connectCalendar: vi.fn(),
  disconnectCalendar: vi.fn(),
  refreshCalendarTokens: vi.fn(),
}));

vi.mock('../../config/features', async () => {
  const actual = await vi.importActual<typeof import('../../config/features')>(
    '../../config/features'
  );
  return {
    ...actual,
    getFeatureFlags: () => ({ ...actual.defaultFeatures, enableCalendarSync: true }),
  };
});

const context: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: [],
};

describe('CalendarOAuthService - state validation', () => {
  const baseConnection: CalendarConnection = {
    id: 'conn-1',
    businessId: context.businessId,
    userId: context.userId,
    userName: context.userName,
    provider: 'google',
    accessToken: 'dev-google-access',
    refreshToken: 'dev-google-refresh',
    tokenExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
    settings: {
      syncDirection: 'bidirectional',
      defaultCalendarId: 'primary',
      syncMeetings: true,
      syncCalls: true,
      syncTasks: false,
      lookbackDays: 7,
      lookforwardDays: 30,
    },
    lastSyncStatus: 'success',
    status: 'active',
    createdAt: new Date(),
  };

  let connections: any;
  let rateLimit: any;
  let audit: any;

  beforeEach(() => {
    sessionStorage.clear();
    connections = {
      create: vi.fn().mockResolvedValue({ success: true, data: baseConnection }),
      getByUser: vi.fn().mockResolvedValue({ success: true, data: { data: [] } }),
      getById: vi.fn().mockResolvedValue({ success: true, data: baseConnection }),
      update: vi.fn().mockResolvedValue({
        success: true,
        data: { ...baseConnection, accessToken: 'refreshed-token', refreshToken: 'refreshed-refresh' },
      }),
    };

    rateLimit = {
      checkLimit: vi.fn().mockResolvedValue({ allowed: true, resetAt: new Date() }),
      recordAction: vi.fn(),
    };

    audit = {
      logAction: vi.fn().mockResolvedValue(undefined),
    };
  });

  const buildService = () => {
    const service = new CalendarOAuthService(connections, rateLimit, audit);
    // Force dev/stub mode for tests
    (service as any).isConfigured = () => false;
    return service;
  };

  it('stores state and validates matching callback', async () => {
    const service = buildService();
    const url = await service.getAuthUrl('google', context.userId, context.businessId);
    const state = new URL(url).searchParams.get('state');
    expect(state).toBeTruthy();

    const connection = await service.handleCallback(context, 'google', 'auth-code-1', state || '');

    expect(connections.create).toHaveBeenCalled();
    expect(connection.id).toBe(baseConnection.id);
  });

  it('rejects when state is missing', async () => {
    const service = buildService();
    await expect(service.handleCallback(context, 'google', 'auth-code-1', ''))
      .rejects.toThrow(/OAuth state/i);
  });

  it('rejects mismatched or expired state', async () => {
    const service = buildService();
    const url = await service.getAuthUrl('google', context.userId, context.businessId);
    const state = new URL(url).searchParams.get('state')!;

    // Tamper stored state to simulate expiration
    const storedRaw = sessionStorage.getItem('calendar_oauth_state');
    const stored = storedRaw ? (JSON.parse(storedRaw) as Array<any>) : [];
    if (stored.length > 0) {
      stored[0].issuedAt = Date.now() - 20 * 60 * 1000;
      sessionStorage.setItem('calendar_oauth_state', JSON.stringify(stored));
    }

    await expect(
      service.handleCallback(
        { ...context, userId: 'different-user' },
        'google',
        'auth-code-1',
        state
      )
    ).rejects.toThrow(/OAuth state/);

    await expect(
      service.handleCallback(context, 'google', 'auth-code-1', state)
    ).rejects.toThrow(/expired/i);
  });

  it('refreshes tokens locally when Functions are not configured', async () => {
    const service = buildService();

    const refreshed = await service.refreshTokens(context, baseConnection.id);

    expect(connections.update).toHaveBeenCalledWith(
      context,
      baseConnection.id,
      expect.objectContaining({
        accessToken: expect.any(String),
        refreshToken: expect.any(String),
        status: 'active',
      })
    );
    expect(refreshed.accessToken).toBe('refreshed-token');
  });

  it('blocks connect/refresh when Functions are not configured in non-test mode', async () => {
    const service = buildService();
    vi.spyOn(service as any, 'isConfigured').mockReturnValue(false);
    vi.spyOn(service as any, 'isTestEnv').mockReturnValue(false);

    await expect(service.getAuthUrl('google', context.userId, context.businessId)).rejects.toThrow(
      /Calendar Functions are not configured/i
    );

    await expect(service.refreshTokens(context, baseConnection.id)).rejects.toThrow(
      /Calendar Functions are not configured/i
    );
  });

  it('disconnects and clears tokens even if remote revoke is stubbed', async () => {
    const service = buildService();

    await service.disconnect(context, baseConnection.id);

    expect(connections.update).toHaveBeenCalledWith(
      context,
      baseConnection.id,
      expect.objectContaining({
        status: 'disconnected',
        accessToken: '',
        refreshToken: '',
      })
    );
    expect(audit.logAction).toHaveBeenCalledWith(
      context,
      expect.objectContaining({
        entityId: baseConnection.id,
        metadata: expect.objectContaining({ operation: 'disconnect' }),
      })
    );
  });
});
