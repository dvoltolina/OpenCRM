/**
 * Contact Repository
 * Manages client/contact records with CRM-specific features
 *
 * Note: This uses the shared 'clients' collection from the Scheduler
 * but adds CRM-specific query and relationship methods.
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp, collection } from 'firebase/firestore';
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
import type { Client, ClientLifecycle, LeadSource, Deal, SalesActivity } from '../../types/models';
import { businessPath } from '../../lib/collections';
import { isDuplicatePreventionEnabled } from '../../config/features';

// ============================================
// Types
// ============================================

export interface ContactFilters {
  lifecycle?: ClientLifecycle;
  companyId?: string;
  leadSource?: LeadSource;
  tags?: string[];
  hasEmail?: boolean;
  hasPhone?: boolean;
  /** Filter by lead status (for unified funnel view) */
  leadStatus?: string;
  /** Filter to only contacts with any lead status set (not null) */
  hasLeadStatus?: boolean;
  /** Filter by assigned rep */
  assignedRepUid?: string;
}

export interface ContactWithRelations extends Client {
  dealCount?: number;
  openDealValueCents?: number;
  activityCount?: number;
  lastActivity?: SalesActivity;
}

// ============================================
// Validation
// ============================================

const PHONE_REGEX = /^[+]?[\d\s\-().]+$/;
const MIN_PHONE_DIGITS = 7;

const normalizePhone = (phone?: string): string | null => {
  if (!phone) return null;
  return phone.replace(/\D/g, '');
};

const contactValidator: Validator<Client> = (data: Partial<Client>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.firstName !== undefined && !data.firstName?.trim()) {
    errors.push({ field: 'firstName', message: 'First name is required', code: 'REQUIRED' });
  }

  if (data.lastName !== undefined && !data.lastName?.trim()) {
    errors.push({ field: 'lastName', message: 'Last name is required', code: 'REQUIRED' });
  }

  if (data.email !== undefined && !data.email?.trim()) {
    errors.push({ field: 'email', message: 'Email is required', code: 'REQUIRED' });
  } else if (data.email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      errors.push({ field: 'email', message: 'Invalid email format', code: 'INVALID_FORMAT' });
    }
  }

  const phone = data.phone?.trim();
  if (phone && !PHONE_REGEX.test(phone)) {
    errors.push({ field: 'phone', message: 'Invalid phone number format', code: 'INVALID_FORMAT' });
  } else if (phone) {
    const normalizedPhone = normalizePhone(phone) || '';
    if (normalizedPhone && normalizedPhone.length < MIN_PHONE_DIGITS) {
      errors.push({
        field: 'phone',
        message: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
        code: 'INVALID_FORMAT',
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateContactCreate: Validator<Client> = (data: Partial<Client>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.firstName?.trim()) {
    errors.push({ field: 'firstName', message: 'First name is required', code: 'REQUIRED' });
  }

  if (!data.lastName?.trim()) {
    errors.push({ field: 'lastName', message: 'Last name is required', code: 'REQUIRED' });
  }

  if (!data.email?.trim()) {
    errors.push({ field: 'email', message: 'Email is required', code: 'REQUIRED' });
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      errors.push({ field: 'email', message: 'Invalid email format', code: 'INVALID_FORMAT' });
    }
  }

  const phone = data.phone?.trim();
  if (phone && !PHONE_REGEX.test(phone)) {
    errors.push({ field: 'phone', message: 'Invalid phone number format', code: 'INVALID_FORMAT' });
  } else if (phone) {
    const normalizedPhone = normalizePhone(phone) || '';
    if (normalizedPhone && normalizedPhone.length < MIN_PHONE_DIGITS) {
      errors.push({
        field: 'phone',
        message: `Phone number must include at least ${MIN_PHONE_DIGITS} digits`,
        code: 'INVALID_FORMAT',
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Contact Repository
// ============================================

/**
 * Contact Repository
 * Handles CRUD operations for client/contact records with CRM features
 */
export class ContactRepository extends ShareableRepository<Client> {
  protected entityName = 'contact';
  protected sensitiveFields: Array<keyof Client> = ['crmNotes', 'customFields'];
  private readonly duplicateQueryLimit = 10;

  constructor() {
    // Uses 'clients' collection - shared with Scheduler
    super({ collectionName: 'clients' });
    this.setValidator(contactValidator);
  }

  private async findDuplicateConflicts(
    context: SecurityContext,
    data: Partial<Client>,
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
        const candidate = (data as unknown as Client)[field];
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
    return ValidationError.fromErrors(
      conflictFields.map((field) => ({
        field,
        message: `Potential duplicate ${field === 'email' ? 'email' : 'phone'} detected`,
      }))
    );
  }

  private canOverrideDuplicates(context: SecurityContext, allowDuplicate?: boolean): boolean {
    return Boolean(allowDuplicate) && (context.userRole === 'owner' || context.userRole === 'admin');
  }

  async create(
    context: SecurityContext,
    data: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Client>> {
    const { allowDuplicate, ...contactData } = (data as Omit<
      Client,
      'id' | 'createdAt' | 'updatedAt'
    > & { allowDuplicate?: boolean }) || {};

    const validation = validateContactCreate(contactData);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    const normalizedPhone = normalizePhone(contactData.phone as string | undefined);
    if (contactData.phone !== undefined) {
      contactData.phone = normalizedPhone || undefined;
    }

    const { duplicateCount, conflictFields } = await this.findDuplicateConflicts(
      context,
      contactData
    );
    const allowOverride = this.canOverrideDuplicates(context, allowDuplicate);

    if (duplicateCount > 0 && !allowOverride) {
      return failedResult(this.buildDuplicateError(conflictFields));
    }

    const result = await super.create(context, contactData, customId);

    if (result.success && duplicateCount > 0 && allowOverride) {
      await this.logAudit(context, 'create', result.data.id, {
        duplicateOverride: true,
        conflictFields,
        duplicateCount,
      });
    }

    return result;
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<Client, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<Client>> {
    const { allowDuplicate, ...updateData } = (data as Partial<
      Omit<Client, 'id' | 'createdAt'>
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
  // Query Methods
  // ============================================

  /**
   * Get contacts by lifecycle stage
   */
  async getByLifecycle(
    context: SecurityContext,
    lifecycle: ClientLifecycle
  ): Promise<RepositoryResult<Client[]>> {
    try {
      if (this.useLocalDemoData) {
        const contacts = this.filterAccessibleContacts(context, this.getLocalDemoPage(context, {
          where: [{ field: 'lifecycle', operator: '==', value: lifecycle }],
          orderBy: { field: 'lastName', direction: 'asc' },
        }).data);
        return successResult(contacts);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'lifecycle', operator: '==', value: lifecycle }],
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const contacts = this.filterAccessibleContacts(context, this.snapshotToContacts(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByLifecycle', lifecycle });

      return successResult(contacts);
    } catch (error) {
      return failedResult(error, 'Failed to get contacts by lifecycle');
    }
  }

  /**
   * Get contacts for a company
   */
  async getByCompany(
    context: SecurityContext,
    companyId: string
  ): Promise<RepositoryResult<Client[]>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }

      if (this.useLocalDemoData) {
        const contacts = this.filterAccessibleContacts(context, this.getLocalDemoPage(context, {
          where: [{ field: 'companyId', operator: '==', value: companyId }],
          orderBy: { field: 'lastName', direction: 'asc' },
        }).data);
        return successResult(contacts);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'companyId', operator: '==', value: companyId }],
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const contacts = this.filterAccessibleContacts(context, this.snapshotToContacts(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByCompany', companyId });

      return successResult(contacts);
    } catch (error) {
      return failedResult(error, 'Failed to get contacts by company');
    }
  }

  /**
   * Get contacts by lead source
   */
  async getBySource(
    context: SecurityContext,
    source: LeadSource
  ): Promise<RepositoryResult<Client[]>> {
    try {
      if (this.useLocalDemoData) {
        const contacts = this.filterAccessibleContacts(context, this.getLocalDemoPage(context, {
          where: [{ field: 'leadSource', operator: '==', value: source }],
          orderBy: { field: 'lastName', direction: 'asc' },
        }).data);
        return successResult(contacts);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'leadSource', operator: '==', value: source }],
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const contacts = this.filterAccessibleContacts(context, this.snapshotToContacts(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getBySource', source });

      return successResult(contacts);
    } catch (error) {
      return failedResult(error, 'Failed to get contacts by source');
    }
  }

  /**
   * Get contacts with a specific tag
   */
  async getByTag(
    context: SecurityContext,
    tag: string
  ): Promise<RepositoryResult<Client[]>> {
    try {
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      if (this.useLocalDemoData) {
        const contacts = this.filterAccessibleContacts(context, this.getLocalDemoPage(context, {
          where: [{ field: 'tags', operator: 'array-contains', value: tag }],
          orderBy: { field: 'lastName', direction: 'asc' },
        }).data);
        return successResult(contacts);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'tags', operator: 'array-contains', value: tag }],
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const contacts = this.filterAccessibleContacts(context, this.snapshotToContacts(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByTag', tag });

      return successResult(contacts);
    } catch (error) {
      return failedResult(error, 'Failed to get contacts by tag');
    }
  }

  /**
   * Search contacts by name, email, or phone
   */
  async search(
    context: SecurityContext,
    query: string
  ): Promise<RepositoryResult<Client[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      const normalizedQuery = query.toLowerCase().trim();

      if (!normalizedQuery) {
        return successResult(allResult.data.data);
      }

      const filtered = allResult.data.data.filter((contact) => {
        const fullName = `${contact.firstName} ${contact.lastName}`.toLowerCase();
        return (
          fullName.includes(normalizedQuery) ||
          contact.email.toLowerCase().includes(normalizedQuery) ||
          contact.phone?.toLowerCase().includes(normalizedQuery) ||
          contact.companyName?.toLowerCase().includes(normalizedQuery)
        );
      });

      await this.logAudit(context, 'list', null, {
        action: 'search',
        query,
        resultCount: filtered.length,
      });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to search contacts');
    }
  }

  /**
   * Get contacts with combined filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: ContactFilters
  ): Promise<RepositoryResult<Client[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      let filtered = allResult.data.data;

      if (filters.lifecycle) {
        filtered = filtered.filter((c) => c.lifecycle === filters.lifecycle);
      }

      if (filters.companyId) {
        filtered = filtered.filter((c) => c.companyId === filters.companyId);
      }

      if (filters.leadSource) {
        filtered = filtered.filter((c) => c.leadSource === filters.leadSource);
      }

      if (filters.tags && filters.tags.length > 0) {
        filtered = filtered.filter((c) =>
          filters.tags!.some((tag) => c.tags.includes(tag))
        );
      }

      if (filters.hasEmail !== undefined) {
        filtered = filtered.filter((c) =>
          filters.hasEmail ? !!c.email : !c.email
        );
      }

      if (filters.hasPhone !== undefined) {
        filtered = filtered.filter((c) =>
          filters.hasPhone ? !!c.phone : !c.phone
        );
      }

      // Filter by specific lead status (unified funnel)
      if (filters.leadStatus) {
        filtered = filtered.filter((c) => c.leadStatus === filters.leadStatus);
      }

      // Filter to only contacts with any lead status set (for Leads view)
      if (filters.hasLeadStatus !== undefined) {
        filtered = filtered.filter((c) =>
          filters.hasLeadStatus ? !!c.leadStatus : !c.leadStatus
        );
      }

      // Filter by assigned rep (for rep-specific views)
      if (filters.assignedRepUid) {
        filtered = filtered.filter((c) => c.assignedRepUid === filters.assignedRepUid);
      }

      await this.logAudit(context, 'list', null, { action: 'getFiltered', filters });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to get filtered contacts');
    }
  }

  /**
   * Get recently contacted contacts
   */
  async getRecentlyContacted(
    context: SecurityContext,
    days: number = 30
  ): Promise<RepositoryResult<Client[]>> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'lastContactedAt', operator: '>=', value: Timestamp.fromDate(cutoffDate) },
        ],
        orderBy: { field: 'lastContactedAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const contacts = this.filterAccessibleContacts(context, this.snapshotToContacts(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getRecentlyContacted', days });

      return successResult(contacts);
    } catch (error) {
      return failedResult(error, 'Failed to get recently contacted');
    }
  }

  /**
   * Get contacts not contacted in N days
   */
  async getStaleContacts(
    context: SecurityContext,
    days: number = 30
  ): Promise<RepositoryResult<Client[]>> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      // Get all contacts and filter client-side
      // (Firestore doesn't support OR queries or null checks with inequality)
      const allResult = await this.getAll(context);
      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      const filtered = allResult.data.data.filter((contact) => {
        // Include if never contacted or contacted before cutoff
        if (!contact.lastContactedAt) return true;
        return contact.lastContactedAt < cutoffDate;
      });

      await this.logAudit(context, 'list', null, { action: 'getStaleContacts', days });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to get stale contacts');
    }
  }

  // ============================================
  // Lifecycle Management
  // ============================================

  /**
   * Update contact lifecycle stage
   */
  async updateLifecycle(
    context: SecurityContext,
    contactId: string,
    lifecycle: ClientLifecycle
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }

      const result = await this.update(context, contactId, { lifecycle });

      if (result.success) {
        await this.logAudit(context, 'update', contactId, { action: 'updateLifecycle', lifecycle });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update lifecycle');
    }
  }

  /**
   * Update last contacted timestamp
   */
  async updateLastContacted(
    context: SecurityContext,
    contactId: string
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }

      const result = await this.update(context, contactId, {
        lastContactedAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', contactId, { action: 'updateLastContacted' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update last contacted');
    }
  }

  // ============================================
  // Company Relationship
  // ============================================

  /**
   * Link contact to a company
   */
  async linkToCompany(
    context: SecurityContext,
    contactId: string,
    companyId: string,
    companyName: string
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }
      if (!companyName?.trim()) {
        return failedResult(new InvalidArgumentError('Company name is required', 'companyName'));
      }

      const result = await this.update(context, contactId, {
        companyId,
        companyName: companyName.trim(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', contactId, {
          action: 'linkToCompany',
          companyId,
          companyName,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to link contact to company');
    }
  }

  /**
   * Unlink contact from company
   */
  async unlinkFromCompany(
    context: SecurityContext,
    contactId: string
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }

      const result = await this.update(context, contactId, {
        companyId: undefined,
        companyName: undefined,
      });

      if (result.success) {
        await this.logAudit(context, 'update', contactId, { action: 'unlinkFromCompany' });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to unlink contact from company');
    }
  }

  // ============================================
  // Tag Management
  // ============================================

  /**
   * Add a tag to a contact
   */
  async addTag(
    context: SecurityContext,
    contactId: string,
    tag: string
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      const existingResult = await this.getById(context, contactId);
      if (!existingResult.success) {
        return existingResult;
      }

      const contact = existingResult.data;
      const normalizedTag = tag.trim().toLowerCase();

      if (contact.tags.includes(normalizedTag)) {
        return successResult(contact);
      }

      const updatedTags = [...contact.tags, normalizedTag];
      return this.update(context, contactId, { tags: updatedTags });
    } catch (error) {
      return failedResult(error, 'Failed to add tag');
    }
  }

  /**
   * Remove a tag from a contact
   */
  async removeTag(
    context: SecurityContext,
    contactId: string,
    tag: string
  ): Promise<RepositoryResult<Client>> {
    try {
      if (!isValidDocumentId(contactId)) {
        return failedResult(new InvalidArgumentError('Invalid contact ID', 'contactId'));
      }
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      const existingResult = await this.getById(context, contactId);
      if (!existingResult.success) {
        return existingResult;
      }

      const contact = existingResult.data;
      const normalizedTag = tag.trim().toLowerCase();
      const updatedTags = contact.tags.filter((t) => t !== normalizedTag);

      if (updatedTags.length === contact.tags.length) {
        return successResult(contact);
      }

      return this.update(context, contactId, { tags: updatedTags });
    } catch (error) {
      return failedResult(error, 'Failed to remove tag');
    }
  }

  // ============================================
  // Relationship Queries
  // ============================================

  /**
   * Get contact with relationship data
   */
  async getWithRelations(
    context: SecurityContext,
    contactId: string
  ): Promise<RepositoryResult<ContactWithRelations>> {
    try {
      const contactResult = await this.getById(context, contactId);
      if (!contactResult.success) {
        return contactResult;
      }

      // Query deals for this contact
      const dealsRef = this.getCollectionRefForPath(context, 'deals');
      const dealsQuery = buildQuery(dealsRef, {
        where: [{ field: 'clientId', operator: '==', value: contactId }],
      });
      const dealsSnapshot = await getDocs(dealsQuery);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(dealsSnapshot));

      // Query activities for this contact
      const activitiesRef = this.getCollectionRefForPath(context, 'sales_activities');
      const activitiesQuery = buildQuery(activitiesRef, {
        where: [{ field: 'clientId', operator: '==', value: contactId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
        limit: 1,
      });
      const activitiesSnapshot = await getDocs(activitiesQuery);
      const activities = this.filterAccessibleActivities(
        context,
        this.snapshotToActivities(activitiesSnapshot)
      );

      // Count deals and calculate value
      const openDeals = deals.filter((d) => d.status === 'open');
      const openDealValueCents = openDeals.reduce((sum, d) => sum + d.valueCents, 0);

      // Count all activities
      const allActivitiesQuery = buildQuery(activitiesRef, {
        where: [{ field: 'clientId', operator: '==', value: contactId }],
      });
      const allActivitiesSnapshot = await getDocs(allActivitiesQuery);
      const accessibleActivityCount = this.filterAccessibleActivities(
        context,
        this.snapshotToActivities(allActivitiesSnapshot)
      ).length;

      const contactWithRelations: ContactWithRelations = {
        ...contactResult.data,
        dealCount: openDeals.length,
        openDealValueCents,
        activityCount: accessibleActivityCount,
        lastActivity: activities[0],
      };

      return successResult(contactWithRelations);
    } catch (error) {
      return failedResult(error, 'Failed to get contact with relations');
    }
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Get collection reference for a different collection path
   */
  protected getCollectionRefForPath(context: SecurityContext, collectionName: string) {
    return collection(this.db, `${businessPath(context.businessId)}/${collectionName}`);
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleContacts(context: SecurityContext, contacts: Client[]): Client[] {
    return filterAuthorizedEntities(context, contacts, this.sensitiveFields);
  }

  private filterAccessibleDeals(context: SecurityContext, deals: Deal[]): Deal[] {
    return filterAuthorizedEntities(context, deals, ['valueCents', 'wonLostReason', 'notes', 'customFields']);
  }

  private filterAccessibleActivities(
    context: SecurityContext,
    activities: SalesActivity[]
  ): SalesActivity[] {
    return filterAuthorizedEntities(context, activities, ['description']);
  }

  private snapshotToContacts(
    snapshot: QuerySnapshot<DocumentData>
  ): Client[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as Client['visibility']) ?? 'team';
      const ownerId = (data.ownerId as string | undefined) ?? undefined;
      const ownerName = (data.ownerName as string | undefined) ?? undefined;
      return {
        id: doc.id,
        firstName: data.firstName as string,
        lastName: data.lastName as string,
        email: data.email as string,
        phone: data.phone as string | undefined,
        lifecycle: data.lifecycle as ClientLifecycle | undefined,
        tags: (data.tags as string[]) || [],
        userId: data.userId as string | undefined,
        ownerId,
        ownerName,
        teamIds,
        visibility,
        companyId: data.companyId as string | undefined,
        companyName: data.companyName as string | undefined,
        title: data.title as string | undefined,
        address: data.address as Client['address'],
        crmNotes: data.crmNotes as string | undefined,
        lastContactedAt: data.lastContactedAt?.toDate?.() || undefined,
        leadSource: data.leadSource as LeadSource | undefined,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }

  private snapshotToDeals(
    snapshot: QuerySnapshot<DocumentData>
  ): Deal[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as Deal['visibility']) ?? 'team';
      return {
        id: doc.id,
        pipelineId: data.pipelineId as string,
        stageId: data.stageId as string,
        title: data.title as string,
        valueCents: data.valueCents as number,
        currency: data.currency as string,
        probability: data.probability as number,
        expectedCloseDate: data.expectedCloseDate?.toDate?.() || undefined,
        status: data.status as Deal['status'],
        wonLostReason: data.wonLostReason as string | undefined,
        closedAt: data.closedAt?.toDate?.() || undefined,
        clientId: data.clientId as string | undefined,
        clientName: data.clientName as string | undefined,
        companyId: data.companyId as string | undefined,
        companyName: data.companyName as string | undefined,
        assigneeId: data.assigneeId as string | undefined,
        assigneeName: data.assigneeName as string | undefined,
        ownerId: (data.ownerId as string | undefined) ?? (data.assigneeId as string | undefined),
        ownerName: (data.ownerName as string | undefined) ?? (data.assigneeName as string | undefined),
        teamIds,
        visibility,
        tags: (data.tags as string[]) || [],
        notes: data.notes as string | undefined,
        customFields: data.customFields as Record<string, unknown> | undefined,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }

  private snapshotToActivities(
    snapshot: QuerySnapshot<DocumentData>
  ): SalesActivity[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as SalesActivity['visibility']) ?? 'team';
      return {
        id: doc.id,
        type: data.type as SalesActivity['type'],
        title: data.title as string,
        description: data.description as string | undefined,
        dealId: data.dealId as string | undefined,
        clientId: data.clientId as string | undefined,
        leadId: data.leadId as string | undefined,
        companyId: data.companyId as string | undefined,
        dueDate: data.dueDate?.toDate?.() || undefined,
        isCompleted: data.isCompleted as boolean,
        completedAt: data.completedAt?.toDate?.() || undefined,
        assigneeId: data.assigneeId as string | undefined,
        assigneeName: data.assigneeName as string | undefined,
        createdById: data.createdById as string,
        createdByName: data.createdByName as string,
        ownerId: (data.ownerId as string | undefined) ?? (data.createdById as string | undefined),
        ownerName: (data.ownerName as string | undefined) ?? (data.createdByName as string | undefined),
        teamIds,
        visibility,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let contactRepository: ContactRepository | null = null;

export function getContactRepository(): ContactRepository {
  if (!contactRepository) {
    contactRepository = new ContactRepository();
  }
  return contactRepository;
}
