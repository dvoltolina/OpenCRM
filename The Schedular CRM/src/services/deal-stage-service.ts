/**
 * Deal Stage Transition Service
 * Business logic for deal stage movements and win/loss tracking
 *
 * Agent CRM-12 Implementation
 * Dependencies: Agent CRM-04 (deals), Agent CRM-02 (stages), Agent CRM-06 (activities)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { getDealRepository } from '../data/repositories/deal-repository';
import { getStageRepository } from '../data/repositories/stage-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Deal, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

/**
 * Stage transition request
 */
export interface StageTransition {
  /** ID of the deal to move */
  dealId: string;
  /** ID of the stage the deal is moving from */
  fromStageId: string;
  /** ID of the stage the deal is moving to */
  toStageId: string;
  /** Optional reason for the transition */
  reason?: string;
}

/**
 * Win/loss data for closing a deal
 */
export interface WinLossData {
  /** ID of the deal */
  dealId: string;
  /** Outcome of the deal */
  outcome: 'won' | 'lost';
  /** Reason for win/loss */
  reason?: string;
  /** When the deal was closed (defaults to now) */
  closedAt?: Date;
  /** Actual value for won deals (may differ from original estimate) */
  actualValue?: number;
}

/**
 * Entry in a deal's stage history
 */
export interface StageHistoryEntry {
  /** ID of the activity representing this transition */
  activityId: string;
  /** Stage ID the deal moved from */
  fromStageId: string;
  /** Name of the stage the deal moved from */
  fromStageName: string;
  /** Stage ID the deal moved to */
  toStageId: string;
  /** Name of the stage the deal moved to */
  toStageName: string;
  /** When the transition occurred */
  movedAt: Date;
  /** ID of the user who moved the deal */
  movedById: string;
  /** Name of the user who moved the deal */
  movedByName: string;
  /** Reason for the transition (if provided) */
  reason?: string;
}

/**
 * Result of checking if a move is allowed
 */
export interface CanMoveResult {
  canMove: boolean;
  reason?: string;
}

/**
 * Result of a stage transition operation
 */
export interface TransitionResult {
  success: boolean;
  deal?: Deal;
  error?: string;
}

// ============================================
// Deal Stage Service
// ============================================

/**
 * DealStageService
 * Handles deal stage transitions with validation, activity logging, and history tracking
 */
export class DealStageService {
  /**
   * Check if a deal can be moved to a specific stage
   */
  async canMoveToStage(
    context: SecurityContext,
    dealId: string,
    stageId: string
  ): Promise<CanMoveResult> {
    const dealRepo = getDealRepository();
    const stageRepo = getStageRepository();

    // Step 1: Get the deal
    const dealResult = await dealRepo.getById(context, dealId);
    if (!dealResult.success) {
      return {
        canMove: false,
        reason: dealResult.error.message,
      };
    }

    const deal = dealResult.data;

    // Step 2: Check if deal is open
    if (deal.status !== 'open') {
      return {
        canMove: false,
        reason: `Cannot move a ${deal.status} deal. Reopen it first.`,
      };
    }

    // Step 3: Check if already in target stage
    if (deal.stageId === stageId) {
      return {
        canMove: false,
        reason: 'Deal is already in this stage',
      };
    }

    // Step 4: Get the target stage
    const stageResult = await stageRepo.getById(context, stageId);
    if (!stageResult.success) {
      return {
        canMove: false,
        reason: 'Target stage not found',
      };
    }

    const stage = stageResult.data;

    // Step 5: Check if stage is active
    if (!stage.isActive) {
      return {
        canMove: false,
        reason: 'Cannot move to an inactive stage',
      };
    }

    // Step 6: Check if stage belongs to the same pipeline
    if (stage.pipelineId !== deal.pipelineId) {
      return {
        canMove: false,
        reason: 'Target stage belongs to a different pipeline',
      };
    }

    return { canMove: true };
  }

  /**
   * Move a deal to a new stage
   * Validates the transition, updates the deal, and logs an activity
   */
  async moveToStage(
    context: SecurityContext,
    transition: StageTransition
  ): Promise<TransitionResult> {
    const dealRepo = getDealRepository();
    const stageRepo = getStageRepository();
    const activityRepo = getActivityRepository();

    // Step 1: Validate the move
    const canMove = await this.canMoveToStage(
      context,
      transition.dealId,
      transition.toStageId
    );

    if (!canMove.canMove) {
      return {
        success: false,
        error: canMove.reason,
      };
    }

    // Step 2: Get stage names for activity logging
    const [fromStageResult, toStageResult] = await Promise.all([
      stageRepo.getById(context, transition.fromStageId),
      stageRepo.getById(context, transition.toStageId),
    ]);

    const fromStageName = fromStageResult.success
      ? fromStageResult.data.name
      : 'Unknown Stage';
    const toStageName = toStageResult.success
      ? toStageResult.data.name
      : 'Unknown Stage';

    // Get probability from target stage
    const probability = toStageResult.success
      ? toStageResult.data.probability
      : undefined;

    // Step 3: Move the deal
    const moveResult = await dealRepo.moveToStage(
      context,
      transition.dealId,
      transition.toStageId,
      probability
    );

    if (!moveResult.success) {
      return {
        success: false,
        error: moveResult.error.message,
      };
    }

    // Step 4: Log the stage transition activity
    const activityDescription = transition.reason
      ? `Moved from "${fromStageName}" to "${toStageName}". Reason: ${transition.reason}`
      : `Moved from "${fromStageName}" to "${toStageName}"`;

    await activityRepo.create(context, {
      type: 'note',
      title: 'Stage Changed',
      description: activityDescription,
      dealId: transition.dealId,
      clientId: moveResult.data.clientId,
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    return {
      success: true,
      deal: moveResult.data,
    };
  }

  /**
   * Mark a deal as won
   */
  async markWon(
    context: SecurityContext,
    data: WinLossData
  ): Promise<TransitionResult> {
    const dealRepo = getDealRepository();
    const activityRepo = getActivityRepository();

    // Validate outcome
    if (data.outcome !== 'won') {
      return {
        success: false,
        error: 'Invalid outcome for markWon. Use markLost for lost deals.',
      };
    }

    // Get the deal first for activity logging
    const existingResult = await dealRepo.getById(context, data.dealId);
    if (!existingResult.success) {
      return {
        success: false,
        error: existingResult.error.message,
      };
    }

    const deal = existingResult.data;

    // Check if deal is already won
    if (deal.status === 'won') {
      return {
        success: false,
        error: 'Deal is already marked as won',
      };
    }

    // Mark as won
    const wonResult = await dealRepo.markWon(context, data.dealId, data.reason);

    if (!wonResult.success) {
      return {
        success: false,
        error: wonResult.error.message,
      };
    }

    // Update actual value if provided
    if (data.actualValue !== undefined && data.actualValue !== deal.valueCents) {
      await dealRepo.update(context, data.dealId, {
        valueCents: data.actualValue,
      });
    }

    // Log the win activity
    const description = data.reason
      ? `Deal won! Reason: ${data.reason}`
      : 'Deal won!';

    await activityRepo.create(context, {
      type: 'note',
      title: 'Deal Won',
      description,
      dealId: data.dealId,
      clientId: deal.clientId,
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    return {
      success: true,
      deal: wonResult.data,
    };
  }

  /**
   * Mark a deal as lost (reason required)
   */
  async markLost(
    context: SecurityContext,
    data: WinLossData
  ): Promise<TransitionResult> {
    const dealRepo = getDealRepository();
    const activityRepo = getActivityRepository();

    // Validate outcome
    if (data.outcome !== 'lost') {
      return {
        success: false,
        error: 'Invalid outcome for markLost. Use markWon for won deals.',
      };
    }

    // Validate reason is provided
    if (!data.reason?.trim()) {
      return {
        success: false,
        error: 'Reason is required when marking a deal as lost',
      };
    }

    // Get the deal first for activity logging
    const existingResult = await dealRepo.getById(context, data.dealId);
    if (!existingResult.success) {
      return {
        success: false,
        error: existingResult.error.message,
      };
    }

    const deal = existingResult.data;

    // Check if deal is already lost
    if (deal.status === 'lost') {
      return {
        success: false,
        error: 'Deal is already marked as lost',
      };
    }

    // Mark as lost
    const lostResult = await dealRepo.markLost(context, data.dealId, data.reason);

    if (!lostResult.success) {
      return {
        success: false,
        error: lostResult.error.message,
      };
    }

    // Log the loss activity with reason
    await activityRepo.create(context, {
      type: 'note',
      title: 'Deal Lost',
      description: `Deal lost. Reason: ${data.reason}`,
      dealId: data.dealId,
      clientId: deal.clientId,
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    return {
      success: true,
      deal: lostResult.data,
    };
  }

  /**
   * Reopen a closed deal
   */
  async reopenDeal(
    context: SecurityContext,
    dealId: string
  ): Promise<TransitionResult> {
    const dealRepo = getDealRepository();
    const activityRepo = getActivityRepository();

    // Get the deal first
    const existingResult = await dealRepo.getById(context, dealId);
    if (!existingResult.success) {
      return {
        success: false,
        error: existingResult.error.message,
      };
    }

    const deal = existingResult.data;

    // Check if deal is open (can't reopen an open deal)
    if (deal.status === 'open') {
      return {
        success: false,
        error: 'Deal is already open',
      };
    }

    const previousStatus = deal.status;

    // Reopen the deal
    const reopenResult = await dealRepo.reopen(context, dealId);

    if (!reopenResult.success) {
      return {
        success: false,
        error: reopenResult.error.message,
      };
    }

    // Log the reopen activity
    await activityRepo.create(context, {
      type: 'note',
      title: 'Deal Reopened',
      description: `Deal reopened. Previous status: ${previousStatus}`,
      dealId,
      clientId: deal.clientId,
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    return {
      success: true,
      deal: reopenResult.data,
    };
  }

  /**
   * Get the stage history for a deal
   * Returns all stage transitions as recorded in activities
   */
  async getStageHistory(
    context: SecurityContext,
    dealId: string
  ): Promise<StageHistoryEntry[]> {
    const activityRepo = getActivityRepository();

    // Get all activities for this deal
    const activitiesResult = await activityRepo.getByDeal(context, dealId);

    if (!activitiesResult.success) {
      return [];
    }

    const activities = activitiesResult.data.data;

    // Filter for stage change activities and parse them
    const stageHistory: StageHistoryEntry[] = [];

    for (const activity of activities) {
      // Look for "Stage Changed" activities
      if (activity.title === 'Stage Changed' && activity.description) {
        const historyEntry = this.parseStageChangeActivity(activity);
        if (historyEntry) {
          stageHistory.push(historyEntry);
        }
      }
    }

    // Sort by date (most recent first)
    stageHistory.sort((a, b) => b.movedAt.getTime() - a.movedAt.getTime());

    return stageHistory;
  }

  /**
   * Parse a stage change activity into a history entry
   */
  private parseStageChangeActivity(
    activity: SalesActivity
  ): StageHistoryEntry | null {
    if (!activity.description) {
      return null;
    }

    // Parse: Moved from "Stage A" to "Stage B". Reason: ...
    const movePattern = /Moved from "([^"]+)" to "([^"]+)"(?:\. Reason: (.+))?/;
    const match = activity.description.match(movePattern);

    if (!match) {
      return null;
    }

    return {
      activityId: activity.id,
      fromStageId: '', // We don't store IDs in description, just names
      fromStageName: match[1],
      toStageId: '',
      toStageName: match[2],
      movedAt: activity.createdAt instanceof Date
        ? activity.createdAt
        : new Date(activity.createdAt),
      movedById: activity.createdById,
      movedByName: activity.createdByName,
      reason: match[3],
    };
  }

  /**
   * Validate a stage transition and move if valid
   * This is a convenience method that combines canMoveToStage and moveToStage
   */
  async validateAndMove(
    context: SecurityContext,
    dealId: string,
    toStageId: string,
    reason?: string
  ): Promise<TransitionResult> {
    const dealRepo = getDealRepository();

    // Get the current deal to find fromStageId
    const dealResult = await dealRepo.getById(context, dealId);
    if (!dealResult.success) {
      return {
        success: false,
        error: dealResult.error.message,
      };
    }

    const transition: StageTransition = {
      dealId,
      fromStageId: dealResult.data.stageId,
      toStageId,
      reason,
    };

    return this.moveToStage(context, transition);
  }
}

// ============================================
// Singleton Export
// ============================================

let dealStageServiceInstance: DealStageService | null = null;

export function getDealStageService(): DealStageService {
  if (!dealStageServiceInstance) {
    dealStageServiceInstance = new DealStageService();
  }
  return dealStageServiceInstance;
}
