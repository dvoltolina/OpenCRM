/**
 * useCompanyMutations Hook
 * CRUD operations for companies
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (company repository)
 */

import { useCallback, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { createSecurityContext } from './usePipeline';
import type { Company, CompanySize } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseCompanyMutationsResult {
  /** Create a new company */
  createCompany: (data: Partial<Company>) => Promise<Company>;
  /** Update an existing company */
  updateCompany: (id: string, data: Partial<Company>) => Promise<void>;
  /** Delete a company */
  deleteCompany: (id: string) => Promise<void>;
  /** Add tag to company */
  addTag: (id: string, tag: string) => Promise<void>;
  /** Remove tag from company */
  removeTag: (id: string, tag: string) => Promise<void>;
  /** Whether a mutation is in progress */
  isLoading: boolean;
  /** Error from the last mutation */
  error: Error | null;
  /** Clear the error state */
  clearError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for company CRUD operations
 *
 * @returns Mutation functions and state
 *
 * @example
 * ```tsx
 * const { createCompany, updateCompany, addTag, isLoading } = useCompanyMutations();
 *
 * const handleCreate = async () => {
 *   const company = await createCompany({
 *     name: 'Acme Corp',
 *     industry: 'Technology',
 *     size: 'enterprise',
 *   });
 *   console.log('Created company:', company.id);
 * };
 * ```
 */
export function useCompanyMutations(): UseCompanyMutationsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Clear error
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // Create a new company
  const createCompany = useCallback(
    async (data: Partial<Company>): Promise<Company> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getCompanyRepository();

        const companyData = {
          name: data.name || '',
          industry: data.industry,
          size: data.size as CompanySize | undefined,
          website: data.website,
          phone: data.phone,
          email: data.email,
          address: data.address,
          tags: data.tags || [],
          notes: data.notes,
        };

        const result = await repo.create(
          context,
          companyData as Omit<Company, 'id' | 'createdAt' | 'updatedAt'>
        );

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create company');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update an existing company
  const updateCompany = useCallback(
    async (id: string, data: Partial<Company>): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only admin/owner/staff can edit (front desk is read-only)
        if (context.userRole !== 'owner' && context.userRole !== 'admin' && context.userRole !== 'staff') {
          throw new Error('Insufficient permissions to edit companies');
        }

        const repo = getCompanyRepository();

        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update company');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Delete a company
  const deleteCompany = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only admin/owner can delete
        if (context.userRole !== 'owner' && context.userRole !== 'admin') {
          throw new Error('Only administrators can delete companies');
        }

        const repo = getCompanyRepository();

        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete company');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Add tag to company
  const addTag = useCallback(
    async (id: string, tag: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getCompanyRepository();

        const result = await repo.addTag(context, id, tag);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add tag');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Remove tag from company
  const removeTag = useCallback(
    async (id: string, tag: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getCompanyRepository();

        const result = await repo.removeTag(context, id, tag);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to remove tag');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createCompany: guardMutation(createCompany, { action: 'company-create' }),
    updateCompany: guardMutation(updateCompany, { action: 'company-update' }),
    deleteCompany: guardMutation(deleteCompany, { action: 'company-delete' }),
    addTag: guardMutation(addTag, { action: 'company-tag-add' }),
    removeTag: guardMutation(removeTag, { action: 'company-tag-remove' }),
    isLoading,
    error,
    clearError,
  };
}

export default useCompanyMutations;
