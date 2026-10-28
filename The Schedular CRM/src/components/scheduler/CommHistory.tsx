/**
 * CommHistory Component
 * Displays communication history (email/SMS) from The Scheduler
 *
 * Agent CRM-43 Implementation
 */

import { useState } from 'react';
import { useClientCommunications } from '../../hooks/useSchedulerData';
import type { CommunicationRecord } from '../../hooks/useSchedulerData';
import './scheduler.css';

// ============================================
// Types
// ============================================

export interface CommHistoryProps {
  /** Client ID to fetch communication history for */
  clientId: string;
}

type FilterType = 'all' | 'email' | 'sms';

// ============================================
// Helpers
// ============================================

function getTypeIcon(type: CommunicationRecord['type']): string {
  return type === 'email' ? '📧' : '💬';
}

function getDirectionIcon(direction: CommunicationRecord['direction']): string {
  return direction === 'inbound' ? '⬇️' : '⬆️';
}

function getDirectionLabel(direction: CommunicationRecord['direction']): string {
  return direction === 'inbound' ? 'Received' : 'Sent';
}

function getStatusBadgeClass(status: CommunicationRecord['status']): string {
  const classes: Record<CommunicationRecord['status'], string> = {
    sent: 'comm-status--sent',
    delivered: 'comm-status--delivered',
    opened: 'comm-status--opened',
    failed: 'comm-status--failed',
  };
  return classes[status] || 'comm-status--default';
}

function getStatusLabel(status: CommunicationRecord['status']): string {
  const labels: Record<CommunicationRecord['status'], string> = {
    sent: 'Sent',
    delivered: 'Delivered',
    opened: 'Opened',
    failed: 'Failed',
  };
  return labels[status] || status;
}

function formatDateTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / 86400000);

  // If today, show time
  if (diffDays === 0) {
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  }

  // If this year, show month and day
  if (date.getFullYear() === now.getFullYear()) {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  }

  // Otherwise, show full date
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ============================================
// Component
// ============================================

/**
 * CommHistory - Display communication history
 *
 * @example
 * ```tsx
 * <CommHistory clientId="client-123" />
 * ```
 */
export function CommHistory({ clientId }: CommHistoryProps) {
  const { communications, emails, sms, isLoading } = useClientCommunications(clientId);
  const [filter, setFilter] = useState<FilterType>('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  // Get communications for active filter
  const getFilteredCommunications = (): CommunicationRecord[] => {
    switch (filter) {
      case 'email':
        return emails;
      case 'sms':
        return sms;
      case 'all':
      default:
        return communications;
    }
  };

  const filteredComms = getFilteredCommunications();

  const toggleExpanded = (id: string) => {
    setExpandedId(expandedId === id ? null : id);
  };

  if (isLoading) {
    return (
      <div className="comm-history">
        <div className="comm-history__loading">Loading communication history...</div>
      </div>
    );
  }

  return (
    <div className="comm-history">
      {/* Header with filter */}
      <div className="comm-history__header">
        <h3 className="comm-history__title">Communication History</h3>
        <div className="comm-filter">
          <button
            type="button"
            className={`comm-filter-btn ${filter === 'all' ? 'comm-filter-btn--active' : ''}`}
            onClick={() => setFilter('all')}
          >
            All {communications.length > 0 && `(${communications.length})`}
          </button>
          <button
            type="button"
            className={`comm-filter-btn ${filter === 'email' ? 'comm-filter-btn--active' : ''}`}
            onClick={() => setFilter('email')}
          >
            Email {emails.length > 0 && `(${emails.length})`}
          </button>
          <button
            type="button"
            className={`comm-filter-btn ${filter === 'sms' ? 'comm-filter-btn--active' : ''}`}
            onClick={() => setFilter('sms')}
          >
            SMS {sms.length > 0 && `(${sms.length})`}
          </button>
        </div>
      </div>

      {/* Communication timeline */}
      {filteredComms.length === 0 ? (
        <div className="comm-history__empty">
          {filter === 'all' && 'No communication history'}
          {filter === 'email' && 'No email communications'}
          {filter === 'sms' && 'No SMS communications'}
        </div>
      ) : (
        <div className="comm-timeline">
          {filteredComms.map((comm) => {
            const isExpanded = expandedId === comm.id;
            return (
              <div key={comm.id} className="comm-timeline-item">
                <div className="comm-timeline-marker">
                  <span className="comm-type-icon">{getTypeIcon(comm.type)}</span>
                </div>

                <div className="comm-timeline-content">
                  <div className="comm-timeline-header">
                    <div className="comm-timeline-info">
                      <span className="comm-direction-icon">
                        {getDirectionIcon(comm.direction)}
                      </span>
                      <span className="comm-direction-label">
                        {getDirectionLabel(comm.direction)}
                      </span>
                      <span className="comm-type-label">
                        {comm.type.toUpperCase()}
                      </span>
                      <span className="comm-date">{formatDateTime(comm.sentAt)}</span>
                    </div>
                    <span className={`comm-status ${getStatusBadgeClass(comm.status)}`}>
                      {getStatusLabel(comm.status)}
                    </span>
                  </div>

                  {comm.subject && (
                    <div className="comm-subject">{comm.subject}</div>
                  )}

                  <div className="comm-preview">
                    {isExpanded ? comm.preview : comm.preview.substring(0, 100)}
                    {comm.preview.length > 100 && !isExpanded && '...'}
                  </div>

                  {comm.preview.length > 100 && (
                    <button
                      type="button"
                      className="comm-expand-btn"
                      onClick={() => toggleExpanded(comm.id)}
                    >
                      {isExpanded ? 'Show less' : 'Show more'}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Footer attribution */}
      <div className="comm-history__footer">
        Data from The Scheduler
      </div>
    </div>
  );
}

export default CommHistory;
