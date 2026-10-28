/**
 * Calendar Conflict Service
 * Detects scheduling conflicts for staff members by checking their calendar busy times
 *
 * HIPAA Compliance: Only fetches time blocks, not event details
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import {
  getCalendarConnectionRepository,
  type CalendarConnectionRepository,
} from '../data/repositories/calendar-connection-repository';
import { getFeatureFlags } from '../config/features';

// ============================================
// Types
// ============================================

export interface BusyTimeSlot {
  start: Date;
  end: Date;
  source: 'calendar' | 'schedule_exception';
}

export interface StaffConflict {
  staffId: string;
  staffName: string;
  conflictType: 'busy' | 'blocked' | 'overlap';
  timeSlot: BusyTimeSlot;
  message: string;
}

export interface ConflictCheckResult {
  staffId: string;
  hasConflicts: boolean;
  busySlots: BusyTimeSlot[];
  conflicts: StaffConflict[];
}

export interface ConflictCheckOptions {
  date: Date;
  startTime?: string; // HH:mm format
  endTime?: string; // HH:mm format
  staffIds: string[];
}

// ============================================
// Service
// ============================================

export class CalendarConflictService {
  private connections: CalendarConnectionRepository;

  constructor(connectionRepo?: CalendarConnectionRepository) {
    this.connections = connectionRepo || getCalendarConnectionRepository();
  }

  private assertEnabled(): void {
    const flags = getFeatureFlags();
    if (!flags.enableCalendarSync) {
      throw new Error('Calendar sync is disabled');
    }
  }

  /**
   * Check for conflicts for a list of staff members on a specific date
   */
  async checkConflicts(
    context: SecurityContext,
    options: ConflictCheckOptions
  ): Promise<ConflictCheckResult[]> {
    this.assertEnabled();

    const results: ConflictCheckResult[] = [];

    // Build date range for the day
    const dayStart = new Date(options.date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(options.date);
    dayEnd.setHours(23, 59, 59, 999);

    // Parse work hours if provided
    let workStart: Date | null = null;
    let workEnd: Date | null = null;

    if (options.startTime) {
      const [startHour, startMin] = options.startTime.split(':').map(Number);
      workStart = new Date(options.date);
      workStart.setHours(startHour, startMin, 0, 0);
    }

    if (options.endTime) {
      const [endHour, endMin] = options.endTime.split(':').map(Number);
      workEnd = new Date(options.date);
      workEnd.setHours(endHour, endMin, 0, 0);
    }

    for (const staffId of options.staffIds) {
      const result = await this.checkStaffConflicts(
        context,
        staffId,
        dayStart,
        dayEnd,
        workStart,
        workEnd
      );
      results.push(result);
    }

    return results;
  }

  /**
   * Check conflicts for a single staff member
   */
  private async checkStaffConflicts(
    context: SecurityContext,
    staffId: string,
    dayStart: Date,
    dayEnd: Date,
    workStart: Date | null,
    workEnd: Date | null
  ): Promise<ConflictCheckResult> {
    const busySlots: BusyTimeSlot[] = [];
    const conflicts: StaffConflict[] = [];

    try {
      // Get calendar connections for this staff member
      const connectionsResult = await this.connections.getByUser(context, staffId);

      if (!connectionsResult.success || connectionsResult.data.data.length === 0) {
        // No calendar connected - no conflicts from calendar
        return {
          staffId,
          hasConflicts: false,
          busySlots: [],
          conflicts: [],
        };
      }

      // For each connected calendar, fetch busy times
      // Note: In production, this would call a Cloud Function to fetch from Google/Outlook
      // For now, we simulate based on connection metadata
      for (const connection of connectionsResult.data.data) {
        if (connection.status !== 'active') continue;

        // Get busy times from calendar
        // In production: const busyTimes = await this.fetchBusyTimes(context, connection, dayStart, dayEnd);
        // For now, use any scheduled sync events stored locally
        const calendarBusySlots = await this.getLocalBusySlots(context, connection.id, dayStart, dayEnd);
        busySlots.push(...calendarBusySlots);
      }

      // Check if any busy slots conflict with work hours
      if (workStart && workEnd) {
        for (const slot of busySlots) {
          if (this.overlaps(slot.start, slot.end, workStart, workEnd)) {
            conflicts.push({
              staffId,
              staffName: '', // Would be filled in by caller
              conflictType: 'busy',
              timeSlot: slot,
              message: `Calendar event from ${this.formatTime(slot.start)} to ${this.formatTime(slot.end)}`,
            });
          }
        }
      }
    } catch (error) {
      console.error(`Failed to check conflicts for staff ${staffId}:`, error);
      // Return empty result on error - don't block route planning
    }

    return {
      staffId,
      hasConflicts: conflicts.length > 0,
      busySlots,
      conflicts,
    };
  }

  /**
   * Get locally stored busy slots (from sync mappings)
   * In production, this would be replaced by actual calendar API calls
   */
  private async getLocalBusySlots(
    _context: SecurityContext,
    _connectionId: string,
    _dayStart: Date,
    _dayEnd: Date
  ): Promise<BusyTimeSlot[]> {
    // This is a placeholder - in production, fetch from calendar provider
    // or from cached sync data
    return [];
  }

  /**
   * Check if two time ranges overlap
   */
  private overlaps(start1: Date, end1: Date, start2: Date, end2: Date): boolean {
    return start1 < end2 && end1 > start2;
  }

  /**
   * Format time for display
   */
  private formatTime(date: Date): string {
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  }

  /**
   * Check if a specific time slot is available for a staff member
   */
  async isSlotAvailable(
    context: SecurityContext,
    staffId: string,
    start: Date,
    end: Date
  ): Promise<boolean> {
    const dayStart = new Date(start);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(start);
    dayEnd.setHours(23, 59, 59, 999);

    const result = await this.checkStaffConflicts(
      context,
      staffId,
      dayStart,
      dayEnd,
      start,
      end
    );

    return !result.hasConflicts;
  }

  /**
   * Get available time slots for a staff member on a date
   */
  async getAvailableSlots(
    context: SecurityContext,
    staffId: string,
    date: Date,
    workStart: string, // HH:mm
    workEnd: string, // HH:mm
    slotDurationMinutes: number = 60
  ): Promise<{ start: Date; end: Date }[]> {
    const dayStart = new Date(date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    const [startHour, startMin] = workStart.split(':').map(Number);
    const [endHour, endMin] = workEnd.split(':').map(Number);

    const workStartDate = new Date(date);
    workStartDate.setHours(startHour, startMin, 0, 0);
    const workEndDate = new Date(date);
    workEndDate.setHours(endHour, endMin, 0, 0);

    const result = await this.checkStaffConflicts(
      context,
      staffId,
      dayStart,
      dayEnd,
      workStartDate,
      workEndDate
    );

    // Generate all possible slots
    const allSlots: { start: Date; end: Date }[] = [];
    let currentStart = new Date(workStartDate);

    while (currentStart < workEndDate) {
      const slotEnd = new Date(currentStart.getTime() + slotDurationMinutes * 60000);
      if (slotEnd <= workEndDate) {
        allSlots.push({ start: new Date(currentStart), end: slotEnd });
      }
      currentStart = slotEnd;
    }

    // Filter out slots that overlap with busy times
    return allSlots.filter((slot) => {
      return !result.busySlots.some((busy) =>
        this.overlaps(slot.start, slot.end, busy.start, busy.end)
      );
    });
  }
}

// ============================================
// Singleton
// ============================================

let serviceInstance: CalendarConflictService | null = null;

export function getCalendarConflictService(): CalendarConflictService {
  if (!serviceInstance) {
    serviceInstance = new CalendarConflictService();
  }
  return serviceInstance;
}

export function resetCalendarConflictService(): void {
  serviceInstance = null;
}

export default CalendarConflictService;
