/**
 * useLeadMutations Hook
 * CRUD operations for leads
 *
 * Agent CRM-08 Implementation
 * Dependencies: Agent CRM-03 (leads repository)
 */

import { useCallback, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { createSecurityContext } from './usePipeline';
import { sanitizeTeamIds } from '../lib/security-context';
import { dispatchAutomationEvent } from '../services/automation-dispatcher';
import type { Lead, LeadStatus } from '../types/models';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseLeadMutationsResult {
  /** Create a new lead */
  createLead: (data: Partial<Lead>, options?: { allowDuplicate?: boolean }) => Promise<Lead>;
  /** Update an existing lead */
  updateLead: (
    id: string,
    data: Partial<Lead>,
    options?: { allowDuplicate?: boolean }
  ) => Promise<void>;
  /** Delete a lead */
  deleteLead: (id: string) => Promise<void>;
  /** Update lead status with validation */
  updateStatus: (id: string, status: LeadStatus) => Promise<void>;
  /** Assign lead to a user */
  assignLead: (id: string, assigneeId: string, assigneeName: string) => Promise<void>;
  /** Bulk assign multiple leads */
  bulkAssign: (ids: string[], assigneeId: string, assigneeName: string) => Promise<{ successCount: number; failedIds: string[] }>;
  /** Bulk update status for multiple leads */
  bulkUpdateStatus: (ids: string[], status: LeadStatus) => Promise<{ successCount: number; failedIds: string[] }>;
  /** Bulk delete multiple leads */
  bulkDelete: (ids: string[]) => Promise<{ successCount: number; failedIds: string[] }>;
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
 * Hook for lead CRUD operations
 *
 * @returns Mutation functions and state
 *
 * @example
 * ```tsx
 * const {
 *   createLead,
 *   updateLead,
 *   updateStatus,
 *   assignLead,
 *   isLoading,
 *   error,
 * } = useLeadMutations();
 *
 * const handleCreate = async () => {
 *   try {
 *     const lead = await createLead({
 *       firstName: 'John',
 *       lastName: 'Doe',
 *       email: 'john@example.com',
 *     });
 *     console.log('Created lead:', lead.id);
 *   } catch (err) {
 *     console.error('Failed to create lead:', err);
 *   }
 * };
 * ```
 */
export function useLeadMutations(): UseLeadMutationsResult {
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

  // Create a new lead
  const createLead = useCallback(
    async (data: Partial<Lead>, options?: { allowDuplicate?: boolean }): Promise<Lead> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        // crmUser is guaranteed non-null here since getContext() throws if null
        const currentUser = crmUser!;
        const leadData = {
          firstName: data.firstName || '',
          lastName: data.lastName || '',
          email: data.email || '',
          phone: data.phone,
          companyName: data.companyName,
          title: data.title,
          status: data.status || 'new',
          source: data.source || 'other',
          score: data.score,
          tags: data.tags || [],
          notes: data.notes,
          assigneeId: data.assigneeId,
          assigneeName: data.assigneeName,
          ownerId: data.ownerId ?? currentUser.id,
          ownerName: data.ownerName ?? currentUser.displayName ?? currentUser.email ?? 'Unknown User',
          teamIds: data.teamIds ? sanitizeTeamIds(data.teamIds) : undefined,
          visibility: data.visibility ?? 'team',
        };

        const result = await repo.create(
          context,
          {
            ...(options?.allowDuplicate ? { allowDuplicate: true } : {}),
            ...(leadData as Omit<Lead, 'id' | 'createdAt' | 'updatedAt'>),
          } as Omit<Lead, 'id' | 'createdAt' | 'updatedAt'> & { allowDuplicate?: boolean }
        );

        if (!result.success) {
          throw new Error(result.error.message);
        }

        void dispatchAutomationEvent({
          triggerType: 'leadCreated',
          entityId: result.data.id,
          entityType: 'lead',
          businessId: context.businessId,
          toStatus: leadData.status,
        });

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create lead');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [crmUser, getContext]
  );

  // Update an existing lead
  const updateLead = useCallback(
    async (id: string, data: Partial<Lead>, options?: { allowDuplicate?: boolean }): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        const result = await repo.update(
          context,
          id,
          {
            ...data,
            ...(options?.allowDuplicate ? { allowDuplicate: true } : {}),
            teamIds: data.teamIds ? sanitizeTeamIds(data.teamIds) : data.teamIds,
          } as Partial<Lead> & { allowDuplicate?: boolean }
        );

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update lead');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Delete a lead
  const deleteLead = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete lead');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update lead status with validation
  const updateStatus = useCallback(
    async (id: string, status: LeadStatus): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();
        let previousStatus: LeadStatus | undefined;

        const existing = await repo.getById(context, id);
        if (existing.success && existing.data) {
          previousStatus = existing.data.status;
        }

        const result = await repo.updateStatus(context, id, status);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        void dispatchAutomationEvent({
          triggerType: 'leadStatusChanged',
          entityId: id,
          entityType: 'lead',
          businessId: context.businessId,
          fromStatus: previousStatus,
          toStatus: status,
        });
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update lead status');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Assign lead to a user
  const assignLead = useCallback(
    async (id: string, assigneeId: string, assigneeName: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        const result = await repo.assignTo(context, id, assigneeId, assigneeName);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to assign lead');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Bulk assign multiple leads
  const bulkAssign = useCallback(
    async (
      ids: string[],
      assigneeId: string,
      assigneeName: string
    ): Promise<{ successCount: number; failedIds: string[] }> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        const result = await repo.bulkAssign(context, ids, assigneeId, assigneeName);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to bulk assign leads');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Bulk update status for multiple leads
  const bulkUpdateStatus = useCallback(
    async (
      ids: string[],
      status: LeadStatus
    ): Promise<{ successCount: number; failedIds: string[] }> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        const result = await repo.bulkUpdateStatus(context, ids, status);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to bulk update lead status');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Bulk delete multiple leads
  const bulkDelete = useCallback(
    async (ids: string[]): Promise<{ successCount: number; failedIds: string[] }> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getLeadRepository();

        let successCount = 0;
        const failedIds: string[] = [];

        // Delete one by one since repository doesn't have bulkDelete
        for (const id of ids) {
          const result = await repo.delete(context, id);
          if (result.success) {
            successCount++;
          } else {
            failedIds.push(id);
          }
        }

        return { successCount, failedIds };
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to bulk delete leads');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createLead: guardMutation(createLead, { action: 'lead-create' }),
    updateLead: guardMutation(updateLead, { action: 'lead-update' }),
    deleteLead: guardMutation(deleteLead, { action: 'lead-delete' }),
    updateStatus: guardMutation(updateStatus, { action: 'lead-status-update' }),
    assignLead: guardMutation(assignLead, { action: 'lead-assign' }),
    bulkAssign: guardMutation(bulkAssign, { action: 'lead-bulk-assign' }),
    bulkUpdateStatus: guardMutation(bulkUpdateStatus, { action: 'lead-bulk-status' }),
    bulkDelete: guardMutation(bulkDelete, { action: 'lead-bulk-delete' }),
    isLoading,
    error,
    clearError,
  };
}

export default useLeadMutations;
