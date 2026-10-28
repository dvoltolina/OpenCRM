/**
 * useContact Hook
 * Fetches and manages a single contact with related data
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (contact repository)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { getDealRepository } from '../data/repositories/deal-repository';
import { createSecurityContext } from './usePipeline';
import type { Client, Company, Deal, SalesActivity } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseContactResult {
  /** The contact data, null if loading or not found */
  contact: Client | null;
  /** The contact's company, null if not linked */
  company: Company | null;
  /** Deals associated with this contact */
  deals: Deal[];
  /** Activities related to this contact */
  activities: SalesActivity[];
  /** True while initial data is loading */
  isLoading: boolean;
  /** Error object if fetch failed */
  error: Error | null;
  /** Manually refresh the contact data */
  refresh: () => void;
  /** Total value of all deals */
  totalDealValue: number;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for fetching and managing a single contact with relationships
 *
 * @param contactId - ID of the contact to fetch
 * @returns Contact data, related entities, and refresh function
 *
 * @example
 * ```tsx
 * const { contact, company, deals, activities, isLoading } = useContact('contact-123');
 *
 * if (isLoading) return <Spinner />;
 * if (!contact) return <NotFound />;
 *
 * return <ContactDetail contact={contact} company={company} deals={deals} />;
 * ```
 */
export function useContact(contactId: string | undefined): UseContactResult {
  const { crmUser, businessId } = useAuth();
  const [contact, setContact] = useState<Client | null>(null);
  const [company, setCompany] = useState<Company | null>(null);
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

  // Fetch contact and related data
  const fetchContact = useCallback(async () => {
    if (!contactId || !businessId || !crmUser) {
      setContact(null);
      setCompany(null);
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
      const contactRepo = getContactRepository();

      // Fetch contact
      const contactResult = await contactRepo.getById(context, contactId);

      if (!contactResult.success) {
        setError(new Error(contactResult.error.message));
        setContact(null);
        setCompany(null);
        setDeals([]);
        setActivities([]);
        setTotalDealValue(0);
        setIsLoading(false);
        return;
      }

      setContact(contactResult.data);

      // Fetch related company if linked
      if (contactResult.data.companyId) {
        const companyRepo = getCompanyRepository();
        const companyResult = await companyRepo.getById(context, contactResult.data.companyId);
        if (companyResult.success) {
          setCompany(companyResult.data);
        } else {
          setCompany(null);
        }
      } else {
        setCompany(null);
      }

      // Fetch related deals
      const dealRepo = getDealRepository();
      const dealsResult = await dealRepo.getByClient(context, contactId);
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
      setError(err instanceof Error ? err : new Error('Failed to fetch contact'));
      setContact(null);
      setCompany(null);
      setDeals([]);
      setActivities([]);
      setTotalDealValue(0);
    } finally {
      setIsLoading(false);
    }
  }, [contactId, businessId, crmUser, getContext]);

  // Initial fetch
  useEffect(() => {
    fetchContact();
  }, [fetchContact]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchContact();
  }, [fetchContact]);

  return {
    contact,
    company,
    deals,
    activities,
    isLoading,
    error,
    refresh,
    totalDealValue,
  };
}

export default useContact;
