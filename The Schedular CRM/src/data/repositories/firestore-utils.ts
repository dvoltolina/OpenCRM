/**
 * Firestore Utilities
 * Helper functions for Firestore operations
 *
 * HIPAA Compliance: These utilities ensure consistent data handling
 * and prevent accidental exposure of sensitive information through
 * proper timestamp conversion and data sanitization.
 */

import type {
  Query,
  DocumentData,
  CollectionReference,
  DocumentSnapshot,
  Firestore, // Added Firestore
} from 'firebase/firestore';
import {
  where,
  orderBy,
  limit,
  startAfter,
  Timestamp,
  query,
  collection,
} from 'firebase/firestore';
import type { QueryOptions, WhereClause, OrderByClause } from './repository-types';

// ============================================
// Query Building
// ============================================

/**
 * Build a Firestore query from QueryOptions
 * Applies where clauses, ordering, pagination, and limits
 */
export function buildQuery<T extends DocumentData>(
  collectionRef: CollectionReference<T>,
  options: QueryOptions = {}
): Query<T> {
  const constraints: Parameters<typeof query>[1][] = [];

  // Apply where clauses
  if (options.where && options.where.length > 0) {
    for (const clause of options.where) {
      constraints.push(where(clause.field, clause.operator as any, clause.value));
    }
  }

  // Apply ordering - primary orderBy
  if (options.orderBy) {
    constraints.push(orderBy(options.orderBy.field, options.orderBy.direction));
  }

  // Apply additional orderBy clauses
  if (options.orderByMultiple && options.orderByMultiple.length > 0) {
    for (const clause of options.orderByMultiple) {
      constraints.push(orderBy(clause.field, clause.direction));
    }
  }

  // Apply pagination cursor
  if (options.startAfter) {
    constraints.push(startAfter(options.startAfter));
  }

  // Apply limit
  if (options.limit && options.limit > 0) {
    constraints.push(limit(options.limit));
  }

  return query(collectionRef, ...constraints);
}

/**
 * Create where clause helper
 */
export function createWhereClause(
  field: string,
  operator: WhereClause['operator'],
  value: unknown
): WhereClause {
  return { field, operator, value };
}

/**
 * Create orderBy clause helper
 */
export function createOrderBy(
  field: string,
  direction: OrderByClause['direction'] = 'asc'
): OrderByClause {
  return { field, direction };
}

// ============================================
// Timestamp Conversion
// ============================================

/**
 * Check if a value is a Firestore Timestamp (duck typing for testability)
 */
function isTimestamp(value: unknown): value is { toDate: () => Date; seconds: number; nanoseconds: number } {
  return (
    value !== null &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate: unknown }).toDate === 'function' &&
    'seconds' in value &&
    'nanoseconds' in value
  );
}

/**
 * Convert Firestore Timestamp to JavaScript Date
 * Handles both Timestamp objects and already-converted Dates
 */
export function timestampToDate(value: Timestamp | Date | undefined | null): Date | undefined {
  if (!value) return undefined;
  if (value instanceof Date) {
    return value;
  }
  // Use duck typing for Timestamp check (works with mocks)
  if (isTimestamp(value)) {
    return value.toDate();
  }
  // Handle serialized timestamp objects (from JSON)
  if (typeof value === 'object' && 'seconds' in value && 'nanoseconds' in value) {
    return new Date((value as { seconds: number }).seconds * 1000);
  }
  return undefined;
}

/**
 * Convert JavaScript Date to Firestore Timestamp
 */
export function dateToTimestamp(value: Date | undefined | null): Timestamp | undefined {
  if (!value) return undefined;
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  return undefined;
}

/**
 * Convert all Date fields in an object to Timestamps for Firestore
 */
export function datesToTimestamps<T extends Record<string, unknown>>(
  data: T
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(data)) {
    if (value instanceof Date) {
      result[key] = Timestamp.fromDate(value);
    } else if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      // Recursively handle nested objects
      result[key] = datesToTimestamps(value as Record<string, unknown>);
    } else {
      result[key] = value;
    }
  }

  return result;
}

/**
 * Convert all Timestamp fields in a Firestore document to Dates
 */
export function timestampsToDates<T extends Record<string, unknown>>(
  data: T
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(data)) {
    // Already a Date
    if (value instanceof Date) {
      result[key] = value;
    }
    // Timestamp with toDate method (duck typing for testability)
    else if (isTimestamp(value)) {
      result[key] = value.toDate();
    }
    // Serialized timestamp object (from JSON)
    else if (
      value !== null &&
      typeof value === 'object' &&
      'seconds' in value &&
      'nanoseconds' in value
    ) {
      result[key] = new Date((value as { seconds: number }).seconds * 1000);
    }
    // Recursively handle nested objects (but not arrays or null)
    else if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      result[key] = timestampsToDates(value as Record<string, unknown>);
    }
    // Pass through all other values
    else {
      result[key] = value;
    }
  }

  return result;
}

// ============================================
// Data Sanitization
// ============================================

/**
 * Remove undefined fields from an object before saving to Firestore
 * Firestore does not accept undefined values
 */
export function sanitizeForFirestore<T extends Record<string, unknown>>(
  data: T
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(data)) {
    // Skip undefined values
    if (value === undefined) {
      continue;
    }

    // Convert Dates to Timestamps
    if (value instanceof Date) {
      result[key] = Timestamp.fromDate(value);
      continue;
    }

    // Recursively handle nested objects (but not arrays or null)
    if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      const nested = sanitizeForFirestore(value as Record<string, unknown>);
      // Only include if nested object has values
      if (Object.keys(nested).length > 0) {
        result[key] = nested;
      }
      continue;
    }

    // Include all other values (including null and arrays)
    result[key] = value;
  }

  return result;
}

/**
 * Prepare data for creation - adds timestamps and removes id
 */
export function prepareForCreate<T extends Record<string, unknown>>(
  data: T
): Record<string, unknown> {
  const sanitized = sanitizeForFirestore(data);

  // Remove id field - Firestore will generate or use provided doc ID
  delete sanitized.id;

  // Add creation timestamp
  sanitized.createdAt = Timestamp.now();

  return sanitized;
}

/**
 * Prepare data for update - adds updatedAt timestamp
 */
export function prepareForUpdate<T extends Record<string, unknown>>(
  data: T
): Record<string, unknown> {
  const sanitized = sanitizeForFirestore(data);

  // Remove fields that shouldn't be updated
  delete sanitized.id;
  delete sanitized.createdAt;

  // Add update timestamp
  sanitized.updatedAt = Timestamp.now();

  return sanitized;
}

// ============================================
// ID Generation
// ============================================

/**
 * Generate a Firestore-compatible document ID
 * Uses the same character set as Firestore auto-generated IDs
 */
export function generateId(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let id = '';
  for (let i = 0; i < 20; i++) {
    id += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return id;
}

/**
 * Validate that a string is a valid Firestore document ID
 */
export function isValidDocumentId(id: string): boolean {
  if (!id || typeof id !== 'string') {
    return false;
  }
  // Firestore IDs must be non-empty, less than 1500 bytes, and not contain /
  if (id.length === 0 || id.length > 1500) {
    return false;
  }
  if (id.includes('/')) {
    return false;
  }
  // Cannot be . or ..
  if (id === '.' || id === '..') {
    return false;
  }
  return true;
}

// ============================================
// Document Conversion
// ============================================

/**
 * Convert a Firestore document snapshot to a typed entity
 * Includes the document ID and converts timestamps to dates
 */
export function documentToEntity<T extends { id: string }>(
  doc: DocumentSnapshot
): T | null {
  if (!doc.exists()) {
    return null;
  }

  const data = doc.data();
  if (!data) {
    return null;
  }

  // Convert timestamps to dates and add ID
  const converted = timestampsToDates(data as Record<string, unknown>);

  return {
    ...converted,
    id: doc.id,
  } as T;
}

/**
 * Convert multiple document snapshots to typed entities
 */
export function documentsToEntities<T extends { id: string }>(
  docs: DocumentSnapshot[]
): T[] {
  return docs
    .map(doc => documentToEntity<T>(doc))
    .filter((entity): entity is T => entity !== null);
}

// ============================================
// Collection Reference Helpers
// ============================================

/**
 * Get a typed collection reference
 */
export function getTypedCollection<T extends DocumentData>(
  db: Firestore,
  path: string
): CollectionReference<T> {
  return collection(db, path) as CollectionReference<T>;
}

// ============================================
// Batch Size Constants
// ============================================

/**
 * Maximum batch size for Firestore batch writes
 */
export const MAX_BATCH_SIZE = 500;

/**
 * Recommended batch size for optimal performance
 */
export const RECOMMENDED_BATCH_SIZE = 100;

/**
 * Maximum number of documents for in queries
 */
export const MAX_IN_QUERY_SIZE = 30;
