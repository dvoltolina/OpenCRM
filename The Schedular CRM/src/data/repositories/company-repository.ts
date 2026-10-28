/**
 * Company Repository
 * Manages company/organization records with relationship tracking
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, collection } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, normalizeVisibility } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type { Company, CompanySize, Client, Deal } from '../../types/models';
import { sanitizeTeamIds } from '../../lib/security-context';
import { businessPath } from '../../lib/collections';

// ============================================
// Types
// ============================================

export interface CompanyWithRelations extends Company {
  contactCount?: number;
  dealCount?: number;
  totalDealValueCents?: number;
}

export interface CompanyFilters {
  industry?: string;
  size?: CompanySize;
  tags?: string[];
}

// ============================================
// Validation
// ============================================

const companyValidator: Validator<Company> = (data: Partial<Company>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({ field: 'name', message: 'Company name is required', code: 'REQUIRED' });
  }

  if (data.email !== undefined && data.email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      errors.push({ field: 'email', message: 'Invalid email format', code: 'INVALID_FORMAT' });
    }
  }

  if (data.website !== undefined && data.website) {
    // Basic URL validation
    try {
      new URL(data.website.startsWith('http') ? data.website : `https://${data.website}`);
    } catch {
      errors.push({ field: 'website', message: 'Invalid website URL', code: 'INVALID_FORMAT' });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Company Repository
// ============================================

/**
 * Company Repository
 * Handles CRUD operations for company/organization records
 */
export class CompanyRepository extends ShareableRepository<Company> {
  protected entityName = 'company';
  protected sensitiveFields: Array<keyof Company> = ['notes', 'customFields'];
  protected defaultVisibility: 'private' | 'team' | 'org' = 'team';

  constructor() {
    super({ collectionName: 'companies' });
    this.setValidator(companyValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get companies by industry
   */
  async getByIndustry(
    context: SecurityContext,
    industry: string
  ): Promise<RepositoryResult<Company[]>> {
    try {
      if (!industry?.trim()) {
        return failedResult(new InvalidArgumentError('Industry is required', 'industry'));
      }

      const result = await this.getAll(context, {
        where: [{ field: 'industry', operator: '==', value: industry }],
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'list', null, { action: 'getByIndustry', industry });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get companies by industry');
    }
  }

  /**
   * Get companies by size
   */
  async getBySize(
    context: SecurityContext,
    size: CompanySize
  ): Promise<RepositoryResult<Company[]>> {
    try {
      const result = await this.getAll(context, {
        where: [{ field: 'size', operator: '==', value: size }],
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'list', null, { action: 'getBySize', size });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get companies by size');
    }
  }

  /**
   * Get companies with specific tag
   */
  async getByTag(
    context: SecurityContext,
    tag: string
  ): Promise<RepositoryResult<Company[]>> {
    try {
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      const result = await this.getAll(context, {
        where: [{ field: 'tags', operator: 'array-contains', value: tag }],
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!result.success) {
        return result;
      }

      await this.logAudit(context, 'list', null, { action: 'getByTag', tag });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get companies by tag');
    }
  }

  /**
   * Search companies by name
   */
  async search(
    context: SecurityContext,
    query: string
  ): Promise<RepositoryResult<Company[]>> {
    try {
      // For now, fetch all and filter client-side
      // In production, consider Algolia or similar for full-text search
      const allResult = await this.getAll(context, {
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      const normalizedQuery = query.toLowerCase().trim();

      if (!normalizedQuery) {
        return successResult(allResult.data.data);
      }

      const filtered = allResult.data.data.filter((company) => {
        return (
          company.name.toLowerCase().includes(normalizedQuery) ||
          company.industry?.toLowerCase().includes(normalizedQuery) ||
          company.website?.toLowerCase().includes(normalizedQuery)
        );
      });

      await this.logAudit(context, 'list', null, {
        action: 'search',
        query,
        resultCount: filtered.length,
      });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to search companies');
    }
  }

  /**
   * Get companies with combined filters
   */
  async getFiltered(
    context: SecurityContext,
    filters: CompanyFilters
  ): Promise<RepositoryResult<Company[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'name', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      let filtered = allResult.data.data;

      if (filters.industry) {
        filtered = filtered.filter((c) => c.industry === filters.industry);
      }

      if (filters.size) {
        filtered = filtered.filter((c) => c.size === filters.size);
      }

      if (filters.tags && filters.tags.length > 0) {
        filtered = filtered.filter((c) =>
          filters.tags!.some((tag) => c.tags.includes(tag))
        );
      }

      await this.logAudit(context, 'list', null, { action: 'getFiltered', filters });

      return successResult(filtered);
    } catch (error) {
      return failedResult(error, 'Failed to get filtered companies');
    }
  }

  // ============================================
  // Relationship Methods
  // ============================================

  /**
   * Get all contacts (clients) for a company
   * Note: This queries the clients collection, not companies
   */
  async getContacts(
    context: SecurityContext,
    companyId: string,
    clientsCollectionRef?: ReturnType<typeof this.getCollectionRef>
  ): Promise<RepositoryResult<Client[]>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }

      // Use provided ref or create one for clients collection
      const collectionRef = clientsCollectionRef ||
        this.getCollectionRefForPath(context, 'clients');

      const q = buildQuery(collectionRef, {
        where: [{ field: 'companyId', operator: '==', value: companyId }],
        orderBy: { field: 'lastName', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const clients = this.snapshotToClients(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getContacts',
        companyId,
        count: clients.length,
      });

      return successResult(clients);
    } catch (error) {
      return failedResult(error, 'Failed to get company contacts');
    }
  }

  /**
   * Get all deals for a company
   * Note: This queries the deals collection, not companies
   */
  async getDeals(
    context: SecurityContext,
    companyId: string,
    dealsCollectionRef?: ReturnType<typeof this.getCollectionRef>
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }

      // Use provided ref or create one for deals collection
      const collectionRef = dealsCollectionRef ||
        this.getCollectionRefForPath(context, 'deals');

      const q = buildQuery(collectionRef, {
        where: [{ field: 'companyId', operator: '==', value: companyId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.snapshotToDeals(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getDeals',
        companyId,
        count: deals.length,
      });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get company deals');
    }
  }

  /**
   * Get company with relationship counts
   */
  async getWithRelations(
    context: SecurityContext,
    companyId: string
  ): Promise<RepositoryResult<CompanyWithRelations>> {
    try {
      const companyResult = await this.getById(context, companyId);
      if (!companyResult.success) {
        return companyResult;
      }

      const [contactsResult, dealsResult] = await Promise.all([
        this.getContacts(context, companyId),
        this.getDeals(context, companyId),
      ]);

      const contacts = contactsResult.success ? contactsResult.data : [];
      const deals = dealsResult.success ? dealsResult.data : [];

      const openDeals = deals.filter((d) => d.status === 'open');
      const totalDealValueCents = openDeals.reduce((sum, d) => sum + d.valueCents, 0);

      const companyWithRelations: CompanyWithRelations = {
        ...companyResult.data,
        contactCount: contacts.length,
        dealCount: openDeals.length,
        totalDealValueCents,
      };

      return successResult(companyWithRelations);
    } catch (error) {
      return failedResult(error, 'Failed to get company with relations');
    }
  }

  // ============================================
  // Tag Management
  // ============================================

  /**
   * Add a tag to a company
   */
  async addTag(
    context: SecurityContext,
    companyId: string,
    tag: string
  ): Promise<RepositoryResult<Company>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      const existingResult = await this.getById(context, companyId);
      if (!existingResult.success) {
        return existingResult;
      }

      const company = existingResult.data;
      const normalizedTag = tag.trim().toLowerCase();

      if (company.tags.includes(normalizedTag)) {
        // Tag already exists, return company as-is
        return successResult(company);
      }

      const updatedTags = [...company.tags, normalizedTag];
      return this.update(context, companyId, { tags: updatedTags });
    } catch (error) {
      return failedResult(error, 'Failed to add tag');
    }
  }

  /**
   * Remove a tag from a company
   */
  async removeTag(
    context: SecurityContext,
    companyId: string,
    tag: string
  ): Promise<RepositoryResult<Company>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }
      if (!tag?.trim()) {
        return failedResult(new InvalidArgumentError('Tag is required', 'tag'));
      }

      const existingResult = await this.getById(context, companyId);
      if (!existingResult.success) {
        return existingResult;
      }

      const company = existingResult.data;
      const normalizedTag = tag.trim().toLowerCase();

      const updatedTags = company.tags.filter((t) => t !== normalizedTag);

      if (updatedTags.length === company.tags.length) {
        // Tag didn't exist, return company as-is
        return successResult(company);
      }

      return this.update(context, companyId, { tags: updatedTags });
    } catch (error) {
      return failedResult(error, 'Failed to remove tag');
    }
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Get all unique industries across companies
   */
  async getUniqueIndustries(context: SecurityContext): Promise<RepositoryResult<string[]>> {
    try {
      const allResult = await this.getAll(context);
      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      const industries = new Set<string>();
      for (const company of allResult.data.data) {
        if (company.industry) {
          industries.add(company.industry);
        }
      }

      return successResult(Array.from(industries).sort());
    } catch (error) {
      return failedResult(error, 'Failed to get unique industries');
    }
  }

  /**
   * Get collection reference for a different collection path
   * Used for cross-collection queries (clients, deals)
   */
  protected getCollectionRefForPath(context: SecurityContext, collectionName: string) {
    return collection(this.db, `${businessPath(context.businessId)}/${collectionName}`);
  }

  // ============================================
  // Helper Methods
  // ============================================

  /** Helper to convert snapshot to typed Company array - kept for potential batch operations */
  protected snapshotToCompanies(
    snapshot: QuerySnapshot<DocumentData>
  ): Company[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name as string,
        industry: data.industry as string | undefined,
        size: data.size as CompanySize | undefined,
        website: data.website as string | undefined,
        phone: data.phone as string | undefined,
        email: data.email as string | undefined,
        address: data.address as Company['address'],
        notes: data.notes as string | undefined,
        tags: (data.tags as string[]) || [],
        customFields: data.customFields as Record<string, unknown> | undefined,
        ownerId: data.ownerId as string | undefined,
        ownerName: data.ownerName as string | undefined,
        teamIds: sanitizeTeamIds(data.teamIds as string[] | undefined),
        visibility: normalizeVisibility(data.visibility as Company['visibility']),
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }

  private snapshotToClients(
    snapshot: QuerySnapshot<DocumentData>
  ): Client[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        firstName: data.firstName as string,
        lastName: data.lastName as string,
        email: data.email as string,
        phone: data.phone as string | undefined,
        lifecycle: data.lifecycle as Client['lifecycle'],
        tags: (data.tags as string[]) || [],
        userId: data.userId as string | undefined,
        companyId: data.companyId as string | undefined,
        companyName: data.companyName as string | undefined,
        title: data.title as string | undefined,
        address: data.address as Client['address'],
        crmNotes: data.crmNotes as string | undefined,
        lastContactedAt: data.lastContactedAt?.toDate?.() || undefined,
        leadSource: data.leadSource as Client['leadSource'],
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
        tags: (data.tags as string[]) || [],
        notes: data.notes as string | undefined,
        customFields: data.customFields as Record<string, unknown> | undefined,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let companyRepository: CompanyRepository | null = null;

export function getCompanyRepository(): CompanyRepository {
  if (!companyRepository) {
    companyRepository = new CompanyRepository();
  }
  return companyRepository;
}
