/**
 * Notification Service
 * Main service for creating, delivering, and managing notifications
 *
 * HIPAA Compliance:
 * - NO PHI in notification content - reference entities only
 * - All operations require SecurityContext for multi-tenant isolation
 * - Rate limiting to prevent notification spam
 * - Audit logging for notification access
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getNotificationRepository,
  type NotificationCreateData,
} from '../data/repositories/notification-repository';
import { getNotificationPreferencesRepository } from '../data/repositories/notification-preferences-repository';
import { getPushSubscriptionRepository } from '../data/repositories/push-subscription-repository';
import { checkAndRecordRateLimit } from './RateLimitService';
import { getFeatureFlags } from '../config/features';
import type {
  Notification,
  NotificationType,
  NotificationPriority,
  NotificationChannel,
  NotificationPreferences,
  NotificationPreferencesUpdate,
  PushSubscription,
  CreateNotificationOptions,
  GetNotificationsOptions,
  NotificationListResponse,
} from '../types/notifications';
import { getIconTypeForNotification as getIcon } from '../types/notifications';

// ============================================
// Types
// ============================================

export interface NotificationServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// Notification Service
// ============================================

export class NotificationService {
  private notificationRepo = getNotificationRepository();
  private preferencesRepo = getNotificationPreferencesRepository();
  private pushSubRepo = getPushSubscriptionRepository();

  // ============================================
  // Create Notifications
  // ============================================

  /**
   * Create and deliver a notification to a single user
   */
  async notify(
    context: SecurityContext,
    options: CreateNotificationOptions
  ): Promise<NotificationServiceResult<Notification>> {
    try {
      // Check rate limit
      const rateCheck = await checkAndRecordRateLimit('automation', context);
      if (rateCheck && rateCheck.allowed === false) {
        return {
          success: false,
          error: {
            code: 'RATE_LIMITED',
            message: rateCheck.message || 'Rate limit exceeded for notifications',
          },
        };
      }

      // Get user preferences (ensures preferences exist, but we use options.channels directly if provided)
      await this.preferencesRepo.getOrCreateDefault({
        ...context,
        userId: options.userId,
      });

      // Determine channels based on preferences
      const channels = await this.determineChannels(
        context,
        options.userId,
        options.type,
        options.priority || 'normal'
      );

      // Create notification
      const createData: NotificationCreateData = {
        userId: options.userId,
        type: options.type,
        priority: options.priority || 'normal',
        title: options.title,
        body: options.body,
        iconType: options.iconType || getIcon(options.type),
        entityType: options.entity?.type,
        entityId: options.entity?.id,
        actionUrl: options.actionUrl,
        actorId: options.actorId,
        actorName: options.actorName,
        channels,
        expiresAt: options.expiresAt,
      };

      const result = await this.notificationRepo.create(context, createData);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'CREATE_FAILED',
            message: result.error?.message || 'Failed to create notification',
          },
        };
      }

      // Trigger delivery (async, don't block)
      this.deliverNotification(context, result.data).catch(() => {
        // Soft-fail delivery - notification is created, delivery can retry
      });

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'NOTIFY_ERROR',
          message: error instanceof Error ? error.message : 'Failed to send notification',
        },
      };
    }
  }

  /**
   * Send notifications to multiple users (e.g., team announcement)
   */
  async notifyMany(
    context: SecurityContext,
    userIds: string[],
    options: Omit<CreateNotificationOptions, 'userId'>
  ): Promise<NotificationServiceResult<Notification[]>> {
    try {
      const notifications: Notification[] = [];
      const errors: string[] = [];

      // Process in batches to respect rate limits
      for (const userId of userIds) {
        const result = await this.notify(context, {
          ...options,
          userId,
        });

        if (result.success && result.data) {
          notifications.push(result.data);
        } else {
          errors.push(`Failed for user ${userId}: ${result.error?.message}`);
        }
      }

      return {
        success: errors.length === 0,
        data: notifications,
        error: errors.length > 0
          ? { code: 'PARTIAL_FAILURE', message: errors.join('; ') }
          : undefined,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'NOTIFY_MANY_ERROR',
          message: error instanceof Error ? error.message : 'Failed to send notifications',
        },
      };
    }
  }

  // ============================================
  // Read Notifications
  // ============================================

  /**
   * Get unread notifications for current user
   */
  async getUnread(
    context: SecurityContext,
    maxResults = 50
  ): Promise<NotificationServiceResult<Notification[]>> {
    try {
      const result = await this.notificationRepo.getUnread(context, maxResults);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to fetch unread notifications',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'FETCH_ERROR',
          message: error instanceof Error ? error.message : 'Failed to fetch notifications',
        },
      };
    }
  }

  /**
   * Get all notifications with options
   */
  async getAll(
    context: SecurityContext,
    options: GetNotificationsOptions = {}
  ): Promise<NotificationServiceResult<NotificationListResponse>> {
    try {
      const result = await this.notificationRepo.getAll(context, options);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to fetch notifications',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'FETCH_ERROR',
          message: error instanceof Error ? error.message : 'Failed to fetch notifications',
        },
      };
    }
  }

  /**
   * Get unread count for current user
   */
  async getUnreadCount(context: SecurityContext): Promise<NotificationServiceResult<number>> {
    try {
      const result = await this.notificationRepo.getUnreadCount(context);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to get unread count',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'FETCH_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get unread count',
        },
      };
    }
  }

  // ============================================
  // Update Notifications
  // ============================================

  /**
   * Mark notification as read
   */
  async markAsRead(
    context: SecurityContext,
    notificationId: string
  ): Promise<NotificationServiceResult<void>> {
    try {
      const result = await this.notificationRepo.markAsRead(context, notificationId);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'UPDATE_ERROR',
            message: result.error?.message || 'Failed to mark as read',
          },
        };
      }

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UPDATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to mark as read',
        },
      };
    }
  }

  /**
   * Mark all notifications as read for current user
   */
  async markAllAsRead(context: SecurityContext): Promise<NotificationServiceResult<number>> {
    try {
      const result = await this.notificationRepo.markAllAsRead(context);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'UPDATE_ERROR',
            message: result.error?.message || 'Failed to mark all as read',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UPDATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to mark all as read',
        },
      };
    }
  }

  /**
   * Archive notification
   */
  async archive(
    context: SecurityContext,
    notificationId: string
  ): Promise<NotificationServiceResult<void>> {
    try {
      const result = await this.notificationRepo.archive(context, notificationId);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'ARCHIVE_ERROR',
            message: result.error?.message || 'Failed to archive notification',
          },
        };
      }

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'ARCHIVE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to archive notification',
        },
      };
    }
  }

  // ============================================
  // Preferences
  // ============================================

  /**
   * Get notification preferences for current user
   */
  async getPreferences(
    context: SecurityContext
  ): Promise<NotificationServiceResult<NotificationPreferences>> {
    try {
      const result = await this.preferencesRepo.getOrCreateDefault(context);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to get preferences',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'FETCH_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get preferences',
        },
      };
    }
  }

  /**
   * Update notification preferences
   */
  async updatePreferences(
    context: SecurityContext,
    updates: NotificationPreferencesUpdate
  ): Promise<NotificationServiceResult<NotificationPreferences>> {
    try {
      const result = await this.preferencesRepo.update(context, updates);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'UPDATE_ERROR',
            message: result.error?.message || 'Failed to update preferences',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UPDATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to update preferences',
        },
      };
    }
  }

  // ============================================
  // Push Subscriptions
  // ============================================

  /**
   * Subscribe to push notifications
   */
  async subscribeToPush(
    context: SecurityContext,
    subscription: PushSubscriptionJSON
  ): Promise<NotificationServiceResult<PushSubscription>> {
    try {
      const features = getFeatureFlags();
      if (!features.enablePushNotifications) {
        return {
          success: false,
          error: {
            code: 'FEATURE_DISABLED',
            message: 'Push notifications are not enabled',
          },
        };
      }

      const result = await this.pushSubRepo.create(context, {
        endpoint: subscription.endpoint || '',
        keys: {
          p256dh: subscription.keys?.p256dh || '',
          auth: subscription.keys?.auth || '',
        },
        userAgent: navigator.userAgent,
        deviceName: this.getDeviceName(),
      });

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'SUBSCRIBE_ERROR',
            message: result.error?.message || 'Failed to subscribe to push',
          },
        };
      }

      // Enable push in preferences
      await this.updatePreferences(context, { pushEnabled: true });

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'SUBSCRIBE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to subscribe to push',
        },
      };
    }
  }

  /**
   * Unsubscribe from push notifications
   */
  async unsubscribeFromPush(
    context: SecurityContext,
    subscriptionId: string
  ): Promise<NotificationServiceResult<void>> {
    try {
      const result = await this.pushSubRepo.delete(context, subscriptionId);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'UNSUBSCRIBE_ERROR',
            message: result.error?.message || 'Failed to unsubscribe from push',
          },
        };
      }

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UNSUBSCRIBE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to unsubscribe',
        },
      };
    }
  }

  // ============================================
  // Delivery (Internal)
  // ============================================

  /**
   * Deliver notification via configured channels
   * Called internally after notification creation
   */
  async deliverNotification(
    context: SecurityContext,
    notification: Notification
  ): Promise<void> {
    const deliveredVia: NotificationChannel[] = ['in_app'];

    // Check if push is enabled and in channels
    if (notification.channels.includes('push')) {
      try {
        await this.sendPushNotification(context, notification);
        deliveredVia.push('push');
      } catch {
        // Push delivery failure is non-blocking
      }
    }

    // Email delivery is handled by Cloud Functions (async)
    // We just mark which channels should receive it

    // Update delivery status
    await this.notificationRepo.updateDeliveryStatus(context, notification.id, {
      deliveredVia,
      pushSentAt: deliveredVia.includes('push') ? new Date() : undefined,
    });
  }

  /**
   * Send push notification to user's devices
   */
  private async sendPushNotification(
    context: SecurityContext,
    notification: Notification
  ): Promise<void> {
    const features = getFeatureFlags();
    if (!features.enablePushNotifications) {
      return;
    }

    // Get user's active push subscriptions
    const subsResult = await this.pushSubRepo.getActiveByUser(
      { ...context, userId: notification.userId },
      notification.userId
    );

    if (!subsResult.success || !subsResult.data || subsResult.data.length === 0) {
      return;
    }

    // TODO: Send push notification payload to Cloud Function
    // const payload: PushNotificationPayload = {
    //   title: notification.title,
    //   body: notification.body,
    //   icon: '/icon-192.png',
    //   badge: '/badge-72.png',
    //   data: { url: notification.actionUrl, notificationId: notification.id, type: notification.type },
    // };
    // This would call a Cloud Function that handles web-push
    // For now, we just mark as delivered
  }

  // ============================================
  // Helpers
  // ============================================

  /**
   * Determine which channels to use based on user preferences and notification type
   */
  private async determineChannels(
    context: SecurityContext,
    userId: string,
    type: NotificationType,
    priority: NotificationPriority
  ): Promise<NotificationChannel[]> {
    const channels: NotificationChannel[] = ['in_app']; // Always include in-app

    // Check if user wants email for this type
    const wantsEmail = await this.preferencesRepo.shouldNotify(
      context,
      userId,
      type,
      'email'
    );
    if (wantsEmail) {
      channels.push('email');
    }

    // Check if user wants push for this type
    const wantsPush = await this.preferencesRepo.shouldNotify(
      context,
      userId,
      type,
      'push'
    );
    if (wantsPush) {
      channels.push('push');
    }

    // Urgent notifications always try all enabled channels
    if (priority === 'urgent') {
      const prefs = await this.preferencesRepo.getOrCreateDefault({
        ...context,
        userId,
      });
      if (prefs.success && prefs.data) {
        if (prefs.data.emailEnabled && !channels.includes('email')) {
          channels.push('email');
        }
        if (prefs.data.pushEnabled && !channels.includes('push')) {
          channels.push('push');
        }
      }
    }

    return channels;
  }

  /**
   * Get device name from user agent
   */
  private getDeviceName(): string {
    const ua = navigator.userAgent;

    if (ua.includes('iPhone')) return 'iPhone';
    if (ua.includes('iPad')) return 'iPad';
    if (ua.includes('Android')) return 'Android Device';
    if (ua.includes('Windows')) return 'Windows PC';
    if (ua.includes('Mac')) return 'Mac';
    if (ua.includes('Linux')) return 'Linux';

    return 'Web Browser';
  }

  // ============================================
  // Real-time Subscriptions
  // ============================================

  /**
   * Subscribe to real-time notification updates
   */
  subscribe(
    context: SecurityContext,
    callback: (notifications: Notification[]) => void,
    options?: { limit?: number; includeArchived?: boolean }
  ): () => void {
    return this.notificationRepo.subscribe(context, callback, options);
  }

  /**
   * Subscribe to unread count updates
   */
  subscribeToUnreadCount(
    context: SecurityContext,
    callback: (count: number) => void
  ): () => void {
    return this.notificationRepo.subscribeToUnreadCount(context, callback);
  }
}

// ============================================
// Singleton Instance
// ============================================

let notificationServiceInstance: NotificationService | null = null;

export function getNotificationService(): NotificationService {
  // Provide fresh instances under Vitest to avoid cross-test state leakage.
  if (typeof process !== 'undefined' && process.env?.VITEST) {
    return new NotificationService();
  }
  if (!notificationServiceInstance) {
    notificationServiceInstance = new NotificationService();
  }
  return notificationServiceInstance;
}
