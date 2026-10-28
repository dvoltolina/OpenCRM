/**
 * Notifications Types
 * Comprehensive notification system types for in-app, email, and push notifications
 *
 * HIPAA Compliance Notes:
 * - NO PHI in notification titles/bodies - reference entities by ID only
 * - Push notification content kept minimal - link back to app for details
 * - Email digests sent to authenticated email only, no PHI content
 */

// ============================================
// Core Notification Types
// ============================================

/**
 * Types of notifications the system can generate
 */
export type NotificationType =
  | 'task_due'
  | 'task_assigned'
  | 'task_completed'
  | 'deal_stage_changed'
  | 'deal_won'
  | 'deal_lost'
  | 'lead_assigned'
  | 'lead_converted'
  | 'sequence_reply'
  | 'sequence_completed'
  | 'email_opened'
  | 'email_clicked'
  | 'meeting_scheduled'
  | 'mention'
  | 'comment'
  | 'goal_achieved'
  | 'goal_at_risk'
  | 'system_announcement';

/**
 * Notification priority levels
 */
export type NotificationPriority = 'low' | 'normal' | 'high' | 'urgent';

/**
 * Delivery channels for notifications
 */
export type NotificationChannel = 'in_app' | 'email' | 'push' | 'sms';

/**
 * Digest email frequency settings
 */
export type DigestFrequency = 'realtime' | 'hourly' | 'daily' | 'weekly' | 'off';

/**
 * Entity types that can be associated with notifications
 */
export type NotificationEntityType =
  | 'lead'
  | 'client'
  | 'deal'
  | 'task'
  | 'sequence'
  | 'email'
  | 'goal'
  | 'activity';

// ============================================
// Main Notification Interface
// ============================================

/**
 * Core notification entity
 * HIPAA: No PHI fields - titles/bodies reference entities, not health data
 */
export interface Notification {
  id: string;
  businessId: string;
  userId: string; // Recipient

  // Type and content
  type: NotificationType;
  priority: NotificationPriority;
  title: string;
  body: string;
  iconType?: string; // For UI icon selection (e.g., 'task', 'deal', 'email')

  // Related entity
  entityType?: NotificationEntityType;
  entityId?: string;
  actionUrl?: string; // Deep link into app (e.g., '/deals/abc123')

  // Actor (who triggered the notification)
  actorId?: string;
  actorName?: string;

  // Status
  isRead: boolean;
  readAt?: Date;
  isArchived: boolean;
  archivedAt?: Date;

  // Delivery tracking
  channels: NotificationChannel[];
  deliveredVia: NotificationChannel[];
  emailSentAt?: Date;
  pushSentAt?: Date;

  // Timestamps
  createdAt: Date;
  expiresAt?: Date; // For auto-cleanup
}

// ============================================
// Notification Preferences
// ============================================

/**
 * Per-notification-type settings
 */
export interface TypeNotificationSetting {
  enabled: boolean;
  channels: NotificationChannel[];
  digestOnly?: boolean; // Don't send immediately, include in digest
}

/**
 * User notification preferences
 */
export interface NotificationPreferences {
  id: string;
  businessId: string;
  userId: string;

  // Global settings
  emailEnabled: boolean;
  pushEnabled: boolean;
  quietHoursStart?: string; // HH:MM format
  quietHoursEnd?: string; // HH:MM format
  timezone: string;

  // Per-type settings
  typeSettings: Record<NotificationType, TypeNotificationSetting>;

  // Digest settings
  emailDigestFrequency: DigestFrequency;
  emailDigestTime?: string; // HH:MM for daily/weekly digest delivery

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

/**
 * Supported updates for persisted notification preferences.
 */
export interface NotificationPreferencesUpdate {
  emailEnabled?: boolean;
  pushEnabled?: boolean;
  quietHoursStart?: string;
  quietHoursEnd?: string;
  timezone?: string;
  typeSettings?: Partial<Record<NotificationType, TypeNotificationSetting>>;
  emailDigestFrequency?: DigestFrequency;
  emailDigestTime?: string;
}

// ============================================
// Push Subscriptions
// ============================================

/**
 * Web Push subscription keys
 */
export interface PushSubscriptionKeys {
  p256dh: string;
  auth: string;
}

/**
 * Push notification subscription for a user's device
 */
export interface PushSubscription {
  id: string;
  businessId: string;
  userId: string;

  // Web Push subscription
  endpoint: string;
  keys: PushSubscriptionKeys;

  // Device info
  userAgent: string;
  deviceName?: string;

  // Status
  isActive: boolean;
  lastUsedAt?: Date;
  failedAttempts: number;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Notification Batches (Digests)
// ============================================

/**
 * Batch types for grouped notifications
 */
export type NotificationBatchType = 'digest';

/**
 * Notification batch status
 */
export type NotificationBatchStatus = 'pending' | 'sent' | 'failed';

/**
 * Notification batch for digest emails
 */
export interface NotificationBatch {
  id: string;
  businessId: string;
  userId: string;

  // Batch info
  batchType: NotificationBatchType;
  frequency: DigestFrequency;
  periodStart: Date;
  periodEnd: Date;

  // Content
  notificationIds: string[];
  notificationCount: number;

  // Delivery
  sentAt?: Date;
  status: NotificationBatchStatus;

  // Timestamps
  createdAt: Date;
}

// ============================================
// Service Input/Output Types
// ============================================

/**
 * Options for creating a notification
 */
export interface CreateNotificationOptions {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  priority?: NotificationPriority;
  entity?: {
    type: NotificationEntityType;
    id: string;
  };
  actionUrl?: string;
  actorId?: string;
  actorName?: string;
  iconType?: string;
  expiresAt?: Date;
}

/**
 * Options for bulk notification creation
 */
export interface BulkNotificationOptions
  extends Omit<CreateNotificationOptions, 'userId'> {
  userIds: string[];
}

/**
 * Options for fetching notifications
 * Note: Uses cursor-based pagination via lastDocId for Firestore compatibility
 */
export interface GetNotificationsOptions {
  includeArchived?: boolean;
  limit?: number;
  /** @deprecated Use lastDocId for cursor-based pagination instead */
  offset?: number;
  /** Document ID of the last notification from previous page (cursor-based pagination) */
  lastDocId?: string;
  types?: NotificationType[];
  unreadOnly?: boolean;
}

/**
 * Paginated notification response
 */
export interface NotificationListResponse {
  notifications: Notification[];
  total: number;
  hasMore: boolean;
  /** ID of the last notification for cursor-based pagination */
  lastDocId?: string;
}

// ============================================
// Push Notification Payload
// ============================================

/**
 * Payload for push notifications
 */
export interface PushNotificationPayload {
  title: string;
  body: string;
  icon?: string;
  badge?: string;
  data?: {
    url?: string;
    notificationId?: string;
    type?: NotificationType;
  };
}

// ============================================
// Email Digest Types
// ============================================

/**
 * Grouped notifications for digest email
 */
export interface DigestNotificationGroup {
  type: NotificationType;
  notifications: Notification[];
  count: number;
}

/**
 * Email digest content
 */
export interface DigestEmailContent {
  subject: string;
  html: string;
  groups: DigestNotificationGroup[];
  totalCount: number;
  periodStart: Date;
  periodEnd: Date;
}

// ============================================
// Default Preferences
// ============================================

/**
 * Get default notification preferences for a new user
 */
export function getDefaultNotificationPreferences(
  userId: string,
  businessId: string,
  timezone = 'America/New_York'
): Omit<NotificationPreferences, 'id' | 'createdAt'> {
  const typeSettings: Record<NotificationType, TypeNotificationSetting> = {
    // High priority - immediate notifications
    task_due: { enabled: true, channels: ['in_app', 'push'], digestOnly: false },
    task_assigned: { enabled: true, channels: ['in_app', 'email'], digestOnly: false },
    task_completed: { enabled: true, channels: ['in_app'], digestOnly: true },

    // Deal notifications
    deal_stage_changed: { enabled: true, channels: ['in_app'], digestOnly: true },
    deal_won: { enabled: true, channels: ['in_app', 'push'], digestOnly: false },
    deal_lost: { enabled: true, channels: ['in_app'], digestOnly: false },

    // Lead notifications
    lead_assigned: { enabled: true, channels: ['in_app', 'email'], digestOnly: false },
    lead_converted: { enabled: true, channels: ['in_app'], digestOnly: true },

    // Sequence notifications
    sequence_reply: { enabled: true, channels: ['in_app', 'push'], digestOnly: false },
    sequence_completed: { enabled: true, channels: ['in_app'], digestOnly: true },

    // Email tracking
    email_opened: { enabled: true, channels: ['in_app'], digestOnly: true },
    email_clicked: { enabled: true, channels: ['in_app'], digestOnly: true },

    // Meetings
    meeting_scheduled: { enabled: true, channels: ['in_app', 'email'], digestOnly: false },

    // Collaboration
    mention: { enabled: true, channels: ['in_app', 'push'], digestOnly: false },
    comment: { enabled: true, channels: ['in_app'], digestOnly: true },

    // Goals
    goal_achieved: { enabled: true, channels: ['in_app', 'push'], digestOnly: false },
    goal_at_risk: { enabled: true, channels: ['in_app', 'email'], digestOnly: false },

    // System
    system_announcement: { enabled: true, channels: ['in_app', 'email'], digestOnly: false },
  };

  return {
    businessId,
    userId,
    emailEnabled: true,
    pushEnabled: false, // Requires explicit opt-in
    quietHoursStart: '22:00',
    quietHoursEnd: '08:00',
    timezone,
    typeSettings,
    emailDigestFrequency: 'daily',
    emailDigestTime: '09:00',
  };
}

// ============================================
// Validation Helpers
// ============================================

/**
 * Valid notification types for validation
 */
export const VALID_NOTIFICATION_TYPES: NotificationType[] = [
  'task_due',
  'task_assigned',
  'task_completed',
  'deal_stage_changed',
  'deal_won',
  'deal_lost',
  'lead_assigned',
  'lead_converted',
  'sequence_reply',
  'sequence_completed',
  'email_opened',
  'email_clicked',
  'meeting_scheduled',
  'mention',
  'comment',
  'goal_achieved',
  'goal_at_risk',
  'system_announcement',
];

/**
 * Valid notification priorities
 */
export const VALID_PRIORITIES: NotificationPriority[] = [
  'low',
  'normal',
  'high',
  'urgent',
];

/**
 * Valid notification channels
 */
export const VALID_CHANNELS: NotificationChannel[] = [
  'in_app',
  'email',
  'push',
  'sms',
];

/**
 * Valid digest frequencies
 */
export const VALID_DIGEST_FREQUENCIES: DigestFrequency[] = [
  'realtime',
  'hourly',
  'daily',
  'weekly',
  'off',
];

/**
 * Validate notification type
 */
export function isValidNotificationType(type: string): type is NotificationType {
  return VALID_NOTIFICATION_TYPES.includes(type as NotificationType);
}

/**
 * Validate notification priority
 */
export function isValidPriority(priority: string): priority is NotificationPriority {
  return VALID_PRIORITIES.includes(priority as NotificationPriority);
}

/**
 * Get icon type for notification type
 */
export function getIconTypeForNotification(type: NotificationType): string {
  const iconMap: Record<NotificationType, string> = {
    task_due: 'clock',
    task_assigned: 'clipboard',
    task_completed: 'check-circle',
    deal_stage_changed: 'trending-up',
    deal_won: 'trophy',
    deal_lost: 'x-circle',
    lead_assigned: 'user-plus',
    lead_converted: 'user-check',
    sequence_reply: 'message-circle',
    sequence_completed: 'check-square',
    email_opened: 'eye',
    email_clicked: 'mouse-pointer',
    meeting_scheduled: 'calendar',
    mention: 'at-sign',
    comment: 'message-square',
    goal_achieved: 'award',
    goal_at_risk: 'alert-triangle',
    system_announcement: 'bell',
  };

  return iconMap[type] || 'bell';
}
