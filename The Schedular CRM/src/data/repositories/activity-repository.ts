/**
 * Activity Repository
 * Firestore data access for sales activities (calls, emails, meetings, notes, tasks)
 *
 * Agent CRM-06 Implementation
 * Dependencies: Agent CRM-01 (base repository)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { Timestamp } from 'firebase/firestore';
import { ShareableRepository } from './access-control';
import type {
  SecurityContext,
  QueryOptions,
  RepositoryResult,
  PaginatedResult,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  ValidationError,
  failedResult,
  successResult,
  InvalidArgumentError,
} from '../errors/repository-errors';
import type { SalesActivity, SalesActivityType } from '../../types/models';

// ============================================
// Activity-Specific Types
// ============================================

/**
 * Entity types that can have activities linked
 */
export type EntityType = 'deal' | 'client' | 'lead' | 'company';

/**
 * Filter options for activities
 */
export interface ActivityFilterOptions {
  type?: SalesActivityType;
  assigneeId?: string;
  createdById?: string;
  isCompleted?: boolean;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
}

// ============================================
// Activity Validator
// ============================================

/**
 * Validate activity data
 */
export function validateActivity(data: Partial<SalesActivity>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];
  const isDateLike = (value: unknown) =>
    value instanceof Date || value instanceof Timestamp;

  // Title validation
  if (data.title !== undefined && !data.title?.trim()) {
    errors.push({
      field: 'title',
      message: 'Title is required',
      code: 'REQUIRED',
    });
  }

  // Type validation
  const validTypes: SalesActivityType[] = ['call', 'email', 'meeting', 'note', 'task'];
  if (data.type !== undefined && !validTypes.includes(data.type)) {
    errors.push({
      field: 'type',
      message: 'Invalid activity type',
      code: 'INVALID_VALUE',
    });
  }

  // Task validation: tasks should have dueDate
  if (data.type === 'task' && data.dueDate === undefined) {
    // Warning only - not a hard error
  }

  if (data.slaMinutes !== undefined && data.slaMinutes <= 0) {
    errors.push({
      field: 'slaMinutes',
      message: 'SLA minutes must be greater than zero when provided',
      code: 'INVALID_VALUE',
    });
  }

  if (data.slaAt !== undefined && !isDateLike(data.slaAt)) {
    errors.push({
      field: 'slaAt',
      message: 'SLA target must be a valid date',
      code: 'INVALID_VALUE',
    });
  }

  if (data.reminderAt !== undefined && !isDateLike(data.reminderAt)) {
    errors.push({
      field: 'reminderAt',
      message: 'Reminder timestamp must be a valid date',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate required fields for activity creation
 */
export function validateActivityCreate(
  data: Partial<SalesActivity>
): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Type is required
  const validTypes: SalesActivityType[] = ['call', 'email', 'meeting', 'note', 'task'];
  if (!data.type || !validTypes.includes(data.type)) {
    errors.push({
      field: 'type',
      message: 'Valid activity type is required',
      code: 'REQUIRED',
    });
  }

  // Title is required
  if (!data.title?.trim()) {
    errors.push({
      field: 'title',
      message: 'Title is required',
      code: 'REQUIRED',
    });
  }

  // Creator info is required
  if (!data.createdById?.trim()) {
    errors.push({
      field: 'createdById',
      message: 'Creator ID is required',
      code: 'REQUIRED',
    });
  }

  if (!data.createdByName?.trim()) {
    errors.push({
      field: 'createdByName',
      message: 'Creator name is required',
      code: 'REQUIRED',
    });
  }

  // At least one entity must be linked
  const hasEntity = data.dealId || data.clientId || data.leadId || data.companyId;
  if (!hasEntity) {
    errors.push({
      field: 'entity',
      message: 'Activity must be linked to at least one entity (deal, client, lead, or company)',
      code: 'REQUIRED',
    });
  }

  if (data.slaMinutes !== undefined && data.slaMinutes <= 0) {
    errors.push({
      field: 'slaMinutes',
      message: 'SLA minutes must be greater than zero when provided',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Activity Repository Class
// ============================================

/**
 * ActivityRepository
 * Provides CRUD operations and activity-specific queries
 */
export class ActivityRepository extends ShareableRepository<SalesActivity> {
  protected entityName = 'activity';
  protected sensitiveFields: Array<keyof SalesActivity> = ['description'];

  constructor() {
    super({
      collectionName: 'sales_activities',
      softDelete: false,
    });
    this.setValidator(validateActivity as Validator<SalesActivity>);
  }

  // ============================================
  // Create Override (with required field validation)
  // ============================================

  /**
   * Create a new activity with required field validation
   */
  async create(
    context: SecurityContext,
    data: Omit<SalesActivity, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<SalesActivity>> {
    // Validate required fields for creation
    const validation = validateActivityCreate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Set defaults
    const activityData = {
      ...data,
      isCompleted: data.isCompleted ?? false,
    };

    return super.create(context, activityData, customId);
  }

  // ============================================
  // Entity-Linked Queries
  // ============================================

  /**
   * Get activities linked to a deal
   */
  async getByDeal(
    context: SecurityContext,
    dealId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'dealId', operator: '==', value: dealId },
      ],
      orderBy: options.orderBy || { field: 'createdAt', direction: 'desc' },
    });
  }

  /**
   * Get activities linked to a client
   */
  async getByClient(
    context: SecurityContext,
    clientId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'clientId', operator: '==', value: clientId },
      ],
      orderBy: options.orderBy || { field: 'createdAt', direction: 'desc' },
    });
  }

  /**
   * Get activities linked to a lead
   */
  async getByLead(
    context: SecurityContext,
    leadId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'leadId', operator: '==', value: leadId },
      ],
      orderBy: options.orderBy || { field: 'createdAt', direction: 'desc' },
    });
  }

  /**
   * Get activities linked to a company
   */
  async getByCompany(
    context: SecurityContext,
    companyId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'companyId', operator: '==', value: companyId },
      ],
      orderBy: options.orderBy || { field: 'createdAt', direction: 'desc' },
    });
  }

  // ============================================
  // Filter Methods
  // ============================================

  /**
   * Filter activities by type
   */
  async getByType(
    context: SecurityContext,
    type: SalesActivityType,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'type', operator: '==', value: type },
      ],
    });
  }

  /**
   * Get activities assigned to a user
   */
  async getByAssignee(
    context: SecurityContext,
    assigneeId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'assigneeId', operator: '==', value: assigneeId },
      ],
    });
  }

  /**
   * Get activities created by a user
   */
  async getByCreator(
    context: SecurityContext,
    createdById: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'createdById', operator: '==', value: createdById },
      ],
    });
  }

  /**
   * Get activities with combined filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: ActivityFilterOptions,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    const whereClause = options.where || [];

    if (filters.type) {
      whereClause.push({ field: 'type', operator: '==', value: filters.type });
    }

    if (filters.assigneeId) {
      whereClause.push({ field: 'assigneeId', operator: '==', value: filters.assigneeId });
    }

    if (filters.createdById) {
      whereClause.push({ field: 'createdById', operator: '==', value: filters.createdById });
    }

    if (filters.isCompleted !== undefined) {
      whereClause.push({ field: 'isCompleted', operator: '==', value: filters.isCompleted });
    }

    if (filters.dealId) {
      whereClause.push({ field: 'dealId', operator: '==', value: filters.dealId });
    }

    if (filters.clientId) {
      whereClause.push({ field: 'clientId', operator: '==', value: filters.clientId });
    }

    if (filters.leadId) {
      whereClause.push({ field: 'leadId', operator: '==', value: filters.leadId });
    }

    if (filters.companyId) {
      whereClause.push({ field: 'companyId', operator: '==', value: filters.companyId });
    }

    if (filters.dateRange) {
      whereClause.push({
        field: 'createdAt',
        operator: '>=',
        value: Timestamp.fromDate(filters.dateRange.start),
      });
      whereClause.push({
        field: 'createdAt',
        operator: '<=',
        value: Timestamp.fromDate(filters.dateRange.end),
      });
    }

    return this.getAll(context, {
      ...options,
      where: whereClause,
    });
  }

  // ============================================
  // Task-Specific Methods
  // ============================================

  /**
   * Get all task-type activities
   */
  async getTasks(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    return this.getByType(context, 'task', options);
  }

  /**
   * Get pending (incomplete) tasks, optionally filtered by assignee
   */
  async getPendingTasks(
    context: SecurityContext,
    assigneeId?: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    const whereClause = [
      { field: 'type', operator: '==' as const, value: 'task' },
      { field: 'isCompleted', operator: '==' as const, value: false },
    ];

    if (assigneeId) {
      whereClause.push({ field: 'assigneeId', operator: '==' as const, value: assigneeId });
    }

    return this.getAll(context, {
      ...options,
      where: [...(options.where || []), ...whereClause],
      orderBy: options.orderBy || { field: 'dueDate', direction: 'asc' },
    });
  }

  /**
   * Get overdue tasks (past due date, not completed)
   */
  async getOverdueTasks(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    const now = new Date();

    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'type', operator: '==', value: 'task' },
        { field: 'isCompleted', operator: '==', value: false },
        { field: 'dueDate', operator: '<', value: Timestamp.fromDate(now) },
      ],
      orderBy: options.orderBy || { field: 'dueDate', direction: 'asc' },
    });
  }

  /**
   * Get upcoming tasks (due within N days)
   */
  async getUpcomingTasks(
    context: SecurityContext,
    days: number,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    if (days < 0) {
      return failedResult(
        new InvalidArgumentError('Days must be a non-negative number')
      );
    }

    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'type', operator: '==', value: 'task' },
        { field: 'isCompleted', operator: '==', value: false },
        { field: 'dueDate', operator: '>=', value: Timestamp.fromDate(now) },
        { field: 'dueDate', operator: '<=', value: Timestamp.fromDate(futureDate) },
      ],
      orderBy: options.orderBy || { field: 'dueDate', direction: 'asc' },
    });
  }

  /**
   * Mark a task as completed
   */
  async markComplete(
    context: SecurityContext,
    activityId: string
  ): Promise<RepositoryResult<SalesActivity>> {
    // Get current activity to verify it's a task
    const existing = await this.getById(context, activityId);
    if (!existing.success) {
      return existing;
    }

    if (existing.data.type !== 'task') {
      return failedResult(
        new ValidationError('Only tasks can be marked as complete', [
          {
            field: 'type',
            message: 'Activity is not a task',
          },
        ])
      );
    }

    if (existing.data.isCompleted) {
      // Already completed, return as-is
      return existing;
    }

    return this.update(context, activityId, {
      isCompleted: true,
      completedAt: new Date(),
    });
  }

  /**
   * Mark a task as incomplete (uncomplete)
   */
  async markIncomplete(
    context: SecurityContext,
    activityId: string
  ): Promise<RepositoryResult<SalesActivity>> {
    const existing = await this.getById(context, activityId);
    if (!existing.success) {
      return existing;
    }

    if (existing.data.type !== 'task') {
      return failedResult(
        new ValidationError('Only tasks can be marked as incomplete', [
          {
            field: 'type',
            message: 'Activity is not a task',
          },
        ])
      );
    }

    return this.update(context, activityId, {
      isCompleted: false,
      completedAt: undefined,
    });
  }

  // ============================================
  // Timeline Methods
  // ============================================

  /**
   * Get chronological timeline for a specific entity
   */
  async getTimeline(
    context: SecurityContext,
    entityType: EntityType,
    entityId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    const fieldMap: Record<EntityType, string> = {
      deal: 'dealId',
      client: 'clientId',
      lead: 'leadId',
      company: 'companyId',
    };

    const field = fieldMap[entityType];
    if (!field) {
      return failedResult(
        new InvalidArgumentError(`Invalid entity type: ${entityType}`)
      );
    }

    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field, operator: '==', value: entityId },
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
    });
  }

  /**
   * Get unified timeline across multiple related entities
   * Useful for showing all activities for a deal AND its client
   */
  async getUnifiedTimeline(
    context: SecurityContext,
    params: {
      dealId?: string;
      clientId?: string;
      companyId?: string;
      leadId?: string;
    },
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    // Get all activities, then filter client-side
    // Firestore doesn't support OR queries across different fields
    const result = await this.getAll(context, {
      ...options,
      limit: undefined, // Get all for merging
      orderBy: { field: 'createdAt', direction: 'desc' },
    });

    if (!result.success) {
      return result;
    }

    // Filter activities that match any of the provided IDs
    const filtered = result.data.data.filter((activity) => {
      if (params.dealId && activity.dealId === params.dealId) return true;
      if (params.clientId && activity.clientId === params.clientId) return true;
      if (params.companyId && activity.companyId === params.companyId) return true;
      if (params.leadId && activity.leadId === params.leadId) return true;
      return false;
    });

    // Sort by createdAt descending
    filtered.sort((a, b) => {
      const dateA = a.createdAt instanceof Date ? a.createdAt : new Date(a.createdAt);
      const dateB = b.createdAt instanceof Date ? b.createdAt : new Date(b.createdAt);
      return dateB.getTime() - dateA.getTime();
    });

    // Apply limit if specified
    const limitedResults = options.limit
      ? filtered.slice(0, options.limit)
      : filtered;

    return successResult({
      data: limitedResults,
      lastDoc: null,
      hasMore: options.limit ? filtered.length > options.limit : false,
    });
  }

  // ============================================
  // Recent Activities
  // ============================================

  /**
   * Get recent activities (last N days)
   */
  async getRecent(
    context: SecurityContext,
    days: number = 7,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<SalesActivity>>> {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'createdAt', operator: '>=', value: Timestamp.fromDate(startDate) },
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
    });
  }
}

// Export singleton instance factory
let activityRepositoryInstance: ActivityRepository | null = null;

export function getActivityRepository(): ActivityRepository {
  if (!activityRepositoryInstance) {
    activityRepositoryInstance = new ActivityRepository();
  }
  return activityRepositoryInstance;
}
