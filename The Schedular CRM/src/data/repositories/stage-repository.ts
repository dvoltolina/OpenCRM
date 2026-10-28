/**
 * Stage Repository
 * Manages pipeline stage configurations with ordering support
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, writeBatch, Timestamp } from 'firebase/firestore';

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId, generateId } from './firestore-utils';
import type { Stage, Pipeline, Visibility } from '../../types/models';
import { getPipelineRepository } from './pipeline-repository';
import { resolveTeamIds, sanitizeTeamIds } from '../../lib/security-context';

const DEFAULT_VISIBILITY: Visibility = 'team';

function normalizeVisibility(value?: Visibility): Visibility {
  if (value === 'private' || value === 'org' || value === 'team') {
    return value;
  }
  return DEFAULT_VISIBILITY;
}

/**
 * Stage Repository
 * Handles CRUD operations for pipeline stages with ordering support
 */
export class StageRepository extends BaseRepository<Stage> {
  constructor() {
    super({ collectionName: 'stages' });
  }

  private inheritOwnershipFromPipeline(
    pipeline: Pipeline,
    stage: Partial<Stage>
  ): Partial<Stage> {
    return {
      ...stage,
      ownerId: pipeline.ownerId,
      ownerName: pipeline.ownerName,
      teamIds: sanitizeTeamIds(stage.teamIds ?? pipeline.teamIds ?? []),
      visibility: normalizeVisibility(stage.visibility ?? (pipeline.visibility as Visibility)),
    };
  }

  private normalizeStage(pipeline: Pipeline, stage: Stage): Stage {
    const owned = this.inheritOwnershipFromPipeline(pipeline, stage);
    return {
      ...stage,
      ownerId: owned.ownerId || pipeline.ownerId,
      ownerName: owned.ownerName || pipeline.ownerName,
      teamIds: sanitizeTeamIds(owned.teamIds),
      visibility: normalizeVisibility(owned.visibility as Visibility),
    };
  }

  private async getPipelineForAccess(
    context: SecurityContext,
    pipelineId: string,
    teamIds?: string[]
  ): Promise<RepositoryResult<Pipeline>> {
    const pipelineRepo = getPipelineRepository();
    return pipelineRepo.getById(context, pipelineId, teamIds);
  }

  // Utility method for future use with team-based queries
  protected getUserTeamIds(context: SecurityContext, teamIds?: string[]): string[] {
    return resolveTeamIds(teamIds, context.teamIds || []);
  }

  private ensurePipelineReadAccess(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): RepositoryResult<Pipeline> {
    const pipelineRepo = getPipelineRepository();
    const canRead = pipelineRepo.hasReadAccess(context, pipeline, teamIds);
    return canRead
      ? { success: true, data: pipeline, error: null }
      : failedResult(new AuthorizationError('Not authorized to view this pipeline'));
  }

  private ensurePipelineWriteAccess(
    context: SecurityContext,
    pipeline: Pipeline,
    teamIds?: string[]
  ): RepositoryResult<Pipeline> {
    const pipelineRepo = getPipelineRepository();
    const canWrite = pipelineRepo.hasWriteAccess(context, pipeline, teamIds);
    return canWrite
      ? { success: true, data: pipeline, error: null }
      : failedResult(new AuthorizationError('Not authorized to modify this pipeline'));
  }

  /**
   * Create a new stage
   * RBAC: Caller must have access to the parent pipeline
   */
  async create(
    context: SecurityContext,
    data: Omit<Stage, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage>> {
    const pipelineResult = await this.getPipelineForAccess(context, data.pipelineId as string, teamIds);
    if (!pipelineResult.success) {
      return { success: false, data: null, error: pipelineResult.error };
    }
    const accessResult = this.ensurePipelineWriteAccess(context, pipelineResult.data, teamIds);
    if (!accessResult.success) {
      return accessResult;
    }
    const stageWithOwnership = this.inheritOwnershipFromPipeline(pipelineResult.data, data);
    const result = await super.create(
      context,
      stageWithOwnership as Omit<Stage, 'id' | 'createdAt' | 'updatedAt'>,
      customId
    );
    if (!result.success) {
      return result;
    }
    return successResult(this.normalizeStage(pipelineResult.data, result.data));
  }

  /**
   * Get a stage by ID with pipeline access enforcement.
   */
  async getById(
    context: SecurityContext,
    id: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage>> {
    const result = await super.getById(context, id);
    if (!result.success) {
      return result;
    }

    const pipelineResult = await this.getPipelineForAccess(
      context,
      result.data.pipelineId,
      teamIds
    );
    if (!pipelineResult.success) {
      return { success: false, data: null, error: pipelineResult.error };
    }

    return successResult(this.normalizeStage(pipelineResult.data, result.data));
  }

  /**
   * Update a stage
   * RBAC: Caller must have access to the parent pipeline
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<Stage, 'id' | 'createdAt'>>,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage>> {
    const stageResult = await this.getById(context, id, teamIds);
    if (!stageResult.success) {
      return stageResult;
    }
    const pipelineResult = await this.getPipelineForAccess(
      context,
      stageResult.data.pipelineId,
      teamIds
    );
    if (!pipelineResult.success) {
      return { success: false, data: null, error: pipelineResult.error };
    }
    const accessResult = this.ensurePipelineWriteAccess(context, pipelineResult.data, teamIds);
    if (!accessResult.success) {
      return accessResult;
    }
    const updates = this.inheritOwnershipFromPipeline(pipelineResult.data, data);
    const result = await super.update(context, id, updates);
    if (!result.success) {
      return result;
    }
    return successResult(this.normalizeStage(pipelineResult.data, result.data));
  }

  /**
   * Delete a stage
   * RBAC: Only owner can delete stages
   */
  async delete(
    context: SecurityContext,
    id: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<void>> {
    const stageResult = await this.getById(context, id, teamIds);
    if (!stageResult.success) {
      return { success: false, data: null, error: stageResult.error };
    }
    const pipelineResult = await this.getPipelineForAccess(
      context,
      stageResult.data.pipelineId,
      teamIds
    );
    if (!pipelineResult.success) {
      return { success: false, data: null, error: pipelineResult.error };
    }
    const accessResult = this.ensurePipelineWriteAccess(context, pipelineResult.data, teamIds);
    if (!accessResult.success) {
      return { success: false, data: null, error: accessResult.error };
    }
    return super.delete(context, id);
  }

  /**
   * Get all stages for a pipeline, ordered by the 'order' field
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of the pipeline
   * @returns Result with ordered list of stages
   */
  async getByPipeline(
    context: SecurityContext,
    pipelineId: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      const pipelineResult = await this.getPipelineForAccess(context, pipelineId, teamIds);
      if (!pipelineResult.success) {
        return { success: false, data: null, error: pipelineResult.error };
      }
      const accessResult = this.ensurePipelineReadAccess(context, pipelineResult.data, teamIds);
      if (!accessResult.success) {
        return accessResult;
      }

      if (this.useLocalDemoData) {
        const stages = this.getLocalDemoPage(context, {
          where: [{ field: 'pipelineId', operator: '==', value: pipelineId }],
          orderBy: { field: 'order', direction: 'asc' },
        }).data.map((stage) => this.normalizeStage(pipelineResult.data, stage));
        return successResult(stages);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'pipelineId', operator: '==', value: pipelineId }],
        orderBy: { field: 'order', direction: 'asc' },
      });

      const querySnapshot = await getDocs(q);

      const stages: Stage[] = querySnapshot.docs
        .map((doc) => {
          const data = doc.data();
          const stage: Stage = {
            id: doc.id,
            pipelineId: data.pipelineId,
            name: data.name,
            order: data.order,
            colorHex: data.colorHex,
            probability: data.probability,
            isActive: data.isActive,
            ownerId: data.ownerId,
            ownerName: data.ownerName,
            teamIds: data.teamIds,
            visibility: data.visibility,
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate(),
          };
          return this.normalizeStage(pipelineResult.data, stage);
        })
        .filter((stage) => stage.pipelineId === pipelineId);

      await this.logAudit(context, 'list', null, {
        action: 'getByPipeline',
        pipelineId,
        count: stages.length,
      });

      return successResult(stages);
    } catch (error) {
      return failedResult(error, 'Failed to get stages by pipeline');
    }
  }

  /**
   * Get only active stages for a pipeline, ordered by the 'order' field
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of the pipeline
   * @returns Result with ordered list of active stages
   */
  async getActiveByPipeline(
    context: SecurityContext,
    pipelineId: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      const pipelineResult = await this.getPipelineForAccess(context, pipelineId, teamIds);
      if (!pipelineResult.success) {
        return { success: false, data: null, error: pipelineResult.error };
      }
      const accessResult = this.ensurePipelineReadAccess(context, pipelineResult.data, teamIds);
      if (!accessResult.success) {
        return accessResult;
      }

      if (this.useLocalDemoData) {
        const stages = this.getLocalDemoPage(context, {
          where: [
            { field: 'pipelineId', operator: '==', value: pipelineId },
            { field: 'isActive', operator: '==', value: true },
          ],
          orderBy: { field: 'order', direction: 'asc' },
        }).data.map((stage) => this.normalizeStage(pipelineResult.data, stage));
        return successResult(stages);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'pipelineId', operator: '==', value: pipelineId },
          { field: 'isActive', operator: '==', value: true },
        ],
        orderBy: { field: 'order', direction: 'asc' },
      });

      const querySnapshot = await getDocs(q);

      const stages: Stage[] = querySnapshot.docs
        .map((doc) => {
          const data = doc.data();
          const stage: Stage = {
            id: doc.id,
            pipelineId: data.pipelineId,
            name: data.name,
            order: data.order,
            colorHex: data.colorHex,
            probability: data.probability,
            isActive: data.isActive,
            ownerId: data.ownerId,
            ownerName: data.ownerName,
            teamIds: data.teamIds,
            visibility: data.visibility,
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate(),
          };
          return this.normalizeStage(pipelineResult.data, stage);
        })
        .filter((stage) => stage.pipelineId === pipelineId);

      await this.logAudit(context, 'list', null, {
        action: 'getActiveByPipeline',
        pipelineId,
        count: stages.length,
      });

      return successResult(stages);
    } catch (error) {
      return failedResult(error, 'Failed to get active stages by pipeline');
    }
  }

  /**
   * Reorder stages atomically
   * Updates the 'order' field of each stage based on the array index
   * RBAC: Only owner/admin can reorder stages
   *
   * @param context - Security context with businessId
   * @param stageIds - Array of stage IDs in the desired order
   * @returns Result indicating success
   */
  async reorder(
    context: SecurityContext,
    stageIds: string[],
    teamIds: string[] = []
  ): Promise<RepositoryResult<void>> {
    try {
      if (!stageIds || stageIds.length === 0) {
        return failedResult(new InvalidArgumentError('Stage IDs array is required', 'stageIds'));
      }

      // Ensure caller can access the pipeline that owns these stages
      const firstStage = await this.getById(context, stageIds[0], teamIds);
      if (!firstStage.success) {
        return { success: false, data: null, error: firstStage.error };
      }

      // Validate all stage IDs
      for (const id of stageIds) {
        if (!isValidDocumentId(id)) {
          return failedResult(new InvalidArgumentError(`Invalid stage ID: ${id}`, 'stageIds'));
        }
      }

      // Verify all stages exist
      for (const stageId of stageIds) {
        const exists = await this.exists(context, stageId);
        if (!exists) {
          return failedResult(
            new InvalidArgumentError(`Stage not found: ${stageId}`, 'stageIds')
          );
        }
      }

      // Confirm caller can modify the parent pipeline
      const pipelineResult = await this.getPipelineForAccess(
        context,
        firstStage.success ? firstStage.data.pipelineId : stageIds[0],
        teamIds
      );
      if (!pipelineResult.success) {
        return { success: false, data: null, error: pipelineResult.error };
      }
      const writeAccess = this.ensurePipelineWriteAccess(context, pipelineResult.data, teamIds);
      if (!writeAccess.success) {
        return writeAccess;
      }

      // Use batch to update all stages atomically
      const batch = writeBatch(this.db);

      stageIds.forEach((stageId, index) => {
        const docRef = this.getDocRef(context, stageId);
        batch.update(docRef, {
          order: index,
          updatedAt: Timestamp.now(),
        });
      });

      await batch.commit();

      await this.logAudit(context, 'batch', null, {
        action: 'reorder',
        stageIds,
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to reorder stages');
    }
  }

  /**
   * Archive a stage (soft archive by setting isActive to false)
   * Note: Should check for deals in this stage before archiving - placeholder for DealRepository
   * RBAC: Only owner/admin can archive stages
   *
   * @param context - Security context with businessId
   * @param stageId - ID of stage to archive
   * @returns Result with archived stage
   */
  async archive(
    context: SecurityContext,
    stageId: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage>> {
    try {
      if (!isValidDocumentId(stageId)) {
        return failedResult(new InvalidArgumentError('Invalid stage ID', 'stageId'));
      }

      // Verify stage exists
      const existingResult = await this.getById(context, stageId, teamIds);
      if (!existingResult.success) {
        return existingResult;
      }

      const stage = existingResult.data;

      // Check if this is the only active stage in the pipeline
      const activeStagesResult = await this.getActiveByPipeline(
        context,
        stage.pipelineId,
        teamIds
      );
      if (activeStagesResult.success && activeStagesResult.data.length <= 1) {
        return failedResult(
          new InvalidArgumentError(
            'Cannot archive the only active stage in a pipeline',
            'stageId'
          )
        );
      }

      // Archive the stage
      const result = await this.update(context, stageId, {
        isActive: false,
      });

      if (result.success) {
        await this.logAudit(context, 'update', stageId, { action: 'archive' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to archive stage');
    }
  }

  /**
   * Restore an archived stage
   * RBAC: Only owner/admin can restore stages
   *
   * @param context - Security context with businessId
   * @param stageId - ID of stage to restore
   * @returns Result with restored stage
   */
  async restore(
    context: SecurityContext,
    stageId: string,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage>> {
    try {
      if (!isValidDocumentId(stageId)) {
        return failedResult(new InvalidArgumentError('Invalid stage ID', 'stageId'));
      }

      // Verify stage exists
      const existingResult = await this.getById(context, stageId, teamIds);
      if (!existingResult.success) {
        return existingResult;
      }

      // Restore the stage
      const result = await this.update(context, stageId, {
        isActive: true,
      });

      if (result.success) {
        await this.logAudit(context, 'update', stageId, { action: 'restore' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to restore stage');
    }
  }

  /**
   * Create multiple stages for a pipeline at once (batch create)
   * Useful for seeding default stages when creating a new pipeline
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of the pipeline
   * @param stages - Array of stage data to create
   * @returns Result with created stages
   */
  async createMany(
    context: SecurityContext,
    pipelineId: string,
    stages: Array<Omit<Stage, 'id' | 'pipelineId' | 'createdAt' | 'updatedAt'>>,
    teamIds: string[] = []
  ): Promise<RepositoryResult<Stage[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      const pipelineResult = await this.getPipelineForAccess(context, pipelineId, teamIds);
      if (!pipelineResult.success) {
        return { success: false, data: null, error: pipelineResult.error };
      }
      const accessResult = this.ensurePipelineWriteAccess(context, pipelineResult.data, teamIds);
      if (!accessResult.success) {
        return { success: false, data: null, error: accessResult.error };
      }

      if (!stages || stages.length === 0) {
        return failedResult(new InvalidArgumentError('Stages array is required', 'stages'));
      }

      const batch = writeBatch(this.db);
      const createdIds: string[] = [];

      for (const stageData of stages) {
        const stageId = generateId();
        const docRef = this.getDocRef(context, stageId);

        const stageWithOwnership = this.inheritOwnershipFromPipeline(pipelineResult.data, stageData as Partial<Stage>);

        batch.set(docRef, {
          ...stageData,
          ...stageWithOwnership,
          pipelineId,
          createdAt: Timestamp.now(),
          visibility: stageWithOwnership.visibility ?? DEFAULT_VISIBILITY,
        });

        createdIds.push(stageId);
      }

      await batch.commit();

      // Fetch all created stages
      const createdStages: Stage[] = [];
      for (const id of createdIds) {
        const result = await this.getById(context, id);
        if (result.success) {
          createdStages.push(result.data);
        }
      }

      await this.logAudit(context, 'batch', null, {
        action: 'createMany',
        pipelineId,
        count: createdStages.length,
        createdIds,
      });

      return successResult(createdStages);
    } catch (error) {
      return failedResult(error, 'Failed to create stages');
    }
  }

  /**
   * Get the next available order number for a pipeline
   *
   * @param context - Security context with businessId
   * @param pipelineId - ID of the pipeline
   * @returns Next order number (max + 1)
   */
  async getNextOrder(
    context: SecurityContext,
    pipelineId: string,
    teamIds: string[] = []
  ): Promise<number> {
    const stagesResult = await this.getByPipeline(context, pipelineId, teamIds);
    if (!stagesResult.success || stagesResult.data.length === 0) {
      return 0;
    }

    const maxOrder = Math.max(...stagesResult.data.map((s) => s.order));
    return maxOrder + 1;
  }

  /**
   * Check if a stage can be deleted (no deals in this stage)
   * Note: This is a placeholder - actual deal check should be done by DealRepository
   *
   * @param context - Security context with businessId
   * @param stageId - ID of stage to check
   * @returns True if stage can be safely deleted
   */
  async canDelete(context: SecurityContext, stageId: string): Promise<boolean> {
    // This will be implemented properly when DealRepository is available
    // For now, just check if the stage exists
    const result = await this.getById(context, stageId);
    return result.success;
  }
}

// Export singleton instance for convenience
let stageRepository: StageRepository | null = null;

export function getStageRepository(): StageRepository {
  if (!stageRepository) {
    stageRepository = new StageRepository();
  }
  return stageRepository;
}
