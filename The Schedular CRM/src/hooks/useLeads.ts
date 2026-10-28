/**
 * useLeads Hook
 * Lead list with filtering, search, and pagination support
 *
 * Agent CRM-08 Implementation
 * Dependencies: Agent CRM-03 (leads repository)
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getLeadRepository, type LeadFilterOptions } from '../data/repositories/lead-repository';
import { createSecurityContext } from './usePipeline';
import type { Lead, LeadStatus, LeadSource } from '../types/models';
import {
  getUserManagedTeamIds,
  getUserTeamIds,
  getShareableAccessSummary,
  type ShareableAccessSummary,
} from '../lib/security-context';
import type { DocumentSnapshot } from 'firebase/firestore';

// ============================================
// Types
// ============================================

export interface LeadFilters {
  /** Filter by lead status */
  status?: LeadStatus;
  /** Filter by lead source */
  source?: LeadSource;
  /** Filter by assignee user ID */
  assigneeId?: string;
  /** Search by name, email, or company */
  search?: string;
  /** Filter by date range */
  dateRange?: { start: Date; end: Date };
  /** Filter by tags */
  tags?: string[];
}

export interface UseLeadsResult {
  /** List of leads matching filters */
  leads: Lead[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether there are more results to load */
  hasMore: boolean;
  /** Load more results (for infinite scroll) */
  loadMore: () => void;
  /** Manually refresh the lead list */
  refresh: () => void;
  /** Total count of leads (approximate for filtered results) */
  totalCount: number;
  /** Whether currently loading more results */
  isLoadingMore: boolean;
  /** Access metadata helper for UI guards */
  getAccessSummary: (lead: Lead | null | undefined) => ShareableAccessSummary | null;
}

// ============================================
// Constants
// ============================================

const DEFAULT_PAGE_SIZE = 25;
const SEARCH_DEBOUNCE_MS = 300;

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and filtering leads
 *
 * @param filters - Optional filters to apply
 * @param pageSize - Number of results per page (default: 25)
 * @returns Lead list, loading state, and pagination controls
 *
 * @example
 * ```tsx
 * const { leads, isLoading, hasMore, loadMore } = useLeads({
 *   status: 'qualified',
 *   assigneeId: currentUserId,
 * });
 *
 * if (isLoading) return <Spinner />;
 *
 * return (
 *   <LeadList
 *     leads={leads}
 *     onLoadMore={loadMore}
 *     hasMore={hasMore}
 *   />
 * );
 * ```
 */
export function useLeads(
  filters?: LeadFilters,
  pageSize: number = DEFAULT_PAGE_SIZE
): UseLeadsResult {
  const { crmUser, businessId } = useAuth();
  const [leads, setLeads] = useState<Lead[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);

  // Track last document for pagination
  const lastDocRef = useRef<DocumentSnapshot | null | undefined>(undefined);
  const leadCountRef = useRef(0);

  // Request cancellation for preventing stale results
  const abortControllerRef = useRef<AbortController | null>(null);

  // Debounce search
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const [debouncedSearch, setDebouncedSearch] = useState(filters?.search);

  // Debounce search input
  useEffect(() => {
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    searchTimeoutRef.current = setTimeout(() => {
      setDebouncedSearch(filters?.search);
    }, SEARCH_DEBOUNCE_MS);

    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
    };
  }, [filters?.search]);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      getUserTeamIds(crmUser),
      getUserManagedTeamIds(crmUser)
    );
  }, [businessId, crmUser]);

  const getAccessSummary = useCallback(
    (lead: Lead | null | undefined): ShareableAccessSummary | null => {
      if (!lead || !businessId || !crmUser) return null;
      try {
        const context = getContext();
        return getShareableAccessSummary(context, lead);
      } catch {
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Convert filters to repository format
  const getFilterOptions = useCallback((): LeadFilterOptions => {
    return {
      status: filters?.status,
      source: filters?.source,
      assigneeId: filters?.assigneeId,
      search: debouncedSearch,
      dateRange: filters?.dateRange,
      tags: filters?.tags,
    };
  }, [filters?.status, filters?.source, filters?.assigneeId, debouncedSearch, filters?.dateRange, filters?.tags]);

  // Fetch leads
  const fetchLeads = useCallback(
    async (loadingMore: boolean = false) => {
      if (!businessId || !crmUser) {
        setLeads([]);
        setIsLoading(false);
        return;
      }

      // Cancel previous request to prevent stale results
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      abortControllerRef.current = new AbortController();
      const currentAbortController = abortControllerRef.current;

      if (loadingMore) {
        setIsLoadingMore(true);
      } else {
        setIsLoading(true);
        lastDocRef.current = null;
      }
      setError(null);

      try {
        // Check if request was cancelled
        if (currentAbortController.signal.aborted) {
          return;
        }
        const context = getContext();
        const repo = getLeadRepository();
        const filterOptions = getFilterOptions();

        // If search is provided, use search method
        if (filterOptions.search) {
          const result = await repo.search(context, filterOptions.search, {
            limit: pageSize,
          });

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newLeads = result.data.data;
            const nextTotal = loadingMore ? leadCountRef.current + newLeads.length : newLeads.length;
            if (loadingMore) {
              setLeads((prev) => [...prev, ...newLeads]);
            } else {
              setLeads(newLeads);
            }
            setHasMore(result.data.hasMore);
            leadCountRef.current = nextTotal;
            setTotalCount(nextTotal);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) {
              leadCountRef.current = 0;
              setTotalCount(0);
              setLeads([]);
            }
          }
        } else {
          // Use filtered query
          const result = await repo.getFiltered(context, filterOptions, {
            limit: pageSize,
            startAfter: loadingMore && lastDocRef.current ? lastDocRef.current : undefined,
            orderBy: { field: 'createdAt', direction: 'desc' },
          });

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newLeads = result.data.data;
            const nextTotal = loadingMore ? leadCountRef.current + newLeads.length : newLeads.length;
            if (loadingMore) {
              setLeads((prev) => [...prev, ...newLeads]);
            } else {
              setLeads(newLeads);
            }
            setHasMore(result.data.hasMore);
            lastDocRef.current = result.data.lastDoc;
            leadCountRef.current = nextTotal;
            setTotalCount(nextTotal);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) {
              leadCountRef.current = 0;
              setTotalCount(0);
              setLeads([]);
            }
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch leads'));
        if (!loadingMore) {
          leadCountRef.current = 0;
          setTotalCount(0);
          setLeads([]);
        }
      } finally {
        if (loadingMore) {
          setIsLoadingMore(false);
        } else {
          setIsLoading(false);
        }
      }
    },
    [businessId, crmUser, getContext, getFilterOptions, pageSize]
  );

  // Initial fetch and refetch on filter changes
  useEffect(() => {
    fetchLeads(false);
  }, [fetchLeads]);

  // Load more
  const loadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      fetchLeads(true);
    }
  }, [fetchLeads, isLoadingMore, hasMore]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchLeads(false);
  }, [fetchLeads]);

  return {
    leads,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
    totalCount,
    isLoadingMore,
    getAccessSummary,
  };
}

export default useLeads;
