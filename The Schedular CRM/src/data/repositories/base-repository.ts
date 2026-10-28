/**
 * Base Repository
 * Abstract class providing common CRUD operations for Firestore collections
 *
 * HIPAA Compliance Requirements:
 * - All operations require SecurityContext for multi-tenant isolation
 * - All data access is scoped by businessId
 * - Audit logging is supported via optional AuditLogger
 * - Error messages are sanitized to prevent information leakage
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  writeBatch,
  Timestamp,
  DocumentReference,
  CollectionReference,
} from 'firebase/firestore';
import type { Firestore, DocumentData } from 'firebase/firestore';

import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import {
  getLocalDemoCollection,
  getLocalDemoDocument,
  isLocalDemoDataEnabled,
} from '../demo-store';

import type {
  SecurityContext,
  RepositoryOptions,
  QueryOptions,
  PaginatedResult,
  RepositoryResult,
  BaseEntity,
  SubscriptionCallback,
  Unsubscribe,
  BatchOperation,
  BatchResult,
  AuditLogger,
  AuditLogEntry,
  Validator,
  ValidationResult,
} from './repository-types';

import {
  NotFoundError,
  ValidationError,
  InvalidArgumentError,
  AuthorizationError,
  toRepositoryError,
  failedResult,
  successResult,
} from '../errors/repository-errors';

import type { UserRole } from '../../types/models';

import {
  buildQuery,
  prepareForCreate,
  prepareForUpdate,
  documentToEntity,
  documentsToEntities,
  generateId,
  isValidDocumentId,
  MAX_BATCH_SIZE,
} from './firestore-utils';

/**
 * Abstract base repository class
 * Provides common CRUD operations with multi-tenant isolation
 *
 * @template T - Entity type (must extend BaseEntity)
 */
export abstract class BaseRepository<T extends BaseEntity> {
  protected readonly db: Firestore;
  protected readonly collectionName: string;
  protected readonly softDelete: boolean;
  protected readonly useLocalDemoData: boolean;
  protected auditLogger?: AuditLogger;
  protected validator?: Validator<T>;

  constructor(options: RepositoryOptions) {
    this.useLocalDemoData = isLocalDemoDataEnabled();
    const db = this.useLocalDemoData ? null : getFirebaseDb();
    if (!db) {
      if (!this.useLocalDemoData) {
        throw new Error('Firestore not initialized');
      }
    }
    this.db = db as Firestore;
    this.collectionName = options.collectionName;
    this.softDelete = options.softDelete ?? false;
  }

  /**
   * Set the audit logger for HIPAA compliance
   */
  setAuditLogger(logger: AuditLogger): void {
    this.auditLogger = logger;
  }

  /**
   * Set the validator for entity data
   */
  setValidator(validator: Validator<T>): void {
    this.validator = validator;
  }

  // ============================================
  // Path Helpers
  // ============================================

  /**
   * Validate security context required fields.
   * Throws sanitised error if any field is missing to prevent unauthenticated or cross-tenant access.
   */
  protected ensureSecurityContext(context: SecurityContext): void {
    const missingFields: string[] = [];
    if (!context.businessId?.trim()) missingFields.push('businessId');
    if (!context.userId?.trim()) missingFields.push('userId');
    if (!context.userName?.trim()) missingFields.push('userName');
    if (!context.userRole?.trim()) missingFields.push('userRole');

    if (missingFields.length > 0) {
      throw new InvalidArgumentError(
        `SecurityContext missing required field(s): ${missingFields.join(', ')}`
      );
    }

    if (!context.teamIds) {
      (context as SecurityContext).teamIds = [];
    }
    if (!context.managedTeamIds) {
      (context as SecurityContext).managedTeamIds = [];
    }
  }

  /**
   * Validates that the user has one of the required roles
   * RBAC Enforcement: Repository-layer authorization check
   * @throws AuthorizationError if user role is not in allowedRoles
   */
  protected requireRole(context: SecurityContext, allowedRoles: UserRole[]): void {
    this.ensureSecurityContext(context);

    if (!allowedRoles.includes(context.userRole as UserRole)) {
      throw new AuthorizationError(
        `User with role '${context.userRole}' is not authorized to perform this action. Required: ${allowedRoles.join(' or ')}`
      );
    }
  }

  /**
   * Helper to check if user is admin or owner
   * @returns true if user has admin or owner role
   */
  protected isAdminOrOwner(context: SecurityContext): boolean {
    return context.userRole === 'admin' || context.userRole === 'owner';
  }

  /**
   * Get the collection path scoped by businessId
   */
  protected getCollectionPath(context: SecurityContext): string {
    this.ensureSecurityContext(context);
    return `${businessPath(context.businessId)}/${this.collectionName}`;
  }

  /**
   * Get a collection reference scoped by businessId
   */
  protected getCollectionRef(context: SecurityContext): CollectionReference<DocumentData> {
    return collection(this.db, this.getCollectionPath(context));
  }

  /**
   * Get a document reference scoped by businessId
   */
  protected getDocRef(context: SecurityContext, docId: string): DocumentReference<DocumentData> {
    return doc(this.db, this.getCollectionPath(context), docId);
  }

  protected getLocalDemoPage(
    context: SecurityContext,
    options: QueryOptions = {}
  ): PaginatedResult<T> {
    const result = getLocalDemoCollection<T>(
      context.businessId,
      this.collectionName,
      options
    );
    const data = this.softDelete
      ? result.data.filter((entity) => !entity.isDeleted)
      : result.data;
    return {
      data,
      lastDoc: null,
      hasMore: result.hasMore,
    };
  }

  protected getLocalDemoEntity(context: SecurityContext, id: string): T | null {
    const entity = getLocalDemoDocument<T>(context.businessId, this.collectionName, id);
    if (this.softDelete && entity?.isDeleted) {
      return null;
    }
    return entity;
  }

  protected localDemoMutationResult<TResult>(): RepositoryResult<TResult> {
    return failedResult(
      new AuthorizationError('This action is disabled in demo mode', 'write')
    );
  }

  // ============================================
  // Audit Logging (HIPAA Compliance)
  // ============================================

  /**
   * Log an audit entry - wrapped in try-catch per HIPAA guidelines
   * Failures should not block operations
   */
  protected async logAudit(
    context: SecurityContext,
    action: AuditLogEntry['action'],
    entityId: string | null,
    details?: Record<string, unknown>
  ): Promise<void> {
    const requiresHipaaCompliance = context.requiresHipaaCompliance === true;
    const auditLoggingEnabled = requiresHipaaCompliance || context.auditLoggingEnabled === true;
    if (!auditLoggingEnabled) {
      return;
    }

    if (!this.auditLogger) return;

    try {
      await this.auditLogger.log({
        action,
        entityType: this.collectionName,
        entityId,
        businessId: context.businessId,
        userId: context.userId,
        userName: context.userName,
        timestamp: new Date(),
        details,
        requiresHipaaCompliance,
        auditLoggingEnabled,
      });
    } catch (error) {
      // HIPAA: Audit logging failures should not block operations
      // but should be logged for debugging
      console.error('Audit logging failed:', error);
    }
  }

  // ============================================
  // Validation
  // ============================================

  /**
   * Validate entity data using the configured validator
   */
  protected validate(data: Partial<T>): ValidationResult {
    if (!this.validator) {
      return { isValid: true, errors: [] };
    }
    return this.validator(data);
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /**
   * Get a single entity by ID
   *
   * @param context - Security context with businessId
   * @param id - Document ID
   * @returns Result with entity or error
   */
  async getById(context: SecurityContext, id: string): Promise<RepositoryResult<T>> {
    try {
      this.ensureSecurityContext(context);

      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid document ID', 'id'));
      }

      if (this.useLocalDemoData) {
        const entity = this.getLocalDemoEntity(context, id);
        if (!entity) {
          return failedResult(new NotFoundError(this.collectionName, id));
        }
        return successResult(entity);
      }

      const docRef = this.getDocRef(context, id);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        return failedResult(new NotFoundError(this.collectionName, id));
      }

      const entity = documentToEntity<T>(docSnap);
      if (!entity) {
        return failedResult(new NotFoundError(this.collectionName, id));
      }

      // Check soft delete
      if (this.softDelete && entity.isDeleted) {
        return failedResult(new NotFoundError(this.collectionName, id));
      }

      await this.logAudit(context, 'read', id);

      return successResult(entity);
    } catch (error) {
      return failedResult(error, `Failed to get ${this.collectionName}`);
    }
  }

  /**
   * Get all entities with optional filtering and pagination
   *
   * @param context - Security context with businessId
   * @param options - Query options for filtering, sorting, and pagination
   * @returns Paginated result with entities
   */
  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<T>>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        return successResult(this.getLocalDemoPage(context, options));
      }

      const collectionRef = this.getCollectionRef(context);

      // Add soft delete filter if enabled
      const queryOptions = { ...options };
      if (this.softDelete) {
        queryOptions.where = [
          ...(queryOptions.where || []),
          { field: 'isDeleted', operator: '!=', value: true },
        ];
      }

      // Default ordering by createdAt if not specified
      if (!queryOptions.orderBy) {
        queryOptions.orderBy = { field: 'createdAt', direction: 'desc' };
      }

      const q = buildQuery(collectionRef, queryOptions);
      const querySnapshot = await getDocs(q);

      const entities = documentsToEntities<T>(querySnapshot.docs);
      const lastDoc = querySnapshot.docs[querySnapshot.docs.length - 1] || null;

      // Determine if there are more results
      const hasMore = options.limit ? querySnapshot.docs.length >= options.limit : false;

      await this.logAudit(context, 'list', null, {
        count: entities.length,
        hasMore,
      });

      return successResult({
        data: entities,
        lastDoc,
        hasMore,
      });
    } catch (error) {
      return failedResult(error, `Failed to list ${this.collectionName}`);
    }
  }

  /**
   * Create a new entity
   *
   * @param context - Security context with businessId
   * @param data - Entity data (without id, createdAt)
   * @param customId - Optional custom document ID
   * @returns Result with created entity
   */
  async create(
    context: SecurityContext,
    data: Omit<T, 'id' | 'createdAt' | 'updatedAt'> & Partial<Pick<T, 'createdAt' | 'updatedAt'>>,
    customId?: string
  ): Promise<RepositoryResult<T>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        return this.localDemoMutationResult<T>();
      }

      // Validate data
      const validation = this.validate(data as Partial<T>);
      if (!validation.isValid) {
        return failedResult(ValidationError.fromErrors(validation.errors));
      }

      // Generate or validate ID
      const docId = customId || generateId();
      if (!isValidDocumentId(docId)) {
        return failedResult(new InvalidArgumentError('Invalid document ID', 'id'));
      }

      // Prepare data for Firestore
      const preparedData = prepareForCreate(data as Record<string, unknown>);

      // Create document
      const docRef = this.getDocRef(context, docId);
      await setDoc(docRef, preparedData);

      // Fetch the created document to return
      const result = await this.getById(context, docId);
      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'create', docId);

      return successResult(result.data);
    } catch (error) {
      return failedResult(error, `Failed to create ${this.collectionName}`);
    }
  }

  /**
   * Update an existing entity
   *
   * @param context - Security context with businessId
   * @param id - Document ID
   * @param data - Partial entity data to update
   * @returns Result with updated entity
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<T, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<T>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        return this.localDemoMutationResult<T>();
      }

      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid document ID', 'id'));
      }

      // Verify document exists
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return existing;
      }

      // Validate data
      const validation = this.validate(data as Partial<T>);
      if (!validation.isValid) {
        return failedResult(ValidationError.fromErrors(validation.errors));
      }

      // Prepare data for Firestore
      const preparedData = prepareForUpdate(data as Record<string, unknown>);

      // Update document
      const docRef = this.getDocRef(context, id);
      await updateDoc(docRef, preparedData);

      // Fetch updated document
      const result = await this.getById(context, id);
      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'update', id, { fields: Object.keys(data) });

      return successResult(result.data);
    } catch (error) {
      return failedResult(error, `Failed to update ${this.collectionName}`);
    }
  }

  /**
   * Delete an entity (hard delete or soft delete based on configuration)
   *
   * @param context - Security context with businessId
   * @param id - Document ID
   * @returns Result indicating success or failure
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        return this.localDemoMutationResult<void>();
      }

      if (!isValidDocumentId(id)) {
        return failedResult(new InvalidArgumentError('Invalid document ID', 'id'));
      }

      // Verify document exists
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      const docRef = this.getDocRef(context, id);

      if (this.softDelete) {
        // Soft delete - mark as deleted
        await updateDoc(docRef, {
          isDeleted: true,
          deletedAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        });
      } else {
        // Hard delete
        await deleteDoc(docRef);
      }

      await this.logAudit(context, 'delete', id, { softDelete: this.softDelete });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, `Failed to delete ${this.collectionName}`);
    }
  }

  // ============================================
  // Real-time Subscriptions
  // ============================================

  /**
   * Subscribe to real-time updates for all entities
   *
   * @param context - Security context with businessId
   * @param callback - Function called with updated data
   * @param options - Query options for filtering
   * @returns Unsubscribe function
   */
  subscribe(
    context: SecurityContext,
    callback: SubscriptionCallback<T>,
    options: QueryOptions = {}
  ): Unsubscribe {
    this.ensureSecurityContext(context);

    if (this.useLocalDemoData) {
      callback(this.getLocalDemoPage(context, options).data);
      return () => {};
    }

    const collectionRef = this.getCollectionRef(context);

    // Add soft delete filter if enabled
    const queryOptions = { ...options };
    if (this.softDelete) {
      queryOptions.where = [
        ...(queryOptions.where || []),
        { field: 'isDeleted', operator: '!=', value: true },
      ];
    }

    // Default ordering
    if (!queryOptions.orderBy) {
      queryOptions.orderBy = { field: 'createdAt', direction: 'desc' };
    }

    const q = buildQuery(collectionRef, queryOptions);

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const entities = documentsToEntities<T>(snapshot.docs);
        callback(entities);
      },
      (error) => {
        const repoError = toRepositoryError(error);
        callback([], new Error(repoError.message));
      }
    );

    return unsubscribe;
  }

  /**
   * Subscribe to a single entity
   *
   * @param context - Security context with businessId
   * @param id - Document ID
   * @param callback - Function called with updated entity
   * @returns Unsubscribe function
   */
  subscribeToOne(
    context: SecurityContext,
    id: string,
    callback: (entity: T | null, error?: Error) => void
  ): Unsubscribe {
    try {
      this.ensureSecurityContext(context);
    } catch (err) {
      callback(null, err instanceof Error ? err : new Error('Invalid security context'));
      return () => {};
    }

    if (!isValidDocumentId(id)) {
      callback(null, new Error('Invalid document ID'));
      return () => {};
    }

    if (this.useLocalDemoData) {
      callback(this.getLocalDemoEntity(context, id));
      return () => {};
    }

    const docRef = this.getDocRef(context, id);

    const unsubscribe = onSnapshot(
      docRef,
      (snapshot) => {
        const entity = documentToEntity<T>(snapshot);
        if (this.softDelete && entity?.isDeleted) {
          callback(null);
        } else {
          callback(entity);
        }
      },
      (error) => {
        const repoError = toRepositoryError(error);
        callback(null, new Error(repoError.message));
      }
    );

    return unsubscribe;
  }

  // ============================================
  // Batch Operations
  // ============================================

  /**
   * Execute batch operations atomically
   *
   * @param context - Security context with businessId
   * @param operations - Array of batch operations
   * @returns Result of batch operation
   */
  async batch(
    context: SecurityContext,
    operations: BatchOperation<T>[]
  ): Promise<RepositoryResult<BatchResult>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        return this.localDemoMutationResult<BatchResult>();
      }

      if (operations.length === 0) {
        return successResult({
          success: true,
          successCount: 0,
          failureCount: 0,
        });
      }

      if (operations.length > MAX_BATCH_SIZE) {
        return failedResult(
          new InvalidArgumentError(
            `Batch size ${operations.length} exceeds maximum of ${MAX_BATCH_SIZE}`
          )
        );
      }

      const batch = writeBatch(this.db);
      const createdIds: string[] = [];

      for (const op of operations) {
        switch (op.type) {
          case 'create': {
            const docId = op.id || generateId();
            const docRef = this.getDocRef(context, docId);
            const preparedData = prepareForCreate(op.data as Record<string, unknown>);
            batch.set(docRef, preparedData);
            createdIds.push(docId);
            break;
          }
          case 'update': {
            if (!op.id) {
              return failedResult(new InvalidArgumentError('Update operation requires id'));
            }
            const docRef = this.getDocRef(context, op.id);
            const preparedData = prepareForUpdate(op.data as Record<string, unknown>);
            batch.update(docRef, preparedData);
            break;
          }
          case 'delete': {
            if (!op.id) {
              return failedResult(new InvalidArgumentError('Delete operation requires id'));
            }
            const docRef = this.getDocRef(context, op.id);
            if (this.softDelete) {
              batch.update(docRef, {
                isDeleted: true,
                deletedAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
              });
            } else {
              batch.delete(docRef);
            }
            break;
          }
        }
      }

      await batch.commit();

      await this.logAudit(context, 'batch', null, {
        operationCount: operations.length,
        createdIds,
      });

      return successResult({
        success: true,
        successCount: operations.length,
        failureCount: 0,
        createdIds,
      });
    } catch (error) {
      return failedResult(error, `Batch operation failed for ${this.collectionName}`);
    }
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Check if an entity exists
   *
   * @param context - Security context with businessId
   * @param id - Document ID
   * @returns True if entity exists and is not deleted
   */
  async exists(context: SecurityContext, id: string): Promise<boolean> {
    this.ensureSecurityContext(context);
    const result = await this.getById(context, id);
    return result.success;
  }

  /**
   * Count entities matching query options
   * Note: This fetches all documents - use sparingly
   *
   * @param context - Security context with businessId
   * @param options - Query options for filtering
   * @returns Count of matching entities
   */
  async count(context: SecurityContext, options: QueryOptions = {}): Promise<number> {
    this.ensureSecurityContext(context);
    const result = await this.getAll(context, { ...options, limit: undefined });
    return result.success ? result.data.data.length : 0;
  }
}
