/**
 * useDashboardKPIs Hook
 * Calculates KPI metrics for the dashboard
 *
 * Agent CRM-18 Implementation
 * Dependencies: useDeals, useLeads, usePipelineWithStages hooks
 */

import { useMemo } from 'react';
import type { Deal, Lead, Stage } from '../types/models';

// ============================================
// Types
// ============================================

export interface DashboardKPIs {
  /** Total value of all open deals in cents */
  totalPipelineValue: number;
  /** Number of deals won this month */
  dealsWonThisMonth: number;
  /** Total value of deals won this month in cents */
  dealsWonValue: number;
  /** Conversion rate (deals won / total deals) as percentage */
  conversionRate: number;
  /** Average deal size in cents */
  averageDealSize: number;
  /** Deals grouped by stage */
  dealsByStage: { stageId: string; stageName: string; count: number; value: number }[];
  /** Number of leads created this month */
  leadsThisMonth: number;
  /** Number of leads converted this month */
  leadsConverted: number;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Check if a date is within the current month
 */
function isThisMonth(date: Date): boolean {
  const now = new Date();
  return (
    date.getMonth() === now.getMonth() &&
    date.getFullYear() === now.getFullYear()
  );
}

/**
 * Calculate KPIs from deals data
 */
function calculateDealKPIs(deals: Deal[], stages: Stage[]) {
  // Filter open deals
  const openDeals = deals.filter((deal) => deal.status === 'open');

  // Total pipeline value (open deals only)
  const totalPipelineValue = openDeals.reduce(
    (sum, deal) => sum + deal.valueCents,
    0
  );

  // Deals won this month
  const wonDealsThisMonth = deals.filter(
    (deal) =>
      deal.status === 'won' &&
      deal.closedAt &&
      isThisMonth(deal.closedAt)
  );
  const dealsWonThisMonth = wonDealsThisMonth.length;
  const dealsWonValue = wonDealsThisMonth.reduce(
    (sum, deal) => sum + deal.valueCents,
    0
  );

  // Conversion rate (won deals / all closed deals)
  const closedDeals = deals.filter(
    (deal) => deal.status === 'won' || deal.status === 'lost'
  );
  const wonDeals = deals.filter((deal) => deal.status === 'won');
  const conversionRate =
    closedDeals.length > 0
      ? (wonDeals.length / closedDeals.length) * 100
      : 0;

  // Average deal size (all deals)
  const averageDealSize =
    deals.length > 0
      ? deals.reduce((sum, deal) => sum + deal.valueCents, 0) / deals.length
      : 0;

  // Group deals by stage
  const stageMap = new Map<string, { stageName: string; count: number; value: number }>();

  // Initialize with all stages
  stages.forEach((stage) => {
    stageMap.set(stage.id, {
      stageName: stage.name,
      count: 0,
      value: 0,
    });
  });

  // Count open deals per stage
  openDeals.forEach((deal) => {
    const existing = stageMap.get(deal.stageId);
    if (existing) {
      existing.count += 1;
      existing.value += deal.valueCents;
    } else {
      // Handle case where stage might not be in active stages list
      stageMap.set(deal.stageId, {
        stageName: 'Unknown Stage',
        count: 1,
        value: deal.valueCents,
      });
    }
  });

  const dealsByStage = Array.from(stageMap.entries()).map(([stageId, data]) => ({
    stageId,
    stageName: data.stageName,
    count: data.count,
    value: data.value,
  }));

  return {
    totalPipelineValue,
    dealsWonThisMonth,
    dealsWonValue,
    conversionRate,
    averageDealSize,
    dealsByStage,
  };
}

/**
 * Calculate KPIs from leads data
 */
function calculateLeadKPIs(leads: Lead[]) {
  // Leads created this month
  const leadsThisMonth = leads.filter((lead) => isThisMonth(lead.createdAt)).length;

  // Leads converted this month
  const leadsConverted = leads.filter(
    (lead) =>
      lead.status === 'converted' &&
      lead.convertedAt &&
      isThisMonth(lead.convertedAt)
  ).length;

  return {
    leadsThisMonth,
    leadsConverted,
  };
}

// ============================================
// Hook Implementation
// ============================================

export interface UseDashboardKPIsOptions {
  /** List of all deals */
  deals: Deal[];
  /** List of all leads */
  leads: Lead[];
  /** List of pipeline stages */
  stages: Stage[];
}

/**
 * Hook for calculating dashboard KPIs
 *
 * @param options - Deals, leads, and stages data
 * @returns Calculated KPI metrics
 *
 * @example
 * ```tsx
 * const { deals } = useDeals();
 * const { leads } = useLeads();
 * const { stages } = usePipelineWithStages();
 *
 * const kpis = useDashboardKPIs({ deals, leads, stages });
 *
 * console.log(kpis.totalPipelineValue); // Total pipeline value in cents
 * console.log(kpis.conversionRate); // Conversion rate percentage
 * ```
 */
export function useDashboardKPIs(options: UseDashboardKPIsOptions): DashboardKPIs {
  const { deals, leads, stages } = options;

  const kpis = useMemo(() => {
    const dealKPIs = calculateDealKPIs(deals, stages);
    const leadKPIs = calculateLeadKPIs(leads);

    return {
      ...dealKPIs,
      ...leadKPIs,
    };
  }, [deals, leads, stages]);

  return kpis;
}

export default useDashboardKPIs;
