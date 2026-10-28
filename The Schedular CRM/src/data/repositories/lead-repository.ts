/**
 * Lead Repository
 * Firestore data access for sales leads with full CRUD and conversion support
 *
 * Agent CRM-03 Implementation
 * Dependencies: Agent CRM-01 (base repository)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { Timestamp, writeBatch, getDocs } from 'firebase/firestore';
import { getFirebaseDb } from '../../lib/firebase';
import { ShareableRepository, isPrivileged } from './access-control';
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
  AuthorizationError,
} from '../errors/repository-errors';
import { prepareForUpdate, MAX_BATCH_SIZE, buildQuery } from './firestore-utils';
import type { Lead, LeadStatus, LeadSource } from '../../types/models';
import { isDuplicatePreventionEnabled } from '../../config/features';

// ============================================
// Lead-Specific Types
// ============================================

/**
 * Valid status transitions for leads
 * Prevents invalid workflow transitions
 */
const VALID_STATUS_TRANSITIONS: Record<LeadStatus, LeadStatus[]> = {
  new: ['contacted', 'qualified', 'unqualified'],
  contacted: ['qualified', 'unqualified', 'new'],
  qualified: ['converted', 'unqualified', 'contacted'],
  unqualified: ['new', 'contacted', 'qualified'],
  converted: [], // Terminal state - cannot transition from converted
};

/**
 * Filter options specific to leads
 */
export interface LeadFilterOptions {
  status?: LeadStatus;
  source?: LeadSource;
  assigneeId?: string;
  search?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
  tags?: string[];
}

// ============================================
// Lead Validator
// ============================================

/**
 * Email validation regex pattern
 */
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

const normalizePhone = (phone?: string): string | null => {
  if (!phone) return null;
  return phone.replace(/\D/g, '');
};

/**
 * Validate lead data
 */
export function validateLead(data: Partial<Lead>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Required fields validation (only for create operations where these are undefined)
  if (data.firstName !== undefined && !data.firstName?.trim()) {
    errors.push({
      field: 'firstName',
      message: 'First name is required',
      code: 'REQUIRED',
    });
  }

  if (data.lastName !== undefined && !data.lastName?.trim()) {
    errors.push({
      field: 'lastName',
      message: 'Last name is required',
      code: 'REQUIRED',
    });
  }

  if (data.email !== undefined && !data.email?.trim()) {
    errors.push({
      field: 'email',
      message: 'Email is required',
      code: 'REQUIRED',
    });
  }

  // Email format validation
  if (data.email && !EMAIL_REGEX.test(data.email)) {
    errors.push({
      field: 'email',
      message: 'Invalid email format',
      code: 'INVALID_FORMAT',
    });
  }

  const phone = data.phone?.trim();
  if (phone && !PHONE_REGEX.test(phone)) {
    errors.push({
      field: 'phone',
      message: 'Invalid phone number format',
      code: 'INVALID_FORMAT',
    });
  } else if (phone) {
    const normalized = normalizePhone(phone) || '';
    if (normalized && normalized.length < MIN_PHONE_DIGITS) {
      errors.push({
        field: 'phone',
        message: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
        code: 'INVALID_FORMAT',
      });
    }
  }

  // Score validation (if provided)
  if (data.score !== undefined && (data.score < 0 || data.score > 100)) {
    errors.push({
      field: 'score',
      message: 'Score must be between 0 and 100',
      code: 'OUT_OF_RANGE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate required fields for lead creation
 */
export function validateLeadCreate(
  data: Partial<Lead>
): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Check required fields exist
  if (!data.firstName?.trim()) {
    errors.push({
      field: 'firstName',
      message: 'First name is required',
      code: 'REQUIRED',
    });
  }

  if (!data.lastName?.trim()) {
    errors.push({
      field: 'lastName',
      message: 'Last name is required',
      code: 'REQUIRED',
    });
  }

  if (!data.email?.trim()) {
    errors.push({
      field: 'email',
      message: 'Email is required',
      code: 'REQUIRED',
    });
  } else if (!EMAIL_REGEX.test(data.email)) {
    errors.push({
      field: 'email',
      message: 'Invalid email format',
      code: 'INVALID_FORMAT',
    });
  }

  const phone = data.phone?.trim();
  if (phone && !PHONE_REGEX.test(phone)) {
    errors.push({
      field: 'phone',
      message: 'Invalid phone number format',
      code: 'INVALID_FORMAT',
    });
  } else if (phone) {
    const normalized = normalizePhone(phone) || '';
    if (normalized && normalized.length < MIN_PHONE_DIGITS) {
      errors.push({
        field: 'phone',
        message: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
        code: 'INVALID_FORMAT',
      });
    }
  }

  // Score validation (if provided)
  if (data.score !== undefined && (data.score < 0 || data.score > 100)) {
    errors.push({
      field: 'score',
      message: 'Score must be between 0 and 100',
      code: 'OUT_OF_RANGE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Lead Repository Class
// ============================================

/**
 * LeadRepository
 * Provides CRUD operations and lead-specific queries
 */
export class LeadRepository extends ShareableRepository<Lead> {
  protected entityName = 'lead';
  protected sensitiveFields: Array<keyof Lead> = ['notes', 'customFields'];
  private readonly duplicateQueryLimit = 10;

  constructor() {
    super({
      collectionName: 'leads',
      softDelete: false,
    });
    // Set the validator for update operations
    this.setValidator(validateLead as Validator<Lead>);
  }

  private async findDuplicateConflicts(
    context: SecurityContext,
    data: Partial<Lead>,
    excludeId?: string
  ): Promise<{ duplicateCount: number; conflictFields: Array<'email' | 'phone'> }> {
    if (!isDuplicatePreventionEnabled()) {
      return { duplicateCount: 0, conflictFields: [] };
    }

    const normalizedEmail = data.email?.toLowerCase().trim();
    const normalizedPhone = normalizePhone(data.phone);

    if (!normalizedEmail && !normalizedPhone) {
      return { duplicateCount: 0, conflictFields: [] };
    }

    const conflictFields = new Set<'email' | 'phone'>();
    const seenIds = new Set<string>();
    const collectionRef = this.getCollectionRef(context);

    const queryForIdentifier = async (
      field: 'email' | 'phone',
      value: string
    ): Promise<void> => {
      const snapshot = await getDocs(
        buildQuery(collectionRef, {
          where: [{ field, operator: '==', value }],
          limit: this.duplicateQueryLimit,
        })
      );

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const candidate = (data as unknown as Lead)[field];
        if (!candidate) return;

        const normalizedCandidate =
          field === 'phone' ? normalizePhone(candidate) : String(candidate).toLowerCase();
        const normalizedValue = field === 'phone' ? value : value.toLowerCase();

        if (normalizedCandidate !== normalizedValue) return;

        if (excludeId && doc.id === excludeId) {
          return;
        }
        if (seenIds.has(doc.id)) {
          return;
        }
        seenIds.add(doc.id);
        conflictFields.add(field);
      });
    };

    const lookups: Array<Promise<void>> = [];
    if (normalizedEmail) {
      lookups.push(queryForIdentifier('email', normalizedEmail));
    }
    if (normalizedPhone) {
      lookups.push(queryForIdentifier('phone', normalizedPhone));
    }

    await Promise.all(lookups);

    return { duplicateCount: seenIds.size, conflictFields: Array.from(conflictFields) };
  }

  private buildDuplicateError(conflictFields: Array<'email' | 'phone'>): ValidationError {
    const errors = conflictFields.map((field) => ({
      field,
      message: `Potential duplicate ${field === 'email' ? 'email' : 'phone'} detected`,
    }));
    return ValidationError.fromErrors(errors);
  }

  private canOverrideDuplicates(context: SecurityContext, allowDuplicate?: boolean): boolean {
    return Boolean(allowDuplicate) && this.isAdminOrOwner(context);
  }

  // ============================================
  // Create Override (with required field validation)
  // ============================================

  /**
   * Create a new lead with required field validation
   */
  async create(
    context: SecurityContext,
    data: Omit<Lead, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Lead>> {
    const { allowDuplicate, ...leadInput } = (data as Omit<
      Lead,
      'id' | 'createdAt' | 'updatedAt'
    > & { allowDuplicate?: boolean }) || {};

    // Validate required fields for creation
    const validation = validateLeadCreate(leadInput);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Set defaults
    const leadData = {
      ...leadInput,
      status: leadInput.status || 'new',
      source: leadInput.source || 'other',
      tags: leadInput.tags || [],
    } as Omit<Lead, 'id' | 'createdAt' | 'updatedAt'>;

    const normalizedPhone = normalizePhone(leadData.phone as string | undefined);
    if (leadData.phone !== undefined) {
      leadData.phone = normalizedPhone || undefined;
    }

    const { duplicateCount, conflictFields } = await this.findDuplicateConflicts(
      context,
      leadData
    );
    const allowOverride = this.canOverrideDuplicates(context, allowDuplicate);

    if (duplicateCount > 0 && !allowOverride) {
      return failedResult(this.buildDuplicateError(conflictFields));
    }

    const result = await super.create(context, leadData, customId);

    if (result.success && duplicateCount > 0 && allowOverride) {
      await this.logAudit(context, 'create', result.data.id, {
        duplicateOverride: true,
        conflictFields,
        duplicateCount,
      });
    }

    return result;
  }

  // ============================================
  // Update Override (duplicate guard)
  // ============================================

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<Lead, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<Lead>> {
    const { allowDuplicate, ...updateData } = (data as Partial<
      Omit<Lead, 'id' | 'createdAt'>
    > & { allowDuplicate?: boolean }) || {};

    const existing = await this.getById(context, id);
    if (!existing.success) {
      return existing;
    }

    const sanitizedUpdate = { ...updateData };
    if (updateData.phone !== undefined) {
      const normalized = normalizePhone(updateData.phone as string | undefined);
      sanitizedUpdate.phone = normalized || undefined;
    }

    const merged = { ...existing.data, ...sanitizedUpdate };
    const { duplicateCount, conflictFields } = await this.findDuplicateConflicts(
      context,
      merged,
      id
    );
    const allowOverride = this.canOverrideDuplicates(context, allowDuplicate);

    if (duplicateCount > 0 && !allowOverride) {
      return failedResult(this.buildDuplicateError(conflictFields));
    }

    const result = await super.update(context, id, sanitizedUpdate);

    if (result.success && duplicateCount > 0 && allowOverride) {
      await this.logAudit(context, 'update', id, {
        duplicateOverride: true,
        conflictFields,
        duplicateCount,
      });
    }

    return result;
  }

  // ============================================
  // Filter Methods
  // ============================================

  /**
   * Get leads filtered by status
   */
  async getByStatus(
    context: SecurityContext,
    status: LeadStatus,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'status', operator: '==', value: status },
      ],
    });
  }

  /**
   * Get leads assigned to a specific user
   */
  async getByAssignee(
    context: SecurityContext,
    assigneeId: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'assigneeId', operator: '==', value: assigneeId },
      ],
    });
  }

  /**
   * Get leads filtered by source
   */
  async getBySource(
    context: SecurityContext,
    source: LeadSource,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'source', operator: '==', value: source },
      ],
    });
  }

  /**
   * Get leads with combined filters
   * Supports status + assignee + date range filtering
   */
  async getFiltered(
    context: SecurityContext,
    filters: LeadFilterOptions,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    const whereClause = options.where || [];

    if (filters.status) {
      whereClause.push({ field: 'status', operator: '==', value: filters.status });
    }

    if (filters.source) {
      whereClause.push({ field: 'source', operator: '==', value: filters.source });
    }

    if (filters.assigneeId) {
      whereClause.push({ field: 'assigneeId', operator: '==', value: filters.assigneeId });
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

    // Note: Firestore doesn't support array-contains-any with other equality filters
    // Tags filtering would need to be done client-side or use a different approach

    return this.getAll(context, {
      ...options,
      where: whereClause,
    });
  }

  // ============================================
  // Search Methods
  // ============================================

  /**
   * Search leads by name, email, or company
   * Note: Firestore doesn't support full-text search natively.
   * This implementation uses prefix matching for basic search.
   * For production, consider Algolia or similar.
   */
  async search(
    context: SecurityContext,
    query: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    if (!query || query.trim().length === 0) {
      return this.getAll(context, options);
    }

    const normalizedQuery = query.toLowerCase().trim();

    // Get all leads and filter client-side
    // In production, use a search service like Algolia
    const result = await this.getAll(context, {
      ...options,
      limit: undefined, // Get all for search
    });

    if (!result.success) {
      return result;
    }

    // Filter by name, email, or company
    const filtered = result.data.data.filter((lead) => {
      const fullName = `${lead.firstName} ${lead.lastName}`.toLowerCase();
      const email = lead.email?.toLowerCase() || '';
      const company = lead.companyName?.toLowerCase() || '';

      return (
        fullName.includes(normalizedQuery) ||
        email.includes(normalizedQuery) ||
        company.includes(normalizedQuery)
      );
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
  // Status Management
  // ============================================

  /**
   * Update lead status with transition validation
   */
  async updateStatus(
    context: SecurityContext,
    leadId: string,
    newStatus: LeadStatus
  ): Promise<RepositoryResult<Lead>> {
    // Get current lead
    const existing = await this.getById(context, leadId);
    if (!existing.success) {
      return existing;
    }

    const currentStatus = existing.data.status;

    // Validate status transition
    const validTransitions = VALID_STATUS_TRANSITIONS[currentStatus];
    if (!validTransitions.includes(newStatus)) {
      return failedResult(
        new ValidationError(
          `Invalid status transition from '${currentStatus}' to '${newStatus}'`,
          [
            {
              field: 'status',
              message: `Cannot transition from '${currentStatus}' to '${newStatus}'. Valid transitions: ${validTransitions.join(', ') || 'none'}`,
            },
          ]
        )
      );
    }

    return this.update(context, leadId, { status: newStatus });
  }

  // ============================================
  // Assignment Methods
  // ============================================

  /**
   * Assign lead to a user
   */
  async assignTo(
    context: SecurityContext,
    leadId: string,
    assigneeId: string,
    assigneeName: string
  ): Promise<RepositoryResult<Lead>> {
    return this.update(context, leadId, {
      assigneeId,
      assigneeName,
    });
  }

  /**
   * Bulk assign multiple leads to a user
   */
  async bulkAssign(
    context: SecurityContext,
    leadIds: string[],
    assigneeId: string,
    assigneeName: string
  ): Promise<RepositoryResult<{ successCount: number; failedIds: string[] }>> {
    if (!isPrivileged(context)) {
      return failedResult(
        new AuthorizationError('Bulk assign requires admin/manager/owner permissions')
      );
    }

    if (leadIds.length === 0) {
      return successResult({ successCount: 0, failedIds: [] });
    }

    if (leadIds.length > MAX_BATCH_SIZE) {
      return failedResult(
        new InvalidArgumentError(
          `Batch size ${leadIds.length} exceeds maximum of ${MAX_BATCH_SIZE}`
        )
      );
    }

    const db = getFirebaseDb();
    if (!db) {
      return failedResult(new Error('Firestore not initialized'));
    }

    const batch = writeBatch(db);
    const failedIds: string[] = [];

    for (const leadId of leadIds) {
      try {
        const docRef = this.getDocRef(context, leadId);
        const updateData = prepareForUpdate({
          assigneeId,
          assigneeName,
        });
        batch.update(docRef, updateData);
      } catch {
        failedIds.push(leadId);
      }
    }

    try {
      await batch.commit();
      await this.logAudit(context, 'batch', null, {
        action: 'bulkAssign',
        leadIds,
        assigneeId,
        assigneeName,
      });

      return successResult({
        successCount: leadIds.length - failedIds.length,
        failedIds,
      });
    } catch (error) {
      return failedResult(error, 'Bulk assign failed');
    }
  }

  /**
   * Bulk update status for multiple leads
   */
  async bulkUpdateStatus(
    context: SecurityContext,
    leadIds: string[],
    status: LeadStatus
  ): Promise<RepositoryResult<{ successCount: number; failedIds: string[] }>> {
    if (!isPrivileged(context)) {
      return failedResult(
        new AuthorizationError('Bulk status updates require admin/manager/owner permissions')
      );
    }

    if (leadIds.length === 0) {
      return successResult({ successCount: 0, failedIds: [] });
    }

    if (leadIds.length > MAX_BATCH_SIZE) {
      return failedResult(
        new InvalidArgumentError(
          `Batch size ${leadIds.length} exceeds maximum of ${MAX_BATCH_SIZE}`
        )
      );
    }

    const db = getFirebaseDb();
    if (!db) {
      return failedResult(new Error('Firestore not initialized'));
    }

    const batch = writeBatch(db);
    const failedIds: string[] = [];

    // Note: For bulk operations, we skip individual status transition validation
    // as it would require N reads. Status transitions should be validated at UI level.
    for (const leadId of leadIds) {
      try {
        const docRef = this.getDocRef(context, leadId);
        const updateData = prepareForUpdate({ status });
        batch.update(docRef, updateData);
      } catch {
        failedIds.push(leadId);
      }
    }

    try {
      await batch.commit();
      await this.logAudit(context, 'batch', null, {
        action: 'bulkUpdateStatus',
        leadIds,
        status,
      });

      return successResult({
        successCount: leadIds.length - failedIds.length,
        failedIds,
      });
    } catch (error) {
      return failedResult(error, 'Bulk status update failed');
    }
  }

  // ============================================
  // Conversion Methods
  // ============================================

  /**
   * Mark lead as converted
   * Sets conversion metadata and updates status to 'converted'
   */
  async markConverted(
    context: SecurityContext,
    leadId: string,
    clientId: string,
    dealId?: string
  ): Promise<RepositoryResult<Lead>> {
    // Validate lead exists and is not already converted
    const existing = await this.getById(context, leadId);
    if (!existing.success) {
      return existing;
    }

    if (existing.data.status === 'converted') {
      return failedResult(
        new ValidationError('Lead is already converted', [
          {
            field: 'status',
            message: 'Cannot convert a lead that is already converted',
          },
        ])
      );
    }

    // Validate clientId is provided
    if (!clientId || clientId.trim().length === 0) {
      return failedResult(
        new ValidationError('Client ID is required for conversion', [
          {
            field: 'clientId',
            message: 'Client ID is required',
          },
        ])
      );
    }

    const updateData: Partial<Lead> = {
      status: 'converted',
      convertedToClientId: clientId,
      convertedAt: new Date(),
    };

    if (dealId) {
      updateData.convertedToDealId = dealId;
    }

    const result = await this.update(context, leadId, updateData);

    if (result.success) {
      await this.logAudit(context, 'update', leadId, {
        action: 'conversion',
        clientId,
        dealId,
      });
    }

    return result;
  }

  /**
   * Get converted leads for a specific client
   */
  async getByConvertedClient(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      where: [
        { field: 'convertedToClientId', operator: '==', value: clientId },
      ],
    });
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Get unassigned leads
   */
  async getUnassigned(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'assigneeId', operator: '==', value: null },
      ],
    });
  }

  /**
   * Get leads by tags (any match)
   * Note: Uses array-contains for single tag matching
   */
  async getByTag(
    context: SecurityContext,
    tag: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'tags', operator: 'array-contains', value: tag },
      ],
    });
  }

  /**
   * Get leads sorted by score (descending)
   */
  async getByScore(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      orderBy: { field: 'score', direction: 'desc' },
    });
  }

  /**
   * Get leads sorted by last name
   */
  async getByLastName(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<Lead>>> {
    return this.getAll(context, {
      ...options,
      orderBy: { field: 'lastName', direction: 'asc' },
    });
  }
}

// Export singleton instance factory
let leadRepositoryInstance: LeadRepository | null = null;

export function getLeadRepository(): LeadRepository {
  if (!leadRepositoryInstance) {
    leadRepositoryInstance = new LeadRepository();
  }
  return leadRepositoryInstance;
}

// Export for testing
export { VALID_STATUS_TRANSITIONS };
