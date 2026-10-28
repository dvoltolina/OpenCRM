/**
 * SequencePreview Component
 * Timeline preview of the sequence
 */

import { useMemo } from 'react';
import type { SequenceStep, SequenceSettings, SequenceStepType } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequencePreviewProps {
  steps: SequenceStep[];
  settings: SequenceSettings;
}

interface DayGroup {
  day: number;
  steps: SequenceStep[];
}

// ============================================
// Helpers
// ============================================

function getStepTypeLabel(type: SequenceStepType): string {
  switch (type) {
    case 'email':
      return 'Email';
    case 'task':
      return 'Task';
    case 'wait':
      return 'Wait';
    case 'call_reminder':
      return 'Call';
    case 'sms':
      return 'SMS';
    default:
      return 'Step';
  }
}

function getStepContent(step: SequenceStep): string {
  switch (step.type) {
    case 'email':
      return step.emailConfig?.subject || step.emailConfig?.templateId || 'Untitled email';
    case 'task':
      return step.taskConfig?.title || 'Untitled task';
    case 'wait':
      return `Wait ${step.delayDays} day${step.delayDays !== 1 ? 's' : ''}${step.delayHours ? ` ${step.delayHours}h` : ''}`;
    case 'call_reminder':
      return step.callConfig?.title || 'Untitled call';
    case 'sms':
      return step.smsConfig?.body?.substring(0, 30) || 'Untitled SMS';
    default:
      return 'Step';
  }
}

function groupStepsByDay(steps: SequenceStep[]): DayGroup[] {
  if (steps.length === 0) return [];

  const groups: DayGroup[] = [];
  let currentDay = 1;

  steps.forEach((step, index) => {
    // First step is always day 1
    if (index === 0) {
      groups.push({ day: currentDay, steps: [step] });
      return;
    }

    // Add delay to current day
    currentDay += step.delayDays || 0;

    // Find or create group for this day
    const existingGroup = groups.find((g) => g.day === currentDay);
    if (existingGroup) {
      existingGroup.steps.push(step);
    } else {
      groups.push({ day: currentDay, steps: [step] });
    }
  });

  return groups;
}

function isWeekend(day: number): boolean {
  // This is a simplified check - in real implementation would use actual dates
  // For preview purposes, we just show every 7th day as weekend
  return day % 7 === 0 || day % 7 === 6;
}

// ============================================
// Component
// ============================================

export function SequencePreview({ steps, settings }: SequencePreviewProps) {
  const dayGroups = useMemo(() => groupStepsByDay(steps), [steps]);

  const excludeWeekends = useMemo(
    () =>
      settings.sendingSchedule.excludeDays?.includes(0) &&
      settings.sendingSchedule.excludeDays?.includes(6),
    [settings.sendingSchedule.excludeDays]
  );

  const businessHours = useMemo(() => {
    if (!settings.sendingSchedule.businessHoursOnly) return null;
    const formatHour = (h: number) =>
      h === 0 ? '12 AM' : h < 12 ? `${h} AM` : h === 12 ? '12 PM' : `${h - 12} PM`;
    return `${formatHour(settings.sendingSchedule.startHour)} - ${formatHour(settings.sendingSchedule.endHour)}`;
  }, [settings.sendingSchedule]);

  if (steps.length === 0) {
    return (
      <div className="sequence-preview" data-testid="sequence-preview">
        <div className="sequence-preview__empty">
          <svg
            width="48"
            height="48"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            style={{ opacity: 0.5, marginBottom: '0.5rem' }}
          >
            <circle cx="12" cy="12" r="10" />
            <path d="M12 6v6l4 2" />
          </svg>
          <p>Add steps to see a preview of your sequence timeline.</p>
        </div>
      </div>
    );
  }

  const totalDays = dayGroups.length > 0 ? dayGroups[dayGroups.length - 1].day : 0;
  const actionSteps = steps.filter((s) => s.type !== 'wait');

  return (
    <div className="sequence-preview" data-testid="sequence-preview">
      {/* Summary */}
      <div
        style={{
          marginBottom: '1.5rem',
          padding: '1rem',
          background: 'var(--surface-secondary)',
          borderRadius: '0.5rem',
          fontSize: '0.8125rem',
        }}
      >
        <div style={{ marginBottom: '0.5rem' }}>
          <strong>{actionSteps.length}</strong> action{actionSteps.length !== 1 ? 's' : ''} over{' '}
          <strong>{totalDays}</strong> day{totalDays !== 1 ? 's' : ''}
        </div>
        {businessHours && (
          <div style={{ color: 'var(--text-secondary)' }}>
            Sending: {businessHours}
          </div>
        )}
        {excludeWeekends && (
          <div style={{ color: 'var(--text-secondary)' }}>
            Skipping weekends
          </div>
        )}
      </div>

      {/* Timeline */}
      <div className="sequence-preview__timeline">
        {dayGroups.map((group) => {
          const isWeekendDay = isWeekend(group.day);
          const skipped = excludeWeekends && isWeekendDay;

          return (
            <div
              key={group.day}
              className="sequence-preview__day"
              style={{ opacity: skipped ? 0.5 : 1 }}
            >
              <div
                className="sequence-preview__day-marker"
                style={{
                  background: skipped
                    ? 'var(--gray-400)'
                    : 'var(--primary)',
                }}
              />
              <div className="sequence-preview__day-label">
                Day {group.day}
                {skipped && ' (weekend - skipped)'}
              </div>
              {group.steps
                .filter((s) => s.type !== 'wait')
                .map((step) => (
                  <div key={step.id} className="sequence-preview__step">
                    <span className="sequence-preview__step-type">
                      {getStepTypeLabel(step.type)}
                    </span>
                    <div className="sequence-preview__step-content">
                      {getStepContent(step)}
                    </div>
                    {step.timeOfDay && (
                      <div
                        style={{
                          fontSize: '0.6875rem',
                          color: 'var(--text-tertiary)',
                          marginTop: '0.25rem',
                        }}
                      >
                        at {step.timeOfDay}
                      </div>
                    )}
                  </div>
                ))}
            </div>
          );
        })}
      </div>

      {/* Legend */}
      <div
        style={{
          marginTop: '1.5rem',
          padding: '0.75rem',
          background: 'var(--surface-secondary)',
          borderRadius: '0.375rem',
          fontSize: '0.75rem',
          color: 'var(--text-secondary)',
        }}
      >
        <strong>Note:</strong> Days are relative to enrollment. Actual send times
        depend on timezone and business hours settings.
      </div>
    </div>
  );
}

export default SequencePreview;
