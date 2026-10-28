/**
 * Sequence Scheduler Tests
 *
 * Tests scheduling logic for sequence step execution
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  SequenceScheduler,
  getSequenceScheduler,
  calculateBackoffDelay,
  getNextRetryTime,
} from '../sequence-scheduler';
import type { SequenceStep, SequenceSettings } from '../../types/sequences';
import { DEFAULT_SEQUENCE_SETTINGS } from '../../types/sequences';

describe('SequenceScheduler', () => {
  let scheduler: SequenceScheduler;

  beforeEach(() => {
    scheduler = new SequenceScheduler();
  });

  describe('calculateNextStepTime', () => {
    const defaultSettings: SequenceSettings = {
      ...DEFAULT_SEQUENCE_SETTINGS,
      sendingSchedule: {
        timezone: 'America/New_York',
        businessHoursOnly: false,
        startHour: 9,
        endHour: 17,
        excludeDays: [],
      },
    };

    it('should add delay days correctly', () => {
      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 3,
        isActive: true,
      };

      const fromTime = new Date('2025-12-01T10:00:00Z');
      const result = scheduler.calculateNextStepTime(fromTime, step, defaultSettings);

      expect(result.scheduledAt.getDate()).toBe(fromTime.getDate() + 3);
    });

    it('should add delay hours correctly', () => {
      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 0,
        delayHours: 5,
        isActive: true,
      };

      const fromTime = new Date('2025-12-01T10:00:00Z');
      const result = scheduler.calculateNextStepTime(fromTime, step, defaultSettings);

      expect(result.scheduledAt.getHours()).toBe(fromTime.getHours() + 5);
    });

    it('should apply preferred time of day', () => {
      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 1,
        timeOfDay: '09:00',
        isActive: true,
      };

      const fromTime = new Date('2025-12-01T14:00:00');
      const result = scheduler.calculateNextStepTime(fromTime, step, defaultSettings);

      expect(result.scheduledAt.getHours()).toBe(9);
      expect(result.scheduledAt.getMinutes()).toBe(0);
    });

    it('should skip weekends when configured', () => {
      const settings: SequenceSettings = {
        ...defaultSettings,
        sendingSchedule: {
          ...defaultSettings.sendingSchedule,
          excludeDays: [0, 6], // Sunday, Saturday
        },
      };

      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 1,
        skipWeekends: true,
        isActive: true,
      };

      // Friday December 5, 2025
      const fromTime = new Date('2025-12-05T10:00:00');
      const result = scheduler.calculateNextStepTime(fromTime, step, settings);

      // Should skip to Monday (day 8)
      expect(result.scheduledAt.getDay()).not.toBe(0); // Not Sunday
      expect(result.scheduledAt.getDay()).not.toBe(6); // Not Saturday
    });

    it('should adjust for business hours when configured', () => {
      const settings: SequenceSettings = {
        ...defaultSettings,
        sendingSchedule: {
          ...defaultSettings.sendingSchedule,
          businessHoursOnly: true,
          startHour: 9,
          endHour: 17,
        },
      };

      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 0,
        isActive: true,
      };

      // 7 AM - before business hours
      const fromTime = new Date('2025-12-01T07:00:00');
      const result = scheduler.calculateNextStepTime(fromTime, step, settings);

      expect(result.scheduledAt.getHours()).toBeGreaterThanOrEqual(9);
    });

    it('should move to next day if after business hours', () => {
      const settings: SequenceSettings = {
        ...defaultSettings,
        sendingSchedule: {
          ...defaultSettings.sendingSchedule,
          businessHoursOnly: true,
          startHour: 9,
          endHour: 17,
        },
      };

      const step: SequenceStep = {
        id: 'step1',
        order: 0,
        type: 'email',
        delayDays: 0,
        isActive: true,
      };

      // 6 PM - after business hours
      const fromTime = new Date('2025-12-01T18:00:00');
      const result = scheduler.calculateNextStepTime(fromTime, step, settings);

      expect(result.scheduledAt.getDate()).toBe(fromTime.getDate() + 1);
      expect(result.scheduledAt.getHours()).toBe(9);
    });
  });

  describe('isWithinBusinessHours', () => {
    const settings: SequenceSettings = {
      ...DEFAULT_SEQUENCE_SETTINGS,
      sendingSchedule: {
        timezone: 'America/New_York',
        businessHoursOnly: true,
        startHour: 9,
        endHour: 17,
        excludeDays: [0, 6],
      },
    };

    it('should return true for time within business hours', () => {
      const time = new Date('2025-12-01T10:00:00'); // Monday 10 AM
      expect(scheduler.isWithinBusinessHours(time, settings)).toBe(true);
    });

    it('should return false for time before business hours', () => {
      const time = new Date('2025-12-01T08:00:00'); // 8 AM
      expect(scheduler.isWithinBusinessHours(time, settings)).toBe(false);
    });

    it('should return false for time after business hours', () => {
      const time = new Date('2025-12-01T18:00:00'); // 6 PM
      expect(scheduler.isWithinBusinessHours(time, settings)).toBe(false);
    });

    it('should return false for weekend days', () => {
      const saturday = new Date('2025-12-06T10:00:00'); // Saturday
      expect(scheduler.isWithinBusinessHours(saturday, settings)).toBe(false);
    });
  });

  describe('isWeekend', () => {
    it('should return true for Saturday', () => {
      const saturday = new Date('2025-12-06T10:00:00');
      expect(scheduler.isWeekend(saturday)).toBe(true);
    });

    it('should return true for Sunday', () => {
      const sunday = new Date('2025-12-07T10:00:00');
      expect(scheduler.isWeekend(sunday)).toBe(true);
    });

    it('should return false for weekday', () => {
      const monday = new Date('2025-12-01T10:00:00');
      expect(scheduler.isWeekend(monday)).toBe(false);
    });
  });

  describe('calculateFullSchedule', () => {
    it('should calculate schedule for all active steps', () => {
      const settings: SequenceSettings = {
        ...DEFAULT_SEQUENCE_SETTINGS,
        sendingSchedule: {
          timezone: 'America/New_York',
          businessHoursOnly: false,
          startHour: 9,
          endHour: 17,
          excludeDays: [],
        },
      };

      const steps: SequenceStep[] = [
        { id: 'step1', order: 0, type: 'email', delayDays: 0, isActive: true },
        { id: 'step2', order: 1, type: 'wait', delayDays: 2, isActive: true },
        { id: 'step3', order: 2, type: 'email', delayDays: 1, isActive: true },
        { id: 'step4', order: 3, type: 'task', delayDays: 1, isActive: false }, // Inactive
      ];

      const startTime = new Date('2025-12-01T10:00:00');
      const schedule = scheduler.calculateFullSchedule(steps, settings, startTime);

      expect(schedule).toHaveLength(3); // Only active steps
      expect(schedule[0].stepId).toBe('step1');
      expect(schedule[1].stepId).toBe('step2');
      expect(schedule[2].stepId).toBe('step3');
    });
  });

  describe('calculateSequenceDurationDays', () => {
    it('should calculate total duration correctly', () => {
      const settings: SequenceSettings = {
        ...DEFAULT_SEQUENCE_SETTINGS,
        sendingSchedule: {
          timezone: 'America/New_York',
          businessHoursOnly: false,
          startHour: 9,
          endHour: 17,
          excludeDays: [],
        },
      };

      const steps: SequenceStep[] = [
        { id: 'step1', order: 0, type: 'email', delayDays: 0, isActive: true },
        { id: 'step2', order: 1, type: 'wait', delayDays: 3, isActive: true },
        { id: 'step3', order: 2, type: 'email', delayDays: 2, isActive: true },
      ];

      const duration = scheduler.calculateSequenceDurationDays(steps, settings);
      expect(duration).toBeGreaterThanOrEqual(5); // 0 + 3 + 2 = 5 days minimum
    });

    it('should return 0 for empty steps', () => {
      const duration = scheduler.calculateSequenceDurationDays([], DEFAULT_SEQUENCE_SETTINGS);
      expect(duration).toBe(0);
    });
  });
});

describe('Backoff utilities', () => {
  describe('calculateBackoffDelay', () => {
    it('should calculate correct delay for first attempt', () => {
      const delay = calculateBackoffDelay(1, 60000, 3600000, 2);
      expect(delay).toBe(60000); // 1 minute
    });

    it('should double delay for each attempt', () => {
      const delay1 = calculateBackoffDelay(1, 60000, 3600000, 2);
      const delay2 = calculateBackoffDelay(2, 60000, 3600000, 2);
      const delay3 = calculateBackoffDelay(3, 60000, 3600000, 2);

      expect(delay2).toBe(delay1 * 2);
      expect(delay3).toBe(delay2 * 2);
    });

    it('should not exceed max delay', () => {
      const delay = calculateBackoffDelay(10, 60000, 3600000, 2);
      expect(delay).toBe(3600000); // Max 1 hour
    });
  });

  describe('getNextRetryTime', () => {
    it('should return future date', () => {
      const now = Date.now();
      const retryTime = getNextRetryTime(1);
      expect(retryTime.getTime()).toBeGreaterThan(now);
    });
  });
});

describe('getSequenceScheduler', () => {
  it('should return singleton instance', () => {
    const instance1 = getSequenceScheduler();
    const instance2 = getSequenceScheduler();
    expect(instance1).toBe(instance2);
  });
});
