/**
 * useDuplicateDetection Hook
 * React hook for duplicate detection and merge workflows
 *
 * Agent CRM-27 Implementation
 * Dependencies: DuplicateDetectionService
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getDuplicateDetectionService,
  type DuplicateMatch,
  type FindDuplicatesOptions,
  type MergeOptions,
  type MergeResult,
  type EntityType,
} from '../services/DuplicateDetectionService';
import type { Lead, Client, Company } from '../types/models';
import {
  createSecurityContextFromParams,
  getUserManagedTeamIds,
  getUserTeamIds,
  sanitizeTeamIds,
} from '../lib/security-context';

// ============================================
// Types
// ============================================

export type { DuplicateMatch, MergeResult };

export interface ScanAllOptions {
  /** Entity type to scan */
  entityType: EntityType;
  /** Minimum confidence score (default: 70) */
  minConfidence?: number;
}

export interface DuplicateGroup<T = Lead | Client | Company> {
  /** The entity with duplicates */
  entity: T;
  /** List of potential duplicates */
  matches: DuplicateMatch<T>[];
}

export interface UseDuplicateDetectionResult {
  /** Check a single entity for duplicates */
  checkEntity: <T extends Lead | Client | Company>(
    entity: T,
    options: Omit<FindDuplicatesOptions, 'entityType'> & { entityType: EntityType }
  ) => Promise<DuplicateMatch<T>[]>;

  /** Scan all entities of a type for duplicates */
  scanAll: <T extends Lead | Client | Company>(
    entities: T[],
    options: ScanAllOptions
  ) => Promise<DuplicateGroup<T>[]>;

  /** Merge two entities */
  mergeEntities: (options: MergeOptions) => Promise<MergeResult>;

  /** Duplicate matches from last check */
  duplicates: DuplicateMatch[];

  /** Duplicate groups from last scan */
  duplicateGroups: DuplicateGroup[];

  /** True while checking for duplicates */
  isChecking: boolean;

  /** True while scanning all entities */
  isScanning: boolean;

  /** True while merging entities */
  isMerging: boolean;

  /** Error from the last operation */
  error: Error | null;

  /** Clear the error state */
  clearError: () => void;

  /** Clear all duplicate data */
  clearDuplicates: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for duplicate detection and merge workflows
 *
 * @returns Duplicate detection functions, state, and error handling
 *
 * @example
 * ```tsx
 * const {
 *   checkEntity,
 *   mergeEntities,
 *   duplicates,
 *   isChecking,
 *   error,
 * } = useDuplicateDetection();
 *
 * // Check for duplicates on a client
 * const handleCheckDuplicates = async (client: Client) => {
 *   const matches = await checkEntity(client, {
 *     entityType: 'client',
 *     minConfidence: 70,
 *   });
 *
 *   if (matches.length > 0) {
 *     console.log('Found duplicates:', matches);
 *   }
 * };
 *
 * // Merge two clients
 * const handleMerge = async () => {
 *   const result = await mergeEntities({
 *     entityType: 'client',
 *     primaryId: 'client-1',
 *     secondaryId: 'client-2',
 *     fieldPreferences: {
 *       phone: 'secondary',
 *     },
 *     transferRelatedRecords: true,
 *   });
 *
 *   console.log('Merged:', result.merged.id);
 *   console.log('Transferred:', result.recordsTransferred, 'records');
 * };
 * ```
 */
export function useDuplicateDetection(): UseDuplicateDetectionResult {
  const { crmUser, businessId } = useAuth();
  const [duplicates, setDuplicates] = useState<DuplicateMatch[]>([]);
  const [duplicateGroups, setDuplicateGroups] = useState<DuplicateGroup[]>([]);
  const [isChecking, setIsChecking] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [isMerging, setIsMerging] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    const teamIds = sanitizeTeamIds(getUserTeamIds(crmUser));
    const managedTeamIds = sanitizeTeamIds(getUserManagedTeamIds(crmUser));
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName || crmUser.email || 'Unknown User',
      crmUser.role,
      teamIds,
      managedTeamIds,
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  // Clear error
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // Clear duplicates
  const clearDuplicates = useCallback(() => {
    setDuplicates([]);
    setDuplicateGroups([]);
  }, []);

  // Check a single entity for duplicates
  const checkEntity = useCallback(
    async <T extends Lead | Client | Company>(
      entity: T,
      options: Omit<FindDuplicatesOptions, 'entityType'> & { entityType: EntityType }
    ): Promise<DuplicateMatch<T>[]> => {
      setIsChecking(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDuplicateDetectionService();

        const findOptions: FindDuplicatesOptions = {
          entityType: options.entityType,
          minConfidence: options.minConfidence,
          limit: options.limit,
          excludeId: options.excludeId || entity.id,
        };

        const matches = await service.findDuplicates<T>(context, entity, findOptions);
        setDuplicates(matches);
        return matches;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to check for duplicates');
        setError(error);
        setDuplicates([]);
        return [];
      } finally {
        setIsChecking(false);
      }
    },
    [getContext]
  );

  // Scan all entities for duplicates
  const scanAll = useCallback(
    async <T extends Lead | Client | Company>(
      entities: T[],
      options: ScanAllOptions
    ): Promise<DuplicateGroup<T>[]> => {
      setIsScanning(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDuplicateDetectionService();

        const groups: DuplicateGroup<T>[] = [];
        const processedIds = new Set<string>();

        for (const entity of entities) {
          // Skip if already processed as a duplicate
          if (processedIds.has(entity.id)) continue;

          const findOptions: FindDuplicatesOptions = {
            entityType: options.entityType,
            minConfidence: options.minConfidence || 70,
            excludeId: entity.id,
          };

          const matches = await service.findDuplicates<T>(context, entity, findOptions);

          if (matches.length > 0) {
            groups.push({
              entity,
              matches,
            });

            // Mark all matches as processed to avoid duplicate groups
            matches.forEach((match) => processedIds.add(match.entity.id));
          }
        }

        setDuplicateGroups(groups);
        return groups;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to scan for duplicates');
        setError(error);
        setDuplicateGroups([]);
        return [];
      } finally {
        setIsScanning(false);
      }
    },
    [getContext]
  );

  // Merge two entities
  const mergeEntities = useCallback(
    async (options: MergeOptions): Promise<MergeResult> => {
      setIsMerging(true);
      setError(null);

      try {
        const context = getContext();
        const service = getDuplicateDetectionService();

        const result = await service.merge(context, options);

        // Clear duplicates after successful merge
        clearDuplicates();

        return result;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to merge entities');
        setError(error);
        throw error;
      } finally {
        setIsMerging(false);
      }
    },
    [getContext, clearDuplicates]
  );

  return {
    checkEntity,
    scanAll,
    mergeEntities,
    duplicates,
    duplicateGroups,
    isChecking,
    isScanning,
    isMerging,
    error,
    clearError,
    clearDuplicates,
  };
}

export default useDuplicateDetection;
