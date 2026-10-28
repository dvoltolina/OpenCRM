/**
 * useAdvancedAnalytics Hook Tests
 * Tests for advanced analytics calculations
 *
 * Agent CRM-31 Implementation
 */

import { renderHook } from '@testing-library/react';
import { useAdvancedAnalytics } from '../useAdvancedAnalytics';
import type { Deal, Lead } from '../../types/models';
import type { Appointment } from '../useSchedulerData';
import type { Payment, Dispute } from '../../types/models';

// ============================================
// Test Data Helpers
// ============================================

function createLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    status: 'new',
    source: 'website',
    tags: [],
    createdAt: new Date('2025-01-15'),
    ...overrides,
  };
}

function createDeal(overrides: Partial<Deal> = {}): Deal {
  return {
    id: 'deal-1',
    pipelineId: 'pipeline-1',
    stageId: 'stage-1',
    title: 'Test Deal',
    valueCents: 100000,
    currency: 'USD',
    probability: 50,
    status: 'open',
    tags: [],
    createdAt: new Date('2025-01-15'),
    ...overrides,
  };
}

function createAppointment(overrides: Partial<Appointment> = {}): Appointment {
  return {
    id: 'apt-1',
    clientId: 'client-1',
    providerId: 'staff-1',
    providerName: 'Dr. Smith',
    staffId: 'staff-1', // Added for test compatibility
    staffName: 'Dr. Smith', // Added for test compatibility
    startTime: new Date('2025-01-15T10:00:00'),
    endTime: new Date('2025-01-15T11:00:00'),
    status: 'completed',
    serviceType: 'Consultation',
    ...overrides,
  };
}

function createPayment(overrides: Partial<Payment> = {}): Payment {
  const defaultPayment: Payment = {
    id: 'pay-1',
    amountCents: 50000,
    currency: 'USD',
    status: 'completed',
    method: 'card',
    type: 'full',
    description: 'Test Payment',
    clientId: 'client-123',
    clientName: 'John Doe',
    dealId: 'deal-123',
    dealTitle: 'Test Deal',
    providerId: 'ch_123',
    processedById: 'user-123',
    processedByName: 'Test User',
    processedAt: new Date(),
    createdAt: new Date('2025-01-15'),
    updatedAt: new Date('2025-01-15'),
  };

  return { ...defaultPayment, ...overrides };
}

function createDispute(overrides: Partial<Dispute> = {}): Dispute {
  return {
    id: 'dispute-1',
    paymentId: 'pay-1',
    amountCents: 50000,
    status: 'open',
    reason: 'Fraudulent charge',
    clientId: 'client-1',
    clientName: 'John Doe',
    createdAt: new Date('2025-01-15'),
    ...overrides,
  };
}

// ============================================
// Lead Source ROI Tests
// ============================================

describe('useAdvancedAnalytics - Lead Source ROI', () => {
  it('should calculate ROI correctly for single source', () => {
    const leads: Lead[] = [
      createLead({ id: 'lead-1', source: 'website', status: 'converted', convertedToDealId: 'deal-1' }),
      createLead({ id: 'lead-2', source: 'website' }),
    ];

    const deals: Deal[] = [
      createDeal({ id: 'deal-1', status: 'won', valueCents: 200000 }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads, deals, appointments: [], payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const sourceCosts = new Map([['website', 50000]]);
    const roiData = result.current.getLeadSourceROI(dateRange, sourceCosts);

    expect(roiData).toHaveLength(1);
    expect(roiData[0].source).toBe('website');
    expect(roiData[0].leadCount).toBe(2);
    expect(roiData[0].convertedCount).toBe(1);
    expect(roiData[0].conversionRate).toBe(50);
    expect(roiData[0].revenueCents).toBe(200000);
    expect(roiData[0].costCents).toBe(50000);
    expect(roiData[0].roiPercentage).toBe(300); // (200000 - 50000) / 50000 * 100
    expect(roiData[0].costPerLead).toBe(25000);
    expect(roiData[0].costPerConversion).toBe(50000);
  });

  it('should handle multiple lead sources', () => {
    const leads: Lead[] = [
      createLead({ id: 'lead-1', source: 'website', status: 'converted', convertedToDealId: 'deal-1' }),
      createLead({ id: 'lead-2', source: 'referral', status: 'converted', convertedToDealId: 'deal-2' }),
      createLead({ id: 'lead-3', source: 'website' }),
    ];

    const deals: Deal[] = [
      createDeal({ id: 'deal-1', status: 'won', valueCents: 100000 }),
      createDeal({ id: 'deal-2', status: 'won', valueCents: 150000 }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads, deals, appointments: [], payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const sourceCosts = new Map([
      ['website', 30000],
      ['referral', 10000],
    ]);

    const roiData = result.current.getLeadSourceROI(dateRange, sourceCosts);

    expect(roiData).toHaveLength(2);

    // Should be sorted by ROI descending
    expect(roiData[0].roiPercentage).toBeGreaterThan(roiData[1].roiPercentage);
  });

  it('should handle zero cost correctly', () => {
    const leads: Lead[] = [
      createLead({ id: 'lead-1', source: 'referral', status: 'converted', convertedToDealId: 'deal-1' }),
    ];

    const deals: Deal[] = [
      createDeal({ id: 'deal-1', status: 'won', valueCents: 100000 }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads, deals, appointments: [], payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const sourceCosts = new Map([['referral', 0]]);
    const roiData = result.current.getLeadSourceROI(dateRange, sourceCosts);

    expect(roiData[0].roiPercentage).toBe(0);
  });

  it('should filter by date range', () => {
    const leads: Lead[] = [
      createLead({ id: 'lead-1', source: 'website', createdAt: new Date('2025-01-15') }),
      createLead({ id: 'lead-2', source: 'website', createdAt: new Date('2024-12-15') }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads, deals: [], appointments: [], payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const roiData = result.current.getLeadSourceROI(dateRange, new Map());

    expect(roiData[0].leadCount).toBe(1);
  });
});

// ============================================
// Appointment Completion Tests
// ============================================

describe('useAdvancedAnalytics - Appointment Completion', () => {
  it('should calculate completion rates correctly', () => {
    const appointments: Appointment[] = [
      createAppointment({ id: 'apt-1', status: 'completed', startTime: new Date('2025-01-15T10:00') }),
      createAppointment({ id: 'apt-2', status: 'completed', startTime: new Date('2025-01-15T14:00') }),
      createAppointment({ id: 'apt-3', status: 'missed', startTime: new Date('2025-01-15T16:00') }),
      createAppointment({ id: 'apt-4', status: 'cancelled', startTime: new Date('2025-01-15T18:00') }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const completionData = result.current.getAppointmentCompletion(dateRange, 'daily');

    expect(completionData).toHaveLength(1);
    expect(completionData[0].scheduled).toBe(4);
    expect(completionData[0].completed).toBe(2);
    expect(completionData[0].missed).toBe(1);
    expect(completionData[0].cancelled).toBe(1);
    expect(completionData[0].completionRate).toBe(50);
  });

  it('should filter by staff member', () => {
    const appointments: Appointment[] = [
      createAppointment({ id: 'apt-1', staffId: 'staff-1', status: 'completed' }),
      createAppointment({ id: 'apt-2', staffId: 'staff-2', status: 'completed' }),
      createAppointment({ id: 'apt-3', staffId: 'staff-1', status: 'missed' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const completionData = result.current.getAppointmentCompletion(dateRange, 'daily', 'staff-1');

    expect(completionData[0].scheduled).toBe(2);
    expect(completionData[0].completed).toBe(1);
    expect(completionData[0].missed).toBe(1);
  });

  it('should group by weekly granularity', () => {
    const appointments: Appointment[] = [
      createAppointment({ id: 'apt-1', startTime: new Date('2025-01-06'), status: 'completed' }),
      createAppointment({ id: 'apt-2', startTime: new Date('2025-01-07'), status: 'completed' }),
      createAppointment({ id: 'apt-3', startTime: new Date('2025-01-13'), status: 'completed' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const completionData = result.current.getAppointmentCompletion(dateRange, 'weekly');

    expect(completionData.length).toBeGreaterThan(1);
  });
});

// ============================================
// Staff Utilization Tests
// ============================================

describe('useAdvancedAnalytics - Staff Utilization', () => {
  it('should create heatmap correctly', () => {
    const appointments: Appointment[] = [
      createAppointment({
        id: 'apt-1',
        staffId: 'staff-1',
        staffName: 'Dr. Smith',
        startTime: new Date('2025-01-15T10:00'), // Wednesday 10am
        status: 'completed',
      }),
      createAppointment({
        id: 'apt-2',
        staffId: 'staff-1',
        staffName: 'Dr. Smith',
        startTime: new Date('2025-01-15T10:00'), // Same slot
        status: 'completed',
      }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const utilizationData = result.current.getStaffUtilization(dateRange);

    expect(utilizationData).toHaveLength(1);
    expect(utilizationData[0].staffId).toBe('staff-1');
    expect(utilizationData[0].totalAppointments).toBe(2);
    expect(utilizationData[0].heatmap).toHaveLength(7); // 7 days
    expect(utilizationData[0].heatmap[0]).toHaveLength(16); // 16 hours (6am-10pm)
  });

  it('should calculate peak hour correctly', () => {
    const appointments: Appointment[] = [
      createAppointment({ startTime: new Date('2025-01-15T10:00') }), // 10am
      createAppointment({ startTime: new Date('2025-01-15T10:00') }), // 10am
      createAppointment({ startTime: new Date('2025-01-15T14:00') }), // 2pm
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const utilizationData = result.current.getStaffUtilization(dateRange);

    expect(utilizationData[0].peakHour).toBe(10);
  });

  it('should filter by staff ID', () => {
    const appointments: Appointment[] = [
      createAppointment({ staffId: 'staff-1', staffName: 'Dr. Smith' }),
      createAppointment({ staffId: 'staff-2', staffName: 'Dr. Jones' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments, payments: [], disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const utilizationData = result.current.getStaffUtilization(dateRange, 'staff-1');

    expect(utilizationData).toHaveLength(1);
    expect(utilizationData[0].staffId).toBe('staff-1');
  });
});

// ============================================
// Payout Tests
// ============================================

describe('useAdvancedAnalytics - Payouts', () => {
  it('should calculate payout totals correctly', () => {
    const payments: Payment[] = [
      createPayment({ amountCents: 50000, type: 'full' }),
      createPayment({ amountCents: 30000, type: 'full' }),
      createPayment({ amountCents: 20000, type: 'subscription' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments, disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const payoutData = result.current.getPayouts(dateRange, 'daily');

    expect(payoutData).toHaveLength(1);
    expect(payoutData[0].totalCents).toBe(100000);
    expect(payoutData[0].appointmentsCents).toBe(80000);
    expect(payoutData[0].invoicesCents).toBe(0);
    expect(payoutData[0].subscriptionsCents).toBe(20000);
    expect(payoutData[0].count).toBe(3);
  });

  it('should only include completed payments', () => {
    const payments: Payment[] = [
      createPayment({ status: 'completed', amountCents: 50000 }),
      createPayment({ status: 'pending', amountCents: 30000 }),
      createPayment({ status: 'failed', amountCents: 20000 }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments, disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const payoutData = result.current.getPayouts(dateRange, 'daily');

    expect(payoutData[0].totalCents).toBe(50000);
    expect(payoutData[0].count).toBe(1);
  });

  it('should group by monthly granularity', () => {
    const payments: Payment[] = [
      createPayment({ createdAt: new Date('2025-01-15'), amountCents: 50000 }),
      createPayment({ createdAt: new Date('2025-02-15'), amountCents: 30000 }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments, disputes: [] })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-02-28'),
    };

    const payoutData = result.current.getPayouts(dateRange, 'monthly');

    expect(payoutData).toHaveLength(2);
  });
});

// ============================================
// Dispute Tests
// ============================================

describe('useAdvancedAnalytics - Disputes', () => {
  it('should return all disputes', () => {
    const disputes: Dispute[] = [
      createDispute({ id: 'dispute-1', status: 'open' }),
      createDispute({ id: 'dispute-2', status: 'resolved' }),
      createDispute({ id: 'dispute-3', status: 'lost' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments: [], disputes })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const disputeData = result.current.getDisputes(dateRange);

    expect(disputeData).toHaveLength(3);
  });

  it('should filter by status', () => {
    const disputes: Dispute[] = [
      createDispute({ id: 'dispute-1', status: 'open' }),
      createDispute({ id: 'dispute-2', status: 'open' }),
      createDispute({ id: 'dispute-3', status: 'resolved' }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments: [], disputes })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const disputeData = result.current.getDisputes(dateRange, 'open');

    expect(disputeData).toHaveLength(2);
    expect(disputeData.every(d => d.status === 'open')).toBe(true);
  });

  it('should sort by date descending', () => {
    const disputes: Dispute[] = [
      createDispute({ id: 'dispute-1', createdAt: new Date('2025-01-10') }),
      createDispute({ id: 'dispute-2', createdAt: new Date('2025-01-20') }),
      createDispute({ id: 'dispute-3', createdAt: new Date('2025-01-15') }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments: [], disputes })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const disputeData = result.current.getDisputes(dateRange);

    expect(disputeData[0].id).toBe('dispute-2');
    expect(disputeData[1].id).toBe('dispute-3');
    expect(disputeData[2].id).toBe('dispute-1');
  });

  it('should filter by date range', () => {
    const disputes: Dispute[] = [
      createDispute({ id: 'dispute-1', createdAt: new Date('2025-01-15') }),
      createDispute({ id: 'dispute-2', createdAt: new Date('2024-12-15') }),
    ];

    const { result } = renderHook(() =>
      useAdvancedAnalytics({ leads: [], deals: [], appointments: [], payments: [], disputes })
    );

    const dateRange = {
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    };

    const disputeData = result.current.getDisputes(dateRange);

    expect(disputeData).toHaveLength(1);
    expect(disputeData[0].id).toBe('dispute-1');
  });
});
