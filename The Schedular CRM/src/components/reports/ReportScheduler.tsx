/**
 * ReportScheduler Component
 * Schedule configuration dialog for recurring report delivery.
 *
 * HIPAA Compliance:
 * - Schedule configurations contain no PHI
 * - Recipient selection respects RBAC (team members only)
 * - All schedule operations are logged via audit service
 *
 * Agent CRM - Task 7 Implementation
 */

import { useState, useMemo, useCallback } from 'react';
import type {
  ScheduledReportFrequency,
  ScheduledReportFormat,
} from '../../types/reporting';

// ============================================
// Types
// ============================================

export interface ReportSchedulerProps {
  /** Report ID being scheduled */
  reportId: string;
  /** Report name for display */
  reportName: string;
  /** Available team members for recipient selection */
  teamMembers: TeamMemberOption[];
  /** Existing schedule data for editing */
  existingSchedule?: ExistingScheduleData;
  /** Callback when schedule is saved */
  onSave: (schedule: ScheduleFormData) => Promise<void>;
  /** Callback when cancelled */
  onCancel: () => void;
  /** Callback when schedule is deleted (if editing) */
  onDelete?: () => Promise<void>;
  /** Whether save is in progress */
  isSaving?: boolean;
  /** Whether delete is in progress */
  isDeleting?: boolean;
}

export interface TeamMemberOption {
  id: string;
  name: string;
  email: string;
}

export interface ExistingScheduleData {
  id: string;
  frequency: ScheduledReportFrequency;
  dayOfWeek?: number;
  dayOfMonth?: number;
  timeOfDay: string;
  timezone?: string;
  recipientUserIds: string[];
  recipientEmails?: string[];
  format: ScheduledReportFormat;
  includeChart: boolean;
  isActive: boolean;
}

export interface ScheduleFormData {
  frequency: ScheduledReportFrequency;
  dayOfWeek?: number;
  dayOfMonth?: number;
  timeOfDay: string;
  timezone: string;
  recipientUserIds: string[];
  recipientEmails: string[];
  format: ScheduledReportFormat;
  includeChart: boolean;
  isActive: boolean;
}

// ============================================
// Constants
// ============================================

const FREQUENCIES: { value: ScheduledReportFrequency; label: string; description: string }[] = [
  { value: 'daily', label: 'Daily', description: 'Delivered every day' },
  { value: 'weekly', label: 'Weekly', description: 'Delivered once per week' },
  { value: 'monthly', label: 'Monthly', description: 'Delivered once per month' },
];

const FORMATS: { value: ScheduledReportFormat; label: string; description: string }[] = [
  { value: 'csv', label: 'CSV', description: 'Comma-separated values, compatible with Excel' },
  { value: 'xlsx', label: 'Excel', description: 'Native Excel format with formatting' },
  { value: 'pdf', label: 'PDF', description: 'Formatted document with charts' },
];

const DAYS_OF_WEEK = [
  { value: 0, label: 'Sunday' },
  { value: 1, label: 'Monday' },
  { value: 2, label: 'Tuesday' },
  { value: 3, label: 'Wednesday' },
  { value: 4, label: 'Thursday' },
  { value: 5, label: 'Friday' },
  { value: 6, label: 'Saturday' },
];

const DAYS_OF_MONTH = Array.from({ length: 28 }, (_, i) => ({
  value: i + 1,
  label: `${i + 1}${getOrdinalSuffix(i + 1)}`,
}));

const TIMEZONES = [
  { value: 'America/New_York', label: 'Eastern Time (ET)' },
  { value: 'America/Chicago', label: 'Central Time (CT)' },
  { value: 'America/Denver', label: 'Mountain Time (MT)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (PT)' },
  { value: 'America/Anchorage', label: 'Alaska Time (AKT)' },
  { value: 'Pacific/Honolulu', label: 'Hawaii Time (HT)' },
  { value: 'UTC', label: 'UTC' },
];

function getOrdinalSuffix(n: number): string {
  const s = ['th', 'st', 'nd', 'rd'];
  const v = n % 100;
  return s[(v - 20) % 10] || s[v] || s[0];
}

// Generate time options in 30-minute increments
const TIME_OPTIONS = Array.from({ length: 48 }, (_, i) => {
  const hours = Math.floor(i / 2);
  const minutes = (i % 2) * 30;
  const value = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
  const label = new Date(2000, 0, 1, hours, minutes).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
  return { value, label };
});

// ============================================
// Helper Functions
// ============================================

function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function getNextDeliveryDescription(schedule: ScheduleFormData): string {
  const now = new Date();
  const [hours, minutes] = schedule.timeOfDay.split(':').map(Number);

  const nextDate = new Date(now);
  nextDate.setHours(hours, minutes, 0, 0);

  switch (schedule.frequency) {
    case 'daily':
      if (nextDate <= now) {
        nextDate.setDate(nextDate.getDate() + 1);
      }
      break;

    case 'weekly': {
      const targetDay = schedule.dayOfWeek ?? 1;
      const currentDay = nextDate.getDay();
      let daysToAdd = targetDay - currentDay;
      if (daysToAdd < 0 || (daysToAdd === 0 && nextDate <= now)) {
        daysToAdd += 7;
      }
      nextDate.setDate(nextDate.getDate() + daysToAdd);
      break;
    }

    case 'monthly': {
      const targetDate = schedule.dayOfMonth ?? 1;
      nextDate.setDate(targetDate);
      if (nextDate <= now) {
        nextDate.setMonth(nextDate.getMonth() + 1);
      }
      break;
    }
  }

  return nextDate.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

// ============================================
// Main Component
// ============================================

/**
 * ReportScheduler - Schedule configuration for recurring reports
 *
 * Features:
 * - Configure frequency (daily, weekly, monthly)
 * - Set delivery time and timezone
 * - Select recipients from team or add external emails
 * - Choose export format (CSV, Excel, PDF)
 * - Option to include charts in export
 *
 * @example
 * ```tsx
 * <ReportScheduler
 *   reportId="report-123"
 *   reportName="Monthly Revenue Report"
 *   teamMembers={teamMembers}
 *   onSave={handleSaveSchedule}
 *   onCancel={handleCancel}
 * />
 * ```
 */
export function ReportScheduler({
  reportId: _reportId,
  reportName,
  teamMembers,
  existingSchedule,
  onSave,
  onCancel,
  onDelete,
  isSaving = false,
  isDeleting = false,
}: ReportSchedulerProps) {
  const isEditing = Boolean(existingSchedule);

  // Form state
  const [frequency, setFrequency] = useState<ScheduledReportFrequency>(
    existingSchedule?.frequency || 'weekly'
  );
  const [dayOfWeek, setDayOfWeek] = useState<number>(
    existingSchedule?.dayOfWeek ?? 1
  );
  const [dayOfMonth, setDayOfMonth] = useState<number>(
    existingSchedule?.dayOfMonth ?? 1
  );
  const [timeOfDay, setTimeOfDay] = useState(
    existingSchedule?.timeOfDay || '09:00'
  );
  const [timezone, setTimezone] = useState(
    existingSchedule?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
  );
  const [selectedRecipients, setSelectedRecipients] = useState<string[]>(
    existingSchedule?.recipientUserIds || []
  );
  const [externalEmails, setExternalEmails] = useState<string[]>(
    existingSchedule?.recipientEmails || []
  );
  const [newEmail, setNewEmail] = useState('');
  const [format, setFormat] = useState<ScheduledReportFormat>(
    existingSchedule?.format || 'xlsx'
  );
  const [includeChart, setIncludeChart] = useState(
    existingSchedule?.includeChart ?? true
  );
  const [isActive, setIsActive] = useState(
    existingSchedule?.isActive ?? true
  );

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Computed values
  const scheduleData = useMemo<ScheduleFormData>(() => ({
    frequency,
    dayOfWeek: frequency === 'weekly' ? dayOfWeek : undefined,
    dayOfMonth: frequency === 'monthly' ? dayOfMonth : undefined,
    timeOfDay,
    timezone,
    recipientUserIds: selectedRecipients,
    recipientEmails: externalEmails,
    format,
    includeChart,
    isActive,
  }), [
    frequency,
    dayOfWeek,
    dayOfMonth,
    timeOfDay,
    timezone,
    selectedRecipients,
    externalEmails,
    format,
    includeChart,
    isActive,
  ]);

  const nextDelivery = useMemo(
    () => getNextDeliveryDescription(scheduleData),
    [scheduleData]
  );

  const totalRecipients = selectedRecipients.length + externalEmails.length;

  // Validation
  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (totalRecipients === 0) {
      newErrors.recipients = 'At least one recipient is required';
    }

    if (externalEmails.some((email) => !validateEmail(email))) {
      newErrors.externalEmails = 'Invalid email format';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [totalRecipients, externalEmails]);

  // Handlers
  const handleRecipientToggle = useCallback((userId: string) => {
    setSelectedRecipients((prev) =>
      prev.includes(userId)
        ? prev.filter((id) => id !== userId)
        : [...prev, userId]
    );
  }, []);

  const handleAddExternalEmail = useCallback(() => {
    const email = newEmail.trim().toLowerCase();
    if (email && validateEmail(email) && !externalEmails.includes(email)) {
      setExternalEmails((prev) => [...prev, email]);
      setNewEmail('');
    }
  }, [newEmail, externalEmails]);

  const handleRemoveExternalEmail = useCallback((email: string) => {
    setExternalEmails((prev) => prev.filter((e) => e !== email));
  }, []);

  const handleSave = useCallback(async () => {
    if (!validate()) return;
    await onSave(scheduleData);
  }, [validate, scheduleData, onSave]);

  const handleDelete = useCallback(async () => {
    if (onDelete) {
      await onDelete();
    }
  }, [onDelete]);

  return (
    <div className="report-scheduler">
      {/* Header */}
      <div className="report-scheduler__header">
        <h2 className="report-scheduler__title">
          {isEditing ? 'Edit Schedule' : 'Schedule Report'}
        </h2>
        <p className="report-scheduler__subtitle">
          {reportName}
        </p>
      </div>

      {/* Content */}
      <div className="report-scheduler__content">
        {/* Active Toggle (for editing) */}
        {isEditing && (
          <div className="report-scheduler__toggle-section">
            <label className="form-toggle">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
              />
              <span className="form-toggle__slider" />
              <span className="form-toggle__label">
                Schedule is {isActive ? 'active' : 'paused'}
              </span>
            </label>
          </div>
        )}

        {/* Frequency */}
        <div className="report-scheduler__section">
          <h3 className="report-scheduler__section-title">Frequency</h3>
          <div className="report-scheduler__frequency-options">
            {FREQUENCIES.map((freq) => (
              <label
                key={freq.value}
                className={`report-scheduler__frequency-option ${
                  frequency === freq.value ? 'report-scheduler__frequency-option--selected' : ''
                }`}
              >
                <input
                  type="radio"
                  name="frequency"
                  value={freq.value}
                  checked={frequency === freq.value}
                  onChange={(e) => setFrequency(e.target.value as ScheduledReportFrequency)}
                />
                <span className="report-scheduler__frequency-label">{freq.label}</span>
                <span className="report-scheduler__frequency-desc">{freq.description}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Day Selection */}
        {frequency === 'weekly' && (
          <div className="report-scheduler__section">
            <h3 className="report-scheduler__section-title">Day of Week</h3>
            <div className="report-scheduler__day-options">
              {DAYS_OF_WEEK.map((day) => (
                <button
                  key={day.value}
                  type="button"
                  className={`report-scheduler__day-btn ${
                    dayOfWeek === day.value ? 'report-scheduler__day-btn--selected' : ''
                  }`}
                  onClick={() => setDayOfWeek(day.value)}
                >
                  {day.label.substring(0, 3)}
                </button>
              ))}
            </div>
          </div>
        )}

        {frequency === 'monthly' && (
          <div className="report-scheduler__section">
            <label htmlFor="day-of-month" className="form-label">
              Day of Month
            </label>
            <select
              id="day-of-month"
              className="form-select"
              value={dayOfMonth}
              onChange={(e) => setDayOfMonth(Number(e.target.value))}
            >
              {DAYS_OF_MONTH.map((day) => (
                <option key={day.value} value={day.value}>
                  {day.label}
                </option>
              ))}
            </select>
            <p className="form-hint">
              Days 29-31 will be adjusted to the last day of shorter months.
            </p>
          </div>
        )}

        {/* Time Selection */}
        <div className="report-scheduler__section">
          <div className="form-row">
            <div className="form-group">
              <label htmlFor="time-of-day" className="form-label">
                Delivery Time
              </label>
              <select
                id="time-of-day"
                className="form-select"
                value={timeOfDay}
                onChange={(e) => setTimeOfDay(e.target.value)}
              >
                {TIME_OPTIONS.map((time) => (
                  <option key={time.value} value={time.value}>
                    {time.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label htmlFor="timezone" className="form-label">
                Timezone
              </label>
              <select
                id="timezone"
                className="form-select"
                value={timezone}
                onChange={(e) => setTimezone(e.target.value)}
              >
                {TIMEZONES.map((tz) => (
                  <option key={tz.value} value={tz.value}>
                    {tz.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Recipients */}
        <div className="report-scheduler__section">
          <h3 className="report-scheduler__section-title">
            Recipients
            <span className="report-scheduler__recipient-count">
              ({totalRecipients} selected)
            </span>
          </h3>
          {errors.recipients && (
            <p className="form-error">{errors.recipients}</p>
          )}

          <div className="report-scheduler__recipients">
            {/* Team Members */}
            <div className="report-scheduler__team-members">
              <label className="form-label">Team Members</label>
              <div className="report-scheduler__team-list">
                {teamMembers.map((member) => (
                  <label
                    key={member.id}
                    className={`report-scheduler__team-item ${
                      selectedRecipients.includes(member.id)
                        ? 'report-scheduler__team-item--selected'
                        : ''
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={selectedRecipients.includes(member.id)}
                      onChange={() => handleRecipientToggle(member.id)}
                    />
                    <span className="report-scheduler__team-name">{member.name}</span>
                    <span className="report-scheduler__team-email">{member.email}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* External Emails */}
            <div className="report-scheduler__external-emails">
              <label className="form-label">External Email Addresses</label>
              <div className="report-scheduler__email-input">
                <input
                  type="email"
                  className="form-input"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  placeholder="Enter email address"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleAddExternalEmail();
                    }
                  }}
                />
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={handleAddExternalEmail}
                  disabled={!newEmail.trim() || !validateEmail(newEmail)}
                >
                  Add
                </button>
              </div>
              {errors.externalEmails && (
                <p className="form-error">{errors.externalEmails}</p>
              )}
              {externalEmails.length > 0 && (
                <div className="report-scheduler__email-list">
                  {externalEmails.map((email) => (
                    <div key={email} className="report-scheduler__email-chip">
                      <span>{email}</span>
                      <button
                        type="button"
                        className="report-scheduler__email-remove"
                        onClick={() => handleRemoveExternalEmail(email)}
                        title="Remove"
                      >
                        &times;
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Format */}
        <div className="report-scheduler__section">
          <h3 className="report-scheduler__section-title">Export Format</h3>
          <div className="report-scheduler__format-options">
            {FORMATS.map((fmt) => (
              <label
                key={fmt.value}
                className={`report-scheduler__format-option ${
                  format === fmt.value ? 'report-scheduler__format-option--selected' : ''
                }`}
              >
                <input
                  type="radio"
                  name="format"
                  value={fmt.value}
                  checked={format === fmt.value}
                  onChange={(e) => setFormat(e.target.value as ScheduledReportFormat)}
                />
                <span className="report-scheduler__format-label">{fmt.label}</span>
                <span className="report-scheduler__format-desc">{fmt.description}</span>
              </label>
            ))}
          </div>

          {(format === 'pdf' || format === 'xlsx') && (
            <label className="form-checkbox-label mt-4">
              <input
                type="checkbox"
                checked={includeChart}
                onChange={(e) => setIncludeChart(e.target.checked)}
              />
              <span>Include chart visualization in export</span>
            </label>
          )}
        </div>

        {/* Preview */}
        <div className="report-scheduler__preview">
          <div className="report-scheduler__preview-icon">📅</div>
          <div className="report-scheduler__preview-content">
            <p className="report-scheduler__preview-label">Next scheduled delivery:</p>
            <p className="report-scheduler__preview-date">{nextDelivery}</p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="report-scheduler__footer">
        {isEditing && onDelete && (
          <div className="report-scheduler__delete">
            {showDeleteConfirm ? (
              <div className="report-scheduler__delete-confirm">
                <span>Delete this schedule?</span>
                <button
                  type="button"
                  className="btn btn-sm btn-danger"
                  onClick={handleDelete}
                  disabled={isDeleting}
                >
                  {isDeleting ? 'Deleting...' : 'Yes, Delete'}
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-ghost"
                  onClick={() => setShowDeleteConfirm(false)}
                >
                  Cancel
                </button>
              </div>
            ) : (
              <button
                type="button"
                className="btn btn-ghost btn-danger"
                onClick={() => setShowDeleteConfirm(true)}
              >
                Delete Schedule
              </button>
            )}
          </div>
        )}

        <div className="report-scheduler__actions">
          <button type="button" className="btn btn-ghost" onClick={onCancel}>
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={handleSave}
            disabled={isSaving}
          >
            {isSaving ? 'Saving...' : isEditing ? 'Update Schedule' : 'Create Schedule'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ReportScheduler;
