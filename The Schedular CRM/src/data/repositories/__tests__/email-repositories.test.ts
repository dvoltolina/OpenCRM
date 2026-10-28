import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import type { SecurityContext } from '../repository-types';
import { EmailAccountRepository } from '../email-account-repository';
import { EmailMessageRepository } from '../email-message-repository';
import { EmailTemplateRepository } from '../email-template-repository';
import { BaseRepository } from '../base-repository';
import type { EmailAccount, EmailMessage } from '../../../types/email-integration';
import type { EmailTemplate } from '../../../types/email';
import {
  AuthorizationError,
  failedResult,
  successResult,
} from '../../errors/repository-errors';

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(() => ({ docs: [], empty: true })),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  onSnapshot: vi.fn(),
  writeBatch: vi.fn(),
  Timestamp: {
    now: vi.fn(() => ({ toDate: () => new Date() })),
    fromDate: vi.fn(() => ({ toDate: () => new Date() })),
  },
}));

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

vi.mock('../../../lib/collections', () => ({
  businessPath: vi.fn((businessId: string) => `businesses/${businessId}`),
}));

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'admin-1',
  userName: 'Admin User',
  userRole: 'owner',
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-1',
  userName: 'Staff User',
  userRole: 'staff',
};

describe('EmailAccountRepository RBAC', () => {
  let repo: EmailAccountRepository;

  beforeEach(() => {
    repo = new EmailAccountRepository();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('allows privileged lookup for other users without double scoping filters', async () => {
    const superGetAll = vi
      .spyOn(BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll }, 'getAll')
      .mockResolvedValue(successResult({ data: [], lastDoc: null, hasMore: false }));

    await repo.getByUserId(adminContext, 'other-user');

    expect(superGetAll).toHaveBeenCalledTimes(1);
    const optionsArg = superGetAll.mock.calls[0][1]!;
    expect(optionsArg.where).toEqual([{ field: 'userId', operator: '==', value: 'other-user' }]);
  });

  it('blocks non-privileged lookup for another user', async () => {
    const result = await repo.getByUserId(staffContext, 'other-user');

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
  });

  it('prevents creating accounts for other users when not privileged', async () => {
    const superCreate = vi
      .spyOn(BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create }, 'create')
      .mockResolvedValue(successResult({} as EmailAccount));

    const result = await repo.create(staffContext, {
      provider: 'gmail',
      email: 'other@example.com',
      userId: 'other-user',
      businessId: staffContext.businessId,
      accessToken: 'enc-access',
      refreshToken: 'enc-refresh',
      tokenExpiresAt: new Date(),
      syncStatus: 'synced',
      syncEnabled: true,
      syncInbound: true,
      syncOutbound: true,
      autoAssociate: true,
      lastSyncAt: undefined,
      syncCursor: undefined,
    });

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('PERMISSION_DENIED');
    expect(superCreate).not.toHaveBeenCalled();
  });
});

describe('EmailMessageRepository access cache', () => {
  let repo: EmailMessageRepository;
  let superGetAll: any;
  const message: EmailMessage = {
    id: 'msg-1',
    businessId: 'biz-1',
    accountId: 'acct-1',
    providerMessageId: 'pm-1',
    fromEmail: 'sender@example.com',
    toEmails: ['recipient@example.com'],
    subject: 'Hello',
    snippet: 'Hello',
    direction: 'outbound',
    sentAt: new Date(),
    trackingId: 'track-1',
    opens: 0,
    clicks: 0,
    hasAttachments: false,
    isRead: false,
    isStarred: false,
    createdAt: new Date(),
  };

  beforeEach(() => {
    superGetAll = vi
      .spyOn(BaseRepository.prototype as unknown as { getAll: typeof BaseRepository.prototype.getAll }, 'getAll')
      .mockResolvedValue(successResult({ data: [message], lastDoc: null, hasMore: false }));

    repo = new EmailMessageRepository();
    const accountRepoStub = {
      getById: vi.fn(async (context: SecurityContext) => {
        if (context.userRole === 'owner' || context.userRole === 'admin') {
          return successResult({ userId: context.userId } as EmailAccount);
        }
        return failedResult(new AuthorizationError('forbidden'));
      }),
    };

    (repo as unknown as { accountRepo: typeof accountRepoStub }).accountRepo = accountRepoStub as never;
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('does not reuse account access cache across users', async () => {
    await repo.getAll(adminContext);
    const staffResult = await repo.getAll(staffContext);

    const accountRepo = (repo as unknown as { accountRepo: { getById: ReturnType<typeof vi.fn> } }).accountRepo;
    const callerIds = accountRepo.getById.mock.calls.map(([ctx]) => (ctx as SecurityContext).userId);
    expect(callerIds).toContain(staffContext.userId);
    expect(staffResult.success).toBe(true);
    expect(staffResult.data?.data ?? []).toHaveLength(0);
    expect(superGetAll).toHaveBeenCalledTimes(2);
  });

  it('enforces access checks when resolving tracking IDs', async () => {
    const trackingResult = await repo.getByTrackingId(staffContext, 'track-1');

    expect(trackingResult.success).toBe(false);
    expect(trackingResult.error?.code).toBe('PERMISSION_DENIED');
  });
});

describe('EmailTemplateRepository validation', () => {
  let repo: EmailTemplateRepository;

  type TemplateInput = Omit<EmailTemplate, 'id' | 'createdAt' | 'updatedAt'> & {
    category?: 'transactional' | 'outreach' | 'followup' | 'nurture';
  };

  const buildTemplateInput = (
    overrides: Partial<TemplateInput> = {}
  ): TemplateInput => ({
    businessId: adminContext.businessId,
    name: 'Template',
    type: 'custom',
    subject: 'Subject',
    textBody: 'Body text',
    htmlBody: '<p>Body text</p>',
    bodyHtml: '<p>Body text</p>',
    bodyText: 'Body text',
    sendGridTemplateId: 'sg-1',
    isActive: true,
    category: 'outreach',
    createdById: 'creator',
    availableMergeFields: ['firstName'],
    usageCount: 0,
    ...overrides,
  });

  beforeEach(() => {
    repo = new EmailTemplateRepository();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('rejects PHI-like placeholders in HTML bodies', async () => {
    const createSpy = vi.spyOn(BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create }, 'create');
    const result = await repo.create(adminContext, buildTemplateInput({ bodyHtml: '<p>{{patient name}}</p>' }));

    expect(result.success).toBe(false);
    expect(createSpy).not.toHaveBeenCalled();
  });

  it('normalizes body fields for compatibility on create', async () => {
    const createSpy = vi
      .spyOn(BaseRepository.prototype as unknown as { create: typeof BaseRepository.prototype.create }, 'create')
      .mockImplementation(async (_context, data) =>
        successResult({
          ...(data as Record<string, unknown>),
          id: 'tmpl-1',
          createdAt: new Date(),
        } as EmailTemplate)
      );

    const result = await repo.create(
      adminContext,
      buildTemplateInput({
        bodyHtml: '<p>Welcome</p>',
        bodyText: 'Welcome',
        availableMergeFields: undefined,
      })
    );

    expect(result.success).toBe(true);
    const passedData = createSpy.mock.calls[0][1] as EmailTemplate;
    expect(passedData.textBody).toBe('Welcome');
    expect(passedData.htmlBody).toBe('<p>Welcome</p>');
    expect(passedData.bodyText).toBe('Welcome');
    expect(passedData.bodyHtml).toBe('<p>Welcome</p>');
    expect(passedData.availableMergeFields).toEqual([]);
    expect(passedData.businessId).toBe(adminContext.businessId);
  });
});
