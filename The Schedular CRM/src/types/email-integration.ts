/**
 * Email Integration Types
 * OAuth-connected inbox sync, tracking, and templating definitions.
 *
 * HIPAA: No PHI in logs; tokens must be encrypted at rest; IPs hashed for tracking.
 */

export type EmailProvider = 'gmail' | 'outlook' | 'smtp';
export type EmailSyncStatus = 'syncing' | 'synced' | 'error' | 'disconnected';
export type EmailDirection = 'inbound' | 'outbound';

export interface EmailAccount {
  id: string;
  businessId: string;
  userId: string;

  // Provider info
  provider: EmailProvider;
  email: string;
  displayName?: string;

  // OAuth tokens (encrypted)
  accessToken: string; // Encrypted
  refreshToken: string; // Encrypted
  tokenExpiresAt: Date;

  // Sync state
  syncStatus: EmailSyncStatus;
  lastSyncAt?: Date;
  syncCursor?: string; // For incremental sync

  // Settings
  syncEnabled: boolean;
  syncInbound: boolean;
  syncOutbound: boolean;
  autoAssociate: boolean; // Auto-link emails to contacts

  createdAt: Date;
  updatedAt?: Date;
}

export interface EmailMessage {
  id: string;
  businessId: string;
  accountId: string;

  // Provider reference
  providerMessageId: string;
  threadId?: string;

  // Participants
  fromEmail: string;
  fromName?: string;
  toEmails: string[];
  ccEmails?: string[];
  bccEmails?: string[];

  // Content
  subject: string;
  bodyText?: string;
  bodyHtml?: string;
  snippet: string; // First 200 chars for preview

  // Metadata
  direction: EmailDirection;
  sentAt: Date;
  receivedAt?: Date;

  // Associations
  associatedEntityType?: 'lead' | 'client' | 'deal';
  associatedEntityId?: string;
  associatedByUserId?: string; // Who linked it

  // Tracking (outbound only)
  trackingId?: string;
  opens: number;
  clicks: number;
  firstOpenedAt?: Date;
  lastOpenedAt?: Date;

  // Attachments (metadata only, files in storage)
  attachments?: EmailAttachment[];
  hasAttachments: boolean;

  // Status
  isRead: boolean;
  isStarred: boolean;
  labels?: string[];

  createdAt: Date;
  updatedAt?: Date;
}

export interface EmailAttachment {
  id: string;
  filename: string;
  mimeType: string;
  size: number;
  storageUrl?: string; // If downloaded
}

export interface EmailThread {
  id: string;
  businessId: string;
  accountId: string;
  providerThreadId: string;

  subject: string;
  participantEmails: string[];
  messageCount: number;

  // Latest message info
  lastMessageAt: Date;
  lastMessageSnippet: string;

  // Association
  associatedEntityType?: 'lead' | 'client' | 'deal';
  associatedEntityId?: string;

  createdAt: Date;
  updatedAt?: Date;
}

export interface EmailTrackingEvent {
  id: string;
  businessId: string;
  messageId: string;
  trackingId: string;

  eventType: 'open' | 'click';
  linkUrl?: string; // For clicks

  // Context
  ipAddress?: string; // Hashed
  userAgent?: string;

  occurredAt: Date;
  createdAt: Date;
  updatedAt?: Date;
}

export interface EmailTemplate {
  id: string;
  businessId: string;
  name: string;
  subject: string;
  bodyHtml: string;
  bodyText?: string;

  // Merge fields
  availableMergeFields: string[];

  // Metadata
  category: 'outreach' | 'followup' | 'nurture' | 'transactional';
  isActive: boolean;
  usageCount: number;

  createdById: string;
  createdAt: Date;
  updatedAt?: Date;
}
