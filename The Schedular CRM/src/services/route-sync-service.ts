/**
 * Route Sync Service
 * Queues routes for synchronization to The Scheduler mobile app
 *
 * Features:
 * - Queue routes for mobile sync
 * - Track sync status
 * - Trigger push notifications
 *
 * HIPAA Compliance: Route data contains contact info - ensure mobile app has proper controls
 */

import {
  doc,
  collection,
  setDoc,
  updateDoc,
  serverTimestamp,
  query,
  where,
  getDocs,
  Timestamp,
  writeBatch,
} from 'firebase/firestore';
import { getFirebaseDb } from '../lib/firebase';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Route, RouteStop } from '../types/models';
import { getAuditLogService } from './AuditLogService';

function getDb() {
  const db = getFirebaseDb();
  if (!db) throw new Error('Firestore not initialized');
  return db;
}

// ============================================
// Types
// ============================================

export type SyncStatus = 'pending' | 'syncing' | 'synced' | 'failed';

export interface RouteSyncItem {
  id: string;
  businessId: string;
  routeId: string;
  assigneeId: string;
  assigneeName: string;
  routeDate: Date;
  status: SyncStatus;
  stopCount: number;
  totalDistanceKm?: number;
  estimatedDurationMinutes?: number;
  createdAt: Date;
  updatedAt: Date;
  syncedAt?: Date;
  failureReason?: string;
  notificationSent: boolean;
}

export interface SyncResult {
  success: boolean;
  syncedCount: number;
  failedCount: number;
  errors: string[];
}

export interface MobileRoutePayload {
  routeId: string;
  name: string;
  date: string; // ISO date
  assigneeId: string;
  assigneeName: string;
  stops: MobileRouteStop[];
  status: string;
  notes?: string;
  totalDistanceKm?: number;
  estimatedDurationMinutes?: number;
}

export interface MobileRouteStop {
  order: number;
  contactId: string;
  contactName: string;
  companyName?: string;
  address: string;
  latitude?: number;
  longitude?: number;
  status: string;
  notes?: string;
  preferredArrivalStart?: string;
  preferredArrivalEnd?: string;
}

// ============================================
// Service
// ============================================

export class RouteSyncService {
  private audit = getAuditLogService();

  /**
   * Queue a route for mobile sync
   */
  async queueRouteForSync(
    context: SecurityContext,
    route: Route
  ): Promise<RouteSyncItem> {
    if (!route.assigneeId) {
      throw new Error('Route must have an assignee to sync to mobile');
    }

    const db = getDb();
    const syncItemRef = doc(
      collection(db, 'businesses', context.businessId, 'route_sync_queue')
    );

    const syncItem: Omit<RouteSyncItem, 'id'> = {
      businessId: context.businessId,
      routeId: route.id,
      assigneeId: route.assigneeId,
      assigneeName: route.assigneeName ?? '',
      routeDate: route.date instanceof Timestamp ? route.date.toDate() : route.date,
      status: 'pending',
      stopCount: route.stops.length,
      totalDistanceKm: route.totalDistanceKm as number | undefined,
      estimatedDurationMinutes: route.estimatedDurationMinutes as number | undefined,
      createdAt: new Date(),
      updatedAt: new Date(),
      notificationSent: false,
    };

    await setDoc(syncItemRef, {
      ...syncItem,
      routeDate: Timestamp.fromDate(
        syncItem.routeDate instanceof Date ? syncItem.routeDate : new Date(syncItem.routeDate)
      ),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    await this.audit.logAction(context, {
      action: 'create',
      entityType: 'route',
      entityId: route.id,
      metadata: { assigneeId: route.assigneeId, stopCount: route.stops.length },
    });

    return {
      ...syncItem,
      id: syncItemRef.id,
    };
  }

  /**
   * Queue multiple routes for sync (batch operation)
   */
  async queueRoutesForSync(
    context: SecurityContext,
    routes: Route[]
  ): Promise<SyncResult> {
    const db = getDb();
    const batch = writeBatch(db);
    const errors: string[] = [];
    let queuedCount = 0;

    for (const route of routes) {
      if (!route.assigneeId) {
        errors.push(`Route ${route.id} has no assignee - skipped`);
        continue;
      }

      try {
        const syncItemRef = doc(
          collection(db, 'businesses', context.businessId, 'route_sync_queue')
        );

        const syncItem = {
          businessId: context.businessId,
          routeId: route.id,
          assigneeId: route.assigneeId,
          assigneeName: route.assigneeName ?? '',
          routeDate: Timestamp.fromDate(
            route.date instanceof Timestamp ? route.date.toDate() : route.date
          ),
          status: 'pending' as SyncStatus,
          stopCount: route.stops.length,
          totalDistanceKm: route.totalDistanceKm,
          estimatedDurationMinutes: route.estimatedDurationMinutes,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          notificationSent: false,
        };

        batch.set(syncItemRef, syncItem);
        queuedCount++;
      } catch (err) {
        errors.push(`Failed to queue route ${route.id}: ${err instanceof Error ? err.message : 'Unknown error'}`);
      }
    }

    if (queuedCount > 0) {
      await batch.commit();

      await this.audit.logAction(context, {
        action: 'create',
        entityType: 'route',
        entityId: 'batch',
        metadata: { count: queuedCount },
      });
    }

    return {
      success: errors.length === 0,
      syncedCount: queuedCount,
      failedCount: errors.length,
      errors,
    };
  }

  /**
   * Get pending sync items for a staff member
   */
  async getPendingSyncItems(
    context: SecurityContext,
    assigneeId: string
  ): Promise<RouteSyncItem[]> {
    const db = getDb();
    const q = query(
      collection(db, 'businesses', context.businessId, 'route_sync_queue'),
      where('assigneeId', '==', assigneeId),
      where('status', '==', 'pending')
    );

    const snapshot = await getDocs(q);
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        businessId: data.businessId,
        routeId: data.routeId,
        assigneeId: data.assigneeId,
        assigneeName: data.assigneeName,
        routeDate: data.routeDate?.toDate() ?? new Date(),
        status: data.status,
        stopCount: data.stopCount,
        totalDistanceKm: data.totalDistanceKm,
        estimatedDurationMinutes: data.estimatedDurationMinutes,
        createdAt: data.createdAt?.toDate() ?? new Date(),
        updatedAt: data.updatedAt?.toDate() ?? new Date(),
        syncedAt: data.syncedAt?.toDate(),
        failureReason: data.failureReason,
        notificationSent: data.notificationSent ?? false,
      };
    });
  }

  /**
   * Mark sync item as synced (called by mobile app or Cloud Function)
   */
  async markAsSynced(
    context: SecurityContext,
    syncItemId: string
  ): Promise<void> {
    const db = getDb();
    const syncItemRef = doc(
      db,
      'businesses',
      context.businessId,
      'route_sync_queue',
      syncItemId
    );

    await updateDoc(syncItemRef, {
      status: 'synced',
      syncedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  }

  /**
   * Mark sync item as failed
   */
  async markAsFailed(
    context: SecurityContext,
    syncItemId: string,
    reason: string
  ): Promise<void> {
    const db = getDb();
    const syncItemRef = doc(
      db,
      'businesses',
      context.businessId,
      'route_sync_queue',
      syncItemId
    );

    await updateDoc(syncItemRef, {
      status: 'failed',
      failureReason: reason,
      updatedAt: serverTimestamp(),
    });
  }

  /**
   * Build mobile-friendly route payload
   */
  buildMobilePayload(route: Route): MobileRoutePayload {
    return {
      routeId: route.id,
      name: route.name,
      date: (route.date instanceof Timestamp ? route.date.toDate() : route.date).toISOString().split('T')[0],
      assigneeId: route.assigneeId ?? '',
      assigneeName: route.assigneeName ?? '',
      stops: route.stops.map((stop, index) => this.buildMobileStop(stop, index)),
      status: route.status,
      notes: route.notes as string | undefined,
      totalDistanceKm: route.totalDistanceKm as number | undefined,
      estimatedDurationMinutes: route.estimatedDurationMinutes as number | undefined,
    };
  }

  /**
   * Build mobile-friendly stop payload
   */
  private buildMobileStop(stop: RouteStop, index: number): MobileRouteStop {
    const contact = stop.contact;

    // Build address string
    const addressParts = [];
    if (contact.address?.street) addressParts.push(contact.address.street);
    if (contact.address?.city) addressParts.push(contact.address.city);
    if (contact.address?.state) addressParts.push(contact.address.state);
    if (contact.address?.zipCode) addressParts.push(contact.address.zipCode);

    return {
      order: stop.order ?? index,
      contactId: stop.contactId,
      contactName: `${contact.firstName ?? ''} ${contact.lastName ?? ''}`.trim(),
      companyName: contact.companyName,
      address: addressParts.join(', '),
      latitude: contact.geocodedAddress?.latitude,
      longitude: contact.geocodedAddress?.longitude,
      status: stop.status ?? 'pending',
      notes: stop.notes,
      preferredArrivalStart: stop.preferredArrivalStart?.toISOString(),
      preferredArrivalEnd: stop.preferredArrivalEnd?.toISOString(),
    };
  }

  /**
   * Trigger push notification for route assignment
   * Note: In production, this would call FCM via Cloud Functions
   */
  async sendRouteNotification(
    context: SecurityContext,
    assigneeId: string,
    routeId: string,
    routeName: string,
    stopCount: number
  ): Promise<boolean> {
    // This is a placeholder - in production, call Cloud Function to send FCM notification
    console.log(`[RouteSyncService] Would send notification to ${assigneeId}: "${routeName}" with ${stopCount} stops`);

    // Log the notification attempt
    await this.audit.logAction(context, {
      action: 'update',
      entityType: 'route',
      entityId: routeId,
      metadata: { assigneeId, routeName, stopCount, notification: true },
    });

    return true;
  }

  /**
   * Get sync status for a route
   */
  async getSyncStatus(
    context: SecurityContext,
    routeId: string
  ): Promise<RouteSyncItem | null> {
    const db = getDb();
    const q = query(
      collection(db, 'businesses', context.businessId, 'route_sync_queue'),
      where('routeId', '==', routeId)
    );

    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;

    const doc = snapshot.docs[0];
    const data = doc.data();

    return {
      id: doc.id,
      businessId: data.businessId,
      routeId: data.routeId,
      assigneeId: data.assigneeId,
      assigneeName: data.assigneeName,
      routeDate: data.routeDate?.toDate() ?? new Date(),
      status: data.status,
      stopCount: data.stopCount,
      totalDistanceKm: data.totalDistanceKm,
      estimatedDurationMinutes: data.estimatedDurationMinutes,
      createdAt: data.createdAt?.toDate() ?? new Date(),
      updatedAt: data.updatedAt?.toDate() ?? new Date(),
      syncedAt: data.syncedAt?.toDate(),
      failureReason: data.failureReason,
      notificationSent: data.notificationSent ?? false,
    };
  }
}

// ============================================
// Singleton
// ============================================

let serviceInstance: RouteSyncService | null = null;

export function getRouteSyncService(): RouteSyncService {
  if (!serviceInstance) {
    serviceInstance = new RouteSyncService();
  }
  return serviceInstance;
}

export function resetRouteSyncService(): void {
  serviceInstance = null;
}

export default RouteSyncService;
