/**
 * Custom Fields Repository
 * Handles CRUD operations for custom field definitions
 *
 * Agent CRM-39 Implementation
 * Dependencies: BaseRepository, custom-fields types
 *
 * Storage: businesses/{businessId}/crm_custom_fields/{fieldId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  QueryOptions,
  RepositoryResult,
  PaginatedResult,
} from './repository-types';
import type {
  CustomFieldDefinition,
  CustomFieldEntityType,
} from '../../types/custom-fields';

// ============================================
// Custom Fields Repository
// ============================================

/**
 * Repository for managing custom field definitions
 */
export class CustomFieldsRepository extends BaseRepository<CustomFieldDefinition> {
  constructor() {
    super({
      collectionName: 'crm_custom_fields',
      softDelete: true,
    });
  }

  /**
   * Create a new custom field
   * RBAC: Only owner/admin can create custom fields
   */
  async create(
    context: SecurityContext,
    data: Omit<CustomFieldDefinition, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<CustomFieldDefinition>> {
    this.requireRole(context, ['owner', 'admin']);
    return super.create(context, data, customId);
  }

  /**
   * Update a custom field
   * RBAC: Only owner/admin can update custom fields
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<CustomFieldDefinition, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<CustomFieldDefinition>> {
    this.requireRole(context, ['owner', 'admin']);
    return super.update(context, id, data);
  }

  /**
   * Delete a custom field
   * RBAC: Only owner can delete custom fields
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    this.requireRole(context, ['owner']);
    return super.delete(context, id);
  }

  /**
   * Get all custom fields for a specific entity type
   *
   * @param context - Security context
   * @param entityType - Type of entity (lead, deal, contact, company)
   * @returns Active custom fields for the entity type
   */
  async getFieldsForEntity(
    context: SecurityContext,
    entityType: CustomFieldEntityType
  ): Promise<RepositoryResult<PaginatedResult<CustomFieldDefinition>>> {
    const options: QueryOptions = {
      where: [
        { field: 'entityType', operator: '==', value: entityType },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'order', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get all active custom fields grouped by entity type
   *
   * @param context - Security context
   * @returns All active custom fields
   */
  async getAllActive(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<CustomFieldDefinition>>> {
    const options: QueryOptions = {
      where: [{ field: 'isActive', operator: '==', value: true }],
      orderBy: { field: 'order', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Reorder custom fields for an entity type
   * RBAC: Only owner/admin can reorder custom fields
   *
   * @param context - Security context
   * @param entityType - Type of entity
   * @param fieldIds - Array of field IDs in desired order
   * @returns Success result
   */
  async reorderFields(
    context: SecurityContext,
    entityType: CustomFieldEntityType,
    fieldIds: string[]
  ): Promise<RepositoryResult<void>> {
    try {
      this.requireRole(context, ['owner', 'admin']);

      // Update each field with its new order
      const updates = fieldIds.map((fieldId, index) =>
        this.update(context, fieldId, { order: index })
      );

      const results = await Promise.all(updates);

      // Check if any failed
      const failed = results.find((r) => !r.success);
      if (failed) {
        return {
          success: false,
          data: null,
          error: failed.error,
        };
      }

      await this.logAudit(context, 'update', null, {
        action: 'reorder',
        entityType,
        fieldCount: fieldIds.length,
      });

      return {
        success: true,
        data: undefined,
        error: null,
      };
    } catch (error) {
      return {
        success: false,
        data: null,
        error: {
          code: 'UNKNOWN',
          message: error instanceof Error ? error.message : 'Failed to reorder fields',
        },
      };
    }
  }

  /**
   * Archive a custom field (soft delete)
   *
   * @param context - Security context
   * @param fieldId - ID of the field to archive
   * @returns Updated field
   */
  async archiveField(
    context: SecurityContext,
    fieldId: string
  ): Promise<RepositoryResult<CustomFieldDefinition>> {
    return this.update(context, fieldId, { isActive: false });
  }

  /**
   * Restore an archived custom field
   *
   * @param context - Security context
   * @param fieldId - ID of the field to restore
   * @returns Updated field
   */
  async restoreField(
    context: SecurityContext,
    fieldId: string
  ): Promise<RepositoryResult<CustomFieldDefinition>> {
    return this.update(context, fieldId, { isActive: true });
  }

  /**
   * Check if a field name is already in use for an entity type
   *
   * @param context - Security context
   * @param entityType - Type of entity
   * @param fieldName - Name to check
   * @param excludeFieldId - Field ID to exclude from check (for updates)
   * @returns True if name is available
   */
  async isFieldNameAvailable(
    context: SecurityContext,
    entityType: CustomFieldEntityType,
    fieldName: string,
    excludeFieldId?: string
  ): Promise<boolean> {
    const result = await this.getFieldsForEntity(context, entityType);
    if (!result.success) return true; // Assume available on error

    const existingField = result.data.data.find(
      (field) => field.name === fieldName && field.id !== excludeFieldId
    );

    return !existingField;
  }

  /**
   * Get the next available order number for an entity type
   *
   * @param context - Security context
   * @param entityType - Type of entity
   * @returns Next order number
   */
  async getNextOrder(
    context: SecurityContext,
    entityType: CustomFieldEntityType
  ): Promise<number> {
    const result = await this.getFieldsForEntity(context, entityType);
    if (!result.success || result.data.data.length === 0) return 0;

    const maxOrder = Math.max(...result.data.data.map((f) => f.order));
    return maxOrder + 1;
  }

  /**
   * Duplicate a custom field
   *
   * @param context - Security context
   * @param fieldId - ID of the field to duplicate
   * @returns New duplicated field
   */
  async duplicateField(
    context: SecurityContext,
    fieldId: string
  ): Promise<RepositoryResult<CustomFieldDefinition>> {
    try {
      // Get the original field
      const originalResult = await this.getById(context, fieldId);
      if (!originalResult.success) {
        return originalResult;
      }

      const original = originalResult.data;

      // Get next order number
      const nextOrder = await this.getNextOrder(context, original.entityType);

      // Find a unique name
      let duplicateName = `${original.name}_copy`;
      let suffix = 1;
      while (
        !(await this.isFieldNameAvailable(context, original.entityType, duplicateName))
      ) {
        suffix++;
        duplicateName = `${original.name}_copy${suffix}`;
      }

      // Create the duplicate
      const duplicateData = {
        businessId: context.businessId,
        entityType: original.entityType,
        name: duplicateName,
        label: `${original.label} (Copy)`,
        fieldType: original.fieldType,
        required: original.required,
        options: original.options,
        defaultValue: original.defaultValue,
        order: nextOrder,
        isActive: true,
      };

      return this.create(context, duplicateData);
    } catch (error) {
      return {
        success: false,
        data: null,
        error: {
          code: 'UNKNOWN',
          message: error instanceof Error ? error.message : 'Failed to duplicate field',
        },
      };
    }
  }
}

// ============================================
// Singleton Export
// ============================================

let customFieldsRepositoryInstance: CustomFieldsRepository | null = null;

/**
 * Get the singleton instance of the custom fields repository
 */
export function getCustomFieldsRepository(): CustomFieldsRepository {
  if (!customFieldsRepositoryInstance) {
    customFieldsRepositoryInstance = new CustomFieldsRepository();
  }
  return customFieldsRepositoryInstance;
}

/**
 * Reset the singleton instance (for testing)
 */
export function resetCustomFieldsRepository(): void {
  customFieldsRepositoryInstance = null;
}
