/**
 * Push Subscription Repository
 * CRUD operations for Web Push subscriptions
 *
 * HIPAA Compliance:
 * - Subscriptions stored under users/{userId} path for user-scoped access
 * - All operations require SecurityContext
 * - Endpoints and keys are user-specific credentials
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
  limit,
} from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import type { SecurityContext, RepositoryResult } from './repository-types';
import { successResult, failedResult } from '../errors/repository-errors';
import { generateId, prepareForCreate, prepareForUpdate } from './firestore-utils';
import type { PushSubscription, PushSubscriptionKeys } from '../../types/notifications';

// ============================================
// Types
// ============================================

/**
 * Data for creating a new push subscription
 */
export interface PushSubscriptionCreateData {
  endpoint: string;
  keys: PushSubscriptionKeys;
  userAgent: string;
  deviceName?: string;
}

// ============================================
// Push Subscription Repository
// ============================================

export class PushSubscriptionRepository {
  private readonly collectionName = 'push_subscriptions';

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
   * Create a new push subscription
   */
  async create(
    context: SecurityContext,
    data: PushSubscriptionCreateData
  ): Promise<RepositoryResult<PushSubscription>> {
    try {
      this.ensureSecurityContext(context);

      // Check if subscription with same endpoint already exists
      const existing = await this.getByEndpoint(context, data.endpoint);
      if (existing.success && existing.data) {
        // Update existing subscription
        return this.reactivate(context, existing.data.id);
      }

      const id = generateId();
      const now = new Date();

      const subscription: PushSubscription = {
        id,
        businessId: context.businessId,
        userId: context.userId,
        endpoint: data.endpoint,
        keys: data.keys,
        userAgent: data.userAgent,
        deviceName: data.deviceName,
        isActive: true,
        lastUsedAt: now,
        failedAttempts: 0,
        createdAt: now,
      };

      const docRef = this.getDocRef(context.userId, id);
      const preparedData = prepareForCreate(subscription as unknown as Record<string, unknown>);
      await setDoc(docRef, preparedData);

      return successResult(subscription);
    } catch (error) {
      return failedResult(error, 'Failed to create push subscription');
    }
  }

  /**
   * Get subscription by ID
   */
  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<PushSubscription>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.userId, id);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(
          new Error('Push subscription not found'),
          'Push subscription not found'
        );
      }

      const data = docSnap.data();
      const subscription: PushSubscription = {
        id: docSnap.id,
        businessId: data.businessId,
        userId: data.userId,
        endpoint: data.endpoint,
        keys: data.keys,
        userAgent: data.userAgent,
        deviceName: data.deviceName,
        isActive: data.isActive,
        lastUsedAt: data.lastUsedAt?.toDate?.() || undefined,
        failedAttempts: data.failedAttempts || 0,
        createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };

      return successResult(subscription);
    } catch (error) {
      return failedResult(error, 'Failed to get push subscription');
    }
  }

  /**
   * Get subscription by endpoint
   */
  async getByEndpoint(
    context: SecurityContext,
    endpoint: string
  ): Promise<RepositoryResult<PushSubscription | null>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.userId);
      const q = query(
        collectionRef,
        where('endpoint', '==', endpoint),
        limit(1)
      );

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const doc = snapshot.docs[0];
      const data = doc.data();

      const subscription: PushSubscription = {
        id: doc.id,
        businessId: data.businessId,
        userId: data.userId,
        endpoint: data.endpoint,
        keys: data.keys,
        userAgent: data.userAgent,
        deviceName: data.deviceName,
        isActive: data.isActive,
        lastUsedAt: data.lastUsedAt?.toDate?.() || undefined,
        failedAttempts: data.failedAttempts || 0,
        createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };

      return successResult(subscription);
    } catch (error) {
      return failedResult(error, 'Failed to get subscription by endpoint');
    }
  }

  /**
   * Get all active subscriptions for a user
   */
  async getActiveByUser(
    context: SecurityContext,
    userId: string
  ): Promise<RepositoryResult<PushSubscription[]>> {
    try {
      this.ensureSecurityContext(context);

      // RBAC: Users can only access their own subscriptions
      if (userId !== context.userId) {
        return failedResult(
          new Error('Not authorized to access these subscriptions'),
          'Not authorized'
        );
      }

      const collectionRef = this.getCollectionRef(userId);
      const q = query(
        collectionRef,
        where('isActive', '==', true)
      );

      const snapshot = await getDocs(q);
      const subscriptions = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          businessId: data.businessId,
          userId: data.userId,
          endpoint: data.endpoint,
          keys: data.keys,
          userAgent: data.userAgent,
          deviceName: data.deviceName,
          isActive: data.isActive,
          lastUsedAt: data.lastUsedAt?.toDate?.() || undefined,
          failedAttempts: data.failedAttempts || 0,
          createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
          updatedAt: data.updatedAt?.toDate?.() || undefined,
        } as PushSubscription;
      });

      return successResult(subscriptions);
    } catch (error) {
      return failedResult(error, 'Failed to get active subscriptions');
    }
  }

  /**
   * Update last used timestamp
   */
  async updateLastUsed(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.userId, id);
      await updateDoc(docRef, prepareForUpdate({
        lastUsedAt: new Date(),
        failedAttempts: 0, // Reset failed attempts on success
      }));

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to update last used');
    }
  }

  /**
   * Increment failed attempts counter
   */
  async incrementFailedAttempts(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<number>> {
    try {
      this.ensureSecurityContext(context);

      // Get current count
      const existing = await this.getById(context, id);
      if (!existing.success || !existing.data) {
        return { success: false, data: null, error: existing.error };
      }

      const newCount = existing.data.failedAttempts + 1;

      const docRef = this.getDocRef(context.userId, id);
      await updateDoc(docRef, prepareForUpdate({
        failedAttempts: newCount,
      }));

      // Auto-deactivate if too many failures
      if (newCount >= 3) {
        await this.deactivate(context, id);
      }

      return successResult(newCount);
    } catch (error) {
      return failedResult(error, 'Failed to increment failed attempts');
    }
  }

  /**
   * Deactivate a subscription
   */
  async deactivate(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.userId, id);
      await updateDoc(docRef, prepareForUpdate({
        isActive: false,
      }));

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to deactivate subscription');
    }
  }

  /**
   * Reactivate a subscription
   */
  async reactivate(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<PushSubscription>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.userId, id);
      await updateDoc(docRef, prepareForUpdate({
        isActive: true,
        failedAttempts: 0,
        lastUsedAt: new Date(),
      }));

      // Return updated subscription
      return this.getById(context, id);
    } catch (error) {
      return failedResult(error, 'Failed to reactivate subscription');
    }
  }

  /**
   * Delete a subscription
   */
  async delete(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context.userId, id);
      await deleteDoc(docRef);

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete subscription');
    }
  }

  /**
   * Delete subscription by endpoint
   */
  async deleteByEndpoint(
    context: SecurityContext,
    endpoint: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const existing = await this.getByEndpoint(context, endpoint);
      if (existing.success && existing.data) {
        return this.delete(context, existing.data.id);
      }

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to delete subscription by endpoint');
    }
  }

  /**
   * Clean up failed subscriptions
   * (Called by Cloud Functions)
   */
  async cleanupFailedSubscriptions(
    context: SecurityContext
  ): Promise<RepositoryResult<number>> {
    try {
      this.ensureSecurityContext(context);

      const collectionRef = this.getCollectionRef(context.userId);
      const q = query(
        collectionRef,
        where('isActive', '==', false)
      );

      const snapshot = await getDocs(q);
      const deletes = snapshot.docs.map((doc) => deleteDoc(doc.ref));

      await Promise.all(deletes);
      return successResult(snapshot.docs.length);
    } catch (error) {
      return failedResult(error, 'Failed to cleanup subscriptions');
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let pushSubscriptionRepositoryInstance: PushSubscriptionRepository | null = null;

export function getPushSubscriptionRepository(): PushSubscriptionRepository {
  if (!pushSubscriptionRepositoryInstance) {
    pushSubscriptionRepositoryInstance = new PushSubscriptionRepository();
  }
  return pushSubscriptionRepositoryInstance;
}
