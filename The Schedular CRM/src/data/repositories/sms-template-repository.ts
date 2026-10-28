/**
 * SMS Template Repository
 * Manages SMS templates in Firestore
 *
 * HIPAA Compliance:
 * - Templates MUST NOT contain PHI
 * - Use merge fields for personalization
 * - Audit logging for all operations
 * - Tenant isolation via businessId
 *
 * Storage Path: businesses/{businessId}/sms_templates/{templateId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { SmsTemplate, SmsCategory } from '../../types/sms';
import { calculateSegmentCount, calculateCharacterCount } from '../../types/sms';
import { successResult, failedResult, ValidationError } from '../errors/repository-errors';

// ============================================
// Repository Implementation
// ============================================

export class SmsTemplateRepository extends BaseRepository<SmsTemplate> {
  constructor() {
    super({
      collectionName: 'sms_templates',
      softDelete: true,
    });
  }

  /**
   * Validate template data
   * Ensures NO PHI in template content
   */
  private validateTemplate(data: Partial<SmsTemplate>): {
    isValid: boolean;
    errors: Array<{ field: string; message: string }>;
  } {
    const errors: Array<{ field: string; message: string }> = [];

    // Check for PHI patterns in body
    if (data.body) {
      const phiPatterns = [
        /\{\{.*ssn.*\}\}/i,
        /\{\{.*dob.*\}\}/i,
        /\{\{.*date.?of.?birth.*\}\}/i,
        /\{\{.*diagnosis.*\}\}/i,
        /\{\{.*treatment.*\}\}/i,
        /\{\{.*medication.*\}\}/i,
        /\{\{.*medical.*\}\}/i,
        /\{\{.*health.*\}\}/i,
        /\{\{.*patient.*\}\}/i,
        /\{\{.*appointment.*time.*\}\}/i,
        /\{\{.*appointment.*date.*\}\}/i,
        /\{\{.*provider.*name.*\}\}/i,
      ];

      for (const pattern of phiPatterns) {
        if (pattern.test(data.body)) {
          errors.push({
            field: 'body',
            message: 'Template contains potential PHI merge field - use secure portal links instead',
          });
          break;
        }
      }

      // Check body length (allow for merge fields to expand)
      if (data.body.length > 2000) {
        errors.push({
          field: 'body',
          message: 'Template exceeds maximum length',
        });
      }
    }

    // Validate name
    if (data.name !== undefined && (!data.name || data.name.trim().length === 0)) {
      errors.push({
        field: 'name',
        message: 'Template name is required',
      });
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Create a new SMS template
   */
  async create(
    context: SecurityContext,
    data: Omit<SmsTemplate, 'id' | 'createdAt' | 'updatedAt' | 'characterCount' | 'segmentCount'> & {
      characterCount?: number;
      segmentCount?: number;
    },
    customId?: string
  ): Promise<RepositoryResult<SmsTemplate>> {
    // Validate for PHI
    const validation = this.validateTemplate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Calculate character and segment counts
    const body = data.body || '';
    const templateData = {
      ...data,
      businessId: context.businessId,
      characterCount: calculateCharacterCount(body),
      segmentCount: calculateSegmentCount(body),
      createdById: context.userId,
      createdByName: context.userName,
    };

    return super.create(context, templateData, customId);
  }

  /**
   * Update an SMS template
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<SmsTemplate, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<SmsTemplate>> {
    // Validate for PHI
    const validation = this.validateTemplate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Recalculate counts if body changed
    const updateData = { ...data };
    if (data.body !== undefined) {
      updateData.characterCount = calculateCharacterCount(data.body);
      updateData.segmentCount = calculateSegmentCount(data.body);
    }

    return super.update(context, id, updateData);
  }

  /**
   * Get active templates
   */
  async getActiveTemplates(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<SmsTemplate>>> {
    const options: QueryOptions = {
      where: [{ field: 'isActive', operator: '==', value: true }],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get templates by category
   */
  async getByCategory(
    context: SecurityContext,
    category: SmsCategory
  ): Promise<RepositoryResult<PaginatedResult<SmsTemplate>>> {
    const options: QueryOptions = {
      where: [
        { field: 'category', operator: '==', value: category },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Deactivate a template (soft disable)
   */
  async deactivate(context: SecurityContext, id: string): Promise<RepositoryResult<SmsTemplate>> {
    return this.update(context, id, { isActive: false });
  }

  /**
   * Activate a template
   */
  async activate(context: SecurityContext, id: string): Promise<RepositoryResult<SmsTemplate>> {
    return this.update(context, id, { isActive: true });
  }

  /**
   * Duplicate a template
   */
  async duplicate(
    context: SecurityContext,
    id: string,
    newName?: string
  ): Promise<RepositoryResult<SmsTemplate>> {
    try {
      // Get the original template
      const originalResult = await this.getById(context, id);
      if (!originalResult.success) {
        return originalResult;
      }

      const original = originalResult.data;

      // Create new template data
      const duplicateData: Omit<SmsTemplate, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        name: newName || `${original.name} (Copy)`,
        body: original.body,
        characterCount: original.characterCount,
        segmentCount: original.segmentCount,
        isActive: true,
        category: original.category,
        createdById: context.userId,
        createdByName: context.userName,
      };

      return this.create(context, duplicateData);
    } catch (error) {
      return failedResult(error, 'Failed to duplicate template');
    }
  }

  /**
   * Search templates by name
   */
  async searchByName(
    context: SecurityContext,
    searchTerm: string
  ): Promise<RepositoryResult<PaginatedResult<SmsTemplate>>> {
    // Get all active templates and filter client-side
    // (Firestore doesn't support full-text search natively)
    const result = await this.getActiveTemplates(context);

    if (!result.success) {
      return result;
    }

    const lowerSearch = searchTerm.toLowerCase();
    const filtered = result.data.data.filter(
      (template) =>
        template.name.toLowerCase().includes(lowerSearch) ||
        template.body.toLowerCase().includes(lowerSearch)
    );

    return successResult({
      data: filtered,
      lastDoc: null,
      hasMore: false,
    });
  }
}

// ============================================
// Singleton Instance
// ============================================

let smsTemplateRepositoryInstance: SmsTemplateRepository | null = null;

export function getSmsTemplateRepository(): SmsTemplateRepository {
  if (!smsTemplateRepositoryInstance) {
    smsTemplateRepositoryInstance = new SmsTemplateRepository();
  }
  return smsTemplateRepositoryInstance;
}
