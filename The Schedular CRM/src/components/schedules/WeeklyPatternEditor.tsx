/**
 * Weekly Pattern Editor Component
 * Grid for editing staff work hours per day of week
 */

import { useState, useCallback } from 'react';
import type { WeeklySchedulePattern, ScheduleTimeSlot, DayOfWeek } from '../../types/models';

const DAYS_OF_WEEK: { key: DayOfWeek; label: string; short: string }[] = [
  { key: 'monday', label: 'Monday', short: 'Mon' },
  { key: 'tuesday', label: 'Tuesday', short: 'Tue' },
  { key: 'wednesday', label: 'Wednesday', short: 'Wed' },
  { key: 'thursday', label: 'Thursday', short: 'Thu' },
  { key: 'friday', label: 'Friday', short: 'Fri' },
  { key: 'saturday', label: 'Saturday', short: 'Sat' },
  { key: 'sunday', label: 'Sunday', short: 'Sun' },
];

const DEFAULT_SHIFT: ScheduleTimeSlot = {
  startTime: '09:00',
  endTime: '17:00',
};

interface WeeklyPatternEditorProps {
  patterns: WeeklySchedulePattern[];
  onChange: (patterns: WeeklySchedulePattern[]) => void;
  disabled?: boolean;
}

export function WeeklyPatternEditor({
  patterns,
  onChange,
  disabled = false,
}: WeeklyPatternEditorProps) {
  const [expandedDay, setExpandedDay] = useState<DayOfWeek | null>(null);

  const getPatternForDay = useCallback(
    (day: DayOfWeek): WeeklySchedulePattern => {
      return (
        patterns.find((p) => p.dayOfWeek === day) ?? {
          dayOfWeek: day,
          isWorkingDay: false,
          shifts: [],
        }
      );
    },
    [patterns]
  );

  const updatePattern = useCallback(
    (day: DayOfWeek, updates: Partial<WeeklySchedulePattern>) => {
      const existingIndex = patterns.findIndex((p) => p.dayOfWeek === day);
      const existing = getPatternForDay(day);
      const updated = { ...existing, ...updates };

      if (existingIndex >= 0) {
        const newPatterns = [...patterns];
        newPatterns[existingIndex] = updated;
        onChange(newPatterns);
      } else {
        onChange([...patterns, updated]);
      }
    },
    [patterns, onChange, getPatternForDay]
  );

  const toggleWorkingDay = useCallback(
    (day: DayOfWeek) => {
      const pattern = getPatternForDay(day);
      const isWorkingDay = !pattern.isWorkingDay;
      updatePattern(day, {
        isWorkingDay,
        shifts: isWorkingDay && pattern.shifts.length === 0 ? [DEFAULT_SHIFT] : pattern.shifts,
      });
    },
    [getPatternForDay, updatePattern]
  );

  const updateShift = useCallback(
    (day: DayOfWeek, shiftIndex: number, field: 'startTime' | 'endTime', value: string) => {
      const pattern = getPatternForDay(day);
      const newShifts = [...pattern.shifts];
      newShifts[shiftIndex] = { ...newShifts[shiftIndex], [field]: value };
      updatePattern(day, { shifts: newShifts });
    },
    [getPatternForDay, updatePattern]
  );

  const addShift = useCallback(
    (day: DayOfWeek) => {
      const pattern = getPatternForDay(day);
      const lastShift = pattern.shifts[pattern.shifts.length - 1];
      const newShift: ScheduleTimeSlot = lastShift
        ? { startTime: lastShift.endTime, endTime: '18:00' }
        : DEFAULT_SHIFT;
      updatePattern(day, { shifts: [...pattern.shifts, newShift] });
    },
    [getPatternForDay, updatePattern]
  );

  const removeShift = useCallback(
    (day: DayOfWeek, shiftIndex: number) => {
      const pattern = getPatternForDay(day);
      const newShifts = pattern.shifts.filter((_, i) => i !== shiftIndex);
      updatePattern(day, {
        shifts: newShifts,
        isWorkingDay: newShifts.length > 0,
      });
    },
    [getPatternForDay, updatePattern]
  );

  const applyToAllWeekdays = useCallback(
    (sourceDay: DayOfWeek) => {
      const sourcePattern = getPatternForDay(sourceDay);
      const weekdays: DayOfWeek[] = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      const newPatterns = patterns.filter(
        (p) => !weekdays.includes(p.dayOfWeek) || p.dayOfWeek === sourceDay
      );

      weekdays.forEach((day) => {
        if (day !== sourceDay) {
          newPatterns.push({
            dayOfWeek: day,
            isWorkingDay: sourcePattern.isWorkingDay,
            shifts: [...sourcePattern.shifts],
          });
        }
      });

      // Preserve the source day pattern
      const sourceIndex = newPatterns.findIndex((p) => p.dayOfWeek === sourceDay);
      if (sourceIndex < 0) {
        newPatterns.push(sourcePattern);
      }

      onChange(newPatterns);
    },
    [patterns, onChange, getPatternForDay]
  );

  return (
    <div className="weekly-pattern-editor">
      <div className="weekly-pattern-header">
        <span className="weekly-pattern-title">Weekly Schedule</span>
      </div>

      <div className="weekly-pattern-grid">
        {DAYS_OF_WEEK.map(({ key, label, short }) => {
          const pattern = getPatternForDay(key);
          const isExpanded = expandedDay === key;

          return (
            <div
              key={key}
              className={`day-pattern ${pattern.isWorkingDay ? 'day-pattern--working' : ''} ${isExpanded ? 'day-pattern--expanded' : ''}`}
            >
              <div className="day-pattern__header">
                <label className="day-pattern__toggle">
                  <input
                    type="checkbox"
                    checked={pattern.isWorkingDay}
                    onChange={() => toggleWorkingDay(key)}
                    disabled={disabled}
                  />
                  <span className="day-pattern__label">
                    <span className="day-pattern__label-full">{label}</span>
                    <span className="day-pattern__label-short">{short}</span>
                  </span>
                </label>

                {pattern.isWorkingDay && (
                  <button
                    type="button"
                    className="day-pattern__expand-btn"
                    onClick={() => setExpandedDay(isExpanded ? null : key)}
                    disabled={disabled}
                  >
                    {isExpanded ? '−' : '+'}
                  </button>
                )}
              </div>

              {pattern.isWorkingDay && (
                <div className="day-pattern__shifts">
                  {pattern.shifts.map((shift, index) => (
                    <div key={index} className="shift-row">
                      <input
                        type="time"
                        value={shift.startTime}
                        onChange={(e) => updateShift(key, index, 'startTime', e.target.value)}
                        disabled={disabled}
                        className="shift-input"
                      />
                      <span className="shift-separator">to</span>
                      <input
                        type="time"
                        value={shift.endTime}
                        onChange={(e) => updateShift(key, index, 'endTime', e.target.value)}
                        disabled={disabled}
                        className="shift-input"
                      />
                      {pattern.shifts.length > 1 && (
                        <button
                          type="button"
                          className="shift-remove-btn"
                          onClick={() => removeShift(key, index)}
                          disabled={disabled}
                        >
                          &times;
                        </button>
                      )}
                    </div>
                  ))}

                  {isExpanded && (
                    <div className="day-pattern__actions">
                      <button
                        type="button"
                        className="btn btn-sm btn-ghost"
                        onClick={() => addShift(key)}
                        disabled={disabled}
                      >
                        + Add Shift
                      </button>
                      {['monday', 'tuesday', 'wednesday', 'thursday', 'friday'].includes(key) && (
                        <button
                          type="button"
                          className="btn btn-sm btn-ghost"
                          onClick={() => applyToAllWeekdays(key)}
                          disabled={disabled}
                        >
                          Apply to Weekdays
                        </button>
                      )}
                    </div>
                  )}
                </div>
              )}

              {!pattern.isWorkingDay && (
                <div className="day-pattern__off">Day Off</div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default WeeklyPatternEditor;
