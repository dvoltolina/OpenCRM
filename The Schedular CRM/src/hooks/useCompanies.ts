/**
 * useCompanies Hook
 * Company list with filtering, search, and pagination support
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (company repository)
 */

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { createSecurityContext } from './usePipeline';
import type { Company, CompanySize } from '../types/models';
import { getShareableAccessSummary, type ShareableAccessSummary } from '../lib/security-context';

// ============================================
// Types
// ============================================

export interface CompanyFilters {
  /** Filter by industry */
  industry?: string;
  /** Filter by company size */
  size?: CompanySize;
  /** Search by name, website, or industry */
  search?: string;
  /** Filter by tags */
  tags?: string[];
}

export interface UseCompaniesResult {
  /** List of companies matching filters */
  companies: Company[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether there are more results to load */
  hasMore: boolean;
  /** Load more results (for infinite scroll) */
  loadMore: () => void;
  /** Manually refresh the company list */
  refresh: () => void;
  /** Total count of companies */
  totalCount: number;
  /** Whether currently loading more results */
  isLoadingMore: boolean;
  /** List of unique industries for filtering */
  industries: string[];
  /** Access metadata helper for UI guards */
  getAccessSummary: (company: Company | null | undefined) => ShareableAccessSummary | null;
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
 * Hook for fetching and filtering companies
 *
 * @param filters - Optional filters to apply
 * @param pageSize - Number of results per page (default: 25)
 * @returns Company list, loading state, and pagination controls
 *
 * @example
 * ```tsx
 * const { companies, isLoading, industries, hasMore, loadMore } = useCompanies({
 *   industry: 'Technology',
 *   size: 'enterprise',
 * });
 * ```
 */
export function useCompanies(
  filters?: CompanyFilters,
  pageSize: number = DEFAULT_PAGE_SIZE
): UseCompaniesResult {
  const { crmUser, businessId } = useAuth();
  const [companies, setCompanies] = useState<Company[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [industries, setIndustries] = useState<string[]>([]);

  // Track last document for pagination
  const lastDocRef = useRef<unknown>(null);

  // Request cancellation for preventing stale results
  const abortControllerRef = useRef<AbortController | null>(null);

  // Debounce search
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const [debouncedSearch, setDebouncedSearch] = useState(filters?.search);
  const companyTagsKey = JSON.stringify(filters?.tags ?? []);
  const companyFilters = useMemo(
    () => ({
      industry: filters?.industry,
      size: filters?.size,
      tags: companyTagsKey === '[]' ? undefined : (JSON.parse(companyTagsKey) as string[]),
    }),
    [companyTagsKey, filters?.industry, filters?.size]
  );

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
      crmUser.role
    );
  }, [businessId, crmUser]);

  const getAccessSummary = useCallback(
    (company: Company | null | undefined): ShareableAccessSummary | null => {
      if (!company || !businessId || !crmUser) return null;
      try {
        const context = getContext();
        return getShareableAccessSummary(context, company);
      } catch {
        return null;
      }
    },
    [businessId, crmUser, getContext]
  );

  // Fetch unique industries
  const fetchIndustries = useCallback(async () => {
    if (!businessId || !crmUser) return;

    try {
      const context = getContext();
      const repo = getCompanyRepository();
      const result = await repo.getUniqueIndustries(context);

      if (result.success) {
        setIndustries(result.data);
      }
    } catch {
      // Silently fail - industries are optional
    }
  }, [businessId, crmUser, getContext]);

  // Fetch companies
  const fetchCompanies = useCallback(
    async (loadingMore: boolean = false) => {
      if (!businessId || !crmUser) {
        setCompanies([]);
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
        const repo = getCompanyRepository();

        // If search is provided, use search method
        if (debouncedSearch) {
          const result = await repo.search(context, debouncedSearch);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newCompanies = result.data;
            if (loadingMore) {
              setCompanies((prev) => [...prev, ...newCompanies]);
            } else {
              setCompanies(newCompanies);
            }
            setHasMore(false); // Simple search doesn't support pagination
            setTotalCount(newCompanies.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setCompanies([]);
          }
        } else if (companyFilters.industry) {
          // Filter by industry
          const result = await repo.getByIndustry(context, companyFilters.industry);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newCompanies = result.data;
            if (loadingMore) {
              setCompanies((prev) => [...prev, ...newCompanies]);
            } else {
              setCompanies(newCompanies);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newCompanies.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setCompanies([]);
          }
        } else if (companyFilters.size) {
          // Filter by size
          const result = await repo.getBySize(context, companyFilters.size);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newCompanies = result.data;
            if (loadingMore) {
              setCompanies((prev) => [...prev, ...newCompanies]);
            } else {
              setCompanies(newCompanies);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newCompanies.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setCompanies([]);
          }
        } else {
          // Get all companies with optional filters
          const filterOptions = {
            industry: companyFilters.industry,
            size: companyFilters.size,
            tags: companyFilters.tags,
          };

          const result = await repo.getFiltered(context, filterOptions);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newCompanies = result.data;
            if (loadingMore) {
              setCompanies((prev) => [...prev, ...newCompanies]);
            } else {
              setCompanies(newCompanies);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newCompanies.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setCompanies([]);
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch companies'));
        if (!loadingMore) setCompanies([]);
      } finally {
        if (loadingMore) {
          setIsLoadingMore(false);
        } else {
          setIsLoading(false);
        }
      }
    },
    [businessId, companyFilters, crmUser, debouncedSearch, getContext]
  );

  // Initial fetch and refetch on filter changes
  useEffect(() => {
    fetchCompanies(false);
    fetchIndustries();
  }, [debouncedSearch, fetchCompanies, fetchIndustries, pageSize]);

  // Load more
  const loadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      fetchCompanies(true);
    }
  }, [fetchCompanies, isLoadingMore, hasMore]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchCompanies(false);
    fetchIndustries();
  }, [fetchCompanies, fetchIndustries]);

  return {
    companies,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
    totalCount,
    isLoadingMore,
    industries,
    getAccessSummary,
  };
}

export default useCompanies;
