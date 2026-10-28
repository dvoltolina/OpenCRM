/**
 * useSequenceEnrollments Hook
 * Manages sequence enrollments for leads/contacts/deals
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { createSecurityContext } from './usePipeline';
import type {
  SequenceEnrollment,
  EnrollmentStatus,
  EnrollmentEntityType,
  ExitReason,
  EnrollmentFilters,
} from '../types/sequences';

// ============================================
// Types
// ============================================

export interface UseSequenceEnrollmentsResult {
  /** List of enrollments */
  enrollments: SequenceEnrollment[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Manually refresh the list */
  refresh: () => void;
  /** Total count */
  totalCount: number;
  /** Count by status */
  countByStatus: Record<EnrollmentStatus, number>;
}

export interface UseEntityEnrollmentResult {
  /** Active enrollment for this entity (if any) */
  activeEnrollment: SequenceEnrollment | null;
  /** All enrollments for this entity */
  enrollmentHistory: SequenceEnrollment[];
  /** Whether entity is currently enrolled */
  isEnrolled: boolean;
  /** Whether entity can be enrolled */
  canEnroll: boolean;
  /** Reason entity cannot be enrolled (if applicable) */
  enrollmentBlockReason?: string;
  /** True while loading */
  isLoading: boolean;
  /** Error if any */
  error: Error | null;
  /** Refresh data */
  refresh: () => void;
}

export interface UseEnrollmentMutationsResult {
  /** Enroll an entity in a sequence */
  enroll: (params: EnrollParams) => Promise<SequenceEnrollment>;
  /** Bulk enroll multiple entities */
  bulkEnroll: (params: BulkEnrollParams) => Promise<BulkEnrollResult>;
  /** Pause an enrollment */
  pause: (enrollmentId: string, reason?: string) => Promise<SequenceEnrollment>;
  /** Resume a paused enrollment */
  resume: (enrollmentId: string) => Promise<SequenceEnrollment>;
  /** Exit an enrollment */
  exit: (enrollmentId: string, reason: ExitReason) => Promise<SequenceEnrollment>;
  /** Loading state */
  isMutating: boolean;
  /** Error from last mutation */
  mutationError: Error | null;
}

export interface UseEnrollmentResult {
  enrollment: SequenceEnrollment | null;
  isLoading: boolean;
  error: Error | null;
  refresh: () => void;
}

export interface EnrollParams {
  sequenceId: string;
  sequenceName: string;
  entityType: EnrollmentEntityType;
  entityId: string;
  entityName: string;
  entityEmail: string;
  /** Total steps in the sequence */
  totalSteps: number;
}

export interface BulkEnrollParams {
  sequenceId: string;
  sequenceName: string;
  totalSteps: number;
  entities: Array<{
    type: EnrollmentEntityType;
    id: string;
    name: string;
    email: string;
  }>;
}

export interface BulkEnrollResult {
  enrolled: string[];
  skipped: Array<{ entityId: string; reason: string }>;
}

// ============================================
// useSequenceEnrollments Hook
// ============================================

/**
 * Hook for fetching enrollments for a sequence
 */
export function useSequenceEnrollments(
  sequenceId: string | undefined,
  filters?: EnrollmentFilters
): UseSequenceEnrollmentsResult {
  const { crmUser, businessId } = useAuth();
  const [enrollments, setEnrollments] = useState<SequenceEnrollment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const statusFilter = filters?.status;
  const entityTypeFilter = filters?.entityType;
  const searchFilter = filters?.search;

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

  const fetchEnrollments = useCallback(async () => {
    if (!businessId || !crmUser || !sequenceId) {
      setEnrollments([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSequenceEnrollmentRepository();

      const result = await repo.getBySequence(context, sequenceId, statusFilter);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      let fetchedEnrollments = result.data;

      // Apply client-side filters
      if (entityTypeFilter) {
        fetchedEnrollments = fetchedEnrollments.filter(
          (e) => e.entityType === entityTypeFilter
        );
      }

      if (searchFilter) {
        const searchLower = searchFilter.toLowerCase();
        fetchedEnrollments = fetchedEnrollments.filter(
          (e) =>
            e.entityName.toLowerCase().includes(searchLower) ||
            e.entityEmail.toLowerCase().includes(searchLower)
        );
      }

      setEnrollments(fetchedEnrollments);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch enrollments'));
      setEnrollments([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, entityTypeFilter, getContext, searchFilter, sequenceId, statusFilter]);

  useEffect(() => {
    fetchEnrollments();
  }, [fetchEnrollments, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  const countByStatus = useMemo(() => {
    const counts: Record<EnrollmentStatus, number> = {
      active: 0,
      paused: 0,
      completed: 0,
      exited: 0,
      bounced: 0,
      unsubscribed: 0,
    };

    enrollments.forEach((e) => {
      counts[e.status]++;
    });

    return counts;
  }, [enrollments]);

  return {
    enrollments,
    isLoading,
    error,
    refresh,
    totalCount: enrollments.length,
    countByStatus,
  };
}

// ============================================
// useEntityEnrollment Hook
// ============================================

/**
 * Hook for checking enrollment status of a specific entity
 */
export function useEntityEnrollment(
  entityType: EnrollmentEntityType | undefined,
  entityId: string | undefined,
  entityEmail?: string
): UseEntityEnrollmentResult {
  const { crmUser, businessId } = useAuth();
  const [activeEnrollment, setActiveEnrollment] = useState<SequenceEnrollment | null>(null);
  const [enrollmentHistory, setEnrollmentHistory] = useState<SequenceEnrollment[]>([]);
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

  const fetchEnrollments = useCallback(async () => {
    if (!businessId || !crmUser || !entityType || !entityId) {
      setActiveEnrollment(null);
      setEnrollmentHistory([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSequenceEnrollmentRepository();

      // Get all enrollments for this entity
      const result = await repo.getByEntity(context, entityType, entityId);

      if (!result.success) {
        throw new Error(result.error.message);
      }

      setEnrollmentHistory(result.data);

      // Find active enrollment
      const active = result.data.find(
        (e) => e.status === 'active' || e.status === 'paused'
      );
      setActiveEnrollment(active || null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch enrollment status'));
      setActiveEnrollment(null);
      setEnrollmentHistory([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, entityType, entityId, getContext]);

  useEffect(() => {
    fetchEnrollments();
  }, [fetchEnrollments, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  // Determine if entity can be enrolled
  const { canEnroll, enrollmentBlockReason } = useMemo(() => {
    if (activeEnrollment) {
      return {
        canEnroll: false,
        enrollmentBlockReason: `Already enrolled in sequence: ${activeEnrollment.sequenceName}`,
      };
    }

    if (!entityEmail) {
      return {
        canEnroll: false,
        enrollmentBlockReason: 'Email address is required for enrollment',
      };
    }

    return { canEnroll: true, enrollmentBlockReason: undefined };
  }, [activeEnrollment, entityEmail]);

  return {
    activeEnrollment,
    enrollmentHistory,
    isEnrolled: !!activeEnrollment,
    canEnroll,
    enrollmentBlockReason,
    isLoading,
    error,
    refresh,
  };
}

/**
 * Hook for fetching a single enrollment by ID
 */
export function useEnrollment(enrollmentId: string | undefined): UseEnrollmentResult {
  const { crmUser, businessId } = useAuth();
  const [enrollment, setEnrollment] = useState<SequenceEnrollment | null>(null);
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

  const fetchEnrollment = useCallback(async () => {
    if (!businessId || !crmUser || !enrollmentId) {
      setEnrollment(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const repo = getSequenceEnrollmentRepository();
      const result = await repo.getById(context, enrollmentId);

      if (result.success) {
        setEnrollment(result.data);
      } else {
        throw new Error(result.error?.message || 'Failed to fetch enrollment');
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch enrollment'));
      setEnrollment(null);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, enrollmentId, getContext]);

  useEffect(() => {
    fetchEnrollment();
  }, [fetchEnrollment, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    enrollment,
    isLoading,
    error,
    refresh,
  };
}

// ============================================
// useEnrollmentMutations Hook
// ============================================

/**
 * Hook for enrollment mutations
 */
export function useEnrollmentMutations(): UseEnrollmentMutationsResult {
  const { crmUser, businessId } = useAuth();
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

  const enroll = useCallback(
    async (params: EnrollParams): Promise<SequenceEnrollment> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const enrollmentRepo = getSequenceEnrollmentRepository();
        const sequenceRepo = getSequenceRepository();

        const enrollmentData: Omit<SequenceEnrollment, 'id' | 'createdAt' | 'updatedAt'> = {
          sequenceId: params.sequenceId,
          sequenceName: params.sequenceName,
          entityType: params.entityType,
          entityId: params.entityId,
          entityName: params.entityName,
          entityEmail: params.entityEmail,
          status: 'active',
          currentStepIndex: 0,
          stepsCompleted: 0,
          totalSteps: params.totalSteps,
          emailsSent: 0,
          emailsOpened: 0,
          emailsClicked: 0,
          tasksCreated: 0,
          repliesReceived: 0,
          enrolledById: context.userId,
          enrolledByName: context.userName,
          ownerId: context.userId,
          ownerName: context.userName,
          teamIds: context.teamIds || [],
          visibility: 'team',
        };

        const result = await enrollmentRepo.enroll(context, enrollmentData);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        // Update sequence stats
        await sequenceRepo.incrementStat(context, params.sequenceId, 'totalEnrolled');
        await sequenceRepo.incrementStat(context, params.sequenceId, 'activeEnrollments');

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to enroll');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const bulkEnroll = useCallback(
    async (params: BulkEnrollParams): Promise<BulkEnrollResult> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const enrollmentRepo = getSequenceEnrollmentRepository();
        const sequenceRepo = getSequenceRepository();

        const enrollments = params.entities.map((entity) => ({
          sequenceId: params.sequenceId,
          sequenceName: params.sequenceName,
          entityType: entity.type,
          entityId: entity.id,
          entityName: entity.name,
          entityEmail: entity.email,
          status: 'active' as EnrollmentStatus,
          currentStepIndex: 0,
          stepsCompleted: 0,
          totalSteps: params.totalSteps,
          emailsSent: 0,
          emailsOpened: 0,
          emailsClicked: 0,
          tasksCreated: 0,
          repliesReceived: 0,
          enrolledById: context.userId,
          enrolledByName: context.userName,
          ownerId: context.userId,
          ownerName: context.userName,
          teamIds: context.teamIds || [],
          visibility: 'team' as const,
        }));

        const result = await enrollmentRepo.bulkEnroll(context, enrollments);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        // Update sequence stats
        const enrolledCount = result.data.enrolled.length;
        if (enrolledCount > 0) {
          await sequenceRepo.incrementStat(
            context,
            params.sequenceId,
            'totalEnrolled',
            enrolledCount
          );
          await sequenceRepo.incrementStat(
            context,
            params.sequenceId,
            'activeEnrollments',
            enrolledCount
          );
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to bulk enroll');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const pause = useCallback(
    async (enrollmentId: string, reason?: string): Promise<SequenceEnrollment> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceEnrollmentRepository();
        const result = await repo.pause(context, enrollmentId, reason);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to pause enrollment');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const resume = useCallback(
    async (enrollmentId: string): Promise<SequenceEnrollment> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const repo = getSequenceEnrollmentRepository();
        const result = await repo.resume(context, enrollmentId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to resume enrollment');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  const exit = useCallback(
    async (enrollmentId: string, reason: ExitReason): Promise<SequenceEnrollment> => {
      setIsMutating(true);
      setMutationError(null);

      try {
        const context = getContext();
        const enrollmentRepo = getSequenceEnrollmentRepository();
        const sequenceRepo = getSequenceRepository();

        // Get enrollment to find sequence
        const getResult = await enrollmentRepo.getById(context, enrollmentId);
        if (!getResult.success) {
          throw new Error(getResult.error.message);
        }

        const result = await enrollmentRepo.exit(context, enrollmentId, reason);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        // Update sequence stats
        await sequenceRepo.incrementStat(context, getResult.data.sequenceId, 'exitedCount');
        await sequenceRepo.incrementStat(
          context,
          getResult.data.sequenceId,
          'activeEnrollments',
          -1
        );

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to exit enrollment');
        setMutationError(error);
        throw error;
      } finally {
        setIsMutating(false);
      }
    },
    [getContext]
  );

  return {
    enroll,
    bulkEnroll,
    pause,
    resume,
    exit,
    isMutating,
    mutationError,
  };
}

export default useSequenceEnrollments;
