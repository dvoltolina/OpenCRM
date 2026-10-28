import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import type { SecurityContext } from '../../data/repositories/repository-types';
import { EmailTrackingService } from '../email-tracking-service';
import type { EmailMessage } from '../../types/email-integration';

const messageRepoMock = {
  getById: vi.fn(),
  getByTrackingId: vi.fn(),
  update: vi.fn(),
};

const trackingRepoMock = {
  getByTrackingId: vi.fn(),
  create: vi.fn(),
};

vi.mock('../../data/repositories/email-message-repository', () => ({
  getEmailMessageRepository: vi.fn(() => messageRepoMock),
}));

vi.mock('../../data/repositories/email-tracking-event-repository', () => ({
  getEmailTrackingEventRepository: vi.fn(() => trackingRepoMock),
}));

const baseContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const baseMessage = (): EmailMessage => ({
  id: 'msg-1',
  businessId: 'biz-1',
  accountId: 'acct-1',
  providerMessageId: 'prov-1',
  threadId: undefined,
  fromEmail: 'from@example.com',
  fromName: 'Sender',
  toEmails: ['to@example.com'],
  ccEmails: [],
  bccEmails: [],
  subject: 'Hello',
  bodyText: 'Hello world',
  bodyHtml: '<p>Hello world</p>',
  snippet: 'Hello world',
  direction: 'outbound',
  sentAt: new Date('2024-01-01T00:00:00Z'),
  receivedAt: undefined,
  associatedEntityType: undefined,
  associatedEntityId: undefined,
  associatedByUserId: undefined,
  trackingId: 'track-1',
  opens: 0,
  clicks: 0,
  attachments: [],
  hasAttachments: false,
  isRead: true,
  isStarred: false,
  labels: [],
  createdAt: new Date('2024-01-01T00:00:00Z'),
  updatedAt: new Date('2024-01-01T00:00:00Z'),
});

const restoreEnv = process.env.VITE_FUNCTIONS_BASE_URL;

describe('EmailTrackingService', () => {
  beforeEach(() => {
    process.env.VITE_FUNCTIONS_BASE_URL = 'https://functions.test';
    vi.clearAllMocks();
  });

  afterEach(() => {
    process.env.VITE_FUNCTIONS_BASE_URL = restoreEnv;
  });

  it('injects tracking pixel and wraps links when tracking is enabled', async () => {
    const service = new EmailTrackingService();
    const message = baseMessage();

    messageRepoMock.getById.mockResolvedValue({ success: true, data: message, error: null });
    messageRepoMock.update.mockResolvedValue({ success: true, data: { ...message }, error: null });

    const html = '<p>Test <a href="https://example.com/path">Link</a> <a href="mailto:test@example.com">Mail</a></p>';
    const result = await service.prepareEmailForTracking(baseContext, message.id, html, {
      trackOpens: true,
      trackClicks: true,
    });

    expect(result).toContain('trackEmailOpen?tid=track-1&bid=biz-1&mid=msg-1');
    expect(result).toContain('trackEmailClick?tid=track-1&bid=biz-1&mid=msg-1&url=https%3A%2F%2Fexample.com%2Fpath');
    expect(result).toContain('style="display:block;width:1px;height:1px;max-width:1px;max-height:1px;border:0;line-height:0;"');
    expect(result).toContain('mailto:test@example.com'); // mailto links are not wrapped

    expect(messageRepoMock.update).toHaveBeenCalledWith(
      baseContext,
      message.id,
      expect.objectContaining({
        trackingId: 'track-1',
        opens: 0,
        clicks: 0,
      })
    );
  });

  it('deduplicates opens by ip hash and user agent', async () => {
    const service = new EmailTrackingService();
    const message = baseMessage();

    const storedMessage = { ...message };
    messageRepoMock.getById.mockResolvedValue({ success: true, data: storedMessage, error: null });
    messageRepoMock.getByTrackingId.mockResolvedValue({ success: true, data: storedMessage, error: null });
    messageRepoMock.update.mockImplementation(async (_ctx, _id, updates) => {
      Object.assign(storedMessage, updates);
      return { success: true, data: storedMessage, error: null };
    });

    const firstOpen = { success: true, data: { data: [], lastDoc: null, hasMore: false }, error: null };
    const duplicateOpen = {
      success: true,
      data: {
        data: [
          {
            id: 'evt-1',
            businessId: 'biz-1',
            messageId: message.id,
            trackingId: message.trackingId!,
            eventType: 'open' as const,
            occurredAt: new Date('2024-01-01T00:01:00Z'),
            ipAddress: 'hash-ip',
            userAgent: 'ua',
          },
        ],
        lastDoc: null,
        hasMore: false,
      },
      error: null,
    };

    trackingRepoMock.getByTrackingId
      .mockResolvedValueOnce(firstOpen)
      .mockResolvedValueOnce(duplicateOpen);

    trackingRepoMock.create.mockResolvedValue({ success: true, data: null, error: null });

    await service.recordOpen(message.trackingId!, {
      businessId: 'biz-1',
      messageId: message.id,
      ipHash: 'hash-ip',
      userAgent: 'ua',
      occurredAt: new Date('2024-01-01T00:01:00Z'),
    });

    await service.recordOpen(message.trackingId!, {
      businessId: 'biz-1',
      messageId: message.id,
      ipHash: 'hash-ip',
      userAgent: 'ua',
      occurredAt: new Date('2024-01-01T00:02:00Z'),
    });

    expect(trackingRepoMock.create).toHaveBeenCalledTimes(1);
    expect(messageRepoMock.update).toHaveBeenCalledTimes(1);
    expect(storedMessage.opens).toBe(1);
    expect(storedMessage.firstOpenedAt).toEqual(new Date('2024-01-01T00:01:00Z'));
  });

  it('increments clicks for each tracked click', async () => {
    const service = new EmailTrackingService();
    const message = baseMessage();
    const storedMessage = { ...message };

    messageRepoMock.getById.mockResolvedValue({ success: true, data: storedMessage, error: null });
    messageRepoMock.getByTrackingId.mockResolvedValue({ success: true, data: storedMessage, error: null });
    messageRepoMock.update.mockImplementation(async (_ctx, _id, updates) => {
      Object.assign(storedMessage, updates);
      return { success: true, data: storedMessage, error: null };
    });

    trackingRepoMock.getByTrackingId.mockResolvedValue({
      success: true,
      data: { data: [], lastDoc: null, hasMore: false },
      error: null,
    });
    trackingRepoMock.create.mockResolvedValue({ success: true, data: null, error: null });

    await service.recordClick(message.trackingId!, 'https://example.com', {
      businessId: 'biz-1',
      messageId: message.id,
    });
    await service.recordClick(message.trackingId!, 'https://example.com', {
      businessId: 'biz-1',
      messageId: message.id,
    });

    expect(storedMessage.clicks).toBe(2);
    expect(trackingRepoMock.create).toHaveBeenCalledTimes(2);
    expect(messageRepoMock.update).toHaveBeenCalledTimes(2);
  });
});
