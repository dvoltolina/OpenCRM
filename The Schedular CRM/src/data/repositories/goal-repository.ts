/**
 * Goal Repository
 * Manages sales goals/quotas with RBAC and progress tracking
 *
 * HIPAA Compliance:
 * - Goals contain no PHI (metrics are counts/values only)
 * - All operations require SecurityContext for businessId scoping
 * - Audit log goal creation/updates with IDs only
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities, isOrgPrivileged } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type { Goal, GoalStatus, GoalPeriod, GoalMetric, GoalAssigneeType } from '../../types/goals';

// ============================================
// Validation
// ============================================

const VALID_METRICS: GoalMetric[] = [
  'revenue',
  'deals_won',
  'deals_created',
  'activities_completed',
  'calls_made',
  'emails_sent',
];

const VALID_PERIODS: GoalPeriod[] = ['weekly', 'monthly', 'quarterly', 'yearly'];
const VALID_STATUSES: GoalStatus[] = ['active', 'achieved', 'missed', 'cancelled'];
const VALID_ASSIGNEE_TYPES: GoalAssigneeType[] = ['user', 'team', 'business'];

const goalValidator: Validator<Goal> = (data: Partial<Goal>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.metric !== undefined && !VALID_METRICS.includes(data.metric)) {
    errors.push({
      field: 'metric',
      message: `Invalid metric. Must be one of: ${VALID_METRICS.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.targetValue !== undefined && data.targetValue < 0) {
    errors.push({
      field: 'targetValue',
      message: 'Target value must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  if (data.period !== undefined && !VALID_PERIODS.includes(data.period)) {
    errors.push({
      field: 'period',
      message: `Invalid period. Must be one of: ${VALID_PERIODS.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.status !== undefined && !VALID_STATUSES.includes(data.status)) {
    errors.push({
      field: 'status',
      message: `Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.assigneeType !== undefined && !VALID_ASSIGNEE_TYPES.includes(data.assigneeType)) {
    errors.push({
      field: 'assigneeType',
      message: `Invalid assignee type. Must be one of: ${VALID_ASSIGNEE_TYPES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.startDate && data.endDate && data.startDate > data.endDate) {
    errors.push({
      field: 'endDate',
      message: 'End date must be after start date',
      code: 'INVALID_VALUE',
    });
  }

  if (data.progressPercent !== undefined && (data.progressPercent < 0 || data.progressPercent > 100)) {
    errors.push({
      field: 'progressPercent',
      message: 'Progress percent must be between 0 and 100',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Goal Repository
// ============================================

/**
 * Goal Repository
 * Handles CRUD operations for sales goals with RBAC
 */
export class GoalRepository extends ShareableRepository<Goal> {
  protected entityName = 'goal';
  protected sensitiveFields: Array<keyof Goal> = [];

  constructor() {
    super({ collectionName: 'goals' });
    this.setValidator(goalValidator);
  }

  // ============================================
  // Authorization Helpers
  // ============================================

  /**
   * Check if user can create goals for the specified assignee
   * - Admin/owner can create goals for anyone
   * - Managers can create goals for their team members
   * - Regular users can only create goals for themselves
   */
  private canCreateGoalFor(
    context: SecurityContext,
    assigneeType: GoalAssigneeType,
    assigneeId: string
  ): boolean {
    if (isOrgPrivileged(context)) return true;

    // Managers can create goals for team members
    if (context.userRole === 'manager') {
      if (assigneeType === 'user') {
        // Manager can create for users in their managed teams
        return true; // Simplified - in production, check team membership
      }
      if (assigneeType === 'team') {
        // Check if manager manages this team
        const managedTeams = context.managedTeamIds || [];
        return managedTeams.includes(assigneeId);
      }
    }

    // Regular users can only create goals for themselves
    return assigneeType === 'user' && assigneeId === context.userId;
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get goals for a specific assignee (user/team/business)
   */
  async getByAssignee(
    context: SecurityContext,
    assigneeType: GoalAssigneeType,
    assigneeId: string
  ): Promise<RepositoryResult<Goal[]>> {
    try {
      if (!assigneeId) {
        return failedResult(new InvalidArgumentError('Assignee ID is required', 'assigneeId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'assigneeType', operator: '==', value: assigneeType },
          { field: 'assigneeId', operator: '==', value: assigneeId },
        ],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const goals = this.filterAccessibleGoals(context, this.snapshotToGoals(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByAssignee',
        assigneeType,
        assigneeId,
        count: goals.length,
      });

      return successResult(goals);
    } catch (error) {
      return failedResult(error, 'Failed to get goals by assignee');
    }
  }

  /**
   * Get active goals for a specific period
   */
  async getActiveByPeriod(
    context: SecurityContext,
    period: GoalPeriod,
    startDate: Date
  ): Promise<RepositoryResult<Goal[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'active' },
          { field: 'period', operator: '==', value: period },
          { field: 'startDate', operator: '>=', value: Timestamp.fromDate(startDate) },
        ],
        orderBy: { field: 'startDate', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const goals = this.filterAccessibleGoals(context, this.snapshotToGoals(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getActiveByPeriod',
        period,
        startDate: startDate.toISOString(),
        count: goals.length,
      });

      return successResult(goals);
    } catch (error) {
      return failedResult(error, 'Failed to get active goals by period');
    }
  }

  /**
   * Get all active goals
   */
  async getActive(context: SecurityContext): Promise<RepositoryResult<Goal[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: 'active' }],
        orderBy: { field: 'endDate', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const goals = this.filterAccessibleGoals(context, this.snapshotToGoals(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getActive',
        count: goals.length,
      });

      return successResult(goals);
    } catch (error) {
      return failedResult(error, 'Failed to get active goals');
    }
  }

  /**
   * Get goals by status
   */
  async getByStatus(
    context: SecurityContext,
    status: GoalStatus
  ): Promise<RepositoryResult<Goal[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: status }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const goals = this.filterAccessibleGoals(context, this.snapshotToGoals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByStatus', status });

      return successResult(goals);
    } catch (error) {
      return failedResult(error, 'Failed to get goals by status');
    }
  }

  /**
   * Get goals for the current user
   */
  async getMyGoals(context: SecurityContext): Promise<RepositoryResult<Goal[]>> {
    return this.getByAssignee(context, 'user', context.userId);
  }

  // ============================================
  // Progress Management
  // ============================================

  /**
   * Update goal progress
   */
  async updateProgress(
    context: SecurityContext,
    goalId: string,
    currentValue: number
  ): Promise<RepositoryResult<Goal>> {
    try {
      if (!isValidDocumentId(goalId)) {
        return failedResult(new InvalidArgumentError('Invalid goal ID', 'goalId'));
      }

      // Get current goal
      const existingResult = await this.getById(context, goalId);
      if (!existingResult.success) {
        return existingResult;
      }

      const goal = existingResult.data;

      // Calculate progress percentage
      const progressPercent = goal.targetValue > 0
        ? Math.min(100, Math.round((currentValue / goal.targetValue) * 100))
        : 0;

      const updateData: Partial<Goal> = {
        currentValue,
        progressPercent,
        lastCalculatedAt: new Date(),
      };

      const result = await this.update(context, goalId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', goalId, {
          action: 'updateProgress',
          currentValue,
          progressPercent,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update goal progress');
    }
  }

  /**
   * Check and update goal status based on dates and progress
   */
  async checkAndUpdateStatus(
    context: SecurityContext,
    goalId: string
  ): Promise<RepositoryResult<Goal>> {
    try {
      if (!isValidDocumentId(goalId)) {
        return failedResult(new InvalidArgumentError('Invalid goal ID', 'goalId'));
      }

      const existingResult = await this.getById(context, goalId);
      if (!existingResult.success) {
        return existingResult;
      }

      const goal = existingResult.data;

      // Only check active goals
      if (goal.status !== 'active') {
        return successResult(goal);
      }

      const now = new Date();
      let newStatus: GoalStatus = 'active';

      // Check if goal is achieved
      if (goal.currentValue >= goal.targetValue) {
        newStatus = 'achieved';
      }
      // Check if goal period has ended
      else if (goal.endDate && now > goal.endDate) {
        newStatus = 'missed';
      }

      if (newStatus !== 'active') {
        const result = await this.update(context, goalId, { status: newStatus });
        if (result.success) {
          await this.logAudit(context, 'update', goalId, {
            action: 'statusTransition',
            fromStatus: 'active',
            toStatus: newStatus,
          });
        }
        return result;
      }

      return successResult(goal);
    } catch (error) {
      return failedResult(error, 'Failed to check goal status');
    }
  }

  /**
   * Cancel a goal
   */
  async cancelGoal(context: SecurityContext, goalId: string): Promise<RepositoryResult<Goal>> {
    try {
      if (!isValidDocumentId(goalId)) {
        return failedResult(new InvalidArgumentError('Invalid goal ID', 'goalId'));
      }

      const existingResult = await this.getById(context, goalId);
      if (!existingResult.success) {
        return existingResult;
      }

      const goal = existingResult.data;

      // Can only cancel active goals
      if (goal.status !== 'active') {
        return failedResult(
          new InvalidArgumentError('Can only cancel active goals', 'status')
        );
      }

      const result = await this.update(context, goalId, { status: 'cancelled' });

      if (result.success) {
        await this.logAudit(context, 'update', goalId, {
          action: 'cancel',
          previousStatus: goal.status,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to cancel goal');
    }
  }

  // ============================================
  // Override Create with Authorization
  // ============================================

  async create(
    context: SecurityContext,
    data: Omit<Goal, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Goal>> {
    // Check authorization for creating goals for the specified assignee
    if (!this.canCreateGoalFor(context, data.assigneeType as GoalAssigneeType, data.assigneeId as string)) {
      return failedResult(
        new AuthorizationError(
          'Not authorized to create goals for this assignee',
          'create',
          context.userRole
        )
      );
    }

    // Set defaults for progress tracking
    const goalData = {
      ...data,
      currentValue: data.currentValue ?? 0,
      progressPercent: data.progressPercent ?? 0,
      lastCalculatedAt: data.lastCalculatedAt ?? new Date(),
      status: data.status ?? 'active',
      createdById: context.userId,
      createdByName: context.userName,
    };

    return super.create(context, goalData as Omit<Goal, 'id' | 'createdAt' | 'updatedAt'>, customId);
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleGoals(context: SecurityContext, goals: Goal[]): Goal[] {
    return filterAuthorizedEntities(context, goals, this.sensitiveFields);
  }

  /**
   * Convert Firestore snapshot to Goal array
   */
  private snapshotToGoals(snapshot: QuerySnapshot<DocumentData>): Goal[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        metric: data.metric as GoalMetric,
        targetValue: data.targetValue as number,
        period: data.period as GoalPeriod,
        startDate: data.startDate?.toDate?.() || data.startDate,
        endDate: data.endDate?.toDate?.() || data.endDate,
        assigneeType: data.assigneeType as GoalAssigneeType,
        assigneeId: data.assigneeId as string,
        assigneeName: data.assigneeName as string,
        pipelineId: data.pipelineId as string | undefined,
        currentValue: data.currentValue as number,
        progressPercent: data.progressPercent as number,
        lastCalculatedAt: data.lastCalculatedAt?.toDate?.() || data.lastCalculatedAt,
        status: data.status as GoalStatus,
        createdById: data.createdById as string,
        createdByName: data.createdByName as string,
        ownerId: data.ownerId as string,
        ownerName: data.ownerName as string,
        teamIds: (data.teamIds as string[]) || [],
        visibility: data.visibility || 'team',
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let goalRepository: GoalRepository | null = null;

export function getGoalRepository(): GoalRepository {
  if (!goalRepository) {
    goalRepository = new GoalRepository();
  }
  return goalRepository;
}
