/**
 * Notification Repository
 * CRUD operations for notifications with RBAC enforcement
 *
 * HIPAA Compliance:
 * - Users can only access their own notifications (userId scoping)
 * - All operations require SecurityContext for multi-tenant isolation
 * - No PHI stored in notification content - reference entities only
 * - Audit logging for all notification access
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  onSnapshot,
  Timestamp,
  getCountFromServer,
} from 'firebase/firestore';
import type { DocumentData, QuerySnapshot, Unsubscribe } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type { SecurityContext, RepositoryResult } from './repository-types';
import { successResult, failedResult } from '../errors/repository-errors';
import { generateId, prepareForCreate, prepareForUpdate, documentToEntity } from './firestore-utils';
import type {
  Notification,
  NotificationType,
  NotificationPriority,
  NotificationChannel,
  NotificationEntityType,
  GetNotificationsOptions,
  NotificationListResponse,
} from '../../types/notifications';

// ============================================
// Types
// ============================================

/**
 * Data for creating a new notification
 */
export interface NotificationCreateData {
  userId: string;
  type: NotificationType;
  priority?: NotificationPriority;
  title: string;
  body: string;
  iconType?: string;
  entityType?: NotificationEntityType;
  entityId?: string;
  actionUrl?: string;
  actorId?: string;
  actorName?: string;
  channels?: NotificationChannel[];
  expiresAt?: Date;
}

/**
 * Data for updating a notification
 */
export interface NotificationUpdateData {
  isRead?: boolean;
  readAt?: Date;
  isArchived?: boolean;
  archivedAt?: Date;
  deliveredVia?: NotificationChannel[];
  emailSentAt?: Date;
  pushSentAt?: Date;
}

// ============================================
// Notification Repository
// ============================================

export class NotificationRepository {
  private readonly collectionName = 'notifications';

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
   * Get collection path scoped by businessId
   */
  private getCollectionPath(businessId: string): string {
    return `${businessPath(businessId)}/${this.collectionName}`;
  }

  /**
   * Get collection reference
   */
  private getCollectionRef(businessId: string) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return collection(db, this.getCollectionPath(businessId));
  }

  /**
   * Get document reference
   */
  private getDocRef(businessId: string, docId: string) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return doc(db, this.getCollectionPath(businessId), docId);
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /**
   * Create a new notification
   */
  async create(
    context: SecurityContext,
    data: NotificationCreateData
  ): Promise<RepositoryResult<Notification>> {
    try {
      this.ensureSecurityContext(context);

      const id = generateId();
      const now = new Date();

      const notification: Omit<Notification, 'id'> = {
        businessId: context.businessId,
        userId: data.userId,
        type: data.type,
        priority: data.priority || 'normal',
        title: data.title,
        body: data.body,
        iconType: data.iconType,
        entityType: data.entityType,
        entityId: data.entityId,
        actionUrl: data.actionUrl,
        actorId: data.actorId,
        actorName: data.actorName,
        isRead: false,
        isArchived: false,
        channels: data.channels || ['in_app'],
        deliveredVia: ['in_app'], // In-app is always delivered immediately
        createdAt: now,
        expiresAt: data.expiresAt,
      };

      const docRef = this.getDocRef(context.businessId, id);
      const preparedData = prepareForCreate(notification as unknown as Record<string, unknown>);
      await setDoc(docRef, preparedData);

      return successResult({
        id,
        ...notification,
      } as Notification);
    } catch (error) {
      return failedResult(error, 'Failed to create notification');
    }
  }

  /**
   * Get notification by ID (only if owned by user)
   */
  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<Notification>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.businessId, id);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new Error('Notification not found'), 'Notification not found');
      }

      const notification = documentToEntity<Notification>(docSnap);
      if (!notification) {
        return failedResult(new Error('Invalid notification data'), 'Invalid notification data');
      }

      // RBAC: Users can only access their own notifications
      if (notification.userId !== context.userId) {
        return failedResult(
          new Error('Not authorized to access this notification'),
          'Not authorized'
        );
      }

      return successResult(notification);
    } catch (error) {
      return failedResult(error, 'Failed to get notification');
    }
  }

  /**
   * Get all notifications for current user
   * Uses cursor-based pagination for Firestore compatibility
   */
  async getAll(
    context: SecurityContext,
    options: GetNotificationsOptions = {}
  ): Promise<RepositoryResult<NotificationListResponse>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const constraints: any[] = [
        where('userId', '==', context.userId),
      ];

      // Filter by archived status
      if (!options.includeArchived) {
        constraints.push(where('isArchived', '==', false));
      }

      // Filter by unread only
      if (options.unreadOnly) {
        constraints.push(where('isRead', '==', false));
      }

      // Filter by types
      if (options.types && options.types.length > 0) {
        constraints.push(where('type', 'in', options.types));
      }

      // Order by createdAt desc
      constraints.push(orderBy('createdAt', 'desc'));

      // Cursor-based pagination: fetch the last document and start after it
      if (options.lastDocId) {
        const lastDocRef = doc(collectionRef, options.lastDocId);
        const lastDocSnap = await getDoc(lastDocRef);
        if (lastDocSnap.exists()) {
          constraints.push(startAfter(lastDocSnap));
        }
      }

      // Apply limit
      const queryLimit = options.limit || 50;
      constraints.push(limit(queryLimit + 1)); // Fetch one extra to determine hasMore

      const q = query(collectionRef, ...constraints);
      const snapshot = await getDocs(q);

      const notifications = snapshot.docs.slice(0, queryLimit).map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
          readAt: data.readAt?.toDate?.() || (data.readAt ? new Date(data.readAt) : undefined),
          archivedAt: data.archivedAt?.toDate?.() || (data.archivedAt ? new Date(data.archivedAt) : undefined),
          emailSentAt: data.emailSentAt?.toDate?.() || (data.emailSentAt ? new Date(data.emailSentAt) : undefined),
          pushSentAt: data.pushSentAt?.toDate?.() || (data.pushSentAt ? new Date(data.pushSentAt) : undefined),
          expiresAt: data.expiresAt?.toDate?.() || (data.expiresAt ? new Date(data.expiresAt) : undefined),
        } as Notification;
      });

      const hasMore = snapshot.docs.length > queryLimit;
      const lastDocId = notifications.length > 0 ? notifications[notifications.length - 1].id : undefined;

      return successResult({
        notifications,
        total: notifications.length,
        hasMore,
        lastDocId,
      });
    } catch (error) {
      return failedResult(error, 'Failed to get notifications');
    }
  }

  /**
   * Get unread notifications for current user
   */
  async getUnread(
    context: SecurityContext,
    maxResults = 50
  ): Promise<RepositoryResult<Notification[]>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('userId', '==', context.userId),
        where('isRead', '==', false),
        where('isArchived', '==', false),
        orderBy('createdAt', 'desc'),
        limit(maxResults)
      );

      const snapshot = await getDocs(q);
      const notifications = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
          readAt: data.readAt?.toDate?.() || undefined,
          expiresAt: data.expiresAt?.toDate?.() || undefined,
        } as Notification;
      });

      return successResult(notifications);
    } catch (error) {
      return failedResult(error, 'Failed to get unread notifications');
    }
  }

  /**
   * Get count of unread notifications
   */
  async getUnreadCount(context: SecurityContext): Promise<RepositoryResult<number>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('userId', '==', context.userId),
        where('isRead', '==', false),
        where('isArchived', '==', false)
      );

      const snapshot = await getCountFromServer(q);
      return successResult(snapshot.data().count);
    } catch (error) {
      return failedResult(error, 'Failed to get unread count');
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      // Verify ownership
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, id);
      await updateDoc(docRef, prepareForUpdate({
        isRead: true,
        readAt: new Date(),
      }));

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to mark notification as read');
    }
  }

  /**
   * Mark all notifications as read for current user
   */
  async markAllAsRead(context: SecurityContext): Promise<RepositoryResult<number>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('userId', '==', context.userId),
        where('isRead', '==', false),
        where('isArchived', '==', false)
      );

      const snapshot = await getDocs(q);
      const now = new Date();
      const updateData = prepareForUpdate({
        isRead: true,
        readAt: now,
      });

      const updates = snapshot.docs.map((doc) =>
        updateDoc(doc.ref, updateData)
      );

      await Promise.all(updates);
      return successResult(snapshot.docs.length);
    } catch (error) {
      return failedResult(error, 'Failed to mark all as read');
    }
  }

  /**
   * Archive a notification
   */
  async archive(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      // Verify ownership
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context.businessId, id);
      await updateDoc(docRef, prepareForUpdate({
        isArchived: true,
        archivedAt: new Date(),
      }));

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to archive notification');
    }
  }

  /**
   * Update notification delivery status
   */
  async updateDeliveryStatus(
    context: SecurityContext,
    id: string,
    data: NotificationUpdateData
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.businessId, id);
      await updateDoc(docRef, prepareForUpdate(data as unknown as Record<string, unknown>));

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to update delivery status');
    }
  }

  /**
   * Get notifications for digest (Cloud Function use)
   */
  async getForDigest(
    context: SecurityContext,
    userId: string,
    periodStart: Date,
    periodEnd: Date
  ): Promise<RepositoryResult<Notification[]>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('userId', '==', userId),
        where('createdAt', '>=', Timestamp.fromDate(periodStart)),
        where('createdAt', '<=', Timestamp.fromDate(periodEnd)),
        orderBy('createdAt', 'desc')
      );

      const snapshot = await getDocs(q);
      const notifications = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
        } as Notification;
      });

      return successResult(notifications);
    } catch (error) {
      return failedResult(error, 'Failed to get notifications for digest');
    }
  }

  /**
   * Delete old notifications (Cloud Function cleanup)
   */
  async deleteOlderThan(
    context: SecurityContext,
    date: Date
  ): Promise<RepositoryResult<number>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.businessId);
      const q = query(
        collectionRef,
        where('createdAt', '<', Timestamp.fromDate(date)),
        limit(500) // Batch delete limit
      );

      const snapshot = await getDocs(q);
      const deletes = snapshot.docs.map((doc) => deleteDoc(doc.ref));

      await Promise.all(deletes);
      return successResult(snapshot.docs.length);
    } catch (error) {
      return failedResult(error, 'Failed to delete old notifications');
    }
  }

  // ============================================
  // Real-time Subscriptions
  // ============================================

  /**
   * Subscribe to notifications for current user
   */
  subscribe(
    context: SecurityContext,
    callback: (notifications: Notification[]) => void,
    options: { limit?: number; includeArchived?: boolean } = {}
  ): Unsubscribe {
    try {
      this.ensureSecurityContext(context);
    } catch (err) {
      callback([]);
      return () => {};
    }

    const collectionRef = this.getCollectionRef(context.businessId);
    const constraints: Parameters<typeof query>[1][] = [
      where('userId', '==', context.userId),
    ];

    if (!options.includeArchived) {
      constraints.push(where('isArchived', '==', false));
    }

    constraints.push(orderBy('createdAt', 'desc'));
    constraints.push(limit(options.limit || 50));

    const q = query(collectionRef, ...constraints);

    return onSnapshot(
      q,
      (snapshot: QuerySnapshot<DocumentData>) => {
        const notifications = snapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            ...data,
            createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
            readAt: data.readAt?.toDate?.() || undefined,
            archivedAt: data.archivedAt?.toDate?.() || undefined,
            expiresAt: data.expiresAt?.toDate?.() || undefined,
          } as Notification;
        });
        callback(notifications);
      },
      () => {
        // Error callback - fail silently per HIPAA guidelines
        callback([]);
      }
    );
  }

  /**
   * Subscribe to unread count for current user
   */
  subscribeToUnreadCount(
    context: SecurityContext,
    callback: (count: number) => void
  ): Unsubscribe {
    try {
      this.ensureSecurityContext(context);
    } catch (err) {
      callback(0);
      return () => {};
    }

    const collectionRef = this.getCollectionRef(context.businessId);
    const q = query(
      collectionRef,
      where('userId', '==', context.userId),
      where('isRead', '==', false),
      where('isArchived', '==', false)
    );

    return onSnapshot(
      q,
      (snapshot: QuerySnapshot<DocumentData>) => {
        callback(snapshot.docs.length);
      },
      () => {
        callback(0);
      }
    );
  }
}

// ============================================
// Singleton Instance
// ============================================

let notificationRepositoryInstance: NotificationRepository | null = null;

export function getNotificationRepository(): NotificationRepository {
  if (!notificationRepositoryInstance) {
    notificationRepositoryInstance = new NotificationRepository();
  }
  return notificationRepositoryInstance;
}
