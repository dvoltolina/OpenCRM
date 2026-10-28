/**
 * Route Repository
 * Manages route planning records for CRM field sales
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 * Path: businesses/{businessId}/routes/{routeId}
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  ValidationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type { Route, RouteStatus, RouteStop, Client } from '../../types/models';

// ============================================
// Types
// ============================================

export interface RouteFilters {
  status?: RouteStatus;
  assigneeId?: string;
  dateFrom?: Date;
  dateTo?: Date;
}

// ============================================
// Validation
// ============================================

const routeValidator: Validator<Route> = (data: Partial<Route>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({ field: 'name', message: 'Route name is required', code: 'REQUIRED' });
  }

  if (data.date !== undefined && !(data.date instanceof Date) && typeof data.date !== 'object') {
    errors.push({ field: 'date', message: 'Valid date is required', code: 'INVALID_FORMAT' });
  }

  if (data.stops !== undefined) {
    if (!Array.isArray(data.stops)) {
      errors.push({ field: 'stops', message: 'Stops must be an array', code: 'INVALID_FORMAT' });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateRouteCreate: Validator<Route> = (data: Partial<Route>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.name?.trim()) {
    errors.push({ field: 'name', message: 'Route name is required', code: 'REQUIRED' });
  }

  if (!data.date) {
    errors.push({ field: 'date', message: 'Route date is required', code: 'REQUIRED' });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Route Repository
// ============================================

/**
 * Route Repository
 * Handles CRUD operations for route planning records
 */
export class RouteRepository extends ShareableRepository<Route> {
  protected entityName = 'route';
  protected sensitiveFields: Array<keyof Route> = [];

  constructor() {
    super({ collectionName: 'routes' });
    this.setValidator(routeValidator);
  }

  async create(
    context: SecurityContext,
    data: Omit<Route, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Route>> {
    const validation = validateRouteCreate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Set defaults
    const routeData = {
      ...data,
      businessId: context.businessId,
      status: data.status || 'draft',
      stops: data.stops || [],
      createdBy: context.userId,
      createdByName: context.userName,
    };

    return super.create(context, routeData, customId);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get routes by date range
   */
  async getByDateRange(
    context: SecurityContext,
    startDate: Date,
    endDate: Date
  ): Promise<RepositoryResult<Route[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'date', operator: '>=', value: Timestamp.fromDate(startDate) },
          { field: 'date', operator: '<=', value: Timestamp.fromDate(endDate) },
        ],
        orderBy: { field: 'date', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const routes = this.filterAccessibleRoutes(context, this.snapshotToRoutes(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByDateRange',
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
      });

      return successResult(routes);
    } catch (error) {
      return failedResult(error, 'Failed to get routes by date range');
    }
  }

  /**
   * Get routes by date (single day)
   */
  async getByDate(
    context: SecurityContext,
    date: Date
  ): Promise<RepositoryResult<Route[]>> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return this.getByDateRange(context, startOfDay, endOfDay);
  }

  /**
   * Get routes by assignee
   */
  async getByAssignee(
    context: SecurityContext,
    assigneeId: string
  ): Promise<RepositoryResult<Route[]>> {
    try {
      if (!isValidDocumentId(assigneeId)) {
        return failedResult(new InvalidArgumentError('Invalid assignee ID', 'assigneeId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'assigneeId', operator: '==', value: assigneeId }],
        orderBy: { field: 'date', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const routes = this.filterAccessibleRoutes(context, this.snapshotToRoutes(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByAssignee', assigneeId });

      return successResult(routes);
    } catch (error) {
      return failedResult(error, 'Failed to get routes by assignee');
    }
  }

  /**
   * Get routes by status
   */
  async getByStatus(
    context: SecurityContext,
    status: RouteStatus
  ): Promise<RepositoryResult<Route[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: status }],
        orderBy: { field: 'date', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const routes = this.filterAccessibleRoutes(context, this.snapshotToRoutes(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByStatus', status });

      return successResult(routes);
    } catch (error) {
      return failedResult(error, 'Failed to get routes by status');
    }
  }

  /**
   * Get routes with combined filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: RouteFilters
  ): Promise<RepositoryResult<Route[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'date', direction: 'desc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      let filtered = allResult.data.data;

      if (filters.status) {
        filtered = filtered.filter((r) => r.status === filters.status);
      }

      if (filters.assigneeId) {
        filtered = filtered.filter((r) => r.assigneeId === filters.assigneeId);
      }

      if (filters.dateFrom) {
        filtered = filtered.filter((r) => r.date >= filters.dateFrom!);
      }

      if (filters.dateTo) {
        filtered = filtered.filter((r) => r.date <= filters.dateTo!);
      }

      await this.logAudit(context, 'list', null, { action: 'getFiltered', filters });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to get filtered routes');
    }
  }

  // ============================================
  // Stop Management
  // ============================================

  /**
   * Add a stop to a route
   */
  async addStop(
    context: SecurityContext,
    routeId: string,
    stop: Omit<RouteStop, 'order'>
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      const existingResult = await this.getById(context, routeId);
      if (!existingResult.success) {
        return existingResult;
      }

      const route = existingResult.data;
      const newStop: RouteStop = {
        ...stop,
        order: route.stops.length,
        status: 'pending',
      };

      const updatedStops = [...route.stops, newStop];
      return this.update(context, routeId, { stops: updatedStops });
    } catch (error) {
      return failedResult(error, 'Failed to add stop');
    }
  }

  /**
   * Remove a stop from a route
   */
  async removeStop(
    context: SecurityContext,
    routeId: string,
    contactId: string
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      const existingResult = await this.getById(context, routeId);
      if (!existingResult.success) {
        return existingResult;
      }

      const route = existingResult.data;
      const updatedStops = route.stops
        .filter((s) => s.contactId !== contactId)
        .map((s, index) => ({ ...s, order: index }));

      return this.update(context, routeId, { stops: updatedStops });
    } catch (error) {
      return failedResult(error, 'Failed to remove stop');
    }
  }

  /**
   * Reorder stops in a route
   */
  async reorderStops(
    context: SecurityContext,
    routeId: string,
    newOrder: string[] // Array of contactIds in new order
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      const existingResult = await this.getById(context, routeId);
      if (!existingResult.success) {
        return existingResult;
      }

      const route = existingResult.data;
      const stopMap = new Map(route.stops.map((s) => [s.contactId, s]));

      const reorderedStops: RouteStop[] = [];
      for (let i = 0; i < newOrder.length; i++) {
        const stop = stopMap.get(newOrder[i]);
        if (stop) {
          reorderedStops.push({ ...stop, order: i });
        }
      }

      return this.update(context, routeId, { stops: reorderedStops });
    } catch (error) {
      return failedResult(error, 'Failed to reorder stops');
    }
  }

  /**
   * Update stop status (mark as completed/skipped)
   */
  async updateStopStatus(
    context: SecurityContext,
    routeId: string,
    contactId: string,
    status: 'pending' | 'completed' | 'skipped'
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      const existingResult = await this.getById(context, routeId);
      if (!existingResult.success) {
        return existingResult;
      }

      const route = existingResult.data;
      const updatedStops = route.stops.map((s) => {
        if (s.contactId === contactId) {
          return {
            ...s,
            status,
            completedAt: status === 'completed' ? new Date() : undefined,
          };
        }
        return s;
      });

      return this.update(context, routeId, { stops: updatedStops });
    } catch (error) {
      return failedResult(error, 'Failed to update stop status');
    }
  }

  // ============================================
  // Status Management
  // ============================================

  /**
   * Update route status
   */
  async updateStatus(
    context: SecurityContext,
    routeId: string,
    status: RouteStatus
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      return this.update(context, routeId, { status });
    } catch (error) {
      return failedResult(error, 'Failed to update status');
    }
  }

  /**
   * Mark route as optimized with distance/duration data
   */
  async markOptimized(
    context: SecurityContext,
    routeId: string,
    optimizationData: {
      stops: RouteStop[];
      totalDistanceKm: number;
      totalDurationMinutes: number;
    }
  ): Promise<RepositoryResult<Route>> {
    try {
      if (!isValidDocumentId(routeId)) {
        return failedResult(new InvalidArgumentError('Invalid route ID', 'routeId'));
      }

      return this.update(context, routeId, {
        stops: optimizationData.stops,
        totalDistanceKm: optimizationData.totalDistanceKm,
        totalDurationMinutes: optimizationData.totalDurationMinutes,
        optimizedAt: new Date(),
        status: 'planned',
      });
    } catch (error) {
      return failedResult(error, 'Failed to mark route as optimized');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleRoutes(context: SecurityContext, routes: Route[]): Route[] {
    return filterAuthorizedEntities(context, routes, this.sensitiveFields);
  }

  private snapshotToRoutes(snapshot: QuerySnapshot<DocumentData>): Route[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as Route['visibility']) ?? 'team';
      const ownerId = (data.ownerId as string | undefined) ?? undefined;
      const ownerName = (data.ownerName as string | undefined) ?? undefined;

      // Parse stops with embedded contact data
      const stops: RouteStop[] = Array.isArray(data.stops)
        ? data.stops.map((stop: Record<string, unknown>) => ({
            contactId: stop.contactId as string,
            contact: stop.contact as Client,
            order: stop.order as number,
            estimatedArrival: stop.estimatedArrival
              ? (stop.estimatedArrival as { toDate: () => Date }).toDate?.() || undefined
              : undefined,
            estimatedDuration: stop.estimatedDuration as number | undefined,
            notes: stop.notes as string | undefined,
            status: (stop.status as RouteStop['status']) ?? 'pending',
            completedAt: stop.completedAt
              ? (stop.completedAt as { toDate: () => Date }).toDate?.() || undefined
              : undefined,
          }))
        : [];

      return {
        id: doc.id,
        businessId: data.businessId as string,
        name: data.name as string,
        date: data.date?.toDate?.() || new Date(),
        assigneeId: data.assigneeId as string | undefined,
        assigneeName: data.assigneeName as string | undefined,
        stops,
        status: (data.status as RouteStatus) || 'draft',
        totalDistanceKm: data.totalDistanceKm as number | undefined,
        totalDurationMinutes: data.totalDurationMinutes as number | undefined,
        optimizedAt: data.optimizedAt?.toDate?.() || undefined,
        startLatitude: data.startLatitude as number | undefined,
        startLongitude: data.startLongitude as number | undefined,
        startAddress: data.startAddress as string | undefined,
        ownerId,
        ownerName,
        teamIds,
        visibility,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
        createdBy: data.createdBy as string,
        createdByName: data.createdByName as string | undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let routeRepository: RouteRepository | null = null;

export function getRouteRepository(): RouteRepository {
  if (!routeRepository) {
    routeRepository = new RouteRepository();
  }
  return routeRepository;
}
