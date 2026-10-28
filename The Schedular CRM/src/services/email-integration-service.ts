/**
 * Email Integration Service
 * Provides inbox connection, sync scaffolding, send, and association helpers.
 *
 * Note: Provider-specific OAuth/webhook handling is deferred to Cloud Functions.
 * This service focuses on repository interactions and client-side safeguards.
 */

import { getAuth } from 'firebase/auth';
import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getEmailAccountRepository,
  getEmailMessageRepository,
  getEmailThreadRepository,
  getEmailTemplateRepository,
} from '../data/repositories';
import type {
  EmailAccount,
  EmailMessage,
  EmailDirection,
  EmailTemplate,
  EmailProvider,
  EmailThread,
  EmailAttachment,
} from '../types/email-integration';
import { generateId } from '../data/repositories/firestore-utils';
import { getFeatureFlags } from '../config/features';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService, type LogActionOptions } from './AuditLogService';
import { getEmailTrackingService, EmailTrackingService } from './email-tracking-service';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { getFunctionsBaseUrl } from './functions-base-url';

export interface SyncResult {
  success: boolean;
  created: number;
  updated: number;
  skipped?: number;
  errors?: string[];
  cursor?: string;
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  providerMessageId?: string;
  trackingId?: string;
  threadId?: string;
  error?: string;
}

interface EmailIntegrationServiceConfig {
  functionsBaseUrl: string;
  connectPath: string;
  refreshPath: string;
  syncInboxPath: string;
  syncSentPath: string;
  sendPath: string;
  disconnectPath: string;
}

interface ConnectAccountResponse {
  accountId?: string;
  email?: string;
  displayName?: string;
  accessToken?: string;
  refreshToken?: string;
  expiresAt?: string | number | Date;
  syncCursor?: string;
}

interface RefreshTokensResponse {
  accountId?: string;
  accessToken?: string;
  refreshToken?: string;
  expiresAt?: string | number | Date;
}

interface SendEmailFunctionResponse {
  providerMessageId?: string;
  threadId?: string;
  trackingId?: string;
  sentAt?: string | number | Date;
}

type AssociationTarget = { type: 'lead' | 'client'; id: string };

const DEFAULT_SNIPPET_LENGTH = 200;

const defaultConfig: EmailIntegrationServiceConfig = {
  functionsBaseUrl: '',
  connectPath: '/connectEmailAccount',
  refreshPath: '/refreshEmailTokens',
  syncInboxPath: '/syncEmailInbox',
  syncSentPath: '/syncEmailSent',
  sendPath: '/sendIntegratedEmail',
  disconnectPath: '/disconnectEmailAccount',
};

const now = () => new Date();

const stripHtml = (html?: string): string =>
  (html || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

const buildSnippet = (text?: string, html?: string): string => {
  const source = text?.trim() || stripHtml(html);
  return source.slice(0, DEFAULT_SNIPPET_LENGTH);
};

const normalizeEmail = (email?: string): string => email?.trim().toLowerCase() || '';

const toDate = (value?: string | number | Date): Date => {
  if (!value) return now();
  return value instanceof Date ? value : new Date(value);
};

export class EmailIntegrationService {
  private accounts = getEmailAccountRepository();
  private messages = getEmailMessageRepository();
  private threads = getEmailThreadRepository();
  private templates = getEmailTemplateRepository();
  private contacts = getContactRepository();
  private leads = getLeadRepository();
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private tracking: EmailTrackingService;
  private config: EmailIntegrationServiceConfig;

  constructor(config: Partial<EmailIntegrationServiceConfig> = {}) {
    this.config = { ...defaultConfig, ...config };
    this.rateLimit = getRateLimitService();
    this.audit = getAuditLogService();
    this.tracking = getEmailTrackingService();
  }

  // ============================================
  // Account management
  // ============================================

  async connectAccount(
    context: SecurityContext,
    provider: EmailProvider,
    authCode: string
  ): Promise<EmailAccount> {
    this.assertEnabled();

    const response = await this.callEmailFunction<ConnectAccountResponse>(context, this.config.connectPath, {
      provider,
      authCode,
      businessId: context.businessId,
      userId: context.userId,
    });

    if (response.accountId) {
      const stored = await this.accounts.getById(context, response.accountId);
      if (!stored.success || !stored.data) {
        throw new Error(stored.error?.message || 'Backend created account was not available');
      }

      await this.logAudit(context, {
        action: 'integration',
        entityType: 'integration',
        entityId: stored.data.id,
        metadata: { provider, operation: 'connect' },
      });

      return stored.data;
    }

    if (!response.accessToken || !response.refreshToken) {
      throw new Error('Mail provider token exchange failed');
    }

    const result = await this.accounts.create(context, {
      businessId: context.businessId,
      userId: context.userId,
      provider,
      email: normalizeEmail(response.email) || `${context.userId}-${provider}@pending.example.com`,
      displayName: response.displayName || context.userName,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      tokenExpiresAt: toDate(response.expiresAt),
      syncStatus: 'syncing',
      lastSyncAt: undefined,
      syncCursor: response.syncCursor,
      syncEnabled: true,
      syncInbound: true,
      syncOutbound: true,
      autoAssociate: true,
    });

    if (!result.success || !result.data) {
      throw new Error(result.error?.message || 'Failed to store inbox account');
    }

    await this.logAudit(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: result.data.id,
      metadata: { provider, operation: 'connect' },
    });

    return result.data;
  }

  async disconnectAccount(context: SecurityContext, accountId: string): Promise<void> {
    this.assertEnabled();
    const account = await this.getAccountOrThrow(context, accountId);

    try {
      await this.callEmailFunction(context, this.config.disconnectPath, {
        accountId,
        provider: account.provider,
        businessId: context.businessId,
      });
    } catch {
      // Best-effort revoke; still mark account as disconnected
    }

    await this.accounts.update(context, accountId, {
      syncEnabled: false,
      syncStatus: 'disconnected',
      accessToken: '',
      refreshToken: '',
      syncCursor: undefined,
      updatedAt: now(),
    });

    await this.logAudit(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: accountId,
      metadata: { provider: account.provider, operation: 'disconnect' },
    });
  }

  async refreshTokens(context: SecurityContext, accountId: string): Promise<void> {
    this.assertEnabled();
    const account = await this.getAccountOrThrow(context, accountId);
    const limit = await this.rateLimit.checkLimit('integration_sync', context.userId, context.businessId);

    if (!limit.allowed) {
      throw new Error(limit.message || 'Token refresh rate limit exceeded');
    }

    try {
      const response = await this.callEmailFunction<RefreshTokensResponse>(
        context,
        this.config.refreshPath,
        {
          accountId,
          provider: account.provider,
          businessId: context.businessId,
        }
      );

      if (response.accessToken || response.refreshToken || response.expiresAt) {
        await this.accounts.update(context, accountId, {
          accessToken: response.accessToken || account.accessToken,
          refreshToken: response.refreshToken || account.refreshToken,
          tokenExpiresAt: response.expiresAt ? toDate(response.expiresAt) : account.tokenExpiresAt,
          updatedAt: now(),
          syncStatus: 'synced',
        });
      }

      await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);
    } catch (error) {
      await this.accounts.update(context, accountId, {
        syncStatus: 'error',
        updatedAt: now(),
      });
      throw error;
    }
  }

  async getAccounts(context: SecurityContext): Promise<EmailAccount[]> {
    if (!this.isEnabled()) return [];
    const result = await this.accounts.getByUserId(context);
    if (!result.success || !result.data) {
      return [];
    }
    return result.data.data;
  }

  // ============================================
  // Sync operations (delegated to Cloud Functions)
  // ============================================

  async syncInbox(context: SecurityContext, accountId: string): Promise<SyncResult> {
    return this.runSync(context, accountId, this.config.syncInboxPath, 'inbox');
  }

  async syncSentFolder(context: SecurityContext, accountId: string): Promise<SyncResult> {
    return this.runSync(context, accountId, this.config.syncSentPath, 'sent');
  }

  // ============================================
  // Send email
  // ============================================

  async sendEmail(
    context: SecurityContext,
    options: {
      accountId: string;
      to: string[];
      cc?: string[];
      bcc?: string[];
      subject: string;
      bodyHtml: string;
      bodyText?: string;
      attachments?: File[];
      trackOpens?: boolean;
      trackClicks?: boolean;
      associatedEntity?: { type: string; id: string };
    }
  ): Promise<SendEmailResult> {
    this.assertEnabled();
    const account = await this.getAccountOrThrow(context, options.accountId);
    const limit = await this.rateLimit.checkLimit('email', context.userId, context.businessId);

    if (!limit.allowed) {
      return {
        success: false,
        error: limit.message || 'Email rate limit exceeded',
      };
    }

    const messageId = generateId();
    const trackingId = options.trackOpens || options.trackClicks ? generateId() : undefined;
    const attachments = this.mapAttachments(options.attachments, messageId);
    const bodyText = options.bodyText || stripHtml(options.bodyHtml);
    const snippet = buildSnippet(bodyText, options.bodyHtml);

    const messagePayload: Omit<EmailMessage, 'id'> = {
      businessId: context.businessId,
      accountId: options.accountId,
      providerMessageId: messageId,
      threadId: undefined,
      fromEmail: normalizeEmail(account.email),
      fromName: account.displayName || context.userName,
      toEmails: options.to.map(normalizeEmail),
      ccEmails: options.cc?.map(normalizeEmail),
      bccEmails: options.bcc?.map(normalizeEmail),
      subject: options.subject,
      bodyText,
      bodyHtml: options.bodyHtml,
      snippet,
      direction: 'outbound',
      sentAt: now(),
      receivedAt: undefined,
      associatedEntityType: options.associatedEntity?.type as EmailMessage['associatedEntityType'],
      associatedEntityId: options.associatedEntity?.id,
      associatedByUserId: options.associatedEntity ? context.userId : undefined,
      trackingId,
      opens: 0,
      clicks: 0,
      attachments,
      hasAttachments: attachments.length > 0,
      isRead: true,
      isStarred: false,
      labels: [],
      createdAt: now(),
      updatedAt: now(),
    };

    const created = await this.messages.create(context, messagePayload, messageId);
    if (!created.success || !created.data) {
      return {
        success: false,
        error: created.error?.message || 'Failed to queue email',
      };
    }

    let finalBodyHtml = options.bodyHtml;
    if (options.trackOpens || options.trackClicks) {
      finalBodyHtml = await this.tracking.prepareEmailForTracking(
        context,
        created.data.id,
        options.bodyHtml,
        { trackOpens: Boolean(options.trackOpens), trackClicks: Boolean(options.trackClicks) }
      );

      await this.messages.update(context, created.data.id, {
        bodyHtml: finalBodyHtml,
        updatedAt: now(),
      });
    }

    try {
      const response = await this.callEmailFunction<SendEmailFunctionResponse>(
        context,
        this.config.sendPath,
        {
          accountId: options.accountId,
          businessId: context.businessId,
          messageId,
          trackingId,
          to: messagePayload.toEmails,
          cc: messagePayload.ccEmails,
          bcc: messagePayload.bccEmails,
          subject: options.subject,
          bodyHtml: finalBodyHtml,
          bodyText,
          attachments,
          associatedEntity: options.associatedEntity,
          provider: account.provider,
        }
      );

      await this.messages.update(context, created.data.id, {
        providerMessageId: response.providerMessageId || created.data.providerMessageId,
        threadId: response.threadId || created.data.threadId,
        trackingId: response.trackingId || created.data.trackingId,
        sentAt: response.sentAt ? toDate(response.sentAt) : created.data.sentAt,
        updatedAt: now(),
      });

      await this.rateLimit.recordAction('email', context.userId, context.businessId);

      await this.logAudit(context, {
        action: 'create',
        entityType: 'activity',
        entityId: created.data.id,
        metadata: {
          type: 'email',
          direction: 'outbound',
          accountId: options.accountId,
          associatedEntityType: options.associatedEntity?.type,
          associatedEntityId: options.associatedEntity?.id,
        },
      });

      return {
        success: true,
        messageId: created.data.id,
        providerMessageId: response.providerMessageId || created.data.providerMessageId,
        trackingId: response.trackingId || created.data.trackingId,
        threadId: response.threadId || created.data.threadId,
      };
    } catch (error) {
      await this.messages.update(context, created.data.id, {
        labels: ['send_error'],
        updatedAt: now(),
      });
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to send email',
        messageId: created.data.id,
      };
    }
  }

  async sendTemplatedEmail(
    context: SecurityContext,
    options: {
      accountId: string;
      templateId: string;
      to: string[];
      mergeData: Record<string, string>;
      associatedEntity?: { type: string; id: string };
    }
  ): Promise<SendEmailResult> {
    this.assertEnabled();
    const templateResult = await this.templates.getById(context, options.templateId);
    const template = templateResult.success ? templateResult.data : null;

    if (!template || template.isActive === false) {
      return { success: false, error: 'Template not found or inactive' };
    }

    const bodyHtml = this.applyMerge(template.bodyHtml || template.htmlBody || '', options.mergeData);
    const bodyText = this.applyMerge(template.bodyText || template.textBody || '', options.mergeData);
    const subject = this.applyMerge(template.subject, options.mergeData);

    const sendResult = await this.sendEmail(context, {
      accountId: options.accountId,
      to: options.to,
      subject,
      bodyHtml,
      bodyText,
      associatedEntity: options.associatedEntity,
      trackOpens: true,
      trackClicks: true,
    });

    if (sendResult.success) {
      await this.templates.incrementUsage(context, options.templateId);
    }

    return sendResult;
  }

  // ============================================
  // Association helpers
  // ============================================

  async associateEmail(
    context: SecurityContext,
    messageId: string,
    entityType: string,
    entityId: string
  ): Promise<void> {
    this.assertEnabled();
    await this.messages.update(context, messageId, {
      associatedEntityType: entityType as EmailMessage['associatedEntityType'],
      associatedEntityId: entityId,
      associatedByUserId: context.userId,
      updatedAt: now(),
    });
  }

  async autoAssociateEmails(context: SecurityContext, accountId: string): Promise<number> {
    this.assertEnabled();
    const unlinkedResult = await this.messages.getUnassociated(context, accountId);
    if (!unlinkedResult.success || !unlinkedResult.data) return 0;

    let associated = 0;
    const cache = new Map<string, AssociationTarget | null>();

    for (const message of unlinkedResult.data) {
      const candidateEmails = this.getCandidateEmails(message);
      for (const email of candidateEmails) {
        const association = await this.findAssociationByEmail(context, email, cache);
        if (association) {
          await this.messages.update(context, message.id, {
            associatedEntityType: association.type,
            associatedEntityId: association.id,
            associatedByUserId: context.userId,
            updatedAt: now(),
          });
          associated += 1;
          break;
        }
      }
    }

    return associated;
  }

  // ============================================
  // Queries
  // ============================================

  async getEmailsForEntity(
    context: SecurityContext,
    entityType: string,
    entityId: string
  ): Promise<EmailMessage[]> {
    if (!this.isEnabled()) return [];
    const result = await this.messages.getByEntity(
      context,
      entityType as EmailMessage['associatedEntityType'],
      entityId
    );
    if (!result.success || !result.data) return [];
    return result.data.data;
  }

  async getThread(
    context: SecurityContext,
    threadId: string
  ): Promise<EmailThread & { messages: EmailMessage[] }> {
    if (!this.isEnabled()) {
      throw new Error('Messaging integration is disabled');
    }
    const threadResult = await this.threads.getById(context, threadId);
    if (!threadResult.success || !threadResult.data) {
      throw new Error(threadResult.error?.message || 'Thread not found');
    }
    const messagesResult = await this.messages.getByThread(context, threadId);
    return {
      ...threadResult.data,
      messages: messagesResult.success ? messagesResult.data.data : [],
    };
  }

  async searchEmails(
    context: SecurityContext,
    query: string,
    filters?: { accountId?: string; direction?: EmailDirection }
  ): Promise<EmailMessage[]> {
    if (!this.isEnabled()) return [];
    const result = await this.messages.search(context, query, filters);
    if (!result.success || !result.data) return [];
    return result.data.data;
  }

  // ============================================
  // Templates
  // ============================================

  async createTemplate(
    context: SecurityContext,
    template: Omit<EmailTemplate, 'id' | 'createdAt'>
  ): Promise<EmailTemplate> {
    this.assertEnabled();
    // Map category to EmailTemplateType
    const categoryToType: Record<string, 'follow_up' | 'marketing' | 'custom'> = {
      outreach: 'marketing',
      followup: 'follow_up',
      nurture: 'marketing',
      transactional: 'custom',
    };
    // Convert email-integration EmailTemplate to email.ts EmailTemplate format
    const repoTemplate = {
      ...template,
      type: categoryToType[template.category] || 'custom',
      textBody: template.bodyText || '',
    };
    const result = await this.templates.create(context, repoTemplate);
    if (!result.success || !result.data) {
      throw new Error(result.error?.message || 'Failed to create template');
    }
    return result.data as EmailTemplate;
  }

  async getTemplates(context: SecurityContext): Promise<EmailTemplate[]> {
    if (!this.isEnabled()) return [];
    const result = await this.templates.getActiveTemplates(context);
    if (!result.success || !result.data) return [];
    return result.data.data as EmailTemplate[];
  }

  async deleteTemplate(context: SecurityContext, templateId: string): Promise<void> {
    this.assertEnabled();
    await this.templates.deactivate(context, templateId);
  }

  // ============================================
  // Utilities
  // ============================================

  private applyMerge(template: string, data: Record<string, string>): string {
    return Object.entries(data || {}).reduce((acc, [key, value]) => {
      const pattern = new RegExp(`{{\\s*${key}\\s*}}`, 'gi');
      return acc.replace(pattern, value ?? '');
    }, template);
  }

  private async runSync(
    context: SecurityContext,
    accountId: string,
    path: string,
    folder: 'inbox' | 'sent'
  ): Promise<SyncResult> {
    this.assertEnabled();
    const account = await this.getAccountOrThrow(context, accountId);

    if (!account.syncEnabled) {
      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: ['Sync disabled for this account'],
        cursor: account.syncCursor,
      };
    }

    const limit = await this.rateLimit.checkLimit('integration_sync', context.userId, context.businessId);
    if (!limit.allowed) {
      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: [limit.message || 'Integration sync rate limit exceeded'],
        cursor: account.syncCursor,
      };
    }

    await this.accounts.updateSyncStatus(context, accountId, 'syncing');

    try {
      const syncResult = await this.callEmailFunction<SyncResult>(context, path, {
        accountId,
        businessId: context.businessId,
        cursor: account.syncCursor,
        provider: account.provider,
        folder,
      });

      await this.accounts.updateSyncStatus(
        context,
        accountId,
        syncResult.success ? 'synced' : 'error',
        syncResult.cursor || account.syncCursor
      );
      await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);

      if (syncResult.success) {
        await this.logAudit(context, {
          action: 'integration',
          entityType: 'integration',
          entityId: accountId,
          metadata: { provider: account.provider, operation: 'sync', folder },
        });
      }

      return {
        success: syncResult.success,
        created: syncResult.created,
        updated: syncResult.updated,
        skipped: syncResult.skipped,
        errors: syncResult.errors,
        cursor: syncResult.cursor || account.syncCursor,
      };
    } catch (error) {
      await this.accounts.updateSyncStatus(context, accountId, 'error', account.syncCursor);
      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: [error instanceof Error ? error.message : 'Failed to sync email'],
        cursor: account.syncCursor,
      };
    }
  }

  private assertEnabled(): void {
    if (!this.isEnabled()) {
      throw new Error('Messaging integration is disabled');
    }
  }

  private isEnabled(): boolean {
    const flags = getFeatureFlags();
    return Boolean(flags.enableEmailIntegration);
  }

  isConfigured(): boolean {
    return Boolean(this.resolveFunctionsBaseUrl());
  }

  private async getAccountOrThrow(context: SecurityContext, accountId: string): Promise<EmailAccount> {
    const accountResult = await this.accounts.getById(context, accountId);
    if (!accountResult.success || !accountResult.data) {
      throw new Error(accountResult.error?.message || 'Inbox account not found');
    }
    return accountResult.data;
  }

  private async callEmailFunction<T>(
    context: SecurityContext,
    path: string,
    payload: unknown
  ): Promise<T> {
    const functionsBaseUrl = this.resolveFunctionsBaseUrl();
    if (!functionsBaseUrl) {
      throw new Error('Cloud Functions base URL is not configured for messaging');
    }

    const auth = getAuth();
    const user = auth.currentUser;
    if (!user) {
      throw new Error('User must be authenticated to call messaging functions');
    }

    const token = await user.getIdToken();
    const response = await fetch(`${functionsBaseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        'X-Business-Id': context.businessId,
      },
      body: JSON.stringify(payload),
    });

    const contentType = response.headers.get('content-type') || '';
    const data = contentType.includes('application/json') ? await response.json() : await response.text();

    if (!response.ok) {
      const message = typeof data === 'string' ? data : data?.error || 'Email function request failed';
      throw new Error(message);
    }

    return data as T;
  }

  private resolveFunctionsBaseUrl(): string {
    return this.config.functionsBaseUrl || getFunctionsBaseUrl();
  }

  private mapAttachments(attachments: File[] | undefined, messageId: string): EmailAttachment[] {
    if (!attachments?.length) return [];
    return attachments.map((file, index) => ({
      id: `${messageId}-att-${index}`,
      filename: file.name,
      mimeType: file.type,
      size: file.size,
    }));
  }

  private getCandidateEmails(message: EmailMessage): string[] {
    const emails = new Set<string>();
    if (message.direction === 'inbound') {
      emails.add(normalizeEmail(message.fromEmail));
    } else {
      message.toEmails.forEach((email) => emails.add(normalizeEmail(email)));
      (message.ccEmails || []).forEach((email) => emails.add(normalizeEmail(email)));
      (message.bccEmails || []).forEach((email) => emails.add(normalizeEmail(email)));
    }
    return Array.from(emails).filter(Boolean);
  }

  private async findAssociationByEmail(
    context: SecurityContext,
    email: string,
    cache: Map<string, AssociationTarget | null>
  ): Promise<AssociationTarget | null> {
    const normalized = normalizeEmail(email);
    if (!normalized) return null;

    if (cache.has(normalized)) {
      return cache.get(normalized) || null;
    }

    const leadResult = await this.leads.getAll(context, {
      where: [{ field: 'email', operator: '==', value: normalized }],
      limit: 1,
    });
    if (leadResult.success && leadResult.data.data.length > 0) {
      const match = leadResult.data.data[0];
      const association: AssociationTarget = { type: 'lead', id: (match as any).id ?? match.id };
      cache.set(normalized, association);
      return association;
    }

    const contactResult = await this.contacts.getAll(context, {
      where: [{ field: 'email', operator: '==', value: normalized }],
      limit: 1,
    });
    if (contactResult.success && contactResult.data.data.length > 0) {
      const match = contactResult.data.data[0];
      const association: AssociationTarget = { type: 'client', id: (match as any).id ?? match.id };
      cache.set(normalized, association);
      return association;
    }

    cache.set(normalized, null);
    return null;
  }

  private async logAudit(context: SecurityContext, options: LogActionOptions): Promise<void> {
    const result = await this.audit.logAction(context, options);
    void result;
  }
}

let emailIntegrationService: EmailIntegrationService | null = null;

export function getEmailIntegrationService(): EmailIntegrationService {
  if (!emailIntegrationService) {
    emailIntegrationService = new EmailIntegrationService();
  }
  return emailIntegrationService;
}
