/**
 * useSequences Hook
 * Manages sequence list with filtering and mutations
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { createSecurityContext } from './usePipeline';
import type {
  Sequence,
  SequenceFilters,
  SequenceStep,
  SequenceSettings,
} from '../types/sequences';
import { getShareableAccessSummary, type ShareableAccessSummary } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseSequencesResult {
  /** List of sequences matching filters */
  sequences: Sequence[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh the sequence list */
  refresh: () => void;
  /** Total count of filtered sequences */
  totalCount: number;
  /** Access metadata helper for UI guards */
  getAccessSummary: (sequence: Sequence | null | undefined) => ShareableAccessSummary | null;
}

export interface UseSequenceResult {
  /** Single sequence */
  sequence: Sequence | null;
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh */
  refresh: () => void;
  /** Access metadata */
  accessSummary: ShareableAccessSummary | null;
}

export interface UseSequenceMutationsResult {
  /** Create a new sequence */
  createSequence: (data: CreateSequenceInput) => Promise<Sequence>;
  /** Update an existing sequence */
  updateSequence: (id: string, data: Partial<Sequence>) => Promise<Sequence>;
  /** Delete/archive a sequence */
  archiveSequence: (id: string) => Promise<void>;
  /** Activate a sequence */
  activateSequence: (id: string) => Promise<Sequence>;
  /** Pause a sequence */
  pauseSequence: (id: string) => Promise<Sequence>;
  /** Duplicate a sequence */
  duplicateSequence: (id: string, newName?: string) => Promise<Sequence>;
  /** Update sequence steps */
  updateSteps: (id: string, steps: SequenceStep[]) => Promise<Sequence>;
  /** Loading state for mutations */
  isMutating: boolean;
  /** Error from last mutation */
  mutationError: Error | null;
}

export interface CreateSequenceInput {
  name: string;
  description?: string;
  steps?: SequenceStep[];
  settings?: Partial<SequenceSettings>;
}

// ============================================
// useSequences Hook
// ============================================

/**
 * Hook for fetching and filtering sequences
 */
export function useSequences(filters?: SequenceFilters): UseSequencesResult {
  const { crmUser, businessId } = useAuth();
  const [sequences, setSequences] = useState<Sequence[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const statusFilter = filters?.status;
  const ownerIdFilter = filters?.ownerId;
  const searchFilter = filters?.search;

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

  const getAccessSummary = useCallback(
    (sequence: Sequence | null | undefined): ShareableAccessSummary | null => {
      if (!sequence || !businessId || !crmUser) return null;
      try {
        const context = getContext();
        return getShareableAccessSummary(context, sequence);
      } catch {
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Fetch sequences
  const fetchSequences = useCallback(async () => {
    if (!businessId || !crmUser) {
      setSequences([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSequenceRepository();

      let fetchedSequences: Sequence[] = [];

      // Use appropriate query based on filters
      if (statusFilter) {
        const result = await repo.getByStatus(context, statusFilter);
        if (result.success) {
          fetchedSequences = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (ownerIdFilter) {
        const result = await repo.getByOwner(context, ownerIdFilter);
        if (result.success) {
          fetchedSequences = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else {
        const result = await repo.getAll(context, {
          orderBy: { field: 'createdAt', direction: 'desc' },
        });
        if (result.success) {
          fetchedSequences = result.data.data;
        } else {
          throw new Error(result.error.message);
        }
      }

      // Apply client-side search filter
      if (searchFilter) {
        const searchLower = searchFilter.toLowerCase();
        fetchedSequences = fetchedSequences.filter(
          (seq) =>
            seq.name.toLowerCase().includes(searchLower) ||
            seq.description?.toLowerCase().includes(searchLower)
        );
      }

      setSequences(fetchedSequences);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch sequences'));
      setSequences([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, ownerIdFilter, searchFilter, statusFilter]);

  useEffect(() => {
    fetchSequences();
  }, [fetchSequences, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    sequences,
    isLoading,
    error,
    refresh,
    totalCount: sequences.length,
    getAccessSummary,
  };
}

// ============================================
// useSequence Hook (single sequence)
// ============================================

/**
 * Hook for fetching a single sequence by ID
 */
export function useSequence(sequenceId: string | undefined): UseSequenceResult {
  const { crmUser, businessId } = useAuth();
  const [sequence, setSequence] = useState<Sequence | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

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

  const accessSummary = useMemo(() => {
    if (!sequence || !businessId || !crmUser) return null;
    try {
      const context = getContext();
      return getShareableAccessSummary(context, sequence);
    } catch {
      return null;
    }
  }, [sequence, businessId, crmUser, getContext]);

  const fetchSequence = useCallback(async () => {
    if (!businessId || !crmUser || !sequenceId) {
      setSequence(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSequenceRepository();
      const result = await repo.getById(context, sequenceId);

      if (result.success) {
        setSequence(result.data);
      } else {
        throw new Error(result.error.message);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch sequence'));
      setSequence(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, sequenceId]);

  useEffect(() => {
    fetchSequence();
  }, [fetchSequence, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    sequence,
    isLoading,
    error,
    refresh,
    accessSummary,
  };
}

// ============================================
// useSequenceMutations Hook
// ============================================

/**
 * Hook for sequence mutations (create, update, delete, etc.)
 */
export function useSequenceMutations(): UseSequenceMutationsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isMutating, setIsMutating] = useState(false);
  const [mutationError, setMutationError] = useState<Error | null>(null);

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

  const createSequence = useCallback(
    async (data: CreateSequenceInput): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();

        const sequenceData: Omit<Sequence, 'id' | 'createdAt' | 'updatedAt'> = {
          name: data.name,
          description: data.description,
          status: 'draft',
          steps: data.steps || [],
          settings: {
            sendingSchedule: {
              timezone: 'America/New_York',
              businessHoursOnly: true,
              startHour: 9,
              endHour: 17,
              excludeDays: [0, 6],
            },
            pauseOnReply: true,
            pauseOnOpen: false,
            pauseOnMeetingBooked: true,
            removeOnUnsubscribe: true,
            threadEmails: false,
            ...data.settings,
          },
          stats: {
            totalEnrolled: 0,
            activeEnrollments: 0,
            completedCount: 0,
            exitedCount: 0,
          },
          exitCriteria: {
            onReply: true,
            onMeetingBooked: true,
            onDealWon: true,
            onDealLost: true,
            onLeadConverted: true,
            onManualRemoval: true,
          },
          ownerId: context.userId,
          ownerName: context.userName,
          teamIds: context.teamIds || [],
          visibility: 'team',
        };

        const result = await repo.create(context, sequenceData);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const updateSequence = useCallback(
    async (id: string, data: Partial<Sequence>): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.update(context, id, data);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const archiveSequence = useCallback(
    async (id: string): Promise<void> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.archive(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to archive sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const activateSequence = useCallback(
    async (id: string): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.activate(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to activate sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const pauseSequence = useCallback(
    async (id: string): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.pause(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to pause sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const duplicateSequence = useCallback(
    async (id: string, newName?: string): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.duplicate(context, id, newName);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to duplicate sequence');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const updateSteps = useCallback(
    async (id: string, steps: SequenceStep[]): Promise<Sequence> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceRepository();
        const result = await repo.updateSteps(context, id, steps);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update steps');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  return {
    createSequence: guardMutation(createSequence, { action: 'sequence-create' }),
    updateSequence: guardMutation(updateSequence, { action: 'sequence-update' }),
    archiveSequence: guardMutation(archiveSequence, { action: 'sequence-archive' }),
    activateSequence: guardMutation(activateSequence, { action: 'sequence-activate' }),
    pauseSequence: guardMutation(pauseSequence, { action: 'sequence-pause' }),
    duplicateSequence: guardMutation(duplicateSequence, { action: 'sequence-duplicate' }),
    updateSteps: guardMutation(updateSteps, { action: 'sequence-steps-update' }),
    isMutating,
    mutationError,
  };
}

export default useSequences;
