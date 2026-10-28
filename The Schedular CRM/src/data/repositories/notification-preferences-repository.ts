/**
 * Notification Preferences Repository
 * CRUD operations for user notification preferences
 *
 * HIPAA Compliance:
 * - Preferences stored under users/{userId} path for user-scoped access
 * - All operations require SecurityContext
 * - No PHI in preferences data
 */

import {
  collection,
  doc,
  getDocs,
  setDoc,
  updateDoc,
  query,
  where,
  limit,
} from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import type { SecurityContext, RepositoryResult } from './repository-types';
import { successResult, failedResult } from '../errors/repository-errors';
import { generateId, prepareForCreate, prepareForUpdate } from './firestore-utils';
import type {
  DigestFrequency,
  NotificationPreferences,
  NotificationPreferencesUpdate,
  NotificationType,
  TypeNotificationSetting,
} from '../../types/notifications';
import { getDefaultNotificationPreferences } from '../../types/notifications';

// ============================================
// Types
// ============================================

// ============================================
// Notification Preferences Repository
// ============================================

export class NotificationPreferencesRepository {
  private readonly collectionName = 'notification_preferences';

  /**
   * Ensure security context is valid
   */
  private ensureSecurityContext(context: SecurityContext): void {
    if (!context.businessId?.trim()) {
      throw new Error('SecurityContext missing businessId');
    }
    if (!context.userId?.trim()) {
      throw new Error('SecurityContext missing userId');
    }
  }

  /**
   * Get collection path under user document
   * Preferences are stored at users/{userId}/notification_preferences
   */
  private getCollectionPath(userId: string): string {
    return `users/${userId}/${this.collectionName}`;
  }

  /**
   * Get collection reference
   */
  private getCollectionRef(userId: string) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return collection(db, this.getCollectionPath(userId));
  }

  /**
   * Get document reference
   */
  private getDocRef(userId: string, docId: string) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return doc(db, this.getCollectionPath(userId), docId);
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /**
   * Get preferences for current user, creating defaults if not exists
   */
  async getOrCreateDefault(
    context: SecurityContext
  ): Promise<RepositoryResult<NotificationPreferences>> {
    try {
      this.ensureSecurityContext(context);

      // Try to get existing preferences
      const existing = await this.getByUserId(context, context.userId);
      if (existing.success && existing.data) {
        return successResult(existing.data);
      }

      // Create default preferences
      const defaults = getDefaultNotificationPreferences(
        context.userId,
        context.businessId
      );

      const id = generateId();
      const now = new Date();

      const preferences: NotificationPreferences = {
        id,
        ...defaults,
        createdAt: now,
      };

      const docRef = this.getDocRef(context.userId, id);
      const preparedData = prepareForCreate(preferences as unknown as Record<string, unknown>);
      await setDoc(docRef, preparedData);

      return successResult(preferences);
    } catch (error) {
      return failedResult(error, 'Failed to get or create notification preferences');
    }
  }

  /**
   * Get preferences by user ID
   */
  async getByUserId(
    context: SecurityContext,
    userId: string
  ): Promise<RepositoryResult<NotificationPreferences | null>> {
    try {
      this.ensureSecurityContext(context);

      // RBAC: Users can only access their own preferences
      if (userId !== context.userId) {
        return failedResult(
          new Error('Not authorized to access these preferences'),
          'Not authorized'
        );
      }

      const collectionRef = this.getCollectionRef(userId);
      const q = query(
        collectionRef,
        where('businessId', '==', context.businessId),
        limit(1)
      );

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const doc = snapshot.docs[0];
      const data = doc.data();

      const preferences: NotificationPreferences = {
        id: doc.id,
        businessId: data.businessId,
        userId: data.userId,
        emailEnabled: data.emailEnabled ?? true,
        pushEnabled: data.pushEnabled ?? false,
        quietHoursStart: data.quietHoursStart,
        quietHoursEnd: data.quietHoursEnd,
        timezone: data.timezone || 'America/New_York',
        typeSettings: data.typeSettings || {},
        emailDigestFrequency: data.emailDigestFrequency || 'daily',
        emailDigestTime: data.emailDigestTime,
        createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };

      return successResult(preferences);
    } catch (error) {
      return failedResult(error, 'Failed to get notification preferences');
    }
  }

  /**
   * Update notification preferences
   */
  async update(
    context: SecurityContext,
    data: NotificationPreferencesUpdate
  ): Promise<RepositoryResult<NotificationPreferences>> {
    try {
      this.ensureSecurityContext(context);

      // Get existing preferences (or create defaults)
      const existing = await this.getOrCreateDefault(context);
      if (!existing.success || !existing.data) {
        return failedResult(existing.error ?? new Error('Failed to load preferences'));
      }

      const preferences = existing.data;

      // Merge type settings if provided
      let updatedTypeSettings = preferences.typeSettings;
      if (data.typeSettings) {
        updatedTypeSettings = {
          ...preferences.typeSettings,
          ...data.typeSettings,
        };
      }

      const updateData: Record<string, unknown> = {
        ...data,
        typeSettings: updatedTypeSettings,
      };

      const docRef = this.getDocRef(context.userId, preferences.id);
      await updateDoc(docRef, prepareForUpdate(updateData));

      // Return updated preferences
      const updated = await this.getByUserId(context, context.userId);
      if (!updated.success || !updated.data) {
        return failedResult(updated.error ?? new Error('Failed to load preferences after update'));
      }

      return successResult(updated.data);
    } catch (error) {
      return failedResult(error, 'Failed to update notification preferences');
    }
  }

  /**
   * Update settings for a specific notification type
   */
  async updateTypeSettings(
    context: SecurityContext,
    type: NotificationType,
    settings: TypeNotificationSetting
  ): Promise<RepositoryResult<NotificationPreferences>> {
    try {
      this.ensureSecurityContext(context);

      return this.update(context, {
        typeSettings: {
          [type]: settings,
        },
      });
    } catch (error) {
      return failedResult(error, 'Failed to update type settings');
    }
  }

  /**
   * Check if user should receive notification via specific channel
   */
  async shouldNotify(
    context: SecurityContext,
    userId: string,
    type: NotificationType,
    channel: 'email' | 'push' | 'in_app'
  ): Promise<boolean> {
    try {
      // Use a system context for checking other users' preferences
      const checkContext: SecurityContext = {
        ...context,
        userId,
      };

      const result = await this.getByUserId(checkContext, userId);
      if (!result.success || !result.data) {
        // Default to in_app only if no preferences found
        return channel === 'in_app';
      }

      const preferences = result.data;

      // Check global channel settings
      if (channel === 'email' && !preferences.emailEnabled) {
        return false;
      }
      if (channel === 'push' && !preferences.pushEnabled) {
        return false;
      }

      // Check quiet hours
      if (this.isInQuietHours(preferences)) {
        // During quiet hours, only urgent notifications go through
        return false;
      }

      // Check type-specific settings
      const typeSettings = preferences.typeSettings[type];
      if (!typeSettings) {
        // Default to in_app only
        return channel === 'in_app';
      }

      if (!typeSettings.enabled) {
        return false;
      }

      return typeSettings.channels.includes(channel);
    } catch {
      // Default to allowing in-app notifications
      return channel === 'in_app';
    }
  }

  /**
   * Check if currently in quiet hours
   */
  private isInQuietHours(preferences: NotificationPreferences): boolean {
    if (!preferences.quietHoursStart || !preferences.quietHoursEnd) {
      return false;
    }

    try {
      const now = new Date();

      // Parse quiet hours (HH:MM format)
      const [startHour, startMin] = preferences.quietHoursStart.split(':').map(Number);
      const [endHour, endMin] = preferences.quietHoursEnd.split(':').map(Number);

      // Get current time in user's timezone
      const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone: preferences.timezone || 'America/New_York',
        hour: 'numeric',
        minute: 'numeric',
        hour12: false,
      });

      const parts = formatter.formatToParts(now);
      const currentHour = parseInt(parts.find(p => p.type === 'hour')?.value || '0', 10);
      const currentMin = parseInt(parts.find(p => p.type === 'minute')?.value || '0', 10);

      const currentMinutes = currentHour * 60 + currentMin;
      const startMinutes = startHour * 60 + startMin;
      const endMinutes = endHour * 60 + endMin;

      // Handle overnight quiet hours (e.g., 22:00 to 08:00)
      if (startMinutes > endMinutes) {
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
      }

      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } catch {
      return false;
    }
  }

  /**
   * Get users who want digest at specific frequency and time
   * (Used by Cloud Functions for batch digest sending)
   */
  async getUsersForDigest(
    _businessId: string,
    _frequency: DigestFrequency,
    _currentHour: string // HH:00 format
  ): Promise<string[]> {
    // This would be implemented in Cloud Functions with appropriate admin context
    // For now, return empty array as this requires server-side implementation
    return [];
  }
}

// ============================================
// Singleton Instance
// ============================================

let notificationPreferencesRepositoryInstance: NotificationPreferencesRepository | null = null;

export function getNotificationPreferencesRepository(): NotificationPreferencesRepository {
  if (!notificationPreferencesRepositoryInstance) {
    notificationPreferencesRepositoryInstance = new NotificationPreferencesRepository();
  }
  return notificationPreferencesRepositoryInstance;
}
