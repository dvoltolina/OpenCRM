/**
 * Exception List Component
 * Manage time-off, holidays, and modified hours
 */

import { useState, useCallback } from 'react';
import type { ScheduleException, ScheduleTimeSlot } from '../../types/models';

interface ExceptionListProps {
  exceptions: ScheduleException[];
  onAdd: (exception: Omit<ScheduleException, 'id'>) => void;
  onRemove: (exceptionId: string) => void;
  disabled?: boolean;
}

const EXCEPTION_TYPES = [
  { value: 'time_off', label: 'Time Off' },
  { value: 'holiday', label: 'Holiday' },
  { value: 'modified_hours', label: 'Modified Hours' },
] as const;

export function ExceptionList({
  exceptions,
  onAdd,
  onRemove,
  disabled = false,
}: ExceptionListProps) {
  const [showAddForm, setShowAddForm] = useState(false);
  const [newException, setNewException] = useState<{
    date: string;
    type: ScheduleException['type'];
    allDay: boolean;
    reason: string;
    shifts: ScheduleTimeSlot[];
  }>({
    date: '',
    type: 'time_off',
    allDay: true,
    reason: '',
    shifts: [{ startTime: '09:00', endTime: '17:00' }],
  });

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!newException.date) return;

      onAdd({
        date: new Date(newException.date),
        type: newException.type,
        allDay: newException.allDay,
        reason: newException.reason || undefined,
        shifts: newException.type === 'modified_hours' ? newException.shifts : undefined,
      });

      setNewException({
        date: '',
        type: 'time_off',
        allDay: true,
        reason: '',
        shifts: [{ startTime: '09:00', endTime: '17:00' }],
      });
      setShowAddForm(false);
    },
    [newException, onAdd]
  );

  const formatDate = (date: Date | string): string => {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const getTypeLabel = (type: ScheduleException['type']): string => {
    return EXCEPTION_TYPES.find((t) => t.value === type)?.label ?? type;
  };

  const getTypeColor = (type: ScheduleException['type']): string => {
    switch (type) {
      case 'time_off':
        return 'var(--color-warning)';
      case 'holiday':
        return 'var(--color-success)';
      case 'modified_hours':
        return 'var(--color-primary)';
      default:
        return 'var(--color-text-secondary)';
    }
  };

  // Sort exceptions by date (upcoming first)
  const sortedExceptions = [...exceptions].sort((a, b) => {
    const dateA = typeof a.date === 'string' ? new Date(a.date) : a.date;
    const dateB = typeof b.date === 'string' ? new Date(b.date) : b.date;
    return dateA.getTime() - dateB.getTime();
  });

  const upcomingExceptions = sortedExceptions.filter((exc) => {
    const excDate = typeof exc.date === 'string' ? new Date(exc.date) : exc.date;
    return excDate >= new Date(new Date().toDateString());
  });

  const pastExceptions = sortedExceptions.filter((exc) => {
    const excDate = typeof exc.date === 'string' ? new Date(exc.date) : exc.date;
    return excDate < new Date(new Date().toDateString());
  });

  return (
    <div className="exception-list">
      <div className="exception-list__header">
        <h4>Schedule Exceptions</h4>
        {!showAddForm && (
          <button
            type="button"
            className="btn btn-sm btn-primary"
            onClick={() => setShowAddForm(true)}
            disabled={disabled}
          >
            + Add Exception
          </button>
        )}
      </div>

      {showAddForm && (
        <form className="exception-form" onSubmit={handleSubmit}>
          <div className="exception-form__row">
            <div className="form-group">
              <label>Date</label>
              <input
                type="date"
                value={newException.date}
                onChange={(e) => setNewException({ ...newException, date: e.target.value })}
                required
                disabled={disabled}
              />
            </div>

            <div className="form-group">
              <label>Type</label>
              <select
                value={newException.type}
                onChange={(e) =>
                  setNewException({
                    ...newException,
                    type: e.target.value as ScheduleException['type'],
                    allDay: e.target.value !== 'modified_hours',
                  })
                }
                disabled={disabled}
              >
                {EXCEPTION_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {newException.type === 'modified_hours' && (
            <div className="exception-form__shifts">
              <label>Working Hours</label>
              {newException.shifts.map((shift, index) => (
                <div key={index} className="shift-row">
                  <input
                    type="time"
                    value={shift.startTime}
                    onChange={(e) => {
                      const newShifts = [...newException.shifts];
                      newShifts[index] = { ...shift, startTime: e.target.value };
                      setNewException({ ...newException, shifts: newShifts });
                    }}
                    disabled={disabled}
                  />
                  <span>to</span>
                  <input
                    type="time"
                    value={shift.endTime}
                    onChange={(e) => {
                      const newShifts = [...newException.shifts];
                      newShifts[index] = { ...shift, endTime: e.target.value };
                      setNewException({ ...newException, shifts: newShifts });
                    }}
                    disabled={disabled}
                  />
                </div>
              ))}
            </div>
          )}

          <div className="form-group">
            <label>Reason (optional)</label>
            <input
              type="text"
              value={newException.reason}
              onChange={(e) => setNewException({ ...newException, reason: e.target.value })}
              placeholder="e.g., Doctor's appointment, Company holiday"
              disabled={disabled}
            />
          </div>

          <div className="exception-form__actions">
            <button
              type="button"
              className="btn btn-sm btn-ghost"
              onClick={() => setShowAddForm(false)}
              disabled={disabled}
            >
              Cancel
            </button>
            <button type="submit" className="btn btn-sm btn-primary" disabled={disabled}>
              Add Exception
            </button>
          </div>
        </form>
      )}

      {upcomingExceptions.length > 0 && (
        <div className="exception-section">
          <h5 className="exception-section__title">Upcoming</h5>
          <div className="exception-items">
            {upcomingExceptions.map((exc) => (
              <div key={exc.id} className="exception-item">
                <div
                  className="exception-item__type-indicator"
                  style={{ backgroundColor: getTypeColor(exc.type) }}
                />
                <div className="exception-item__content">
                  <div className="exception-item__date">{formatDate(exc.date)}</div>
                  <div className="exception-item__details">
                    <span className="exception-item__type">{getTypeLabel(exc.type)}</span>
                    {exc.reason && (
                      <span className="exception-item__reason"> - {exc.reason}</span>
                    )}
                    {exc.type === 'modified_hours' && exc.shifts && (
                      <span className="exception-item__shifts">
                        {exc.shifts.map((s, i) => (
                          <span key={i}>
                            {i > 0 && ', '}
                            {s.startTime}-{s.endTime}
                          </span>
                        ))}
                      </span>
                    )}
                  </div>
                </div>
                <button
                  type="button"
                  className="exception-item__remove"
                  onClick={() => onRemove(exc.id)}
                  disabled={disabled}
                >
                  &times;
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {pastExceptions.length > 0 && (
        <div className="exception-section exception-section--past">
          <h5 className="exception-section__title">Past</h5>
          <div className="exception-items">
            {pastExceptions.slice(0, 5).map((exc) => (
              <div key={exc.id} className="exception-item exception-item--past">
                <div
                  className="exception-item__type-indicator"
                  style={{ backgroundColor: getTypeColor(exc.type), opacity: 0.5 }}
                />
                <div className="exception-item__content">
                  <div className="exception-item__date">{formatDate(exc.date)}</div>
                  <div className="exception-item__details">
                    <span className="exception-item__type">{getTypeLabel(exc.type)}</span>
                    {exc.reason && (
                      <span className="exception-item__reason"> - {exc.reason}</span>
                    )}
                  </div>
                </div>
              </div>
            ))}
            {pastExceptions.length > 5 && (
              <div className="exception-item__more">
                +{pastExceptions.length - 5} more past exceptions
              </div>
            )}
          </div>
        </div>
      )}

      {exceptions.length === 0 && !showAddForm && (
        <div className="exception-list__empty">
          No schedule exceptions. Add time-off, holidays, or modified hours.
        </div>
      )}
    </div>
  );
}

export default ExceptionList;
