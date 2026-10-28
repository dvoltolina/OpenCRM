/**
 * useContacts Hook
 * Contact list with filtering, search, and pagination support
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (contact repository)
 */

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getContactRepository } from '../data/repositories/contact-repository';
import { createSecurityContext } from './usePipeline';
import type { Client, ClientLifecycle, LeadSource, ContactLeadStatus } from '../types/models';

// ============================================
// Types
// ============================================

export interface ContactFilters {
  /** Filter by company ID */
  companyId?: string;
  /** Filter by lifecycle stage */
  lifecycle?: ClientLifecycle;
  /** Filter by lead source */
  source?: LeadSource;
  /** Search by name, email, or phone */
  search?: string;
  /** Filter by tags */
  tags?: string[];
  /** Filter stale contacts (days since last contact) */
  staleDays?: number;
  /** Filter by specific lead status (unified funnel) */
  leadStatus?: ContactLeadStatus;
  /** Filter to only contacts with any lead status set (for Leads view) */
  hasLeadStatus?: boolean;
  /** Filter by assigned rep UID */
  assignedRepUid?: string;
}

export interface UseContactsResult {
  /** List of contacts matching filters */
  contacts: Client[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if operation failed */
  error: Error | null;
  /** Whether there are more results to load */
  hasMore: boolean;
  /** Load more results (for infinite scroll) */
  loadMore: () => void;
  /** Manually refresh the contact list */
  refresh: () => void;
  /** Total count of contacts */
  totalCount: number;
  /** Whether currently loading more results */
  isLoadingMore: boolean;
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
 * Hook for fetching and filtering contacts
 *
 * @param filters - Optional filters to apply
 * @param pageSize - Number of results per page (default: 25)
 * @returns Contact list, loading state, and pagination controls
 *
 * @example
 * ```tsx
 * const { contacts, isLoading, hasMore, loadMore } = useContacts({
 *   companyId: 'company-123',
 *   lifecycle: 'customer',
 * });
 * ```
 */
export function useContacts(
  filters?: ContactFilters,
  pageSize: number = DEFAULT_PAGE_SIZE
): UseContactsResult {
  const { crmUser, businessId } = useAuth();
  const [contacts, setContacts] = useState<Client[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);

  // Track last document for pagination
  const lastDocRef = useRef<unknown>(null);

  // Request cancellation for preventing stale results
  const abortControllerRef = useRef<AbortController | null>(null);

  // Debounce search
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const [debouncedSearch, setDebouncedSearch] = useState(filters?.search);
  const contactTagsKey = JSON.stringify(filters?.tags ?? []);
  const contactFilters = useMemo(
    () => ({
      companyId: filters?.companyId,
      lifecycle: filters?.lifecycle,
      source: filters?.source,
      tags: contactTagsKey === '[]' ? undefined : (JSON.parse(contactTagsKey) as string[]),
      staleDays: filters?.staleDays,
      leadStatus: filters?.leadStatus,
      hasLeadStatus: filters?.hasLeadStatus,
      assignedRepUid: filters?.assignedRepUid,
    }),
    [
      contactTagsKey,
      filters?.assignedRepUid,
      filters?.companyId,
      filters?.hasLeadStatus,
      filters?.leadStatus,
      filters?.lifecycle,
      filters?.source,
      filters?.staleDays,
    ]
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

  // Fetch contacts
  const fetchContacts = useCallback(
    async (loadingMore: boolean = false) => {
      if (!businessId || !crmUser) {
        setContacts([]);
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
        const repo = getContactRepository();

        // If search is provided, use search method
        if (debouncedSearch) {
          const result = await repo.search(context, debouncedSearch);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newContacts = result.data;
            if (loadingMore) {
              setContacts((prev) => [...prev, ...newContacts]);
            } else {
              setContacts(newContacts);
            }
            setHasMore(false); // Simple search doesn't support pagination
            setTotalCount(newContacts.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setContacts([]);
          }
        } else if (contactFilters.companyId) {
          // Filter by company
          const result = await repo.getByCompany(context, contactFilters.companyId);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newContacts = result.data;
            if (loadingMore) {
              setContacts((prev) => [...prev, ...newContacts]);
            } else {
              setContacts(newContacts);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newContacts.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setContacts([]);
          }
        } else if (contactFilters.lifecycle) {
          // Filter by lifecycle
          const result = await repo.getByLifecycle(context, contactFilters.lifecycle);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newContacts = result.data;
            if (loadingMore) {
              setContacts((prev) => [...prev, ...newContacts]);
            } else {
              setContacts(newContacts);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newContacts.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setContacts([]);
          }
        } else if (contactFilters.staleDays) {
          // Get stale contacts
          const result = await repo.getStaleContacts(context, contactFilters.staleDays);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newContacts = result.data;
            if (loadingMore) {
              setContacts((prev) => [...prev, ...newContacts]);
            } else {
              setContacts(newContacts);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newContacts.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setContacts([]);
          }
        } else {
          // Get all contacts with optional filters
          const filterOptions = {
            lifecycle: contactFilters.lifecycle,
            leadSource: contactFilters.source,
            tags: contactFilters.tags,
            // Unified funnel filters
            leadStatus: contactFilters.leadStatus || undefined,
            hasLeadStatus: contactFilters.hasLeadStatus,
            assignedRepUid: contactFilters.assignedRepUid,
          };

          const result = await repo.getFiltered(context, filterOptions);

          // Check if request was cancelled after completion
          if (currentAbortController.signal.aborted) {
            return;
          }

          if (result.success) {
            const newContacts = result.data;
            if (loadingMore) {
              setContacts((prev) => [...prev, ...newContacts]);
            } else {
              setContacts(newContacts);
            }
            setHasMore(false); // Simple query doesn't support pagination
            setTotalCount(newContacts.length);
          } else {
            setError(new Error(result.error.message));
            if (!loadingMore) setContacts([]);
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to fetch contacts'));
        if (!loadingMore) setContacts([]);
      } finally {
        if (loadingMore) {
          setIsLoadingMore(false);
        } else {
          setIsLoading(false);
        }
      }
    },
    [businessId, contactFilters, crmUser, debouncedSearch, getContext]
  );

  // Initial fetch and refetch on filter changes
  useEffect(() => {
    fetchContacts(false);
  }, [debouncedSearch, fetchContacts, pageSize]);

  // Load more
  const loadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      fetchContacts(true);
    }
  }, [fetchContacts, isLoadingMore, hasMore]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchContacts(false);
  }, [fetchContacts]);

  return {
    contacts,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
    totalCount,
    isLoadingMore,
  };
}

export default useContacts;
