/**
 * useEntitySequenceStatus Hook
 * Check enrollment status and availability for a specific entity
 *
 * Phase 3 Implementation
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { createSecurityContext } from './usePipeline';
import { getFeatureFlags } from '../config/features';
import type {
  SequenceEnrollment,
  EnrollmentEntityType,
} from '../types/sequences';

// ============================================
// Types
// ============================================

export type EnrollmentBlockReason =
  | 'no_email'
  | 'opted_out'
  | 'already_enrolled'
  | 'feature_disabled';

export interface UseEntitySequenceStatusResult {
  /** Whether entity is currently enrolled in any sequence */
  isEnrolled: boolean;
  /** Active enrollment (if any) */
  activeEnrollment: SequenceEnrollment | null;
  /** Past enrollments */
  enrollmentHistory: SequenceEnrollment[];
  /** Whether entity can be enrolled */
  canEnroll: boolean;
  /** Reason enrollment is blocked (if applicable) */
  enrollmentBlockReason?: EnrollmentBlockReason;
  /** Human-readable message for block reason */
  enrollmentBlockMessage?: string;
  /** True while loading */
  isLoading: boolean;
  /** Error if any */
  error: Error | null;
  /** Refresh data */
  refresh: () => void;
  /** Whether sequences feature is enabled */
  isSequencesEnabled: boolean;
}

// ============================================
// Hook
// ============================================

/**
 * Hook to check entity's sequence enrollment status
 *
 * @example
 * ```tsx
 * const { canEnroll, isEnrolled, enrollmentBlockMessage } = useEntitySequenceStatus(
 *   'lead',
 *   leadId,
 *   lead.email
 * );
 * ```
 */
export function useEntitySequenceStatus(
  entityType: EnrollmentEntityType | undefined,
  entityId: string | undefined,
  entityEmail?: string,
  hasOptedOut?: boolean
): UseEntitySequenceStatusResult {
  const { crmUser, businessId } = useAuth();
  const [activeEnrollment, setActiveEnrollment] = useState<SequenceEnrollment | null>(null);
  const [enrollmentHistory, setEnrollmentHistory] = useState<SequenceEnrollment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Check feature flag
  const features = getFeatureFlags();
  const isSequencesEnabled = features.enableSequences;

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

  // Fetch enrollment status
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

      // Find active enrollment (active or paused)
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

  // Refresh function
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  // Determine enrollment eligibility
  const eligibility = useMemo(() => {
    // Feature disabled
    if (!isSequencesEnabled) {
      return {
        canEnroll: false,
        blockReason: 'feature_disabled' as EnrollmentBlockReason,
        blockMessage: 'Sequences feature is not enabled',
      };
    }

    // Already enrolled
    if (activeEnrollment) {
      return {
        canEnroll: false,
        blockReason: 'already_enrolled' as EnrollmentBlockReason,
        blockMessage: `Already enrolled in sequence: ${activeEnrollment.sequenceName}`,
      };
    }

    // No email
    if (!entityEmail || !entityEmail.trim()) {
      return {
        canEnroll: false,
        blockReason: 'no_email' as EnrollmentBlockReason,
        blockMessage: 'Email address is required for sequence enrollment',
      };
    }

    // Opted out
    if (hasOptedOut) {
      return {
        canEnroll: false,
        blockReason: 'opted_out' as EnrollmentBlockReason,
        blockMessage: 'Contact has opted out of email communications',
      };
    }

    return {
      canEnroll: true,
      blockReason: undefined,
      blockMessage: undefined,
    };
  }, [isSequencesEnabled, activeEnrollment, entityEmail, hasOptedOut]);

  return {
    isEnrolled: !!activeEnrollment,
    activeEnrollment,
    enrollmentHistory,
    canEnroll: eligibility.canEnroll,
    enrollmentBlockReason: eligibility.blockReason,
    enrollmentBlockMessage: eligibility.blockMessage,
    isLoading,
    error,
    refresh,
    isSequencesEnabled,
  };
}

// ============================================
// Simplified Variant (skip validation)
// ============================================

/**
 * Simplified hook that only fetches enrollment status without validation checks
 * Use when you already have enrollment data or don't need validation
 */
export function useEntityEnrollmentStatus(
  entityType: EnrollmentEntityType | undefined,
  entityId: string | undefined
): {
  isEnrolled: boolean;
  activeEnrollment: SequenceEnrollment | null;
  isLoading: boolean;
  refresh: () => void;
} {
  const { crmUser, businessId } = useAuth();
  const [activeEnrollment, setActiveEnrollment] = useState<SequenceEnrollment | null>(null);
  const [isLoading, setIsLoading] = useState(true);
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

  useEffect(() => {
    async function fetch() {
      if (!businessId || !crmUser || !entityType || !entityId) {
        setActiveEnrollment(null);
        setIsLoading(false);
        return;
      }

      setIsLoading(true);

      try {
        const context = getContext();
        const repo = getSequenceEnrollmentRepository();
        const result = await repo.getActiveByEntity(context, entityType, entityId);

        if (result.success) {
          setActiveEnrollment(result.data);
        }
      } catch {
        // Silent error
      } finally {
        setIsLoading(false);
      }
    }

    fetch();
  }, [businessId, crmUser, entityType, entityId, getContext, refreshKey]);

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  return {
    isEnrolled: !!activeEnrollment,
    activeEnrollment,
    isLoading,
    refresh,
  };
}

export default useEntitySequenceStatus;
