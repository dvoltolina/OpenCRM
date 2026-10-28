/**
 * Pipeline Repository
 * Manages sales pipeline configurations with multi-tenant isolation
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, writeBatch, Timestamp } from 'firebase/firestore';

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId, documentsToEntities } from './firestore-utils';
import type { Pipeline, Visibility } from '../../types/models';
import { resolveTeamIds, sanitizeTeamIds } from '../../lib/security-context';

const DEFAULT_VISIBILITY: Visibility = 'team';

function normalizeVisibility(value?: Visibility): Visibility {
  if (value === 'private' || value === 'org' || value === 'team') {
    return value;
  }
  return DEFAULT_VISIBILITY;
}

/**
 * Default pipeline stages configuration
 * Used when creating a new default pipeline
 */
export const DEFAULT_STAGES = [
  { name: 'Lead', order: 0, colorHex: '#6B7280', probability: 10 },
  { name: 'Qualified', order: 1, colorHex: '#3B82F6', probability: 25 },
  { name: 'Proposal', order: 2, colorHex: '#8B5CF6', probability: 50 },
  { name: 'Negotiation', order: 3, colorHex: '#F59E0B', probability: 75 },
  { name: 'Won', order: 4, colorHex: '#10B981', probability: 100 },
  { name: 'Lost', order: 5, colorHex: '#EF4444', probability: 0 },
] as const;

/**
 * Pipeline Repository
 * Handles CRUD operations for sales pipelines
 */
export class PipelineRepository extends BaseRepository<Pipeline> {
  constructor() {
    super({ collectionName: 'pipelines' });
  }

  /**
   * Normalize pipeline data with defaults for new ownership fields.
   */
  private normalizePipeline(pipeline: Pipeline): Pipeline {
    return {
      ...pipeline,
      ownerId: pipeline.ownerId || 'unknown-owner',
      ownerName: pipeline.ownerName || 'Unknown Owner',
      teamIds: sanitizeTeamIds(pipeline.teamIds),
      visibility: normalizeVisibility(pipeline.visibility),
    };
  }

  /**
   * Resolve caller team IDs from context or explicit override.
   */
  private getUserTeamIds(context: SecurityContext, teamIds?: string[]): string[] {
    const fallbackTeams = [...(context.teamIds || []), ...(context.managedTeamIds || [])];
    return resolveTeamIds(teamIds, fallbackTeams);
  }

  /**
   * Determine whether the caller can view a pipeline.
   */
  private canAccessPipeline(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): boolean {
    if (this.isAdminOrOwner(context)) return true;
    const visibility = normalizeVisibility(pipeline.visibility);
    if (visibility === 'org') return true;
    const memberships = this.getUserTeamIds(context, teamIds);
    return (
      pipeline.ownerId === context.userId ||
      (pipeline.teamIds || []).some((id) => memberships.includes(id))
    );
  }

  /**
   * Determine whether the caller can modify a pipeline (non-destructive).
   */
  private canWritePipeline(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): boolean {
    if (this.isAdminOrOwner(context)) return true;
    if (!this.canAccessPipeline(context, pipeline, teamIds)) return false;
    const memberships = this.getUserTeamIds(context, teamIds);
    return (
      pipeline.ownerId === context.userId ||
      (pipeline.teamIds || []).some((id) => memberships.includes(id))
    );
  }

  public hasReadAccess(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): boolean {
    return this.canAccessPipeline(context, pipeline, teamIds);
  }

  public hasWriteAccess(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): boolean {
    return this.canWritePipeline(context, pipeline, teamIds);
  }

  /**
   * Apply ownership defaults when creating/updating pipelines.
   * Only admins/owners can override owner fields.
   */
  private withOwnership(
    context: SecurityContext,
    data: Partial<Pipeline>,
    allowOverride: boolean,
    currentOwner?: { ownerId?: string; ownerName?: string; teamIds?: string[]; visibility?: Visibility }
  ): { ownerId: string; ownerName: string; teamIds: string[]; visibility: Visibility } {
    const canOverrideOwner = allowOverride && this.isAdminOrOwner(context);

    const ownerId = canOverrideOwner
      ? data.ownerId || currentOwner?.ownerId || context.userId
      : currentOwner?.ownerId || context.userId;

    const ownerName = canOverrideOwner
      ? data.ownerName || currentOwner?.ownerName || context.userName
      : currentOwner?.ownerName || context.userName;

    const fallbackTeams =
      (Array.isArray(currentOwner?.teamIds) && currentOwner?.teamIds.length
        ? currentOwner.teamIds
        : [...(context.teamIds || []), ...(context.managedTeamIds || [])]) || [];

    const requestedTeams = Array.isArray(data.teamIds) ? data.teamIds : fallbackTeams;
    const teamIds = resolveTeamIds(requestedTeams, fallbackTeams);

    return {
      ownerId,
      ownerName,
      teamIds: sanitizeTeamIds(teamIds),
      visibility: normalizeVisibility(data.visibility ?? currentOwner?.visibility ?? DEFAULT_VISIBILITY),
    };
  }

  /**
   * Create a new pipeline
   * RBAC: Only owner/admin can create pipelines
   */
  async create(
    context: SecurityContext,
    data: Omit<Pipeline, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Pipeline>> {
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return failedResult(new AuthorizationError('Not authorized to create pipelines'));
    }

    // Sales/Staff can create pipelines they will own; admins/owners can override owner/team
    const ownership = this.withOwnership(context, data, true);
    const payload: Omit<Pipeline, 'id' | 'createdAt' | 'updatedAt'> = {
      ...data,
      ...ownership,
      teamIds: ownership.teamIds,
      visibility: ownership.visibility,
    };
    return super.create(context, payload, customId);
  }

  /**
   * Update a pipeline
   * RBAC: Admin/owner can update any; sales/staff can update pipelines they own or are shared to their team
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<Pipeline, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<Pipeline>> {
    if (context.userRole === 'frontDesk' || context.userRole === 'client') {
      return failedResult(new AuthorizationError('Not authorized to update pipelines'));
    }

    // Prevent non-admin overrides of ownership
    if (!this.isAdminOrOwner(context) && (data.ownerId || data.ownerName)) {
      return failedResult(
        new AuthorizationError('Only admins or owners can reassign pipeline ownership')
      );
    }

    const existingResult = await super.getById(context, id);
    if (!existingResult.success) {
      return existingResult;
    }
    const pipeline = this.normalizePipeline(existingResult.data);
    if (!this.canWritePipeline(context, pipeline)) {
      return failedResult(new AuthorizationError('Not authorized to update this pipeline'));
    }

    const ownership = this.withOwnership(context, data, true, pipeline);
    const payload: Partial<Omit<Pipeline, 'id' | 'createdAt'>> = {
      ...data,
      ownerId: ownership.ownerId,
      ownerName: ownership.ownerName,
      teamIds: ownership.teamIds,
      visibility: ownership.visibility,
    };

    const result = await super.update(context, id, payload);
    if (!result.success) {
      return result;
    }
    return successResult(this.normalizePipeline(result.data));
  }

  /**
   * Delete a pipeline
   * RBAC: Only admin/owner can delete pipelines
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    this.requireRole(context, ['owner', 'admin']);
    return super.delete(context, id);
  }

  /**
   * Get pipeline by ID with access enforcement.
   */
  async getById(
    context: SecurityContext,
    id: string,
    teamIds?: string[]
  ): Promise<RepositoryResult<Pipeline>> {
    const result = await super.getById(context, id);
    if (!result.success) {
      return result;
    }

    const pipeline = this.normalizePipeline(result.data);
    if (!this.canAccessPipeline(context, pipeline, teamIds)) {
      return failedResult(new AuthorizationError('Not authorized to access this pipeline'));
    }

    return successResult(pipeline);
  }

  /**
   * Get the default pipeline for the business
   *
   * @param context - Security context with businessId
   * @returns Result with default pipeline or null if none exists
   */
  async getDefault(context: SecurityContext): Promise<RepositoryResult<Pipeline | null>> {
    try {
      if (this.useLocalDemoData) {
        const page = this.getLocalDemoPage(context, {
          where: [
            { field: 'isDefault', operator: '==', value: true },
            { field: 'isActive', operator: '==', value: true },
          ],
          limit: 1,
        });
        const raw = page.data[0];
        if (!raw) {
          return successResult(null);
        }
        const pipeline = this.normalizePipeline(raw);
        return this.canAccessPipeline(context, pipeline)
          ? successResult(pipeline)
          : successResult(null);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'isDefault', operator: '==', value: true },
          { field: 'isActive', operator: '==', value: true },
        ],
        limit: 1,
      });

      const querySnapshot = await getDocs(q);

      if (querySnapshot.empty) {
        return successResult(null);
      }

      const [raw] = documentsToEntities<Pipeline>(querySnapshot.docs);
      if (!raw) {
        return successResult(null);
      }
      const pipeline = this.normalizePipeline(raw);

      if (!this.canAccessPipeline(context, pipeline)) {
        return successResult(null);
      }

      await this.logAudit(context, 'read', pipeline.id, { action: 'getDefault' });

      return successResult(pipeline);
    } catch (error) {
      return failedResult(error, 'Failed to get default pipeline');
    }
  }

  /**
   * Set a pipeline as the default (unsets any existing default)
   * RBAC: Only owner/admin can set default pipeline
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of pipeline to set as default
   * @returns Result with updated pipeline
   */
  async setDefault(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<Pipeline>> {
    try {
      this.requireRole(context, ['owner', 'admin']);

      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      // Verify the pipeline exists and is active
      const existingResult = await this.getById(context, pipelineId);
      if (!existingResult.success) {
        return existingResult;
      }

      if (!existingResult.data.isActive) {
        return failedResult(
          new InvalidArgumentError('Cannot set inactive pipeline as default', 'pipelineId')
        );
      }

      // Get current default pipeline(s) to unset
      const collectionRef = this.getCollectionRef(context);
      const currentDefaultQuery = buildQuery(collectionRef, {
        where: [{ field: 'isDefault', operator: '==', value: true }],
      });
      const currentDefaults = await getDocs(currentDefaultQuery);

      // Use batch to atomically update
      const batch = writeBatch(this.db);

      // Unset existing defaults
      for (const doc of currentDefaults.docs) {
        if (doc.id !== pipelineId) {
          batch.update(doc.ref, {
            isDefault: false,
            updatedAt: Timestamp.now(),
          });
        }
      }

      // Set new default
      const newDefaultRef = this.getDocRef(context, pipelineId);
      batch.update(newDefaultRef, {
        isDefault: true,
        updatedAt: Timestamp.now(),
      });

      await batch.commit();

      // Fetch and return updated pipeline
      const result = await this.getById(context, pipelineId);
      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'update', pipelineId, { action: 'setDefault' });

      return successResult(result.data);
    } catch (error) {
      return failedResult(error, 'Failed to set default pipeline');
    }
  }

  /**
   * Get all active pipelines for the business
   *
   * @param context - Security context with businessId
   * @returns Result with list of active pipelines
   */
  async getActive(
    context: SecurityContext,
    teamIds?: string[]
  ): Promise<RepositoryResult<PaginatedResult<Pipeline>>> {
    try {
      const resolvedTeams = this.getUserTeamIds(context, teamIds);
      if (this.useLocalDemoData) {
        const page = this.getLocalDemoPage(context, {
          where: [{ field: 'isActive', operator: '==', value: true }],
          orderBy: { field: 'name', direction: 'asc' },
        });
        const data = page.data
          .map((pipeline) => this.normalizePipeline(pipeline))
          .filter((pipeline) => this.canAccessPipeline(context, pipeline, resolvedTeams));
        return successResult({
          data,
          lastDoc: null,
          hasMore: false,
        });
      }

      const collectionRef = this.getCollectionRef(context);

      // Admins/owners can list all active pipelines.
      if (this.isAdminOrOwner(context)) {
        const adminQuery = buildQuery(collectionRef, {
          where: [{ field: 'isActive', operator: '==', value: true }],
          orderBy: { field: 'name', direction: 'asc' },
        });
        const snapshot = await getDocs(adminQuery);
        const normalized = documentsToEntities<Pipeline>(snapshot.docs)
          .map((p) => this.normalizePipeline(p))
          .filter((p) => p.isActive);
        return successResult({
          data: normalized,
          lastDoc: null,
          hasMore: false,
        });
      }

      // Staff/sales: fetch owned pipelines + team-shared pipelines only.
      const ownedQuery = buildQuery(collectionRef, {
        where: [
          { field: 'isActive', operator: '==', value: true },
          { field: 'ownerId', operator: '==', value: context.userId },
        ],
        orderBy: { field: 'name', direction: 'asc' },
      });
      const ownedSnapshot = await getDocs(ownedQuery);
      const owned = documentsToEntities<Pipeline>(ownedSnapshot.docs);

      let shared: Pipeline[] = [];
      if (resolvedTeams.length > 0) {
        const limitedTeams = resolvedTeams.slice(0, 10); // Firestore array-contains-any max
        const sharedQuery = buildQuery(collectionRef, {
          where: [
            { field: 'isActive', operator: '==', value: true },
            { field: 'teamIds', operator: 'array-contains-any', value: limitedTeams },
          ],
          orderBy: { field: 'name', direction: 'asc' },
        });
        const sharedSnapshot = await getDocs(sharedQuery);
        shared = documentsToEntities<Pipeline>(sharedSnapshot.docs);
      }

      const mergedMap = new Map<string, Pipeline>();
      [...owned, ...shared].forEach((pipeline) => {
        const normalized = this.normalizePipeline(pipeline);
        if (normalized.isActive && this.canAccessPipeline(context, normalized, resolvedTeams)) {
          mergedMap.set(normalized.id, normalized);
        }
      });

      const data = Array.from(mergedMap.values()).sort((a, b) =>
        a.name.localeCompare(b.name)
      );

      return successResult({
        data,
        lastDoc: null,
        hasMore: false,
      });
    } catch (error) {
      return failedResult(error, 'Failed to get active pipelines');
    }
  }

  /**
   * Archive a pipeline (soft archive by setting isActive to false)
   * Cannot archive if it's the only active pipeline
   * RBAC: Only owner/admin can archive pipelines
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of pipeline to archive
   * @returns Result indicating success
   */
  async archive(context: SecurityContext, pipelineId: string): Promise<RepositoryResult<Pipeline>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      // Verify pipeline exists
      const existingResult = await this.getById(context, pipelineId);
      if (!existingResult.success) {
        return existingResult;
      }

      const pipeline = this.normalizePipeline(existingResult.data);

      if (!this.canWritePipeline(context, pipeline)) {
        return failedResult(new AuthorizationError('Not authorized to archive this pipeline'));
      }

      // Check if this is the only active pipeline
      const activeResult = await this.getActive(context);
      if (activeResult.success && activeResult.data.data.length <= 1) {
        return failedResult(
          new InvalidArgumentError('Cannot archive the only active pipeline', 'pipelineId')
        );
      }

      // If this is the default pipeline, need to set a new default
      if (pipeline.isDefault) {
        // Find another active pipeline to set as default
        if (activeResult.success && activeResult.data) { // Added null check for activeResult.data
          const otherActive = activeResult.data.data.find((p) => p.id !== pipelineId);
          if (otherActive) {
            await this.setDefault(context, otherActive.id);
          }
        }
      }

      // Archive the pipeline
      const result = await this.update(context, pipelineId, {
        isActive: false,
        isDefault: false,
      });

      if (result.success) {
        await this.logAudit(context, 'update', pipelineId, { action: 'archive' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to archive pipeline');
    }
  }

  /**
   * Restore an archived pipeline
   * RBAC: Only owner/admin can restore pipelines
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of pipeline to restore
   * @returns Result with restored pipeline
   */
  async restore(context: SecurityContext, pipelineId: string): Promise<RepositoryResult<Pipeline>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      // Verify pipeline exists
      const existingResult = await this.getById(context, pipelineId);
      if (!existingResult.success) {
        return existingResult;
      }

      if (!this.canWritePipeline(context, existingResult.data)) {
        return failedResult(new AuthorizationError('Not authorized to restore this pipeline'));
      }

      // Restore the pipeline
      const result = await this.update(context, pipelineId, {
        isActive: true,
      });

      if (result.success) {
        await this.logAudit(context, 'update', pipelineId, { action: 'restore' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to restore pipeline');
    }
  }

  /**
   * Check if a pipeline can be deleted (no active deals)
   * Note: This is a placeholder - actual deal check should be done by DealRepository
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of pipeline to check
   * @returns True if pipeline can be safely deleted
   */
  async canDelete(context: SecurityContext, pipelineId: string): Promise<boolean> {
    // This will be implemented properly when DealRepository is available
    // For now, just check if the pipeline exists
    const result = await this.getById(context, pipelineId);
    return result.success;
  }
}

// Export singleton instance for convenience
let pipelineRepository: PipelineRepository | null = null;

export function getPipelineRepository(): PipelineRepository {
  if (!pipelineRepository) {
    pipelineRepository = new PipelineRepository();
  }
  return pipelineRepository;
}
