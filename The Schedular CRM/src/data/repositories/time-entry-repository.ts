/**
 * Time Entry Repository
 * Manages time entry / punch clock records synced from mobile staff app
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 * Path: businesses/{businessId}/timeEntries/{entryId}
 *
 * Note: Time entries are created by the mobile app. CRM primarily reads and approves/rejects.
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  query,
  where,
  orderBy,
  Timestamp,
  onSnapshot,
} from 'firebase/firestore';
import type { QuerySnapshot, DocumentData, Unsubscribe } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type {
  SecurityContext,
  RepositoryResult,
} from './repository-types';
import {
  NotFoundError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import type { TimeEntry, TimeEntryStatus, BreakPeriod } from '../../types/models';

// ============================================
// Types
// ============================================

export interface TimeEntryFilters {
  staffId?: string;
  status?: TimeEntryStatus;
  dateFrom?: Date;
  dateTo?: Date;
}

// ============================================
// Helper Functions
// ============================================

function convertBreaks(breaks: unknown[]): BreakPeriod[] {
  if (!Array.isArray(breaks)) return [];

  return breaks.map((b) => {
    const breakData = b as Record<string, unknown>;
    return {
      startTime: breakData.startTime instanceof Timestamp
        ? breakData.startTime.toDate()
        : new Date(breakData.startTime as string),
      endTime: breakData.endTime
        ? breakData.endTime instanceof Timestamp
          ? breakData.endTime.toDate()
          : new Date(breakData.endTime as string)
        : undefined,
      type: (breakData.type as 'meal' | 'rest') || 'rest',
    };
  });
}

function docToTimeEntry(id: string, data: DocumentData): TimeEntry {
  return {
    id,
    businessId: data.businessId,
    staffId: data.staffId,
    clockInTime: data.clockInTime instanceof Timestamp
      ? data.clockInTime.toDate()
      : new Date(data.clockInTime),
    clockOutTime: data.clockOutTime
      ? data.clockOutTime instanceof Timestamp
        ? data.clockOutTime.toDate()
        : new Date(data.clockOutTime)
      : undefined,
    clockInLatitude: data.clockInLatitude,
    clockInLongitude: data.clockInLongitude,
    clockInAddress: data.clockInAddress,
    clockInLocationId: data.clockInLocationId,
    clockInOutsideGeofence: data.clockInOutsideGeofence,
    clockOutLatitude: data.clockOutLatitude,
    clockOutLongitude: data.clockOutLongitude,
    clockOutAddress: data.clockOutAddress,
    clockOutLocationId: data.clockOutLocationId,
    clockOutOutsideGeofence: data.clockOutOutsideGeofence,
    breaks: convertBreaks(data.breaks || []),
    totalMinutes: data.totalMinutes,
    breakMinutes: data.breakMinutes,
    workedMinutes: data.workedMinutes,
    status: data.status || 'pending',
    approvedByUserId: data.approvedByUserId,
    approvedAt: data.approvedAt instanceof Timestamp
      ? data.approvedAt.toDate()
      : data.approvedAt
        ? new Date(data.approvedAt)
        : undefined,
    rejectionReason: data.rejectionReason,
    staffNotes: data.staffNotes,
    managerNotes: data.managerNotes,
    createdAt: data.createdAt instanceof Timestamp
      ? data.createdAt.toDate()
      : new Date(data.createdAt),
    updatedAt: data.updatedAt instanceof Timestamp
      ? data.updatedAt.toDate()
      : new Date(data.updatedAt),
  };
}

function snapshotToTimeEntries(snapshot: QuerySnapshot<DocumentData>): TimeEntry[] {
  return snapshot.docs.map((doc) => docToTimeEntry(doc.id, doc.data()));
}

// ============================================
// Time Entry Repository Class
// ============================================

class TimeEntryRepositoryClass {
  private readonly collectionName = 'timeEntries';

  private getCollectionRef(context: SecurityContext) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return collection(db, `${businessPath(context.businessId)}/${this.collectionName}`);
  }

  private getDocRef(context: SecurityContext, id: string) {
    const db = getFirebaseDb();
    if (!db) throw new Error('Firestore not initialized');
    return doc(db, `${businessPath(context.businessId)}/${this.collectionName}`, id);
  }

  /**
   * Check if user can view all time entries (admin/owner/manager)
   */
  private canViewAll(context: SecurityContext): boolean {
    return ['owner', 'admin', 'manager'].includes(context.userRole);
  }

  /**
   * Check if user can approve/reject entries
   */
  private canApprove(context: SecurityContext): boolean {
    return ['owner', 'admin'].includes(context.userRole);
  }

  // ============================================
  // Read Operations
  // ============================================

  /**
   * Get a single time entry by ID
   */
  async getById(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<TimeEntry>> {
    try {
      const docRef = this.getDocRef(context, id);
      const snapshot = await getDoc(docRef);

      if (!snapshot.exists()) {
        return failedResult(new NotFoundError('TimeEntry', id));
      }

      const entry = docToTimeEntry(snapshot.id, snapshot.data());

      // Staff can only view their own entries
      if (!this.canViewAll(context) && entry.staffId !== context.userId) {
        return failedResult(new AuthorizationError('Not authorized to view this entry'));
      }

      return successResult(entry);
    } catch (error) {
      return failedResult(error instanceof Error ? error : new Error('Failed to get time entry'));
    }
  }

  /**
   * Get time entries with filters
   */
  async list(
    context: SecurityContext,
    filters?: TimeEntryFilters
  ): Promise<RepositoryResult<TimeEntry[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const constraints: Parameters<typeof query>[1][] = [];

      // Staff can only see their own entries
      if (!this.canViewAll(context)) {
        constraints.push(where('staffId', '==', context.userId));
      } else if (filters?.staffId) {
        constraints.push(where('staffId', '==', filters.staffId));
      }

      if (filters?.status) {
        constraints.push(where('status', '==', filters.status));
      }

      if (filters?.dateFrom) {
        constraints.push(where('clockInTime', '>=', Timestamp.fromDate(filters.dateFrom)));
      }

      if (filters?.dateTo) {
        constraints.push(where('clockInTime', '<=', Timestamp.fromDate(filters.dateTo)));
      }

      constraints.push(orderBy('clockInTime', 'desc'));

      const q = query(collectionRef, ...constraints);
      const snapshot = await getDocs(q);
      const entries = snapshotToTimeEntries(snapshot);

      return successResult(entries);
    } catch (error) {
      return failedResult(error instanceof Error ? error : new Error('Failed to list time entries'));
    }
  }

  /**
   * Get pending entries (for approval queue)
   */
  async getPendingApprovals(
    context: SecurityContext
  ): Promise<RepositoryResult<TimeEntry[]>> {
    if (!this.canApprove(context)) {
      return failedResult(new AuthorizationError('Not authorized to view pending approvals'));
    }

    return this.list(context, { status: 'pending' });
  }

  /**
   * Get entries for a specific date
   */
  async getForDate(
    context: SecurityContext,
    date: Date
  ): Promise<RepositoryResult<TimeEntry[]>> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return this.list(context, { dateFrom: startOfDay, dateTo: endOfDay });
  }

  /**
   * Get entries for a date range (for timesheet view)
   */
  async getForDateRange(
    context: SecurityContext,
    startDate: Date,
    endDate: Date,
    staffId?: string
  ): Promise<RepositoryResult<TimeEntry[]>> {
    return this.list(context, {
      staffId,
      dateFrom: startDate,
      dateTo: endDate,
    });
  }

  /**
   * Subscribe to time entries (real-time updates)
   */
  subscribe(
    context: SecurityContext,
    callback: (entries: TimeEntry[]) => void,
    filters?: TimeEntryFilters
  ): Unsubscribe {
    const collectionRef = this.getCollectionRef(context);
    const constraints: Parameters<typeof query>[1][] = [];

    if (!this.canViewAll(context)) {
      constraints.push(where('staffId', '==', context.userId));
    } else if (filters?.staffId) {
      constraints.push(where('staffId', '==', filters.staffId));
    }

    if (filters?.status) {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters?.dateFrom) {
      constraints.push(where('clockInTime', '>=', Timestamp.fromDate(filters.dateFrom)));
    }

    if (filters?.dateTo) {
      constraints.push(where('clockInTime', '<=', Timestamp.fromDate(filters.dateTo)));
    }

    constraints.push(orderBy('clockInTime', 'desc'));

    const q = query(collectionRef, ...constraints);

    return onSnapshot(q, (snapshot) => {
      const entries = snapshotToTimeEntries(snapshot);
      callback(entries);
    });
  }

  // ============================================
  // Approval Operations
  // ============================================

  /**
   * Approve a time entry
   */
  async approve(
    context: SecurityContext,
    id: string,
    managerNotes?: string
  ): Promise<RepositoryResult<TimeEntry>> {
    if (!this.canApprove(context)) {
      return failedResult(new AuthorizationError('Not authorized to approve time entries'));
    }

    try {
      const docRef = this.getDocRef(context, id);
      const snapshot = await getDoc(docRef);

      if (!snapshot.exists()) {
        return failedResult(new NotFoundError('TimeEntry', id));
      }

      const data = snapshot.data();
      if (data.status !== 'pending') {
        return failedResult(new Error('Only pending entries can be approved'));
      }

      await updateDoc(docRef, {
        status: 'approved',
        approvedByUserId: context.userId,
        approvedAt: Timestamp.now(),
        managerNotes: managerNotes || data.managerNotes,
        updatedAt: Timestamp.now(),
      });

      // Fetch updated entry
      const updated = await getDoc(docRef);
      return successResult(docToTimeEntry(updated.id, updated.data()!));
    } catch (error) {
      return failedResult(error instanceof Error ? error : new Error('Failed to approve entry'));
    }
  }

  /**
   * Reject a time entry
   */
  async reject(
    context: SecurityContext,
    id: string,
    reason: string,
    managerNotes?: string
  ): Promise<RepositoryResult<TimeEntry>> {
    if (!this.canApprove(context)) {
      return failedResult(new AuthorizationError('Not authorized to reject time entries'));
    }

    if (!reason?.trim()) {
      return failedResult(new Error('Rejection reason is required'));
    }

    try {
      const docRef = this.getDocRef(context, id);
      const snapshot = await getDoc(docRef);

      if (!snapshot.exists()) {
        return failedResult(new NotFoundError('TimeEntry', id));
      }

      const data = snapshot.data();
      if (data.status !== 'pending') {
        return failedResult(new Error('Only pending entries can be rejected'));
      }

      await updateDoc(docRef, {
        status: 'rejected',
        rejectionReason: reason,
        approvedByUserId: context.userId,
        approvedAt: Timestamp.now(),
        managerNotes: managerNotes || data.managerNotes,
        updatedAt: Timestamp.now(),
      });

      // Fetch updated entry
      const updated = await getDoc(docRef);
      return successResult(docToTimeEntry(updated.id, updated.data()!));
    } catch (error) {
      return failedResult(error instanceof Error ? error : new Error('Failed to reject entry'));
    }
  }

  /**
   * Bulk approve multiple entries
   */
  async bulkApprove(
    context: SecurityContext,
    ids: string[]
  ): Promise<RepositoryResult<{ approved: number; failed: number }>> {
    if (!this.canApprove(context)) {
      return failedResult(new AuthorizationError('Not authorized to approve time entries'));
    }

    let approved = 0;
    let failed = 0;

    for (const id of ids) {
      const result = await this.approve(context, id);
      if (result.success) {
        approved++;
      } else {
        failed++;
      }
    }

    return successResult({ approved, failed });
  }
}

// ============================================
// Singleton Export
// ============================================

let instance: TimeEntryRepositoryClass | null = null;

export function getTimeEntryRepository(): TimeEntryRepositoryClass {
  if (!instance) {
    instance = new TimeEntryRepositoryClass();
  }
  return instance;
}

export type { TimeEntryRepositoryClass };
