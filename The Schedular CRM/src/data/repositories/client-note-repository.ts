/**
 * Client Note Repository
 * Manages client notes with bidirectional sync support for Flutter app
 *
 * This collection is shared between CRM and Flutter:
 * - CRM can create, read, update, delete own notes
 * - Flutter Sales View can create and read notes
 * - Notes sync bidirectionally
 *
 * Also provides read-only access to Job Notes (created by Flutter providers)
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp, orderBy, where, query, collection } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { documentsToEntities } from './firestore-utils';
import { businessPath } from '../../lib/collections';
import type { ShareableFields } from '../../types/models';

// ============================================
// Types
// ============================================

export type ClientNoteType = 'call' | 'meeting' | 'email' | 'followUp' | 'other';

export interface ClientNote extends ShareableFields {
  id: string;
  businessId: string;
  clientId: string;
  content: string;
  type: ClientNoteType;
  createdByUserId: string;
  createdByName: string;
  createdAt: Date;
  updatedAt?: Date;
}

export type JobNoteType = 'preJob' | 'completion' | 'followUp';

/**
 * Job Notes are created by providers in the Flutter app
 * They are read-only in the CRM
 */
export interface JobNote {
  id: string;
  businessId: string;
  appointmentId: string;
  clientId: string;
  locationAddress?: string;
  providerId: string;
  providerName: string;
  serviceId: string;
  serviceName: string;
  noteContent: string;
  type: JobNoteType;
  photoUrls: string[];
  checklistItems?: Record<string, boolean>;
  createdAt: Date;
}

export interface ClientNoteFilters {
  clientId?: string;
  type?: ClientNoteType;
  createdByUserId?: string;
  dateRange?: { start: Date; end: Date };
}

export interface JobNoteFilters {
  clientId?: string;
  appointmentId?: string;
  providerId?: string;
  type?: JobNoteType;
  dateRange?: { start: Date; end: Date };
}

// ============================================
// Validation
// ============================================

const clientNoteValidator: Validator<ClientNote> = (data: Partial<ClientNote>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.clientId?.trim()) {
    errors.push({ field: 'clientId', message: 'Client ID is required', code: 'REQUIRED' });
  }

  if (!data.content?.trim()) {
    errors.push({ field: 'content', message: 'Note content is required', code: 'REQUIRED' });
  }

  if (data.content && data.content.length > 10000) {
    errors.push({ field: 'content', message: 'Note content must be less than 10,000 characters', code: 'MAX_LENGTH' });
  }

  const validTypes: ClientNoteType[] = ['call', 'meeting', 'email', 'followUp', 'other'];
  if (data.type && !validTypes.includes(data.type)) {
    errors.push({ field: 'type', message: 'Invalid note type', code: 'INVALID_VALUE' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Client Note Repository
// ============================================

export class ClientNoteRepository extends ShareableRepository<ClientNote> {
  protected entityName = 'clientNote';

  constructor() {
    super({
      collectionName: 'clientNotes',
      softDelete: false,
    });
    this.setValidator(clientNoteValidator);
  }

  /**
   * Get all notes for a specific client
   */
  async getByClientId(
    context: SecurityContext,
    clientId: string,
    options?: { limit?: number; orderDirection?: 'asc' | 'desc' }
  ): Promise<RepositoryResult<ClientNote[]>> {
    try {
      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('Client ID is required', 'clientId'));
      }

      const collRef = this.getCollectionRef(context);
      const constraints = [
        where('clientId', '==', clientId),
        orderBy('createdAt', options?.orderDirection || 'desc'),
      ];

      const q = query(collRef, ...constraints);
      const snapshot = await getDocs(q);

      const notes = documentsToEntities<ClientNote>(snapshot.docs);
      const filteredNotes = filterAuthorizedEntities(context, notes, []);

      const limited = options?.limit ? filteredNotes.slice(0, options.limit) : filteredNotes;

      return successResult(limited);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get notes with filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: ClientNoteFilters,
    options?: { limit?: number; offset?: number }
  ): Promise<RepositoryResult<PaginatedResult<ClientNote>>> {
    try {
      const collRef = this.getCollectionRef(context);
      const constraints: Parameters<typeof query>[1][] = [];

      if (filters.clientId) {
        constraints.push(where('clientId', '==', filters.clientId));
      }

      if (filters.type) {
        constraints.push(where('type', '==', filters.type));
      }

      if (filters.createdByUserId) {
        constraints.push(where('createdByUserId', '==', filters.createdByUserId));
      }

      constraints.push(orderBy('createdAt', 'desc'));

      const q = query(collRef, ...constraints);
      const snapshot = await getDocs(q);

      let notes = documentsToEntities<ClientNote>(snapshot.docs);
      notes = filterAuthorizedEntities(context, notes, []);

      // Apply date range filter (in-memory since Firestore can't do range + equality on different fields)
      if (filters.dateRange) {
        notes = notes.filter((note) => {
          const createdAt = note.createdAt;
          return createdAt >= filters.dateRange!.start && createdAt <= filters.dateRange!.end;
        });
      }

      const total = notes.length;
      const offset = options?.offset || 0;
      const limit = options?.limit || 50;
      const paginatedNotes = notes.slice(offset, offset + limit);

      return successResult({
        data: paginatedNotes,
        lastDoc: null,
        hasMore: offset + limit < total,
        totalCount: total,
      });
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Create a new client note
   */
  async createNote(
    context: SecurityContext,
    data: Omit<ClientNote, 'id' | 'businessId' | 'createdAt' | 'createdByUserId' | 'createdByName'>
  ): Promise<RepositoryResult<ClientNote>> {
    const noteData: Partial<ClientNote> = {
      ...data,
      createdByUserId: context.userId,
      createdByName: context.userName,
      ownerId: context.userId,
      ownerName: context.userName,
      teamIds: context.teamIds || [],
      visibility: 'org', // Notes are visible to entire org by default
    };

    return this.create(context, noteData as ClientNote);
  }

  /**
   * Update own note (only owner can update)
   */
  async updateNote(
    context: SecurityContext,
    noteId: string,
    updates: Pick<ClientNote, 'content' | 'type'>
  ): Promise<RepositoryResult<ClientNote>> {
    // First check ownership
    const existing = await this.getById(context, noteId);
    if (!existing.success) {
      return existing;
    }

    if (existing.data.createdByUserId !== context.userId && !this.isAdminOrOwner(context)) {
      return failedResult(new AuthorizationError('You can only edit your own notes'));
    }

    return this.update(context, noteId, updates);
  }

  /**
   * Delete own note (only owner or admin can delete)
   */
  async deleteNote(
    context: SecurityContext,
    noteId: string
  ): Promise<RepositoryResult<void>> {
    const existing = await this.getById(context, noteId);
    if (!existing.success) {
      return { success: false, data: null, error: existing.error };
    }

    if (existing.data.createdByUserId !== context.userId && !this.isAdminOrOwner(context)) {
      return { success: false, data: null, error: new AuthorizationError('You can only delete your own notes') };
    }

    return this.delete(context, noteId);
  }

  /**
   * Get recent notes across all clients (for dashboard/activity feed)
   */
  async getRecent(
    context: SecurityContext,
    limit: number = 10
  ): Promise<RepositoryResult<ClientNote[]>> {
    try {
      const collRef = this.getCollectionRef(context);
      const q = query(
        collRef,
        orderBy('createdAt', 'desc')
      );
      const snapshot = await getDocs(q);

      let notes = documentsToEntities<ClientNote>(snapshot.docs);
      notes = filterAuthorizedEntities(context, notes, []);

      return successResult(notes.slice(0, limit));
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  protected isAdminOrOwner(context: SecurityContext): boolean {
    return context.userRole === 'admin' || context.userRole === 'owner';
  }
}

// ============================================
// Job Note Repository (Read-Only)
// ============================================

/**
 * Job Note Repository
 * Provides read-only access to job notes created by providers in Flutter
 */
export class JobNoteRepository {
  private readonly collectionName = 'jobNotes';

  /**
   * Get all job notes for a specific client
   */
  async getByClientId(
    context: SecurityContext,
    clientId: string,
    options?: { limit?: number }
  ): Promise<RepositoryResult<JobNote[]>> {
    try {
      if (!clientId?.trim()) {
        return failedResult(new InvalidArgumentError('Client ID is required', 'clientId'));
      }

      const { getFirebaseDb } = await import('../../lib/firebase');
      const db = getFirebaseDb();
      if (!db) {
        return failedResult(new Error('Firestore not initialized'));
      }

      const collRef = collection(db, businessPath(context.businessId), this.collectionName);
      const q = query(
        collRef,
        where('clientId', '==', clientId),
        orderBy('createdAt', 'desc')
      );
      const snapshot = await getDocs(q);

      const notes = this.documentsToJobNotes(snapshot);
      const limited = options?.limit ? notes.slice(0, options.limit) : notes;

      return successResult(limited);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get job notes for a specific appointment
   */
  async getByAppointmentId(
    context: SecurityContext,
    appointmentId: string
  ): Promise<RepositoryResult<JobNote[]>> {
    try {
      if (!appointmentId?.trim()) {
        return failedResult(new InvalidArgumentError('Appointment ID is required', 'appointmentId'));
      }

      const { getFirebaseDb } = await import('../../lib/firebase');
      const db = getFirebaseDb();
      if (!db) {
        return failedResult(new Error('Firestore not initialized'));
      }

      const collRef = collection(db, businessPath(context.businessId), this.collectionName);
      const q = query(
        collRef,
        where('appointmentId', '==', appointmentId),
        orderBy('createdAt', 'desc')
      );
      const snapshot = await getDocs(q);

      const notes = this.documentsToJobNotes(snapshot);

      return successResult(notes);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  /**
   * Get recent job notes (for client service history)
   */
  async getFiltered(
    context: SecurityContext,
    filters: JobNoteFilters,
    options?: { limit?: number }
  ): Promise<RepositoryResult<JobNote[]>> {
    try {
      const { getFirebaseDb } = await import('../../lib/firebase');
      const db = getFirebaseDb();
      if (!db) {
        return failedResult(new Error('Firestore not initialized'));
      }

      const collRef = collection(db, businessPath(context.businessId), this.collectionName);
      const constraints: Parameters<typeof query>[1][] = [];

      if (filters.clientId) {
        constraints.push(where('clientId', '==', filters.clientId));
      }

      if (filters.appointmentId) {
        constraints.push(where('appointmentId', '==', filters.appointmentId));
      }

      if (filters.providerId) {
        constraints.push(where('providerId', '==', filters.providerId));
      }

      if (filters.type) {
        constraints.push(where('type', '==', filters.type));
      }

      constraints.push(orderBy('createdAt', 'desc'));

      const q = query(collRef, ...constraints);
      const snapshot = await getDocs(q);

      let notes = this.documentsToJobNotes(snapshot);

      // Apply date range filter in-memory
      if (filters.dateRange) {
        notes = notes.filter((note) => {
          const createdAt = note.createdAt;
          return createdAt >= filters.dateRange!.start && createdAt <= filters.dateRange!.end;
        });
      }

      const limited = options?.limit ? notes.slice(0, options.limit) : notes;

      return successResult(limited);
    } catch (error) {
      return failedResult(error as Error);
    }
  }

  private documentsToJobNotes(snapshot: QuerySnapshot<DocumentData>): JobNote[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        businessId: data.businessId,
        appointmentId: data.appointmentId,
        clientId: data.clientId,
        locationAddress: data.locationAddress,
        providerId: data.providerId,
        providerName: data.providerName,
        serviceId: data.serviceId,
        serviceName: data.serviceName,
        noteContent: data.noteContent,
        type: data.type,
        photoUrls: data.photoUrls || [],
        checklistItems: data.checklistItems,
        createdAt: data.createdAt instanceof Timestamp ? data.createdAt.toDate() : new Date(data.createdAt),
      };
    });
  }
}

// ============================================
// Singleton Instances
// ============================================

let clientNoteRepositoryInstance: ClientNoteRepository | null = null;
let jobNoteRepositoryInstance: JobNoteRepository | null = null;

export function getClientNoteRepository(): ClientNoteRepository {
  if (!clientNoteRepositoryInstance) {
    clientNoteRepositoryInstance = new ClientNoteRepository();
  }
  return clientNoteRepositoryInstance;
}

export function getJobNoteRepository(): JobNoteRepository {
  if (!jobNoteRepositoryInstance) {
    jobNoteRepositoryInstance = new JobNoteRepository();
  }
  return jobNoteRepositoryInstance;
}
