/**
 * Templates Repository
 * Firestore repository for managing form templates and template instances
 *
 * Agent CRM-30 Implementation
 *
 * Collections:
 * - businesses/{businessId}/form_templates/{templateId}
 * - businesses/{businessId}/template_instances/{instanceId}
 *
 * HIPAA Compliance:
 * - All templates scoped by businessId
 * - Audit logging for all operations
 * - Soft delete support for compliance
 */

import { query, where, orderBy, getDocs } from 'firebase/firestore';
import type { QueryConstraint } from 'firebase/firestore';

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  QueryOptions, // Added QueryOptions import
} from './repository-types';

import type {
  FormTemplate,
  TemplateInstance,
  TemplateCategory,
  TemplateFilter,
  SEED_TEMPLATES,
} from '../../types/templates';

import { generateId } from './firestore-utils';
import { successResult, failedResult } from '../errors/repository-errors';

// ============================================
// Template Repository
// ============================================

class TemplateRepository extends BaseRepository<FormTemplate> {
  constructor() {
    super({
      collectionName: 'form_templates',
      softDelete: true,
    });
  }

  /**
   * Get all templates with optional filtering
   */
  async getFiltered(
    context: SecurityContext,
    filter: TemplateFilter = {},
    options: QueryOptions = {}
  ): Promise<RepositoryResult<FormTemplate[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const constraints: QueryConstraint[] = [];

      // Apply filters
      if (filter.category) {
        constraints.push(where('category', '==', filter.category));
      }

      if (filter.isSystem !== undefined) {
        constraints.push(where('isSystem', '==', filter.isSystem));
      }

      if (filter.isActive !== undefined) {
        constraints.push(where('isActive', '==', filter.isActive));
      }

      if (filter.tags && filter.tags.length > 0) {
        // Firestore array-contains only supports single value
        // For multiple tags, we'll filter in memory after fetch
        constraints.push(where('tags', 'array-contains', filter.tags[0]));
      }

      // Soft delete filter
      if (this.softDelete) {
        constraints.push(where('isDeleted', '!=', true));
      }

      // Default ordering by usage count (most popular first)
      const orderField = options.orderBy?.field || 'usageCount';
      const orderDirection = options.orderBy?.direction || 'desc';
      constraints.push(orderBy(orderField, orderDirection));

      const q = query(collectionRef, ...constraints);
      const querySnapshot = await getDocs(q);

      let templates = querySnapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          ...data,
          id: doc.id,
          createdAt: data.createdAt?.toDate?.() || data.createdAt,
          updatedAt: data.updatedAt?.toDate?.() || data.updatedAt,
          lastUsedAt: data.lastUsedAt?.toDate?.() || data.lastUsedAt,
        } as FormTemplate;
      });

      // Apply search term filter in memory
      if (filter.searchTerm) {
        const searchLower = filter.searchTerm.toLowerCase();
        templates = templates.filter(
          (t) =>
            t.name.toLowerCase().includes(searchLower) ||
            t.description?.toLowerCase().includes(searchLower) ||
            t.tags.some((tag) => tag.toLowerCase().includes(searchLower))
        );
      }

      // Apply multi-tag filter in memory
      if (filter.tags && filter.tags.length > 1) {
        templates = templates.filter((t) => filter.tags!.every((tag) => t.tags.includes(tag)));
      }

      // Apply pagination
      const limit = options.limit || templates.length;
      const paginatedTemplates = templates.slice(0, limit);

      await this.logAudit(context, 'list', null, {
        count: paginatedTemplates.length,
        filter,
      });

      return successResult(paginatedTemplates);
    } catch (error) {
      return failedResult(error, 'Failed to get filtered templates');
    }
  }

  /**
   * Get templates by category
   */
  async getByCategory(
    context: SecurityContext,
    category: TemplateCategory
  ): Promise<RepositoryResult<FormTemplate[]>> {
    const result = await this.getFiltered(context, { category, isActive: true });

    if (!result.success) {
      return {
        success: false,
        data: null,
        error: result.error,
      };
    }

    return successResult(result.data);
  }

  /**
   * Clone a template (create a copy)
   */
  async cloneTemplate(
    context: SecurityContext,
    templateId: string,
    newName: string
  ): Promise<RepositoryResult<FormTemplate>> {
    try {
      // Get the original template
      const originalResult = await this.getById(context, templateId);
      if (!originalResult.success) {
        return originalResult;
      }

      const original = originalResult.data;

      // Create a new template with cloned data
      const clonedData = {
        businessId: context.businessId,
        name: newName,
        description: original.description,
        category: original.category,
        fields: original.fields.map((field) => ({
          ...field,
          id: generateId(), // Generate new IDs for fields
        })),
        isSystem: false, // Cloned templates are never system templates
        isActive: true,
        tags: [...original.tags],
        usageCount: 0,
        createdBy: context.userId,
        createdByName: context.userName || 'Unknown User',
      };

      const result = await this.create(context, clonedData);

      if (result.success) {
        await this.logAudit(context, 'create', result.data.id, {
          action: 'clone',
          originalTemplateId: templateId,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to clone template');
    }
  }

  /**
   * Increment usage count for a template
   */
  async incrementUsage(
    context: SecurityContext,
    templateId: string
  ): Promise<RepositoryResult<void>> {
    try {
      const templateResult = await this.getById(context, templateId);
      if (!templateResult.success) {
        return { success: false, data: null, error: templateResult.error };
      }

      const template = templateResult.data;

      await this.update(context, templateId, {
        usageCount: (template.usageCount || 0) + 1,
        lastUsedAt: new Date(),
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to increment template usage');
    }
  }

  /**
   * Seed system templates if they don't exist
   */
  async seedSystemTemplates(
    context: SecurityContext,
    seedTemplates: typeof SEED_TEMPLATES
  ): Promise<RepositoryResult<{ created: number; skipped: number }>> {
    try {
      let created = 0;
      let skipped = 0;

      // Get existing templates
      const existingResult = await this.getFiltered(context, { isSystem: true });
      if (!existingResult.success) {
        return {
          success: false,
          data: null,
          error: existingResult.error,
        };
      }

      const existingNames = new Set(existingResult.data.map((t) => t.name));

      // Create seed templates that don't exist
      for (const [, seedTemplate] of Object.entries(seedTemplates)) {
        if (existingNames.has(seedTemplate.name)) {
          skipped++;
          continue;
        }

        const templateData = {
          businessId: context.businessId,
          name: seedTemplate.name,
          description: seedTemplate.description,
          category: seedTemplate.category,
          fields: seedTemplate.fields.map((field) => ({
            ...field,
            id: generateId(),
          })),
          isSystem: true,
          isActive: true,
          tags: seedTemplate.tags,
          usageCount: 0,
          createdBy: 'system',
          createdByName: 'System',
        };

        const result = await this.create(context, templateData);
        if (result.success) {
          created++;
        }
      }

      await this.logAudit(context, 'create', null, {
        action: 'seed',
        created,
        skipped,
      });

      return successResult({ created, skipped });
    } catch (error) {
      return failedResult(error, 'Failed to seed system templates');
    }
  }

  /**
   * Prevent deletion of system templates
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    try {
      // Check if it's a system template
      const templateResult = await this.getById(context, id);
      if (!templateResult.success) {
        return { success: false, data: null, error: templateResult.error };
      }

      if (templateResult.data.isSystem) {
        return failedResult(
          new Error('System templates cannot be deleted'),
          'Cannot delete system template'
        );
      }

      return super.delete(context, id);
    } catch (error) {
      return failedResult(error, 'Failed to delete template');
    }
  }
}

// ============================================
// Template Instance Repository
// ============================================

class TemplateInstanceRepository extends BaseRepository<TemplateInstance> {
  constructor() {
    super({
      collectionName: 'template_instances',
      softDelete: true,
    });
  }

  /**
   * Get instances by template ID
   */
  async getByTemplate(
    context: SecurityContext,
    templateId: string
  ): Promise<RepositoryResult<TemplateInstance[]>> {
    try {
      const result = await this.getAll(context, {
        where: [{ field: 'templateId', operator: '==', value: templateId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return {
          success: false,
          data: null,
          error: result.error,
        };
      }

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get template instances');
    }
  }

  /**
   * Get instances by client
   */
  async getByClient(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<TemplateInstance[]>> {
    try {
      const result = await this.getAll(context, {
        where: [{ field: 'clientId', operator: '==', value: clientId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return {
          success: false,
          data: null,
          error: result.error,
        };
      }

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get client template instances');
    }
  }

  /**
   * Get instances by deal
   */
  async getByDeal(
    context: SecurityContext,
    dealId: string
  ): Promise<RepositoryResult<TemplateInstance[]>> {
    try {
      const result = await this.getAll(context, {
        where: [{ field: 'dealId', operator: '==', value: dealId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return {
          success: false,
          data: null,
          error: result.error,
        };
      }

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get deal template instances');
    }
  }

  /**
   * Get pending instances (awaiting signature)
   */
  async getPending(context: SecurityContext): Promise<RepositoryResult<TemplateInstance[]>> {
    try {
      const result = await this.getAll(context, {
        where: [{ field: 'status', operator: '==', value: 'pending_signature' }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return {
          success: false,
          data: null,
          error: result.error,
        };
      }

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get pending instances');
    }
  }

  /**
   * Mark instance as completed
   */
  async markCompleted(
    context: SecurityContext,
    instanceId: string
  ): Promise<RepositoryResult<TemplateInstance>> {
    try {
      const result = await this.update(context, instanceId, {
        status: 'completed',
        completedAt: new Date(),
      });

      if (result.success) {
        await this.logAudit(context, 'update', instanceId, {
          action: 'mark_completed',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark instance as completed');
    }
  }

  /**
   * Expire old instances
   */
  async expireOldInstances(context: SecurityContext): Promise<RepositoryResult<number>> {
    try {
      const now = new Date();

      // Get instances that have passed their expiration date
      const result = await this.getAll(context, {
        where: [
          { field: 'status', operator: '!=', value: 'completed' },
          { field: 'status', operator: '!=', value: 'expired' },
        ],
      });

      if (!result.success) {
        return {
          success: false,
          data: null,
          error: result.error,
        };
      }

      let expiredCount = 0;

      for (const instance of result.data.data) {
        if (instance.expiresAt && instance.expiresAt < now) {
          await this.update(context, instance.id, { status: 'expired' });
          expiredCount++;
        }
      }

      await this.logAudit(context, 'update', null, {
        action: 'expire_old_instances',
        count: expiredCount,
      });

      return successResult(expiredCount);
    } catch (error) {
      return failedResult(error, 'Failed to expire old instances');
    }
  }
}

// ============================================
// Repository Instances
// ============================================

let templateRepositoryInstance: TemplateRepository | null = null;
let templateInstanceRepositoryInstance: TemplateInstanceRepository | null = null;

export function getTemplateRepository(): TemplateRepository {
  if (!templateRepositoryInstance) {
    templateRepositoryInstance = new TemplateRepository();
  }
  return templateRepositoryInstance;
}

export function getTemplateInstanceRepository(): TemplateInstanceRepository {
  if (!templateInstanceRepositoryInstance) {
    templateInstanceRepositoryInstance = new TemplateInstanceRepository();
  }
  return templateInstanceRepositoryInstance;
}
