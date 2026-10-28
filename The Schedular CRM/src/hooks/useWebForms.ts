/**
 * useWebForms Hook
 * Data fetching and mutations for web forms
 *
 * Agent Web Forms Implementation
 */

import { useState, useEffect, useCallback } from 'react';
import { getWebFormRepository } from '../data/repositories/web-form-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { WebForm } from '../types/web-forms';
import { useDemoGuard } from './useDemoGuard';

export interface UseWebFormsReturn {
  forms: WebForm[];
  isLoading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
  createForm: (
    data: Omit<WebForm, 'id' | 'createdAt' | 'updatedAt' | 'stats'>
  ) => Promise<WebForm | null>;
  updateForm: (id: string, data: Partial<WebForm>) => Promise<WebForm | null>;
  deleteForm: (id: string) => Promise<boolean>;
  getFormById: (id: string) => Promise<WebForm | null>;
}

/**
 * Hook for managing web forms
 */
export function useWebForms(context: SecurityContext | null): UseWebFormsReturn {
  const { guardMutation } = useDemoGuard();
  const [forms, setForms] = useState<WebForm[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const repository = getWebFormRepository();

  // Fetch all forms
  const fetchForms = useCallback(async () => {
    if (!context) {
      setForms([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const result = await repository.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (result.success) {
        setForms(result.data.data);
      } else {
        setError(new Error(result.error?.message || 'Failed to fetch forms'));
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setIsLoading(false);
    }
  }, [context, repository]);

  // Initial fetch
  useEffect(() => {
    fetchForms();
  }, [fetchForms]);

  // Create form
  const createForm = useCallback(
    async (
      data: Omit<WebForm, 'id' | 'createdAt' | 'updatedAt' | 'stats'>
    ): Promise<WebForm | null> => {
      if (!context) return null;

      try {
        const result = await repository.create(context, data as any);
        if (result.success) {
          setForms((prev) => [result.data, ...prev]);
          return result.data;
        }
        setError(new Error(result.error?.message || 'Failed to create form'));
        return null;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
        return null;
      }
    },
    [context, repository]
  );

  // Update form
  const updateForm = useCallback(
    async (id: string, data: Partial<WebForm>): Promise<WebForm | null> => {
      if (!context) return null;

      try {
        const result = await repository.update(context, id, data);
        if (result.success) {
          setForms((prev) =>
            prev.map((f) => (f.id === id ? result.data : f))
          );
          return result.data;
        }
        setError(new Error(result.error?.message || 'Failed to update form'));
        return null;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
        return null;
      }
    },
    [context, repository]
  );

  // Delete form
  const deleteForm = useCallback(
    async (id: string): Promise<boolean> => {
      if (!context) return false;

      try {
        const result = await repository.delete(context, id);
        if (result.success) {
          setForms((prev) => prev.filter((f) => f.id !== id));
          return true;
        }
        setError(new Error(result.error?.message || 'Failed to delete form'));
        return false;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
        return false;
      }
    },
    [context, repository]
  );

  // Get form by ID
  const getFormById = useCallback(
    async (id: string): Promise<WebForm | null> => {
      if (!context) return null;

      try {
        const result = await repository.getById(context, id);
        if (result.success) {
          return result.data;
        }
        return null;
      } catch {
        return null;
      }
    },
    [context, repository]
  );

  return {
    forms,
    isLoading,
    error,
    refetch: fetchForms,
    createForm: guardMutation(createForm, { action: 'web-form-create' }),
    updateForm: guardMutation(updateForm, { action: 'web-form-update' }),
    deleteForm: guardMutation(deleteForm, { action: 'web-form-delete' }),
    getFormById,
  };
}

export default useWebForms;
