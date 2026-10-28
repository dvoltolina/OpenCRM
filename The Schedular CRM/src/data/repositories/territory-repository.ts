/**
 * Territory Repository
 * Manages territory records for route planning
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 * Path: businesses/{businessId}/territories/{territoryId}
 */

import { getDocs } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository } from './access-control';
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
import type {
  Territory,
  TerritoryBoundary,
  TerritoryAssignment,
  TerritoryBoundaryType,
} from '../../types/models';

// ============================================
// Types
// ============================================

export interface TerritoryFilters {
  isActive?: boolean;
  staffId?: string;
  boundaryType?: TerritoryBoundaryType;
}

// ============================================
// Validation
// ============================================

const territoryValidator: Validator<Territory> = (
  data: Partial<Territory>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({
      field: 'name',
      message: 'Territory name is required',
      code: 'REQUIRED',
    });
  }

  if (data.boundary !== undefined) {
    if (!data.boundary.type) {
      errors.push({
        field: 'boundary.type',
        message: 'Boundary type is required',
        code: 'REQUIRED',
      });
    }
  }

  if (data.colorHex !== undefined && !data.colorHex?.trim()) {
    errors.push({
      field: 'colorHex',
      message: 'Color is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateTerritoryCreate: Validator<Territory> = (
  data: Partial<Territory>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.name?.trim()) {
    errors.push({
      field: 'name',
      message: 'Territory name is required',
      code: 'REQUIRED',
    });
  }

  if (!data.boundary) {
    errors.push({
      field: 'boundary',
      message: 'Boundary definition is required',
      code: 'REQUIRED',
    });
  } else if (!data.boundary.type) {
    errors.push({
      field: 'boundary.type',
      message: 'Boundary type is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Helper Functions
// ============================================

/**
 * Generate a random hex color for territory visualization
 */
export function generateTerritoryColor(): string {
  const colors = [
    '#3b82f6', // blue
    '#10b981', // green
    '#f59e0b', // amber
    '#ef4444', // red
    '#8b5cf6', // violet
    '#ec4899', // pink
    '#06b6d4', // cyan
    '#84cc16', // lime
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

/**
 * Check if a point is inside a polygon using ray casting algorithm
 */
export function pointInPolygon(
  lat: number,
  lng: number,
  polygon: Array<[number, number]>
): boolean {
  if (polygon.length < 3) return false;

  let inside = false;
  const n = polygon.length;

  for (let i = 0, j = n - 1; i < n; j = i++) {
    const [xi, yi] = polygon[i]; // [lng, lat]
    const [xj, yj] = polygon[j];

    // Note: polygon uses [lng, lat] format, so yi/yj are latitudes, xi/xj are longitudes
    const intersect =
      yi > lat !== yj > lat && lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi;

    if (intersect) {
      inside = !inside;
    }
  }

  return inside;
}

/**
 * Haversine distance between two points in kilometers
 */
export function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Check if a location is within a territory boundary
 */
export function isLocationInTerritory(
  territory: Territory,
  latitude: number,
  longitude: number
): boolean {
  const { boundary } = territory;

  switch (boundary.type) {
    case 'zip_codes':
      // Can't check by lat/lng for zip codes - use isZipCodeInTerritory instead
      return false;

    case 'polygon':
      if (!boundary.polygonCoordinates || boundary.polygonCoordinates.length < 3) {
        return false;
      }
      return pointInPolygon(latitude, longitude, boundary.polygonCoordinates);

    case 'radius':
      if (
        boundary.centerLatitude === undefined ||
        boundary.centerLongitude === undefined ||
        boundary.radiusKm === undefined
      ) {
        return false;
      }
      const distance = haversineDistance(
        boundary.centerLatitude,
        boundary.centerLongitude,
        latitude,
        longitude
      );
      return distance <= boundary.radiusKm;

    default:
      return false;
  }
}

/**
 * Check if a zip code is within a territory boundary
 */
export function isZipCodeInTerritory(territory: Territory, zipCode: string): boolean {
  const { boundary } = territory;

  if (boundary.type !== 'zip_codes' || !boundary.zipCodes) {
    return false;
  }

  return boundary.zipCodes.includes(zipCode);
}

// ============================================
// Territory Repository
// ============================================

export class TerritoryRepository extends ShareableRepository<Territory> {
  protected entityName = 'territory';
  protected sensitiveFields: Array<keyof Territory> = [];

  constructor() {
    super({ collectionName: 'territories' });
    this.setValidator(territoryValidator);
  }

  async create(
    context: SecurityContext,
    data: Omit<Territory, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Territory>> {
    const validation = validateTerritoryCreate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Set defaults
    const territoryData = {
      ...data,
      businessId: context.businessId,
      colorHex: data.colorHex ?? generateTerritoryColor(),
      assignments: data.assignments ?? [],
      enableAutoSuggestion: data.enableAutoSuggestion ?? true,
      loadBalancingEnabled: data.loadBalancingEnabled ?? false,
      isActive: data.isActive ?? true,
      createdBy: context.userId,
      createdByName: context.userName,
    };

    return super.create(context, territoryData, customId);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all active territories
   */
  async getActive(context: SecurityContext): Promise<RepositoryResult<Territory[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'isActive', operator: '==', value: true }],
        orderBy: { field: 'name', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const territories = this.snapshotToTerritories(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getActive',
        count: territories.length,
      });

      return successResult(territories);
    } catch (error) {
      return failedResult(error, 'Failed to get active territories');
    }
  }

  /**
   * Get all territories (including inactive)
   */
  async getAllTerritories(
    context: SecurityContext
  ): Promise<RepositoryResult<Territory[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      return successResult(allResult.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get all territories');
    }
  }

  /**
   * Get territories assigned to a specific staff member
   */
  async getByStaffId(
    context: SecurityContext,
    staffId: string
  ): Promise<RepositoryResult<Territory[]>> {
    try {
      if (!isValidDocumentId(staffId)) {
        return failedResult(new InvalidArgumentError('Invalid staff ID', 'staffId'));
      }

      // Get all territories and filter by assignment
      // (Firestore doesn't support querying nested array properties efficiently)
      const allResult = await this.getActive(context);
      if (!allResult.success) {
        return allResult;
      }

      const staffTerritories = allResult.data.filter((t) =>
        t.assignments.some((a) => a.staffId === staffId)
      );

      await this.logAudit(context, 'list', null, {
        action: 'getByStaffId',
        staffId,
        count: staffTerritories.length,
      });

      return successResult(staffTerritories);
    } catch (error) {
      return failedResult(error, 'Failed to get territories by staff ID');
    }
  }

  /**
   * Find territory containing a location
   */
  async findByLocation(
    context: SecurityContext,
    latitude: number,
    longitude: number
  ): Promise<RepositoryResult<Territory | null>> {
    try {
      const activeResult = await this.getActive(context);
      if (!activeResult.success) {
        return { success: false, data: null, error: activeResult.error };
      }

      const matchingTerritory = activeResult.data.find((t) =>
        isLocationInTerritory(t, latitude, longitude)
      );

      await this.logAudit(context, 'read', matchingTerritory?.id ?? null, {
        action: 'findByLocation',
        latitude,
        longitude,
      });

      return successResult(matchingTerritory ?? null);
    } catch (error) {
      return failedResult(error, 'Failed to find territory by location');
    }
  }

  /**
   * Find territory by zip code
   */
  async findByZipCode(
    context: SecurityContext,
    zipCode: string
  ): Promise<RepositoryResult<Territory | null>> {
    try {
      const activeResult = await this.getActive(context);
      if (!activeResult.success) {
        return { success: false, data: null, error: activeResult.error };
      }

      const matchingTerritory = activeResult.data.find((t) =>
        isZipCodeInTerritory(t, zipCode)
      );

      await this.logAudit(context, 'read', matchingTerritory?.id ?? null, {
        action: 'findByZipCode',
        zipCode,
      });

      return successResult(matchingTerritory ?? null);
    } catch (error) {
      return failedResult(error, 'Failed to find territory by zip code');
    }
  }

  // ============================================
  // Assignment Management
  // ============================================

  /**
   * Update staff assignments for a territory
   */
  async updateAssignments(
    context: SecurityContext,
    territoryId: string,
    assignments: TerritoryAssignment[]
  ): Promise<RepositoryResult<Territory>> {
    try {
      if (!isValidDocumentId(territoryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid territory ID', 'territoryId')
        );
      }

      return this.update(context, territoryId, { assignments });
    } catch (error) {
      return failedResult(error, 'Failed to update assignments');
    }
  }

  /**
   * Add a staff member to a territory
   */
  async addAssignment(
    context: SecurityContext,
    territoryId: string,
    assignment: TerritoryAssignment
  ): Promise<RepositoryResult<Territory>> {
    try {
      if (!isValidDocumentId(territoryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid territory ID', 'territoryId')
        );
      }

      const existingResult = await this.getById(context, territoryId);
      if (!existingResult.success) {
        return existingResult;
      }

      const territory = existingResult.data;

      // Check if already assigned
      if (territory.assignments.some((a) => a.staffId === assignment.staffId)) {
        return failedResult(
          new InvalidArgumentError('Staff is already assigned to this territory')
        );
      }

      const updatedAssignments = [...territory.assignments, assignment];
      return this.update(context, territoryId, { assignments: updatedAssignments });
    } catch (error) {
      return failedResult(error, 'Failed to add assignment');
    }
  }

  /**
   * Remove a staff member from a territory
   */
  async removeAssignment(
    context: SecurityContext,
    territoryId: string,
    staffId: string
  ): Promise<RepositoryResult<Territory>> {
    try {
      if (!isValidDocumentId(territoryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid territory ID', 'territoryId')
        );
      }

      const existingResult = await this.getById(context, territoryId);
      if (!existingResult.success) {
        return existingResult;
      }

      const territory = existingResult.data;
      const updatedAssignments = territory.assignments.filter(
        (a) => a.staffId !== staffId
      );

      return this.update(context, territoryId, { assignments: updatedAssignments });
    } catch (error) {
      return failedResult(error, 'Failed to remove assignment');
    }
  }

  /**
   * Update contact count cache for a territory
   */
  async updateContactCount(
    context: SecurityContext,
    territoryId: string,
    count: number
  ): Promise<RepositoryResult<Territory>> {
    try {
      if (!isValidDocumentId(territoryId)) {
        return failedResult(
          new InvalidArgumentError('Invalid territory ID', 'territoryId')
        );
      }

      return this.update(context, territoryId, { contactCount: count });
    } catch (error) {
      return failedResult(error, 'Failed to update contact count');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private snapshotToTerritories(snapshot: QuerySnapshot<DocumentData>): Territory[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as Territory['visibility']) ?? 'team';

      // Parse boundary
      const boundaryData = data.boundary as Record<string, unknown> | undefined;
      const boundary: TerritoryBoundary = boundaryData
        ? {
            type: boundaryData.type as TerritoryBoundaryType,
            zipCodes: Array.isArray(boundaryData.zipCodes)
              ? boundaryData.zipCodes
              : undefined,
            polygonCoordinates: Array.isArray(boundaryData.polygonCoordinates)
              ? boundaryData.polygonCoordinates
              : undefined,
            centerLatitude: boundaryData.centerLatitude as number | undefined,
            centerLongitude: boundaryData.centerLongitude as number | undefined,
            radiusKm: boundaryData.radiusKm as number | undefined,
          }
        : { type: 'zip_codes', zipCodes: [] };

      // Parse assignments
      const assignments: TerritoryAssignment[] = Array.isArray(data.assignments)
        ? data.assignments.map((a: Record<string, unknown>) => ({
            staffId: String(a.staffId ?? ''),
            staffName: String(a.staffName ?? ''),
            isPrimary: Boolean(a.isPrimary),
            priority: Number(a.priority ?? 1),
          }))
        : [];

      return {
        id: doc.id,
        businessId: data.businessId as string,
        name: data.name as string,
        description: data.description as string | undefined,
        colorHex: (data.colorHex as string) ?? '#3b82f6',
        boundary,
        assignments,
        enableAutoSuggestion: Boolean(data.enableAutoSuggestion ?? true),
        loadBalancingEnabled: Boolean(data.loadBalancingEnabled),
        isActive: Boolean(data.isActive ?? true),
        contactCount: data.contactCount as number | undefined,
        ownerId: data.ownerId as string | undefined,
        ownerName: data.ownerName as string | undefined,
        teamIds,
        visibility,
        createdAt: data.createdAt?.toDate?.() ?? new Date(),
        updatedAt: data.updatedAt?.toDate?.() ?? undefined,
        createdBy: data.createdBy as string,
        createdByName: data.createdByName as string | undefined,
      };
    });
  }
}

// Export singleton instance
let territoryRepository: TerritoryRepository | null = null;

export function getTerritoryRepository(): TerritoryRepository {
  if (!territoryRepository) {
    territoryRepository = new TerritoryRepository();
  }
  return territoryRepository;
}
