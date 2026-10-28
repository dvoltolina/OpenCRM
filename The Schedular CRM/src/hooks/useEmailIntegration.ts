/**
 * useEmailIntegration Hook
 * UI-friendly wrapper around EmailIntegrationService for accounts, messages, templates, and tracking-aware sends.
 *
 * Security:
 * - All operations require SecurityContext (business/user scoped).
 * - Feature flag + Functions base URL guard to avoid accidental network calls when disabled.
 * - No PHI is logged or exposed through error messages.
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import type {
  EmailAccount,
  EmailDirection,
  EmailMessage,
  EmailProvider,
  EmailTemplate,
  EmailThread,
} from '../types/email-integration';
import {
  getEmailIntegrationService,
  type SendEmailResult,
  type SyncResult,
} from '../services/email-integration-service';
import { hasFunctionsBaseUrl } from '../services/functions-base-url';
import { createSecurityContext } from '../lib/security-context';
import { getFeatureFlags } from '../config/features';

interface UseEmailIntegrationOptions {
  entityType?: 'lead' | 'client' | 'deal';
  entityId?: string;
  loadEmails?: boolean;
  loadAccounts?: boolean;
  loadTemplates?: boolean;
  defaultAccountId?: string;
}

interface CreateEmailTemplateInput {
  name: string;
  subject: string;
  bodyHtml: string;
  bodyText?: string;
  availableMergeFields?: string[];
  category?: EmailTemplate['category'];
}

export interface UseEmailIntegrationResult {
  enabled: boolean;
  configured: boolean;
  contextReady: boolean;
  accounts: EmailAccount[];
  accountsLoading: boolean;
  accountsError: string | null;
  selectedAccountId?: string;
  setSelectedAccountId: (id: string | undefined) => void;
  refreshAccounts: () => Promise<void>;
  connectAccount: (
    provider: EmailProvider,
    authCode: string
  ) => Promise<EmailAccount | null>;
  disconnectAccount: (accountId: string) => Promise<void>;
  syncAccount: (accountId: string, folder?: 'inbox' | 'sent') => Promise<SyncResult | null>;
  refreshAccountTokens: (accountId: string) => Promise<void>;

  emails: EmailMessage[];
  emailsLoading: boolean;
  emailError: string | null;
  refreshEmails: () => Promise<void>;
  searchEmails: (query: string, filters?: { accountId?: string; direction?: EmailDirection }) => Promise<EmailMessage[]>;

  thread: (EmailThread & { messages: EmailMessage[] }) | null;
  threadLoading: boolean;
  threadError: string | null;
  loadThread: (threadId: string) => Promise<(EmailThread & { messages: EmailMessage[] }) | null>;

  templates: EmailTemplate[];
  templatesLoading: boolean;
  templateError: string | null;
  saveTemplate: (input: CreateEmailTemplateInput) => Promise<EmailTemplate | null>;
  deleteTemplate: (templateId: string) => Promise<void>;

  sendEmail: (options: {
    accountId?: string;
    to: string[];
    cc?: string[];
    bcc?: string[];
    subject: string;
    bodyHtml: string;
    bodyText?: string;
    trackOpens?: boolean;
    trackClicks?: boolean;
    associatedEntity?: { type: string; id: string };
  }) => Promise<SendEmailResult>;
  sendTemplatedEmail: (options: {
    accountId?: string;
    templateId: string;
    to: string[];
    mergeData?: Record<string, string>;
    associatedEntity?: { type: string; id: string };
  }) => Promise<SendEmailResult>;
  isSending: boolean;

  associateEmail: (
    messageId: string,
    entityType: string,
    entityId: string
  ) => Promise<void>;
  autoAssociate: (accountId: string) => Promise<number>;
}

const sanitizeError = (error: unknown, fallback: string): string => {
  if (error instanceof Error && error.message) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return fallback;
};

const stripHtml = (html?: string): string =>
  (html || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

export function useEmailIntegration(options: UseEmailIntegrationOptions = {}): UseEmailIntegrationResult {
  const {
    entityType,
    entityId,
    loadEmails = Boolean(entityType && entityId),
    loadAccounts = true,
    loadTemplates = true,
    defaultAccountId,
  } = options;

  const { crmUser } = useAuth();
  const service = useMemo(() => getEmailIntegrationService(), []);
  const enabled = useMemo(() => getFeatureFlags().enableEmailIntegration, []);
  const configured = useMemo(() => hasFunctionsBaseUrl() || service.isConfigured(), [service]);

  const context = useMemo(() => {
    if (!crmUser) return null;
    try {
      return createSecurityContext(crmUser);
    } catch {
      return null;
    }
  }, [crmUser]);

  const contextReady = Boolean(enabled && context);

  const [accounts, setAccounts] = useState<EmailAccount[]>([]);
  const [selectedAccountId, setSelectedAccountId] = useState<string | undefined>(defaultAccountId);
  const [accountsLoading, setAccountsLoading] = useState(false);
  const [accountsError, setAccountsError] = useState<string | null>(null);

  const [emails, setEmails] = useState<EmailMessage[]>([]);
  const [emailsLoading, setEmailsLoading] = useState(false);
  const [emailError, setEmailError] = useState<string | null>(null);

  const [thread, setThread] = useState<(EmailThread & { messages: EmailMessage[] }) | null>(null);
  const [threadLoading, setThreadLoading] = useState(false);
  const [threadError, setThreadError] = useState<string | null>(null);

  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [templatesLoading, setTemplatesLoading] = useState(false);
  const [templateError, setTemplateError] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);

  const ensureReady = useCallback((requireConfig = true) => {
    if (!enabled) {
      throw new Error('Messaging integration is disabled');
    }
    if (requireConfig && !configured) {
      throw new Error('Messaging integration is not configured');
    }
    if (!context) {
      throw new Error('User context unavailable');
    }
    return context;
  }, [configured, context, enabled]);

  const filterByEntity = useCallback(
    (messages: EmailMessage[]) => {
      if (entityType && entityId) {
        return messages.filter(
          (msg) => msg.associatedEntityType === entityType && msg.associatedEntityId === entityId
        );
      }
      return messages;
    },
    [entityType, entityId]
  );

  const refreshAccounts = useCallback(async () => {
    if (!loadAccounts || !contextReady) return;

    setAccountsLoading(true);
    setAccountsError(null);

    try {
      const ctx = ensureReady(false);
      const data = await service.getAccounts(ctx);
      setAccounts(data);

      if (!selectedAccountId && data.length > 0) {
        setSelectedAccountId(data[0].id);
      }
    } catch (err) {
      setAccountsError(sanitizeError(err, 'Unable to load email accounts'));
    } finally {
      setAccountsLoading(false);
    }
  }, [contextReady, ensureReady, loadAccounts, selectedAccountId, service]);

  const refreshTemplates = useCallback(async () => {
    if (!loadTemplates || !contextReady) return;

    setTemplatesLoading(true);
    setTemplateError(null);

    try {
      const ctx = ensureReady(false);
      const data = await service.getTemplates(ctx);
      setTemplates(data);
    } catch (err) {
      setTemplateError(sanitizeError(err, 'Unable to load email templates'));
    } finally {
      setTemplatesLoading(false);
    }
  }, [contextReady, ensureReady, loadTemplates, service]);

  const refreshEmails = useCallback(async () => {
    if (!loadEmails || !contextReady || !entityType || !entityId) return;

    setEmailsLoading(true);
    setEmailError(null);
    try {
      const ctx = ensureReady(false);
      const data = await service.getEmailsForEntity(ctx, entityType, entityId);
      setEmails(filterByEntity(data));
    } catch (err) {
      setEmailError(sanitizeError(err, 'Unable to load emails'));
    } finally {
      setEmailsLoading(false);
    }
  }, [contextReady, ensureReady, loadEmails, entityType, entityId, filterByEntity, service]);

  const searchEmails = useCallback(
    async (query: string, filters?: { accountId?: string; direction?: EmailDirection }) => {
      if (!contextReady) return [];
      try {
        const ctx = ensureReady(false);
        let results: EmailMessage[] = [];
        if (query) {
          results = await service.searchEmails(ctx, query, filters);
        } else if (entityType && entityId) {
          results = await service.getEmailsForEntity(ctx, entityType, entityId);
        } else {
          setEmails([]);
          return [];
        }
        const scopedResults = filterByEntity(results);
        setEmails(scopedResults);
        return scopedResults;
      } catch (err) {
        setEmailError(sanitizeError(err, 'Unable to search emails'));
        return [];
      }
    },
    [contextReady, ensureReady, service, filterByEntity, entityType, entityId]
  );

  const loadThread = useCallback(
    async (threadId: string) => {
      if (!contextReady || !threadId) return null;
      setThreadLoading(true);
      setThreadError(null);
      try {
        const ctx = ensureReady(false);
        const result = await service.getThread(ctx, threadId);
        setThread(result);
        return result;
      } catch (err) {
        const message = sanitizeError(err, 'Unable to load thread');
        setThreadError(message);
        return null;
      } finally {
        setThreadLoading(false);
      }
    },
    [contextReady, ensureReady, service]
  );

  const connectAccount = useCallback(
    async (provider: EmailProvider, authCode: string) => {
      if (!authCode) {
        throw new Error('Authorization code required to connect account');
      }
      const ctx = ensureReady();
      const account = await service.connectAccount(ctx, provider, authCode);
      await refreshAccounts();
      return account;
    },
    [ensureReady, refreshAccounts, service]
  );

  const disconnectAccount = useCallback(
    async (accountId: string) => {
      const ctx = ensureReady();
      await service.disconnectAccount(ctx, accountId);
      await refreshAccounts();
    },
    [ensureReady, refreshAccounts, service]
  );

  const refreshAccountTokens = useCallback(
    async (accountId: string) => {
      const ctx = ensureReady();
      await service.refreshTokens(ctx, accountId);
      await refreshAccounts();
    },
    [ensureReady, refreshAccounts, service]
  );

  const syncAccount = useCallback(
    async (accountId: string, folder: 'inbox' | 'sent' = 'inbox') => {
      const ctx = ensureReady();
      const result = folder === 'sent'
        ? await service.syncSentFolder(ctx, accountId)
        : await service.syncInbox(ctx, accountId);
      await refreshEmails();
      return result;
    },
    [ensureReady, refreshEmails, service]
  );

  const sendEmail = useCallback(
    async (options: {
      accountId?: string;
      to: string[];
      cc?: string[];
      bcc?: string[];
      subject: string;
      bodyHtml: string;
      bodyText?: string;
      trackOpens?: boolean;
      trackClicks?: boolean;
      associatedEntity?: { type: string; id: string };
    }): Promise<SendEmailResult> => {
      try {
        const ctx = ensureReady();
        const accountId = options.accountId || selectedAccountId || accounts[0]?.id;
        if (!accountId) {
          return { success: false, error: 'No connected email account' };
        }

        setIsSending(true);
        const result = await service.sendEmail(ctx, {
          ...options,
          accountId,
          trackOpens: options.trackOpens ?? true,
          trackClicks: options.trackClicks ?? true,
        });

        if (result.success) {
          await refreshEmails();
        }
        return result;
      } catch (err) {
        return { success: false, error: sanitizeError(err, 'Unable to send email') };
      } finally {
        setIsSending(false);
      }
    },
    [accounts, ensureReady, refreshEmails, selectedAccountId, service]
  );

  const sendTemplatedEmail = useCallback(
    async (options: {
      accountId?: string;
      templateId: string;
      to: string[];
      mergeData?: Record<string, string>;
      associatedEntity?: { type: string; id: string };
    }): Promise<SendEmailResult> => {
      try {
        const ctx = ensureReady();
        const accountId = options.accountId || selectedAccountId || accounts[0]?.id;
        if (!accountId) {
          return { success: false, error: 'No connected email account' };
        }
        setIsSending(true);
        const result = await service.sendTemplatedEmail(ctx, {
          ...options,
          accountId,
          mergeData: options.mergeData || {},
        });
        if (result.success) {
          await refreshEmails();
        }
        return result;
      } catch (err) {
        return { success: false, error: sanitizeError(err, 'Unable to send templated email') };
      } finally {
        setIsSending(false);
      }
    },
    [accounts, ensureReady, refreshEmails, selectedAccountId, service]
  );

  const saveTemplate = useCallback(
    async (input: CreateEmailTemplateInput) => {
      const ctx = ensureReady(false);
      setTemplatesLoading(true);
      setTemplateError(null);

      try {
        const templatePayload: Omit<EmailTemplate, 'id' | 'createdAt'> = {
          businessId: ctx.businessId,
          name: input.name,
          subject: input.subject,
          bodyHtml: input.bodyHtml,
          bodyText: input.bodyText || stripHtml(input.bodyHtml),
          availableMergeFields: input.availableMergeFields || [],
          category: input.category || 'outreach',
          isActive: true,
          usageCount: 0,
          createdById: ctx.userId,
        };

        const template = await service.createTemplate(ctx, templatePayload);

        setTemplates((prev) => [template, ...prev]);
        return template;
      } catch (err) {
        const message = sanitizeError(err, 'Unable to save template');
        setTemplateError(message);
        return null;
      } finally {
        setTemplatesLoading(false);
      }
    },
    [ensureReady, service]
  );

  const deleteTemplate = useCallback(
    async (templateId: string) => {
      const ctx = ensureReady(false);
      try {
        await service.deleteTemplate(ctx, templateId);
        setTemplates((prev) => prev.filter((tpl) => tpl.id !== templateId));
      } catch (err) {
        setTemplateError(sanitizeError(err, 'Unable to delete template'));
      }
    },
    [ensureReady, service]
  );

  const associateEmail = useCallback(
    async (messageId: string, targetEntityType: string, targetEntityId: string) => {
      const ctx = ensureReady(false);
      await service.associateEmail(ctx, messageId, targetEntityType, targetEntityId);
      await refreshEmails();
    },
    [ensureReady, refreshEmails, service]
  );

  const autoAssociate = useCallback(
    async (accountId: string) => {
      const ctx = ensureReady(false);
      const result = await service.autoAssociateEmails(ctx, accountId);
      await refreshEmails();
      return result;
    },
    [ensureReady, refreshEmails, service]
  );

  useEffect(() => {
    if (contextReady) {
      refreshAccounts();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextReady, loadAccounts]);

  useEffect(() => {
    if (contextReady) {
      refreshTemplates();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextReady, loadTemplates]);

  useEffect(() => {
    if (contextReady && loadEmails && entityType && entityId) {
      refreshEmails();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextReady, loadEmails, entityType, entityId]);

  return {
    enabled,
    configured,
    contextReady,
    accounts,
    accountsLoading,
    accountsError,
    selectedAccountId,
    setSelectedAccountId,
    refreshAccounts,
    connectAccount,
    disconnectAccount,
    syncAccount,
    refreshAccountTokens,

    emails,
    emailsLoading,
    emailError,
    refreshEmails,
    searchEmails,

    thread,
    threadLoading,
    threadError,
    loadThread,

    templates,
    templatesLoading,
    templateError,
    saveTemplate,
    deleteTemplate,

    sendEmail,
    sendTemplatedEmail,
    isSending,

    associateEmail,
    autoAssociate,
  };
}
