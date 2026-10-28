/**
 * useGlobalSearch Hook
 * Global search across all CRM entities
 *
 * Agent CRM-26 Implementation
 * Dependencies: CRM-08 to CRM-10 hooks (entity hooks)
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getLeadRepository } from '../data/repositories/lead-repository';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { createSecurityContext } from './usePipeline';
import type { Lead, Deal, Client, Company } from '../types/models';

// ============================================
// Types
// ============================================

export interface SearchResult {
  id: string;
  type: 'lead' | 'deal' | 'contact' | 'company';
  title: string;
  subtitle?: string;
  metadata?: string;
}

export interface GroupedSearchResults {
  leads: SearchResult[];
  deals: SearchResult[];
  contacts: SearchResult[];
  companies: SearchResult[];
}

export interface UseGlobalSearchResult {
  /** Search query */
  query: string;
  /** Update search query */
  setQuery: (query: string) => void;
  /** Grouped search results */
  results: GroupedSearchResults;
  /** True while searching */
  isSearching: boolean;
  /** Total number of results */
  totalResults: number;
  /** Whether results are shown */
  hasResults: boolean;
  /** Clear search */
  clear: () => void;
}

// ============================================
// Constants
// ============================================

const DEBOUNCE_MS = 300;
const MAX_RESULTS_PER_TYPE = 5;

// ============================================
// Helper Functions
// ============================================

function formatLead(lead: Lead): SearchResult {
  return {
    id: lead.id,
    type: 'lead',
    title: `${lead.firstName} ${lead.lastName}`,
    subtitle: lead.companyName || lead.email,
    metadata: lead.status,
  };
}

function formatDeal(deal: Deal): SearchResult {
  return {
    id: deal.id,
    type: 'deal',
    title: deal.title,
    subtitle: deal.clientName || deal.companyName,
    metadata: `$${(deal.valueCents / 100).toLocaleString()}`,
  };
}

function formatContact(contact: Client): SearchResult {
  return {
    id: contact.id,
    type: 'contact',
    title: `${contact.firstName} ${contact.lastName}`,
    subtitle: contact.companyName || contact.email,
    metadata: contact.lifecycle,
  };
}

function formatCompany(company: Company): SearchResult {
  return {
    id: company.id,
    type: 'company',
    title: company.name,
    subtitle: company.industry,
    metadata: company.size,
  };
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for global search across all CRM entities
 *
 * @returns Search state and controls
 *
 * @example
 * ```tsx
 * const { query, setQuery, results, isSearching, hasResults, clear } = useGlobalSearch();
 *
 * return (
 *   <GlobalSearch
 *     query={query}
 *     onQueryChange={setQuery}
 *     results={results}
 *     isSearching={isSearching}
 *     onClear={clear}
 *   />
 * );
 * ```
 */
export function useGlobalSearch(): UseGlobalSearchResult {
  const { crmUser, businessId } = useAuth();
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [results, setResults] = useState<GroupedSearchResults>({
    leads: [],
    deals: [],
    contacts: [],
    companies: [],
  });

  // Refs
  const debounceTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  // Debounce search query
  useEffect(() => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }

    debounceTimeoutRef.current = setTimeout(() => {
      setDebouncedQuery(query);
    }, DEBOUNCE_MS);

    return () => {
      if (debounceTimeoutRef.current) {
        clearTimeout(debounceTimeoutRef.current);
      }
    };
  }, [query]);

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

  // Perform search
  const performSearch = useCallback(
    async (searchQuery: string) => {
      if (!searchQuery.trim() || !businessId || !crmUser) {
        setResults({
          leads: [],
          deals: [],
          contacts: [],
          companies: [],
        });
        return;
      }

      // Cancel previous search request to prevent stale results
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      abortControllerRef.current = new AbortController();
      const currentAbortController = abortControllerRef.current;

      setIsSearching(true);

      try {
        // Check if request was cancelled
        if (currentAbortController.signal.aborted) {
          return;
        }
        const context = getContext();

        // Search all entity types in parallel
        const [leadsResult, dealsResult, contactsResult, companiesResult] = await Promise.all([
          getLeadRepository().search(context, searchQuery),
          getDealRepository()
            .getAll(context, { limit: 100 })
            .then((result) => {
              if (!result.success) return { success: false as const, error: result.error };
              // Client-side search for deals
              const searchLower = searchQuery.toLowerCase();
              const filtered = result.data.data.filter(
                (deal) =>
                  deal.title.toLowerCase().includes(searchLower) ||
                  deal.clientName?.toLowerCase().includes(searchLower) ||
                  deal.companyName?.toLowerCase().includes(searchLower)
              );
              return {
                success: true as const,
                data: filtered.slice(0, MAX_RESULTS_PER_TYPE),
              };
            }),
          getContactRepository().search(context, searchQuery),
          getCompanyRepository().search(context, searchQuery),
        ]);

        // Check if request was cancelled after completion
        if (currentAbortController.signal.aborted) {
          return;
        }

        // Format results
        const newResults: GroupedSearchResults = {
          leads: leadsResult.success ? leadsResult.data.data.map(formatLead) : [],
          deals: dealsResult.success ? dealsResult.data.map(formatDeal) : [],
          contacts: contactsResult.success ? contactsResult.data.map(formatContact) : [],
          companies: companiesResult.success ? companiesResult.data.map(formatCompany) : [],
        };

        setResults(newResults);
      } catch (error) {
        console.error('Search error:', error);
        setResults({
          leads: [],
          deals: [],
          contacts: [],
          companies: [],
        });
      } finally {
        setIsSearching(false);
      }
    },
    [businessId, crmUser, getContext]
  );

  // Execute search when debounced query changes
  useEffect(() => {
    performSearch(debouncedQuery);
  }, [debouncedQuery, performSearch]);

  // Clear search
  const clear = useCallback(() => {
    setQuery('');
    setDebouncedQuery('');
    setResults({
      leads: [],
      deals: [],
      contacts: [],
      companies: [],
    });
  }, []);

  // Calculate total results
  const totalResults =
    results.leads.length +
    results.deals.length +
    results.contacts.length +
    results.companies.length;

  const hasResults = totalResults > 0 && debouncedQuery.trim().length > 0;

  return {
    query,
    setQuery,
    results,
    isSearching,
    totalResults,
    hasResults,
    clear,
  };
}

export default useGlobalSearch;
