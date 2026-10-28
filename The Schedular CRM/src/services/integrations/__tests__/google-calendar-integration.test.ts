/**
 * Google Calendar Integration Tests
 * Tests for Google Calendar OAuth flow, sync, and event management
 *
 * Task 8: Native Integrations Framework
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GoogleCalendarIntegration } from '../google-calendar-integration';
import type { SecurityContext } from '../../../data/repositories/repository-types';
import type { CalendarEventInput } from '../google-calendar-integration';

// Mock fetch globally
global.fetch = vi.fn() as any;

// Mock integration repository
const mockIntegrationRepo = {
  create: vi.fn(),
  getById: vi.fn(),
  getByIdWithTokens: vi.fn(),
  updateOAuthTokens: vi.fn(),
  updateStatus: vi.fn(),
  clearOAuthTokens: vi.fn(),
  recordSync: vi.fn(),
  recordError: vi.fn(),
};

vi.mock('../../../data/repositories/integration-repository', () => ({
  getIntegrationRepository: vi.fn(() => mockIntegrationRepo),
}));

// Mock TokenEncryptionService - encrypts/decrypts as passthrough for testing
const mockEncryptionService = {
  encrypt: vi.fn((value: string) => Promise.resolve(`encrypted:${value}`)),
  decrypt: vi.fn((value: string) => {
    // Handle both prefixed and legacy tokens
    if (value.startsWith('encrypted:')) {
      return Promise.resolve(value.replace('encrypted:', ''));
    }
    // For backwards compatibility with base64 encoded test data
    try {
      return Promise.resolve(Buffer.from(value, 'base64').toString('utf-8'));
    } catch {
      return Promise.resolve(value);
    }
  }),
  initialize: vi.fn(),
  rotate: vi.fn(),
  needsRotation: vi.fn(() => false),
};

vi.mock('../../token-encryption-service', () => ({
  getTokenEncryptionService: vi.fn(() => mockEncryptionService),
  TokenEncryptionService: vi.fn(() => mockEncryptionService),
  resetTokenEncryptionService: vi.fn(),
}));

// ============================================
// Test Setup
// ============================================

describe('GoogleCalendarIntegration', () => {
  let googleCalendar: GoogleCalendarIntegration;
  let mockContext: SecurityContext;
  let mockFetch: any;

  beforeEach(() => {
    googleCalendar = new GoogleCalendarIntegration();
    mockContext = {
      businessId: 'test-business-id',
      userId: 'test-user-id',
      userName: 'Test User',
      userRole: 'admin',
    };
    mockFetch = global.fetch as any;
    vi.clearAllMocks();
    Object.values(mockIntegrationRepo).forEach((fn) => fn.mockReset());

    // Set environment variables for tests
    process.env.GOOGLE_CLIENT_ID = 'test-client-id';
    process.env.GOOGLE_CLIENT_SECRET = 'test-client-secret';
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // Core Properties Tests
  // ============================================

  describe('Core Properties', () => {
    it('should have correct name', () => {
      expect(googleCalendar.name).toBe('Google Calendar');
    });

    it('should have correct type', () => {
      expect(googleCalendar.type).toBe('native');
    });

    it('should have correct provider', () => {
      expect(googleCalendar.provider).toBe('google_calendar');
    });
  });

  // ============================================
  // OAuth Authorization URL Tests
  // ============================================

  describe('getAuthorizationUrl', () => {
    it('should generate valid authorization URL', () => {
      const redirectUri = 'https://app.example.com/oauth/callback';
      const url = googleCalendar.getAuthorizationUrl(mockContext, redirectUri);

      expect(url).toContain('https://accounts.google.com/o/oauth2/v2/auth');
      expect(url).toContain('client_id=test-client-id');
      expect(url).toContain(`redirect_uri=${encodeURIComponent(redirectUri)}`);
      expect(url).toContain('response_type=code');
      expect(url).toContain('access_type=offline');
      expect(url).toContain('prompt=consent');
    });

    it('should include required scopes', () => {
      const url = googleCalendar.getAuthorizationUrl(
        mockContext,
        'https://app.example.com'
      );

      const urlObj = new URL(url);
      const scopes = urlObj.searchParams.get('scope')?.split(' ') || [];

      expect(scopes).toContain('https://www.googleapis.com/auth/calendar');
      expect(scopes).toContain('https://www.googleapis.com/auth/calendar.events');
    });

    it('should include state parameter', () => {
      const url = googleCalendar.getAuthorizationUrl(
        mockContext,
        'https://app.example.com'
      );

      const urlObj = new URL(url);
      const state = urlObj.searchParams.get('state');

      expect(state).toBeTruthy();
      expect(state).toMatch(/^[A-Za-z0-9+/=]+$/);
    });

    it('should throw if GOOGLE_CLIENT_ID not configured', () => {
      delete process.env.GOOGLE_CLIENT_ID;

      expect(() =>
        googleCalendar.getAuthorizationUrl(mockContext, 'https://app.example.com')
      ).toThrow('GOOGLE_CLIENT_ID not configured');
    });
  });

  // ============================================
  // Event Creation Tests
  // ============================================

  describe('createEvent', () => {
    it('should create event successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: 'event-123', status: 'confirmed' }),
      } as Response);

      const eventInput: CalendarEventInput = {
        summary: 'Test Event',
        description: 'Test Description',
        startDateTime: new Date('2025-12-03T10:00:00Z'),
        endDateTime: new Date('2025-12-03T11:00:00Z'),
        timeZone: 'UTC',
      };

      const result = await googleCalendar.createEvent(
        'test-integration-id',
        eventInput,
        'test-business-id'
      );

      expect(result.success).toBe(true);
      expect(result.eventId).toBe('event-123');
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('googleapis.com/calendar/v3'),
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-access-token',
          }),
        })
      );
    });

    it('should sanitize event data before sending', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: 'event-123' }),
      } as Response);

      const eventInput: CalendarEventInput = {
        summary: 'Meeting with john@example.com',
        description: 'Call 555-1234 to discuss',
        startDateTime: new Date('2025-12-03T10:00:00Z'),
        endDateTime: new Date('2025-12-03T11:00:00Z'),
      };

      await googleCalendar.createEvent(
        'test-integration-id',
        eventInput,
        'test-business-id'
      );

      const fetchCall = mockFetch.mock.calls[0];
      const body = JSON.parse(fetchCall[1]?.body as string);

      expect(body.summary).not.toContain('john@example.com');
      expect(body.description).not.toContain('555-1234');
    });

    it('should handle integration not found', async () => {
      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: false,
      });

      const eventInput: CalendarEventInput = {
        summary: 'Test Event',
        startDateTime: new Date(),
        endDateTime: new Date(),
      };

      const result = await googleCalendar.createEvent(
        'nonexistent-id',
        eventInput,
        'test-business-id'
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('not found');
    });

    it('should refresh expired token before creating event', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('old-token').toString('base64'),
        refreshToken: Buffer.from('refresh-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() - 1000), // Expired
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });
      mockRepo.getById.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      // Mock token refresh
      mockFetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            access_token: 'new-access-token',
            expires_in: 3600,
          }),
        } as Response)
        // Mock event creation
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ id: 'event-123' }),
        } as Response);

      const eventInput: CalendarEventInput = {
        summary: 'Test Event',
        startDateTime: new Date(),
        endDateTime: new Date(),
      };

      await googleCalendar.createEvent(
        'test-integration-id',
        eventInput,
        'test-business-id'
      );

      expect(mockRepo.updateOAuthTokens).toHaveBeenCalled();
    });
  });

  // ============================================
  // Event Update Tests
  // ============================================

  describe('updateEvent', () => {
    it('should update event successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: 'event-123', status: 'confirmed' }),
      } as Response);

      const result = await googleCalendar.updateEvent(
        'test-integration-id',
        'event-123',
        {
          summary: 'Updated Event',
          description: 'Updated Description',
        },
        'test-business-id'
      );

      expect(result.success).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('events/event-123'),
        expect.objectContaining({
          method: 'PATCH',
        })
      );
    });

    it('should sanitize update data', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: 'event-123' }),
      } as Response);

      await googleCalendar.updateEvent(
        'test-integration-id',
        'event-123',
        {
          summary: 'Call john@example.com',
          description: 'Phone: 555-1234',
        },
        'test-business-id'
      );

      const fetchCall = mockFetch.mock.calls[0];
      const body = JSON.parse(fetchCall[1]?.body as string);

      expect(body.summary).not.toContain('john@example.com');
      expect(body.description).not.toContain('555-1234');
    });
  });

  // ============================================
  // Event Deletion Tests
  // ============================================

  describe('deleteEvent', () => {
    it('should delete event successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
      } as Response);

      const result = await googleCalendar.deleteEvent(
        'test-integration-id',
        'event-123',
        'test-business-id'
      );

      expect(result.success).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('events/event-123'),
        expect.objectContaining({
          method: 'DELETE',
        })
      );
    });
  });

  // ============================================
  // Token Refresh Tests
  // ============================================

  describe('refreshTokens', () => {
    it('should refresh tokens successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('old-token').toString('base64'),
        refreshToken: Buffer.from('refresh-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() - 1000),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });
      mockRepo.getById.mockResolvedValue({
        success: true,
        data: { ...mockIntegration, accessToken: undefined },
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({
          access_token: 'new-access-token',
          expires_in: 3600,
          scope: 'https://www.googleapis.com/auth/calendar',
        }),
      } as Response);

      const result = await googleCalendar.refreshTokens(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(true);
      expect(mockRepo.updateOAuthTokens).toHaveBeenCalledWith(
        mockContext,
        'test-integration-id',
        expect.objectContaining({
          accessToken: expect.any(String),
          tokenExpiresAt: expect.any(Date),
        })
      );
    });

    it('should handle missing refresh token', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('old-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() - 1000),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      const result = await googleCalendar.refreshTokens(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(false);
    });

    it('should handle refresh token failure', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('old-token').toString('base64'),
        refreshToken: Buffer.from('refresh-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() - 1000),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({
          error: 'invalid_grant',
          error_description: 'Token has been revoked',
        }),
      } as Response);

      const result = await googleCalendar.refreshTokens(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(false);
      expect(mockRepo.updateStatus).toHaveBeenCalledWith(
        mockContext,
        'test-integration-id',
        'error',
        expect.any(String)
      );
    });
  });

  // ============================================
  // Sync Tests
  // ============================================

  describe('sync', () => {
    it('should sync calendar successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({
          items: [
            {
              id: 'event-1',
              summary: 'Event 1',
              start: { dateTime: new Date().toISOString() },
              end: { dateTime: new Date().toISOString() },
            },
          ],
        }),
      } as Response);

      const result = await googleCalendar.sync(mockContext, 'test-integration-id');

      expect(result.success).toBe(true);
      expect(result.data?.integrationId).toBe('test-integration-id');
      expect(mockRepo.recordSync).toHaveBeenCalled();
    });

    it('should refresh token if expired during sync', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('old-token').toString('base64'),
        refreshToken: Buffer.from('refresh-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() - 1000), // Expired
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });
      mockRepo.getById.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      // Mock token refresh
      mockFetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            access_token: 'new-token',
            expires_in: 3600,
          }),
        } as Response)
        // Mock calendar fetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ items: [] }),
        } as Response);

      await googleCalendar.sync(mockContext, 'test-integration-id');

      expect(mockRepo.updateOAuthTokens).toHaveBeenCalled();
    });

    it('should record error on sync failure', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockRejectedValue(new Error('Network error'));

      const result = await googleCalendar.sync(mockContext, 'test-integration-id');

      expect(result.success).toBe(false);
      expect(mockRepo.recordError).toHaveBeenCalled();
    });
  });

  // ============================================
  // Test Connection Tests
  // ============================================

  describe('testConnection', () => {
    it('should test connection successfully', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({
          summary: 'test@example.com',
          timeZone: 'UTC',
        }),
      } as Response);

      const result = await googleCalendar.testConnection(
        mockContext,
        'test-integration-id'
      );

      expect(result.success).toBe(true);
      expect(result.data?.success).toBe(true);
      expect(result.data?.message).toContain('valid');
    });
  });

  // ============================================
  // HIPAA Compliance Tests
  // ============================================

  describe('HIPAA Compliance', () => {
    it('should not include PHI in event descriptions', async () => {
      const mockIntegration = {
        id: 'test-integration-id',
        accessToken: Buffer.from('test-access-token').toString('base64'),
        tokenExpiresAt: new Date(Date.now() + 3600 * 1000),
        config: { calendarId: 'primary' },
      };

      const mockRepo = mockIntegrationRepo;
      mockRepo.getByIdWithTokens.mockResolvedValue({
        success: true,
        data: mockIntegration,
      });

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: 'event-123' }),
      } as Response);

      const eventWithPHI: CalendarEventInput = {
        summary: 'Appointment with John Doe',
        description:
          'Patient john.doe@example.com, phone 555-123-4567, SSN 123-45-6789',
        startDateTime: new Date(),
        endDateTime: new Date(),
      };

      await googleCalendar.createEvent(
        'test-integration-id',
        eventWithPHI,
        'test-business-id'
      );

      const fetchCall = mockFetch.mock.calls[0];
      const body = JSON.parse(fetchCall[1]?.body as string);

      expect(body.summary).not.toContain('John Doe');
      expect(body.description).not.toContain('john.doe@example.com');
      expect(body.description).not.toContain('555-123-4567');
      expect(body.description).not.toContain('123-45-6789');
    });
  });
});
