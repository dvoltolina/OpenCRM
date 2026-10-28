import { renderHook, act, waitFor } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import type {
  EmailAccount,
  EmailMessage,
  EmailTemplate,
  EmailThread,
} from '../../types/email-integration';
import { useEmailIntegration } from '../useEmailIntegration';

const now = new Date();

const mockAccounts: EmailAccount[] = [
  {
    id: 'acc-1',
    businessId: 'biz-1',
    userId: 'user-1',
    provider: 'gmail',
    email: 'user@example.com',
    displayName: 'User',
    accessToken: 'enc',
    refreshToken: 'enc',
    tokenExpiresAt: now,
    syncStatus: 'synced',
    lastSyncAt: now,
    syncEnabled: true,
    syncInbound: true,
    syncOutbound: true,
    autoAssociate: true,
    createdAt: now,
  },
];

const mockMessage: EmailMessage = {
  id: 'msg-1',
  businessId: 'biz-1',
  accountId: 'acc-1',
  providerMessageId: 'pm-1',
  threadId: 'thread-1',
  fromEmail: 'sender@example.com',
  fromName: 'Sender',
  toEmails: ['lead@example.com'],
  subject: 'Test Subject',
  snippet: 'Snippet text',
  direction: 'outbound',
  sentAt: now,
  associatedEntityType: 'lead',
  associatedEntityId: 'lead-1',
  opens: 1,
  clicks: 0,
  hasAttachments: false,
  isRead: true,
  isStarred: false,
  labels: [],
  createdAt: now,
  bodyText: 'Hello',
};

const mockTemplate: EmailTemplate = {
  id: 'tpl-1',
  businessId: 'biz-1',
  name: 'Welcome',
  subject: 'Welcome Subject',
  bodyHtml: '<p>Welcome</p>',
  availableMergeFields: ['firstName'],
  category: 'outreach',
  isActive: true,
  usageCount: 0,
  createdById: 'user-1',
  createdAt: now,
};

const mockThread: EmailThread & { messages: EmailMessage[] } = {
  id: 'thread-1',
  businessId: 'biz-1',
  accountId: 'acc-1',
  providerThreadId: 'prov-1',
  subject: 'Thread subject',
  participantEmails: ['sender@example.com', 'lead@example.com'],
  messageCount: 1,
  lastMessageAt: now,
  lastMessageSnippet: 'Snippet text',
  createdAt: now,
  messages: [mockMessage],
};

const mockService = {
  isConfigured: vi.fn(() => true),
  getAccounts: vi.fn(async () => mockAccounts),
  getTemplates: vi.fn(async () => [mockTemplate]),
  getEmailsForEntity: vi.fn(async () => [mockMessage]),
  searchEmails: vi.fn(async () => [mockMessage]),
  getThread: vi.fn(async () => mockThread),
  connectAccount: vi.fn(async () => mockAccounts[0]),
  disconnectAccount: vi.fn(async () => undefined),
  refreshTokens: vi.fn(async () => undefined),
  syncInbox: vi.fn(async () => ({ success: true, created: 0, updated: 0 })),
  syncSentFolder: vi.fn(async () => ({ success: true, created: 0, updated: 0 })),
  sendEmail: vi.fn(async () => ({ success: true, messageId: 'msg-1' })),
  sendTemplatedEmail: vi.fn(async () => ({ success: true, messageId: 'msg-2' })),
  createTemplate: vi.fn(async (_ctx, payload) => ({ ...payload, id: 'tpl-2', createdAt: now })),
  deleteTemplate: vi.fn(async () => undefined),
  associateEmail: vi.fn(async () => undefined),
  autoAssociateEmails: vi.fn(async () => 1),
};

let getFeatureFlagsMock: ReturnType<typeof vi.fn>;

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => {
    if (!getFeatureFlagsMock) {
      getFeatureFlagsMock = vi.fn(() => ({ enableEmailIntegration: true }));
    }
    return getFeatureFlagsMock();
  },
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      email: 'user@example.com',
      displayName: 'User',
      role: 'owner',
      businessId: 'biz-1',
      teamIds: [],
      managedTeamIds: [],
    },
  }),
}));

vi.mock('../../services/email-integration-service', () => ({
  getEmailIntegrationService: () => mockService,
}));

describe('useEmailIntegration', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    if (!getFeatureFlagsMock) {
      getFeatureFlagsMock = vi.fn(() => ({ enableEmailIntegration: true }));
    } else {
      getFeatureFlagsMock.mockReturnValue({ enableEmailIntegration: true });
    }
  });

  it('returns disabled state when feature flag is off', () => {
    getFeatureFlagsMock.mockReturnValue({ enableEmailIntegration: false });
    const { result } = renderHook(() => useEmailIntegration());
    expect(result.current.enabled).toBe(false);
    expect(result.current.contextReady).toBe(false);
  });

  it('loads accounts, templates, and emails for an entity', async () => {
    const { result } = renderHook(() =>
      useEmailIntegration({ entityType: 'lead', entityId: 'lead-1' })
    );

    await waitFor(() => {
      expect(result.current.accounts).toHaveLength(1);
      expect(result.current.templates).toHaveLength(1);
    });

    await waitFor(() => {
      expect(result.current.emails[0]?.id).toBe('msg-1');
    });

    expect(mockService.getAccounts).toHaveBeenCalled();
    expect(mockService.getTemplates).toHaveBeenCalled();
    expect(mockService.getEmailsForEntity).toHaveBeenCalled();
  });

  it('sends email with selected account and refreshes emails', async () => {
    const { result } = renderHook(() =>
      useEmailIntegration({ entityType: 'lead', entityId: 'lead-1' })
    );

    await waitFor(() => expect(result.current.accounts).toHaveLength(1));

    await act(async () => {
      await result.current.sendEmail({
        to: ['target@example.com'],
        subject: 'Hello',
        bodyHtml: '<p>Hello</p>',
      });
    });

    expect(mockService.sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'biz-1' }),
      expect.objectContaining({
        to: ['target@example.com'],
        accountId: 'acc-1',
      })
    );
  });

  it('associates an email to an entity', async () => {
    const { result } = renderHook(() =>
      useEmailIntegration({ entityType: 'lead', entityId: 'lead-1' })
    );

    await act(async () => {
      await result.current.associateEmail('msg-1', 'lead', 'lead-1');
    });

    expect(mockService.associateEmail).toHaveBeenCalledWith(
      expect.objectContaining({ businessId: 'biz-1' }),
      'msg-1',
      'lead',
      'lead-1'
    );
  });
});
