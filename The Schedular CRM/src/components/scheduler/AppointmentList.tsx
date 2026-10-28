/**
 * AppointmentList Component
 * Displays client appointments from The Scheduler
 *
 * Agent CRM-43 Implementation
 */

import { useState } from 'react';
import { useClientAppointments } from '../../hooks/useSchedulerData';
import type { Appointment } from '../../hooks/useSchedulerData';
import './scheduler.css';

// ============================================
// Types
// ============================================

export interface AppointmentListProps {
  /** Client ID to fetch appointments for */
  clientId: string;
  /** Optional callback when book appointment is clicked */
  onBookAppointment?: () => void;
}

type TabType = 'upcoming' | 'past' | 'all';

// ============================================
// Helpers
// ============================================

function getStatusBadgeClass(status: Appointment['status']): string {
  const classes: Record<Appointment['status'], string> = {
    pending: 'appointment-status--pending',
    confirmed: 'appointment-status--confirmed',
    scheduled: 'appointment-status--scheduled',
    completed: 'appointment-status--completed',
    cancelled: 'appointment-status--cancelled',
    noShow: 'appointment-status--no-show',
    missed: 'appointment-status--no-show',
  };
  return classes[status] || 'appointment-status--default';
}

function getStatusLabel(status: Appointment['status']): string {
  const labels: Record<Appointment['status'], string> = {
    pending: 'Pending',
    confirmed: 'Confirmed',
    scheduled: 'Scheduled',
    completed: 'Completed',
    cancelled: 'Cancelled',
    noShow: 'No Show',
    missed: 'Missed',
  };
  return labels[status] || status;
}

function formatDateTime(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
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

// ============================================
// Component
// ============================================

/**
 * AppointmentList - Display client appointments
 *
 * @example
 * ```tsx
 * <AppointmentList
 *   clientId="client-123"
 *   onBookAppointment={() => window.open('/scheduler/book')}
 * />
 * ```
 */
export function AppointmentList({ clientId, onBookAppointment }: AppointmentListProps) {
  const { appointments, upcoming, past, isLoading } = useClientAppointments(clientId);
  const [activeTab, setActiveTab] = useState<TabType>('upcoming');

  // Get appointments for active tab
  const getTabAppointments = (): Appointment[] => {
    switch (activeTab) {
      case 'upcoming':
        return upcoming;
      case 'past':
        return past;
      case 'all':
        return appointments;
      default:
        return appointments;
    }
  };

  const tabAppointments = getTabAppointments();

  if (isLoading) {
    return (
      <div className="appointment-list">
        <div className="appointment-list__loading">Loading appointments...</div>
      </div>
    );
  }

  return (
    <div className="appointment-list">
      {/* Header with tabs */}
      <div className="appointment-list__header">
        <div className="appointment-tabs">
          <button
            type="button"
            className={`appointment-tab ${activeTab === 'upcoming' ? 'appointment-tab--active' : ''}`}
            onClick={() => setActiveTab('upcoming')}
          >
            Upcoming {upcoming.length > 0 && `(${upcoming.length})`}
          </button>
          <button
            type="button"
            className={`appointment-tab ${activeTab === 'past' ? 'appointment-tab--active' : ''}`}
            onClick={() => setActiveTab('past')}
          >
            Past {past.length > 0 && `(${past.length})`}
          </button>
          <button
            type="button"
            className={`appointment-tab ${activeTab === 'all' ? 'appointment-tab--active' : ''}`}
            onClick={() => setActiveTab('all')}
          >
            All {appointments.length > 0 && `(${appointments.length})`}
          </button>
        </div>

        {onBookAppointment && (
          <button
            type="button"
            className="appointment-list__book-btn"
            onClick={onBookAppointment}
          >
            Book Appointment
          </button>
        )}
      </div>

      {/* Appointment items */}
      {tabAppointments.length === 0 ? (
        <div className="appointment-list__empty">
          {activeTab === 'upcoming' && 'No upcoming appointments'}
          {activeTab === 'past' && 'No past appointments'}
          {activeTab === 'all' && 'No appointments'}
        </div>
      ) : (
        <div className="appointment-list__items">
          {tabAppointments.map((appt) => (
            <div key={appt.id} className="appointment-item">
              <div className="appointment-item__header">
                <div className="appointment-item__date">{formatDateTime(appt.startTime)}</div>
                <span className={`appointment-status ${getStatusBadgeClass(appt.status)}`}>
                  {getStatusLabel(appt.status)}
                </span>
              </div>

              <div className="appointment-item__body">
                <div className="appointment-item__service">{appt.serviceType}</div>
                <div className="appointment-item__details">
                  <span className="appointment-item__time">
                    {formatTime(appt.startTime)} - {formatTime(appt.endTime)}
                  </span>
                  {appt.providerName && (
                    <span className="appointment-item__provider">
                      with {appt.providerName}
                    </span>
                  )}
                </div>
                {appt.notes && (
                  <div className="appointment-item__notes">{appt.notes}</div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Footer attribution */}
      <div className="appointment-list__footer">
        Data from The Scheduler
      </div>
    </div>
  );
}

export default AppointmentList;
