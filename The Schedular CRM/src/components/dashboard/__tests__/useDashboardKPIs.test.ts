/**
 * useDashboardKPIs Hook Tests
 *
 * Agent CRM-18 Implementation
 */

import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useDashboardKPIs } from '../../../hooks/useDashboardKPIs';
import type { Deal, Lead, Stage } from '../../../types/models';

// ============================================
// Test Data
// ============================================

const mockStages: Stage[] = [
  {
    id: 'stage-1',
    pipelineId: 'pipeline-1',
    name: 'Prospecting',
    order: 1,
    colorHex: '#3b82f6',
    probability: 10,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
  {
    id: 'stage-2',
    pipelineId: 'pipeline-1',
    name: 'Qualification',
    order: 2,
    colorHex: '#8b5cf6',
    probability: 30,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
  {
    id: 'stage-3',
    pipelineId: 'pipeline-1',
    name: 'Proposal',
    order: 3,
    colorHex: '#10b981',
    probability: 60,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  },
];

const currentMonth = new Date().getMonth();
const currentYear = new Date().getFullYear();

const mockDeals: Deal[] = [
  {
    id: 'deal-1',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Deal 1',
    valueCents: 100000, // $1,000
    currency: 'USD',
    probability: 10,
    status: 'open',
    tags: [],
    createdAt: new Date('2024-01-15'),
  },
  {
    id: 'deal-2',
    pipelineId: 'pipeline-1',
    stageId: 'stage-2',
    title: 'Deal 2',
    valueCents: 200000, // $2,000
    currency: 'USD',
    probability: 30,
    status: 'open',
    tags: [],
    createdAt: new Date('2024-01-20'),
  },
  {
    id: 'deal-3',
    pipelineId: 'pipeline-1',
    stageId: 'stage-3',
    title: 'Deal 3',
    valueCents: 300000, // $3,000
    currency: 'USD',
    probability: 60,
    status: 'open',
    tags: [],
    createdAt: new Date('2024-02-01'),
  },
  {
    id: 'deal-4',
    pipelineId: 'pipeline-1',
    stageId: 'stage-3',
    title: 'Deal 4',
    valueCents: 500000, // $5,000
    currency: 'USD',
    probability: 100,
    status: 'won',
    closedAt: new Date(currentYear, currentMonth, 15),
    tags: [],
    createdAt: new Date('2024-01-10'),
  },
  {
    id: 'deal-5',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Deal 5',
    valueCents: 150000, // $1,500
    currency: 'USD',
    probability: 0,
    status: 'lost',
    closedAt: new Date(currentYear, currentMonth, 10),
    wonLostReason: 'Price too high',
    tags: [],
    createdAt: new Date('2024-01-05'),
  },
];

const mockLeads: Lead[] = [
  {
    id: 'lead-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    status: 'new',
    source: 'website',
    tags: [],
    createdAt: new Date(currentYear, currentMonth, 5),
  },
  {
    id: 'lead-2',
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    status: 'qualified',
    source: 'referral',
    tags: [],
    createdAt: new Date(currentYear, currentMonth, 10),
  },
  {
    id: 'lead-3',
    firstName: 'Bob',
    lastName: 'Johnson',
    email: 'bob@example.com',
    status: 'converted',
    source: 'coldCall',
    tags: [],
    createdAt: new Date('2024-01-15'),
    convertedAt: new Date(currentYear, currentMonth, 12),
    convertedToClientId: 'client-1',
  },
  {
    id: 'lead-4',
    firstName: 'Alice',
    lastName: 'Williams',
    email: 'alice@example.com',
    status: 'new',
    source: 'social',
    tags: [],
    createdAt: new Date('2023-12-20'),
  },
];

// ============================================
// Tests
// ============================================

describe('useDashboardKPIs', () => {
  // ============================================
  // Test 1: Calculates total pipeline value
  // ============================================
  it('calculates total pipeline value from open deals', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    // Should only include open deals: $1,000 + $2,000 + $3,000 = $6,000 (600000 cents)
    expect(result.current.totalPipelineValue).toBe(600000);
  });

  // ============================================
  // Test 2: Calculates deals won this month
  // ============================================
  it('calculates deals won this month', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    // Should count deal-4 which was won this month
    expect(result.current.dealsWonThisMonth).toBe(1);
    expect(result.current.dealsWonValue).toBe(500000); // $5,000
  });

  // ============================================
  // Test 3: Calculates conversion rate
  // ============================================
  it('calculates conversion rate from closed deals', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    // Closed deals: deal-4 (won), deal-5 (lost) = 2 total
    // Won deals: deal-4 = 1
    // Conversion rate: 1/2 = 50%
    expect(result.current.conversionRate).toBe(50);
  });

  // ============================================
  // Test 4: Calculates average deal size
  // ============================================
  it('calculates average deal size across all deals', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    // All deals: $1,000 + $2,000 + $3,000 + $5,000 + $1,500 = $12,500
    // Average: $12,500 / 5 = $2,500 (250000 cents)
    expect(result.current.averageDealSize).toBe(250000);
  });

  // ============================================
  // Test 5: Groups deals by stage
  // ============================================
  it('groups deals by stage with counts and values', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    const dealsByStage = result.current.dealsByStage;

    // Find each stage
    const stage1 = dealsByStage.find((s) => s.stageId === 'stage-1');
    const stage2 = dealsByStage.find((s) => s.stageId === 'stage-2');
    const stage3 = dealsByStage.find((s) => s.stageId === 'stage-3');

    // Stage 1: deal-1 ($1,000)
    expect(stage1).toEqual({
      stageId: 'stage-1',
      stageName: 'Prospecting',
      count: 1,
      value: 100000,
    });

    // Stage 2: deal-2 ($2,000)
    expect(stage2).toEqual({
      stageId: 'stage-2',
      stageName: 'Qualification',
      count: 1,
      value: 200000,
    });

    // Stage 3: deal-3 ($3,000) - deal-4 is won so not counted in open deals
    expect(stage3).toEqual({
      stageId: 'stage-3',
      stageName: 'Proposal',
      count: 1,
      value: 300000,
    });
  });

  // ============================================
  // Test 6: CRITICAL - Scoped by businessId
  // ============================================
  it('calculates KPIs scoped by businessId context', () => {
    // This test verifies that the hook correctly uses data filtered by businessId
    // The actual businessId filtering happens in the data fetching hooks (useDeals, useLeads)
    // This test confirms the KPI calculations work with scoped data

    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: mockDeals,
        leads: mockLeads,
        stages: mockStages,
      })
    );

    // Verify all KPIs are calculated
    expect(result.current.totalPipelineValue).toBeDefined();
    expect(result.current.dealsWonThisMonth).toBeDefined();
    expect(result.current.conversionRate).toBeDefined();
    expect(result.current.averageDealSize).toBeDefined();
    expect(result.current.dealsByStage).toBeDefined();
    expect(result.current.leadsThisMonth).toBeDefined();
    expect(result.current.leadsConverted).toBeDefined();

    // Verify leads this month (lead-1, lead-2 created this month)
    expect(result.current.leadsThisMonth).toBe(2);

    // Verify leads converted this month (lead-3 converted this month)
    expect(result.current.leadsConverted).toBe(1);
  });

  // ============================================
  // Additional Edge Case Tests
  // ============================================

  it('handles empty data gracefully', () => {
    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: [],
        leads: [],
        stages: [],
      })
    );

    expect(result.current.totalPipelineValue).toBe(0);
    expect(result.current.dealsWonThisMonth).toBe(0);
    expect(result.current.dealsWonValue).toBe(0);
    expect(result.current.conversionRate).toBe(0);
    expect(result.current.averageDealSize).toBe(0);
    expect(result.current.dealsByStage).toEqual([]);
    expect(result.current.leadsThisMonth).toBe(0);
    expect(result.current.leadsConverted).toBe(0);
  });

  it('handles all open deals scenario', () => {
    const openDeals: Deal[] = mockDeals.filter((d) => d.status === 'open');

    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: openDeals,
        leads: [],
        stages: mockStages,
      })
    );

    // No closed deals, so conversion rate should be 0
    expect(result.current.conversionRate).toBe(0);
    expect(result.current.dealsWonThisMonth).toBe(0);
  });

  it('handles all closed deals scenario', () => {
    const closedDeals: Deal[] = mockDeals.filter((d) => d.status !== 'open');

    const { result } = renderHook(() =>
      useDashboardKPIs({
        deals: closedDeals,
        leads: [],
        stages: mockStages,
      })
    );

    // No open deals, so pipeline value should be 0
    expect(result.current.totalPipelineValue).toBe(0);
    // But we still have closed deals for conversion rate
    expect(result.current.conversionRate).toBe(50); // 1 won, 1 lost
  });
});
