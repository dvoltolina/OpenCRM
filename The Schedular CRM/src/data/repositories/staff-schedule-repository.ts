/**
 * Staff Schedule Repository
 * Manages staff schedule records for route planning
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 * Path: businesses/{businessId}/staff_schedules/{scheduleId}
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  ValidationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type {
  StaffSchedule,
  ScheduleException,
  DayOfWeek,
  WeeklySchedulePattern,
} from '../../types/models';

// ============================================
// Types
// ============================================

export interface StaffScheduleFilters {
  staffId?: string;
  isWorking?: boolean; // Filter to only working staff on a date
  date?: Date; // For checking who's working on a specific date
}

// ============================================
// Validation
// ============================================

const staffScheduleValidator: Validator<StaffSchedule> = (
  data: Partial<StaffSchedule>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.staffId !== undefined && !data.staffId?.trim()) {
    errors.push({
      field: 'staffId',
      message: 'Staff ID is required',
      code: 'REQUIRED',
    });
  }

  if (data.staffName !== undefined && !data.staffName?.trim()) {
    errors.push({
      field: 'staffName',
      message: 'Staff name is required',
      code: 'REQUIRED',
    });
  }

  if (data.weeklyPatterns !== undefined && !Array.isArray(data.weeklyPatterns)) {
    errors.push({
      field: 'weeklyPatterns',
      message: 'Weekly patterns must be an array',
      code: 'INVALID_FORMAT',
    });
  }

  if (data.timezone !== undefined && !data.timezone?.trim()) {
    errors.push({
      field: 'timezone',
      message: 'Timezone is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateScheduleCreate: Validator<StaffSchedule> = (
  data: Partial<StaffSchedule>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!data.staffId?.trim()) {
    errors.push({
      field: 'staffId',
      message: 'Staff ID is required',
      code: 'REQUIRED',
    });
  }

  if (!data.staffName?.trim()) {
    errors.push({
      field: 'staffName',
      message: 'Staff name is required',
      code: 'REQUIRED',
    });
  }

  if (!data.timezone?.trim()) {
    errors.push({
      field: 'timezone',
      message: 'Timezone is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Helper Functions
// ============================================

const DAYS_OF_WEEK: DayOfWeek[] = [
  'sunday',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
];

/**
 * Get the day of week string from a Date
 */
function getDayOfWeek(date: Date): DayOfWeek {
  return DAYS_OF_WEEK[date.getDay()];
}

/**
 * Check if a date matches any exception
 */
function findException(
  exceptions: ScheduleException[],
  date: Date
): ScheduleException | undefined {
  const dateStr = date.toISOString().split('T')[0];
  return exceptions.find((exc) => {
    const excDate =
      exc.date instanceof Date ? exc.date : new Date(exc.date as unknown as string);
    return excDate.toISOString().split('T')[0] === dateStr;
  });
}

/**
 * Check if staff is working on a specific date based on schedule
 */
export function isStaffWorkingOnDate(schedule: StaffSchedule, date: Date): boolean {
  // Check for exception first
  const exception = findException(schedule.exceptions, date);
  if (exception) {
    if (exception.allDay && exception.type === 'time_off') {
      return false;
    }
    if (exception.type === 'modified_hours' && exception.shifts) {
      return exception.shifts.length > 0;
    }
    if (exception.type === 'holiday') {
      return false;
    }
  }

  // Check weekly pattern
  const dayOfWeek = getDayOfWeek(date);
  const pattern = schedule.weeklyPatterns.find((p) => p.dayOfWeek === dayOfWeek);
  return pattern?.isWorkingDay ?? false;
}

/**
 * Create default weekly patterns (Mon-Fri 9-5)
 */
export function createDefaultWeeklyPatterns(): WeeklySchedulePattern[] {
  return DAYS_OF_WEEK.map((day) => ({
    dayOfWeek: day,
    isWorkingDay: day !== 'saturday' && day !== 'sunday',
    shifts:
      day !== 'saturday' && day !== 'sunday'
        ? [{ startTime: '09:00', endTime: '17:00' }]
        : [],
  }));
}

// ============================================
// Staff Schedule Repository
// ============================================

export class StaffScheduleRepository extends ShareableRepository<StaffSchedule> {
  protected entityName = 'staff_schedule';
  protected sensitiveFields: Array<keyof StaffSchedule> = [];

  constructor() {
    super({ collectionName: 'staff_schedules' });
    this.setValidator(staffScheduleValidator);
  }

  async create(
    context: SecurityContext,
    data: Omit<StaffSchedule, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<StaffSchedule>> {
    const validation = validateScheduleCreate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Set defaults
    const scheduleData = {
      ...data,
      businessId: context.businessId,
      weeklyPatterns: data.weeklyPatterns ?? createDefaultWeeklyPatterns(),
      exceptions: data.exceptions ?? [],
      syncExceptionsFromCalendar: data.syncExceptionsFromCalendar ?? false,
      createdBy: context.userId,
      createdByName: context.userName,
    };

    return super.create(context, scheduleData, customId);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get schedule for a specific staff member
   */
  async getByStaffId(
    context: SecurityContext,
    staffId: string
  ): Promise<RepositoryResult<StaffSchedule | null>> {
    try {
      if (!isValidDocumentId(staffId)) {
        return failedResult(new InvalidArgumentError('Invalid staff ID', 'staffId'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'staffId', operator: '==', value: staffId }],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return successResult(null);
      }

      const schedule = this.snapshotToSchedules(snapshot)[0];

      await this.logAudit(context, 'read', schedule.id, { action: 'getByStaffId' });

      return successResult(schedule);
    } catch (error) {
      return failedResult(error, 'Failed to get schedule by staff ID');
    }
  }

  /**
   * Get all schedules for staff working on a specific date
   */
  async getWorkingStaffForDate(
    context: SecurityContext,
    date: Date
  ): Promise<RepositoryResult<StaffSchedule[]>> {
    try {
      // Get all schedules first, then filter in memory
      // (Firestore can't query nested array properties)
      const allResult = await this.getAll(context, {
        orderBy: { field: 'staffName', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      const workingStaff = allResult.data.data.filter((schedule) =>
        isStaffWorkingOnDate(schedule, date)
      );

      await this.logAudit(context, 'list', null, {
        action: 'getWorkingStaffForDate',
        date: date.toISOString(),
        count: workingStaff.length,
      });

      return successResult(workingStaff);
    } catch (error) {
      return failedResult(error, 'Failed to get working staff for date');
    }
  }

  /**
   * Get all schedules
   */
  async getAllSchedules(
    context: SecurityContext
  ): Promise<RepositoryResult<StaffSchedule[]>> {
    try {
      const allResult = await this.getAll(context, {
        orderBy: { field: 'staffName', direction: 'asc' },
      });

      if (!allResult.success) {
        return { success: false, data: null, error: allResult.error };
      }

      return successResult(allResult.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get all schedules');
    }
  }

  // ============================================
  // Exception Management
  // ============================================

  /**
   * Add an exception to a schedule
   */
  async addException(
    context: SecurityContext,
    scheduleId: string,
    exception: Omit<ScheduleException, 'id'>
  ): Promise<RepositoryResult<StaffSchedule>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(
          new InvalidArgumentError('Invalid schedule ID', 'scheduleId')
        );
      }

      const existingResult = await this.getById(context, scheduleId);
      if (!existingResult.success) {
        return existingResult;
      }

      const schedule = existingResult.data;
      const newException: ScheduleException = {
        ...exception,
        id: `exc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      };

      const updatedExceptions = [...schedule.exceptions, newException];
      return this.update(context, scheduleId, { exceptions: updatedExceptions });
    } catch (error) {
      return failedResult(error, 'Failed to add exception');
    }
  }

  /**
   * Remove an exception from a schedule
   */
  async removeException(
    context: SecurityContext,
    scheduleId: string,
    exceptionId: string
  ): Promise<RepositoryResult<StaffSchedule>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(
          new InvalidArgumentError('Invalid schedule ID', 'scheduleId')
        );
      }

      const existingResult = await this.getById(context, scheduleId);
      if (!existingResult.success) {
        return existingResult;
      }

      const schedule = existingResult.data;
      const updatedExceptions = schedule.exceptions.filter(
        (exc) => exc.id !== exceptionId
      );

      return this.update(context, scheduleId, { exceptions: updatedExceptions });
    } catch (error) {
      return failedResult(error, 'Failed to remove exception');
    }
  }

  /**
   * Update weekly patterns
   */
  async updateWeeklyPatterns(
    context: SecurityContext,
    scheduleId: string,
    patterns: WeeklySchedulePattern[]
  ): Promise<RepositoryResult<StaffSchedule>> {
    try {
      if (!isValidDocumentId(scheduleId)) {
        return failedResult(
          new InvalidArgumentError('Invalid schedule ID', 'scheduleId')
        );
      }

      return this.update(context, scheduleId, { weeklyPatterns: patterns });
    } catch (error) {
      return failedResult(error, 'Failed to update weekly patterns');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private snapshotToSchedules(snapshot: QuerySnapshot<DocumentData>): StaffSchedule[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const teamIds = Array.isArray(data.teamIds) ? data.teamIds : [];
      const visibility = (data.visibility as StaffSchedule['visibility']) ?? 'team';

      // Parse weekly patterns
      const weeklyPatterns: WeeklySchedulePattern[] = Array.isArray(data.weeklyPatterns)
        ? data.weeklyPatterns.map((pattern: Record<string, unknown>) => ({
            dayOfWeek: pattern.dayOfWeek as DayOfWeek,
            isWorkingDay: Boolean(pattern.isWorkingDay),
            shifts: Array.isArray(pattern.shifts)
              ? pattern.shifts.map((shift: Record<string, unknown>) => ({
                  startTime: String(shift.startTime ?? '09:00'),
                  endTime: String(shift.endTime ?? '17:00'),
                }))
              : [],
          }))
        : createDefaultWeeklyPatterns();

      // Parse exceptions
      const exceptions: ScheduleException[] = Array.isArray(data.exceptions)
        ? data.exceptions.map((exc: Record<string, unknown>) => ({
            id: String(exc.id ?? ''),
            date: exc.date instanceof Timestamp ? exc.date.toDate() : new Date(exc.date as string),
            type: exc.type as ScheduleException['type'],
            reason: exc.reason as string | undefined,
            shifts: Array.isArray(exc.shifts)
              ? exc.shifts.map((shift: Record<string, unknown>) => ({
                  startTime: String(shift.startTime ?? ''),
                  endTime: String(shift.endTime ?? ''),
                }))
              : undefined,
            allDay: Boolean(exc.allDay),
            externalEventId: exc.externalEventId as string | undefined,
            calendarProvider: exc.calendarProvider as 'google' | 'outlook' | undefined,
          }))
        : [];

      return {
        id: doc.id,
        businessId: data.businessId as string,
        staffId: data.staffId as string,
        staffName: data.staffName as string,
        staffEmail: data.staffEmail as string | undefined,
        weeklyPatterns,
        exceptions,
        timezone: (data.timezone as string) ?? 'America/Los_Angeles',
        maxStopsPerDay: data.maxStopsPerDay as number | undefined,
        maxDrivingMinutesPerDay: data.maxDrivingMinutesPerDay as number | undefined,
        homeBaseAddress: data.homeBaseAddress as string | undefined,
        homeBaseLatitude: data.homeBaseLatitude as number | undefined,
        homeBaseLongitude: data.homeBaseLongitude as number | undefined,
        calendarConnectionId: data.calendarConnectionId as string | undefined,
        lastCalendarSyncAt: data.lastCalendarSyncAt?.toDate?.() ?? undefined,
        syncExceptionsFromCalendar: Boolean(data.syncExceptionsFromCalendar),
        ownerId: data.ownerId as string | undefined,
        ownerName: data.ownerName as string | undefined,
        teamIds,
        visibility,
        createdAt: data.createdAt?.toDate?.() ?? new Date(),
        updatedAt: data.updatedAt?.toDate?.() ?? undefined,
        createdBy: data.createdBy as string,
        createdByName: data.createdByName as string | undefined,
      };
    });
  }
}

// Export singleton instance
let staffScheduleRepository: StaffScheduleRepository | null = null;

export function getStaffScheduleRepository(): StaffScheduleRepository {
  if (!staffScheduleRepository) {
    staffScheduleRepository = new StaffScheduleRepository();
  }
  return staffScheduleRepository;
}
