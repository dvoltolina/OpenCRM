/**
 * useAdvancedAnalytics Hook
 * Advanced analytics calculations for CRM reporting
 *
 * Agent CRM-31 Implementation
 * Dependencies: CRM-18/19 (dashboard/charts)
 */

import { useMemo } from 'react';
import type { Deal, Lead, Payment, Dispute } from '../types/models';
import type { Appointment } from './useSchedulerData';

// ============================================
// Analytics Result Types
// ============================================

export interface LeadSourceROIData {
  source: string;
  leadCount: number;
  convertedCount: number;
  conversionRate: number;
  costCents: number;
  revenueCents: number;
  roiPercentage: number;
  costPerLead: number;
  costPerConversion: number;
}

export interface AppointmentCompletionData {
  date: string;
  scheduled: number;
  completed: number;
  missed: number;
  cancelled: number;
  completionRate: number;
}

export interface StaffUtilizationData {
  staffId: string;
  staffName: string;
  heatmap: number[][]; // [day][hour] = appointment count
  totalAppointments: number;
  averagePerDay: number;
  peakHour: number;
  peakDay: number;
}

export interface PayoutData {
  date: string;
  totalCents: number;
  appointmentsCents: number;
  invoicesCents: number;
  subscriptionsCents: number;
  count: number;
}

export interface DisputeData {
  id: string;
  paymentId: string;
  amountCents: number;
  status: 'open' | 'resolved' | 'lost';
  reason: string;
  clientId: string;
  clientName?: string;
  createdAt: Date;
  resolvedAt?: Date;
  paymentAmount?: number;
}

// ============================================
// Date Range Type
// ============================================

export interface DateRange {
  startDate: Date;
  endDate: Date;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Check if date is within range
 */
function isInDateRange(date: Date, range: DateRange): boolean {
  return date >= range.startDate && date <= range.endDate;
}

/**
 * Format date for grouping
 */
function formatDateKey(date: Date, granularity: 'daily' | 'weekly' | 'monthly'): string {
  const year = date.getFullYear();
  const month = date.getMonth();
  const day = date.getDate();

  if (granularity === 'daily') {
    return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }

  if (granularity === 'weekly') {
    const firstDay = new Date(year, 0, 1);
    const days = Math.floor((date.getTime() - firstDay.getTime()) / (24 * 60 * 60 * 1000));
    const week = Math.ceil((days + firstDay.getDay() + 1) / 7);
    return `${year}-W${String(week).padStart(2, '0')}`;
  }

  // monthly
  return `${year}-${String(month + 1).padStart(2, '0')}`;
}

/**
 * Get hour from date (0-23)
 */
function getHour(date: Date): number {
  return date.getHours();
}

/**
 * Get day of week (0=Sunday, 6=Saturday)
 */
function getDayOfWeek(date: Date): number {
  return date.getDay();
}

// ============================================
// Calculation Functions
// ============================================

/**
 * Calculate Lead Source ROI
 */
function calculateLeadSourceROI(
  leads: Lead[],
  deals: Deal[],
  dateRange: DateRange,
  sourceCosts: Map<string, number>
): LeadSourceROIData[] {
  // Filter leads in range
  const filteredLeads = leads.filter(lead => isInDateRange(lead.createdAt, dateRange));

  // Group by source
  const sourceMap = new Map<string, {
    leadCount: number;
    convertedCount: number;
    revenueCents: number;
  }>();

  filteredLeads.forEach(lead => {
    const source = lead.source;
    const existing = sourceMap.get(source) || {
      leadCount: 0,
      convertedCount: 0,
      revenueCents: 0,
    };

    existing.leadCount++;

    // Check if converted
    if (lead.status === 'converted' && lead.convertedToDealId) {
      const deal = deals.find(d => d.id === lead.convertedToDealId);
      if (deal && deal.status === 'won') {
        existing.convertedCount++;
        existing.revenueCents += deal.valueCents;
      }
    }

    sourceMap.set(source, existing);
  });

  // Calculate ROI metrics
  const results: LeadSourceROIData[] = [];

  sourceMap.forEach((data, source) => {
    const costCents = sourceCosts.get(source) || 0;
    const conversionRate = data.leadCount > 0
      ? (data.convertedCount / data.leadCount) * 100
      : 0;
    const roiPercentage = costCents > 0
      ? ((data.revenueCents - costCents) / costCents) * 100
      : 0;
    const costPerLead = data.leadCount > 0 ? costCents / data.leadCount : 0;
    const costPerConversion = data.convertedCount > 0
      ? costCents / data.convertedCount
      : 0;

    results.push({
      source,
      leadCount: data.leadCount,
      convertedCount: data.convertedCount,
      conversionRate,
      costCents,
      revenueCents: data.revenueCents,
      roiPercentage,
      costPerLead,
      costPerConversion,
    });
  });

  // Sort by ROI descending
  return results.sort((a, b) => b.roiPercentage - a.roiPercentage);
}

/**
 * Calculate Appointment Completion Rates
 */
function calculateAppointmentCompletion(
  appointments: Appointment[],
  dateRange: DateRange,
  granularity: 'daily' | 'weekly' | 'monthly',
  staffId?: string
): AppointmentCompletionData[] {
  // Filter appointments
  let filtered = appointments.filter(apt =>
    isInDateRange(apt.startTime, dateRange)
  );

  if (staffId) {
    filtered = filtered.filter(apt => apt.staffId === staffId);
  }

  // Group by date
  const dateMap = new Map<string, {
    scheduled: number;
    completed: number;
    missed: number;
    cancelled: number;
  }>();

  filtered.forEach(apt => {
    const key = formatDateKey(apt.startTime, granularity);
    const existing = dateMap.get(key) || {
      scheduled: 0,
      completed: 0,
      missed: 0,
      cancelled: 0,
    };

    existing.scheduled++;
    if (apt.status === 'completed') existing.completed++;
    if (apt.status === 'missed') existing.missed++;
    if (apt.status === 'cancelled') existing.cancelled++;

    dateMap.set(key, existing);
  });

  // Calculate completion rates
  const results: AppointmentCompletionData[] = [];

  dateMap.forEach((data, date) => {
    const completionRate = data.scheduled > 0
      ? (data.completed / data.scheduled) * 100
      : 0;

    results.push({
      date,
      scheduled: data.scheduled,
      completed: data.completed,
      missed: data.missed,
      cancelled: data.cancelled,
      completionRate,
    });
  });

  // Sort by date
  return results.sort((a, b) => a.date.localeCompare(b.date));
}

/**
 * Calculate Staff Utilization Heatmap
 */
function calculateStaffUtilization(
  appointments: Appointment[],
  dateRange: DateRange,
  staffId?: string
): StaffUtilizationData[] {
  // Filter appointments
  let filtered = appointments.filter(apt =>
    isInDateRange(apt.startTime, dateRange) &&
    (apt.status === 'completed' || apt.status === 'scheduled')
  );

  if (staffId) {
    filtered = filtered.filter(apt => apt.staffId === staffId);
  }

  // Group by staff
  const staffMap = new Map<string, {
    staffName: string;
    appointments: Appointment[];
  }>();

  filtered.forEach(apt => {
    if (!apt.staffId) return; // Skip if no staffId

    const existing = staffMap.get(apt.staffId) || {
      staffName: apt.staffName || 'Unknown',
      appointments: [],
    };
    existing.appointments.push(apt);
    staffMap.set(apt.staffId, existing);
  });

  // Calculate heatmaps
  const results: StaffUtilizationData[] = [];

  staffMap.forEach((data, id) => {
    // Create 7x16 grid (7 days, 16 hours from 6am-10pm)
    const heatmap: number[][] = Array(7).fill(0).map(() => Array(16).fill(0));

    data.appointments.forEach(apt => {
      const day = getDayOfWeek(apt.startTime);
      const hour = getHour(apt.startTime);

      // Map to grid (6am-10pm = indexes 0-15)
      if (hour >= 6 && hour < 22) {
        heatmap[day][hour - 6]++;
      }
    });

    // Calculate stats
    const totalAppointments = data.appointments.length;
    const daysInRange = Math.ceil(
      (dateRange.endDate.getTime() - dateRange.startDate.getTime()) / (1000 * 60 * 60 * 24)
    );
    const averagePerDay = daysInRange > 0 ? totalAppointments / daysInRange : 0;

    // Find peak hour and day
    let peakHour = 0;
    let peakDay = 0;
    let maxCount = 0;

    heatmap.forEach((dayData, day) => {
      dayData.forEach((count, hour) => {
        if (count > maxCount) {
          maxCount = count;
          peakDay = day;
          peakHour = hour + 6; // Convert back to actual hour
        }
      });
    });

    results.push({
      staffId: id,
      staffName: data.staffName,
      heatmap,
      totalAppointments,
      averagePerDay,
      peakHour,
      peakDay,
    });
  });

  // Sort by total appointments descending
  return results.sort((a, b) => b.totalAppointments - a.totalAppointments);
}

/**
 * Calculate Payout Totals
 */
function calculatePayouts(
  payments: Payment[],
  dateRange: DateRange,
  granularity: 'daily' | 'weekly' | 'monthly'
): PayoutData[] {
  // Filter completed payments in range
  const filtered = payments.filter(payment =>
    payment.status === 'completed' &&
    isInDateRange(payment.createdAt, dateRange)
  );

  // Group by date
  const dateMap = new Map<string, {
    totalCents: number;
    appointmentsCents: number;
    invoicesCents: number;
    subscriptionsCents: number;
    count: number;
  }>();

  filtered.forEach(payment => {
    const key = formatDateKey(payment.createdAt, granularity);
    const existing = dateMap.get(key) || {
      totalCents: 0,
      appointmentsCents: 0,
      invoicesCents: 0,
      subscriptionsCents: 0,
      count: 0,
    };

    existing.totalCents += payment.amountCents;
    existing.count++;

    if (
      payment.type === 'full' ||
      payment.type === 'deposit' ||
      payment.type === 'reschedule_fee' ||
      payment.type === 'cancellation_fee'
    ) {
      existing.appointmentsCents += payment.amountCents;
    } else if (payment.type === 'subscription') {
      existing.subscriptionsCents += payment.amountCents;
    } else {
      // Any other type is treated as an invoice/other bucket
      existing.invoicesCents += payment.amountCents;
    }

    dateMap.set(key, existing);
  });

  // Convert to array
  const results: PayoutData[] = [];

  dateMap.forEach((data, date) => {
    results.push({
      date,
      ...data,
    });
  });

  // Sort by date
  return results.sort((a, b) => a.date.localeCompare(b.date));
}

/**
 * Get Disputes
 */
function getDisputes(
  disputes: Dispute[],
  dateRange: DateRange,
  status?: 'open' | 'resolved' | 'lost'
): DisputeData[] {
  // Filter disputes
  let filtered = disputes.filter(dispute =>
    isInDateRange(dispute.createdAt, dateRange)
  );

  if (status) {
    filtered = filtered.filter(d => d.status === status);
  }

  // Sort by date descending
  return filtered.sort((a, b) =>
    b.createdAt.getTime() - a.createdAt.getTime()
  );
}

// ============================================
// Hook Implementation
// ============================================

export interface UseAdvancedAnalyticsOptions {
  leads: Lead[];
  deals: Deal[];
  appointments: Appointment[];
  payments: Payment[];
  disputes: Dispute[];
}

export interface UseAdvancedAnalyticsResult {
  /**
   * Get Lead Source ROI data
   * @param dateRange - Date range to analyze
   * @param sourceCosts - Map of source name to cost in cents
   */
  getLeadSourceROI: (
    dateRange: DateRange,
    sourceCosts: Map<string, number>
  ) => LeadSourceROIData[];

  /**
   * Get Appointment Completion data
   * @param dateRange - Date range to analyze
   * @param granularity - Time grouping (daily/weekly/monthly)
   * @param staffId - Optional staff filter
   */
  getAppointmentCompletion: (
    dateRange: DateRange,
    granularity: 'daily' | 'weekly' | 'monthly',
    staffId?: string
  ) => AppointmentCompletionData[];

  /**
   * Get Staff Utilization heatmap data
   * @param dateRange - Date range to analyze
   * @param staffId - Optional staff filter
   */
  getStaffUtilization: (
    dateRange: DateRange,
    staffId?: string
  ) => StaffUtilizationData[];

  /**
   * Get Payout totals
   * @param dateRange - Date range to analyze
   * @param granularity - Time grouping (daily/weekly/monthly)
   */
  getPayouts: (
    dateRange: DateRange,
    granularity: 'daily' | 'weekly' | 'monthly'
  ) => PayoutData[];

  /**
   * Get Disputes
   * @param dateRange - Date range to analyze
   * @param status - Optional status filter
   */
  getDisputes: (
    dateRange: DateRange,
    status?: 'open' | 'resolved' | 'lost'
  ) => DisputeData[];
}

/**
 * Hook for advanced analytics calculations
 *
 * @param options - Data sources for analytics
 * @returns Analytics calculation functions
 *
 * @example
 * ```tsx
 * const { deals, leads } = useDeals();
 * const appointments = []; // From scheduler
 * const payments = []; // From scheduler
 * const disputes = []; // From scheduler
 *
 * const analytics = useAdvancedAnalytics({
 *   leads,
 *   deals,
 *   appointments,
 *   payments,
 *   disputes,
 * });
 *
 * const roiData = analytics.getLeadSourceROI(
 *   { startDate: new Date('2025-01-01'), endDate: new Date() },
 *   new Map([['website', 50000], ['referral', 10000]])
 * );
 * ```
 */
export function useAdvancedAnalytics(
  options: UseAdvancedAnalyticsOptions
): UseAdvancedAnalyticsResult {
  const { leads, deals, appointments, payments, disputes } = options;

  return useMemo(() => {
    return {
      getLeadSourceROI: (dateRange, sourceCosts) =>
        calculateLeadSourceROI(leads, deals, dateRange, sourceCosts),

      getAppointmentCompletion: (dateRange, granularity, staffId) =>
        calculateAppointmentCompletion(appointments, dateRange, granularity, staffId),

      getStaffUtilization: (dateRange, staffId) =>
        calculateStaffUtilization(appointments, dateRange, staffId),

      getPayouts: (dateRange, granularity) =>
        calculatePayouts(payments, dateRange, granularity),

      getDisputes: (dateRange, status) =>
        getDisputes(disputes, dateRange, status),
    };
  }, [leads, deals, appointments, payments, disputes]);
}

export default useAdvancedAnalytics;
