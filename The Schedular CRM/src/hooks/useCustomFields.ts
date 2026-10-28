/**
 * useCustomFields Hook
 * Manages custom field definitions with CRUD operations
 *
 * Agent CRM-39 Implementation
 * Dependencies: custom-fields-repository, AuthContext
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getCustomFieldsRepository } from '../data/repositories/custom-fields-repository';
import { getCustomFieldsService } from '../services/custom-fields-service';
import type { SecurityContext } from '../data/repositories/repository-types';
import { createSecurityContextFromParams } from '../lib/security-context';
import type {
  CustomFieldDefinition,
  CustomFieldEntityType,
  CustomFieldInput,
  CustomFieldUpdateInput,
} from '../types/custom-fields';

// ============================================
// Types
// ============================================

export interface UseCustomFieldsResult {
  /** All custom fields for the current entity type */
  fields: CustomFieldDefinition[];

  /** True while initial data is loading */
  isLoading: boolean;

  /** Error object if operation failed */
  error: Error | null;

  /** Create a new custom field */
  createField: (data: CustomFieldInput) => Promise<CustomFieldDefinition>;

  /** Update an existing custom field */
  updateField: (id: string, data: CustomFieldUpdateInput) => Promise<void>;

  /** Delete a custom field (soft delete) */
  deleteField: (id: string) => Promise<void>;

  /** Archive a custom field */
  archiveField: (id: string) => Promise<void>;

  /** Restore an archived custom field */
  restoreField: (id: string) => Promise<void>;

  /** Reorder fields */
  reorderFields: (fieldIds: string[]) => Promise<void>;

  /** Duplicate a field */
  duplicateField: (id: string) => Promise<CustomFieldDefinition>;

  /** Check if a field name is available */
  isFieldNameAvailable: (name: string, excludeId?: string) => Promise<boolean>;

  /** Manually refresh the field list */
  refresh: () => void;
}

// ============================================
// Helper Function
// ============================================

/**
 * Create security context from auth state
 */
function createSecurityContext(
  businessId: string,
  userId: string,
  userName: string,
  userRole: string,
  teamIds: string[] = [],
  managedTeamIds: string[] = []
): SecurityContext {
  return createSecurityContextFromParams(businessId, userId, userName, userRole, teamIds, managedTeamIds);
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing custom fields for a specific entity type
 *
 * @param entityType - Type of entity (lead, deal, contact, company)
 * @returns Custom fields, mutations, and state
 *
 * @example
 * ```tsx
 * const {
 *   fields,
 *   isLoading,
 *   createField,
 *   updateField,
 *   reorderFields,
 * } = useCustomFields('lead');
 *
 * const handleCreate = async () => {
 *   await createField({
 *     businessId: 'biz-123',
 *     entityType: 'lead',
 *     name: 'industryType',
 *     label: 'Industry Type',
 *     fieldType: 'select',
 *     required: false,
 *     options: ['Technology', 'Healthcare', 'Finance'],
 *     order: 0,
 *     isActive: true,
 *   });
 * };
 * ```
 */
export function useCustomFields(
  entityType: CustomFieldEntityType
): UseCustomFieldsResult {
  const { crmUser, businessId } = useAuth();
  const [fields, setFields] = useState<CustomFieldDefinition[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Get security context
  const getContext = useCallback((): SecurityContext => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      crmUser.teamIds || [],
      crmUser.managedTeamIds || []
    );
  }, [businessId, crmUser]);

  // Fetch fields for the entity type
  const fetchFields = useCallback(async () => {
    if (!businessId || !crmUser) {
      setFields([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.getFieldsForEntity(context, entityType);

      if (result.success) {
        setFields(result.data.data);
      } else {
        setError(new Error(result.error.message));
        setFields([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch custom fields'));
      setFields([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, entityType, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchFields();
  }, [fetchFields]);

  // Create a new custom field
  const createField = useCallback(
    async (data: CustomFieldInput): Promise<CustomFieldDefinition> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();
      const service = getCustomFieldsService();

      // Validate the field definition
      const validationError = service.validateDefinition(data);
      if (validationError) {
        throw new Error(validationError);
      }

      // Check if name is available
      const nameAvailable = await repo.isFieldNameAvailable(
        context,
        entityType,
        data.name
      );
      if (!nameAvailable) {
        throw new Error(`Field name "${data.name}" is already in use`);
      }

      // Get next order if not specified
      let order = data.order;
      if (order === undefined) {
        order = await repo.getNextOrder(context, entityType);
      }

      const fieldData = {
        ...data,
        order,
      };

      const result = await repo.create(context, fieldData);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();

      return result.data;
    },
    [getContext, entityType, fetchFields]
  );

  // Update an existing custom field
  const updateField = useCallback(
    async (id: string, data: CustomFieldUpdateInput): Promise<void> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();
      const service = getCustomFieldsService();

      // If updating name, validate it
      if (data.name !== undefined) {
        const validationError = service.validateDefinition({ ...data, name: data.name });
        if (validationError) {
          throw new Error(validationError);
        }

        // Check if name is available (excluding current field)
        const nameAvailable = await repo.isFieldNameAvailable(
          context,
          entityType,
          data.name,
          id
        );
        if (!nameAvailable) {
          throw new Error(`Field name "${data.name}" is already in use`);
        }
      }

      const result = await repo.update(context, id, data);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();
    },
    [getContext, entityType, fetchFields]
  );

  // Delete a custom field (soft delete)
  const deleteField = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.delete(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();
    },
    [getContext, fetchFields]
  );

  // Archive a custom field
  const archiveField = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.archiveField(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();
    },
    [getContext, fetchFields]
  );

  // Restore an archived custom field
  const restoreField = useCallback(
    async (id: string): Promise<void> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.restoreField(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();
    },
    [getContext, fetchFields]
  );

  // Reorder fields
  const reorderFields = useCallback(
    async (fieldIds: string[]): Promise<void> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.reorderFields(context, entityType, fieldIds);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();
    },
    [getContext, entityType, fetchFields]
  );

  // Duplicate a field
  const duplicateField = useCallback(
    async (id: string): Promise<CustomFieldDefinition> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      const result = await repo.duplicateField(context, id);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      // Refresh the list
      await fetchFields();

      return result.data;
    },
    [getContext, fetchFields]
  );

  // Check if a field name is available
  const isFieldNameAvailable = useCallback(
    async (name: string, excludeId?: string): Promise<boolean> => {
      const context = getContext();
      const repo = getCustomFieldsRepository();

      return repo.isFieldNameAvailable(context, entityType, name, excludeId);
    },
    [getContext, entityType]
  );

  // Manual refresh
  const refresh = useCallback(() => {
    fetchFields();
  }, [fetchFields]);

  return {
    fields,
    isLoading,
    error,
    createField,
    updateField,
    deleteField,
    archiveField,
    restoreField,
    reorderFields,
    duplicateField,
    isFieldNameAvailable,
    refresh,
  };
}

export default useCustomFields;
