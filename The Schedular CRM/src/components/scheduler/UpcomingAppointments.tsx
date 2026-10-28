/**
 * UpcomingAppointments Component
 * Widget displaying next upcoming appointments for a client
 * Designed for dashboard and sidebar use
 *
 * Agent CRM-43 Implementation
 */

import { useClientAppointments } from '../../hooks/useSchedulerData';
import type { Appointment } from '../../hooks/useSchedulerData';
import './scheduler.css';

// ============================================
// Types
// ============================================

export interface UpcomingAppointmentsProps {
  /** Client ID to fetch appointments for */
  clientId: string;
  /** Maximum number of appointments to show (default: 3) */
  maxItems?: number;
  /** Optional callback when appointment is clicked */
  onAppointmentClick?: (appointment: Appointment) => void;
  /** Optional callback when book appointment is clicked */
  onBookAppointment?: () => void;
  /** Compact mode for smaller spaces */
  compact?: boolean;
}

// ============================================
// Helpers
// ============================================

function formatDate(date: Date): string {
  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  const diffDays = Math.floor(diffMs / 86400000);
  const diffHours = Math.floor(diffMs / 3600000);

  // Today
  if (diffDays === 0 && diffHours >= 0) {
    return `Today at ${formatTime(date)}`;
  }

  // Tomorrow
  if (diffDays === 1) {
    return `Tomorrow at ${formatTime(date)}`;
  }

  // Within a week
  if (diffDays > 0 && diffDays < 7) {
    const dayName = date.toLocaleDateString('en-US', { weekday: 'long' });
    return `${dayName} at ${formatTime(date)}`;
  }

  // Future date
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}

function formatTime(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}

function getRelativeTimeColor(date: Date): string {
  const now = new Date();
  const diffHours = (date.getTime() - now.getTime()) / 3600000;

  if (diffHours < 2) return 'upcoming-soon';
  if (diffHours < 24) return 'upcoming-today';
  return 'upcoming-future';
}

// ============================================
// Component
// ============================================

/**
 * UpcomingAppointments - Widget for next appointments
 *
 * @example
 * ```tsx
 * // Full widget
 * <UpcomingAppointments
 *   clientId="client-123"
 *   maxItems={5}
 *   onAppointmentClick={(appt) => console.log(appt)}
 *   onBookAppointment={() => window.open('/scheduler/book')}
 * />
 *
 * // Compact mode for sidebar
 * <UpcomingAppointments
 *   clientId="client-123"
 *   maxItems={3}
 *   compact
 * />
 * ```
 */
export function UpcomingAppointments({
  clientId,
  maxItems = 3,
  onAppointmentClick,
  onBookAppointment,
  compact = false,
}: UpcomingAppointmentsProps) {
  const { upcoming, isLoading } = useClientAppointments(clientId);

  // Limit to maxItems
  const displayAppointments = upcoming.slice(0, maxItems);

  if (isLoading) {
    return (
      <div className={`upcoming-appointments ${compact ? 'upcoming-appointments--compact' : ''}`}>
        <div className="upcoming-appointments__loading">Loading...</div>
      </div>
    );
  }

  if (displayAppointments.length === 0) {
    return (
      <div className={`upcoming-appointments ${compact ? 'upcoming-appointments--compact' : ''}`}>
        <div className="upcoming-appointments__empty">
          <div className="upcoming-appointments__empty-icon">📅</div>
          <div className="upcoming-appointments__empty-text">No upcoming appointments</div>
          {onBookAppointment && (
            <button
              type="button"
              className="upcoming-appointments__book-btn upcoming-appointments__book-btn--primary"
              onClick={onBookAppointment}
            >
              Book Appointment
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className={`upcoming-appointments ${compact ? 'upcoming-appointments--compact' : ''}`}>
      {!compact && (
        <div className="upcoming-appointments__header">
          <h4 className="upcoming-appointments__title">Upcoming Appointments</h4>
          {onBookAppointment && (
            <button
              type="button"
              className="upcoming-appointments__book-btn upcoming-appointments__book-btn--small"
              onClick={onBookAppointment}
            >
              + Book
            </button>
          )}
        </div>
      )}

      <div className="upcoming-appointments__list">
        {displayAppointments.map((appt) => {
          const isClickable = !!onAppointmentClick;
          const timeColor = getRelativeTimeColor(appt.startTime);

          return (
            <div
              key={appt.id}
              className={`upcoming-appointment-item ${isClickable ? 'upcoming-appointment-item--clickable' : ''}`}
              onClick={isClickable ? () => onAppointmentClick(appt) : undefined}
            >
              {!compact && (
                <div className="upcoming-appointment-item__icon">📅</div>
              )}

              <div className="upcoming-appointment-item__content">
                <div className="upcoming-appointment-item__service">
                  {appt.serviceType}
                </div>
                <div className={`upcoming-appointment-item__time ${timeColor}`}>
                  {formatDate(appt.startTime)}
                </div>
                {!compact && appt.providerName && (
                  <div className="upcoming-appointment-item__provider">
                    with {appt.providerName}
                  </div>
                )}
              </div>

              {isClickable && (
                <div className="upcoming-appointment-item__arrow">→</div>
              )}
            </div>
          );
        })}
      </div>

      {upcoming.length > maxItems && (
        <div className="upcoming-appointments__footer">
          +{upcoming.length - maxItems} more appointment{upcoming.length - maxItems > 1 ? 's' : ''}
        </div>
      )}
    </div>
  );
}

export default UpcomingAppointments;
