/**
 * useDeals Hook
 * Manages deal list with filtering and pagination
 *
 * Agent CRM-09 Implementation
 * Dependencies: Agent CRM-04 (deals repository), Agent CRM-07 (pipeline hooks)
 */

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getDealRepository } from '../data/repositories/deal-repository';
import { createSecurityContext } from './usePipeline';
import type { Deal, DealStatus } from '../types/models';
import type { DocumentSnapshot } from 'firebase/firestore';
import { getShareableAccessSummary, type ShareableAccessSummary } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface DealFilters {
  pipelineId?: string;
  stageId?: string;
  status?: DealStatus;
  assigneeId?: string;
  clientId?: string;
  companyId?: string;
  search?: string;
  dateRange?: { start: Date; end: Date };
  valueRange?: { min: number; max: number };
  /** Filter by assigned rep UID (inherited from contact in unified funnel) */
  assignedRepUid?: string;
}

export interface UseDealsResult {
  /** List of deals matching filters */
  deals: Deal[];
  /** True while data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether there are more deals to load */
  hasMore: boolean;
  /** Load more deals for pagination */
  loadMore: () => void;
  /** Total value of all filtered deals (in cents) */
  totalValue: number;
  /** Total count of filtered deals */
  totalCount: number;
  /** Manually refresh the deal list */
  refresh: () => void;
  /** Whether currently loading more results */
  isLoadingMore: boolean;
  /** Access metadata helper for UI guards */
  getAccessSummary: (deal: Deal | null | undefined) => ShareableAccessSummary | null;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and filtering deals
 *
 * @param filters - Optional filters to apply
 * @returns Deal list, totals, and state
 *
 * @example
 * ```tsx
 * const { deals, isLoading, totalValue } = useDeals({
 *   pipelineId: 'pipeline-123',
 *   status: 'open',
 * });
 * ```
 */
export function useDeals(filters?: DealFilters): UseDealsResult {
  const { crmUser, businessId } = useAuth();
  const [deals, setDeals] = useState<Deal[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  // Track last document for pagination
  const lastDocRef = useRef<DocumentSnapshot | null | undefined>(undefined);

  // Stabilize filter values for dependency array
  const filterKey = useMemo(
    () =>
      JSON.stringify({
        pipelineId: filters?.pipelineId,
        stageId: filters?.stageId,
        status: filters?.status,
        assigneeId: filters?.assigneeId,
        clientId: filters?.clientId,
        companyId: filters?.companyId,
        search: filters?.search,
        valueRangeMin: filters?.valueRange?.min,
        valueRangeMax: filters?.valueRange?.max,
        dateRangeStart: filters?.dateRange?.start?.getTime(),
        dateRangeEnd: filters?.dateRange?.end?.getTime(),
      }),
    [filters]
  );

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
    (deal: Deal | null | undefined): ShareableAccessSummary | null => {
      if (!deal || !businessId || !crmUser) return null;
      try {
        const context = getContext();
        return getShareableAccessSummary(context, deal);
      } catch {
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Fetch deals with filters
  const fetchDeals = useCallback(async (loadingMore: boolean = false) => {
    if (!businessId || !crmUser) {
      setDeals([]);
      setIsLoading(false);
      return;
    }

    if (loadingMore) {
      setIsLoadingMore(true);
    } else {
      setIsLoading(true);
      lastDocRef.current = null;
    }
    setError(null);

    try {
      const context = getContext();
      const repo = getDealRepository();

      let fetchedDeals: Deal[] = [];

      // Determine which repository method to use based on filters
      if (filters?.pipelineId && filters?.stageId) {
        const result = await repo.getByStage(context, filters.pipelineId, filters.stageId);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (filters?.pipelineId) {
        const result = await repo.getByPipeline(context, filters.pipelineId);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (filters?.status) {
        const result = await repo.getByStatus(context, filters.status);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (filters?.assigneeId) {
        const result = await repo.getByAssignee(context, filters.assigneeId);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (filters?.clientId) {
        const result = await repo.getByClient(context, filters.clientId);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else if (filters?.companyId) {
        const result = await repo.getByCompany(context, filters.companyId);
        if (result.success) {
          fetchedDeals = result.data;
        } else {
          throw new Error(result.error.message);
        }
      } else {
        // Get all deals (paginated with cursor)
        const result = await repo.getAll(context, {
          limit: 100,
          startAfter: loadingMore && lastDocRef.current ? lastDocRef.current : undefined,
          orderBy: { field: 'createdAt', direction: 'desc' },
        });
        if (result.success) {
          fetchedDeals = result.data.data;
          setHasMore(result.data.hasMore);
          lastDocRef.current = result.data.lastDoc;
        } else {
          throw new Error(result.error.message);
        }
      }

      // Apply client-side filters for search and value range
      let filteredDeals = fetchedDeals;

      // Search filter (title, client name, company name)
      if (filters?.search) {
        const searchLower = filters.search.toLowerCase();
        filteredDeals = filteredDeals.filter(
          (deal) =>
            deal.title.toLowerCase().includes(searchLower) ||
            deal.clientName?.toLowerCase().includes(searchLower) ||
            deal.companyName?.toLowerCase().includes(searchLower)
        );
      }

      // Value range filter
      if (filters?.valueRange) {
        filteredDeals = filteredDeals.filter(
          (deal) =>
            deal.valueCents >= filters.valueRange!.min &&
            deal.valueCents <= filters.valueRange!.max
        );
      }

      // Date range filter
      if (filters?.dateRange) {
        filteredDeals = filteredDeals.filter((deal) => {
          const dealDate = deal.createdAt;
          return dealDate >= filters.dateRange!.start && dealDate <= filters.dateRange!.end;
        });
      }

      // Filter by assigned rep UID (unified funnel - inherited from contact)
      if (filters?.assignedRepUid) {
        filteredDeals = filteredDeals.filter(
          (deal) => deal.assignedRepUid === filters.assignedRepUid
        );
      }

      // Append or replace deals based on loading mode
      if (loadingMore) {
        setDeals((prev) => [...prev, ...filteredDeals]);
      } else {
        setDeals(filteredDeals);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch deals'));
      if (!loadingMore) setDeals([]);
    } finally {
      if (loadingMore) {
        setIsLoadingMore(false);
      } else {
        setIsLoading(false);
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessId, crmUser, getContext, filterKey, refreshKey]);

  // Initial fetch and re-fetch on filter changes
  useEffect(() => {
    fetchDeals();
  }, [fetchDeals]);

  // Load more (cursor-based pagination)
  const loadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      fetchDeals(true);
    }
  }, [fetchDeals, isLoadingMore, hasMore]);

  // Manual refresh - triggers re-fetch by incrementing refreshKey
  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  // Calculate totals
  const { totalValue, totalCount } = useMemo(() => {
    return {
      totalValue: deals.reduce((sum, deal) => sum + deal.valueCents, 0),
      totalCount: deals.length,
    };
  }, [deals]);

  return {
    deals,
    isLoading,
    error,
    hasMore,
    loadMore,
    totalValue,
    totalCount,
    refresh,
    isLoadingMore,
    getAccessSummary,
  };
}

export default useDeals;
