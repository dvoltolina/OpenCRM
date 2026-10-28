/**
 * Sequence Scheduler
 * Handles scheduling logic for sequence step execution
 *
 * HIPAA Compliance: No PHI in scheduling calculations
 * All times are calculated based on configuration, not user data
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { SequenceStep, SequenceSettings, SendingSchedule } from '../types/sequences';

// ============================================
// Types
// ============================================

export interface ScheduleResult {
  scheduledAt: Date;
  adjustedReason?: string;
}

// ============================================
// Sequence Scheduler
// ============================================

export class SequenceScheduler {
  /**
   * Calculate when the next step should execute.
   * Respects business hours, weekends, and step delays.
   */
  calculateNextStepTime(
    fromTime: Date,
    step: SequenceStep,
    settings: SequenceSettings
  ): ScheduleResult {
    let targetTime = new Date(fromTime);
    const reasons: string[] = [];

    // 1. Add delay (days + hours)
    const delayDays = step.delayDays || 0;
    const delayHours = step.delayHours || 0;

    targetTime.setDate(targetTime.getDate() + delayDays);
    targetTime.setHours(targetTime.getHours() + delayHours);

    // 2. Apply preferred time of day if specified
    if (step.timeOfDay) {
      const [hours, minutes] = step.timeOfDay.split(':').map(Number);
      if (!isNaN(hours) && !isNaN(minutes)) {
        targetTime.setHours(hours, minutes, 0, 0);
        // If we've gone backwards in time, move to next day
        if (targetTime <= fromTime && delayDays === 0 && delayHours === 0) {
          targetTime.setDate(targetTime.getDate() + 1);
        }
      }
    }

    // 3. Skip weekends if configured (step-level or settings-level)
    const skipWeekends = step.skipWeekends ?? settings.sendingSchedule.excludeDays.length > 0;
    if (skipWeekends) {
      const originalDate = new Date(targetTime);
      targetTime = this.adjustForExcludedDays(targetTime, settings.sendingSchedule.excludeDays);
      if (targetTime.getTime() !== originalDate.getTime()) {
        reasons.push('Adjusted for excluded days');
      }
    }

    // 4. Adjust for business hours if configured
    if (settings.sendingSchedule.businessHoursOnly) {
      const originalTime = new Date(targetTime);
      targetTime = this.adjustForBusinessHours(targetTime, settings.sendingSchedule);
      if (targetTime.getTime() !== originalTime.getTime()) {
        reasons.push('Adjusted for business hours');
      }
    }

    return {
      scheduledAt: targetTime,
      adjustedReason: reasons.length > 0 ? reasons.join('; ') : undefined,
    };
  }

  /**
   * Check if a time is within business hours.
   */
  isWithinBusinessHours(time: Date, settings: SequenceSettings): boolean {
    const schedule = settings.sendingSchedule;

    // Check if day is excluded
    if (this.isExcludedDay(time, schedule.excludeDays)) {
      return false;
    }

    const hour = time.getHours();
    return hour >= schedule.startHour && hour < schedule.endHour;
  }

  /**
   * Get next available business hour time.
   */
  getNextBusinessHour(time: Date, settings: SequenceSettings): Date {
    return this.adjustForBusinessHours(new Date(time), settings.sendingSchedule);
  }

  /**
   * Check if a date is on an excluded day.
   */
  isExcludedDay(date: Date, excludeDays: number[]): boolean {
    return excludeDays.includes(date.getDay());
  }

  /**
   * Check if a date is a weekend (Saturday = 6, Sunday = 0).
   */
  isWeekend(date: Date): boolean {
    const day = date.getDay();
    return day === 0 || day === 6;
  }

  /**
   * Adjust time to skip excluded days.
   * Moves to the next non-excluded day.
   */
  private adjustForExcludedDays(time: Date, excludeDays: number[]): Date {
    const result = new Date(time);
    let attempts = 0;
    const maxAttempts = 7; // Prevent infinite loop

    while (excludeDays.includes(result.getDay()) && attempts < maxAttempts) {
      result.setDate(result.getDate() + 1);
      attempts++;
    }

    return result;
  }

  /**
   * Adjust time to be within business hours.
   * If outside hours, moves to next available business hour.
   */
  private adjustForBusinessHours(time: Date, schedule: SendingSchedule): Date {
    const result = new Date(time);

    // First, skip any excluded days
    result.setTime(this.adjustForExcludedDays(result, schedule.excludeDays).getTime());

    const hour = result.getHours();

    // If before start hour, move to start hour
    if (hour < schedule.startHour) {
      result.setHours(schedule.startHour, 0, 0, 0);
    }
    // If after end hour, move to start hour of next business day
    else if (hour >= schedule.endHour) {
      result.setDate(result.getDate() + 1);
      result.setHours(schedule.startHour, 0, 0, 0);
      // Skip excluded days again after moving to next day
      result.setTime(this.adjustForExcludedDays(result, schedule.excludeDays).getTime());
    }

    return result;
  }

  /**
   * Calculate the schedule for all remaining steps in a sequence.
   * Useful for previewing the timeline.
   */
  calculateFullSchedule(
    steps: SequenceStep[],
    settings: SequenceSettings,
    startTime?: Date
  ): Array<{ stepId: string; stepIndex: number; scheduledAt: Date }> {
    const schedule: Array<{ stepId: string; stepIndex: number; scheduledAt: Date }> = [];
    let currentTime = startTime || new Date();

    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      if (!step.isActive) continue;

      const result = this.calculateNextStepTime(currentTime, step, settings);
      schedule.push({
        stepId: step.id,
        stepIndex: i,
        scheduledAt: result.scheduledAt,
      });
      currentTime = result.scheduledAt;
    }

    return schedule;
  }

  /**
   * Calculate total duration of a sequence in days.
   */
  calculateSequenceDurationDays(
    steps: SequenceStep[],
    settings: SequenceSettings
  ): number {
    if (steps.length === 0) return 0;

    const now = new Date();
    const schedule = this.calculateFullSchedule(steps, settings, now);

    if (schedule.length === 0) return 0;

    const lastStep = schedule[schedule.length - 1];
    const durationMs = lastStep.scheduledAt.getTime() - now.getTime();

    return Math.ceil(durationMs / (24 * 60 * 60 * 1000));
  }

  /**
   * Convert a date to the specified timezone.
   * Note: Full timezone support requires a library like date-fns-tz or luxon.
   * This is a simplified implementation.
   */
  toTimezone(date: Date, timezone: string): Date {
    try {
      // Get the offset for the target timezone
      const targetDate = new Date(
        date.toLocaleString('en-US', { timeZone: timezone })
      );
      return targetDate;
    } catch {
      // If timezone is invalid, return original date
      return date;
    }
  }

  /**
   * Get the current time in the specified timezone.
   */
  nowInTimezone(timezone: string): Date {
    return this.toTimezone(new Date(), timezone);
  }
}

// ============================================
// Singleton Instance
// ============================================

let schedulerInstance: SequenceScheduler | null = null;

export function getSequenceScheduler(): SequenceScheduler {
  if (!schedulerInstance) {
    schedulerInstance = new SequenceScheduler();
  }
  return schedulerInstance;
}

// ============================================
// Utility Functions
// ============================================

/**
 * Calculate retry delay with exponential backoff.
 */
export function calculateBackoffDelay(
  attempt: number,
  baseDelayMs: number = 60000,
  maxDelayMs: number = 3600000,
  multiplier: number = 2
): number {
  const delay = baseDelayMs * Math.pow(multiplier, attempt - 1);
  return Math.min(delay, maxDelayMs);
}

/**
 * Get the next retry time based on attempt number.
 */
export function getNextRetryTime(
  attempt: number,
  baseDelayMs: number = 60000,
  maxDelayMs: number = 3600000
): Date {
  const delay = calculateBackoffDelay(attempt, baseDelayMs, maxDelayMs);
  return new Date(Date.now() + delay);
}
