/**
 * Push Notification Service
 * Handles Web Push notifications via service worker
 *
 * HIPAA Compliance:
 * - Push notification content kept minimal - NO PHI
 * - Links back to app for details
 * - VAPID keys stored securely in environment
 *
 * Note: Actual push delivery is handled by Cloud Functions
 * This service manages client-side subscription and preparation
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getPushSubscriptionRepository,
  type PushSubscriptionCreateData,
} from '../data/repositories/push-subscription-repository';
import { getFeatureFlags } from '../config/features';
import type { PushSubscription, PushNotificationPayload } from '../types/notifications';

// ============================================
// Types
// ============================================

export interface PushServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// Configuration
// ============================================

/**
 * Get VAPID public key from environment
 */
function getVapidPublicKey(): string | null {
  return import.meta.env.VITE_VAPID_PUBLIC_KEY || null;
}

/**
 * Convert URL-safe base64 to Uint8Array for applicationServerKey
 */
function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }

  return outputArray;
}

// ============================================
// Push Notification Service
// ============================================

export class PushNotificationService {
  private pushSubRepo = getPushSubscriptionRepository();

  // ============================================
  // Subscription Management
  // ============================================

  /**
   * Check if push notifications are supported
   */
  isSupported(): boolean {
    return (
      'serviceWorker' in navigator &&
      'PushManager' in window &&
      'Notification' in window
    );
  }

  /**
   * Check if push notifications are enabled (feature flag)
   */
  isEnabled(): boolean {
    const features = getFeatureFlags();
    return features.enablePushNotifications === true;
  }

  /**
   * Get current notification permission status
   */
  getPermissionStatus(): NotificationPermission {
    if (!this.isSupported()) {
      return 'denied';
    }
    return Notification.permission;
  }

  /**
   * Request notification permission
   */
  async requestPermission(): Promise<NotificationPermission> {
    if (!this.isSupported()) {
      return 'denied';
    }

    const permission = await Notification.requestPermission();
    return permission;
  }

  /**
   * Subscribe to push notifications
   */
  async subscribe(context: SecurityContext): Promise<PushServiceResult<PushSubscription>> {
    try {
      // Check if feature is enabled
      if (!this.isEnabled()) {
        return {
          success: false,
          error: {
            code: 'FEATURE_DISABLED',
            message: 'Push notifications are not enabled',
          },
        };
      }

      // Check browser support
      if (!this.isSupported()) {
        return {
          success: false,
          error: {
            code: 'NOT_SUPPORTED',
            message: 'Push notifications are not supported in this browser',
          },
        };
      }

      // Check permission
      const permission = await this.requestPermission();
      if (permission !== 'granted') {
        return {
          success: false,
          error: {
            code: 'PERMISSION_DENIED',
            message: 'Notification permission was denied',
          },
        };
      }

      // Get VAPID key
      const vapidKey = getVapidPublicKey();
      if (!vapidKey) {
        return {
          success: false,
          error: {
            code: 'CONFIG_ERROR',
            message: 'Push notification configuration is missing',
          },
        };
      }

      // Register service worker if not already registered
      const registration = await this.getServiceWorkerRegistration();
      if (!registration) {
        return {
          success: false,
          error: {
            code: 'SW_ERROR',
            message: 'Failed to register service worker',
          },
        };
      }

      // Subscribe to push manager
      const pushSubscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidKey) as BufferSource,
      });

      // Extract subscription data
      const subscriptionJson = pushSubscription.toJSON();
      if (!subscriptionJson.endpoint || !subscriptionJson.keys) {
        return {
          success: false,
          error: {
            code: 'SUBSCRIPTION_ERROR',
            message: 'Invalid push subscription',
          },
        };
      }

      // Save to repository
      const createData: PushSubscriptionCreateData = {
        endpoint: subscriptionJson.endpoint,
        keys: {
          p256dh: subscriptionJson.keys.p256dh || '',
          auth: subscriptionJson.keys.auth || '',
        },
        userAgent: navigator.userAgent,
        deviceName: this.getDeviceName(),
      };

      const result = await this.pushSubRepo.create(context, createData);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'SAVE_ERROR',
            message: result.error?.message || 'Failed to save subscription',
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
          code: 'SUBSCRIBE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to subscribe',
        },
      };
    }
  }

  /**
   * Unsubscribe from push notifications
   */
  async unsubscribe(context: SecurityContext): Promise<PushServiceResult<void>> {
    try {
      // Get service worker registration
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();

      if (subscription) {
        // Unsubscribe from browser
        await subscription.unsubscribe();

        // Remove from repository
        const endpoint = subscription.endpoint;
        await this.pushSubRepo.deleteByEndpoint(context, endpoint);
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

  /**
   * Get current push subscription status
   */
  async getSubscriptionStatus(
    context: SecurityContext
  ): Promise<PushServiceResult<{ subscribed: boolean; subscription?: PushSubscription }>> {
    try {
      if (!this.isSupported()) {
        return {
          success: true,
          data: { subscribed: false },
        };
      }

      const registration = await navigator.serviceWorker.ready;
      const browserSubscription = await registration.pushManager.getSubscription();

      if (!browserSubscription) {
        return {
          success: true,
          data: { subscribed: false },
        };
      }

      // Check if stored in repository
      const result = await this.pushSubRepo.getByEndpoint(
        context,
        browserSubscription.endpoint
      );

      if (result.success && result.data) {
        return {
          success: true,
          data: {
            subscribed: true,
            subscription: result.data,
          },
        };
      }

      return {
        success: true,
        data: { subscribed: false },
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'STATUS_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get status',
        },
      };
    }
  }

  /**
   * Get all active subscriptions for current user
   */
  async getActiveSubscriptions(
    context: SecurityContext
  ): Promise<PushServiceResult<PushSubscription[]>> {
    try {
      const result = await this.pushSubRepo.getActiveByUser(context, context.userId);
      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to fetch subscriptions',
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
          message: error instanceof Error ? error.message : 'Failed to fetch subscriptions',
        },
      };
    }
  }

  // ============================================
  // Service Worker Management
  // ============================================

  /**
   * Get or register service worker
   */
  private async getServiceWorkerRegistration(): Promise<ServiceWorkerRegistration | null> {
    try {
      // Check if already registered
      const existing = await navigator.serviceWorker.getRegistration('/');
      if (existing) {
        return existing;
      }

      // Register service worker
      const registration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/',
      });

      // Wait for activation
      await navigator.serviceWorker.ready;

      return registration;
    } catch (error) {
      return null;
    }
  }

  // ============================================
  // Local Notifications (Fallback)
  // ============================================

  /**
   * Show a local notification (for testing or fallback)
   */
  async showLocalNotification(
    payload: PushNotificationPayload
  ): Promise<PushServiceResult<void>> {
    try {
      if (!this.isSupported()) {
        return {
          success: false,
          error: {
            code: 'NOT_SUPPORTED',
            message: 'Notifications not supported',
          },
        };
      }

      const permission = Notification.permission;
      if (permission !== 'granted') {
        return {
          success: false,
          error: {
            code: 'PERMISSION_DENIED',
            message: 'Notification permission not granted',
          },
        };
      }

      const registration = await navigator.serviceWorker.ready;
      await registration.showNotification(payload.title, {
        body: payload.body,
        icon: payload.icon || '/icon.svg',
        badge: payload.badge || '/icon.svg',
        data: payload.data,
        tag: payload.data?.notificationId,
      });

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'SHOW_ERROR',
          message: error instanceof Error ? error.message : 'Failed to show notification',
        },
      };
    }
  }

  // ============================================
  // Helpers
  // ============================================

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
    if (ua.includes('Chrome')) return 'Chrome Browser';
    if (ua.includes('Firefox')) return 'Firefox Browser';
    if (ua.includes('Safari')) return 'Safari Browser';

    return 'Web Browser';
  }
}

// ============================================
// Singleton Instance
// ============================================

let pushNotificationServiceInstance: PushNotificationService | null = null;

export function getPushNotificationService(): PushNotificationService {
  if (!pushNotificationServiceInstance) {
    pushNotificationServiceInstance = new PushNotificationService();
  }
  return pushNotificationServiceInstance;
}
