import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  buildAccountId,
  buildSyncedMessageId,
  buildThreadId,
  decryptToken,
  EmailAccountDoc,
  EmailFolder,
  EmailProvider,
  encryptToken,
  hashValue,
  parseSyncCursor,
  SyncResult,
  TokenPair,
  updateSyncCursor,
  UserContext,
  writeAuditLog,
} from './email-security';

export async function loadAccount(businessId: string, accountId: string) {
  const ref = admin.firestore().doc(`businesses/${businessId}/email_accounts/${accountId}`);
  const snap = await ref.get();
  if (!snap.exists) return null;
  return { ref, id: snap.id, data: snap.data() as EmailAccountDoc };
}

export function assertAccountAccess(user: UserContext, account: EmailAccountDoc) {
  const privileged = user.role === 'owner' || user.role === 'admin';
  if (!privileged && account.userId !== user.uid) {
    throw new functions.https.HttpsError('permission-denied', 'Account access denied');
  }
}

function syntheticEmail(provider: EmailProvider, user: UserContext): string {
  return (user.email || `${user.uid}@${provider}.local`).trim().toLowerCase();
}

export async function exchangeAuthCode(
  provider: EmailProvider,
  authCode: string,
  user: UserContext
): Promise<TokenPair> {
  const suffix = hashValue(`${provider}:${authCode}:${user.uid}`).slice(0, 12);
  return {
    accessToken: `stub-${provider}-access-${suffix}`,
    refreshToken: `stub-${provider}-refresh-${suffix}`,
    expiresAt: new Date(Date.now() + 55 * 60 * 1000),
    email: syntheticEmail(provider, user),
    displayName: user.userName,
  };
}

export async function refreshProviderTokens(
  provider: EmailProvider,
  encryptedRefreshToken: string,
  user: UserContext
) {
  const decrypted = decryptToken(encryptedRefreshToken);
  return exchangeAuthCode(provider, `${decrypted}:${Date.now()}`, user);
}

export async function persistAccount(
  user: UserContext,
  provider: EmailProvider,
  tokens: TokenPair,
  accountId?: string
) {
  const db = admin.firestore();
  const resolvedAccountId = accountId || buildAccountId(user.uid, provider, tokens.email);
  const ref = db.doc(`businesses/${user.businessId}/email_accounts/${resolvedAccountId}`);
  const existing = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await ref.set(
    {
      businessId: user.businessId,
      userId: user.uid,
      provider,
      email: tokens.email,
      displayName: tokens.displayName || user.userName,
      accessToken: encryptToken(tokens.accessToken),
      refreshToken: encryptToken(tokens.refreshToken),
      tokenExpiresAt: tokens.expiresAt,
      syncStatus: 'syncing',
      syncEnabled: true,
      syncInbound: true,
      syncOutbound: true,
      autoAssociate: true,
      syncCursor: (existing.data() as EmailAccountDoc | undefined)?.syncCursor,
      createdAt: existing.exists ? existing.get('createdAt') : now,
      updatedAt: now,
    },
    { merge: true }
  );

  return resolvedAccountId;
}

async function upsertThread(
  businessId: string,
  accountId: string,
  providerThreadId: string,
  subject: string,
  participantEmails: string[],
  lastMessageAt: Date,
  lastMessageSnippet: string
) {
  const ref = admin
    .firestore()
    .doc(`businesses/${businessId}/email_threads/${buildThreadId(accountId, providerThreadId)}`);
  const existing = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const existingCount =
    typeof existing.get('messageCount') === 'number' ? (existing.get('messageCount') as number) : 0;

  await ref.set(
    {
      businessId,
      accountId,
      providerThreadId,
      subject,
      participantEmails,
      messageCount: existing.exists ? Math.max(existingCount, 1) : 1,
      lastMessageAt,
      lastMessageSnippet,
      createdAt: existing.exists ? existing.get('createdAt') : now,
      updatedAt: now,
    },
    { merge: true }
  );

  return ref.id;
}

async function upsertSyncedMessage(
  businessId: string,
  accountId: string,
  providerMessageId: string,
  threadId: string,
  payload: Record<string, unknown>
): Promise<'created' | 'updated'> {
  const ref = admin
    .firestore()
    .doc(`businesses/${businessId}/email_messages/${buildSyncedMessageId(accountId, providerMessageId)}`);
  const existing = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await ref.set(
    {
      businessId,
      accountId,
      providerMessageId,
      threadId,
      opens: 0,
      clicks: 0,
      createdAt: existing.exists ? existing.get('createdAt') : now,
      updatedAt: now,
      ...payload,
    },
    { merge: true }
  );

  return existing.exists ? 'updated' : 'created';
}

function buildStubMessages(account: EmailAccountDoc, folder: EmailFolder): Array<Record<string, unknown>> {
  const timestamp = new Date();
  const accountEmail = account.email.trim().toLowerCase();
  const counterpart = folder === 'inbox' ? 'client@example.test' : 'prospect@example.test';
  const subject = folder === 'inbox' ? 'Welcome to your synced inbox' : 'Follow-up sent from CRM';
  const snippet =
    folder === 'inbox'
      ? 'This is a metadata-only stub inbound message created by the email functions backend.'
      : 'This is a metadata-only stub outbound message created by the email functions backend.';

  return [
    {
      providerMessageId: `stub-${folder}-1`,
      providerThreadId: `stub-${folder}-thread-1`,
      fromEmail: folder === 'inbox' ? counterpart : accountEmail,
      fromName: folder === 'inbox' ? 'Demo Contact' : account.displayName || 'CRM User',
      toEmails: folder === 'inbox' ? [accountEmail] : [counterpart],
      ccEmails: [],
      bccEmails: [],
      subject,
      bodyText: undefined,
      bodyHtml: undefined,
      snippet,
      direction: folder === 'inbox' ? 'inbound' : 'outbound',
      sentAt: timestamp,
      receivedAt: folder === 'inbox' ? timestamp : undefined,
      attachments: [],
      hasAttachments: false,
      isRead: folder !== 'inbox',
      isStarred: false,
      labels: folder === 'inbox' ? ['synced'] : ['sent'],
    },
  ];
}

export async function syncFolder(
  businessId: string,
  accountId: string,
  folder: EmailFolder,
  actor: { userId: string; userName: string }
): Promise<SyncResult> {
  const accountRecord = await loadAccount(businessId, accountId);
  if (!accountRecord) {
    return { success: false, created: 0, updated: 0, skipped: 0, errors: ['Account not found'] };
  }

  const { ref, data: account } = accountRecord;
  if (!account.syncEnabled || account.syncStatus === 'disconnected') {
    return {
      success: false,
      created: 0,
      updated: 0,
      skipped: 1,
      cursor: account.syncCursor,
      errors: ['Account is disconnected or sync is disabled'],
    };
  }

  if ((folder === 'inbox' && !account.syncInbound) || (folder === 'sent' && !account.syncOutbound)) {
    return {
      success: true,
      created: 0,
      updated: 0,
      skipped: 1,
      cursor: account.syncCursor,
    };
  }

  const cursor = parseSyncCursor(account.syncCursor);
  const alreadySeeded = folder === 'inbox' ? cursor.inbox : cursor.sent;
  let created = 0;
  let updated = 0;

  if (!alreadySeeded) {
    const messages = buildStubMessages(account, folder);
    for (const message of messages) {
      const providerThreadId = String(message.providerThreadId);
      const threadId = await upsertThread(
        businessId,
        accountId,
        providerThreadId,
        String(message.subject),
        [String(message.fromEmail), ...((message.toEmails as string[]) || [])].filter(Boolean),
        message.sentAt as Date,
        String(message.snippet)
      );

      const status = await upsertSyncedMessage(
        businessId,
        accountId,
        String(message.providerMessageId),
        threadId,
        message
      );
      if (status === 'created') {
        created += 1;
      } else {
        updated += 1;
      }
    }
  }

  const nextCursor = updateSyncCursor(
    account.syncCursor,
    folder,
    alreadySeeded || `stub-${folder}-${Date.now()}`
  );
  await ref.set(
    {
      syncCursor: nextCursor,
      syncStatus: 'synced',
      lastSyncAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await writeAuditLog(businessId, actor.userId, actor.userName, 'integration', 'integration', accountId, {
    operation: 'sync',
    folder,
    created,
    updated,
  });

  functions.logger.info('email_sync_complete', { businessId, accountId, folder, created, updated });

  return {
    success: true,
    created,
    updated,
    skipped: alreadySeeded ? 1 : 0,
    cursor: nextCursor,
  };
}
