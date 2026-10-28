/**
 * useCompany Hook
 * Fetches and manages a single company with related data
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (company repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getDealRepository } from '../data/repositories/deal-repository';
import { createSecurityContext } from './usePipeline';
import type { Company, Client, Deal, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseCompanyResult {
  /** The company data, null if loading or not found */
  company: Company | null;
  /** Contacts associated with this company */
  contacts: Client[];
  /** Deals associated with this company */
  deals: Deal[];
  /** Activities related to this company */
  activities: SalesActivity[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if fetch failed */
  error: Error | null;
  /** Manually refresh the company data */
  refresh: () => void;
  /** Total value of all deals */
  totalDealValue: number;
  /** Number of contacts */
  contactCount: number;
  /** Number of deals */
  dealCount: number;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and managing a single company with relationships
 *
 * @param companyId - ID of the company to fetch
 * @returns Company data, related entities, and refresh function
 *
 * @example
 * ```tsx
 * const { company, contacts, deals, totalDealValue, isLoading } = useCompany('company-123');
 *
 * if (isLoading) return <Spinner />;
 * if (!company) return <NotFound />;
 *
 * return <CompanyDetail company={company} contacts={contacts} deals={deals} />;
 * ```
 */
export function useCompany(companyId: string | undefined): UseCompanyResult {
  const { crmUser, businessId } = useAuth();
  const [company, setCompany] = useState<Company | null>(null);
  const [contacts, setContacts] = useState<Client[]>([]);
  const [deals, setDeals] = useState<Deal[]>([]);
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [totalDealValue, setTotalDealValue] = useState(0);

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

  // Fetch company and related data
  const fetchCompany = useCallback(async () => {
    if (!companyId || !businessId || !crmUser) {
      setCompany(null);
      setContacts([]);
      setDeals([]);
      setActivities([]);
      setTotalDealValue(0);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const companyRepo = getCompanyRepository();

      // Fetch company
      const companyResult = await companyRepo.getById(context, companyId);

      if (!companyResult.success) {
        setError(new Error(companyResult.error.message));
        setCompany(null);
        setContacts([]);
        setDeals([]);
        setActivities([]);
        setTotalDealValue(0);
        setIsLoading(false);
        return;
      }

      setCompany(companyResult.data);

      // Fetch contacts for this company
      const contactRepo = getContactRepository();
      const contactsResult = await contactRepo.getByCompany(context, companyId);
      if (contactsResult.success) {
        setContacts(contactsResult.data);
      } else {
        setContacts([]);
      }

      // Fetch deals for this company
      const dealRepo = getDealRepository();
      const dealsResult = await dealRepo.getByCompany(context, companyId);
      if (dealsResult.success) {
        setDeals(dealsResult.data);
        // Calculate total deal value
        const total = dealsResult.data.reduce((sum, deal) => sum + (deal.valueCents || 0), 0);
        setTotalDealValue(total);
      } else {
        setDeals([]);
        setTotalDealValue(0);
      }

      // Activities placeholder - will be implemented when activity hooks are ready
      setActivities([]);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch company'));
      setCompany(null);
      setContacts([]);
      setDeals([]);
      setActivities([]);
      setTotalDealValue(0);
    } finally {
      setIsLoading(false);
    }
  }, [companyId, businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchCompany();
  }, [fetchCompany]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchCompany();
  }, [fetchCompany]);

  return {
    company,
    contacts,
    deals,
    activities,
    isLoading,
    error,
    refresh,
    totalDealValue,
    contactCount: contacts.length,
    dealCount: deals.length,
  };
}

export default useCompany;
